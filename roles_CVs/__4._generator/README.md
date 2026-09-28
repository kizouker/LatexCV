# CV generator (template + data)

Generates role-specific `.tex` CVs from one shared template
(`base_cv_template.tex`) plus a data file (`roles.json`) — instead of
hand-copying and editing a ~300-line `.tex` file for every new role.

No third-party dependencies: pure Python 3 stdlib (`generate_cv.py` only
imports `json`, `os`, `sys`). Only writes `.tex` files — compiling to PDF
still happens via your existing `latexmk` / VS Code LaTeX Workshop setup,
or via a plain `pdflatex` invocation (see **Compiling** below).

## How it works, end to end

```
roles.json  ──┐
              ├──> generate_cv.py ──> roles_CVs/<output_dir>/<output_file>.tex ──> pdflatex ──> PDF
base_cv_template.tex ──┘                                       │
                                                                 ├─ \input{.../SUMMARY_SECTION}
                                        roles_CVs/__3._sections/─┼─ \input{.../EXTRA_SECTIONS[i]}
                                                                 └─ \input{.../section_employments.tex}
```

1. `generate_cv.py` reads `base_cv_template.tex` (a `.tex` file with
   `$$PLACEHOLDER$$` tokens instead of real content) and `roles.json`
   (a list of role objects — one per CV variant).
2. For each role, it does plain string substitution — no templating
   engine, no Jinja, just `str.replace()` — swapping every `$$TOKEN$$` in
   the template for that role's data.
3. It writes the result to `roles_CVs/<output_dir>/<output_file>`, a
   normal, human-readable `.tex` file with `\input{...}` lines pointing
   at content sections that live in `roles_CVs/__3._sections/`. The
   generated file is a wrapper — the actual professional summary,
   coursework, and job history text lives in those `\input`-ed files,
   not in the generated file itself.
4. Compiling that `.tex` file (via `pdflatex`/`latexmk`) is a separate,
   manual step — the generator never invokes a LaTeX compiler.

Because step 3 produces an ordinary `.tex` file, every generated CV is
independently viewable/editable/committable — nothing about the pipeline
is "magic" once generation is done. Re-running the generator just
overwrites that file with fresh content from the same template + data.

## Placeholder reference

Every `$$TOKEN$$` in `base_cv_template.tex` and what replaces it:

| Placeholder | Comes from | Notes |
|---|---|---|
| `$$TITLE_LINE1$$` | `role["title_line1"]` | Big bold title line 1 |
| `$$TITLE_LINE2$$` | `role["title_line2"]` | Big title line 2 |
| `$$SUBTITLE$$` | `role["subtitle"]` | Small gray subtitle |
| `$$QUOTE$$` | `role["quote"]` | Shown via moderncv's `\quote{}` |
| `$$SUMMARY_SECTION$$` | `role["summary_section"]` | Filename only (not a path) — becomes `\input{$$REL$$/__3._sections/<name>}` |
| `$$EXTRA_SECTIONS$$` | `role["extra_sections"]` (a list) | Each entry becomes its own `\input{...}` line, joined with newlines, inserted in list order |
| `$$INDUSTRY_SECTORS$$` | `role["industry_sectors"]` (a list of 2-item lists) | Each pair becomes one `\cvlistdoubleitem{A}{B}` line |
| `$$REL$$` | computed, not a `roles.json` field | `os.path.relpath(ROLES_CVS_DIR, output_dir)` — the right number of `../` so `\input`/`\includegraphics` paths resolve regardless of how deep `output_dir` is nested |

`title_line1`, `title_line2`, `subtitle`, and `quote` are the only fields
run through `escape_latex()` (see **LaTeX-escaping** below) — everything
else (section filenames, industry sector labels) is inserted as literal
LaTeX by design, since section filenames aren't text and industry-sector
labels are short trusted strings you write yourself.

## Fixed vs. variable content

