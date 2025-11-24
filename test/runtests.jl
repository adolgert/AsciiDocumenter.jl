using Test
using AsciiDoc
# Explicitly import AsciiDoc's parse to avoid ambiguity with Base.parse
import AsciiDoc: parse, convert, LaTeX, HTML

# Run specification compliance tests
include("spec_tests.jl")

# Run IO streaming tests (PR2)
include("io_streaming_tests.jl")

@testset "AsciiDoc.jl - Legacy Tests" begin
    @testset "Headers" begin
        doc = parse("= Level 1 Header")
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa Header
        @test doc.blocks[1].level == 1

        doc = parse("=== Level 3 Header")
        @test doc.blocks[1].level == 3

        # Header with ID
        doc = parse("= Title [#mytitle]")
        @test doc.blocks[1].id == "mytitle"
    end

    @testset "Paragraphs" begin
        doc = parse("This is a simple paragraph.")
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa Paragraph

        # Multi-line paragraph
        doc = parse("""
        This is a paragraph
        that spans multiple lines.
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa Paragraph
    end

    @testset "Inline Formatting" begin
        # Bold
        doc = parse("This is *bold* text.")
        para = doc.blocks[1]
        @test any(n -> n isa Bold, para.content)

        # Italic
        doc = parse("This is _italic_ text.")
        para = doc.blocks[1]
        @test any(n -> n isa Italic, para.content)

        # Monospace
        doc = parse("This is `code` text.")
        para = doc.blocks[1]
        @test any(n -> n isa Monospace, para.content)
    end

    @testset "Code Blocks" begin
        doc = parse("""
        ----
        code here
        ----
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa CodeBlock
        @test contains(doc.blocks[1].content, "code here")

        # With language
        doc = parse("""
        [source,julia]
        ----
        println("Hello")
        ----
        """)
        @test doc.blocks[1] isa CodeBlock
        @test doc.blocks[1].language == "julia"
    end

    @testset "Lists" begin
        # Unordered list
        doc = parse("""
        * Item 1
        * Item 2
        * Item 3
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa UnorderedList
        @test length(doc.blocks[1].items) == 3

        # Ordered list
        doc = parse("""
        . First
        . Second
        . Third
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa OrderedList
        @test length(doc.blocks[1].items) == 3

        # Definition list
        doc = parse("""
        Term 1::
        Definition 1
        Term 2::
        Definition 2
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa DefinitionList
        @test length(doc.blocks[1].items) == 2
    end

    @testset "Block Quotes" begin
        doc = parse("""
        ____
        This is a quote.
        ____
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa BlockQuote
    end

    @testset "Tables" begin
        doc = parse("""
        |===
        |Cell 1|Cell 2
        |Cell 3|Cell 4
        |===
        """)
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa Table
        @test length(doc.blocks[1].rows) == 2
    end

    @testset "Horizontal Rules" begin
        doc = parse("'''")
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa HorizontalRule

        doc = parse("---")
        @test length(doc.blocks) == 1
        @test doc.blocks[1] isa HorizontalRule
    end

    @testset "Links and Images" begin
        # Links
        doc = parse("Visit https://example.com for more info.")
        para = doc.blocks[1]
        @test any(n -> n isa Link, para.content)

        # Links with text
        doc = parse("Visit https://example.com[Example Site] for more.")
        para = doc.blocks[1]
        link = findfirst(n -> n isa Link, para.content)
        @test link !== nothing

        # Images
        doc = parse("Here is an image:example.png[Alt text]")
        para = doc.blocks[1]
        @test any(n -> n isa Image, para.content)
    end

    @testset "Cross References" begin
        doc = parse("See <<section1>> for details.")
        para = doc.blocks[1]
        @test any(n -> n isa CrossRef, para.content)

        doc = parse("See <<section1,Section One>> for details.")
        para = doc.blocks[1]
        @test any(n -> n isa CrossRef, para.content)
    end

    @testset "LaTeX Conversion" begin
        doc = parse("= Title\n\nThis is *bold*.")
        latex = convert(LaTeX, doc)

        @test contains(latex, "\\section{Title}")
        @test contains(latex, "\\textbf{bold}")

        # Code blocks
        doc = parse("""
        [source,julia]
        ----
        println("test")
        ----
        """)
        latex = convert(LaTeX, doc)
        @test contains(latex, "\\begin{lstlisting}")
        @test contains(latex, "language=julia")
    end

    @testset "HTML Conversion" begin
        doc = parse("= Title\n\nThis is *bold*.")
        html = convert(HTML, doc)

        @test contains(html, "<h1>Title</h1>")
        @test contains(html, "<strong>bold</strong>")

        # Standalone mode
        html = convert(HTML, doc, standalone=true)
        @test contains(html, "<!DOCTYPE html>")
        @test contains(html, "<html>")
        @test contains(html, "</html>")
    end

    @testset "Convenience Functions" begin
        latex = asciidoc_to_latex("= Title\n\nParagraph")
        @test contains(latex, "\\section{Title}")

        html = asciidoc_to_html("= Title\n\nParagraph")
        @test contains(html, "<h1>Title</h1>")

        html = asciidoc_to_html("= Title\n\nParagraph", standalone=true)
        @test contains(html, "<!DOCTYPE html>")
    end

    @testset "Complex Document" begin
        text = """
        = My Document

        This is the introduction with *bold* and _italic_ text.

        == First Section

        Here's a list:

        * Item 1
        * Item 2
        * Item 3

        === Subsection

        [source,julia]
        ----
        function hello()
            println("Hello, World!")
        end
        ----

        == Second Section

        |===
        |Header 1|Header 2
        |Cell 1|Cell 2
        |===

        ____
        This is a quote.
        ____

        '''

        For more information, see <<first-section>>.
        """

        doc = parse(text)

        # Should have multiple blocks
        @test length(doc.blocks) > 5

        # Convert to both formats without errors
        latex = convert(LaTeX, doc)
        @test !isempty(latex)

        html = convert(HTML, doc)
        @test !isempty(html)
    end

    @testset "Edge Cases" begin
        # Empty document
        doc = parse("")
        @test length(doc.blocks) == 0

        # Only whitespace
        doc = parse("   \n\n   ")
        @test length(doc.blocks) == 0

        # Multiple blank lines between blocks
        doc = parse("Para 1\n\n\n\nPara 2")
        @test length(doc.blocks) == 2
    end
end
