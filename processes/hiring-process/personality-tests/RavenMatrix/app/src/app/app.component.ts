import { Component, signal } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import {
  Difficulty,
  Family,
  LETTERS,
  Option,
  Puzzle,
  ShapeSpec,
  cellSvg,
  generatePuzzle,
} from './puzzle-core';

interface CellView {
  isQuestion: boolean;
  svg: SafeHtml | null;
}

interface OptionView {
  idx: number;
  letter: string;
  svg: SafeHtml;
  isCorrect: boolean;
  state: 'idle' | 'correct' | 'wrong';
}

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  readonly families: { key: Family | 'random'; label: string }[] = [
    { key: 'random', label: 'Slumpa' },
    { key: 'rotation', label: 'Rotation' },
    { key: 'crescent', label: 'Månskära' },
    { key: 'latin', label: 'Färg & form' },
    { key: 'spikes', label: 'Uddar' },
    { key: 'trio', label: 'Tre former' },
    { key: 'slots', label: 'Rotation & fack' },
    { key: 'fill', label: 'Byggmönster' },
    { key: 'diag', label: 'Rotera & lägg till' },
  ];
  readonly difficulties: { key: Difficulty; label: string }[] = [
    { key: 'easy', label: 'Lätt' },
    { key: 'medium', label: 'Medel' },
    { key: 'hard', label: 'Svår' },
  ];

  family = signal<Family | 'random'>('random');
  difficulty = signal<Difficulty>('medium');

  score = signal(0);
  total = signal(0);
  streak = signal(0);
  best = signal(0);
  elapsedLabel = signal('0.0s');

  cells = signal<CellView[]>([]);
  options = signal<OptionView[]>([]);
  explanation = signal('');
  answered = signal(false);
  verdictText = signal('');
  verdictOk = signal(false);

  private current: Puzzle | null = null;
  private timerId: ReturnType<typeof setInterval> | null = null;
  private startTime = 0;

  constructor(private sanitizer: DomSanitizer) {
    this.newPuzzle();
  }

  private safe(spec: ShapeSpec): SafeHtml {
    return this.sanitizer.bypassSecurityTrustHtml(cellSvg(spec));
  }

  newPuzzle(): void {
    const puzzle = generatePuzzle(this.family(), this.difficulty());
    this.current = puzzle;
    this.answered.set(false);
    this.explanation.set(puzzle.explanation);

    const cellViews: CellView[] = [];
    for (let r = 0; r < 3; r++) {
      for (let c = 0; c < 3; c++) {
        if (r === 2 && c === 2) {
          cellViews.push({ isQuestion: true, svg: null });
        } else {
          cellViews.push({ isQuestion: false, svg: this.safe(puzzle.grid[r][c]) });
        }
      }
    }
    this.cells.set(cellViews);

    this.options.set(
      puzzle.options.map((opt: Option, idx: number) => ({
        idx,
        letter: LETTERS[idx],
        svg: this.safe(opt),
        isCorrect: opt.isCorrect,
        state: 'idle' as const,
      }))
    );

    this.startTimer();
  }

  private startTimer(): void {
    this.stopTimer();
    this.startTime = Date.now();
    this.updateTimer();
    this.timerId = setInterval(() => this.updateTimer(), 200);
  }

  private stopTimer(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }

  private updateTimer(): void {
    const s = ((Date.now() - this.startTime) / 1000).toFixed(1);
    this.elapsedLabel.set(s + 's');
  }

  selectOption(idx: number): void {
    if (this.answered() || !this.current) return;
    this.answered.set(true);
    this.stopTimer();

    const chosen = this.current.options[idx];
    this.total.update((v) => v + 1);
    if (chosen.isCorrect) {
      this.score.update((v) => v + 1);
      this.streak.update((v) => v + 1);
      this.best.update((v) => Math.max(v, this.streak()));
    } else {
      this.streak.set(0);
    }

    this.options.update((opts) =>
      opts.map((o) => ({
        ...o,
        state: o.isCorrect ? 'correct' : o.idx === idx ? 'wrong' : 'idle',
      }))
    );

    this.verdictOk.set(chosen.isCorrect);
    this.verdictText.set(chosen.isCorrect ? 'Rätt!' : 'Fel svar.');
  }

  setFamily(key: Family | 'random'): void {
    this.family.set(key);
    this.newPuzzle();
  }

  setDifficulty(key: Difficulty): void {
    this.difficulty.set(key);
    this.newPuzzle();
  }
}
