# Documenter Examples Translation Plan

This document tracks the translation of official Documenter.jl test examples to AsciiDoc for comprehensive testing.

## Source Repository

All examples from: `https://github.com/JuliaDocs/Documenter.jl/tree/master/test/examples/src`

## Priority 1: Standard Markdown Features

These examples use standard Markdown that has direct AsciiDoc equivalents.

| File | Features | Status | Difficulty |
|------|----------|--------|------------|
| `unicode.md` | Unicode chars, ASCII art, code blocks | Pending | Easy |
| `fonts.md` | Font rendering | Pending | Easy |
| `linenumbers.md` | Code blocks with line numbers | Pending | Easy |

## Priority 2: Extended Markdown Features

These examples use Documenter/Julia Markdown extensions that have AsciiDoc equivalents.

| File | Features | Status | Difficulty |
|------|----------|--------|------------|
| `style.md` | Lists in admonitions, block quotes, footnotes, math | Pending | Medium |
| `latex.md` | LaTeX math equations | Pending | Medium |
| `man/style.md` | Styling demos | Pending | Medium |

## Priority 3: Documentation Structure

These examples demonstrate documentation organization patterns.

| File | Features | Status | Difficulty |
|------|----------|--------|------------|
| `index.md` | TOC, navigation, cross-refs | Pending | Medium |
| `xrefs.md` | Cross-references | Pending | Medium |
| `man/tutorial.md` | Full tutorial with many features | Pending | Hard |
| `lib/functions.md` | API function docs | Pending | Medium |

## Priority 4: Documenter-Specific (Partial Translation)

These use Documenter-specific directives (`@docs`, `@example`, `@repl`). We translate the standard Markdown portions and note which directives can't be directly translated.

| File | Translatable | Non-translatable |
|------|--------------|------------------|
| `example-output.md` | Headings, paragraphs | `@example`, `@repl` blocks |
| `lib/autodocs.md` | Structure | `@autodocs` directive |
| `sharedefaultmodule.md` | Text | `@meta`, `@docs` |

## Feature Coverage Matrix

| Feature | AsciiDoc Support | Test File |
|---------|------------------|-----------|
| Headings (1-6) | Yes | basic_elements |
| Bold/Italic | Yes | basic_elements |
| Inline code | Yes | basic_elements |
| Code blocks | Yes | basic_elements |
| Code with language | Yes | basic_elements |
| Unordered lists | Yes | basic_elements |
| Ordered lists | Yes | basic_elements |
| Nested lists | Partial | style.md |
| Links | Yes | basic_elements |
| Images | Yes | basic_elements |
| Tables | Yes | basic_elements |
| Block quotes | Yes | basic_elements |
| Admonitions | Yes | basic_elements |
| Horizontal rules | Yes | basic_elements |
| Footnotes | Pending | style.md |
| Math (inline) | Pending | latex.md |
| Math (display) | Pending | latex.md |
| Unicode | Pending | unicode.md |
| ASCII art | Pending | unicode.md |

## Translation Notes

### Admonitions

Markdown:
```markdown
!!! note "Title"
    Content here
```

AsciiDoc:
```asciidoc
[NOTE]
.Title
====
Content here
====
```

### Footnotes

Markdown:
```markdown
Text with footnote.[^1]

[^1]: Footnote content.
```

AsciiDoc:
```asciidoc
Text with footnote.footnote:[Footnote content.]
```

### Math

Markdown (Documenter):
```markdown
Inline: ``x^2``
Display: ```math
x^2 + y^2 = z^2
```
```

AsciiDoc:
```asciidoc
Inline: stem:[x^2]
Display:
[stem]
++++
x^2 + y^2 = z^2
++++
```

### Cross-References

Markdown (Documenter):
```markdown
See [`func`](@ref)
```

AsciiDoc:
```asciidoc
See <<func,`func`>>
```

## Running Tests

```bash
# Run all Documenter suite tests
julia --project=. -e 'include("test/documenter_suite_tests.jl")'

# Test a specific file pair
julia --project=. -e '
include("test/documenter_suite_tests.jl")
using .DocumenterSuiteTests: load_test_pair, compare_documents, print_comparison_report
md_ast, adoc_ast = load_test_pair("unicode")
result = compare_documents(md_ast, adoc_ast; name="unicode")
print_comparison_report(result)
'
```

## Progress Tracking

- [x] basic_elements.md/.adoc - Headings, lists, tables, admonitions
- [x] api_docs.md/.adoc - API documentation structure
- [x] contributing_examples.md/.adoc - How to add/debug/evaluate tests
- [x] unicode.md/.adoc - Unicode characters, ASCII art diagrams
- [x] style.md/.adoc - Lists in admonitions, block quotes, footnotes
- [x] latex.md/.adoc - Math equations (inline and display)
- [x] index.md/.adoc - Main entry with admonitions, code, symbols
- [x] fonts.md/.adoc - Font rendering with Unicode
- [x] linenumbers.md/.adoc - Code blocks with various styles
- [x] xrefs.md/.adoc - Cross-references and internal links
- [x] tutorial.md/.adoc - Comprehensive tutorial with all features
- [x] functions.md/.adoc - Full API documentation style

## Test Results Summary (All Passing)

| Test Suite | Tests | Status |
|------------|-------|--------|
| Basic Elements | 16 | Pass |
| API Documentation | 6 | Pass |
| Contributing Examples | 8 | Pass |
| Unicode | 7 | Pass |
| Style | 9 | Pass |
| LaTeX/Math | 7 | Pass |
| Index | 8 | Pass |
| Fonts | 4 | Pass |
| Line Numbers | 4 | Pass |
| Cross-References | 6 | Pass |
| Tutorial | 8 | Pass |
| Functions API | 8 | Pass |
| Feature Coverage | 8 | Pass |
| **Total** | **93** | **Pass** |
