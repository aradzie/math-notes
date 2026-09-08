#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["beautifulsoup4", "lxml"]
# ///
"""Fetch an OpenStax textbook page and convert its end-of-section
"Exercises" block into a standalone LaTeX file.

See .agents/skills/import-openstax-exercises/SKILL.md for the full
rationale (why this doesn't just use a generic web-fetch tool, why the math
has to be converted from MathML, and the known rendering gotchas). That
skill also has the coverage table of MathML tags this converter handles --
extend CONVERTERS below and update the table together when a new page needs
a tag this doesn't cover yet.

Usage:
    uv run extract-exercises.py <page-url> [-o output.tex]

Example:
    uv run extract-exercises.py \\
        https://openstax.org/books/calculus-volume-2/pages/5-1-sequences
    # writes vol2-5-1-sequences.tex in the current directory

Patches: some source pages have a genuine defect (e.g. OpenStax's own
MathML omitting a summation operator) that no converter fix can address --
the correct LaTeX just isn't derivable from the source. For these, a manual
fix on top of the raw conversion is tracked as a unified diff in
patches/<output filename>.patch and reapplied automatically after every
re-run (see the "Patches" section of the skill for how to create one).
Pass --no-patch to get the raw, unpatched conversion instead (e.g. when
regenerating the baseline to build a new patch against).
"""
import argparse
import json
import re
import string
import subprocess
import sys
import urllib.request
from pathlib import Path
from bs4 import BeautifulSoup, NavigableString, Tag

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
PATCHES_DIR = Path(__file__).resolve().parent / "patches"

FUNC_NAMES = {
    "sin", "cos", "tan", "cot", "sec", "csc", "ln", "log", "lim", "exp",
    "cosh", "sinh", "tanh", "arctan",
}

# Sentence punctuation is sometimes included as the final token of an
# OpenStax inline MathML span.  It belongs to the surrounding prose in the
# generated LaTeX, not to math mode.  Exclamation marks are deliberately not
# included: a terminal ``!`` can instead be a factorial and cannot be moved
# safely from the converted text alone.
TRAILING_PROSE_PUNCTUATION = frozenset(",.;:?")

# mo/mi macros that are letter sequences MUST carry a trailing space --
# LaTeX's tokenizer greedily extends a control-word name across a following
# letter, so e.g. "\le" immediately before "x" becomes the single (bogus)
# command "\lex" rather than "\le" + "x". Digits and symbols terminate a
# control word fine, so "\ge1" is not a problem -- only letter neighbors are.
MO_MAP = {
    "(": "(", ")": ")", "+": "+", ",": ",", ".": ".", "...": r"\ldots ",
    ";": ";", "<": "<", "=": "=", ">": ">", "{": r"\{", "}": r"\}",
    "|": "|", "′": "'", "″": "''", "‴": "'''", "→": r"\to ", "−": "-",
    # "–" (U+2013 EN DASH) shows up as an <mo> minus sign on this page (e.g.
    # "1–y^2", "–π/2") instead of the usual "−" (U+2212 MINUS SIGN) -- same
    # "same character, different tag/codepoint across pages" inconsistency
    # documented for other symbols; maps the same as "−".
    "–": "-",
    "≤": r"\le ", "≥": r"\ge ", "∑": r"\sum ", "∫": r"\int ",
    "∬": r"\iint ", "∭": r"\iiint ",
    "∞": r"\infty ", "≈": r"\approx ", "±": r"\pm ",
    "·": r"\cdot ", "⋅": r"\cdot ", "⋯": r"\cdots ", "…": r"\ldots ",
    "×": r"\times ",
    "〈": r"\langle ", "〉": r"\rangle ",
    # U+27E8/U+27E9 MATHEMATICAL ANGLE BRACKET -- the canonical,
    # non-deprecated codepoints for the same angle-bracket vector
    # notation as the lookalikes above; this page uses these instead.
    "⟨": r"\langle ", "⟩": r"\rangle ",
    "∈": r"\in ",
    "⊂": r"\subset ", "ℝ": r"\mathbb{R}", "≠": r"\ne ", "∘": r"\circ ",
    # "π" is normally an <mi>, but this page also uses it as an <mo> (e.g.
    # the bound "π/2") -- same MI_MAP entry, duplicated here since the mo
    # branch resolves purely through MO_MAP (unlike mtext, which falls back
    # to MI_MAP for a bare Greek letter).
    "π": r"\pi ",
    "∂": r"\partial ",
    "∇": r"\nabla ",
    "‖": r"\|",
    "⌊": r"\lfloor ", "⌋": r"\rfloor ",
    # U+03F5 GREEK LUNATE EPSILON SYMBOL -- a distinct codepoint from the
    # usual "ε" (U+03B5) already in MI_MAP, used on this page under <mo>
    # instead of <mi>; same \epsilon macro.
    "ϵ": r"\epsilon ",
    "∪": r"\cup ",
}

MI_MAP = {
    "α": r"\alpha ", "β": r"\beta ", "γ": r"\gamma ", "δ": r"\delta ",
    "ε": r"\epsilon ", "ζ": r"\zeta ", "η": r"\eta ", "θ": r"\theta ",
    "ι": r"\iota ", "κ": r"\kappa ", "λ": r"\lambda ", "μ": r"\mu ",
    "ν": r"\nu ", "ξ": r"\xi ", "π": r"\pi ", "ρ": r"\rho ",
    "σ": r"\sigma ", "τ": r"\tau ", "υ": r"\upsilon ", "φ": r"\phi ",
    # U+03D5 GREEK PHI SYMBOL -- a distinct Unicode codepoint from the usual
    # "φ" (U+03C6) above, used on this page for potential-function labels
    # (phi_1(x,y), phi_2(x,y)); same \phi macro, just a different source
    # glyph OpenStax happened to author with.
    "ϕ": r"\phi ",
    "χ": r"\chi ", "ψ": r"\psi ", "ω": r"\omega ",
    "Γ": r"\Gamma ", "Δ": r"\Delta ", "Θ": r"\Theta ", "Λ": r"\Lambda ",
    "Ξ": r"\Xi ", "Π": r"\Pi ", "Σ": r"\Sigma ", "Υ": r"\Upsilon ",
    "Φ": r"\Phi ", "Ψ": r"\Psi ", "Ω": r"\Omega ",
    "∞": r"\infty ",
    # U+211D DOUBLE-STRUCK CAPITAL R (blackboard-bold R), used for the
    # domain of a vector field (e.g. "for (x,y,z) in R^3"). MO_MAP already
    # had this mapped for pages that author it as an <mo>; this page uses
    # <mi> instead -- same "same character, different tag" inconsistency
    # documented elsewhere in this file, so both tables need the entry.
    "ℝ": r"\mathbb{R}",
}

# MathML's <mover accent="true"> places a diacritic over its base. OpenStax
# uses this for the standard LaTeX accent macros (only tilde seen so far,
# e.g. antiderivative notation f\tilde{}), keyed here by the *raw*
# (pre-MO_MAP) accent character so the mover branch can special-case it
# before falling back to generic \overset{}{} stacking.
ACCENT_MAP = {
    "˜": "tilde",  # U+02DC SMALL TILDE
    # U+2014 EM DASH used as a full-width stretchy overline is OpenStax's
    # encoding of vector notation over a two-letter point pair, e.g.
    # <mover accent="true"><mi>O</mi><mi>A</mi></mrow><mo stretchy="true">
    # —</mo></mover> for the vector OA -- confirmed against the live page
    # (\overrightarrow{OA}+\overrightarrow{OB}), not a literal em dash.
    "—": "overrightarrow",
}

# OpenStax's fill-in-the-blank idiom: a run of literal "_" characters (either
# a bare <mo>, or as the stretchy underscript of an <munder> with an empty
# <mrow/> base) marks a blank answer line, e.g. "sin^2 x + ____ = 1" or a
# reduction formula's "... = ____". Left as literal "_" characters, these are
# not just wrong -- a bare "_" in math mode is a subscript operator that
# needs a following braced group, so pdflatex rejects it with "Missing {
# inserted." The underscore count varies with the page's own layout (as few
# as 6, as many as 8 seen so far) and carries no meaning, so every instance
# renders as the same fixed-width rule regardless of length.
BLANK_LINE = r"\underline{\hspace{1.5cm}}"

