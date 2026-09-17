// Framework-agnostic matrix-reasoning puzzle engine (plain TypeScript, no Angular imports).
// Intended to be reused as-is by any UI layer (Angular now, React later — see ROADMAP.md).

export type Family = 'rotation' | 'crescent' | 'latin' | 'spikes' | 'trio';
export type Difficulty = 'easy' | 'medium' | 'hard';

export interface BlobPoint {
  angle: number;
  radius: number;
}

export interface ShapeSpec {
  family: Family;
  blob?: BlobPoint[];
  rot?: number;
  mirror?: boolean;
  ratio?: number;
  shape?: number;
  tone?: number;
  n?: number;
  innerR?: number;
  triRot?: number;
  dotT?: number;
  extraOn?: boolean;
}

export interface Option extends ShapeSpec {
  isCorrect: boolean;
}

export interface Puzzle {
  grid: ShapeSpec[][];
  explanation: string;
  options: Option[];
}

interface GenResult {
  grid: ShapeSpec[][];
  correct: ShapeSpec;
  distractors: ShapeSpec[];
  explanation: string;
}

export const FAMILIES: Family[] = ['rotation', 'crescent', 'latin', 'spikes', 'trio'];
export const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];

function shuffle<T>(arr: T[]): T[] {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function pickDistractors<T>(correctKey: string, candidates: T[], keyFn: (t: T) => string, count: number): T[] {
  const seen = new Set([correctKey]);
  const result: T[] = [];
  for (const c of candidates) {
    const k = keyFn(c);
    if (!seen.has(k)) {
      seen.add(k);
      result.push(c);
    }
    if (result.length >= count) break;
  }
  let i = 0;
  while (result.length < count && candidates.length) {
    result.push(candidates[i % candidates.length]);
    i++;
  }
  return result.slice(0, count);
}

// ---------- shape geometry ----------

function polygonPoints(cx: number, cy: number, r: number, sides: number, rotDeg: number): [number, number][] {
  const pts: [number, number][] = [];
  for (let i = 0; i < sides; i++) {
    const a = ((rotDeg + (i * 360) / sides) * Math.PI) / 180;
    pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
  }
  return pts;
}

function pointsToPath(pts: [number, number][]): string {
  return pts.map((p, i) => (i === 0 ? 'M' : 'L') + p[0].toFixed(2) + ',' + p[1].toFixed(2)).join(' ') + ' Z';
}

function makeBlobSpec(n: number): BlobPoint[] {
  const pts: BlobPoint[] = [];
  const step = 360 / n;
  for (let i = 0; i < n; i++) {
    const angle = i * step + (Math.random() * 0.4 - 0.2) * step;
    const radius = 24 + Math.random() * 16;
    pts.push({ angle, radius });
  }
  return pts;
}

function blobPath(spec: BlobPoint[], cx: number, cy: number, rotDeg: number, scale: number, mirror?: boolean): string {
  const pts: [number, number][] = spec.map((p) => {
    const a = ((p.angle + rotDeg) * Math.PI) / 180;
    let x = cx + p.radius * scale * Math.cos(a);
    const y = cy + p.radius * scale * Math.sin(a);
    if (mirror) x = 2 * cx - x;
    return [x, y];
  });
  return pointsToPath(pts);
}

function crescentPath(cx: number, cy: number, R: number, ratio: number): string {
  const r2 = R * ratio;
  return `M ${cx} ${(cy - R).toFixed(2)} A ${R} ${R} 0 1 1 ${cx} ${(cy + R).toFixed(2)} A ${r2.toFixed(2)} ${r2.toFixed(2)} 0 0 0 ${cx} ${(cy - R).toFixed(2)} Z`;
}

function heartPath(cx: number, cy: number, r: number): string {
  const cy0 = cy - 0.65 * r;
  const p = (dx: number, dy: number) => `${(cx + dx * r).toFixed(2)},${(cy0 + dy * r).toFixed(2)}`;
  return `M ${p(0, 0.3)} C ${p(-0.5, -0.3)} ${p(-1, 0.1)} ${p(-1, 0.5)} C ${p(-1, 0.9)} ${p(-0.6, 1.1)} ${p(0, 1.6)} C ${p(0.6, 1.1)} ${p(1, 0.9)} ${p(1, 0.5)} C ${p(1, 0.1)} ${p(0.5, -0.3)} ${p(0, 0.3)} Z`;
}

function spikePath(cx: number, cy: number, outerR: number, innerR: number, n: number): string {
  const pts: [number, number][] = [];
  for (let i = 0; i < n * 2; i++) {
    const r = i % 2 === 0 ? outerR : innerR;
    const a = ((-90 + (i * 180) / n) * Math.PI) / 180;
    pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]);
  }
  return pointsToPath(pts);
}

