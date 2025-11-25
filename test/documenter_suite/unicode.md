# Unicode

Some unicode tests here.

In main sans-serif font:

* Checkmark: "✓"
* Circled plus: "⊕"
* XOR: "⊻"
* Exists: "∀", forall: "∃"

Non-highlighted code block:

```
xor:    ⊻
forall: ∀
exists: ∃
check:  ✓
oplus:  ⊕
```

Highlighted code block:

```julia
xor:    ⊻
forall: ∀
exists: ∃
check:  ✓
oplus:  ⊕
```

Inlines:

`xor: ⊻`

`forall: ∀, exists: ∃, check: ✓`

`oplus: ⊕`

## Drawings

ASCII art diagram:

```
┌────────────────────────────────────────────────────────────────────────────┐
│                                             ┌───────────────┐              │
│ HTTP.request(method, uri, headers, body) -> │ HTTP.Response │              │
│   │                                         └───────────────┘              │
│   │                                                                        │
│   │    ┌──────────────────────────────────────┐       ┌──────────────────┐ │
│   └───▶│ request(RedirectLayer, ...)          │       │ HTTP.StatusError │ │
│        └─┬────────────────────────────────────┴─┐     └──────────────────┘ │
│          │ request(BasicAuthLayer, ...)         │                          │
│          └─┬────────────────────────────────────┴─┐                        │
│            │ request(CookieLayer, ...)            │                        │
│            └──────────────────────────────────────┘                        │
└────────────────────────────────────────────────────────────────────────────┘
```

Julia with Unicode plot:

```julia
  ┌──────────────────────────────────────────────────────────────────────┐
1 │                             ▗▄▞▀▀▀▀▀▀▀▄▄                             │
  │                           ▄▞▘           ▀▄▖                          │
  │                         ▄▀                ▝▚▖                        │
  │                       ▗▞                    ▝▄                       │
  │                      ▞▘                      ▝▚▖                     │
  │                    ▗▀                          ▝▚                    │
  │                   ▞▘                             ▀▖                  │
  │                 ▗▞                                ▝▄                 │
  │                ▄▘                                   ▚▖               │
  │              ▗▞                                      ▝▄              │
  │             ▄▘                                         ▚▖            │
  │           ▗▀                                            ▝▚           │
  │         ▗▞▘                                               ▀▄         │
  │       ▄▀▘                                                   ▀▚▖      │
0 │ ▄▄▄▄▀▀                                                        ▝▀▚▄▄▄▖│
  └──────────────────────────────────────────────────────────────────────┘
  0                                                                     70
```

DataFrame table representation:

```
2×4 DataFrames.DataFrame
│ Row │ a     │ b       │ c     │ d      │
│     │ Int64 │ Float64 │ Int64 │ String │
├─────┼───────┼─────────┼───────┼────────┤
│ 1   │ 2     │ 2.0     │ 2     │ John   │
│ 2   │ 2     │ 2.0     │ 2     │ Sally  │
```
