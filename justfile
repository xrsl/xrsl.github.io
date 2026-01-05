# Justfile for CV build system
# Use `just --list` to see all available commands

# Default recipe (shows help)
default:
    @just --list

serve:
    uv run mkdocs serve

build:
    uv run mkdocs build    
