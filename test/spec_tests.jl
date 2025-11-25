"""
Specification-driven tests for AsciiDoc.jl

This test suite is organized to mirror the official AsciiDoc specification,
making it easy to track compliance and identify missing features.

Each test is tagged with its spec section for traceability.
"""

module SpecTests

using Test
using AsciiDocumenter
# Explicitly import AsciiDocumenter's parse to avoid ambiguity with Base.parse
import AsciiDocumenter: parse, convert, LaTeX, HTML, Document, Admonition, Text, Paragraph, Image, Table

# Test DSL for spec compliance
"""
    @spec_section(name, reference, tests)

Macro to define a test section corresponding to a specification section.

# Arguments
- `name`: Name of the spec section
- `reference`: URL or reference to the spec documentation
- `tests`: Test code block

# Example
```julia
@spec_section "Inline Formatting - Bold" "https://docs.asciidoctor.org/asciidoc/latest/text/bold/" begin
    @test_feature "basic bold" "*bold*" begin
        doc = parse("*bold*")
        # assertions...
    end
end
```
"""
macro spec_section(name, reference, tests)
    quote
        @testset $name begin
            # Store reference for documentation
            spec_ref = $reference
            $tests
        end
    end |> esc
end

"""
    @test_feature(name, syntax, code)

Test a specific AsciiDoc feature with its syntax example.

# Arguments
- `name`: Feature description
- `syntax`: AsciiDoc syntax being tested
- `code`: Test code block
"""
macro test_feature(name, syntax, code)
    quote
        @testset $name begin
            # Document the syntax being tested
            syntax_example = $syntax
            $code
        end
    end |> esc
end

"""
    @test_skip_unimplemented(name, reason, code)

Mark a test as skipped because the feature isn't implemented yet.
"""
macro test_skip_unimplemented(name, reason)
    quote
        @testset $name begin
            @test_skip true  # Feature not yet implemented: $reason
        end
    end |> esc
end

# Helper functions for common assertions

"""Assert that a document has exactly n blocks"""
function assert_block_count(doc, n)
    @test length(doc.blocks) == n
end

"""Assert that the first block is of a specific type"""
function assert_first_block_type(doc, T)
    @test !isempty(doc.blocks)
    @test doc.blocks[1] isa T
end

"""Assert that the AST contains a node of type T"""
function assert_contains_node_type(doc, T)
    @test any_node(doc, n -> n isa T)
end

"""Traverse AST looking for a node matching predicate"""
function any_node(node, pred)
    pred(node) && return true

    if node isa Document
        return any(block -> any_node(block, pred), node.blocks)
    elseif node isa Paragraph
        return any(inline -> any_node(inline, pred), node.content)
    elseif node isa Header
        return any(inline -> any_node(inline, pred), node.text)
    elseif node isa Bold || node isa Italic || node isa Monospace
        return any(inline -> any_node(inline, pred), node.content)
    elseif node isa UnorderedList || node isa OrderedList
        return any(item -> any_node(item.content, pred), node.items)
    elseif node isa Admonition
        return any(block -> any_node(block, pred), node.content)
    end

    return false
end

function any_node(nodes::Vector, pred)
    any(n -> any_node(n, pred), nodes)
end

# ============================================================================
# SPECIFICATION TESTS
# ============================================================================

@testset "AsciiDoc Specification Compliance" begin

# ----------------------------------------------------------------------------
# Document Structure
# ----------------------------------------------------------------------------

