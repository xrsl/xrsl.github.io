---
icon: lucide/workflow
date: 2026-01-05
---

# Embracing a TOML-First Workflow

Over the past few months, I've shifted most of my configuration files from YAML and JSON to TOML. This post explains why and shares the patterns I've discovered.

## The TOML Philosophy

TOML stands for "Tom's Obvious, Minimal Language." The key word is **obvious**. When you read a TOML file, there should be no ambiguity about what it means.

### The YAML Problem

YAML has too many ways to express the same thing:

```yaml
# All of these are equivalent
key: value
key: "value"
key: 'value'

# Arrays can be written multiple ways
items: [1, 2, 3]
items:
  - 1
  - 2
  - 3

# Booleans are a minefield
debug: yes      # true
debug: Yes      # true
debug: YES      # true
debug: true     # true
debug: True     # true
debug: on       # true
norway: NO      # false (!)
```

This flexibility creates confusion. Is `1.0` a string or a number? Is `no` a boolean or a string?

### The TOML Solution

TOML is explicit:

```toml
# Strings are quoted
key = "value"

# Numbers are not
port = 8080
version = 1.0

# Booleans are lowercase
debug = true
production = false

# Arrays are always bracketed
items = [1, 2, 3]

# Dates are ISO 8601
created = 2026-01-05T08:30:00Z
```

No ambiguity. No surprises.

## Where I Use TOML

### 1. Project Configuration

My projects now use `pyproject.toml` for Python configuration:

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"

dependencies = [
    "httpx>=0.27.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "ruff>=0.1.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N"]
ignore = ["E501"]
```

Everything in one file, strongly typed, easy to read.

### 2. Build Systems

I use TOML for data files that feed into build systems. My CV is `cv.toml`, my site config is `zensical.toml`, even my spell-checker uses `cspell.toml`:

```toml
# cspell.toml
version = "0.2"
language = "en"

words = [
    "zensical",
    "typst",
    "toml",
]

ignorePaths = [
    "node_modules",
    ".venv",
    "*.min.js",
]
```

### 3. Task Runners

I pair TOML configs with [Just](https://github.com/casey/just) for task running:

```justfile
# Build CV
cv:
    typst compile cv.typ cv.pdf

# Build site
site:
    uv run zensical build

# Deploy everything
deploy: cv site
    gh-pages deploy site/
```

The TOML holds the data, Just orchestrates the commands.

## Patterns I've Learned

### Pattern 1: Separate Data from Logic

TOML is for **data**, not **logic**. Don't try to make it do computation:

```toml
# Good: data
[database]
host = "localhost"
port = 5432
name = "mydb"

# Bad: trying to do logic in TOML
# (use a proper language for this)
```

### Pattern 2: Use Tables for Grouping

TOML tables create clear namespaces:

```toml
[development]
debug = true
log_level = "DEBUG"

[production]
debug = false
log_level = "WARNING"
```

### Pattern 3: Arrays of Tables for Repeated Structures

For lists of similar items, use array of tables:

```toml
[[servers]]
name = "alpha"
ip = "10.0.0.1"

[[servers]]
name = "beta"
ip = "10.0.0.2"
```

This is cleaner than nested arrays.

### Pattern 4: Validate with Schemas

Use schema validation tools to catch errors early. For Python, I use `pydantic`:

```python
from pydantic import BaseModel
import tomllib

class Config(BaseModel):
    debug: bool
    port: int
    host: str

with open("config.toml", "rb") as f:
    data = tomllib.load(f)
    config = Config(**data)  # Validates types
```

## The Tooling Ecosystem

TOML has excellent tooling:

- **Parsers**: Available in every major language
- **Formatters**: `taplo` for formatting TOML files
- **Validators**: Schema validation libraries
- **Editors**: Great LSP support in VS Code, Neovim, etc.

## When NOT to Use TOML

TOML isn't perfect for everything:

- **Deep nesting** - TOML gets verbose with deeply nested structures
- **Dynamic data** - Use JSON for API responses
- **Markup** - Use Markdown or HTML for content
- **Complex logic** - Use a real programming language

## The Migration Path

Moving from YAML to TOML:

1. **Start with new projects** - Use TOML from day one
2. **Convert small files first** - Start with simple configs
3. **Use converters** - Tools exist to convert YAML → TOML
4. **Update tooling** - Ensure your tools support TOML
5. **Document the change** - Help your team understand why

## Conclusion

TOML won't solve all your problems, but for configuration files, it's a significant improvement over YAML. The explicitness and type safety prevent entire classes of bugs.

My workflow is now:

- **TOML** for configuration and structured data
- **Markdown** for content and documentation
- **Just** for task automation
- **Git** for version control

This stack is simple, explicit, and maintainable. No magic, no surprises, just clear data and clear processes.

If you're starting a new project, give TOML a try. Your future self (and your teammates) will appreciate the clarity.

---

**Tools mentioned:**

- [TOML](https://toml.io/) - Configuration language
- [Just](https://github.com/casey/just) - Command runner
- [taplo](https://taplo.tamasfe.dev/) - TOML formatter and LSP
- [Pydantic](https://docs.pydantic.dev/) - Python data validation
- [uv](https://github.com/astral-sh/uv) - Fast Python package manager
