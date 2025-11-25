"""
Parser for AsciiDoc documents.

This module provides functions to parse AsciiDoc text into an Abstract Syntax Tree.
"""

# Exported functions
export parse_asciidoc, parse_asciidoc_file, parse_inline

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
    parse_inline(text::AbstractString, attributes::Dict{String,String}=Dict{String,String}()) -> Vector{InlineNode}

Parse inline formatting within text using a Regex-based approach.

Optionally substitutes attribute references ({name}) with their values.
"""
function parse_inline(text::AbstractString, attributes::Dict{String,String}=Dict{String,String}())
    # Substitute attribute references first
    processed_text = text
    if !isempty(attributes)
        processed_text = substitute_attributes(text, attributes)
    end

    nodes = InlineNode[]
    last_idx = 1 # Tracks the end of the last processed segment

    # Iterate over all matches of the combined inline token pattern
    for m in eachmatch(INLINE_TOKEN_PATTERN, processed_text)
        # Add plain text before the current match
        if m.offset > last_idx
            push!(nodes, Text(String(processed_text[last_idx:m.offset-1])))
        end

        # Parse the matched inline token and add it to nodes
        push!(nodes, _parse_inline_match(m))

        # Update last_idx to the end of the current match
        last_idx = m.offset + length(m.match)
    end

    # Add any remaining plain text after the last match
    if last_idx <= length(processed_text)
        push!(nodes, Text(String(processed_text[last_idx:end])))
    end

    return nodes
end

"""
    substitute_attributes(text::AbstractString, attributes::Dict{String,String}) -> String

Substitute attribute references ({name}) in text with their values.
"""
function substitute_attributes(text::AbstractString, attributes::Dict{String,String})
    result = String(text)

    # Find and replace all {name} patterns
    for (name, value) in attributes
        # Use a simple regex replacement for each attribute
        pattern = Regex("\\{$name\\}")
        result = replace(result, pattern => value)
    end

    return result
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
    base_path::String  # Directory for resolving include paths
    include_stack::Vector{String}  # Track included files to prevent cycles
end

ParserState(text::String) = ParserState(split(text, '\n'), 1, Dict{String,String}(), pwd(), String[])
ParserState(text::String, base_path::String) = ParserState(split(text, '\n'), 1, Dict{String,String}(), base_path, String[])
ParserState(text::String, base_path::String, include_stack::Vector{String}) =
    ParserState(split(text, '\n'), 1, Dict{String,String}(), base_path, include_stack)

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
    parse_asciidoc(text::String; base_path::String=pwd()) -> Document

Parse an AsciiDoc document into an AST.

# Arguments
- `text`: The AsciiDoc source text
- `base_path`: Directory for resolving include directives (default: current directory)
"""
function parse_asciidoc(text::String; base_path::String=pwd())
    state = ParserState(text, base_path)
    return _parse_asciidoc_state(state)
end

"""
    parse_asciidoc_file(filepath::String) -> Document

Parse an AsciiDoc file into an AST. Automatically sets base_path for includes.
"""
function parse_asciidoc_file(filepath::String)
    abs_path = abspath(filepath)
    base_path = dirname(abs_path)
    text = read(filepath, String)
    state = ParserState(text, base_path, [abs_path])
    return _parse_asciidoc_state(state)
end

