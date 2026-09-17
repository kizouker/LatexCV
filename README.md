# LatexCV

My CV in LaTeX format, organized per role/application under `roles_CVs/` and
`processes/Applications/`.

## Lokal installation (macOS)

1. Installera en LaTeX-distribution:
   ```bash
   brew install --cask mactex-no-gui
   ```
   (mindre alternativ: `brew install --cask basictex`, men då behöver du
   installera paket manuellt vid behov med `tlmgr install <paket>`, t.ex.
   `moderncv fontawesome5 lmodern enumitem microtype babel-swedish`)

2. Öppna en ny terminal (så PATH uppdateras) och verifiera:
   ```bash
   which pdflatex latexmk
   ```

3. VS Code-alternativ: repot har redan `settings.json` med
   `latex-workshop`-konfiguration. Installera tillägget **LaTeX Workshop**
   i VS Code, öppna en `.tex`-fil, så byggs PDF:en automatiskt vid sparning.

## Kompilera ett CV

PDF-filer, `.aux`, `.log` m.fl. är gitignorade (se `.gitignore`) -- bara
`.tex`-källfilerna ligger i repot. Bygg PDF:en lokalt:

```bash
cd "processes/Applications/<ansökningsmapp>"   # eller roles_CVs/...
mkdir -p build
latexmk -pdf -interaction=nonstopmode -output-directory=build "CV-fil.tex"
```

PDF:en hamnar i `build/`.

## Hämta ett specifikt CV via branch

Varje ny jobbansökan/CV utvecklas på en egen branch innan den (eventuellt)
mergas till `main`. För att bara hämta en specifik ansökan utan att merga in
allt:

```bash
git fetch origin
git checkout <branch-namn>
```

Exempel -- Signaltekniker-CV:t (Professionals Nord / Infranord):

```bash
git fetch origin
git checkout claude/signaltekniker-professionals-nord
cd "processes/Applications/2026_09_17_ProfessionalsNord_Signaltekniker-Malmo"
mkdir -p build
latexmk -pdf -interaction=nonstopmode -output-directory=build \
  "CV-RickardÅberg-Signaltekniker-ProfessionalsNord.tex"
```

Lista alla tillgängliga branches (lokalt kända + på origin):

```bash
git branch -a
```

Vill du bara titta på filerna utan att byta branch i din arbetskopia, använd
`git worktree add ../signaltekniker claude/signaltekniker-professionals-nord`
istället för `git checkout`.

## ATS-vänlig variant (utan foto)

Vissa rekryteringssystem (ATS, Applicant Tracking Systems) har svårt att
parsa CV:n med inbäddat foto. Lägg till `--ats` för att även bygga en
fotolös variant vid sidan av den vanliga:

```bash
build-cv claude/signaltekniker-professionals-nord --ats
```

Ger `CV-RickardÅberg-Signaltekniker.pdf` (vanlig) och
`CV-RickardÅberg-Signaltekniker-ATS.pdf` (utan foto) i samma `build/`-mapp.
Fungerar bara på CV:n vars `.tex`-fil deklarerar
`\providecommand{\ATSMODE}{0}` (alla byggda från 2026-09 och framåt).

## Global symlänk + man-sida

Kör från valfri katalog:

```bash
mkdir -p ~/bin
ln -sf ~/Desktop/01_Arbete_Studier/CV_Work/LatexCV/sh/build-cv.sh ~/bin/build-cv
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Full dokumentation: `build-cv --help`, eller som riktig man-sida:

```bash
man ./sh/build-cv.1                                    # läs direkt, ingen installation
# eller, för att kunna köra `man build-cv` varsomhelst:
echo 'export MANPATH="$HOME/Desktop/01_Arbete_Studier/CV_Work/LatexCV/sh:$MANPATH"' >> ~/.zshrc
source ~/.zshrc
man build-cv
```
