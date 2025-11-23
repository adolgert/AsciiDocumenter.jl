# AsciiDoc.jl Refactoring Session State

**Date:** November 22, 2024
**Session:** Refactoring for Julia Idiomaticity

## Current Status: TESTS NOT RUNNING ⚠️

### Immediate Problem

Running `julia --project -e 'using Pkg; Pkg.test()'` fails with:

```
ERROR: LoadError: UndefVarError: `Text` not defined in `AsciiDoc.LaTeX`
```

**Root Cause:** Nested module structure is broken. The `LaTeX` module can't access `Text` type from the `AST` module.

**Location:** `/Users/adolgert/dev/asciidoc/src/latex.jl:230`

### What We Were Doing

1. ✅ Completed comprehensive idiomaticity review (3 documents created)
2. ✅ Identified major issues with current implementation
3. 🔄 Started refactoring process - got tests to run first
4. ❌ Hit module structure issue immediately

### Documents Created (Already Committed)

1. **JULIA_IDIOMATICITY_REVIEW.md** - Detailed analysis of un-Julian patterns
2. **REFACTORING_EXAMPLES.jl** - Side-by-side before/after code examples
3. **REFACTORING_PLAN.md** - Prioritized roadmap for fixes

### Critical Issues Identified

#### 🔴 Priority 1: Fix Module Structure (BLOCKING)
- **Current:** Nested modules (AST, Parser, LaTeX, HTML as separate modules)
- **Problem:** Cross-module dependencies broken (`Text` not found in LaTeX)
- **Solution:** Flatten to single module namespace
- **File:** `src/AsciiDoc.jl` lines 54-64

#### 🔴 Priority 2: Inline Parser (Most Un-Julian Code)
- **Location:** `src/parser.jl` function `parse_inline`
- **Problem:** Manual character iteration, O(n²) string concatenation
- **Solution:** Rewrite using `eachmatch` with regex patterns

#### 🔴 Priority 3: Regex Constants
- **Problem:** Regexes compiled on every function call
- **Solution:** Define as module-level constants

## Next Steps (In Order)

### Step 1: Fix Module Structure to Get Tests Running

**File to Edit:** `src/AsciiDoc.jl`

**Change from:**
```julia
module AsciiDoc
    include("ast.jl")     # defines module AST
    include("parser.jl")  # defines module Parser
    include("latex.jl")   # defines module LaTeX
    include("html.jl")    # defines module HTML

    using .AST
    using .Parser
    using .LaTeX
    using .HTML
end
```

**Change to:**
```julia
module AsciiDoc
    # All in one namespace - no nested modules
    include("ast.jl")     # just type definitions
    include("parser.jl")  # just functions
    include("latex.jl")   # just functions
    include("html.jl")    # just functions
end
```

**Then modify each included file:**
- `src/ast.jl`: Remove `module AST ... end` wrapper, keep just type definitions
- `src/parser.jl`: Remove `module Parser ... end` wrapper, keep just functions
- `src/latex.jl`: Remove `module LaTeX ... end` wrapper, keep just functions
- `src/html.jl`: Remove `module HTML ... end` wrapper, keep just functions

### Step 2: After Tests Pass - Define Regex Constants

Add to top of parser.jl:
```julia
const HEADER_RE = r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$"
const CODE_BLOCK_RE = r"^\[source,\s*(\w+)\]$"
const LIST_ITEM_RE = r"^\s*[\*\-]\s+(.+)$"
# ... etc
```

### Step 3: Rewrite Inline Parser

Replace character-by-character iteration with regex-based parsing using `eachmatch`.

See `REFACTORING_EXAMPLES.jl` for detailed before/after code.

### Step 4: Make ParserState an Iterator

Implement iterator protocol for cleaner code.

### Step 5: Run Full Test Suite

Verify everything works:
```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## Todo List Status

- [x] Idiomaticity review completed
- [x] Review documents created and committed
- [ ] Get tests running (BLOCKED on module structure)
- [ ] Flatten module structure
- [ ] Define regex constants
- [ ] Rewrite inline parser
- [ ] Improve ParserState
- [ ] All tests passing

## Files to Focus On

1. **src/AsciiDoc.jl** - Main module (fix first!)
2. **src/ast.jl** - Remove `module AST` wrapper
3. **src/parser.jl** - Remove `module Parser` wrapper, add regex constants
4. **src/latex.jl** - Remove `module LaTeX` wrapper
5. **src/html.jl** - Remove `module HTML` wrapper

## Environment

- **Working Directory:** `/Users/adolgert/dev/asciidoc`
- **Julia Version:** 1.12.2
- **Branch:** `claude/asciidoc-parser-julia-01LwAqk6RdfQse4qewVFZ8Rq`

## Test Command

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## Git Status

All refactoring documentation is committed and pushed. Ready to start actual code refactoring.

## Key Insight

**The nested module structure was well-intentioned but adds complexity without benefit in Julia.** Most Julia packages use a flat structure with everything in one module namespace. This is both simpler AND more idiomatic.

## Resume Point

Start by flattening the module structure in this order:
1. Modify `src/ast.jl` - remove module wrapper
2. Modify `src/parser.jl` - remove module wrapper
3. Modify `src/latex.jl` - remove module wrapper
4. Modify `src/html.jl` - remove module wrapper
5. Modify `src/AsciiDoc.jl` - remove `using .Module` statements
6. Run tests
7. Fix any remaining issues
8. Commit when tests pass

Good luck! The refactoring plan is solid, just need to execute it step by step.
