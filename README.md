# Curriculum

AI-powered training documentation generator that analyzes codebases and existing documentation to create structured course curricula.

## Overview

Curriculum ingests multiple sources of truth about your product:

- **Codebase** — Routes, models, controllers, components, services
- **Notion** — Pages, databases, wikis
- **Knowledge Base** — Markdown docs, HTML articles, help center content

Then it:
1. Extracts features and UI flows from code
2. Maps existing documentation to features
3. Identifies **gaps** — features that lack documentation
4. Generates a structured training curriculum with modules and lessons

## Features

### 🔍 Language-Agnostic Codebase Analysis

Automatically detects and parses:

| Language | Frameworks |
|----------|------------|
| Elixir | Phoenix |
| Python | Django, Flask, FastAPI |
| JavaScript | Express, Next.js, React, Vue, Svelte |
| TypeScript | Express, Next.js, React, Vue, Svelte |
| Ruby | Rails |
| Go | Gin, Echo, Fiber |
| Java | Spring |
| PHP | Laravel |
| Rust | Actix, Axum |
| C# | .NET |

### 📚 Documentation Ingestion

- **Notion API** — Fetch pages and databases
- **Knowledge Base** — Scan directories of markdown/HTML docs
- **README files** — Auto-extracted for context

### 🎯 Gap Analysis

Identifies features in your code that don't have corresponding documentation — high-priority items for new training content.

### 📋 Curriculum Generation

Outputs structured course with:
- Modules (Getting Started, Core Features, Advanced, etc.)
- Lessons with estimated duration
- UI flows to record
- Content sources to reference

Export as **JSON** or **Markdown**.

## Installation

```bash
# Clone the repo
git clone https://github.com/harisjlatif/curriculum.git
cd curriculum

# Install dependencies
mix deps.get

# Setup database
mix ecto.create

# Start the server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000)

## Usage

### Via Web UI

1. **Connect Codebase** — Enter path to your project
2. **Connect Notion** (optional) — Add API key
3. **Add Knowledge Base** (optional) — Point to docs directory
4. **Generate** — Get your curriculum

### Via API

```elixir
# Analyze a codebase
{:ok, codebase} = Curriculum.Ingest.Codebase.analyze("/path/to/project")

# Check detected stack
codebase.language  # :python
codebase.framework # :django

# See extracted features
codebase.routes      # [%{method: "GET", path: "/users", ...}]
codebase.models      # [%{name: "User", fields: [...]}]
codebase.controllers # [%{name: "UserController", actions: [...]}]

# Generate curriculum
curriculum = Curriculum.Curriculum.generate(
  codebase: codebase,
  product_name: "My App"
)

# Export
Curriculum.Curriculum.to_markdown(curriculum)
Curriculum.Curriculum.to_json(curriculum)
```

## Architecture

```
lib/
├── curriculum/
│   ├── curriculum.ex       # Core curriculum generator
│   └── ingest/
│       ├── codebase.ex     # Language-agnostic code analyzer
│       ├── notion.ex       # Notion API client
│       └── knowledge_base.ex # Doc directory scanner
└── curriculum_web/
    ├── live/
    │   └── curriculum_live.ex  # Main UI
    └── ...
```

## Requirements

- Elixir ~> 1.15
- Erlang/OTP 25+
- PostgreSQL (for persistence)

## Roadmap

- [ ] GitHub repo ingestion (clone & analyze)
- [ ] OpenAPI/Swagger spec parsing
- [ ] AI-powered lesson content generation
- [ ] Video recording integration
- [ ] LMS export (SCORM, xAPI)

## License

MIT

## Contributing

PRs welcome! Please open an issue first to discuss major changes.
