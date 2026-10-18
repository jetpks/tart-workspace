# REPLACEMENT SPEC TASK — I72 markdown-parity-revisit (predecessor spec TIMED OUT at 1h)

You are the REPLACEMENT architect-spec for I72. Your substantive brief remains
`notes/briefs/i72-spec-task.md` in this space repo — read it FIRST and execute
it. This file adds only the inheritance-audit instruction and the handoff
facts. You have a 2h budget (the predecessor ran out of a 1h budget in the
final rehearsal).

## FIRST TASK — audit the inherited state (do NOT redo committed work)

The predecessor run `ee5dc67c-434e-4639-abc0-6fdd1188ac20` was killed by its
3600000ms timeout while running its FINAL "fresh rehearsal for a clean stamp"
(it had already re-rehearsed after a polluted run). Before anything else,
audit and reconcile the inherited uncommitted/committed diff:

- Committed space work (execute-on, do not re-author): `80978dd` scaffold,
  `61c4df8` grounds, `0625ffa` specification, `c94c758` acceptance criteria,
  `65ff897` acceptance criteria (amend), `ea7183f` markdown-gem scope-fork note.
- `architecture/I72-markdown-parity-revisit.md` is committed through `65ff897`
  with sections Specification / Acceptance Criteria / Builder Prompt / Builder
  Report / Verdict templates.
- UNCOMMITTED `space.yaml`: a `rehearsal:` block under the I72 project record
  with `gates_digest: 8774427a72d7dfab70f24206b62008f67c0af33acac6da3cb983cf3f9abe8474`
  at `2026-10-17T20:16:49-06:00`. Verify whether this digest is the CLEAN stamp
  or the polluted one; refresh it if the clean rehearsal changes it.
- `tmp/i72-spec/` holds the working artifacts: `acceptance-criteria.md`,
  `acceptance-criteria-full.md`, `specification.md`, `gates.yaml`,
  `grounds.md`, `rehearse-1.log` (43726 B), `rehearse-2.log` (0 B — aborted),
  `base-suite.log`/`base-suite-2.log`, `micro-bench*.rb`, `guard-probe/`.
- `repos/tart` has regenerable scratch out-dirs `t72*` (t72mot, t72s1..s10,
  t72s17, t72s1t, t72tp, t72ub, t72wir, t72zwr) at tip 870e3f8 — scratch, not
  tracked; leave or clean, do not commit.

## Predecessor findings to inherit (verify, then build on)

- The suite hung ONCE on the standing `chat_test` interrupt-timing class
  (`chat_test.rb:1613` blocked in `wait_until`, SIGTERMed at 900s) — the SAME
  class that has flaked as a failure in prior sessions; the predecessor caught
  it, amended the AC preamble to name the hang form, and re-rehearsed. Its
  measured suite was green TWICE directly (~227s each). Standing law applies:
  a `chat_test` interrupt-class RED is re-run cold before adjudicating.
- At-base measured facts the predecessor recorded (re-verify at base 870e3f8
  and freeze): render-perf-probe at base `RENDER_PERF_OK` with **BP2 237.6**
  (session value) vs the standing machine regime 236.7–241.7; AC6 bench GREEN
  (`SEAM_BENCH_OK`); AC4 md-repro GREEN.

## THEN — finish the brief

Complete the clean rehearsal stamp for the full frozen gate set (66 gates),
freeze the MEASURED base floor, and emit your spec report ending with the
digest path and the rehearsal vector (per the substantive brief). Measure —
never a predicted floor. No inline long payloads in any subagent call.
