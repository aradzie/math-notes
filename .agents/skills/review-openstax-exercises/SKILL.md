---
name: review-openstax-exercises
description: Review and correct existing OpenStax exercise `.tex` files for mathematical correctness, LaTeX quality, math-mode boundaries, punctuation, and whitespace; preserve corrections as cumulative patches and track reviewed files. Use for manual audits under `openstax/`, not for importing a new page.
---

# Review OpenStax Exercises

## Purpose and scope

Act as a mathematical and typographic censor for existing exercise files under
`openstax/`. Correct the local `.tex`, rebuild and inspect its PDF, and save a
cumulative patch that the extractor will reapply after a future import.

This is not an import workflow. Do not fetch or re-extract OpenStax content
unless the user explicitly authorizes it. Before creating or updating patches,
read `../import-openstax-exercises/SKILL.md`; its patch format and extractor
behavior are authoritative.

Preserve exercise substance, numbering, document-class hooks, and nearby
notation, but do not preserve a clear mathematical error merely because it is
upstream. Repair the intended statement when its context makes the correction
unambiguous. If two plausible repairs yield different exercises, report the
ambiguity rather than inventing a problem.

Do not modify `extract-exercises.py` merely because one reviewed file has a
defect. A safe recurring conversion defect may justify a separate converter
change when the user authorizes that broader scope. Do not put editorial
comments in `.tex` files; explain manual corrections in their patch preambles.

## Selecting files

`openstax/REVIEWED.txt` is the review ledger, with one bare `.tex`
filename per line. When the user does not name files:

1. Subtract the ledger entries from the flat set `openstax/*.tex`.
2. Randomly select the requested count, or five files if no count is given.
3. Report the selection before editing.
4. Never select `exercises.cls` or non-exercise files.

Start with `git status --short`. Existing changes belong to the user; do not
overwrite them or fold unrelated work into review patches.

## Review checklist

Read each assigned source line by line. Searches help locate candidates but do
not replace mathematical review.

### Mathematical correctness

Check every formula against its prose and neighboring exercises. Defects found
in prior reviews include:

- a series beginning at `n=1` although the conclusion uses `a_0`;
- `dy/dt` paired with an equation and initial condition in `x`, or an IVP in
  `t` followed by a proposed solution in `x`;
- a numerical-method step size that cannot land on the requested endpoint in a
  whole number of steps;
- incorrect signs, bounds, exponents, subscripts, function arguments,
  hypotheses, or supplied exact solutions;
- ambiguous forms such as `\sin ax` where repeated structure clearly intends
  `\sin(ax)`.

Verify supplied solutions by substitution when practical. An upstream error is
still eligible for correction, but call out consequential departures from the
source in the handoff and patch explanation.

### Prose that should be mathematics

Variables and symbolic expressions belong in math mode even when imported as
upright prose. Typical examples are `the value of n`, `where M is the maximum`,
`functions f and g`, `assume x > 0`, and inequalities inside figure
descriptions. Use `$x$-axis` and `$x$- and $y$-axes`.