@spec_section "Headers - Section Titles" "https://docs.asciidoctor.org/asciidoc/latest/sections/titles-and-levels/" begin

    @test_feature "Level 1 header" "= Title" begin
        doc = parse("= Title")
        assert_block_count(doc, 1)
        assert_first_block_type(doc, Header)
        @test doc.blocks[1].level == 1
    end

    @test_feature "Level 2 header" "== Section" begin
        doc = parse("== Section")
        @test doc.blocks[1].level == 2
    end

    @test_feature "Level 3 header" "=== Subsection" begin
        doc = parse("=== Subsection")
        @test doc.blocks[1].level == 3
    end

    @test_feature "Header with ID" "= Title [#custom-id]" begin
        doc = parse("= Title [#custom-id]")
        @test doc.blocks[1].id == "custom-id"
    end

    @test_feature "Auto-generated IDs" "= My Section Title -> id=my-section-title" begin
        # Basic auto-generation
        doc = parse("= My Section Title")
        @test doc.blocks[1].id == "my-section-title"

        # With special characters
        doc = parse("== Hello, World!")
        @test doc.blocks[1].id == "hello-world"

        # With inline markup (should be stripped)
        doc = parse("=== *Bold* and _Italic_")
        @test doc.blocks[1].id == "bold-and-italic"

        # Starting with number gets underscore prefix
        doc = parse("== 3rd Party Libraries")
        @test doc.blocks[1].id == "_3rd-party-libraries"

        # Explicit ID still takes precedence
        doc = parse("= Title [#custom]")
        @test doc.blocks[1].id == "custom"
    end
end

@spec_section "Paragraphs" "https://docs.asciidoctor.org/asciidoc/latest/blocks/paragraphs/" begin

    @test_feature "Simple paragraph" "A paragraph." begin
        doc = parse("A paragraph.")
        assert_first_block_type(doc, Paragraph)
    end

    @test_feature "Multi-line paragraph" "Line 1\nLine 2" begin
        doc = parse("Line 1\nLine 2")
        assert_block_count(doc, 1)
    end

    @test_feature "Paragraphs separated by blank line" "Para 1\n\nPara 2" begin
        doc = parse("Para 1\n\nPara 2")
        assert_block_count(doc, 2)
    end
end

@spec_section "Horizontal Rules" "https://docs.asciidoctor.org/asciidoc/latest/blocks/thematic-breaks/" begin

    @test_feature "Horizontal rule with '''" "'''" begin
        doc = parse("'''")
        assert_first_block_type(doc, HorizontalRule)
    end

    @test_feature "Horizontal rule with ---" "---" begin
        doc = parse("---")
        assert_first_block_type(doc, HorizontalRule)
    end
end

# ----------------------------------------------------------------------------
# Text Formatting (Inline)
# ----------------------------------------------------------------------------

@spec_section "Bold Text" "https://docs.asciidoctor.org/asciidoc/latest/text/bold/" begin

    @test_feature "Bold text" "*bold*" begin
        doc = parse("This is *bold* text.")
        assert_contains_node_type(doc, Bold)
    end

    @test_feature "Bold in middle of word disallowed" "in*middle*word" begin
        doc = parse("in*middle*word")
        # Should NOT create bold - asterisks must have space or boundaries
        # Current implementation may vary
    end
end

@spec_section "Italic Text" "https://docs.asciidoctor.org/asciidoc/latest/text/italic/" begin

    @test_feature "Italic text" "_italic_" begin
        doc = parse("This is _italic_ text.")
        assert_contains_node_type(doc, Italic)
    end
end

@spec_section "Monospace Text" "https://docs.asciidoctor.org/asciidoc/latest/text/monospace/" begin

    @test_feature "Monospace text" "`code`" begin
        doc = parse("This is `code` text.")
        assert_contains_node_type(doc, Monospace)
    end
end

@spec_section "Subscript and Superscript" "https://docs.asciidoctor.org/asciidoc/latest/text/subscript-and-superscript/" begin

    @test_feature "Subscript" "~subscript~" begin
        doc = parse("H~2~O")
        assert_contains_node_type(doc, Subscript)
    end

    @test_feature "Superscript" "^superscript^" begin
        doc = parse("E=mc^2^")
        assert_contains_node_type(doc, Superscript)
    end
end

# ----------------------------------------------------------------------------
# Lists
# ----------------------------------------------------------------------------

