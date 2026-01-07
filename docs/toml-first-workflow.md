---
icon: lucide/workflow
date: 2026-01-07
---

# The TOML-First Workflow: How I Built an AI-Powered CV Build System

Over the holidays, I've built something I never expected: a full-stack job application system where TOML is the canonical truth. Not YAML, not JSON, not a database — TOML. This post explains the _why_ behind every decision, the problems I was actually solving, and the unexpected benefits that emerged.

## The Problem I Was Actually Solving

Let me be honest: I didn't set out to build a "TOML-first workflow." I set out to solve a very specific pain point: **applying to jobs is tedious, error-prone, and soul-crushing**.

Every application needs:

1. A tailored CV emphasizing relevant experience
2. A cover letter that doesn't sound generic
3. Version tracking (what did I send to Company X?)
4. The ability to iterate quickly on feedback

My first attempts used Word documents. Then LaTeX. Both failed for the same reason: **content and presentation were coupled**. Changing a bullet point meant fighting with margins. Updating a date meant fixing page breaks.

I needed to separate concerns completely.

## Why TOML Won

I evaluated several formats for the "source of truth" layer:

### Why Not YAML?

YAML looks clean but hides landmines:

```yaml
# Norway problem - is this a country or false?
norway: NO  # → false

# Type coercion surprises
version: 1.0  # Is this a string or float?
port: 8080    # What about this?

# Multiple ways to write the same thing
items: [1, 2, 3]
items:
  - 1
  - 2
  - 3
```

When an AI model writes YAML, these ambiguities cause real bugs. I've had cover letters fail to build because an LLM wrote `yes` instead of `"yes"`.

### Why Not JSON?

JSON is unambiguous, but:

- No comments (I need `#:schema` directives for editor support)
- Verbose for humans to edit
- Trailing comma errors are common
- No multi-line strings without escaping

### Why TOML?

TOML eliminated entire categories of errors:

```toml
#:schema ../schema/schema.json

[cv]
name = "John Doe, PhD"
headline = "Senior Software Engineer"
email = "john.doe@example.com"

[[cv.experience]]
company = "Acme Corp"
position = "Senior Software Engineer"
start_date = "2022-11"
end_date = "present"
highlights = [
  "Built a unified data platform for analytics",
  "Architected simulation engine for *5x* faster designs",
]
```

Key benefits:

1. **Explicit types** — Strings are quoted, dates are ISO 8601, no surprises
2. **Comments** — I can document schema directives and explain choices
3. **Human-editable** — I can fix AI output by hand
4. **Tooling** — `tombi format`, `taplo`, schema validation all work beautifully

## The Architecture That Emerged

What started as "TOML instead of YAML" became a full system with multiple components working together. Here's the data flow:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              JOB APPLICATION FLOW                           │
└─────────────────────────────────────────────────────────────────────────────┘

   Job Posting URL                    GitHub Issue                  AI Analysis
         │                                 │                              │
         ▼                                 ▼                              ▼
    ┌─────────┐    LLM extracts     ┌───────────┐    Career advisor   ┌───────────┐
    │   URL   │ ──────────────────► │  Issue #N │ ─────────────────► │  Comment   │
    └─────────┘   structured data   │  (tracks  │   posts advice     │  with gap  │
                                    │  company, │                    │  analysis  │
         ▲                          │  role,    │                    └───────────┘
         │                          │  posting) │
    just add                        └───────────┘
    https://...                            │
                                          │ /rebuild command
                                          ▼
         ┌────────────────────────────────────────────────────────────────────┐
         │                        BUILD PIPELINE                              │
         └────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
    │ reference/   │     │ schema.cue   │     │ src/cv.toml  │
    │ GUIDELINES.md│     │ (source of   │     │ src/letter.  │
    │ EXPERIENCE.md│     │  truth for   │     │     toml     │
    └──────────────┘     │   types)     │     └──────────────┘
           │             └──────────────┘            │
           │                    │                    │
           └────────────┬───────┴────────────────────┘
                        ▼
                 ┌─────────────┐
                 │   LLM API   │  (Gemini, Claude, Groq)
                 │ pydantic-ai │
                 └─────────────┘
                        │
                        │ Returns JSON matching schema
                        ▼
                 ┌─────────────┐     ┌─────────────┐
                 │  tomli-w    │────►│  cv.toml    │
                 │  (writes    │     │  letter.toml│
                 │   TOML)     │     │  (tailored) │
                 └─────────────┘     └─────────────┘
                                            │
                                            │ just build
                                            ▼
         ┌────────────────────────────────────────────────────────────────────┐
         │                        TYPST PIPELINE                              │
         └────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
    │   cv.toml    │────►│   cv.json    │────►│   cv.typ     │
    │              │     │ (Typst can't │     │  (template)  │
    └──────────────┘     │  read TOML)  │     └──────────────┘
                         └──────────────┘            │
                                                     ▼
                                              ┌──────────────┐
                                              │   cv.pdf     │
                                              │  letter.pdf  │
                                              │ combined.pdf │
                                              └──────────────┘
