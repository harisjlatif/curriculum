defmodule Curriculum.Ingest.Notion do
  @moduledoc """
  Ingests content from Notion workspaces.
  Uses the Notion API to fetch pages, databases, and their content.
  """

  @notion_api "https://api.notion.com/v1"
  @notion_version "2022-06-28"

  defstruct [:api_key, :pages, :databases]

  def new(api_key) do
    %__MODULE__{api_key: api_key, pages: [], databases: []}
  end

  @doc """
  Fetches all pages from a Notion workspace.
  """
  def fetch_pages(%__MODULE__{api_key: api_key} = state) do
    case search_all(api_key, %{filter: %{property: "object", value: "page"}}) do
      {:ok, pages} ->
        pages_with_content = Enum.map(pages, &fetch_page_content(api_key, &1))
        {:ok, %{state | pages: pages_with_content}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches all databases from a Notion workspace.
  """
  def fetch_databases(%__MODULE__{api_key: api_key} = state) do
    case search_all(api_key, %{filter: %{property: "object", value: "database"}}) do
      {:ok, databases} ->
        databases_with_items = Enum.map(databases, &fetch_database_items(api_key, &1))
        {:ok, %{state | databases: databases_with_items}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp search_all(api_key, query) do
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(query)

    case HTTPoison.post("#{@notion_api}/search", body, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["results"]}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "Notion API error #{status}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp fetch_page_content(api_key, page) do
    page_id = page["id"]

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Notion-Version", @notion_version}
    ]

    case HTTPoison.get("#{@notion_api}/blocks/#{page_id}/children?page_size=100", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        blocks = Jason.decode!(body)["results"]
        content = blocks_to_text(blocks)

        Map.merge(page, %{
          "content" => content,
          "title" => extract_title(page)
        })

      _ ->
        Map.put(page, "content", "")
    end
  end

  defp fetch_database_items(api_key, database) do
    db_id = database["id"]

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Notion-Version", @notion_version},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post("#{@notion_api}/databases/#{db_id}/query", "{}", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        items = Jason.decode!(body)["results"]
        Map.put(database, "items", items)

      _ ->
        Map.put(database, "items", [])
    end
  end

  defp extract_title(page) do
    case get_in(page, ["properties", "title", "title"]) do
      [%{"plain_text" => text} | _] -> text
      _ ->
        case get_in(page, ["properties", "Name", "title"]) do
          [%{"plain_text" => text} | _] -> text
          _ -> "Untitled"
        end
    end
  end

  defp blocks_to_text(blocks) do
    blocks
    |> Enum.map(&block_to_text/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp block_to_text(%{"type" => type} = block) do
    case type do
      "paragraph" -> extract_rich_text(block["paragraph"]["rich_text"])
      "heading_1" -> "# " <> extract_rich_text(block["heading_1"]["rich_text"])
      "heading_2" -> "## " <> extract_rich_text(block["heading_2"]["rich_text"])
      "heading_3" -> "### " <> extract_rich_text(block["heading_3"]["rich_text"])
      "bulleted_list_item" -> "• " <> extract_rich_text(block["bulleted_list_item"]["rich_text"])
      "numbered_list_item" -> "1. " <> extract_rich_text(block["numbered_list_item"]["rich_text"])
      "code" -> "```\n" <> extract_rich_text(block["code"]["rich_text"]) <> "\n```"
      "quote" -> "> " <> extract_rich_text(block["quote"]["rich_text"])
      _ -> nil
    end
  end

  defp extract_rich_text(rich_text) when is_list(rich_text) do
    rich_text
    |> Enum.map(& &1["plain_text"])
    |> Enum.join("")
  end

  defp extract_rich_text(_), do: ""
end
