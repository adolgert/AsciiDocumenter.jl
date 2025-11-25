# AsciiDoc.jl

Convert AsciiDoc to Markdown for use with [Documenter.jl](https://documenter.juliadocs.org/).

## Quick Start

```julia
using Pkg
Pkg.add("AsciiDoc")
```

```julia
using AsciiDoc

# Parse AsciiDoc
doc = AsciiDoc.parse("""
= My Document

This is *bold* text.

See link:@ref[My Function].
""")

# Convert to Markdown string for Documenter
md = AsciiDoc.to_markdown(doc)
```

## Documentation

- [Guide](guide.md) — How to configure `make.jl` and project structure.
- [Syntax](syntax.md) — How to write AsciiDoc that maps to Documenter features (math, cross-refs, @docs).

## Supported Features

| Feature | AsciiDoc Syntax | Documenter Result |
|---------|-----------------|-------------------|
| **Cross-Refs** | `link:@ref[Target]` | `[Target](@ref)` |
| **Math** | `stem:[x^2]` | `$x^2$` |
| **Docstrings** | `[source,@docs]` | ```` ```@docs ```` |
| **Admonitions** | `[NOTE]` | `!!! note` |
| **Code** | `[source,julia]` | ```` ```julia ```` |
| **Standard** | Headers, Lists, Tables | Standard Markdown |

## License

MIT