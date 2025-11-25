# AsciiDoc.jl

Convert AsciiDoc to Markdown for use with [Documenter.jl](https://documenter.juliadocs.org/).

## Installation

```julia
using Pkg
Pkg.add("AsciiDoc")
```

## Quick Start

```julia
using AsciiDoc

# Parse AsciiDoc
doc = AsciiDoc.parse("""
= My Document

== Introduction

This is *bold* and _italic_ text.

[source,julia]
----
println("Hello")
----
""")

# Convert to Markdown string
md = AsciiDoc.to_markdown(doc)
println(md)
# Output:
# # My Document
#
# ## Introduction
#
# This is **bold** and *italic* text.
#
# ```julia
# println("Hello")
# ```

# Or convert to MarkdownAST (for Documenter internals)
ast = AsciiDoc.to_markdownast(doc)
```

## Documentation

- [Guide](guide.md) — Setup and integration with Documenter.jl
- [Syntax](syntax.md) — AsciiDoc syntax reference

## Basic Usage

### Parse and Convert

```julia
using AsciiDoc

# From string
md = AsciiDoc.to_markdown(AsciiDoc.parse(adoc_string))

# From file
content = read("document.adoc", String)
md = AsciiDoc.to_markdown(AsciiDoc.parse(content))
write("document.md", md)
```

### With Documenter.jl

In `docs/make.jl`:

```julia
using Documenter
using AsciiDoc

# Convert all .adoc files to .md
for file in readdir("docs/src"; join=true)
    if endswith(file, ".adoc")
        content = read(file, String)
        md = AsciiDoc.to_markdown(AsciiDoc.parse(content))
        write(replace(file, ".adoc" => ".md"), md)
    end
end

makedocs(...)
```

## Supported Features

| Feature | Status |
|---------|--------|
| Headings | ✓ |
| Paragraphs | ✓ |
| Bold, italic, code | ✓ |
| Links | ✓ |
| Images | ✓ |
| Code blocks | ✓ |
| Lists (ordered, unordered) | ✓ |
| Tables | ✓ |
| Admonitions | ✓ |
| Block quotes | ✓ |
| Include directive | ✓ |
| Document attributes | ✓ |

## License

MIT