`base_cv_template.tex` is not just placeholders — most of it is **fixed
content shared by every generated CV**: the LaTeX preamble, your name/
contact block, the "Certification Badges" section (4 badge images, hard-
coded), "Process Management" (a fixed 6-item skill list), the full
`section_employments.tex` include (job history — always shown in full,
not condensed), two "What people have said about me" quotes, "Languages"
(Swedish/English/French, always all three), and "References" (a fixed
one-liner). If you want a CV where any of *that* differs by role (e.g. a
different quote per role, different languages listed), it currently has
to become a new `$$PLACEHOLDER$$` in the template — `roles.json` can only
vary what's already wired up as a placeholder.

The only per-role variability today is: title/subtitle/quote text, which
one summary section is used, which list of extra sections is inserted
(and in what order), and which industry-sector pairs are listed.

## `roles.json` schema

```json
{
  "id": "some-role",
  "output_dir": "1. Primary_Roles/Some Role",
  "output_file": "CV-RickardÅberg-Some-Role.tex",
  "title_line1": "Line 1 of the big title",
  "title_line2": "Line 2 of the big title",
  "subtitle": "Small gray subtitle line",
  "quote": "The quote shown under your name",
  "summary_section": "SomeRoleSummary.tex",
  "extra_sections": ["pm_tm_experiences.tex", "education.tex"],
  "industry_sectors": [["Sector A", "Sector B"], ["Sector C", "Sector D"]]
}
```

- `id`: used only to select one role via `python3 generate_cv.py <id>` —
  never written into the output.
- `output_dir`: relative to `roles_CVs/` (not to the generator directory).
- `summary_section` and every entry in `extra_sections` must be a bare
  filename (no path) that exists in `roles_CVs/__3._sections/`.
- There is **no schema validation** — a typo'd filename, a missing key, or
  a malformed `industry_sectors` shape fails as a Python `KeyError` or
  produces a broken `\input{...}` path that only surfaces when you run
  `pdflatex` and read the log. Always regenerate *and* compile after
  editing `roles.json`, never just regenerate.

## Usage

```bash
cd roles_CVs/__4._generator
python3 generate_cv.py               # regenerate every role in roles.json
python3 generate_cv.py math-teacher  # regenerate just one role, by id
```

## Compiling

The generator only writes `.tex` files. To get a PDF:

```bash
cd "roles_CVs/<output_dir>"
export TEXINPUTS=".:$(pwd)/../../__1._images//:$(pwd)/../../__2._photos//:$(pwd)/../../__3._sections//:"
mkdir -p build
pdflatex -interaction=nonstopmode -output-directory=build "<output_file>"
```

(Adjust the relative path depth in `TEXINPUTS` to wherever `roles_CVs/`
actually is from your current directory — the `.latexmkrc` at
`roles_CVs/.latexmkrc` sets the same three search paths for `latexmk`/VS
Code LaTeX Workshop, so if you compile through those instead, you don't
need to set `TEXINPUTS` by hand.)

`pdflatex` needs `moderncv` plus `fontawesome5` (pulled in by moderncv's
icon packages) and `lmodern` — on a fresh TeX Live install these are in
the `texlive-latex-extra`, `texlive-fonts-extra`, and `lmodern` packages
respectively (`apt-get install --no-install-recommends texlive-latex-base
texlive-latex-recommended texlive-fonts-recommended texlive-lang-european
texlive-latex-extra texlive-fonts-extra lmodern latexmk`, ~700MB).

## Adding a new role

1. Write the role-specific professional summary as a new file in
   `roles_CVs/__3._sections/` (see `Math_teacher.tex` for a short example,
   or `Music_business_economics.tex` for one that blends two angles).
2. Optionally write a role-specific "skills"/"foundation" section too
   (see `Math_teacher_academic_foundation.tex`, `Music_production_skills.tex`,
   `Economics_leadership_foundation.tex`) if the generic shared sections
   don't cover what's distinctive about this role.
3. Add an entry to `roles.json` per the schema above, choosing which
   existing `__3._sections/` files to reuse in `extra_sections`.