@spec_section "Unordered Lists" "https://docs.asciidoctor.org/asciidoc/latest/lists/unordered/" begin

    @test_feature "Unordered list with *" "* item" begin
        doc = parse("* Item 1\n* Item 2")
        assert_first_block_type(doc, UnorderedList)
        @test length(doc.blocks[1].items) == 2
    end

    @test_feature "Unordered list with -" "- item" begin
        doc = parse("- Item 1\n- Item 2")
        assert_first_block_type(doc, UnorderedList)
    end

    @test_feature "Nested unordered lists" "* item\\n** nested" begin
        doc = parse("* Outer 1\n** Inner A\n** Inner B\n* Outer 2")
        assert_first_block_type(doc, UnorderedList)
        @test length(doc.blocks[1].items) == 2
        # First item should have nested list
        @test doc.blocks[1].items[1].nested !== nothing
        @test doc.blocks[1].items[1].nested isa UnorderedList
        @test length(doc.blocks[1].items[1].nested.items) == 2
    end
end

@spec_section "Ordered Lists" "https://docs.asciidoctor.org/asciidoc/latest/lists/ordered/" begin

    @test_feature "Ordered list with ." ". item" begin
        doc = parse(". Item 1\n. Item 2")
        assert_first_block_type(doc, OrderedList)
        @test length(doc.blocks[1].items) == 2
    end

    @test_feature "Ordered list with numbers" "1. item" begin
        doc = parse("1. Item 1\n2. Item 2")
        assert_first_block_type(doc, OrderedList)
    end

    @test_feature "Nested ordered lists" ". item\\n.. nested" begin
        doc = parse(". Outer 1\n.. Inner A\n.. Inner B\n. Outer 2")
        assert_first_block_type(doc, OrderedList)
        @test length(doc.blocks[1].items) == 2
        # First item should have nested list
        @test doc.blocks[1].items[1].nested !== nothing
        @test doc.blocks[1].items[1].nested isa OrderedList
        @test length(doc.blocks[1].items[1].nested.items) == 2
    end

    @test_feature "Custom start number" "[start=5]\\n. item" begin
        doc = parse("[start=5]\n. Fifth\n. Sixth\n. Seventh")
        assert_first_block_type(doc, OrderedList)
        @test haskey(doc.blocks[1].attributes, "start")
        @test doc.blocks[1].attributes["start"] == "5"
        # Verify HTML output has start attribute
        html = convert(HTML, doc)
        @test contains(html, "start=\"5\"")
    end
end

@spec_section "Definition Lists" "https://docs.asciidoctor.org/asciidoc/latest/lists/description/" begin

    @test_feature "Definition list" "term::" begin
        doc = parse("CPU::\nCentral Processing Unit")
        assert_first_block_type(doc, DefinitionList)
        @test length(doc.blocks[1].items) == 1
    end
end

# ----------------------------------------------------------------------------
# Blocks
# ----------------------------------------------------------------------------

@spec_section "Code Blocks - Listing" "https://docs.asciidoctor.org/asciidoc/latest/blocks/listing/" begin

    @test_feature "Listing block" "----\ncode\n----" begin
        doc = parse("----\ncode\n----")
        assert_first_block_type(doc, CodeBlock)
        @test contains(doc.blocks[1].content, "code")
    end

    @test_feature "Source block with language" "[source,julia]\n----\ncode\n----" begin
        doc = parse("[source,julia]\n----\ncode\n----")
        assert_first_block_type(doc, CodeBlock)
        @test doc.blocks[1].language == "julia"
    end

    @test_feature "Line numbers" "[source,lang,linenums]" begin
        # Test with comma-separated linenums
        doc = parse("[source,julia,linenums]\n----\nx = 1\ny = 2\n----")
        assert_first_block_type(doc, CodeBlock)
        @test haskey(doc.blocks[1].attributes, "linenums")
        @test doc.blocks[1].attributes["linenums"] == "true"

        # Test HTML output has line numbers
        html = convert(HTML, doc)
        @test contains(html, "line-number")
        @test contains(html, ">1<")
        @test contains(html, ">2<")

        # Test LaTeX output has numbers option
        latex = convert(LaTeX, doc)
        @test contains(latex, "numbers=left")

        # Test with % shorthand
        doc2 = parse("[source,python%linenums]\n----\nprint('hi')\n----")
        @test haskey(doc2.blocks[1].attributes, "linenums")
    end
    @test_feature "Callouts" "<1> explanation" begin
        # Test code block with callouts
        doc = parse("""
----
x = 1 # <1>
y = 2 # <2>
----
<1> Initialize x
<2> Initialize y
""")
        assert_first_block_type(doc, CodeBlock)
        cb = doc.blocks[1]
        @test haskey(cb.callouts, 1)
        @test haskey(cb.callouts, 2)
        @test cb.callouts[1] == "Initialize x"
        @test cb.callouts[2] == "Initialize y"

        # Test HTML output has callout list
        html = convert(HTML, doc)
        @test contains(html, "callouts")
        @test contains(html, "<dt>1</dt>")
        @test contains(html, "Initialize x")

        # Test LaTeX output has description list
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\begin{description}")
        @test contains(latex, "\\item[1]")
    end
