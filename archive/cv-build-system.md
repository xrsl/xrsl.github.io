---
icon: lucide/file-text
date: 2026-01-05
---

# Building a CV with TOML and Typst

Recently, I built a modern CV generation system that uses TOML for data and Typst for typesetting. This approach separates content from presentation and makes maintaining a professional CV surprisingly pleasant.

## The Problem with Traditional CVs

Most people maintain their CVs in Word documents or design tools like Figma. This creates several issues:

- **Version control is painful** - Binary formats don't play well with git
- **Content and design are coupled** - Changing a job title means fighting with layout
- **No single source of truth** - Different versions drift apart over time
- **Hard to automate** - Can't easily generate different formats or variants

## The Solution: TOML + Typst

My approach uses three key technologies:

### 1. TOML for Data

TOML is perfect for structured CV data. It's human-readable and has strong typing:

```toml
[personal]
name = "Your Name"
email = "you@example.com"
location = "City, Country"

[[experience]]
title = "Senior Engineer"
company = "Tech Corp"
start_date = "2023-01"
end_date = "present"
highlights = [
    "Led team of 5 engineers",
    "Reduced deployment time by 60%",
]
```

### 2. Typst for Typesetting

[Typst](https://typst.app/) is a modern alternative to LaTeX. It's faster, has better error messages, and produces beautiful PDFs:

```typst
#let cv(data) = {
  set text(font: "Inter", size: 11pt)

  // Header
  align(center)[
    #text(size: 24pt, weight: "bold")[#data.personal.name]
    #data.personal.email | #data.personal.location
  ]

  // Experience
  for job in data.experience [
    *#job.title* at #job.company #h(1fr) #job.start_date -- #job.end_date
    #for highlight in job.highlights [
      - #highlight
    ]
  ]
}
```

### 3. Automation with Just

I use [Just](https://github.com/casey/just) as a command runner (like Make, but better):

```justfile
# Build CV to PDF
build:
    typst compile cv.typ cv.pdf

# Watch for changes and rebuild
watch:
    typst watch cv.typ cv.pdf

# Generate web version
web:
    typst compile --format html cv.typ cv.html
```

## Benefits

This system gives me:

- **Version control** - Everything is plain text, perfect for git
- **Multiple outputs** - PDF, HTML, or even Markdown from the same source
- **Easy updates** - Change data in TOML, design updates automatically
- **Variants** - Generate different CVs for different roles by filtering the TOML
- **Validation** - TOML parsers catch errors early

## The Workflow

1. Update `cv.toml` with new experience or skills
2. Run `just build` to generate the PDF
3. Commit both the TOML and PDF to git
4. Deploy to GitHub Pages or wherever

## Future Improvements

I'm planning to add:

- **Schema validation** with a TOML schema checker
- **Multiple templates** for different industries
- **Automated deployment** via GitHub Actions
- **Web preview** with live editing

## Conclusion

This TOML-based approach transforms CV maintenance from a dreaded chore into a simple data update. The separation of concerns means I can focus on content while Typst handles the beautiful typography.

If you maintain a CV, consider trying this approach. Your future self will thank you when you need to update it in a hurry.

---

**Tools mentioned:**

- [Typst](https://typst.app/) - Modern typesetting system
- [TOML](https://toml.io/) - Configuration language
- [Just](https://github.com/casey/just) - Command runner
