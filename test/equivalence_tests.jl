"""
Equivalence tests: Compare AsciiDoc→MarkdownAST with Markdown→MarkdownAST

This test suite verifies that AsciiDoc documents produce semantically
equivalent MarkdownAST output as their Markdown counterparts.

The approach:
1. Define equivalent content in both AsciiDoc and Markdown
2. Parse both to MarkdownAST
3. Compare using semantic equivalence (not string matching)
"""

module EquivalenceTests

using Test
using AsciiDoc
using MarkdownAST
import Markdown  # Julia's built-in Markdown parser
import AsciiDoc: parse, to_markdownast  # Explicitly import to avoid ambiguity

# Include comparison utilities
include("ast_comparison.jl")

# ============================================================================
# Helper: Convert Julia Markdown to MarkdownAST
# ============================================================================

"""
    markdown_to_ast(md_text::String) -> MarkdownAST.Node

Parse Markdown text using Julia's parser and convert to MarkdownAST.

Note: This is a simplified conversion. For production use, you'd want
to handle more edge cases.
"""
function markdown_to_ast(md_text::String)
    md = Markdown.parse(md_text)
    return convert_md_to_ast(md)
end

function convert_md_to_ast(md::Markdown.MD)
    root = MarkdownAST.Node(MarkdownAST.Document())
    for block in md.content
        child = convert_md_block(block)
        if child !== nothing
            push!(root.children, child)
        end
    end
    return root
end

function convert_md_block(block::Markdown.Header{N}) where N
    node = MarkdownAST.Node(MarkdownAST.Heading(N))
    for item in block.text
        push!(node.children, convert_md_inline(item))
    end
    return node
end

function convert_md_block(block::Markdown.Paragraph)
    node = MarkdownAST.Node(MarkdownAST.Paragraph())
    for item in block.content
        push!(node.children, convert_md_inline(item))
    end
    return node
end

function convert_md_block(block::Markdown.Code)
    return MarkdownAST.Node(MarkdownAST.CodeBlock(block.language, block.code))
end

function convert_md_block(block::Markdown.BlockQuote)
    node = MarkdownAST.Node(MarkdownAST.BlockQuote())
    for item in block.content
        child = convert_md_block(item)
        if child !== nothing
            push!(node.children, child)
        end
    end
    return node
end

function convert_md_block(block::Markdown.List)
    list_type = block.ordered == -1 ? :bullet : :ordered
    node = MarkdownAST.Node(MarkdownAST.List(list_type, false))
    for item in block.items
        item_node = MarkdownAST.Node(MarkdownAST.Item())
        # Items in Markdown.List are arrays of content
        for content in item
            if content isa String
                para = MarkdownAST.Node(MarkdownAST.Paragraph())
                push!(para.children, MarkdownAST.Node(MarkdownAST.Text(content)))
                push!(item_node.children, para)
            else
                child = convert_md_block(content)
                if child !== nothing
                    push!(item_node.children, child)
                end
            end
        end
        push!(node.children, item_node)
    end
    return node
end

function convert_md_block(block::Markdown.HorizontalRule)
    return MarkdownAST.Node(MarkdownAST.ThematicBreak())
end

function convert_md_block(block::Markdown.Admonition)
    return MarkdownAST.Node(MarkdownAST.Admonition(block.category, block.title))
end