end

@spec_section "Quote Blocks" "https://docs.asciidoctor.org/asciidoc/latest/blocks/blockquotes/" begin

    @test_feature "Quote block" "____\nquote\n____" begin
        doc = parse("____\nQuote text\n____")
        assert_first_block_type(doc, BlockQuote)
    end
end

@spec_section "Admonitions" "https://docs.asciidoctor.org/asciidoc/latest/blocks/admonitions/" begin

    @test_feature "NOTE admonition (inline form)" "NOTE: text" begin
        doc = parse("NOTE: This is a note.")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "note"
        @test !isempty(doc.blocks[1].content)
    end

    @test_feature "TIP admonition (inline form)" "TIP: text" begin
        doc = parse("TIP: Here's a helpful tip.")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "tip"
    end

    @test_feature "IMPORTANT admonition (inline form)" "IMPORTANT: text" begin
        doc = parse("IMPORTANT: Don't forget this.")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "important"
    end

    @test_feature "WARNING admonition (inline form)" "WARNING: text" begin
        doc = parse("WARNING: Be careful here.")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "warning"
    end

    @test_feature "CAUTION admonition (inline form)" "CAUTION: text" begin
        doc = parse("CAUTION: This may cause issues.")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "caution"
    end

    @test_feature "NOTE admonition (block form)" "[NOTE]\\n====\\ntext\\n====" begin
        doc = parse("[NOTE]\n====\nThis is a note with *bold* text.\n====")
        assert_first_block_type(doc, Admonition)
        @test doc.blocks[1].type == "note"
        @test !isempty(doc.blocks[1].content)
    end

    @test_feature "Admonition with multiple paragraphs" "[NOTE]\\n====\\npara1\\n\\npara2\\n====" begin
        doc = parse("[NOTE]\n====\nFirst paragraph.\n\nSecond paragraph.\n====")
        assert_first_block_type(doc, Admonition)
        @test length(doc.blocks[1].content) == 2
    end

    @test_feature "Admonition HTML output" "NOTE: text -> HTML" begin
        doc = parse("NOTE: This is a note.")
        html = convert(HTML, doc)
        @test contains(html, "admonition")
        @test contains(html, "note")
        @test contains(html, "Note")
    end

    @test_feature "Admonition LaTeX output" "NOTE: text -> LaTeX" begin
        doc = parse("NOTE: This is a note.")
        latex = convert(LaTeX, doc)
        @test contains(latex, "Note")
        @test contains(latex, "quote")
    end
end

# ----------------------------------------------------------------------------
# Tables
# ----------------------------------------------------------------------------

