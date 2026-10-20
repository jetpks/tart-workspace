# I83 rig-sweep-parallel — builders-settled @ 20261020T063457Z

## What finished

- Spec run `7bde4e10-dcd0-42af-a4f2-dcece1d5620e` — **completed**. Iteration I83
  `rig-sweep-parallel`, plan ENTRY 2 (`notes/plan-20261020T034216Z-test-rig-speed.md`),
  repo tart @ project/pi-port, base `467b82e`.
- Freeze: space.yaml ordinal 83, freeze_sha
  `ecf3a1a6ff31cbda60dfab90ea6ac3b7d0b5a196`, verdict **pending**; stamp commit `3eec4c2`.
- Rehearsal vector at `467b82e`: **GREEN 93 / RED 4 / BROKEN 0 / EMPTY 0**
  (`build/rehearse/I83-rig-sweep-parallel-20261020T001635.387606.md`), gates_digest
  `44b9b567b9e6d24287541f638fdbeb418770de53701e5fbde14f7f5f992d91dc` @
  2026-10-20T00:16:35-06:00. Each RED verified for exactly its declared reason —
  three declared-new gates on the absent wrapper/test file; `scope` on the absent new
  files with every other leg verified clean.
- Gates: 97 total = 93 carried (rebased `t83*` era prefix, diff base `467b82e`, suite
  comment re-grounded, scope dropped/rewritten) + 4 new (`sweep-units`, `sweep-parity`,
  `sweep-crosstalk`, `scope`). `sweep-parity` freezes the base battery table
  (s1_tart=1, s11=1, s13=2, s18=1, others 0) and the ≤ 40 s concurrent wall bound
  (measured 19.05 s at 8-way).
- Spec digest committed `b0b3330`: `notes/spec-digest-20261020T063207Z-rig-sweep-parallel.md`.
- Provision: `architect provision rig-sweep-parallel --base 467b82e` → worktree
  `build/I83-rig-sweep-parallel-core/wt` @ `467b82e`, branch
  `lane/I83-rig-sweep-parallel-core`. Lane prompt authored `tmp/i83-spec/prompt-core.md`,
  copied to `build/I83-rig-sweep-parallel-core/prompt.md`.

## Running now

- ONE builder (lane `core`, effort medium; frozen 2-path touch set, both NEW:
  `gems/tui-split-rig/bin/tui-split-rig-sweep` and `gems/tui-split-rig/test/sweep_test.rb`),
  run id `ba09b18e-bc61-4376-8b5b-66101db52bc6` (architect-builder, cwd
  `build/I83-rig-sweep-parallel-core/wt`) — spawned and confirmed running at
  `20261020T063457Z`.

## What's next

- Await the builder's report (per-scenario sweep table at `--jobs 1` and default jobs,
  crosstalk gate legs + `tmux ls` evidence, red-before/after for the four declared-RED
  gates, itemize-and-defend, `STATUS:` line), then judge.

## Attention

- Spec open questions carried for the judge: concurrent wall under judge-machine load
  vs the 40 s bound; s13's ec=2 shape under N-way concurrency (root-caused to the I54
  unamended leak-era `expected_requests: 2` — owner backlog); the INT/TERM child-kill
  belt's orphan evidence; `date +%sN` portability verified on this host only.