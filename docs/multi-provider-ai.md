---
icon: lucide/shuffle
date: 2026-01-07
---

# Multi-Provider AI: Building Model-Agnostic Agents with pydantic-ai

One of the most frustrating aspects of building with LLMs is vendor lock-in. You build a system around Claude, then Gemini releases a faster model. Or you want to use Groq for speed but Claude for quality. Switching means rewriting API calls, parsing logic, and error handling.

I solved this problem by building a model-agnostic agent layer using [pydantic-ai](https://ai.pydantic.dev/). This post explains how.

## The Problem: Every Provider Is Different

Here's what calling different LLM providers looks like without abstraction:

=== "OpenAI"

    ```python
    from openai import OpenAI

    client = OpenAI()
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}]
    )
    result = response.choices[0].message.content
    ```

=== "Anthropic"

    ```python
    import anthropic

    client = anthropic.Anthropic()
    response = client.messages.create(
        model="claude-sonnet-4",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}]
    )
    result = response.content[0].text
    ```

=== "Google Gemini"

    ```python
    import google.generativeai as genai

    model = genai.GenerativeModel("gemini-2.5-flash")
    response = model.generate_content(prompt)
    result = response.text
    ```

Three different APIs. Three different response structures. Three times the maintenance burden.

## The Solution: pydantic-ai as Abstraction Layer

[pydantic-ai](https://ai.pydantic.dev/) provides a unified interface across providers:

```python
from pydantic_ai import Agent

# Create an agent with any supported model
agent = Agent("google-gla:gemini-3-flash-preview")

# Run it the same way regardless of provider
result = agent.run_sync("Extract the company name from this job posting...")
print(result.output)
```

The magic is in the model string format: `provider:model-name`. Switch providers by changing a single string.

## My Model Normalization Layer

In my CV build system, I wanted even simpler model names. Instead of `google-gla:gemini-3-flash-preview`, I wanted `flash-3`. So I built a normalization layer:

```python
def normalize_model_name(model: str) -> str:
    """Convert friendly model names to pydantic-ai format.

    Mapping:
      gemini-*       → google-gla:gemini-*
      claude-*       → anthropic:claude-*
      openai/*       → openai:* (strip prefix, add colon)
      qwen/*         → openai:qwen/* (use OpenAI-compatible endpoint)
    """
    if model.startswith('gemini-'):
        return f"google-gla:{model}"
    elif model.startswith('claude-'):
        return f"anthropic:{model}"
    elif model.startswith('openai/'):
        # OpenAI-compatible models via Groq
        return f"openai:{model.removeprefix('openai/')}"
    elif model.startswith('qwen/'):
        # Qwen models via OpenAI-compatible endpoint
        return f"openai:{model}"
    else:
        # Already in pydantic-ai format or unknown
        return model
```

Now my build commands accept simple names:

```bash
just add https://company.com/job flash-3     # Gemini 3 Flash
just add https://company.com/job sonnet-4    # Claude Sonnet 4
just add https://company.com/job gpt-oss-120b  # Groq's open model
```

## The Full Model Menu

My system supports multiple providers and models:

| Shortcut       | Full Model Name          | Provider  | Use Case                         |
| -------------- | ------------------------ | --------- | -------------------------------- |
| `flash-3`      | `gemini-3-flash-preview` | Google    | Fast, cheap, good for extraction |
| `flash-2-5`    | `gemini-2.5-flash`       | Google    | Production flash model           |
| `pro-3`        | `gemini-3-pro-preview`   | Google    | Higher quality, slower           |
| `haiku-4`      | `claude-haiku-4`         | Anthropic | Fast Claude                      |
| `sonnet-4`     | `claude-sonnet-4`        | Anthropic | Balanced quality/speed           |
| `opus-4`       | `claude-opus-4`          | Anthropic | Maximum quality                  |
| `gpt-oss-120b` | `openai/gpt-oss-120b`    | Groq      | Open-source via Groq             |
| `qwen3-32b`    | `qwen/qwen3-32b`         | Groq      | Qwen via OpenAI-compatible       |

The workflow dispatch in GitHub Actions presents these as a dropdown:

```yaml
inputs:
  model:
    description: "LLM model to use"
    required: true
    type: choice
    options:
      # Google Gemini models
      - gemini-2.5-flash
      - gemini-3-flash-preview
      - gemini-2.5-pro
      - gemini-3-pro-preview
      # OpenAI-compatible models via Groq
      - openai/gpt-oss-120b
      - qwen/qwen3-32b
      # Anthropic Claude models
      - claude-haiku-4
      - claude-sonnet-4
      - claude-opus-4
    default: gemini-3-flash-preview
```

## Environment Variable Management

Each provider needs its own API key:

```bash
# .env file
GEMINI_API_KEY=your-gemini-key
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=your-groq-key  # Groq uses OpenAI-compatible API
```

Pydantic-ai automatically reads these based on the model prefix. No manual key routing needed.

For GitHub Actions, I set all three as repository secrets and pass them to the Python script:

```yaml
- name: Extract job details
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  run: uv run python .github/scripts/add.py
```

The script doesn't need to know which key to use — pydantic-ai handles it based on the model string.

## Structured Output: JSON Schema Enforcement

Beyond provider abstraction, pydantic-ai gives me **structured output**. Instead of parsing free-form text, I define a schema and the LLM returns data that matches:

```python
from pydantic import BaseModel
from pydantic_ai import Agent

class JobPosting(BaseModel):
    company: str
    title: str
    location: str | None
    requirements: list[str]
    nice_to_have: list[str]

agent = Agent(
    "google-gla:gemini-3-flash-preview",
    result_type=JobPosting,  # Enforce this schema
)

result = agent.run_sync(f"Extract job details from: {job_text}")
job: JobPosting = result.output  # Strongly typed!
```

No regex parsing. No JSON extraction from markdown code blocks. Just typed data.

## Why This Matters for Production

1. **A/B Testing Models** — Try Gemini vs Claude on the same task, compare results
2. **Cost Optimization** — Use cheap models for simple tasks, expensive ones for complex
3. **Fallback Chains** — If one provider is down, switch to another
4. **Speed Tuning** — Use Groq for latency-sensitive tasks, Claude for quality-sensitive

In my CV system, I use:

- **Gemini Flash** for job posting extraction (fast, cheap)
- **Gemini Pro or Claude Sonnet** for CV tailoring (needs quality)
- **Any model** for iterative feedback (user choice)

## The Abstraction Tax

There's always a cost to abstraction. With pydantic-ai:

- **Pros**: Clean code, easy switching, structured output, usage tracking
- **Cons**: Another dependency, slight overhead, may lag behind latest provider features

For my use case, the benefits far outweigh the costs. I can experiment with new models in minutes instead of hours.

## Key Takeaways

1. **Abstract early** — Don't couple your code to a specific provider
2. **Use friendly names** — Build a normalization layer for your team
3. **Structured output** — Define schemas, not prompts that ask for JSON
4. **Track usage** — pydantic-ai gives you token counts for free

The LLM landscape changes fast. Building model-agnostic from day one means you're always ready to switch.

---

**Tools mentioned:**

- [pydantic-ai](https://ai.pydantic.dev/) — Python AI agent framework
- [Groq](https://groq.com/) — Fast LLM inference
- [Google Gemini](https://ai.google.dev/) — Google's LLM API
- [Anthropic Claude](https://www.anthropic.com/) — Claude API
