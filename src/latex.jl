"""
LaTeX backend for AsciiDoc.

Converts AsciiDoc AST to LaTeX output using IO streaming for memory efficiency.
"""

export to_latex

"""
    to_latex(io::IO, doc::Document) -> Nothing

Convert an AsciiDoc document to LaTeX, writing to the provided IO stream.
"""
function to_latex(io::IO, doc::Document)
    for block in doc.blocks
        to_latex(io, block)
        write(io, "\n\n")
    end

    return nothing
end

"""
    to_latex(io::IO, node::Header) -> Nothing

Convert a header to LaTeX section command, writing to IO.
"""
function to_latex(io::IO, node::Header)
    commands = ["\\chapter", "\\section", "\\subsection",
                "\\subsubsection", "\\paragraph", "\\subparagraph"]

    if node.level == 0 || node.level == 1
        cmd = "\\section"
    else
        cmd = commands[min(node.level, length(commands))]
    end

    print(io, cmd, "{")
    for child in node.text
        to_latex(io, child)
    end
    print(io, "}")

    if !isempty(node.id)
        print(io, "\n\\label{", escape_latex(node.id), "}")
    end

    return nothing
end

"""
    to_latex(io::IO, node::Paragraph) -> Nothing

Convert a paragraph to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Paragraph)
    for child in node.content
        to_latex(io, child)
    end
    return nothing
end

"""
    to_latex(io::IO, node::CodeBlock) -> Nothing

Convert a code block to LaTeX using listings or verbatim, writing to IO.
"""
function to_latex(io::IO, node::CodeBlock)
    if isempty(node.language)
        print(io, "\\begin{verbatim}\n")
        write(io, node.content)
        print(io, "\n\\end{verbatim}")
    else
        print(io, "\\begin{lstlisting}[language=", node.language, "]\n")
        write(io, node.content)
        print(io, "\n\\end{lstlisting}")
    end
    return nothing
end

"""
    to_latex(io::IO, node::BlockQuote) -> Nothing

Convert a block quote to LaTeX quotation environment, writing to IO.
"""
function to_latex(io::IO, node::BlockQuote)
    print(io, "\\begin{quotation}\n")

    for block in node.blocks
        to_latex(io, block)
        write(io, "\n")
    end

    if !isempty(node.attribution)
        print(io, "\\hfill --- ", escape_latex(node.attribution), "\n")
    end

    print(io, "\\end{quotation}")
    return nothing
end

"""
    to_latex(io::IO, node::Admonition) -> Nothing

Convert an admonition to LaTeX, writing to IO.

Uses a simple boxed format. For better styling, consider using
packages like tcolorbox in your document preamble.
Uses custom title if provided, otherwise defaults to capitalized type.
"""
function to_latex(io::IO, node::Admonition)
    # Use custom title if provided, otherwise default to capitalized type
    title = isempty(node.title) ? uppercase(node.type[1:1]) * node.type[2:end] : node.title

    print(io, "\\begin{quote}\n")
    print(io, "\\textbf{", escape_latex(title), ":} ")

    for (idx, block) in enumerate(node.content)
        to_latex(io, block)
        if idx < length(node.content)
            write(io, "\n")
        end
    end

    print(io, "\n\\end{quote}")
    return nothing
end

"""
    to_latex(io::IO, node::UnorderedList) -> Nothing

Convert an unordered list to LaTeX itemize environment, writing to IO.
"""
function to_latex(io::IO, node::UnorderedList)
    print(io, "\\begin{itemize}\n")

    for item in node.items
        print(io, "\\item ")
        for child in item.content
            to_latex(io, child)
        end

        if item.nested !== nothing
            write(io, "\n")
            to_latex(io, item.nested)
        end

        write(io, "\n")
    end

    print(io, "\\end{itemize}")
    return nothing
end

"""
    to_latex(io::IO, node::OrderedList) -> Nothing

Convert an ordered list to LaTeX enumerate environment, writing to IO.

Supports `start` attribute for custom starting number.
"""
function to_latex(io::IO, node::OrderedList)
    print(io, "\\begin{enumerate}\n")

    # Handle custom start number
    if haskey(node.attributes, "start")
        start_val = tryparse(Int, node.attributes["start"])
        if start_val !== nothing && start_val != 1
            print(io, "\\setcounter{enumi}{", start_val - 1, "}\n")
        end
    end

    for item in node.items
        print(io, "\\item ")
        for child in item.content
            to_latex(io, child)
        end

        if item.nested !== nothing
            write(io, "\n")
            to_latex(io, item.nested)
        end

        write(io, "\n")
    end

    print(io, "\\end{enumerate}")
    return nothing
end

"""
    to_latex(io::IO, node::DefinitionList) -> Nothing

Convert a definition list to LaTeX description environment, writing to IO.
"""
function to_latex(io::IO, node::DefinitionList)
    print(io, "\\begin{description}\n")

    for (term, desc) in node.items
        print(io, "\\item[")
        for child in term.content
            to_latex(io, child)
        end
        print(io, "] ")
        for child in desc.content
            to_latex(io, child)
        end
        write(io, "\n")
    end

    print(io, "\\end{description}")
    return nothing
end

"""
    to_latex(io::IO, node::Table) -> Nothing

