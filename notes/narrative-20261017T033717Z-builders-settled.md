# I66 viewport-polish — builders-settled — 2026-10-17T03:37Z

## What finished

Iteration I66 `viewport-polish` (plan `notes/plan-20261017T005042Z-live-render-correctness.md` ENTRY 2; ENTRY 1 = I65, already landed and integrated as `9db6370`) completed its architect phase and dispatched its builder. The spec run — RESUME session after the prior spec run died at the z.ai quota wall — landed the full chain without rewriting any inherited section:

- Spec run id: 476e4829-0226-459d-b96d-9766090914cd (architect-spec, openrouter/z-ai/glm-5.3:high). Inherited read-only sections scaffold `0e4a0b3` / grounds `cfa43fe` / specification `7117ab0` verified, never rewritten.
- Spec session chain: AC `f72bdc1` → rehearsal #1 (stamp held, no fix needed) → Builder Prompt `292da32` ("dispatched") → freeze freeze_sha `292da329e76c75d68eadceabc42864da99a72585` (bookkeeping `30f4310`) → lane integration_branch fix `db074cb` → provision → dispatch.
- Rehearsal #1 vector: GREEN 20 (suite, bench, md-repro, md-inline-units, pending-registry-units, footer-window, thinking-pins, hermeticity, lock-deps, zai-data, threads-budget, session-golden, strict-wire, error-transcript-units, error-transcript-render-units, render-perf-units, render-perf-probe, tool-pending-gate, user-bash-stream-gate, zai-max-tokens-units) / RED 5, all pre-declared (scope = owner-checkout noise; the 4 designed defect gates rail-bg, jump-pill-units, rail-bg-units, viewport-probe). Transcript: `build/rehearse/I66-viewport-polish-20261016T212847.489508.md`.
- Lane base = tart `project/pi-port` @ `9db6370`. Base suite re-derived: 1192 runs / 5709 assertions / 0 failures / 0 errors / 1 skip, rake exit 0; `SEAM_BENCH_OK`.
- Lane `core` (single lane, repo tart). Scratch brief `build/i66-core/prompt-brief.md` committed verbatim as Builder Prompt/### core. Kit `build/I66-viewport-polish-core/prompt.md` 69,056 bytes, sha256 prefix `a5d5d1c33e58c0e2`, byte-identical `prompt-src.md`.

## Running now

The builder is alive and streaming as of the digest timestamp:

- Dispatch: `env -u BUNDLE_GEMFILE architect dispatch viewport-polish core --prompt build/I66-viewport-polish-core/prompt-src.md --detach` — PID 95239, model openrouter/z-ai/glm-5.3-flash @ effort high, confirmed ALIVE AND STREAMING (run.jsonl showing thinking deltas; ps shows the pi process).
- Builder run log: `build/I66-viewport-polish-core/run.jsonl`. Expected report: `build/I66-viewport-polish-core/report.md`.
- Scope of the lane (per the frozen sections): port pi's jump-to-bottom pill (F1), fix rail-background parity + wide-grapheme straddle in `overlay_rail_cell` (F2/F3), and drive the bounded RatatuiRuby buffer/terminal probe (F4). Test-name tokens `jump_pill` (≥6) and `rail_background` (≥4) are load-bearing.
- Routing: the whole run is pinned openrouter-side (z.ai quota-exhausted until 2026-10-19 13:51:50); spec digest `notes/spec-digest-20261017T033641Z.md`.

## What's next

- Wait for the builder report at `build/I66-viewport-polish-core/report.md`, then proceed to judging/integration on lane `core` against base `9db6370`.
- Probe deliverable pending: the RatatuiRuby artifact probe's outcome letter (a/b/c) is a first-class judged deliverable still open in the running builder.

## Attention

Nothing requires the human right now. Two watch items, both already handled procedurally: the lane-level `integration_branch` was left empty by provision (the I50/I52/I56 class) and was set by hand to `project/pi-port` (space commit `db074cb`) before dispatch; and the run is pinned to openrouter until the z.ai quota window clears.