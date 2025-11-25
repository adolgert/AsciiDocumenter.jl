"""
HTML backend for AsciiDoc.

Converts AsciiDoc AST to HTML output using IO streaming for memory efficiency.
"""

export to_html

"""
    to_html(io::IO, doc::Document; standalone=false) -> Nothing

Convert an AsciiDoc document to HTML, writing to the provided IO stream.

If `standalone=true`, wraps the output in a complete HTML document.
"""
function to_html(io::IO, doc::Document; standalone::Bool=false)
    if standalone
        write(io, """<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Document</title>
<style>
body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
pre { background-color: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto; }
code { background-color: #f5f5f5; padding: 2px 4px; border-radius: 2px; }
blockquote { border-left: 4px solid #ccc; margin-left: 0; padding-left: 20px; color: #666; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #f5f5f5; }
.admonition { padding: 12px; margin: 12px 0; border-left: 4px solid; border-radius: 4px; }
.admonition-title { font-weight: bold; margin: 0 0 8px 0; }
.admonition.note { background-color: #e7f3fe; border-color: #2196F3; }
.admonition.tip { background-color: #e7f6e7; border-color: #4CAF50; }
.admonition.important { background-color: #fff3e0; border-color: #FF9800; }
.admonition.warning { background-color: #fff8e1; border-color: #FFC107; }
.admonition.caution { background-color: #ffebee; border-color: #f44336; }
</style>
</head>
<body>
""")
    end

    for block in doc.blocks
        to_html(io, block)
        write(io, "\n")
    end

    if standalone
        write(io, "</body>\n</html>")
    end

    return nothing
end

"""
    to_html(io::IO, node::Header) -> Nothing

Convert a header to HTML heading tag, writing to IO.
"""
function to_html(io::IO, node::Header)
    level = clamp(node.level, 1, 6)

    print(io, "<h", level)
    if !isempty(node.id)
        print(io, " id=\"", escape_html(node.id), "\"")
    end
    print(io, ">")

    for child in node.text
        to_html(io, child)
    end

    print(io, "</h", level, ">")
    return nothing
end

"""
    to_html(io::IO, node::Paragraph) -> Nothing

Convert a paragraph to HTML, writing to IO.
"""
function to_html(io::IO, node::Paragraph)
    print(io, "<p>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</p>")
    return nothing
end

"""
    to_html(io::IO, node::CodeBlock) -> Nothing

Convert a code block to HTML, writing to IO.
"""
function to_html(io::IO, node::CodeBlock)
    print(io, "<pre><code")

    if !isempty(node.language)
        print(io, " class=\"language-", node.language, "\"")
    end

    print(io, ">")
    write(io, escape_html(node.content))
    print(io, "</code></pre>")
    return nothing
end

"""
    to_html(io::IO, node::BlockQuote) -> Nothing

Convert a block quote to HTML, writing to IO.
"""
function to_html(io::IO, node::BlockQuote)
    print(io, "<blockquote>\n")

    for block in node.blocks
        to_html(io, block)
        write(io, "\n")
    end

    if !isempty(node.attribution)
        print(io, "<footer>— ", escape_html(node.attribution), "</footer>\n")
    end

    print(io, "</blockquote>")
    return nothing
end

"""
    to_html(io::IO, node::Admonition) -> Nothing

Convert an admonition to HTML, writing to IO.

Produces semantic HTML with appropriate classes for styling.
"""
function to_html(io::IO, node::Admonition)
    print(io, "<div class=\"admonition ", node.type, "\">\n")
    print(io, "<p class=\"admonition-title\">", uppercase(node.type[1:1]), node.type[2:end], "</p>\n")

    for block in node.content
        to_html(io, block)
        write(io, "\n")
    end

    print(io, "</div>")
    return nothing
end

"""
    to_html(io::IO, node::UnorderedList) -> Nothing

Convert an unordered list to HTML, writing to IO.
"""
function to_html(io::IO, node::UnorderedList)
    print(io, "<ul>\n")

    for item in node.items
        print(io, "<li>")
        for child in item.content
            to_html(io, child)
        end

        if item.nested !== nothing
            write(io, "\n")
            to_html(io, item.nested)
        end

        print(io, "</li>\n")
    end

    print(io, "</ul>")
    return nothing
end

"""
    to_html(io::IO, node::OrderedList) -> Nothing

Convert an ordered list to HTML, writing to IO.
"""
function to_html(io::IO, node::OrderedList)
    print(io, "<ol")

    if node.style == "loweralpha"
        print(io, " type=\"a\"")
    elseif node.style == "upperalpha"
        print(io, " type=\"A\"")
    elseif node.style == "lowerroman"
        print(io, " type=\"i\"")
    elseif node.style == "upperroman"
        print(io, " type=\"I\"")
    end

    print(io, ">\n")

    for item in node.items
        print(io, "<li>")
        for child in item.content
            to_html(io, child)
        end

        if item.nested !== nothing
            write(io, "\n")
            to_html(io, item.nested)
        end

        print(io, "</li>\n")
    end

    print(io, "</ol>")
    return nothing
end