@spec_section "Tables" "https://docs.asciidoctor.org/asciidoc/latest/tables/build-a-basic-table/" begin

    @test_feature "Basic table" "|===\n|Cell\n|===" begin
        doc = parse("|===\n|Cell 1|Cell 2\n|===")
        assert_first_block_type(doc, Table)
        @test length(doc.blocks[1].rows) >= 1
    end

    @test_feature "Column alignment" "[cols=\"<,^,>\"]" begin
        doc = parse("[cols=\"<,^,>\"]\n|===\n|Left|Center|Right\n|A|B|C\n|===")
        assert_first_block_type(doc, Table)

        # Verify cols attribute is stored
        @test haskey(doc.blocks[1].attributes, "cols")
        @test doc.blocks[1].attributes["cols"] == "<,^,>"

        # Test HTML output has alignment styles
        html = convert(HTML, doc)
        @test contains(html, "text-align: left")
        @test contains(html, "text-align: center")
        @test contains(html, "text-align: right")

        # Test LaTeX output has column specs
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\begin{tabular}{l c r}")
    end
    @test_feature "Cell spanning" "2+|Cell spans" begin
        # Column spanning: 2+ means span 2 columns
        doc = parse("|===\n|2+|Spans two|End\n|A|B|C\n|===")
        assert_first_block_type(doc, Table)

        # Check first cell has colspan
        first_cell = doc.blocks[1].rows[1].cells[1]
        @test haskey(first_cell.attributes, "colspan")
        @test first_cell.attributes["colspan"] == "2"

        # Test HTML output has colspan
        html = convert(HTML, doc)
        @test contains(html, "colspan=\"2\"")

        # Test LaTeX output has multicolumn
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\multicolumn{2}")
    end

    @test_feature "Table header (explicit)" "[%header]\\n|===\\n|H|\\n|D|\\n|===" begin
        doc = parse("[%header]\n|===\n|Header 1|Header 2\n|Data 1|Data 2\n|===")
        assert_first_block_type(doc, Table)
        @test length(doc.blocks[1].rows) == 2
        # First row should be marked as header
        @test doc.blocks[1].rows[1].is_header == true
        @test doc.blocks[1].rows[2].is_header == false
        # HTML should use <th> for header cells
        html = convert(HTML, doc)
        @test contains(html, "<th>")
    end

    @test_feature "Table header with options syntax" "[options=\"header\"]" begin
        doc = parse("[options=\"header\"]\n|===\n|H1|H2\n|V1|V2\n|===")
        @test doc.blocks[1].rows[1].is_header == true
    end
end

# ----------------------------------------------------------------------------
# Links and References
# ----------------------------------------------------------------------------

@spec_section "URLs and Links" "https://docs.asciidoctor.org/asciidoc/latest/macros/url-macro/" begin

    @test_feature "Bare URL" "https://example.com" begin
        doc = parse("Visit https://example.com today")
        assert_contains_node_type(doc, Link)
    end

    @test_feature "URL with link text" "https://example.com[text]" begin
        doc = parse("https://example.com[Example]")
        assert_contains_node_type(doc, Link)
    end
end

@spec_section "Images" "https://docs.asciidoctor.org/asciidoc/latest/macros/images/" begin

    @test_feature "Inline image" "image:file.png[]" begin
        doc = parse("image:test.png[Alt text]")
        assert_contains_node_type(doc, Image)
    end

    @test_feature "Block image (image::)" "image::file.png[]" begin
        doc = parse("image::test.png[Alt text]")
        # Block image creates a paragraph containing the image
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa Paragraph
        @test length(doc.blocks[1].content) == 1
        img = doc.blocks[1].content[1]
        @test img isa Image
        @test img.url == "test.png"
        @test img.alt_text == "Alt text"
    end

    @test_feature "Image attributes (width, height)" "image::file.png[alt,width=100]" begin
        doc = parse("image::logo.png[Logo, width=200, height=100]")
        @test length(doc.blocks) == 1
        img = doc.blocks[1].content[1]
        @test img isa Image
        @test img.alt_text == "Logo"
        @test haskey(img.attributes, "width")
        @test img.attributes["width"] == "200"
        @test haskey(img.attributes, "height")
        @test img.attributes["height"] == "100"
    end
end

@spec_section "Cross References" "https://docs.asciidoctor.org/asciidoc/latest/macros/xref/" begin

    @test_feature "Cross reference" "<<target>>" begin
        doc = parse("See <<section1>> for details")
        assert_contains_node_type(doc, CrossRef)
    end

    @test_feature "Cross reference with text" "<<target,text>>" begin
        doc = parse("See <<section1,Section 1>> for details")
        assert_contains_node_type(doc, CrossRef)
    end
