"""
# AsciiDoc.jl

A parser for AsciiDoc documents in Julia.

This package provides:
- Parsing of AsciiDoc text into an Abstract Syntax Tree (AST)
- Conversion to LaTeX for document generation
- Conversion to HTML for web display
- A clean API for integration with tools like Documenter.jl

## Basic Usage

```julia
using AsciiDoc

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
using AsciiDoc

# Read AsciiDoc file
content = read("mydoc.adoc", String)

# Parse and convert to desired format
doc = parse(content)
html = convert(HTML, doc)
```
"""
module AsciiDoc

# Include submodules
include("ast.jl")
include("parser.jl")
include("latex.jl")
include("html.jl")

# Re-export main types and functions
using .AST
using .Parser
using .LaTeX
using .HTML

export Document, Header, Paragraph, CodeBlock, BlockQuote,
       UnorderedList, OrderedList, DefinitionList,
       Table, HorizontalRule,
       Text, Bold, Italic, Monospace, Link, Image, CrossRef,
       parse, convert

# Main API

"""
    parse(text::String) -> Document

Parse AsciiDoc text into a Document AST.

# Example

```julia
doc = parse(\"\"\"
= My Title

This is a paragraph.
\"\"\")
```
"""
Base.parse(::Type{Document}, text::String) = Parser.parse_asciidoc(text)
parse(text::String) = Base.parse(Document, text)

"""
    convert(::Type{LaTeX}, doc::Document) -> String

Convert a Document AST to LaTeX.

# Example

```julia
doc = parse("= Title\\n\\nParagraph")
latex = convert(LaTeX, doc)
```
"""
Base.convert(::Type{LaTeX}, doc::Document) = LaTeX.to_latex(doc)

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
    HTML.to_html(doc, standalone=standalone)

# Convenience functions

"""
    asciidoc_to_latex(text::String) -> String

Parse AsciiDoc text and convert directly to LaTeX.

# Example

```julia
latex = asciidoc_to_latex(\"\"\"
= My Document

Some *bold* text.
\"\"\")
```
"""
function asciidoc_to_latex(text::String)
    doc = parse(text)
    return convert(LaTeX, doc)
end

"""
    asciidoc_to_html(text::String; standalone=false) -> String

Parse AsciiDoc text and convert directly to HTML.

# Example

```julia
html = asciidoc_to_html(\"\"\"
= My Document

Some *bold* text.
\"\"\", standalone=true)
```
"""
function asciidoc_to_html(text::String; standalone::Bool=false)
    doc = parse(text)
    return convert(HTML, doc, standalone=standalone)
end

export asciidoc_to_latex, asciidoc_to_html

end # module
