# RavenMatrix — roadmap

A practice tool for Raven/Matrigma-style matrix-reasoning puzzles, built for
prepping ahead of assessments like the one from Academic Work.

## Status

- `app/` — Angular 19 (standalone components, signals, built-in `@for`/`@if`
  control flow). Builds and runs (`npm start` inside `app/`).
- Puzzle logic lives in `app/src/app/puzzle-core.ts` and is **plain
  TypeScript with zero Angular imports** — shape geometry, all puzzle
  families, distractor generation, and SVG markup rendering all live there.
  The Angular component is a thin UI wrapper around it (signals + DOM
  sanitization only).
- Difficulty is handled at two levels: each generator function takes a
  `Difficulty` ('easy'/'medium'/'hard') and some use it to scale numeric
  parameters (rotation step size, counts, row offsets); on top of that the
  UI adds two difficulty *modes* that work regardless of per-family support
  — "Slumpa nivå" (random tier each puzzle) and "Adaptiv" (starts at easy,
  one correct answer climbs a tier, one wrong answer drops a tier).
- Real reference images (from the real Matrigma/Test The Talent Sverige
  test) are deliberately **not** in this repo or app — see "Copyright
  decision" below. They briefly ended up committed via an unrelated file
  cleanup and were untracked again; see `.gitignore` for the excluded path.

## Puzzle families

Each family's generator lives in `puzzle-core.ts` (`gen<Name>`). "Diff?"
says whether the `Difficulty` param actually changes anything for that
family today — a "no" doesn't mean the puzzle is always the same difficulty,
just that it's a fixed inherent complexity rather than tunable.

| Family | UI label | Inspired by | Diff? |
|---|---|---|---|
| `rotation` | Rotation | pasted example (irregular shape rotating) | yes |
| `crescent` | Månskära | pasted example (moon thickness/lean) | yes |
| `latin` | Färg & form | pasted example (pentagon/heart/diamond, black/gray/white) | no |
| `spikes` | Uddar | pasted example (star with growing spike count) | yes |
| `trio` | Tre former | described in words (rotate + slide + on/off) | yes |
| `slots` | Rotation & fack | described in words (rotate left + 3 fixed slots) | yes |
| `fill` | Byggmönster | described in words (6-slot template fills/empties) | partial (row-shift only) |
| `diag` | Rotera & lägg till | pasted example (3×3 rotate-whole-pattern + accrete) | no |
| `axis` | Ram & symbol | two pasted examples (container↔row, symbol↔column) | no |
| `quadrant` | Hörnzoner | 5 pasted examples (crosshair grid, triangle↔row corner, circle↔column corner) | no |

Follow-up worth doing: `latin`, `diag`, `axis`, and `quadrant` are
combinatorial/discrete rules (a Latin square, a fixed rotate-and-add
sequence, independent axis bindings) rather than magnitude-based ones, so
"harder" doesn't mean "bigger number" for them the way it does for rotation
degrees or spike counts. If they need real difficulty tiers, that likely
means something qualitatively different per tier (e.g. more
visually-similar distractor shapes for hard, or combining `axis`/`quadrant`
with a `latin`-style permutation on one axis for hard) rather than scaling
an existing parameter — not started.

## Copyright decision (see issue #4)

Real Matrigma/Raven test images (whether the actual commercial test or a
test-prep company's own mock version, e.g. testthetalent.se) are not
committed to this repo or embedded in the app, tweaked or not — modifying
an image doesn't change whose copyrighted content it derives from. Real
images may be used privately (viewed in chat, kept outside the repo) purely
as inspiration for identifying new puzzle *mechanisms*, which then get
implemented as original, algorithmically-generated content here — every
family above followed that path.

## Planned: one core, multiple UI targets

Because `puzzle-core.ts` has no framework dependency, it should be
extractable as-is into a shared package (or just copy-pasted, given its
size) and reused by a React version later, instead of reimplementing the
puzzle rules a second time. Concretely, when a React version is wanted:

1. Copy `puzzle-core.ts` unchanged (it's plain TS — works in any bundler).
2. Write a thin React wrapper: state via `useState`/`useReducer` in place of
   Angular signals, shape markup injected via `dangerouslySetInnerHTML`
   (mirrors the Angular `[innerHTML]` + `DomSanitizer` approach) in place of
   `[innerHTML]`.
3. Reuse the same CSS (it's plain custom-property-based CSS, not
   Angular-specific — only the `::ng-deep` selectors for piercing into the
   injected SVG markup would need to become plain global selectors).

If a third target ever comes up (e.g. a static Artifact/demo build), the
same split applies: core stays put, only the UI shell changes.

## Open items

- [ ] React port (see "Planned: one core, multiple UI targets" above) —
  not started.
- [ ] Data-driven pusseldefinitioner (markdown/config istället för
  hårdkodade generatorfunktioner) — see issue #8, not started.
- [ ] Real difficulty tiers for `latin`/`diag`/`axis` — see table above,
  not started.
- [ ] More organic patterns spotted in pasted examples but not yet built:
  a line-stroke composition/overlay family (shapes combined via
  boolean-style rules), and a dot-cluster arrow/chevron family — both
  more complex to generalize cleanly than the families above.
- [ ] Optional: extract `puzzle-core.ts` + its CSS into a small shared
  package if/when a second UI target actually gets built, rather than
  copy-pasting.
