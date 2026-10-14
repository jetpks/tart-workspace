# I53: gem-concurrency-docs

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I53 gem-concurrency-docs

## 0. Control (this session)

- Space base: `9b274d8` (the fiber-native program's final report commit;
  I52 fast-completions-integration is CLOSED — verdict 7b52b9b1, lane
  merge `1a8ea775` on project/pi-port, index row updated at `ac0da7e`).
- This iteration: ENTRY 1 of the gem-polish program
  (`notes/plan-20261014T070847Z.md` — read in full this session; its
  standing-rules preamble governs). It is the program's ONLY entry;
  after it the program is complete and landing is the human's.
- repos/fast-llm at `main` `4736ddc` — the owner's README commit IS the
  tip ("update readme", 2026-10-14 01:00 −0600, touches
  `gems/completions/README.md` only). Tree clean; the gem (0.1.0,
  122-example RSpec suite, 11/11 wire fixtures) is the I51 deliverable
  with the I51 judge fixes (`dc8eea9`) integrated.
- repos/tart at `project/pi-port` `1a8ea775` (I52 integrated tip) —
  READ-ONLY for this entry (executor precedent + pin precedents only).
  This entry never edits tart.
- repos/pi at `f1b2e77f5` (the pinned fork, unchanged since I51) — the
  source oracle, read-only.
- House docs pattern verified read-only at
  `~/architect/spaces/20260919-review-fast-prom-protowire/repos/{fast-prometheus,fast-protowire}`
  (also `20260910-fast-prometheus-release` — same trees).

## 1. The program frame (owner rulings 2026-10-14, plan preamble + handoff)

- Order: gem polish FIRST, then live-run rev3 (a separate program; not
  this entry's).
- **The owner's README prose on the gem is BYTE-FROZEN** (owner ruling
  2026-10-14, commit `4736ddc`): the docs lane fixes/defines links and
  moves sections per the plan, and touches NO other prose. This is the
  entry's sharpest constraint — mechanically pinned (AC6).
- **Wire-neutral again**: concurrency changes WHO runs tools in the
  standalone Chat, never any request/response byte. Wire/session digests
  on EXISTING scenarios must not move; new behavior gets new
  scenarios/specs only, never edits to old pins.
- Builders never commit, never push, no GitHub/rubygems actions in-loop;
  release tags are the human's at landing; the loop stops at releasable.
- Loop discipline: rehearse → freeze → provision → dispatch → judge →
  integrate. Children never block on contact_supervisor — escalation
  only via `build/loop/exception-*.md` checkpoints.

## 2. PHASE -1 — plan cite verification (this session, against the final integrated trees)

Every file:line cite in the plan entry was re-verified. Two relocations,
both spec inputs (the plan's premises hold; nothing invalidates them —
no exception file needed):

- **"executeToolCalls ~:600-665"** — in the pinned fork the parallel
  executor is `executeToolCallsParallel` at
  `packages/agent/src/agent-loop.ts:586-664` (the plan's `:646`
  `Promise.all` cite is EXACT — verified at :646). `executeToolCalls`
  itself (:508-523) is now a DISPATCHER between a sequential arm
  (:530-583) and the parallel arm; the dispatcher consults
  `config.toolExecution === "sequential"` and per-tool
  `executionMode === "sequential"`. Consequences: (a) the plan's
  described shape IS the parallel arm, verbatim; (b) pi's default is
  concurrent (the plan's premise); (c) the plan's parenthetical "(pi
  has none)" about a concurrency knob is FACTUALLY OFF for the pinned
  fork — pi has `config.toolExecution` + `executionMode`. The owner's
  directive (NO knob in the gem) governs regardless; D6 records it.
- **"fast-prometheus's tree … 11 pages"** — fast-prometheus's tree has
  16 pages (4 explanation + 7 how-to + 4 reference + 1 tutorial);
  fast-protowire's has 11 (3+4+3+1). The four-quadrant + README-landing
  premise holds on both trees; the count belongs to protowire. This
  spec's page list (11 pages) mirrors protowire's shape by coincidence
  of content, not by count-mandate.

