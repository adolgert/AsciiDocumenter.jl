# AsciiDoc Syntax for Documenter.jl

This guide covers how to write AsciiDoc that compiles correctly to Documenter.jl's expected format.

## Documenter Features

### Cross-References (`@ref`)

Use the `link:` macro to create Documenter-style cross-references. This macro allows any target string, enabling `@ref` syntax.

```asciidoc
// Link to a docstring
See the link:@ref[MyFunction] documentation.

// Link to a section in another file
See link:@ref[Section Name] for details.

// Explicit @ref syntax
See link:@ref#my-id[Custom Link Text].

// Relative links to other files
See the link:../guide.md[User Guide].
```

### Math

AsciiDoc.jl supports `stem` (Science, Technology, Engineering, Math) blocks, which map directly to Documenter's math support.

**Inline Math:**

```asciidoc
The formula is stem:[E = mc^2].
```

**Display Math:**

```asciidoc
[stem]
++++
\int_0^\infty x^2 dx
++++
```

### Documenter Blocks (@docs, @example, etc.)

To use Documenter's "magic" blocks like `@docs`, `@example`, or `@repl`, use a source block with the language prefixed by `@`.

**@docs (Docstrings):**

```asciidoc
[source,@docs]
----
MyPackage.my_function
----
```

**@example (Executed Code):**

```asciidoc
[source,@example]
----
x = 10
y = 20
println(x + y)
----
```

**@repl (REPL Simulation):**

```asciidoc
[source,@repl]
----
julia> 1 + 1
2
----
```

## Standard AsciiDoc Syntax

### Headings

```asciidoc
= Document Title (H1)
== Section Level 2
=== Section Level 3
==== Section Level 4
```

### Text Formatting

```asciidoc
*Bold text*
_Italic text_
`Monospace/Code`
#Subscript# (Coming soon)
^Superscript^ (Coming soon)
```

### Lists

**Unordered:**

```asciidoc
* Item 1
* Item 2
** Nested Item
```

**Ordered:**

```asciidoc
. Step 1
. Step 2
.. Nested Step
```

**Definition Lists:**

```asciidoc
Term 1:: Definition text
Term 2:: 
+
Multi-paragraph definition.
```

### Code Blocks

Standard code blocks map to Markdown code fences.

```asciidoc
[source,julia]
----
function foo()
    return "bar"
end
----
```

### Admonitions

Maps standard AsciiDoc admonitions to Documenter's `!!!` blocks.

```asciidoc
[NOTE]
.Optional Title
====
This is a note block.
====

WARNING: This is a single-line warning.
```

Supported types: `NOTE`, `TIP`, `WARNING`, `IMPORTANT`, `CAUTION`.

### Tables

Standard AsciiDoc tables are supported.

```asciidoc
|===
| Header 1 | Header 2

| Cell A1  | Cell A2
| Cell B1  | Cell B2
|===
```

### Images

```asciidoc
image::path/to/image.png[Alt Text]
```

### Raw Passthrough

To inject raw HTML or content that should bypass processing:

```asciidoc
++++
<div class="custom-alert">
  Raw HTML content
</div>
++++
```