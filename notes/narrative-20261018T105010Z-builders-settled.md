# I75 signal-hygiene builders-settled 20261018T105010Z

## What finished

- Spec run `cae6928f-0c33-4b5c-a4a1-7cd004c54fe6` (architect-spec, ~50 min) froze I75 at `architecture/I75-signal-hygiene.md`, freeze_sha `92cbf63563e91fb07ca2428653d2b0f5b3051e5b` (bookkeeping `7b70c4e`; space.yaml lane + rehearsal stamp recorded).
- Base `b326399` measured floor: pristine plain suite 1368/6471/1F/241.95s; with declared one-line repair 1368/6474/0F/0E/1S rake exit 0; `SEAM_BENCH_OK`.
- Rehearsal vector (full frozen 76-gate set, fresh stamp): **GREEN 71 / RED 5 / BROKEN 0 / EMPTY 0** — every RED declared and verified for the right reason (signal-hygiene-units runs=0 file absent; signal-orphan-e2e LoadError harness absent; scope pristine-base must-differ; suite the declared subagents hermeticity env class; render-perf-probe the BP2 load-margin class). Carry audit `AUDIT_OK` (76 = 73 carried + 2 new + 1 rewritten scope).
- Root cause PROVEN (Grounds F1–F9): unrouted HUP/TERM + ratatui_ruby 1.5.0 `poll_event` wedge on dead pty + VM-exit thread join.
- Digest path: `notes/spec-digest-20261018T104858Z-signal-hygiene.md` (commit `cab39bc`).

## Running now

- Lane provisioned: ONE lane `core` — worktree `build/I75-signal-hygiene-core/wt` @ tart `b326399`, branch `lane/I75-signal-hygiene-core` (9-path touch set incl. NEW `test/signal_hygiene_test.rb` + NEW `test/support/signal_hygiene_harness.rb`; effort high).
- Builder spawned and RUNNING: run `64844552-afd7-4475-8df1-d80fb27b7efd` (architect-builder, model openrouter/z-ai/glm-5.3-flash:high, cwd = the lane worktree, timeoutMs 7200000). Lane prompt: `build/I75-signal-hygiene-core/prompt.md` (provenance recorded `b400dea1`). Task-presence verified (defect-watch): the spawn materialized WITH its task key.

## What's next

- Builder executes root-cause verification (re-verify F1–F9 at lane tree with instrument set), then implements cure: `Tart::TUI::SignalGuard` (route HUP→129 / TERM→143 in-band, EXIT_BOUND_S 10s) + bounded teardown ladder + hard exit that bypasses the wedged poller.
- OPEN QUESTION flagged for VERDICT: spec grew touch set by ONE line over plan's constraint list (`test/subagents_test.rb` — the declared hermeticity repair; alternative was deterministically unsatisfiable plain suite gate).