```

### Layer 1: CUE as Schema Source of Truth

The first insight was that **the schema should be defined once and generate everything else**. I use [CUE](https://cuelang.org/) for this:

```cue
// schema/schema.cue
#Entry: {
    name?:        string
    title?:       string
    company?:     string
    position?:    string
    summary?:     string
    start_date?:  #Date
    end_date?:    #ExactDate
    highlights?: [...string]
    ...
}

#CV: {
    name?:     string
    headline?: string
    keywords: [...string]
    experience?: [...#Entry]
    education?: [...#Entry]
    skills?: [...#SkillEntry]
    ...
}
```

From this single source, I generate:

1. **`schema.json`** — For editor autocompletion and AI tool use
2. **Validation** — `cue vet` validates TOML against the schema
3. **Key ordering** — A custom script extracts field order from CUE and adds `x-tombi-table-keys-order` to JSON schema

The key ordering script (`schema/order-schema.sh`) was born from frustration. `tombi format` kept reordering my fields alphabetically, destroying the logical grouping I wanted (name before email before phone). The solution:

```bash
# Extract field order from CUE type definitions
get_field_order() {
    local type_name="$1"
    awk "/${type_name}: \\{/,/^}/" "$SCHEMA_CUE" | \
        grep -E '^[[:space:]]+[a-zA-Z_]' | \
        sed -E 's/^[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\??.*/\1/' | \
        jq -R -s 'split("\n") | map(select(length > 0))'
}
```

Now `just schema` generates a JSON schema that tells `tombi` to respect my field order. Change the order in `schema.cue`, and the formatter follows.

### Layer 2: GitHub Issues as Job Tracking

Each job application is a GitHub Issue. This sounds weird until you realize:

- **Built-in project board** — Track status (New, Applied, Interview, etc.)
- **Custom fields** — AppliedDate, Company, Role
- **Comments for iteration** — `/rebuild with more emphasis on Python` triggers a new build
- **Branch per application** — `45-acme-corp-senior-engineer`

The workflow starts with `just add https://company.com/job`:

```bash
# Triggers GitHub workflow that:
# 1. Fetches job posting HTML
# 2. Sends to LLM (pydantic-ai) to extract structured data
# 3. Creates GitHub issue with parsed fields
# 4. Posts career advisor comment analyzing fit
```

The AI extracts company, title, location, requirements — all from the raw HTML. No manual data entry.

### Layer 3: AI-Powered Tailoring

This is where TOML really shines. The build script:

1. Loads `reference/GUIDELINES.md` and `reference/EXPERIENCE.md` (the truth about what I've actually done)
2. Loads current `cv.toml` and `letter.toml` as JSON
3. Sends everything to an LLM with the job posting
4. LLM returns structured JSON matching `schema.json`
5. `tomli-w` converts JSON back to TOML

Why this matters:

- **No TOML syntax errors** — AI returns JSON, Python library handles TOML serialization
- **Schema enforcement** — pydantic-ai validates against the schema
- **Multi-provider support** — Gemini, Claude, Groq (OpenAI-compatible) all work identically

The `build.py` script abstracts away model differences:

```python
def normalize_model_name(model: str) -> str:
    """Convert model names to pydantic-ai format."""
    if model.startswith('gemini-'):
        return f"google-gla:{model}"
    elif model.startswith('claude-'):
        return f"anthropic:{model}"
    elif model.startswith('openai/'):
        return f"openai:{model.removeprefix('openai/')}"
    # ...
```

I can switch between `gemini-3-flash-preview` and `claude-sonnet-4` with a single flag.

### Layer 4: Typst for Beautiful Output

[Typst](https://typst.app/) replaced LaTeX for PDF generation. It's faster, has better error messages, and the syntax is more intuitive.

But there's a problem: **Typst can't read TOML directly**. So the pipeline is:

```
cv.toml → cv.json → cv.typ → cv.pdf
```

The `just build` command handles this:

```just
# Convert cv.toml to cv.json (Typst can't read TOML directly)
json-cv: validate-cv
    uv run python -c "import tomllib, json; json.dump(tomllib.load(open('src/cv.toml', 'rb')), open('src/cv.json', 'w'), indent=2)"
```

The Typst template (`cv.typ`) then reads the JSON:

```typst
#let cv-data = json("../src/cv.json")

// Text replacement for special characters
#let replace-text(value) = {
  if type(value) == str {
    value
      .replace("Munchen", "München")
      .replace("Zurich", "Zürich")
  }
  // ...
}

#let cv = replace-text(cv-data.cv)
```

I even handle character replacements (Munchen → München) in the template layer, keeping the TOML clean for AI editing.

### Layer 5: Git Worktrees for Parallel Applications

When applying to multiple jobs simultaneously, I use git worktrees:

```bash
just init 51  # Creates ../cv-51 worktree with branch 51-company-role
just init 52  # Creates ../cv-52 worktree with branch 52-other-company
```

Each worktree has its own `cv.toml` and `letter.toml`, tailored for that specific application. The `main` branch holds the master template.

The `run` command even launches Claude agents in parallel:

```bash
just run 51 52 53  # Opens Claude in each worktree simultaneously
```

## The Justfile: Command Runner as Glue

The `justfile` orchestrates everything. It's the interface between all these components:

```just
# Schema management
schema: schema-ordered         # Full pipeline: CUE → JSON → ordered
validate: validate-cv validate-letter

# Build pipeline
build: build-cv build-letter combine
build-cv: json-cv
    typst compile --root . --font-path fonts src/cv.typ out/cv.pdf

# Development
watch:
    watchexec -w src/cv.toml -w src/cv.typ -w src/letter.toml -- just build

# Application lifecycle
add url model="flash-3":       # Create issue from job posting
init issue_number editor="none":  # Create worktree for application
applied:                       # Mark as submitted, tag, push, update project
```

The `applied` command encapsulates the entire submission workflow:

```bash
# Commits with --no-verify (skip linting)
# Creates tag: 51-company-role-2026-01-07
# Pushes branch and tag
# Updates GitHub Project: Status → Applied, AppliedDate → today
```

## What I Learned

### 1. The Schema Is Everything

Having `schema.cue` as the single source of truth eliminated so many bugs. When I add a new field, it flows through to:

- JSON schema (editor autocomplete)
- Validation (catches errors early)
- AI prompts (LLM knows the structure)
- Typst templates (data always matches)

### 2. AI Works Better with Structure

Asking an LLM to write TOML directly causes syntax errors. Asking it to return JSON that matches a schema? Works almost perfectly. The `pydantic-ai` library even supports tool use for schema enforcement.

### 3. TOML Is the Right Abstraction

TOML sits in the sweet spot between:

- **Too structured** (JSON) — hard to read and edit
- **Too flexible** (YAML) — too many ways to be wrong

For configuration and structured data that humans need to touch, TOML is ideal.

### 4. Pre-commit Hooks Catch What You Forget

My `.pre-commit-config.yaml` includes:

- `cue vet` validation
- `tombi format` formatting
- `cspell` spell checking
- Auto-regeneration of `schema.json` when CUE changes

The system catches errors before they hit CI.

## The Unexpected Benefits

1. **AI can fix its own mistakes** — When the LLM output is wrong, I comment `/rebuild with feedback` and it tries again
2. **Version control works** — Every change is a git commit, every application is a branch
3. **Templates evolve** — Improving `cv.typ` improves all future PDFs
4. **Provider switching** — Gemini too expensive? Switch to Groq. Claude too slow? Try Gemini Flash.

## Is This Overkill?

Probably. For most people, a Word document works fine.

But if you:

- Apply to many jobs with tailored materials
- Want to track what you sent where
- Like automating tedious tasks
- Want AI to help without hallucinating experience

Then a TOML-first workflow might be worth the investment.

---

**Tools mentioned:**

- [TOML](https://toml.io/) — Configuration language
- [CUE](https://cuelang.org/) — Configuration language with types
- [Typst](https://typst.app/) — Modern typesetting system
- [Just](https://github.com/casey/just) — Command runner
- [pydantic-ai](https://ai.pydantic.dev/) — Python AI agent framework
- [tombi](https://github.com/tombi-toml/tombi) — TOML formatter
- [uv](https://github.com/astral-sh/uv) — Fast Python package manager
- [watchexec](https://github.com/watchexec/watchexec) — File watcher
