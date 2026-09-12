# CV generator (template + data)

Generates role-specific `.tex` CVs from one shared template
(`base_cv_template.tex`) plus a data file (`roles.json`) — instead of
hand-copying and editing a ~300-line `.tex` file for every new role.

No third-party dependencies: pure Python 3 stdlib. Only writes `.tex`
files; compiling to PDF still happens via your existing `latexmk` / VS
Code LaTeX Workshop setup.

## Usage

```bash
cd roles_CVs/__4._generator
python3 generate_cv.py               # regenerate every role in roles.json
python3 generate_cv.py math-teacher  # regenerate just one role, by id
```

## Adding a new role

Add an entry to `roles.json`:

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

- `summary_section` and every entry in `extra_sections` must be a filename
  that exists in `roles_CVs/__3._sections/` — write the role-specific
  professional summary there first (see `Math_teacher.tex` for an example),
  then reuse whichever shared experience/education sections fit the role.
- `output_dir` is relative to `roles_CVs/`.
- Run `python3 generate_cv.py <id>` — the script computes the right number
  of `../` for image/section paths automatically based on `output_dir`'s
  depth, so you never have to count directory levels by hand (a common
  source of broken image links in the hand-written CVs in this repo).

## Why this exists

Every role CV in `roles_CVs/` shares ~90% of its LaTeX boilerplate
(preamble, photo, certification badges, quotes, references, languages)
and differs only in: title/subtitle, the professional-summary section, and
which experience sections to include. This generator captures that shared
structure once and lets a new CV variant be a ~15-line JSON entry instead
of a full file copy-paste.
