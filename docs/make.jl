using Documenter
using AsciiDoc

# Pre-processing: Convert AsciiDoc files to Markdown
# This allows us to write documentation in .adoc and have it compiled to .md
# before Documenter runs.
source_dir = joinpath(@__DIR__, "src")
if isdir(source_dir)
    println("Scanning for .adoc files in $source_dir...")
    for (root, dirs, files) in walkdir(source_dir)
        for file in files
            if endswith(file, ".adoc")
                path = joinpath(root, file)
                println("  Converting $path to Markdown...")
                
                try
                    # Read, Parse, Convert
                    adoc_content = read(path, String)
                    doc = AsciiDoc.parse(adoc_content)
                    md_content = AsciiDoc.to_markdown(doc)
                    
                    # Write to .md
                    md_path = replace(path, ".adoc" => ".md")
                    write(md_path, md_content)
                    println("    Success: $md_path")
                catch e
                    @error "Failed to convert $path" exception=(e, catch_backtrace())
                end
            end
        end
    end
end

makedocs(
    sitename = "AsciiDoc.jl",
    modules = [AsciiDoc],
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Syntax" => "syntax.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    checkdocs = :none # Disable strict docstring checking for this initial build
)
