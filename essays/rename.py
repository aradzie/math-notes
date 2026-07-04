#!/usr/bin/env python3

"""Rename *.tex and *.pdf files in this directory to lower_snake_case.

Dry run by default; pass --apply to actually rename.
"""

import os
import re
import sys

DIR = os.path.dirname(os.path.abspath(__file__))


def to_snake_case(stem: str) -> str:
    stem = stem.replace("-", "_")
    stem = stem.replace("(", "").replace(")", "")
    stem = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", stem)
    stem = re.sub(r"(?<=[A-Z])(?=[A-Z][a-z])", "_", stem)
    stem = stem.lower()
    stem = re.sub(r"_+", "_", stem)
    return stem.strip("_")


def main():
    apply = "--apply" in sys.argv

    renames = []
    for name in sorted(os.listdir(DIR)):
        stem, ext = os.path.splitext(name)
        if ext not in (".tex", ".pdf"):
            continue
        new_name = to_snake_case(stem) + ext
        if new_name != name:
            renames.append((name, new_name))

    targets = {}
    for old, new in renames:
        targets.setdefault(new, []).append(old)
    collisions = {new: olds for new, olds in targets.items() if len(olds) > 1}
    if collisions:
        print("Collision(s) detected, aborting:")
        for new, olds in collisions.items():
            print(f"  {olds} -> {new}")
        sys.exit(1)

    if not renames:
        print("No renames needed.")
        return

    for old, new in renames:
        print(f"{old} -> {new}")

    if not apply:
        print("\nDry run only. Re-run with --apply to perform these renames.")
        return

    for old, new in renames:
        os.rename(os.path.join(DIR, old), os.path.join(DIR, new))
    print(f"\nRenamed {len(renames)} file(s).")


if __name__ == "__main__":
    main()
