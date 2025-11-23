# Julia Idiomaticity Review

A critical review of AsciiDoc.jl code asking: "Is this how you would write this in Julia?"

## 🔴 Major Issues - Top-Level Design

### 1. Module Structure - Over-engineered?

**Current:**
```julia
module AsciiDoc
    include("ast.jl")  # defines module AST
    include("parser.jl")  # defines module Parser
    include("latex.jl")  # defines module LaTeX
    include("html.jl")  # defines module HTML

    using .AST
    using .Parser
    # ...
end
```

**Issue:** Nested modules add complexity without clear benefit. Julia packages typically use a flatter structure.

**More Julian:**
```julia
module AsciiDoc
    # All types and functions in one namespace
    include("ast.jl")     # just type definitions
    include("parser.jl")  # just functions
    include("latex.jl")   # just functions
    include("html.jl")    # just functions
end
```

**Why:** Simpler imports, clearer namespace, easier to extend. Only use submodules when you need separate namespaces or lazy loading.

### 2. API Design - Should Use Julia Base Methods

**Current:**
```julia
parse(text::String) = Parser.parse_asciidoc(text)
Base.convert(::Type{LaTeX}, doc::Document) = LaTeX.to_latex(doc)
```

**Better:**
```julia
# parse is already extending Base, good!
parse(::Type{Document}, text::String) -> Document

# But for conversion, Julia has a pattern:
# Define callable types (functors) for backends
struct LaTeXBackend end
const LaTeX = LaTeXBackend()

(::LaTeXBackend)(doc::Document) = to_latex(doc)

# Usage: latex_output = LaTeX(doc)
```

Or even simpler:
```julia
# Just use functions
to_latex(doc::Document) -> String
to_html(doc::Document; standalone=false) -> String
```

## 🟡 Medium Issues - Implementation Patterns

### 3. Parser State - Should Be an Iterator

**Current:**
```julia
mutable struct ParserState
    lines::Vector{String}
    pos::Int
    attributes::Dict{String,String}
end

function next_line!(state::ParserState)
    if state.pos <= length(state.lines)
        line = state.lines[state.pos]
        state.pos += 1
        return line
    end
    return nothing
end
```

**More Julian - Use Iterator Protocol:**
```julia
struct LineIterator
    lines::Vector{String}
end

Base.iterate(iter::LineIterator) = isempty(iter.lines) ? nothing : (iter.lines[1], 2)
Base.iterate(iter::LineIterator, state) = state > length(iter.lines) ? nothing : (iter.lines[state], state + 1)

# Usage:
for line in LineIterator(lines)
    # ...
end

# Or with stateful iterator:
lines = stateful(eachline(io))
line = popfirst!(lines)  # consume one
peek(lines)  # look ahead without consuming
```

**Why:** More composable, works with all iterator tools, clearer intent.

### 4. Inline Parsing - VERY Un-Julian!

**Current (BAD):**
```julia
function parse_inline(text::String)
    nodes = InlineNode[]
    i = 1
    current_text = ""

    while i <= length(text)
        char = text[i]

        if char == '*' && i < length(text) && text[i+1] != ' '
            # Manual index manipulation...
            close_idx = findnext('*', text, i+1)
            # ...
            i = close_idx + 1
            continue
        end

        current_text *= char  # STRING CONCATENATION IN LOOP!
        i += 1
    end
end
```

**Issues:**
- ❌ Manual index tracking (`i = 1`, `i += 1`)
- ❌ Character-by-character iteration
- ❌ String concatenation in loop (allocates new string each time!)
- ❌ Should use `eachmatch` with regex

