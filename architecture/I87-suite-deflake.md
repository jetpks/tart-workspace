# I87: suite-deflake

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I87 grounds — suite-deflake

Plan: `notes/plan-20261025T023612Z-suite-deflake.md` (operator plan
2026-10-25 — cure the two 4.0.9 parallel-load flake classes BEFORE the
tart PR merges; ENTRY 1, repo tart, ONE lane `core`). Base tip:
**`40ed92b`** (the I85 integration merge, `Merge
lane/I85-ruby-4-0-9-core`; verified this session: `git -C repos/tart log
--oneline -1` = `40ed92b`, tracked tree clean).

## Why (owner directive, cited not restated)

BRIEF §8's daily-driver bar: the suite must be trustworthy — a battery
that cries wolf trains its operator to ignore red (the plan header).
I85's recorded residual measured two declared flake classes firing at an
elevated rate on ruby 4.0.9 under full parallel load (~2/9 full
`rake test:par` runs each). The owner wants them CURED, not carried.
I82's standing law applies: **deterministic synchronization over real
sleeps** — await the actual condition, never poll a wall-clock window;
a fix that only widens a timeout or adds a sleep is a defect, not a cure.

## Machine facts (measured fresh, this session)

- `repos/tart` @ `40ed92b`, tracked-clean; `ruby -v` = ruby 4.0.9
  (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin25], resolved by
  the COMMITTED `.ruby-version` (I85 landed — no unpinned-tree subtlety
  remains; worktrees inherit the pin).
- **The bundler self-checksum heal class is QUIET at this base**
  (measured this session): the heal line `bundler (4.0.22) sha256=d8d5ec…`
  LANDED in `Gemfile.lock` at the I85 integration, so `bundle install
  --quiet` at the pristine base produces ZERO lock diff (`git diff --
  Gemfile.lock` empty after install). The I85-era lock-heal acceptance
  clauses in the carried `ruby-pin` gate are inert-but-harmless; the
  rewritten `scope` gate pins the lock byte-unchanged.
- Remote ancestry (forces `--base` at provision): `git -C repos/tart
  merge-base --is-ancestor 40ed92b origin/main` → **exit 1 (NOT an
  ancestor)** — origin/main holds squashed PR merges; re-verify
  immediately before provisioning (the standing rule).

## The two classes, measured (the fire-rate record)

- **Class (a) — chat-interrupt loud-red.** I85 spec sample: fired 2/9
  full parallel runs (rehearsal `parallel-repeat` run 2, second
  sighting). **THIS session at base `40ed92b`: fired 2/5 full
  `rake test:par` runs (runs 1 and 5)** — both times
  `Tart::ChatTest#test_escape_interrupts_a_streaming_run_through_the_kernel_path`,
  `RuntimeError: work condition never satisfied` at
  `test/test_helper.rb:15` (`wait_until`'s 5 s deadline) from
  **`test/chat_test.rb:5791` — the post-ESC `wait_until { !chat.busy? }`**.
  Failing worker logs preserved: `tmp/t87-spec/base-par-{1,5}-failing-worker.log`
  (plus the five full runner logs `base-par-{1..5}.log`; green-run
  literals 1491 runs / 5 skips, assertions 10112–10122 — inside the
  carried ±20 band; walls 45.5–47.5 s).
- **Class (f) — subagents-e2e drain-timing.** I85 spec sample: fired 2/9
  full parallel runs (`parallel-parity` rehearsal RED, second sighting);
  the firing test is
  `test_default_on_e2_async_detached_notify_and_print_drain`
  (`test/subagents_e2e_test.rb:987`) — `assert_equal B_FINAL,
  stdout.strip` ("the drain adds no extra stdout") inverts under
  sustained 8-way load. I85 measured it GREEN standalone ×3 + ×3 under
  deliberate 8-way CPU steal and GREEN serial — it fires ONLY inside
  full-suite 8-way runs. This session's 5 base runs: 0/5.
- Combined measured per-run rates: (a) ≈ 4/14 ≈ 0.29, (f) ≈ 2/9 ≈ 0.22.
  These drive the frozen N (the AC preamble carries the math).

## The stated race mechanisms (the forensics starting points — the lane
## confirms or refines each with a deliberate-load reproduction BEFORE
## fixing; Law 0)

### Class (a) — the busy-clear race (evidence: the two captured firings)

The escape-interrupt test (`test/chat_test.rb:5775`) drives a real kernel
against a `MockLLMServer` scripted `:slow_stream` of `"x" * 40` — 40
chunks at the server's hard-coded `spec_pause` 0.1 s (`write_sse`'s
`:pause` arm) ≈ **4 s of real-time streaming**. The scenario thread:
`type(...)` → `wait_until { chat.busy? }` → push ESC →
`wait_until { !chat.busy? }` (**the firing line, :5791**) → await the
"interrupted" transcript row. ESC reaches
`Core::Loop#interrupt_work!` (`lib/tart/core/loop.rb:250`), which cancels
`@work_task` (else the `@tasks`) — **and silently no-ops when no work is
live yet**. The candidate loss windows, both load-sensitive:

- **W1 — interrupt dropped before task registration.** `chat.busy?` is
  SURFACE state (flipped by the agent_start event handled in a kernel
  frame); the kernel's work-task registration is reactor-side. An ESC
  processed in the gap is a silent no-op → the stream runs to its
  NATURAL end (~4 s + steal inflation) before `busy?` clears → the 5 s
  deadline pops. Serially, a dropped interrupt is MASKED (natural end
  < 5 s deadline — silent green); under 8-way steal it crosses 5 s → the
  belt's loud red. This is consistent with both captured firings.
- **W2 — interrupt lands but teardown is starved.** Even a landed
  cancellation must unwind the in-flight streaming request and re-render
  before `busy?` clears; under steal that can exceed 5 s.

The deterministic-cure direction (Law 1 freezes the property, the
builder picks the mechanism and itemizes): **order the handshake** —
push ESC only after an observable that GUARANTEES the work task is live
and the stream in flight (e.g. the mock server captured the request AND
the first content chunk rendered); **make the scripted stream outlast
the deadline** so a dropped interrupt is ALWAYS a loud red, never masked
by natural stream end; **close the belt gap** —
`test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
(`:1608`) LACKS the I82 Law-4 `ensure kernel.stop!` belt at base
(verified this session by the frozen belt-audit leg: a missed window
there WEDGES `kernel.run` — this session's first standalone probe of the
amplifier gate wedged past a 600 s outer timeout on exactly this class).
`wait_until`'s 5 s deadline is NEVER raised; no sleeps are added.

### Class (f) — the script-order bet (evidence: code + the I85 inversion)

`MockLLMServer#serve` shifts the script queue by **REQUEST ARRIVAL
ORDER** (`test/support/mock_llm_server.rb:164`: `spec = @script.shift ||
{type: :message, content: ""}`). Leg B (`:157`) and its default-on twin
E2 (`:987`) script three responses and bet the parent's tool-result turn
arrives before the child's FIRST request — the test's own comment: "the
child still owes a ~350ms interpreter boot… The margin is two orders of
magnitude; a flipped order fails loud on the stdout pin." Under
sustained 8-way parallel load the child's `bundle exec ruby bin/tart`
boot is starved past the parent's instant tool-result turn → the order
FLIPS: the child takes the fast `:stream B_FINAL`, the parent's final
turn takes the `:slow_stream B_CHILD_SLOW` → the parent's stdout carries
the CHILD-answer text → `assert_equal B_FINAL, stdout.strip` inverts.
Follow-on: the early child completion queues a notify that rides the
in-flight parent run's next drain (`lib/tart/agent/loop.rb:227-229`
comment + `:441-446` — the wake opens a turn on `pending_next_turn`),
issuing a FOURTH request the exhausted script answers with
`{type: :message, content: ""}`. The child's env is DERIVED INSIDE the
parent process (`Manager#child_env` propagates `PI_API_BASE`), so the
test cannot point the child at a second endpoint without a lib change —
the deterministic cure is test-side: **content-addressable scripting**
(a strictly additive per-entry match capability in
`mock_llm_server.rb`, or an equivalent deterministic ordering mechanism
the builder itemizes) so each scripted response routes by REQUEST
CONTENT, never arrival order.

## The I82 laws (the house law this iteration enforces)

From `notes/spec-digest-20261020T044344Z-suite-sleep-surgery.md` and the
I82 arch file: deterministic fakes over real sleeps — every fixed sleep
becomes a bounded poll on a TRUE observable; the anti-wedge belt (I82
Law 4: `begin … ensure kernel.stop!` on EVERY scenario-thread exit path)
converts a missed window into a ≤5 s loud red instead of the standing
900 s wedge; duration shrinks keep ≥3× outlast margins. This iteration
extends the same law to its conclusion: the two remaining loud-red
classes get their mechanisms REMOVED, not their windows widened.

## The carried battery (the extraction + rebase record)

- Carry source: the **I85 frozen/post-verdict ```gates block in
  `architecture/I85-ruby-4-0-9.md` — THE ARCH FILE, never a digest**;
  post-freeze commits to that file are Builder Report/Verdict appends
  only (the I85 verdict's own mechanical post-flight), so the current
  file's block IS the frozen block. 103 gates: **102 carried verbatim
  with the DECLARED deltas** (scope rewritten per-iteration), then +4
  new gates → **107 gates**.
- Declared deltas (the ONLY changes to the carried 102):
  (a) era prefix `t85*` → `t87*` (all out dirs / mktemp prefixes / tmux
      tokens);
  (b) every functional git-diff base + comment reference `6a054df` →
      `40ed92b` (threads-budget, parallel-parity's Rakefile leg,
      ruby-pin's floor/lock legs);
  (c) the suite gate comment's tail sentence refreshed to the I87 carry
      declaration (comment only; command bytes untouched);
  (d) **the parallel gates' flake preamble AMENDED (the plan's
      mandate)**: `parallel-parity` + `parallel-repeat` no longer list
      classes (a)/(f) as live note-and-pass classes — the comments state
      their CURED-at-I87 status and that a red on those signatures is a
      REAL failure (comment-only; command bytes untouched);
  (e) `ruby-pin`'s declared-RED comment updated: the pin is LANDED at
      this base — the gate is a re-verification GUARD (comment-only).
- Carry audit (`tmp/t87-spec/rebase.rb`, run this session): applying the
  declared deltas then their inverses reproduces the extracted I85 block
  minus `scope` **byte-identically** — `CARRY_AUDIT_OK (102 carried
  gates)`; the assembled 107-gate block YAML-parses, ids unique, expect
  shapes well-formed (`GATES_FINAL_OK 107`).
- The untracked-scratch whitelist class `t8[0-5]` lived ONLY in the
  rewritten `scope` gate; its I87 form is `t8[0-7]`.
- Handoff facts from `notes/spec-digest-20261024T071323Z-ruby-4-0-9.md`
  (honored, not re-derived): gate-shell discipline (/bin/sh has NO
  `set -e` — every comparison gates its own exit; a `bundle exec ruby`
  abort does NOT stop the gate — **this session's probe caught exactly
  this defect in the belt-audit leg and it was fixed pre-freeze**);
  never gates under nohup; gate gem-home anchors use `Gem.default_dir`;
  short out dirs; judge runs gates at the LANE tree cold;
  itemize-and-defend every gate and edit; the one-full-suite-run-per-
  battery fold and the ≤240 s serial wall hold unchanged; carried gates
  keep origin `ac:` labels verbatim.
- Measured base for the judge's cross-check: parallel runs 1491 / 5S /
  walls 45.5–47.5 s ×5 this session; I85 judge-cold serial 1491 / 0F /
  0E / 5S / 214 s at this same tree content; the interrupt-pair
  standalone ~1 s; the drain-pair standalone ~37 s (two real
  bundle-exec boots per leg — the I82 excluded e2e-boot seam).

## The frozen seams (cited)

- `repos/tart/test/chat_test.rb` — the streaming-interrupt family
  (`:1608` belt-less, `:5775` belted); the firing line `:5791`.
- `repos/tart/test/subagents_e2e_test.rb` — legs B (`:157`) and E2
  (`:987`); `tart_sub`'s `PARENT_DEADLINE_S = 180` watchdog (`:43`);
  `wait_until_bounded` (`:459`).
- `repos/tart/test/support/mock_llm_server.rb` — the arrival-order
  script shift (`:164`), `spec_pause` 0.1, the EPIPE-swallowing
  mid-stream teardown arms. ALSO the pty-tester parity rig's support
  file (bin/pty-tester loads it minitest-free) — any change must keep
  the top-level, minitest-optional shape and every existing caller's
  semantics byte-preserved.
- `repos/tart/test/support/parallel_runner.rb` — the load context (8
  workers, per-worker log files, kill+reap). Fan-out mechanics FROZEN
  unless forensics prove it the race source (then itemize-and-defend —
  the task's letter). This session's evidence points elsewhere (both
  firings are in-suite tests' own races; the runner merely supplies the
  load).
- `repos/tart/test/support/signal_hygiene_harness.rb` — the I75/I82
  six-leg belt. HARD-FROZEN byte-untouched (the `deflake-no-widening`
  gate pins it).
- `repos/tart/test/test_helper.rb` — `wait_until`'s 5 s deadline.
  HARD-FROZEN (same gate).
- `lib/tart/core/loop.rb:250` (`interrupt_work!`'s no-op window),
  `lib/tart/agent/loop.rb:225-262/:441-446` (the wake/drain path),
  `lib/tart/subagents/manager.rb` (`drain`, `child_env`),
  `lib/tart/print.rb` (`final_response`), `bin/tart:351-369` (the print
  drain) — mechanism seams CITED, read-only unless forensics prove a
  production defect (minimal, itemized, PHASE 0 if the shape surprises).

## Deliberately excluded (plan rulings, do not build)

Any `.ruby-version`/`Gemfile*`/gemspec touch (landed and pinned); the
parallel runner's fan-out mechanics (above); `architecture/`; any
timeout widening, added sleep, or poll-interval padding anywhere in the
diff (the `deflake-no-widening` gate is the mechanical backstop);
weakening or deleting ANY existing watchdog/belt/deadline (belts stay or
tighten); re-litigating the OTHER declared flake classes ((b) s5
`Took`-line, (c) lane-tree-depth geometry, (d) render-perf BP2
load-margin, (e) suite order/env — they ride as declared); the standing
I84 gate-flip question and the owner's post-landing follow-ups (the
tart PR, pushes). If a class proves INCURABLE at acceptable cost the
spec says so and it stays declared — that outcome requires owner ruling,
PHASE 0.

## Specification

# I87 specification — suite-deflake

## Objective

Cure flake classes (a) — the chat-interrupt loud-red — and (f) — the
subagents-e2e drain-timing inversion — at the ROOT, so the suite runs
clean under full parallel load on ruby 4.0.9: **measured, not
asserted**. BRIEF §8's daily-driver bar: a battery that cries wolf
trains its operator to ignore red. Each class gets a named firing test,
a stated race mechanism confirmed by reproduction, and a fix that
REMOVES the mechanism by deterministic synchronization (await the
condition, order the handshake, content-address the script) — never a
widened timeout, never an added sleep.

## Deliverable shape (frozen)

ONE lane `core`, repo tart, frozen touch set:

- `test/chat_test.rb` — the class-(a) cure (the streaming-interrupt
  family).
- `test/subagents_e2e_test.rb` — the class-(f) cure (drain legs B + E2).
- `test/support/mock_llm_server.rb` — the declared-possible
  test-support seam for the class-(f) deterministic-ordering cure.
- PLUS at most ONE NEW file under `test/support/` (e.g. a hermetic pin
  battery for a new mock-server capability) — its presence REQUIRES an
  itemize-and-defend entry.

No production `lib/` change unless forensics PROVE a production defect —
minimal, itemized, and a PHASE 0 event if the shape surprises (the
judge adjudicates per the I77 precedent).

## Law 0 — forensics first, reproduction before cure

BEFORE any fix, for EACH class: (1) name the firing test; (2) state the
race mechanism precisely — confirm or refine the Grounds' hypotheses
(W1/W2 for (a); the arrival-order flip for (f)) with EVIDENCE; (3)
reproduce the firing under deliberate load with the failing artifact
PRESERVED (the class-(a) reproduction keeps the failing parallel-run
worker log — the streak gate's `cp` leg shows the shape; a standalone
or reduced-context reproduction is acceptable iff it fires the SAME
signature); (4) only then fix. A fix without a named, evidenced
mechanism is a defect. Two base firings of class (a) with preserved
worker logs already sit at `tmp/t87-spec/base-par-{1,5}-failing-worker.log`
(space scratch — the lane re-measures at its own tree).

## Law 1 — the class-(a) cure (deterministic interrupt handshake)

In the streaming-interrupt family (the named tests:
`test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`,
`test_escape_interrupts_a_streaming_run_through_the_kernel_path`):

- **Order the handshake.** The ESC is pushed ONLY after an observable
  that guarantees the kernel's work task is live AND the stream is in
  flight (e.g. the mock server captured the request AND a first content
  chunk has rendered/started — the exact observable is the builder's,
  itemized and defended). The interrupt must deterministically find a
  live task to cancel — the W1 silent-no-op window is closed BY
  CONSTRUCTION, not by timing.
- **Unmask the drop.** The scripted stream must OUTLAST the test's
  observation deadline, so a dropped or delayed interrupt can never be
  masked by the stream's natural end — a missed interrupt is ALWAYS a
  loud red. (At base the 40-chunk × 0.1 s ≈ 4 s stream ends inside the
  5 s deadline, silently greening a dropped interrupt serially; on the
  interrupt path the stream is cancelled immediately, so a longer
  script costs NOTHING on green runs.)
- **Close the belt gap.** BOTH named tests carry the I82 Law-4 belt:
  `kernel.stop!` rides an `ensure` on every scenario-thread exit path
  (the `:1608` test lacks it at base — a missed window there WEDGES the
  suite; proven at spec time).
- **Asserted properties and test NAMES unchanged.** Each test still
  proves the same pi-parity property (the escape interrupt cancels the
  run, the loop survives, the transcript renders "interrupted"
  coherently); no test deleted, none renamed, counts grow only by any
  DECLARED new pins.
- **Never** raise `wait_until`'s 5 s deadline (`test/test_helper.rb` is
  hard-frozen), never add a sleep, never pad a poll interval.

## Law 2 — the class-(f) cure (kill the arrival-order bet)

The drain legs (`test_leg_b_async_delegation_and_print_drain`,
`test_default_on_e2_async_detached_notify_and_print_drain`) currently
bet on REQUEST ARRIVAL ORDER at the mock server (the child's slow boot
usually loses). The cure removes the bet: scripted responses route by
REQUEST CONTENT, deterministically — e.g. a strictly additive per-entry
match capability in `test/support/mock_llm_server.rb` (a `match:`
predicate selecting the entry whose predicate matches the captured
request body; unmatched entries keep the blind shift; the exhausted
fallback `{type: :message, content: ""}` unchanged), or an equivalent
deterministic-ordering mechanism the builder itemizes and defends.
Hard requirements on whichever mechanism:

- **Strictly additive**: every existing caller's semantics
  byte-preserved (the suite's many order-dependent scripts, the
  pty-tester parity rig's minitest-free load of the file, `rearm!`,
  `suppress_usage!`, the request logs, the EPIPE arms); the file's
  top-level, minitest-optional shape holds.
- The child's slow stream lands on the CHILD's request regardless of
  arrival order; the parent's two turns get their two fast responses
  regardless. Both legs converted; both keep every existing assertion
  (the stdout pin, the notify session tail, the run-dir facts) —
  strengthened, never weakened.
- Any new mock-server capability carries NEW hermetic pins (in-suite,
  discovered by the canonical globs — the suite's run count grows by
  exactly the declared new pins; the growth is itemized in the Builder
  Report).

## Law 3 — nothing weakens (the belt-and-timeouts law)

The anti-wedge belt and EVERY existing timeout/loud-red safety stay or
tighten — never loosen. Byte-frozen vs `40ed92b` (the
`deflake-no-widening` gate is the mechanical backstop):
`test/test_helper.rb` (the 5 s `wait_until`), `Rakefile`,
`test/support/signal_hygiene_harness.rb` (the I75/I82 six-leg belt),
`test/support/parallel_runner.rb` (the I84 fan-out mechanics — frozen
unless forensics prove it the race source, then itemize-and-defend per
the task's letter), `PARENT_DEADLINE_S = 180` in the e2e harness. ZERO
added `sleep` statements in the diff. ZERO production bytes (`lib/`,
`gems/`, `bin/`, `bench/`) unless Law 0's forensics prove a production
defect — then minimal, itemized (old bytes → new bytes), and the
`deflake-no-widening`/`scope` REDs are judge-adjudicated per the I77
precedent. Any timing literal the fix DOES touch is itemized old→new
with the reason it is not a widening.

## Law 4 — the cure bar is MEASURED

The frozen bar (the AC preamble carries the N defense):

- **The streak**: **16** consecutive full `rake test:par` runs at the
  lane tree with ZERO (a)/(f) firings — every run exit 0, clean
  `PARALLEL_OK` (0F/0E), well-formed `COVERAGE_OK` (the
  `deflake-par-streak` gate; a red run breaks the streak and preserves
  the failing worker log).
- **The amplifiers**: the two named interrupt tests ×16 standalone +
  ×8 under deliberate 8-way CPU steal, every iteration under a hard 90 s
  wall watchdog (`deflake-interrupt-streak`); the two drain legs ×16
  standalone + ×8 under the same steal, 300 s watchdog
  (`deflake-drain-streak`).
- **The floor**: serial `rake test` green AND ≤ 240 s wall (the carried
  timed `suite` gate — the one-full-suite-run-per-battery fold holds;
  the serial suite is run ONCE per battery, by that gate), and the
  whole carried 102-gate battery green cold at the lane tree.
- The Builder Report carries: the forensics record per class (mechanism,
  reproduction, pre-fix firing), the per-edit itemization (old bytes →
  new bytes + the mechanism each edit removes), the full 107-gate table
  with a measured one-liner per gate (an absent gate entry is
  REJECT-class), the streak logs' summary lines, and the suite
  runs/skips literal with the declared new-pin growth if any.

## Tool guidance (exact verification, this session's tested forms)

- Parallel run: `cd repos/tart && bundle exec rake test:par` (measured
  ~45.5–47.5 s at base, 8 workers, this session ×5).
- Serial gate anchor: `bundle exec rake` (I85 judge-cold at this tree
  content: 1491 runs / 0F / 0E / 5S / 214 s).
- The named interrupt pair standalone (measured ~1 s idle, green):
  `bundle exec ruby -Itest -Ilib test/chat_test.rb -n
  "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"`
  → exactly `2 runs`.
- The drain pair standalone (measured ~37 s idle, green):
  `bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n
  "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"`
  → exactly `2 runs, 46 assertions`.
- Gates: run verbatim from the frozen ```gates block; /bin/sh has NO
  `set -e` — EVERY comparison gates its own exit (a `bundle exec ruby`
  abort does NOT stop the gate — capture `ec=$?`); never gates under
  nohup (the I85 SIGHUP-inheritance lesson); gate gem-home anchors use
  `Gem.default_dir`, never `Gem.dir`.
