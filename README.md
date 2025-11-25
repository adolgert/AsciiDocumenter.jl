# AsciiDocumenter.jl

A pure Julia parser for AsciiDoc documents that works with Documenter.jl.

For use with Documenter.jl, this will translate AsciiDoc documents to Markdown.
It's limited to what Markdown can express.

## Features

- **Parse AsciiDoc**: Convert AsciiDoc text into a clean Abstract Syntax Tree (AST)
- **LaTeX Output**: Generate LaTeX documents for high-quality typesetting
- **HTML Output**: Create HTML for web display with optional standalone mode
- **Extensible**: Easy to add new output backends
- **Documenter.jl Integration**: Designed to work with Julia's documentation system
- **Clean API**: Simple, intuitive interface for both parsing and conversion

## Installation

```julia
using Pkg
Pkg.add("AsciiDocumenter")
```

Or in development mode:

```julia
using Pkg
Pkg.develop(path="/path/to/asciidocumenter.jl")
```

## Quick Start

```julia
using AsciiDocumenter

# Parse AsciiDoc text
doc = parse("""
= My Document

This is a paragraph with *bold* and _italic_ text.

== Section 1

* Item 1
* Item 2
* Item 3
""")

# Convert to LaTeX
latex = convert(LaTeX, doc)

# Convert to HTML
html = convert(HTML, doc)

# Or use convenience functions
latex = asciidoc_to_latex("= Title\n\nContent")
html = asciidoc_to_html("= Title\n\nContent", standalone=true)
```

## Supported AsciiDoc Features

### Document Structure
- **Headers**: `= Title`, `== Section`, `=== Subsection` (levels 1-6)
- **Paragraphs**: Regular text blocks
- **Horizontal Rules**: `'''` or `---`

### Inline Formatting
- **Bold**: `*bold text*`
- **Italic**: `_italic text_`
- **Monospace**: `` `code` ``
- **Subscript**: `~subscript~`
- **Superscript**: `^superscript^`

### Lists
- **Unordered**: `* item` or `- item`
- **Ordered**: `. item` or `1. item`
- **Definition Lists**: `term:: definition`

### Blocks
- **Code Blocks**:
  ```
  [source,julia]
  ----
  code here
  ----
  ```
- **Block Quotes**:
  ```
  ____
  quote text
  ____
  ```

### Tables
```
|===
|Header 1|Header 2
|Cell 1|Cell 2
|===
```

### Links and References
- **Links**: `https://example.com` or `https://example.com[link text]`
- **Images**: `image:path.png[alt text]`
- **Cross References**: `<<target>>` or `<<target,display text>>`

## Usage Examples

### Basic Document

```julia
using AsciiDocumenter

text = """
= User Guide

== Installation

Follow these steps:

. Download the package
. Extract the files
. Run the installer

== Usage

Simply run:

[source,bash]
----
julia -e 'using MyPackage'
----
"""

# Parse and convert
doc = parse(text)
latex_output = convert(LaTeX, doc)
html_output = convert(HTML, doc, standalone=true)
```

### For Documenter.jl Integration

```julia
using AsciiDocumenter

# Read AsciiDoc documentation file
content = read("docs/mypage.adoc", String)

# Parse to AST
doc = parse(content)

# Convert to HTML for Documenter
html = convert(HTML, doc)
```

### Working with the AST

```julia
using AsciiDocumenter

doc = parse("= Title\n\nParagraph with *bold*")

# Access the AST structure
for block in doc.blocks
    if block isa Header
        println("Found header: level $(block.level)")
    elseif block isa Paragraph
        println("Found paragraph with $(length(block.content)) inline nodes")
    end
end
```

## API Reference

### Main Functions

- `parse(text::String) -> Document`: Parse AsciiDoc text into an AST
- `convert(::Type{LaTeX}, doc::Document) -> String`: Convert to LaTeX
- `convert(::Type{HTML}, doc::Document; standalone=false) -> String`: Convert to HTML
- `asciidoc_to_latex(text::String) -> String`: Parse and convert to LaTeX in one step
- `asciidoc_to_html(text::String; standalone=false) -> String`: Parse and convert to HTML in one step

### AST Types

**Block Nodes:**
- `Document`: Root node containing blocks
- `Header`: Section headers
- `Paragraph`: Text paragraphs
- `CodeBlock`: Source code blocks
- `BlockQuote`: Quotations
- `UnorderedList`, `OrderedList`, `DefinitionList`: List types
- `Table`: Tables with rows and cells
- `HorizontalRule`: Horizontal dividers

**Inline Nodes:**
- `Text`: Plain text
- `Bold`, `Italic`, `Monospace`: Text formatting
- `Subscript`, `Superscript`: Script formatting
- `Link`, `Image`: External references
- `CrossRef`: Internal cross-references
- `LineBreak`: Explicit line breaks

## Architecture

AsciiDocumenter.jl follows a modular design:

1. **Parser** (`src/parser.jl`): Converts AsciiDoc text to AST
2. **AST** (`src/ast.jl`): Type definitions for document structure
3. **Backends**: Convert AST to output formats
   - **LaTeX** (`src/latex.jl`): LaTeX conversion
   - **HTML** (`src/html.jl`): HTML conversion

This architecture makes it easy to:
- Add new output formats (Markdown, reStructuredText, etc.)
- Extend the parser for additional AsciiDoc features
- Process documents programmatically via the AST

## Design Philosophy

AsciiDocumenter.jl is designed with these principles:

1. **Separation of Concerns**: Parsing, AST, and output generation are independent
2. **Extensibility**: New backends can be added without modifying the parser
3. **Simplicity**: Clean API that's easy to use and understand
4. **Julia-Native**: Written in pure Julia with no external dependencies
5. **Standards-Compliant**: Based on the official AsciiDoc specification

## Testing

Run the test suite:

```julia
using Pkg
Pkg.test("AsciiDocumenter")
```

Or from the package directory:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## Examples

See the `examples/` directory for more detailed usage examples:

```bash
julia --project examples/basic_usage.jl
```

## Contributing

Contributions are welcome! Areas for improvement:

- Additional AsciiDoc features (admonitions, sidebars, etc.)
- More output backends (Markdown, reStructuredText, etc.)
- Performance optimizations
- Better error messages and diagnostics
- Compliance with the official AsciiDoc spec

## Roadmap

- [ ] Support for admonitions (NOTE, TIP, WARNING, etc.)
- [ ] Include directives
- [ ] Attribute substitution
- [ ] Conditional directives
- [ ] More table features (merged cells, alignment)
- [ ] Bibliography and footnotes
- [ ] Documenter.jl plugin for native AsciiDoc support

## License

MIT License (see LICENSE file)

## References

- [AsciiDoc Language Specification](https://gitlab.eclipse.org/eclipse/asciidoc-lang/asciidoc-lang)
- [AsciiDoctor Documentation](https://asciidoctor.org/docs/)
- [Documenter.jl](https://juliadocs.github.io/Documenter.jl/)

## Related Packages

- [CommonMark.jl](https://github.com/MichaelHatherly/CommonMark.jl): Markdown parser for Julia
- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl): Julia documentation generator
