---
icon: lucide/wrench
---

# Amazing Rust Tools for Non-Rust Developers

Rust is slowly and steadily taking over the tools space. It has been [the most admired programming language](https://survey.stackoverflow.co/2025/technology#2-programming-scripting-and-markup-languages) among developers for several years and for a good reason: the blazingly fast speed.

Here are some of my favorites.

## :material-folder-search: File & Directory Operations

| Tool                                                      | Replaces | Why It's Better                                                     |
| --------------------------------------------------------- | -------- | ------------------------------------------------------------------- |
| **[bat](https://github.com/sharkdp/bat)**                 | `cat`    | Syntax highlighting, git integration, line numbers                  |
| **[ripgrep (rg)](https://github.com/BurntSushi/ripgrep)** | `grep`   | 10x faster, respects `.gitignore`, smarter defaults                 |
| **[fd](https://github.com/sharkdp/fd)**                   | `find`   | Intuitive syntax, colorized output, ignores hidden files by default |
| **[eza](https://github.com/eza-community/eza)**           | `ls`     | Icons, git status, tree view, beautiful colors                      |

## :material-console: Modern Shell Experience

| Tool                                                | What It Does                                                               |
| --------------------------------------------------- | -------------------------------------------------------------------------- |
| **[starship](https://starship.rs/)**                | Cross-shell prompt that's fast and infinitely customizable                 |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | Smarter `cd` — learns your habits and jumps to directories by partial name |
| **[atuin](https://github.com/atuinsh/atuin)**       | Magical shell history with sync, search, and stats                         |

## :material-code-braces: Developer Essentials

| Tool                                                  | What It Does                                        |
| ----------------------------------------------------- | --------------------------------------------------- |
| **[just](https://github.com/casey/just)**             | A better `make` for running project commands        |
| **[delta](https://github.com/dandavison/delta)**      | Beautiful git diffs with syntax highlighting        |
| **[hyperfine](https://github.com/sharkdp/hyperfine)** | Benchmarking CLI commands with statistical analysis |
| **[tokei](https://github.com/XAMPPRocky/tokei)**      | Count lines of code, fast                           |

## :material-language-python: Python Tooling (by Astral)

The [Astral](https://astral.sh/) team is rewriting Python's tooling in Rust. If you write Python, these are game-changers:

| Tool                                          | Replaces                   | Why It's Better                                                           |
| --------------------------------------------- | -------------------------- | ------------------------------------------------------------------------- |
| **[uv](https://github.com/astral-sh/uv)**     | `pip`, `venv`, `poetry`    | 10-100x faster package installs, unified tool for packages + environments |
| **[ruff](https://github.com/astral-sh/ruff)** | `flake8`, `black`, `isort` | Linter + formatter in one, 100x faster than alternatives                  |
| **[ty](https://github.com/astral-sh/ty)**     | `mypy`, `pyright`          | Type checker that's 10-100x faster, with built-in LSP                     |

## :material-pencil: Editors

| Tool                                            | What It Does                                                                |
| ----------------------------------------------- | --------------------------------------------------------------------------- |
| **[fresh](https://github.com/nicholasq/fresh)** | Terminal editor with GUI-like UX — opens 2GB files in 600ms using <40MB RAM |

## :material-cog: Config & Git Hooks

| Tool                                             | Replaces     | Why It's Better                                                         |
| ------------------------------------------------ | ------------ | ----------------------------------------------------------------------- |
| **[tombi](https://github.com/tombi-toml/tombi)** | `taplo`      | TOML language server, formatter, and linter with JSON Schema validation |
| **[prek](https://github.com/j178/prek)**         | `pre-commit` | 10x faster hook installation, single binary, monorepo support           |

## :material-file-document-edit: Data & Text Processing

| Tool                                                        | Replaces | Why It's Better                              |
| ----------------------------------------------------------- | -------- | -------------------------------------------- |
| **[jq](https://github.com/jqlang/jq)** _(not Rust, but...)_ | —        | JSON processor (mention for completeness)    |
| **[jaq](https://github.com/01mf02/jaq)**                    | `jq`     | Rust clone of jq, faster and more correct    |
| **[sd](https://github.com/chmln/sd)**                       | `sed`    | Intuitive find-and-replace, no escaping hell |
| **[xsv](https://github.com/BurntSushi/xsv)**                | —        | Lightning-fast CSV toolkit                   |

## :material-apple: Quick Install (macOS)

```bash
brew install ripgrep fd eza bat starship zoxide just delta hyperfine sd uv ruff
```

## :material-package-variant: Quick Install (via uv)

If you already have `uv`, you can install the Python-oriented tools:

```bash
uv tool install ruff ty prek
```

Most Rust tools distribute standalone binaries — no runtime dependencies, no virtual environments, just download and run.

---

> **Pro tip:** Alias these in your shell config for muscle memory:
>
> ```bash
> alias ls='eza'
> alias cat='bat'
> alias find='fd'
> alias grep='rg'
> ```
