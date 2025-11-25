"""
Documenter.jl Integration for AsciiDoc.jl

This module provides conversion from AsciiDoc AST to MarkdownAST, enabling
AsciiDoc.jl to work as a first-class plugin for Documenter.jl.

# Usage

```julia
using AsciiDoc
using MarkdownAST

# Parse AsciiDoc document
doc = parse_asciidoc(text)

# Convert to MarkdownAST
md_ast = to_markdownast(doc)

# Use with Documenter.jl
# (md_ast can now be used in Documenter pipelines)
```
"""

import MarkdownAST
import MarkdownAST: Node, @ast

export to_markdownast, to_markdown

"""
    to_markdownast(doc::Document) -> MarkdownAST.Node

Convert an AsciiDoc document to MarkdownAST representation.

This enables integration with Documenter.jl and other tools that consume MarkdownAST.
"""
function to_markdownast(doc::Document)
    # Create root document node
    root = Node(MarkdownAST.Document())

    # Convert all block nodes
    for block in doc.blocks
        child = convert_block(block)
        if child !== nothing
            push!(root.children, child)
        end
    end

    return root
end

"""
    convert_block(node::BlockNode) -> Union{MarkdownAST.Node, Nothing}

Convert an AsciiDoc block node to MarkdownAST using multiple dispatch.
"""
convert_block(node::Header) = convert_header(node)
convert_block(node::Paragraph) = convert_paragraph(node)
convert_block(node::CodeBlock) = convert_codeblock(node)
convert_block(node::BlockQuote) = convert_blockquote(node)
convert_block(node::Admonition) = convert_admonition(node)
convert_block(node::UnorderedList) = convert_unordered_list(node)
convert_block(node::OrderedList) = convert_ordered_list(node)
convert_block(node::DefinitionList) = convert_definition_list(node)
convert_block(node::Table) = convert_table(node)
convert_block(node::HorizontalRule) = convert_horizontal_rule(node)

function convert_block(node::BlockNode)
    @warn "Unknown block node type: $(typeof(node))"
    return nothing
end

"""
    convert_header(node::Header) -> MarkdownAST.Node

Convert AsciiDoc Header to MarkdownAST Heading.
"""
function convert_header(node::Header)
    heading = Node(MarkdownAST.Heading(node.level))

    for inline in node.text
        child = convert_inline(inline)
        if child !== nothing
            push!(heading.children, child)
        end
    end

    return heading
end

"""
    convert_paragraph(node::Paragraph) -> MarkdownAST.Node

Convert AsciiDoc Paragraph to MarkdownAST Paragraph.
"""
function convert_paragraph(node::Paragraph)
    para = Node(MarkdownAST.Paragraph())

    for inline in node.content
        child = convert_inline(inline)
        if child !== nothing
            push!(para.children, child)
        end
    end

    return para
end

"""
    convert_codeblock(node::CodeBlock) -> MarkdownAST.Node

Convert AsciiDoc CodeBlock to MarkdownAST CodeBlock.
"""
function convert_codeblock(node::CodeBlock)
    # MarkdownAST CodeBlock stores info (language) and code separately
    code_node = Node(MarkdownAST.CodeBlock(node.language, node.content))
    return code_node
end

"""
    convert_blockquote(node::BlockQuote) -> MarkdownAST.Node

Convert AsciiDoc BlockQuote to MarkdownAST BlockQuote.
"""
function convert_blockquote(node::BlockQuote)
    quote_node = Node(MarkdownAST.BlockQuote())

    for block in node.blocks
        child = convert_block(block)
        if child !== nothing
            push!(quote_node.children, child)
        end
    end

    # Note: MarkdownAST doesn't have native attribution support
    # If attribution exists, add it as a paragraph
    if !isempty(node.attribution)
        attr_para = Node(MarkdownAST.Paragraph())
        push!(attr_para.children, Node(MarkdownAST.Text("— $(node.attribution)")))
        push!(quote_node.children, attr_para)
    end

    return quote_node
end

