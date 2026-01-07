---
icon: lucide/globe
date: 2026-01-05
---

# Building Static Sites with Zensical and TOML

After years of wrestling with YAML configuration files, I discovered [Zensical](https://zensical.org/) - a static site generator that uses TOML for configuration. It's been a game-changer for my documentation workflow.

## Why TOML Over YAML?

TOML has several advantages for configuration:

- **Unambiguous** - No weird edge cases with indentation or special values
- **Strongly typed** - Clear distinction between strings, numbers, booleans, arrays
- **Readable** - Looks like INI files, familiar to most developers
- **No surprises** - `yes`, `no`, `on`, `off` are just strings, not booleans

Compare this YAML:

```yaml
# YAML - what type is this?
debug: no
version: 1.0
norway: NO # This becomes false!
```

To this TOML:

```toml
# TOML - crystal clear
debug = false
version = "1.0"
norway = "NO"  # This is a string
```

## Zensical: Material for MkDocs, but TOML-first

Zensical is built on Material for MkDocs but replaces YAML with TOML. Here's my config:

```toml
[project]
site_name = "Personal Website"
site_description = "My learning journey and technical notes"
site_author = "Your Name"

[project.theme]
language = "en"
features = [
    "navigation.instant",
    "navigation.tracking",
    "navigation.sections",
    "search.highlight",
    "content.code.copy",
]

[[project.theme.palette]]
scheme = "default"
toggle.icon = "lucide/sun"
toggle.name = "Switch to dark mode"

[[project.theme.palette]]
scheme = "slate"
toggle.icon = "lucide/moon"
toggle.name = "Switch to light mode"
```

## The Development Experience

Setting up is straightforward:

```bash
# Install with uv (fast Python package manager)
uv pip install zensical

# Start dev server
uv run zensical serve

# Build for production
uv run zensical build
```

I use a `justfile` to make this even simpler:

```justfile
serve:
    uv run zensical serve

build:
    uv run zensical build
```

Now it's just `just serve` or `just build`.

## What I Love About This Stack

### 1. Configuration as Code

The TOML config is version-controlled and reviewable. I can see exactly what changed between versions:

```diff
- site_name = "My Blog"
+ site_name = "Personal Website"

  features = [
    "navigation.instant",
+   "navigation.tracking",
  ]
```

### 2. Type Safety

TOML's type system catches errors early. If I accidentally write:

```toml
features = "navigation.instant"  # Wrong: should be array
```

The parser immediately tells me, instead of silently breaking at build time.

### 3. Modern Tooling

Zensical supports all the modern documentation features:

- **Code blocks** with syntax highlighting and annotations
- **Admonitions** for notes, warnings, tips
- **Diagrams** with Mermaid
- **Math** with MathJax
- **Dark mode** toggle
- **Instant navigation** for SPA-like experience

### 4. Fast Iteration

The dev server has hot reload. I save a Markdown file and see changes instantly in the browser. Combined with instant navigation, the editing experience is smooth.

## The Workflow

1. Write content in Markdown files in `docs/`
2. Configure features in `zensical.toml`
3. Run `just serve` to preview locally
4. Run `just build` to generate static HTML
5. Deploy to GitHub Pages, Netlify, or anywhere

## Lessons Learned

**TOML is not perfect for everything.** For deeply nested structures, it can get verbose. But for configuration files, it's excellent.

**Migration from MkDocs is easy.** Zensical is compatible with Material for MkDocs. I converted my YAML config to TOML in about 10 minutes.

**The ecosystem matters.** TOML has great tooling - parsers in every language, schema validators, formatters. This makes the whole experience better.

## Conclusion

If you're building documentation sites, give Zensical a try. The TOML configuration is refreshingly clear, and the Material for MkDocs foundation means you get a beautiful, feature-rich site out of the box.

The combination of TOML for config, Markdown for content, and modern tooling for development creates a workflow that just feels right.

---

**Tools mentioned:**

- [Zensical](https://zensical.org/) - TOML-based static site generator
- [uv](https://github.com/astral-sh/uv) - Fast Python package manager
- [Just](https://github.com/casey/just) - Command runner
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) - Beautiful documentation theme
