defmodule Curriculum.Ingest.Codebase do
  @moduledoc """
  Language-agnostic codebase analyzer.
  
  Extracts common concepts from any codebase:
  - Routes/endpoints (REST, GraphQL)
  - Models/entities (database schemas, types)
  - Controllers/handlers
  - Components/views
  - Services/business logic
  
  Supports: Elixir, Python, JavaScript/TypeScript, Ruby, Go, Java, Rust, PHP
  """

  defstruct [
    :path,
    :language,
    :framework,
    :routes,
    :models,
    :controllers,
    :components,
    :services,
    :config,
    :readme
  ]

  @type t :: %__MODULE__{
          path: String.t(),
          language: atom(),
          framework: atom() | nil,
          routes: [route()],
          models: [model()],
          controllers: [controller()],
          components: [component()],
          services: [service()],
          config: map(),
          readme: String.t() | nil
        }

  @type route :: %{
          method: String.t(),
          path: String.t(),
          handler: String.t() | nil,
          file: String.t()
        }

  @type model :: %{
          name: String.t(),
          fields: [%{name: String.t(), type: String.t()}],
          file: String.t()
        }

  @type controller :: %{
          name: String.t(),
          actions: [String.t()],
          file: String.t()
        }

  @type component :: %{
          name: String.t(),
          props: [String.t()],
          file: String.t()
        }

  @type service :: %{
          name: String.t(),
          functions: [String.t()],
          file: String.t()
        }

  @doc """
  Analyzes a codebase at the given path.
  Auto-detects language and framework.
  """
  def analyze(path) when is_binary(path) do
    with {:ok, language, framework} <- detect_stack(path) do
      state = %__MODULE__{
        path: path,
        language: language,
        framework: framework,
        routes: [],
        models: [],
        controllers: [],
        components: [],
        services: [],
        config: %{},
        readme: read_readme(path)
      }

      state
      |> extract_routes()
      |> extract_models()
      |> extract_controllers()
      |> extract_components()
      |> extract_services()
      |> extract_config()
      |> then(&{:ok, &1})
    end
  end

  @doc """
  Detects the primary language and framework of a codebase.
  """
  def detect_stack(path) do
    cond do
      # Elixir/Phoenix
      File.exists?(Path.join(path, "mix.exs")) ->
        framework = if has_phoenix?(path), do: :phoenix, else: :elixir
        {:ok, :elixir, framework}

      # Python
      File.exists?(Path.join(path, "requirements.txt")) or
          File.exists?(Path.join(path, "pyproject.toml")) or
          File.exists?(Path.join(path, "setup.py")) ->
        framework = detect_python_framework(path)
        {:ok, :python, framework}

      # JavaScript/TypeScript (Node)
      File.exists?(Path.join(path, "package.json")) ->
        {lang, framework} = detect_js_stack(path)
        {:ok, lang, framework}

      # Ruby
      File.exists?(Path.join(path, "Gemfile")) ->
        framework = if has_rails?(path), do: :rails, else: :ruby
        {:ok, :ruby, framework}

      # Go
      File.exists?(Path.join(path, "go.mod")) ->
        framework = detect_go_framework(path)
        {:ok, :go, framework}

      # Rust
      File.exists?(Path.join(path, "Cargo.toml")) ->
        framework = detect_rust_framework(path)
        {:ok, :rust, framework}

      # Java
      File.exists?(Path.join(path, "pom.xml")) or
          File.exists?(Path.join(path, "build.gradle")) ->
        framework = detect_java_framework(path)
        {:ok, :java, framework}

      # PHP
      File.exists?(Path.join(path, "composer.json")) ->
        framework = detect_php_framework(path)
        {:ok, :php, framework}

      # C# / .NET
      Enum.any?(Path.wildcard(Path.join(path, "*.csproj"))) or
          Enum.any?(Path.wildcard(Path.join(path, "*.sln"))) ->
        {:ok, :csharp, :dotnet}

      true ->
        {:ok, :unknown, nil}
    end
  end

  # ============================================
  # Route Extraction
  # ============================================

  defp extract_routes(%__MODULE__{language: lang, framework: fw, path: path} = state) do
    routes =
      case {lang, fw} do
        {:elixir, :phoenix} -> extract_phoenix_routes(path)
        {:python, :django} -> extract_django_routes(path)
        {:python, :flask} -> extract_flask_routes(path)
        {:python, :fastapi} -> extract_fastapi_routes(path)
        {:javascript, :express} -> extract_express_routes(path)
        {:typescript, :express} -> extract_express_routes(path)
        {:javascript, :nextjs} -> extract_nextjs_routes(path)
        {:typescript, :nextjs} -> extract_nextjs_routes(path)
        {:ruby, :rails} -> extract_rails_routes(path)
        {:go, :gin} -> extract_gin_routes(path)
        {:go, :echo} -> extract_echo_routes(path)
        {:go, :fiber} -> extract_fiber_routes(path)
        {:java, :spring} -> extract_spring_routes(path)
        {:php, :laravel} -> extract_laravel_routes(path)
        {:rust, :actix} -> extract_actix_routes(path)
        {:rust, :axum} -> extract_axum_routes(path)
        {:csharp, :dotnet} -> extract_dotnet_routes(path)
        _ -> extract_generic_routes(path)
      end

    %{state | routes: routes}
  end

  # ============================================
  # Model Extraction
  # ============================================

  defp extract_models(%__MODULE__{language: lang, framework: fw, path: path} = state) do
    models =
      case {lang, fw} do
        {:elixir, _} -> extract_ecto_models(path)
        {:python, :django} -> extract_django_models(path)
        {:python, _} -> extract_python_models(path)
        {:javascript, _} -> extract_js_models(path)
        {:typescript, _} -> extract_ts_models(path)
        {:ruby, :rails} -> extract_rails_models(path)
        {:go, _} -> extract_go_models(path)
        {:java, :spring} -> extract_jpa_models(path)
        {:php, :laravel} -> extract_eloquent_models(path)
        {:rust, _} -> extract_rust_models(path)
        {:csharp, _} -> extract_ef_models(path)
        _ -> []
      end

    %{state | models: models}
  end

  # ============================================
  # Controller Extraction
  # ============================================

  defp extract_controllers(%__MODULE__{language: lang, framework: fw, path: path} = state) do
    controllers =
      case {lang, fw} do
        {:elixir, :phoenix} -> extract_phoenix_controllers(path)
        {:python, :django} -> extract_django_views(path)
        {:python, :flask} -> extract_flask_views(path)
        {:python, :fastapi} -> extract_fastapi_handlers(path)
        {:javascript, :express} -> extract_express_handlers(path)
        {:typescript, :express} -> extract_express_handlers(path)
        {:ruby, :rails} -> extract_rails_controllers(path)
        {:go, _} -> extract_go_handlers(path)
        {:java, :spring} -> extract_spring_controllers(path)
        {:php, :laravel} -> extract_laravel_controllers(path)
        {:csharp, :dotnet} -> extract_dotnet_controllers(path)
        _ -> []
      end

    %{state | controllers: controllers}
  end

  # ============================================
  # Component Extraction
  # ============================================

  defp extract_components(%__MODULE__{language: lang, framework: fw, path: path} = state) do
    components =
      case {lang, fw} do
        {:elixir, :phoenix} -> extract_phoenix_components(path)
        {:javascript, :react} -> extract_react_components(path)
        {:javascript, :nextjs} -> extract_react_components(path)
        {:typescript, :react} -> extract_react_components(path)
        {:typescript, :nextjs} -> extract_react_components(path)
        {:javascript, :vue} -> extract_vue_components(path)
        {:typescript, :vue} -> extract_vue_components(path)
        {:javascript, :svelte} -> extract_svelte_components(path)
        {:typescript, :svelte} -> extract_svelte_components(path)
        {:ruby, :rails} -> extract_rails_views(path)
        _ -> []
      end

    %{state | components: components}
  end

  # ============================================
  # Service/Business Logic Extraction
  # ============================================

  defp extract_services(%__MODULE__{language: lang, path: path} = state) do
    services =
      case lang do
        :elixir -> extract_elixir_contexts(path)
        :python -> extract_python_services(path)
        :javascript -> extract_js_services(path)
        :typescript -> extract_js_services(path)
        :ruby -> extract_ruby_services(path)
        :go -> extract_go_services(path)
        :java -> extract_java_services(path)
        :php -> extract_php_services(path)
        :csharp -> extract_csharp_services(path)
        _ -> []
      end

    %{state | services: services}
  end

  # ============================================
  # Config Extraction
  # ============================================

  defp extract_config(%__MODULE__{language: lang, path: path} = state) do
    config =
      case lang do
        :elixir -> read_elixir_config(path)
        :python -> read_python_config(path)
        :javascript -> read_package_json(path)
        :typescript -> read_package_json(path)
        :ruby -> read_ruby_config(path)
        :go -> read_go_config(path)
        :java -> read_java_config(path)
        _ -> %{}
      end

    %{state | config: config}
  end

  # ============================================
  # Framework Detection Helpers
  # ============================================

  defp has_phoenix?(path) do
    case File.read(Path.join(path, "mix.exs")) do
      {:ok, content} -> String.contains?(content, ":phoenix")
      _ -> false
    end
  end

  defp detect_python_framework(path) do
    files = list_all_files(path, ["*.py", "*.txt", "*.toml"])
    content = files |> Enum.take(20) |> Enum.map(&safe_read/1) |> Enum.join("\n")

    cond do
      String.contains?(content, "django") -> :django
      String.contains?(content, "fastapi") or String.contains?(content, "FastAPI") -> :fastapi
      String.contains?(content, "flask") or String.contains?(content, "Flask") -> :flask
      true -> :python
    end
  end

  defp detect_js_stack(path) do
    pkg = read_package_json(path)
    deps = Map.merge(Map.get(pkg, "dependencies", %{}), Map.get(pkg, "devDependencies", %{}))

    lang = if Map.has_key?(deps, "typescript"), do: :typescript, else: :javascript

    framework =
      cond do
        Map.has_key?(deps, "next") -> :nextjs
        Map.has_key?(deps, "nuxt") -> :nuxt
        Map.has_key?(deps, "svelte") or Map.has_key?(deps, "@sveltejs/kit") -> :svelte
        Map.has_key?(deps, "vue") -> :vue
        Map.has_key?(deps, "react") -> :react
        Map.has_key?(deps, "express") -> :express
        Map.has_key?(deps, "fastify") -> :fastify
        Map.has_key?(deps, "hono") -> :hono
        true -> nil
      end

    {lang, framework}
  end

  defp has_rails?(path) do
    File.exists?(Path.join(path, "config/routes.rb")) or
      File.exists?(Path.join(path, "bin/rails"))
  end

  defp detect_go_framework(path) do
    case File.read(Path.join(path, "go.mod")) do
      {:ok, content} ->
        cond do
          String.contains?(content, "github.com/gin-gonic/gin") -> :gin
          String.contains?(content, "github.com/labstack/echo") -> :echo
          String.contains?(content, "github.com/gofiber/fiber") -> :fiber
          String.contains?(content, "github.com/gorilla/mux") -> :gorilla
          true -> :go
        end

      _ ->
        :go
    end
  end

  defp detect_rust_framework(path) do
    case File.read(Path.join(path, "Cargo.toml")) do
      {:ok, content} ->
        cond do
          String.contains?(content, "actix-web") -> :actix
          String.contains?(content, "axum") -> :axum
          String.contains?(content, "rocket") -> :rocket
          String.contains?(content, "warp") -> :warp
          true -> :rust
        end

      _ ->
        :rust
    end
  end

  defp detect_java_framework(path) do
    files = list_all_files(path, ["*.xml", "*.gradle", "*.java"])
    content = files |> Enum.take(30) |> Enum.map(&safe_read/1) |> Enum.join("\n")

    cond do
      String.contains?(content, "spring") -> :spring
      String.contains?(content, "quarkus") -> :quarkus
      String.contains?(content, "micronaut") -> :micronaut
      true -> :java
    end
  end

  defp detect_php_framework(path) do
    case File.read(Path.join(path, "composer.json")) do
      {:ok, content} ->
        cond do
          String.contains?(content, "laravel") -> :laravel
          String.contains?(content, "symfony") -> :symfony
          true -> :php
        end

      _ ->
        :php
    end
  end

  # ============================================
  # Phoenix/Elixir Extractors
  # ============================================

  defp extract_phoenix_routes(path) do
    find_files(path, "**/router.ex")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          Regex.scan(~r/(get|post|put|patch|delete|live)\s+"([^"]+)"/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_ecto_models(path) do
    find_files(path, "**/*.ex")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          if String.contains?(content, "schema \"") do
            case Regex.run(~r/schema\s+"(\w+)"\s+do(.*?)end/s, content) do
              [_, table, body] ->
                fields =
                  Regex.scan(~r/field\s+:(\w+),\s+:?(\w+)/, body)
                  |> Enum.map(fn [_, name, type] -> %{name: name, type: type} end)

                [%{name: extract_module_name(content), fields: fields, file: file}]

              _ ->
                []
            end
          else
            []
          end

        _ ->
          []
      end
    end)
  end

  defp extract_phoenix_controllers(path) do
    find_files(path, "**/*_controller.ex")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          actions =
            Regex.scan(~r/def\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.uniq()

          %{name: extract_module_name(content), actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_phoenix_components(path) do
    (find_files(path, "**/*_live.ex") ++ find_files(path, "**/components/*.ex"))
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          props =
            Regex.scan(~r/attr\s+:(\w+)/, content)
            |> Enum.map(fn [_, prop] -> prop end)

          %{name: extract_module_name(content), props: props, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_elixir_contexts(path) do
    find_files(path, "lib/**/*.ex")
    |> Enum.reject(&String.contains?(&1, "_web/"))
    |> Enum.reject(&String.ends_with?(&1, "/repo.ex"))
    |> Enum.reject(&String.ends_with?(&1, "/application.ex"))
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/def\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.reject(&String.starts_with?(&1, "_"))
            |> Enum.uniq()

          if length(functions) > 0 do
            %{name: extract_module_name(content), functions: functions, file: file}
          else
            nil
          end

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # Python Extractors
  # ============================================

  defp extract_django_routes(path) do
    find_files(path, "**/urls.py")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # path('users/', views.user_list)
          Regex.scan(~r/path\s*\(\s*['"](.*?)['"]/, content)
          |> Enum.map(fn [_, route_path] ->
            %{method: "GET", path: "/" <> route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_flask_routes(path) do
    find_files(path, "**/*.py")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # @app.route('/users', methods=['GET', 'POST'])
          Regex.scan(~r/@\w+\.route\s*\(\s*['"](.*?)['"]/, content)
          |> Enum.map(fn [_, route_path] ->
            %{method: "GET", path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_fastapi_routes(path) do
    find_files(path, "**/*.py")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # @app.get("/users")
          Regex.scan(~r/@\w+\.(get|post|put|patch|delete)\s*\(\s*['"](.*?)['"]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_django_models(path) do
    find_files(path, "**/models.py") ++ find_files(path, "**/models/*.py")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # class User(models.Model):
          Regex.scan(~r/class\s+(\w+)\s*\(\s*(?:models\.Model|Model)/, content)
          |> Enum.map(fn [_, name] ->
            fields =
              Regex.scan(~r/(\w+)\s*=\s*models\.(\w+)Field/, content)
              |> Enum.map(fn [_, field_name, field_type] ->
                %{name: field_name, type: field_type}
              end)

            %{name: name, fields: fields, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_python_models(path) do
    # Generic Python: look for dataclasses, Pydantic models
    find_files(path, "**/*.py")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # @dataclass or class Foo(BaseModel)
          models =
            Regex.scan(~r/(?:@dataclass[^\n]*\n)?class\s+(\w+)\s*(?:\((?:BaseModel|Base)\))?:/, content)
            |> Enum.map(fn matches ->
              name = List.last(matches)

              fields =
                Regex.scan(~r/(\w+)\s*:\s*(\w+)/, content)
                |> Enum.take(20)
                |> Enum.map(fn [_, field_name, field_type] ->
                  %{name: field_name, type: field_type}
                end)

              %{name: name, fields: fields, file: file}
            end)

          models

        _ ->
          []
      end
    end)
    |> Enum.filter(&(length(&1.fields) > 0))
  end

  defp extract_django_views(path) do
    find_files(path, "**/views.py") ++ find_files(path, "**/views/*.py")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          actions =
            Regex.scan(~r/def\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.reject(&(&1 in ["__init__", "__str__"]))
            |> Enum.uniq()

          %{name: Path.basename(file, ".py"), actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_flask_views(path), do: extract_django_views(path)
  defp extract_fastapi_handlers(path), do: extract_django_views(path)

  defp extract_python_services(path) do
    (find_files(path, "**/services/*.py") ++ find_files(path, "**/service.py"))
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/def\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.reject(&String.starts_with?(&1, "_"))
            |> Enum.uniq()

          %{name: Path.basename(file, ".py"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # JavaScript/TypeScript Extractors
  # ============================================

  defp extract_express_routes(path) do
    find_files(path, "**/*.{js,ts}")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # router.get('/users', handler) or app.post('/api/users', ...)
          Regex.scan(~r/(?:router|app)\.(get|post|put|patch|delete)\s*\(\s*['"](.*?)['"]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_nextjs_routes(path) do
    # Next.js file-based routing
    pages_dirs = [
      Path.join(path, "pages"),
      Path.join(path, "src/pages"),
      Path.join(path, "app"),
      Path.join(path, "src/app")
    ]

    pages_dirs
    |> Enum.filter(&File.dir?/1)
    |> Enum.flat_map(fn dir ->
      find_files(dir, "**/*.{js,jsx,ts,tsx}")
      |> Enum.reject(&String.contains?(&1, "_app"))
      |> Enum.reject(&String.contains?(&1, "_document"))
      |> Enum.map(fn file ->
        route_path =
          file
          |> String.replace(dir, "")
          |> String.replace(~r/\.(js|jsx|ts|tsx)$/, "")
          |> String.replace("/index", "")
          |> String.replace(~r/\[(\w+)\]/, ":\\1")

        route_path = if route_path == "", do: "/", else: route_path
        %{method: "GET", path: route_path, handler: nil, file: file}
      end)
    end)
  end

  defp extract_js_models(path), do: extract_ts_models(path)

  defp extract_ts_models(path) do
    # Look for TypeScript interfaces, types, and Prisma models
    find_files(path, "**/*.{ts,tsx}")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # interface User { ... } or type User = { ... }
          Regex.scan(~r/(?:interface|type)\s+(\w+)\s*(?:=\s*)?\{([^}]+)\}/, content)
          |> Enum.map(fn [_, name, body] ->
            fields =
              Regex.scan(~r/(\w+)\s*[?]?\s*:\s*(\w+)/, body)
              |> Enum.map(fn [_, field_name, field_type] ->
                %{name: field_name, type: field_type}
              end)

            %{name: name, fields: fields, file: file}
          end)

        _ ->
          []
      end
    end)
    |> Enum.filter(&(length(&1.fields) > 0))
  end

  defp extract_react_components(path) do
    find_files(path, "**/*.{jsx,tsx}")
    |> Enum.reject(&String.contains?(&1, "node_modules"))
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # function ComponentName or const ComponentName = 
          name =
            case Regex.run(~r/(?:function|const)\s+([A-Z]\w+)/, content) do
              [_, n] -> n
              _ -> Path.basename(file) |> String.replace(~r/\.(jsx|tsx)$/, "")
            end

          # Props: { prop1, prop2 } or interface Props
          props =
            Regex.scan(~r/(?:\{\s*([^}]+)\s*\}|Props\s*\{([^}]+)\})/, content)
            |> Enum.flat_map(fn matches ->
              matches
              |> Enum.drop(1)
              |> Enum.filter(& &1)
              |> Enum.flat_map(&String.split(&1, ~r/[,\n]/))
              |> Enum.map(&String.trim/1)
              |> Enum.map(&String.replace(&1, ~r/[?:].+/, ""))
              |> Enum.filter(&(&1 != "" and &1 =~ ~r/^\w+$/))
            end)
            |> Enum.take(10)

          %{name: name, props: props, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_vue_components(path) do
    find_files(path, "**/*.vue")
    |> Enum.map(fn file ->
      name = Path.basename(file, ".vue")

      case File.read(file) do
        {:ok, content} ->
          props =
            Regex.scan(~r/props\s*:\s*\[([^\]]+)\]|defineProps<\{([^}]+)\}>/, content)
            |> Enum.flat_map(fn matches ->
              matches
              |> Enum.drop(1)
              |> Enum.filter(& &1)
              |> Enum.flat_map(&String.split(&1, ~r/[,\n'"]/))
              |> Enum.map(&String.trim/1)
              |> Enum.filter(&(&1 != ""))
            end)

          %{name: name, props: props, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_svelte_components(path) do
    find_files(path, "**/*.svelte")
    |> Enum.map(fn file ->
      name = Path.basename(file, ".svelte")

      case File.read(file) do
        {:ok, content} ->
          # export let propName
          props =
            Regex.scan(~r/export\s+let\s+(\w+)/, content)
            |> Enum.map(fn [_, prop] -> prop end)

          %{name: name, props: props, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_express_handlers(path) do
    find_files(path, "**/controllers/*.{js,ts}") ++
      find_files(path, "**/handlers/*.{js,ts}") ++
      find_files(path, "**/routes/*.{js,ts}")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          actions =
            Regex.scan(~r/(?:export\s+)?(?:async\s+)?(?:function|const)\s+(\w+)/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.uniq()

          %{name: Path.basename(file) |> String.replace(~r/\.(js|ts)$/, ""), actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_js_services(path) do
    find_files(path, "**/services/*.{js,ts}") ++
      find_files(path, "**/lib/*.{js,ts}") ++
      find_files(path, "**/utils/*.{js,ts}")
    |> Enum.reject(&String.contains?(&1, "node_modules"))
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/(?:export\s+)?(?:async\s+)?(?:function|const)\s+(\w+)/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.reject(&String.starts_with?(&1, "_"))
            |> Enum.uniq()

          %{name: Path.basename(file) |> String.replace(~r/\.(js|ts)$/, ""), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(&(&1 && length(&1.functions) > 0))
  end

  # ============================================
  # Ruby/Rails Extractors
  # ============================================

  defp extract_rails_routes(path) do
    case File.read(Path.join(path, "config/routes.rb")) do
      {:ok, content} ->
        # resources :users or get '/users', to: 'users#index'
        resource_routes =
          Regex.scan(~r/resources?\s+:(\w+)/, content)
          |> Enum.flat_map(fn [_, resource] ->
            [
              %{method: "GET", path: "/#{resource}", handler: "#{resource}#index", file: "config/routes.rb"},
              %{method: "GET", path: "/#{resource}/:id", handler: "#{resource}#show", file: "config/routes.rb"},
              %{method: "POST", path: "/#{resource}", handler: "#{resource}#create", file: "config/routes.rb"},
              %{method: "PUT", path: "/#{resource}/:id", handler: "#{resource}#update", file: "config/routes.rb"},
              %{method: "DELETE", path: "/#{resource}/:id", handler: "#{resource}#destroy", file: "config/routes.rb"}
            ]
          end)

        explicit_routes =
          Regex.scan(~r/(get|post|put|patch|delete)\s+['"]([^'"]+)['"]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: "config/routes.rb"}
          end)

        resource_routes ++ explicit_routes

      _ ->
        []
    end
  end

  defp extract_rails_models(path) do
    find_files(path, "app/models/*.rb")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          case Regex.run(~r/class\s+(\w+)\s*<\s*(?:ApplicationRecord|ActiveRecord::Base)/, content) do
            [_, name] ->
              # Look at schema.rb for fields or use associations
              [%{name: name, fields: [], file: file}]

            _ ->
              []
          end

        _ ->
          []
      end
    end)
  end

  defp extract_rails_controllers(path) do
    find_files(path, "app/controllers/**/*_controller.rb")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          name =
            case Regex.run(~r/class\s+(\w+)Controller/, content) do
              [_, n] -> n
              _ -> Path.basename(file, "_controller.rb")
            end

          actions =
            Regex.scan(~r/def\s+(\w+)/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.reject(&(&1 in ["initialize", "set_#{String.downcase(name)}"]))
            |> Enum.uniq()

          %{name: name, actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_rails_views(path) do
    find_files(path, "app/views/**/*.html.erb") ++
      find_files(path, "app/views/**/*.html.haml")
    |> Enum.map(fn file ->
      %{name: Path.basename(file), props: [], file: file}
    end)
  end

  defp extract_ruby_services(path) do
    find_files(path, "app/services/*.rb") ++ find_files(path, "lib/*.rb")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/def\s+(\w+)/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.reject(&String.starts_with?(&1, "_"))
            |> Enum.uniq()

          %{name: Path.basename(file, ".rb"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # Go Extractors
  # ============================================

  defp extract_gin_routes(path), do: extract_go_routes(path, ~r/(?:GET|POST|PUT|PATCH|DELETE)\s*\(\s*"([^"]+)"/)
  defp extract_echo_routes(path), do: extract_go_routes(path, ~r/\.(?:GET|POST|PUT|PATCH|DELETE)\s*\(\s*"([^"]+)"/)
  defp extract_fiber_routes(path), do: extract_go_routes(path, ~r/\.(?:Get|Post|Put|Patch|Delete)\s*\(\s*"([^"]+)"/)

  defp extract_go_routes(path, pattern) do
    find_files(path, "**/*.go")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          Regex.scan(pattern, content)
          |> Enum.map(fn [full, route_path] ->
            method =
              case Regex.run(~r/(GET|POST|PUT|PATCH|DELETE|Get|Post|Put|Patch|Delete)/, full) do
                [_, m] -> String.upcase(m)
                _ -> "GET"
              end

            %{method: method, path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_go_models(path) do
    find_files(path, "**/*.go")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # type User struct { ... }
          Regex.scan(~r/type\s+(\w+)\s+struct\s*\{([^}]+)\}/s, content)
          |> Enum.map(fn [_, name, body] ->
            fields =
              Regex.scan(~r/(\w+)\s+(\w+)/, body)
              |> Enum.map(fn [_, field_name, field_type] ->
                %{name: field_name, type: field_type}
              end)

            %{name: name, fields: fields, file: file}
          end)

        _ ->
          []
      end
    end)
    |> Enum.filter(&(length(&1.fields) > 0))
  end

  defp extract_go_handlers(path) do
    find_files(path, "**/handlers/*.go") ++ find_files(path, "**/controllers/*.go")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/func\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.uniq()

          %{name: Path.basename(file, ".go"), actions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_go_services(path) do
    find_files(path, "**/services/*.go") ++ find_files(path, "**/service/*.go")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/func\s+(?:\([^)]+\)\s+)?(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.uniq()

          %{name: Path.basename(file, ".go"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # Java/Spring Extractors
  # ============================================

  defp extract_spring_routes(path) do
    find_files(path, "**/*.java")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # @GetMapping("/users") or @RequestMapping(value = "/users", method = GET)
          Regex.scan(~r/@(Get|Post|Put|Patch|Delete)Mapping\s*\(\s*"([^"]+)"/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_jpa_models(path) do
    find_files(path, "**/*.java")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          if String.contains?(content, "@Entity") do
            case Regex.run(~r/class\s+(\w+)/, content) do
              [_, name] ->
                fields =
                  Regex.scan(~r/private\s+(\w+)\s+(\w+)\s*;/, content)
                  |> Enum.map(fn [_, type, field_name] ->
                    %{name: field_name, type: type}
                  end)

                [%{name: name, fields: fields, file: file}]

              _ ->
                []
            end
          else
            []
          end

        _ ->
          []
      end
    end)
  end

  defp extract_spring_controllers(path) do
    find_files(path, "**/*Controller.java")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          name =
            case Regex.run(~r/class\s+(\w+)Controller/, content) do
              [_, n] -> n
              _ -> Path.basename(file, ".java")
            end

          actions =
            Regex.scan(~r/public\s+\w+\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.uniq()

          %{name: name, actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_java_services(path) do
    find_files(path, "**/*Service.java") ++ find_files(path, "**/services/*.java")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/public\s+\w+\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.uniq()

          %{name: Path.basename(file, ".java"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # PHP/Laravel Extractors
  # ============================================

  defp extract_laravel_routes(path) do
    (find_files(path, "routes/*.php") ++ [Path.join(path, "routes/web.php"), Path.join(path, "routes/api.php")])
    |> Enum.uniq()
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          Regex.scan(~r/Route::(get|post|put|patch|delete)\s*\(\s*['"]([^'"]+)['"]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_eloquent_models(path) do
    find_files(path, "app/Models/*.php") ++ find_files(path, "app/*.php")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          if String.contains?(content, "extends Model") do
            case Regex.run(~r/class\s+(\w+)\s+extends\s+Model/, content) do
              [_, name] ->
                # $fillable array
                fields =
                  case Regex.run(~r/\$fillable\s*=\s*\[([^\]]+)\]/, content) do
                    [_, fields_str] ->
                      Regex.scan(~r/['"](\w+)['"]/, fields_str)
                      |> Enum.map(fn [_, field] -> %{name: field, type: "mixed"} end)

                    _ ->
                      []
                  end

                [%{name: name, fields: fields, file: file}]

              _ ->
                []
            end
          else
            []
          end

        _ ->
          []
      end
    end)
  end

  defp extract_laravel_controllers(path) do
    find_files(path, "app/Http/Controllers/*.php")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          name =
            case Regex.run(~r/class\s+(\w+)Controller/, content) do
              [_, n] -> n
              _ -> Path.basename(file, ".php")
            end

          actions =
            Regex.scan(~r/public\s+function\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.reject(&(&1 == "__construct"))
            |> Enum.uniq()

          %{name: name, actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_php_services(path) do
    find_files(path, "app/Services/*.php")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/public\s+function\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.reject(&(&1 == "__construct"))
            |> Enum.uniq()

          %{name: Path.basename(file, ".php"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # Rust Extractors
  # ============================================

  defp extract_actix_routes(path), do: extract_rust_routes(path)
  defp extract_axum_routes(path), do: extract_rust_routes(path)

  defp extract_rust_routes(path) do
    find_files(path, "**/*.rs")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # #[get("/users")] or .route("/users", get(handler))
          Regex.scan(~r/#\[(get|post|put|patch|delete)\s*\(\s*"([^"]+)"/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_rust_models(path) do
    find_files(path, "**/*.rs")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # struct User { ... }
          Regex.scan(~r/(?:#\[derive[^\]]+\]\s*)?struct\s+(\w+)\s*\{([^}]+)\}/s, content)
          |> Enum.map(fn [_, name, body] ->
            fields =
              Regex.scan(~r/(\w+)\s*:\s*(\w+)/, body)
              |> Enum.map(fn [_, field_name, field_type] ->
                %{name: field_name, type: field_type}
              end)

            %{name: name, fields: fields, file: file}
          end)

        _ ->
          []
      end
    end)
    |> Enum.filter(&(length(&1.fields) > 0))
  end

  # ============================================
  # C#/.NET Extractors
  # ============================================

  defp extract_dotnet_routes(path) do
    find_files(path, "**/*.cs")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # [HttpGet("users")] or [Route("api/[controller]")]
          Regex.scan(~r/\[Http(Get|Post|Put|Patch|Delete)\s*\(\s*"?([^")\]]*)"?\s*\)\]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: "/" <> route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  defp extract_ef_models(path) do
    find_files(path, "**/*.cs")
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          # public class User { ... }
          Regex.scan(~r/public\s+class\s+(\w+)\s*(?::\s*\w+)?\s*\{([^}]+)\}/s, content)
          |> Enum.map(fn [_, name, body] ->
            fields =
              Regex.scan(~r/public\s+(\w+)\s+(\w+)\s*\{/, body)
              |> Enum.map(fn [_, type, field_name] ->
                %{name: field_name, type: type}
              end)

            %{name: name, fields: fields, file: file}
          end)

        _ ->
          []
      end
    end)
    |> Enum.filter(&(length(&1.fields) > 0))
  end

  defp extract_dotnet_controllers(path) do
    find_files(path, "**/*Controller.cs")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          name =
            case Regex.run(~r/class\s+(\w+)Controller/, content) do
              [_, n] -> n
              _ -> Path.basename(file, ".cs")
            end

          actions =
            Regex.scan(~r/public\s+(?:async\s+)?(?:Task<)?(?:IActionResult|ActionResult|\w+)>?\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, action] -> action end)
            |> Enum.uniq()

          %{name: name, actions: actions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp extract_csharp_services(path) do
    find_files(path, "**/*Service.cs") ++ find_files(path, "**/Services/*.cs")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          functions =
            Regex.scan(~r/public\s+(?:async\s+)?(?:Task<)?(?:\w+)>?\s+(\w+)\s*\(/, content)
            |> Enum.map(fn [_, func] -> func end)
            |> Enum.uniq()

          %{name: Path.basename(file, ".cs"), functions: functions, file: file}

        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  # ============================================
  # Generic/Fallback Extractors  
  # ============================================

  defp extract_generic_routes(path) do
    # Try common patterns across languages
    all_files = list_all_files(path, ["*.py", "*.js", "*.ts", "*.rb", "*.go", "*.java", "*.php", "*.rs", "*.cs", "*.ex"])

    all_files
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          Regex.scan(~r/(GET|POST|PUT|PATCH|DELETE|get|post|put|patch|delete)\s*[(\[]\s*['"]([^'"]+)['"]/, content)
          |> Enum.map(fn [_, method, route_path] ->
            %{method: String.upcase(method), path: route_path, handler: nil, file: file}
          end)

        _ ->
          []
      end
    end)
  end

  # ============================================
  # Config Readers
  # ============================================

  defp read_elixir_config(path) do
    case File.read(Path.join(path, "mix.exs")) do
      {:ok, content} ->
        app_name =
          case Regex.run(~r/app:\s*:(\w+)/, content) do
            [_, name] -> name
            _ -> "unknown"
          end

        %{app_name: app_name, type: "elixir"}

      _ ->
        %{}
    end
  end

  defp read_python_config(path) do
    pyproject = Path.join(path, "pyproject.toml")
    setup = Path.join(path, "setup.py")

    cond do
      File.exists?(pyproject) ->
        case File.read(pyproject) do
          {:ok, content} ->
            name =
              case Regex.run(~r/name\s*=\s*"([^"]+)"/, content) do
                [_, n] -> n
                _ -> "unknown"
              end

            %{app_name: name, type: "python"}

          _ ->
            %{}
        end

      File.exists?(setup) ->
        %{type: "python"}

      true ->
        %{}
    end
  end

  defp read_package_json(path) do
    case File.read(Path.join(path, "package.json")) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, json} -> json
          _ -> %{}
        end

      _ ->
        %{}
    end
  end

  defp read_ruby_config(path) do
    case File.read(Path.join(path, "config/application.rb")) do
      {:ok, content} ->
        name =
          case Regex.run(~r/module\s+(\w+)/, content) do
            [_, n] -> n
            _ -> "unknown"
          end

        %{app_name: name, type: "ruby"}

      _ ->
        %{type: "ruby"}
    end
  end

  defp read_go_config(path) do
    case File.read(Path.join(path, "go.mod")) do
      {:ok, content} ->
        name =
          case Regex.run(~r/module\s+(.+)/, content) do
            [_, n] -> n |> String.trim()
            _ -> "unknown"
          end

        %{app_name: name, type: "go"}

      _ ->
        %{}
    end
  end

  defp read_java_config(path) do
    pom = Path.join(path, "pom.xml")

    if File.exists?(pom) do
      case File.read(pom) do
        {:ok, content} ->
          name =
            case Regex.run(~r/<artifactId>([^<]+)<\/artifactId>/, content) do
              [_, n] -> n
              _ -> "unknown"
            end

          %{app_name: name, type: "java"}

        _ ->
          %{}
      end
    else
      %{type: "java"}
    end
  end

  # ============================================
  # Utility Functions
  # ============================================

  defp find_files(path, pattern) do
    Path.wildcard(Path.join(path, pattern))
    |> Enum.reject(&String.contains?(&1, "node_modules"))
    |> Enum.reject(&String.contains?(&1, "_build"))
    |> Enum.reject(&String.contains?(&1, "deps"))
    |> Enum.reject(&String.contains?(&1, "vendor"))
    |> Enum.reject(&String.contains?(&1, ".git"))
  end

  defp list_all_files(path, patterns) do
    patterns
    |> Enum.flat_map(fn pattern -> find_files(path, "**/" <> pattern) end)
    |> Enum.uniq()
  end

  defp safe_read(file) do
    case File.read(file) do
      {:ok, content} -> content
      _ -> ""
    end
  end

  defp extract_module_name(content) do
    case Regex.run(~r/defmodule\s+([\w.]+)/, content) do
      [_, name] -> name
      _ -> "Unknown"
    end
  end

  defp read_readme(path) do
    readme_files = ["README.md", "readme.md", "README", "README.txt"]

    readme_files
    |> Enum.map(&Path.join(path, &1))
    |> Enum.find(&File.exists?/1)
    |> case do
      nil -> nil
      file -> File.read!(file)
    end
  end
end
