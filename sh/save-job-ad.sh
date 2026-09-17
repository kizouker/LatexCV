#!/bin/bash
# Save a job ad's original text as job_ad.txt next to a CV, from a URL, a
# PDF, or a plain text file. Always normalizes to plain text (no PDFs
# committed) so the source stays small and greppable; a PDF can always be
# regenerated later from the text if ever needed.
#
# Usage:
#   save-job-ad <url> <application-folder>
#   save-job-ad <path/to/ad.pdf> <application-folder>
#   save-job-ad <path/to/ad.txt> <application-folder>
#   save-job-ad - <application-folder>   # read the ad text from stdin
#
# Examples:
#   save-job-ad "https://example.com/jobs/123" processes/Applications/2026_09_17_Foo_Bar
#   save-job-ad ~/Downloads/annons.pdf processes/Applications/2026_09_17_Foo_Bar
#   pbpaste | save-job-ad - processes/Applications/2026_09_17_Foo_Bar
set -euo pipefail

print_help() {
  cat <<'EOF'
save-job-ad -- save a job ad's original text as job_ad.txt in an application folder

USAGE
  save-job-ad <url|path/to/file.pdf|path/to/file.txt|-> <application-folder>
  save-job-ad --help | -h

DESCRIPTION
  Normalizes a job ad, from whatever form you have it in, down to a plain
  job_ad.txt file inside <application-folder>:
    - a URL: fetched with curl, then HTML is stripped to plain text
      (lynx, then pandoc, then a crude fallback -- whichever is installed).
    - a .pdf file: text is extracted with pdftotext.
    - a .txt (or any other) file: copied as-is.
    - "-": ad text is read from stdin (e.g. pbpaste | save-job-ad - <folder>).

  Plain text is used on purpose instead of storing PDFs: it stays small,
  is greppable/diffable in git, and a PDF can always be produced from it
  later if one is ever actually needed.

  Note for URLs: many job sites (LinkedIn included) render the actual ad
  text client-side with JavaScript, so a plain curl fetch can come back
  mostly empty. If the saved job_ad.txt looks thin, paste the ad text
  manually instead: pbpaste | save-job-ad - <application-folder>

  If job_ad.txt already exists in the target folder, the old one is kept
  as job_ad.txt.bak before being overwritten.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -lt 2 ]]; then
  print_help
  exit "$([[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && echo 0 || echo 1)"
fi

SOURCE="$1"
DEST_DIR="$2"

if [ ! -d "$DEST_DIR" ]; then
  echo "Ansökningsmappen '$DEST_DIR' finns inte." >&2
  exit 1
fi

DEST_FILE="$DEST_DIR/job_ad.txt"
if [ -f "$DEST_FILE" ]; then
  cp "$DEST_FILE" "$DEST_FILE.bak"
  echo "==> Befintlig job_ad.txt sparad som job_ad.txt.bak"
fi

html_to_text() {
  if command -v lynx >/dev/null 2>&1; then
    lynx -dump -stdin
  elif command -v pandoc >/dev/null 2>&1; then
    pandoc -f html -t plain
  else
    # Crude fallback: strip tags/scripts/styles well enough to be readable.
    sed -e 's/<script[^>]*>.*<\/script>//g' \
        -e 's/<style[^>]*>.*<\/style>//g' \
        -e 's/<[^>]*>//g' \
        -e 's/&nbsp;/ /g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' \
      | sed '/^[[:space:]]*$/d'
  fi
}

case "$SOURCE" in
  http://*|https://*)
    echo "==> Hämtar $SOURCE ..."
    curl -sL "$SOURCE" | html_to_text > "$DEST_FILE"
    WORDS=$(wc -w < "$DEST_FILE" | tr -d ' ')
    echo "==> Sparade $WORDS ord till $DEST_FILE"
    if [ "$WORDS" -lt 50 ]; then
      echo "OBS: väldigt lite text hämtades ($WORDS ord) -- sidan kanske" >&2
      echo "renderas med JavaScript. Klistra in annonsen manuellt istället:" >&2
      echo "  pbpaste | $0 - '$DEST_DIR'" >&2
    fi
    ;;
  -)
    cat > "$DEST_FILE"
    echo "==> Sparade $(wc -w < "$DEST_FILE" | tr -d ' ') ord (från stdin) till $DEST_FILE"
    ;;
  *.pdf)
    if [ ! -f "$SOURCE" ]; then
      echo "Filen '$SOURCE' hittades inte." >&2
      exit 1
    fi
    if ! command -v pdftotext >/dev/null 2>&1; then
      echo "pdftotext hittades inte (ingår i poppler-utils). Installera det, t.ex.:" >&2
      echo "  brew install poppler" >&2
      exit 1
    fi
    pdftotext -layout "$SOURCE" "$DEST_FILE"
    echo "==> Extraherade text från $SOURCE till $DEST_FILE"
    ;;
  *)
    if [ ! -f "$SOURCE" ]; then
      echo "Filen '$SOURCE' hittades inte." >&2
      exit 1
    fi
    cp "$SOURCE" "$DEST_FILE"
    echo "==> Kopierade $SOURCE till $DEST_FILE"
    ;;
esac
