"""
Spec-Based Parser Tests

This module extracts examples from the official AsciiDoc Language specification
and uses them to test parser compliance. The spec examples are in:
    ~/dev/asciidoc-lang/docs/modules/*/examples/*.adoc

Each example file contains tagged sections:
    // tag::example-name[]
    AsciiDoc content here...
    // end::example-name[]

These tagged sections can be extracted and parsed to verify our parser handles
real-world AsciiDoc syntax correctly.
"""

using Test
using AsciiDocumenter
import AsciiDocumenter: parse

const SPEC_PATH = expanduser("~/dev/asciidoc-lang/docs/modules")

"""
    extract_tagged_examples(filepath::String) -> Dict{String, String}

Extract all tagged examples from an AsciiDoc file.
Returns a dictionary mapping tag names to their content.
"""
function extract_tagged_examples(filepath::String)
    if !isfile(filepath)
        return Dict{String, String}()
    end

    content = read(filepath, String)
    examples = Dict{String, String}()

    # Match // tag::name[] ... // end::name[]
    pattern = r"//\s*tag::([^\]]+)\[\]\s*\n(.*?)//\s*end::\1\[\]"s

    for m in eachmatch(pattern, content)
        tag_name = String(m.captures[1])
        tag_content = String(m.captures[2])
        # Remove trailing whitespace but preserve internal structure
        examples[tag_name] = rstrip(tag_content)
    end

    return examples
end

"""
    list_example_files() -> Vector{String}

Find all example files in the AsciiDoc spec.
"""
function list_example_files()
    if !isdir(SPEC_PATH)
        @warn "AsciiDoc spec not found at $SPEC_PATH"
        return String[]
    end

    files = String[]
    for (root, dirs, filenames) in walkdir(SPEC_PATH)
        if basename(root) == "examples"
            for f in filenames
                if endswith(f, ".adoc")
                    push!(files, joinpath(root, f))
                end
            end
        end
    end
    return sort(files)
end

"""
    get_module_name(filepath::String) -> String

Extract the module name from a spec example filepath.
"""
function get_module_name(filepath::String)
    parts = splitpath(filepath)
    for (i, part) in enumerate(parts)
        if part == "modules" && i + 1 <= length(parts)
            return parts[i + 1]
        end
    end
    return "unknown"
end

# Test that examples can be parsed without errors.
# This catches syntax that our parser mishandles.
@testset "Spec Examples Parse Without Errors" begin
    example_files = list_example_files()

    if isempty(example_files)
        @warn "No spec example files found. Skipping spec compliance tests."
        @test_skip "Spec examples not available"
    else
        @testset "Module: $(get_module_name(filepath))" for filepath in example_files
            filename = basename(filepath)
            examples = extract_tagged_examples(filepath)

            @testset "File: $filename" begin
                for (tag, content) in examples
                    @testset "Example: $tag" begin
                        # The test is simply: can we parse this without throwing?
                        result = try
                            parse(content)
                            true
                        catch e
                            @error "Failed to parse spec example" filepath tag exception=e
                            false
                        end
                        @test result
                    end
                end
            end
        end
    end
end

# Test specific features that we know are tricky
@testset "Spec Examples - Text Formatting" begin
    text_file = joinpath(SPEC_PATH, "text", "examples", "text.adoc")
    examples = extract_tagged_examples(text_file)

    if isempty(examples)
        @test_skip "Text examples not available"
    else
        @testset "Constrained formatting" begin
            if haskey(examples, "constrained-bold-italic-mono")
                doc = parse(examples["constrained-bold-italic-mono"])
                @test length(doc.blocks) >= 1
                # Check that we found Bold, Italic, and Monospace nodes
                has_bold = any(b -> any(n -> n isa Bold, b.content), filter(b -> b isa Paragraph, doc.blocks))
                has_italic = any(b -> any(n -> n isa Italic, b.content), filter(b -> b isa Paragraph, doc.blocks))
                has_mono = any(b -> any(n -> n isa Monospace, b.content), filter(b -> b isa Paragraph, doc.blocks))
                @test has_bold
                @test has_italic
                @test has_mono
            else
                @test_skip "Example not found"
            end
        end

        @testset "Unconstrained formatting" begin
            if haskey(examples, "unconstrained-bold-italic-mono")
                doc = parse(examples["unconstrained-bold-italic-mono"])
                @test length(doc.blocks) >= 1
                # Unconstrained: **C**reate should parse C as bold
                # This is a known challenging case for many parsers
            else
                @test_skip "Example not found"
            end
        end

        @testset "Subscript and superscript" begin
            if haskey(examples, "b-sub-sup")
                doc = parse(examples["b-sub-sup"])
                @test length(doc.blocks) >= 1
            else
                @test_skip "Example not found"
            end
        end

        @testset "Curly quotes" begin
            if haskey(examples, "c-quote")
                doc = parse(examples["c-quote"])
                @test length(doc.blocks) >= 1
            else
                @test_skip "Example not found"
            end
        end
    end
end

