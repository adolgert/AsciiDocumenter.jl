# Cross-references

This document tests cross-reference functionality.

## Basic Links

* [External link to Julia](https://julialang.org)
* [Link to another page](index.md)
* [Link with title](https://docs.julialang.org "Julia Documentation")

## Internal References

See the [Introduction](#introduction) section below.

Check out the [Code Examples](#code-examples) for more details.

## Introduction

This is the introduction section that can be referenced from above.

Cross-references allow you to link to:

* Other sections in the same document
* Other documents in your project
* External websites
* Specific functions or types

## Code Examples

Here are some code examples:

```julia
# Define a function
function greet(name)
    println("Hello, $name!")
end

# Call the function
greet("World")
```

## Named Sections

### First Named Section

Content of the first section.

### Second Named Section

Content of the second section.

You can reference [First Named Section](#first-named-section) or [Second Named Section](#second-named-section).

## Special Characters in Headers

### Section with `code` in title

This section has inline code in its title.

### Section with *emphasis*

This section has emphasis in its title.

## Summary

Cross-references help users navigate your documentation:

1. Use descriptive link text
2. Keep section IDs stable
3. Test all links before publishing
