---
date: 2025-10-28
authors:
  - xrsl
categories:
  - Python
  - Programming
---

# Useful Python Tips

A collection of Python tips and tricks I've found helpful in my daily work.

<!-- more -->

## 1. Use f-strings for Formatting

F-strings are more readable and faster than older formatting methods:

```python
name = "World"
# Good
print(f"Hello, {name}!")

# Old way
print("Hello, %s!" % name)
print("Hello, {}!".format(name))
```

## 2. Dictionary Comprehensions

Create dictionaries concisely:

```python
# Square numbers
squares = {x: x**2 for x in range(5)}
# {0: 0, 1: 1, 2: 4, 3: 9, 4: 16}
```

## 3. Enumerate for Index and Value

Don't use `range(len(list))`:

```python
items = ['a', 'b', 'c']

# Good
for i, item in enumerate(items):
    print(f"{i}: {item}")

# Bad
for i in range(len(items)):
    print(f"{i}: {items[i]}")
```

## 4. Use pathlib for File Paths

`pathlib` is cleaner than `os.path`:

```python
from pathlib import Path

path = Path("docs") / "blog" / "posts"
if path.exists():
    print(f"Found {len(list(path.glob('*.md')))} posts")
```

More tips coming soon!
