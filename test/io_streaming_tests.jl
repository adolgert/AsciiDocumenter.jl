"""
IO Streaming Tests for PR2

These tests validate the unified I/O rendering architecture introduced in PR2.
They ensure that:
1. Both HTML and LaTeX backends support IO streaming
2. IO streaming produces identical output to the convenience wrappers
3. Streaming works with different IO types (IOBuffer, files, custom IO)
4. Backward compatibility is maintained
"""

using Test
using AsciiDocumenter
import AsciiDocumenter: parse, to_html, to_latex

@testset "IO Streaming Architecture" begin

    # Sample document for testing
    sample_doc = parse("""
    = Test Document

    This is a paragraph with *bold* and _italic_ text.

    == Section

    * Item 1
    * Item 2

    [source,julia]
    ----
    println("Hello")
    ----
    """)

    @testset "HTML IO Streaming" begin
        @testset "HTML IOBuffer Streaming" begin
            # Test that we can write to an IOBuffer
            io = IOBuffer()
            to_html(io, sample_doc)
            result = String(take!(io))

            @test !isempty(result)
            @test contains(result, "<h1")  # Headers now have auto-generated IDs
            @test contains(result, "<strong>bold</strong>")
            @test contains(result, "<em>italic</em>")
        end

        @testset "HTML Backward Compatibility" begin
            # IO version
            io = IOBuffer()
            to_html(io, sample_doc)
            io_result = String(take!(io))

            # Convenience wrapper version
            wrapper_result = to_html(sample_doc)

            # Both should produce identical output
            @test io_result == wrapper_result
        end

        @testset "HTML Standalone via IO" begin
            io = IOBuffer()
            to_html(io, sample_doc; standalone=true)
            result = String(take!(io))

            @test contains(result, "<!DOCTYPE html>")
            @test contains(result, "<html>")
            @test contains(result, "</html>")
            @test contains(result, "<body>")
        end

        @testset "HTML File Streaming" begin
            # Test that we can write directly to a file
            mktempdir() do tmpdir
                filepath = joinpath(tmpdir, "test.html")

                open(filepath, "w") do io
                    to_html(io, sample_doc)
                end

                # Verify file was written correctly
                @test isfile(filepath)
                content = read(filepath, String)
                @test contains(content, "<h1")  # Headers now have auto-generated IDs
                @test contains(content, "<strong>bold</strong>")
            end
        end

        @testset "HTML Individual Node Streaming" begin
            # Test that we can render individual nodes
            doc = parse("This is *bold* text.")
            para = doc.blocks[1]

            io = IOBuffer()
            to_html(io, para)
            result = String(take!(io))

            @test contains(result, "<p>")
            @test contains(result, "<strong>bold</strong>")
            @test contains(result, "</p>")
        end
    end

    @testset "LaTeX IO Streaming" begin
        @testset "LaTeX IOBuffer Streaming" begin
            io = IOBuffer()
            to_latex(io, sample_doc)
            result = String(take!(io))

            @test !isempty(result)
            @test contains(result, "\\section{")
            @test contains(result, "\\textbf{bold}")
            @test contains(result, "\\textit{italic}")
        end

        @testset "LaTeX Backward Compatibility" begin
            # IO version
            io = IOBuffer()
            to_latex(io, sample_doc)
            io_result = String(take!(io))

            # Convenience wrapper version
            wrapper_result = to_latex(sample_doc)

            # Both should produce identical output
            @test io_result == wrapper_result
        end

        @testset "LaTeX File Streaming" begin
            mktempdir() do tmpdir
                filepath = joinpath(tmpdir, "test.tex")

                open(filepath, "w") do io
                    to_latex(io, sample_doc)
                end

                @test isfile(filepath)
                content = read(filepath, String)
                @test contains(content, "\\section{")
                @test contains(content, "\\textbf{bold}")
            end
        end

        @testset "LaTeX Individual Node Streaming" begin
            doc = parse("This is *bold* text.")
            para = doc.blocks[1]

            io = IOBuffer()
            to_latex(io, para)
            result = String(take!(io))

            @test contains(result, "\\textbf{bold}")
        end
    end

    @testset "Memory Efficiency - No String Concat" begin
        # This is a conceptual test - in practice, we'd need to instrument
        # the code or use allocation tracking to verify this
        # For now, we verify the pattern is correct by checking the API

        @testset "All methods return Nothing" begin
            doc = parse("*bold*")
            para = doc.blocks[1]

            io = IOBuffer()
            result = to_html(io, para)
            @test result === nothing  # IO methods should return nothing

            io = IOBuffer()
            result = to_latex(io, para)
            @test result === nothing
        end
    end

    @testset "Composability - Multiple Streams" begin
        @testset "Concurrent writes to different streams" begin
            doc1 = parse("= Doc 1\n\nContent 1")
            doc2 = parse("= Doc 2\n\nContent 2")

            io1 = IOBuffer()
            io2 = IOBuffer()

            # Write to different streams
            to_html(io1, doc1)
            to_html(io2, doc2)

            result1 = String(take!(io1))
            result2 = String(take!(io2))

            @test contains(result1, "Doc 1")
            @test contains(result2, "Doc 2")
            @test result1 != result2
        end

        @testset "Interleaved writes to same stream" begin
            doc = parse("= Title")
            io = IOBuffer()

            # We can manually construct output by calling node-level methods
            print(io, "<!-- Header -->\n")
            to_html(io, doc.blocks[1])  # Just the header
            print(io, "\n<!-- End Header -->\n")

            result = String(take!(io))
            @test contains(result, "<!-- Header -->")
            @test contains(result, "<h1")  # Headers now have auto-generated IDs
            @test contains(result, "<!-- End Header -->")
        end
    end

    @testset "Edge Cases" begin
        @testset "Empty document" begin
            doc = parse("")

            io = IOBuffer()
            to_html(io, doc)
            @test String(take!(io)) == ""

            io = IOBuffer()
            to_latex(io, doc)
            @test String(take!(io)) == ""
        end

        @testset "Large document streaming" begin
            # Generate a large document
            large_text = """
            = Large Document

            $(join(["Paragraph $i with *bold* and _italic_ text." for i in 1:100], "\n\n"))

            == Section

            $(join(["* Item $i" for i in 1:100], "\n"))
            """

            doc = parse(large_text)

            # Stream to IOBuffer
            io = IOBuffer()
            to_html(io, doc)
            result = String(take!(io))

            # Should contain all elements
            @test contains(result, "<h1")  # Headers now have auto-generated IDs
            @test occursin(r"Paragraph \d+", result)
            @test occursin(r"Item \d+", result)
        end

        @testset "Special characters in streaming" begin
            doc = parse("Test <>&\"' characters")

            io = IOBuffer()
            to_html(io, doc)
            html = String(take!(io))
            @test contains(html, "&lt;")
            @test contains(html, "&gt;")
            @test contains(html, "&amp;")

            io = IOBuffer()
            to_latex(io, doc)
            latex = String(take!(io))
            # LaTeX escaping is handled by escape_latex
            @test !isempty(latex)
        end
    end

    @testset "Performance Characteristics" begin
        @testset "Streaming vs Wrapper performance" begin
            # Both should produce identical output
            # This test validates correctness rather than performance
            doc = parse("""
            = Document

            $(join(["Paragraph $i" for i in 1:50], "\n\n"))
            """)

            # IO version
            io = IOBuffer()
            to_html(io, doc)
            io_result = String(take!(io))

            # Wrapper version
            wrapper_result = to_html(doc)

            @test io_result == wrapper_result
            @test length(io_result) > 1000  # Substantial document
        end
    end
end
