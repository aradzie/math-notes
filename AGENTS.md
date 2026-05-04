## Purpose

This repository contains LaTeX source files for mathematical self-check question sets.

The documents are for active recall and conceptual reinforcement, not passive exposition.

Primary output:

- standalone `.tex` files
- compilable with `pdflatex`
- readable, conceptually clear question sets

This is not a software project. Do not assume build steps, tests, or generated artifacts.

## Content Standards

Prefer questions that test understanding rather than recall. Good prompts usually ask the learner to explain, derive, compare, interpret, check assumptions, or analyze failure cases.

Useful patterns include:

- why does ...
- under what conditions ...
- what breaks if ...
- how are X and Y related ...
- give an interpretation of ...
- derive ...
- compare ...
- construct a counterexample ...

Default to a small number of substantial questions per topic. Group them by conceptual theme and increase depth within a section.

Avoid by default:

- trivial definition regurgitation
- shallow repetition of the same question
- purely computational drill unless computation is the point
- vague prompts with no clear mathematical target

Keep the material technically precise and direct. Do not add filler or motivational language. Simplify when useful, but do not sacrifice correctness.

## Mathematical Rigor

All mathematical statements must be:

- internally consistent
- notation-consistent
- logically correct
- explicit about assumptions

Do not conflate intuition with proof or use false equivalences for pedagogical convenience.

If rigor is being compressed, preserve correctness and say what is being omitted, approximated, or treated informally.

## LaTeX Style

Use:

- `align*` for multi-line derivations
- semantic sectioning such as `\section` and `\subsection`
- consistent inline math formatting
- standard mathematical notation
