# Spec digest — I87 suite-deflake (cure flake classes (a)/(f) at the root)

UTC 2026-10-25T0426Z (session date 2026-10-24 local). Spec COMPLETE and
FROZEN. Facts only — the handoff for the next spec.

## State (verified this session)

- Iteration `suite-deflake` (I87), ONE lane `core` (repo tart, frozen
  3-file touch set + at most ONE new `test/support/[a-z0-9_]+\.rb`).
  Base tip `40ed92b` (the I85 integration merge; tracked-clean;
  `git -C repos/tart merge-base --is-ancestor 40ed92b origin/main` →
  exit 1, so provision needs `--base 40ed92b` — re-verify immediately
  before dispatch).
- Space commits this run: scaffold `464c4d1` → grounds `29adce0` →
  specification `8f8895c` → AC `0390bc8` → **AC FIX** `01cfa4c` (see
  defect 1) → freeze `6633bb8`. **freeze_sha =
  `01cfa4c597b9e84560aae8b2c59f3ad030704cce`** (the AC-FIX commit; the
  frozen region's last touch); space.yaml lanes recorded at freeze (lane
  `core`, the 3-file touch set); rehearsal stamp digest `76ab9400…`
  at `2026-10-24T21:18:22-06:00`.
- NOTE: this spec ran as a REPLACEMENT run — the predecessor died at its
  1h timeout with the detached rehearsal mid-flight. The replacement
  audited the inherited state (5 commits, gates byte-match re-verified),
  collected the live rehearsal (never relaunched), froze, and wrote this
  digest. Nothing committed by the predecessor was redone.
- Arch file `architecture/I87-suite-deflake.md`: Grounds /
  Specification / AC + 107-gate frozen ```gates block (102 carried
  byte-audited from the I85 ARCH FILE + scope rewrite + 4 new:
  `deflake-par-streak`, `deflake-interrupt-streak`,
  `deflake-drain-streak`, `deflake-no-widening`).
- Scratch: `tmp/t87-spec/` — grounds.md, specification.md,
  acceptance-criteria-head.md, acceptance-criteria.md (assembled),
  gates-i85-extracted.yaml (102+scope extraction), rebase.rb (the carry
  audit), gates-carried-rebased.yaml (102), gates-new.yaml (5: scope + 4),
  gates-final.yaml (107, the stamped bytes), probe-*.sh (the 5 new-gate
  bodies as probed), base-par-{1..5}.log + base-par-summary.txt +
  base-par-{1,5}-failing-worker.log (the base fire-rate sample WITH the
  failing worker logs preserved), prompt-core.md (the lane prompt),
  rehearse.log.

## The rehearsal vector (the fresh stamp)

`architect rehearse suite-deflake --color never` (plain-`&` detached by
the predecessor at 21:18 local, collected by the replacement run;
finished ~22:23, ~65 min wall at base; REHEARSE_EC=0; transcript
`build/rehearse/I87-suite-deflake-20261024T211822.888979.md`):
**GREEN 101 / RED 3 / BROKEN 3** — every non-green is a declared base
state, no spec defect found, frozen as-is:
- `scope` RED — the declared must-differ leg (no firing test file
  touched at base).
- `deflake-no-widening` RED — the declared belt-audit leg (the `:1608`
  interrupt test lacks the I82 Law-4 belt at base).
- `deflake-interrupt-streak` RED — the LIVE class-(a) wedge fired
  standalone at iteration 6: the 90 s per-iteration watchdog caught it
  LOUD (`FAIL … standalone iteration 6 WEDGED`), transcript captures the
  `wait_until` RuntimeError from the `chat_test.rb:1613` thread. The
  declared-possible base firing; the watchdog design proven in anger.
- `deflake-par-streak` BROKEN (900 s runner cap) — cap-exceeding by
  construction (~13 min), the declared runner artifact.
- `deflake-drain-streak` BROKEN (900 s runner cap) — cap-exceeding by
  construction (~25 min), the declared runner artifact.
- `parallel-parity` BROKEN (900 s runner cap, empty output) — the same
  belt-less wedge INSIDE a full `rake test:par`: the `:1608`
  kernel_interrupt test missed its window and wedged `kernel.run`
  forever; the parallel runner has no global timeout BY DESIGN (fan-out
  mechanics untouchable), so the gate cap killed it. `parallel-repeat`
  (3 consecutive full runs) went GREEN immediately after — the live
  flake, not a deterministic defect. **New measured fact: the class-(a)
  wedge mode wedges a WHOLE parallel run, not just a standalone test —
  this is the loudest base symptom the cure removes.**

## Defects found this session + fixes (itemized)

1. **My own AC assembly ate backslashes** (`String#sub` with a STRING
   replacement processes `\1`/`\\`/etc. in the replacement — the gates
   block's `^\+`, `\\to`, `\+=` literals were corrupted in the first
   `architect section acceptance-criteria` record). Caught by the
   post-record extraction diff (the standing discipline), fixed by the
   BLOCK form (`head.sub(token) { gates }`), re-recorded, re-verified
   byte-identical. **House rule: assemble section files with the block
   form of sub (or plain concatenation), NEVER the string-replacement
   form, when the payload contains backslashes.**
