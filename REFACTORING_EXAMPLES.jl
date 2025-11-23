# Idiomatic Julia Refactoring Examples
# Showing how to rewrite key parts of AsciiDoc.jl in a more Julian way

#==============================================================================
# 1. INLINE PARSER - Complete Rewrite
#==============================================================================#

# BEFORE (Un-Julian: manual index tracking, string concatenation in loop)
function parse_inline_OLD(text::String)
    nodes = InlineNode[]
    i = 1
    current_text = ""

    while i <= length(text)
        char = text[i]
        if char == '*' && i < length(text) && text[i+1] != ' '
            if !isempty(current_text)
                push!(nodes, Text(current_text))
                current_text = ""
            end
            close_idx = findnext('*', text, i+1)
            if close_idx !== nothing
                content = text[i+1:close_idx-1]
                push!(nodes, Bold(parse_inline(content)))
                i = close_idx + 1
                continue
            end
        end
        current_text *= char
        i += 1
    end

    if !isempty(current_text)
        push!(nodes, Text(current_text))
    end
    nodes
end

# AFTER (Julian: regex-based, functional style)

# Define patterns as constants
const INLINE_PATTERNS = [
    :bold      => r"\*(?<content>[^\*]+)\*",
    :italic    => r"_(?<content>[^_]+)_",
    :mono      => r"`(?<content>[^`]+)`",
    :subscript => r"~(?<content>[^~]+)~",
    :super     => r"\^(?<content>[^\^]+)\^",
    :link      => r"(?<url>https?://[^\s\[\]]+)(?:\[(?<text>[^\]]+)\])?",
    :image     => r"image:(?<url>[^\[]+)(?:\[(?<alt>[^\]]*)\])?",
    :xref      => r"<<(?<target>[^,>]+)(?:,(?<text>[^>]+))?>>",
]

# Build combined pattern
const INLINE_COMBINED = Regex(
    "(" * join([p.pattern for (_, p) in INLINE_PATTERNS], "|") * ")"
)

"""Parse inline formatting using regex and multiple dispatch"""
function parse_inline(text::String)::Vector{InlineNode}
    nodes = InlineNode[]
    last_pos = 1

    for m in eachmatch(INLINE_COMBINED, text)
        # Add text before match
        if m.offset > last_pos
            text_content = text[last_pos:m.offset-1]
            !isempty(text_content) && push!(nodes, Text(text_content))
        end

        # Parse the match using dispatch
        push!(nodes, parse_inline_match(m))
        last_pos = m.offset + ncodeunits(m.match)
    end

    # Add remaining text
    if last_pos <= ncodeunits(text)
        remaining = text[last_pos:end]
        !isempty(remaining) && push!(nodes, Text(remaining))
    end

    nodes
end

# Use multiple dispatch to handle different match types
function parse_inline_match(m::RegexMatch)
    # Determine which pattern matched and dispatch accordingly
    if occursin(r"\*[^\*]+\*", m.match)
        content = m.match[2:end-1]  # strip asterisks
        Bold(parse_inline(content))
    elseif occursin(r"_[^_]+_", m.match)
        content = m.match[2:end-1]
        Italic(parse_inline(content))
    elseif occursin(r"`[^`]+`", m.match)
        content = m.match[2:end-1]
        Monospace([Text(content)])
    elseif occursin(r"~[^~]+~", m.match)
        content = m.match[2:end-1]
        Subscript(parse_inline(content))
    elseif occursin(r"\^[^\^]+\^", m.match)
        content = m.match[2:end-1]
        Superscript(parse_inline(content))
    elseif startswith(m.match, "http")
        parse_link(m)
    elseif startswith(m.match, "image:")
        parse_image(m)
    elseif startswith(m.match, "<<")
        parse_xref(m)
    else
        Text(m.match)
    end
end

# Even better: Use a parser combinator approach
using ParserCombinator  # hypothetical - there are Julia parsing libraries

bold_parser = between('*', '*', many1(not_char('*'))) do content
    Bold([Text(String(content))])
end

#==============================================================================
# 2. PARSER STATE - Make it an Iterator
#==============================================================================#

# BEFORE (Imperative with mutation)
mutable struct ParserState
    lines::Vector{String}
    pos::Int
    attributes::Dict{String,String}
