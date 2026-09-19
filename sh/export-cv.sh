#!/usr/bin/env bash
# Compile one or more CV .tex files and export the resulting PDFs to a
# dated, tagged folder outside the repo, so a finished CV is easy to find
# without digging through build/ directories. Complements sh/build-cv.sh
# (which fetches/checks out a branch, compiles, and opens the PDF) --
# this one is for archiving a finished build somewhere findable.
#
# Usage:
#   sh/export-cv.sh path/to/CV-Foo.tex [more .tex files...]
#   sh/export-cv.sh --prune-days 30      # delete exported dates older than 30 days
#
# Every run writes:
#   ~/Desktop/CV/<YYYY-MM-DD>/<basename>__<HHMMSS>.pdf   (permanent, timestamped)
#   ~/Desktop/CV/latest/<basename>.pdf                   (always the newest build)
#
# Override the export root with CV_EXPORT_ROOT if you don't want ~/Desktop/CV.

set -euo pipefail

EXPORT_ROOT="${CV_EXPORT_ROOT:-$HOME/Desktop/CV}"

prune_days() {
  local days="$1"
  echo "Deleting export dates older than $days days under $EXPORT_ROOT ..."
  find "$EXPORT_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' -mtime "+$days" -print |
    while read -r d; do
      echo "  removing $d"
      rm -rf "$d"
    done
}

build_one() {
  local texfile="$1"
  local dir base pdf today stamp outdir tagged

  [[ -f "$texfile" ]] || { echo "Not found: $texfile" >&2; return 1; }

  dir="$(cd "$(dirname "$texfile")" && pwd)"
  base="$(basename "$texfile" .tex)"

  echo "==> Building $base"
  ( cd "$dir" && mkdir -p build \
    && pdflatex -interaction=nonstopmode -halt-on-error -output-directory=build "$base.tex" >/dev/null \
    && pdflatex -interaction=nonstopmode -halt-on-error -output-directory=build "$base.tex" >/dev/null )

  pdf="$dir/build/$base.pdf"
  [[ -f "$pdf" ]] || { echo "Build failed, no PDF produced for $texfile" >&2; return 1; }

  today="$(date +%Y-%m-%d)"
  stamp="$(date +%H%M%S)"
  outdir="$EXPORT_ROOT/$today"
  mkdir -p "$outdir" "$EXPORT_ROOT/latest"

  tagged="$outdir/${base}__${stamp}.pdf"
  cp "$pdf" "$tagged"
  cp "$pdf" "$EXPORT_ROOT/latest/${base}.pdf"

  echo "    -> $tagged"
  echo "    -> $EXPORT_ROOT/latest/${base}.pdf"
}

if [[ "${1:-}" == "--prune-days" ]]; then
  prune_days "${2:?usage: sh/export-cv.sh --prune-days <N>}"
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "usage: sh/export-cv.sh <file.tex> [<file.tex> ...]" >&2
  echo "       sh/export-cv.sh --prune-days <N>" >&2
  exit 1
fi

for f in "$@"; do
  build_one "$f"
done
