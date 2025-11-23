using AsciiDoc

# Example 1: Basic parsing and conversion
println("=" ^ 60)
println("Example 1: Basic Document")
println("=" ^ 60)

text1 = """
= My Document

This is a paragraph with *bold* and _italic_ text.

== Section 1

Here's what we can do:

* Parse AsciiDoc documents
* Convert to LaTeX
* Convert to HTML
"""

doc1 = parse(text1)
println("\nParsed document with $(length(doc1.blocks)) blocks\n")

# Convert to LaTeX
latex1 = convert(LaTeX, doc1)
println("LaTeX output:")
println(latex1)
println()

# Convert to HTML
html1 = convert(HTML, doc1)
println("HTML output:")
println(html1)
println()

# Example 2: Code blocks
println("=" ^ 60)
println("Example 2: Code Blocks")
println("=" ^ 60)

text2 = """
= Julia Code Example

Here's a simple Julia function:

[source,julia]
----
function fibonacci(n)
    if n <= 1
        return n
    end
    return fibonacci(n-1) + fibonacci(n-2)
end
----

This function computes Fibonacci numbers recursively.
"""

doc2 = parse(text2)
latex2 = convert(LaTeX, doc2)
println("\nLaTeX output:")
println(latex2)
println()

# Example 3: Lists and tables
println("=" ^ 60)
println("Example 3: Lists and Tables")
println("=" ^ 60)

text3 = """
= Data Structures

== Common Types

. Arrays
. Dictionaries
. Sets
. Tuples

== Comparison

|===
|Type|Ordered|Mutable
|Array|Yes|Yes
|Dictionary|No|Yes
|Set|No|Yes
|Tuple|Yes|No
|===
"""

doc3 = parse(text3)
html3 = convert(HTML, doc3, standalone=true)
println("\nStandalone HTML output:")
println(html3[1:min(500, length(html3))])
println("...")
println()

# Example 4: Using convenience functions
println("=" ^ 60)
println("Example 4: Convenience Functions")
println("=" ^ 60)

simple_text = """
= Quick Example

This demonstrates the convenience functions.

Check out https://julialang.org[Julia] for more!
"""

latex = asciidoc_to_latex(simple_text)
println("\nDirect LaTeX conversion:")
println(latex)
println()

html = asciidoc_to_html(simple_text)
println("Direct HTML conversion:")
println(html)
println()

# Example 5: Advanced features
println("=" ^ 60)
println("Example 5: Advanced Features")
println("=" ^ 60)

text5 = """
= Advanced AsciiDoc

== Mathematical Notation

Using subscripts~2~ and superscripts^2^.

== Block Quotes

____
The best way to predict the future is to invent it.
____

== Cross References

See <<mathematical-notation>> for details on notation.

'''

That's all!
"""

doc5 = parse(text5)
latex5 = convert(LaTeX, doc5)
html5 = convert(HTML, doc5)

println("\nLaTeX with advanced features:")
println(latex5)
println()

println("HTML with advanced features:")
println(html5)
println()

println("=" ^ 60)
println("Examples Complete!")
println("=" ^ 60)
