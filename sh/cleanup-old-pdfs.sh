#!/bin/bash
# Delete old, locally-built CV PDFs (*.pdf is gitignored -- these are build
# output, never committed) while leaving the .tex sources untouched. Any
# deleted PDF can be regenerated any time with build-cv.
#
# Usage:
#   cleanup-old-pdfs [--days N] [--yes]
#   cleanup-old-pdfs --help
#
# Default: dry run, lists what WOULD be deleted. Pass --yes to actually delete.
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -P "$SCRIPT_DIR/.." && pwd)"

print_help() {
  cat <<'EOF'
cleanup-old-pdfs -- delete locally-built CV PDFs older than N days

USAGE
  cleanup-old-pdfs [--days N] [--yes]
  cleanup-old-pdfs --help | -h

DESCRIPTION
  *.pdf is gitignored in this repo -- every PDF next to a CV .tex file is a
  local build artifact, never committed. Over time these pile up on disk.
  This deletes ones older than --days (default 180, ~6 months), based on
  file modification time, and leaves every .tex source untouched -- any
  deleted PDF can be rebuilt any time with `build-cv`.

  By default this is a DRY RUN: it only lists what would be deleted, with
  total size and count. Nothing is removed until you pass --yes.

OPTIONS
  --days N   Age threshold in days (default: 180).
  --yes      Actually delete the matched files. Without this, dry run only.
  --help, -h Show this help and exit.

EXAMPLES
  cleanup-old-pdfs                # see what's older than 6 months
  cleanup-old-pdfs --days 365     # see what's older than a year
  cleanup-old-pdfs --days 365 --yes   # actually delete those
EOF
}

DAYS=180
CONFIRM=0

for arg in "$@"; do
  case "$arg" in
    --yes)
      CONFIRM=1
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
  esac
done

# Separate pass for `--days N`, since its value is a following positional arg.
ARGS=("$@")
for i in "${!ARGS[@]}"; do
  if [[ "${ARGS[$i]}" == "--days" ]]; then
    DAYS="${ARGS[$((i+1))]:-180}"
  fi
done

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "Ogiltigt värde för --days: '$DAYS'" >&2
  exit 1
fi

echo "==> Letar efter *.pdf i $REPO_ROOT äldre än $DAYS dagar ..."
MATCHES_FILE="$(mktemp)"
trap 'rm -f "$MATCHES_FILE"' EXIT

find "$REPO_ROOT" \
  -type d \( -name .git -o -name node_modules -o -name dist -o -name .angular \) -prune -o \
  -type f -name '*.pdf' -mtime "+$DAYS" -print > "$MATCHES_FILE"

COUNT=$(wc -l < "$MATCHES_FILE" | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
  echo "Inga PDF:er äldre än $DAYS dagar hittades."
  exit 0
fi

TOTAL_BYTES=0
while IFS= read -r f; do
  SZ=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo 0)
  TOTAL_BYTES=$((TOTAL_BYTES + SZ))
  echo "  $f"
done < "$MATCHES_FILE"

TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN { printf "%.1f", b/1024/1024 }')
echo "==> $COUNT fil(er), totalt ${TOTAL_MB} MB."

if [ "$CONFIRM" -eq 0 ]; then
  echo "==> Dry run -- inget har tagits bort. Kör med --yes för att faktiskt ta bort dessa."
  exit 0
fi

while IFS= read -r f; do
  rm -f "$f"
done < "$MATCHES_FILE"
echo "==> Tog bort $COUNT PDF-fil(er) (${TOTAL_MB} MB). .tex-källorna är orörda."
