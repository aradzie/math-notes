---
name: import-openstax-exercises
description: Import the end-of-section "Exercises" from an OpenStax textbook page into a standalone LaTeX file under openstax/. Use when asked to extract, transcribe, convert, or import exercises/problems from an openstax.org page.
---

# Import OpenStax Exercises

## Purpose

Turn an OpenStax page's own end-of-section exercise list (e.g.
`https://openstax.org/books/calculus-volume-2/pages/5-1-sequences`) into a
standalone, compilable `.tex` file under `openstax/` at the repo root,
reproducing the problem text and math verbatim.

This is a source-material reproduction, not one of the three self-authored
artifact types described in `CLAUDE.md` (flashcards, self-check questions,
essays) — it's raw textbook content kept for reference/practice, licensed
from OpenStax under CC BY 4.0 (see Attribution below).

## The tool: `openstax/extract-exercises.py`

Don't redo this by hand or by fetching-and-summarizing the page — a working,
tested extractor already exists. Run it via `uv run`:

```
cd openstax
uv run extract-exercises.py <page-url> [-o output.tex]
```

It fetches the page, pulls the exercises section, converts every formula
from MathML to LaTeX, and writes a standalone document (default output name:
`<vol-prefix><page-slug>.tex`, e.g. `vol2-5-1-sequences.tex`
— see "Output conventions" below for the `vol2-`/`vol3-` prefix). Then build
and eyeball it before considering the job done:

```
make -C openstax          # compiles every openstax/*.tex via texlive.sh + latexmk
pdftoppm -png -r 100 openstax/<file>.pdf tmp/check/page   # run on the HOST, not through texlive.sh
```

Open a few of the resulting PNGs and compare against the live page,
especially any exercise with unusual notation (piecewise definitions,
matrices, multi-line displays) — the converter's tag coverage (below) is
only what's been seen so far, and a page with an unfamiliar MathML tag will
either raise or silently emit something wrong.