"""
    _parse_asciidoc_state(state::ParserState) -> Document

Internal function to parse with a given state.
"""
function _parse_asciidoc_state(state::ParserState)
    blocks = BlockNode[]

    while peek_line(state) !== nothing
        skip_blank_lines!(state)
        line = peek_line(state)
        line === nothing && break

        # Try to parse different block types
        if try_parse_attribute_definition(state)
            # Attribute was parsed, continue (doesn't produce a block)
            continue
        elseif (block = try_parse_header(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_code_block(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_block_quote(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_admonition(state)) !== nothing
            push!(blocks, block)
        elseif (included_blocks = try_parse_include(state)) !== nothing
            append!(blocks, included_blocks)
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
    try_parse_attribute_definition(state::ParserState) -> Bool

Try to parse a document attribute definition.

Supports:
- `:name: value` - set attribute
- `:name!:` - unset attribute

Returns true if an attribute line was parsed, false otherwise.
"""
function try_parse_attribute_definition(state::ParserState)
    line = peek_line(state)
    line === nothing && return false

    # Match attribute definition: :name: value
    m = match(r"^:([a-zA-Z0-9_-]+):\s*(.*)$", strip(line))
    if m !== nothing
        attr_name = String(m.captures[1])
        attr_value = String(m.captures[2])
        state.attributes[attr_name] = attr_value
        next_line!(state)
        return true
    end

    # Match attribute unset: :name!:
    m = match(r"^:([a-zA-Z0-9_-]+)!:$", strip(line))
    if m !== nothing
        attr_name = String(m.captures[1])
        delete!(state.attributes, attr_name)
        next_line!(state)
        return true
    end

    return false
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
        return Header(level, parse_inline(text, state.attributes), id)
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

# Valid admonition types
const ADMONITION_TYPES = ["NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION"]

"""
    try_parse_admonition(state::ParserState) -> Union{Admonition,Nothing}

Try to parse an admonition block.

Supports two forms:
1. Inline form: `NOTE: This is a note`
2. Block form:
   ```
   [NOTE]
   ====
   Content here
   ====
   ```
"""
function try_parse_admonition(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Try block form first: [NOTE] or [TIP] etc.
    block_match = match(r"^\[(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]$", strip(line))
    if block_match !== nothing
        admon_type = lowercase(String(block_match.captures[1]))
        next_line!(state)

        # Next line should be ==== delimiter
        delim_line = peek_line(state)
        if delim_line !== nothing && startswith(strip(delim_line), "====")
            next_line!(state)

            # Collect content until closing delimiter
            content_lines = String[]
            while (line = peek_line(state)) !== nothing
                if startswith(strip(line), "====")
                    next_line!(state)
                    break
                end
                push!(content_lines, line)
                next_line!(state)
            end

            # Parse the content as blocks
            content_text = join(content_lines, '\n')
            inner_doc = parse_asciidoc(content_text)

            return Admonition(admon_type, inner_doc.blocks)
        else
            # No ==== delimiter, treat rest as single paragraph until blank line
            content_lines = String[]
            while (line = peek_line(state)) !== nothing
                stripped = strip(line)
                if isempty(stripped)
                    break
                end
                push!(content_lines, line)
                next_line!(state)
            end

            if !isempty(content_lines)
                content_text = join(content_lines, " ")
                return Admonition(admon_type, [Paragraph(parse_inline(content_text, state.attributes))])
            else
                return Admonition(admon_type, BlockNode[])
            end
        end
    end

    # Try inline form: NOTE: text or TIP: text etc.
    inline_match = match(r"^(NOTE|TIP|IMPORTANT|WARNING|CAUTION):\s*(.*)$", line)
    if inline_match !== nothing
        admon_type = lowercase(String(inline_match.captures[1]))
        content = String(inline_match.captures[2])
        next_line!(state)

        # Collect continuation lines (non-blank, not starting with special syntax)
        while (line = peek_line(state)) !== nothing
            stripped = strip(line)

            # Stop at blank line
            if isempty(stripped)
                break
            end

            # Stop at block delimiters or special syntax
            if startswith(line, "=") || startswith(line, "----") ||
               startswith(line, "____") || startswith(line, "|===") ||
               startswith(line, "[") ||
               match(r"^\s*[\*\-]\s+", line) !== nothing ||
               match(r"^\s*\.+\s+", line) !== nothing ||
               match(r"^(NOTE|TIP|IMPORTANT|WARNING|CAUTION):", line) !== nothing
                break
            end

            content *= " " * stripped
            next_line!(state)
        end

        if !isempty(strip(content))
            return Admonition(admon_type, [Paragraph(parse_inline(content, state.attributes))])
        else
            return Admonition(admon_type, BlockNode[])
        end
    end

    return nothing
end

"""
    try_parse_include(state::ParserState) -> Union{Vector{BlockNode},Nothing}

Try to parse an include directive.

Supports:
- `include::path/to/file.adoc[]` - include entire file
- `include::path/to/file.adoc[lines=1..10]` - include specific lines
- `include::path/to/file.adoc[lines="1..5;10..15"]` - include multiple ranges
"""
function try_parse_include(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Match include directive: include::path[attributes]
    m = match(r"^include::([^\[]+)\[(.*)\]$", strip(line))
    if m === nothing
        return nothing
    end

    include_path = String(m.captures[1])
    attributes_str = String(m.captures[2])
    next_line!(state)

    # Resolve the path
    if isabspath(include_path)
        resolved_path = include_path
    else
        resolved_path = normpath(joinpath(state.base_path, include_path))
    end

    # Check for circular includes
    if resolved_path in state.include_stack
        @warn "Circular include detected: $resolved_path"
        return BlockNode[]
    end

    # Check if file exists
    if !isfile(resolved_path)
        @warn "Include file not found: $resolved_path"
        return BlockNode[]
    end

    # Read the file content
    content = read(resolved_path, String)

    # Parse attributes for line selection
    lines_attr = _parse_include_lines_attr(attributes_str)

    # Apply line filtering if specified
    if lines_attr !== nothing
        content_lines = split(content, '\n')
        selected_lines = _select_lines(content_lines, lines_attr)
        content = join(selected_lines, '\n')
    end

    # Parse the included content recursively
    new_include_stack = vcat(state.include_stack, [resolved_path])
    include_state = ParserState(content, dirname(resolved_path), new_include_stack)
    included_doc = _parse_asciidoc_state(include_state)

    return included_doc.blocks
end

"""
    _parse_include_lines_attr(attr_str::String) -> Union{Vector{UnitRange{Int}},Nothing}

Parse the lines= attribute from include directive.

Supports formats:
- `lines=5` - single line
- `lines=1..10` - range
- `lines=1..5;10..15` - multiple ranges
- `lines="1..5;10..15"` - quoted
"""
function _parse_include_lines_attr(attr_str::String)
    # Look for lines= attribute
    m = match(r"lines=[\"']?([^\"'\]]+)[\"']?", attr_str)
    if m === nothing
        return nothing
    end

    lines_spec = String(m.captures[1])
    ranges = UnitRange{Int}[]

    # Split by semicolon for multiple ranges
    for part in split(lines_spec, ';')
        part = strip(part)
        if isempty(part)
            continue
        end

        # Check for range (start..end)
        range_match = match(r"^(\d+)\.\.(\d+)$", part)
        if range_match !== nothing
            start_line = Base.parse(Int, range_match.captures[1])
            end_line = Base.parse(Int, range_match.captures[2])
            push!(ranges, start_line:end_line)
            continue
        end

        # Check for single line
        if match(r"^\d+$", part) !== nothing
            line_num = Base.parse(Int, part)
            push!(ranges, line_num:line_num)
        end
    end

    return isempty(ranges) ? nothing : ranges
end

"""
    _select_lines(lines::Vector, ranges::Vector{UnitRange{Int}}) -> Vector{String}

Select lines based on the given ranges.
"""
function _select_lines(lines::AbstractVector, ranges::Vector{UnitRange{Int}})
    selected = String[]

    for range in ranges
        for i in range
            if 1 <= i <= length(lines)
                push!(selected, String(lines[i]))
            end
        end
    end

    return selected
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

        push!(items, ListItem(parse_inline(content, state.attributes)))
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

        push!(items, ListItem(parse_inline(content, state.attributes)))
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
            push!(items, (DefinitionTerm(parse_inline(term, state.attributes)),
                         DefinitionDescription(parse_inline(strip(desc_line), state.attributes))))
        else
            push!(items, (DefinitionTerm(parse_inline(term, state.attributes)),
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
                        push!(current_row_cells, TableCell(parse_inline(String(cell_content), state.attributes)))
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
        return Paragraph(parse_inline(text, state.attributes))
    end

    return nothing
end