"""
Utilities for comparing MarkdownAST trees semantically.

These functions test that two ASTs are semantically equivalent even when
the exact representation differs (whitespace, attribute order, etc.)
"""

using MarkdownAST
using Test

# ============================================================================
# Strategy 1: Structural Comparison
# ============================================================================

"""
    ast_structure_equal(node1::Node, node2::Node; ignore_text_whitespace=true) -> Bool

Compare two MarkdownAST nodes for structural equivalence.

Compares:
- Element types match
- Key element properties match (heading levels, code language, etc.)
- Children count and structure match recursively

Does NOT compare:
- Exact text content (only structure)
- Whitespace differences (when ignore_text_whitespace=true)
"""
function ast_structure_equal(node1::MarkdownAST.Node, node2::MarkdownAST.Node;
                             ignore_text_whitespace::Bool=true)
    # Element type must match
    typeof(node1.element) === typeof(node2.element) || return false

    # Check type-specific properties
    if !element_properties_equal(node1.element, node2.element)
        return false
    end

    # Children count must match
    c1 = collect(node1.children)
    c2 = collect(node2.children)
    length(c1) == length(c2) || return false

    # Recursively compare children
    for (child1, child2) in zip(c1, c2)
        ast_structure_equal(child1, child2; ignore_text_whitespace) || return false
    end

    return true
end

"""
    element_properties_equal(e1, e2) -> Bool

Compare element-specific properties for semantic equivalence.
"""
function element_properties_equal(e1::MarkdownAST.Heading, e2::MarkdownAST.Heading)
    e1.level == e2.level
end

function element_properties_equal(e1::MarkdownAST.CodeBlock, e2::MarkdownAST.CodeBlock)
    # Language should match, code content should match
    e1.info == e2.info && e1.code == e2.code
end

function element_properties_equal(e1::MarkdownAST.List, e2::MarkdownAST.List)
    e1.type == e2.type  # :bullet or :ordered
end

function element_properties_equal(e1::MarkdownAST.Admonition, e2::MarkdownAST.Admonition)
    e1.category == e2.category  # note, warning, etc.
end

function element_properties_equal(e1::MarkdownAST.Link, e2::MarkdownAST.Link)
    e1.destination == e2.destination
end

function element_properties_equal(e1::MarkdownAST.Image, e2::MarkdownAST.Image)
    e1.destination == e2.destination
end

function element_properties_equal(e1::MarkdownAST.Code, e2::MarkdownAST.Code)
    e1.code == e2.code
end

function element_properties_equal(e1::MarkdownAST.Text, e2::MarkdownAST.Text)
    # Normalize whitespace for comparison
    normalize_whitespace(e1.text) == normalize_whitespace(e2.text)
end

# Default: elements with no special properties are equal if types match
function element_properties_equal(e1, e2)
    true
end

normalize_whitespace(s::String) = join(split(strip(s)), " ")

# ============================================================================
# Strategy 2: Element Manifest (Count element types)
# ============================================================================

"""
    element_manifest(node::MarkdownAST.Node) -> Dict{Symbol, Int}

Create a manifest counting each element type in the AST.

Useful for high-level equivalence testing: "both documents have
3 headings, 5 paragraphs, 2 code blocks, etc."
"""
function element_manifest(node::MarkdownAST.Node)
    manifest = Dict{Symbol, Int}()

    function traverse(n)
        type_sym = Symbol(typeof(n.element).name.name)
        manifest[type_sym] = get(manifest, type_sym, 0) + 1
        for child in n.children
            traverse(child)
        end
    end

    traverse(node)
    return manifest
end

"""
    manifest_equal(m1::Dict, m2::Dict; ignore_keys=Symbol[]) -> Bool

Compare two manifests, optionally ignoring certain element types.
"""
function manifest_equal(m1::Dict, m2::Dict; ignore_keys::Vector{Symbol}=Symbol[])
    keys1 = setdiff(keys(m1), ignore_keys)
    keys2 = setdiff(keys(m2), ignore_keys)

    keys1 == keys2 || return false

    for k in keys1
        m1[k] == m2[k] || return false
    end

    return true
end

# ============================================================================
# Strategy 3: Text Content Extraction
# ============================================================================

"""
    extract_text_content(node::MarkdownAST.Node) -> String

Extract all text content from an AST, ignoring formatting.

Useful for verifying that the same information is present,
regardless of how it's formatted.
"""
function extract_text_content(node::MarkdownAST.Node)
    texts = String[]

    function traverse(n)
        if n.element isa MarkdownAST.Text
            push!(texts, n.element.text)
        elseif n.element isa MarkdownAST.Code
            push!(texts, n.element.code)
        elseif n.element isa MarkdownAST.CodeBlock
            push!(texts, n.element.code)
        end
        for child in n.children
            traverse(child)
        end
    end

    traverse(node)
    return join(texts, " ")
end

"""
    text_content_equal(node1::MarkdownAST.Node, node2::MarkdownAST.Node) -> Bool

Compare text content of two ASTs, ignoring formatting and whitespace.
"""
function text_content_equal(node1::MarkdownAST.Node, node2::MarkdownAST.Node)
    t1 = normalize_whitespace(extract_text_content(node1))
    t2 = normalize_whitespace(extract_text_content(node2))
    t1 == t2
end

# ============================================================================
# Strategy 4: Detailed Diff Report
# ============================================================================

"""
    ast_diff(node1::MarkdownAST.Node, node2::MarkdownAST.Node) -> Vector{String}

Generate a list of differences between two ASTs.

Returns an empty vector if the ASTs are structurally equivalent.
"""
function ast_diff(node1::MarkdownAST.Node, node2::MarkdownAST.Node;
                  path::String="root")
    diffs = String[]

    # Element type check
    if typeof(node1.element) !== typeof(node2.element)
        push!(diffs, "$path: type mismatch - $(typeof(node1.element)) vs $(typeof(node2.element))")
        return diffs
    end

    # Element properties check
    if !element_properties_equal(node1.element, node2.element)
        push!(diffs, "$path: property mismatch in $(typeof(node1.element))")
    end

    # Children check
    c1 = collect(node1.children)
    c2 = collect(node2.children)

    if length(c1) != length(c2)
        push!(diffs, "$path: children count mismatch - $(length(c1)) vs $(length(c2))")
        return diffs
    end

    for (i, (child1, child2)) in enumerate(zip(c1, c2))
        child_path = "$path/$(typeof(child1.element).name.name)[$i]"
        append!(diffs, ast_diff(child1, child2; path=child_path))
    end

    return diffs
end

# ============================================================================
# Testing Helpers
# ============================================================================

"""
    @test_ast_equivalent(ast1, ast2)

Test macro that compares two ASTs and provides detailed diff on failure.
"""
macro test_ast_equivalent(ast1, ast2)
    quote
        local a1 = $(esc(ast1))
        local a2 = $(esc(ast2))
        local diffs = ast_diff(a1, a2)
        if !isempty(diffs)
            @warn "AST differences found:" diffs
        end
        @test isempty(diffs)
    end
end

"""
    @test_manifest_equivalent(ast1, ast2)

Test that two ASTs have the same element counts.
"""
macro test_manifest_equivalent(ast1, ast2)
    quote
        local m1 = element_manifest($(esc(ast1)))
        local m2 = element_manifest($(esc(ast2)))
        @test manifest_equal(m1, m2)
    end
end
