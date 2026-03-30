# sudo dnf install texlive-scheme-basic
# sudo dnf install 'tex(amsmath.sty)'
# sudo dnf install 'tex(graphicx.sty)'
# sudo dnf install latexmk

all: pdf

pdf:
	node generate-stats.js
	latexmk -pdf active-recall.tex

pdf-preview:
	node generate-stats.js
	latexmk -pdf -pvc active-recall.tex

clean:
	latexmk -c

cleanall:
	latexmk -C

format:
	~/.cargo/bin/tex-fmt --nowrap **/*.tex
