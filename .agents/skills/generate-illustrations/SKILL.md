---
name: generate-illustrations
description: Author and compile a math illustration in this repository — a 2D or 3D Asymptote (.asy) diagram. Use when asked to draw, illustrate, plot, render, or visualize a curve, surface, or geometric construction, or to build/compile/regenerate an existing .asy illustration.
---

# Generate Math Illustrations

## Purpose

Author an Asymptote diagram (2D or 3D), compile it, and check that the output actually landed before handing it back or referencing it from a `.note` file.

All compilation runs through `texlive.sh` at the repo root, inside a locally built podman image with a virtual display (see "TeX Live via `texlive.sh`" in `AGENTS.md`). The PNG transparent-background step also needs `uv` on the host.

## Files

### Figures

Every `.asy` source lives under `flashcards/`, in an `img/` subdirectory beside the `.note` file it illustrates. For example, a figure for `01-algebra/some-topic.note` lives at `01-algebra/img/some-topic-figure.asy`. If a topic directory has no `img/` yet, create one rather than placing the source flat.

- Name the file after the concept it shows, in kebab-case (e.g. `unit-circle.asy`).
- Each figure compiles to a same-named `.svg` (or `.png`, see below) next to its source.
- Built outputs are committed alongside their sources.

### Libraries

**An `.asy` file whose name starts with `_` is a library.** Figures import it, and it is never compiled on its own. A library can live in one of two places:

| Location | Scope | Current libraries |
| --- | --- | --- |
| `flashcards/` (root) | every figure | `_common.asy`: 2D helpers and the default look (black axes, blue curves, 10pt labels, `size(...)`); `_common3d.asy`: 3D scenes projected to 2D, plus the TNB/helix family (builds on `_common`) |
| a figure's own `img/` directory | figures in that directory | `12-trigonometry/img/_trig.asy`: the trig figures' own look (gray axes and grid, 8pt labels, fixed 7cm clipped window), with function-graph and unit-circle helpers |

Import a library by its file name without the extension: `import _common;`, `import _trig;`.

These two places are exactly where `import` looks. Asymptote runs with `flashcards/` as its working directory, and the Makefile adds `-dir <figure's directory>`. Neither an intermediate directory such as `21-calculus/` nor a sibling topic's `img/` is searched. A library shared by more than one topic therefore belongs in the root.

Rules for libraries:

- **Names must be unique across both levels.** A local `_common.asy` would shadow the root one for the figures beside it: `-dir` is searched before the working directory.
- **Every figure depends on every library in both places,** whether it imports it or not. Editing a root library rebuilds everything, and editing a local one rebuilds its directory. This is coarse on purpose, so a rebuild is never missed.
- **Each library documents itself** in its header comment: what it is for, the import line, and, for a "look" library, a skeleton figure showing the call order. Read the header before using a library, and keep it current when you change one. This skill does not repeat library APIs.
- **Don't keep dead code.** If a helper loses its last caller, delete it.
- Add a local library when several figures in one directory share a construction or a look that the rest of the repo doesn't. Promote helpers to the root only once a second topic needs them.

## Authoring

1. Look at 2–3 existing figures with the closest analog (similar curve family, construction, or the same directory) and match their structure and style.
2. Import the library that sets the look:
   - most 2D figures use `import _common;` plus `size(...)` and `mathdefaults();`;
   - 3D scenes use `import _common3d;`;
   - figures inside a directory with its own library use that library (e.g. `_trig`), following its header's skeleton.
3. Use plain `draw`, `label` and `dot` calls, and the library helpers where they fit.

### LaTeX labels

`mathdefaults()` (in `_common.asy`) loads `amsmath`, so `\text`, `\dfrac`, `\substack` and similar macros work in `label()` strings. Every figure must call it before any `label()`. You can call it directly, or through a library call that does (e.g. `_trig`'s `windowSetup`).

Without it, an amsmath macro fails in a misleading way. Asymptote's per-label pdflatex pass errors and leaves a stale intermediate `.pdf` behind. The visible error is `! I can't find file '<name>_.tex'` followed by `shipout failed`, which looks like a filesystem problem, and the macro is never mentioned.

### SVG or PNG output

By default a figure compiles to a vector `.svg` (`asy -f svg -render=0`). That covers all 2D diagrams and 3D wireframes built from `draw`, `dot` and `label`.

A scene that needs `surface(...)`, `render(...)`, shading or lighting can't be vectorized. Asymptote's SVG backend then quietly embeds a raster image instead. For such a scene, put this directive near the top of the source:

```
// output: png
```

The Makefile then builds a same-named `.png` with a transparent background. Before authoring one, read [PNG output](png-output.md): it covers the required bare `mathdefaults();` line, the render level, and sizing.

For any 3D scene, read [3D scenes](3d-scenes.md) first. It explains why a flat translucent fill must not be mixed with `path3`/`size3`, and the projected-2D pattern `_common3d.asy` uses instead.

## Preview

The Read tool can't display `.svg`, so for an SVG figure render a raster preview and look at that:

```sh
make -C flashcards path/to/file.preview.png
```

This runs `asy -f png` with the same libraries and render level as the real build. The preview lands next to the source, is gitignored, and is scratch rather than a deliverable. `make -C flashcards clean-previews` removes all of them.

Check the preview for:

- overlapping labels or elements;
- anything clipped by the canvas;
- shapes that read wrong.

Edit the source, re-render, and repeat until it's right. If you need more detail, increase `size(...)` in the source rather than cropping the image.

For scenes with overlapping or translucent fills, also count the fills in the compiled SVG, e.g. `grep -c "opacity=" path/to/file.svg`. Confirm the count matches the number of filled shapes in the source; see [3D scenes](3d-scenes.md) for the stray-duplicate failure this catches.

For `// output: png` figures, skip the preview. Build the real `.png` and inspect it directly. The preview is a single opaque render, while the real target goes through the transparency step.

## Compile

```sh
make -C flashcards                               # every figure (svg + png)
make -C flashcards 12-trigonometry/img/graph-sin.svg   # one figure, path relative to flashcards/
```

To build a single figure, use `.svg` or `.png` according to the source's directive. Check that the output exists before referencing it.

The Makefile works like this:

- **Which files it builds:** every non-library `.asy` under `flashcards/`, split by the `// output: png` directive.
- **SVG figures:** built with `../texlive.sh asy -dir <dir> -f svg -render=0 -o <name> <name>.asy`.
  - `dvisvgm` typesets the labels as real vector glyphs.
  - `-o` puts the output next to the source rather than in the working directory.
- **PNG figures:** built with `render-transparent-png.sh`, which is described in [PNG output](png-output.md).
- **When it rebuilds:** only targets older than their source or any library they depend on (see Libraries above).
