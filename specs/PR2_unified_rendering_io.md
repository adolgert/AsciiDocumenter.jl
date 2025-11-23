# PR Proposal: Unified I/O Rendering Architecture

## 1. Objective
Standardize the rendering pipeline (`src/html.jl`, `src/latex.jl`) to strictly use `IO` streams, eliminating inconsistent string allocations and enabling streaming output for large documents.

## 2. Problem Statement
The current rendering logic is inconsistent:
- Some methods return `String` (allocating memory).
- Some methods create their own `IOBuffer` internally.
- Large documents require holding the entire output string in memory before writing to a file.
- Inconsistent patterns: `result = "$cmd{$text}"` mixed with `write(io, ...)`

## 3. Proposed Solution

### 3.1. The `to_format` Protocol
Refactor all backend methods to follow this signature:

```julia
# Core method (does the work, returns Nothing)
to_html(io::IO, node::Node) -> Nothing

# Convenience wrapper (creates the buffer, returns String)
function to_html(node::Node)
    io = IOBuffer()
    to_html(io, node)
    return String(take!(io))
end
```

### 3.2. Refactoring `src/html.jl`
1.  Update the root `to_html(doc::Document)` to take an `io` argument.
2.  Update every node handler (`Header`, `Paragraph`, `Bold`, etc.) to accept `io`.
3.  Replace string interpolation (`return "<p>$content</p>"`) with stream writing:
    ```julia
    function to_html(io::IO, node::Paragraph)
        print(io, "<p>")
        for child in node.content
            to_html(io, child)
        end
        print(io, "</p>")
    end
    ```

## 4. Benefits
- **Memory Efficiency:** Streaming allows writing huge documents to disk without loading the generated HTML/LaTeX entirely into RAM.
- **Composability:** Easier to embed `AsciiDoc.jl` output into other web servers or pipelines (e.g., `HTTP.jl` streams).
- **Consistency:** A single pattern for all renderers makes it easier for contributors to add new backends (e.g., Markdown, PDF).

## 5. Success Criteria
- All `to_html` methods accept an `IO` argument.
- No method in the rendering path performs `String` concatenation or interpolation for the final output.
- Public API remains backward compatible (via convenience wrappers).
