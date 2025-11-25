"""
# AsciiDocumenter.jl

A parser for AsciiDoc documents in Julia.

This package provides:
- Parsing of AsciiDoc text into an Abstract Syntax Tree (AST)
- Conversion to LaTeX for document generation
- Conversion to HTML for web display
- A clean API for integration with tools like Documenter.jl

## Basic Usage

```julia
using AsciiDocumenter

# Parse AsciiDoc text
doc = parse(\"\"\"
= My Document

This is a *bold* paragraph with some _italic_ text.

== Section 1

Here's a list:

* Item 1
* Item 2
* Item 3
\"\"\")

# Convert to LaTeX
latex_output = convert(LaTeX, doc)

# Convert to HTML
html_output = convert(HTML, doc)
```

## For Documenter Integration

```julia
using AsciiDocumenter

# Read AsciiDoc file
content = read("mydoc.adoc", String)

# Parse and convert to desired format
doc = parse(content)
html = convert(HTML, doc)
```

## API Notes

This package extends `Base.parse` and `Base.convert` to provide a natural Julia interface:
- `parse(text)` - Parse AsciiDoc text into a Document AST
- `convert(LaTeX, doc)` - Convert Document to LaTeX string
- `convert(HTML, doc)` - Convert Document to HTML string

## Known Limitations

This parser intentionally implements a practical subset of full AsciiDoc:

**Lists:**
- Definition lists support single-line descriptions only
- List nesting uses simplified rules (marker depth for unordered, dot count for ordered)

**Attributes:**
- Block attribute syntax requires strict ordering: positional arguments before key=value pairs
- Limited set of attributes is recognized (primarily for code blocks, tables, and quotes)

**Tables:**
- First row is treated as header by default (can be overridden with explicit markers)
- Cell spanning is supported via `2+` and `.2+` syntax
- Complex table features (multi-line cells, nested blocks) are not supported

**Inline Formatting:**
- Formatting markers (*bold*, _italic_) must not start/end with whitespace
- Nested formatting is supported but may have edge cases
- Math rendering requires MathJax/KaTeX for HTML output

These limitations are by design to maintain a simple, maintainable implementation
while supporting the most common AsciiDoc use cases.
"""
module AsciiDocumenter

include("ast.jl")
include("parser.jl")
include("latex.jl")
include("html.jl")
include("integration.jl")

export Document, Header, Paragraph, CodeBlock, BlockQuote,
       UnorderedList, OrderedList, DefinitionList,
       Table, HorizontalRule,
       Text, Bold, Italic, Monospace, Link, Image, CrossRef,
       parse, convert, LaTeX, HTML, to_markdownast, to_markdown

struct LaTeXBackend end
struct HTMLBackend end

const LaTeX = LaTeXBackend
const HTML = HTMLBackend

"""
    Base.parse(::Type{Document}, text::AbstractString; base_path::AbstractString=pwd()) -> Document

Parse AsciiDoc text into a Document AST.

This extends `Base.parse` to support the `Document` type.

# Arguments
- `text`: The AsciiDoc source text
- `base_path`: Directory for resolving include directives (default: current directory)

# Example

```julia
doc = Base.parse(Document, \"\"\"
= My Title

This is a paragraph.
\"\"\")
```
"""
Base.parse(::Type{Document}, text::AbstractString; base_path::AbstractString=pwd()) =
    parse_asciidoc(String(text); base_path=String(base_path))

"""
    parse(text::AbstractString; base_path::AbstractString=pwd()) -> Document

Parse AsciiDoc text into a Document AST.

This is a convenience wrapper around `Base.parse(Document, text)`.

# Arguments
- `text`: The AsciiDoc source text
- `base_path`: Directory for resolving include directives (default: current directory)

# Example

```julia
doc = parse(\"\"\"
= My Title

This is a paragraph.
\"\"\")

# With include support
doc = parse("include::other.adoc[]"; base_path="/path/to/docs")
```
"""
parse(text::AbstractString; base_path::AbstractString=pwd()) = Base.parse(Document, text; base_path=base_path)

"""
    convert(::Type{LaTeX}, doc::Document) -> String

Convert a Document AST to LaTeX.

# Example

```julia
doc = parse("= Title\\n\\nParagraph")
latex = convert(LaTeX, doc)
```
"""
Base.convert(::Type{LaTeX}, doc::Document) = to_latex(doc)

"""
    convert(::Type{HTML}, doc::Document; standalone=false) -> String

Convert a Document AST to HTML.

Set `standalone=true` to generate a complete HTML document with CSS.

# Example

```julia
doc = parse("= Title\\n\\nParagraph")
html = convert(HTML, doc)
html_standalone = convert(HTML, doc, standalone=true)
```
"""
Base.convert(::Type{HTML}, doc::Document; standalone::Bool=false) =
    to_html(doc, standalone=standalone)

"""
    asciidoc_to_latex(text::AbstractString) -> String

Parse AsciiDoc text and convert directly to LaTeX.

# Example

```julia
latex = asciidoc_to_latex(\"\"\"
= My Document

Some *bold* text.
\"\"\")
```
"""
function asciidoc_to_latex(text::AbstractString)
    doc = parse(text)
    return convert(LaTeX, doc)
end

"""
    asciidoc_to_html(text::AbstractString; standalone=false) -> String

Parse AsciiDoc text and convert directly to HTML.

# Example

```julia
html = asciidoc_to_html(\"\"\"
= My Document

Some *bold* text.
\"\"\", standalone=true)
```
"""
function asciidoc_to_html(text::AbstractString; standalone::Bool=false)
    doc = parse(text)
    return convert(HTML, doc, standalone=standalone)
end

export asciidoc_to_latex, asciidoc_to_html

end # module
