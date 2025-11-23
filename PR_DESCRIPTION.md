# AsciiDoc.jl - Complete AsciiDoc Parser for Julia

This PR implements a comprehensive AsciiDoc parser package for Julia with multiple output backends, designed for integration with Documenter.jl and general-purpose document conversion.

## Overview

AsciiDoc.jl provides a pure Julia implementation of an AsciiDoc parser with a clean, modular architecture that separates parsing from output generation.

## Features Implemented

### Core Parser
- **AST-based architecture** - Clean Abstract Syntax Tree representation
- **Document structure** - Headers (levels 1-6), paragraphs, horizontal rules
- **Inline formatting** - Bold, italic, monospace, subscript, superscript
- **Lists** - Unordered, ordered, and definition lists
- **Code blocks** - With optional language syntax highlighting
- **Tables** - Basic table support
- **Block quotes** - Quotation blocks with attribution
- **Links and references** - URLs, images, and cross-references

### Output Backends

#### LaTeX Backend
- Section commands (\section, \subsection, etc.)
- Text formatting (\textbf, \textit, \texttt)
- Lists (itemize, enumerate, description)
- Code blocks (verbatim, listings)
- Tables, block quotes, links, images
- Proper LaTeX character escaping

#### HTML Backend
- Semantic HTML5 tags
- CSS styling (optional standalone mode)
- Syntax highlighting support
- Responsive tables and lists
- Proper HTML entity escaping

### API

```julia
using AsciiDoc

# Parse AsciiDoc text
doc = parse("= Title\n\nContent with *bold* text")

# Convert to different formats
latex = convert(LaTeX, doc)
html = convert(HTML, doc, standalone=true)

# Convenience functions
latex = asciidoc_to_latex("= Title\n\nContent")
html = asciidoc_to_html("= Title\n\nContent")
```

## Package Structure

```
asciidoc.jl/
├── src/
│   ├── AsciiDoc.jl      # Main module
│   ├── ast.jl           # AST node type definitions
│   ├── parser.jl        # Parser implementation
│   ├── latex.jl         # LaTeX backend
│   └── html.jl          # HTML backend
├── test/
│   ├── runtests.jl      # Main test runner
│   ├── spec_tests.jl    # Specification-driven tests
│   ├── compliance_report.jl  # Report generator
│   └── README.md        # Test documentation
├── examples/
│   ├── basic_usage.jl   # Usage examples
│   └── simple_test.jl   # Quick verification
├── SPEC_COMPLIANCE.md   # Compliance tracking
└── README.md            # Package documentation
```

## Specification Compliance

Current implementation covers ~40-50% of the full AsciiDoc specification, with strong coverage of core features:

### ✅ Implemented
- Document structure (headers, paragraphs, horizontal rules)
- All basic inline formatting
- Lists (unordered, ordered, definition)
- Code blocks with language syntax
- Tables (basic)
- Block quotes
- Links, images, and cross-references
- Both LaTeX and HTML backends

### 📋 High Priority for Future Implementation
- Admonitions (NOTE, TIP, WARNING, etc.)
- Document attributes (`:name: value`, `{attribute}` references)
- Include directive (`include::file.adoc[]`)
- Comments (`//` and `////`)
- Advanced table features (alignment, cell spanning)

See `SPEC_COMPLIANCE.md` for detailed tracking.

## Testing Framework

Includes a novel **specification-driven test DSL** that maps directly to the official AsciiDoc specification:

```julia
@spec_section "Bold Text" "https://docs.asciidoctor.org/asciidoc/latest/text/bold/" begin
    @test_feature "basic bold" "*bold*" begin
        doc = parse("This is *bold* text")
        assert_contains_node_type(doc, Bold)
    end
end
```

Benefits:
- Direct traceability to spec documentation
- Syntax examples in tests serve as documentation
- Automated compliance reporting
- Clear visibility of implemented vs missing features

## Design Philosophy

1. **Separation of Concerns** - Parsing, AST, and output generation are independent
2. **Extensibility** - Easy to add new output backends
3. **Simplicity** - Clean API that's easy to use and understand
4. **Julia-Native** - Pure Julia with no external dependencies
5. **Standards-Compliant** - Based on the official AsciiDoc specification

## Documentation

- **README.md** - Comprehensive usage guide and API reference
- **SPEC_COMPLIANCE.md** - Detailed compliance tracking with checkboxes
- **test/README.md** - Testing framework documentation
- **examples/** - Multiple usage examples

## Compatibility

- Julia 1.10+ (current LTS)
- No external dependencies
- Designed for Documenter.jl integration

## Future Enhancements

The modular architecture makes it straightforward to add:
- Additional AsciiDoc features (admonitions, attributes, etc.)
- More output backends (Markdown, reStructuredText, etc.)
- Documenter.jl plugin for native AsciiDoc support
- Performance optimizations
- Enhanced error messages and diagnostics

## References

- [AsciiDoc Language Documentation](https://docs.asciidoctor.org/asciidoc/latest/)
- [AsciiDoc Language Project at Eclipse](https://projects.eclipse.org/projects/asciidoc.asciidoc-lang)
- [AsciiDoc Specification](https://gitlab.eclipse.org/eclipse/asciidoc-lang/asciidoc-lang)

---

This provides a solid foundation for AsciiDoc parsing in Julia, ready for real-world use and further development.
