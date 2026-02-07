defmodule Trainer.Ingest.Codebase do
  @moduledoc """
  Ingests and analyzes a codebase to extract:
  - Routes and pages
  - Components and their relationships
  - API endpoints
  - Database models
  - Navigation structure
  """

  defstruct [
    :path,
    :routes,
    :components,
    :schemas,
    :controllers,
    :live_views,
    :contexts
  ]

  @doc """
  Analyzes a codebase at the given path.
  """
  def analyze(path) when is_binary(path) do
    state = %__MODULE__{
      path: path,
      routes: [],
      components: [],
      schemas: [],
      controllers: [],
      live_views: [],
      contexts: []
    }

    with {:ok, state} <- extract_routes(state),
         {:ok, state} <- extract_schemas(state),
         {:ok, state} <- extract_controllers(state),
         {:ok, state} <- extract_live_views(state),
         {:ok, state} <- extract_contexts(state) do
      {:ok, state}
    end
  end

  @doc """
  Extracts routes from Phoenix router files.
  """
  def extract_routes(%__MODULE__{path: path} = state) do
    router_files = find_files(path, "**/router.ex")

    routes =
      router_files
      |> Enum.flat_map(&parse_router_file/1)
      |> Enum.uniq_by(& &1.path)

    {:ok, %{state | routes: routes}}
  end

  @doc """
  Extracts Ecto schemas (database models).
  """
  def extract_schemas(%__MODULE__{path: path} = state) do
    schema_files = find_files(path, "**/*.ex")

    schemas =
      schema_files
      |> Enum.flat_map(&parse_schema_file/1)
      |> Enum.filter(& &1)

    {:ok, %{state | schemas: schemas}}
  end

  @doc """
  Extracts Phoenix controllers.
  """
  def extract_controllers(%__MODULE__{path: path} = state) do
    controller_files = find_files(path, "**/*_controller.ex")

    controllers =
      controller_files
      |> Enum.map(&parse_controller_file/1)
      |> Enum.filter(& &1)

    {:ok, %{state | controllers: controllers}}
  end

  @doc """
  Extracts Phoenix LiveViews.
  """
  def extract_live_views(%__MODULE__{path: path} = state) do
    live_files = find_files(path, "**/*_live.ex") ++ find_files(path, "**/*_live/*.ex")

    live_views =
      live_files
      |> Enum.map(&parse_live_view_file/1)
      |> Enum.filter(& &1)

    {:ok, %{state | live_views: live_views}}
  end

  @doc """
  Extracts context modules (business logic).
  """
  def extract_contexts(%__MODULE__{path: path} = state) do
    # Contexts are typically in lib/app_name/ but not in lib/app_name_web/
    context_files =
      find_files(path, "lib/**/*.ex")
      |> Enum.reject(&String.contains?(&1, "_web/"))
      |> Enum.reject(&String.contains?(&1, "/repo.ex"))
      |> Enum.reject(&String.contains?(&1, "/application.ex"))

    contexts =
      context_files
      |> Enum.map(&parse_context_file/1)
      |> Enum.filter(& &1)

    {:ok, %{state | contexts: contexts}}
  end

  # Private helpers

  defp find_files(path, pattern) do
    Path.wildcard(Path.join(path, pattern))
  end

  defp parse_router_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        # Extract route definitions
        route_regex = ~r/(get|post|put|patch|delete|live)\s+"([^"]+)"/

        Regex.scan(route_regex, content)
        |> Enum.map(fn [_, method, path] ->
          %{
            method: String.upcase(method),
            path: path,
            file: file_path
          }
        end)

      _ ->
        []
    end
  end

  defp parse_schema_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        # Check if file contains schema definition
        if String.contains?(content, "use Ecto.Schema") or
             String.contains?(content, "schema \"") do
          # Extract schema name and fields
          schema_regex = ~r/schema\s+"(\w+)"\s+do(.*?)end/s
          field_regex = ~r/field\s+:(\w+),\s+:?(\w+)/

          case Regex.run(schema_regex, content, capture: :all_but_first) do
            [table_name, schema_body] ->
              fields =
                Regex.scan(field_regex, schema_body)
                |> Enum.map(fn [_, name, type] -> %{name: name, type: type} end)

              module_name = extract_module_name(content)

              %{
                module: module_name,
                table: table_name,
                fields: fields,
                file: file_path
              }

            _ ->
              nil
          end
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp parse_controller_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        module_name = extract_module_name(content)

        # Extract action functions
        action_regex = ~r/def\s+(index|show|new|create|edit|update|delete|[\w]+)\s*\(/

        actions =
          Regex.scan(action_regex, content)
          |> Enum.map(fn [_, action] -> action end)
          |> Enum.uniq()

        %{
          module: module_name,
          actions: actions,
          file: file_path
        }

      _ ->
        nil
    end
  end

  defp parse_live_view_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        if String.contains?(content, "use Phoenix.LiveView") or
             String.contains?(content, "use TrainerWeb, :live_view") do
          module_name = extract_module_name(content)

          # Extract event handlers
          event_regex = ~r/def\s+handle_event\s*\(\s*"([^"]+)"/

          events =
            Regex.scan(event_regex, content)
            |> Enum.map(fn [_, event] -> event end)

          %{
            module: module_name,
            events: events,
            file: file_path
          }
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp parse_context_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        module_name = extract_module_name(content)

        # Extract public functions
        func_regex = ~r/def\s+(\w+)\s*\(/

        functions =
          Regex.scan(func_regex, content)
          |> Enum.map(fn [_, func] -> func end)
          |> Enum.reject(&String.starts_with?(&1, "_"))
          |> Enum.uniq()

        if length(functions) > 0 do
          %{
            module: module_name,
            functions: functions,
            file: file_path
          }
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp extract_module_name(content) do
    case Regex.run(~r/defmodule\s+([\w.]+)/, content) do
      [_, name] -> name
      _ -> "Unknown"
    end
  end
end
