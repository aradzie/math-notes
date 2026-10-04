export SOURCE_DATE_EPOCH := 0
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
TEXLIVE_SH := $(abspath $(MAKEFILE_DIR)../texlive.sh)
TEXLIVE_RUN = $(TEXLIVE_SH)
RENDER_TRANSPARENT_PNG_SH := $(abspath $(MAKEFILE_DIR)render-transparent-png.sh)
RECONSTRUCT_PY := $(abspath $(MAKEFILE_DIR)reconstruct-transparent-png.py)

# GL-rendered (hardware-depth-buffered) PNG output needs a display.
# texlive.sh's podman image bundles Xvfb for exactly this, giving Asymptote a
# real GLX display and Asymptote's own -render default (2) for correct
# hardware depth buffering -- needed for scenes with several overlapping 3D
# surfaces (e.g. quad_*.asy), which render with wrong occlusion under
# Asymptote's software rasterizer (-render=0). Override with e.g.
# `ASY_RENDER=4` if needed.
ASY_RENDER ?= 2

# A .asy file whose name starts with '_' is a library: imported by figures,
# never compiled itself. '.transient.' excludes render-transparent-png.sh's
# own temp .asy copies (see that script) from being picked up as scenes in
# their own right.
ASY_SOURCES := $(shell find . -name '*.asy' -not -name '_*' -not -name '*.transient.*' -print)
PNG_SOURCES := $(shell grep -l '^// output: png' $(ASY_SOURCES) 2>/dev/null)
SVG_SOURCES := $(filter-out $(PNG_SOURCES),$(ASY_SOURCES))
SVG_TARGETS := $(SVG_SOURCES:.asy=.svg)
PNG_TARGETS := $(PNG_SOURCES:.asy=.png)

# `import` resolves a library from exactly two places: flashcards/ (asy's
# working directory) and the figure's own directory (passed as -dir). A
# figure depends on every library in both, whether it imports it or not --
# coarse, but it never misses a rebuild. The local half needs the figure's
# directory, hence secondary expansion.
.SECONDEXPANSION:
ROOT_LIBS := $(wildcard _*.asy)
LIBS = $(ROOT_LIBS) $$(wildcard $$(dir $$*)_*.asy)
ASY_DIR = -dir $(dir $<)

all: svg png

svg: $(SVG_TARGETS)

png: $(PNG_TARGETS)

%.svg: %.asy $(LIBS)
	$(TEXLIVE_RUN) asy $(ASY_DIR) -f svg -render=0 -o $(basename $@) $<

# Renders with a real transparent background (not just an opaque one) via
# render-transparent-png.sh's two-render difference-matting technique -- see
# .agents/skills/generate-illustrations/png-output.md.
%.png: %.asy $(LIBS) $(RENDER_TRANSPARENT_PNG_SH) $(RECONSTRUCT_PY)
	$(RENDER_TRANSPARENT_PNG_SH) $(ASY_RENDER) $< $@

# Deliberately stays a single, fast, opaque render (unlike the %.png rule
# above) -- previews are for iterating on layout/labels/clipping, where
# background transparency doesn't matter and doubling render time for it
# would slow down iteration for no benefit.
%.preview.png: %.asy $(LIBS)
	$(TEXLIVE_RUN) asy $(ASY_DIR) -f png -render=$(ASY_RENDER) -o $(basename $@) $<

clean-previews:
	find . -name '*.preview.png' -delete

.DELETE_ON_ERROR:
.PHONY: all svg png clean-previews
