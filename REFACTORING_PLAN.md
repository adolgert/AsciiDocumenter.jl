# AsciiDoc.jl Refactoring Plan

Based on the idiomaticity review, here's a prioritized plan to make the code more Julian.

## 🎯 Goals

1. **More Julian**: Use patterns native to Julia (dispatch, broadcasting, iterators)
2. **Better Performance**: Eliminate inefficiencies (string concat in loops, repeated regex compilation)
3. **More Maintainable**: Clearer structure, easier to extend
4. **Keep It Working**: Refactor incrementally with tests

## Priority 1: Critical Performance & Idiomaticity Issues

### 1.1 Rewrite Inline Parser ⚠️ CRITICAL

**Problem:** Character-by-character iteration with string concatenation in loop

**Impact:**
- ❌ O(n²) performance due to string concatenation
- ❌ Very un-Julian code style
- ❌ Hard to maintain and extend

**Solution:**
```julia
# Use regex with eachmatch
const INLINE_PATTERN = r"(\*[^\*]+\*|_[^_]+_|`[^`]+`|~[^~]+~|...)"

function parse_inline(text::String)::Vector{InlineNode}
    nodes = InlineNode[]
    last_pos = 1

    for m in eachmatch(INLINE_PATTERN, text)
        # Add text before match
        if m.offset > last_pos
            push!(nodes, Text(text[last_pos:m.offset-1]))
        end

        # Dispatch on match type
        push!(nodes, parse_inline_match(m))
        last_pos = m.offset + ncodeunits(m.match)
    end

    # Remaining text
    last_pos <= ncodeunits(text) && push!(nodes, Text(text[last_pos:end]))

    nodes
end
```

**Estimated Effort:** 4-6 hours
**Tests Affected:** All inline formatting tests
**Breaking Changes:** None (internal implementation)

### 1.2 Define Regex Constants

**Problem:** Regexes compiled on every call

**Impact:**
- ❌ Wasteful recompilation
- ❌ Harder to maintain patterns
- ❌ No single source of truth

**Solution:**
```julia
# At module level
const HEADER_RE = r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$"
const CODE_BLOCK_RE = r"^\[source,\s*(\w+)\]$"
const LIST_ITEM_RE = r"^\s*[\*\-]\s+(.+)$"
# ... all patterns
```

**Estimated Effort:** 1-2 hours
**Tests Affected:** None
**Breaking Changes:** None

### 1.3 Fix String Building Inconsistencies

**Problem:** Mix of IOBuffer and string concatenation

**Impact:**
- ❌ Inconsistent patterns
- ❌ Some inefficiencies
- ❌ Harder to predict behavior

**Solution:** Use IOBuffer consistently in backends

**Estimated Effort:** 2-3 hours
**Tests Affected:** Backend tests (verify output unchanged)
**Breaking Changes:** None

## Priority 2: Structural Improvements

### 2.1 Flatten Module Structure

**Problem:** Nested modules add complexity without benefit

**Current:**
```julia
module AsciiDoc
    module AST ... end
    module Parser ... end
    using .AST, .Parser
end
```

**Better:**
```julia
module AsciiDoc
    # All in one namespace
    include("types.jl")
    include("parser.jl")
    include("backends.jl")
end
```

**Estimated Effort:** 2-3 hours
**Tests Affected:** Import statements
**Breaking Changes:** Potentially - need to verify exports

### 2.2 Make ParserState an Iterator

**Problem:** Manual state management

**Impact:**
- ❌ More verbose than needed
- ❌ Doesn't compose with Julia iterator tools
- ❌ Can't use zip, enumerate, etc.

**Solution:**
```julia
struct DocumentLines
    lines::Vector{String}
    attributes::Dict{String,String}
end

Base.iterate(doc::DocumentLines, state=1) =
    state > length(doc.lines) ? nothing : (doc.lines[state], state + 1)

# Use with Stateful for peek/popfirst!
lines = Iterators.Stateful(DocumentLines(split(text, '\n')))
```

**Estimated Effort:** 3-4 hours
**Tests Affected:** Parser tests
**Breaking Changes:** Internal only

### 2.3 Use Dispatch Table for Block Parsing

**Problem:** Long if-elseif chain

**Solution:**
```julia
const BLOCK_PARSERS = [
    try_parse_header,
    try_parse_code_block,
    # ...
]

for parser in BLOCK_PARSERS
    block = parser(line, lines)
    !isnothing(block) && return block
