#!/bin/bash

# === CV Build Script ===
TEX_FILE="CV-RickardÅberg-Backend-Developer_java_freelance_eng.tex"
PDF_NAME="CV-Rickard-Aberg-Backend-Developer_freelance_eng.pdf"
DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP="$HOME/Desktop"

cd "$DIR" || exit 1

echo "🧹 Rensar gamla byggfiler..."
rm -f *.aux *.log *.out *.fls *.fdb_latexmk *.synctex.gz

echo "⚙️  Kompilerar (pass 1)..."
xelatex -interaction=nonstopmode "$TEX_FILE"

echo "⚙️  Kompilerar (pass 2, för referenser)..."
xelatex -interaction=nonstopmode "$TEX_FILE"

echo "🧹 Rensar loggfiler..."
rm -f *.aux *.log *.out *.fls *.fdb_latexmk *.synctex.gz

GENERATED_PDF="${TEX_FILE%.tex}.pdf"
if [ -f "$GENERATED_PDF" ]; then
    cp "$GENERATED_PDF" "$DESKTOP/$PDF_NAME"
    echo "✅ Klar! PDF sparad till: $DESKTOP/$PDF_NAME"
    open "$DESKTOP/$PDF_NAME"
else
    echo "❌ Kompilering misslyckades — ingen PDF genererades."
    exit 1
fi