function convert_md_block(block::Markdown.Table)
    # Get number of columns from first row
    ncols = length(block.rows[1])

    # Create table with alignment spec
    spec = fill(:left, ncols)
    table_node = MarkdownAST.Node(MarkdownAST.Table(spec))

    # Header section (first row)
    header_section = MarkdownAST.Node(MarkdownAST.TableHeader())
    header_row = MarkdownAST.Node(MarkdownAST.TableRow())
    for (col_idx, cell) in enumerate(block.rows[1])
        cell_node = MarkdownAST.Node(MarkdownAST.TableCell(:left, true, col_idx))
        for item in cell
            push!(cell_node.children, convert_md_inline(item))
        end
        push!(header_row.children, cell_node)
    end
    push!(header_section.children, header_row)
    push!(table_node.children, header_section)

    # Body section (remaining rows)
    if length(block.rows) > 1
        body_section = MarkdownAST.Node(MarkdownAST.TableBody())
        for row in block.rows[2:end]
            row_node = MarkdownAST.Node(MarkdownAST.TableRow())
            for (col_idx, cell) in enumerate(row)
                cell_node = MarkdownAST.Node(MarkdownAST.TableCell(:left, false, col_idx))
                for item in cell
                    push!(cell_node.children, convert_md_inline(item))
                end
                push!(row_node.children, cell_node)
            end
            push!(body_section.children, row_node)
        end
        push!(table_node.children, body_section)
    end

    return table_node
end

# Fallback
function convert_md_block(block)
    @warn "Unknown Markdown block type: $(typeof(block))"
    return nothing
end

function convert_md_inline(item::String)
    return MarkdownAST.Node(MarkdownAST.Text(item))
end

function convert_md_inline(item::Markdown.Bold)
    node = MarkdownAST.Node(MarkdownAST.Strong())
    for child in item.text
        push!(node.children, convert_md_inline(child))
    end
    return node
end

function convert_md_inline(item::Markdown.Italic)
    node = MarkdownAST.Node(MarkdownAST.Emph())
    for child in item.text
        push!(node.children, convert_md_inline(child))
    end
    return node
end

function convert_md_inline(item::Markdown.Code)
    return MarkdownAST.Node(MarkdownAST.Code(item.code))
end

function convert_md_inline(item::Markdown.Link)
    node = MarkdownAST.Node(MarkdownAST.Link(item.url, ""))
    for child in item.text
        push!(node.children, convert_md_inline(child))
    end
    return node
end

function convert_md_inline(item::Markdown.Image)
    return MarkdownAST.Node(MarkdownAST.Image(item.url, item.alt))
end

# Fallback
function convert_md_inline(item)
    return MarkdownAST.Node(MarkdownAST.Text(string(item)))
end

# ============================================================================
# Test Cases: Parallel AsciiDoc and Markdown
# ============================================================================

