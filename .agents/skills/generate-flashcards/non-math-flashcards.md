# Non-Math Flashcards

Use this reference when the requested `.note` cards cover programming or another non-math topic. Follow the main skill for `.note` syntax, stable IDs, note independence, and validation. Match the nearby deck, tags, terminology, and note type; programming cards use `!type: Basic`.

## Answer Style

Write `!back:` as a **recall target**, not a mini-explanation. The learner should be able to check the core idea without reproducing a sentence verbatim.

- **Answer directly.** Do not start by restating the question (e.g. "Decoding text means ...") or repeat its terms unless they label distinct items in a comparison.
- **Use keywords and short keyphrases.** Keep their relationship clear with a colon, arrow, semicolon, or brief clause. Use separate bullets for distinct facts or comparison items; omit a summary paragraph that repeats the bullets.
- **Bold the recall anchors** — usually one or two important words or phrases per chunk. Do not bold every word or a whole long sentence.
- **Keep the answer sufficient.** Retain ranges, conditions, qualifiers, and contrasts needed for correctness. A "why" card still needs its core cause or consequence; omit the surrounding tutorial.
- **Split oversized answers.** If several independent facts do not fit into a small set of memorable chunks, narrow the front or make separate notes. Put optional context in `!extra:` only when it helps after recall; make separately testable facts into their own notes.

## Examples

```text
!type: Basic
!deck: Programming
!tags: Programming Encoding

!front: What does it mean to decode text?
!back: **Bytes → Unicode scalar values**, using the specified encoding.
~~~

!front: What is the difference between Unicode and an encoding such as UTF-8?
!back:
- **Unicode:** abstract text standard; code points, names, properties.
- **UTF-8:** byte representation of Unicode scalar values.
~~~

!front: Why can truncating UTF-8 by bytes corrupt text?
!back: A cut can split a **UTF-8 sequence** (invalid bytes) or a **grapheme cluster** (broken visible character).
~~~
```
