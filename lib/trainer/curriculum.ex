defmodule Trainer.Curriculum do
  @moduledoc """
  Generates a training curriculum from ingested sources.
  Combines code analysis, documentation, Notion, and knowledge base
  to create a structured course outline.
  """

  alias Trainer.Ingest.{Codebase, Notion, KnowledgeBase}

  defstruct [
    :title,
    :description,
    :modules,
    :metadata
  ]

  @type course_module :: %{
          id: String.t(),
          title: String.t(),
          description: String.t(),
          lessons: [lesson()],
          order: integer()
        }

  @type lesson :: %{
          id: String.t(),
          title: String.t(),
          description: String.t(),
          content_sources: [String.t()],
          ui_flows: [String.t()],
          estimated_duration: integer()
        }

  @doc """
  Generates a curriculum from the provided sources.
  """
  def generate(opts \\ []) do
    codebase = Keyword.get(opts, :codebase)
    notion = Keyword.get(opts, :notion)
    kb = Keyword.get(opts, :knowledge_base)
    product_name = Keyword.get(opts, :product_name, "Product")

    # Extract features from code
    features = extract_features(codebase)

    # Extract topics from documentation
    topics = extract_topics(notion, kb)

    # Identify gaps
    gaps = identify_gaps(features, topics)

    # Build curriculum structure
    modules = build_modules(features, topics, gaps)

    %__MODULE__{
      title: "#{product_name} Training Course",
      description: "Comprehensive training covering all features and workflows",
      modules: modules,
      metadata: %{
        generated_at: DateTime.utc_now(),
        feature_count: length(features),
        topic_count: length(topics),
        gap_count: length(gaps)
      }
    }
  end

  @doc """
  Identifies features that exist in code but lack documentation/training.
  These are high-priority items for new content.
  """
  def identify_gaps(features, topics) do
    topic_keywords =
      topics
      |> Enum.flat_map(fn t ->
        t.title
        |> String.downcase()
        |> String.split(~r/\s+/)
      end)
      |> MapSet.new()

    features
    |> Enum.filter(fn feature ->
      feature_words =
        feature.name
        |> String.downcase()
        |> String.replace("_", " ")
        |> String.split(~r/\s+/)
        |> MapSet.new()

      # Feature is a gap if none of its words appear in topic keywords
      MapSet.disjoint?(feature_words, topic_keywords)
    end)
    |> Enum.map(fn feature ->
      %{
        feature: feature.name,
        type: feature.type,
        priority: :high,
        reason: "Feature exists in code but no documentation found"
      }
    end)
  end

  @doc """
  Exports the curriculum as a structured JSON document.
  """
  def to_json(%__MODULE__{} = curriculum) do
    Jason.encode!(curriculum, pretty: true)
  end

  @doc """
  Exports the curriculum as markdown for human review.
  """
  def to_markdown(%__MODULE__{} = curriculum) do
    header = """
    # #{curriculum.title}

    #{curriculum.description}

    ---

    """

    modules_md =
      curriculum.modules
      |> Enum.sort_by(& &1.order)
      |> Enum.map(&module_to_markdown/1)
      |> Enum.join("\n\n")

    header <> modules_md
  end

  # Private helpers

  defp extract_features(nil), do: []

  defp extract_features(%Codebase{} = codebase) do
    route_features =
      codebase.routes
      |> Enum.map(fn route ->
        %{
          name: path_to_feature_name(route.path),
          type: :route,
          path: route.path,
          method: route.method
        }
      end)

    schema_features =
      codebase.schemas
      |> Enum.map(fn schema ->
        %{
          name: schema.module |> String.split(".") |> List.last(),
          type: :entity,
          table: schema.table,
          fields: schema.fields
        }
      end)

    live_view_features =
      codebase.live_views
      |> Enum.map(fn lv ->
        %{
          name: lv.module |> String.split(".") |> List.last() |> String.replace("Live", ""),
          type: :live_view,
          events: lv.events
        }
      end)

    route_features ++ schema_features ++ live_view_features
  end

  defp extract_topics(notion, kb) do
    notion_topics = extract_notion_topics(notion)
    kb_topics = extract_kb_topics(kb)

    (notion_topics ++ kb_topics)
    |> Enum.uniq_by(& &1.title)
  end

  defp extract_notion_topics(nil), do: []

  defp extract_notion_topics(%Notion{pages: pages}) do
    pages
    |> Enum.map(fn page ->
      %{
        title: page["title"] || "Untitled",
        content: page["content"] || "",
        source: :notion
      }
    end)
  end

  defp extract_kb_topics(nil), do: []

  defp extract_kb_topics(%KnowledgeBase{articles: articles}) do
    articles
    |> Enum.map(fn article ->
      %{
        title: article.title,
        content: article.content,
        source: :knowledge_base,
        views: article.views
      }
    end)
  end

  defp build_modules(features, topics, gaps) do
    # Group features by type
    feature_groups = Enum.group_by(features, & &1.type)

    # Create modules for each feature type
    base_modules = [
      %{
        id: "getting-started",
        title: "Getting Started",
        description: "Introduction and initial setup",
        lessons: build_getting_started_lessons(features),
        order: 1
      },
      %{
        id: "core-features",
        title: "Core Features",
        description: "Essential features and workflows",
        lessons: build_feature_lessons(Map.get(feature_groups, :route, [])),
        order: 2
      },
      %{
        id: "data-management",
        title: "Data & Entities",
        description: "Understanding and managing your data",
        lessons: build_entity_lessons(Map.get(feature_groups, :entity, [])),
        order: 3
      },
      %{
        id: "advanced",
        title: "Advanced Features",
        description: "Power user features and customization",
        lessons: build_advanced_lessons(Map.get(feature_groups, :live_view, [])),
        order: 4
      }
    ]

    # Add gap module if there are undocumented features
    if length(gaps) > 0 do
      gap_module = %{
        id: "new-features",
        title: "New & Undocumented Features",
        description: "Features that need documentation - high priority",
        lessons: build_gap_lessons(gaps),
        order: 5
      }

      base_modules ++ [gap_module]
    else
      base_modules
    end
  end

  defp build_getting_started_lessons(features) do
    [
      %{
        id: "intro",
        title: "Introduction",
        description: "What this product does and who it's for",
        content_sources: [],
        ui_flows: ["/", "/login"],
        estimated_duration: 5
      },
      %{
        id: "first-steps",
        title: "Your First Steps",
        description: "Creating your account and initial configuration",
        content_sources: [],
        ui_flows: ["/register", "/onboarding"],
        estimated_duration: 10
      },
      %{
        id: "navigation",
        title: "Navigating the Interface",
        description: "Understanding the main UI areas",
        content_sources: [],
        ui_flows: features |> Enum.take(5) |> Enum.map(& &1[:path]) |> Enum.filter(& &1),
        estimated_duration: 10
      }
    ]
  end

  defp build_feature_lessons(routes) do
    routes
    |> Enum.group_by(fn route ->
      route.path |> String.split("/") |> Enum.at(1, "other")
    end)
    |> Enum.map(fn {group, group_routes} ->
      %{
        id: "feature-#{group}",
        title: String.capitalize(group),
        description: "Working with #{group}",
        content_sources: [],
        ui_flows: Enum.map(group_routes, & &1.path),
        estimated_duration: 15
      }
    end)
  end

  defp build_entity_lessons(entities) do
    entities
    |> Enum.map(fn entity ->
      %{
        id: "entity-#{String.downcase(entity.name)}",
        title: "Managing #{entity.name}",
        description: "Create, view, update, and delete #{entity.name} records",
        content_sources: [],
        ui_flows: ["/#{String.downcase(entity.name)}s"],
        estimated_duration: 15
      }
    end)
  end

  defp build_advanced_lessons(live_views) do
    live_views
    |> Enum.map(fn lv ->
      %{
        id: "advanced-#{String.downcase(lv.name)}",
        title: lv.name,
        description: "Advanced #{lv.name} features",
        content_sources: [],
        ui_flows: [],
        estimated_duration: 20
      }
    end)
  end

  defp build_gap_lessons(gaps) do
    gaps
    |> Enum.map(fn gap ->
      %{
        id: "gap-#{String.downcase(gap.feature)}",
        title: "#{gap.feature} (Needs Documentation)",
        description: gap.reason,
        content_sources: [],
        ui_flows: [],
        estimated_duration: 15
      }
    end)
  end

  defp module_to_markdown(module) do
    header = "## Module #{module.order}: #{module.title}\n\n#{module.description}\n"

    lessons =
      module.lessons
      |> Enum.with_index(1)
      |> Enum.map(fn {lesson, idx} ->
        flows =
          if length(lesson.ui_flows) > 0 do
            "\n   - UI Flows: #{Enum.join(lesson.ui_flows, ", ")}"
          else
            ""
          end

        "#{idx}. **#{lesson.title}** (#{lesson.estimated_duration} min)\n   #{lesson.description}#{flows}"
      end)
      |> Enum.join("\n\n")

    header <> "\n" <> lessons
  end

  defp path_to_feature_name(path) do
    path
    |> String.trim("/")
    |> String.split("/")
    |> Enum.take(2)
    |> Enum.join(" ")
    |> String.replace(~r/[_-]/, " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