4. Run `python3 generate_cv.py <id>`, then compile (see **Compiling**)
   and actually read the resulting PDF — see **Verification workflow**.

## Section-file catalog (`roles_CVs/__3._sections/`)

This directory has ~70 files. Only a subset were written *for* this
generator system; the rest predate it and were written for hand-crafted
CVs elsewhere in the repo. Both kinds are equally valid `\input` targets
for a new role — the generator doesn't distinguish them — but it's worth
knowing which is which before reusing one.

**Written for the generator (all verified against the actual Linköping/
Lund/Mittuniversitetet transcripts and personal application letters in
this repo — see the git history on this directory for what was checked
against what):**

| File | Role(s) using it | Content |
|---|---|---|
| `Math_teacher.tex` | math-teacher | Professional summary |
| `Math_teacher_academic_foundation.tex` | math-teacher | Math/electronics/programming coursework with ECTS totals |
| `French_teacher.tex` | french-teacher | Professional summary |
| `Music_production_teacher.tex` | music-production-teacher | Professional summary |
| `Music_production_skills.tex` | music-production-teacher, music-business-economics | Instruments, DAWs, Lund/Miun coursework (marked "Ongoing" — not yet graded) |
| `Economics_innovation_leadership.tex` | economics-innovation-leadership | Professional summary |
| `Economics_leadership_foundation.tex` | economics-innovation-leadership, music-business-economics | Leadership/economics/entrepreneurship coursework |
| `Music_business_economics.tex` | music-business-economics | Professional summary (music tech + IT + business framing) |
| `General_substitute_teacher.tex` | general-substitute-teacher | Professional summary |
| `cv_section_general_subjects.tex` | general-substitute-teacher | Swedish/English/Math/SFI/Samhällskunskap/Historia, with level (Gymnasienivå) |
| `cv_section_education_minimal.tex` | all six roles above | Shared "Formal Education" list (MSc, Lund/Miun, Dramapedagogik I, upper-secondary) |
| `cv_section_it_experience_condensed.tex` | math-teacher, french-teacher, music-production-teacher, general-substitute-teacher | One-paragraph condensed career summary (used instead of the full `pm_tm_experiences.tex` job-by-job history, to keep teaching-focused CVs shorter) |

**Pre-existing, reused as-is:**

- `pm_tm_experiences.tex`, `dev_experiences.tex` — detailed job-by-job
  project management / development narratives (used in full by
  `economics-innovation-leadership`, where the detail is the point,
  rather than the condensed version)
- `section_employments.tex` — the flat employer/date/title list, always
  included by the template unconditionally (**not** an `extra_sections`
  entry — see `education.tex`'s two known bugs below, which also live in
  this same directory and are shared by anything that still `\input`s it)
- `education.tex` — the old, long-form education section (course-by-
  course paragraphs, an Agile/DevOps course grid). Superseded by
  `cv_section_education_minimal.tex` for every generator-built role, but
  still `\input`-ed by hand-written CVs elsewhere in the repo.
- Everything else (`cv-fullstack.tex`, `dev_backend_section.tex`,
  `cyber_security.tex`, the various `cv_section_prof_summary_*.tex`
  files, etc.) — written for specific hand-crafted CVs under
  `roles_CVs/1. Primary_Roles/` and `2. Secondary_Roles/` that predate
  this generator. Safe to reuse in a new role's `extra_sections` if the
  content genuinely fits, but **re-read and re-verify the content first**
  — some of it was written before the honesty/verification discipline
  below was established, so treat anything not in the first table as
  unverified until you've checked it.

## Verification workflow (why this matters)

Every fact-bearing section listed in the "written for the generator"
table above was checked against a primary source — the official
Linköping University degree transcript, Lund/Mittuniversitetet course
listings, or the applicant's own prior application letters — before being
written. Two real mistakes happened during that process and are worth
knowing about before adding more:

