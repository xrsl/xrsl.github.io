---
icon: lucide/bot
date: 2026-01-07
---

# Agentic Workflows: Building a Self-Improving Application System

Most AI integrations are one-shot: send a prompt, get a response, done. But the interesting problems require **iteration** — the AI does something, you give feedback, it improves, you refine, and eventually you converge on a good result.

I built an agentic workflow for job applications that demonstrates this pattern. Here's how it works and what I learned.

## What Makes a Workflow "Agentic"?

An agentic workflow has these properties:

1. **Multi-step** — Not just prompt → response, but a sequence of actions
2. **Stateful** — Remembers context across interactions
3. **Tool-using** — Can take actions beyond generating text
4. **Human-in-the-loop** — Incorporates feedback and refines

My application system hits all four. Let me walk through it.

## The Workflow: From Job URL to Tailored Application

### Step 1: Job Ingestion (`just add`)

```bash
just add https://company.com/job-posting flash-3
```

This triggers a GitHub Actions workflow that:

1. **Fetches the job posting** — Downloads HTML, strips boilerplate
2. **Extracts structured data** — LLM parses company, title, requirements into JSON
3. **Creates a GitHub Issue** — Structured fields for tracking
4. **Posts career advice** — A second agent analyzes fit and suggests strategy

The key insight: **the issue becomes the persistent state**. All future interactions reference this issue number.

### Step 2: Career Advisor Comment

Immediately after creating the issue, a "career advisor" agent posts a comment:

```markdown
## Match Analysis

**Strong Fits:**

- Python expertise aligns with their stack
- Process engineering domain knowledge

**Gaps to Address:**

- No Kubernetes experience mentioned
- Limited data pipeline work

**Suggested Positioning:**
Focus on your simulation work as "data-intensive systems"...
```

This isn't just generated text — it's **actionable intelligence** for the next step.

### Step 3: Iterative Tailoring (`/rebuild`)

Now the human enters the loop. I review the issue, read the career advice, and trigger a build:

```
/rebuild with more emphasis on Python and less on the PhD research
```

The build workflow:

