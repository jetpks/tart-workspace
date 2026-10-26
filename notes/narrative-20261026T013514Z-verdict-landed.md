# I88 intercom-toctou — verdict-landed — 2026-10-26T01:35Z

## What finished

The verdict landed and the cure is IN. Judge verdict (replacement run
`a7536cc2-dc86-4213-bc74-c29db0d09f9e`, ~52 min, finishing the timed-out first
judge's recorded work from intact scratch):

> `architect verdict intercom-toctou continue` — commit 38a4594 "I88: verdict"

All 6 acceptance criteria PASS (architecture/I88-intercom-toctou.md, ## Verdict):

- AC1 — whole-class audit: 8 sites enumerated, 5 racy cured, 3 itemized
  non-racy; production ENOENT-immunity re-confirmed (`supervisor.rb`
  scan_requests :327 / run_terminal? :352 / remove_request_file :436 /
  read_json :452).
- AC2 — all 5 racy sites cured per frozen semantics; toctou-amplifier ×32
  idle + ×16 steal GREEN.
- AC3 — 4 hermetic `toctou` pins, suite 1497→1501.
- AC4 — toctou-par-streak **38/38 ZERO firings judge-cold foreground**; serial
  suite 1501/10161/0F/0E/5S in **221 s ≤ 240 s judge-cold**; parallel-parity +
  parallel-repeat ×3 GREEN.
- AC5 — zero added sleep, zero production bytes.
- AC6 — tracked diff exactly `test/subagents_intercom_test.rb`.

Two reds in the battery were adjudicated note-and-pass: `s9-parity` +
`sweep-parity` = the standing declared class-(c) lane-tree-depth wrap
geometry — the judge's own cold reproductions were byte-identical to the
base-content reproduction with the lane diff removed, zero lane attribution,
and both are GREEN at canonical depth on the integrated tip. Judge ledger
111/111 adjudicated: 109 PASS + 2 note-and-pass.

The nohup finding (second firing of the I75 house note): the timed-out judge's
battery ran detached under nohup → SIGHUP=SIG_IGN inherited across exec → the
2 HUP-disposition routing pins read `"IGNORE"` → every full-suite gate in that
battery red'd with exactly `failures=2`. All tainted gates re-run foreground
at the lane tree: all GREEN. Full record:
`build/I88-intercom-toctou-core/scratch/judge-cold-adjudication.md`.

Integration is done: lane commit `df79c5f` ("lane core: I88
intercom-toctou: cure the test-side glob->read TOCTOU class (5 sites), 4
hermetic pins, N=38 bar met judge-cold") merged as `752c370` on
project/pi-port (tart — confirmed in `.git/logs/refs/heads/project/pi-port`:
`5ee64cee… 752c3701… merge lane/I88-intercom-toctou-core: Merge made by the
'ort' strategy.`); space integrate commit `8618246`; ARCHITECT.md index
updated by `ba7a567` "I88: index — CONTINUE, INTEGRATED (752c370 on
project/pi-port); plan closed". space.yaml bookkeeping reconciled in the
integrate commit. Lane branch + worktree torn down; the lane record
(prompt/report/scratch incl. the adjudication log) persists in
`build/I88-intercom-toctou-core/`.

In plain prose: the suite's hottest known loud-red — the glob→read TOCTOU
flake in the intercom tests (~3/29 judge-cold full runs at base) — is cured
test-side, measured, and off the note-and-pass list. A red on that signature
after I88 is REAL.

## Running now

Nothing in this lane. This was the last planned iteration of the
intercom-toctou plan — verdict-landed records the verdict.

## What's next

- The coordinator writes plan-complete narration + the completion report.
- Owner follow-up (your call): the cure lands on project/pi-port as its own
  small PR — `752c370` is the merge tip to PR, same posture as PR #9 /
  the standing PR-only landing discipline.
- Residual (ii) (real-user ESC pre-IO window) remains a candidate
  problems.md note / future production-hardening entry — owner's call.
- House note, twice-burned: never run gates under nohup.
