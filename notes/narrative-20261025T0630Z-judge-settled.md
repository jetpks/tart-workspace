# I87 suite-deflake — judge settled / builder COMPLETE, judge RUNNING — 2026-10-25T06:30Z

kind: judge-settled
iteration: I87 suite-deflake (repo tart, lane core)

## What finished

The I87 `core` builder run finished COMPLETE after ~115 min:

- STATUS: builder run e4fe6be0-e0e6-4487-84e8-1e1c244fa5f8 COMPLETE after ~115 min — forensics-before-fix both flake classes; cures strictly test-side (ESC gated on captured request AND 3 chunks rendered; stream 40→80 chars at the frozen 0.1 s/char pace; I82 Law-4 belt on the :1608 test; additive `match:` content-routing in mock_llm_server.rb; legs B/E2 order-independent; 6 hermetic pins in one sanctioned new file — suite 1491→1497 runs).

What the builder claims it cured (per build/I87-suite-deflake-core/report.md):

- **Class (a)** — chat-interrupt loud-red: forensics (instrumented in-suite firing at cycle 5 of 11 pre-cure cycles) refuted both prior Grounds hypotheses; the instrument dump shows `interrupt_work!` found both tasks alive and called `Task#stop` on each, but the cancellation was never delivered into the agent fiber, which was parked pre-IO with `server.request_count=0` (the mock server never received the request). Cure: the ESC test now gates on a captured request AND 3 chunks rendered, plus an I82 Law-4 belt on the `:1608` twin test.
- **Class (f)** — pair inversion: reproduced by a reduced-context forced-order driver against the base `mock_llm_server.rb` bytes firing the exact signature (sanctioned by spec Law 0); cure is additive `match:` content-routing in `mock_llm_server.rb`, plus stream 40→80 chars at the frozen 0.1 s/char pace, and legs B/E2 made order-independent.
- Suite grew 1491→1497 via exactly the one sanctioned new file, `test/support/mock_llm_match_test.rb` (6 hermetic pins).

Scope discipline, per report PHASE 0 declarations: NONE — zero production bytes, no frozen sentinel moved, no sleep added, no test renamed/deleted/weakened/timeout-raised. Three gate rows are the carried declared classes (c)/(d) riding note-and-pass with mechanical attribution.

## Running now

The judge is spawned and running:

- STATUS: judge spawned and RUNNING — run f8622365-9ef9-47ee-b603-bdab9595c04a, cwd the space root, tasked to judge I87 suite-deflake by id, gates cold at the lane tree, itemize-and-defend every gate and edit; verdict decides CONTINUE vs KILL.

The judge judges by id (cold re-run of gates at the lane tree), so it does not inherit the builder's measured-bar numbers — its cold re-run is now the arbiter of whether the cures hold.

## What's next

- STATUS: measured cure bar 16/16 full `rake test:par` runs with ZERO (a)/(f) firings (664 s); interrupt amplifier x16 + x8 CPU-steal green; drain amplifier x16 + x8 CPU-steal green; serial suite 1497/0F/0E/5S in 221 s (bound 240 s); 107-gate battery with a measured row each — 104 PASS + 3 declared note-and-pass rows ((c)/(d) carried, mechanically attributed).

Why the bar is measured, not asserted: the class-(a) cure was validated by 16 consecutive full parallel-suite runs with zero firings (664 s each), under both an x16 interrupt amplifier and an x8 CPU-steal amplifier; the class-(f) cure the same way via the drain amplifier; the serial suite landed 221 s against a 240 s bound; and all 107 frozen gates have a measured row (104 PASS, 3 declared carried note-and-pass). The builder's forensics artifacts are preserved in the lane scratch (`scratch/forensics/`: worker log, two instrument JSON dumps, pristine base mock-server copy).

- STATUS: no frozen bytes, no production bytes, no sleeps, no commits (builders-never-commit verified: `git log 40ed92b..` empty); tracked diff 3 test files; untracked t87* scratch per the I87 scope era prefix.

- STATUS: builder report at build/I87-suite-deflake-core/report.md (judge transcribes via `architect evidence`).

Next human-visible event: the judge run's CONTINUE-vs-KILL verdict for I87 suite-deflake.