"""
    convert_admonition(node::Admonition) -> MarkdownAST.Node

Convert AsciiDoc Admonition to MarkdownAST Admonition.

Maps AsciiDoc admonition types to Documenter.jl categories:
- note -> "note"
- tip -> "tip"
- important -> "important"
- warning -> "warning"
- caution -> "danger"
"""
function convert_admonition(node::Admonition)
    category_map = Dict(
        "note" => "note",
        "tip" => "tip",
        "important" => "important",
        "warning" => "warning",
        "caution" => "danger"  # Documenter uses "danger" for caution-level
    )

    category = get(category_map, node.type, "note")
    # Use custom title if provided, otherwise default to capitalized type
    title = isempty(node.title) ? uppercase(node.type[1:1]) * node.type[2:end] : node.title

    admon_node = Node(MarkdownAST.Admonition(category, title))

    for block in node.content
        child = convert_block(block)
        if child !== nothing
            push!(admon_node.children, child)
        end
    end

    return admon_node
end

"""
    convert_unordered_list(node::UnorderedList) -> MarkdownAST.Node

Convert AsciiDoc UnorderedList to MarkdownAST List (unordered).
"""
function convert_unordered_list(node::UnorderedList)
    list_node = Node(MarkdownAST.List(:bullet, false))

    for item in node.items
        item_node = convert_list_item(item)
        if item_node !== nothing
            push!(list_node.children, item_node)
        end
    end

    return list_node
end

"""
    convert_ordered_list(node::OrderedList) -> MarkdownAST.Node

Convert AsciiDoc OrderedList to MarkdownAST List (ordered).
"""
function convert_ordered_list(node::OrderedList)
    list_node = Node(MarkdownAST.List(:ordered, false))

    for item in node.items
        item_node = convert_list_item(item)
        if item_node !== nothing
            push!(list_node.children, item_node)
        end
    end

    return list_node
end

"""
    convert_list_item(item::ListItem) -> MarkdownAST.Node

Convert AsciiDoc ListItem to MarkdownAST Item.

Note: MarkdownAST Item nodes can only contain block-level elements,
so we wrap inline content in a Paragraph.
"""
function convert_list_item(item::ListItem)
    item_node = Node(MarkdownAST.Item())

    # MarkdownAST Item nodes can only contain block-level elements.
    para = Node(MarkdownAST.Paragraph())
    for inline in item.content
        child = convert_inline(inline)
        if child !== nothing
            push!(para.children, child)
        end
    end
    push!(item_node.children, para)

    if item.nested !== nothing
        nested = convert_block(item.nested)
        if nested !== nothing
            push!(item_node.children, nested)
        end
    end

    return item_node
end

"""
    convert_definition_list(node::DefinitionList) -> MarkdownAST.Node

Convert AsciiDoc DefinitionList to MarkdownAST representation.

Note: MarkdownAST doesn't have native definition list support,
so we convert to a regular list with bold terms. List items must
contain block-level elements, so we wrap in paragraphs.
"""
function convert_definition_list(node::DefinitionList)
    list_node = Node(MarkdownAST.List(:bullet, false))

    for (term, desc) in node.items
        item_node = Node(MarkdownAST.Item())
        para = Node(MarkdownAST.Paragraph())

        strong_node = Node(MarkdownAST.Strong())
        for inline in term.content
            child = convert_inline(inline)
            if child !== nothing
                push!(strong_node.children, child)
            end
        end
        push!(para.children, strong_node)

        push!(para.children, Node(MarkdownAST.Text(": ")))

        for inline in desc.content
            child = convert_inline(inline)
            if child !== nothing
                push!(para.children, child)
            end
        end

        push!(item_node.children, para)
        push!(list_node.children, item_node)
    end

    return list_node
end

