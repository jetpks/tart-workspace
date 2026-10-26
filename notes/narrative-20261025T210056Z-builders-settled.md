# I88 intercom-toctou — builders-settled — 20261025T210056Z

Iteration I88 (intercom-toctou, repo tart, space 20261009-pi-port): spec is frozen and the single build lane is underway.

## What finished

**Spec, twice over.** The first spec run `04918003-2935-48e8-80be-f8eef85cdf92` hit the 30-min default timeout — the coordinator launch omitted an explicit timeoutMs (coordinator error, not a child defect). Nothing was lost: its committed sections were intact (`df4c64b` scaffold, `e13ea88` grounds, `1b3c85d` spec, `1cf733d` AC) and it had left a detached rehearsal (pid 69983) mid-flight. Per the timeout-death protocol no resume was attempted; exactly one replacement launched.

The replacement, run `43218df7-e9b2-4d01-b390-c7f8d1084067`, completed in 49m38s: it audited the inherited state, **collected the inherited detached rehearsal to completion** instead of relaunching, reconciled the vector, applied one prose-only AC preamble fix (commit `eb0d725`), and froze.

**The rehearsal.** Verdict vector GREEN 105 / RED 5 / BROKEN 1, EC=0, ~53 min wall; transcript `build/rehearse/I88-intercom-toctou-20261025T135822.386695.md`. Every non-green is declared or measured base state:
- `scope` RED — declared must-differ leg
- `toctou-pin-units` RED — declared pins-absent
- `toctou-no-widening` RED — declared audit leg (2 ParserError-only rescues at :712/:736)
- `toctou-par-streak` RED — the live class, fired run 1/38 on the exact TOCTOU signature (worker log `tmp/t88-spec/rehearse-toctou-par-streak-r1-failing-worker.log`)
- `deflake-par-streak` RED — same live class, run 6/16 (~82% base exposure, p≈0.103/16)
- `deflake-drain-streak` BROKEN — declared 900 s runner-cap artifact (standalone ×16 leg GREEN pre-cap; I87 precedent)

One prose-only AC preamble fix (commit `eb0d725`) was verified against space-architect 9.6.0 source: the rehearsal stamp binds to the gates-block digest only — block sha256 `37072190…` byte-identical, stamp stayed fresh, no re-rehearsal needed.

**Freeze.** Freeze SHA `eb0d725bae70c27d2a09549ac3e5177e46efd6df`, freeze-record commit `3daf60c`, bare `architect freeze` (no --skip-rehearse). Digest written: `notes/spec-digest-20261025T2058Z-intercom-toctou.md` (commit `1c113f0`).

**Provision + prompt.** Base re-verified immediately before provisioning — `origin/main` advanced to `c76c131` (PR #9 merge, squashed history) while `project/pi-port` stayed at `5ee64ce`; provisioned with `architect provision intercom-toctou --base 5ee64ce` → "core: ~/architect/spaces/20261009-pi-port/build/I88-intercom-toctou-core/wt (created)". The spec scratch prompt `tmp/t88-spec/prompt-core.md` was copied (bash cp) to `build/I88-intercom-toctou-core/prompt.md` (102 lines); the `architect section … prompt --append` provenance write was NOT executed — coordinator protocol forbids writing into architecture/; the build/ copy is the operative lane prompt. The frozen arch file `architecture/I88-intercom-toctou.md` carries the Grounds / Specification / AC sections plus Builder Prompt / Builder Report / Verdict stubs.

## Running now

**The builder.** Lane `core`, builder run `e5435e38-641f-4fcd-9c83-278266decbb9` — SPAWNED AND RUNNING, cwd = the lane worktree `build/I88-intercom-toctou-core/wt` at `5ee64ce`, timeout 7200000 ms, task = read `build/I88-intercom-toctou-core/prompt.md` before anything else. The prompt's contract: touch ONLY `test/subagents_intercom_test.rb`, never commit; Law 0 whole-class audit first, per-site ENOENT cure (Law 1), ≥3 hermetic `toctou` pins (Law 2), nothing weakens (Law 3, byte-frozen sentinels vs `5ee64ce`), and the measured bar (Law 4): `toctou-par-streak` = 38 standalone full `rake test:par` runs (~30 min, exceeds the 900 s runner cap by construction), `toctou-amplifier` ×32 idle + ×16 steal, serial suite ≤240 s, whole 111-gate battery green cold.

## What's next

The builder runs; when it settles, the judge is next. The 38-run standalone streak dominates the lane's wall time (~30 min on its own). This narration is never a gate on the loop.
