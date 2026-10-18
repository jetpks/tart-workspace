# NARRATION BRIEF — kind: builders-settled — I75 signal-hygiene — 20261018T105010Z

You are architect-narrator. Write a best-effort human update to
`notes/narrative-20261018T105010Z-builders-settled.md` (space root). Do not gate
anything; do not modify any other file. Factual; quote verbatim where quoted.

## Facts (verbatim)

- Kind: builders-settled. Iteration: **I75 signal-hygiene** (ENTRY 7 — the
  FINAL planned entry of notes/plan-20261017T183001Z-tart-standalone.md; repo
  repos/tart; ONE lane `core`).
- Spec finished: run `cae6928f-0c33-4b5c-a4a1-7cd004c54fe6` (architect-spec,
  ~50 min) — I75 frozen at `architecture/I75-signal-hygiene.md`,
  **freeze_sha `92cbf63563e91fb07ca2428653d2b0f5b3051e5b`** (bookkeeping
  `7b70c4e`; space.yaml lane + rehearsal stamp recorded). BASE `b326399`.
  - Measured base floor (never predicted): pristine b326399 plain suite
    1368/6471/1F (exactly the declared env class)/241.95s; with the declared
    one-line repair 1368/6474/0F/0E/1S rake exit 0; SEAM_BENCH_OK.
  - Rehearsal vector (full frozen 76-gate set, fresh stamp): **GREEN 71 / RED 5
    / BROKEN 0 / EMPTY 0** — every RED declared and verified for the right
    reason (signal-hygiene-units runs=0 file absent; signal-orphan-e2e
    LoadError harness absent; scope pristine-base must-differ; suite the
    declared subagents hermeticity env class; render-perf-probe the BP2
    load-margin class). Carry audit AUDIT_OK (76 = 73 carried + 2 new + 1
    rewritten scope).
  - **Digest path:** `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
    (commit `cab39bc`).
- Root cause is PROVEN (Grounds F1–F9): unrouted HUP/TERM + the native
  ratatui_ruby 1.5.0 `poll_event` wedge on a dead pty + the VM-exit thread join.
  The cure: a `Tart::TUI::SignalGuard` (route HUP→129 / TERM→143 in-band, EXIT_BOUND_S
  10s) + a bounded teardown ladder + a hard exit that bypasses the wedged poller.
- Lane provisioned: ONE lane `core` — worktree
  `build/I75-signal-hygiene-core/wt` @ tart `b326399`, branch
  `lane/I75-signal-hygiene-core` (9-path touch set incl. NEW
  `test/signal_hygiene_test.rb` + NEW `test/support/signal_hygiene_harness.rb`;
  effort high).
- Builder spawned and RUNNING: run `64844552-afd7-4475-8df1-d80fb27b7efd`
  (architect-builder, model openrouter/z-ai/glm-5.3-flash:high, cwd = the lane
  worktree, timeoutMs 7200000). Lane prompt:
  `build/I75-signal-hygiene-core/prompt.md` (provenance recorded `b400dea1`).
  Task-presence verified (defect-watch): the spawn materialized WITH its task
  key.
- OPEN QUESTION flagged by the spec for the VERDICT (ratification point): the
  spec grew the touch set by ONE line over the plan's constraint list
  (`test/subagents_test.rb` — the declared hermeticity repair; the alternative
  was a deterministically unsatisfiable plain suite gate).

## Paths to read for context

- `architecture/I75-signal-hygiene.md` (§Specification; §Verdict pending)
- `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
- `build/I75-signal-hygiene-core/prompt.md`
- `notes/briefs/i75-spec-task.md`
