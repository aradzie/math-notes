# PNG Output

Read this before authoring or debugging a figure with the `// output: png` directive. Those are 3D scenes with shaded surfaces, which can't be vector SVG.

## Rendering needs a display

PNG output goes through Asymptote's hardware GL rasterizer (`-render` above 0), and that needs a display. `texlive.sh`'s image provides a virtual `Xvfb` display, which gives Asymptote's default `-render=2` a real depth buffer. With that depth buffer, several overlapping `surface()` draws occlude correctly whatever order they were drawn in.

Without a display, Asymptote falls back to `-render=0`. That software rasterizer does not reliably depth-sort across separate `draw()` calls, so the occlusion comes out wrong.

The Makefile's `ASY_RENDER` variable sets the level. It defaults to 2; override it with e.g. `ASY_RENDER=4`.

## Size for pixels

A raster can't rescale losslessly, so author PNG scenes at a larger physical size than a vector figure would use. For example, use `size3(6cm,10cm,16cm)` rather than `size3(3cm,5cm,8cm)`.

## Transparent background

Asymptote's 3D renderer always composites onto an opaque background. The `%.png` rule (`flashcards/render-transparent-png.sh`) therefore renders the scene twice:

1. Once with `currentlight.background = black;`.
2. Once with `currentlight.background = white;`.

It then difference-mattes the pair into RGBA with `flashcards/reconstruct-transparent-png.py`, run on the host through `uv`:

```
alpha = 1 - (white_render - black_render)   # averaged across R, G, B
rgb   = black_render / alpha                 # the recovered foreground color
```

This holds through any number of overlapping translucent surfaces. Stacked "over" blends are still affine in a common solid backdrop, so the same two-point solve recovers the total alpha and color at each pixel.

Reconstruction stays in gamma space, not linear light. Asymptote's `-srgb` defaults to false, so it already composites in gamma space. Converting to linear light first was measured to make per-channel alpha agreement about an order of magnitude worse.

**Authoring requirement:** the scene must call `mathdefaults();` on its own bare line. The script injects the background setting immediately after that exact line. A scene without it fails the build loudly, rather than silently rendering an opaque background.

The script writes its two temporary sources as `<name>.transient.*.asy` next to the original, so library imports resolve unchanged. The Makefile's source glob skips these files.

## Checking the result

Build and view the real target (`make -C flashcards path/to/file.png`) rather than a `.preview.png`. The preview is a single opaque render with no transparency step, so it can't show how the final image composites over a non-white background.
