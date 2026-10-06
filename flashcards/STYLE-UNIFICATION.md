# Unifying the Illustration Styles

Status: parked (2026-10-04). This is a record of options to pick up later, not a plan in progress.

## Where things stand

The figures under `flashcards/` are drawn in two styles. The code cleanup is done: each style now has one library, and both libraries share `mathdefaults()`.

| | General style (`_common.asy`) | Trig style (`12-trigonometry/img/_trig.asy`) |
|---|---|---|
| Figures | 138 (26 of them 3D) | 26 (the other 2 in that folder use `_common`) |
| Axes | black, 10pt black labels | thinner gray axes, 8pt gray labels |
| Grid | none | light gray |
| Curves | blue (90 files hard-code it), red for a second curve (64 files), usually labeled inside the plot | black, gray for a secondary curve, no label on the curve |
| Ticks | mostly none; some values labeled by hand (about 20 files) | numbered ticks along both axes, π fractions where useful |
| Asymptotes | dashed lines drawn by hand in each file, with varying pens | `asymptoteH/V`: one dashed gray pen |
| Points | `closedPoint`/`openPoint`, radius in plot units, so the dot size depends on the figure's scale | `keyDot`/`openEnd`, size in points, so the same on every figure |
| Poles | a hand-tuned `eps` gap around each pole (14 files) | `drawFunction` splits the curve at poles automatically |
| Size | `size(...)` per figure, 7cm to 26cm wide | `windowSetup`: the longer side is 7cm, equal axis scales |
| Framing | the image ends at whatever was drawn, so the axis labels at the right and top arrow tips widen it on those sides only and push the plot off-centre | `windowSetup` draws an invisible box with an equal margin on all sides, so the tip labels don't shift the plot |
| Curves leaving the plot | stop at the end of the plotted domain | cut at the window edge, with an arrowhead meaning "continues" |

**Preferred direction:** the trig style. Nothing is decided beyond that.

## Can every figure be about 7cm?

Not literally, but the point of the fixed size can be kept.

Anki shrinks an image to fit the card. What the eye compares between cards is therefore the label size *relative to the figure's width*, not centimeters. At the moment a 10pt label on a 24cm-wide figure displays at roughly a third of the size of the same label on an 8cm figure.

The rule that would actually unify this is **one physical scale for one plot panel**, not one image size. It plays out like this:

- **Single-panel graphs (most figures):** 7cm on the longer side works, as it does for trig. Many are currently 9–14cm and would just come out smaller, with the same font size in points.
- **Multi-panel figures:** about 20 figures are 18–26cm wide because they place 2–3 plots side by side. Examples: `inflection-point`, `rolle-theorem`, `hyperbola-branches-map`, `lines-dependent-compare`. They would get about 7cm per panel, so the total width would be roughly 14cm or 21cm. The other options are to split them into separate images, or to accept smaller text on those cards.
- **Number lines and set pictures:** the `abs-inequality-*` figures and the `61-real-numbers` ones are wide and short (18–20cm × 5–6cm). A "7cm longer side" rule would make their labels too dense. They need their own rule, for example a fixed height per line.
- **3D scenes (26 figures, `_common3d`):** these have their own camera and sizing and are best left out of scope.

So a fixed window would work for most figures, but the multi-panel and number-line ones are each a small redesign.

## What makes a step cheap or expensive

- **Cheap: change a library default.** Some steps only touch `_common.asy`. Every figure using that helper restyles at once, with no figure edits. The work is one edit plus a look at previews (`make -C flashcards <file>.preview.png`).
- **Expensive: edit figures one by one.** Other steps need changes in many figure files, and each one must be reviewed by eye.

## Possible steps, cheapest first

Each step can be done and reviewed on its own, and stopping after any of them leaves a consistent state.

### 1. Axes: library only

Give `drawAxes` and `numberLine` in `_common.asy` the trig axis pen (`gray(0.35)`, 0.5pt) and gray tip labels. This restyles 72 + 8 figures with no figure edits.

**Open question:** should the tip labels also go to 8pt? On today's larger figures 8pt reads very small, so the label size depends on step 6.

### 1b. Balanced frame: library only (wanted)

This is what the trig style's `windowSetup` does.

