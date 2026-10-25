# I87 suite-deflake — builders settled — 20261025T045200Z

## What finished

- kind: builders-settled
- iteration: I87 suite-deflake (repo tart, lane core only)
- spec predecessor run b6cd62bf-b26e-45d0-a1b6-d089a630cbae timed out at its 3600000ms timeout AFTER committing scaffold→grounds→specification→AC(+FIX); replacement spec run 69feeb6d-6f35-4bca-b8de-06fbda44101b completed; nothing redone, audit-clean.
- STATUS: spec FROZEN — freeze SHA 01cfa4c597b9e84560aae8b2c59f3ad030704cce (freeze commit 6633bb8), fresh stamp, lanes recorded in space.yaml.
- STATUS: rehearsal vector GREEN 101 / RED 3 / BROKEN 3 (stamp 2026-10-24T21:18:22-06:00, transcript build/rehearse/I87-suite-deflake-20261024T211822.888979.md) — every non-green a declared base state: RED scope (declared must-differ leg), deflake-no-widening (declared :1608 belt gap), deflake-interrupt-streak (live class-(a) wedge fired standalone at iteration 6, caught loud by the gate's own 90 s watchdog); BROKEN deflake-par-streak + deflake-drain-streak (declared 900 s runner-cap artifacts, standalone-operative per AC preamble), parallel-parity (new measured fact: the belt-less class-(a) wedge hangs a whole rake test:par run; parallel-repeat x3 GREEN right after).
- STATUS: provision suite-deflake --base 40ed92b OK — lane core worktree build/I87-suite-deflake-core/wt, branch lane/I87-suite-deflake-core.
- STATUS: builder spawned and RUNNING — run e4fe6be0-e0e6-4487-84e8-1e1c244fa5f8, cwd build/I87-suite-deflake-core/wt, first task: read build/I87-suite-deflake-core/prompt.md.
- STATUS: spec digest committed — notes/spec-digest-20261025T0426Z-suite-deflake.md (space commit 9ae2a91).

## Running now

The builder (run e4fe6be0-e0e6-4487-84e8-1e1c244fa5f8) is curing flake classes (a) chat-interrupt loud-red and (f) subagents-e2e drain-timing under full parallel load on ruby 4.0.9, in the lane `core` worktree `build/I87-suite-deflake-core/wt`. Per the prompt and Laws 0–4 of the frozen contract (`architecture/I87-suite-deflake.md`): forensics first (deliberate-load reproduction with preserved failing artifacts), then the class-(a) deterministic interrupt handshake and the class-(f) arrival-order-bet removal — root cures, never widened timeouts, never added sleeps. The cure bar is a measured streak (N=16 frozen), not an assertion.

## What's next

Builder completes against the frozen 107-gate block; judge then reviews against the frozen AC. The non-green rehearsal entries are all declared base states and are not open defects.

## Attention

The class-(a) wedge fired live at base this spec session — both standalone (gate iteration 6, caught loud by the 90 s watchdog) and hanging a whole `rake test:par` run. The cure mechanisms W1 (silent no-op window) vs W2 (starved teardown) are hypotheses; the builder's forensics decide. If the cure bar's N=16 streak cannot be measured because the reproduction rate is too low, that is a judge-facing deviation to flag, not something to paper over.