end
```

**Estimated Effort:** 2 hours
**Tests Affected:** None (behavior unchanged)
**Breaking Changes:** None

## Priority 3: API Improvements

### 3.1 Simplify Backend API

**Current:**
```julia
Base.convert(::Type{LaTeX}, doc::Document) = to_latex(doc)
Base.convert(::Type{HTML}, doc::Document) = to_html(doc)
```

**Issue:** `LaTeX` and `HTML` aren't types, they're module names. This is misleading.

**Better Option A - Just use functions:**
```julia
to_latex(doc::Document) -> String
to_html(doc::Document; standalone=false) -> String
```

**Better Option B - Callable types:**
```julia
struct LaTeXBackend end
struct HTMLBackend end

const LaTeX = LaTeXBackend()
const HTML = HTMLBackend()

(::LaTeXBackend)(doc::Document) = render(LaTeX, doc)
(::HTMLBackend)(doc::Document) = render(HTML, doc)

# Usage: LaTeX(doc)
```

**Estimated Effort:** 3-4 hours
**Tests Affected:** API tests
**Breaking Changes:** Yes - API change

### 3.2 Add Type Annotations to Public API

**Problem:** No return type hints

**Solution:**
```julia
parse(text::String)::Document
to_latex(doc::Document)::String
to_html(doc::Document; standalone::Bool=false)::String
```

**Estimated Effort:** 1 hour
**Tests Affected:** None
**Breaking Changes:** None

## Priority 4: Nice-to-Haves

### 4.1 Use @kwdef for Structs

```julia
Base.@kwdef struct CodeBlock <: BlockNode
    content::String
    language::String = ""
    attributes::Dict{String,String} = Dict{String,String}()
end
```

**Estimated Effort:** 1-2 hours
**Breaking Changes:** None (can keep old constructors)

### 4.2 Use @enum for Fixed Sets

When we add admonitions:
```julia
@enum AdmonitionType NOTE TIP WARNING IMPORTANT CAUTION
```

**Estimated Effort:** 30 minutes per feature
**Breaking Changes:** None

### 4.3 Broadcasting Utilities

Add convenience functions:
```julia
# Parse multiple documents
docs = parse.(readlines("files.txt"))

# Convert all blocks
latex_blocks = to_latex.(doc.blocks)
```

**Estimated Effort:** 1 hour
**Breaking Changes:** None (additions only)

## 📊 Implementation Strategy

### Phase 1: Non-Breaking Improvements (Can do now)
- ✅ Regex constants
- ✅ String building consistency
- ✅ Type annotations
- ✅ @kwdef for new code
- ✅ Dispatch table

**Timeline:** 1-2 days
**Risk:** Low
**Value:** Medium

### Phase 2: Internal Refactors (Requires testing)
- ⚠️ Inline parser rewrite
- ⚠️ Iterator protocol
- ⚠️ Module flattening

**Timeline:** 3-4 days
**Risk:** Medium (need comprehensive tests)
**Value:** High

### Phase 3: API Changes (Breaking, needs version bump)
- 🔴 Backend API redesign
- 🔴 Any public API changes

**Timeline:** 1-2 days
**Risk:** High (breaking changes)
**Value:** Medium
**Note:** Save for v0.2.0

## 🧪 Testing Strategy

For each refactor:

1. **Run existing tests** - Must pass
2. **Add new tests** - For edge cases
3. **Benchmark** - Verify performance improvement
4. **Manual testing** - Run examples
5. **Update docs** - Keep in sync

## 📝 Decision Points

### Should we use a parsing library?

**Pros:**
- Well-tested parsing primitives
- Better error messages
- More maintainable

**Cons:**
- Learning curve
- External dependency
- May be overkill for AsciiDoc

**Recommendation:** Not for v0.1, consider for v0.2 if parser becomes complex

### Should we make everything immutable?

**Current:** Most types are immutable (good), ParserState is mutable

**Recommendation:** Keep as-is. ParserState needs mutation for efficiency.

### Should we optimize for performance or simplicity?

**Recommendation:** Simplicity for v0.1. Add performance optimizations later with benchmarks.

## 🎯 Immediate Next Steps

1. **Review with maintainer** - Get feedback on priorities
2. **Create issues** - Track each refactor
3. **Start with Phase 1** - Low risk, high value
4. **Comprehensive tests** - Before major refactors
5. **Benchmark** - Establish baseline

## 📚 References

- Julia Performance Tips: https://docs.julialang.org/en/v1/manual/performance-tips/
- Style Guide: https://docs.julialang.org/en/v1/manual/style-guide/
- Package Development: https://pkgdocs.julialang.org/
