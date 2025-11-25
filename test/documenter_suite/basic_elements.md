# Basic Elements

## Headings

This document tests basic Markdown elements that Documenter supports.

### Third Level

#### Fourth Level

## Paragraphs and Formatting

This is a simple paragraph with **bold text** and *italic text*.
You can also have `inline code` within paragraphs.

Here is another paragraph with ***bold italic*** text combined.

## Code Blocks

Here's a simple code block:

```julia
function greet(name)
    println("Hello, $name!")
end

greet("World")
```

And one without a language:

```
Plain text code block
with multiple lines
```

## Lists

### Unordered Lists

- First item
- Second item
- Third item with **bold**

### Ordered Lists

1. First step
2. Second step
3. Third step

### Nested Lists

- Outer item 1
  - Inner item A
  - Inner item B
- Outer item 2
  - Inner item C

## Links and Images

Visit [Julia](https://julialang.org) for more information.

Here's an inline link to [Documenter.jl](https://documenter.juliadocs.org).

![Julia Logo](assets/logo.png)

## Block Quotes

> This is a block quote.
> It can span multiple lines.

> Another quote with **formatting** inside.

## Horizontal Rules

Above the rule.

---

Below the rule.

## Tables

| Column A | Column B | Column C |
|----------|----------|----------|
| A1       | B1       | C1       |
| A2       | B2       | C2       |
| A3       | B3       | C3       |

## Admonitions

!!! note "A Note"
    This is a note admonition.
    It has multiple lines.

!!! warning "Be Careful"
    This is a warning.

!!! tip
    A tip without a custom title.
