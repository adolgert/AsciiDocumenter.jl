"""
HTML backend for AsciiDoc.

Converts AsciiDoc AST to HTML output.
"""

# Exported functions for HTML backend
export to_html

"""
    to_html(doc::Document; standalone=false) -> String

Convert an AsciiDoc document to HTML.

If `standalone=true`, wraps the output in a complete HTML document.
"""
function to_html(doc::Document; standalone::Bool=false)
    io = IOBuffer()

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
</style>
</head>
<body>
""")
    end

    # Convert blocks
    for block in doc.blocks
        write(io, to_html(block))
        write(io, "\n")
    end

    if standalone
        write(io, "</body>\n</html>")
    end

    return String(take!(io))
end

"""
    to_html(node::Header) -> String

Convert a header to HTML heading tag.
"""
function to_html(node::Header)
    # Map AsciiDoc levels to HTML (h1-h6)
    level = clamp(node.level, 1, 6)
    text = join([to_html(n) for n in node.text], "")

    id_attr = !isempty(node.id) ? " id=\"$(escape_html(node.id))\"" : ""

    return "<h$level$id_attr>$text</h$level>"
end

"""
    to_html(node::Paragraph) -> String

Convert a paragraph to HTML.
"""
function to_html(node::Paragraph)
    content = join([to_html(n) for n in node.content], "")
    return "<p>$content</p>"
end

"""
    to_html(node::CodeBlock) -> String

Convert a code block to HTML.
"""
function to_html(node::CodeBlock)
    escaped_content = escape_html(node.content)

    if isempty(node.language)
        return "<pre><code>$escaped_content</code></pre>"
    else
        # Add language class for syntax highlighting libraries
        return "<pre><code class=\"language-$(node.language)\">$escaped_content</code></pre>"
    end
end

"""
    to_html(node::BlockQuote) -> String

Convert a block quote to HTML.
"""
function to_html(node::BlockQuote)
    io = IOBuffer()
    write(io, "<blockquote>\n")

    for block in node.blocks
        write(io, to_html(block))
        write(io, "\n")
    end

    if !isempty(node.attribution)
        write(io, "<footer>— $(escape_html(node.attribution))</footer>\n")
    end

    write(io, "</blockquote>")

    return String(take!(io))
end

"""
    to_html(node::UnorderedList) -> String

Convert an unordered list to HTML.
"""
function to_html(node::UnorderedList)
    io = IOBuffer()
    write(io, "<ul>\n")

    for item in node.items
        write(io, "<li>")
        write(io, join([to_html(n) for n in item.content], ""))

        if item.nested !== nothing
            write(io, "\n")
            write(io, to_html(item.nested))
        end

        write(io, "</li>\n")
    end

    write(io, "</ul>")

    return String(take!(io))
end

"""
    to_html(node::OrderedList) -> String

Convert an ordered list to HTML.
"""
function to_html(node::OrderedList)
    io = IOBuffer()

    # Map list style to HTML type attribute
    type_attr = if node.style == "loweralpha"
        " type=\"a\""
    elseif node.style == "upperalpha"
        " type=\"A\""
    elseif node.style == "lowerroman"
        " type=\"i\""
    elseif node.style == "upperroman"
        " type=\"I\""
    else
        ""
    end

    write(io, "<ol$type_attr>\n")

    for item in node.items
        write(io, "<li>")
        write(io, join([to_html(n) for n in item.content], ""))

        if item.nested !== nothing
            write(io, "\n")
            write(io, to_html(item.nested))
        end

        write(io, "</li>\n")
    end

    write(io, "</ol>")

    return String(take!(io))
end

"""
    to_html(node::DefinitionList) -> String

Convert a definition list to HTML.
"""
function to_html(node::DefinitionList)
    io = IOBuffer()
    write(io, "<dl>\n")

    for (term, desc) in node.items
        term_text = join([to_html(n) for n in term.content], "")
        desc_text = join([to_html(n) for n in desc.content], "")

        write(io, "<dt>$(term_text)</dt>\n")
        write(io, "<dd>$(desc_text)</dd>\n")
    end

    write(io, "</dl>")

    return String(take!(io))
end

"""
    to_html(node::Table) -> String

Convert a table to HTML.
"""
function to_html(node::Table)
    if isempty(node.rows)
        return ""
    end

    io = IOBuffer()
    write(io, "<table>\n")

    for (idx, row) in enumerate(node.rows)
        write(io, "<tr>\n")

        tag = (row.is_header || idx == 1) ? "th" : "td"

        for cell in row.cells
            cell_content = join([to_html(n) for n in cell.content], "")
            write(io, "<$tag>$(cell_content)</$tag>\n")
        end

        write(io, "</tr>\n")
    end

    write(io, "</table>")

    return String(take!(io))
end

"""
    to_html(node::HorizontalRule) -> String

Convert a horizontal rule to HTML.
"""
function to_html(node::HorizontalRule)
    return "<hr>"
end

# Inline nodes

"""
    to_html(node::Text) -> String

Convert text node to HTML (with escaping).
"""
function to_html(node::Text)
    return escape_html(node.content)
end

"""
    to_html(node::Bold) -> String

Convert bold text to HTML.
"""
function to_html(node::Bold)
    content = join([to_html(n) for n in node.content], "")
    return "<strong>$content</strong>"
end

"""
    to_html(node::Italic) -> String

Convert italic text to HTML.
"""
function to_html(node::Italic)
    content = join([to_html(n) for n in node.content], "")
    return "<em>$content</em>"
end

"""
    to_html(node::Monospace) -> String

Convert monospace text to HTML.
"""
function to_html(node::Monospace)
    content = join([to_html(n) for n in node.content], "")
    return "<code>$content</code>"
end

"""
    to_html(node::Subscript) -> String

Convert subscript to HTML.
"""
function to_html(node::Subscript)
    content = join([to_html(n) for n in node.content], "")
    return "<sub>$content</sub>"
end

"""
    to_html(node::Superscript) -> String

Convert superscript to HTML.
"""
function to_html(node::Superscript)
    content = join([to_html(n) for n in node.content], "")
    return "<sup>$content</sup>"
end

"""
    to_html(node::Link) -> String

Convert a link to HTML.
"""
function to_html(node::Link)
    if isempty(node.text)
        return "<a href=\"$(escape_html(node.url))\">$(escape_html(node.url))</a>"
    else
        text = join([to_html(n) for n in node.text], "")
        return "<a href=\"$(escape_html(node.url))\">$text</a>"
    end
end

"""
    to_html(node::Image) -> String

Convert an image to HTML.
"""
function to_html(node::Image)
    alt_attr = !isempty(node.alt_text) ? " alt=\"$(escape_html(node.alt_text))\"" : ""
    return "<img src=\"$(escape_html(node.url))\"$alt_attr>"
end

"""
    to_html(node::CrossRef) -> String

Convert a cross-reference to HTML.
"""
function to_html(node::CrossRef)
    if isempty(node.text)
        return "<a href=\"#$(escape_html(node.target))\">$(escape_html(node.target))</a>"
    else
        text = join([to_html(n) for n in node.text], "")
        return "<a href=\"#$(escape_html(node.target))\">$text</a>"
    end
end

"""
    to_html(node::LineBreak) -> String

Convert a line break to HTML.
"""
function to_html(node::LineBreak)
    return "<br>"
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