**The problem:** a figure's image ends at whatever was drawn. `drawAxes` puts the `x` label past the right arrow tip and the `y` label above the top one. The image therefore gets wider on the right and taller at the top, but not on the left or bottom. Anki centres the image, not the plot, so a figure that should be symmetric about the origin shows up slightly shifted left and down.

**The fix:** `windowSetup` draws an invisible box, the window plus the same margin on every side (7% of the longer side). The margin absorbs the tip labels, so the frame stays balanced.

**Doing it for the general figures:** `drawAxes(xmin, xmax, ymin, ymax, ...)` already knows the window, so it could draw the same invisible box itself. The 72 figures that use it would gain a balanced frame with no figure edits. Points to check:

- **The plot shrinks a little.** Under `size(...)` the extra margin is fitted into the same size, so the plot gets slightly smaller in each figure and the labels look a bit larger relative to it.
- **Content outside the axes still shifts the plot.** Captions above the plot or labels far left of it still unbalance the frame. Such figures need a margin of their own, or can accept it.
- **Opting out.** Give `drawAxes` a flag to turn the box off, for figures where it does more harm than good.

This step doesn't depend on the 7cm decision, so it can be done on its own, right after step 1.

### 2. Points: library only

Change `closedPoint`/`openPoint` to fixed-size dots (`keyDot`/`openEnd` style). This affects 34 figures.

Some calls pass an explicit radius in plot units. Those arguments become meaningless, so drop them, or keep the parameter as a size in points.

### 3. Asymptotes and guide lines: mechanical figure edits

1. Move one `asymptotePen` and the `asymptoteH`/`asymptoteV`-style helpers into `_common.asy`.
2. Replace the hand-drawn dashed lines with them. `dashed` appears in 75 files, but not all of those are asymptotes.

Optionally, move `_trig`'s pole-splitting `drawFunction` (with its clipping helpers) to the root and use it to remove the `eps` gaps (14 files). This needs a window (step 6), or a version that clips to a box given explicitly.

### 4. Curve colors: decision first, then figure edits

The trig style draws one main curve in black, plus a gray secondary one. Many general figures use blue and red to tell two curves apart, and the labels refer to those colors.

The options:
- **(a)** Black/gray everywhere. Figures that need two distinguishable curves would use a dashed pen or the accent color.
- **(b)** Keep blue as the main-curve color in both styles, which means changing `_trig`'s `curvePen`.
- **(c)** Define a small named palette (`mainPen`, `secondPen`, `accentColor`) in `_common.asy` and replace the hard-coded colors (about 90 files).

Option (c) is the most work, but afterwards any later color change is a library edit.

### 5. Ticks and grid: optional, per figure

Whether a figure shows numbered ticks or a grid is a content choice, not a style choice. Many general figures label only the meaningful values (a, b, c) on purpose.

**Suggestion:** move the tick and grid helpers to the root so they're available. Use them in new function graphs. Retrofit only figures where the reader actually needs to read off values.

### 6. Size and window: the big one

Adopt `windowSetup` (a fixed scale with clipping) for single-panel 2D graphs, and decide the multi-panel and number-line rules described above.

This step is per figure and changes layout. Labels positioned for a 14cm figure will collide at 7cm, so each figure needs a preview check and probably small fixes to label positions.

The natural order is one folder at a time, starting with a folder made mostly of single-panel function graphs: `13-hyperbolic-functions` (18 figures) or `02-functions` (21).

### 7. Merge the libraries

Once steps 1–4 and 6 are done for the general figures, `_common.asy` is the trig style. Then:

- move `_trig.asy`'s generic parts (window, clipping, `drawFunction`, axes, dots, labels) into it;
- leave `_trig.asy` with only the trig-specific helpers (`piTicks*`, `mirrorLine`, the unit-circle/reference-triangle helpers).

## Checking the changes

Last time, the code cleanup could be checked by confirming the rebuilt output was byte-identical. A style change is meant to change the output, so that check doesn't apply. Each step needs:

- previews of the affected figures, looked at for overlaps, clipping, and colors that the labels or `.note` text refer to;
- for color changes, a grep of the `.note` files for color words ("blue", "red", "dashed"), since card text that describes the figure must stay true.