- provision: `architect provision suite-deflake --base 40ed92b`
  (origin/main holds squashed PR merges — re-verify `git -C repos/tart
  merge-base --is-ancestor 40ed92b origin/main` FAILS immediately
  before dispatch; measured FAIL this session).

## Boundaries

- MAY touch: `test/chat_test.rb`, `test/subagents_e2e_test.rb`,
  `test/support/mock_llm_server.rb`, + at most ONE NEW
  `test/support/[a-z0-9_]+\.rb` file (itemized).
- MUST NOT touch: `.ruby-version`, `Gemfile`, `Gemfile.lock`,
  `tart.gemspec`, `Rakefile`, `test/test_helper.rb`,
  `test/support/signal_hygiene_harness.rb`,
  `test/support/parallel_runner.rb` (unless forensics PROVE it the race
  source — then itemize-and-defend, PHASE 0), `lib/**`, `gems/**`,
  `bin/`, `bench/`, `architecture/` — unless Law 0's forensics prove a
  production defect (minimal, itemized, PHASE 0 if the shape
  surprises).
- Builders never commit (lane work lands untracked/modified at the lane
  tree; integration commits it).
- No new gems, no rig changes, no timeout widened, no sleep added, no
  belt weakened or removed, no test renamed or deleted.
- If a class proves INCURABLE at acceptable cost: it stays declared —
  owner ruling, PHASE 0 (the plan's letter).

## Lane plan

ONE lane (repo tart; the three-file touch set overlaps nothing). Effort
at dispatch: **high** — the diff is small, but the deliverable is the
forensics plus the measured bar: a full 107-gate cold battery whose
streak/amplifier gates alone run ~45–60 min, plus the pre-fix
reproduction record.

```lanes
- name: core
  repo: tart
  touch:
    - test/chat_test.rb
    - test/subagents_e2e_test.rb
    - test/support/mock_llm_server.rb
```

## Acceptance Criteria

# I87 acceptance criteria — suite-deflake

Property-level, each independently judgeable. The frozen ```gates block
below (107 gates: 102 carried verbatim from the I85 post-verdict battery
with the standing rebases + declared comment deltas — era prefix `t87*`,
diff bases `40ed92b`, the parallel gates' flake preamble amended to the
cured status — plus the per-iteration `scope` rewrite and 4 new gates)
is the runnable floor this iteration is judged against; the prose ACs
name which gate carries which property and what the Builder Report must
evidence. Calibration: floors from the defect's side only; exactness
only where the number is itself the deliverable (the frozen N, the
watchdog budgets, the byte-frozen sentinels).

## AC preamble — declared states and the measured base

- **Carried-block provenance.** Extracted from the ARCH FILE
  (`architecture/I85-ruby-4-0-9.md`, the post-verdict 103-gate block —
  never a digest; its post-freeze commits are report/verdict appends
  only): 102 carried (scope rewritten per-iteration), carry audit
  BYTE-IDENTICAL after the DECLARED deltas (`tmp/t87-spec/rebase.rb`:
  `CARRY_AUDIT_OK (102 carried gates)`). Declared deltas: (a) era prefix
  `t85*`→`t87*`; (b) diff bases/comment references `6a054df`→`40ed92b`;
  (c) the suite gate comment's tail sentence refreshed (comment only);
  (d) the parallel gates' flake preamble amended — classes (a)/(f)
  CURED, no longer live note-and-pass (comment only, the plan's
  mandate); (e) `ruby-pin`'s base-state comment updated (the pin is
  landed; the gate is a re-verification guard). Carried gates keep
  origin `ac:` labels verbatim.
- **Declared-RED at base `40ed92b`** (each verified STANDALONE this
  session for EXACTLY its declared reason): `scope` (the must-differ
  leg — no firing test file touched at base, verified: `FAIL scope:
  must-differ — no firing test file touched`); `deflake-no-widening`
  (the belt-audit leg — the `:1608` interrupt test LACKS the I82 Law-4
  belt at base, verified: `FAIL no-widening: belt audit ec=1`);
  `deflake-par-streak` (classes (a)/(f) LIVE — measured this session at
  base: class (a) fired in 2 of 5 full `rake test:par` runs, both the
  escape-interrupt test at `chat_test.rb:5791`; the streak breaks
  before 16 with high probability — expected RED within the first
  handful of runs).
- **GREEN-expected at base:** `deflake-interrupt-streak` (measured
  standalone GREEN this session: ×16 + ×8 steal, `DEFLAKE_INTERRUPT_OK`
  — the class fires under full-suite parallel load, not standalone;
  a base firing under the steal leg is the live class,
  declared-possible) and `deflake-drain-streak` (the I85 spec sample
  GREEN ×3 standalone + ×3 steal; the pair measured ~37 s/iteration
  idle this session). `ruby-pin`/`native-bundle` are GREEN-expected
  re-verification guards at this base (the pin + bundle landed at
  I85). Every other carried member is GREEN-expected per the I85
  rehearsal + judge ledger at this tree content; the rehearsal
  measures the true vector.
- **The runner-cap declaration.** `deflake-par-streak` (~13 min) and
  `deflake-drain-streak` (~25 min) EXCEED the official gate runner's
  900 s per-gate cap BY CONSTRUCTION (the cure bar is measured; the
  measurements cost what they cost). Per the I77/I80 precedent the
  standalone cold run is the operative record: a runner SIGTERM at the
  cap on one of these two gates is a runner artifact, adjudicated by
  the verbatim standalone re-run — never silently, always recorded.
- **The N = 16 defense (frozen).** Measured per-run fire rates: class
  (a) 2/9 (I85 spec sample) + 2/5 (this session's base sample) ≈ 0.29;
  class (f) 2/9 ≈ 0.22. Were a "cure" a no-op, the probability of
  ZERO firings across 16 consecutive full runs is (1−0.29)^16 ≈ 0.4%
  for (a) and (1−0.22)^16 ≈ 1.9% for (f) — a still-flaky class survives
  the bar with ≤ ~2% probability per class, BEFORE the amplifier gates
  (32 further focused exposures) and the judge's own cold re-run add
  theirs. N = 16 is ~1.8× the largest measurement window (9 runs) —
  materially larger than the sample, per the plan's letter — at a
  measured cost of ~13 min per battery (16 × ~47 s), inside the
  battery's tolerance given the runner-cap declaration above.
- **The cured-status amendment (the plan's letter).** With the cure
  landed and the bar met, classes (a) and (f) come OFF the live
  declared-flake record: the carried parallel gates' comments (declared
  delta (d)) state the cured status; a red whose signature is (a) or
  (f) after this iteration is a REAL failure — investigate, never
  adjudicate note-and-pass. The remaining declared classes — (b) the
  s5 `Took`-line, (c) the lane-tree-depth geometry, (d) the
  render-perf BP2 load-margin, (e) the suite order/env classes — ride
  exactly as before (note-and-pass on cold re-run, zero lane
  attribution unless the diff proves otherwise).
- **Suite literals.** Base: 1491 runs / 5 skips (stable across this
  session's 5 base runs; assertions 10112–10122 parallel, inside the
  carried ±20 band). If Law 2 adds hermetic pins, the suite grows by
  EXACTLY the declared new pins — the growth is itemized in the Builder
  Report; any other count/shape movement is itemize-and-defend, never
  silent.

## AC1 — forensics: named mechanism, reproduced, then cured

For EACH class the Builder Report carries: the named firing test(s); the
stated race mechanism (confirming or refining the Grounds' W1/W2 and
arrival-order-flip hypotheses, with evidence); the deliberate-load
pre-fix reproduction WITH the failing artifact preserved (worker log or
standalone transcript, at the lane tree or base — the same signature as
the recorded firings); and the per-edit itemization (old bytes → new
bytes, the mechanism each edit removes). A fix without a named,
evidenced mechanism — or one that only widens a timeout or adds a sleep
— is a defect, not a cure. Carried by: the Builder Report (judged);
`deflake-no-widening` (the mechanical backstop); `scope`.

## AC2 — class (a) cured (the deterministic interrupt handshake)

The two named streaming-interrupt tests push ESC only after an
observable guaranteeing the work task is live and the stream in flight
(the W1 silent-drop window closed by construction); the scripted stream
outlasts the observation deadline (a dropped interrupt is ALWAYS a loud
red, never masked by natural stream end); BOTH tests carry the I82
Law-4 `ensure kernel.stop!` belt; asserted pi-parity properties and
test names unchanged. Measured: `deflake-interrupt-streak` GREEN at the
lane tree (×16 standalone + ×8 under deliberate 8-way CPU steal, every
iteration inside its 90 s watchdog), and ZERO (a)-signature firings
across the `deflake-par-streak` bar. Carried by:
`deflake-interrupt-streak`, `deflake-par-streak`, `deflake-no-widening`
(belt-audit leg), `suite` (the family runs in the serial battery too).

## AC3 — class (f) cured (the arrival-order bet removed)

Both drain legs' scripted responses route by REQUEST CONTENT, never
arrival order (or an equivalent deterministic-ordering mechanism,
itemized and defended): the child's slow stream lands on the child's
request regardless of boot delay, under ANY load. The mock-server
change — if any — is strictly additive (every existing caller's
semantics byte-preserved; the minitest-free rig load holds) and carries
new hermetic pins. Every existing leg assertion stands (the stdout pin,
the notify session tail, the run-dir facts) — strengthened, never
weakened. Measured: `deflake-drain-streak` GREEN at the lane tree (×16
standalone + ×8 under steal, 300 s watchdogs), and ZERO (f)-signature
firings across the `deflake-par-streak` bar. Carried by:
`deflake-drain-streak`, `deflake-par-streak`, `suite`.

## AC4 — the measured cure bar

**16 consecutive full `rake test:par` runs at the lane tree with ZERO
(a)/(f) firings** — each exit 0, clean `PARALLEL_OK` (0F/0E),
well-formed `COVERAGE_OK` (`deflake-par-streak`; any red run breaks the
streak and the failing worker log is preserved). PLUS: the serial
`rake test` green AND ≤ 240 s wall (the carried timed `suite` gate —
one full-suite run per battery); the whole carried 102-gate battery
green cold at the lane tree (declared classes (b)–(e) ride as
declared); the carried parallel trio re-proven WITH the amended flake
preamble. Suite literals: 1491 runs / 5 skips + exactly the declared
new-pin growth, if any. Carried by: `deflake-par-streak`, `suite`,
`parallel-parity`, `parallel-repeat`, the full carried floor.

## AC5 — nothing weakens

Byte-frozen vs `40ed92b`: `test/test_helper.rb` (the 5 s `wait_until`),
`Rakefile`, `test/support/signal_hygiene_harness.rb`,
`test/support/parallel_runner.rb` (unless forensics prove it the race
source — itemize-and-defend), `PARENT_DEADLINE_S = 180`. ZERO added
`sleep` statements in the diff; ZERO production bytes (`lib/`, `gems/`,
`bin/`, `bench/`) unless forensics prove a production defect (minimal,
itemized, PHASE 0-judged); every timing literal the fix touches is
itemized old→new with the not-a-widening reason. The belt audit: both
named interrupt tests carry the belt post-lane. Carried by:
`deflake-no-widening` (all five legs), `scope`, the carried
`signal-orphan-e2e` + `signal-hygiene-units` gates (the belt re-proven
end-to-end every battery).

## AC6 — scope: the frozen touch set, nothing else

Tracked diff vs `40ed92b` confined to `test/chat_test.rb`,
`test/subagents_e2e_test.rb`, `test/support/mock_llm_server.rb`; at most
ONE NEW `test/support/[a-z0-9_]+\.rb` file (untracked at the lane tree —
builders never commit — and itemized in the report); `Gemfile.lock`
byte-unchanged (the heal class is quiet at this base — measured);
untracked set confined to the standing scratch families (`t75`–`t87`,
the standing `tmp/` families) + the one sanctioned new file. The Builder
Report itemizes every frozen gate (107/107 — an absent entry is
REJECT-class) and every deviation. Carried by: `scope` (+
`deflake-no-widening`'s sentinel legs; the carried battery as the
behavioral backstop).

```gates
- id: stale-run-reaper
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t87sr-")
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    id = "01deadbee-0000-7000-8000-000000000001"
    dir = File.join(runs_home, id)
    FileUtils.mkdir_p([File.join(dir, "control", "steer-requests"), File.join(dir, "control", "stop-requests"), File.join(dir, "sessions")])
    pid = Process.spawn("sleep", "0.05"); Process.detach(pid); sleep 0.5
    File.write(File.join(dir, "status.json"), JSON.generate({"id" => id, "agent" => "worker", "task" => nil, "taskChars" => nil, "mode" => "single", "state" => "running", "pid" => pid, "cwd" => home, "asyncDir" => dir, "sessionRoot" => File.join(dir, "sessions"), "startedAt" => nil, "lastUpdate" => nil, "toolCallId" => nil}))
    File.write(File.join(dir, "runner.stderr.log"), "a ruby warning line\nsecond diagnostic line\n")
    hooks = Tart::Hooks.new
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k"}, identity: "pi", hooks: hooks, root: File.join(home, ".tart"))
    list = manager.status(id: nil)
    abort "fleet did not list the stale run: #{list.inspect}" unless list.include?("- #{id} | failed | single | worker")
    status = JSON.parse(File.read(File.join(dir, "status.json")))
    abort "status not converged to failed: #{status["state"].inspect}" unless status["state"] == "failed"
    abort "status lost the pid record" unless status["pid"] == pid
    result = JSON.parse(File.read(File.join(dir, "result.json")))
    abort "result not fabricated failed" unless result["success"] == false && result["timedOut"] == false && result["output"] == ""
    msg = result["error"].to_s
    want = "Async runner process #{pid} exited or disappeared before writing a result. Marked run failed by stale-run reconciliation."
    abort "repair message not the pi-pinned base: #{msg.inspect}" unless msg.start_with?(want)
    abort "stderr-tail diagnostics missing from the message: #{msg.inspect}" unless msg.include?("\n\nRunner stderr tail:\n") && msg.include?("second diagnostic line")
    abort "status error not the repair message" unless status["error"].to_s.start_with?(want)
    abort "a non-owned convergence queued a completion notification in the adopter" unless hooks.pending_next_turn.empty?
    abort "a non-owned run gates outstanding?" if manager.outstanding?
    puts "STALE_RUN_REAPER_OK"'
  expect:
    exit_code: 0
    stdout_match: STALE_RUN_REAPER_OK


- id: unknown-model-reject
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t87um-")
    root = File.join(home, ".tart")
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "models.json"), JSON.generate({"providers" => {"openrouter" => {"name" => "OpenRouter", "baseUrl" => "http://127.0.0.1:9/v1", "apiKey" => "k", "api" => "openai-completions", "models" => [{"id" => "z-ai/glm-4.7", "name" => "GLM", "reasoning" => false, "contextWindow" => 100000, "maxTokens" => 8192}]}}}))
    loaded = Tart::Models.load(root: root)
    empty = Tart::Models.load(root: File.join(home, "no-such-root"))
    abort "fixture catalog did not load" if loaded.model_entries.empty?
    abort "empty catalog is not empty" unless empty.model_entries.empty?
    spec = "openrouter/mistralai/devstral-2512"
    begin
      Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: nil)
      abort "unknown model + loaded catalog did not raise (no dispatch validation)"
    rescue ArgumentError => e
      abort "wrong rejection message: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    pair = Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: ["openrouter", "mistralai/devstral-2512", nil])
    abort "parent-pair exemption broken: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: empty, fallback: nil)
    abort "empty-registry validation fired (must never raise without a registry): #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: nil, fallback: nil)
    abort "nil catalog must stay parse-only: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model("openrouter/z-ai/glm-4.7", catalog: loaded, fallback: nil)
    abort "registry-resolvable model rejected: #{pair.inspect}" unless pair == ["openrouter", "z-ai/glm-4.7", nil]
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k", "PI_API_BASE" => "http://127.0.0.1:9/v1", "PI_PROVIDER" => "openrouter", "PI_MODEL" => "z-ai/glm-4.7"}, identity: "pi", hooks: Tart::Hooks.new, root: root)
    begin
      manager.spawn_run(agent: "worker", task: "must not spawn", async: false, model: spec)
      abort "spawn dispatched an unknown model without raising"
    rescue ArgumentError => e
      abort "spawn rejection message moved: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    abort "side effects before validation (run dirs created)" unless Dir.children(runs_home).empty?
    puts "UNKNOWN_MODEL_REJECT_OK"'
  expect:
    exit_code: 0
    stdout_match: UNKNOWN_MODEL_REJECT_OK


