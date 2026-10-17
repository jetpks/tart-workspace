# I66 verdict-landed — viewport-polish CONTINUE, last plan iteration closes the program

## What finished

Iteration I66 viewport-polish — ENTRY 2 (the last planned entry) of
`notes/plan-20261017T005042Z-live-render-correctness.md` — judged and
integrated. The program is closing; no successor iteration follows.

- Judge: run id `1c917390-ed15-42e3-8684-c8589e4427ed` (architect-judge,
  openrouter/z-ai/glm-5.3). `architect verify viewport-polish` 4/4 PASS
  (frozen untouched, no builder commits, report exists, in-bounds).
  `architect gate viewport-polish core` cold at the LANE tree: 24/25 PASS
  verbatim; `suite` hit a 900s gate-timeout under battery load and was
  re-adjudicated by running the exact frozen command standalone — exit 0,
  SUITE_OK, 1205 runs / 5896 assertions / 0 failures / 0 errors / 1 standing
  skip in 2m56s (floor ≥1192 met).
- Verdict: **CONTINUE** — 5/5 AC PASS. Decisive reason (verbatim): "the diff
  is faithful to the frozen Specification at every seam read (span-level
  straddle-safe clip, pi-exact pill geometry and indicator-first route, the
  one theme token), the cold battery is 25/25 with the suite re-adjudicated
  green on the exact frozen command, and the probe's first-class letter `c`
  is honest with its correspondence independently reproduced — the two
  live-run viewport findings are cured to BRIEF §8 parity."
- Deviation rulings: D1 (shortcut segment omitted — no tart analog binding),
  D2 (target-bg short-row fallback), D3 (Chat#jump_pill_rect readback), D6
  (probe letter c) — ACCEPT. D4/D5 — REJECTED, premises false: the frozen
  commands already read `Tart::Executable.resolve_boot_entry` and
  `context_messages(forked.path)`; both ran verbatim cold GREEN
  (`FOOTER_WINDOW_OK 1000000`, `SESSION_GOLDEN_OK` 7/7 digests); the builder
  misread a nested call — a report-accuracy blemish, no code consequence,
  recorded in the verdict.
- Probe (AC3): letter `c` — the two owner artifacts (inset rail, stuck-dark
  after fade) do not reproduce in-buffer at the cured tree; the judge
  INDEPENDENTLY reproduced the instrument-honesty correspondence (same probe
  over the verbatim BASE composition: straddle line 21 cells in a 20-wide
  area; cured tree exactly 20) — artifacts were tart-composition-homed,
  F2/F3 cures eliminate exactly them. ratatui_ruby 1.5.0 wide-grapheme
  continuation-cell diff-redraw quirk carried as an upstream owner note.
- Integration: `architect integrate viewport-polish --lanes core` → lane
  commit `239650d` "lane core: integrate", merge **`25adab9`** "Merge
  lane/I66-viewport-polish-core" on tart project/pi-port (space.yaml
  integrate_sha `239650d…`, records d77c27d + 1f5c58c). Teardown done
  (worktree removed, lane branch deleted). Canonical checkout spot-verified:
  theme selected_bg `#213b49`, Viewport#following?/#scroll_to_end,
  Chat#jump_pill_rect, test/support/viewport_buffer_probe.rb present; the
  owner's intentional uncommitted diff untouched.
- Space commits this iteration: verdict `c632ca3` + `7140fea`; index
  `7d81511`; digest notes/spec-digest-20261017T033641Z.md (`05e3b0e`).

## Running now

Nothing in this lane. Teardown complete; the loop has no further planned
iteration to dispatch from this plan.

## What's next

- Program closure bookkeeping for plan
  `notes/plan-20261017T005042Z-live-render-correctness.md` (both entries
  landed: I65 earlier, I66 now).
- Owner residuals queued outside this plan (unchanged): fast-llm 0.4.1
  release + tart re-pin; rig-oracle re-pin to repos/pi @ v1.1.0 (the
  standing ruling's successor entry); the tart `main` merge decision;
  ratatui_ruby upstream note disposition.
- NOT pushed — the tart project/pi-port push stays an owner residual
  (honest-history ruling).