All other cites verified exact: chat.rb `run_tool_batch` :132-150 with
the `final.content.each` serial loop; the four dangling README
reference links at :5/:15/:16/:32; the README section map (Dialects
:26, Installation :35, Quickstart :43, Dialects as data :84, Error
taxonomy :109, Parity :124); the 13-key `VOCABULARY` (dialects.rb:17-31,
counted); the trio declarations (:150/:159/:168); the I50 overlap pin
(tart `test/agent_loop_test.rb:609`) and the I52 cancel-during-batch
pin (:732).

## 3. THE ORACLE — pi's parallel batch executor (agent-loop.ts :508-664, verified line-by-line this session)

`executeToolCallsParallel` (:586-664), per tool call in the batch,
SERIALLY in the loop (:593-643):
1. `tool_execution_start` emitted.
2. `prepareToolCall` (:713-770): tool look-up (unknown ⇒ IMMEDIATE
   error result `Tool <name> not found`), `prepareToolCallArguments`,
   `validateToolArguments` (validation errors ⇒ immediate), the
   `beforeToolCall` hook (awaited — runs IN THE LOOP, serial), abort
   checks; any exception in prep ⇒ immediate error result.
3. Immediate outcomes are finalized INLINE (:618-628) — `tool_execution_end`
   emitted in the loop, pushed as a VALUE — no concurrency for them.
4. Every executable call becomes an async THUNK pushed IN ORDER
   (:631-644). The thunk: signal-abort check at entry, then
   `executePreparedToolCall` (:807-838 — `tool.execute` awaited; a
   THROWN error is caught and becomes an `isError` result — the thunk
   NEVER rejects for tool failure; update events drained), then
   `finalizeExecutedToolCall` (:855-904 — the `afterToolCall` hook runs
   INSIDE the thunk, per call as it completes; hook errors convert to
   error results), then `tool_execution_end` emitted inside the thunk
   as that call completes.
5. `await Promise.all(thunks)` (:646) — concurrent execution;
   `orderedFinalizedCalls` preserves CALL ORDER (Promise.all
   semantics), independent of completion order.
6. Tool-result messages are created + emitted AFTER the join, IN CALL
   ORDER (:648-655).

The sequential arm (:530-583) exists only behind the knob — it is NOT
the gem's model (D6).

## 4. The gem today (fast-llm 4736ddc — the surface this entry changes)

