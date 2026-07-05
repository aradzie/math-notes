#!/usr/bin/env bash

# Compile every *.tex file in this directory to a PDF using the texlive
# docker image via podman.

set -uo pipefail
shopt -s nullglob

IMAGE="registry.gitlab.com/islandoftex/images/texlive:latest"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUXDIR="build"

# Pin the timestamp pdfTeX embeds in /CreationDate, /ModDate and /ID to a
# fixed constant (not derived from git or wall-clock time) so that
# rebuilding unchanged sources always produces byte-identical PDFs. We
# commit built PDFs alongside sources, so any git-derived timestamp (e.g.
# last commit time) would drift on every unrelated commit and make
# unrelated PDFs' embedded dates churn on rebuild for no reason. pdfTeX
# reads this variable itself; no extra flags are needed.
SOURCE_DATE_EPOCH=0
export SOURCE_DATE_EPOCH

mkdir -p "$DIR/$AUXDIR"

tex_files=("$DIR"/*.tex)

failed=()

for f in "${tex_files[@]}"; do
  name="$(basename "$f")"
  echo "==> Compiling $name"
  if podman run \
      --rm \
      --userns keep-id \
      -e SOURCE_DATE_EPOCH \
      -v "$DIR:/work:Z" \
      -w /work "$IMAGE" \
      latexmk -pdf \
        -interaction=nonstopmode \
        -halt-on-error \
        -auxdir="$AUXDIR" \
        -outdir=. \
        "$name"; then
    echo "==> OK: $name"
  else
    echo "==> FAILED: $name"
    failed+=("$name")
  fi
  echo
done

if [ ${#failed[@]} -eq 0 ]; then
  echo "All ${#tex_files[@]} file(s) compiled successfully."
else
  echo "${#failed[@]} of ${#tex_files[@]} file(s) failed:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