1. **Reads the issue** — Gets job posting, company, role
2. **Reads all comments** — Includes match analysis and any previous feedback
3. **Loads reference materials** — `GUIDELINES.md`, `EXPERIENCE.md` (the truth about what I've done)
4. **Loads current TOML templates** — `cv.toml`, `letter.toml`
5. **Calls the LLM** — With all context: references, templates, job posting, feedback
6. **Writes tailored TOML** — Updates `cv.toml` and `letter.toml`
7. **Builds PDFs** — Typst compiles to beautiful output
8. **Uploads to GitHub Release** — Draft release with downloadable PDFs
9. **Comments on issue** — Links to PDFs and commit

The **feedback is part of the prompt**. Each `/rebuild` incorporates everything said before.

### Step 4: Review and Refine

I download the PDFs, review them, and if something's wrong:

```
/rebuild the cover letter opening is too formal, make it more conversational
```

The cycle repeats. Each iteration is informed by all previous iterations.

### Step 5: Approval (`/approved`)

When I'm satisfied:

```
/approved
```

This triggers finalization:

1. **Creates a git tag** — `45-acme-corp-engineer-2026-01-07`
2. **Converts draft to final release** — PDFs are permanently archived
3. **Updates GitHub Project** — Status → Applied, AppliedDate → today
4. **Closes the loop** — Everything is tracked and versioned

## The Conversation History Pattern

The magic is in how conversation history flows through the system:

```python
def get_conversation_context(issue_number: str) -> str:
    """Fetch conversation history from issue comments."""
    comments = fetch_issue_comments(issue_number, github_token)
    return build_conversation_history(comments)

def build_conversation_history(comments: list) -> str:
    """Format comments as conversation for LLM context."""
    history = []
    for comment in comments:
        # Skip bot comments that are just status updates
        if is_status_comment(comment):
            continue
        history.append(f"**{comment['author']}**: {comment['body']}")
    return "\n\n".join(history)
```

Every `/rebuild` sees:

1. The original job posting
2. The career advisor's analysis
3. All human feedback comments
4. Any previous build comments

This is **multi-turn conversation at the workflow level**, not the API level.

## The Prompt Architecture

The build prompt is carefully structured:

```python
def create_build_prompt(
    job_posting: str,
    references: str,
    cv_template: dict,
    letter_template: dict,
    conversation_history: str = "",
    current_feedback: str = ""
) -> str:
    """Create the build prompt from template and context."""

    prompt_template = load_prompt('build')  # From .github/prompts/build.md

    feedback_section = ""
    if current_feedback:
        feedback_section += f"""
## Current Feedback

IMPORTANT: Address this feedback in your tailoring:

{current_feedback}
"""

    if conversation_history:
        feedback_section += f"""
## Previous Conversation History

For additional context, here is the conversation history:

{conversation_history}
"""

    return prompt_template.format(
        feedback_section=feedback_section,
        job_posting=job_posting,
        references=references,
        cv_template=json.dumps(cv_template, indent=2),
        letter_template=json.dumps(letter_template, indent=2)
    )
```

The **current feedback** is prioritized over **conversation history**. The most recent instruction matters most.

## Subagents: Career Advisor Pattern

The career advisor is a separate agent with a different persona:

```python
# From advise.py
SYSTEM_PROMPT = """You are a seasoned career advisor with expertise in:
- Resume optimization and ATS systems
- Cover letter strategy
- Gap analysis and positioning
- Industry-specific advice

Analyze the job posting and candidate profile. Provide:
1. Match analysis (strengths and gaps)
2. Positioning strategy
3. Specific recommendations for CV and letter
"""

agent = Agent(
    model,
    system_prompt=SYSTEM_PROMPT,
)
```

Different agents have different roles:

| Agent          | Purpose            | Persona             |
| -------------- | ------------------ | ------------------- |
| Job Extractor  | Parse job postings | Precise, structured |
| Career Advisor | Strategic advice   | Experienced mentor  |
| CV Tailor      | Write content      | Professional writer |

This is **specialization through prompting**, not different models.

## The Slash Command Pattern

Slash commands trigger workflows without leaving the issue:

| Command               | Action                                 |
| --------------------- | -------------------------------------- |
| `/rebuild`            | Re-tailor with feedback                |
| `/rebuild [feedback]` | Re-tailor addressing specific feedback |
| `/approved`           | Finalize and submit                    |

GitHub Actions listens for these in issue comments:

```yaml
on:
  issue_comment:
    types: [created]

jobs:
  build:
    if: |
      github.event.issue.state == 'open' &&
      github.event.sender.type != 'Bot' &&
      (contains(github.event.comment.body, '/rebuild') ||
       contains(github.event.comment.body, '/approved'))
```

The feedback is extracted from the comment body:

```bash
# Extract feedback from comment (remove /rebuild from anywhere)
FEEDBACK="${COMMENT_BODY//\/rebuild/}"
FEEDBACK="$(echo "$FEEDBACK" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
```

## Why GitHub Issues?

I could have built this with a custom UI. But GitHub Issues give me:

1. **Free persistence** — State lives in GitHub, not a database
2. **Built-in collaboration** — Others can comment
3. **Project boards** — Track status across applications
4. **Mobile access** — Review PDFs and approve from my phone
5. **Audit trail** — Every change is logged

The issue IS the workflow state. Comments ARE the conversation history.

## Lessons Learned

### 1. Feedback Loops Beat One-Shot

A mediocre first draft + 3 iterations = better than a perfect prompt once. The iteration is the product.

### 2. State Management Is Everything

Without persistent state (the GitHub Issue), every interaction would start from scratch. The issue carries context forward.

### 3. Separation of Concerns Matters

- **Career Advisor** analyzes strategy
- **CV Tailor** writes content
- **Build Pipeline** handles formatting

Each component does one thing well.

### 4. Human-in-the-Loop Is Non-Negotiable

The AI suggests, the human approves. Final review before `/approved` catches errors. Full automation would produce embarrassing mistakes.

### 5. Slash Commands Are a Great UX

Natural language in comments → triggered workflows. No separate UI, no context switching.

## The Meta Point

This workflow is itself an example of what I do: **building systems that make tedious work disappear**. The tedium of job applications — tailoring each CV, writing each letter, tracking what I sent where — is reduced to:

1. Add URL
2. Review advice
3. `/rebuild` with feedback
4. `/approved`

The AI does the grunt work. I do the judgment calls.

---

**Tools mentioned:**

- [GitHub Actions](https://github.com/features/actions) — Workflow automation
- [pydantic-ai](https://ai.pydantic.dev/) — Python AI agent framework
- [GitHub Issues](https://github.com/features/issues) — State management
- [Typst](https://typst.app/) — PDF generation
