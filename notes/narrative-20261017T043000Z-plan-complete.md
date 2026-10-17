# Plan-complete — live-render-correctness program CLOSED (2026-10-17T0430Z)

## What finished

THE LIVE-RENDER-CORRECTNESS PROGRAM IS CLOSED — both entries of
`notes/plan-20261017T005042Z-live-render-correctness.md` are done, judged
CONTINUE, integrated, torn down. No successor iteration follows.

- ENTRY 1 I65 render-correctness: CONTINUE, integrated 9db6370 on tart
  project/pi-port (landed 2026-10-17T03:02Z, before this session's resume).
- ENTRY 2 I66 viewport-polish:
  - Spec run 476e4829-0226-459d-b96d-9766090914cd (resume session —
    inherited grounds/specification verified, never rewritten; freeze_sha
    `292da329e76c75d68eadceabc42864da99a72585`). Digest:
    notes/spec-digest-20261017T033641Z.md.
  - Builder PID 95239 via `architect dispatch --detach`
    (openrouter/z-ai/glm-5.3-flash); report
    build/I66-viewport-polish-core/report.md; uncommitted 6-file
    deliverable (chat.rb, viewport.rb, theme.rb, chat_test.rb,
    theme_test.rb, NEW test/support/viewport_buffer_probe.rb).
  - Judge run 1c917390-ed15-42e3-8684-c8589e4427ed — verify 4/4, gates
    25/25 green (suite re-adjudicated on the exact frozen command after a
    900s gate-timeout), verdict CONTINUE 5/5 AC (commits c632ca3, 7140fea;
    index 7d81511).
  - Integration merge 25adab9 "Merge lane/I66-viewport-polish-core"
    (lane commit 239650d; space.yaml integrate_sha recorded; teardown done).
- The two viewport findings are cured to BRIEF §8 parity: the
  jump-to-bottom pill (pi-exact geometry, indicator-first mouse route,
  selected_bg token, shortcut segment omitted+itemized because tart has no
  bottom-binding analog) and the rail background parity + wide-grapheme
  straddle fix (span-level clip, target-bg carry, never-invented bg).
- Probe letter `c`: the two owner artifacts (inset rail, stuck-dark after
  fade) do not reproduce in-buffer at the cured tree; the instrument
  reproduces the base defect verbatim (straddle line 21 cells in a
  20-wide area) — tart-composition-homed, confirmed by elimination.
  ratatui_ruby 1.5.0 continuation-cell diff-redraw quirk recorded as an
  upstream owner note.
- Builder-report blemish (judge-recorded, no code consequence): D4/D5
  claimed two carried gates were frozen-text-defective; the judge ran
  both verbatim cold GREEN and rejected the premises.
- Completion report: notes/report-20261017T041627Z.md.

## Running now

Nothing in this program. Teardown complete; the loop has no further
planned iteration to dispatch from this plan.

## What's next

- No expected-wall stated for the program (it is closed).
- Owner residuals queued OUTSIDE this plan, unchanged:
  - fast-llm 0.4.1 release + tart re-pin.
  - Rig-oracle re-pin to repos/pi @ v1.1.0 (successor entry per the
    standing ruling).
  - The tart `main` merge decision.
  - The project/pi-port push (NOT pushed — honest-history ruling).
  - ratatui_ruby upstream note disposition.
  - Historical problems.md tick-offs.