2. **The belt-audit leg's `bundle exec ruby` abort did NOT stop the
   gate** (probe printed the abort message then `NO_WIDENING_OK`,
   ec=0) — the /bin/sh no-`set -e` discipline: a ruby abort is just a
   nonzero exit the NEXT line must gate. Fixed (capture `ec=$?` +
   explicit exit). Verified: RED at base for exactly the declared
   reason (the :1608 belt gap).
3. **The class-(a) wedge fires STANDALONE, not only under parallel
   load**: the first standalone probe of the interrupt amplifier wedged
   past a 600 s outer timeout — the belt-less
   `test_kernel_interrupt_during_streaming_...` (:1608) missed its
   window and `kernel.run` looped forever. Consequence baked into the
   frozen gates: EVERY amplifier iteration runs under a hard wall
   watchdog (90 s interrupt / 300 s drain — fail-loud, never a hung
   battery). **House rule: any gate loop that runs a wedgable test
   needs its own per-iteration watchdog; do not rely on the test's
   belt alone (the belt is the CURE's deliverable, absent at base).**
4. **Scope-gate shell**: `echo "$diff" | grep -vE …` false-positives on
   an empty diff (the empty echo line fails the anchored match) —
   piped `git diff --name-only` directly instead. Verified both
   directions in a scratch clone: GREEN on the exact lane shape (both
   firing files touched + t87stk scratch + one new support file), RED
   on an out-of-bounds tracked touch.

## Measured facts the next spec must honor

- **Base fire rates at `40ed92b` (ruby 4.0.9), this session's sample:**
  class (a) fired 2/5 full `rake test:par` runs (runs 1 and 5), BOTH
  `test_escape_interrupts_a_streaming_run_through_the_kernel_path` at
  `test/chat_test.rb:5791` (the post-ESC `wait_until { !chat.busy? }`,
  "work condition never satisfied" from `test/test_helper.rb:15`).
  Class (f): 0/5 this session (I85 sample: 2/9). Green-run literals:
  1491 runs / 5 skips / assertions 10112–10122 (inside the carried ±20
  band) / walls 45.5–47.5 s.
- **The frozen N = 16 defense** (AC preamble): at the measured rates an
  uncured class survives 16 consecutive zero-firing runs with
  probability ≤ ~0.4% ((a), p≈0.29) / ~1.9% ((f), p≈0.22) — before the
  amplifier gates (32 focused exposures) and the judge's cold re-run.
- **Gate costs (measured/estimated)**: interrupt pair ~1 s/iteration
  idle (the gate ≈ 3–4 min total incl. the steal leg, GREEN at base
  this session: `DEFLAKE_INTERRUPT_OK standalone=16 steal=8`); drain
  pair ~37 s/iteration idle (two real bundle-exec boots per leg) →
  `deflake-drain-streak` ≈ 25 min; `deflake-par-streak` ≈ 13 min at
  base walls. The streak + drain gates EXCEED the official runner's
  900 s per-gate cap BY CONSTRUCTION — declared in the AC preamble;
  the standalone cold run is the operative record (I77/I80 precedent).
- **The bundler heal class is QUIET at this base**: the heal line
  landed in `Gemfile.lock` at 40ed92b; `bundle install --quiet` at the
  pristine base produces ZERO lock diff (measured). The I87 scope gate
  pins the lock byte-unchanged.
- Serial suite literals for cross-check: 1491 / 5S, I85 judge-cold
  214 s at this tree content; any growth = exactly the lane's declared
  new pins.

## Verification commands actually used (exact, tested)

- Carry audit: `cd tmp/t87-spec && ruby rebase.rb` →
  `CARRY_AUDIT_OK (102 carried gates, byte-identical after the declared
  rebases + comment deltas; scope rewritten apart)`.
- Post-record extraction check (run after EVERY AC record):
  `sed -n '/^```gates$/,/^```$/p' architecture/I87-suite-deflake.md |
  sed '1d;$d' > /tmp/x.yaml && diff /tmp/x.yaml
  tmp/t87-spec/gates-final.yaml && ruby -ryaml -e '…'` (count 107, dup
  ids, expect shapes).
- New-gate probes (from `repos/tart`): `sh
  ../../tmp/t87-spec/probe-<id>.sh` — scope RED at base on the
  must-differ leg (`FAIL scope: must-differ`); deflake-no-widening RED
  on the belt gap (`FAIL no-widening: belt audit ec=1`);
  deflake-interrupt-streak GREEN (`DEFLAKE_INTERRUPT_OK`); the two
  streak/par gates shell-checked `sh -n` (their full base behavior is
  the rehearsal's declared-RED evidence). Scope positive/negative
  controls ran in a scratch clone at 40ed92b.
- Base fire-rate sample: 5 × `bundle exec rake test:par` (plain `&`
  background, never nohup), logs at `tmp/t87-spec/base-par-*.log`;
  failing worker logs copied OUT of the runner's mktmpdir (they are
  OS-cleaned otherwise).
- Named-test standalone forms (tested): the interrupt pair
  (`test/chat_test.rb -n
  "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"`
  → exactly `2 runs`, ~1 s); the drain pair
  (`test/subagents_e2e_test.rb -n
  "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"`
  → exactly `2 runs, 46 assertions`, ~37 s).
- Rehearse: `architect rehearse suite-deflake --color never` —
  FOREGROUND or plain `&`, NEVER nohup; this battery ran ~65 min at
  base (measured this session; the streak gates + drain amplifier
  dominate). Freeze: `architect freeze suite-deflake --color never`
  (accepts the fresh stamp with RED/BROKEN members — it refuses only
  without a matching rehearsal stamp).

## House conventions the next spec must honor

- Carry the 107-gate floor onward from the **I87 ARCH FILE** (never a
  digest; verdicts amend frozen gates): era prefix `t87*` → its own,
  diff bases `40ed92b` → the then-tip, scope rewritten per-iteration.
  Classes (a)/(f) are CURED as of I87's bar — the parallel gates'
  preamble says so; a red on those signatures post-I87 is REAL, never
  note-and-pass. Classes (b)–(e) ride as declared.
- **Assemble section payloads with the block form of `sub` or plain
  concatenation** — never string-replacement sub with backslash-bearing
  payloads (defect 1).
- **Every comparison gates its own exit** — including `bundle exec
  ruby` one-liners inside gates (defect 2).
- **Per-iteration watchdogs on gate loops that run wedgable tests**
  (defect 3); the amplifier gates' `run_iter` idiom is the tested
  shape.
- NEVER gates/rehearsals under nohup (the I85 SIGHUP lesson, still
  standing); gate gem-home anchors use `Gem.default_dir` (standing).
- provision on tart needs `--base 40ed92b` while origin/main holds
  squashed PR merges; re-verify `merge-base --is-ancestor` FAILS
  immediately before.
- Judge runs gates at the LANE tree, cold; the two cap-exceeding gates
  (par-streak, drain-streak) are standalone-operative per the AC
  preamble's runner-cap declaration; itemize-and-defend EVERY gate and
  edit.
- The freeze discipline held this run: sections → extraction check →
  rehearsal → (fixes) → freeze with a FRESH stamp; never
  --skip-rehearse.

## Builder Prompt provenance

Assembled by THIS spec session at **`tmp/t87-spec/prompt-core.md`**
(modeled on the I85/I86 shape: the mission with the measured fire-rate
record, Law 0 forensics-first ordering, Laws 1–3 compressed, the
measured cure bar with the runner-cap note, the gate-discipline rules,
the report shape). NOT copied anywhere. **The COORDINATOR copies it to
`build/I87-suite-deflake-core/prompt.md`** at dispatch and appends the
Builder Prompt section (`architect section suite-deflake prompt
--append --lane core --from build/I87-suite-deflake-core/prompt.md`) —
the recorded split of labor. `tmp/` is gitignored; this digest is the
committed record of the prompt's existence and contents.

## Decisions taken (one line each)

- **N = 16** for the par streak — ≤ ~2% per-class survival for a no-op
  cure at the measured rates; ~1.8× the largest measurement window;
  ~13 min/battery cost, cap-exceeding declared.
- **Amplifier counts ×16 standalone / ×8 steal** — the amplifiers are
  regression proofs + load amplifiers; detection power lives in the
  par streak (the classes fire inside full-suite runs, not standalone).
- **Per-iteration watchdogs (90 s / 300 s) inside the amplifier gates**
  — the belt-less wedge class fires standalone (measured); a gate must
  never hang.
- **The class-(f) cure is test-side content-addressable scripting** —
  the child's env derives INSIDE the parent process, so a second
  endpoint would force a lib change; the frozen contract allows the
  additive `match:` shape or an equivalent, itemized.
- **All 103 I85 gates carried (incl. `premise-remeasure`)** — the
  task's letter ("the carried 103-gate floor rides rebased"); the
  premise is settled on 4.0.9 but the gate is an 18 s measurement gate,
  GREEN-expected.
- **`ruby-pin`/`native-bundle` kept as re-verification guards** — the
  pin is landed; RED only on regression.
- **Scope sanctions at most ONE new `test/support/*.rb`** — the
  declared-possible pin battery; its presence forces an
  itemize-and-defend entry (the I80 new-file lesson, pre-answered).

## Known unknowns / open questions for the judge

- Which of W1 (dropped interrupt — no live work task at ESC) vs W2
  (starved teardown) is the operative (a) mechanism — the Grounds cite
  both with evidence for W1's plausibility; the lane's forensics
  decides (`chat.agent.interrupted?` on the firing run discriminates:
  false ⇒ dropped, true ⇒ starved).
- Whether the (a) cure needs a PRODUCTION change (e.g. a pending
  interrupt flag in `Core::Loop#interrupt_work!`) — sanctioned ONLY on
  proven production defect, minimal, itemized, PHASE 0 if the shape
  surprises; the expectation set by the plan is test-side only.
- The drain-streak's steal-leg walls at the lane tree (300 s watchdog
  vs ~37 s idle iterations — expected ample; measured by the rehearsal
  at base and the judge cold).
- The two cap-exceeding gates' interaction with the official runner —
  declared, standalone-operative; the judge's transcript names which
  record is operative.
