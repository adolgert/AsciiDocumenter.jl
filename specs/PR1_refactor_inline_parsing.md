# PR Proposal: Refactor Inline Parsing Logic

## 1. Objective
Replace the current character-by-character, imperative inline parser in `src/parser.jl` with a robust, Regex-based (or Tokenizer-based) approach using Julia's iterator protocols.

## 2. Problem Statement
The current `parse_inline` function suffers from significant performance and maintainability issues:
- **Performance:** It performs string concatenation (`*=`) inside a loop, leading to $O(N^2)$ allocation behavior.
- **Fragility:** Manual index manipulation (`i += 1`, `i = close_idx + 1`) is error-prone and hard to extend.
- **Idiomaticity:** It ignores Julia's powerful regex and string iteration capabilities (`eachmatch`, `SubString`).

## 3. Proposed Solution

### 3.1. Primary Strategy: `eachmatch` Iteration
Rewrite `parse_inline` to iterate over matches of a master Regex pattern that captures all inline tokens (bold, italic, links, code).

**Pseudocode Implementation Plan:**
```julia
const INLINE_TOKEN_PATTERN = r"(\*[^\*]+\*|_[^_]+_|`[^`]+`|https?://\S+)"

function parse_inline(text::AbstractString)
    nodes = InlineNode[]
    last_idx = 1

    for m in eachmatch(INLINE_TOKEN_PATTERN, text)
        # 1. Capture plain text before the match
        if m.offset > last_idx
            push!(nodes, Text(text[last_idx:m.offset-1]))
        end

        # 2. Dispatch based on what matched
        push!(nodes, parse_token_match(m))

        # 3. Update index
        last_idx = m.offset + length(m.match)
    end

    # 4. Capture remaining text
    if last_idx <= length(text)
        push!(nodes, Text(text[last_idx:end]))
    end

    return nodes
end
```

### 3.2. Helper Dispatch
Introduce a dispatcher `parse_token_match(m::RegexMatch)` that inspects the match and returns the correct `InlineNode` (e.g., `Bold`, `Link`).

## 4. Success Criteria
- **Zero String Concatenation:** No use of `*=` for building text buffers.
- **Passes Existing Tests:** All current inline formatting tests must pass.
- **Benchmark Improvement:** A simple benchmark parsing a large paragraph should show reduced memory allocation.

## 5. Future Considerations
- Ideally, for very complex nested grammars, we might eventually move to `Automa.jl` (finite state machine generator), but the Regex refactor is the necessary first step to clean up the code.
