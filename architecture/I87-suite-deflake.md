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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section suite-deflake specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision suite-deflake`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
```

## Acceptance Criteria

<!-- PROOF. Write the prose conditions of correctness (AC1, AC2, …) that the
architect judges against. Calibrate precision to the property (SKILL.md §4): a
property criterion is bounded from the defect's side only — freeze a floor, not
an equality; exactness is for criteria whose number is itself the deliverable.
A presence-grep gate on prose is a tripwire, never the proof — its criterion
should say which. Runnable checks live in the fenced ```gates block below
(parsed at freeze time — absent or empty is allowed; malformed fails freeze).
Pre-freeze check — snapshot: no count/name-set/byte-identity frozen at merely
today's value; control: every baseline actually run this session; mechanism: no
*how* where the *what* is the requirement; interface: every CLI surface the
Specification names (verb, flag spelling, subcommand) executed once before it
freezes; dry-run:
`architect rehearse suite-deflake` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze suite-deflake` needs a fresh rehearsal stamp — editing gates
stales it; `--skip-rehearse REASON` records the skip. The stamp records that you
looked, never that gates passed. Freeze commits this file and records its SHA as
freeze_sha. Read-only afterward — any change to Grounds/Specification/Acceptance
Criteria = automatic iteration FAIL. -->

> Gate-pass is necessary, not sufficient: the architect also reads the diff against the
> cited **BRIEF §sections** intent and the §1 cardinal invariant before the verdict.

**AC1.** ...

```gates
# Each gate backs one prose AC above. Remove the comment markers to activate.
# `cmd` paths resolve against the REPO TREE; `cwd` is relative to the SPACE
# ROOT. The judge-time remap is asymmetric: a `cwd` under repos/<repo> is
# remapped into the lane worktree, one outside it passes through unchanged.
# End a multi-step `cmd` with `echo SENTINEL` + `stdout_match`: /bin/sh (the
# gate runner's shell) has no `set -e`, so an early branch can exit 0 — the
# sentinel proves the command reached its end.
# Draft, then run `architect rehearse suite-deflake` — before the freeze, while
# a bad gate still costs nothing.
# - id: suite-green        # unique slug within the iteration (required)
#   ac: AC1                # which prose AC this gate backs (required)
#   cwd: repos/my-repo     # run dir, space-root-relative (optional)
#   cmd: |-                # block style by default — a plain scalar breaks on `: `
#     bundle exec rake test && echo SUITE_OK
#   expect:                # at least one of: exit_code, stdout_match, threshold
#     exit_code: 0
#     stdout_match: SUITE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I87-suite-deflake-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section suite-deflake prompt --append --lane <lane> --from build/I87-suite-deflake-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I87-suite-deflake-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence suite-deflake --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section suite-deflake verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify suite-deflake`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
