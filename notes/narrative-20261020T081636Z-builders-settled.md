# I84 parallel-test-runner — builders-settled — 20261020T081636Z

## What finished

Spec + provision + dispatch for **I84 `parallel-test-runner`** (test-rig-speed plan `notes/plan-20261020T034216Z-test-rig-speed.md` ENTRY 3 — the plan's LAST entry; repo tart @ project/pi-port, base `f07c25f`).

- Spec run `ab6659c2-af36-44ba-b186-e711c7a79448` — completed. Digest: `notes/spec-digest-20261020T081608Z-parallel-test-runner.md` (committed `c9c7c30`).
- Freeze: space.yaml iteration `parallel-test-runner` ordinal 84, `freeze_sha dc28f80583fcbf6a5fb255f152807ca6f46e0689`, verdict pending; stamp commit `99ab309`.
- Rehearsal vector: **GREEN 96 / RED 4 / BROKEN 0 / EMPTY 0** (stamp `2026-10-20T01:59:14-06:00`, `gates_digest 94b4b1753c453dd36acaabb6d011384dcb67ee7f404d0ca735c80bf668f3ac61`). Each RED verified standalone and in-rehearsal for exactly its declared reason — `parallel-units`: absent pins file; `parallel-parity`/`parallel-repeat`: rake refuses `test:par`; `scope`: absent new files. Gates total **100** (96 carried rebased + 4 new).
- Frozen lane plan: ONE lane `core`, repo tart, frozen 3-path touch set — `Rakefile` (additive-only), `test/support/parallel_runner.rb` (NEW), `test/parallel_runner_test.rb` (NEW).
- Design frozen: name-sharded subprocess fan-out (one load-only enumeration pass, 1474 `Klass#method` in 0.4 s; deterministic round-robin shards; 8 `bundle exec ruby` workers with full-form `--name` filters + recorded seeds; merged counts with per-worker attribution; `PARALLEL_OK`/`COVERAGE_OK` literals; kill-first interruption). File-level chunking rejected by measurement (`subagents_e2e_test.rb` ~95 s serial would sit on the critical path). Existence proof at base: serial **213.6 s** → parallel **51.7 s / 50.8 s**, runs/skips byte-identical (1474/5S).
- Provision: `architect provision parallel-test-runner --base f07c25f` → worktree `build/I84-parallel-test-runner-core/wt` @ `f07c25f`, branch `lane/I84-parallel-test-runner-core`.
- Lane prompt authored `tmp/i84-spec/prompt-core.md`; copied to `build/I84-parallel-test-runner-core/prompt.md`.
- **Builder spawned and confirmed running at `20261020T081636Z`**: run id `b244a4c7-9002-4f15-880a-0941004a509b` (architect-builder, cwd `build/I84-parallel-test-runner-core/wt`).

## Running now

- Builder run `b244a4c7-9002-4f15-880a-0941004a509b` in `build/I84-parallel-test-runner-core/wt` — just confirmed running at the timestamp of this narrative; no Builder Report or STATUS line yet.

## What's next

- Await the builder's Builder Report (interference audit per Law 4, red-before/after for the four declared-RED gates, lane-tree `rake test:par` walls + literals, itemize-and-defend, final `STATUS:` line), then judge with the 100-gate frozen block.
- Spec open questions handed to the judge, verbatim: (1) the chat-interrupt flake class fired once under 8-way load in the probe (declared note-and-pass for the parallel gates; rate under repeated parallel load is the one unproven leg); (2) judge-machine wall margin ~1.7× (51–52 s vs the 90 s floor); (3) the plan's post-entry follow-ups (flipping the loop's gate command to `test:par`) remain owner decisions, excluded by design.