# I87 suite-deflake verdict CONTINUE — 20261025T082458Z — verdict-landed

- kind: verdict-landed
- iteration: I87 suite-deflake (repo tart, lane core)

## What finished

The judge run landed. From the verdict record:

> STATUS: judge run f8622365-9ef9-47ee-b603-bdab9595c04a COMPLETE after ~119 min — VERDICT **CONTINUE**, recorded in space.yaml; verdict prose committed in architecture/I87-suite-deflake.md.

> STATUS: per-AC rollup AC1 forensics PASS, AC2 class-(a) cured PASS, AC3 class-(f) cured PASS, AC4 measured bar PASS (one recorded adjudication), AC5 nothing-weakens PASS, AC6 scope PASS — 6/6.

The judge-cold battery: 102/107 direct PASS; all 5 REDs adjudicated note-and-pass with zero lane attribution (verbatim fact lines below, quoted from the record):

> STATUS: judge-cold battery 102/107 direct PASS; the 5 REDs each adjudicated note-and-pass: deflake-par-streak x2 (I85-declared intercom TOCTOU ENOENT residual, zero lane bytes in path, NEVER (a)/(f)), deflake-drain-streak (runner SIGTERM at the declared 900 s cap; verbatim standalone cold GREEN standalone=16 steal=8), render-perf-probe (declared class (d); judge's BASE control fails the same leg same night), s9-parity + sweep-parity (declared class (c); identical gate bytes GREEN at canonical depth).

> STATUS: THE CURE BAR IS MEASURED MET — 27 consecutive judge-cold full `rake test:par` runs with ZERO (a)/(f) firings + the builder's verbatim 16/16; frozen N=16 satisfied several-fold (at the measured base rates, 27 clean runs has probability <= 0.01%).

PHASE 0 was quiet and the spec digest's operative open questions closed:

> STATUS: PHASE 0 — zero builder disagreements; the spec digest's open questions resolved: W1 AND W2 both refuted literally (judge-read instrument dump: tasks found alive, server_requests=0, Cancel never delivered into the pre-IO-parked fiber; the defect lives in async/io-event below tart's seams); NO production change sanctioned.

The verdict prose (architecture/I87-suite-deflake.md, `## Verdict`) gives the mechanism in the judge's own words: the preserved instrument dump (`scratch/forensics/i87-forensics-14617.json`) shows `interrupt_work!` finding both tasks alive (`found=true, tasks_alive=[true,true]` at t=26.6235), then 5 s of nothing with `server_requests=0` — "the request never hit the wire, so the fiber was parked pre-IO and `Task#stop`'s cancellation was never DELIVERED". This refutes W1 (dropped-before-registration) and W2 (starved teardown) in their literal forms; the spec digest (`notes/spec-digest-20261025T0426Z-suite-deflake.md`) had posed exactly this W1-vs-W2 discrimination plus whether a production change was needed — both answered, none sanctioned.

Integration and landing are done:

> STATUS: integration — lane commit dc04d5f, merge 5ee64ce on project/pi-port; teardown done; integrated tip re-verified cold (serial 1497/10152/0F/0E/5S in 222 s <= 240 s; new pins 6/6; both cured pairs standalone green); evidence transcribed cbbeb9d; ARCHITECT.md indexed 81c7cff; verify in-bounds FAIL was purely mechanical (frozen 3-path glob cannot express the AC6-sanctioned ONE new file) — recorded --accept-bounds override, I69/I77/I80 pattern.

## Running now

Nothing in this lane. The judge run is complete; teardown done; the integrated tip is cold-verified.

## What's next

> STATUS: this was the plan's ONLY entry — NO successor iteration is planned; the coordinator proceeds to the completion report and plan-complete narration.

Carried residuals for the owner (verbatim):

> STATUS: carried residuals for the owner: (1) intercom TOCTOU ENOENT is now the suite's hottest loud-red class (~3/29 judge-cold runs; one-line rescue Errno::ENOENT cure candidate — OUTSIDE I87's frozen touch set, should headline a future deflake entry); (2) owner-facing: a real-user ESC inside the pre-IO window under load can still stick a run (async/io-event defect below tart's seams — candidate problems.md note / future production-hardening entry); (3) owner post-landing follow-ups remain: push tart project/pi-port and open the I77-I87 PR from the staged body build/land/tart-pr-body-20261024-2034.md.
