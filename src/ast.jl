"""
Abstract Syntax Tree (AST) node types for AsciiDoc documents.

This module defines the type hierarchy for representing parsed AsciiDoc content.
"""

export AsciiDocNode, Document, Header, Paragraph, List, ListItem,
       CodeBlock, BlockQuote, Table, TableRow, TableCell,
       InlineNode, Text, Bold, Italic, Monospace, Subscript, Superscript,
       Link, Image, CrossRef, LineBreak, HorizontalRule,
       OrderedList, UnorderedList, DefinitionList, DefinitionTerm, DefinitionDescription,
       Admonition

abstract type AsciiDocNode end
abstract type BlockNode <: AsciiDocNode end
abstract type InlineNode <: AsciiDocNode end

"""
    Document(attributes::Dict{String,String}, blocks::Vector{BlockNode})

Root node representing a complete AsciiDoc document.
"""
struct Document <: AsciiDocNode
    attributes::Dict{String,String}
    blocks::Vector{BlockNode}
end

Document(blocks::Vector{BlockNode}) = Document(Dict{String,String}(), blocks)

"""
    Header(level::Int, text::Vector{InlineNode}, id::String)

Represents a section header (= to ======).
"""
struct Header <: BlockNode
    level::Int
    text::Vector{InlineNode}
    id::String
end

Header(level::Int, text::Vector{InlineNode}) = Header(level, text, "")

"""
    Paragraph(content::Vector{InlineNode}, attributes::Dict{String,String})

A paragraph of text with inline formatting.
"""
struct Paragraph <: BlockNode
    content::Vector{InlineNode}
    attributes::Dict{String,String}
end

Paragraph(content::Vector{InlineNode}) = Paragraph(content, Dict{String,String}())

"""
    CodeBlock(content::String, language::String, attributes::Dict{String,String})

A source code block with optional syntax highlighting.
"""
struct CodeBlock <: BlockNode
    content::String
    language::String
    attributes::Dict{String,String}
end

CodeBlock(content::String, language::String="") = CodeBlock(content, language, Dict{String,String}())

"""
    BlockQuote(blocks::Vector{BlockNode}, attribution::String)

A block quotation, optionally with attribution.
"""
struct BlockQuote <: BlockNode
    blocks::Vector{BlockNode}
    attribution::String
end

BlockQuote(blocks::Vector{BlockNode}) = BlockQuote(blocks, "")

"""
    Admonition(type::String, content::Vector{BlockNode}, title::String="")

An admonition block (NOTE, TIP, IMPORTANT, WARNING, CAUTION).

The `type` field contains the lowercase admonition type.
The `content` field contains the block content of the admonition.
The `title` field contains an optional custom title (from `.Title` syntax).
"""
struct Admonition <: BlockNode
    type::String  # "note", "tip", "important", "warning", "caution"
    content::Vector{BlockNode}
    title::String
end

Admonition(type::String, content::Vector{BlockNode}) = Admonition(type, content, "")

abstract type List <: BlockNode end

"""
    ListItem(content::Vector{InlineNode}, nested::Union{Nothing,List})

An item in a list, optionally containing a nested list.
"""
struct ListItem <: AsciiDocNode
    content::Vector{InlineNode}
    nested::Union{Nothing,List}
end

ListItem(content::Vector{InlineNode}) = ListItem(content, nothing)

"""
    UnorderedList(items::Vector{ListItem}, attributes::Dict{String,String})

A bulleted list (* or -).
"""
struct UnorderedList <: List
    items::Vector{ListItem}
    attributes::Dict{String,String}
end

UnorderedList(items::Vector{ListItem}) = UnorderedList(items, Dict{String,String}())

"""
    OrderedList(items::Vector{ListItem}, style::String, attributes::Dict{String,String})

A numbered list (. or 1.).
"""
struct OrderedList <: List
    items::Vector{ListItem}
    style::String  # "arabic", "loweralpha", "upperalpha", "lowerroman", "upperroman"
    attributes::Dict{String,String}