- `lib/fast/completions/chat.rb`: `#step` :98-128 (stream → append
  assistant → `run_tool_batch` on `:tool_use`); `run_tool_batch`
  :132-150 — `final.content.each` → per tool_call block: latch check
  (:138) + `Cancellation.check` (:141), `@before_tool_hooks` dispatch,
  `execute_tool_call` (:155-170 — tool look-up there; unknown tool ⇒
  `{content: "no such tool: <name>", is_error: true}`; `{error:}`-Hash ⇒
  error result; Hash ⇒ JSON.generate; else to_s), `Message.tool_result`
  construction, `@after_tool_hooks` dispatch, `add_message` — all
  SERIAL on the calling fiber (I51's frozen D9: "tart owns its own
  concurrency; the gem's loop is one batch per step"). The owner
  reopens D9 for standalone consumers 2026-10-14 (plan Grounding).
- `cancel` (:89-95): latch `@cancelled` + `Async::Cancel` into
  `@in_flight` (the step task) unless self-cancelled; `#step`'s ladder
  (:122-124) converts `Async::Cancel` ⇒ `CancelledError` (D8 — no
  phantom terminal).
- `cancellation.rb`: `Cancellation.check` — raises `CancelledError`
  when the current Async task is cancelled; no-op off-reactor.
- `Async::Cancel < Exception` (NOT StandardError — verified against
  async 2.46.0, the installed pin); `CancelledError < StandardError`
  and NOT under `Error` (errors.rb:46-47).
- **The frozen regression net (must pass UNMODIFIED)**:
  `spec/fast/completions/chat_spec.rb` (7 examples — incl. "executes a
  multi-call batch SERIALLY in tool-call order (D9)" :144-159, pinning
  before-hook order `%w[c1 c2]` AND tool_result call-order; "yields an
  error result for unknown tool names" with the exact
  `"no such tool: nope"` bytes; hooks-in-registration-order;
  complete?-state machine) and `stream_cancel_spec.rb` (4 examples —
  incl. "the tool batch stops at the next Cancellation.check once
  cancelled (D8)" :63-88: a tool SELF-CANCELS inside the first of two
  executions; pins `ran == ["a"]` — tool c2 NEVER executes — and
  `step` raising `CancelledError`). Both stay byte-identical: the
  concurrent shape must preserve these observables (analysis at D5).
- The wire fixtures (`spec/fixtures/wire/*.json`, 11 SHA256-pinned) +
  `wire_parity_spec.rb` replay pre-built history through Chat → Client
  → Protocol; the scripted replies never request tools, so the
  executor is OFF the parity path — wire-neutrality is structural as
  long as history appends stay call-ordered (D7).

## 5. tart's I52 executor — the in-house fiber precedent (read-only)

`tart/lib/tart/agent/chat.rb` (I52 spec §2 D2): `run_tool_batch`
:249-253 — `parent = Async::Task.current`; one `parent.async { … }`
child per call (children of the TURN task — Sync-inline reactor
discipline, the I50-proved shape); `children.map(&:wait)` joins with
immediate re-raise on cancel (never waits out natural completion —
I50's probe6-ARM-A residual closed); results append in CALL order;
per-child checkpoint at `execute_tool_call` entry (:258-260). The two
empirical pins (tart `test/agent_loop_test.rb`):
- `test_fibers_tool_concurrency_overlaps_two_interleaved_tools` :609 —
  two 0.5 s sleep tools in ONE batch: wall span (first start → last
  end) < 0.9 s vs the Bridge-era sequential ≈ 1.0 s; both `:tool`
  messages land.
- `test_cancel_during_tool_batch_aborts_fast` :732 — cancel ~0.1 s
  into a two-call 0.5 s batch: the abort surfaces < 0.2 s after the
  cancel (natural completion ≈ 0.4 s later), no error terminal.
Both bounds are adopted for the gem's NEW pins (Specification §2).

## 6. The house docs pattern + the owner's README (docs lane grounding)

- House pattern (both fast- family trees, verified): `docs/tutorials/`,
  `docs/how-to/`, `docs/reference/`, `docs/explanation/` — one task per
  page, kebab-case filenames, README as the landing page linking into
  the tree. fast-prometheus: 16 pages; fast-protowire: 11 (see §2).
- The owner's README (`gems/completions/README.md` @ 4736ddc) carries
  FOUR dangling reference links with NO definitions anywhere:
  `[socketry/async-http]` :5, `[see the tool docs]` :15,
  `[see the dialect docs]` :16, `[Dialect Docs]` :32. The plan fixes
  their destinations: the first three → pages this lane creates; the
  last → `https://github.com/socketry/async-http`.
- Content seeds (no inventions required): the Tool DSL
  (`tool.rb` — description/tool_name/parameters/execute + the §11
  outcome contract String/Hash→JSON/`{error:}`); the 13-key
  `VOCABULARY` + the DSL + registry semantics (declare/lookup/last-wins,
  `dialects.rb`); the error taxonomy table (README :109-123, moving to
  `docs/reference/errors.md`); the stream-event vocabulary (`Event`:
  `:start`, `:text_start/:text_delta/:text_end`,
  `:thinking_start/:thinking_delta/:thinking_end`,
  `:tool_call_start/:tool_call_delta/:tool_call_end`, client-level
  `:error` + `:done` with `reason`); the Quickstart (README :43-82) and
  "Dialects as data" (:84-107); cancel semantics (D8) and the
  fiber-native section (README :126-133).
- Root `README.md` (fast-llm, house-authored at I51 — NOT owner-frozen):
  describes the monorepo; the plan aligns it to link the docs tree.
- `CHANGELOG.md` 0.1.0 (unreleased — tags are the human's) says the
  Chat "execute[s] tool calls serially with cancellation checkpoints"
  — a stale-by-this-entry statement the concurrency lane corrects
  (house prose, not owner prose).

## 7. Design decisions (letter-grounded; OQs itemized for the judge)

- **D1 — two-phase `run_tool_batch`.** A serial before-phase (per
  tool_call block, in call order: latch check + `Cancellation.check` +
  before hooks + executability resolution), then ONE reactor task per
  executable call (`Async::Task.current.async` — children of the step
  task, the tart D2/I50 Sync-inline discipline), then the join, then
  tool-result Messages appended IN CALL ORDER after the join.
  pi :593-655 shape; tart :249-253 mechanics.
- **D2 — hook placement.** Before hooks fire in the serial before-phase
  in call order (pi's loop-run `beforeToolCall`); after hooks fire
  INSIDE each child as that call completes (pi's thunk-run
  `afterToolCall`), keyed by tool_call id through the call's own
  closure — never completion-shared state. Gem continuity over pi on
  one point: the gem's before hooks fire for EVERY parsed tool_call
  block INCLUDING unknown tools (today's behavior; pi skips the hook
  for unknown tools because its hook can block on validated args — the
  gem's hooks are observers with no block/validation semantics). No
  existing spec pins either order for unknown tools; continuity wins
  (OQ-1).
- **D3 — immediate outcomes finalize inline.** Unknown-tool results
  (`"no such tool: <name>"`, the exact chat_spec bytes) are computed in
  the before-phase and appended in call order WITHOUT a child task
  (pi's immediate-outcome arm). No other prep-error class exists in the
  gem (no validation layer — the consumer's schema is the wire bytes).
- **D4 — per-child failure isolation (pi's per-thunk try/catch).** Each
  child rescues around `execute`: `Fast::Completions::CancelledError`
  re-raised (never laundered into a result); `Async::Cancel` passes
  through untouched (`< Exception`, not caught by `StandardError` —
  verified async 2.46.0); any other `StandardError` from `execute`
  becomes that call's `{content: <message>, is_error: true}` result —
  the sibling calls are unaffected and the join completes (pi
  executePreparedToolCall :824-837). This CHANGES today's raised-domain
  behavior (a raising tool currently propagates out of `step`) —
  pi-mandated by the plan's letter, unpinned at base, additive (OQ-2).
  Hook exceptions (before/after) still propagate out of `step`
  unchanged — today's contract, not this entry's to move.
- **D5 — cancel discipline (I51 D8 extended to the batch).** A cancel
  during the join aborts in-flight children (children of the cancelled
  step task stop via async's stop-children semantics), `step` raises
  `CancelledError`, and NO phantom terminals: no `:error`/`:done`
  event, no tool-result Messages appended, no after hooks fired for
  aborted calls. pi's thunk-entry abort→"Operation aborted" ERROR
  RESULT conversion is NOT ported — the gem's D8 raise-instead
  discipline governs (the frozen `stream_cancel_spec` D8 pin
  `ran == ["a"]` + CancelledError is the anchor: c2's child dies at its
  opening checkpoint, its tool never runs). The self-cancel path keeps
  today's observables: `cancel` inside a tool cancels `@in_flight`
  (the step task, not the child), the step ladder converts, and the
  remaining children's opening checkpoints latch-raise.
- **D6 — NO concurrency knob.** Owner directive (plan letter). pi's
  `config.toolExecution`/`executionMode` sequential escape exists in
  the fork (§2) and is deliberately NOT ported: the gem's Chat is
  always-concurrent across executable calls in a batch; single-call
  batches are the degenerate case. Reopen only on owner ask.
- **D7 — wire-neutrality is structural.** Tool results reach the wire
  only via the NEXT `step`'s request build over `@messages`; the
  codec/request-build is untouched; call-order appends make the history
  bytes identical to the serial executor's for every batch (single- and
  multi-call). The parity fixtures + spec are untouched bytes; the
  wire-parity gate re-runs them unchanged.
- **D8 — docs tree placement + packaging.** The tree lives at
  `gems/completions/docs/{tutorials,how-to,reference,explanation}/`.
  The gemspec `spec.files` glob stays UNTOUCHED
  (`{lib}/**/*` + `*.md` — README/CHANGELOG ship in the .gem exactly as
  I51 froze; docs are repo/GitHub-facing). Packaging docs into the .gem
  is the human's landing-time call (one glob token), recorded here —
  not this entry's (OQ-3).
- **D9 — README surgery is minimal and mechanically pinned.** The ONLY
  section that moves is the Error-taxonomy table (:109-123) →
  `docs/reference/errors.md`, replaced by a short pointer block (≤ 6
  lines) linking the page. "Dialects as data" STAYS (it is positioning
  prose; the plan's "keep … Dialects … pointers" names the section as
  kept; `docs/reference/dialects.md` EXPANDS it). Everything else is
  byte-preserved except ADDED link-definition lines. Byte-preservation
  is pinned against a fixture copy of the 4736ddc README (AC6).
- **D10 — the link checker rides the RSpec suite.**
  `spec/fast/completions/docs_links_spec.rb` (a spec, never lib/ code):
  reference + inline link resolution over the repo's markdown (scoped
  to README.md, gems/completions/README.md, CHANGELOG.md, docs/** —
  EXCLUDING spec/fixtures, whose frozen owner copy dangles by design),
  the four owner labels land at their ruled destinations, quadrant
  non-emptiness, and the D9 prose-preservation line-diff property.
  Riding the suite makes the checks permanent regression gates (the
  standing `gem-suite` gate runs them forever).

Open questions (judge adjudicates; none blocking):
- OQ-1 before-hook firing for unknown tools (D2 gem-continuity choice
  over pi's look-up-first).
- OQ-2 StandardError-from-execute now converts to an error result (D4)
  — a behavior change in the raised domain, pi-mandated, unpinned at
  base.
- OQ-3 docs not packaged into the .gem (D8) — recorded landing-time
  option for the human.
- OQ-4 after hooks are now observable in COMPLETION order for
  multi-call batches (D2/pi shape) — single-call consumers see no
  change; documented in tools.md.

## 8. Standing rules (inherited; binding on every child)

- Per-child timeouts: `timeoutMs` AND `toolTimeoutMs` ≥ 3600000; no
  mid-run contact_supervisor from children; bg_wait abort → re-issue;
  builders zai/glm-5.3-flash; builders never commit (the coordinator
  integrates); loop discipline rehearse → freeze → provision →
  dispatch → judge → integrate.
- Multi-lane dispatch carry-in (I26, binding): each lane prompt opens
  with its lane name + its own touch/must-not lists and embeds ONLY its
  lane's spec section.
- Freeze-time carry-in (I24/I25): grep-verify purity premises before
  freezing; enumerate every file the spec's own artifacts force into
  the touch set.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section gem-concurrency-docs specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision gem-concurrency-docs`
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
`architect rehearse gem-concurrency-docs` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze gem-concurrency-docs` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse gem-concurrency-docs` — before the freeze, while
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
subsection per lane. A copy is written to build/I53-gem-concurrency-docs-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section gem-concurrency-docs prompt --append --lane <lane> --from build/I53-gem-concurrency-docs-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I53-gem-concurrency-docs-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence gem-concurrency-docs --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section gem-concurrency-docs verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify gem-concurrency-docs`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