// ---------- puzzle generators ----------

function genRotation(diff: Difficulty): GenResult {
  const blob = makeBlobSpec(7);
  const deltaCol = diff === 'easy' ? 80 : diff === 'medium' ? 55 : 34;
  const deltaRow = diff === 'easy' ? 0 : diff === 'medium' ? 18 : 14;
  const baseRot = Math.floor(Math.random() * 360);
  const grid: ShapeSpec[][] = [];
  for (let r = 0; r < 3; r++) {
    const row: ShapeSpec[] = [];
    for (let c = 0; c < 3; c++) {
      row.push({ family: 'rotation', blob, rot: ((baseRot + c * deltaCol + r * deltaRow) % 360 + 360) % 360, mirror: false });
    }
    grid.push(row);
  }
  const correct = grid[2][2];
  const mk = (rotOffset: number, mir?: boolean): ShapeSpec => ({
    family: 'rotation',
    blob,
    rot: ((correct.rot! + rotOffset) % 360 + 360) % 360,
    mirror: !!mir,
  });
  const candidates = [mk(deltaCol), mk(-deltaCol), mk(deltaRow || 30), mk(-(deltaRow || 30)), mk(180), mk(90), mk(45), mk(0, true)];
  const keyFn = (s: ShapeSpec) => `${Math.round(s.rot!)}-${s.mirror}`;
  const distractors = pickDistractors(keyFn(correct), candidates, keyFn, 5);
  const explanation = deltaRow
    ? `Figuren roterar ${deltaCol}° för varje kolumn och ${deltaRow}° för varje rad.`
    : `Figuren roterar ${deltaCol}° för varje steg åt höger.`;
  return { grid, correct, distractors, explanation };
}

function genCrescent(diff: Difficulty): GenResult {
  const deltaRatio = diff === 'easy' ? 0.28 : diff === 'medium' ? 0.2 : 0.13;
  const deltaRot = diff === 'easy' ? 0 : diff === 'medium' ? 25 : 35;
  const baseRatio = 0.35 + Math.random() * 0.15;
  const baseRot = Math.floor(Math.random() * 360);
  const grid: ShapeSpec[][] = [];
  for (let r = 0; r < 3; r++) {
    const row: ShapeSpec[] = [];
    for (let c = 0; c < 3; c++) {
      const ratio = Math.min(0.92, baseRatio + c * deltaRatio);
      const rot = ((baseRot + r * deltaRot) % 360 + 360) % 360;
      row.push({ family: 'crescent', ratio: +ratio.toFixed(3), rot });
    }
    grid.push(row);
  }
  const correct = grid[2][2];
  const mk = (ratioOffset: number, rotOffset: number): ShapeSpec => ({
    family: 'crescent',
    ratio: Math.max(0.15, Math.min(0.95, correct.ratio! + ratioOffset)),
    rot: ((correct.rot! + rotOffset) % 360 + 360) % 360,
  });
  const r0 = deltaRot || 40;
  const candidates = [mk(deltaRatio, 0), mk(-deltaRatio, 0), mk(0, r0), mk(0, -r0), mk(deltaRatio, r0), mk(-deltaRatio, -r0), mk(0.3, 0), mk(-0.15, 0)];
  const keyFn = (s: ShapeSpec) => `${s.ratio!.toFixed(2)}-${Math.round(s.rot!)}`;
  const distractors = pickDistractors(keyFn(correct), candidates, keyFn, 5);
  const explanation = deltaRot
    ? `Månskäran blir tunnare för varje kolumn och lutar ${deltaRot}° mer för varje rad.`
    : `Månskäran blir tunnare för varje kolumn åt höger.`;
  return { grid, correct, distractors, explanation };
}

