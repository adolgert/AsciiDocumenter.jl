# Syntax

AsciiDoc equivalents for Documenter Markdown syntax.

## Headings

```markdown
# Level 1
## Level 2
### Level 3
#### Level 4
```

```asciidoc
= Level 1
== Level 2
=== Level 3
==== Level 4
```

## Paragraphs

Paragraphs are separated by blank lines in both formats.

## Inline Formatting

| Markdown | AsciiDoc | Result |
|----------|----------|--------|
| `**bold**` | `*bold*` | **bold** |
| `*italic*` | `_italic_` | *italic* |
| `` `code` `` | `` `code` `` | `code` |
| `~~strike~~` | `[line-through]#strike#` | ~~strike~~ |

## Links

```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title")
```

```asciidoc
https://example.com[Link text]
https://example.com[Link with title, title="Title"]
```

## Images

```markdown
![Alt text](image.png)
![Alt text](image.png "Title")
```

```asciidoc
image::image.png[Alt text]
image::image.png[Alt text, title="Title"]
```

Inline images:

```asciidoc
image:icon.png[Icon]
```

## Code Blocks

````markdown
```julia
function foo()
    return 42
end
```
````

```asciidoc
[source,julia]
----
function foo()
    return 42
end
----
```

Without language:

````markdown
```
plain text
```
````

```asciidoc
----
plain text
----
```

## Lists

### Unordered

```markdown
- Item 1
- Item 2
  - Nested item
```

```asciidoc
* Item 1
* Item 2
** Nested item
```

### Ordered

```markdown
1. First
2. Second
3. Third
```

```asciidoc
. First
. Second
. Third
```

### Nested Mixed

```asciidoc
. First ordered
* Unordered under first
* Another unordered
. Second ordered
```

## Block Quotes

```markdown
> This is a quote.
> It continues here.
```

```asciidoc
____
This is a quote.
It continues here.
____
```

## Admonitions

```markdown
!!! note "Title"
    Content here.

!!! warning
    Warning content.

!!! tip "Pro Tip"
    Tip content.

!!! danger "Danger"
    Danger content.
```

```asciidoc
[NOTE]
.Title
====
Content here.
====

[WARNING]
====
Warning content.
====

[TIP]
.Pro Tip
====
Tip content.
====

[CAUTION]
.Danger
====
Danger content.
====
```

Inline admonitions (single paragraph):

```asciidoc
NOTE: This is a note.

WARNING: This is a warning.

TIP: This is a tip.
```

Supported types: `NOTE`, `TIP`, `WARNING`, `CAUTION`, `IMPORTANT`

## Tables

```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

```asciidoc
[cols="1,1,1"]
|===
| Header 1 | Header 2 | Header 3

| Cell 1
| Cell 2
| Cell 3

| Cell 4
| Cell 5
| Cell 6
|===
```

Simpler table syntax:

```asciidoc
|===
| Header 1 | Header 2

| Cell 1 | Cell 2
| Cell 3 | Cell 4
|===
```

## Horizontal Rules

```markdown
---
```

```asciidoc
'''
```

## Math

Documenter uses double backticks for inline math and `math` code blocks for display math.

```markdown
Inline: ``x^2 + y^2``

Display:
```math
\int_0^1 x^2 dx
```
```

AsciiDoc uses `stem` for math:

```asciidoc
Inline: stem:[x^2 + y^2]

Display:
[stem]
++++
\int_0^1 x^2 dx
++++
```

Alternatively, use code blocks with `math` language (converts to Documenter's format):

```asciidoc
[source,math]
----
\int_0^1 x^2 dx
----
```

## Include Directive

Include content from other files:

```asciidoc
\include::other_file.adoc[]
```

With line selection:

```asciidoc
\include::code.jl[lines=5..10]
```

## Document Attributes

Define variables at the top of the document:

```asciidoc
:version: 1.0.0
:author: Jane Doe

Version {version} by {author}.
```

## Raw Passthrough

Insert raw Markdown or HTML:

```asciidoc
++++
<!-- Raw HTML here -->
<div class="custom">Content</div>
++++
```

## Comments

```asciidoc
// This is a comment (not rendered)
```

## Escaping

Escape AsciiDoc syntax with backslash:

```asciidoc
\*not bold\*
\`not code\`
```

## Documenter-Specific Blocks

These Documenter features have no direct AsciiDoc equivalent. Use passthrough blocks:

```asciidoc
++++
```@docs
MyModule.myfunction
```
++++

++++
```@example
x = 1 + 1
```
++++

++++
```@repl
julia> 1 + 1
2
```
++++
```

Or keep API reference pages in Markdown and use AsciiDoc for narrative content.