"""
    convert_table(node::Table) -> MarkdownAST.Node

Convert AsciiDoc Table to MarkdownAST Table.

MarkdownAST table structure:
- Table contains TableHeader section and TableBody section
- Each section contains TableRow nodes
- Each TableRow contains TableCell nodes
- TableCell(align, is_header, column_index) can contain inline elements
"""
function convert_table(node::Table)
    if isempty(node.rows)
        return nothing
    end

    ncols = length(node.rows[1].cells)
    spec = fill(:left, ncols)
    table_node = Node(MarkdownAST.Table(spec))

    header_rows = Int[]
    body_rows = Int[]
    for (idx, row) in enumerate(node.rows)
        if idx == 1 || row.is_header
            push!(header_rows, idx)
        else
            push!(body_rows, idx)
        end
    end

    if !isempty(header_rows)
        header_section = Node(MarkdownAST.TableHeader())
        for idx in header_rows
            row = node.rows[idx]
            row_node = Node(MarkdownAST.TableRow())

            for (col_idx, cell) in enumerate(row.cells)
                # TableCell(align, is_header_cell, column_index)
                cell_node = Node(MarkdownAST.TableCell(:left, true, col_idx))

                for inline in cell.content
                    child = convert_inline(inline)
                    if child !== nothing
                        push!(cell_node.children, child)
                    end
                end

                push!(row_node.children, cell_node)
            end

            push!(header_section.children, row_node)
        end
        push!(table_node.children, header_section)
    end

    if !isempty(body_rows)
        body_section = Node(MarkdownAST.TableBody())
        for idx in body_rows
            row = node.rows[idx]
            row_node = Node(MarkdownAST.TableRow())

            for (col_idx, cell) in enumerate(row.cells)
                cell_node = Node(MarkdownAST.TableCell(:left, false, col_idx))

                for inline in cell.content
                    child = convert_inline(inline)
                    if child !== nothing
                        push!(cell_node.children, child)
                    end
                end

                push!(row_node.children, cell_node)
            end

            push!(body_section.children, row_node)
        end
        push!(table_node.children, body_section)
    end

    return table_node
end

"""
    convert_horizontal_rule(node::HorizontalRule) -> MarkdownAST.Node

Convert AsciiDoc HorizontalRule to MarkdownAST ThematicBreak.
"""
function convert_horizontal_rule(node::HorizontalRule)
    return Node(MarkdownAST.ThematicBreak())
end

"""
    convert_inline(node::InlineNode) -> Union{MarkdownAST.Node, Nothing}

Convert an AsciiDoc inline node to MarkdownAST using multiple dispatch.
"""
convert_inline(node::Text) = convert_text(node)
convert_inline(node::Bold) = convert_bold(node)
convert_inline(node::Italic) = convert_italic(node)
convert_inline(node::Monospace) = convert_monospace(node)
convert_inline(node::Subscript) = convert_subscript(node)
convert_inline(node::Superscript) = convert_superscript(node)
convert_inline(node::Link) = convert_link(node)
convert_inline(node::Image) = convert_image(node)
convert_inline(node::CrossRef) = convert_crossref(node)
convert_inline(node::LineBreak) = convert_linebreak(node)

function convert_inline(node::InlineNode)
    @warn "Unknown inline node type: $(typeof(node))"
    return nothing
end

"""
    convert_text(node::Text) -> MarkdownAST.Node

Convert AsciiDoc Text to MarkdownAST Text.
"""
function convert_text(node::Text)
    return Node(MarkdownAST.Text(node.content))
end

"""
    convert_bold(node::Bold) -> MarkdownAST.Node

Convert AsciiDoc Bold to MarkdownAST Strong.
"""
function convert_bold(node::Bold)
    strong = Node(MarkdownAST.Strong())

    for inline in node.content
        child = convert_inline(inline)
        if child !== nothing
            push!(strong.children, child)
        end
    end

    return strong
end

"""
    convert_italic(node::Italic) -> MarkdownAST.Node

Convert AsciiDoc Italic to MarkdownAST Emph.
"""
function convert_italic(node::Italic)
    emph = Node(MarkdownAST.Emph())

    for inline in node.content
        child = convert_inline(inline)
        if child !== nothing
            push!(emph.children, child)
        end
    end

    return emph
end

"""
    convert_monospace(node::Monospace) -> MarkdownAST.Node

Convert AsciiDoc Monospace to MarkdownAST Code.
"""
function convert_monospace(node::Monospace)
    text_content = ""
    for inline in node.content
        if inline isa Text
            text_content *= inline.content
        end
    end

    return Node(MarkdownAST.Code(text_content))
end

"""
    convert_subscript(node::Subscript) -> MarkdownAST.Node

Convert AsciiDoc Subscript to MarkdownAST representation.

Note: MarkdownAST doesn't have native subscript support.
We use HTML fallback: <sub>text</sub>
"""
function convert_subscript(node::Subscript)
    text_content = ""
    for inline in node.content
        if inline isa Text
            text_content *= inline.content
        end
    end

    html = "<sub>$(text_content)</sub>"
    return Node(MarkdownAST.HTMLInline(html))
end

