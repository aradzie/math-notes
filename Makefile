PODMAN ?= podman
TEXLIVE_IMAGE ?= registry.gitlab.com/islandoftex/images/texlive:latest
TEXLIVE_RUN = $(PODMAN) run --rm -it --userns keep-id -v "$(CURDIR):/work:Z" -w /work $(TEXLIVE_IMAGE)

all: pdf

pdf:
	node generate-stats.js
	$(TEXLIVE_RUN) latexmk -pdf active-recall.tex

clean:
	$(TEXLIVE_RUN) latexmk -c

cleanall:
	$(TEXLIVE_RUN) latexmk -C

format:
	~/.cargo/bin/tex-fmt --nowrap **/*.tex