- id: subagents-health-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_health_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL health pins runs=${runs1:-0} (want >=8; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL health pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENTS_HEALTH_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_HEALTH_UNITS_OK


- id: edit-fold-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    payload = %q({"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []})
    rec = JSON.parse(payload)
    abort "payload is not the recorded folded shape" unless rec["path"].start_with?("architect.yaml\nedits: [\n") && rec["edits"] == []
    tail = rec["path"].split("\n", 2)[1]
    abort "tail is not edits-prefixed" unless tail.match?(/\Aedits:\s*\[/)
    want_edits = begin
      JSON.parse(tail.sub(/\Aedits:\s*\[/, "["))
    rescue JSON::ParserError
      JSON.parse(Fast::Completions::Protocol.repair_json(tail).sub(/\Aedits:\s*\[/, "["))
    end
    e = want_edits.first
    abort "expected one edit in the tail" unless want_edits.size == 1 && e["oldText"] == "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low" && e["newText"] == "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"
    got = Tart::Tools::Edit.normalize_arguments(rec.transform_keys(&:to_sym))
    abort "folded path not recovered: #{got.inspect}" unless got[:path] == "architect.yaml"
    abort "folded edits not recovered: #{got[:edits].inspect}" unless got[:edits] == want_edits
    bad = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [oops", edits: []})
    abort "unparseable tail must stay unchanged: #{bad.inspect}" unless bad == {path: "a.rb\nedits: [oops", edits: []}
    plain = Tart::Tools::Edit.normalize_arguments({path: "a.rb", edits: []})
    abort "no-newline must stay unchanged: #{plain.inspect}" unless plain == {path: "a.rb", edits: []}
    busy = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]", edits: [{oldText: "z", newText: "w"}]})
    abort "non-empty edits must win: #{busy.inspect}" unless busy[:edits] == [{oldText: "z", newText: "w"}] && busy[:path] == "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]"
    msg = "Edit tool input is invalid. edits must contain at least one replacement."
    abort "PINNED_EDITS_MESSAGE moved" unless Tart::Schemas::Tools::PINNED_EDITS_MESSAGE == msg
    v = Tart::Schemas::Tools.validate("edit", {path: "a.rb", edits: []})
    abort "pinned rejection not byte-identical: #{v.inspect}" unless v == {error: msg}
    dir = Dir.mktmpdir("t87ef-")
    begin
      f = File.join(dir, "architect.yaml")
      File.write(f, "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\n")
      tool = Tart::Tools::Edit.new(cwd: dir)
      out = tool.call(**rec.transform_keys(&:to_sym))
      abort "the cured call failed: #{out.inspect}" unless out == "Successfully replaced 1 block(s) in architect.yaml."
      after = File.read(f)
      abort "the staged file was not cured" unless after.include?("openrouter/mistralai/devstral-2512")
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "EDIT_FOLD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_REPRO_OK


- id: edit-fold-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/edit_fold_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL edit-fold pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL edit-fold pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo EDIT_FOLD_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_UNITS_OK


- id: session-model-identity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    m = Tart::Agent::Message.new(role: :assistant, content: "hi", provider: "openrouter", model: "reflection/beam-1.0-501b-a23b:nitro", tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "stop")
    h = m.to_h
    abort "model identity not recorded: #{h.inspect}" unless h[:model] == "reflection/beam-1.0-501b-a23b:nitro"
    abort "provider identity not recorded: #{h.inspect}" unless h[:provider] == "openrouter"
    abort "key order moved: #{h.keys.inspect}" unless h.keys == [:role, :content, :tool_calls, :provider, :model, :finish_reason, :input_tokens, :output_tokens, :cache_write_tokens]
    plain = Tart::Agent::Message.new(role: :assistant, content: "hi").to_h
    abort "model-less assistant byte shape moved: #{plain.keys.inspect}" unless plain.keys == [:role, :content, :tool_calls]
    failure = Tart::Agent::Message.error_failure(error_message: "boom")
    abort "the failure assistant gained keys: #{failure.to_h.keys.inspect}" unless failure.to_h.keys == [:role, :content, :tool_calls, :finish_reason, :error_message]
    user = Tart::Agent::Message.user("hi").to_h
    abort "user message gained keys: #{user.keys.inspect}" unless user.keys == [:role, :content]
    dir = Dir.mktmpdir("t87mi-")
    begin
      rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: File.join(dir, "agent"))
      rec.append_message(Tart::Agent::Message.user("hi"))
      rec.append_message(m)
      lines = File.readlines(rec.path).map { |l| JSON.parse(l) }
      # AMENDMENT 2026-10-18 (escalation-seat ruling, disclosed in the
      # builder-report PHASE 0): the frozen form dereferenced
      # entry["message"] on the session-header line (no "message" key) and
      # raised NoMethodError on its own recorder leg — BROKEN-class, green
      # with no implementation. Nil-safe find only; the discrimination (the
      # first assistant record model identity) is preserved.
      asst = lines.find { |entry| entry["message"] && entry["message"]["role"] == "assistant" }["message"]
      abort "the recorded session lost the model identity: #{asst.keys.inspect}" unless asst["model"] == "reflection/beam-1.0-501b-a23b:nitro" && asst["provider"] == "openrouter"
      seed = Tart::Agent::Message.from_seed_hash(asst)
      abort "the replay seed must stay model-inert: #{seed.model.inspect} #{seed.provider.inspect}" unless seed.model.nil? && seed.provider.nil?
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "SESSION_MODEL_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_IDENTITY_OK


- id: session-model-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/model_identity/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL model-identity pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL model-identity pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SESSION_MODEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_UNITS_OK

- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    # REWRITTEN at I82 (declared: the ONE carried rewrite beside `scope`) —
    # the timed form of the identical command. Reason: the wall floor is
    # this iteration's headline discriminator, and running the suite TWICE
    # per battery (a bare `suite` + a separate wall gate) doubles the
    # exposure to the standing chat-interrupt 900s-hang + spinner-dwell
    # flake classes the I75-I81 verdicts record. One full-suite run per
    # battery, with the clock: the suite must be green AND complete within
    # the frozen 240 s wall bound (base history: dff5447 measured 271 s
    # cold, RED on the wall leg; the I82 cure LANDED — integrated f07c25f
    # measured ~219 s cold per the I82 judge ledger, ~214 s cold at the I85 judge
    # ledger (40ed92b tree, ruby 4.0.9) — carried at I87 (base 40ed92b) GREEN-expected
    # at ~215 s; a count or shape movement is itemize-and-defend, never silent).
    bundle install --quiet
    log=$(mktemp t87wall.XXXXXX)
    t0=$(date +%s)
    bundle exec rake > "$log" 2>&1
    ec=$?
    wall=$(( $(date +%s) - t0 ))
    tail -3 "$log"
    echo "SUITE_WALL ${wall}s (frozen bound: 240s)"
    rm -f "$log"
    [ "$ec" -eq 0 ] || { echo "FAIL: suite — the suite itself is not green (exit $ec)"; exit 1; }
    [ "$wall" -le 240 ] || { echo "FAIL: suite — wall ${wall}s exceeds the frozen 240s bound"; exit 1; }
    echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK

- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK

- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK

- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK

- id: thinking-pins
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK

- id: lock-deps
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 40ed92b -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,

- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK

- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK

- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0

- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK

- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t87tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t87ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK

- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK

- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK

- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK

- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK

- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK

- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK

- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t87s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t87s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t87s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t87s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t87s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t87s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t87s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t87s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t87s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t87s10
  expect:
    exit_code: 0

- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t87s17
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t87s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t87s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t87s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t87wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t87wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t87wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t87zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t87zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t87zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK

- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK

- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK

- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i75-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK

- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i75-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK

- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t87hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t87hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK

- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i75-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK

- id: subagents-default-law
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK

- id: subagents-default-boot
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK

- id: subagents-motd-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK

- id: subagents-motd-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t87mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t87mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK

- id: subagents-e2e-default-on
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK

- id: rig-staging-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK

- id: vendored-attribution
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK

- id: vendored-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i75-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK

- id: listing-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK

- id: model-menu-live-merge
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK

- id: launcher-listing-thread
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK

- id: vendored-no-boot-network
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK

- id: listing-thread-law
  ac: AC4
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK

- id: md-battery-fixture
  ac: AC1
  cwd: repos/tart
  cmd: |-
    [ -f test/fixtures/markdown_battery.json ] || { echo "FAIL: battery fixture missing (declared-new; copy tmp/i68-spec/markdown_battery.json VERBATIM)"; exit 1; }
    sha=$(shasum -a 256 test/fixtures/markdown_battery.json | cut -d" " -f1)
    [ "$sha" = "4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883" ] || { echo "FAIL: battery fixture sha $sha (want the spec-frozen 4ecd9cc2...)"; exit 1; }
    ruby -rjson -e 'j = JSON.parse(File.read("test/fixtures/markdown_battery.json")); abort "want 48 cases, got #{j["cases"].size}" unless j["cases"].size == 48; puts "MD_BATTERY_FIXTURE_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_FIXTURE_OK

- id: md-battery-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/md_battery/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 48 ] || { echo "FAIL battery pins runs=${runs1:-0} (want >=48; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL battery pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_BATTERY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_UNITS_OK

- id: md-regression-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 79 ] || { echo "FAIL markdown family runs=${runs1:-0} (want >=79 = 31 base + 48 battery; nothing deleted)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown family ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_REGRESSION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_REGRESSION_UNITS_OK

- id: md-flanking-repro
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    flat = ->(src) { Tart::Render::Markdown.rows(src, width: 94).map { |r| r.map { |s| [s.text, s.fg&.to_s, s.modifiers.map(&:to_s).uniq.sort] }.reject { |t, _f, _m| t.empty? } } }
    x = flat.call("checking some_var_name and then other_value next")
    abort "R1a intraword _ em still eats underscores: #{x.inspect}" unless x == [[["checking some_var_name and then other_value next", nil, []]]]
    x = flat.call("A _real_ emphasis case")
    abort "R1b real _em_ lost: #{x.inspect}" unless x == [[["A ", nil, []], ["real", nil, ["italic"]], [" emphasis case", nil, []]]]
    x = flat.call("foo__bar__baz")
    abort "R2 intraword __ strong: #{x.inspect}" unless x == [[["foo__bar__baz", nil, []]]]
    x = flat.call("** padded ** stays literal")
    abort "R3 padded ** strong: #{x.inspect}" unless x == [[["** padded ** stays literal", nil, []]]]
    x = flat.call("foo*bar*baz")
    abort "R3b * intraword em lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["italic"]], ["baz", nil, []]]]
    x = flat.call("foo**bar**baz")
    abort "R3c ** intraword strong lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["bold"]], ["baz", nil, []]]]
    x = flat.call("*em **inner** em*")
    abort "R4 em not spanning inner *: #{x.inspect}" unless x == [[["em ", nil, ["italic"]], ["inner", nil, ["bold", "italic"]], [" em", nil, ["italic"]]]]
    x = flat.call("back \\to *em* now")
    abort "R5 backslash before letter eaten: #{x.inspect}" unless x == [[["back \\to ", nil, []], ["em", nil, ["italic"]], [" now", nil, []]]]
    x = flat.call("see [wiki](https://en.wikipedia.org/wiki/Foo_(bar)) here")
    abort "R6 parens-in-URL span boundary: #{x.inspect}" unless x == [[["see ", nil, []], ["wiki", "light_blue", ["underlined"]], [" (https://en.wikipedia.org/wiki/Foo_(bar))", "gray", []], [" here", nil, []]]]
    x = flat.call("  ```\n  indented body\n  ```")
    abort "R7 indented fence body not dedented: #{x.inspect}" unless x == [[["```", "gray", []]], [["  ", nil, []], ["indented body", "green", []]], [["```", "gray", []]]]
    x = flat.call("- [x] done\n- [ ] todo")
    abort "R8 task marker not in bullet span: #{x.inspect}" unless x == [[["- [x] ", "light_magenta", []], ["done", nil, []]], [["- [ ] ", "light_magenta", []], ["todo", nil, []]]]
    x = flat.call("x * padded * and *em* tail")
    abort "I65 reject-emission semantics regressed: #{x.inspect}" unless x == [[["x * padded * and ", nil, []], ["em", nil, ["italic"]], [" tail", nil, []]]]
    puts "MD_FLANKING_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_FLANKING_OK

- id: md-micro-perf
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    line = ->(i) { "row #{i} of some_var_name plus __dunder__ and **bold words** and *em words* and [link #{i}](https://example.test/wiki/Foo_(bar)) and `code #{i}` and ~~strike this~~ and \\no escape; filler text to widen the line toward the wrap width ninety-four" }
    p80 = (1..80).map(&line).join("\n")
    p160 = (1..160).map(&line).join("\n")
    3.times { Tart::Render::Markdown.rows(p80, width: 94) }
    n = 100
    bm = lambda do |src|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      n.times { Tart::Render::Markdown.rows(src, width: 94) }
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0 / n
    end
    a = bm.call(p80); b = bm.call(p160)
    abort format("MD_MICRO absolute over budget: %.2f ms/conversion (want <= 8.0; at-base anchor ~2.8 this session)", a) if a > 8.0
    abort format("MD_MICRO scale ratio over budget: %.2f (want <= 3.0; linear base ~2.1, the I68 defect ~4.1)", b / a) if b / a > 3.0
    puts format("MD_MICRO_OK %.2f ms/conv ratio %.2f", a, b / a)'
  expect:
    exit_code: 0
    stdout_match: MD_MICRO_OK

- id: child-env-law-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "fileutils"; require "tmpdir"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    poisoned = {
      "BUNDLE_GEMFILE" => "/t/Gemfile", "BUNDLE_LOCKFILE" => "/t/Gemfile.lock",
      "BUNDLE_BIN_PATH" => "/b/exe/bundle", "BUNDLER_VERSION" => "4.0.22",
      "BUNDLER_SETUP" => "/s/bundler/setup",
      "RUBYOPT" => "-r/s/bundler/setup -w", "RUBYLIB" => "/s",
      "GEM_HOME" => "/gems", "GEM_PATH" => "/gp", "MANPATH" => "/m",
      "RB_USER_INSTALL" => "1", "PATH" => "/bundle/bin:/usr/bin:/bin",
      "BUNDLER_ORIG_BUNDLE_GEMFILE" => NIL, "BUNDLER_ORIG_BUNDLE_LOCKFILE" => NIL,
      "BUNDLER_ORIG_BUNDLE_BIN_PATH" => NIL, "BUNDLER_ORIG_BUNDLER_VERSION" => NIL,
      "BUNDLER_ORIG_BUNDLER_SETUP" => NIL, "BUNDLER_ORIG_GEM_HOME" => NIL,
      "BUNDLER_ORIG_GEM_PATH" => NIL, "BUNDLER_ORIG_MANPATH" => NIL,
      "BUNDLER_ORIG_RB_USER_INSTALL" => NIL, "BUNDLER_ORIG_PATH" => "/usr/bin:/bin",
      "BUNDLER_ORIG_RUBYOPT" => "-w", "BUNDLER_ORIG_RUBYLIB" => NIL,
      "USER_VAR" => "keep-me"
    }
    frozen = poisoned.dup
    out = Tart::ChildEnv.scrub(poisoned)
    abort "the scrub MUTATED its argument" unless poisoned == frozen
    %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
       GEM_HOME GEM_PATH MANPATH RB_USER_INSTALL RUBYLIB].each do |k|
      abort "poison key #{k} survived: #{out[k].inspect}" if out.key?(k)
    end
    abort "ORIG residue survived: #{out.keys.grep(/\ABUNDLER_ORIG_/).inspect}" unless out.keys.grep(/\ABUNDLER_ORIG_/).empty?
    abort "ORIG-restore lost USER_VAR" unless out["USER_VAR"] == "keep-me"
    abort "PATH not restored to the ORIG record" unless out["PATH"] == "/usr/bin:/bin"
    abort "RUBYOPT not restored to the user original" unless out["RUBYOPT"] == "-w"
    belt = {
      "RUBYOPT" => "-r/x/y/bundler/setup -w -rother", "USER_VAR" => "keep-me",
      "BUNDLER_ORIG_USER_TAIL" => NIL
    }
    bout = Tart::ChildEnv.scrub(belt)
    abort "belt: the bundler setup token survived RUBYOPT: #{bout["RUBYOPT"].inspect}" unless bout["RUBYOPT"] == "-w -rother"
    dir = Dir.mktmpdir("i75-belt-")
    begin
      FileUtils.mkdir_p(File.join(dir, "bundler"))
      FileUtils.touch(File.join(dir, "bundler", "setup.rb"))
      blib = {
        "RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR),
        "BUNDLER_ORIG_RUBYLIB" => NIL
      }
      bluff = Tart::ChildEnv.scrub(blib)
      abort "a NIL ORIG record must DELETE RUBYLIB (records are authoritative, the belt never overrides them): #{bluff["RUBYLIB"].inspect}" if bluff.key?("RUBYLIB")
      blib2 = {"RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR)}
      b2 = Tart::ChildEnv.scrub(blib2)
      abort "belt-with-no-record must still strip the bundler lib dir: #{b2["RUBYLIB"].inspect}" unless b2["RUBYLIB"] == "/user/lib"
    ensure
      FileUtils.rm_rf(dir)
    end
    clean = {"PATH" => "/usr/bin:/bin", "HOME" => "/h", "USER_VAR" => "v"}
    cout = Tart::ChildEnv.scrub(clean)
    abort "clean env is not an identity: #{cout.inspect}" unless cout == clean
    empty = Tart::ChildEnv.scrub({})
    abort "empty env is not an identity: #{empty.inspect}" unless empty == {}
    puts "CHILD_ENV_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_LAW_OK

- id: child-env-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_env_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL child-env law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-env law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENV_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_UNITS_OK

- id: child-env-site-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 2 ] || { echo "FAIL bash seam pins runs=${runs1:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL bash seam pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/child_env/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL subagents seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/mcp_test.rb -n "/child_env/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 1 ] || { echo "FAIL mcp seam pins runs=${runs3:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL mcp seam pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo CHILD_ENV_SITE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_SITE_UNITS_OK

- id: bash-child-env-live
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    expected = lambda do |key|
      orig = ENV["BUNDLER_ORIG_#{key}"]
      orig.nil? ? :absent : (orig == NIL ? :absent : orig)
    end
    child_lines = lambda do |text|
      text.to_s.lines.map(&:strip).reject(&:empty?).to_h { |l| l.split("=", 2) }
    end
    check = lambda do |env, arm|
      %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
         GEM_HOME GEM_PATH MANPATH RUBYLIB RB_USER_INSTALL].each do |k|
        want = expected.call(k)
        if want == :absent
          abort "LIVE(#{arm}): #{k} reached the child: #{env[k].inspect}" if env.key?(k)
        else
          abort "LIVE(#{arm}): #{k}=#{env[k].inspect}, want the user-shell #{want.inspect}" unless env[k] == want
        end
      end
      abort "LIVE(#{arm}): RUBYOPT carries bundler poison: #{env["RUBYOPT"].inspect}" if env["RUBYOPT"].to_s.include?("bundler/setup")
      want_path = expected.call("PATH")
      abort "LIVE(#{arm}): no BUNDLER_ORIG_PATH record — the gate parent is not under bundle exec" if want_path == :absent
      abort "LIVE(#{arm}): PATH #{env["PATH"].inspect} is not the user-shell PATH" unless env["PATH"] == want_path
      abort "LIVE(#{arm}): BUNDLER_ORIG residue in the child" unless env.keys.grep(/\ABUNDLER_ORIG_/).empty?
    end
    tool = Tart::Tools::Bash.new(cwd: Dir.pwd)
    out = Async { tool.execute(command: "env", timeout: 30) }.wait
    abort "LIVE(tool): env dump failed: #{out.inspect}" if out.is_a?(Hash) && out[:error]
    tool_text = out.is_a?(String) ? out : out[:content].to_s
    check.call(child_lines.call(tool_text), "tool")
    user = Async { tool.run_user("env") }.wait
    check.call(child_lines.call(user.content), "run_user")
    cli = Async { tool.execute(command: "architect --version && gem --version", timeout: 60) }.wait
    abort "LIVE: the owner-class rubygems CLIs did not resolve in the child: #{cli.inspect}" if cli.is_a?(Hash) && cli[:error]
    puts "BASH_CHILD_ENV_LIVE_OK"'
  expect:
    exit_code: 0
    stdout_match: BASH_CHILD_ENV_LIVE_OK

- id: session-sink-config-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/config_law/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL config law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL config law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    if grep -nE "extensions (<<|\+=) .?.?session-sink" bin/tart; then echo "FAIL: a session-sink MOTD/extensions row was added (the no-row ruling)"; exit 1; fi
    bundle exec ruby -Ilib -e 'require "tart"
    abort "QUEUE_CAP moved" unless Tart::SessionSink::QUEUE_CAP == 2000
    abort "DEBOUNCE_MS moved" unless Tart::SessionSink::DEBOUNCE_MS == 250 && Tart::SessionSink::DEBOUNCE_MS <= 500
    abort "POST_TIMEOUT_MS moved" unless Tart::SessionSink::POST_TIMEOUT_MS == 8000
    abort "MAX_ATTEMPTS moved" unless Tart::SessionSink::MAX_ATTEMPTS == 3
    abort "RETRY_BACKOFF_MS moved" unless Tart::SessionSink::RETRY_BACKOFF_MS == [500, 1000]
    abort "SHUTDOWN_WAIT_MS moved" unless Tart::SessionSink::SHUTDOWN_WAIT_MS == 1000
    abort "SHUTDOWN_POST_TIMEOUT_MS moved" unless Tart::SessionSink::SHUTDOWN_POST_TIMEOUT_MS == 2000
    url = Tart::SessionSink.ingest_url("http://deck.test/")
    abort "ingest_url form moved: #{url.inspect}" unless url == "http://deck.test/conversations/ingest"
    puts "SESSION_SINK_CONSTANTS_OK"'
    echo SESSION_SINK_CONFIG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CONFIG_UNITS_OK

- id: session-sink-projection-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/projection/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL projection pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL projection pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"
    S = "018f0000-0000-7000-8000-000000000001"
    abort "record id law" unless Tart::SessionSink.record_id(S, 7) == "#{S}/7"
    u = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.user("hi there")}, S, 1)
    uj = JSON.parse(JSON.generate(u))
    um = uj["message"]
    abort "user record shape: #{uj.inspect}" unless uj["type"] == "message_end" && uj["id"] == "#{S}/1"
    abort "user blocks: #{um["content"].inspect}" unless um["role"] == "user" && um["content"] == [{"type" => "text", "text" => "hi there"}]
    abort "user timestamp: #{um["timestamp"].inspect}" unless um["timestamp"].is_a?(Integer) && um["timestamp"] > 1_700_000_000_000
    abort "user keys moved: #{um.keys.inspect}" unless um.keys.sort == ["content", "role", "timestamp"]
    call = Tart::Agent::ToolCall.new(id: "c1", name: "bash", arguments: {"command" => "ls"})
    am1 = Tart::Agent::Message.new(role: :assistant, content: "the answer", tool_calls: {"c1" => call},
      thinking: Tart::Agent::Thinking.new(text: "because", signature: "reasoning_content"),
      tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "tool_calls")
    a = Tart::SessionSink.project_event({type: :message_end, message: am1}, S, 2)
    aj = JSON.parse(JSON.generate(a))
    am = aj["message"]
    abort "assistant record id" unless aj["id"] == "#{S}/2"
    want_blocks = [{"type" => "thinking", "thinking" => "because", "thinkingSignature" => "reasoning_content"},
      {"type" => "text", "text" => "the answer"},
      {"type" => "toolCall", "id" => "c1", "name" => "bash", "arguments" => {"command" => "ls"}}]
    abort "assistant blocks: #{am["content"].inspect}" unless am["content"] == want_blocks
    abort "stopReason map: #{am["stopReason"].inspect}" unless am["stopReason"] == "toolUse"
    abort "usage map: #{am["usage"].inspect}" unless am["usage"] == {"input" => 5, "output" => 4, "cacheWrite" => 0}
    {"stop" => "end_turn", "length" => "maxTokens", "error" => "error"}.each do |fr, want|
      m = Tart::Agent::Message.new(role: :assistant, content: "x", finish_reason: fr)
      r = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: m}, S, 3)))
      abort "stopReason map #{fr}: #{r["message"]["stopReason"].inspect}" unless r["message"]["stopReason"] == want
    end
    quiet = Tart::Agent::Message.new(role: :assistant, content: "x")
    q = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: quiet}, S, 4)))
    abort "unreported usage must omit the key: #{q["message"].keys.inspect}" if q["message"].key?("usage")
    abort "absent finish_reason must omit stopReason: #{q["message"].keys.inspect}" if q["message"].key?("stopReason")
    t = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "ok-output", duration: 1.234}, S, 5)
    tj = JSON.parse(JSON.generate(t))
    want_tool = {"type" => "tool_execution_end", "id" => "#{S}/5", "toolCallId" => "c1", "toolName" => "bash",
      "result" => {"content" => [{"type" => "text", "text" => "ok-output"}]}, "isError" => false, "durationMs" => 1234}
    abort "tool record: #{tj.inspect}" unless tj == want_tool
    e = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: {"error" => "boom"}, duration: 0.5}, S, 6)
    ej = JSON.parse(JSON.generate(e))
    abort "isError law: #{ej.inspect}" unless ej["isError"] == true && ej.dig("result", "content", 0, "text") == JSON.generate({"error" => "boom"})
    p = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "x", duration: 0.5, parent_tool_call_id: "pc9"}, S, 7)
    abort "parentToolCallId present-only law" unless JSON.parse(JSON.generate(p))["parentToolCallId"] == "pc9"
    skip1 = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.tool(tool_call_id: "c1", content: "x")}, S, 8)
    skip2 = Tart::SessionSink.project_event({type: :message_start, message: Tart::Agent::Message.user("x")}, S, 9)
    abort "skip rules: #{skip1.inspect} #{skip2.inspect}" unless skip1.nil? && skip2.nil?
    puts "SESSION_SINK_PROJECTION_REPRO_OK"'
    echo SESSION_SINK_PROJECTION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_PROJECTION_UNITS_OK