"""
    to_html(io::IO, node::DefinitionList) -> Nothing

Convert a definition list to HTML, writing to IO.
"""
function to_html(io::IO, node::DefinitionList)
    print(io, "<dl>\n")

    for (term, desc) in node.items
        print(io, "<dt>")
        for child in term.content
            to_html(io, child)
        end
        print(io, "</dt>\n")

        print(io, "<dd>")
        for child in desc.content
            to_html(io, child)
        end
        print(io, "</dd>\n")
    end

    print(io, "</dl>")
    return nothing
end

"""
    to_html(io::IO, node::Table) -> Nothing

Convert a table to HTML, writing to IO.
"""
function to_html(io::IO, node::Table)
    if isempty(node.rows)
        return nothing
    end

    print(io, "<table>\n")

    for (idx, row) in enumerate(node.rows)
        print(io, "<tr>\n")

        tag = (row.is_header || idx == 1) ? "th" : "td"

        for cell in row.cells
            print(io, "<", tag, ">")
            for child in cell.content
                to_html(io, child)
            end
            print(io, "</", tag, ">\n")
        end

        print(io, "</tr>\n")
    end

    print(io, "</table>")
    return nothing
end

"""
    to_html(io::IO, node::HorizontalRule) -> Nothing

Convert a horizontal rule to HTML, writing to IO.
"""
function to_html(io::IO, node::HorizontalRule)
    print(io, "<hr>")
    return nothing
end

"""
    to_html(io::IO, node::Text) -> Nothing

Convert text node to HTML (with escaping), writing to IO.
"""
function to_html(io::IO, node::Text)
    write(io, escape_html(node.content))
    return nothing
end

"""
    to_html(io::IO, node::Bold) -> Nothing

Convert bold text to HTML, writing to IO.
"""
function to_html(io::IO, node::Bold)
    print(io, "<strong>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</strong>")
    return nothing
end

"""
    to_html(io::IO, node::Italic) -> Nothing

Convert italic text to HTML, writing to IO.
"""
function to_html(io::IO, node::Italic)
    print(io, "<em>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</em>")
    return nothing
end

"""
    to_html(io::IO, node::Monospace) -> Nothing

Convert monospace text to HTML, writing to IO.
"""
function to_html(io::IO, node::Monospace)
    print(io, "<code>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</code>")
    return nothing
end

"""
    to_html(io::IO, node::Subscript) -> Nothing

Convert subscript to HTML, writing to IO.
"""
function to_html(io::IO, node::Subscript)
    print(io, "<sub>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</sub>")
    return nothing
end

"""
    to_html(io::IO, node::Superscript) -> Nothing

Convert superscript to HTML, writing to IO.
"""
function to_html(io::IO, node::Superscript)
    print(io, "<sup>")
    for child in node.content
        to_html(io, child)
    end
    print(io, "</sup>")
    return nothing
end

"""
    to_html(io::IO, node::Link) -> Nothing

Convert a link to HTML, writing to IO.
"""
function to_html(io::IO, node::Link)
    print(io, "<a href=\"", escape_html(node.url), "\">")

    if isempty(node.text)
        write(io, escape_html(node.url))
    else
        for child in node.text
            to_html(io, child)
        end
    end

    print(io, "</a>")
    return nothing
end

"""
    to_html(io::IO, node::Image) -> Nothing

Convert an image to HTML, writing to IO.
"""
function to_html(io::IO, node::Image)
    print(io, "<img src=\"", escape_html(node.url), "\"")

    if !isempty(node.alt_text)
        print(io, " alt=\"", escape_html(node.alt_text), "\"")
    end

    print(io, ">")
    return nothing
end

"""
    to_html(io::IO, node::CrossRef) -> Nothing

Convert a cross-reference to HTML, writing to IO.
"""
function to_html(io::IO, node::CrossRef)
    print(io, "<a href=\"#", escape_html(node.target), "\">")

    if isempty(node.text)
        write(io, escape_html(node.target))
    else
        for child in node.text
            to_html(io, child)
        end
    end

    print(io, "</a>")
    return nothing
end

"""
    to_html(io::IO, node::LineBreak) -> Nothing

Convert a line break to HTML, writing to IO.
"""
function to_html(io::IO, node::LineBreak)
    print(io, "<br>")
    return nothing
end

"""
    to_html(doc::Document; standalone=false) -> String

Convert an AsciiDoc document to HTML string.

This is a convenience wrapper that creates an IOBuffer internally.
For streaming output, use `to_html(io::IO, doc::Document)` instead.
"""
function to_html(doc::Document; standalone::Bool=false)
    io = IOBuffer()
    to_html(io, doc; standalone=standalone)
    return String(take!(io))
end

"""
    to_html(node::Union{BlockNode,InlineNode}) -> String

Convert any AST node to HTML string.

This is a convenience wrapper that creates an IOBuffer internally.
For streaming output, use `to_html(io::IO, node)` instead.
"""
function to_html(node::Union{BlockNode,InlineNode})
    io = IOBuffer()
    to_html(io, node)
    return String(take!(io))
end

"""
    escape_html(text::String) -> String

Escape special HTML characters.
"""
function escape_html(text::String)
    replacements = [
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "\"" => "&quot;",
        "'" => "&#39;"
    ]

    result = text
    for (char, replacement) in replacements
        result = replace(result, char => replacement)
    end

    return result
end
