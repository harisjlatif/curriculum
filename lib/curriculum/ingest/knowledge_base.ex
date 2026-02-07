defmodule Curriculum.Ingest.KnowledgeBase do
  @moduledoc """
  Ingests content from knowledge base systems.
  Supports common KB formats and APIs:
  - Zendesk
  - Intercom
  - Help Scout
  - Generic markdown/HTML files
  """

  defstruct [:source, :articles, :categories]

  @type article :: %{
          id: String.t(),
          title: String.t(),
          content: String.t(),
          category: String.t() | nil,
          views: integer() | nil,
          helpful_votes: integer() | nil,
          url: String.t() | nil
        }

  @doc """
  Creates a new knowledge base ingestor from a directory of markdown files.
  """
  def from_directory(path) do
    articles =
      Path.wildcard(Path.join(path, "**/*.{md,markdown,html}"))
      |> Enum.map(&parse_file/1)
      |> Enum.filter(& &1)

    categories =
      articles
      |> Enum.map(& &1.category)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    {:ok,
     %__MODULE__{
       source: {:directory, path},
       articles: articles,
       categories: categories
     }}
  end

  @doc """
  Fetches articles from Zendesk Help Center API.
  """
  def from_zendesk(subdomain, api_token, email) do
    base_url = "https://#{subdomain}.zendesk.com/api/v2/help_center"
    auth = Base.encode64("#{email}/token:#{api_token}")

    headers = [
      {"Authorization", "Basic #{auth}"},
      {"Content-Type", "application/json"}
    ]

    with {:ok, categories} <- fetch_zendesk_categories(base_url, headers),
         {:ok, articles} <- fetch_zendesk_articles(base_url, headers, categories) do
      {:ok,
       %__MODULE__{
         source: {:zendesk, subdomain},
         articles: articles,
         categories: Enum.map(categories, & &1["name"])
       }}
    end
  end

  @doc """
  Fetches articles from Intercom Help Center API.
  """
  def from_intercom(access_token) do
    base_url = "https://api.intercom.io"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
    ]

    with {:ok, collections} <- fetch_intercom_collections(base_url, headers),
         {:ok, articles} <- fetch_intercom_articles(base_url, headers) do
      {:ok,
       %__MODULE__{
         source: {:intercom, "api"},
         articles: articles,
         categories: Enum.map(collections, & &1["name"])
       }}
    end
  end

  @doc """
  Calculates priority score for articles based on views and helpfulness.
  Higher score = more important to include in training.
  """
  def prioritize_articles(%__MODULE__{articles: articles} = kb) do
    scored_articles =
      articles
      |> Enum.map(fn article ->
        score = calculate_priority_score(article)
        Map.put(article, :priority_score, score)
      end)
      |> Enum.sort_by(& &1.priority_score, :desc)

    %{kb | articles: scored_articles}
  end

  @doc """
  Groups articles by category for curriculum organization.
  """
  def group_by_category(%__MODULE__{articles: articles}) do
    articles
    |> Enum.group_by(& &1.category)
    |> Enum.map(fn {category, articles} ->
      %{
        category: category || "Uncategorized",
        articles: articles,
        article_count: length(articles)
      }
    end)
    |> Enum.sort_by(& &1.article_count, :desc)
  end

  # Private helpers

  defp parse_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        {title, body} = extract_title_and_body(content, file_path)
        category = extract_category_from_path(file_path)

        %{
          id: file_path,
          title: title,
          content: body,
          category: category,
          views: nil,
          helpful_votes: nil,
          url: nil
        }

      _ ->
        nil
    end
  end

  defp extract_title_and_body(content, file_path) do
    # Try to extract title from markdown header
    case Regex.run(~r/^#\s+(.+)$/m, content) do
      [_, title] ->
        body = String.replace(content, ~r/^#\s+.+$/m, "", global: false)
        {String.trim(title), String.trim(body)}

      nil ->
        # Fall back to filename
        title =
          file_path
          |> Path.basename()
          |> Path.rootname()
          |> String.replace(~r/[-_]/, " ")
          |> String.capitalize()

        {title, content}
    end
  end

  defp extract_category_from_path(file_path) do
    parts = Path.split(file_path)

    case length(parts) do
      n when n > 2 ->
        # Use parent directory as category
        Enum.at(parts, -2)
        |> String.replace(~r/[-_]/, " ")
        |> String.capitalize()

      _ ->
        nil
    end
  end

  defp calculate_priority_score(article) do
    views = article[:views] || 0
    helpful = article[:helpful_votes] || 0

    # Weighted score: views matter, but helpfulness matters more
    views * 1 + helpful * 10
  end

  defp fetch_zendesk_categories(base_url, headers) do
    case HTTPoison.get("#{base_url}/categories.json", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["categories"]}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "Zendesk API error #{status}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp fetch_zendesk_articles(base_url, headers, categories) do
    category_map =
      categories
      |> Enum.into(%{}, fn cat -> {cat["id"], cat["name"]} end)

    case HTTPoison.get("#{base_url}/articles.json?per_page=100", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        articles =
          Jason.decode!(body)["articles"]
          |> Enum.map(fn article ->
            %{
              id: to_string(article["id"]),
              title: article["title"],
              content: strip_html(article["body"]),
              category: Map.get(category_map, article["section_id"]),
              views: article["vote_count"],
              helpful_votes: article["vote_sum"],
              url: article["html_url"]
            }
          end)

        {:ok, articles}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "Zendesk API error #{status}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp fetch_intercom_collections(base_url, headers) do
    case HTTPoison.get("#{base_url}/help_center/collections", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["data"]}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "Intercom API error #{status}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp fetch_intercom_articles(base_url, headers) do
    case HTTPoison.get("#{base_url}/articles", headers) do
      {:ok, %{status_code: 200, body: body}} ->
        articles =
          Jason.decode!(body)["data"]
          |> Enum.map(fn article ->
            %{
              id: article["id"],
              title: article["title"],
              content: strip_html(article["body"]),
              category: nil,
              views: article["statistics"]["views"],
              helpful_votes: article["statistics"]["happy_reaction_percentage"],
              url: article["url"]
            }
          end)

        {:ok, articles}

      {:ok, %{status_code: status, body: body}} ->
        {:error, "Intercom API error #{status}: #{body}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp strip_html(nil), do: ""

  defp strip_html(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
