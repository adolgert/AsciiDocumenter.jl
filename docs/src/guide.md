# Guide

This guide assumes familiarity with [Documenter.jl](https://documenter.juliadocs.org/). It covers how to write documentation in AsciiDoc instead of Markdown.

## Setup

Add to your `docs/Project.toml`:

```toml
[deps]
Documenter = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
AsciiDoc = "..."
```

## Converting AsciiDoc to Markdown

In your `docs/make.jl`, convert `.adoc` files before calling `makedocs`:

```julia
using Documenter
using AsciiDoc
using MyPackage

# Convert AsciiDoc files to Markdown
for file in readdir("docs/src"; join=true)
    if endswith(file, ".adoc")
        adoc_content = read(file, String)
        md_content = AsciiDoc.to_markdown(AsciiDoc.parse(adoc_content))
        md_file = replace(file, ".adoc" => ".md")
        write(md_file, md_content)
    end
end

makedocs(
    sitename = "MyPackage.jl",
    modules = [MyPackage],
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
    ]
)
```

Alternatively, convert files recursively:

```julia
function convert_adoc_files(dir)
    for (root, dirs, files) in walkdir(dir)
        for file in files
            if endswith(file, ".adoc")
                path = joinpath(root, file)
                content = read(path, String)
                md = AsciiDoc.to_markdown(AsciiDoc.parse(content))
                write(replace(path, ".adoc" => ".md"), md)
            end
        end
    end
end

convert_adoc_files("docs/src")
```

## File Structure

Standard Documenter structure works with AsciiDoc files:

```
docs/
├── make.jl
├── Project.toml
└── src/
    ├── index.adoc
    ├── guide.adoc
    └── api.adoc
```

## Building

```bash
julia --project=docs docs/make.jl
```

The converted Markdown files are generated alongside the AsciiDoc sources before Documenter processes them.

## Docstrings

AsciiDoc does not have a direct equivalent to Documenter's `@docs` blocks. Keep docstring inclusion in separate Markdown files, or write a custom preprocessor that inserts `@docs` blocks during conversion.

For a hybrid approach, use Markdown for API reference pages (with `@docs` blocks) and AsciiDoc for narrative documentation.

## Cross-References

Documenter's `@ref` syntax is Markdown-specific. For cross-references:

**Option 1**: Use standard AsciiDoc links and let them convert to Markdown links:

```asciidoc
See the <<installation>> section.
```

**Option 2**: Use raw Markdown in your AsciiDoc where needed:

```asciidoc
++++
See [`MyFunction`](@ref) for details.
++++
```

## Navigation

The `pages` argument in `makedocs` controls navigation. Ensure your converted `.md` filenames match the `pages` configuration.
