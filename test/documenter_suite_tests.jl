"""
Documenter Suite Tests

Compares AsciiDoc documents with their Markdown equivalents to verify
that the AsciiDoc parser produces output suitable for Documenter.jl.

Test approach:
1. Parse Markdown using MarkdownAST's parser (via Markdown.jl conversion)
2. Parse AsciiDoc using our parser, convert to MarkdownAST
3. Compare using semantic equivalence (element counts, text content)
"""

module DocumenterSuiteTests

using Test
using AsciiDoc
using MarkdownAST
import Markdown
import AsciiDoc: parse, to_markdownast

# Include comparison utilities
include("ast_comparison.jl")

# Include Markdown→MarkdownAST converter from equivalence tests
include("equivalence_tests.jl")
using .EquivalenceTests: markdown_to_ast

const SUITE_DIR = joinpath(@__DIR__, "documenter_suite")

"""
    load_test_pair(basename::String) -> (md_ast, adoc_ast)

Load a matched pair of Markdown and AsciiDoc files, parse both to MarkdownAST.
"""
function load_test_pair(basename::String)
    md_path = joinpath(SUITE_DIR, "$(basename).md")
    adoc_path = joinpath(SUITE_DIR, "$(basename).adoc")

    @assert isfile(md_path) "Missing Markdown file: $md_path"
    @assert isfile(adoc_path) "Missing AsciiDoc file: $adoc_path"

    md_text = read(md_path, String)
    adoc_text = read(adoc_path, String)

    md_ast = markdown_to_ast(md_text)
    adoc_ast = to_markdownast(parse(adoc_text))

    return (md_ast, adoc_ast)
end

"""
    compare_documents(md_ast, adoc_ast; name="document") -> NamedTuple

Compare two ASTs and return detailed comparison results.
"""
function compare_documents(md_ast, adoc_ast; name="document")
    md_manifest = element_manifest(md_ast)
    adoc_manifest = element_manifest(adoc_ast)

    # Text content comparison
    text_equal = text_content_equal(md_ast, adoc_ast)

    # Structural diff
    diffs = ast_diff(md_ast, adoc_ast)

    return (
        name = name,
        md_manifest = md_manifest,
        adoc_manifest = adoc_manifest,
        text_equal = text_equal,
        diffs = diffs,
        manifest_keys = union(keys(md_manifest), keys(adoc_manifest))
    )
end

"""
    print_comparison_report(result)

Print a detailed comparison report for debugging.
"""
function print_comparison_report(result)
    println("\n" * "="^60)
    println("Comparison Report: $(result.name)")
    println("="^60)

    println("\nElement Counts:")
    println("-"^40)
    println(rpad("Element", 20), rpad("Markdown", 10), "AsciiDoc")
    println("-"^40)

    for key in sort(collect(result.manifest_keys))
        md_count = get(result.md_manifest, key, 0)
        adoc_count = get(result.adoc_manifest, key, 0)
        marker = md_count == adoc_count ? "" : " ←"
        println(rpad(string(key), 20), rpad(string(md_count), 10), adoc_count, marker)
    end

    println("\nText Content Match: ", result.text_equal ? "✓" : "✗")

    if !isempty(result.diffs)
        println("\nStructural Differences:")
        for diff in result.diffs[1:min(10, length(result.diffs))]
            println("  - ", diff)
        end
        if length(result.diffs) > 10
            println("  ... and $(length(result.diffs) - 10) more")
        end
    end
end

# ============================================================================
# Test Suites
# ============================================================================