Convert a table to LaTeX tabular environment, writing to IO.
"""
function to_latex(io::IO, node::Table)
    if isempty(node.rows)
        return nothing
    end

    ncols = length(node.rows[1].cells)
    col_spec = join(fill("l", ncols), " ")

    print(io, "\\begin{tabular}{", col_spec, "}\n")

    for (idx, row) in enumerate(node.rows)
        if row.is_header || (idx == 1 && !any(r -> r.is_header, node.rows))
            # First row or explicit header
            print(io, "\\textbf{")
            for (cell_idx, cell) in enumerate(row.cells)
                for child in cell.content
                    to_latex(io, child)
                end
                if cell_idx < length(row.cells)
                    print(io, "} & \\textbf{")
                end
            end
            print(io, "} \\\\\n")
            print(io, "\\hline\n")
        else
            for (cell_idx, cell) in enumerate(row.cells)
                for child in cell.content
                    to_latex(io, child)
                end
                if cell_idx < length(row.cells)
                    print(io, " & ")
                end
            end
            print(io, " \\\\\n")
        end
    end

    print(io, "\\end{tabular}")
    return nothing
end

"""
    to_latex(io::IO, node::HorizontalRule) -> Nothing

Convert a horizontal rule to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::HorizontalRule)
    print(io, "\\noindent\\rule{\\textwidth}{0.4pt}")
    return nothing
end

"""
    to_latex(io::IO, node::Text) -> Nothing

Convert text node to LaTeX (with escaping), writing to IO.
"""
function to_latex(io::IO, node::Text)
    write(io, escape_latex(node.content))
    return nothing
end

"""
    to_latex(io::IO, node::Bold) -> Nothing

Convert bold text to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Bold)
    print(io, "\\textbf{")
    for child in node.content
        to_latex(io, child)
    end
    print(io, "}")
    return nothing
end

"""
    to_latex(io::IO, node::Italic) -> Nothing

Convert italic text to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Italic)
    print(io, "\\textit{")
    for child in node.content
        to_latex(io, child)
    end
    print(io, "}")
    return nothing
end

"""
    to_latex(io::IO, node::Monospace) -> Nothing

Convert monospace text to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Monospace)
    print(io, "\\texttt{")
    for child in node.content
        to_latex(io, child)
    end
    print(io, "}")
    return nothing
end

"""
    to_latex(io::IO, node::Subscript) -> Nothing

Convert subscript to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Subscript)
    print(io, "\\textsubscript{")
    for child in node.content
        to_latex(io, child)
    end
    print(io, "}")
    return nothing
end

"""
    to_latex(io::IO, node::Superscript) -> Nothing

Convert superscript to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Superscript)
    print(io, "\\textsuperscript{")
    for child in node.content
        to_latex(io, child)
    end
    print(io, "}")
    return nothing
end

"""
    to_latex(io::IO, node::Link) -> Nothing

Convert a link to LaTeX (using hyperref), writing to IO.
"""
function to_latex(io::IO, node::Link)
    if isempty(node.text)
        print(io, "\\url{", escape_latex(node.url), "}")
    else
        print(io, "\\href{", escape_latex(node.url), "}{")
        for child in node.text
            to_latex(io, child)
        end
        print(io, "}")
    end
    return nothing
end

"""
    to_latex(io::IO, node::Image) -> Nothing

Convert an image to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::Image)
    print(io, "\\begin{figure}[h]\n")
    print(io, "\\centering\n")
    print(io, "\\includegraphics{", escape_latex(node.url), "}")

    if !isempty(node.alt_text)
        print(io, "\n\\caption{", escape_latex(node.alt_text), "}")
    end

    print(io, "\n\\end{figure}")
    return nothing
end

"""
    to_latex(io::IO, node::CrossRef) -> Nothing

Convert a cross-reference to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::CrossRef)
    if isempty(node.text)
        print(io, "\\ref{", escape_latex(node.target), "}")
    else
        print(io, "\\hyperref[", escape_latex(node.target), "]{")
        for child in node.text
            to_latex(io, child)
        end
        print(io, "}")
    end
    return nothing
end

"""
    to_latex(io::IO, node::LineBreak) -> Nothing

Convert a line break to LaTeX, writing to IO.
"""
function to_latex(io::IO, node::LineBreak)
    print(io, "\\\\")
    return nothing
end

"""
    to_latex(doc::Document) -> String

Convert an AsciiDoc document to LaTeX string.

This is a convenience wrapper that creates an IOBuffer internally.
For streaming output, use `to_latex(io::IO, doc::Document)` instead.
"""
function to_latex(doc::Document)
    io = IOBuffer()
    to_latex(io, doc)
    return String(take!(io))
end

"""
    to_latex(node::Union{BlockNode,InlineNode}) -> String

Convert any AST node to LaTeX string.

This is a convenience wrapper that creates an IOBuffer internally.
For streaming output, use `to_latex(io::IO, node)` instead.
"""
function to_latex(node::Union{BlockNode,InlineNode})
    io = IOBuffer()
    to_latex(io, node)
    return String(take!(io))
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
    # Backslash must be replaced first to avoid double-escaping.
    result = replace(result, "\\" => "\\textbackslash{}")

    for (char, replacement) in replacements[2:end]
        result = replace(result, char => replacement)
    end

    return result
end
