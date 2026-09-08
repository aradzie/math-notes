#!/usr/bin/env bash
# One-off: normalize every patches/*.tex.patch diff header to the canonical
# form documented in .agents/skills/import-openstax-exercises/SKILL.md --
# "--- /tmp/raw.tex" / "+++ <slug>.tex" -- replacing whatever ad hoc raw
# baseline name and/or stray timestamp a given patch happened to carry.
# The target name is inferred from the patch's own filename (strip
# ".patch"), not read from the existing "+++" line, so this also corrects
# any patch whose header drifted from its filename.
#
# Only the first "--- " and first "+++ " line (the diff header, before any
# "@@" hunk) are touched -- hunk body lines never start with "--- "/"+++ ".
set -euo pipefail
cd "$(dirname "$0")"

for patch in *.tex.patch; do
	target="${patch%.patch}"
	sed -i \
		-e "0,/^--- /{s|^--- .*|--- /tmp/raw.tex|}" \
		-e "0,/^+++ /{s|^+++ .*|+++ ${target}|}" \
		"$patch"
done
