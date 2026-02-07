# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project scaffolding

---

## [0.1.0] - 2026-02-07

### Added

#### Codebase Analyzer
- Language-agnostic codebase analysis supporting 10 languages:
  - Elixir/Phoenix
  - Python (Django, Flask, FastAPI)
  - JavaScript (Express, Next.js, React, Vue, Svelte)
  - TypeScript (Express, Next.js, React, Vue, Svelte)
  - Ruby/Rails
  - Go (Gin, Echo, Fiber)
  - Java/Spring
  - PHP/Laravel
  - Rust (Actix, Axum)
  - C#/.NET
- Auto-detection of language and framework from project files
- Extraction of:
  - Routes/endpoints
  - Models/entities (database schemas, types)
  - Controllers/handlers
  - Components/views
  - Services/business logic
  - Config files
  - README content

#### Curriculum Generator
- `Curriculum.generate/1` — Creates structured course from ingested sources
- `Curriculum.identify_gaps/2` — Finds features lacking documentation
- `Curriculum.to_markdown/1` — Export as markdown
- `Curriculum.to_json/1` — Export as JSON
- Auto-generated modules:
  - Getting Started
  - Core Features
  - Data & Entities
  - Advanced Features
  - New & Undocumented Features (gaps)

#### Ingest Layer (Scaffolded)
- `Curriculum.Ingest.Codebase` — Full implementation
- `Curriculum.Ingest.Notion` — Struct and API client scaffold
- `Curriculum.Ingest.KnowledgeBase` — Directory scanner scaffold

#### Web Interface
- Phoenix LiveView UI with multi-step wizard
- Connect codebase → Notion → Knowledge Base → Generate flow
- Curriculum preview before export

### Technical
- Phoenix 1.8 with LiveView 1.1
- Ecto 3.12 for persistence
- Tailwind CSS + DaisyUI for styling
- Requires Elixir ~> 1.15, Erlang/OTP 25+

---

## [0.0.1] - 2026-02-07

### Added
- Initial Phoenix project scaffold (as "Trainer")
- Basic project structure

### Changed
- Renamed project from "Trainer" to "Curriculum"
- Renamed all modules: `Trainer` → `Curriculum`, `TrainerWeb` → `CurriculumWeb`
- Updated app name in mix.exs to `:curriculum`

---

[Unreleased]: https://github.com/harisjlatif/curriculum/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/harisjlatif/curriculum/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/harisjlatif/curriculum/releases/tag/v0.0.1
