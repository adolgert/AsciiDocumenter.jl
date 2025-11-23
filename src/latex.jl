"""
LaTeX backend for AsciiDoc.

Converts AsciiDoc AST to LaTeX output.
"""
module LaTeX

using ..AST

export to_latex

"""
    to_latex(doc::Document) -> String

Convert an AsciiDoc document to LaTeX.
"""
function to_latex(doc::Document)
    io = IOBuffer()

    # Write preamble if needed
    # (User can wrap this in their own document class)

    # Convert blocks
    for block in doc.blocks
        write(io, to_latex(block))
        write(io, "\n\n")
    end

    return String(take!(io))
end

"""
    to_latex(node::Header) -> String

Convert a header to LaTeX section command.
"""
function to_latex(node::Header)
    # Map AsciiDoc levels to LaTeX commands
    commands = ["\\chapter", "\\section", "\\subsection",
                "\\subsubsection", "\\paragraph", "\\subparagraph"]

    # Level 0 (= Title) is typically the document title
    if node.level == 0 || node.level == 1
        cmd = "\\section"
        level_offset = 1
    else
        level_offset = 1
        cmd = commands[min(node.level, length(commands))]
    end

    text = join([to_latex(n) for n in node.text], "")

    result = "$cmd{$text}"

    # Add label if there's an ID
    if !isempty(node.id)
        result *= "\n\\label{$(escape_latex(node.id))}"
    end

    return result
end

"""
    to_latex(node::Paragraph) -> String

Convert a paragraph to LaTeX.
"""
function to_latex(node::Paragraph)
    return join([to_latex(n) for n in node.content], "")
end

"""
    to_latex(node::CodeBlock) -> String

Convert a code block to LaTeX using listings or verbatim.
"""
function to_latex(node::CodeBlock)
    if isempty(node.language)
        # Use verbatim environment
        return "\\begin{verbatim}\n$(node.content)\n\\end{verbatim}"
    else
        # Use listings environment with language
        # Note: requires \usepackage{listings}
        return "\\begin{lstlisting}[language=$(node.language)]\n$(node.content)\n\\end{lstlisting}"
    end
end

"""
    to_latex(node::BlockQuote) -> String

Convert a block quote to LaTeX quotation environment.
"""
function to_latex(node::BlockQuote)
    io = IOBuffer()
    write(io, "\\begin{quotation}\n")

    for block in node.blocks
        write(io, to_latex(block))
        write(io, "\n")
    end

    if !isempty(node.attribution)
        write(io, "\\hfill --- $(escape_latex(node.attribution))\n")
    end

    write(io, "\\end{quotation}")

    return String(take!(io))
end

"""
    to_latex(node::UnorderedList) -> String

Convert an unordered list to LaTeX itemize environment.
"""
function to_latex(node::UnorderedList)
    io = IOBuffer()
    write(io, "\\begin{itemize}\n")

    for item in node.items
        write(io, "\\item ")
        write(io, join([to_latex(n) for n in item.content], ""))

        if item.nested !== nothing
            write(io, "\n")
            write(io, to_latex(item.nested))
        end

        write(io, "\n")
    end

    write(io, "\\end{itemize}")

    return String(take!(io))
end

"""
    to_latex(node::OrderedList) -> String

Convert an ordered list to LaTeX enumerate environment.
"""
function to_latex(node::OrderedList)
    io = IOBuffer()
    write(io, "\\begin{enumerate}\n")

    for item in node.items
        write(io, "\\item ")
        write(io, join([to_latex(n) for n in item.content], ""))

        if item.nested !== nothing
            write(io, "\n")
            write(io, to_latex(item.nested))
        end

        write(io, "\n")
    end

    write(io, "\\end{enumerate}")

    return String(take!(io))
end

"""
    to_latex(node::DefinitionList) -> String

Convert a definition list to LaTeX description environment.
"""
function to_latex(node::DefinitionList)
    io = IOBuffer()
    write(io, "\\begin{description}\n")

    for (term, desc) in node.items
        term_text = join([to_latex(n) for n in term.content], "")
        desc_text = join([to_latex(n) for n in desc.content], "")
        write(io, "\\item[$(term_text)] $(desc_text)\n")
    end

    write(io, "\\end{description}")

    return String(take!(io))
end