**More Julian:**
```julia
function parse_inline(text::String)
    nodes = InlineNode[]

    # Use regex to split on formatting markers
    # This is a simplified example - real implementation would be more sophisticated
    pattern = r"(\*[^\*]+\*|_[^_]+_|`[^`]+`|~[^~]+~|\^[^\^]+\^|https?://\S+)"

    last_end = 1
    for m in eachmatch(pattern, text)
        # Add text before match
        if m.offset > last_end
            push!(nodes, Text(text[last_end:m.offset-1]))
        end

        # Parse the match
        push!(nodes, parse_inline_match(m.match))
        last_end = m.offset + length(m.match)
    end

    # Add remaining text
    if last_end <= length(text)
        push!(nodes, Text(text[last_end:end]))
    end

    nodes
end
```

Or use a proper parsing library like `Automa.jl` or build a PEG parser.

### 5. Constant Regexes - Should Be Defined Once

**Current:**
```julia
function try_parse_header(state)
    m = match(r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$", line)
    # ...
end
```

**Better:**
```julia
const HEADER_REGEX = r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$"
const CODE_BLOCK_START = r"^\[source,\s*(\w+)\]$"
const LIST_ITEM_REGEX = r"^\s*[\*\-]\s+(.+)$"

function try_parse_header(state)
    m = match(HEADER_REGEX, line)
    # ...
end
```

**Why:** Compiles regex once, clearer intent, easier to maintain.

### 6. String Building - Use IOBuffer

**Current:**
```julia
function to_latex(node::UnorderedList)
    io = IOBuffer()
    write(io, "\\begin{itemize}\n")
    # ...
    return String(take!(io))
end
```

**This is actually good!** But inconsistent - some functions use string concatenation:

```julia
result = "$cmd{$text}"
result *= "\n\\label{$(escape_latex(node.id))}"
```

Should use IOBuffer everywhere or string interpolation everywhere, not mix.

## 🟢 Good Julia Patterns Already Used

### 1. Type Hierarchy with Abstract Types ✅
```julia
abstract type AsciiDocNode end
abstract type BlockNode <: AsciiDocNode end
```
Good! Enables dispatch.

### 2. Multiple Dispatch for Backends ✅
```julia
to_latex(node::Header) = ...
to_latex(node::Paragraph) = ...
to_latex(node::Bold) = ...
```
Excellent! This is the Julia way.

### 3. Convenience Constructors ✅
```julia
Header(level::Int, text::Vector{InlineNode}) = Header(level, text, "")
```
Good for ergonomics.

### 4. Union Types for Optional Returns ✅
```julia
function try_parse_header(state) -> Union{Header, Nothing}
```
Correct pattern.

### 5. Vector Building with push! ✅
```julia
blocks = BlockNode[]
push!(blocks, header)
```
Idiomatic.

## 🔧 Specific Improvements Needed

### Parser Functions - Use Dispatch More

**Current:**
```julia
function parse_asciidoc(text::String)
    # ...
    if (block = try_parse_header(state)) !== nothing
        push!(blocks, block)
    elseif (block = try_parse_code_block(state)) !== nothing
        push!(blocks, block)
    # ... many elseifs
end
```

**More Julian - Use dispatch or a table:**
```julia
const BLOCK_PARSERS = [
    try_parse_header,
    try_parse_code_block,
    try_parse_block_quote,
    # ...
]

function parse_asciidoc(text::String)
    # ...
    for parser in BLOCK_PARSERS
        if (block = parser(state)) !== nothing
            push!(blocks, block)
            break
        end
    end
end
```

Or use multiple dispatch on line patterns.

### Return Types - Be Explicit

**Current:**
```julia
function parse_inline(text::String)
    # returns Vector{InlineNode}
end
```

**Better:**
```julia
function parse_inline(text::String)::Vector{InlineNode}
    # ...
end
```

Julia doesn't require it, but for public API it helps.

### Use @enum for Constants

If we add admonition types:
```julia
@enum AdmonitionType NOTE TIP WARNING IMPORTANT CAUTION
```

Better than strings for type safety.

### Escape Functions - Use replace with Pairs

**Current:**
```julia
function escape_latex(text::String)
    replacements = [
        "\\" => "\\textbackslash{}",
        "{" => "\\{",
        # ...
    ]
    result = text
    for (char, replacement) in replacements
        result = replace(result, char => replacement)
    end
    return result
end
```

**Better - Single pass:**
```julia
function escape_latex(text::String)
    # Use chain of replacements
    replace(text,
        "\\" => "\\textbackslash{}",
        "{" => "\\{",
        "}" => "\\}",
        "\$" => "\\\$",
        "&" => "\\&",
        "%" => "\\%",
        "#" => "\\#",
        "_" => "\\_",
        "~" => "\\textasciitilde{}",
        "^" => "\\textasciicircum{}"
    )
end
```

Actually, the current approach is necessary because of backslash, but could still be cleaner.

## 📋 Summary of Changes Needed

### High Priority
1. **Rewrite inline parser** - Use regex/eachmatch instead of character iteration
2. **Flatten module structure** - Remove nested modules
3. **Make regexes const** - Define once at module level
4. **Use iterators** - Make ParserState iterable
5. **Consistent string building** - IOBuffer everywhere or string interpolation

### Medium Priority
6. Use dispatch table for block parsers
7. Add return type annotations to public API
8. Use @enum where appropriate
9. Consider using parser combinator library

### Low Priority
10. More functional style where it makes sense
11. Use generated functions for repetitive backend code?
12. Consider lazy evaluation for large documents

## Questions to Consider

1. **Should we use a parsing library?** (Automa.jl, PEG.jl) vs hand-rolled
2. **Streaming vs batch?** Currently loads whole doc, could stream
3. **Immutable by default?** Most types are immutable (good) but ParserState isn't
4. **Performance critical?** If yes, might need different approach
5. **Extensibility?** How easy to add new backends or node types?

The current code is *functional* but not *idiomatic*. It reads like Python/C++ translated to Julia rather than thinking in Julia from the start.
