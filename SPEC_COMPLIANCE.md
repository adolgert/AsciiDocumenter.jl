# AsciiDoc Specification Compliance

This document tracks our implementation against the official AsciiDoc specification maintained by the Eclipse Foundation AsciiDoc Working Group.

## References

- [AsciiDoc Language Documentation](https://docs.asciidoctor.org/asciidoc/latest/) - Official docs (de facto standard until spec is ratified)
- [AsciiDoc Language Project at Eclipse](https://projects.eclipse.org/projects/asciidoc.asciidoc-lang)
- [AsciiDoc Syntax Quick Reference](https://docs.asciidoctor.org/asciidoc/latest/syntax-quick-reference/)
- [GitLab AsciiDoc Spec Repository](https://gitlab.eclipse.org/eclipse/asciidoc-lang/asciidoc-lang)

## Implementation Status

### ✅ Implemented Features

#### Document Structure
- [x] **Headers** (= to ======) - Levels 1-6
  - [x] Header IDs `[#id]`
  - [ ] Auto-generated IDs
  - [ ] Custom ID prefix
- [x] **Paragraphs** - Regular text blocks
- [x] **Horizontal Rules** - `'''` and `---`
- [ ] **Document Header** - Metadata and attributes
  - [ ] Document title
  - [ ] Author information
  - [ ] Revision information
  - [ ] Document attributes

#### Text Formatting (Inline)
- [x] **Bold** - `*text*`
- [x] **Italic** - `_text_`
- [x] **Monospace** - `` `text` ``
- [x] **Subscript** - `~text~`
- [x] **Superscript** - `^text^`
- [ ] **Highlight** - `#text#`
- [ ] **Underline** - `[underline]#text#`
- [ ] **Strikethrough** - `[line-through]#text#`
- [ ] **Small text** - `[small]#text#`
- [ ] **Big text** - `[big]#text#`

#### Lists
- [x] **Unordered Lists** - `*` and `-`
  - [x] Basic items
  - [ ] Nested lists (partially - structure exists but not fully tested)
  - [ ] Max nesting level (5)
- [x] **Ordered Lists** - `.` and `1.`
  - [x] Basic items
  - [x] Numbering styles (arabic, alpha, roman)
  - [ ] Nested lists
  - [ ] Custom start number
- [x] **Definition Lists** - `term::`
  - [x] Basic term/definition pairs
  - [ ] Horizontal vs vertical layout
  - [ ] Multiple definitions per term
- [ ] **Checklists** - `* [ ]` and `* [x]`
- [ ] **Q&A Lists**

#### Code Blocks
- [x] **Listing Blocks** - `----`
- [x] **Source Blocks** - `[source,language]`
  - [x] Language specification
  - [ ] Line numbers
  - [ ] Callouts
  - [ ] Highlighting specific lines
- [ ] **Literal Blocks** - Indented by one space
- [ ] **Passthrough Blocks** - `++++`

#### Block Quotes
- [x] **Quote Blocks** - `____`
  - [x] Basic content
  - [x] Attribution (basic support)
  - [ ] Citation title
  - [ ] Verse blocks

#### Tables
- [x] **Basic Tables** - `|===`
  - [x] Rows and cells
  - [x] Headers (first row detection)
  - [ ] Column alignment (left, center, right)
  - [ ] Cell spanning (colspan, rowspan)
  - [ ] Column width
  - [ ] CSV data support
  - [ ] Nested tables
  - [ ] Footer rows
  - [ ] Table caption/title

#### Admonitions
- [ ] **NOTE** - `NOTE: text`
- [ ] **TIP** - `TIP: text`
- [ ] **IMPORTANT** - `IMPORTANT: text`
- [ ] **WARNING** - `WARNING: text`
- [ ] **CAUTION** - `CAUTION: text`
- [ ] Block form with compound content

#### Links and References
- [x] **URLs** - `https://example.com`
- [x] **Links with text** - `https://example.com[text]`
- [x] **Images** - `image:path[alt]`
  - [x] Basic syntax
  - [ ] Width/height attributes
  - [ ] Alignment
  - [ ] Link to URL
- [x] **Cross-references** - `<<target>>` and `<<target,text>>`
  - [x] Basic xref
  - [ ] Inter-document xrefs
  - [ ] Natural xref text

#### Advanced Blocks
- [ ] **Sidebars** - `****`
- [ ] **Example Blocks** - `====`
- [ ] **Open Blocks** - `--`
- [ ] **Literal Paragraphs**
- [ ] **Pass Blocks** - `++++`

#### Macros
- [x] **Image macro** - `image::`
- [ ] **Include directive** - `include::`
- [ ] **Link macro** - `link:`
- [ ] **Anchor macro** - `anchor:`
- [ ] **Icon macro** - `icon:`
- [ ] **Keyboard macro** - `kbd:`
- [ ] **Button macro** - `btn:`
- [ ] **Menu macro** - `menu:`

#### Attributes
- [ ] **Document attributes** - `:name: value`
- [ ] **Attribute references** - `{name}`
- [ ] **Built-in attributes** (author, docdate, etc.)
- [ ] **Attribute unset** - `:name!:`
- [ ] **Conditional attributes**
- [ ] **Attribute entry substitution**

#### Other Features
- [ ] **Comments** - `//` and `////`
- [ ] **Line breaks** - `+`
- [ ] **Page breaks** - `<<<`
- [ ] **Footnotes** - `footnote:[text]`
- [ ] **Bibliography** - `[bibliography]`
- [ ] **Index terms** - `indexterm:[term]`
- [ ] **Math/STEM** - `stem:[equation]`
- [ ] **Inline anchors** - `[[id]]`
- [ ] **Role attribute** - `[role]#text#`

### Backend-Specific Features

#### LaTeX Backend
- [x] Section commands (\section, \subsection, etc.)
- [x] Text formatting (\textbf, \textit, \texttt)
- [x] Lists (itemize, enumerate, description)
- [x] Code blocks (verbatim, listings)
- [x] Tables (tabular)
- [x] Block quotes (quotation)
- [x] Links (\href, \url)
- [x] Images (figure, includegraphics)
- [x] Cross-references (\ref, \hyperref)
- [x] LaTeX escaping
- [ ] Custom LaTeX preamble
- [ ] Package requirements documentation

#### HTML Backend
- [x] Semantic HTML5 tags
- [x] Text formatting (strong, em, code)
- [x] Lists (ul, ol, dl)
- [x] Code blocks with language classes
- [x] Tables (table, tr, td, th)
- [x] Block quotes (blockquote)
- [x] Links (a href)
- [x] Images (img)
- [x] Cross-references (internal links)
- [x] Standalone mode with CSS
- [ ] Custom CSS themes
- [ ] JavaScript for interactivity
- [ ] Syntax highlighting integration (highlight.js, prism.js)

## Priority Features to Implement

Based on common use cases, here are the priority features to add:

### High Priority
1. **Document attributes** - Essential for metadata and configuration
2. **Admonitions** - Very common in technical documentation (NOTE, TIP, WARNING, etc.)
3. **Include directive** - Critical for modular documentation
4. **Comments** - Basic feature for documentation workflow
5. **Better table support** - Column alignment, cell spanning
6. **Auto-generated header IDs** - Important for linking

### Medium Priority
7. **Sidebars and example blocks** - Common in technical docs
8. **Footnotes** - Academic and technical writing
9. **More inline formatting** - Highlight, strikethrough
10. **Callouts in code blocks** - Technical documentation
11. **Attribute references** - Dynamic content

### Low Priority
12. **Bibliography** - Specialized use case
13. **Index terms** - Mostly for book-length documents
14. **STEM/Math** - Specialized use case
15. **Keyboard/button/menu macros** - UI documentation specific

## Compatibility Notes

### Differences from Asciidoctor
1. **Attribute substitution** - Not yet implemented
2. **Include processing** - Not yet implemented
3. **Extensions/plugins** - No extension mechanism yet
4. **Preprocessor directives** - Not implemented
5. **Custom backends** - Need to subclass and implement manually

### Intentional Simplifications
1. **Single-pass parser** - Asciidoctor uses multiple passes
2. **No block substitutions** - Keeping parser simple
3. **Limited attribute support** - Will add incrementally
4. **No macros/extensions** - Future enhancement

## Testing Against Specification

To test compliance:

```julia
# Test with official AsciiDoc examples
include("test/spec_compliance.jl")
```

## Contributing to Compliance

When adding features from the spec:

1. Check the [official documentation](https://docs.asciidoctor.org/asciidoc/latest/)
2. Add AST node types if needed (src/ast.jl)
3. Update parser (src/parser.jl)
4. Add backend support (src/latex.jl, src/html.jl)
5. Add tests (test/runtests.jl)
6. Update this document
7. Add examples (examples/)

## Version Tracking

- **AsciiDoc.jl**: 0.1.0
- **Target Spec**: AsciiDoc Language (in development at Eclipse Foundation)
- **Reference Implementation**: Asciidoctor 2.x
- **Julia Compatibility**: 1.10+

## Resources

- [AsciiDoc Language Documentation](https://docs.asciidoctor.org/asciidoc/latest/)
- [AsciiDoctor Documentation](https://asciidoctor.org/docs/)
- [AsciiDoc Syntax Quick Reference](https://docs.asciidoctor.org/asciidoc/latest/syntax-quick-reference/)
- [Document Header](https://docs.asciidoctor.org/asciidoc/latest/document/header/)
- [Includes](https://docs.asciidoctor.org/asciidoc/latest/directives/include/)
- [Admonitions](https://docs.asciidoctor.org/asciidoc/latest/blocks/admonitions/)
- [Document Attributes](https://docs.asciidoctor.org/asciidoc/latest/attributes/document-attributes/)