# Macros that are their own math-mode "Op" atom, which TeX's spacing table
# already puts an automatic thin space around whenever an "Ord" atom (a
# variable, number, or parenthesis) sits next to it -- every name in
# FUNC_NAMES becomes exactly such a macro (see the mtext branch below), plus
# "\times". OpenStax's MathML often places an explicit <mspace> next to one
# of these anyway (its own renderer needs it, since it doesn't treat "sin"
# etc. as its own atom the way LaTeX's \sin does) -- converted to "\," or
# "\quad" by the mspace branch below, that duplicates spacing LaTeX already
# provides, e.g. "\sin \,1" where "\sin 1" reads identically.
# strip_redundant_spacing() removes exactly these; an <mspace> between two
# plain Ord atoms (e.g. before a differential "dt", or around a \text{}
# word) is left alone, since Ord-Ord spacing is zero by default and
# dropping it there would visibly glue tokens together (e.g. "0if").
SELF_SPACING_WORD_MACROS = sorted(FUNC_NAMES | {"times"})

_SPACING_BEFORE_SELF_SPACING_MACRO = re.compile(
    r"(?:\\,|\\quad )(?=\\(?:%s)\b)" % "|".join(SELF_SPACING_WORD_MACROS)
)
_SPACING_AFTER_SELF_SPACING_MACRO = re.compile(
    r"(\\(?:%s)\s)(?:\\,|\\quad )" % "|".join(SELF_SPACING_WORD_MACROS)
)
# A control WORD (letters only, e.g. \pi) makes TeX gobble up any spaces
# that follow it during tokenizing, regardless of what comes next -- so a
# delimiter space is only ever load-bearing when the next character is
# itself a letter (else it would merge into the control word's name, e.g.
# "\pi" + "x" -> the bogus command "\pix"). Before any other non-letter
# character -- "}", ",", digits, "-", another "\macro", ... -- the space
# does nothing and just adds noise to the source, e.g. "\frac{13\pi }{2}"
# or "[-\pi ,\pi ]". A following backslash is deliberately excluded here:
# lexically safe to merge too, but two adjacent macros with no separating
# space (e.g. "\pi\theta") are harder to read, and none of the symbol maps
# rely on that merge being cleaned up.
_CONTROL_WORD_SPACE_BEFORE_NON_LETTER = re.compile(r"(\\[A-Za-z]+) (?=[^A-Za-z\\\s])")


def strip_redundant_spacing(tex):
    tex = _SPACING_BEFORE_SELF_SPACING_MACRO.sub("", tex)
    tex = _SPACING_AFTER_SELF_SPACING_MACRO.sub(r"\1", tex)
    return tex


def strip_redundant_control_word_delimiter_spacing(tex):
    r"""Remove a control-word's trailing space before a non-letter delimiter.

    Symbol-map values deliberately end letter-based macros with a space so
    concatenation cannot turn ``\pi`` followed by ``x`` into ``\pix``.  Any
    non-letter character -- a closing brace, a comma, a digit -- already
    terminates the control word on its own, however, so retaining that
    delimiter produces noisy source such as ``\frac{13\pi }{2}`` or
    ``[-\pi ,\pi ]``.
    """
    return _CONTROL_WORD_SPACE_BEFORE_NON_LETTER.sub(r"\1", tex)


def derive_volume_prefix(url):
    """Return a "vol<N>-" filename prefix for a calculus-volume-<N> URL, or
    "" if the URL doesn't match that pattern (a book this hasn't been taught
    about yet -- degrade to the old unprefixed naming rather than guess)."""
    m = re.search(r"/books/calculus-volume-(\d+)/", url)
    return f"vol{m.group(1)}-" if m else ""


def fetch(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {"User-Agent": UA})
    with urllib.request.urlopen(req) as resp:
        return resp.read().decode("utf-8")