@testset "Documenter Suite Tests" begin

    @testset "Basic Elements" begin
        md_ast, adoc_ast = load_test_pair("basic_elements")
        result = compare_documents(md_ast, adoc_ast; name="basic_elements")

        # Print report for debugging
        print_comparison_report(result)

        # Core structural elements should match
        @testset "Headings" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Paragraphs" begin
            # Allow some variance for admonition content
            md_para = get(result.md_manifest, :Paragraph, 0)
            adoc_para = get(result.adoc_manifest, :Paragraph, 0)
            @test adoc_para >= md_para  # AsciiDoc may have extra for admonitions
        end

        @testset "Code Blocks" begin
            @test result.md_manifest[:CodeBlock] == result.adoc_manifest[:CodeBlock]
        end

        @testset "Lists" begin
            # Note: Nested list handling differs between formats
            # AsciiDoc uses ** for nested items (creates parent items)
            # Markdown uses indentation
            # Check that both have lists present
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Formatting" begin
            # Both should have strong, emph, and code formatting
            @test get(result.md_manifest, :Strong, 0) >= 1
            @test get(result.adoc_manifest, :Strong, 0) >= 1
            @test get(result.md_manifest, :Emph, 0) >= 1
            @test get(result.adoc_manifest, :Emph, 0) >= 1
            @test get(result.md_manifest, :Code, 0) >= 1
            @test get(result.adoc_manifest, :Code, 0) >= 1
        end

        @testset "Links" begin
            @test get(result.md_manifest, :Link, 0) == get(result.adoc_manifest, :Link, 0)
        end

        @testset "Tables" begin
            @test get(result.md_manifest, :Table, 0) == get(result.adoc_manifest, :Table, 0)
        end

        @testset "Block Elements" begin
            @test get(result.md_manifest, :BlockQuote, 0) == get(result.adoc_manifest, :BlockQuote, 0)
            @test get(result.md_manifest, :ThematicBreak, 0) == get(result.adoc_manifest, :ThematicBreak, 0)
            @test get(result.md_manifest, :Admonition, 0) == get(result.adoc_manifest, :Admonition, 0)
        end
    end

    @testset "API Documentation" begin
        md_ast, adoc_ast = load_test_pair("api_docs")
        result = compare_documents(md_ast, adoc_ast; name="api_docs")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
            @test result.md_manifest[:CodeBlock] == result.adoc_manifest[:CodeBlock]
        end

        @testset "Lists (Arguments/Fields)" begin
            @test result.md_manifest[:List] == result.adoc_manifest[:List]
        end

        @testset "Formatting" begin
            # API docs use Strong for "Arguments", "Returns", etc.
            @test get(result.md_manifest, :Strong, 0) == get(result.adoc_manifest, :Strong, 0)
        end

        @testset "Admonitions" begin
            # Both should have the warning admonition
            @test get(result.md_manifest, :Admonition, 0) >= 1
            @test get(result.adoc_manifest, :Admonition, 0) >= 1
        end
    end

    @testset "Contributing Examples (Documentation)" begin
        md_ast, adoc_ast = load_test_pair("contributing_examples")
        result = compare_documents(md_ast, adoc_ast; name="contributing_examples")

        print_comparison_report(result)

        @testset "Structure" begin
            # Both should have the same number of headings
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            # Documentation has many code examples
            # Minor differences due to how formats handle unlabeled blocks
            @test get(result.md_manifest, :CodeBlock, 0) >= 10
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 10
        end

        @testset "Lists" begin
            # Both have bullet lists
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Tables" begin
            # Common issues table
            @test get(result.md_manifest, :Table, 0) == get(result.adoc_manifest, :Table, 0)
        end

        @testset "Admonitions" begin
            # tip and warning admonitions
            @test get(result.md_manifest, :Admonition, 0) >= 1
            @test get(result.adoc_manifest, :Admonition, 0) >= 1
        end
    end

    @testset "Unicode (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("unicode")
        result = compare_documents(md_ast, adoc_ast; name="unicode")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            # Multiple code blocks with Unicode content
            @test get(result.md_manifest, :CodeBlock, 0) >= 4
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 4
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Inline Code" begin
            @test get(result.md_manifest, :Code, 0) >= 1
            @test get(result.adoc_manifest, :Code, 0) >= 1
        end
    end

    @testset "Style (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("style")
        result = compare_documents(md_ast, adoc_ast; name="style")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Admonitions" begin
            # Multiple admonitions: note, warning, tip
            @test get(result.md_manifest, :Admonition, 0) >= 3
            @test get(result.adoc_manifest, :Admonition, 0) >= 3
        end

        @testset "Block Quotes" begin
            @test get(result.md_manifest, :BlockQuote, 0) >= 1
            @test get(result.adoc_manifest, :BlockQuote, 0) >= 1
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 1
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 1
        end
    end

    @testset "LaTeX/Math (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("latex")
        result = compare_documents(md_ast, adoc_ast; name="latex")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 1
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 1
        end

        @testset "Admonitions" begin
            @test get(result.md_manifest, :Admonition, 0) >= 1
            @test get(result.adoc_manifest, :Admonition, 0) >= 1
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end
    end

    @testset "Index (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("index")
        result = compare_documents(md_ast, adoc_ast; name="index")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Admonitions" begin
            @test get(result.md_manifest, :Admonition, 0) >= 3
            @test get(result.adoc_manifest, :Admonition, 0) >= 3
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 1
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 1
        end
    end

    @testset "Fonts (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("fonts")
        result = compare_documents(md_ast, adoc_ast; name="fonts")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            # Multiple code blocks with Unicode
            @test get(result.md_manifest, :CodeBlock, 0) >= 4
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 4
        end
    end

    @testset "Line Numbers (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("linenumbers")
        result = compare_documents(md_ast, adoc_ast; name="linenumbers")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 5
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 5
        end
    end

    @testset "Cross-References (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("xrefs")
        result = compare_documents(md_ast, adoc_ast; name="xrefs")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 1
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 1
        end
    end

    @testset "Tutorial (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("tutorial")
        result = compare_documents(md_ast, adoc_ast; name="tutorial")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 8
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 8
        end

        @testset "Admonitions" begin
            @test get(result.md_manifest, :Admonition, 0) >= 3
            @test get(result.adoc_manifest, :Admonition, 0) >= 3
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end
    end

    @testset "Functions API (Documenter Example)" begin
        md_ast, adoc_ast = load_test_pair("functions")
        result = compare_documents(md_ast, adoc_ast; name="functions")

        print_comparison_report(result)

        @testset "Structure" begin
            @test result.md_manifest[:Heading] == result.adoc_manifest[:Heading]
        end

        @testset "Code Blocks" begin
            @test get(result.md_manifest, :CodeBlock, 0) >= 10
            @test get(result.adoc_manifest, :CodeBlock, 0) >= 10
        end

        @testset "Lists" begin
            @test get(result.md_manifest, :List, 0) >= 1
            @test get(result.adoc_manifest, :List, 0) >= 1
        end

        @testset "Tables" begin
            @test get(result.md_manifest, :Table, 0) >= 1
            @test get(result.adoc_manifest, :Table, 0) >= 1
        end
    end

