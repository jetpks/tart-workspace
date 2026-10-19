# I80 child-encoding-hygiene — builders-settled — 2026-10-19T03:51:56Z

## What finished

Spec phase for iteration I80 `child-encoding-hygiene` (plan ENTRY 5, successor
coordinator #2) is frozen, provisioned, and dispatched. Verbatim facts:

- Iteration: I80 `child-encoding-hygiene`, lane `core`, repo tart, branch lane/I80-child-encoding-hygiene-core, base project/pi-port @ 34ba69af, worktree build/I80-child-encoding-hygiene-core/wt.
- Spec finished: frozen at freeze_sha `d3f267e2` (commit ed4991b); the ```lanes``` block was written before the first freeze (the I78 lesson held).
- Spec digest path: notes/spec-digest-20261019T035116Z-child-encoding-hygiene.md.
- Key grounding finding: the plan's hypothesis was audited and INVERTED — `Tart::ChildEnv.scrub` strips NOTHING locale-related (only bundler keys); the defect is `manager.rb child_env`'s closed pick list, which drops `LANG`/`LC_*`. The cure: 3 frozen laws (child-locale picks + UTF-8 floor; a new `Tart::UTF8Boot` boot law + one bin/tart call; binread/force/scrub artifact readers) on top of the byte-untouched, hard-frozen scrub.
- Hermetic base-RED proofs (zero live API): the direct runner path warns `JSON.generate: UTF-8 string passed as BINARY` ×2; the manager path reproduces the exact devstral failure class (`01a14df7`, `01a14e3c`) end to end.
- Rehearsal vector: GREEN 84 / RED 4 / BROKEN 0 / EMPTY 0 at base 34ba69af; the 4 declared-RED are verified for exactly their declared reason. 88 gates = 84 carried (rebased t80*/34ba69af, `-f` legs baked in) + 3 new + scope rewritten. Touch set 5 paths, effort medium, `lib/tart/child_env.rb` HARD-FROZEN.
- Lane provisioned at `--base 34ba69af` (ancestry verified: 34ba69af is not an ancestor of origin/main). Coordinator copied the lane prompt scratch (tmp/i80-spec/prompt-core.md) to build/I80-child-encoding-hygiene-core/prompt.md and appended the Builder Prompt section (arch commit 6437b98e).
- Builder spawned and confirmed RUNNING, run id fc8d5a68-6fcb-4785-a888-0df3d2e22e6c (architect-builder).

Read for this narration (quotes point at, not re-author, the child records):

- architecture/I80-child-encoding-hygiene.md — the frozen Grounds/Specification/AC; its digest-consistent audit answer is "the scrub touches exactly `BUNDLER_ORIG_*` records + the `RUBYOPT`/`RUBYLIB` belts — locale keys pass through it untouched" and the defect is `child_env`'s pick list (no `LANG`, no `LC_*`).
- notes/spec-digest-20261019T035116Z-child-encoding-hygiene.md — the digest; the verification commands actually used (base suite floor 1443 runs / 6793 asserts / 0F / 0E / 1S exit 0 + `SEAM_BENCH_OK`; ancestry check exit 1; freeze at `d3f267e2`/ed4991b; provision verified `git log -1` in the wt).
- notes/plan-20261018T1745Z-live-run-successor.md — the operator plan; ENTRY 5 is `child-encoding-hygiene` (repo tart, 1 lane).
- build/I80-child-encoding-hygiene-core/prompt.md — the builder prompt: the contract is the arch file; the three frozen Laws; the 5-path touch set; the four declared-RED gates (`child-encoding-units`, `child-encoding-e2e`, `runner-encoding-direct`, `scope`); report at build/I80-child-encoding-hygiene-core/report.md with a full 88-gate table and a final `STATUS:` line.

## Running now

- The I80 core lane builder (architect-builder, run id fc8d5a68-6fcb-4785-a888-0df3d2e22e6c), confirmed RUNNING, working in build/I80-child-encoding-hygiene-core/wt at base 34ba69af on branch lane/I80-child-encoding-hygiene-core, zero live API calls.

## What's next

- When the builder settles, read build/I80-child-encoding-hygiene-core/report.md for the suite summary, the full 88-gate table, the itemized deviations, and the final `STATUS:` line; judge runs gates at the lane tree per the standing adjudication classes.
- Carry the disclosed open question to the judge: space.yaml records `effort: high` where the frozen lanes block says `medium` — the CLI does not parse effort from the lanes block; the arch file is authority (disclosed in the digest).
- After the I80 verdict, ENTRY 6 `agent-loading-forensics` is the plan's last entry.