"""
    convert_superscript(node::Superscript) -> MarkdownAST.Node

Convert AsciiDoc Superscript to MarkdownAST representation.

Note: MarkdownAST doesn't have native superscript support.
We use HTML fallback: <sup>text</sup>
"""
function convert_superscript(node::Superscript)
    text_content = ""
    for inline in node.content
        if inline isa Text
            text_content *= inline.content
        end
    end

    html = "<sup>$(text_content)</sup>"
    return Node(MarkdownAST.HTMLInline(html))
end

"""
    convert_link(node::Link) -> MarkdownAST.Node

Convert AsciiDoc Link to MarkdownAST Link.
"""
function convert_link(node::Link)
    link = Node(MarkdownAST.Link(node.url, ""))

    if !isempty(node.text)
        for inline in node.text
            child = convert_inline(inline)
            if child !== nothing
                push!(link.children, child)
            end
        end
    else
        # Use URL as text if no text provided
        push!(link.children, Node(MarkdownAST.Text(node.url)))
    end

    return link
end

"""
    convert_image(node::Image) -> MarkdownAST.Node

Convert AsciiDoc Image to MarkdownAST Image.
"""
function convert_image(node::Image)
    img = Node(MarkdownAST.Image(node.url, node.alt_text))

    if !isempty(node.alt_text)
        push!(img.children, Node(MarkdownAST.Text(node.alt_text)))
    end

    return img
end

"""
    convert_crossref(node::CrossRef) -> MarkdownAST.Node

Convert AsciiDoc CrossRef to MarkdownAST Link.

Cross-references become internal links with # prefix.
"""
function convert_crossref(node::CrossRef)
    destination = "#$(node.target)"
    link = Node(MarkdownAST.Link(destination, ""))

    if !isempty(node.text)
        for inline in node.text
            child = convert_inline(inline)
            if child !== nothing
                push!(link.children, child)
            end
        end
    else
        # Use target as text if no text provided
        push!(link.children, Node(MarkdownAST.Text(node.target)))
    end

    return link
end

"""
    convert_linebreak(node::LineBreak) -> MarkdownAST.Node

Convert AsciiDoc LineBreak to MarkdownAST LineBreak.
"""
function convert_linebreak(node::LineBreak)
    return Node(MarkdownAST.LineBreak())
end

"""
    to_markdown(doc::Document) -> String

Convert an AsciiDoc document to a Markdown string.

# Example

```julia
doc = parse(\"\"\"
= My Title

Some *bold* text.
\"\"\")

md = to_markdown(doc)
```
"""
function to_markdown(doc::Document)
    ast = to_markdownast(doc)
    return render_markdown(ast)
end

"""
    render_markdown(node::MarkdownAST.Node) -> String

Render a MarkdownAST node tree to a Markdown string.
"""
function render_markdown(node::MarkdownAST.Node)
    io = IOBuffer()
    render_md(io, node, 0)
    return String(take!(io))
end

function render_md(io::IO, node::MarkdownAST.Node, indent::Int)
    render_md_element(io, node.element, node, indent)
end

function render_md_element(io::IO, ::MarkdownAST.Document, node::MarkdownAST.Node, indent::Int)
    first = true
    for child in node.children
        if !first
            println(io)
        end
        render_md(io, child, indent)
        first = false
    end
end

function render_md_element(io::IO, elem::MarkdownAST.Heading, node::MarkdownAST.Node, indent::Int)
    print(io, "#"^elem.level, " ")
    for child in node.children
        render_md_inline(io, child)
    end
    println(io)
end

function render_md_element(io::IO, ::MarkdownAST.Paragraph, node::MarkdownAST.Node, indent::Int)
    print(io, " "^indent)
    for child in node.children
        render_md_inline(io, child)
    end
    println(io)
end

function render_md_element(io::IO, elem::MarkdownAST.CodeBlock, node::MarkdownAST.Node, indent::Int)
    lang = isempty(elem.info) ? "" : elem.info
    println(io, "```", lang)
    print(io, elem.code)
    if !endswith(elem.code, "\n")
        println(io)
    end
    println(io, "```")
end

function render_md_element(io::IO, ::MarkdownAST.BlockQuote, node::MarkdownAST.Node, indent::Int)
    buf = IOBuffer()
    for child in node.children
        render_md(buf, child, 0)
    end
    content = String(take!(buf))
    for line in split(rstrip(content), "\n")
        println(io, "> ", line)
    end
end