`pdftoppm` runs directly on the host (it's already installed there) rather
than through `texlive.sh`: `texlive.sh` only bind-mounts `$PWD` into the
container, so a `latexmk -outdir` or a rendering tool pointed outside the
repo (e.g. plain `/tmp`) writes to the container's throwaway filesystem and
vanishes on exit. Build LaTeX output under the repo (e.g. `openstax/aux/` via
the Makefile, which is what it already does) or a repo-relative scratch dir
like `tmp/` (gitignored) if you need an intermediate location.

## Why not just WebFetch the page?

Tried first, doesn't work: WebFetch converts the page to markdown and hands
it to a small intermediate model, which — even when told the content is
CC BY 4.0 and reproduction with attribution is explicitly permitted —
declines to transcribe problem statements verbatim, citing copyright. It
offers to paraphrase or summarize instead, which defeats the purpose (you
need the exact wording and exact formulas). There's no prompt that reliably
talks it out of this; go straight to fetching raw content instead (which is
what the script does).

## How the extraction actually works

1. **The rendered page is a client-side app; the initial HTML is nearly
   empty of content.** It does embed one useful thing: a
   `window.__PRELOADED_STATE__ = {...}` JS object containing the book's
   `id`, `contentVersion`, `archiveVersion`, and the current page's `id`
   (a UUID) — but not the page body itself.
2. **The actual content comes from OpenStax's public archive API**, no
   auth needed:
   ```
   https://openstax.org/apps/archive/{archiveVersion}/contents/{book_id}@{contentVersion}:{page_id}.json
   ```
   The JSON response's `content` field is an HTML fragment containing the
   whole page body, including a `<section class="section-exercises">` at
   the end holding the exercises. This has held steady across every page
   imported so far; if a future page returns something structurally
   different, treat the URL pattern as a hypothesis to verify, not a
   guarantee.
3. **Math is authored as MathML, not TeX/MathJax source** — despite what
   the rendered page's MathJax output might suggest. Each formula is a
   `<span class="os-math-in-para"><math>...</math></span>` with a
   presentation-MathML tree followed by an `<annotation-xml
   encoding="MathML-Content">` sibling (redundant content-MathML, ignored).
   There is no TeX annotation to fall back on — the converter has to walk
   the presentation tree itself.
4. **Exercises section structure**: a flat sequence of shared-instruction
   `<p>` elements (e.g. "Find the first six terms of...") interleaved with
   `<div data-type="exercise">` blocks, each wrapping a `<div
   data-type="problem"><div class="os-problem-container">` with the actual
   `<p>` statement (and occasionally an `<ol><li>` for lettered (a)/(b)/(c)
   sub-parts). The intro paragraphs are not numbered but the exercises
   after them continue the same numbering — reproduced in LaTeX with
   `enumitem`'s `enumerate[resume]` so plain-text instructions can interrupt
   a continuously-numbered list.

### MathML tag coverage (extend `convert_node` in the script together with this table)

Handled so far: `mrow`, `mstyle`, `mi`, `mn`, `mo` (including `∑` and `∫`, mapped to
`\sum `/`\int ` and typically the base of a `munderover` or `msubsup` for
`\sum_{...}^{...}` / `\int_{N}^{\infty}`), `mtext`, `msub`, `msup`,
`msubsup` (see the operator-base quirk below), `mfrac`, `msqrt`, `mroot`,
`munder` (used for `\lim_{n\to\infty}` — detected by checking the base is
literally `\lim`), `mover`, `munderover`, `mspace`, `mtable`/`mtr`/`mtd`
(a `<mo>(</mo><mtable>` one-column, two-row layout is OpenStax's idiom for
a binomial coefficient; a single-column table whose every `mtd` carries
`columnalign="left"` — OpenStax's idiom for a left-aligned system of
equations — renders as `\begin{array}{l}...\end{array}` instead of
`\begin{matrix}`, since `matrix`'s centered column visibly misaligns rows
of different width), `mfenced` (default `open`/`close`/`separators`
attrs only, plus two literal-ASCII idioms mapped to real delimiter macros:
`open`/`close` of `"||"` — a doubled ASCII pipe, OpenStax's norm/magnitude
notation, e.g. `<mfenced open="||" close="||">` — becomes `\left\|...
\right\|`, and `open="<"`/`close=">"` — the same angle-bracket vector/tuple
notation as the Unicode `〈`/`〉` `<mo>` characters, just spelled in plain
ASCII — becomes `\left\langle...\right\rangle`; neither raw glyph is a
valid `\left`/`\right` delimiter on its own, so left unmapped these fail
loudly (`\left<`: "Missing delimiter") or render wrong (`\left||...
\right||`: single-weight bars, not a proper norm symbol)).
Not yet seen/handled: `mpadded`, `mmultiscripts`, `menclose`. If a new page
uses one of these, extend the converter rather than hand-patching the
output.

**`mstyle`/`mi`/`mtext` `mathvariant="bold"` is OpenStax's bold-vector
notation** (e.g. bold **F** for a vector field name, bold **i**/**j**/**k**
unit vectors) — seen in three different shapes: `<mstyle
mathvariant="bold">` wrapping an `<mtext>`, a bare `<mi mathvariant="bold">`,
and a bare `<mtext mathvariant="bold">`, all for the same styling intent.
Left unhandled, the attribute was silently dropped and the letter printed
in ordinary (upright or italic) weight — no error, just quietly wrong
typesetting on a page that's otherwise entirely about vector notation.
`mi`/`mtext` each check their own `mathvariant` and wrap in `\mathbf{}`
directly; `mstyle` does *not* wrap the whole already-converted subtree in
an outer `\mathbf{}` (nesting `\mathbf{\text{F}}` this way silently fails
to bold anything, since `\mathbf` doesn't affect `\text` mode's font) —
instead it pushes `mathvariant="bold"` down onto any `mi`/`mtext`
descendant that doesn't already carry its own, then converts normally, so
the single-node handling above does the actual wrapping.

**Don't render the binomial-coefficient idiom as
`\left(\begin{matrix}..\end{matrix}\right)`** — `convert_node`'s
`mrow`/`math`/`semantics` branch specifically detects the `"(" mo,
two-row-one-col mtable, ")" mo` triple (via `as_binom_table`) and emits
`\binom{top}{bottom}` instead. This isn't just cosmetic: one page had this
idiom as the *denominator of an `mfrac`* (`$\frac{x^n}{\binom{2n}{n}}$`),
and `\begin{matrix}` inside a `\frac{}{}` argument silently corrupts the
layout — `\frac` grabs its argument as a token list before
`\begin{matrix}`'s `\halign` machinery can run in the right context, so the
two rows visually split apart on the page with no compile error at all.
`\binom{}{}` is a plain math macro (no `\halign`) and nests safely
anywhere — the actual fix, not just a style preference. If a future page
nests this idiom somewhere new (`msqrt`, another `mfrac`, etc.), the risk
is the same and `\binom` is still the answer.

**Subscript and superscript bases use only the grouping TeX actually
needs.** MathML identifies the base structurally, but an earlier converter
version emitted a TeX group around every base, producing noisy forms such
as `{x}^{2}`, `{\sin }^{2}`, and `{\sum }_{n=1}^{\infty}`. The
`convert_script_base()` helper now emits atomic bases directly (`x^{2}`,
`\sin^{2}`, `\sum_{n=1}^{\infty}`), unwraps single-child transparent
`mrow`/`mstyle` containers, and keeps braces around genuinely compound
bases such as `{x+1}^{2}`. Do this from the MathML structure; a regex over
finished TeX cannot reliably distinguish redundant braces from necessary
grouping.

## Symbol mapping: `MI_MAP`, `MO_MAP`, and `mtext` escaping

Non-ASCII math symbols go through one of three lookup tables depending on
which MathML tag wraps them: `MI_MAP` (identifiers — Greek letters, `∞`),
`MO_MAP` (operators — `≤ ≥ → ± × · ⋯ … ∑ ∫ 〈 〉 ∈` and the `′`/`″` prime
marks), or a small substitution list inside the `mtext` branch itself
(`− … ⋯ ± ·` plus backslash-escaping `% $ & #`). All three currently cover
the full lowercase Greek alphabet plus the 11 uppercase letters that are
visually distinct from Latin (`Γ Δ Θ Λ Ξ Π Σ Υ Φ Ψ Ω` — the rest look
identical to a Latin letter and have no LaTeX macro to map to, so they're
intentionally omitted).

**The same character shows up under different tags on different pages, and
sometimes different tags on the same page** — OpenStax's authoring isn't
consistent about which of `mi`/`mo`/`mtext` wraps a given symbol (`±` has
been seen as both `mo` and `mtext`; `∞` as both `mi` and `mo`; `·`/`⋯` as
both `mtext` and bare `mo`). When a page raises `LaTeX Error: Unicode
character ... not set up`, or (quieter) a symbol renders as literal
mojibake instead of the macro you expected, **grep that specific page's
raw fetched content for the tag actually used** rather than assuming
whichever map already has an entry for that character in some other tag is
the one that needs updating — check all three.

**Letter-based macros need a trailing space in the map value** (`r"\le "`,
not `r"\le"`) — TeX's tokenizer greedily extends a control-word name across
a following letter, so `\le` immediately before `x` becomes the single
undefined command `\lex`, not `\le` + `x`. Digits and symbols terminate a
control word fine (`\ge1` is not a problem) — only letter neighbors are.
Every letter-macro entry in `MI_MAP`/`MO_MAP` follows this convention;
keep it when adding new ones.

**A trailing control-word delimiter is removed whenever a non-letter makes it
redundant.** The deliberately safe map values above can otherwise leave noisy
source such as `\frac{13\pi }{2}` or `[-\pi ,\pi ]`: the space is needed
before a following letter, but any non-letter character (`}`, a digit, `,`,
`=`, ...) already terminates the control word on its own — TeX gobbles a
control word's trailing spaces during tokenizing regardless of what follows,
so the space was never doing anything there. Before wrapping each converted
formula in math mode, `strip_redundant_control_word_delimiter_spacing()`
changes a letter-based control word followed by a literal space and any
non-letter, non-backslash character into the same control word directly
followed by that character — producing `\frac{13\pi}{2}` and `[-\pi,\pi ]`
without risking the `\pix` tokenization bug or removing semantic spacing
commands such as `\,`. A following backslash is deliberately left alone
(`\pi \theta` keeps its space) — lexically safe to merge too, but harder to
read with no separator between two macro names.

**A bare `:` left in math mode is not just a glyph** — TeX's default math
code classifies it as a Relation (the same class as `=`), which inserts an
automatic thick skip on both sides ("Hint : x = ..." instead of
"Hint: x = ..."). The `mtext` branch's non-word return path wraps a bare
`:` as `{:}` — bracing a single token forces TeX to treat that group as an
`Ord` atom regardless of the character's default math class, the standard
idiom for suppressing this exact spacing quirk.

**Prose can carry curly quotes (`“` `”`, U+201C/U+201D), not just the
already-handled right-single-quote apostrophe.** Section 3.7's "answer
'divergent.'"-style instructions use real Unicode double quotation marks
directly in plain text (outside any `<math>` element) — added to
`escape_plain_text`'s substitution list as LaTeX's native `` `` ``/`''`
open/close-quote idiom, next to the existing `’`→`'` entry.

**Visually-identical Unicode lookalikes are easy to mistranscribe** — the
inner-product angle brackets OpenStax actually emits are U+2329/U+232A,
which are canonically deprecated in favor of the visually identical
U+3008/U+3009 (CJK angle brackets). Verify with `ord()` against the
*actual fetched page content*, not by eye, before adding a dict entry for
a lookalike character. A different page has since used yet another
lookalike pair for the same angle brackets — U+27E8/U+27E9 (the canonical,
non-deprecated MATHEMATICAL ANGLE BRACKET codepoints) under `<mo>` — mapped
the same as the others; check all three (`〈〉`/`〈〉`/`⟨⟩`) whenever a new
page's angle-bracket vector notation renders wrong or raises.

**The same base letter can arrive as more than one Greek Unicode
codepoint.** A page using `φ` (U+03C6, GREEK SMALL LETTER PHI) for potential
functions elsewhere used `ϕ` (U+03D5, GREEK PHI SYMBOL) instead — a
distinct codepoint, not a typo — under `<mi>`. Mapped to the same `\phi`
macro as the U+03C6 entry already in `MI_MAP`; if a future page's Greek
letter renders as an unmapped-symbol warning despite that letter already
having an `MI_MAP` entry, check for exactly this kind of symbol-vs-letter
Unicode variant before assuming the map entry is missing.

**`∇` (U+2207 NABLA) under `<mtext>` needs its own substitution, separate
from the `MO_MAP`/`MI_MAP` entries already used for it under `<mo>`.** The
`mtext` branch only falls back to `MI_MAP` for a bare *Greek letter*
(alphabetic check), and `∇` is neither alphabetic nor in that table, so it
fell through unmapped despite `MO_MAP` already having the right macro for
the `<mo>` case. Added to the same `°`-style non-word substitution chain
inside the `mtext` branch (`t.replace("∇", r"\nabla ")`).

## Spacing: `mtext` words and `mspace`

A bare English word inside `mtext` (e.g. "if", "and", "-kg") needs two
things together, not just one: `\text{}` wrapping (`mtext`'s branch,
gated on `any(ch.isalpha() for ch in raw)` computed from the *raw*
pre-escape text, so the `\ldots`/`\cdots` substitutions don't themselves
trip the alpha check) fixes the font (otherwise each letter renders as its
own italicized math variable, e.g. `0ifa_n<0`), but by itself adds no
visible gap: LaTeX math mode spaces purely by atom class, and two `Ord`
atoms (`0` and `\text{if}` are both `Ord`) get *zero* automatic spacing,
ignoring literal whitespace characters in the source entirely. The actual
gap comes from `mspace`: OpenStax's own `<mspace width="...">` nodes,
which the `mspace` branch converts into real glue (`\,` or `\quad`, see
below) rather than a literal `" "` character (which math mode would
discard just like any other raw whitespace token).

**`mspace`'s source `width` attribute (`"0.1em"`, `"0.2em"`, `"0.5em"`) is
not a meaningful measurement, so don't reproduce it literally with
`\hspace{<width>}`** — it's just whatever OpenStax's own renderer happened
to use, not a deliberate typesetting choice, and it reads as visual noise
in the `.tex` source. Instead `mspace` maps to the standard semantic
spacing macro for its rough size: `\,` (thin space) for the common small
gap (before a differential, around implicit multiplication or an inline
word), `\quad` for the one wide gap (`"0.5em"`) that separates two
independent clauses crammed into one `$...$`
(`$F(x)=\ldots;\quad f(t)=\ldots$`). Neither risks the letter-merging bug
above (`\,` is a control *symbol*, not a control *word*, so it never needs
a trailing space; `\quad` already carries one). Don't confuse this with
`BLANK_LINE` (`\underline{\hspace{1.5cm}}`, see below) — a fixed-width
visual rule for a fill-in-the-blank, generated by a completely different
code path, whose literal width *is* meaningful and must stay.

**Most `mspace` next to a named function or `\times` is redundant, and
`strip_redundant_spacing()` removes it.** OpenStax's own renderer doesn't
treat "sin" as a real math operator, so its source places an explicit
`<mspace>` next to one far more often than the `\text{if}`/`\text{-kg}`
case above. But every name in `FUNC_NAMES` (`sin cos tan cot sec csc ln
log lim exp cosh sinh tanh arctan`) gets converted to a genuine LaTeX
operator macro (all `Op`-class), and `Op` next to an `Ord` atom already
gets an automatic thin space from TeX's math-spacing table in *both*
directions — same for the `Bin`-class `\times`. So `\sin \,1` and `\sin 1`
render identically; the explicit `\,` just duplicates spacing that was
already there. `strip_redundant_spacing()` (called at the end of
`render_tex`) removes a `\,`/`\quad` only when immediately adjacent to one
of these self-spacing macros (the set is derived straight from
`FUNC_NAMES` plus `"times"`, so any name later added to `FUNC_NAMES` is
automatically covered). It leaves every other `mspace` alone — two plain
`Ord` atoms (a variable, digit, or `\text{}` word) get zero automatic
spacing, so the gap before a differential (`f(t)\,dt`) or around an inline
word is load-bearing and dropping it would visibly glue tokens together
(`f(t)dt`, `0if`).

**This is why `cosh`, `sinh`, `tanh`, and `arctan` are in `FUNC_NAMES`
even though they're rarer than `sin`/`cos`/`ln`**: without that, the
`mtext` branch's generic word-wrapping falls back to `\text{cosh}`, which
is an `Ord` atom (plain upright text) with *no* automatic operator
spacing — naively stripping the space next to it (as an earlier version of
this fix did) silently glues `\text{cosh}x` into "coshx". If a page
surfaces another named function this way, add it to `FUNC_NAMES` — that
both fixes the missing-operator-semantics bug and makes it eligible for
the same spacing cleanup — rather than special-casing its `\text{}` form.
`\operatorname{...}` would also get automatic `Op`-class spacing without
needing a real predefined macro to exist, so it's worth reaching for
*instead of* `FUNC_NAMES` only if a future function name has no dedicated
LaTeX macro at all (e.g. `argmax`) — every name in `FUNC_NAMES` today is a
real predefined operator, and using the literal macro name means a typo or
non-existent name fails loudly at build time instead of silently compiling
via `\operatorname{}`.

**Integral differentials always receive a thin space after the integrand,
even when OpenStax omits `mspace`.** The source is inconsistent here: the
same exercise group can contain both an explicit `<mspace>` before `dx` and
an adjacent integrand/`d` pair with no space at all.  LaTeX conventionally
separates the integrand from its differential (`\int f(x)\,dx`), so the
converter recognizes the source structure `<mi>d</mi><mi>x</mi>` (or a
Greek integration variable), checks that an unmatched integral precedes it,
and supplies `\,` when the differential follows an integrand.  It preserves
an existing `mspace` and does not rewrite finished TeX with a regex; this is
important for differentials nested in a fraction numerator and for avoiding
unrelated forms such as `dy/dx`.  The imported source's italic `d` is
retained; changing it to an upright `\mathrm{d}` would be a separate style
decision rather than a spacing correction.

## Other rendering gotchas

- **Sentence punctuation at the end of inline MathML belongs outside math
  mode in the generated LaTeX.** OpenStax commonly includes a final comma,
  period, semicolon, colon, or question mark as the last top-level token of
  the `<math>` element, which used to produce forms such as `$x_{0},$` and
  `$f(x)=0.$`. `convert_math()` now uses `trailing_prose_punctuation()` to
  recognize only a terminal punctuation token reached through transparent
  MathML wrappers and emits `$x_{0}$,` / `$f(x)=0$.` instead. It also handles
  punctuation fused into a final numeric token such as `<mn>0.</mn>`, without
  disturbing a real decimal such as `4.75`. Do not replace punctuation around
  dollar signs with a regex: punctuation inside a nested construct can be
  mathematical, and a terminal `!` may be a factorial, so exclamation marks
  are deliberately left in math mode.
- **A "graph this curve" exercise can carry its own reference figure
  embedded right inside the problem container** — section 3.4 had a
  `data-type="media"` element (an `<img>` with descriptive `alt`/`data-alt`
  text, presumably for accessibility) as a sibling of the exercise's `<p>`,
  inside the same `os-problem-container`; 4.2 has several as top-level
  siblings of the intro `<p>`s (one direction-field image per problem
  group, outside any exercise container); 7.3 has one inside an exercise
  container again. Seen as both `<div data-type="media">` and a bare
  `<span data-type="media">` — check the specific element's tag before
  assuming one form covers both. There's no way to reproduce the image
  itself, but its `data-alt` (duplicated onto the nested `<img>`'s `alt`)
  is a genuine, often multi-sentence prose description of what the figure
  shows — not boilerplate, and in exercises like 4.2's "match the
  direction field with the given equation" or 7.3's "give two sets of
  polar coordinates for each point [A-D]," the *only* way to attempt the
  problem at all without the missing image. `media_placeholder()` renders
  it as `\textit{[Figure: <description>]}` — an "intro" paragraph when the
  media sits at the section top level (4.2), or appended as its own
  `\\`-prefixed line within the item when it's inside an exercise
  container (3.4, 7.3), never as the first part of an item (no `\\` with
  nothing before it — the same reasoning as the newline-span case below).
  **This surfaced a latent gap in `escape_plain_text`**: description text
  is ordinary prose, run through the same plain-text escaping as any other
  `<p>` content, and 7.3's description used a bare `θ` (not the already-
  handled `π`) — pdflatex rejected it as an unset-up Unicode character the
  same way a stray symbol anywhere else in prose would. The single
  `π`-only special case was replaced with a loop over every single-
  character `MI_MAP` entry (Greek letters, `∞`), so any of them dropped
  directly into prose now gets wrapped in inline math the same way,
  instead of waiting for each one to surface as its own bug.
- **`msubsup` with a bare `+`/`-` mo base is not a literal sub/superscript
  on that operator** — it's OpenStax's encoding of a small inline fraction
  typeset immediately after the operator, e.g. `+` with sub `n`, sup `1`
  means `$+ \frac1n$`, not `$+_n^1$` (confirmed against a live page whose
  rendering only makes sense as $\ln(1+\frac1n)$). `convert_node`'s
  `msubsup` branch special-cases a `+`/`-` mo base and swaps to
  `%s\frac{sup}{sub}`. If a future page shows the same pattern on some
  other operator, extend that same check rather than adding a new branch.
- **`mfenced` with no handler silently drops its own parentheses** and
  just concatenates its children (the generic tag fallback) — turning
  `<mfenced><mrow>n - 1</mrow></mfenced>` into `n-1`, changing
  `1/(2(n-1))` into `1/(2n-1)`, a different formula, with no error at all.
  Now handled explicitly (see the tag-coverage table above). This is the
  "silent content loss" failure mode "After extracting" (below) warns
  about — caught only by comparing the rendered PDF against the live page.
- **`∞` is not always an `mi`** — sometimes the upper bound of a
  `munderover` sum is `<mo>∞</mo>` instead. Both `MI_MAP` and `MO_MAP` need
  the entry, or the `mo` variant falls through to a raw `∞` character that
  `pdflatex` rejects outright (at least that failure mode is loud, unlike
  the `mfenced` one above).
- **A standalone `<div data-type="equation">` block is a display-math
  sibling, not a `<p>`** — section 4.2's model-building paragraphs put a
  system of equations in its own `<div data-type="equation"><math
  display="block">...</math></div>`, directly between two `<p>` elements
  (at the section-exercises top level) and, separately, directly inside an
  `<os-problem-container>` (no wrapping `<p>`). Neither the top-level loop
  (which only recognized `<p>` and `<div data-type="exercise">`) nor
  `handle_exercise_div`'s container loop (which only pulled `<p>`
  descendants out of a generic `<div>`) matched it, so the whole equation
  vanished from the output with no error — another instance of the
  "silent content loss" pattern below, this time for a large visible block
  rather than one symbol. Fixed by matching `data-type="equation"`
  explicitly in both places and rendering its `<math>` with the new
  `convert_display_math()` (emits `\[...\]`, no `$...$`/trailing-punctuation
  handling — a display block's own final punctuation belongs inside it).
- **A bare `<mo>` whose text is a non-breaking space (U+00A0) is another
  spacing idiom, not a stray character** — section 4.2 used `<mo>&#160;</mo>`
  between tokens (e.g. around `=` in `y(0)\xa0=\xa02`) the same way other
  pages use `<mspace>`. Left unmapped, the raw U+00A0 leaked straight into
  the `.tex` output — quiet until `pdflatex` rejected it as an unset-up
  Unicode character. The `mo` branch now special-cases text that's entirely
  U+00A0 and maps it to `\,`, same as `mspace`'s default.
- **A `<span data-type="newline"><br/></span>` is OpenStax's manual
  mid-paragraph line break**, not decoration to drop — section 7.1's
  epitrochoid exercise puts a displayed system of equations and a
  follow-up "Let a=1, b=2, c=1." sentence in the *same* `<p>`, separated by
  one of these spans instead of a second paragraph. `node_to_text`'s
  generic fallback recursed into it, found only an empty `<br/>`, and
  produced nothing — not a math error, but the two sentences ran together
  with no separation at all. Now mapped to `\\` (a manual line break, valid
  inside `\item` text) — **but only when something follows it.** OpenStax
  also uses this span, alone in an otherwise-empty `<p>`, purely to tuck an
  intro sentence tight against an image immediately below it in its own
  renderer (e.g. 4.2's "Match the direction field..." groups, one such
  `<p>` per image; the images themselves are already correctly dropped as
  `data-type="media"`). Since that image is never reproduced, a `\\` with
  nothing after it is at best a pointless forced break right before a
  paragraph/item that was ending anyway, and at worst — when the *entire*
  `<p>` was just this span — a bare `\\` with no preceding text on its
  line, which `pdflatex` rejects outright ("There's no line here to end").
  `node_to_text()` now strips a *trailing* `\\` (one with nothing after it
  in the same converted text) after building each paragraph, so a break
  attached to real text on both sides survives untouched, a break at the
  very end is silently dropped, and a `<p>` that was only the span
  collapses to `""` (already filtered out by every caller's `if text:`
  check).
- **A leading `[` right after `\item` is parsed as `\item`'s optional
  relabeling argument**, not literal text — OpenStax marks
  technology-required exercises with a literal `[T]` prefix, and
  `\item [T] ...` silently replaces the item's number with the label "T".
  That marker is always exactly `[T]` in practice, so
  `escape_item_bracket()` emits `exercises.cls`'s `\techrequired` macro for
  it (which expands to `[T]` plus the space that would otherwise be
  swallowed reading the control word's name) instead of raw escaped text;
  any other leading `[` (never observed, but not guaranteed impossible)
  still falls back to the generic `{[}` brace-escape so it prints literally.
- **Numbers with thousands separators** (e.g. `10,000`) need the comma
  wrapped as `{,}` (`10{,}000`) — a bare `,` in math mode is treated as a
  list separator and gets extra space after it.
- **Don't collapse whitespace between adjacent `<math>` spans.** Two
  formulas sitting side by side in the source (e.g. "a_1 = 1, a_2 = 1" as
  two separate `<math>` elements) are sometimes separated by a real space
  text node in the DOM — keep it (`$X$ $Y$`) rather than merging into one
  `$X Y$` span, or a real, intentional space from the source is lost.
- **A long page slug can make `\url{...}` overflow the page margin** (e.g.
  `5-3-the-divergence-and-integral-tests`) — plain `hyperref`'s `\url`
  found no breakpoint and ran text off the page. Fixed by loading `xurl`
  after `hyperref` in `openstax/exercises.cls` (not per-file), which lets
  `\url` break at any character.
- **Plain prose text (outside any `<math>` element) needs its own LaTeX
  escaping, and for years had none.** `node_to_text` walks a `<p>`/`<li>`
  and only special-cases `<math>` children, appending everything else via
  `str(child)` with no escaping at all — invisible for a long time because
  no page happened to have a literal `%`, `&`, `#`, `_`, `{`, or `}` in
  ordinary sentence text, until a bare `π` sitting directly in prose (no
  `<math>` span at all) got rejected by `pdflatex` the same way any
  unmapped Unicode character would be. A stray `%` would have been worse
  and silent: unescaped, it truncates the rest of that source line as a
  LaTeX comment, deleting content with no error. Fixed by
  `escape_plain_text()`, applied to every `NavigableString` in
  `node_to_text` (never to the math-derived fragments alongside it, which
  already contain deliberate, correct LaTeX) — backslash-escapes
  `% $ & # _ { }`, and substitutes common prose symbols (`π`, typographic
  minus `−`, right-single-quote `’`). If a future page turns up some other
  stray symbol directly in prose, extend this function's substitution
  list, not `MI_MAP`/`MO_MAP` (those only run inside `convert_node`, i.e.
  inside an actual `<math>` element). Because this runs page-independently,
  fixing a gap here can silently fix already-committed files too — always
  re-run extraction on all prior pages and diff after touching
  `escape_plain_text`/`node_to_text`, not just the page that prompted the
  change.
- **Some inline math in prose is authored as plain HTML (`<sup>`/`<sub>`),
  not MathML** — e.g. `e<sup>x</sup>` or `p<sub>n</sub>` right in a
  sentence, sometimes wrapped in `<em>`. `node_to_text`'s generic fallback
  for "any other tag" used to just recurse and concatenate as plain
  characters, silently turning `$e^x$` into "ex" and `$p_n$` into "pn" —
  easy to miss since the sentence still reads as English. Fixed by
  special-casing `sup`/`sub` to emit `$^{...}$`/`$_{...}$`, an *empty-base*
  math sub/superscript (valid TeX — `^`/`_` attach to an implicit empty
  atom when nothing precedes them in their own group). This doesn't unify
  the preceding plain text into the same italicized math span (the base
  stays upright roman, not math italic) — a typographic compromise, not a
  content one: position and value are both preserved. Plain `<em>`/
  `<strong>` elsewhere (e.g. an italic "Hint:" marker) are left to the
  older plain-recursion fallback, since losing italic emphasis on
  non-mathematical text is cosmetic, not a correctness loss.
- **A run of literal `_` characters is OpenStax's fill-in-the-blank idiom,
  not real math content** — seen both as a bare `<mo>______</mo>` sibling
  and as the stretchy underscript of an `<munder>` with an empty
  (`<mrow/>`) base. The underscore count varies per exercise and carries
  no meaning. Converting either form literally leaves bare `_` characters
  in math mode, which LaTeX treats as a subscript operator needing a
  following `{...}` group and rejects with "Missing { inserted." Both
  forms are handled in one place: the `mo` branch special-cases any text
  that's entirely `_` characters and returns a shared
  `BLANK_LINE = r"\underline{\hspace{1.5cm}}"` constant regardless of
  length; `munder` special-cases an empty base whose already-converted
  underscript equals `BLANK_LINE` and returns it unwrapped, instead of
  also wrapping it in `\underset{}{}`.
- **A degree sign is its own `<mtext>°</mtext>`, not attached to a unit
  letter** — section 4.3's temperature exercises (`$200°\text{F}$`) wrap
  `°` and the following unit letter as two sibling `mtext` nodes. `°` alone
  has no alphabetic character, so it fell through the `mtext` branch's
  word-detection untouched — a raw, unmapped `°` in math mode, which
  `pdflatex` rejects as a `cmr10` "Missing character". Fixed by adding
  `°` → `^\circ ` to the `mtext` branch's substitution chain (alongside the
  existing `−`/`…`/`⋯`/`±`/`·` entries), producing `200^\circ\text{F}`.
- **En dashes and em dashes in ordinary prose are literal Unicode, not
  LaTeX's `--`/`---` ligature input** — e.g. "Exercises 159–162" outside
  any `<math>` element. `cmr10` has no glyph for either raw codepoint, so
  `pdflatex` rejected them the same "Missing character" way as the degree
  sign above, just in plain text instead of math mode.
  `escape_plain_text()` now substitutes `–`→`--` and `—`→`---`.
- **`^` and `~` in ordinary prose are LaTeX-active characters, not literal
  glyphs, and `escape_plain_text` didn't cover either.** Section 6.4's
  media `data-alt` figure descriptions write plain-text exponents like
  "y=x^2" directly in prose (no `<math>` element at all) — a bare `^`
  outside math mode is the accent-command shorthand expecting a following
  group, so `pdflatex` rejected it with "Missing $ inserted", the same
  failure mode as an unescaped `%` truncating a line, just louder. `~` is
  similarly active (the fixed-width non-breaking-space macro), even though
  no page has hit it yet. `escape_plain_text()` now substitutes
  `^`→`\textasciicircum{}` and `~`→`\textasciitilde{}`, alongside the
  existing `% $ & # _ { }` escaping.
## The shared document class: `openstax/exercises.cls`

Every generated file is `\documentclass{exercises}`, not bare `article` —
mirrors `essays/essay.cls`'s role for essays. It centralizes:

- Page geometry, fonts (`microtype`, `amsmath`/`amssymb`/`amsfonts`),
  `enumitem` (with `itemsep`/`topsep` tuned for dense exercise lists),
  `hyperref`+`xurl`.
- `\title{...}` (the book, e.g. "OpenStax Calculus Volume 2") and
  `\subtitle{...}` (the section label, e.g. "Section 5.1 Exercises:
  Sequences") — same pattern as `essay.cls`'s `\title`/`\subtitle`.
- `\sourceurl{...}`: `\maketitle` prints the CC BY 4.0 attribution line
  from it automatically (`\sourcenotice`) — a generated file no longer
  spells out the "Source: ... licensed under CC BY 4.0" paragraph itself.
- A `\conversionnotice`, also auto-printed by `\maketitle`: a visible
  disclaimer that the math was converted programmatically from MathML and
  may contain conversion errors. Worth flagging to a reader even after
  each known bug (above) is fixed, since the next page can always hit an
  unseen one.

`openstax/Makefile` depends each `%.pdf` on `exercises.cls` (same pattern
as `essays/Makefile` depending on `essay.cls`), so editing the class and
rebuilding (`make -C openstax`) picks it up for every file without
re-running the extractor.

`render_tex()` in the script emits exactly this: `\documentclass{exercises}`,
`\title`/`\subtitle` split from the book title and section label, and
`\sourceurl{...}` — no per-file `\usepackage` lines, no manual attribution
paragraph, no manual `pdftitle`. If you hand-edit a generated `.tex` file,
keep using these class hooks rather than reintroducing inline packages or
title formatting — that's exactly the duplication the class exists to
avoid.

## Output conventions

- One file per page, named `<vol-prefix><chapter>-<section>-<slug>.tex`
  (the script's default is already this, derived from the archive JSON's
  `slug`), living directly under `openstax/`. The `vol-prefix` (`vol2-`,
  `vol3-`, ...) disambiguates which OpenStax book a page came from — chapter
  and section numbers alone collide across books (e.g. both Calculus Volume 2
  and Volume 3 have their own "7.1"..."7.4", covering entirely different
  topics). `derive_volume_prefix()` in the script derives it automatically
  from the page URL's `/books/calculus-volume-<N>/` segment; it's only ever
  empty for a URL that doesn't match that pattern (a book this hasn't been
  taught about yet), in which case name the output by hand with `-o`.
- Standalone document (`\documentclass{exercises}`, not `\input`-ed into
  `self-check/self-check.tex`) — this is reference material, not one of
  the book's compiled artifacts.
- Must include a source URL and a CC BY 4.0 attribution line (OpenStax's
  license permits verbatim reproduction with attribution — this is that
  attribution). `\sourceurl{...}` plus `exercises.cls`'s `\maketitle`
  handle this automatically; the script emits the former.
- Build via `openstax/Makefile` (mirrors `essays/Makefile` and
  `self-check/Makefile`: `texlive.sh` + `latexmk`, output PDF and an
  `aux/` dir for intermediates).

## Patches: fixes that survive a re-import

Some fixes can't live in the converter at all — the defect is in OpenStax's
own source data, not in how the script reads it. Examples so far, all
in `openstax/patches/`: a `<mo>∑</mo>` entirely missing from the source
MathML (empty `<mrow/>` where the summation symbol belongs, in *both* the
presentation and content MathML — nothing to convert, because the operator
simply isn't in the document); two bare adjacent `<mi>R</mi><mi>n</mi>`
identifiers where every sibling occurrence in the same paragraph uses a
proper `<msub>` (`R_n`); a `<mi>α</mi>` (Greek alpha) used as a
center-point variable name where every sibling exercise in the group uses
italic Latin `a` instead — a one-character mix-up in OpenStax's own
equation editor; and a single `<mi>–y</mi>` (en dash glued to the variable
inside one identifier span) where the three sibling exercises in the same
`±y ±1` group all use the proper separate `<mo>-</mo><mi>y</mi>` structure.
None of these are MathML-tag/symbol-mapping gaps (the
converter faithfully reproduces exactly what's in the source); they're
wrong given the surrounding context, and re-running the extractor would
silently reproduce the source's own mistake again without a patch.

A fourth, different in kind: section 3.1's intro paragraphs use
`<em data-effect="italics">u</em>` (and `n`, `dv`, etc.) for a bare
variable name in ordinary prose — valid, unambiguous OpenStax source, not
a defect. The generic `<em>` handling in `node_to_text` only preserves
italics as plain-text emphasis (the right behavior for genuine prose
emphasis, e.g. "*reduction formulas*" in that same paragraph, which must
stay plain text, not become math), so a bare single-letter variable comes
out as upright "u" instead of math-mode `$u$`. Distinguishing "this `<em>`
is a math variable" from "this `<em>` is just italic emphasis" from the
tag alone is exactly the kind of judgment call that risks false positives
in a general heuristic — handled per-occurrence as a patch instead of a
converter rule for now. If a future page shows the same pattern often
enough that patching each one gets tedious, that's the signal to
reconsider a converter heuristic (e.g. "a lone-letter or `dv`-shaped `<em>`
becomes math") rather than one more patch.

**Mechanism**: `openstax/patches/<output filename>.patch` — a plain unified
diff (`diff -u`) — is auto-applied (via `git apply -p0`, run from
`openstax/`, right after the file is written) by `extract-exercises.py`
itself, every time it runs, as long as a patch file with that exact name
exists. No separate step to remember; re-running the extractor on a page
that has a patch reapplies it automatically. If the patch fails to apply
(the upstream source changed enough that the context no longer matches),
the script prints a `WARNING` to stderr and **leaves the fresh unpatched
conversion in place** rather than either silently dropping the fix or
half-applying it — go fix the underlying issue and regenerate the patch
(below).

Why `git apply` and not the `patch` command the name might suggest: plain
`patch` isn't installed on the host, only inside the `texlive-gl` podman
image — and this script needs host network access to fetch the page, so it
runs on the host, not through `texlive.sh`. `git apply -p0` does the same
job and is already available (this is a git repo).

**Creating or updating a patch** for a page whose conversion needs a manual
fix that the converter itself can't produce:

```
cd openstax
# 1. Regenerate the pre-fix baseline (skip any existing patch for this page)
uv run extract-exercises.py <page-url> --no-patch -o /tmp/raw.tex
# 2. Apply ONLY the content fix to the real output file (hand-edit it) --
#    no explanatory comment here; keep the .tex a clean, verbatim
#    transcription, exactly like every non-patched file
#    ... edit openstax/<vol-prefix><slug>.tex ...
# 3. Capture the fix as a patch (diff exits 1 when there ARE differences --
#    that's the expected, successful case here, not an error)
diff -u /tmp/raw.tex openstax/<vol-prefix><slug>.tex > openstax/patches/<vol-prefix><slug>.tex.patch
# 4. Prepend a free-text explanation to the patch FILE, above the "--- "
#    line diff just wrote -- see below for why this is safe.
# 5. Verify: re-running the extractor from scratch should now reproduce
#    your hand-fixed file exactly, with no `git diff` afterward
uv run extract-exercises.py <page-url>
git diff --stat openstax/<vol-prefix><slug>.tex   # expect no output
```

**Explain the fix in the patch file, not the `.tex` file.** A line inside a
diff hunk has no comment syntax of its own — every hunk line must start
with `' '`/`'+'`/`'-'`/`'\'`, so text placed there is just more content
(exactly the bug this avoids: a `%` comment "fix" getting baked into the
tracked `.tex` file on every re-run). Free text placed *before* the first
`--- ` line, however, is fine and is not part of the diff: `git apply`
(like `git am`/`patch`) scans forward for a recognizable diff header and
ignores everything before it — the same mechanism that lets it consume a
`git format-patch` file, which always has a commit message ahead of the
actual diff. So put the rationale there:

```
OpenStax's source MathML for this exercise omits the summation operator
itself (an empty <mrow/> where <mo>∑</mo> belongs, in both the presentation
and content MathML) -- there is nothing for extract-exercises.py to
convert, so the fix is restored by hand here rather than in the converter.

--- /tmp/raw.tex
+++ vol2-5-4-comparison-tests.tex
@@ ...
```

This keeps every `.tex` file a clean, unannotated transcription — a reader
has no way to tell a patched exercise from any other just by reading the
file — while the "why" lives right next to the "what changed" in
`patches/`, not scattered across a separate notes file.

Before reaching for a patch, make sure the issue really is unfixable at the
converter level — most conversion bugs (see the gotchas above) turned out
to be systematic and got fixed once in `convert_node`/`MO_MAP`/`MI_MAP` for
every page, current and future. Patches are for the rarer case where the
*source itself* is defective for that one exercise. If a second, unrelated
page turns out to need the same category of fix, that's a sign it might
actually be a converter gap after all — reconsider before adding another
patch for it.

## After extracting

Always compile and visually check the PDF (see "The tool" above) before
calling the import done — a MathML tag the converter doesn't cover yet
fails loudly (KeyError/IndexError) or, worse, silently drops content, and
the only way to catch the latter is comparing rendered pages against the
live site.

**`make -C openstax` can report "up-to-date" for a `.tex` file you just
regenerated with different content.** `texlive.sh`'s `SOURCE_DATE_EPOCH`
handling for reproducible builds appears to normalize file mtimes inside
the container, which defeats `latexmk`'s own change-detection (it decided
"Nothing to do" even though the `.tex` on disk was newer than the `.pdf`
by several seconds, and the content had genuinely changed) — even though
`make`'s own mtime check still fires the recipe. If you've fixed the
converter and re-run `extract-exercises.py` on a page whose `.tex` you'd
already built once before, don't trust a clean `make` output alone:
`rm openstax/aux/<name>.* openstax/<name>.pdf` first,
then rebuild, so you're actually looking at freshly-typeset output and
not a stale PDF from before the fix.