@testset "AsciiDoc ↔ Markdown Equivalence" begin

    @testset "Headers" begin
        # Equivalent content in both formats
        asciidoc = """
        = Level 1 Header

        == Level 2 Header

        === Level 3 Header
        """

        markdown = """
        # Level 1 Header

        ## Level 2 Header

        ### Level 3 Header
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        # Compare manifests (same element counts)
        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:Heading] == md_manifest[:Heading]
        @test adoc_manifest[:Heading] == 3

        # Compare text content (same words)
        @test text_content_equal(adoc_ast, md_ast)
    end

    @testset "Paragraphs with formatting" begin
        asciidoc = """
        This is a paragraph with *bold* and _italic_ text.
        """

        markdown = """
        This is a paragraph with **bold** and *italic* text.
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        # Both should have Strong and Emph elements
        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test haskey(adoc_manifest, :Strong)
        @test haskey(md_manifest, :Strong)
        @test haskey(adoc_manifest, :Emph)
        @test haskey(md_manifest, :Emph)
    end

    @testset "Code blocks" begin
        asciidoc = """
        [source,julia]
        ----
        function hello()
            println("Hello, World!")
        end
        ----
        """

        markdown = """
        ```julia
        function hello()
            println("Hello, World!")
        end
        ```
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        # Both should have CodeBlock with julia language
        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:CodeBlock] == md_manifest[:CodeBlock]
        @test adoc_manifest[:CodeBlock] == 1

        # Verify language tag preserved
        adoc_code = first(c for c in adoc_ast.children if c.element isa MarkdownAST.CodeBlock)
        md_code = first(c for c in md_ast.children if c.element isa MarkdownAST.CodeBlock)

        @test adoc_code.element.info == "julia"
        @test md_code.element.info == "julia"
    end

    @testset "Unordered lists" begin
        asciidoc = """
        * Item 1
        * Item 2
        * Item 3
        """

        markdown = """
        - Item 1
        - Item 2
        - Item 3
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:List] == md_manifest[:List]
        @test adoc_manifest[:Item] == md_manifest[:Item]
        @test adoc_manifest[:Item] == 3

        # Text content should match
        @test text_content_equal(adoc_ast, md_ast)
    end

    @testset "Ordered lists" begin
        asciidoc = """
        . First
        . Second
        . Third
        """

        markdown = """
        1. First
        2. Second
        3. Third
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:List] == md_manifest[:List]
        @test adoc_manifest[:Item] == md_manifest[:Item]
    end

    @testset "Links" begin
        asciidoc = """
        Visit https://julialang.org[Julia] for more info.
        """

        markdown = """
        Visit [Julia](https://julialang.org) for more info.
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:Link] == md_manifest[:Link]
        @test adoc_manifest[:Link] == 1
    end

    @testset "Block quotes" begin
        asciidoc = """
        ____
        This is a quoted block.
        ____
        """

        markdown = """
        > This is a quoted block.
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        md_ast = markdown_to_ast(markdown)

        adoc_manifest = element_manifest(adoc_ast)
        md_manifest = element_manifest(md_ast)

        @test adoc_manifest[:BlockQuote] == md_manifest[:BlockQuote]
    end

    @testset "Admonitions (AsciiDoc-specific)" begin
        # Markdown doesn't have native admonitions, but Documenter.jl does
        # This tests that our AsciiDoc admonitions produce valid MarkdownAST

        asciidoc = """
        NOTE: This is an important note.

        WARNING: Be careful!
        """

        adoc_ast = to_markdownast(parse(asciidoc))
        adoc_manifest = element_manifest(adoc_ast)

        @test adoc_manifest[:Admonition] == 2

        # Verify admonition categories
        admons = [c for c in adoc_ast.children if c.element isa MarkdownAST.Admonition]
        @test admons[1].element.category == "note"
        @test admons[2].element.category == "warning"
    end

end

# ============================================================================
# Comprehensive Document Test
# ============================================================================

@testset "Full Document Equivalence" begin
    # A realistic document with multiple elements
    asciidoc = """
    = My Documentation

    == Introduction

    This is a paragraph with *bold* and _italic_ formatting.

    == Code Example

    Here's some code:

    [source,julia]
    ----
    function greet(name)
        println("Hello, \$name!")
    end
    ----

    == Features

    * Feature one
    * Feature two
    * Feature three

    NOTE: Remember to check the documentation.
    """

    markdown = """
    # My Documentation

    ## Introduction

    This is a paragraph with **bold** and *italic* formatting.

    ## Code Example

    Here's some code:

    ```julia
    function greet(name)
        println("Hello, \$name!")
    end
    ```

    ## Features

    - Feature one
    - Feature two
    - Feature three
    """

    adoc_ast = to_markdownast(parse(asciidoc))
    md_ast = markdown_to_ast(markdown)

    adoc_manifest = element_manifest(adoc_ast)
    md_manifest = element_manifest(md_ast)

    # Compare key structural elements
    @test adoc_manifest[:Heading] == md_manifest[:Heading]
    @test adoc_manifest[:Paragraph] == md_manifest[:Paragraph] + 1  # +1 for admonition content
    @test adoc_manifest[:CodeBlock] == md_manifest[:CodeBlock]
    @test adoc_manifest[:List] == md_manifest[:List]
    @test adoc_manifest[:Item] == md_manifest[:Item]

    # AsciiDoc has admonition that Markdown doesn't
    @test adoc_manifest[:Admonition] == 1
    @test !haskey(md_manifest, :Admonition)
end

end # module
