# Line Numbers in Code Blocks

This document tests code blocks with line number information.

## Basic Code Block

```julia
println("Line 1")
println("Line 2")
println("Line 3")
```

## Multi-line Function

```julia
function calculate_sum(arr)
    total = 0
    for item in arr
        total += item
    end
    return total
end
```

## REPL Style

```julia-repl
julia> x = 1
1

julia> y = 2
2

julia> x + y
3
```

## Nested Blocks

```julia
module MyModule
    function outer()
        function inner()
            println("Nested function")
        end
        inner()
    end
end
```

## Long Code Block

```julia
# This is a longer code block to test line number rendering
struct DataProcessor
    name::String
    config::Dict{String,Any}
end

function process(dp::DataProcessor, data)
    println("Processing with $(dp.name)")

    # Apply configuration
    for (key, value) in dp.config
        println("  $key = $value")
    end

    # Process each item
    results = []
    for item in data
        result = transform(item)
        push!(results, result)
    end

    return results
end

function transform(item)
    return item * 2
end
```
