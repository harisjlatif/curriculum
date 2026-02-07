defmodule TrainerWeb.CurriculumLive do
  use TrainerWeb, :live_view

  alias Trainer.Curriculum
  alias Trainer.Ingest.{Codebase, Notion, KnowledgeBase}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Curriculum Generator",
       step: :configure,
       codebase_path: "",
       notion_api_key: "",
       kb_path: "",
       product_name: "",
       analyzing: false,
       curriculum: nil,
       codebase_analysis: nil,
       notion_data: nil,
       kb_data: nil,
       errors: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white">
      <div class="max-w-6xl mx-auto px-6 py-12">
        <!-- Header -->
        <div class="mb-12">
          <h1 class="text-4xl font-bold mb-2">
            <span class="bg-gradient-to-r from-emerald-400 to-cyan-400 bg-clip-text text-transparent">
              Training Curriculum
            </span>
            Generator
          </h1>
          <p class="text-gray-400 text-lg">
            Analyze your codebase and documentation to generate a training course structure
          </p>
        </div>

        <!-- Progress Steps -->
        <div class="flex items-center gap-4 mb-12">
          <.step_indicator step={1} current={@step} label="Configure" />
          <div class="flex-1 h-px bg-gray-800"></div>
          <.step_indicator step={2} current={@step} label="Analyze" />
          <div class="flex-1 h-px bg-gray-800"></div>
          <.step_indicator step={3} current={@step} label="Review" />
        </div>

        <!-- Step Content -->
        <%= case @step do %>
          <% :configure -> %>
            <.configure_step
              codebase_path={@codebase_path}
              notion_api_key={@notion_api_key}
              kb_path={@kb_path}
              product_name={@product_name}
            />
          <% :analyze -> %>
            <.analyze_step
              analyzing={@analyzing}
              codebase_analysis={@codebase_analysis}
              notion_data={@notion_data}
              kb_data={@kb_data}
            />
          <% :review -> %>
            <.review_step curriculum={@curriculum} />
        <% end %>

        <!-- Errors -->
        <%= if length(@errors) > 0 do %>
          <div class="mt-6 p-4 bg-red-500/10 border border-red-500/20 rounded-xl">
            <h3 class="text-red-400 font-medium mb-2">Errors</h3>
            <%= for error <- @errors do %>
              <p class="text-red-300 text-sm"><%= error %></p>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Components

  defp step_indicator(assigns) do
    step_num =
      case assigns.step do
        1 -> :configure
        2 -> :analyze
        3 -> :review
      end

    assigns =
      assigns
      |> assign(:is_active, assigns.current == step_num)
      |> assign(:is_complete, step_order(assigns.current) > assigns.step)

    ~H"""
    <div class={[
      "flex items-center gap-3 px-4 py-2 rounded-full",
      @is_active && "bg-emerald-500/20 text-emerald-400",
      @is_complete && "bg-gray-800 text-emerald-400",
      !@is_active && !@is_complete && "bg-gray-900 text-gray-500"
    ]}>
      <div class={[
        "w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold",
        @is_active && "bg-emerald-500 text-white",
        @is_complete && "bg-emerald-500/30",
        !@is_active && !@is_complete && "bg-gray-800"
      ]}>
        <%= if @is_complete do %>
          ✓
        <% else %>
          <%= @step %>
        <% end %>
      </div>
      <span class="font-medium"><%= @label %></span>
    </div>
    """
  end

  defp step_order(:configure), do: 1
  defp step_order(:analyze), do: 2
  defp step_order(:review), do: 3

  defp configure_step(assigns) do
    ~H"""
    <form phx-submit="start_analysis" class="space-y-8">
      <!-- Product Name -->
      <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
        <h2 class="text-xl font-semibold mb-4">Product Name</h2>
        <input
          type="text"
          name="product_name"
          value={@product_name}
          placeholder="My SaaS Product"
          class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500"
        />
      </div>

      <!-- Codebase -->
      <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
        <h2 class="text-xl font-semibold mb-2">Codebase Path</h2>
        <p class="text-gray-400 text-sm mb-4">Path to your project's source code</p>
        <input
          type="text"
          name="codebase_path"
          value={@codebase_path}
          placeholder="/path/to/your/project"
          class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500"
        />
      </div>

      <!-- Notion -->
      <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
        <h2 class="text-xl font-semibold mb-2">Notion API Key <span class="text-gray-500 text-sm">(optional)</span></h2>
        <p class="text-gray-400 text-sm mb-4">Connect to your Notion workspace for internal docs</p>
        <input
          type="password"
          name="notion_api_key"
          value={@notion_api_key}
          placeholder="secret_xxxxx..."
          class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500"
        />
      </div>

      <!-- Knowledge Base -->
      <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
        <h2 class="text-xl font-semibold mb-2">Knowledge Base Path <span class="text-gray-500 text-sm">(optional)</span></h2>
        <p class="text-gray-400 text-sm mb-4">Path to markdown/HTML knowledge base articles</p>
        <input
          type="text"
          name="kb_path"
          value={@kb_path}
          placeholder="/path/to/kb/articles"
          class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:border-emerald-500"
        />
      </div>

      <!-- Submit -->
      <button
        type="submit"
        class="w-full py-4 bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-xl font-semibold text-lg hover:opacity-90 transition"
      >
        Analyze Sources →
      </button>
    </form>
    """
  end

  defp analyze_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= if @analyzing do %>
        <div class="flex items-center justify-center py-12">
          <div class="text-center">
            <div class="w-16 h-16 border-4 border-emerald-500/30 border-t-emerald-500 rounded-full animate-spin mx-auto mb-4"></div>
            <p class="text-gray-400">Analyzing sources...</p>
          </div>
        </div>
      <% else %>
        <!-- Codebase Results -->
        <%= if @codebase_analysis do %>
          <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
            <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
              <span class="text-emerald-400">✓</span> Codebase Analysis
            </h2>
            <div class="grid grid-cols-4 gap-4">
              <.stat_card label="Routes" value={length(@codebase_analysis.routes)} />
              <.stat_card label="Schemas" value={length(@codebase_analysis.schemas)} />
              <.stat_card label="LiveViews" value={length(@codebase_analysis.live_views)} />
              <.stat_card label="Contexts" value={length(@codebase_analysis.contexts)} />
            </div>
          </div>
        <% end %>

        <!-- Notion Results -->
        <%= if @notion_data do %>
          <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
            <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
              <span class="text-emerald-400">✓</span> Notion Content
            </h2>
            <div class="grid grid-cols-2 gap-4">
              <.stat_card label="Pages" value={length(@notion_data.pages)} />
              <.stat_card label="Databases" value={length(@notion_data.databases)} />
            </div>
          </div>
        <% end %>

        <!-- KB Results -->
        <%= if @kb_data do %>
          <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
            <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
              <span class="text-emerald-400">✓</span> Knowledge Base
            </h2>
            <div class="grid grid-cols-2 gap-4">
              <.stat_card label="Articles" value={length(@kb_data.articles)} />
              <.stat_card label="Categories" value={length(@kb_data.categories)} />
            </div>
          </div>
        <% end %>

        <!-- Generate Button -->
        <button
          phx-click="generate_curriculum"
          class="w-full py-4 bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-xl font-semibold text-lg hover:opacity-90 transition"
        >
          Generate Curriculum →
        </button>
      <% end %>
    </div>
    """
  end

  defp review_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <%= if @curriculum do %>
        <!-- Header -->
        <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
          <h2 class="text-2xl font-bold mb-2"><%= @curriculum.title %></h2>
          <p class="text-gray-400"><%= @curriculum.description %></p>
          <div class="flex gap-4 mt-4">
            <span class="px-3 py-1 bg-emerald-500/20 text-emerald-400 rounded-full text-sm">
              <%= @curriculum.metadata.feature_count %> features
            </span>
            <span class="px-3 py-1 bg-cyan-500/20 text-cyan-400 rounded-full text-sm">
              <%= @curriculum.metadata.topic_count %> topics
            </span>
            <%= if @curriculum.metadata.gap_count > 0 do %>
              <span class="px-3 py-1 bg-orange-500/20 text-orange-400 rounded-full text-sm">
                <%= @curriculum.metadata.gap_count %> gaps found
              </span>
            <% end %>
          </div>
        </div>

        <!-- Modules -->
        <%= for module <- Enum.sort_by(@curriculum.modules, & &1.order) do %>
          <div class="bg-gray-900/50 border border-gray-800 rounded-2xl p-6">
            <h3 class="text-xl font-semibold mb-2">
              Module <%= module.order %>: <%= module.title %>
            </h3>
            <p class="text-gray-400 text-sm mb-4"><%= module.description %></p>

            <div class="space-y-3">
              <%= for {lesson, idx} <- Enum.with_index(module.lessons, 1) do %>
                <div class="flex items-start gap-4 p-4 bg-gray-800/50 rounded-xl">
                  <div class="w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0">
                    <%= idx %>
                  </div>
                  <div class="flex-1">
                    <h4 class="font-medium"><%= lesson.title %></h4>
                    <p class="text-gray-400 text-sm"><%= lesson.description %></p>
                    <%= if length(lesson.ui_flows) > 0 do %>
                      <div class="flex flex-wrap gap-2 mt-2">
                        <%= for flow <- lesson.ui_flows do %>
                          <span class="px-2 py-1 bg-gray-700 text-gray-300 rounded text-xs font-mono">
                            <%= flow %>
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                  <div class="text-gray-500 text-sm">
                    <%= lesson.estimated_duration %> min
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <!-- Export Buttons -->
        <div class="flex gap-4">
          <button
            phx-click="export_json"
            class="flex-1 py-4 bg-gray-800 border border-gray-700 rounded-xl font-semibold hover:bg-gray-700 transition"
          >
            📄 Export JSON
          </button>
          <button
            phx-click="export_markdown"
            class="flex-1 py-4 bg-gray-800 border border-gray-700 rounded-xl font-semibold hover:bg-gray-700 transition"
          >
            📝 Export Markdown
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="bg-gray-800/50 rounded-xl p-4 text-center">
      <div class="text-3xl font-bold text-emerald-400"><%= @value %></div>
      <div class="text-gray-400 text-sm"><%= @label %></div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("start_analysis", params, socket) do
    socket =
      socket
      |> assign(:product_name, params["product_name"])
      |> assign(:codebase_path, params["codebase_path"])
      |> assign(:notion_api_key, params["notion_api_key"])
      |> assign(:kb_path, params["kb_path"])
      |> assign(:step, :analyze)
      |> assign(:analyzing, true)
      |> assign(:errors, [])

    # Start async analysis
    send(self(), :run_analysis)

    {:noreply, socket}
  end

  @impl true
  def handle_event("generate_curriculum", _params, socket) do
    curriculum =
      Curriculum.generate(
        codebase: socket.assigns.codebase_analysis,
        notion: socket.assigns.notion_data,
        knowledge_base: socket.assigns.kb_data,
        product_name: socket.assigns.product_name
      )

    {:noreply, assign(socket, step: :review, curriculum: curriculum)}
  end

  @impl true
  def handle_event("export_json", _params, socket) do
    json = Curriculum.to_json(socket.assigns.curriculum)
    # In a real app, trigger download
    IO.puts(json)
    {:noreply, socket}
  end

  @impl true
  def handle_event("export_markdown", _params, socket) do
    md = Curriculum.to_markdown(socket.assigns.curriculum)
    IO.puts(md)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:run_analysis, socket) do
    errors = []

    # Analyze codebase
    {codebase, errors} =
      if socket.assigns.codebase_path != "" do
        case Codebase.analyze(socket.assigns.codebase_path) do
          {:ok, analysis} -> {analysis, errors}
          {:error, msg} -> {nil, ["Codebase: #{msg}" | errors]}
        end
      else
        {nil, errors}
      end

    # Fetch Notion data
    {notion, errors} =
      if socket.assigns.notion_api_key != "" do
        notion = Notion.new(socket.assigns.notion_api_key)

        case Notion.fetch_pages(notion) do
          {:ok, notion_with_pages} ->
            case Notion.fetch_databases(notion_with_pages) do
              {:ok, full_notion} -> {full_notion, errors}
              {:error, msg} -> {notion_with_pages, ["Notion databases: #{msg}" | errors]}
            end

          {:error, msg} ->
            {nil, ["Notion: #{msg}" | errors]}
        end
      else
        {nil, errors}
      end

    # Load knowledge base
    {kb, errors} =
      if socket.assigns.kb_path != "" do
        case KnowledgeBase.from_directory(socket.assigns.kb_path) do
          {:ok, kb_data} -> {kb_data, errors}
          {:error, msg} -> {nil, ["Knowledge Base: #{msg}" | errors]}
        end
      else
        {nil, errors}
      end

    {:noreply,
     assign(socket,
       analyzing: false,
       codebase_analysis: codebase,
       notion_data: notion,
       kb_data: kb,
       errors: Enum.reverse(errors)
     )}
  end
end
