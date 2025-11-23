# AsciiDoc.jl Test Suite

This directory contains the test suite for AsciiDoc.jl, organized to ensure comprehensive coverage and spec compliance.

## Test Structure

### `spec_tests.jl` - Specification-Driven Tests

The primary test suite, organized to mirror the official AsciiDoc specification. Each test is tagged with its corresponding spec section, making it easy to:

- Track compliance with the official spec
- Identify missing features
- Ensure correct implementation of existing features
- Generate compliance reports

**DSL Macros:**

```julia
# Define a spec section with reference link
@spec_section "Feature Name" "https://spec.url" begin
    # tests...
end

# Test a specific feature with its syntax
@test_feature "feature description" "syntax example" begin
    doc = parse("...")
    @test ...
end

# Mark unimplemented features
@test_skip_unimplemented "feature name" "reason"
```

**Example:**

```julia
@spec_section "Bold Text" "https://docs.asciidoctor.org/asciidoc/latest/text/bold/" begin

    @test_feature "Bold text" "*bold*" begin
        doc = parse("This is *bold* text.")
        assert_contains_node_type(doc, Bold)
    end

    @test_skip_unimplemented "Constrained bold" "Not implemented"
end
```

### `runtests.jl` - Main Test Runner

Runs all tests including:
- Specification compliance tests (from `spec_tests.jl`)
- Legacy regression tests
- Backend output tests

### `compliance_report.jl` - Report Generator

Generates detailed compliance reports showing:
- Implementation coverage percentage
- Pass/fail/skip statistics by spec section
- Missing features with priority recommendations
- Links to relevant spec documentation

**Usage:**

```bash
julia --project test/compliance_report.jl
```

This generates `COMPLIANCE_REPORT.md` with detailed statistics.

## Running Tests

### Run all tests:

```julia
using Pkg
Pkg.test("AsciiDoc")
```

Or from command line:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

### Run only spec tests:

```julia
julia --project test/spec_tests.jl
```

### Generate compliance report:

```julia
julia --project test/compliance_report.jl
```

## Test Organization

Tests are organized by AsciiDoc specification sections:

1. **Document Structure**
   - Headers
   - Paragraphs
   - Horizontal rules

2. **Text Formatting (Inline)**
   - Bold, italic, monospace
   - Subscript, superscript
   - Other inline formatting

3. **Lists**
   - Unordered lists
   - Ordered lists
   - Definition lists

4. **Blocks**
   - Code blocks
   - Quote blocks
   - Admonitions (not implemented)
   - Sidebars (not implemented)

5. **Tables**
   - Basic tables
   - Advanced features (not implemented)

6. **Links and References**
   - URLs
   - Images
   - Cross-references

7. **Document Attributes** (not implemented)

8. **Directives** (not implemented)

9. **Backend Tests**
   - LaTeX output
   - HTML output

## Helper Functions

The test suite provides helper functions for common assertions:

- `assert_block_count(doc, n)` - Check number of blocks
- `assert_first_block_type(doc, T)` - Check first block type
- `assert_contains_node_type(doc, T)` - Check if AST contains node type
- `any_node(node, predicate)` - Traverse AST with predicate

## Adding New Tests

When adding support for a new AsciiDoc feature:

1. **Add to spec_tests.jl:**
   ```julia
   @spec_section "Feature Name" "https://spec.url" begin
       @test_feature "description" "syntax" begin
           # test code
       end
   end
   ```

2. **Update SPEC_COMPLIANCE.md:**
   - Check the box for the implemented feature
   - Update priority if needed

3. **Add examples to examples/:**
   - Show real-world usage
   - Demonstrate the feature

4. **Run compliance report:**
   - Verify the feature shows as implemented
   - Check coverage percentage increased

## Benefits of Spec-Driven Testing

1. **Traceability**: Each test links directly to spec documentation
2. **Coverage Visibility**: Easy to see what's implemented vs missing
3. **Regression Prevention**: Tests match spec, not implementation details
4. **Documentation**: Tests serve as examples of correct usage
5. **Prioritization**: Clear view of high-value missing features

## Test Coverage Goals

- ✅ Core features: 100% coverage
- 🎯 Common features: 80%+ coverage
- 📋 Advanced features: Documented as skipped

Current coverage: ~40-50% of full AsciiDoc spec
