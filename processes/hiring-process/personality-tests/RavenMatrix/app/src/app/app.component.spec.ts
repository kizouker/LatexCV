import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';

describe('AppComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AppComponent],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render the title', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('RavenMatrix');
  });

  it('should start with a generated puzzle and six options', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const app = fixture.componentInstance;
    expect(app.cells().length).toBe(9);
    expect(app.options().length).toBe(6);
  });

  it('should score a correct answer and disable further picks', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    const app = fixture.componentInstance;
    const correctIdx = app.options().find((o) => o.isCorrect)!.idx;
    app.selectOption(correctIdx);
    expect(app.score()).toBe(1);
    expect(app.total()).toBe(1);
    expect(app.answered()).toBeTrue();
  });
});