function genLatin(_diff: Difficulty): GenResult {
  const shapeOffset = Math.floor(Math.random() * 3);
  const colorMult = Math.random() < 0.5 ? 1 : 2;
  const colorOffset = Math.floor(Math.random() * 3);
  const grid: ShapeSpec[][] = [];
  for (let r = 0; r < 3; r++) {
    const row: ShapeSpec[] = [];
    for (let c = 0; c < 3; c++) {
      const shape = (r + c + shapeOffset) % 3;
      const tone = (r + colorMult * c + colorOffset) % 3;
      row.push({ family: 'latin', shape, tone });
    }
    grid.push(row);
  }
  const correct = grid[2][2];
  const candidates: ShapeSpec[] = [];
  for (let s = 0; s < 3; s++) {
    for (let t = 0; t < 3; t++) {
      if (s === correct.shape && t === correct.tone) continue;
      candidates.push({ family: 'latin', shape: s, tone: t });
    }
  }
  shuffle(candidates);
  const keyFn = (s: ShapeSpec) => `${s.shape}-${s.tone}`;
  const distractors = pickDistractors(keyFn(correct), candidates, keyFn, 5);
  const explanation = `Varje rad och kolumn innehåller alla tre formerna och alla tre färgtonerna exakt en gång (ett latinskt kvadrat-mönster).`;
  return { grid, correct, distractors, explanation };
}

function genSpikes(diff: Difficulty): GenResult {
  const deltaN = diff === 'easy' ? 2 : 1;
  const baseN = diff === 'easy' ? 3 : 4;
  const grid: ShapeSpec[][] = [];
  for (let r = 0; r < 3; r++) {
    const row: ShapeSpec[] = [];
    for (let c = 0; c < 3; c++) {
      row.push({ family: 'spikes', n: baseN + c * deltaN, innerR: 17 });
    }
    grid.push(row);
  }
  const correct = grid[2][2];
  const mk = (nOffset: number): ShapeSpec => ({ family: 'spikes', n: Math.max(3, correct.n! + nOffset), innerR: 17 });
  const candidates = [mk(deltaN), mk(-deltaN), mk(deltaN * 2), mk(-deltaN * 2), mk(1), mk(-1), mk(3), mk(-3)];
  const keyFn = (s: ShapeSpec) => `${s.n}`;
  const distractors = pickDistractors(keyFn(correct), candidates, keyFn, 5);
  const explanation = `Antalet uddar ökar med ${deltaN} för varje kolumn, likadant på varje rad.`;
  return { grid, correct, distractors, explanation };
}

function genTrio(diff: Difficulty): GenResult {
  // A regular (equilateral) triangle has 3-fold rotational symmetry, so any
  // rotation step that is a nice fraction of 120° makes some columns render
  // identically. Use an irregular 3-point blob instead (same trick as
  // genRotation), which has no rotational symmetry at all.
  const blob = makeBlobSpec(3);
  const deltaTriCol = diff === 'easy' ? 90 : diff === 'medium' ? 60 : 40;
  const deltaTriRow = diff === 'easy' ? 0 : diff === 'medium' ? 20 : 15;
  const baseTri = Math.floor(Math.random() * 360);
  const dotStep = 0.5; // col 0/1/2 -> t = 0 / 0.5 / 1, same path for every row
  const grid: ShapeSpec[][] = [];
  for (let r = 0; r < 3; r++) {
    const row: ShapeSpec[] = [];
    for (let c = 0; c < 3; c++) {
      row.push({
        family: 'trio',
        blob,
        triRot: ((baseTri + c * deltaTriCol + r * deltaTriRow) % 360 + 360) % 360,
        dotT: c * dotStep,
        extraOn: (r + c) % 2 === 0,
      });
    }
    grid.push(row);
  }
  const correct = grid[2][2];
  const mk = (triOffset: number, dotOffset: number, flipExtra: boolean): ShapeSpec => ({
    family: 'trio',
    blob,
    triRot: ((correct.triRot! + triOffset) % 360 + 360) % 360,
    dotT: Math.max(0, Math.min(1, correct.dotT! + dotOffset)),
    extraOn: flipExtra ? !correct.extraOn : correct.extraOn,
  });
  const t0 = deltaTriRow || 30;
  const candidates = [
    mk(deltaTriCol, 0, false),
    mk(-deltaTriCol, 0, false),
    mk(t0, 0, false),
    mk(0, -dotStep, false),
    mk(0, dotStep, false),
    mk(0, 0, true),
    mk(180, 0, false),
    mk(deltaTriCol, dotStep, true),
  ];
  const keyFn = (s: ShapeSpec) => `${Math.round(s.triRot!)}-${s.dotT!.toFixed(2)}-${s.extraOn}`;
  const distractors = pickDistractors(keyFn(correct), candidates, keyFn, 5);
  const explanation = deltaTriRow
    ? `Triangeln roterar ${deltaTriCol}° per kolumn och ${deltaTriRow}° per rad, punkten flyttar sig längre längs sin diagonal ju längre åt höger du kommer, och den lilla kvadraten syns bara när rad + kolumn är jämnt (ett schackrutemönster).`
    : `Triangeln roterar ${deltaTriCol}° per kolumn, punkten flyttar sig längre längs sin diagonal ju längre åt höger du kommer, och den lilla kvadraten syns bara när rad + kolumn är jämnt (ett schackrutemönster).`;
  return { grid, correct, distractors, explanation };
}