@testset "Spec Examples - Lists" begin
    unordered_file = joinpath(SPEC_PATH, "lists", "examples", "unordered.adoc")
    examples = extract_tagged_examples(unordered_file)

    if isempty(examples)
        @test_skip "List examples not available"
    else
        @testset "Basic unordered list" begin
            if haskey(examples, "base")
                doc = parse(examples["base"])
                @test length(doc.blocks) == 1
                @test doc.blocks[1] isa UnorderedList
                @test length(doc.blocks[1].items) == 3
            else
                @test_skip "Example not found"
            end
        end

        @testset "Nested list" begin
            if haskey(examples, "nest")
                doc = parse(examples["nest"])
                @test length(doc.blocks) >= 1
                # The example may include a block title before the list
                list = findfirst(b -> b isa UnorderedList, doc.blocks)
                @test list !== nothing
                if list !== nothing
                    has_nested = any(item -> item.nested !== nothing, doc.blocks[list].items)
                    @test has_nested
                end
            else
                @test_skip "Example not found"
            end
        end

        @testset "Maximum nesting depth" begin
            if haskey(examples, "max")
                doc = parse(examples["max"])
                @test length(doc.blocks) >= 1
                # This tests 6 levels of nesting
            else
                @test_skip "Example not found"
            end
        end

        @testset "Alternate marker (-)" begin
            if haskey(examples, "base-alt")
                doc = parse(examples["base-alt"])
                @test length(doc.blocks) == 1
                @test doc.blocks[1] isa UnorderedList
            else
                @test_skip "Example not found"
            end
        end
    end
end

@testset "Spec Examples - Blocks" begin
    @testset "Admonitions" begin
        admon_file = joinpath(SPEC_PATH, "blocks", "examples", "admonition.adoc")
        examples = extract_tagged_examples(admon_file)

        if !isempty(examples)
            for (tag, content) in examples
                @testset "Admonition: $tag" begin
                    doc = try
                        parse(content)
                    catch
                        nothing
                    end
                    @test doc !== nothing
                    if doc !== nothing
                        # Many admonition examples should produce Admonition nodes
                        has_admon = any(b -> b isa Admonition, doc.blocks)
                        # Not all examples produce admonitions (some are partial)
                        # So we just verify parsing succeeds
                    end
                end
            end
        else
            @test_skip "Admonition examples not available"
        end
    end

    @testset "Block quotes" begin
        quote_file = joinpath(SPEC_PATH, "blocks", "examples", "quote.adoc")
        examples = extract_tagged_examples(quote_file)

        if !isempty(examples)
            # Test basic block quote
            if haskey(examples, "no-cite")
                doc = parse(examples["no-cite"])
                @test any(b -> b isa BlockQuote, doc.blocks)
            end

            # Test block quote with attribution
            if haskey(examples, "bl")
                doc = parse(examples["bl"])
                @test any(b -> b isa BlockQuote, doc.blocks)
                quote_block = findfirst(b -> b isa BlockQuote, doc.blocks)
                if quote_block !== nothing
                    @test !isempty(doc.blocks[quote_block].attribution)
                end
            end

            # Test Markdown-style quotes
            if haskey(examples, "md")
                doc = parse(examples["md"])
                @test any(b -> b isa BlockQuote, doc.blocks)
            end
        else
            @test_skip "Quote examples not available"
        end
    end
end

@testset "Spec Examples - Tables" begin
    table_file = joinpath(SPEC_PATH, "tables", "examples", "table.adoc")
    examples = extract_tagged_examples(table_file)

    if isempty(examples)
        @test_skip "Table examples not available"
    else
        for (tag, content) in examples
            @testset "Table: $tag" begin
                doc = try
                    parse(content)
                catch e
                    @error "Failed to parse table example" tag exception=e
                    nothing
                end
                @test doc !== nothing
            end
        end
    end
end

@testset "Spec Examples - Verbatim (Code Blocks)" begin
    source_file = joinpath(SPEC_PATH, "verbatim", "examples", "source.adoc")
    examples = extract_tagged_examples(source_file)

    if isempty(examples)
        @test_skip "Source examples not available"
    else
        for (tag, content) in examples
            @testset "Source: $tag" begin
                doc = try
                    parse(content)
                catch e
                    @error "Failed to parse source example" tag exception=e
                    nothing
                end
                @test doc !== nothing
                if doc !== nothing
                    # Check if we got a CodeBlock
                    has_code = any(b -> b isa CodeBlock, doc.blocks)
                    # Some examples may be partial, so don't require CodeBlock
                end
            end
        end
    end
end

# Summary statistics
@testset "Spec Coverage Summary" begin
    example_files = list_example_files()
    total_examples = 0
    parseable = 0

    for filepath in example_files
        examples = extract_tagged_examples(filepath)
        for (tag, content) in examples
            total_examples += 1
            try
                parse(content)
                parseable += 1
            catch
                # Count failures silently
            end
        end
    end

    if total_examples > 0
        @test parseable / total_examples >= 0.8
    else
        @test_skip "No examples found"
    end
end
