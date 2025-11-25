# Font Demo

This document tests font rendering with Unicode characters.

## Standard Font

```julia-repl
julia> for n in 0x2700:0x27bf
            Base.isidentifier(string(Char(n))) && print(Char(n))
    end
✀✁✂✃✄✅✆✇✈✉✊✋✌✍✎✏✐✑✒✓✔✕✖✗✘✙✚✛✜✝✞✟✠✡✢✣✤✥✦✧✨✩✪✫✬✭✮✯✰✱✲✳✴✵✶✷✸✹✺
✻✼✽✾✿❀❁❂❃❄❅❆❇❈❉❊❋❌❍❎❏❐❑❒❓❔❕❖❗❘❙❚❛❜❝❞❟❠❡❢❣❤❥❦❧➔➕➖➗➘➙➚➛➜➝➞➟➠➡
➢➣➤➥➦➧➨➩➪➫➬➭➮➯➰➱➲➳➴➵➶➷➸➹➺➻➼➽➾➿

julia> ❤(s) = println("I ❤ $(s)")
❤ (generic function with 1 method)

julia> ❤("Julia")
I ❤ Julia
```

## Unicode Rendering

Unicode rendering examples for various symbols:

```
'∀'  : Unicode U+2200 (category Sm: Symbol, math)
ERROR: StringIndexError("∀ x ∃ y", 2)
1 ⊻ 3:
```

## Box Drawing Characters

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

## Unicode Plot

```
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

## Table with Unicode

```
julia> pretty_table(data, display_size = (11,30))
┌────────┬────────┬────────┬──
│ Col. 1 │ Col. 2 │ Col. 3 │ ⋯
├────────┼────────┼────────┼──
│      1 │  false │    1.0 │ ⋯
│      2 │   true │    2.0 │ ⋯
│      3 │  false │    3.0 │ ⋯
│   ⋮    │   ⋮    │   ⋮    │ ⋱
└────────┴────────┴────────┴──
   1 column and 3 rows omitted
```