end

OrderedList(items::Vector{ListItem}, style::String="arabic") =
    OrderedList(items, style, Dict{String,String}())

"""
    DefinitionTerm(content::Vector{InlineNode})

The term part of a definition list entry.
"""
struct DefinitionTerm <: AsciiDocNode
    content::Vector{InlineNode}
end

"""
    DefinitionDescription(content::Vector{InlineNode})

The description part of a definition list entry.
"""
struct DefinitionDescription <: AsciiDocNode
    content::Vector{InlineNode}
end

"""
    DefinitionList(items::Vector{Tuple{DefinitionTerm,DefinitionDescription}})

A definition list (term::).
"""
struct DefinitionList <: List
    items::Vector{Tuple{DefinitionTerm,DefinitionDescription}}
    attributes::Dict{String,String}
end

DefinitionList(items::Vector{Tuple{DefinitionTerm,DefinitionDescription}}) =
    DefinitionList(items, Dict{String,String}())

"""
    TableCell(content::Vector{InlineNode}, attributes::Dict{String,String})

A single cell in a table.
"""
struct TableCell <: AsciiDocNode
    content::Vector{InlineNode}
    attributes::Dict{String,String}
end

TableCell(content::Vector{InlineNode}) = TableCell(content, Dict{String,String}())

"""
    TableRow(cells::Vector{TableCell}, is_header::Bool)

A row in a table.
"""
struct TableRow <: AsciiDocNode
    cells::Vector{TableCell}
    is_header::Bool
end

TableRow(cells::Vector{TableCell}) = TableRow(cells, false)

"""
    Table(rows::Vector{TableRow}, attributes::Dict{String,String})

A table with rows and cells.
"""
struct Table <: BlockNode
    rows::Vector{TableRow}
    attributes::Dict{String,String}
end

Table(rows::Vector{TableRow}) = Table(rows, Dict{String,String}())

"""
    HorizontalRule(attributes::Dict{String,String})

A horizontal rule ('''  or ---).
"""
struct HorizontalRule <: BlockNode
    attributes::Dict{String,String}
end

HorizontalRule() = HorizontalRule(Dict{String,String}())

"""
    Text(content::String)

Plain text content.
"""
struct Text <: InlineNode
    content::String
end

"""
    Bold(content::Vector{InlineNode})

Bold text (*text*).
"""
struct Bold <: InlineNode
    content::Vector{InlineNode}
end

"""
    Italic(content::Vector{InlineNode})

Italic text (_text_).
"""
struct Italic <: InlineNode
    content::Vector{InlineNode}
end

"""
    Monospace(content::Vector{InlineNode})

Monospace/code text (`text`).
"""
struct Monospace <: InlineNode
    content::Vector{InlineNode}
end

"""
    Subscript(content::Vector{InlineNode})

Subscript text (~text~).
"""
struct Subscript <: InlineNode
    content::Vector{InlineNode}
end

"""
    Superscript(content::Vector{InlineNode})

Superscript text (^text^).
"""
struct Superscript <: InlineNode
    content::Vector{InlineNode}
end

"""
    Link(url::String, text::Vector{InlineNode})

A hyperlink.
"""
struct Link <: InlineNode
    url::String
    text::Vector{InlineNode}
end

Link(url::String) = Link(url, [Text(url)])

"""
    Image(url::String, alt_text::String, attributes::Dict{String,String})

An embedded image.
"""
struct Image <: InlineNode
    url::String
    alt_text::String
    attributes::Dict{String,String}
end

Image(url::String, alt_text::String="") = Image(url, alt_text, Dict{String,String}())

"""
    CrossRef(target::String, text::Vector{InlineNode})

A cross-reference to another section.
"""
struct CrossRef <: InlineNode
    target::String
    text::Vector{InlineNode}
end

CrossRef(target::String) = CrossRef(target, InlineNode[])

"""
    LineBreak()

An explicit line break.
"""
struct LineBreak <: InlineNode end