function render_md_element(io::IO, elem::MarkdownAST.Admonition, node::MarkdownAST.Node, indent::Int)
    println(io, "!!! ", elem.category, " \"", elem.title, "\"")
    for child in node.children
        buf = IOBuffer()
        render_md(buf, child, 0)
        content = String(take!(buf))
        for line in split(rstrip(content), "\n")
            println(io, "    ", line)
        end
    end
end

function render_md_element(io::IO, elem::MarkdownAST.List, node::MarkdownAST.Node, indent::Int)
    marker = elem.type == :ordered ? "1. " : "- "
    for child in node.children
        render_md_list_item(io, child, marker, indent)
    end
end

function render_md_list_item(io::IO, node::MarkdownAST.Node, marker::String, indent::Int)
    print(io, " "^indent, marker)
    first = true
    for child in node.children
        if first
            buf = IOBuffer()
            render_md(buf, child, 0)
            content = rstrip(String(take!(buf)))
            println(io, content)
            first = false
        else
            render_md(io, child, indent + length(marker))
        end
    end
end

function render_md_element(io::IO, ::MarkdownAST.Item, node::MarkdownAST.Node, indent::Int)
    for child in node.children
        render_md(io, child, indent)
    end
end

function render_md_element(io::IO, ::MarkdownAST.ThematicBreak, node::MarkdownAST.Node, indent::Int)
    println(io, "---")
end

function render_md_element(io::IO, elem::MarkdownAST.Table, node::MarkdownAST.Node, indent::Int)
    rows = []
    for child in node.children
        if child.element isa MarkdownAST.TableHeader || child.element isa MarkdownAST.TableBody
            for row in child.children
                push!(rows, row)
            end
        elseif child.element isa MarkdownAST.TableRow
            push!(rows, child)
        end
    end

    if isempty(rows)
        return
    end

    # Render header row
    header_row = rows[1]
    print(io, "|")
    for cell in header_row.children
        print(io, " ")
        for c in cell.children
            render_md_inline(io, c)
        end
        print(io, " |")
    end
    println(io)

    # Separator
    ncols = length(collect(header_row.children))
    println(io, "|", join(fill("---", ncols), "|"), "|")

    # Data rows
    for row in rows[2:end]
        print(io, "|")
        for cell in row.children
            print(io, " ")
            for c in cell.children
                render_md_inline(io, c)
            end
            print(io, " |")
        end
        println(io)
    end
end

function render_md_element(io::IO, elem, node::MarkdownAST.Node, indent::Int)
    for child in node.children
        render_md(io, child, indent)
    end
end

function render_md_inline(io::IO, node::MarkdownAST.Node)
    render_md_inline_element(io, node.element, node)
end

function render_md_inline_element(io::IO, elem::MarkdownAST.Text, node::MarkdownAST.Node)
    print(io, elem.text)
end

function render_md_inline_element(io::IO, elem::MarkdownAST.Code, node::MarkdownAST.Node)
    print(io, "`", elem.code, "`")
end

function render_md_inline_element(io::IO, ::MarkdownAST.Strong, node::MarkdownAST.Node)
    print(io, "**")
    for child in node.children
        render_md_inline(io, child)
    end
    print(io, "**")
end

function render_md_inline_element(io::IO, ::MarkdownAST.Emph, node::MarkdownAST.Node)
    print(io, "*")
    for child in node.children
        render_md_inline(io, child)
    end
    print(io, "*")
end

function render_md_inline_element(io::IO, elem::MarkdownAST.Link, node::MarkdownAST.Node)
    print(io, "[")
    for child in node.children
        render_md_inline(io, child)
    end
    print(io, "](", elem.destination, ")")
end

function render_md_inline_element(io::IO, elem::MarkdownAST.Image, node::MarkdownAST.Node)
    print(io, "![", elem.title, "](", elem.destination, ")")
end

function render_md_inline_element(io::IO, ::MarkdownAST.LineBreak, node::MarkdownAST.Node)
    println(io, "  ")
end

function render_md_inline_element(io::IO, ::MarkdownAST.SoftBreak, node::MarkdownAST.Node)
    println(io)
end

function render_md_inline_element(io::IO, elem::MarkdownAST.HTMLInline, node::MarkdownAST.Node)
    print(io, elem.html)
end

function render_md_inline_element(io::IO, elem, node::MarkdownAST.Node)
    for child in node.children
        render_md_inline(io, child)
    end
end