"""
    to_latex(node::Table) -> String

Convert a table to LaTeX tabular environment.
"""
function to_latex(node::Table)
    if isempty(node.rows)
        return ""
    end

    io = IOBuffer()

    # Determine column count from first row
    ncols = length(node.rows[1].cells)
    col_spec = join(fill("l", ncols), " ")

    write(io, "\\begin{tabular}{$col_spec}\n")

    for (idx, row) in enumerate(node.rows)
        cell_contents = [join([to_latex(n) for n in cell.content], "")
                        for cell in row.cells]

        if row.is_header || (idx == 1 && !any(r -> r.is_header, node.rows))
            # First row or explicit header
            write(io, "\\textbf{", join(cell_contents, "} & \\textbf{"), "} \\\\\n")
            write(io, "\\hline\n")
        else
            write(io, join(cell_contents, " & "), " \\\\\n")
        end
    end

    write(io, "\\end{tabular}")

    return String(take!(io))
end

"""
    to_latex(node::HorizontalRule) -> String

Convert a horizontal rule to LaTeX.
"""
function to_latex(node::HorizontalRule)
    return "\\noindent\\rule{\\textwidth}{0.4pt}"
end

# Inline nodes

"""
    to_latex(node::Text) -> String

Convert text node to LaTeX (with escaping).
"""
function to_latex(node::Text)
    return escape_latex(node.content)
end

"""
    to_latex(node::Bold) -> String

Convert bold text to LaTeX.
"""
function to_latex(node::Bold)
    content = join([to_latex(n) for n in node.content], "")
    return "\\textbf{$content}"
end

"""
    to_latex(node::Italic) -> String

Convert italic text to LaTeX.
"""
function to_latex(node::Italic)
    content = join([to_latex(n) for n in node.content], "")
    return "\\textit{$content}"
end

"""
    to_latex(node::Monospace) -> String

Convert monospace text to LaTeX.
"""
function to_latex(node::Monospace)
    content = join([to_latex(n) for n in node.content], "")
    return "\\texttt{$content}"
end

"""
    to_latex(node::Subscript) -> String

Convert subscript to LaTeX.
"""
function to_latex(node::Subscript)
    content = join([to_latex(n) for n in node.content], "")
    return "\\textsubscript{$content}"
end

"""
    to_latex(node::Superscript) -> String

Convert superscript to LaTeX.
"""
function to_latex(node::Superscript)
    content = join([to_latex(n) for n in node.content], "")
    return "\\textsuperscript{$content}"
end

"""
    to_latex(node::Link) -> String

Convert a link to LaTeX (using hyperref).
"""
function to_latex(node::Link)
    if isempty(node.text)
        return "\\url{$(escape_latex(node.url))}"
    else
        text = join([to_latex(n) for n in node.text], "")
        return "\\href{$(escape_latex(node.url))}{$text}"
    end
end

"""
    to_latex(node::Image) -> String

Convert an image to LaTeX.
"""
function to_latex(node::Image)
    # Basic image inclusion
    # Note: requires \usepackage{graphicx}
    caption = !isempty(node.alt_text) ? "\n\\caption{$(escape_latex(node.alt_text))}" : ""

    return """\\begin{figure}[h]
\\centering
\\includegraphics{$(escape_latex(node.url))}$caption
\\end{figure}"""
end

"""
    to_latex(node::CrossRef) -> String

Convert a cross-reference to LaTeX.
"""
function to_latex(node::CrossRef)
    if isempty(node.text)
        return "\\ref{$(escape_latex(node.target))}"
    else
        text = join([to_latex(n) for n in node.text], "")
        return "\\hyperref[$(escape_latex(node.target))]{$text}"
    end
end

"""
    to_latex(node::LineBreak) -> String

Convert a line break to LaTeX.
"""
function to_latex(node::LineBreak)
    return "\\\\"
end

"""
    escape_latex(text::String) -> String

Escape special LaTeX characters.
"""
function escape_latex(text::String)
    replacements = [
        "\\" => "\\textbackslash{}",
        "{" => "\\{",
        "}" => "\\}",
        "\$" => "\\\$",
        "&" => "\\&",
        "%" => "\\%",
        "#" => "\\#",
        "_" => "\\_",
        "~" => "\\textasciitilde{}",
        "^" => "\\textasciicircum{}"
    ]

    result = text
    # Do backslash first to avoid double-escaping
    result = replace(result, "\\" => "\\textbackslash{}")

    for (char, replacement) in replacements[2:end]
        result = replace(result, char => replacement)
    end

    return result
end

end # module
