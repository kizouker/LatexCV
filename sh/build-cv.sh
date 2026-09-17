#!/bin/bash
# Fetch a CV branch, check it out, and compile its .tex file to PDF.
#
# Usage:
#   sh/build-cv.sh <branch-name> [path/to/file.tex]
#   sh/build-cv.sh --list
#
# Examples:
#   sh/build-cv.sh claude/signaltekniker-professionals-nord
#   sh/build-cv.sh claude/ils-ingenjor-academic-work
set -euo pipefail

# Resolve the script's own location (following symlinks), so this still
# finds the repo when invoked via a symlink from outside it, e.g.
# /usr/local/bin/build-cv -> .../LatexCV/sh/build-cv.sh
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [ "${1:-}" = "--list" ] || [ "${1:-}" = "-l" ]; then
  echo "Hämtar branch-lista från origin..."
  git fetch origin --quiet
  echo "Tillgängliga branches:"
  git branch -a --format='%(refname:short)' | grep -v '^origin/HEAD' | sed 's/^origin\///' | sort -u
  exit 0
fi

BRANCH="${1:-}"
if [ -z "$BRANCH" ]; then
  echo "Användning: $0 <branch-namn> [path/till/fil.tex]" >&2
  echo "       $0 --list   (visa alla branches)" >&2
  exit 1
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "latexmk hittades inte. Installera LaTeX lokalt enligt README.md innan du kör detta." >&2
  exit 1
fi

echo "==> Hämtar senaste från origin..."
git fetch origin --quiet

echo "==> Kollar av oskickade ändringar innan byte av branch..."
if [ -n "$(git status --porcelain)" ]; then
  echo "Du har okommitterade ändringar i arbetsträdet. Committa, stasha eller städa dem först." >&2
  git status --short >&2
  exit 1
fi

echo "==> Checkar ut '$BRANCH'..."
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH" || true
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git checkout -b "$BRANCH" "origin/$BRANCH"
else
  echo "Hittade ingen branch '$BRANCH' lokalt eller på origin." >&2
  echo "Kör '$0 --list' för att se tillgängliga branches." >&2
  exit 1
fi

TEX_FILE="${2:-}"
if [ -z "$TEX_FILE" ]; then
  echo "==> Letar efter CV-fil som skiljer branchen från main..."
  MAPFILE_CANDIDATES=$(git -c core.quotepath=false diff --name-only origin/main..."$BRANCH" -- '*.tex' 2>/dev/null | grep -i '/CV-' || true)
  COUNT=$(echo "$MAPFILE_CANDIDATES" | grep -c . || true)

  if [ "$COUNT" -eq 0 ]; then
    echo "Hittade ingen ny CV-.tex-fil jämfört med main. Ange filen manuellt:" >&2
    echo "  $0 $BRANCH path/till/fil.tex" >&2
    exit 1
  elif [ "$COUNT" -gt 1 ]; then
    echo "Flera CV-filer hittades, ange vilken du menar:" >&2
    echo "$MAPFILE_CANDIDATES" >&2
    exit 1
  fi
  TEX_FILE="$MAPFILE_CANDIDATES"
fi

if [ ! -f "$TEX_FILE" ]; then
  echo "Filen '$TEX_FILE' hittades inte." >&2
  exit 1
fi

TEX_FILE_ABS="$REPO_ROOT/$TEX_FILE"
DIR="$(dirname "$TEX_FILE_ABS")"
BASENAME="$(basename "$TEX_FILE" .tex)"
TEX_BASENAME="$(basename "$TEX_FILE_ABS")"

echo "==> Kompilerar $TEX_FILE ..."
mkdir -p "$DIR/build"
# Körs från filens egen katalog, eftersom mallarnas \graphicspath/\input
# är relativa till den (t.ex. ../../../roles_CVs/__1._images/).
(cd "$DIR" && latexmk -pdf -interaction=nonstopmode -halt-on-error -output-directory=build "$TEX_BASENAME")

PDF_PATH="$DIR/build/$BASENAME.pdf"
echo "==> Klar: $PDF_PATH"

if command -v open >/dev/null 2>&1; then
  open "$PDF_PATH"
fi
