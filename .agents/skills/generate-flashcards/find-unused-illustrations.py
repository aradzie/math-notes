#!/usr/bin/env -S uv run --script
"""List illustration sources and outputs that no flashcard note uses."""

import argparse
import re
from pathlib import Path


# Illustration references in notes use Markdown images with paths relative to
# the .note file, such as ![description](img/unit-circle.svg).
IMAGE = re.compile(r"!\[[^\n]*?\]\(\s*<?([^\s)>]+\.(?:svg|png))>?", re.IGNORECASE)
EXTENSIONS = {".asy", ".png", ".svg"}


def referenced_images(flashcards: Path) -> set[Path]:
    images = set()
    for note in flashcards.rglob("*.note"):
        for reference in IMAGE.findall(note.read_text(encoding="utf-8")):
            images.add((note.parent / reference).resolve())
    return images


def unused_files(flashcards: Path) -> list[Path]:
    images = referenced_images(flashcards)
    sources = {image.with_suffix(".asy") for image in images}
    unused = []

    for image_dir in flashcards.rglob("img"):
        if not image_dir.is_dir():
            continue
        for file in image_dir.iterdir():
            if not file.is_file() or file.suffix not in EXTENSIONS:
                continue
            if file.suffix == ".asy":
                if file.name.startswith("_") or file.resolve() in sources:
                    continue
            elif file.resolve() in images:
                continue
            unused.append(file)

    return sorted(unused)


def main() -> None:
    default_flashcards = Path(__file__).resolve().parents[3] / "flashcards"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "flashcards",
        nargs="?",
        type=Path,
        default=default_flashcards,
        help="flashcards directory (default: this repository's flashcards/)",
    )
    args = parser.parse_args()
    flashcards = args.flashcards.resolve()
    if not flashcards.is_dir():
        parser.error(f"not a directory: {flashcards}")

    unused = unused_files(flashcards)
    if unused:
        for file in unused:
            print(file.relative_to(flashcards))
    else:
        print("No unused illustration files found.")


if __name__ == "__main__":
    main()