- id: session-sink-engine-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/engine/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL engine pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL engine pins ec=$ec"; echo "$out1" | tail -10; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/boot/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 5 ] || { echo "FAIL process-level boot pins runs=${runs2:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL process-level boot pins ec=$ec"; echo "$out2" | tail -12; exit 1; }
    echo SESSION_SINK_ENGINE_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_ENGINE_E2E_OK

- id: session-sink-child-e2e
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/child_capture/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL child-capture pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-capture pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    echo SESSION_SINK_CHILD_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CHILD_E2E_OK

- id: signal-hygiene-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/routing/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL routing pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL routing pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/teardown/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 6 ] || { echo "FAIL teardown pins runs=${runs2:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL teardown pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"
    codes = Tart::TUI::SignalGuard::EXIT_FOR
    abort "EXIT_FOR moved: #{codes.inspect}" unless codes == {"HUP" => 129, "TERM" => 143}
    bound = Tart::TUI::SignalGuard::EXIT_BOUND_S
    abort "EXIT_BOUND_S moved: #{bound.inspect}" unless bound == 10
    puts "SIGNAL_CONSTANTS_OK"'
    echo SIGNAL_HYGIENE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SIGNAL_HYGIENE_UNITS_OK

- id: signal-orphan-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t87sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t87sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK

- id: subagent-box-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagent_box_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 12 ] || { echo "FAIL box pins runs=${runs1:-0} (want >=12; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL box pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENT_BOX_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_BOX_UNITS_OK


- id: subagent-status-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagent-status-probe ]; then echo "FAIL subagent-status-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t87sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t87sb
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_STATUS_OK

- id: child-encoding-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_encoding_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 7 ] || { echo "FAIL encoding pins runs=${runs1:-0} (want >=7; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENCODING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_UNITS_OK

- id: child-encoding-e2e
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/encoding_e2e/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 1 ] || { echo "FAIL encoding e2e runs=${runs1:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding e2e ec=$ec"; echo "$out1" | tail -20; exit 1; }
    echo CHILD_ENCODING_E2E_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_E2E_OK

- id: runner-encoding-direct
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest -e 'require "tmpdir"; require "fileutils"; require "json"; require_relative "test/support/mock_llm_server"
    prompt = "I80 runner: the Diataxis-note payload Diátaxis résumé — á é ü ✓ (em-dash —)"
    answer = "I80 runner answer: Diátaxis résumé ✓ — á é ü OK"
    home = Dir.mktmpdir("i80rd-")
    server = MockLLMServer.new.start
    server.script([{type: :stream, content: answer}])
    env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi", "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "zai/glm-5.3-e2e", "TART_MCP_CONFIG" => File.join(home, "absent.json")}
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    pid = Process.spawn(env, RbConfig.ruby, "bin/tart", "-p", prompt, home, chdir: Dir.pwd, unsetenv_others: true, pgroup: true, out: out_w, err: err_w)
    out_w.close
    err_w.close
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 120
    status = nil
    loop do
      _p, status = Process.waitpid2(pid, Process::WNOHANG)
      break if status
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        begin
          Process.kill("-KILL", -pid)
        rescue StandardError
          nil
        end
        Process.waitpid2(pid)
        abort "I80 direct: parent watchdog fired"
      end
      sleep 0.1
    end
    stdout = out_r.read
    stderr = err_r.read
    out_r.close
    err_r.close
    abort "I80 direct: exit #{status.exitstatus} (stderr: #{stderr.lines.first})" unless status.exitstatus == 0
    abort "I80 direct: stdout mismatch (#{stdout.bytesize}B)" unless stdout.chomp == answer
    hits = stderr.scan("passed as BINARY").size
    abort "I80 direct: #{hits} JSON.generate encoding warning(s) on the runner stderr" unless hits.zero?
    logs = server.captured_request_logs
    body = logs.find { |log| (log[:body]["messages"] || []).any? { |m| m["content"].to_s.include?(prompt) } }
    abort "I80 direct: no wire request carries the non-ASCII prompt" unless body
    server.stop
    FileUtils.rm_rf(home)
    puts "RUNNER_ENCODING_DIRECT_OK"'
  expect:
    exit_code: 0
    stdout_match: RUNNER_ENCODING_DIRECT_OK

- id: agent-loading-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # Leg 1 — the full profiles battery GREEN (>= 15 runs, the base count;
    # the re-pinned reject/shape pins plus the new warn-and-drop pins).
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_profiles_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 15 ] || { echo "FAIL profiles battery runs=${runs1:-0} (want >=15)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL profiles battery ec=$ec"; echo "$out1" | tail -8; exit 1; }
    # Leg 2 — the warn-and-drop discriminators (declared-RED at base:
    # the /dropped/ filter is empty there).
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_profiles_test.rb -n "/dropped/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL warn-and-drop pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL warn-and-drop pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo AGENT_LOADING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_LOADING_UNITS_OK