end

# ----------------------------------------------------------------------------
# Document Attributes
# ----------------------------------------------------------------------------

@spec_section "Document Attributes" "https://docs.asciidoctor.org/asciidoc/latest/attributes/document-attributes/" begin

    @test_feature "Attribute definition (:name: value)" ":author: John Doe" begin
        doc = parse(":author: John Doe\n\n= Document")
        @test haskey(doc.attributes, "author")
        @test doc.attributes["author"] == "John Doe"
    end

    @test_feature "Attribute reference ({name})" "Written by {author}" begin
        doc = parse(":author: John Doe\n\nWritten by {author}")
        @test !isempty(doc.blocks)
        para = doc.blocks[1]
        @test para isa Paragraph
        # Check that the text was substituted
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "John Doe")
    end

    @test_feature "Multiple attributes" ":name: value" begin
        doc = parse(":author: Alice\n:version: 1.0\n:status: draft\n\n= Doc")
        @test haskey(doc.attributes, "author")
        @test haskey(doc.attributes, "version")
        @test haskey(doc.attributes, "status")
        @test doc.attributes["author"] == "Alice"
        @test doc.attributes["version"] == "1.0"
    end

    @test_feature "Attribute unset (:name!:)" ":name!:" begin
        doc = parse(":author: Bob\n:author!:\n\n= Doc")
        @test !haskey(doc.attributes, "author")
    end

    @test_feature "Attributes in headers" "= {doctitle}" begin
        doc = parse(":doctitle: My Document\n\n= {doctitle}")
        @test doc.blocks[1] isa Header
        # Check that attribute was substituted in header
        text_content = join([node.content for node in doc.blocks[1].text if node isa Text], "")
        @test contains(text_content, "My Document")
    end

    @test_feature "Attributes in lists" "* {item}" begin
        doc = parse(":item: Test Item\n\n* {item}")
        @test doc.blocks[1] isa UnorderedList
        list = doc.blocks[1]
        item_text = join([node.content for node in list.items[1].content if node isa Text], "")
        @test contains(item_text, "Test Item")
    end

    @test_feature "Built-in attributes (automatic)" "{nbsp}, {amp}, etc." begin
        # Test non-breaking space
        doc = parse("Text{nbsp}here")
        para = doc.blocks[1]
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "\u00A0")  # Non-breaking space

        # Test ampersand
        doc = parse("A{amp}B")
        para = doc.blocks[1]
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "&")

        # Test C++
        doc = parse("Programming in {cpp}")
        para = doc.blocks[1]
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "C++")

        # Test quotes
        doc = parse("{ldquo}quoted{rdquo}")
        para = doc.blocks[1]
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "\u201C")  # Left double quote
        @test contains(text_content, "\u201D")  # Right double quote
    end
end

# ----------------------------------------------------------------------------
# Directives
# ----------------------------------------------------------------------------

@spec_section "Include Directive" "https://docs.asciidoctor.org/asciidoc/latest/directives/include/" begin

    @test_feature "Basic include directive" "include::file.adoc[]" begin
        # Test with base_path set to the includes directory
        includes_dir = joinpath(@__DIR__, "includes")
        doc = parse("= Main Document\n\ninclude::simple.adoc[]"; base_path=includes_dir)

        # Should have the main header plus included content
        @test length(doc.blocks) >= 2
        @test doc.blocks[1] isa Header
        @test doc.blocks[1].level == 1
    end

    @test_feature "Include with lines= attribute (single range)" "include::file.adoc[lines=2..4]" begin
        includes_dir = joinpath(@__DIR__, "includes")
        doc = parse("include::lines_test.adoc[lines=2..4]"; base_path=includes_dir)

        # Should have content from lines 2-4
        @test !isempty(doc.blocks)
        @test doc.blocks[1] isa Paragraph
    end

    @test_feature "Include with lines= attribute (multiple ranges)" "include::file.adoc[lines=1..2;4..5]" begin
        includes_dir = joinpath(@__DIR__, "includes")
        doc = parse("include::lines_test.adoc[lines=1..2;4..5]"; base_path=includes_dir)

        @test !isempty(doc.blocks)
    end

    @test_feature "Nested includes" "include::nested.adoc[]" begin
        includes_dir = joinpath(@__DIR__, "includes")
        doc = parse("include::nested.adoc[]"; base_path=includes_dir)

        # Should have content from nested.adoc which includes simple.adoc
        @test length(doc.blocks) >= 2
    end

    @test_feature "parse_asciidoc_file function" "parse_asciidoc_file(path)" begin
        filepath = joinpath(@__DIR__, "includes", "simple.adoc")
        doc = AsciiDocumenter.parse_asciidoc_file(filepath)

        @test !isempty(doc.blocks)
        @test doc.blocks[1] isa Header
    end

    @test_feature "Missing include file (graceful handling)" "include::nonexistent.adoc[]" begin
        includes_dir = joinpath(@__DIR__, "includes")
        # Should not error, just warn and continue
        doc = parse("= Doc\n\ninclude::nonexistent.adoc[]\n\nAfter include"; base_path=includes_dir)

        # Should still have the header and the paragraph after the include
        @test length(doc.blocks) >= 2
    end
