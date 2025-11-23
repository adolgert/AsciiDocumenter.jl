"""
Parser for AsciiDoc documents.

This module provides functions to parse AsciiDoc text into an Abstract Syntax Tree.
"""
module Parser

using ..AST

export parse_asciidoc, parse_inline

"""
    ParserState

Internal state for the parser.
"""
mutable struct ParserState
    lines::Vector{String}
    pos::Int
    attributes::Dict{String,String}
end

ParserState(text::String) = ParserState(split(text, '\n'), 1, Dict{String,String}())

"""
    peek_line(state::ParserState)

Look at the current line without advancing.
"""
function peek_line(state::ParserState)
    state.pos <= length(state.lines) ? state.lines[state.pos] : nothing
end

"""
    next_line!(state::ParserState)

Get the current line and advance to the next.
"""
function next_line!(state::ParserState)
    if state.pos <= length(state.lines)
        line = state.lines[state.pos]
        state.pos += 1
        return line
    end
    return nothing
end

"""
    skip_blank_lines!(state::ParserState)

Skip over any blank lines.
"""
function skip_blank_lines!(state::ParserState)
    while (line = peek_line(state)) !== nothing && isempty(strip(line))
        next_line!(state)
    end
end

"""
    parse_asciidoc(text::String) -> Document

Parse an AsciiDoc document into an AST.
"""
function parse_asciidoc(text::String)
    state = ParserState(text)
    blocks = BlockNode[]

    while peek_line(state) !== nothing
        skip_blank_lines!(state)
        line = peek_line(state)
        line === nothing && break

        # Try to parse different block types
        if (block = try_parse_header(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_code_block(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_block_quote(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_horizontal_rule(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_list(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_table(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_paragraph(state)) !== nothing
            push!(blocks, block)
        else
            # Skip unparseable line
            next_line!(state)
        end
    end

    return Document(state.attributes, blocks)
end

"""
    try_parse_header(state::ParserState) -> Union{Header,Nothing}

Try to parse a header (= Title).
"""
function try_parse_header(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Match header pattern: one or more '=' followed by space and text
    m = match(r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$", line)
    if m !== nothing
        level = length(m.captures[1])
        text = m.captures[2]
        id = m.captures[3] !== nothing ? m.captures[3] : ""
        next_line!(state)
        return Header(level, parse_inline(text), id)
    end

    return nothing
end

"""
    try_parse_code_block(state::ParserState) -> Union{CodeBlock,Nothing}

Try to parse a code block (----).
"""
function try_parse_code_block(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Check for source block delimiter
    if startswith(line, "----")
        next_line!(state)

        # Look for optional language specifier in previous lines
        language = ""

        # Collect code content
        code_lines = String[]
        while (line = peek_line(state)) !== nothing
            if startswith(line, "----")
                next_line!(state)
                break
            end
            push!(code_lines, line)
            next_line!(state)
        end

        return CodeBlock(join(code_lines, '\n'), language)
    end

    # Check for source block with language
    m = match(r"^\[source,\s*(\w+)\]$", line)
    if m !== nothing
        language = m.captures[1]
        next_line!(state)

        # Next line should be ----
        line = peek_line(state)
        if line !== nothing && startswith(line, "----")
            next_line!(state)

            code_lines = String[]
            while (line = peek_line(state)) !== nothing
                if startswith(line, "----")
                    next_line!(state)
                    break
                end
                push!(code_lines, line)
                next_line!(state)
            end

            return CodeBlock(join(code_lines, '\n'), language)
        end
    end

    return nothing
end

"""
    try_parse_block_quote(state::ParserState) -> Union{BlockQuote,Nothing}

Try to parse a block quote (____).
"""
function try_parse_block_quote(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    if startswith(line, "____")
        next_line!(state)

        # Collect content until closing delimiter
        content_lines = String[]
        while (line = peek_line(state)) !== nothing
            if startswith(line, "____")
                next_line!(state)
                break
            end
            push!(content_lines, line)
            next_line!(state)
        end

        # Parse the content as blocks
        content_text = join(content_lines, '\n')
        inner_doc = parse_asciidoc(content_text)

        return BlockQuote(inner_doc.blocks)
    end

    return nothing
end

"""
    try_parse_horizontal_rule(state::ParserState) -> Union{HorizontalRule,Nothing}

Try to parse a horizontal rule (''').
"""
function try_parse_horizontal_rule(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    stripped = strip(line)
    if stripped == "'''" || stripped == "---"
        next_line!(state)
        return HorizontalRule()
    end

    return nothing
end

"""
    try_parse_list(state::ParserState) -> Union{List,Nothing}

Try to parse a list (unordered or ordered).
"""
function try_parse_list(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Try unordered list (* or -)
    if match(r"^\s*[\*\-]\s+", line) !== nothing
        return parse_unordered_list(state)
    end

    # Try ordered list (. or 1.)
    if match(r"^\s*\.+\s+", line) !== nothing || match(r"^\s*\d+\.\s+", line) !== nothing
        return parse_ordered_list(state)
    end

    # Try definition list (::)
    if match(r"^.+::\s*$", line) !== nothing
        return parse_definition_list(state)
    end

    return nothing
end

"""
    parse_unordered_list(state::ParserState) -> UnorderedList

Parse an unordered list.
"""
function parse_unordered_list(state::ParserState)
    items = ListItem[]

    while (line = peek_line(state)) !== nothing
        m = match(r"^\s*[\*\-]\s+(.+)$", line)
        if m === nothing
            break
        end

        content = m.captures[1]
        next_line!(state)

        push!(items, ListItem(parse_inline(content)))
    end

    return UnorderedList(items)
end

"""
    parse_ordered_list(state::ParserState) -> OrderedList

Parse an ordered list.
"""
function parse_ordered_list(state::ParserState)
    items = ListItem[]

    while (line = peek_line(state)) !== nothing
        m = match(r"^\s*(?:\.+|\d+\.)\s+(.+)$", line)
        if m === nothing
            break
        end

        content = m.captures[1]
        next_line!(state)

        push!(items, ListItem(parse_inline(content)))
    end

    return OrderedList(items)
end

"""
    parse_definition_list(state::ParserState) -> DefinitionList

Parse a definition list.
"""
function parse_definition_list(state::ParserState)
    items = Tuple{DefinitionTerm,DefinitionDescription}[]

    while (line = peek_line(state)) !== nothing
        # Match term line (ends with ::)
        m = match(r"^(.+)::\s*$", line)
        if m === nothing
            break
        end

        term = m.captures[1]
        next_line!(state)

        # Next line should be the description (indented or not)
        desc_line = peek_line(state)
        if desc_line !== nothing && !isempty(strip(desc_line))
            next_line!(state)
            push!(items, (DefinitionTerm(parse_inline(term)),
                         DefinitionDescription(parse_inline(strip(desc_line)))))
        else
            push!(items, (DefinitionTerm(parse_inline(term)),
                         DefinitionDescription(InlineNode[])))
        end
    end

    return DefinitionList(items)
end

"""
    try_parse_table(state::ParserState) -> Union{Table,Nothing}

Try to parse a table (|===).
"""
function try_parse_table(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    if startswith(line, "|===")
        next_line!(state)

        rows = TableRow[]
        current_row_cells = TableCell[]

        while (line = peek_line(state)) !== nothing
            if startswith(line, "|===")
                # End of table
                if !isempty(current_row_cells)
                    push!(rows, TableRow(current_row_cells))
                end
                next_line!(state)
                break
            end

            if startswith(line, "|")
                # Parse table row
                cells = split(line[2:end], '|')
                for cell in cells
                    cell_content = strip(cell)
                    if !isempty(cell_content)
                        push!(current_row_cells, TableCell(parse_inline(cell_content)))
                    end
                end

                # Each line is a row
                if !isempty(current_row_cells)
                    push!(rows, TableRow(current_row_cells))
                    current_row_cells = TableCell[]
                end
            end

            next_line!(state)
        end

        return Table(rows)
    end

    return nothing
end

"""
    try_parse_paragraph(state::ParserState) -> Union{Paragraph,Nothing}

Parse a paragraph.
"""
function try_parse_paragraph(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Collect lines until blank line or special block
    lines = String[]

    while (line = peek_line(state)) !== nothing
        stripped = strip(line)

        # Stop at blank line
        if isempty(stripped)
            break
        end

        # Stop at block delimiters or special syntax
        if startswith(line, "=") || startswith(line, "----") ||
           startswith(line, "____") || startswith(line, "|===") ||
           match(r"^\s*[\*\-]\s+", line) !== nothing ||
           match(r"^\s*\.+\s+", line) !== nothing
            break
        end

        push!(lines, line)
        next_line!(state)
    end

    if !isempty(lines)
        text = join(lines, " ")
        return Paragraph(parse_inline(text))
    end

    return nothing
end

"""
    parse_inline(text::String) -> Vector{InlineNode}

Parse inline formatting within text.
"""
function parse_inline(text::String)
    nodes = InlineNode[]
    i = 1
    current_text = ""

    while i <= length(text)
        char = text[i]

        # Check for inline formatting
        if char == '*' && i < length(text) && text[i+1] != ' '
            # Bold
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            # Find closing *
            close_idx = findnext('*', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Bold(parse_inline(content)))
                i = close_idx + 1
                continue
            end
        elseif char == '_' && i < length(text) && text[i+1] != ' '
            # Italic
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            close_idx = findnext('_', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Italic(parse_inline(content)))
                i = close_idx + 1
                continue
            end
        elseif char == '`' && i < length(text)
            # Monospace
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            close_idx = findnext('`', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Monospace([Text(content)]))
                i = close_idx + 1
                continue
            end
        elseif char == '~' && i < length(text) && text[i+1] != ' '
            # Subscript
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            close_idx = findnext('~', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Subscript(parse_inline(content)))
                i = close_idx + 1
                continue
            end
        elseif char == '^' && i < length(text) && text[i+1] != ' '
            # Superscript
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            close_idx = findnext('^', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Superscript(parse_inline(content)))
                i = close_idx + 1
                continue
            end
        elseif startswith(text[i:end], "http://") || startswith(text[i:end], "https://")
            # Link
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            # Find end of URL (space or bracket)
            url_match = match(r"^(https?://[^\s\[\]]+)(?:\[([^\]]+)\])?", text[i:end])
            if url_match !== nothing
                url = url_match.captures[1]
                link_text = url_match.captures[2]
                if link_text !== nothing
                    push!(nodes, Link(url, parse_inline(link_text)))
                    i += length(url_match.match)
                else
                    push!(nodes, Link(url))
                    i += length(url)
                end
                continue
            end
        elseif startswith(text[i:end], "image:")
            # Image
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            img_match = match(r"^image:([^\[]+)(?:\[([^\]]*)\])?", text[i:end])
            if img_match !== nothing
                url = img_match.captures[1]
                alt = img_match.captures[2] !== nothing ? img_match.captures[2] : ""
                push!(nodes, Image(url, alt))
                i += length(img_match.match)
                continue
            end
        elseif startswith(text[i:end], "<<")
            # Cross-reference
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end

            xref_match = match(r"^<<([^,>]+)(?:,([^>]+))?>>", text[i:end])
            if xref_match !== nothing
                target = xref_match.captures[1]
                xref_text = xref_match.captures[2]
                if xref_text !== nothing
                    push!(nodes, CrossRef(target, parse_inline(xref_text)))
                else
                    push!(nodes, CrossRef(target))
                end
                i += length(xref_match.match)
                continue
            end
        end

        # Regular character
        current_text *= char
        i += 1
    end

    if !isempty(current_text)
        push!(nodes, Text(current_text))
    end

    return nodes
end

end # module
