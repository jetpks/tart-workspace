# I66 viewport-polish judge-settled — 2026-10-17T03:55Z

## What finished

Builder (lane core) for iteration I66 viewport-polish (plan
`notes/plan-20261017T005042Z-live-render-correctness.md` ENTRY 2) dispatched via
`architect dispatch --detach` PID 95239, model `openrouter/z-ai/glm-5.3-flash`;
process EXITED CLEANLY after writing its report at 2026-10-17T03:52:45Z.

- Builder report: `build/I66-viewport-polish-core/report.md` (read in full).
- Run log: `build/I66-viewport-polish-core/run.jsonl`.
- Builder made NO commits — deliverable is an uncommitted 6-file diff in worktree
  `build/I66-viewport-polish-core/wt` (branch `lane/I66-viewport-polish-core`,
  base `9db6370`): `lib/tart/render/chat.rb` (+115), `lib/tart/render/viewport.rb`
  (+114), `lib/tart/theme.rb` (+4), `test/chat_test.rb` (+250 additive),
  `test/theme_test.rb` (+1, the single pre-declared golden re-pin), untracked NEW
  `test/support/viewport_buffer_probe.rb`.
- Builder self-reported suite: `1205 runs, 5896 assertions, 0 failures, 0 errors,
  1 skips` (base 1192/5709); `SEAM_BENCH_OK`. All 25 gates claimed GREEN at the
  lane tree; the 4 designed-RED-at-base defect gates flip GREEN (`rail-bg`,
  `jump-pill-units` runs=7 floor>=6, `rail-bg-units` runs=6 floor>=4,
  `viewport-probe` `VIEWPORT_PROBE_OK c` exit 0).
- F4 probe verdict letter: `c` (not reproducible in-buffer at the cured tree), with
  instrument honesty: the same probe over the BASE (9db6370) overlay composition
  reproduces artifact A verbatim (straddle line width 21 in a 20-wide area,
  straddle-row glyph clipped). Artifact B absent in both drives; the
  ratatui_ruby 1.5.0 wide-char continuation-cell diff-redraw quirk recorded as an
  upstream owner note only.
- Builder-flagged judge rulings pending: D4 (carried gate `footer-window` calls
  nonexistent `Tart::Models.resolve_boot_entry` — NoMethodErrors at any tree incl.
  base; GREEN with a one-word receiver fix outside the touch set) and D5 (carried
  gate `session-golden` reads `context_messages(rec.path)` but the frozen want
  `[:user, :user]` is the forked session's roles). Both claimed base-inherited via
  the scope gate's byte-identity proof. Plus itemized deviations D1 (pill shortcut
  segment omitted — no tart analog keybinding, per spec), D2 (target-bg short-row
  fallback contract reading), D3 (new public readback `Chat#jump_pill_rect`).
- Spec digest skimmed: `notes/spec-digest-20261017T033641Z.md` — 25 gates =
  20 carried + 5 new; freeze sha `292da329e76c75d68eadceabc42864da99a72585`
  (prompt commit `292da32`).

## Running now

Judge `architect-judge` spawned and confirmed RUNNING — run id
`1c917390-ed15-42e3-8684-c8589e4427ed`, model `openrouter/z-ai/glm-5.3`, cwd the
space root. Its discipline: architect verify → evidence (transcribe the builder
report verbatim) → gate at the LANE tree → diff-vs-BRIEF read → verdict + commit.
Integration/landing is the coordinator's job after a CONTINUE.

Routing: whole run pinned openrouter-side (z.ai quota-exhausted until
2026-10-19 13:51:50).

## What's next

- Await judge run 1c917390's verdict (CONTINUE expected to route to the
  coordinator for integration/landing of the 6-file diff, including the untracked
  `test/support/viewport_buffer_probe.rb`).
- The judge owns the D4/D5 base-inherited carried-gate-text rulings and the
  D1–D3 deviation adjudication.

## Attention

- D4/D5 are live gate-text defects that fail at ANY tree including base (frozen
  carried-gate text, not this lane's code) — the judge must rule on the one-word
  fixes; they sit outside the builder's 6-file touch set.
- D6/upstream note for the owner: ratatui_ruby 1.5.0 diff redraw never repaints a
  wide grapheme's continuation cell — buffer-visible via `get_cell_at`, likely
  invisible on real hardware; recorded as an upstream owner note, no gem change
  made or proposed.