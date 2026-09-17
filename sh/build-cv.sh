#!/bin/bash
# Fetch a CV branch, check it out, and compile its .tex file to PDF.
#
# Usage:
#   build-cv <branch-name> [path/to/file.tex] [--ats]
#   build-cv --list
#   build-cv --help
#
# Examples:
#   build-cv claude/signaltekniker-professionals-nord
#   build-cv claude/ils-ingenjor-academic-work --ats
#
# See `build-cv --help` (or `man build-cv` if the man page is installed,
# see sh/build-cv.1) for full documentation.
set -euo pipefail

# Resolve the script's own location (following symlinks), so this still
# finds the repo when invoked via a symlink from outside it, e.g.
# ~/bin/build-cv -> .../LatexCV/sh/build-cv.sh
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

print_help() {
  cat <<'EOF'
build-cv -- fetch, checkout and compile a CV branch to PDF

USAGE
  build-cv <branch-name> [path/to/file.tex] [--ats]
  build-cv --list | -l
  build-cv --help | -h

DESCRIPTION
  Automates the full flow for this repo's per-application CV branches:
  fetches from origin, checks out (or creates a local tracking branch
  for) <branch-name>, auto-detects which CV .tex file is new on that
  branch compared to main, compiles it with latexmk, and opens the
  resulting PDF (macOS: via `open`).

ARGUMENTS
  <branch-name>       Branch to build, e.g. claude/signaltekniker-professionals-nord.
  [path/to/file.tex]  Optional: skip auto-detection and compile this file
                       explicitly (path relative to repo root). Needed when
                       a branch touches more than one CV-*.tex file.

OPTIONS
  --ats                Also (or only, combined with the flag alone) produce
                       an ATS-friendly variant: no photo/framebox, plain
                       header. Output is named <CV>-ATS.pdf next to the
                       normal PDF in the same build/ directory. Requires
                       the target .tex file to declare \providecommand{\ATSMODE}{0}
                       near the top (already true for CVs built from
                       2026-09 onward; older templates don't support it).
  --list, -l           List all local and remote branches, then exit.
  --help, -h           Show this help and exit.

EXAMPLES
  build-cv --list
  build-cv claude/signaltekniker-professionals-nord
  build-cv claude/kronofogden-service-delivery-incident-problem-manager --ats
  build-cv claude/ils-ingenjor-academic-work roles_CVs/1.Primary_Roles/Foo/CV-Foo.tex

SEE ALSO
  README.md in the repo root for local LaTeX setup instructions.
  man build-cv, if sh/build-cv.1 has been installed into your MANPATH,
  or run: man ./sh/build-cv.1
EOF
}

ATS=0
BRANCH=""
TEX_FILE=""
POSITIONAL=()

for arg in "$@"; do
  case "$arg" in
    --ats)
      ATS=1
      ;;
    --list|-l)
      echo "Hämtar branch-lista från origin..."
      git fetch origin --quiet
      echo "Tillgängliga branches:"
      git branch -a --format='%(refname:short)' | grep -v '^origin/HEAD' | sed 's/^origin\///' | sort -u
      exit 0
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      POSITIONAL+=("$arg")
      ;;
  esac
done

BRANCH="${POSITIONAL[0]:-}"
TEX_FILE="${POSITIONAL[1]:-}"

if [ -z "$BRANCH" ]; then
  print_help
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

if [ "$ATS" -eq 1 ]; then
  echo "==> Kompilerar ATS-variant (utan foto) ..."
  ATS_JOBNAME="${BASENAME}-ATS"
  if ! (cd "$DIR" && pdflatex -interaction=nonstopmode -halt-on-error \
        -jobname="$ATS_JOBNAME" -output-directory=build \
        "\\def\\ATSMODE{1}\\input{$TEX_BASENAME}" >/dev/null); then
    echo "ATS-kompilering misslyckades. Mallen kanske saknar \\providecommand{\\ATSMODE}{0}." >&2
    echo "Se build/$ATS_JOBNAME.log för detaljer." >&2
    exit 1
  fi
  ATS_PDF_PATH="$DIR/build/$ATS_JOBNAME.pdf"
  echo "==> Klar: $ATS_PDF_PATH"
fi

if command -v open >/dev/null 2>&1; then
  open "$PDF_PATH"
  [ "$ATS" -eq 1 ] && open "$ATS_PDF_PATH"
fi
