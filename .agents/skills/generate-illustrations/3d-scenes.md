# 3D Scenes

Read this before authoring a 3D figure.

## Wireframe or shaded

There are two kinds of 3D figure:

- **Wireframes** built from `draw`, `dot` and `label` (e.g. `import three;` with a plain `unitbox`) stay vector SVG.
- **Shaded scenes** that use `surface(...)`, `render(...)` or lighting need the `// output: png` directive; see [PNG output](png-output.md).

## Flat fills: project everything yourself

A 3D scene that needs a flat translucent region, such as a plane through a curve, can't use `surface()` for it without forcing PNG output.

**The tempting shortcut is unsafe.** It goes like this:

1. Draw the wireframe with `path3`/`draw`.
2. Compute the fill's corners with `project()`.
3. Add them as a plain 2D `fill`/`filldraw`.

Asymptote fits `path3` content (via `size3()`, at shipout) and plain 2D content through separate mechanisms. Mixing them makes it emit the projected fill twice: once at the right scale, and once as a small stray duplicate near the fill's source point. The duplicate is tiny and often lands on top of other artwork, so a quick visual check misses it.

**The safe pattern** is to project every element through the same `project(triple, projection)` call: curve, vectors, labels and fills. Don't use `path3`, `size3` or `Arrow3` in the scene at all, and fit the result with plain `size()` like any 2D figure.

`_common3d.asy` is built this way. `proj()` is its single projection helper, and its header explains the rationale. Before adding a 3D helper there, route all its drawing through `proj()` as well.

To check a scene with fills, count them in the compiled SVG (`grep -c "opacity=" file.svg`). The count should equal the number of fills the source draws; an extra one is the stray duplicate.