end

function next_line!(state::ParserState)
    if state.pos <= length(state.lines)
        line = state.lines[state.pos]
        state.pos += 1
        return line
    end
    return nothing
end

# AFTER (Iterator protocol)
struct DocumentLines
    lines::Vector{String}
    attributes::Dict{String,String}
end

DocumentLines(text::String) = DocumentLines(split(text, '\n'), Dict{String,String}())

# Make it iterable
Base.iterate(doc::DocumentLines) =
    isempty(doc.lines) ? nothing : (doc.lines[1], 2)

Base.iterate(doc::DocumentLines, state::Int) =
    state > length(doc.lines) ? nothing : (doc.lines[state], state + 1)

Base.length(doc::DocumentLines) = length(doc.lines)
Base.eltype(::Type{DocumentLines}) = String

# Use with Stateful for peek/lookahead
function parse_asciidoc(text::String)
    lines = Iterators.Stateful(DocumentLines(text))
    blocks = BlockNode[]

    for line in lines
        # Can use peek(lines) to look ahead
        # Use popfirst!(lines) to consume
        block = parse_block(line, lines)
        !isnothing(block) && push!(blocks, block)
    end

    Document(Dict{String,String}(), blocks)
end

#==============================================================================
# 3. BLOCK PARSING - Use Dispatch Table
#==============================================================================#

# BEFORE (Long if-elseif chain)
function parse_block_OLD(line, state)
    if (block = try_parse_header(state)) !== nothing
        return block
    elseif (block = try_parse_code_block(state)) !== nothing
        return block
    elseif (block = try_parse_block_quote(state)) !== nothing
        return block
    # ... many more elseifs
    end
end

# AFTER (Dispatch table + priority)
const BLOCK_PARSERS = [
    try_parse_header,
    try_parse_code_block,
    try_parse_block_quote,
    try_parse_horizontal_rule,
    try_parse_list,
    try_parse_table,
    try_parse_paragraph,  # lowest priority
]

function parse_block(line::String, lines)
    for parser in BLOCK_PARSERS
        block = parser(line, lines)
        !isnothing(block) && return block
    end
    nothing
end

# Or even better: Use traits/dispatch on line type
abstract type LineType end
struct HeaderLine <: LineType end
struct ListLine <: LineType end
struct CodeLine <: LineType end
struct ParagraphLine <: LineType end

classify_line(line::String) =
    startswith(line, "=") ? HeaderLine() :
    occursin(r"^\s*[\*\-]\s", line) ? ListLine() :
    startswith(line, "----") ? CodeLine() :
    ParagraphLine()

# Then dispatch on line type
parse_block(line::String, ::HeaderLine, lines) = parse_header(line)
parse_block(line::String, ::ListLine, lines) = parse_list(line, lines)
# etc.

#==============================================================================
# 4. CONSTANT REGEXES
#==============================================================================#

