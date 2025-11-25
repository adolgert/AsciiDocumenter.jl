#!/usr/bin/env julia
# Simple test to verify AsciiDocumenter.jl works
# Run with: julia --project examples/simple_test.jl

using AsciiDocumenter

println("Testing AsciiDocumenter.jl Parser\n")
println("=" ^ 60)

# Test 1: Simple document
println("\n Test 1: Parsing simple document")
text = """
= Hello AsciiDoc

This is a *simple* test document.
"""

doc = parse(text)
println("✓ Parsed document with $(length(doc.blocks)) blocks")

# Test 2: Convert to LaTeX
println("\n✓ Test 2: Converting to LaTeX")
latex = convert(LaTeX, doc)
println("Generated $(length(latex)) characters of LaTeX")
println("\nLaTeX output:")
println("-" ^ 40)
println(latex)
println("-" ^ 40)

# Test 3: Convert to HTML
println("\n✓ Test 3: Converting to HTML")
html = convert(HTML, doc)
println("Generated $(length(html)) characters of HTML")
println("\nHTML output:")
println("-" ^ 40)
println(html)
println("-" ^ 40)

# Test 4: Complex document
println("\n✓ Test 4: Complex document with multiple features")
complex = """
= My Document

== Introduction

This document demonstrates several features:

* Lists
* *Bold* and _italic_ text
* Code blocks

== Code Example

[source,julia]
----
println("Hello, World!")
----

== Conclusion

That's all!
"""

doc2 = parse(complex)
println("✓ Parsed complex document with $(length(doc2.blocks)) blocks")

latex2 = asciidoc_to_latex(complex)
html2 = asciidoc_to_html(complex, standalone=true)

println("✓ Generated LaTeX ($(length(latex2)) chars)")
println("✓ Generated standalone HTML ($(length(html2)) chars)")

println("\n" * "=" ^ 60)
println("All tests completed successfully! ✓")
println("=" ^ 60)