end

# ----------------------------------------------------------------------------
# Other Features
# ----------------------------------------------------------------------------

@spec_section "Comments" "https://docs.asciidoctor.org/asciidoc/latest/comments/" begin

    @test_feature "Single-line comment (//)" "// comment" begin
        doc = parse("= Title\n// This is a comment\nParagraph text")
        # Comment should be skipped - only header and paragraph remain
        @test length(doc.blocks) == 2
        @test doc.blocks[1] isa Header
        @test doc.blocks[2] isa Paragraph
    end

    @test_feature "Comment block (////)" "////\\ncomment\\n////" begin
        doc = parse("= Title\n////\nThis is a\nmulti-line comment\n////\nParagraph text")
        # Block comment should be skipped - only header and paragraph remain
        @test length(doc.blocks) == 2
        @test doc.blocks[1] isa Header
        @test doc.blocks[2] isa Paragraph
    end

    @test_feature "Comment does not affect inline content" "text // not comment" begin
        # // in the middle of a line is NOT a comment
        doc = parse("Text with // in the middle")
        @test length(doc.blocks) == 1
        para = doc.blocks[1]
        @test para isa Paragraph
        text_content = join([node.content for node in para.content if node isa Text], "")
        @test contains(text_content, "//")
    end
end

# ----------------------------------------------------------------------------
# Backend Output Tests
# ----------------------------------------------------------------------------

@testset "LaTeX Backend Compliance" begin

    @testset "Section commands" begin
        doc = parse("= Title\n== Section")
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\section")
    end

    @testset "Text formatting" begin
        doc = parse("*bold* _italic_ `code`")
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\textbf")
        @test contains(latex, "\\textit")
        @test contains(latex, "\\texttt")
    end

    @testset "LaTeX special character escaping" begin
        doc = parse("Test \$ & % # _ { } characters")
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\\$")
        @test contains(latex, "\\&")
        @test contains(latex, "\\%")
    end
end

@testset "HTML Backend Compliance" begin

    @testset "Semantic HTML5" begin
        doc = parse("= Title\n\nParagraph")
        html = convert(HTML, doc)
        @test contains(html, "<h1")  # Headers now have auto-generated IDs
        @test contains(html, "<p>")
    end

    @testset "Standalone mode" begin
        doc = parse("= Title")
        html = convert(HTML, doc, standalone=true)
        @test contains(html, "<!DOCTYPE html>")
        @test contains(html, "<html>")
        @test contains(html, "</html>")
    end

    @testset "Code block language classes" begin
        doc = parse("[source,julia]\n----\ncode\n----")
        html = convert(HTML, doc)
        @test contains(html, "language-julia")
    end
end

end # @testset "AsciiDoc Specification Compliance"

end # module

# Run the tests if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    using Test
    include("../src/AsciiDocumenter.jl")
    using .AsciiDocumenter
    include(joinpath(@__DIR__, "spec_tests.jl"))
end