# BEFORE (Compiled every time)
function try_parse_header(state)
    m = match(r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$", line)
end

# AFTER (Define once)
const HEADER_RE = r"^(=+)\s+(.+?)(?:\s*\[#([^\]]+)\])?$"
const CODE_BLOCK_RE = r"^\[source,\s*(\w+)\]$"
const LIST_ITEM_RE = r"^\s*[\*\-]\s+(.+)$"
const ORDERED_LIST_RE = r"^\s*(?:\.+|\d+\.)\s+(.+)$"
const DEF_LIST_RE = r"^(.+)::\s*$"
const TABLE_START_RE = r"^\|===$"

function try_parse_header(line::String, lines)
    m = match(HEADER_RE, line)
    isnothing(m) && return nothing

    level = length(m.captures[1])
    text = m.captures[2]
    id = something(m.captures[3], "")

    Header(level, parse_inline(text), id)
end

#==============================================================================
# 5. BACKEND - More Consistent
#==============================================================================#

# Option A: Functions (simple)
to_latex(doc::Document) = join(to_latex.(doc.blocks), "\n\n")
to_latex(h::Header) = "\\section{$(join(to_latex.(h.text)))}"
to_latex(p::Paragraph) = join(to_latex.(p.content))
to_latex(t::Text) = escape_latex(t.content)
to_latex(b::Bold) = "\\textbf{$(join(to_latex.(b.content)))}"

# Option B: Callable type (more extensible)
abstract type Backend end

struct LaTeXBackend <: Backend end
struct HTMLBackend <: Backend end

const LaTeX = LaTeXBackend()
const HTML = HTMLBackend()

# Use functor pattern
(::LaTeXBackend)(doc::Document) = render(LaTeX, doc)
(::HTMLBackend)(doc::Document) = render(HTML, doc)

render(::LaTeXBackend, doc::Document) = join(render.(Ref(LaTeX), doc.blocks), "\n\n")
render(::LaTeXBackend, h::Header) = "\\section{$(join(render.(Ref(LaTeX), h.text)))}"
render(::LaTeXBackend, t::Text) = escape_latex(t.content)

# Usage:
latex_output = LaTeX(doc)
html_output = HTML(doc)

#==============================================================================
# 6. STRING ESCAPING - More Efficient
#==============================================================================#

# BEFORE (Multiple passes)
function escape_latex_OLD(text::String)
    result = text
    result = replace(result, "\\" => "\\textbackslash{}")
    for (char, replacement) in replacements[2:end]
        result = replace(result, char => replacement)
    end
    result
end

# AFTER (Single pass with character mapping)
const LATEX_ESCAPE_MAP = Dict(
    '\\' => "\\textbackslash{}",
    '{' => "\\{",
    '}' => "\\}",
    '$' => "\\\$",
    '&' => "\\&",
    '%' => "\\%",
    '#' => "\\#",
    '_' => "\\_",
    '~' => "\\textasciitilde{}",
    '^' => "\\textasciicircum{}"
)

function escape_latex(text::String)
    io = IOBuffer()
    for c in text
        write(io, get(LATEX_ESCAPE_MAP, c, c))
    end
    String(take!(io))
end

# Or using map + join
escape_latex(text::String) =
    join(get(LATEX_ESCAPE_MAP, c, c) for c in text)

#==============================================================================
# 7. SIMPLIFIED MODULE STRUCTURE
#==============================================================================#

# BEFORE (Nested modules)
module AsciiDoc
    include("ast.jl")     # defines module AST
    include("parser.jl")  # defines module Parser
    using .AST
    using .Parser
    # ...
end

# AFTER (Flat structure)
module AsciiDoc

# AST types (from ast.jl)
abstract type AsciiDocNode end
abstract type BlockNode <: AsciiDocNode end
# ... all types here

# Parser functions (from parser.jl)
const HEADER_RE = r"..."
function parse(text::String)::Document
    # ...
end

# Backend functions (from latex.jl, html.jl)
to_latex(doc::Document) = ...
to_html(doc::Document; standalone=false) = ...

# Exports
export Document, Header, Paragraph, parse, to_latex, to_html

end # module

#==============================================================================
# 8. USE JULIA CONVENIENCES
#==============================================================================#

# Use @kwdef for structs with defaults
Base.@kwdef struct CodeBlock <: BlockNode
    content::String
    language::String = ""
    attributes::Dict{String,String} = Dict{String,String}()
end

# Use @enum for fixed sets
@enum AdmonitionType NOTE TIP WARNING IMPORTANT CAUTION

struct Admonition <: BlockNode
    type::AdmonitionType
    content::Vector{BlockNode}
end

# Use do-syntax for builders
function parse_code_block(lines)
    content = String[]
    for line in Iterators.takewhile(l -> !startswith(l, "----"), lines)
        push!(content, line)
    end
    CodeBlock(content=join(content, '\n'))
end

# Broadcasting!
headings = parse.(readlines("doc.adoc"))
latex_blocks = to_latex.(doc.blocks)

#==============================================================================
# SUMMARY
#==============================================================================#

# The refactored code is:
# ✅ More declarative (what, not how)
# ✅ Uses Julia's strengths (dispatch, broadcasting, iterators)
# ✅ More composable (iterator protocol, functor pattern)
# ✅ Better performance (const regexes, single-pass algorithms)
# ✅ Easier to extend (dispatch tables, traits)
# ✅ More Julian idioms (eachmatch, do-syntax, @kwdef, @enum)
