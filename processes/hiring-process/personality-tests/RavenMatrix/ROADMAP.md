# RavenMatrix — roadmap

A practice tool for Raven/Matrigma-style matrix-reasoning puzzles, built for
prepping ahead of assessments like the one from Academic Work.

## Status

- `app/` — Angular 19 (standalone components, signals, built-in `@for`/`@if`
  control flow). Builds and runs (`npm start` inside `app/`).
- Puzzle logic lives in `app/src/app/puzzle-core.ts` and is **plain
  TypeScript with zero Angular imports** — shape geometry, the four puzzle
  families (rotation, crescent, latin-square color/shape, spike-count),
  distractor generation, and SVG markup rendering all live there. The
  Angular component is a thin UI wrapper around it (signals + DOM
  sanitization only).
- Reference images from the real Matrigma test (the ones pasted into chat,
  and whatever's in the local `RavenMatrix` folder on this machine) are not
  yet in the repo — still need to be committed/pushed before they can be
  used as visual reference or embedded as an "original examples" section.

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

- [ ] Get the real Matrigma reference images into the repo (currently only
  on the local Mac, not pushed to any branch).
- [ ] Decide whether real reference images become an "original examples"
  gallery inside the app, or stay purely as design reference (the generated
  puzzles are original content, not reproductions, on purpose — avoids
  reproducing a commercial test's actual items).
- [ ] React port (see above) — not started.
- [ ] Optional: extract `puzzle-core.ts` + its CSS into a small shared
  package if/when a second UI target actually gets built, rather than
  copy-pasting.