1. **A course looked complete but wasn't.** The Linköping transcript
   lists some courses with no final grade and no completion date (shown
   as `-`/`-` in the raw transcript, vs. an actual grade like `3`/`4`/`5`
   and a real date for genuinely completed courses). `Analys D`,
   `Analys F`, and `Kryptoteknik` were briefly added to
   `Math_teacher_academic_foundation.tex` and then removed once this
   distinction was noticed — they were registered, not completed.
2. **Ongoing coursework was framed as finished.** The Lund/
   Mittuniversitetet music courses in `Music_production_skills.tex` are
   deliberately worded "Currently pursuing" rather than as completed
   qualifications, for the same reason.

**Before writing a new fact-bearing section**: if you're working from a
transcript-like source, check for a real grade *and* a real date, not
just a course name appearing in the list — and if a parent course has
graded sub-components, only claim the ones that are actually graded, not
the parent as a whole. When in doubt, say "ongoing" or "coursework in"
rather than implying completion.

## Known LaTeX gotchas fixed in this template (don't reintroduce them)

- **Unescaped `&`, `%`, `#`, `_` in plain-text fields.** LaTeX treats
  these as special characters outside math/tabular contexts (`&` in
  particular is a table-column separator and corrupts everything parsed
  after it, silently, until the *next* file boundary). `generate_cv.py`'s
  `escape_latex()` handles this automatically for
  `title_line1`/`title_line2`/`subtitle`/`quote` and for
  `industry_sectors` — do not bypass it by writing raw LaTeX into those
  `roles.json` fields expecting it to render literally.
- **`\beforetitle` is not a real moderncv command** in the TeX Live
  version this was built and tested against (`moderncv` 2022-02-21
  v2.3.1) — it silently produced "Undefined control sequence" +
  "Missing \begin{document}" on *every* compile, and LaTeX's error
  recovery happened to still render the title block roughly correctly,
  which is why it went unnoticed for a while. The current template puts
  the title block as plain content directly after `\begin{document}`
  instead. If you see this same "Missing \begin{document}" error
  reappear after edits near the top of the template, check whether
  something is being invoked before `\begin{document}` that isn't
  actually a defined macro.
- **Image/section include paths must match `output_dir`'s actual depth.**
  `$$REL$$` is computed automatically for this reason — don't hand-write
  a `../../` count into a new section file's own `\includegraphics` or
  `\input` calls, since that file may be `\input`-ed from CVs at
  different directory depths. `education.tex`'s
  `\includegraphics[scale=0.4]{it-security}` bug (which turned out to
  point at a cropped screenshot of a degree transcript, not an icon —
  fixed by removing the include entirely) is the cautionary example.

## Why this exists

Every role CV in `roles_CVs/` shares ~90% of its LaTeX boilerplate
(preamble, photo, certification badges, quotes, references, languages)
and differs only in: title/subtitle, the professional-summary section,
and which experience sections to include. This generator captures that
shared structure once and lets a new CV variant be a ~15-line JSON entry
instead of a full file copy-paste.

## Current roles

As of this writing, `roles.json` defines six roles: `math-teacher`,
`french-teacher`, `music-production-teacher`,
`economics-innovation-leadership`, `music-business-economics`, and
`general-substitute-teacher` (Swedish/English/Math/SFI/Samhällskunskap/
Historia, for folkhögskola "vikarie" applications). Each compiles to a
3-4 page PDF with zero LaTeX errors — see each role's git history for
what was verified and how.

## Possible next step: LLM-assisted role generation

Nothing in this repo currently calls an LLM. Everything above is
deterministic string substitution. A natural next layer — not yet
built — would be a script that takes a job posting as input, reads this
directory's `__3._sections/` files as a bank of pre-verified facts, and
asks an LLM to (a) pick which existing sections fit the posting, (b)
draft a new professional-summary section constrained to only the facts
already present in this repo, and (c) emit a new `roles.json` entry —
which this generator then turns into a `.tex` file exactly as it does
today. The verification discipline in this README (real grade + real
date, "ongoing" vs. "completed", no claims beyond what's on file) would
need to become an explicit constraint in that script's prompt, not just
a convention a human remembers.
