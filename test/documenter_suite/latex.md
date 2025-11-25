# LaTeX and Math

This document tests LaTeX math rendering.

## Inline Math

The quadratic formula is ``x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}``.

Einstein's famous equation: ``E = mc^2``.

## Display Math

The Gaussian distribution:

```math
f(x) = \frac{1}{\sigma\sqrt{2\pi}} e^{-\frac{1}{2}\left(\frac{x-\mu}{\sigma}\right)^2}
```

## Equations

Maxwell's equations in differential form:

```math
\nabla \cdot \mathbf{E} = \frac{\rho}{\varepsilon_0}
```

```math
\nabla \cdot \mathbf{B} = 0
```

## Code with Math Comments

```julia
# Compute f(x) = x^2 + 2x + 1
function quadratic(x)
    return x^2 + 2x + 1
end
```

## Math in Lists

Common mathematical constants:

* Pi: ``\pi \approx 3.14159``
* Euler's number: ``e \approx 2.71828``
* Golden ratio: ``\phi = \frac{1 + \sqrt{5}}{2}``

## Math in Admonitions

!!! note "Integration Formula"
    The integral of a polynomial:
    ```math
    \int x^n dx = \frac{x^{n+1}}{n+1} + C
    ```
