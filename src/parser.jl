"""
Parser for AsciiDoc documents.

This module provides functions to parse AsciiDoc text into an Abstract Syntax Tree.
"""

export parse_asciidoc, parse_asciidoc_file, parse_inline

# Order matters in the regex alternation; more specific patterns must come first.
const INLINE_TOKEN_PATTERN = Regex(
    raw"""
    # Cross-reference: <<target,text>> or <<target>>
    (?<xref><<([^,>]+?)(?:,([^>]+?))?>>) | 

    # Image: image:url[alt]
    (?<image>image:([^\[]+?)(?:\b\[([^\]]*?)\])?) | 

    # Generic Link Macro: link:target[text]
    (?<linkmacro>link:([^\[]+?)(?:\[([^\]]*?)\])) | 

    # Inline Math: stem:[content]
    (?<stem>stem:\[([^\]]*?)\]) | 

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
    "x"  # Extended mode allows comments and whitespace in the pattern.
)

"""
    _parse_inline_match(m::RegexMatch) -> InlineNode

Helper function to convert a RegexMatch for an inline token into an InlineNode.
Recursively calls `parse_inline` for nested content.
"""
function _parse_inline_match(m::RegexMatch)
    if m[:xref] !== nothing
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
    elseif m[:linkmacro] !== nothing
        sub_m = match(r"^link:([^\[]+?)(?:\[([^\]]*?)\])$", m[:linkmacro])
        if sub_m !== nothing
            url = String(sub_m.captures[1])
            text_cap = sub_m.captures[2]
            if text_cap !== nothing && !isempty(text_cap)
                return Link(url, parse_inline(String(text_cap)))
            else
                return Link(url)
            end
        end
    elseif m[:stem] !== nothing
        sub_m = match(r"^stem:\[([^\]]*?)\]$", m[:stem])
        if sub_m !== nothing
            content = String(sub_m.captures[1])
            return InlineMath(content)
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
    # Fallback for unmatched patterns, which indicates the regex is incomplete.
    @warn "Failed to parse inline match: $(m.match). Returning as plain text."
    return Text(String(m.match))
end

"""
    parse_inline(text::AbstractString, attributes::Dict{String,String}=Dict{String,String}()) -> Vector{InlineNode}

Parse inline formatting within text using a Regex-based approach.

Optionally substitutes attribute references ({name}) with their values.
"""
function parse_inline(text::AbstractString, attributes::Dict{String,String}=Dict{String,String}())
    processed_text = text
    if !isempty(attributes)
        processed_text = substitute_attributes(text, attributes)
    end

    nodes = InlineNode[]
    last_idx = 1

    for m in eachmatch(INLINE_TOKEN_PATTERN, processed_text)
        if m.offset > last_idx
            push!(nodes, Text(String(processed_text[last_idx:m.offset-1])))
        end

        push!(nodes, _parse_inline_match(m))
        last_idx = m.offset + length(m.match)
    end

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

    for (name, value) in attributes
        pattern = Regex("\\{$name\\}")
        result = replace(result, pattern => value)
    end

    return result
end

"""
    _builtin_attributes() -> Dict{String,String}

Return a dictionary of built-in AsciiDoc attributes.
These are automatically available in all documents.
"""
function _builtin_attributes()
    Dict{String,String}(
        # Special characters
        "nbsp" => "\u00A0",      # Non-breaking space
        "sp" => " ",              # Space
        "empty" => "",            # Empty string
        "blank" => "",            # Blank (same as empty)
        "amp" => "&",             # Ampersand
        "lt" => "<",              # Less than
        "gt" => ">",              # Greater than
        "quot" => "\"",           # Quotation mark
        "apos" => "'",            # Apostrophe
        "brvbar" => "¦",          # Broken vertical bar
        "vbar" => "|",            # Vertical bar
        "zwsp" => "\u200B",       # Zero-width space
        "wj" => "\u2060",         # Word joiner
        "deg" => "°",             # Degree symbol
        "plus" => "+",            # Plus sign
        "caret" => "^",           # Caret
        "tilde" => "~",           # Tilde
        "backslash" => "\\",      # Backslash
        "backtick" => "`",        # Backtick
        "startsb" => "[",         # Left square bracket
        "endsb" => "]",           # Right square bracket
        "lsquo" => "\u2018",      # Left single quote '
        "rsquo" => "\u2019",      # Right single quote '
        "ldquo" => "\u201C",      # Left double quote "
        "rdquo" => "\u201D",      # Right double quote "
        "two-colons" => "::",     # Double colon
        "two-semicolons" => ";;", # Double semicolon
        "cpp" => "C++",           # C++
    )
end

"""
    ParserState

Internal state for the parser.
"""
mutable struct ParserState
    lines::Vector{String}
    pos::Int
    attributes::Dict{String,String}
    base_path::String
    include_stack::Vector{String}  # Prevents circular includes.
end

ParserState(text::String) = ParserState(split(text, '\n'), 1, _builtin_attributes(), pwd(), String[])
ParserState(text::String, base_path::String) = ParserState(split(text, '\n'), 1, _builtin_attributes(), base_path, String[])
ParserState(text::String, base_path::String, include_stack::Vector{String}) =
    ParserState(split(text, '\n'), 1, _builtin_attributes(), base_path, include_stack)

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
    try_skip_comment(state::ParserState) -> Bool

Try to skip a comment (single-line or block).

Single-line comments start with `//` (but not `////` which is a block delimiter).
Block comments are delimited by `////` on their own lines.

Returns true if a comment was skipped, false otherwise.
"""
function try_skip_comment(state::ParserState)
    line = peek_line(state)
    line === nothing && return false

    stripped = strip(line)

    # Block comment: //// ... ////
    if stripped == "////"
        next_line!(state)  # consume opening ////

        # Skip until closing ////
        while (line = peek_line(state)) !== nothing
            if strip(line) == "////"
                next_line!(state)  # consume closing ////
                break
            end
            next_line!(state)
        end
        return true
    end

    # Single-line comment: // (but not //// which is block delimiter)
    if startswith(stripped, "//") && !startswith(stripped, "////")
        next_line!(state)
        return true
    end

    return false
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

        # Skip comments first (they produce no output)
        if try_skip_comment(state)
            continue
        elseif try_parse_attribute_definition(state)
            continue
        elseif (block = try_parse_header(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_code_block(state)) !== nothing
            push!(blocks, block)
        elseif (block = try_parse_passthrough_block(state)) !== nothing
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
        elseif (block = try_parse_block_image(state)) !== nothing
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

    m = match(r"^:([a-zA-Z0-9_-]+):\s*(.*)$", strip(line))
    if m !== nothing
        attr_name = String(m.captures[1])
        attr_value = String(m.captures[2])
        state.attributes[attr_name] = attr_value
        next_line!(state)
        return true
    end

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
    generate_header_id(text::AbstractString) -> String

Generate an ID from header text following AsciiDoc conventions.

- Converts to lowercase
- Replaces spaces and non-alphanumeric chars with hyphens
- Removes consecutive hyphens
- Removes leading/trailing hyphens
- Prefixes with underscore if starting with a digit
"""
function generate_header_id(text::AbstractString)
    # Remove inline markup symbols for cleaner IDs
    clean = replace(text, r"[*_`~^]" => "")
    # Convert to lowercase
    clean = lowercase(clean)
    # Replace non-alphanumeric chars with hyphens
    clean = replace(clean, r"[^a-z0-9]+" => "-")
    # Remove leading/trailing hyphens
    clean = strip(clean, '-')
    # Handle empty result
    isempty(clean) && return "_"
    # Prefix with underscore if starting with digit
    if isdigit(clean[1])
        clean = "_" * clean
    end
    return clean
end

"""
    try_parse_header(state::ParserState) -> Union{Header,Nothing}

Try to parse a header (= Title).
"""
function try_parse_header(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    m = match(r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$", line)
    if m !== nothing
        level = length(m.captures[1])
        text = m.captures[2]
        # Use explicit ID if provided, otherwise auto-generate
        id = if m.captures[3] !== nothing
            String(m.captures[3])
        else
            generate_header_id(text)
        end
        next_line!(state)
        return Header(level, parse_inline(text, state.attributes), id)
    end

    return nothing
end

"""
    _parse_callout_definitions(state::ParserState) -> Dict{Int,String}

Parse callout definitions that follow a code block.
Callouts have syntax: `<1> Explanation text`
"""
function _parse_callout_definitions(state::ParserState)
    callouts = Dict{Int,String}()

    while (line = peek_line(state)) !== nothing
        m = match(r"^<(\d+)>\s+(.+)$", line)
        if m !== nothing
            num = Base.parse(Int, m.captures[1])
            text = String(m.captures[2])
            callouts[num] = text
            next_line!(state)
        else
            # No more callout definitions
            break
        end
    end

    return callouts
end

"""
    try_parse_code_block(state::ParserState) -> Union{CodeBlock,Nothing}

Try to parse a code block (----).

Supports:
- `----` (plain code block)
- `[source,lang]` (code block with language)
- `[source,lang,linenums]` or `[source,lang%linenums]` (with line numbers)
- Callout markers `<1>` in code with definitions after the block
"""
function try_parse_code_block(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    if startswith(line, "----")
        next_line!(state)

        language = ""
        code_lines = String[]
        while (line = peek_line(state)) !== nothing
            if startswith(line, "----")
                next_line!(state)
                break
            end
            push!(code_lines, line)
            next_line!(state)
        end

        # Parse callout definitions after the code block
        callouts = _parse_callout_definitions(state)

        return CodeBlock(join(code_lines, '\n'), language, Dict{String,String}(), callouts)
    end

    # Parse [source,...] with options
    # Allow @-prefixed languages for Documenter.jl blocks (@docs, @example, @repl, etc.)
    m = match(r"^\[source(?:,\s*(@?\w+[\w\s]*))?((?:,\s*\w+|%\w+)*)\]$", line)
    if m !== nothing
        language = m.captures[1] !== nothing ? String(m.captures[1]) : ""
        options_str = m.captures[2] !== nothing ? String(m.captures[2]) : ""

        # Parse attributes from options
        attrs = Dict{String,String}()
        if contains(options_str, "linenums") || contains(options_str, "%linenums")
            attrs["linenums"] = "true"
        end

        next_line!(state)

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

            # Parse callout definitions after the code block
            callouts = _parse_callout_definitions(state)

            return CodeBlock(join(code_lines, '\n'), language, attrs, callouts)
        end
    end

    return nothing
end

"""
    try_parse_passthrough_block(state::ParserState) -> Union{PassthroughBlock,Nothing}

Try to parse a passthrough block (++++).
Supports attributes like `[stem]` or `[latexmath]` preceding the block.
"""
function try_parse_passthrough_block(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    attrs = Dict{String,String}()
    
    # Check for attributes/style
    # Allow [stem] or [latexmath] or normal attributes
    attr_match = match(r"^\[([^\]]+)\]\s*$", strip(line))
    if attr_match !== nothing
        # Lookahead for ++++
        if state.pos + 1 <= length(state.lines)
            next_line_content = state.lines[state.pos + 1]
            if startswith(next_line_content, "++++")
                attr_str = attr_match.captures[1]
                # If simple style like [stem], treat as style attribute
                if !contains(attr_str, "=") && !contains(attr_str, ",")
                    attrs["style"] = String(attr_str)
                else
                    _parse_block_attributes!(attrs, String(attr_str))
                end
                next_line!(state) # consume attributes
                line = peek_line(state)
            end
        end
    end

    if startswith(line, "++++")
        next_line!(state)

        content_lines = String[]
        while (line = peek_line(state)) !== nothing
            if startswith(line, "++++")
                next_line!(state)
                break
            end
            push!(content_lines, line)
            next_line!(state)
        end

        return PassthroughBlock(join(content_lines, '\n'), attrs)
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

        content_lines = String[]
        while (line = peek_line(state)) !== nothing
            if startswith(line, "____")
                next_line!(state)
                break
            end
            push!(content_lines, line)
            next_line!(state)
        end

        content_text = join(content_lines, '\n')
        inner_doc = parse_asciidoc(content_text)

        return BlockQuote(inner_doc.blocks)
    end

    return nothing
end

const ADMONITION_TYPES = ["NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION"]

"""
    try_parse_admonition(state::ParserState) -> Union{Admonition,Nothing}

Try to parse an admonition block.

Supports two forms:
1. Inline form: `NOTE: This is a note`
2. Block form:
   ```
   [NOTE]
   .Optional Title
   ====
   Content here
   ====
   ```
"""
function try_parse_admonition(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    block_match = match(r"^\[(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]$", strip(line))
    if block_match !== nothing
        admon_type = lowercase(String(block_match.captures[1]))
        next_line!(state)

        # Check for optional title (.Title syntax)
        title = ""
        next_line_content = peek_line(state)
        if next_line_content !== nothing
            title_match = match(r"^\.(.+)$", strip(next_line_content))
            if title_match !== nothing
                title = String(title_match.captures[1])
                next_line!(state)
            end
        end

        delim_line = peek_line(state)
        if delim_line !== nothing && startswith(strip(delim_line), "====")
            next_line!(state)

            content_lines = String[]
            while (line = peek_line(state)) !== nothing
                if startswith(strip(line), "====")
                    next_line!(state)
                    break
                end
                push!(content_lines, line)
                next_line!(state)
            end

            content_text = join(content_lines, '\n')
            inner_doc = parse_asciidoc(content_text)

            return Admonition(admon_type, inner_doc.blocks, title)
        else
            # No delimiter means single paragraph until blank line.
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
                return Admonition(admon_type, BlockNode[Paragraph(parse_inline(content_text, state.attributes))], title)
            else
                return Admonition(admon_type, BlockNode[], title)
            end
        end
    end

    inline_match = match(r"^(NOTE|TIP|IMPORTANT|WARNING|CAUTION):\s*(.*)$", line)
    if inline_match !== nothing
        admon_type = lowercase(String(inline_match.captures[1]))
        content = String(inline_match.captures[2])
        next_line!(state)

        while (line = peek_line(state)) !== nothing
            stripped = strip(line)

            if isempty(stripped)
                break
            end

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
            return Admonition(admon_type, BlockNode[Paragraph(parse_inline(content, state.attributes))])
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

    m = match(r"^include::([^\[]+)\[(.*)\]$", strip(line))
    if m === nothing
        return nothing
    end

    include_path = String(m.captures[1])
    attributes_str = String(m.captures[2])
    next_line!(state)

    if isabspath(include_path)
        resolved_path = include_path
    else
        resolved_path = normpath(joinpath(state.base_path, include_path))
    end

    if resolved_path in state.include_stack
        @warn "Circular include detected: $resolved_path"
        return BlockNode[]
    end

    if !isfile(resolved_path)
        @warn "Include file not found: $resolved_path"
        return BlockNode[]
    end

    content = read(resolved_path, String)
    lines_attr = _parse_include_lines_attr(attributes_str)

    if lines_attr !== nothing
        content_lines = split(content, '\n')
        selected_lines = _select_lines(content_lines, lines_attr)
        content = join(selected_lines, '\n')
    end

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
    m = match(r"lines=[\"']?([^\"'\]]+)[\"']?", attr_str)
    if m === nothing
        return nothing
    end

    lines_spec = String(m.captures[1])
    ranges = UnitRange{Int}[]

    for part in split(lines_spec, ';')
        part = strip(part)
        if isempty(part)
            continue
        end

        range_match = match(r"^(\d+)\.\.(\d+)$", part)
        if range_match !== nothing
            start_line = Base.parse(Int, range_match.captures[1])
            end_line = Base.parse(Int, range_match.captures[2])
            push!(ranges, start_line:end_line)
            continue
        end

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

Supports attribute blocks before lists like `[start=5]` for ordered lists.
"""
function try_parse_list(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    list_attrs = Dict{String,String}()

    # Check for attribute block before list - use lookahead
    attr_match = match(r"^\[([^\]]+)\]\s*$", strip(line))
    if attr_match !== nothing
        # Lookahead: check if next line is a list item
        if state.pos + 1 <= length(state.lines)
            next_line_content = state.lines[state.pos + 1]
            if match(r"^[\*\-\.]+\s+", next_line_content) !== nothing ||
               match(r"^\d+\.\s+", next_line_content) !== nothing
                # This is a list with attributes - consume the attribute line
                attr_str = attr_match.captures[1]
                _parse_block_attributes!(list_attrs, String(attr_str))
                next_line!(state)
                line = peek_line(state)
            end
        end
    end

    # Unordered list: *, **, ***, or -
    if match(r"^\*+\s+", line) !== nothing || match(r"^-\s+", line) !== nothing
        return parse_unordered_list(state)
    end

    # Ordered list: ., .., ..., or 1. 2. etc.
    if match(r"^\.+\s+", line) !== nothing || match(r"^\d+\.\s+", line) !== nothing
        return parse_ordered_list(state, 1, list_attrs)
    end

    # Definition list: term::
    if match(r"^.+::\s*$", line) !== nothing
        return parse_definition_list(state)
    end

    return nothing
end

"""
    parse_unordered_list(state::ParserState, level::Int=1) -> UnorderedList

Parse an unordered list with support for nesting.

AsciiDoc nesting uses multiple markers:
- `*` = level 1
- `**` = level 2
- `***` = level 3, etc.
"""
function parse_unordered_list(state::ParserState, level::Int=1)
    items = ListItem[]

    while (line = peek_line(state)) !== nothing
        # Match unordered list item: capture marker and content
        m = match(r"^(\*+|-)\s+(.*)$", line)
        if m === nothing
            break
        end

        marker = m.captures[1]
        item_level = marker == "-" ? 1 : length(marker)

        # If this item is at a higher level (fewer *), we're done with this list
        if item_level < level
            break
        end

        # If this item is at a deeper level, it belongs to a nested list
        if item_level > level
            # Don't consume this line - let nested parsing handle it
            # Attach nested list to the last item
            if !isempty(items)
                nested = parse_unordered_list(state, item_level)
                # Replace last item with one that has the nested list
                last_item = items[end]
                items[end] = ListItem(last_item.content, nested)
            else
                # No parent item - skip this malformed nested item
                next_line!(state)
            end
            continue
        end

        # This item is at our level - consume it
        content = String(m.captures[2])
        next_line!(state)

        push!(items, ListItem(parse_inline(content, state.attributes)))
    end

    return UnorderedList(items)
end

"""
    parse_ordered_list(state::ParserState, level::Int=1, attrs::Dict{String,String}=Dict{String,String}()) -> OrderedList

Parse an ordered list with support for nesting.

AsciiDoc nesting uses multiple dots:
- `.` = level 1
- `..` = level 2
- `...` = level 3, etc.

Numbered format (1., 2., etc.) is always treated as level 1.

Supports attributes like `[start=5]` for custom starting number.
"""
function parse_ordered_list(state::ParserState, level::Int=1, attrs::Dict{String,String}=Dict{String,String}())
    items = ListItem[]

    while (line = peek_line(state)) !== nothing
        # Match ordered list item: dots or number followed by content
        m = match(r"^(\.+|\d+\.)\s+(.*)$", line)
        if m === nothing
            break
        end

        marker = String(m.captures[1])
        # Numbered markers (1., 2., etc.) are always level 1
        # Dot markers have level = number of dots
        item_level = isdigit(marker[1]) ? 1 : length(marker)

        # If this item is at a higher level (fewer dots), we're done with this list
        if item_level < level
            break
        end

        # If this item is at a deeper level, it belongs to a nested list
        if item_level > level
            # Don't consume this line - let nested parsing handle it
            # Attach nested list to the last item
            if !isempty(items)
                nested = parse_ordered_list(state, item_level)
                # Replace last item with one that has the nested list
                last_item = items[end]
                items[end] = ListItem(last_item.content, nested)
            else
                # No parent item - skip this malformed nested item
                next_line!(state)
            end
            continue
        end

        # This item is at our level - consume it
        content = String(m.captures[2])
        next_line!(state)

        push!(items, ListItem(parse_inline(content, state.attributes)))
    end

    return OrderedList(items, "arabic", attrs)
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

Try to parse a table (|===), including preceding attribute block.

Supports:
- `[cols="1,1,1"]` - column specification
- `[options="header"]` - table options
"""
function try_parse_table(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    table_attrs = Dict{String,String}()
    has_attrs = false

    # Check for attribute block before table - use lookahead
    attr_match = match(r"^\[([^\]]+)\]\s*$", strip(line))
    if attr_match !== nothing
        # Lookahead: check if next line is table start (without consuming current line)
        if state.pos + 1 <= length(state.lines)
            next_line_content = state.lines[state.pos + 1]
            if startswith(next_line_content, "|===")
                # This is a table with attributes - consume the attribute line
                attr_str = attr_match.captures[1]
                _parse_block_attributes!(table_attrs, String(attr_str))
                next_line!(state)
                line = peek_line(state)
                has_attrs = true
            end
        end
    end

    if line !== nothing && startswith(line, "|===")
        next_line!(state)

        rows = TableRow[]
        current_row_cells = TableCell[]

        # Check if header option is set
        has_header_option = haskey(table_attrs, "options") &&
                           contains(table_attrs["options"], "header")

        while (line = peek_line(state)) !== nothing
            if startswith(line, "|===")
                if !isempty(current_row_cells)
                    push!(rows, TableRow(current_row_cells))
                end
                next_line!(state)
                break
            end

            if startswith(line, "|")
                cells = split(line[2:end], '|')
                for cell in cells
                    cell_content = strip(cell)
                    if !isempty(cell_content)
                        cell_attrs = Dict{String,String}()

                        # Parse span syntax: 2+ (colspan), .2+ (rowspan), 2.3+ (both)
                        span_match = match(r"^(\d+)?\.?(\d+)?\+\s*(.*)$", cell_content)
                        if span_match !== nothing
                            colspan = span_match.captures[1]
                            rowspan = span_match.captures[2]
                            cell_content = span_match.captures[3] !== nothing ? String(span_match.captures[3]) : ""

                            if colspan !== nothing
                                cell_attrs["colspan"] = String(colspan)
                            end
                            if rowspan !== nothing
                                cell_attrs["rowspan"] = String(rowspan)
                            end
                        end

                        push!(current_row_cells, TableCell(parse_inline(String(cell_content), state.attributes), cell_attrs))
                    end
                end

                if !isempty(current_row_cells)
                    # First row is header if option is set
                    is_header = isempty(rows) && has_header_option
                    push!(rows, TableRow(current_row_cells, is_header))
                    current_row_cells = TableCell[]
                end
            end

            next_line!(state)
        end

        return Table(rows, table_attrs)
    end

    return nothing
end

"""
    _parse_block_attributes!(attrs::Dict{String,String}, attr_str::String)

Parse block attributes like `cols="1,1,1", options="header"` into a dictionary.

Also handles shorthand options like `%header`, `%footer`, `%autowidth`.
"""
function _parse_block_attributes!(attrs::Dict{String,String}, attr_str::String)
    # Handle various formats:
    # - cols="1,1,1"
    # - options="header"
    # - cols="1,1,1", options="header"
    # - %header (shorthand for options="header")

    # Handle shorthand %option syntax (e.g., %header, %footer, %autowidth)
    for m in eachmatch(r"%(\w+)", attr_str)
        option = String(m.captures[1])
        # Store in options, appending if already exists
        if haskey(attrs, "options")
            attrs["options"] *= "," * option
        else
            attrs["options"] = option
        end
    end

    # Simple key=value parsing (handles quoted values)
    for m in eachmatch(r"(\w+)\s*=\s*\"([^\"]*)\"|(\w+)\s*=\s*([^\s,\]]+)", attr_str)
        if m.captures[1] !== nothing
            # Quoted value: key="value"
            attrs[String(m.captures[1])] = String(m.captures[2])
        elseif m.captures[3] !== nothing
            # Unquoted value: key=value
            attrs[String(m.captures[3])] = String(m.captures[4])
        end
    end
end

"""
    try_parse_block_image(state::ParserState) -> Union{Paragraph,Nothing}

Try to parse a block image (image::path[alt]).

Block images use double colons and stand alone on a line.
Returns a Paragraph containing just the Image node.
"""
function try_parse_block_image(state::ParserState)
    line = peek_line(state)
    line === nothing && return nothing

    # Block image: image::path[alt,width,height]
    m = match(r"^image::([^\[]+)\[([^\]]*)\]\s*$", strip(line))
    if m !== nothing
        url = String(m.captures[1])
        attrs_str = String(m.captures[2])
        next_line!(state)

        # Parse attributes: first is alt text, then named attrs like width=, height=
        attrs = Dict{String,String}()
        alt_text = ""

        if !isempty(attrs_str)
            parts = split(attrs_str, ',')
            for (i, part) in enumerate(parts)
                part = strip(String(part))
                if i == 1 && !contains(part, "=")
                    # First part without = is alt text
                    alt_text = part
                elseif contains(part, "=")
                    kv = split(part, '=', limit=2)
                    if length(kv) == 2
                        attrs[strip(String(kv[1]))] = strip(String(kv[2]))
                    end
                end
            end
        end

        return Paragraph(InlineNode[Image(url, alt_text, attrs)])
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

    lines = String[]

    while (line = peek_line(state)) !== nothing
        stripped = strip(line)

        if isempty(stripped)
            break
        end

        # Break on block boundaries
        if startswith(line, "=") || startswith(line, "----") ||
           startswith(line, "____") || startswith(line, "|===") ||
           startswith(stripped, "//") ||  # Comments (single-line or block)
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