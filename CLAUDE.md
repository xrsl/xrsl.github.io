# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal static site built with MkDocs Material. The site is hosted on GitHub Pages and uses uv for Python dependency management.

## Development Commands

**Setup dependencies:**
```bash
uv sync
```

**Run development server:**
```bash
uv run mkdocs serve
```

**Build site:**
```bash
uv run mkdocs build
```

## Architecture

- **Site generator:** MkDocs with Material theme
- **Output directory:** `public/` (configured via `site_dir` in mkdocs.yml)
- **Content directory:** `docs/` - all markdown content lives here
- **Configuration:** `mkdocs.yml` contains site configuration, theme settings, and navigation structure
- **Python version:** Pinned to 3.12.* (see pyproject.toml)

## Key Configuration

- The site builds to `public/` instead of the default `site/` directory
- Material theme configured with:
  - Auto, light, and dark mode support
  - Navigation features (instant loading, progress, sections, etc.)
  - Code highlighting and copy functionality
  - Search with suggestions
- Markdown extensions enabled: tables, footnotes, pymdownx extensions, admonition, tabs
- Plugins: include-markdown, search, autorefs

## Content Structure

- `docs/index.md` - Homepage
- `docs/about.md` - About page
- `docs/blog/` - Blog posts directory
- Navigation is explicitly defined in `mkdocs.yml` under the `nav` section