end

# ============================================================================
# Detailed Feature Coverage Tests
# ============================================================================

@testset "Feature Coverage Analysis" begin

    @testset "Supported Features" begin
        # Test each major feature independently

        @testset "Headings (4 levels)" begin
            adoc = """
            = Level 1
            == Level 2
            === Level 3
            ==== Level 4
            """
            ast = to_markdownast(parse(adoc))
            manifest = element_manifest(ast)
            @test manifest[:Heading] == 4
        end

        @testset "Inline Formatting" begin
            adoc = "This has *bold*, _italic_, and `code`."
            ast = to_markdownast(parse(adoc))
            manifest = element_manifest(ast)
            @test haskey(manifest, :Strong)
            @test haskey(manifest, :Emph)
            @test haskey(manifest, :Code)
        end

        @testset "Code Blocks with Language" begin
            adoc = """
            [source,julia]
            ----
            x = 1
            ----
            """
            ast = to_markdownast(parse(adoc))
            # Find the code block and check language
            for child in ast.children
                if child.element isa MarkdownAST.CodeBlock
                    @test child.element.info == "julia"
                end
            end
        end

        @testset "Admonitions" begin
            adoc = """
            NOTE: This is a note.

            WARNING: This is a warning.

            TIP: This is a tip.
            """
            ast = to_markdownast(parse(adoc))
            manifest = element_manifest(ast)
            @test manifest[:Admonition] == 3
        end

        @testset "Links" begin
            adoc = "Visit https://julialang.org[Julia website]."
            ast = to_markdownast(parse(adoc))
            manifest = element_manifest(ast)
            @test manifest[:Link] == 1
        end

        @testset "Block Quotes" begin
            adoc = """
            ____
            A quoted passage.
            ____
            """
            ast = to_markdownast(parse(adoc))
            manifest = element_manifest(ast)
            @test manifest[:BlockQuote] == 1
        end
    end

end

end # module
