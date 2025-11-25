# Style Demos

## Styling of Lists

* Lorem ipsum dolor sit amet, consectetur adipiscing elit.
* Nulla quis venenatis justo.
* In non _sodales_ eros.

In an admonition it looks like this:

!!! note "Bulleted lists in admonitions"
    * Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    * Nulla quis venenatis justo.
    * In non _sodales_ eros.

But otherwise:

* Lorem ipsum dolor sit amet, consectetur adipiscing elit.
* Nulla quis venenatis justo.
* In non _sodales_ eros.

In block quotes:

> * Lorem ipsum dolor sit amet, consectetur adipiscing elit.
> * Nulla quis venenatis justo.
> * In non _sodales_ eros.

## Links and Code Spans

Lorem [ipsum](#) dolor sit [`amet`](#), consectetur adipiscing `elit`.

## Code Blocks

```julia
foo = "Example of string $(interpolation)."
```

## Footnote Rendering

This sentence has a footnote.[^1]

[^1]: An example footnote with code:
    ```julia
    x = randn(10)
    sum(x)
    ```

## Numbered Lists in Admonitions

!!! note
    1. First item
    2. Second item
    3. Third item

## Warning Admonition

!!! warning "Be Careful"
    This is a warning message that spans
    multiple lines of text.

## Tip Admonition

!!! tip "Pro Tip"
    Here's a helpful tip for users.