Join fragmented expressions such as `p$_{n}$`, `e$^{x}$`, `$\pi$t`, and
`-x$^{2}$ into one math span. Keep English outside math mode rather than using
`\text{and}` plus manual spacing to join separate equations.

Typeset units consistently inside a mathematical quantity, for example
`$2\,\text{g}/\text{cm}^{2}/\text{yr}$`.

### LaTeX structure and semantics

Look beyond compilation success for constructs that render or mean the wrong
thing:

- sentence punctuation trapped inside math, such as
  `$\frac{1}{1-x}.)$` or `$40^\circ\text{F?}$`;
- named functions rendered with `\text{...}` instead of an operator macro or
  `\operatorname{...}`;
- redundant braces, empty scripts, and inconsistent delimiter sizing;
- raw `[T]` markers instead of the class's `\techrequired` macro, including in
  shared instructions and subparts;
- a leading `[` after `\item`, which LaTeX may parse as an optional label;
- comma-separated equations fused into one math span with prose words;
- display arrays with conjunctions embedded at the end of a row.

Prefer clear conventional LaTeX over converter-shaped noise while matching the
file's established notation.

### Whitespace, punctuation, and prose

Preserve every empty and whitespace-only line exactly as it appears in the
pre-review source. Do not add, delete, collapse, move, or normalize such lines.
Whitespace cleanup applies only within non-empty text lines: find trailing
whitespace, doubled spaces, missing prose spaces after punctuation, and erratic
manual math spacing such as `\,=\,`, `,\,\,`, or comma-separated expressions
with no prose space.

Correct clear local prose defects that obstruct the exercise: duplicated
clauses, broken pseudocode labels, inconsistent capitalization of Euler's
method, `directional field` versus nearby `direction field`, and missing list
punctuation. Do not broadly rewrite OpenStax's voice.

Review accessibility figure descriptions as carefully as ordinary prose. They
have contained bare variables, malformed inequalities, duplicated conditions,
and stray characters such as `x > 0-`.

Useful searches, scoped to assigned files, include:

```sh
rg -n '[[:blank:]]+$|  +' <files>
rg -n '[[:alpha:]]\$\^|\$\^\{|p\$_|\[[T]\]' <files>
rg -n '\$[^$]*[.,;:?]\$|\b[xytnabcfgMNR] [<>=] ' <files>
```

Treat every match as a candidate and reread its full context before editing.

## Build and rendered inspection

Build only the assigned PDFs unless a shared dependency changed:

```sh
make -C openstax file-one.pdf file-two.pdf
```

Inspect the logs for errors, missing glyphs, undefined controls, and overfull or
underfull boxes. Report shared-class warnings accurately rather than silently
attributing them to the reviewed source.

## Preserve corrections in cumulative patches

The extractor applies `openstax/patches/<exact-filename>.patch` from inside
`openstax/` with `git apply -p0`. The patch's new-side header must therefore use
the bare `.tex` filename.

Never replace an existing patch with a diff from the committed reviewed file to
the newly edited file. The committed file may already contain corrections from
that patch; doing so would discard them on the next import.

For each assigned file:

1. Preserve its pre-edit reviewed state.
2. Reconstruct the converter-raw baseline. If a patch exists, copy that state
   to a temporary directory and reverse-apply the existing patch there with
   `git apply -R -p0`. With no patch, the starting file is the raw baseline.
3. Edit and validate the real `.tex`.
4. Preserve useful explanations before the existing patch's first `---` line,
   and add a concise explanation of the new corrections there.
5. Generate one cumulative unified diff from the reconstructed raw baseline to
   the final `.tex`, labeling the new side with the bare filename.
6. Apply the cumulative patch to a fresh raw-baseline copy and compare the
   result byte-for-byte with the reviewed source.

Essential verification:

```sh
(cd "$raw_dir" && git apply --check -p0 "/absolute/path/to/file.tex.patch")
(cd "$raw_dir" && git apply -p0 "/absolute/path/to/file.tex.patch")
cmp "$raw_dir/file.tex" openstax/file.tex
```

Do not re-import solely to obtain a patch baseline when re-importing is
prohibited; reconstruct it locally as above.

A unified diff represents an unchanged blank context line with one prefix
space. `git diff --check` run on a `.patch` file may misreport that required
syntax as trailing whitespace. Check whitespace on `.tex` files and validate
patches with `git apply --check`; never strip valid diff context markers.
Also inspect every cumulative patch for added or removed empty or
whitespace-only lines; any such change is a review defect and must be removed
before validation succeeds. For example:

```sh
awk '/^[+-][[:space:]]*$/{print NR ":" $0}' <patch>
```

## Review ledger

Add each bare filename once to `openstax/REVIEWED.txt` only after its
mathematical review, successful build, full rendered-page inspection, and exact
patch replay are complete. Preserve prior entries. Do not mark incomplete or
failed work as reviewed.

## Parallel review

When the user explicitly requests subagents, the coordinator selects files and
assigns disjoint small batches. A worker may edit only its assigned `.tex`, PDF,
and same-named patch files. Workers must not edit `REVIEWED.txt`; the
coordinator updates it once after checking all returned patches and builds.

Require workers to return only filenames, consequential mathematical changes,
ambiguities, and validation status. Because agents share the filesystem, they
need not paste large diffs into the main conversation, and overlapping
assignments are unsafe.

## Handoff

Report the reviewed files, important mathematical judgments, PDF build and
visual-inspection status, cumulative-patch replay, ledger update, and any
ambiguity deliberately left unresolved. Confirm that empty and whitespace-only
lines were preserved. State explicitly when no re-import occurred.
