"""
Parser for AsciiDoc documents.

This module provides functions to parse AsciiDoc text into an Abstract Syntax Tree.
"""

# Exported functions
export parse_asciidoc, parse_inline

# --- Inline Parsing Regexes and Helpers ---

# IMPORTANT: Order matters in the Regex alternation (from left to right for precedence).
# More specific/longer patterns should generally come first.
# Also, non-greedy quantifiers (`*?`, `+?`) are crucial for correct matching.
const INLINE_TOKEN_PATTERN = Regex(
    raw"""
    # Cross-reference: <<target,text>> or <<target>>
    (?<xref><<([^,>]+?)(?:,([^>]+?))?>>) | 

    # Image: image:url[alt]
    (?<image>image:([^\[]+?)(?:\b\[([^\]]*?)\])?) | 

    # Link: https?://url[text] or https?://url
    (?<link>https?://[^\s\[\]]+?(?:\b\[([^\]]+?)\])?) | 

    # Monospace: `text` (can be empty)
    (?<monospace>`([^`]*?)`) | 

    # Bold: *text* (must not start/end with space, not empty)
    (?<bold>\*(?!\s)([^*\s](?:[^\*]*?[^*\s])?)\*) | 

    # Italic: _text_ (must not start/end with space, not empty)
    (?<italic>_(?!\s)([^_\s](?:[^_]*?[^_\s])?)_) | 

    # Subscript: ~text~ (must not start/end with space, not empty)
    (?<subscript>~(?!\s)([^~\s](?:[^~]*?[^~\s])?)~) | 

    # Superscript: ^text^ (must not start/end with space, not empty)
    (?<superscript>\^(?!\s)([^\\^\s](?:[^\\^]*?[^\\^\s])?)\^)
    """,
    "x" # Extended mode for comments and whitespace, for readability
)

"""
    _parse_inline_match(m::RegexMatch) -> InlineNode

Helper function to convert a RegexMatch for an inline token into an InlineNode.
Recursively calls `parse_inline` for nested content.
"""
function _parse_inline_match(m::RegexMatch)
    # Check named capture groups using m[Symbol("name")]
    # Then, extract content based on the matched group.

    if m[:xref] !== nothing
        # Re-match the full xref string to extract its parts reliably
        # The main INLINE_TOKEN_PATTERN captures the whole <<...>> as 'xref'
        # We need to extract target and optional text from m[Symbol("xref")]
        sub_m = match(r"^<<([^,>]+?)(?:,([^>]+?))?>>$", m[:xref])
        if sub_m !== nothing
            target = String(sub_m.captures[1])
            text_cap = sub_m.captures[2]
            if text_cap !== nothing
                return CrossRef(target, parse_inline(String(text_cap)))
            else
                return CrossRef(target)
            end
        end
    elseif m[:image] !== nothing
        sub_m = match(r"^image:([^\[]+?)(?:\b\[([^\]]*?)\])?$", m[:image])
        if sub_m !== nothing
            url = String(sub_m.captures[1])
            alt = sub_m.captures[2]
            return Image(url, alt !== nothing ? String(alt) : "")
        end
    elseif m[:link] !== nothing
        sub_m = match(r"^(https?://[^\s\[\]]+?)(?:\b\[([^\]]+?)\])?$", m[:link])
        if sub_m !== nothing
            url = String(sub_m.captures[1])
            text_cap = sub_m.captures[2]
            if text_cap !== nothing
                return Link(url, parse_inline(String(text_cap)))
            else
                return Link(url)
            end
        end
    elseif m[:monospace] !== nothing
        # For simple delimited tokens, just strip the delimiters
        content = strip(m[:monospace], '`')
        return Monospace([Text(String(content))]) # Text constructor takes String
    elseif m[:bold] !== nothing
        content = strip(m[:bold], '*')
        return Bold(parse_inline(String(content)))
    elseif m[:italic] !== nothing
        content = strip(m[:italic], '_')
        return Italic(parse_inline(String(content)))
    elseif m[:subscript] !== nothing
        content = strip(m[:subscript], '~')
        return Subscript(parse_inline(String(content)))
    elseif m[:superscript] !== nothing
        content = strip(m[:superscript], '^')
        return Superscript(parse_inline(String(content)))
    end
    # This should ideally not be reached if INLINE_TOKEN_PATTERN is exhaustive
    @warn "Failed to parse inline match: $(m.match). Returning as plain text."
    return Text(String(m.match)) # Fallback, should convert to String
end

"""
    parse_inline(text::AbstractString) -> Vector{InlineNode}

Parse inline formatting within text using a Regex-based approach.
"""
function parse_inline(text::AbstractString)
    nodes = InlineNode[]
    last_idx = 1 # Tracks the end of the last processed segment

    # Iterate over all matches of the combined inline token pattern
    for m in eachmatch(INLINE_TOKEN_PATTERN, text)
        # Add plain text before the current match
        if m.offset > last_idx
            push!(nodes, Text(String(text[last_idx:m.offset-1])))
        end

        # Parse the matched inline token and add it to nodes
        push!(nodes, _parse_inline_match(m))

        # Update last_idx to the end of the current match
        last_idx = m.offset + length(m.match)
    end

    # Add any remaining plain text after the last match
    if last_idx <= length(text)
        push!(nodes, Text(String(text[last_idx:end])))
    end

    return nodes
end

# --- Original ParserState and Block Parsing functions (unchanged) ---

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
        id = m.captures[3] !== nothing ? String(m.captures[3]) : ""
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
        language = String(m.captures[1])
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
        m = match(r"^\s*[\*\-]\s+(.*)$", line)
        if m === nothing
            break
        end

        content = String(m.captures[1])
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
        m = match(r"^\s*(?:\.+|\d+\.)\s+(.*)$", line)
        if m === nothing
            break
        end

        content = String(m.captures[1])
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
                        push!(current_row_cells, TableCell(parse_inline(String(cell_content))))
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