- id: nested-grant-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # Leg 1 — the full subagents battery GREEN (>= 34 runs, the base
    # count; carries the re-pinned argv/env/task pins).
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 34 ] || { echo "FAIL subagents battery runs=${runs1:-0} (want >=34)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents battery ec=$ec"; echo "$out1" | tail -8; exit 1; }
    # Leg 2 — the nested-grant discriminators (declared-RED at base:
    # the /nested|depth_cap/ filter is empty there).
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/nested|depth_cap/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 3 ] || { echo "FAIL nested-grant pins runs=${runs2:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL nested-grant pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo NESTED_GRANT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: NESTED_GRANT_UNITS_OK

- id: forensics-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # The forensics discriminators (declared-RED at base: the /forensic/
    # filter is empty there).
    out=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/forensic/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL forensics pins runs=${runs:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL forensics pins ec=$ec"; echo "$out" | tail -8; exit 1; }
    echo FORENSICS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: FORENSICS_UNITS_OK

- id: agent-loading-e2e
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # The nested-spawn e2e leg (declared-RED at base: the /nested/ filter
    # is empty there). Real bin/tart print subprocesses, mock endpoint,
    # staged HOME — the leg-A harness shape, one nesting deeper.
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/nested/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL nested e2e runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL nested e2e ec=$ec"; echo "$out" | tail -8; exit 1; }
    echo AGENT_LOADING_E2E_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_LOADING_E2E_OK

- id: listing-teardown-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The teardown-bounded listing close, unit-pinned: the whole listing
    # battery green (the carried request-log pins byte-identical — the
    # GET /models + Bearer + Accept wire facts never move), PLUS the NEW
    # prompt-return pin (declared-new — runs=0 at base, the empty-filter
    # class): a non-200 listing fetch with timeout: 1 returns nil within
    # a tight bound. Measured base: the first non-200 fetch in a process
    # stalls ~6.0 s in the pool-drain wait (listing.rb:86 client.close →
    # async-http client.rb:90 → async-pool controller.rb:145); the pin
    # freezes the cure at <= 2.5 s elapsed.
    bundle install --quiet
    out=$(bundle exec ruby -Itest test/models_listing_test.rb 2>&1)
    echo "$out" | tail -3
    echo "$out" | grep -q "0 failures, 0 errors" || { echo "FAIL: listing-teardown — the listing battery is not green"; exit 1; }
    pin=$(bundle exec ruby -Itest test/models_listing_test.rb -n "/failure_path_returns_promptly/" 2>&1)
    echo "$pin" | tail -3
    echo "$pin" | grep -qE "(^|[^0-9])1 runs," || { echo "FAIL: listing-teardown — the prompt-return pin is absent (filter runs=0)"; exit 1; }
    echo LISTING_TEARDOWN_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_TEARDOWN_OK

- id: contention-proof
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # The de-flake proof: the converted timing-window battery — the
    # escape-interrupt wedge test (the plan's named proof point), the
    # three agent_loop boundary tests, the subagents steer-receipt pair —
    # runs GREEN under deliberate 8-way CPU steal, every leg inside a
    # watchdog bound. A hang is killed and FAILS the gate: the anti-wedge
    # law is that a missed timing window fails loud, never wedges the
    # suite. Filter/run counts verified at base this session: 1 / 3 / 2
    # runs, all green un-contended; ALL THREE legs measured green under
    # 8-way steal in the first rehearsal (0.4 s / 26.4 s / 27.0 s).
    bundle install --quiet
    cat > t87contention.rb <<'HARNESS'
    kids = []
    8.times { kids << Process.spawn(RbConfig.ruby, "-e", "i = 0; loop { i += 1 }") }
    at_exit { kids.each { |p| Process.kill("KILL", p) rescue nil } }
    legs = [
      ["test/chat_test.rb", "/escape_interrupts_a_streaming_run_through_the_kernel_path/", 90],
      ["test/agent_loop_test.rb", "/inbox_file_is_skipped|inbox_file_is_consumed_at_the_turn_boundary|file_interrupts_the_run_at_the_boundary/", 150],
      ["test/subagents_test.rb", "/steer_receipt/", 150]
    ]
    legs.each do |file, filter, bound|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      pid = Process.spawn(RbConfig.ruby, "-Itest", file, "-n", filter,
                          out: "t87cont-out.txt", err: "t87cont-err.txt")
      status = nil
      loop do
        _, status = Process.waitpid2(pid, Process::WNOHANG)
        break if status
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 > bound
          Process.kill("KILL", pid) rescue nil
          _, status = Process.waitpid2(pid)
          warn "FAIL: contention — #{file} #{filter} hit the #{bound}s watchdog (hang)"
          exit 1
        end
        sleep 0.2
      end
      puts format("CONTEND %-28s exit=%d wall=%.1fs", file, status.exitstatus,
                  Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
      exit 1 unless status.exitstatus.to_i.zero?
    end
    puts "CONTENTION_OK"
    HARNESS
    bundle exec ruby t87contention.rb
    ec=$?
    rm -f t87contention.rb t87cont-out.txt t87cont-err.txt
    [ "$ec" -eq 0 ] || exit 1
    echo CONTENTION_OK
  expect:
    exit_code: 0
    stdout_match: CONTENTION_OK
- id: sweep-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The wrapper's contract, unit-pinned in the rig's own test tree (the
    # sanctioned pin home): hermetic --list/aggregation-shape legs run
    # IN-SUITE (no app boots); the live aggregation legs (real small sweeps
    # — {s1}->0, {s1,s1_tart}->1, {s1,missing}->2, the report shape) ride
    # TUI_SPLIT_RIG_LIVE=1 (the live_run_test discipline). Declared-RED at
    # base: the test file is absent (declared-new).
    if [ ! -f gems/tui-split-rig/test/sweep_test.rb ]; then echo "FAIL sweep-units: gems/tui-split-rig/test/sweep_test.rb missing (declared-new)"; exit 1; fi
    bundle install --quiet
    out=$(TUI_SPLIT_RIG_LIVE=1 bundle exec ruby -Itest gems/tui-split-rig/test/sweep_test.rb 2>&1); ec=$?
    echo "$out" | tail -4
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 8 ] || { echo "FAIL sweep-units: pins runs=${runs:-0} (want >=8; 0 = filter empty)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL sweep-units: battery ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo SWEEP_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SWEEP_UNITS_OK
- id: sweep-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # THE cold parity gate: the concurrent sweep (default jobs) reproduces
    # the serial sweep's (--jobs 1) per-scenario exit codes — both legs
    # through the wrapper, equal-length out roots (t87psp / t87pcp, 6 chars,
    # the per-scenario dirs 12 chars — inside the measured <=20-char green
    # geometry window, Grounds). ALSO frozen: the base-measured battery
    # table itself (exactly s1_tart=1, s11_memory_recall=1,
    # s13_command_while_streaming=2, s18_error_transcript=1; every other of
    # the 19 == 0) — anchoring the uncarried green scenarios (s12/s14/s15/
    # s16) the carried battery misses. Aggregate = max(per-scenario codes)
    # == the sweep process exit, BOTH legs. Concurrent wall <= 40 s at
    # default jobs (measured base: 19.05 s at 8-way). Declared-RED at base:
    # the wrapper bin is absent (declared-new).
    if [ ! -x gems/tui-split-rig/bin/tui-split-rig-sweep ]; then echo "FAIL sweep-parity: gems/tui-split-rig/bin/tui-split-rig-sweep missing (declared-new)"; exit 1; fi
    SWEEP=gems/tui-split-rig/bin/tui-split-rig-sweep
    rm -rf t87psp t87pcp
    t0=$(date +%s%N)
    "$SWEEP" --jobs 1 --out t87psp >/dev/null 2>&1; ser_ec=$?
    t1=$(date +%s%N)
    ser_wall=$(( (t1-t0)/1000000 ))
    t0=$(date +%s%N)
    "$SWEEP" --out t87pcp >/dev/null 2>&1; con_ec=$?
    t1=$(date +%s%N)
    con_wall=$(( (t1-t0)/1000000 ))
    comp=$(ruby -rjson -e '
    ser = JSON.parse(File.read("t87psp/sweep-report.json"))
    con = JSON.parse(File.read("t87pcp/sweep-report.json"))
    stab = ser["scenarios"].map { |s| [s["name"], s["exit_code"]] }
    ctab = con["scenarios"].map { |s| [s["name"], s["exit_code"]] }
    abort "FAIL sweep-parity: serial/concurrent tables differ:\nserial=#{stab.inspect}\nconcurrent=#{ctab.inspect}" unless stab == ctab
    frozen = { "s1_tart" => 1, "s11_memory_recall" => 1, "s13_command_while_streaming" => 2, "s18_error_transcript" => 1 }
    bad = stab.reject { |n, e| frozen.fetch(n, 0) == e }
    abort "FAIL sweep-parity: table drift vs the frozen base battery table: #{bad.inspect} (frozen nonzero: #{frozen.inspect})" unless bad.empty?
    smax = stab.map { |_, e| e }.max
    cmax = ctab.map { |_, e| e }.max
    abort "FAIL sweep-parity: serial aggregate #{ser["aggregate_exit_code"].inspect} != max #{smax}" unless ser["aggregate_exit_code"] == smax
    abort "FAIL sweep-parity: concurrent aggregate #{con["aggregate_exit_code"].inspect} != max #{cmax}" unless con["aggregate_exit_code"] == cmax
    puts "SWEEP_TABLE_OK #{stab.size} scenarios aggregate=#{smax}"
    ' 2>&1); ec=$?
    echo "$comp"
    [ "$ec" -eq 0 ] || exit 1
    [ "$ser_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t87psp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: serial process exit $ser_ec != report aggregate"; exit 1; }
    [ "$con_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t87pcp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: concurrent process exit $con_ec != report aggregate"; exit 1; }
    [ "$con_wall" -le 40000 ] || { echo "FAIL sweep-parity: concurrent wall ${con_wall}ms exceeds the frozen 40000ms bound (serial ${ser_wall}ms)"; exit 1; }
    echo "SWEEP_PARITY_OK serial_wall=${ser_wall}ms concurrent_wall=${con_wall}ms serial_ec=$ser_ec concurrent_ec=$con_ec"
  expect:
    exit_code: 0
    stdout_match: SWEEP_PARITY_OK
- id: sweep-crosstalk
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # The no-cross-talk proof, at the lane tree: TWO concurrent sweeps (the
    # same 6-scenario carried-green subset s2-s7, default jobs each) with a
    # solo gate-shaped single-scenario rig run (s1_text_turn, the standing
    # env-scrub discipline inline) IN FLIGHT — 13 concurrent scenarios, ~26
    # app boots. All three legs must reproduce their solo shapes: solo ec 0,
    # both sweeps aggregate 0 with all-0 tables, and ZERO leftover
    # tui-split-rig-* tmux sessions at the end. I27 token scoping is the
    # mechanism; this gate proves it holds under the wrapper. Declared-RED
    # at base: the wrapper bin is absent (declared-new).
    if [ ! -x gems/tui-split-rig/bin/tui-split-rig-sweep ]; then echo "FAIL sweep-crosstalk: gems/tui-split-rig/bin/tui-split-rig-sweep missing (declared-new)"; exit 1; fi
    SWEEP=gems/tui-split-rig/bin/tui-split-rig-sweep
    ONLY="s2_tool_turn,s3_tool_turn_files,s4_bash_variants,s5_bash_truncation,s6_long_calls,s7_compaction"
    rm -rf t87xa t87xb t87xo
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t87xo >/dev/null 2>&1 & solo=$!
    "$SWEEP" --only "$ONLY" --out t87xa >/dev/null 2>&1 & a=$!
    "$SWEEP" --only "$ONLY" --out t87xb >/dev/null 2>&1 & b=$!
    wait $solo; solo_ec=$?
    wait $a; a_ec=$?
    wait $b; b_ec=$?
    [ "$solo_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: the solo s1 run ec=$solo_ec — flaked by the concurrent sweeps"; exit 1; }
    [ "$a_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep A aggregate ec=$a_ec"; exit 1; }
    [ "$b_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep B aggregate ec=$b_ec"; exit 1; }
    comp=$(ruby -rjson -e '
    want = %w[s2_tool_turn s3_tool_turn_files s4_bash_variants s5_bash_truncation s6_long_calls s7_compaction]
    %w[t87xa t87xb].each do |root|
      rep = JSON.parse(File.read("#{root}/sweep-report.json"))
      tab = rep["scenarios"].map { |s| [s["name"], s["exit_code"]] }
      abort "FAIL sweep-crosstalk: #{root} table #{tab.inspect}" unless tab == want.map { |n| [n, 0] }
      abort "FAIL sweep-crosstalk: #{root} aggregate #{rep["aggregate_exit_code"].inspect}" unless rep["aggregate_exit_code"] == 0
    end
    puts "CROSS_TALK_TABLES_OK"
    ' 2>&1); ec=$?
    echo "$comp"
    [ "$ec" -eq 0 ] || exit 1
    left=$(tmux ls 2>/dev/null | grep -c tui-split-rig || true)
    [ "${left:-0}" -eq 0 ] || { echo "FAIL sweep-crosstalk: ${left} leftover tui-split-rig tmux sessions"; tmux ls 2>/dev/null | grep tui-split-rig; exit 1; }
    echo CROSS_TALK_OK
  expect:
    exit_code: 0
    stdout_match: CROSS_TALK_OK
- id: parallel-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The runner's laws pinned hermetically in the suite's own tree (the
    # NEW test/parallel_runner_test.rb — declared-NEW at base, so this gate
    # is declared-RED there on the absent-file leg). In-suite legs only —
    # no full-suite runs inside the battery (the heavy legs live in
    # parallel-parity / parallel-repeat). Every comparison gates its own
    # exit (the gate shell has no set -e — the I83 lesson).
    if [ ! -f test/parallel_runner_test.rb ]; then echo "FAIL parallel-units: test/parallel_runner_test.rb missing (declared-new)"; exit 1; fi
    bundle install --quiet
    out=$(bundle exec ruby -Itest -Ilib test/parallel_runner_test.rb 2>&1); ec=$?
    echo "$out" | tail -4
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 8 ] || { echo "FAIL parallel-units: pins runs=${runs:-0} (want >=8; 0 = battery absent/empty)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-units: battery ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo PARALLEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_UNITS_OK

- id: parallel-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # The full parallel run, cold, timed: exit 0, the clean PARALLEL_OK
    # summary (0F/0E), the COVERAGE audit (runs == enum — the structural
    # verdict-parity proof: the enumerated set is pinned == rake test's own
    # FileList by the units battery, and every enumerated test ran exactly
    # once), and wall <= 90000 ms (frozen floor; measured 51.7/50.8 s at 8
    # workers vs 213.6 s serial the same session). Plus the Rakefile
    # additivity leg: zero deleted lines vs base — `rake test` stays
    # byte-stable. Declared-RED at base: `rake test:par` does not exist.
    # FLAKE PREAMBLE AMENDED at I87 (declared delta (d), comment-only): the
    # chat-interrupt loud-red class (a) and the subagents-e2e drain-timing
    # class (f) are CURED at I87 — measured by the frozen deflake-par-streak
    # cure bar (16 consecutive full runs, zero firings). They are NO LONGER
    # live note-and-pass classes: a red whose signature is (a) or (f) is a
    # REAL failure — investigate, never adjudicate away. The remaining
    # declared suite order/env classes (e) keep the standing note-and-pass
    # with cold re-run, identical to the serial suite gate's adjudication.
    rm -rf t87par; mkdir -p t87par
    s=$(date +%s%N)
    bundle exec rake test:par > t87par/par.log 2>&1; ec=$?
    e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
    echo "wall_ms=$ms ec=$ec"
    tail -6 t87par/par.log
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-parity: rake test:par ec=$ec"; exit 1; }
    grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t87par/par.log || { echo "FAIL parallel-parity: no clean PARALLEL_OK summary line"; exit 1; }
    grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t87par/par.log || { echo "FAIL parallel-parity: coverage audit line absent/malformed"; exit 1; }
    cov=$(grep -oE "^COVERAGE_OK runs=[0-9]+" t87par/par.log | grep -oE "[0-9]+$")
    enum=$(grep -oE "enum=[0-9]+" t87par/par.log | head -1 | cut -d= -f2)
    [ "$cov" = "$enum" ] || { echo "FAIL parallel-parity: COVERAGE runs=$cov != enum=$enum"; exit 1; }
    [ "$ms" -le 90000 ] || { echo "FAIL parallel-parity: wall ${ms}ms > 90000ms floor"; exit 1; }
    dels=$(git diff 40ed92b -- Rakefile | grep -cE "^-[^-]" || true)
    [ "$dels" -eq 0 ] || { echo "FAIL parallel-parity: Rakefile diff has $dels deleted lines — rake test must stay byte-stable"; exit 1; }
    echo PARALLEL_PARITY_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_PARITY_OK

- id: parallel-repeat
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # Repeat determinism: THREE consecutive full parallel runs — each exit
    # 0, each wall <= 90000 ms, runs/skips literals IDENTICAL across the
    # three, assertions within the standing dynamic-counter band (spread
    # <= 20 across the three — RE-MEASURED on ruby 4.0.9 at I85 base
    # 40ed92b: the 4.0.7-era band was <= 10 (measured 7032-7040 vs serial
    # 7034 on the pre-I84-merge suite); on 4.0.9 the dynamic counters swing
    # wider — measured sample at spec time: parallel 10108/10122/10122/
    # 10123/10123 + serial 10108 == spread 15 across the green runs; the
    # band keeps discriminating power (a lost test moves assertions by
    # tens-hundreds) while absorbing the 4.0.9 swing).
    # Same amended flake preamble as parallel-parity: classes (a)/(f) CURED
    # at I87 — no longer adjudicable note-and-pass; the suite order/env
    # classes (e) ride the standing discipline.
    rm -rf t87rep; mkdir -p t87rep
    prev=""
    i=1
    while [ $i -le 3 ]; do
      s=$(date +%s%N)
      bundle exec rake test:par > t87rep/r$i.log 2>&1; ec=$?
      e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
      line=$(grep -E "^PARALLEL_OK runs=" t87rep/r$i.log | head -1)
      echo "run $i: ec=$ec wall_ms=$ms $line"
      [ "$ec" -eq 0 ] || { echo "FAIL parallel-repeat: run $i ec=$ec"; tail -8 t87rep/r$i.log; exit 1; }
      [ -n "$line" ] || { echo "FAIL parallel-repeat: run $i has no PARALLEL_OK summary"; exit 1; }
      [ "$ms" -le 90000 ] || { echo "FAIL parallel-repeat: run $i wall ${ms}ms > 90000ms"; exit 1; }
      key=$(echo "$line" | grep -oE "runs=[0-9]+|skips=[0-9]+" | tr "\n" " ")
      if [ -n "$prev" ] && [ "$key" != "$prev" ]; then echo "FAIL parallel-repeat: runs/skips literal drifted between runs: '$prev' -> '$key'"; exit 1; fi
      prev="$key"
      echo "$line" | grep -oE "assertions=[0-9]+" >> t87rep/asserts.txt
      i=$((i + 1))
    done
    lo=$(sort -t= -k2 -n t87rep/asserts.txt | head -1 | cut -d= -f2)
    hi=$(sort -t= -k2 -n t87rep/asserts.txt | tail -1 | cut -d= -f2)
    echo "assertions spread: $lo-$hi"
    [ $((hi - lo)) -le 20 ] || { echo "FAIL parallel-repeat: assertions spread $hi-$lo exceeds the ±20 dynamic-counter band (re-measured on 4.0.9 at I85)"; exit 1; }
    echo PARALLEL_REPEAT_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_REPEAT_OK

- id: ruby-pin
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The pin is a committed FILE fact. Base-vs-lane ruby-version
    # discrimination is NOT available via the runtime alone (global mise
    # `latest` already resolves 4.0.9 — the plan header), so the
    # .ruby-version CONTENT is the discriminating leg; the runtime legs
    # prove the file actually drives the resolution. At the I87 base
    # 40ed92b the pin is LANDED (I85 integrated): this gate is a
    # re-verification GUARD now — GREEN-expected at base, RED only on a
    # regression of the pin or its floor/lock legs.
    [ -f .ruby-version ] || { echo "FAIL ruby-pin: .ruby-version absent (declared-new)"; exit 1; }
    content=$(cat .ruby-version)
    [ "$content" = "4.0.9" ] || { echo "FAIL ruby-pin: content '$content', want exactly 4.0.9"; exit 1; }
    lines=$(wc -l < .ruby-version | tr -d " ")
    [ "$lines" = "1" ] || { echo "FAIL ruby-pin: $lines lines, want exactly one"; exit 1; }
    cur=$(mise current ruby 2>/dev/null || echo unavailable)
    [ "$cur" = "4.0.9" ] || { echo "FAIL ruby-pin: mise current ruby = '$cur', want 4.0.9"; exit 1; }
    case "$(ruby -v)" in "ruby 4.0.9 "*) ;; *) echo "FAIL ruby-pin: ruby -v = $(ruby -v)"; exit 1;; esac
    grep -qF 'spec.required_ruby_version = ">= 3.3"' tart.gemspec || { echo "FAIL ruby-pin: the >= 3.3 gemspec floor moved (ruled a FLOOR, unchanged)"; exit 1; }
    git diff --quiet 40ed92b -- Gemfile tart.gemspec || { echo "FAIL ruby-pin: Gemfile/gemspec touched"; exit 1; }
    # Gemfile.lock: byte-unchanged OR exactly the DECLARED bundler
    # self-checksum heal (measured at spec time, this session: bundler
    # 4.0.22's `bundle install` adds its own CHECKSUMS line — `bundler
    # (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d6
    # 1979242a5d75a` — deterministically, under the new runtime; the battery's
    # own `bundle install --quiet` legs produce it at any pristine tree).
    # Any other lock movement is itemize-and-defend PHASE 0.
    badlock=$(git diff 40ed92b -- Gemfile.lock | grep -E "^[-+][^-+]" | grep -vE "^\+  bundler \([0-9.]+\) sha256=[0-9a-f]{64}$" || true)
    [ -z "$badlock" ] || { echo "FAIL ruby-pin: Gemfile.lock moved beyond the declared bundler self-checksum class:"; echo "$badlock"; exit 1; }
    echo RUBY_PIN_OK
  expect:
    exit_code: 0
    stdout_match: RUBY_PIN_OK

- id: native-bundle
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # The full bundle resolves under 4.0.9 and the ratatui_ruby 1.5.0 native
    # extension — compiled from source on THIS ruby (cargo/rustc on the
    # host) — loads and answers. The .bundle living under THIS ruby's
    # Gem.default_dir plus a successful load IS the ABI proof (a foreign-ruby
    # .bundle would not be on the load path and would not load).
    # Gem.default_dir, NOT Gem.dir: the architect CLI binstub pins GEM_HOME
    # to its own libexec, so under `architect rehearse`/`architect gate`
    # Gem.dir resolves to the harness home — a false RED (measured at the
    # first I85 rehearsal). default_dir is RbConfig-derived from the RUNNING
    # ruby — immune to the harness env, still the ABI proof.
    # GREEN-expected at base (re-verification gate: the base already boots
    # 4.0.9 via global mise latest — the plan header).
    bundle install --quiet
    bundle exec ruby -e 'require "ratatui_ruby"
    abort "ruby moved: #{RUBY_DESCRIPTION}" unless RUBY_DESCRIPTION.start_with?("ruby 4.0.9 ")
    abort "gem missing" unless defined?(RatatuiRuby) && RatatuiRuby.respond_to?(:poll_event)
    paths = $LOADED_FEATURES.grep(%r{ratatui_ruby/.*\.bundle$})
    abort "native extension not loaded" if paths.empty?
    abort "native extension not from this ruby gem home: #{paths} vs #{Gem.default_dir}" unless paths.all? { |p| p.start_with?(Gem.default_dir) }
    spec = Gem.loaded_specs["ratatui_ruby"]
    abort "version moved: #{spec.version}" unless spec.version.to_s == "1.5.0"
    abort "native probe failed" unless RatatuiRuby.terminal_active? == false
    puts "NATIVE_BUNDLE_OK #{paths.first}"'
  expect:
    exit_code: 0
    stdout_match: NATIVE_BUNDLE_OK

- id: premise-remeasure
  ac: AC4
  cwd: repos/tart
  cmd: |-
    # The I75 premise re-measurement (RECORD, DON'T ACT): does plain exit(N)
    # still wedge in rb_ec_cleanup->rb_thread_terminate_all on ruby 4.0.9
    # under the I75 native wedge (a poller thread inside the gem's native
    # poll_event on a pty that dies under it — the signal harness's
    # real-wedge shape, F4/F6)? Two differential legs share one wedge app:
    # leg plain calls exit(42) (THE MEASUREMENT), leg bang calls exit!(42)
    # (the landed cure primitive — the control). Each leg boots in tmux
    # (the I75 harness boot pattern: a surviving ruby wrapper records the
    # wire status), proves the wedge REAL (Thread#kill unrecoverable — the
    # F4 mechanic, events.rs passes no unblock function), then the driver
    # watches: EXIT=42 within the bound = escapes; silence at the deadline
    # then kill -9 = wedged. GREEN on EITHER plain-leg outcome (the
    # deliverable is the measured yes/no in the Builder Report); RED if the
    # wedge fails to build, if the exit! control fails to escape (the cure
    # itself would have moved — a material finding), or on an unexpected
    # code. Measured at base 40ed92b this session (ruby 4.0.9): wedge=real
    # both legs, plain=stands (silence, kill -9, EXIT=137), hard=escapes
    # (EXIT=42 in ~2 s).
    rm -rf t87pre; mkdir -p t87pre
    cat > t87pre/wedge_app.rb <<'WEDGE_APP'
    # frozen_string_literal: true
    require "ratatui_ruby"
    dir, mode = ARGV
    trap("HUP", "IGNORE")
    trap("TERM", "IGNORE")
    RatatuiRuby.run do |_tui|
      poller = Thread.new { loop { RatatuiRuby.poll_event(timeout: 0.05) } }
      File.write(File.join(dir, "ready"), "ready")
      sleep 0.1 until File.exist?(File.join(dir, "go"))
      poller.kill
      poller.join(2)
      File.write(File.join(dir, "wedge.txt"), poller.alive? ? "real" : "failed")
      if mode == "plain"
        exit(42)
      else
        exit!(42)
      end
    end
    WEDGE_APP
    cat > t87pre/wedge_wrapper.rb <<'WEDGE_WRAP'
    # frozen_string_literal: true
    dir, root, mode = ARGV
    trap("HUP") {}
    $stderr.reopen(File.join(dir, "stderr.log"), "a")
    pid = Process.spawn(
      {"BUNDLE_GEMFILE" => File.join(root, "Gemfile"), "BUNDLE_FROZEN" => "true"},
      "bundle", "exec", "ruby", File.join(dir, "wedge_app.rb"), dir, mode,
      chdir: root
    )
    File.write(File.join(dir, "app.pid"), pid.to_s)
    _p, st = Process.wait2(pid)
    raw = st.exited? ? st.exitstatus : 128 + (st.termsig || 0)
    File.write(File.join(dir, "exit.txt"), "EXIT=#{raw}")
    WEDGE_WRAP
    plain_verdict=""
    for mode in plain bang; do
      rm -f t87pre/ready t87pre/go t87pre/exit.txt t87pre/wedge.txt t87pre/app.pid
      sess="t87pre-$mode"
      tmux kill-session -t "$sess" 2>/dev/null || true
      tmux new-session -d -x 120 -y 40 -c "$PWD" -s "$sess" "exec ruby $PWD/t87pre/wedge_wrapper.rb $PWD/t87pre $PWD $mode" || { echo "FAIL premise-remeasure: tmux boot refused"; exit 1; }
      i=0; while [ ! -f t87pre/ready ] && [ $i -lt 150 ]; do sleep 0.1; i=$((i+1)); done
      [ -f t87pre/ready ] || { echo "FAIL premise-remeasure: $mode leg never settled"; tmux kill-session -t "$sess" 2>/dev/null; exit 1; }
      tmux kill-session -t "$sess"
      sleep 1
      touch t87pre/go
      i=0; while [ ! -f t87pre/exit.txt ] && [ $i -lt 120 ]; do sleep 0.1; i=$((i+1)); done
      if [ ! -f t87pre/exit.txt ]; then
        kill -9 $(cat t87pre/app.pid) 2>/dev/null || true
        i=0; while [ ! -f t87pre/exit.txt ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
      fi
      code=$(sed "s/EXIT=//" t87pre/exit.txt 2>/dev/null)
      wedge=$(cat t87pre/wedge.txt 2>/dev/null)
      echo "leg $mode: wedge=$wedge code=$code"
      [ "$wedge" = "real" ] || { echo "FAIL premise-remeasure: $mode leg wedge failed to build — the measurement is invalid"; exit 1; }
      if [ "$mode" = "bang" ]; then
        [ "$code" = "42" ] || { echo "FAIL premise-remeasure: the exit! control did NOT escape (code=$code) — the I75 cure primitive moved on this runtime"; exit 1; }
      else
        case "$code" in
          42) plain_verdict="moved" ;;
          137) plain_verdict="stands" ;;
          *) echo "FAIL premise-remeasure: plain leg unexpected code=$code"; exit 1 ;;
        esac
      fi
    done
    rm -rf t87pre
    echo "PREMISE_PROBE_OK wedge=real plain=$plain_verdict hard=escapes"
  expect:
    exit_code: 0
    stdout_match: PREMISE_PROBE_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    # I87 REWRITE (the per-iteration scope rewrite). Frozen touch set:
    # test/chat_test.rb + test/subagents_e2e_test.rb (the firing test
    # files) + test/support/mock_llm_server.rb (the declared-possible
    # test-support seam for the class-(f) deterministic-ordering cure) —
    # PLUS at most ONE NEW file under test/support/ (untracked at the
    # lane tree — builders never commit; its presence REQUIRES a Builder
    # Report itemize-and-defend entry). Tracked diff vs 40ed92b is
    # confined to the three named files. Gemfile.lock moves ZERO bytes at
    # this base: the bundler self-checksum heal line LANDED at 40ed92b
    # (I85 integration) — `bundle install` at a pristine tree is
    # diff-silent now (measured at spec time, this session). ANY lib/
    # movement is a forensics-proven-production-defect PHASE 0 event
    # (judged per the I77 precedent — this gate REDs and the judge
    # adjudicates the itemization). Declared-RED at base: the must-differ
    # leg (a lane that touches NEITHER firing test file has cured
    # nothing). Untracked-scratch filter: the t75-t87 era families incl.
    # mktemp dot+mixed-case suffixes, the standing tmp/ families, the one
    # sanctioned new test-support file.
    bad=$(git diff --name-only 40ed92b -- . | grep -vE "^(test/chat_test\.rb|test/subagents_e2e_test\.rb|test/support/mock_llm_server\.rb)$" || true)
    [ -z "$bad" ] || { echo "FAIL scope: tracked diff vs 40ed92b outside the frozen touch set:"; echo "$bad"; exit 1; }
    touched=$(git diff --name-only 40ed92b -- test/chat_test.rb test/subagents_e2e_test.rb | grep -cE "^test/(chat_test|subagents_e2e_test)\.rb$" || true)
    [ "$touched" -ge 1 ] || { echo "FAIL scope: must-differ — no firing test file touched (the cure is absent)"; exit 1; }
    newsup=$(git status --porcelain | grep "^??" | cut -c4- | grep -E "^test/support/[a-z0-9_]+\.rb$" || true)
    ncount=$(echo "$newsup" | grep -c . || true)
    [ "$ncount" -le 1 ] || { echo "FAIL scope: more than ONE new test-support file (the frozen sanction):"; echo "$newsup"; exit 1; }
    if (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(test/support/[a-z0-9_]+\.rb|t7[5-9][0-9a-zA-Z.]*/?|t8[0-7][0-9a-zA-Z.]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$" | grep -q .; then
      echo "FAIL scope: out-of-bounds untracked paths:"; (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(test/support/[a-z0-9_]+\.rb|t7[5-9][0-9a-zA-Z.]*/?|t8[0-7][0-9a-zA-Z.]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$"; exit 1
    fi
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK

- id: deflake-par-streak
  ac: AC4
  cwd: repos/tart
  cmd: |-
    # THE CURE BAR (N frozen = 16 — the measurement defense lives in the
    # AC preamble): SIXTEEN consecutive full `rake test:par` runs, each
    # exit 0 with a clean PARALLEL_OK (0F/0E) and a well-formed
    # COVERAGE_OK. Any red run breaks the streak and REDs the gate AT
    # that run; the failing worker's log is copied into t87stk/ BEFORE
    # exit so the firing signature is preserved for forensics (worker
    # logs otherwise sit in an OS-cleaned mktmpdir). Declared-RED at base
    # 40ed92b: classes (a)/(f) are LIVE — measured at spec time THIS
    # session: class (a) fired in 2 of 5 full base runs (runs 1 and 5,
    # both test_escape_interrupts_a_streaming_run_through_the_kernel_path
    # at chat_test.rb:5791, wait_until "work condition never satisfied"),
    # riding on the I85 spec sample (2/9 each class). WALL: 16 x ~47 s
    # ~ 13 min EXCEEDS the official runner's 900 s per-gate cap by
    # construction — the standalone cold run is the operative record (the
    # I77/I80 runner-cap adjudication precedent).
    bundle install --quiet
    rm -rf t87stk; mkdir -p t87stk
    i=1
    while [ $i -le 16 ]; do
      s=$(date +%s)
      bundle exec rake test:par > t87stk/r$i.log 2>&1; ec=$?
      e=$(date +%s)
      line=$(grep -E "^(PARALLEL_OK|PARALLEL_FAIL) runs=" t87stk/r$i.log | head -1)
      echo "run $i: ec=$ec wall=$((e-s))s $line"
      if [ "$ec" -ne 0 ]; then
        wlog=$(grep -oE "log=[^ ]+" t87stk/r$i.log | head -1 | cut -d= -f2)
        if [ -n "$wlog" ] && [ -f "$wlog" ]; then cp "$wlog" t87stk/r$i-failing-worker.log; fi
        echo "FAIL deflake-par-streak: run $i of 16 broke the streak (ec=$ec; failing worker log preserved at t87stk/r$i-failing-worker.log)"
        exit 1
      fi
      grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t87stk/r$i.log || { echo "FAIL deflake-par-streak: run $i has no clean PARALLEL_OK summary"; exit 1; }
      grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t87stk/r$i.log || { echo "FAIL deflake-par-streak: run $i coverage audit line absent/malformed"; exit 1; }
      i=$((i + 1))
    done
    echo DEFLAKE_STREAK_OK streak=16
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_STREAK_OK

- id: deflake-interrupt-streak
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # Class (a) amplifier: the TWO named streaming-interrupt tests, one
    # process per iteration, x16 standalone then x8 under deliberate
    # 8-way CPU steal (the I82 contention-probe idiom: eight busy-loop
    # rubies, killed on every exit path). The test NAMES are frozen (the
    # filter must select exactly 2 runs every iteration — a rename is a
    # defect). Declared-GREEN-expected at base standalone (the class
    # fires under FULL-SUITE 8-way parallel load, not standalone — the
    # I85 spec sample and this session's base runs); a base firing under
    # the steal leg is the live class, declared-possible. EVERY iteration
    # runs under a hard 90 s wall watchdog (the fail-loud-never-wedge
    # discipline at the GATE level: pre-cure, a missed window in the
    # belt-less kernel_interrupt test can WEDGE kernel.run forever —
    # measured at spec time: this gate's own first probe wedged
    # standalone at base; an expired iteration is a LOUD RED, never a
    # hung battery).
    bundle install --quiet
    rm -rf t87int; mkdir -p t87int
    run_iter() {
      log=$1; budget=$2; shift 2
      "$@" > "$log" 2>&1 &
      pid=$!
      elapsed=0
      while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget ]; do
        sleep 1; elapsed=$((elapsed + 1))
      done
      if kill -0 $pid 2>/dev/null; then
        kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 124
      fi
      wait $pid
      return $?
    }
    i=1
    while [ $i -le 16 ]; do
      run_iter t87int/s$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: standalone iteration $i WEDGED (90 s watchdog — the belt-less wedge class)"; tail -10 t87int/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: standalone iteration $i ec=$ec"; tail -20 t87int/s$i.log; exit 1; }
      grep -qE "^2 runs, " t87int/s$i.log || { echo "FAIL deflake-interrupt-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t87int/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t87int/c$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: steal iteration $i WEDGED (90 s watchdog)"; tail -10 t87int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: steal iteration $i ec=$ec"; tail -20 t87int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t87int/c$i.log || { echo "FAIL deflake-interrupt-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_INTERRUPT_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_INTERRUPT_OK

- id: deflake-drain-streak
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # Class (f) amplifier: the TWO drain legs sharing the script-order
    # bet (leg B opt-in + leg E2 default-on — the firing test is E2), one
    # process per iteration, x16 standalone then x8 under deliberate
    # 8-way CPU steal. Each iteration boots real parent+child tart
    # subprocesses (measured ~37 s/pair idle at spec time — the e2e
    # bundle-exec boot cost is the standing I82 excluded seam; the
    # durations are the property, NEVER shrunk). WALL ~10 min standalone
    # + ~15-20 min under steal: EXCEEDS the runner's 900 s cap by
    # construction — the standalone cold run is the operative record
    # (the I77/I80 runner-cap adjudication precedent). GREEN-expected at
    # base (the I85 spec sample: GREEN standalone x3 + steal x3 — the
    # class fires only inside full 8-way suite runs); a base firing is
    # the live class, declared-possible. Every iteration runs under a
    # hard 300 s wall watchdog (fail-loud, never a hung battery; the
    # legs' own PARENT_DEADLINE_S = 180 watchdog stays the inner belt).
    bundle install --quiet
    rm -rf t87drn; mkdir -p t87drn
    run_iter() {
      log=$1; budget=$2; shift 2
      "$@" > "$log" 2>&1 &
      pid=$!
      elapsed=0
      while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget ]; do
        sleep 1; elapsed=$((elapsed + 1))
      done
      if kill -0 $pid 2>/dev/null; then
        kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 124
      fi
      wait $pid
      return $?
    }
    i=1
    while [ $i -le 16 ]; do
      run_iter t87drn/s$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: standalone iteration $i exceeded the 300 s watchdog"; tail -10 t87drn/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: standalone iteration $i ec=$ec"; tail -20 t87drn/s$i.log; exit 1; }
      grep -qE "^2 runs, " t87drn/s$i.log || { echo "FAIL deflake-drain-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t87drn/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t87drn/c$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: steal iteration $i exceeded the 300 s watchdog"; tail -10 t87drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: steal iteration $i ec=$ec"; tail -20 t87drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t87drn/c$i.log || { echo "FAIL deflake-drain-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_DRAIN_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_DRAIN_OK
- id: deflake-no-widening
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The nothing-weakens pins (the task's letter: the anti-wedge belt
    # and every existing timeout/loud-red safety stay or tighten — NEVER
    # loosen; a fix that widens a timeout or adds a sleep is a defect,
    # not a cure). Legs: (1) the frozen sentinels byte-unchanged vs
    # 40ed92b — test/test_helper.rb (the 5 s wait_until deadline),
    # test/support/signal_hygiene_harness.rb (the I75/I82 belt),
    # test/support/parallel_runner.rb (the I84 fan-out mechanics),
    # Rakefile; (2) ZERO production bytes move (lib/, gems/, bin/,
    # bench/ — a forensics-proven production defect is a PHASE 0 event,
    # judged per I77); (3) ZERO added sleep statements in the touch-set
    # diff; (4) the e2e parent watchdog PARENT_DEADLINE_S = 180 unmoved;
    # (5) THE BELT AUDIT: BOTH named interrupt tests carry the I82 Law-4
    # ensure belt (kernel.stop! on every scenario-thread exit path).
    # DECLARED-RED at base: test_kernel_interrupt_during_streaming_
    # cancels_and_leaves_render_coherent LACKS the belt at 40ed92b (the
    # gap this iteration closes).
    for f in test/test_helper.rb test/support/signal_hygiene_harness.rb test/support/parallel_runner.rb Rakefile; do
      git diff --quiet 40ed92b -- "$f" || { echo "FAIL no-widening: frozen sentinel $f moved vs 40ed92b"; exit 1; }
    done
    proddiff=$(git diff --name-only 40ed92b -- lib gems bin bench || true)
    [ -z "$proddiff" ] || { echo "FAIL no-widening: production bytes moved (a forensics-proven production defect is PHASE 0, judged):"; echo "$proddiff"; exit 1; }
    adds=$(git diff 40ed92b -- test/chat_test.rb test/subagents_e2e_test.rb test/support/mock_llm_server.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' || true)
    [ "$adds" -eq 0 ] || { echo "FAIL no-widening: $adds added sleep statement(s) in the touch set — a sleep is a defect, not a cure"; exit 1; }
    grep -q "PARENT_DEADLINE_S = 180" test/subagents_e2e_test.rb || { echo "FAIL no-widening: the e2e parent watchdog moved from 180"; exit 1; }
    bundle exec ruby -e 'src = File.read("test/chat_test.rb")
    %w[test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent test_escape_interrupts_a_streaming_run_through_the_kernel_path].each do |t|
      m = src.match(/^    def #{t}\n(.*?)^    end\n/m) or abort "no-widening: #{t} not found (renames are defects)"
      body = m[1]
      abort "no-widening: #{t} LACKS the I82 Law-4 anti-wedge belt (ensure + kernel.stop!)" unless body =~ /^\s+ensure\s*$/ && body.include?("kernel.stop!")
    end
    puts "BELT_AUDIT_OK"'; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL no-widening: belt audit ec=$ec (every comparison gates its own exit — the /bin/sh no-set-e discipline)"; exit 1; }
    echo NO_WIDENING_OK
  expect:
    exit_code: 0
    stdout_match: NO_WIDENING_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I87-suite-deflake-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section suite-deflake prompt --append --lane <lane> --from build/I87-suite-deflake-<lane>/prompt.md`. -->

## Builder Report

### core

# I87 suite-deflake — Builder Report (lane core, repo tart)

Worktree: `build/I87-suite-deflake-core/wt` @ base `40ed92b` (tracked-clean at
dispatch; builders never committed — work lands modified/untracked). Ruby
4.0.9 (2026-10-23 revision 3e93b23afc) per the committed `.ruby-version`.

## PHASE 0 declarations

NONE. Zero production bytes moved (`lib/`, `gems/`, `bin/`, `bench/`
untouched — verified by the `deflake-no-widening` gate's proddiff leg, PASS).
No frozen sentinel moved (`test/test_helper.rb`, `Rakefile`,
`test/support/signal_hygiene_harness.rb`, `test/support/parallel_runner.rb`,
`.ruby-version`, `Gemfile`, `Gemfile.lock`, `tart.gemspec` — all byte-frozen
vs `40ed92b`, gate-pinned). No sleep added (gate grep leg, PASS). No test
renamed, deleted, or weakened; no timeout raised anywhere. The three
non-PASS gate rows below are the carried declared classes (c)/(d) riding
note-and-pass exactly as carried, with mechanical attribution evidence —
not lane-attributable, not PHASE 0 events.

Disclosed judgment calls (within the frozen sanction, itemized):

1. The class-(f) pre-fix reproduction is a REDUCED-CONTEXT one: a
   deterministic forced-order driver against the BASE `mock_llm_server.rb`
   bytes (`git show 40ed92b:…`, pristine copy in
   `scratch/forensics/base_mock_llm_server.rb`) that fires the exact
   inversion signature (`assert_equal B_FINAL, stdout.strip` carries the
   child answer). The load-correlated live firing is the frozen contract's
   own I85 record (2/9 full 8-way runs); the I87 lane's own pre-cure steal
   attempts of the pair standalone did not fire (expected — the class
   fires only inside full-suite 8-way runs, per the I85 spec sample and
   this session's 11 pre-cure par cycles: 1 cycle red, and it was class
   (a), not (f)). The spec's Law 0 sanctions reduced-context reproduction
   "iff it fires the SAME signature" — it does.
2. The new pin file is `test/support/mock_llm_match_test.rb` — THE one
   sanctioned `test/support/[a-z0-9_]+\.rb` file (matches the scope gate's
   untracked whitelist; discovered by BOTH canonical globs — 1491 → 1497,
   growth = exactly its 6 pins).

## 1. Forensics record

### Class (a) — chat-interrupt loud-red

- **Named firing test**:
  `Tart::ChatTest#test_escape_interrupts_a_streaming_run_through_the_kernel_path`,
  firing at the post-ESC `wait_until { !chat.busy? }`
  (`test/chat_test.rb:5791` at base bytes; the twin
  `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
  (:1608) carries the same mechanics minus the belt).
- **Pre-fix reproduction (in-suite, lane tree)**: instrumented
  `test/chat_test.rb` (TEMPORARY forensics probes — reverted byte-exactly
  before the cure; pristine copy sha256
  `01a573782c25f01d7885708c7fb85dd4733865e7689464507fb4377bf1eaf83a`
  verified restored) and ran full `rake test:par` cycles: **fired at cycle
  5 of 11 pre-cure cycles** — identical signature to the two base firings:
  `RuntimeError: work condition never satisfied` at
  `test_helper.rb:15` from the post-ESC wait. Preserved artifacts (lane
  scratch `scratch/forensics/`): `worker-0.log` (the failing worker log,
  copied from the runner-printed mktmpdir path), `i87-forensics-14617.json`
  (the instrument dump), `i87-forensics-12134.json` (a second, earlier
  capture of the same failure state).
- **Stated mechanism (the instrumented firing record — REFINES the
  Grounds' W1/W2; both are refuted in their literal forms)**:

  At the 5 s deadline the dump shows:
  `chat.busy?=true`, `agent.interrupted?=false`, `agent @in_run=true`,
  `kernel.stats[:interrupted]=false`, `kernel @tasks=[nil, nil]` (both
  task objects finalized), `server.request_count=0` (the mock server NEVER
  received the request), transcript has no "interrupted" row.

  The event log (`i87-forensics-14617.json`) shows the full chain:
  `agent_start` at t=26.6232 → ESC dispatched with `busy=true` at
  t=26.6234 (the busy arm taken) → `interrupt_work!` at t=26.6235 with
  `found=true`, `tasks_alive=[true, true]` → then NOTHING for 5 s.

  So the ESC did NOT miss the tasks (W1's literal claim) and the teardown
  was not starved (W2): **`interrupt_work!` found both tasks alive and
  called `Task#stop` on each — `Scheduler#raise` was invoked for both
  fibers — and the cancellation was NEVER DELIVERED into the agent
  fiber.** The agent fiber was parked at a pre-IO cooperative point inside
  its first slice (before the HTTP request hit the wire — zero server
  requests); on this stack (ruby 4.0.9 / async 2.46.0 / io-event 1.22.1
  kqueue backend) `Fiber#raise` delivery into a not-yet-IO-parked fiber
  silently fails: the cancel returns, async finalizes the task objects
  (`@promise.cancel` + `@fiber=nil` — the observed `[nil, nil]`), but the
  agent block's ensure/rescue chain never executes (`@in_run` stuck true,
  `interrupted?` false). The run NEVER completes — not even at natural
  end — so the surface's `busy?` (cleared only by `agent_end`) sticks
  forever: the post-ESC `wait_until { !chat.busy? }` pops at 5 s (the
  firing signature); in the belt-less `:1608` test `kernel.run` never
  returns (the observed 600 s-class wedge at spec time).

  Reduced-context confirmation (`scratch/repro_a.rb` — same
  `chat_with_server` wiring, tight loop, 8-way CPU steal): fires the SAME
  signature at ~1/20–1/300 iterations (`repro-firing.json`,
  `repro-a-run*.txt` preserved). Probe chain in the harness:
  `interrupt_work tasks_alive=[true,true]` → `Async::Scheduler#raise`
  called for both fibers (recorded) → `cancel` returns with
  `cancelled_after=true, fiber_after=nil` — no `FiberError`/`Cancel::Later`
  branch (tally: FiberError→Later = 0 across all runs) — the delivery is
  swallowed below `Scheduler#raise`, inside the selector/fiber raise.

- **Cure (Law 1)** — deterministic synchronization; the ESC is gated onto
  the state where cancellation delivery is the designed mechanism:

  1. ESC only after BOTH observables: (i) the mock server captured the
     request (`captured.any? { …user message == "long stream" }` — the
     kernel's work task is live and the request is on the wire), and
     (ii) three content chunks have rendered
     (`widget_lines_with_spans(session.drawn.last)…include?("xxx")` — the
     fiber has demonstrably parked at the SSE read and cycles between
     read-parks; the pre-IO park window is closed BY CONSTRUCTION).
  2. The scripted stream outlasts the observation deadline: 40 → 80 chars
     (≈4 s → ≈8 s at the FROZEN 0.1 s/char server pace) — a dropped
     interrupt is always a loud red, never masked by natural end; the
     interrupt path cancels the stream immediately, so green runs pay
     ~+0.25 s per test (measured: pair standalone 0.075 s → 0.52 s).
  3. `:1608` got the I82 Law-4 belt (`begin … ensure kernel.stop! end`),
     byte-equivalent in strength to the escape test's existing belt
     (escape test belt kept, untouched).

  Residual risk (disclosed): the delivery failure lives in the
  async/io-event/fiber layers (production-frozen seams). The cure gates
  the ESC into the read-park state where delivery is the exercised
  mechanism — the measured bar (16 full par runs + 24 focused amplifier
  iterations, zero firings) is the evidence it holds. A residual failure
  would now surface as the ≤5 s belt-protected loud red it always should
  have been.

### Class (f) — subagents-e2e drain-timing

- **Named firing test**: `test_default_on_e2_async_detached_notify_and_print_drain`
  (`test/subagents_e2e_test.rb:987` at base), the
  `assert_equal B_FINAL, stdout.strip` inversion; same-script twin
  `test_leg_b_async_delegation_and_print_drain` (:157).
- **Mechanism (confirmed as the Grounds state them)**:
  `MockLLMServer#serve` shifted the script by REQUEST ARRIVAL ORDER
  (`spec = @script.shift || …`, base `mock_llm_server.rb:164`). Both legs
  scripted `[tool_call spec, B_FINAL, child-slow]` and bet the parent's
  instant tool-result turn beats the child's `bundle exec ruby bin/tart`
  boot. Under sustained 8-way load the boot starves, the order flips: the
  child takes B_FINAL, the parent's final turn takes the child slow
  stream, stdout carries the child answer — the pin inverts.
- **Pre-fix reproduction (reduced-context, sanctioned)**:
  `scratch/repro_f.rb` + `scratch/forensics/base_mock_llm_server.rb`
  (base bytes): ORDER A (child last) → child gets the slow stream, parent
  stdout = B_FINAL (the leg passes); ORDER B (child first — the load
  flip) → `child <- "TOOLCALL:subagent(async:true)"`,
  `parent2 <- "leg B child answer streamed slowly"` — **the parent stdout
  pin carries the CHILD answer: the exact firing signature**
  (`scratch/forensics/repro-f-output.txt`). The live load-correlated
  firing is the frozen contract's own I85 record (2/9).
- **Cure (Law 2)** — the arrival-order bet is removed by
  content-addressable scripting:
  - `mock_llm_server.rb`: strictly additive `match:` capability —
    `take_spec(parsed_body)`: (1) the FIRST entry whose `match:` predicate
    is truthy for the parsed body is removed and served (content routing);
    (2) otherwise the first entry WITHOUT a `match:` key (the legacy blind
    shift, in order — byte-identical semantics for every pre-I87 caller);
    (3) otherwise the unchanged `{type: :message, content: ""}` exhausted
    fallback. Selection under a new `@script_mutex` (per-connection serve
    threads). `rearm!`/`suppress_usage!`/request logs/EPIPE arms/
    top-level minitest-optional shape: untouched (the rig's 7
    `mock_llm_extension_test` pins pass unchanged).
  - Legs B + E2: same three response specs, byte-identical, now routed by
    content — parent turn 1 by the B_PROMPT user message, parent turn 2 by
    the `c1` tool message, the child by the B_CHILD_TASK user message.
    Order-independent by construction (the child can never take B_FINAL;
    the parent's final turn can never take the slow stream). Every
    existing leg assertion stands, byte-untouched (drain pair: 2 runs,
    46 assertions — identical to the base measurement).
  - New hermetic pins: `test/support/mock_llm_match_test.rb`, 6 pins
    (routing order-independence; legacy blind-shift preservation incl.
    the parked-match-entry rule; parking + unchanged fallback; rearm!
    restores match entries; first-match-wins + serve-once; the streaming
    arm end-to-end). Suite growth: **1491 → 1497 runs (exactly these
    6)**; skips unchanged at 5.

## 2. Per-edit itemization (old bytes → new bytes)

### `test/chat_test.rb` (2 edits; the only file with class-(a) edits)

1. `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
   (base :1608):
   - OLD: `@server.script([{type: :slow_stream, content: "x" * 40}])`
     NEW: `…content: "x" * 80}` + why-comment.
     Mechanism removed: the natural-end mask (≈4 s < 5 s deadline let a
     dropped/dropped-delivery interrupt green silently serially). NOT a
     timeout widening: the server's per-chunk pace (`spec_pause` 0.1) is
     frozen and untouched; the deadline (`wait_until`, 5 s) is untouched;
     on the interrupt path the stream is cancelled immediately (measured
     green cost ≈ +0.25 s/test).
   - OLD scenario body: bare
     `type → wait busy? → ESC → wait !busy? → wait "interrupted" →
     kernel.stop!` (no belt).
     NEW: same body inside `begin … ensure kernel.stop! end` (the I82
     Law-4 belt — closes the wedge gap: a missed window now costs ≤5 s,
     never a 900 s-class wedge), PLUS two gating waits inserted BETWEEN
     `wait_until { chat.busy? }` and the ESC push:
     `wait_until { captured.any? { |req| … == "long stream" } }` and
     `wait_until { widget_lines_with_spans(session.drawn.last)…include?("xxx") }`.
     Mechanism removed: the pre-IO-park ESC window (the measured silent
     no-delivery geometry). Assertions unchanged (4 asserts,
     `refute kernel.interrupted?` / `assert chat.agent.interrupted?` /
     orphan-poller / coherent render — all byte-identical).
2. `test_escape_interrupts_a_streaming_run_through_the_kernel_path`
   (base :5775):
   - OLD: `content: "x" * 40` NEW: `content: "x" * 80` (+ why-comment) —
     same unmasking as above.
   - OLD: ESC pushed right after `wait_until { chat.busy? }`.
     NEW: the same two gating waits inserted before the ESC push (+ the
     why-comment). Belt already present (kept byte-identical). All
     assertions unchanged (`@agent_interrupted` capture, the "still
     there" follow-up submit, transcript "interrupted").

### `test/support/mock_llm_server.rb` (4 additive hunks)

1. Doc comment: the `match:` entry shape (12 lines).
2. `initialize`: `@script_mutex = Mutex.new` (+ why-comment).
3. `serve`: OLD `spec = @script.shift || {type: :message, content: ""}`
   NEW `spec = take_spec(parsed_body)`.
4. NEW private `take_spec(parsed_body)` — matched-entry scan → legacy
   blind shift → unchanged fallback, under the mutex (+ why-comment).
   Mechanism removed: the arrival-order bet. Every existing caller's
   semantics byte-preserved (no-match scripts take the identical
   first-index-removal path = the old shift).

### `test/subagents_e2e_test.rb` (2 edits)

1. Leg B script block: OLD blind 3-entry script + the order-bet comment;
   NEW the same three specs each carrying its `match:` predicate + the
   class-(f) comment. `PARENT_DEADLINE_S = 180` and every assertion
   untouched.
2. Leg E2 script block: same conversion. All assertions untouched.

### NEW `test/support/mock_llm_match_test.rb`

6 hermetic pins over a real TCP socket (itemize-and-defend entry): the
file exists solely to pin the new mock-server capability — the suite's
run count grows by exactly these 6 (1491 → 1497; verified in the serial
suite, `parallel-parity`'s COVERAGE legs, and all 16 streak runs).

## 3. The full 107-gate table (measured one-liner per gate)

All at the lane tree, cold, bodies VERBATIM from the frozen block
(extracted mechanically — `scratch/gates/<id>.sh`; runner
`scratch/run_gates.sh`; logs `scratch/gate_runs/<id>.log`).

| gate | result | measured one-liner |
|---|---|---|
| stale-run-reaper | PASS | 1s; STALE_RUN_REAPER_OK |
| unknown-model-reject | PASS | 0s; UNKNOWN_MODEL_REJECT_OK |
| subagents-health-units | PASS | 7s; health pins ≥8 runs green |
| edit-fold-repro | PASS | 0s; EDIT_FOLD_REPRO_OK |
| edit-fold-units | PASS | 1s; ≥10 runs green |
| session-model-identity | PASS | 0s; SESSION_MODEL_IDENTITY_OK |
| session-model-units | PASS | 1s; ≥6 model-identity runs green |
| suite | PASS | 221s ≤ 240s; 1497 runs / 10152 assertions / 0F / 0E / 5S |
| bench | PASS | 16s; SEAM_BENCH_OK |
| md-repro | PASS | 1s; MD_REPRO_OK |
| md-inline-units | PASS | 0s; inline-scan pins green |
| pending-registry-units | PASS | 0s; registry pins green |
| footer-window | PASS | 0s; FOOTER_WINDOW_OK 1000000 |
| thinking-pins | PASS | 1s; ≥11 + ≥8 runs green |
| hermeticity | PASS | 10s; launcher smoke + e2e session green |
| lock-deps | PASS | 0s; lock pins + GEM_LOAD_OK |
| zai-data | PASS | 1s; dialect pins green |
| threads-budget | PASS | 0s; zero new Thread.new in lib |
| session-golden | PASS | 0s; session digests byte-frozen |
| strict-wire | PASS | 1s; strict sampling runs 0F/0E |
| error-transcript-units | PASS | 0s; agent-loop + session pins green |
| error-transcript-render-units | PASS | 1s; chat render + replay pins green |
| render-perf-units | PASS | 1s; render_perf green ec=0 |
| render-perf-probe | NOTE-AND-PASS | run 1 FAIL ec=1 (BP1 3.07 ≤3.0, BP2 258.8 ≤250 — declared class (d) load-margin); cold re-run PASS 144s (BP1 2.39, BP2 249.0), RENDER_PERF_OK |
| tool-pending-gate | PASS | 20s; TOOL_PENDING_GATE_OK |
| user-bash-stream-gate | PASS | 14s; USER_BASH_STREAM_GATE_OK |
| zai-max-tokens-units | PASS | 3s; agent/models/launcher pins green |
| rail-bg | PASS | 0s; RAIL_BG_OK |
| jump-pill-units | PASS | 1s; ≥6 runs green |
| rail-bg-units | PASS | 0s; ≥4 runs green |
| viewport-probe | PASS | 0s; VIEWPORT_PROBE_OK |
| oracle-pin-state | PASS | 0s; pin branch + cli 1.1.0 |
| oracle-bin-units | PASS | 1s; ≥5 runs green |
| oracle-resolve | PASS | 0s; pinned-clone resolution |
| s1-parity | PASS | 6s; rig parity ec=0 |
| s2-parity | PASS | 5s; ec=0 |
| s3-parity | PASS | 5s; ec=0 |
| s4-parity | PASS | 5s; ec=0 |
| s5-parity | PASS | 6s; ec=0 |
| s6-parity | PASS | 5s; ec=0 |
| s7-parity | PASS | 5s; ec=0 |
| s8-parity | PASS | 5s; ec=0 |
| s9-parity | NOTE-AND-PASS | FAIL ×2 cold ec=1 — unknown-candidate wrap fragments on sandbox/pi vs sandbox/tart path wrap: the declared class (c) lane-tree geometry; GREEN (ec=0) at repos/tart with the identical command (mechanically proven attribution) |
| s10-parity | PASS | 8s; ec=0 |
| s17-parity | PASS | 8s; ec=0 |
| s1-tart-mode | PASS | 5s; TART_MODE_OK |
| wire-delta | PASS | 5s; WIRE_DELTA_OK (instruction/tool digests frozen) |
| zai-max-tokens-wire | PASS | 5s; tart=pi=512 |
| identity-law | PASS | 1s; IDENTITY_LAW_OK |
| default-face | PASS | 0s; DEFAULT_FACE_OK |
| default-boot | PASS | 1s; DEFAULT_BOOT_OK (tart preamble + TART_* namespace on the wire) |
| herdr-units | PASS | 1s; HERDR_UNITS_OK |
| herdr-wire-probe | PASS | 3s; HERDR_WIRE_OK |
| rig-identity-assert | PASS | 0s; RIG_IDENTITY_OK |
| subagents-default-law | PASS | 0s; default-ON law |
| subagents-default-boot | PASS | 1s; default-on tools digest frozen |
| subagents-motd-units | PASS | 1s; prompts rows frozen |
| subagents-motd-probe | PASS | 3s; SUBAGENTS_MOTD_OK |
| subagents-e2e-default-on | PASS | 36s; ≥4 default-on e2e runs green (incl. cured leg E2) |
| rig-staging-units | PASS | 0s; staging opt-out pinned |
| vendored-attribution | PASS | 1s; manifest + oracle byte-identity |
| vendored-units | PASS | 1s; vendored tier pins |
| listing-units | PASS | 0s; ≥5 runs green |
| model-menu-live-merge | PASS | 1s; live-list pins |
| launcher-listing-thread | PASS | 1s; endpoint-thread pin |
| vendored-no-boot-network | PASS | 0s; offline vendored tier |
| listing-thread-law | PASS | 0s; one Thread.new site |
| md-battery-fixture | PASS | 0s; sha 4ecd9cc2… verified |
| md-battery-units | PASS | 0s; 48 battery cases |
| md-regression-units | PASS | 1s; regression battery |
| md-flanking-repro | PASS | 0s; MD_FLANKING_OK |
| md-micro-perf | PASS | 2s; 4.49 ms/conv ratio 1.98 |
| child-env-law-repro | PASS | 0s; CHILD_ENV_LAW_OK |
| child-env-units | PASS | 1s; pins green |
| child-env-site-units | PASS | 3s; site pins |
| bash-child-env-live | PASS | 1s; BASH_CHILD_ENV_LIVE_OK |
| session-sink-config-units | PASS | 1s; config law |
| session-sink-projection-units | PASS | 1s; projection pins |
| session-sink-engine-e2e | PASS | 6s; ec=0 |
| session-sink-child-e2e | PASS | 3s; ec=0 |
| signal-hygiene-units | PASS | 4s; six-leg belt green |
| signal-orphan-e2e | PASS | 30s; SIGNAL_ORPHAN_OK |
| subagent-box-units | PASS | 32s; box pins |
| subagent-status-probe | PASS | 63s; SUBAGENT_STATUS_OK |
| child-encoding-units | PASS | 4s; encoding pins |
| child-encoding-e2e | PASS | 6s; ec=0 |
| runner-encoding-direct | PASS | 1s; RUNNER_ENCODING_DIRECT_OK |
| agent-loading-units | PASS | 1s; AGENT_LOADING_UNITS_OK |
| nested-grant-units | PASS | 37s; NESTED_GRANT_UNITS_OK |
| forensics-units | PASS | 1s; FORENSICS_UNITS_OK |
| agent-loading-e2e | PASS | 10s; ec=0 |
| listing-teardown-units | PASS | 1s; LISTING_TEARDOWN_OK |
| contention-proof | PASS | 11s; CONTENTION_OK |
| sweep-units | PASS | 22s; SWEEP_UNITS_OK |
| sweep-parity | NOTE-AND-PASS | FAIL ec=1 — serial/concurrent tables AGREE; drift vs the frozen base table is ONLY s9_startup_help=1 + s16_resize_wrap=1, both the declared class (c) lane-tree geometry (both GREEN at repos/tart via the identical wrapper invocations: s9 ec=0, s16 ec=0 — mechanically proven) |
| sweep-crosstalk | PASS | 7s; CROSS_TALK_OK |
| parallel-units | PASS | 1s; PARALLEL_UNITS_OK |
| parallel-parity | PASS | 40s; PARALLEL_OK 1497/10147/0F/0E/5S wall 39.8s ≤90s; COVERAGE_OK runs=1497 enum=1497; Rakefile additivity 0 deletions |
| parallel-repeat | PASS | 123s; 3 runs identical runs=1497 skips=5 literals; assertions spread inside the ±20 band |
| ruby-pin | PASS | 0s; pin 4.0.9 + mise + lock guard |
| native-bundle | PASS | 0s; ratatui 1.5.0 native ext from Gem.default_dir |
| premise-remeasure | PASS | 17s; wedge=real plain=stands hard=escapes |
| scope | PASS | 0s; tracked diff confined to the 3-file touch set; must-differ satisfied; 1 sanctioned new support file; untracked set whitelisted |
| deflake-par-streak | PASS | 664s; **16/16 full par runs, ZERO (a)/(f) firings**, every run exit 0 + clean PARALLEL_OK + well-formed COVERAGE_OK |
| deflake-interrupt-streak | PASS | 24s; ×16 standalone + ×8 under 8-way steal, every iteration ≤90s watchdog, exactly 2 runs/iteration (0.48–0.54s each) |
| deflake-drain-streak | PASS | 942s; ×16 standalone + ×8 steal, every iteration ≤300s watchdog, 2 runs / 46 assertions per iteration (~37–39s each) |
| deflake-no-widening | PASS | 0s; all five legs — frozen sentinels byte-unchanged, ZERO production bytes, ZERO added sleeps, PARENT_DEADLINE_S=180 unmoved, BELT_AUDIT_OK (both named interrupt tests carry the belt) |

107/107 gates run; 104 PASS, 3 note-and-pass (all declared classes with
mechanical attribution: (d) ×1 cold-re-run PASS, (c) ×2 proven
GREEN-at-integration-tree).

## 4. Streak summaries

`deflake-par-streak` (the cure bar, N=16 — all exit 0, PARALLEL_OK, COVERAGE_OK):

```
run 1: PARALLEL_OK runs=1497 assertions=10142 failures=0 errors=0 skips=5 workers=8 wall=41.5s
run 2: PARALLEL_OK runs=1497 assertions=10153 failures=0 errors=0 skips=5 workers=8 wall=42.1s
run 3: PARALLEL_OK runs=1497 assertions=10153 failures=0 errors=0 skips=5 workers=8 wall=41.5s
run 4: PARALLEL_OK runs=1497 assertions=10138 failures=0 errors=0 skips=5 workers=8 wall=41.6s
run 5: PARALLEL_OK runs=1497 assertions=10153 failures=0 errors=0 skips=5 workers=8 wall=40.4s
run 6: PARALLEL_OK runs=1497 assertions=10152 failures=0 errors=0 skips=5 workers=8 wall=41.2s
run 7: PARALLEL_OK runs=1497 assertions=10143 failures=0 errors=0 skips=5 workers=8 wall=41.7s
run 8: PARALLEL_OK runs=1497 assertions=10153 failures=0 errors=0 skips=5 workers=8 wall=41.8s
run 9: PARALLEL_OK runs=1497 assertions=10137 failures=0 errors=0 skips=5 workers=8 wall=42.1s
run 10: PARALLEL_OK runs=1497 assertions=10142 failures=0 errors=0 skips=5 workers=8 wall=42.0s
run 11: PARALLEL_OK runs=1497 assertions=10153 failures=0 errors=0 skips=5 workers=8 wall=40.0s
run 12: PARALLEL_OK runs=1497 assertions=10138 failures=0 errors=0 skips=5 workers=8 wall=40.5s
run 13: PARALLEL_OK runs=1497 assertions=10152 failures=0 errors=0 skips=5 workers=8 wall=40.6s
run 14: PARALLEL_OK runs=1497 assertions=10147 failures=0 errors=0 skips=5 workers=8 wall=41.2s
run 15: PARALLEL_OK runs=1497 assertions=10138 failures=0 errors=0 skips=5 workers=8 wall=41.0s
run 16: PARALLEL_OK runs=1497 assertions=10138 failures=0 errors=0 skips=5 workers=8 wall=41.2s
gate total wall=664s — DEFLAKE_STREAK_OK streak=16
```

Amplifiers: `DEFLAKE_INTERRUPT_OK standalone=16 steal=8` (24 iterations,
max observed 0.54 s vs the 90 s watchdog); `DEFLAKE_DRAIN_OK standalone=16
steal=8` (24 iterations, 37.1–38.8 s vs the 300 s watchdog). Zero (a)/(f)
signatures anywhere in the streak logs (`t87stk/`, `t87int/`, `t87drn/`).

Pre-cure contrast (same lane tree, same day): 11 pre-cure par cycles →
1 class-(a) firing at cycle 5 (the preserved worker log) — consistent
with the frozen ≈0.29/class rate; 0 post-cure in 16+8+24+24 focused
exposures and 16 full runs.

## 5. Suite literals

- Serial (`suite` gate): **1497 runs, 10152 assertions, 0 failures,
  0 errors, 5 skips, wall 221 s** (bound 240 s).
- Parallel: **runs=1497 skips=5** across all 16 streak runs +
  parallel-parity + parallel-repeat (identical literals);
  assertions 10137–10153 (the dynamic-counter band).
- Growth vs base (1491 / 5S): **+6 runs = exactly the 6 new
  `mock_llm_match_test` pins**. No other count/shape movement.

## 6. Deviations, itemized

1. Reduced-context class-(f) reproduction (mechanical forced-order driver
   at base bytes) — sanctioned by Law 0's letter; same signature; the
   live-load correlation rides the frozen I85 record. Disclosed above.
2. ONE new `test/support/` file (the sanctioned maximum), used for the 6
   declared hermetic pins. Disclosed above.
3. `default-boot` was initially missed in the batch ordering (106/107
   logs after the first battery pass) and was run immediately after —
   PASS 1s (DEFAULT_BOOT_OK). All 107 gates have measured rows; no gate
   is absent. No other deviations. No frozen bytes moved, no production
   bytes, no sleeps, no renamed/deleted tests, no weakened assertions or
   belts.

## 7. Artifact inventory (lane scratch, all raw)

- `scratch/forensics/worker-0.log` — the pre-cure in-suite firing worker log (cycle 5).
- `scratch/forensics/i87-forensics-14617.json` — the instrument dump at the firing (the mechanism record).
- `scratch/forensics/i87-forensics-12134.json` — an earlier identical failure-state capture.
- `scratch/forensics/repro-firing.json` + `repro-a-run*.txt` — the reduced-context harness firings + the async probe tallies/ring.
- `scratch/forensics/base_mock_llm_server.rb` + `repro-f-output.txt` — the class-(f) base-bytes order-flip reproduction.
- `scratch/repro_a.rb`, `scratch/repro_f.rb` — the forensic harnesses (NOT in the repo tree).
- `scratch/chat_test.rb.pristine` — the pre-instrumentation byte copy (restored; sha verified).
- `scratch/gates/*.sh` + `scratch/gate_runs/*.log` — the verbatim gate bodies + full run logs.
- `scratch/extract_gates.rb`, `scratch/run_gates.sh` — the extraction + runner.

STATUS: COMPLETE

## Verdict

# I87 suite-deflake — Verdict

**CONTINUE.** One lane `core` (repo tart). Judged in a fresh session against the
frozen contract (freeze SHA `01cfa4c5`, freeze commit `6633bb8`); the builder's
report transcribed verbatim (`architect evidence` → `cbbeb9d4`).

## Mechanical post-flight

- `architect verify suite-deflake`: (a) frozen sections untouched PASS
  (`git diff 01cfa4c5 HEAD -- architecture/I87-suite-deflake.md` empty at
  post-flight); (b) no builder commits PASS (`git -C …/wt log 40ed92b..`
  empty); (c) report exists PASS; (d) in-bounds FAIL — mechanical only: the
  frozen 3-path touch-set glob cannot express the AC6-sanctioned ONE NEW
  `test/support/[a-z0-9_]+\.rb` file (`test/support/mock_llm_match_test.rb`).
  After judge-side cleanup of the regenerable `t87*` gate-scratch dirs (the
  I72/I75 pre-integrate discipline), the worktree changed-set is EXACTLY the
  3-file frozen touch set + the 1 sanctioned new file. The override is
  recorded non-silently via `--accept-bounds` at integrate (I69/I77/I80
  pattern).
- `Gemfile.lock` byte-unchanged; zero production bytes (`lib/ gems/ bin/
  bench/` clean vs `40ed92b`); zero added sleeps in the diff (grep leg
  re-run by this judge: 0); the temporary forensics instrumentation fully
  reverted (0 `I87WaitProbe` bytes in the final diff).

## PHASE 0 rulings

The builder raised **ZERO** PHASE 0 disagreements (explicit "NONE"). The
spec digest's four open questions are answered by this judge:

1. **W1 vs W2 (the operative class-(a) mechanism) — RESOLVED: both refuted
   in their literal forms; ACCEPT the lane's refinement.** The preserved
   instrument dump (`scratch/forensics/i87-forensics-14617.json`,
   judge-read) shows `interrupt_work!` FINDING both tasks alive
   (`found=true, tasks_alive=[true,true]` at t=26.6235 — refuting W1's
   dropped-before-registration), then NOTHING for 5 s: `tasks=[nil,nil]`,
   `interrupted?=false`, `@in_run=true`, **`server_requests=0`** — the
   request never hit the wire, so the fiber was parked pre-IO and
   `Task#stop`'s cancellation was never DELIVERED (async 2.46.0 /
   io-event 1.22.1 / ruby 4.0.9 stack). This is not W2's starved-teardown
   either (no teardown ever started). Law 1's frozen property maps exactly
   onto the measured mechanism: gating ESC on (request captured) AND
   (3 chunks rendered) guarantees the fiber is parked at the SSE read —
   the state where cancellation delivery is the exercised mechanism. The
   refinement strengthens the contract; the cure shape is precisely Law
   1's letter.
2. **Does the (a) cure need a minimal production change? — NO, and none is
   sanctioned.** The delivery failure localizes BELOW tart's seams (the
   async/io-event/fiber layers, production-frozen); Law 3 permits
   production bytes only for a proven tart defect, and the forensics prove
   the tart-side code (`interrupt_work!`) did its part. The test-side
   handshake cure is the sanctioned shape. RESIDUAL (owner-facing): a
   real-user ESC landing inside the pre-IO window under load can still
   stick a run the same way — a candidate problems.md note / future
   production hardening entry, NOT this iteration's scope.
3. **Drain-streak steal-leg walls at the lane tree — measured fine.** The
   verbatim standalone cold run: `DEFLAKE_DRAIN_OK standalone=16 steal=8`
   (24 iterations inside their 300 s watchdogs).
4. **The two cap-exceeding gates vs the runner — confirmed and
   adjudicated per the frozen declaration.** Neither gate carries a
   `timeout:` override, so the runner's 900 s cap applies:
   `deflake-drain-streak` was SIGTERM'd mid-steal-leg after printing
   "standalone x16 green" — a declared runner artifact; the verbatim
   standalone cold re-run (the operative record, I77/I80 precedent) is
   GREEN. `deflake-par-streak` ran to its own verdict inside the cap
   (664–780 s envelopes) — its REDs are NOT runner artifacts; see the
   adjudication below.

## Judge-cold battery ledger (`architect gate suite-deflake core`, transcript
## `build/gate/I87-suite-deflake-20261025T011142.645817.md`)

102/107 PASS direct under the runner, cold, at the lane tree. The 5 REDs,
each adjudicated (itemize-and-defend):

1. **`deflake-par-streak` — RED twice judge-cold, BOTH times on the I85
   verdict-DECLARED intercom TOCTOU residual, NEVER on (a)/(f).
   NOTE-AND-PASS; the (a)/(f) bar is measured MET.** Cold battery run 12
   and standalone verbatim re-run 1 run 1 + re-run 2 run 15 all broke with
   the IDENTICAL signature:
   `SubagentsIntercomTest#test_progress_requests_never_surface_and_are_consumed
   — Errno::ENOENT @ rb_sysopen …/control/supervisor-requests/<uuid>.json,
   test/subagents_intercom_test.rb:711` (the `request_path` glob→find→
   `File.read` rescues only `JSON::ParserError`; the channel's consumer
   unlinks between glob and read). Attribution, mechanical: (i) the I85
   verdict RECORDED this exact test/line/signature as an ACCEPTED residual
   riding note-and-pass ("1 sighting in ~9 parallel runs", architecture/
   I85-ruby-4-0-9.md Verdict); (ii) the mechanism is byte-identical at
   base (`git show 40ed92b:test/subagents_intercom_test.rb` = lane bytes);
   (iii) ZERO lane bytes anywhere in the path (the lane's diff is
   chat_test ×2 tests, subagents_e2e ×2 legs, the additive mock-server
   `match:` selector, +1 new pin file); (iv) the firing test's race is
   filesystem-side (staged home, channel poller vs helper glob) — the
   mock-server selector is not on it. The frozen preamble's machinery
   governs: (a)/(f) reds are REAL failures (none fired); other declared
   classes ride note-and-pass with zero lane attribution "unless the diff
   proves otherwise" — the diff proves otherwise-clean. **The (a)/(f) cure
   bar, measured judge-cold: 27 CONSECUTIVE full `rake test:par` runs with
   ZERO (a)/(f) firings** (battery 12 + attempt-1 run 1 + attempt-2 runs
   1–14 — the three red runs carried zero (a)/(f) signatures, so the
   (a)/(f)-zero count runs through them), PLUS the builder's verbatim
   16/16 green streak, PLUS parallel-parity + parallel-repeat ×3 + the
   serial suite. Were either class live at its measured base rate
   (0.29/0.22 per run), 27 clean runs has probability ≤ 0.01% — the frozen
   N=16 math is satisfied several-fold by the judge's own exposure alone.
   The residual's observed rate (~3/29 judge runs; 0/16 builder) is
   consistent with the I85 sighting rate; it is now the suite's hottest
   known loud-red class and SHOULD headline the next deflake entry (the
   one-line cure: `rescue Errno::ENOENT → false` in `request_path`'s find
   block — OUT of this iteration's frozen touch set, so it rides).
2. **`deflake-drain-streak` — runner SIGTERM at the 900 s cap; PASS on the
   verbatim standalone cold re-run** (`DEFLAKE_DRAIN_OK standalone=16
   steal=8`; the frozen runner-cap declaration + I77/I80 precedent; the
   runner's own log shows the standalone ×16 leg green before the kill).
3. **`render-perf-probe` — declared class (d) (BP load-margin).
   NOTE-AND-PASS.** Lane-tree FAIL (BP1 3.05, BP2 262.1) and standalone
   cold re-run FAIL (BP1 3.24, BP2 260.2), with the judge's BASE control
   at `repos/tart` (zero lane bytes) failing the same leg the same night
   (BP2 255.3 > 250, BP1 2.81 passing — the I74 pattern: "the judge's
   BASE control fails identically … the builder's quiet-box PASS stands").
   The lane diff contains zero render-path bytes; attribution is nil by
   construction. All AV shape legs PASS on every run.
4. **`s9-parity` — declared class (c) (lane-tree-depth geometry).
   NOTE-AND-PASS**, judge-proven: the identical gate bytes at canonical
   depth (`repos/tart`) exit 0 this session.
5. **`sweep-parity` — declared class (c), same mechanism.** Lane-tree RED
   drift is EXACTLY `s16_resize_wrap=1 + s9_startup_help=1` (the geometry
   pair; serial/concurrent tables AGREE); the identical gate bytes at
   canonical depth: `SWEEP_TABLE_OK 19 scenarios` / `SWEEP_PARITY_OK`
   (serial 122 s / concurrent 19 s) this session.

Headline cold measurements: `suite` 1497 runs / 10153 assertions / 0F /
0E / 5S, wall **221 s ≤ 240 s**; `parallel-parity` PARALLEL_OK 1497/10147/
0F/0E/5S wall 41.0 s, COVERAGE_OK runs=1497 enum=1497; `parallel-repeat`
3 runs identical literals (1497/5S, assertions 10142–10148 inside the ±20
band); `deflake-interrupt-streak` GREEN cold under the runner
(`DEFLAKE_INTERRUPT_OK standalone=16 steal=8`, every iteration inside the
90 s watchdog); `deflake-no-widening` GREEN cold (all five legs —
sentinels byte-frozen vs `40ed92b`, zero production bytes, zero added
sleeps, `PARENT_DEADLINE_S = 180` unmoved, `BELT_AUDIT_OK` both named
tests belted); `scope` GREEN cold.

## Diff review (read in full against the Specification's intent)

- `test/chat_test.rb` (2 hunks): both named tests gate ESC on
  `captured.any? { … user "long stream" }` AND ≥3 rendered chunks
  (`widget_lines_with_spans` — both helpers pre-exist at base); script
  40→80 chars at the FROZEN 0.1 s/char server pace (≈8 s > the 5 s
  deadline — a dropped interrupt can never mask as natural end; the
  interrupt path cancels immediately, measured green cost +0.25 s/test —
  NOT a widening: no deadline, timeout, pace, or poll interval moved);
  the `:1608` test gains the I82 Law-4 `ensure kernel.stop!` belt (the
  escape twin's belt untouched). Test names and every assertion
  byte-unchanged.
- `test/support/mock_llm_server.rb` (4 hunks, strictly additive): doc
  comment; `@script_mutex`; `serve`'s `@script.shift || fallback` →
  `take_spec(parsed_body)`; the new selector — first `match:`-truthy entry
  (removed, served once), else first match-less entry (= the old blind
  shift, byte-identical for every pre-I87 caller), else the unchanged
  `{type: :message, content: ""}` fallback; selection under the mutex
  (per-connection serve threads). `rearm!`/`suppress_usage!`/request
  logs/EPIPE arms/top-level minitest-optional shape untouched (the rig's
  `mock_llm_extension_test` pins pass in the cold suite).
- `test/subagents_e2e_test.rb` (2 hunks): legs B + E2 scripts — the same
  three response specs byte-identical, now `match:`-routed (parent turn 1
  by the B_PROMPT user message, parent turn 2 by the `c1` tool message,
  the child by the B_CHILD_TASK user message). Order-independent by
  construction; every leg assertion byte-untouched; drain pair still 2
  runs / 46 assertions.
- NEW `test/support/mock_llm_match_test.rb` — 6 hermetic pins over a real
  TCP socket (routing order-independence incl. the flipped child-first
  order, legacy blind-shift preservation, park + unchanged fallback,
  `rearm!` restoration, first-match-wins/serve-once, the streaming arm
  end-to-end). Suite growth exactly +6 (1491→1497, judge-measured in the
  cold serial suite AND the parallel COVERAGE legs). NIT (recorded, no
  action): the file's header comment says "grows by exactly THESE five" —
  six pins ship; the report and every measured literal say 6. Cosmetic
  comment drift only.

## Per-AC rollup

- **AC1 (forensics) — PASS.** Both classes: named firing tests; stated
  mechanisms with evidence (the class-(a) instrumented in-suite firing at
  pre-cure par cycle 5/11 with the preserved worker log + judge-read
  instrument dump refuting W1/W2 literally; the class-(f) arrival-order
  flip confirmed as Grounds stated, reproduced reduced-context against
  BASE mock-server bytes firing the exact `B_FINAL`-inversion signature —
  Law 0's "same signature" sanction); per-edit itemization old→new
  complete.
- **AC2 (class (a) cured) — PASS.** Handshake ordered on the
  request-captured + chunks-rendered observables; stream outlasts the
  deadline; both belts in place (`BELT_AUDIT_OK` cold); amplifier GREEN
  cold (×16 + ×8 steal); ZERO (a) signatures across 27 consecutive
  judge-cold full runs + the builder's 16/16.
- **AC3 (class (f) cured) — PASS.** Content routing verified additive in
  the diff; both legs converted with every assertion intact; 6 hermetic
  pins (+6 exactly); drain amplifier GREEN verbatim standalone cold (×16 +
  ×8 steal); ZERO (f) signatures across the same exposure.
- **AC4 (measured bar) — PASS, with one recorded adjudication.** The
  (a)/(f) streak bar is measured met over several-fold the frozen N
  (judge-cold 27 + builder 16, zero (a)/(f) anywhere); the streak gate's
  two judge-cold REDs are the I85-declared intercom TOCTOU residual only,
  note-and-pass with mechanical attribution (above); serial suite green
  221 s ≤ 240 s cold; the carried floor green with (c)×2/(d)×1 adjudicated
  as declared; suite literals 1497/5S = base + exactly the declared 6
  pins.
- **AC5 (nothing weakens) — PASS.** `deflake-no-widening` all five legs
  GREEN cold; zero production bytes; zero sleeps; every sentinel
  byte-frozen; belts only ever ADDED.
- **AC6 (scope) — PASS.** Tracked diff exactly the frozen 3-file set; ONE
  sanctioned new support file matching the pattern; `Gemfile.lock`
  byte-unchanged; untracked confined to the `t87*` scratch families
  (judge-cleaned pre-integrate) + the sanctioned file; the report itemizes
  107/107 gates with a measured row each.

## Residual risks (carried forward)

1. **The intercom TOCTOU ENOENT** (`test_progress_requests_never_surface…`,
   `request_path` glob→read vs consumer unlink) — now the suite's hottest
   known loud-red class (~3/29 judge-cold full runs; I85 1/9). Rides
   note-and-pass per the I85 standing ruling; RECOMMENDED headline for the
   next deflake entry (one-line test-side cure identified, out of this
   iteration's frozen scope).
2. **The class-(a) delivery failure lives in the async/io-event/fiber
   stack** (production-frozen seams): a real-user ESC inside the pre-IO
   window under load can still stick a run. The suite cure gates the
   TEST into the delivered-cancellation state; production hardening (if
   desired) is an owner-routed follow-up — candidate problems.md note.
3. The parallel exit-teardown wedge (I85 residual #1) was observed once
   more during this judge's base-tree attribution runs (run 3 wedged at
   base `40ed92b`, scratch OS-cleaned before inspection) — the standing
   residual stands, unchanged by this lane.
4. Rehearsal-era `t87*` scratch sits untracked at the canonical checkout
   (`repos/tart`, spec-time 2026-10-24 21:25–22:23 + this judge's
   attribution runs) — housekeeping for the integrator/owner, no tracked
   drift.
5. Cosmetic: the new pin file's header comment says "five" where six pins
   ship.

STATUS: lane core — COMPLETE, verdict CONTINUE, integration follows.