def extract_preloaded_state(html):
    marker = "window.__PRELOADED_STATE__ = "
    start = html.find(marker)
    if start == -1:
        raise RuntimeError("__PRELOADED_STATE__ not found -- page markup may have changed")
    start += len(marker)
    depth = 0
    in_str = False
    esc = False
    str_char = ""
    i = start
    while i < len(html):
        c = html[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == str_char:
                in_str = False
        else:
            if c in "\"'":
                in_str = True
                str_char = c
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    i += 1
                    break
        i += 1
    return json.loads(html[start:i])


def resolve_symbol(text, table, table_name, tag):
    """Look up ``text`` (an ``<mo>``/``<mi>`` node's content) in a symbol
    table, returning the mapped LaTeX or ``text`` unchanged when it's plain
    ASCII -- ordinary variable letters (``x``, ``R``, ...) and a handful of
    untranslated ASCII operators are meant to pass through ``mi``/``mo``
    unmapped, so that's not itself an error.

    A non-ASCII character with no table entry is a different case: left
    alone, it leaks into the generated .tex as a raw Unicode character and
    fails only much later, at pdflatex compile time -- an error that names
    the character and codepoint but not which MathML tag it came from,
    forcing a manual re-fetch-and-grep of the source page to find that out
    (see the SKILL.md "gotchas" this has repeatedly cost). Warn here
    instead, immediately and with the tag included, since the DOM node is
    still in hand -- but only warn, not raise: some occurrences are a
    genuine, deliberately-preserved source defect (e.g. a stray en dash
    glued inside one <mi>) that a patches/*.patch fixes post-conversion,
    and raising here would abort before that patch ever gets a chance to
    apply, breaking regeneration of already-patched files.
    """
    mapped = table.get(text, text)
    if mapped is text and len(text) > 1 and any(ord(ch) > 127 for ch in text):
        # OpenStax sometimes fuses a mapped symbol (e.g. a Greek letter)
        # directly onto a plain ASCII letter inside a *single* mi/mo node
        # -- e.g. "<mi>πh</mi>" for "\pi h" (a coefficient times a variable,
        # authored as one identifier rather than two siblings). An exact
        # whole-string table lookup misses this even though every
        # character in it is individually resolvable. Fall back to mapping
        # character-by-character (each non-ASCII character through the
        # table, each ASCII character passed through unchanged) when doing
        # so fully resolves the text -- table entries for letter-based
        # macros already carry the trailing space this concatenation
        # relies on to avoid gluing into the next letter (e.g. "\pi "+"h").
        parts = []
        for ch in text:
            if ch in table:
                parts.append(table[ch])
            elif ord(ch) <= 127:
                parts.append(ch)
            else:
                parts = None
                break
        if parts is not None:
            return "".join(parts)
    if mapped is text and any(ord(ch) > 127 for ch in text):
        codepoints = ", ".join(
            "%r (U+%04X)" % (ch, ord(ch)) for ch in text if ord(ch) > 127
        )
        print(
            "WARNING: unmapped symbol %s under <%s> -- grep the raw "
            "fetched page for this tag/character (don't assume the "
            "codepoint by eye, some are lookalikes); add an entry to %s "
            "if it's a systematic gap, or a patches/*.patch if it's a "
            "one-off source defect. Left unconverted for now, which will "
            "likely fail at pdflatex compile time."
            % (codepoints, tag, table_name),
            file=sys.stderr,
        )
    return mapped


def convert_number(s):
    s = s.replace("−", "-")
    # OpenStax sometimes fuses a leading "±" directly into the <mn> token
    # itself (e.g. "<mn>±1</mn>", corners "(±1,±1)") rather than emitting a
    # separate <mo>±</mo> sibling -- MO_MAP/the mtext branch both already
    # map "±" to "\pm ", but neither runs here, so the raw glyph leaked
    # straight into math-mode TeX. Unicode inputenc then silently expands
    # it to the text-mode \textpm, invalid in math mode, and pdflatex
    # separately rejects the ± glyph itself as missing from cmr10.
    s = s.replace("±", r"\pm ")
    if "," in s:
        s = s.replace(",", "{,}")
    return s


def mrow_children(node):
    return [c for c in node.children if isinstance(c, Tag)]


def previous_tag_sibling(node):
    sibling = node.previous_sibling
    while sibling is not None and not isinstance(sibling, Tag):
        sibling = sibling.previous_sibling
    return sibling


def next_tag_sibling(node):
    sibling = node.next_sibling
    while sibling is not None and not isinstance(sibling, Tag):
        sibling = sibling.next_sibling
    return sibling


def is_differential_marker(node):
    """Return whether ``node`` starts a MathML differential such as ``dx``.

    OpenStax represents the differential as adjacent identifier nodes -- an
    ``mi`` containing ``d`` followed by an ``mi`` containing the integration
    variable (including Greek variables such as theta).  Keeping this test on
    the source tree avoids guessing from already-flattened TeX strings.
    """
    variable = next_tag_sibling(node)
    return (
        node.name == "mi"
        and node.get_text().strip() == "d"
        and variable is not None
        and variable.name == "mi"
        and bool(variable.get_text().strip())
    )


INTEGRAL_SIGNS = frozenset(("∫", "∬", "∭"))


def has_unclosed_integral_before(node):
    """Return whether an integral in this formula is awaiting a differential.

    A double/triple integral sign (``∬``/``∭``) is a single MathML ``mo``
    token, not two/three stacked ``∫``s, but conventionally pairs with just
    one differential (``dA``, ``dV``) the same way a single ``∫`` pairs with
    one ``dx`` -- so each counts as exactly one pending integral here.
    """
    math = node.find_parent("math")
    if math is None:
        return False

    pending_integrals = 0
    for candidate in math.find_all(("mo", "mi")):
        if candidate is node:
            return pending_integrals > 0
        if candidate.name == "mo" and candidate.get_text().strip() in INTEGRAL_SIGNS:
            pending_integrals += 1
        elif is_differential_marker(candidate) and pending_integrals:
            pending_integrals -= 1
    return False


def differential_needs_thin_space(node):
    """Detect an integral differential whose source omitted separating space."""
    if not is_differential_marker(node) or not has_unclosed_integral_before(node):
        return False

    previous = previous_tag_sibling(node)
    if previous is None or previous.name == "mspace":
        return False

    # In ``\int dx/f(x)``, the differential starts the numerator and has no
    # integrand immediately before it.  A direct integral sibling similarly
    # represents an integral with an implicit integrand.  Neither needs the
    # integrand--differential separator that this normalization supplies.
    return not (
        previous.name == "mo" and previous.get_text().strip() in INTEGRAL_SIGNS
    )


def as_binom_table(node):
    """If `node` is an mtable (optionally wrapped in a bare mrow) shaped like
    OpenStax's binomial-coefficient idiom -- exactly two rows of one cell
    each -- return its (top, bottom) mtd tags, else None."""
    if node.name == "mrow":
        kids = mrow_children(node)
        if len(kids) != 1:
            return None
        node = kids[0]
    if node.name != "mtable":
        return None
    trs = node.find_all("mtr", recursive=False)
    if len(trs) != 2:
        return None
    cells = [tr.find_all("mtd", recursive=False) for tr in trs]
    if any(len(c) != 1 for c in cells):
        return None
    return cells[0][0], cells[1][0]


SCRIPT_ATOM_TAGS = {
    "mi", "mn", "mo", "mtext", "msub", "msup", "msubsup", "mfrac",
    "msqrt", "mroot", "munder", "mover", "munderover", "mfenced",
}


def convert_script_base(node):
    r"""Convert the base of a subscript/superscript with minimal grouping.

    MathML already tells us where the base ends, but TeX only needs an extra
    group when that base expands to several math atoms.  In particular, a
    single identifier or operator should render as ``x^{2}`` or ``\sin^{2}``,
    not ``{x}^{2}`` or ``{\sin }^{2}``.
    """
    converted = convert_node(node).strip()
    if node.name in SCRIPT_ATOM_TAGS:
        return converted

    # Transparent containers around one child do not make that child a
    # compound base.  Containers with several children do, so retain a TeX
    # group for expressions such as an unparenthesized ``x+1``.
    if node.name in ("mrow", "mstyle", "math", "semantics"):
        kids = mrow_children(node)
        if node.name == "semantics":
            kids = [k for k in kids if k.name != "annotation-xml"]
        if len(kids) == 1:
            return convert_script_base(kids[0])

    return "{%s}" % converted


def convert_node(node):
    if isinstance(node, NavigableString):
        return str(node)
    name = node.name
    if name == "mstyle":
        # OpenStax's bold-vector idiom: <mstyle mathvariant="bold"> wrapping
        # an <mtext> (e.g. bold "F" for a vector field name). Without this,
        # mstyle fell through to the generic tag fallback at the bottom of
        # this function, which recurses into children but drops the
        # mathvariant attribute entirely -- silently printing an upright,
        # non-bold letter instead of the intended bold vector notation.
        #
        # Rather than wrapping the whole already-converted subtree in one
        # outer \mathbf{...}, push the attribute down onto any mi/mtext
        # leaf that doesn't already carry its own mathvariant, then convert
        # normally. Wrapping the outer result instead would nest \mathbf{}
        # around an inner \text{...} (mtext's own word-wrapping, done with
        # no knowledge of the ancestor's styling) -- \mathbf has no effect
        # on \text mode's font, so \mathbf{\text{F}} silently prints
        # upright, not bold, the same content-loss failure mode as not
        # handling mstyle at all. Tagging the leaf directly instead routes
        # through the mi/mtext branches' own mathvariant="bold" handling
        # (below), which is already careful to emit a single \mathbf{}
        # around the right thing.
        if node.get("mathvariant") == "bold":
            for descendant in node.find_all(("mi", "mtext")):
                if not descendant.has_attr("mathvariant"):
                    descendant["mathvariant"] = "bold"
        return "".join(convert_node(k) for k in mrow_children(node))
    if name in ("mrow", "math", "semantics"):
        kids = mrow_children(node)
        if name == "semantics":
            kids = [k for k in kids if k.name != "annotation-xml"]
        # OpenStax's binomial-coefficient idiom is a literal "(" mo, an
        # mtable with one column of two rows, and a literal ")" mo, as
        # siblings (occasionally the mtable sits inside its own wrapping
        # mrow). Rendering that idiom as \left(\begin{matrix}..\end{matrix}
        # \right) (the generic per-child fallback) breaks silently whenever
        # it ends up nested inside \frac{}{}: \frac grabs its argument as a
        # token list before \begin{matrix}'s \halign machinery can run in
        # the right context, splitting the two rows apart on the page.
        # \binom{}{} is a plain math macro (no \halign), safe to nest
        # anywhere, and exactly what this idiom means -- so detect the
        # triple and emit that instead of converting each child in turn.
        out = []
        i = 0
        while i < len(kids):
            # OpenStax sometimes spells a function name as a run of separate
            # single-letter <mi> siblings (e.g. <mi>s</mi><mi>i</mi><mi>n</mi>)
            # instead of the usual single <mtext mathvariant="italic">sin</mtext>
            # -- seen in the same exercise as a sibling term that DOES use the
            # <mtext> idiom for the same function, so it's an OpenStax
            # authoring inconsistency, not a one-off source defect worth a
            # patch. Left as individual mi's, each letter converts to its own
            # italicized math variable with no operator spacing at all
            # ("sin\theta" glued straight to what follows); detect the run and
            # emit the real \sin/\cos/etc. macro instead, matching how the
            # mtext branch already handles FUNC_NAMES.
            matched = None
            for fname in sorted(FUNC_NAMES, key=len, reverse=True):
                n = len(fname)
                if (
                    i + n <= len(kids)
                    and all(
                        kids[j].name == "mi" and kids[j].get_text() == fname[j - i]
                        for j in range(i, i + n)
                    )
                ):
                    matched = fname
                    break
            if matched is not None:
                out.append("\\" + matched + " ")
                i += len(matched)
                continue
            if (
                i + 2 < len(kids)
                and kids[i].name == "mo" and kids[i].get_text() == "("
                and kids[i + 2].name == "mo" and kids[i + 2].get_text() == ")"
            ):
                pair = as_binom_table(kids[i + 1])
                if pair is not None:
                    top, bottom = pair
                    out.append(r"\binom{%s}{%s}" % (convert_node(top), convert_node(bottom)))
                    i += 3
                    continue
            out.append(convert_node(kids[i]))
            i += 1
        return "".join(out)
    if name == "mi":
        t = node.get_text()
        if differential_needs_thin_space(node):
            return r"\,d"
        resolved = resolve_symbol(t, MI_MAP, "MI_MAP", "mi")
        if node.get("mathvariant") == "bold":
            # OpenStax marks a bold vector name (e.g. F in a magnitude
            # expression "||F||") as a plain <mi mathvariant="bold">F</mi>
            # rather than the <mstyle mathvariant="bold"> wrapper handled
            # below -- same styling intent, different tag. Without this,
            # the bold attribute is silently dropped and the vector prints
            # in ordinary italic like any other variable.
            return r"\mathbf{%s}" % resolved.strip()
        return resolved
    if name == "mn":
        return convert_number(node.get_text())
    if name == "mo":
        t = node.get_text()
        if t and set(t) == {"_"}:
            return BLANK_LINE
        if t and set(t) == {"\xa0"}:
            # OpenStax sometimes authors inter-token spacing as a bare
            # <mo>&#160;</mo> (a non-breaking space) instead of <mspace> --
            # same purpose (real glue between two Ord atoms that would
            # otherwise get zero automatic spacing), different encoding.
            # Left unmapped, the literal U+00A0 leaks into the .tex source
            # and pdflatex rejects it as an unset-up Unicode character.
            return r"\,"
        return resolve_symbol(t, MO_MAP, "MO_MAP", "mo")
    if name == "mtext":
        full = node.get_text()
        raw = full.strip()
        # OpenStax sometimes encodes the same inter-token spacing a
        # standalone <mo>&#160;</mo> or sibling <mspace> would otherwise
        # provide by fusing a plain space or non-breaking space onto the
        # *edges of the mtext's own text* instead -- e.g.
        # "<mtext>\xa0and\xa0</mtext>" with no <mspace> siblings at all,
        # seen in one exercise on a page where every other "and" between
        # <mi>/<mn> tokens uses the standard <mspace width="0.2em"/>
        # sibling idiom. .strip() above discards exactly that signal,
        # which otherwise glues this word straight onto its neighbors
        # (e.g. "3y+z=9,\text{and}3y+z=9" rendering as "and3y" with no
        # gap). Recovered once here, before the word/symbol logic below,
        # so every return path through this branch gets it -- but only on
        # a side that doesn't already have a real <mspace> sibling (some
        # other exercises on the same page double up: a fused space *and*
        # an adjacent <mspace>, and adding glue on top of that would
        # produce a doubled gap, e.g. "\,\,\text{and}\,\,").
        prev_tag = node.find_previous_sibling()
        next_tag = node.find_next_sibling()
        leading_glue = (
            r"\," if full[:1] in (" ", "\xa0")
            and not (prev_tag is not None and prev_tag.name == "mspace")
            else ""
        )
        trailing_glue = (
            r"\," if full[-1:] in (" ", "\xa0")
            and not (next_tag is not None and next_tag.name == "mspace")
            else ""
        )
        if raw in FUNC_NAMES:
            return leading_glue + "\\" + raw + " " + trailing_glue
        if raw in MI_MAP:
            # A bare Greek letter (or "∞") in mtext -- e.g. "Ω" as the ohm
            # symbol in a resistance value like "R=30Ω" -- is alphabetic, so
            # the has_word check below would otherwise treat it as an
            # English word and wrap it \text{Ω}. But \text{} switches to the
            # document's text-mode font, which has no glyph for a raw Greek
            # codepoint, so pdflatex rejects it as an unset-up Unicode
            # character -- the same failure mode already fixed for "°"
            # below, just for isalpha() characters instead of isalpha()=False
            # ones. MI_MAP already has the right macro for the mi/mo paths;
            # reuse it here instead of duplicating entries in this branch's
            # own substitution list.
            return leading_glue + MI_MAP[raw] + trailing_glue
        # Decide on the *raw* text whether this holds a real English word
        # (e.g. "if", "-kg") that needs \text{} to avoid rendering as
        # italicized, tight-kerned math variables -- checked before the
        # \ldots/\cdots substitution below, since those macros' own letters
        # would otherwise trip this check (and \text{\cdots} breaks the
        # macro, which needs math mode).  Ellipsis mtext is often glued to
        # punctuation (e.g. ",…"), so substitute rather than exact-match.
        has_word = any(ch.isalpha() for ch in raw)
        t = raw.replace("−", "-").replace("…", r"\ldots ").replace("⋯", r"\cdots ")
        t = t.replace("±", r"\pm ").replace("·", r"\cdot ").replace("⋅", r"\cdot ").replace("‴", "'''")
        t = t.replace("°", r"^\circ ")
        # U+201C/U+201D LEFT/RIGHT DOUBLE QUOTATION MARK -- section 4.9's
        # "What is the value of "c" for Newton's method?" quotes a bare
        # variable name by wrapping it in its own standalone <mtext>“</mtext>
        # / <mtext>”</mtext> siblings around the <mi>c</mi>, rather than
        # putting the curly quotes in ordinary prose text (already handled
        # by escape_plain_text for that case). Neither character is
        # alphabetic, so has_word stays False and \text{} below never fires;
        # substituted directly to LaTeX's own open/close-quote ligature
        # (`` / '') wrapped in \text{} here so it renders correctly even
        # though this mtext node holds nothing else.
        t = t.replace("“", r"\text{``}").replace("”", r"\text{''}")
        # U+00A5 YEN SIGN -- OpenStax's currency notation for Japanese yen
        # amounts (e.g. "$1=¥250"), authored as its own standalone <mtext>
        # sibling right next to a peer "$"-<mtext>, the same idiom as the
        # dollar sign. Not alphabetic, so it wouldn't trip the has_word
        # check above, but the raw glyph has no cmr10 glyph either;
        # \textyen (textcomp) is the standard companion-symbol macro, and
        # \text{} keeps it upright in math mode the same way the adjacent
        # "\$" literal is.
        t = t.replace("¥", r"\text{\textyen}")
        # U+2207 NABLA -- OpenStax authors the gradient operator as an
        # <mtext> here (e.g. "-∇V(x,y)"), even though MO_MAP already maps
        # the same character under <mo> elsewhere. The mtext branch only
        # falls back to MI_MAP for a bare Greek letter (above), not MO_MAP,
        # so this non-alphabetic symbol needs its own substitution here too.
        t = t.replace("∇", r"\nabla ")
        # U+2033 DOUBLE PRIME, same idiom as the already-handled U+2034
        # TRIPLE PRIME above -- a second-derivative mark (e.g. "r″(t)"),
        # rendered the same way ordinary ASCII apostrophes would be.
        t = t.replace("″", "''")
        # U+2032 PRIME, the first-derivative mark (e.g. "x′(t), y′(t)") --
        # same idiom as the double/triple prime above, one apostrophe
        # instead of two/three. MO_MAP already maps this character for the
        # <mo> tag; OpenStax also emits it under <mtext> on this page.
        t = t.replace("′", "'")
        # U+2016 DOUBLE VERTICAL LINE is OpenStax's norm-notation delimiter
        # (e.g. "‖v(t)‖" for the magnitude/speed of a vector-valued
        # function), always appearing in a pair of standalone <mtext>
        # siblings around the enclosed expression -- \| is the standard
        # LaTeX macro for this exact glyph in math mode.
        t = t.replace("‖", r"\|")
        # U+200B ZERO WIDTH SPACE -- seen as a standalone <mtext> sibling
        # between an <mo>)</mo> and a following bold-vector <mstyle>, purely
        # a zero-width filler in OpenStax's own source with no visible
        # effect either way; drop it rather than leak an invisible-but-
        # unmapped character into the .tex output.
        t = t.replace("​", "")
        t = t.replace("%", r"\%").replace("$", r"\$").replace("&", r"\&").replace("#", r"\#")
        if has_word:
            # A Greek letter can be fused into the same mtext "word" as
            # plain ASCII (e.g. "<mtext>Ω/min</mtext>" for the unit
            # "ohms/min") -- the exact-string "raw in MI_MAP" fallback
            # above only catches a bare, standalone Greek letter, not one
            # glued onto other characters. Left alone, the raw Greek
            # codepoint ends up inside the \text{} below, which switches to
            # the document's upright text-mode font -- a font with no
            # glyph for it, so pdflatex rejects it as an unset-up Unicode
            # character. amsmath's \text{} explicitly supports dropping
            # back into math mode via $...$ inside itself for exactly this
            # case; re-enter math mode for each single-character MI_MAP
            # symbol still present (only single-character keys apply here
            # -- a multi-character key such as a function name can't
            # appear fused inside a word like this).
            for ch, macro in MI_MAP.items():
                if len(ch) == 1 and ch in t:
                    t = t.replace(ch, "$%s$" % macro.strip())
        if has_word and node.get("mathvariant") == "bold":
            # OpenStax's other bold-vector idiom: <mtext mathvariant="bold">
            # directly on the letter (e.g. bold "F", bold "i"/"j"/"k" unit
            # vectors), instead of the <mstyle mathvariant="bold"> wrapper
            # handled above. \text{} (the plain has_word path below) would
            # print it upright but not bold, silently losing the styling
            # attribute the same way the mstyle/mi cases did before they
            # were fixed.
            return leading_glue + r"\mathbf{%s}" % t + trailing_glue
        if has_word:
            return leading_glue + r"\text{%s}" % t + trailing_glue
        if any(ord(ch) > 127 for ch in t):
            # Same silent-passthrough concern as resolve_symbol() above, for
            # the one branch here (mtext, non-word) that doesn't go through
            # a lookup table but a fixed chain of .replace() calls -- an
            # unmapped character remaining after those substitutions would
            # otherwise leak into the .tex output and only fail later, at
            # pdflatex compile time, with no indication it came from mtext.
            # A warning, not an error, for the same reason as
            # resolve_symbol(): a one-off source defect here may already be
            # covered by a patches/*.patch applied after conversion.
            codepoints = ", ".join(
                "%r (U+%04X)" % (ch, ord(ch)) for ch in t if ord(ch) > 127
            )
            print(
                "WARNING: unmapped symbol %s under <mtext> -- grep the raw "
                "fetched page for this tag/character (don't assume the "
                "codepoint by eye, some are lookalikes); add a "
                "substitution to the mtext branch of convert_node if it's "
                "a systematic gap, or a patches/*.patch if it's a one-off "
                "source defect. Left unconverted for now, which will "
                "likely fail at pdflatex compile time." % codepoints,
                file=sys.stderr,
            )
        # A bare ":" left in math mode isn't just a glyph -- TeX's default
        # math code classifies it as a Relation (like "="), which inserts a
        # thick automatic skip on both sides, visibly gapping it from
        # neighboring text (e.g. spelled-out "Hint" as individual mi
        # letters followed by this mtext ":" renders "Hint :" with a stray
        # gap). Braces force it to an Ord atom instead, matching how a
        # plain-text colon reads elsewhere in these documents.
        return leading_glue + t.replace(":", "{:}") + trailing_glue
    if name == "msub":
        kids = mrow_children(node)
        return "%s_{%s}" % (convert_script_base(kids[0]), convert_node(kids[1]))
    if name == "msup":
        kids = mrow_children(node)
        base = convert_script_base(kids[0])
        superscript = convert_node(kids[1])
        # OpenStax represents derivative primes as the superscript of an
        # <msup> node.  Apostrophes already have native prime semantics in
        # TeX, so emit them directly (y', y'', y''') instead of treating
        # them as ordinary superscript content (y^{'}, y^{''}, y^{'''}).
        stripped_superscript = superscript.strip()
        if stripped_superscript and set(stripped_superscript) == {"'"}:
            return base + stripped_superscript
        return "%s^{%s}" % (base, superscript)
    if name == "msubsup":
        kids = mrow_children(node)
        base = convert_node(kids[0])
        if kids[0].name == "mo" and base.strip() in ("+", "-"):
            # OpenStax quirk: an msubsup whose base is a bare binary operator
            # encodes a small inline fraction typeset immediately after that
            # operator, not a literal sub/superscript on it -- sub is the
            # denominator, sup is the numerator (e.g. "+" with sub "n", sup
            # "1" means "+ 1/n", not "+_n^1").
            return r"%s\frac{%s}{%s}" % (base, convert_node(kids[2]), convert_node(kids[1]))
        return "%s_{%s}^{%s}" % (
            convert_script_base(kids[0]),
            convert_node(kids[1]),
            convert_node(kids[2]),
        )
    if name == "mfrac":
        kids = mrow_children(node)
        return r"\frac{%s}{%s}" % (convert_node(kids[0]), convert_node(kids[1]))
    if name == "msqrt":
        kids = mrow_children(node)
        return r"\sqrt{%s}" % "".join(convert_node(k) for k in kids)
    if name == "mroot":
        kids = mrow_children(node)
        return r"\sqrt[%s]{%s}" % (convert_node(kids[1]), convert_node(kids[0]))
    if name == "munder":
        kids = mrow_children(node)
        base_txt = convert_node(kids[0]).strip()
        if base_txt == r"\lim":
            return r"\lim_{%s}" % convert_node(kids[1])
        under_txt = convert_node(kids[1]).strip()
        if not base_txt and under_txt == BLANK_LINE:
            # OpenStax's fill-in-the-blank idiom also shows up with an
            # empty base (a bare <mrow/>) and the underscore run as a
            # stretchy underscript instead of a bare <mo> sibling -- same
            # blank, just wrapped in munder. convert_node already turned
            # the underscript into BLANK_LINE via the "mo" branch above;
            # don't also wrap it in \underset{}{}.
            return under_txt
        return r"\underset{%s}{%s}" % (convert_node(kids[1]), base_txt)
    if name == "mover":
        kids = mrow_children(node)
        if node.get("accent") == "true":
            accent_raw = kids[1].get_text().strip()
            if accent_raw in ACCENT_MAP:
                # A genuine diacritic (tilde, hat, bar, ...) over its base --
                # \overset{}{} below is the wrong tool for this: it stacks
                # a full-size copy of the second argument above the first
                # with generic inter-atom spacing, which for a small
                # accent character produces a floating, oddly-spaced mark
                # instead of a diacritic sized and positioned the way
                # \tilde{}/\hat{}/etc. do it. Use the dedicated accent
                # macro whenever the raw (pre-MO_MAP) accent character is
                # one of the ones MathML's accent="true" idiom is known to
                # use for.
                return r"\%s{%s}" % (ACCENT_MAP[accent_raw], convert_node(kids[0]).strip())
        return r"\overset{%s}{%s}" % (convert_node(kids[1]), convert_node(kids[0]))
    if name == "munderover":
        kids = mrow_children(node)
        return "%s_{%s}^{%s}" % (
            convert_script_base(kids[0]),
            convert_node(kids[1]),
            convert_node(kids[2]),
        )
    if name == "mfenced":
        open_ch = node.get("open", "(")
        close_ch = node.get("close", ")")
        sep = node.get("separators", ",")
        sep_ch = sep[0] if sep else ","
        kids = mrow_children(node)
        inner = (sep_ch + " ").join(convert_node(k) for k in kids)
        # Two more OpenStax idioms encoded via literal open/close attributes
        # rather than a dedicated MathML element: "||...||" is norm/
        # magnitude notation (a doubled ASCII pipe instead of the single
        # stretchy "‖"/mtext idiom handled elsewhere), and "<...>" is the
        # same angle-bracket vector/tuple notation as the Unicode "〈"/"〉"
        # <mo> characters above, just spelled with plain ASCII "<"/">".
        # Neither is valid raw \left/\right delimiter syntax on its own --
        # \left< isn't a recognized delimiter (pdflatex: "Missing
        # delimiter") and \left||...\right|| renders as single-weight bars
        # doubled up rather than a proper norm symbol -- so map both to
        # their real LaTeX delimiter macros first.
        FENCE_DELIM_MAP = {"||": r"\|", "<": r"\langle", ">": r"\rangle"}
        left = FENCE_DELIM_MAP.get(open_ch, open_ch)
        right = FENCE_DELIM_MAP.get(close_ch, close_ch)
        return r"\left%s %s \right%s" % (left, inner, right)
    if name == "mspace":
        # A literal " " character is invisible here: math mode determines
        # inter-atom spacing from atom class (Ord-Ord = zero glue) and
        # ignores raw whitespace tokens entirely, regardless of what's in
        # the .tex source -- some real glue is needed instead. But the
        # source's own width attribute (e.g. "0.1em" vs "0.2em") isn't a
        # meaningful measurement to preserve -- it's just whatever OpenStax's
        # own renderer happened to use, not a deliberate typesetting choice
        # -- so rather than reproducing it literally via \hspace{<width>},
        # map it to the standard semantic spacing macro for its rough size:
        # \, (thin space) for the common small gaps (before a differential,
        # around implicit multiplication), \quad for the rare wide gap that
        # separates two independent clauses crammed into one $...$. Both are
        # self-delimiting or pre-spaced, so no letter-merging risk follows.
        return r"\quad " if node.get("width") == "0.5em" else r"\,"
    if name == "mtable":
        trs = node.find_all("mtr", recursive=False)
        rows = []
        # A single-column table where every cell is explicitly
        # columnalign="left" is OpenStax's idiom for a left-aligned system
        # of equations (as opposed to the binomial-coefficient idiom, which
        # is a bare two-row table with no columnalign and is handled
        # separately by as_binom_table before reaching here). \begin{matrix}
        # centers each row within the column instead, which visibly
        # misaligns rows of different width -- \begin{array}{l} reproduces
        # the source's own alignment hint.
        all_single_left = True
        for tr in trs:
            cells = tr.find_all("mtd", recursive=False)
            if len(cells) != 1 or cells[0].get("columnalign") != "left":
                all_single_left = False
            rows.append(" & ".join(convert_node(td) for td in cells))
        body = r" \\ ".join(rows)
        if all_single_left:
            return r"\begin{array}{l}" + body + r"\end{array}"
        return r"\begin{matrix}" + body + r"\end{matrix}"
    kids = mrow_children(node)
    if kids:
        return "".join(convert_node(k) for k in kids)
    return node.get_text()


def trailing_prose_punctuation(node):
    """Return a final top-level punctuation token from transparent wrappers."""
    while node.name in ("math", "semantics", "mrow", "mstyle"):
        kids = mrow_children(node)
        if node.name == "semantics":
            kids = [k for k in kids if k.name not in ("annotation-xml", "annotation")]
        if not kids:
            return None
        node = kids[-1]
    if node.name in ("mo", "mtext"):
        text = node.get_text().strip()
        if text in TRAILING_PROSE_PUNCTUATION:
            return text
    if node.name == "mn":
        # OpenStax occasionally folds sentence punctuation into the number
        # token itself (seen as <mn>0.</mn>).  A final punctuation character
        # after at least one digit is still distinguishable from an actual
        # decimal such as 4.75, whose final character is a digit.
        text = node.get_text().strip()
        if len(text) > 1 and text[-1] in TRAILING_PROSE_PUNCTUATION:
            if any(ch.isdigit() for ch in text[:-1]):
                return text[-1]
    return None


def wrap_inline_math(tex, source_node):
    """Wrap converted MathML and leave terminal prose punctuation outside."""
    tex = strip_redundant_control_word_delimiter_spacing(tex.strip())
    punctuation = trailing_prose_punctuation(source_node)
    converted_suffix = "{:}" if punctuation == ":" else punctuation
    if converted_suffix and tex.endswith(converted_suffix):
        body = tex[:-len(converted_suffix)].rstrip()
        if body:
            return "$%s$%s" % (body, punctuation)
    return "$%s$" % tex


def convert_math(math_tag):
    semantics = math_tag.find("semantics", recursive=False)
    if semantics is None:
        return wrap_inline_math(convert_node(math_tag), math_tag)
    pres = None
    for c in semantics.children:
        if isinstance(c, Tag) and c.name not in ("annotation-xml", "annotation"):
            pres = c
            break
    if pres is None:
        return ""
    return wrap_inline_math(convert_node(pres), pres)


def convert_display_math(math_tag):
    """Like convert_math, but for a standalone <div data-type="equation">
    block (display math, not inline) -- emits \\[...\\] instead of $...$
    and skips the trailing-prose-punctuation handling, since a display
    equation's own terminal punctuation belongs inside it, not appended
    to surrounding prose that doesn't exist here."""
    semantics = math_tag.find("semantics", recursive=False)
    if semantics is None:
        pres = math_tag
    else:
        pres = None
        for c in semantics.children:
            if isinstance(c, Tag) and c.name not in ("annotation-xml", "annotation"):
                pres = c
                break
        if pres is None:
            return ""
    tex = strip_redundant_control_word_delimiter_spacing(convert_node(pres).strip())
    return r"\[%s\]" % tex


def escape_plain_text(s):
    """Text nodes outside any <math> element (ordinary prose) are otherwise
    copied close to verbatim into the .tex source -- but LaTeX gives several
    ASCII characters special meaning even outside math (a bare "%" silently
    truncates the rest of the source line as a comment; "$", "&", "#", "_",
    "{", "}" are similarly reserved), and OpenStax occasionally drops a
    stray Unicode math symbol (e.g. a bare "π") directly into prose rather
    than wrapping it in a <math> element, which pdflatex then rejects
    outright since prose isn't run through convert_node's MI_MAP/MO_MAP at
    all. Escape the former; wrap the latter in inline math."""
    s = s.replace("\\", r"\textbackslash ")
    s = s.replace("{", r"\{").replace("}", r"\}")
    s = s.replace("%", r"\%").replace("$", r"\$").replace("&", r"\&")
    s = s.replace("#", r"\#").replace("_", r"\_")
    # "^" and "~" are also LaTeX-reserved in text mode (bare "^" triggers
    # an accent command expecting a following group -- "Missing $
    # inserted" -- and "~" is the fixed-width non-breaking-space macro,
    # not a literal tilde character). Seen in a media data-alt description
    # that used bare "^" for exponents (e.g. "y=x^2") in plain prose, not
    # inside a <math> element -- escape both to their printable-glyph
    # macros rather than leave them as active characters.
    s = s.replace("^", r"\textasciicircum{}").replace("~", r"\textasciitilde{}")
    # A stray Greek letter (or other MI_MAP symbol -- e.g. an image's
    # data-alt description referencing "the theta = 0 line" with a literal
    # "θ") dropped directly into prose, not wrapped in a <math> element,
    # needs the same macro MI_MAP would give it inside math mode -- reuse
    # that table instead of hand-listing prose-specific cases one at a time
    # (this replaced a π-only special case once a second letter turned up).
    for ch, macro in MI_MAP.items():
        if len(ch) == 1:
            s = s.replace(ch, "$%s$" % macro.strip())
    s = s.replace("−", "-").replace("’", "'")
    s = s.replace("“", "``").replace("”", "''")
    # En/em dashes (e.g. "Exercises 159–162", a range separator) are
    # literal Unicode here, not LaTeX's own "--"/"---" ligature input --
    # cmr10 has no direct glyph for either raw codepoint, so pdflatex
    # rejects them with "Missing character" rather than silently misprinting.
    s = s.replace("–", "--").replace("—", "---")
    return s


def node_to_text(node):
    out = []
    for child in node.children:
        if isinstance(child, NavigableString):
            out.append(escape_plain_text(str(child)))
        elif isinstance(child, Tag):
            if child.name == "math":
                out.append(convert_math(child))
            elif child.name == "span" and child.find("math"):
                for m in child.find_all("math"):
                    out.append(convert_math(m))
            elif child.name == "sup":
                # OpenStax occasionally drops an exponent/subscript directly
                # into prose using plain HTML <sup>/<sub> instead of a
                # <math> element (e.g. "e<sup>x</sup>", "-<em>x</em><sup>2
                # </sup>") -- losing the tag entirely (the generic fallback
                # below) turns "e^x" into plain "ex". An empty-base math
                # superscript/subscript ("$^{...}$") is valid TeX (the "^"
                # attaches to an implicit empty atom) and at least preserves
                # the position/meaning, even though it doesn't unify with a
                # preceding plain-text base into one italicized expression.
                out.append(r"$^{%s}$" % node_to_text(child))
            elif child.name == "sub":
                out.append(r"$_{%s}$" % node_to_text(child))
            elif child.name == "div" and child.find("table") is not None:
                # A data table (see convert_table) sitting inside an <li>'s
                # own prose (e.g. "Approximate the average depth ... <table>"
                # as part of the same list item) rather than as a top-level
                # sibling of the exercise's <p> -- handle_exercise_div's own
                # div branch only sees direct children of the problem
                # container, so a table nested this deep only ever reaches
                # this generic recursive path.
                out.append("\n" + convert_table(child.find("table")) + "\n")
            elif child.name == "span" and child.get("data-type") == "newline":
                # OpenStax's manual mid-paragraph line break (a bare <br/>
                # wrapped in a data-type="newline" span, e.g. between a
                # displayed system of equations and a "Let a=1, b=2, ..."
                # follow-up sentence in the same <p>). The generic fallback
                # below would recurse into it, find no text at all, and
                # silently drop it -- not a content loss, but the two
                # sentences run together with no separation at all. \\ is
                # a manual line break, valid inside an \item's own text.
                # Stripped back out below if nothing ends up following it.
                out.append(r"\\")
            elif child.get("data-type") == "media":
                # A figure sitting inside an <li> (a lettered sub-part)
                # rather than directly in the problem container or at the
                # section top level -- e.g. section 5.3 exercise 57's
                # spherical-cap figures, one per sub-item (a)/(b). Neither
                # handle_exercise_div's container loop (only sees direct
                # children of os-problem-container) nor the top-level
                # section loop reaches this depth; the generic recursive
                # fallback below finds only an <img> with no text and
                # silently drops the figure entirely -- same "silent
                # content loss" pattern as the div/span media cases handled
                # at the container/section level, one level deeper. Reuse
                # the same \\-prefixed-line convention when something
                # already precedes it in this item's text. The media span
                # is typically itself preceded by an explicit newline span
                # (handled just above) that already emitted the "\\" break,
                # usually with a whitespace-only text node in between (the
                # source's own indentation newline) -- so check the joined
                # text so far with trailing whitespace stripped, not just
                # the last raw token, or the whitespace node defeats a
                # naive out[-1] check and doubles the break into "\\\\"
                # (an extra blank line, though not a compile error).
                joined_so_far = "".join(out).rstrip()
                if joined_so_far and not joined_so_far.endswith(r"\\"):
                    out.append(r"\\ ")
                out.append(media_placeholder(child))
            else:
                out.append(node_to_text(child))
    text = "".join(out)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n+", " ", text)
    text = text.strip()
    # A newline span's \\ marker is only meaningful when real content
    # follows it in the same paragraph (the epitrochoid case above). Most
    # occurrences instead sit at the very end of a <p> that also had an
    # image immediately after it in the source (OpenStax's own layout,
    # tucking the sentence tight against the figure below) -- since that
    # image is dropped as data-type="media" and can't be reproduced, the
    # \\ has nothing left to attach to. It's not a compile error there
    # (real text still precedes it), just a pointless forced line break
    # right before the paragraph/item was going to end anyway. Drop a
    # trailing \\ (one or more, in case of consecutive image separators);
    # a paragraph that was ONLY the marker collapses to "" here too, still
    # caught by this function's callers' `if text:` checks.
    text = re.sub(r"(?:\\\\)+$", "", text).rstrip()
    return text


def escape_item_bracket(text):
    """A leading '[' after \\item is parsed by LaTeX as the optional
    relabeling argument -- used here for OpenStax's "[T]" technology-required
    marker, which \\item would otherwise silently swallow as a relabeling
    argument (replacing the item's number with "T"). That marker is always
    exactly "[T]" in practice (never some other bracketed prefix), so emit
    the exercises.cls \\techrequired macro for it instead of raw escaped
    text -- any other leading '[' (never observed, but not guaranteed
    impossible) still falls back to the generic brace-escape."""
    if text.startswith("[T]"):
        return r"\techrequired" + text[3:]
    if text.startswith("["):
        return "{[}" + text[1:]
    return text


def media_placeholder(node):
    """A <div>/<span data-type="media"> wraps a figure (e.g. a direction
    field or a reference plot) that can't be reproduced in the .tex output.
    OpenStax always pairs it with a data-alt attribute -- a real prose
    accessibility description of what the figure shows, not boilerplate --
    duplicated onto the nested <img>'s own alt attribute. Surface it as a
    bracketed placeholder instead of silently dropping the figure outright,
    so a reader at least knows one belongs here and roughly what it shows."""
    desc = node.get("data-alt") or ""
    if not desc.strip():
        img = node.find("img")
        if img is not None:
            desc = img.get("alt") or ""
    desc = desc.strip()
    if not desc:
        return r"\textit{[Figure omitted]}"
    return r"\textit{[Figure: %s]}" % escape_plain_text(desc)


def convert_table(table):
    """A genuine HTML <table> (OpenStax wraps it in <div class="os-table">)
    -- seen so far only for a grid of sampled function values indexed by x
    down the rows and y across the columns (a Riemann-sum midpoint-rule
    exercise). This has no MathML involved at all, so it's a completely
    separate code path from convert_node's mtable handling above (which
    only ever sees a table *inside* a <math> element, e.g. the
    binomial-coefficient or left-aligned-system idioms).

    Without this, the table is either silently dropped entirely (when it's
    a sibling <div> of the exercise's <p>, since the generic div branch in
    handle_exercise_div only pulls out <p> descendants and a <table> has
    none) or, when it's nested inside an <li>'s prose, flattened by
    node_to_text's generic recursion into one run-on line of numbers with
    the row/column structure gone -- both silent content loss on a
    real-numbers reference table where the row/column position is the only
    thing giving each number meaning.

    Renders a plain `tabular` (no extra package needed), row-for-row,
    cell text run through node_to_text so an embedded <math> cell (e.g.
    "$x_0=0$") still converts correctly; a `colspan` becomes a
    `\\multicolumn`. The first column (row labels) is left-aligned, the
    rest centered -- a reasonable default since every table seen has been
    exactly this "row/column labels + numeric grid" shape."""
    rows = []
    ncols = 0
    for tr in table.find_all("tr"):
        cells = []
        for td in tr.find_all(["td", "th"], recursive=False):
            colspan = int(td.get("colspan", 1) or 1)
            text = node_to_text(td)
            cells.append((text, colspan))
        rows.append(cells)
        ncols = max(ncols, sum(c for _, c in cells))
    if not rows:
        return ""
    col_spec = "l" + "c" * max(ncols - 1, 0)
    lines = [r"\begin{center}", r"\begin{tabular}{%s}" % col_spec, r"\hline"]
    for cells in rows:
        rendered = [
            r"\multicolumn{%d}{c}{%s}" % (colspan, text) if colspan > 1 else text
            for text, colspan in cells
        ]
        lines.append(" & ".join(rendered) + r" \\")
    lines.append(r"\hline")
    lines.append(r"\end{tabular}")
    lines.append(r"\end{center}")
    return "\n".join(lines)


def parse_exercises_section(content_html):
    soup = BeautifulSoup(content_html, "lxml")
    sec = soup.find("section", class_="section-exercises")
    if sec is None:
        raise RuntimeError(
            "no <section class=\"section-exercises\"> found -- this page may not "
            "have an end-of-section exercises block, or OpenStax changed the markup"
        )

    problems = []

    def handle_exercise_div(div):
        prob_div = div.find("div", attrs={"data-type": "problem"}, recursive=False)
        if prob_div is None:
            return
        container = prob_div.find("div", class_="os-problem-container")
        if container is None:
            return
        parts = []
        for c in container.children:
            if not isinstance(c, Tag):
                continue
            if c.name == "p":
                text = node_to_text(c)
                if text:
                    parts.append(("p", text))
            elif c.name == "ol":
                subs = [node_to_text(li) for li in c.find_all("li", recursive=False)]
                parts.append(("ol", subs))
            elif c.get("data-type") == "media":
                # An embedded figure (e.g. a "graph this curve" exercise's
                # own reference plot) -- OpenStax marks it data-type="media"
                # on either a div or, seen first in section 3.4, a bare
                # span. There's no way to reproduce the image itself, but
                # its data-alt description is real content worth keeping
                # (see media_placeholder) -- on its own line via the same
                # \\ convention as a manual mid-item break, rather than
                # falling through to the generic div branch below (which
                # would recurse into it looking for <p> tags that aren't
                # there anyway).
                prefix = r"\\ " if parts else ""
                parts.append(("p", prefix + media_placeholder(c)))
            elif c.get("data-type") == "equation":
                # A standalone display-math block (e.g. a system of
                # equations) sitting directly in the problem container,
                # not wrapped in a <p> -- the generic div branch below only
                # looks for <p> descendants and would otherwise silently
                # drop it (see the same handling at the section level below).
                m = c.find("math")
                if m is not None:
                    parts.append(("p", convert_display_math(m)))
            elif c.name == "div" and c.find("table") is not None:
                # A data table (see convert_table) sitting as a direct
                # sibling of the exercise's <p>, not nested inside any <li>
                # (e.g. "the values ... are given in the following table."
                # followed immediately by <div class="os-table">). The
                # generic div branch below only pulls <p> descendants out of
                # a div and a <table> has none, so without this the whole
                # table silently vanished with no error at all.
                parts.append(("p", convert_table(c.find("table"))))
            elif c.name == "div":
                for p in c.find_all("p", recursive=True):
                    text = node_to_text(p)
                    if text:
                        parts.append(("p", text))
        problems.append({"parts": parts})

    for child in sec.children:
        if not isinstance(child, Tag):
            continue
        if child.name == "p":
            # An otherwise-empty <p> (just a data-type="newline" <span>,
            # used between a figure image and the next one as layout
            # padding we can't reproduce) converts to "" here -- see the
            # trailing-\\ stripping at the end of node_to_text.
            text = node_to_text(child)
            if text:
                problems.append({"intro": text})
        elif child.name == "div" and child.get("data-type") == "exercise":
            handle_exercise_div(child)
        elif child.name == "div" and child.get("data-type") == "equation":
            # A standalone display-math block between intro paragraphs
            # (e.g. a system of equations describing a model) -- a sibling
            # of the <p> elements, not itself a <p>, so it falls through
            # both branches above and is silently dropped without this case.
            m = child.find("math")
            if m is not None:
                problems.append({"intro": convert_display_math(m)})
        elif child.name == "div" and child.find("table") is not None:
            # A data table (see convert_table) sitting directly between
            # intro paragraphs, not inside any exercise div -- e.g. 2.8's
            # "use the following table, which features the world
            # population by decade." followed immediately by a sibling
            # <div class="os-table">, both at the section-exercises top
            # level. handle_exercise_div already covers this same
            # <div class="os-table"> shape *inside* one exercise container;
            # this top-level loop had no equivalent branch, so the whole
            # table (real numeric data referenced by several exercises that
            # follow) silently vanished with no error -- the same class of
            # bug as the data-type="equation" top-level case above.
            problems.append({"intro": convert_table(child.find("table"))})
        elif child.get("data-type") == "media":
            # A figure sitting directly between intro paragraphs (e.g. 4.2's
            # "Match the direction field..." groups, one image per problem
            # block) rather than inside an exercise container -- same
            # data-alt placeholder as media_placeholder's other call site,
            # as its own paragraph here since there's no item to attach a
            # \\-prefixed line to.
            problems.append({"intro": media_placeholder(child)})
        elif child.name == "ol":
            # A bare <ol> sibling of the intro <p>s (not nested inside an
            # exercise div) -- e.g. 7.2's "In each of the following
            # problems:" is followed by a shared (a)/(b) instruction list
            # that applies to every exercise in the group that follows, not
            # to one particular exercise. handle_exercise_div's "ol" branch
            # (below) already covers a sub-list *inside* one exercise,
            # rendered as a nested lettered enumerate tied to that \item --
            # that machinery doesn't apply here since this list isn't
            # attached to any single \item, and LaTeX's own list-numbering
            # environments (enumerate/enumitem) aren't worth reaching for
            # just to letter a handful of standalone instruction lines.
            # Rendered as one plain paragraph per <li>, prefixed by hand
            # with "(a)", "(b)", ... (matching OpenStax's own lettering)
            # instead of a literal dash or a real LaTeX list.
            texts = [node_to_text(li) for li in child.find_all("li", recursive=False)]
            texts = [t for t in texts if t]
            for letter, text in zip(string.ascii_lowercase, texts):
                problems.append({"intro": "(%s) %s" % (letter, text)})

    return problems


def render_tex(problems, book_title, section_label, source_url):
    lines = []
    lines.append(f"% {book_title} -- {section_label}" if book_title else f"% {section_label}")
    lines.append("% Exercises reproduced from OpenStax, licensed under CC BY 4.0.")
    lines.append(f"% Source: {source_url}")
    lines.append(r"\documentclass{exercises}")
    lines.append(r"\title{%s}" % (book_title or section_label).replace("&", r"\&"))
    if book_title:
        lines.append(r"\subtitle{%s}" % section_label.replace("&", r"\&"))
    lines.append(r"\sourceurl{%s}" % source_url)
    lines.append(r"\author{}")
    lines.append(r"\date{}")
    lines.append("")
    lines.append(r"\begin{document}")
    lines.append(r"\maketitle")
    lines.append("")

    in_list = False
    started_once = False

    def close_list():
        nonlocal in_list
        if in_list:
            lines.append(r"\end{enumerate}")
            in_list = False

    for item in problems:
        if "intro" in item:
            close_list()
            lines.append("")
            lines.append(item["intro"])
            lines.append("")
        else:
            if not in_list:
                opts = "resume" if started_once else "start=1"
                lines.append(r"\begin{enumerate}[%s]" % opts)
                in_list = True
                started_once = True
            body_chunks = []
            sub_list = None
            for ptype, pval in item["parts"]:
                if ptype == "p":
                    body_chunks.append(pval)
                elif ptype == "ol":
                    sub_list = pval
            body = escape_item_bracket(" ".join(body_chunks))
            lines.append(r"\item %s" % body)
            if sub_list:
                lines.append(r"\begin{enumerate}[label=(\alph*)]")
                for sub in sub_list:
                    lines.append(r"  \item %s" % escape_item_bracket(sub))
                lines.append(r"\end{enumerate}")

    close_list()
    lines.append("")
    lines.append(r"\end{document}")
    lines.append("")
    return strip_redundant_spacing("\n".join(lines))


def apply_patch(out_path):
    """Reapply a hand-maintained fix (patches/<basename>.patch, a unified
    diff produced with `diff -u`) on top of the freshly written out_path, if
    one exists for it. Applied with `git apply` rather than the `patch`
    binary, which isn't installed on the host (only inside the texlive
    podman image, which this script doesn't run in and shouldn't need to).

    Deliberately not fatal on failure -- a page's raw HTML/MathML changing
    upstream enough to break context matching shouldn't block getting the
    fresh (if imperfect) conversion; it should just surface loudly so the
    patch gets regenerated by hand."""
    out_path = Path(out_path)
    patch_path = PATCHES_DIR / (out_path.name + ".patch")
    if not patch_path.is_file():
        return
    result = subprocess.run(
        ["git", "apply", "-p0", str(patch_path.resolve())],
        cwd=out_path.resolve().parent,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(
            f"WARNING: {patch_path} did not apply to {out_path} -- left the "
            f"unpatched conversion in place. Regenerate the patch by hand "
            f"(see the skill's Patches section).\n{result.stderr}",
            file=sys.stderr,
        )
        return
    print(f"Applied {patch_path}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("url", help="OpenStax page URL, e.g. .../pages/5-1-sequences")
    ap.add_argument("-o", "--output", help="output .tex path (default: <vol-prefix><page-slug>.tex)")
    ap.add_argument(
        "--no-patch", action="store_true",
        help="skip applying patches/<output>.patch -- write the raw conversion only "
             "(e.g. to regenerate the baseline a patch should be diffed against)",
    )
    args = ap.parse_args()

    print(f"Fetching {args.url} ...", file=sys.stderr)
    html = fetch(args.url)
    state = extract_preloaded_state(html)
    book = state["content"]["book"]
    page = state["content"]["page"]
    archive_version = book["archiveVersion"]
    content_version = book["contentVersion"]
    book_id = book["id"]
    page_id = page["id"]
    page_slug = state["content"]["params"].get("page") if "params" in state["content"] else None

    archive_url = (
        f"https://openstax.org/apps/archive/{archive_version}/contents/"
        f"{book_id}@{content_version}:{page_id}.json"
    )
    print(f"Fetching archive content {archive_url} ...", file=sys.stderr)
    page_json = json.loads(fetch(archive_url))
    content_html = page_json["content"]
    slug = page_json.get("slug", page_slug or "exercises")
    page_title = page_json.get("title", "")

    problems = parse_exercises_section(content_html)
    n = sum(1 for p in problems if "parts" in p)
    print(f"Extracted {n} numbered exercises.", file=sys.stderr)

    book_title = book.get("title", "")
    m = re.match(r"(\d+)-(\d+)-", slug)
    section_label = f"Section {m.group(1)}.{m.group(2)} Exercises: {page_title}" if m else f"{page_title} Exercises"
    doc_title = f"OpenStax {book_title}" if book_title else ""
    tex = render_tex(problems, doc_title, section_label, args.url)

    out_path = args.output or f"{derive_volume_prefix(args.url)}{slug}.tex"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(tex)
    print(f"Wrote {out_path}", file=sys.stderr)

    if not args.no_patch:
        apply_patch(out_path)


if __name__ == "__main__":
    main()
