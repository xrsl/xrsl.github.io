# Justfile for CV build system
# Use `just --list` to see all available commands

# Default recipe (shows help)
default:
    @just --list

serve:
    uv run zensical serve

build:
    uv run zensical build

spell:
    cspell . --config cspell.toml

prek:
    prek run --all-files