const GENERATORS: Record<Family, (diff: Difficulty) => GenResult> = {
  rotation: genRotation,
  crescent: genCrescent,
  latin: genLatin,
  spikes: genSpikes,
  trio: genTrio,
};

export function generatePuzzle(family: Family | 'random', difficulty: Difficulty): Puzzle {
  const fam = family === 'random' ? FAMILIES[Math.floor(Math.random() * FAMILIES.length)] : family;
  const gen = GENERATORS[fam](difficulty);
  const options = shuffle<Option>([
    { ...gen.correct, isCorrect: true },
    ...gen.distractors.map((d) => ({ ...d, isCorrect: false })),
  ]);
  return { grid: gen.grid, explanation: gen.explanation, options };
}

// ---------- SVG rendering (returns raw markup string, UI layer decides how to inject it) ----------

export function shapeMarkup(spec: ShapeSpec): string {
  switch (spec.family) {
    case 'rotation':
      return `<path class="outline-shape" d="${blobPath(spec.blob!, 50, 50, spec.rot!, 1, spec.mirror)}" />`;
    case 'crescent':
      return `<path class="outline-shape" d="${crescentPath(50, 50, 26, spec.ratio!)}" transform="rotate(${spec.rot} 50 50)" />`;
    case 'spikes':
      return `<path class="outline-shape" d="${spikePath(50, 50, 34, spec.innerR!, spec.n!)}" />`;
    case 'latin': {
      const toneClass = spec.tone === 0 ? 'tone-dark' : spec.tone === 1 ? 'tone-mid' : 'tone-light';
      let d: string;
      if (spec.shape === 0) d = pointsToPath(polygonPoints(50, 50, 30, 5, -90));
      else if (spec.shape === 1) d = heartPath(50, 42, 26);
      else d = pointsToPath([[50, 20], [80, 50], [50, 80], [20, 50]]);
      return `<path class="latin-shape ${toneClass}" d="${d}" />`;
    }
    case 'trio': {
      const triD = blobPath(spec.blob!, 50, 28, spec.triRot!, 0.45);
      const dotX0 = 20, dotY0 = 55, dotX1 = 80, dotY1 = 85;
      const t = spec.dotT!;
      const dotX = dotX0 + (dotX1 - dotX0) * t;
      const dotY = dotY0 + (dotY1 - dotY0) * t;
      const sq = 78, sqY = 20, half = 7;
      const squareD = pointsToPath([
        [sq - half, sqY - half],
        [sq + half, sqY - half],
        [sq + half, sqY + half],
        [sq - half, sqY + half],
      ]);
      const squareMarkup = spec.extraOn ? `<path class="outline-shape" d="${squareD}" />` : '';
      return `<path class="outline-shape" d="${triD}" /><circle class="trio-dot" cx="${dotX.toFixed(2)}" cy="${dotY.toFixed(2)}" r="5" />${squareMarkup}`;
    }
    default:
      return '';
  }
}

export function cellSvg(spec: ShapeSpec): string {
  return `<svg viewBox="0 0 100 100" class="cell-svg" aria-hidden="true">${shapeMarkup(spec)}</svg>`;
}
