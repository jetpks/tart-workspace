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

# Specification — I53 gem-concurrency-docs

## 0. Objective

One iteration, two lanes on repos/fast-llm @ `4736ddc`, disjoint file
sets, one judge pass (the gem-polish program's single entry):

1. `concurrency` — reopen I51's frozen D9: the gem's standalone Chat
   executes a tool batch CONCURRENTLY (pi's `executeToolCallsParallel`
   shape, tart's I52 fiber mechanics), wire-neutral, with the cancel
   discipline (I51 D8) extended to the batch.
2. `docs` — the diataxis pass + the owner's four dangling README links,
   owner prose byte-frozen (Grounding D9).

After this entry the program is complete; landing (publish/push/release
tags) is the human's.

## 1. Lane `concurrency` — the concurrent tool batch

### 1.1 `run_tool_batch` becomes two-phase (chat.rb; Grounds D1–D5)

Rewrite `run_tool_batch` (chat.rb:132-150) as:

**Phase A — serial before-phase**, per tool_call block of
`final.content` IN CALL ORDER, on the calling fiber (pi's loop,
agent-loop.ts:593-643):
1. Latch check (`@cancelled` ⇒ raise `CancelledError`) + 
   `Cancellation.check` — the per-iteration checkpoint, today's
   :138/:141 discipline kept (a cancel latched by an earlier call's
   hook raises HERE, before this call's hooks fire — spec'd by
   batch_cancel_spec example 2).
2. Before hooks dispatch in registration order (unchanged contract).
3. Executability resolution: resolve the tool. Unknown tool ⇒ an
   IMMEDIATE outcome — the exact today-bytes result
   `{content: "no such tool: <name>", is_error: true}` — recorded
   INLINE in call order, NO child task (pi's immediate arm; Grounds
   D2/D3: hooks fire for unknown tools too, gem continuity).
4. Executable calls collect as ordered specs.

**Phase B — concurrent execution**: one `Async::Task.current.async`
child per executable call (children of the STEP task — the Sync-inline
reactor discipline; tart I52 D2 precedent). Each child, in order of
body:
1. Opening checkpoint: latch check + `Cancellation.check` (a cancel
   that landed during Phase A or a sibling's execution kills the child
   HERE — its tool never runs; the frozen stream_cancel D8 pin
   `ran == ["a"]` depends on exactly this).
2. `execute` with the §11 outcome mapping (String verbatim / Hash ⇒
   JSON.generate / `{error:}` ⇒ error result — unchanged bytes).
3. Failure isolation (Grounds D4): rescue ladder around the execution —
   `Fast::Completions::CancelledError` ⇒ re-raise (never a result);
   `Async::Cancel` ⇒ passes through (`< Exception`, not caught);
   other `StandardError` ⇒ that call's result becomes
   `{content: e.message.to_s, is_error: true}` — siblings unaffected,
   the join completes (pi executePreparedToolCall :824-837).
4. After hooks fire INSIDE the child, as the call completes (pi's
   thunk-run `afterToolCall`), keyed by tool_call id through the call's
   own closure. Hook exceptions are NOT converted — they propagate
   (today's contract; Grounds D4).
5. The child's Message.tool_result is collected INDEX-KEYED (call
   position), never completion-keyed.

**Join**: wait all children; a cancel during the join aborts in-flight
children (async stop-children), the join re-raises IMMEDIATELY (never
waits out natural completion — the I50 ARM-A class), `#step`'s
existing ladder (:120-124) surfaces `CancelledError`; NO phantom
terminals: zero tool-result Messages appended, no after hooks fired
for aborted calls (Grounds D5).

**After the join**: append the tool-result Messages IN CALL ORDER
(index-keyed collection; pi's orderedFinalizedCalls + post-join
message creation, :646-655). History bytes are thereby identical to
the serial executor's for every batch (Grounds D7 — wire-neutral by
construction).

Unchanged (frozen surface): `#step`'s stream path, the
assistant-append ordering, `@tool_batch_pending`/`complete?` state
machine, `cancel`/`@in_flight` mechanics, hooks' registration-order
contract, `execute_tool_call`'s outcome-mapping bytes, `add_message`,
the public method set. No concurrency knob of any kind (Grounds D6).
Update the chat.rb class/method comments that say "SERIALLY (D9)" to
the new shape (comments are house prose, not owner prose).

### 1.2 NEW spec: `tool_concurrency_spec.rb` (RED at base BY DESIGN where marked)

`gems/completions/spec/fast/completions/tool_concurrency_spec.rb`,
mock-driven (chat_spec idioms: MockLLMServer, `:stream` + `tool_calls`
scripts, `Async do … end`, `client.close`). Every wall bound cites the
tart precedent bounds (Grounds §5). Required examples:

1. **Overlap + span** [RED at base]: two 0.5 s sleep-tools in ONE
   scripted batch (Kernel#sleep inside execute — scheduler-interruptible
   under the reactor). Each tool records monotonic entry/exit stamps.
   Assert: `max(entries) < min(exits)` (the execution windows overlap —
   serial fails: entry₂=0.5 ≮ exit₁=0.5) AND wall span (first entry →
   last exit) `< 0.9` s (concurrent ≈ 0.5; serial ≈ 1.0 — the I50
   bound) AND both tool-result Messages land.
2. **Call-order results under inverted completion + completion-order
   after hooks** [RED at base]: c1 sleeps 0.5 s, c2 sleeps 0.2 s in one
   batch (completion order c2-first). Assert: tool_result Messages in
   CALL order `[c1, c2]` with correct ids; after-hook fire order ==
   completion order `[c2, c1]` (per-child hooks, Grounds D2/OQ-4);
   before-hook fire order == call order `[c1, c2]` (serial phase).
3. **Failure isolation** [RED at base]: c1's execute raises
   `StandardError`("boom"), c2 sleeps 0.2 s clean. Assert: `step`
   completes; c1's result `is_error: true` with content exactly
   `"boom"`; c2's result clean; both appended in call order (Grounds
   D4 — at base the raise propagates out of step).
4. **Unknown tool finalizes inline in a multi-call batch** [GREEN at
   base — regression guard for the two-phase split]: batch
   [known-tool c1, unknown "nope" c2]. Assert: results in call order;
   c2 content exactly `"no such tool: nope"`, `is_error: true`; c1's
   before+after hooks fired.

### 1.3 NEW spec: `batch_cancel_spec.rb` (RED at base BY DESIGN)

`gems/completions/spec/fast/completions/batch_cancel_spec.rb`:

1. **Cancel during the join** [RED at base via the entered-set]: two
   0.5 s sleep-tools; a sibling task (same reactor) waits for the
   FIRST tool's entry signal (a Queue handshake), settles ~0.05 s
   (both children provably in flight — they enter within the first
   scheduler tick), then `chat.cancel`. Assert: BOTH tools entered
   (entered == `[c1, c2]` — at base c2 never enters: RED); wall from
   cancel to `CancelledError` surfacing `≤ 0.2` s (natural completion
   ≈ 0.4 s away — the I52 bound); `step` raised `CancelledError`; ZERO
   tool-result Messages in `chat.messages`; ZERO after-hook fires; the
   observed step-block events end at the stream's `:done` — no
   `:error`/`:done` after the cancel (no phantom terminals, Grounds
   D5).
2. **Cancel latched by a before hook stops the batch at the next
   phase checkpoint** [RED at base]: two-call batch; c1's before hook
   calls `chat.cancel`. Assert: `step` raises `CancelledError`; NO
   tool executes (`ran == []` — at base c1 still executes after its
   own hook's cancel: RED); c2's before hooks never fire; no
   tool-result Messages. (Grounds D5; deterministic — no timing.)

### 1.4 CHANGELOG correction (house prose)

`gems/completions/CHANGELOG.md` 0.1.0: the Chat bullet "execute tool
calls serially with cancellation checkpoints and before/after hooks
keyed by tool-call id" is now false. Rewrite that bullet to the new
contract (concurrent batch — one reactor task per call, results in
call order, per-call failure isolation, batch cancel discipline).
No version bump, no new section (0.1.0 is unreleased; tags are the
human's).

### 1.5 Verification (concurrency lane, in its worktree)

```
cd repos/fast-llm && bundle install --quiet && bundle exec rspec   # 0 failures
bundle exec rspec gems/completions/spec/fast/completions/wire_parity_spec.rb   # byte-parity green, untouched
bash gems/completions/script/install_check.sh   # INSTALL_CHECK_OK (smoke runs the new executor)
git diff --stat   # only the 4 declared files
```

## 2. Lane `docs` — the diataxis tree + the owner's links

### 2.1 The page list (EXACTLY these 11 paths, all NEW)

Under `gems/completions/docs/` — one task per page, README the landing
page (house pattern, Grounds §6). Content contracts (property-level;
prose is the builder's, seeded from the cited sources — no inventions):

| Page | Required content (seeds) |
|---|---|
| `docs/reference/tools.md` | The Tool DSL: `description`/`tool_name`/`parameters` (literal + block forms)/`execute`; wire-name rule (`tool_name` ∥ class basename); parameters emitted VERBATIM (§9.2); the §11 outcome contract (String verbatim, Hash ⇒ JSON, `{error:}` ⇒ error result); `with_tools` class-or-instance. THE FIBER-SAFETY CONTRACT: execute runs on a reactor child — never block the reactor; batch semantics per THIS spec §1 (concurrent, results in call order, raising isolates to an error result, cancel aborts with `CancelledError` and no results); hooks (registration order, id-keyed; after hooks fire in completion order). Target of `[see the tool docs]`. |
| `docs/reference/dialects.md` | All 13 VOCABULARY keys with defaults + allowed values (dialects.rb:17-31 — the full table); the shipped `:zai`/`:deepseek`/`:fireworks` declarations verbatim (:150-168); declaring custom (block DSL + kwargs); `Fast::Completions.dialect(:x)` lookup (KeyError), `.dialects`; last-wins re-declaration; `Model` resolution (explicit Dialect ∥ symbol ∥ default); `ArgumentError` on unknown key/value. Target of `[see the dialect docs]` AND `[Dialect Docs]`. |
| `docs/reference/errors.md` | The README's error-taxonomy table MOVED here (rows verbatim) + expansion: status mapping for the ApiError tree; `TimeoutError` (TTFB + inactivity); `ConnectionError` (ECONN*); `StreamError` (emits `:error` first); `CancelledError` NOT under `Error` and why (rescue-ladder cleanliness, D8). |
| `docs/reference/stream-events.md` | The full `Event` vocabulary with per-type fields: `:start`, `:text_start/:text_delta/:text_end`, `:thinking_start/:thinking_delta/:thinking_end`, `:tool_call_start/:tool_call_delta/:tool_call_end` (protocol.rb), client-level `:error` (reason `:error`) + `:done` (finish reason — `:tool_use` et al.); the `#step` block contract. |
| `docs/tutorials/first-run.md` | The README Quickstart grown into a first-run tutorial: client + model + one tool, streamed (the `Async do` shape, `#step` block over deltas), what `complete?` means, the follow-up turn consuming tool results. |
| `docs/how-to/declare-a-custom-dialect.md` | Task-shaped: declare, mount on a Model, last-wins override, the closed-vocabulary failure. |
| `docs/how-to/cancel-a-running-chat.md` | Task-shaped: `chat.cancel` mid-stream vs mid-batch (in-flight children abort, `CancelledError`, no phantom terminals, no results), connection discard + reuse, the latch. |
| `docs/how-to/add-a-tool.md` | Task-shaped: subclass, declare, register, the outcome contract, the fiber-safety note (link tools.md). |
| `docs/explanation/why-streaming-only.md` | No synchronous requests: the fiber-native stance + why. |
| `docs/explanation/why-dialects-as-data.md` | The LiteLLM anti-shape: no universal translation, closed vocabulary, fail-loud at declaration, no base-URL detection. |
| `docs/explanation/fiber-native-design.md` | The reactor contract: caller's reactor, ONE persistent `Async::HTTP::Client`, requests as reactor tasks, `Async::Cancel` semantics, the batch executor (children of the step task), zero gem-owned threads/reactors. |

### 2.2 README surgery (gems/completions/README.md — owner prose BYTE-FROZEN, Grounding D9)

1. ADD the four link definitions (anywhere legal; house style = a
   definitions block at the end):
   - `[see the tool docs]: docs/reference/tools.md`
   - `[see the dialect docs]: docs/reference/dialects.md`
   - `[Dialect Docs]: docs/reference/dialects.md`
   - `[socketry/async-http]: https://github.com/socketry/async-http`
2. MOVE the Error-taxonomy section: the `## Error taxonomy` heading +
   table (:109-123) leave the README, replaced by a pointer block of
   AT MOST 6 lines: the `## Error taxonomy` heading kept + 1–2
   sentences + a link resolving to `docs/reference/errors.md`.
3. NOTHING ELSE: every other line byte-identical to `4736ddc` (pinned
   mechanically, AC6). "Dialects as data" STAYS (Grounds D9);
   Installation/Quickstart/Dialects/Parity pointers unchanged.

### 2.3 Root README + fixture

- `README.md` (monorepo root, house-authored): align to link the docs
  tree — a minimal edit (e.g. the `gems/completions` bullet gains a
  docs/ mention/link). No other changes.
- `spec/fixtures/readme/owner-4736ddc.md` (NEW): a byte-verbatim copy
  of `git show 4736ddc:gems/completions/README.md` — the prose-preservation
  anchor. Byte-identity to 4736ddc is gate-pinned (AC6), not spec-pinned.

### 2.4 NEW spec: `docs_links_spec.rb` (rides the standing suite; RED at base BY DESIGN)

`gems/completions/spec/fast/completions/docs_links_spec.rb`. Properties
(all mechanical; no network):

1. **Prose preservation** (vs the §2.3 fixture, line-LCS diff): every
   REMOVED line belongs to the Error-taxonomy section (from
   `## Error taxonomy` inclusive to `## Parity` exclusive); every
   ADDED line is either a link definition (`/\A\[[^\]]+\]:\s*\S/`) or
   part of ONE contiguous replacement block ≤ 6 lines that links
   `docs/reference/errors.md` and sits between the "Dialects as data"
   section and `## Parity`. (Green-at-base trivially — the README IS
   the fixture at base; non-vacuous post-change.)
2. **Link resolution**: for every `.md` in scope — repo `README.md`,
   `gems/completions/README.md`, `gems/completions/CHANGELOG.md`,
   `gems/completions/docs/**/*.md` (EXCLUDING `spec/fixtures/**`, whose
   frozen owner copy dangles by design; fenced code blocks skipped) —
   every reference definition and inline link with a relative path
   resolves to an existing file (anchor fragments stripped); absolute
   `http(s)://` URLs pass.
3. **Label closure**: every used reference label `[label]` has a
   definition in the same file (the four owner links LAND).
4. **The four ruled destinations** (gems/completions/README.md):
   `[see the tool docs]` → `docs/reference/tools.md`;
   `[see the dialect docs]` → `docs/reference/dialects.md`;
   `[Dialect Docs]` → `docs/reference/dialects.md`;
   `[socketry/async-http]` → `https://github.com/socketry/async-http`.
5. **Quadrants non-empty**: `docs/{tutorials,how-to,reference,explanation}`
   each contain ≥ 1 `.md`.

### 2.5 Verification (docs lane, in its worktree)

```
cd repos/fast-llm && bundle install --quiet && bundle exec rspec   # 0 failures (docs_links_spec red-at-base in ITS OWN worktree is the designed base state; the lane turns it green)
git show 4736ddc:gems/completions/README.md | diff - gems/completions/spec/fixtures/readme/owner-4736ddc.md   # empty
git diff 4736ddc -- gems/completions/README.md   # only link definitions + the one moved section
```

The docs lane documents THIS SPEC's §1 batch contract (frozen here),
not the sibling lane's working tree — the lanes are independent and
may run concurrently.

## 3. May touch / must not touch

May touch (the ```lanes block below is the frozen truth; this prose
summarizes):

- Lane `concurrency` (repo fast-llm):
  `gems/completions/lib/fast/completions/chat.rb`,
  `gems/completions/CHANGELOG.md`, and the two NEW spec files
  (`tool_concurrency_spec.rb`, `batch_cancel_spec.rb`).
- Lane `docs` (repo fast-llm): `README.md` (root),
  `gems/completions/README.md`, the 11 NEW `gems/completions/docs/**`
  pages (exact paths §2.1), the NEW fixture
  `gems/completions/spec/fixtures/readme/owner-4736ddc.md`, and the NEW
  `gems/completions/spec/fast/completions/docs_links_spec.rb`.

Must not touch (either lane):

- EVERY pre-existing spec file and fixture — the frozen regression
  net: all of `gems/completions/spec/fast/completions/*_spec.rb` as it
  stands at `4736ddc`, `spec/fixtures/wire/**`,
  `spec/support/mock_llm_server.rb`, `spec/spec_helper.rb`. New
  behavior gets NEW spec files, never edits to old pins.
- `gems/completions/lib/fast/completions/**` EXCEPT `chat.rb` (docs
  lane touches NO lib/ file at all — a stray lib/ edit fails its
  scope).
- `gems/completions/fast-completions.gemspec`, root `Gemfile` +
  `Gemfile.lock`, `.rspec`, `.gitignore`,
  `gems/completions/script/install_check.sh`,
  `gems/completions/lib/fast/completions/version.rb` — packaging and
  deps are FROZEN (Grounding D8).
- Every other repo (`repos/tart`, `repos/pi`, all others) — read-only.
- No `git push`, no GitHub/rubygems actions, no tags; builders never
  commit.

Out of scope (itemized; reopen on owner/consumer need): any
concurrency knob (Grounding D6); tart-side changes (tart keeps its own
executor, I52 D1/D2); packaging docs into the .gem (Grounding D8/OQ-3);
benchmark page (no data — landing-time concern); retries; the 0.1.0
release itself.

## 4. Lane plan

Two lanes, repo fast-llm, DISJOINT by construction (19 files total: 4 +
15), independent — dispatch may run them concurrently; integrate in
lane-declaration order (`concurrency`, then `docs`; no dependency
either way). Both lanes verify in their own worktrees (§1.5/§2.5); the
judge runs the full gate battery cold on the integrated tree.

```lanes
- name: concurrency
  repo: fast-llm
  touch:
    - gems/completions/lib/fast/completions/chat.rb
    - gems/completions/CHANGELOG.md
    - gems/completions/spec/fast/completions/tool_concurrency_spec.rb
    - gems/completions/spec/fast/completions/batch_cancel_spec.rb
- name: docs
  repo: fast-llm
  touch:
    - README.md
    - gems/completions/README.md
    - gems/completions/docs/tutorials/first-run.md
    - gems/completions/docs/how-to/declare-a-custom-dialect.md
    - gems/completions/docs/how-to/cancel-a-running-chat.md
    - gems/completions/docs/how-to/add-a-tool.md
    - gems/completions/docs/reference/tools.md
    - gems/completions/docs/reference/dialects.md
    - gems/completions/docs/reference/errors.md
    - gems/completions/docs/reference/stream-events.md
    - gems/completions/docs/explanation/why-streaming-only.md
    - gems/completions/docs/explanation/why-dialects-as-data.md
    - gems/completions/docs/explanation/fiber-native-design.md
    - gems/completions/spec/fixtures/readme/owner-4736ddc.md
    - gems/completions/spec/fast/completions/docs_links_spec.rb
```

## Acceptance Criteria

# Acceptance Criteria — I53 gem-concurrency-docs

Gate calibration (pre-declared; all gates `cwd: repos/fast-llm`, run
cold by the judge on the INTEGRATED tree — both lanes merged; base =
`4736ddc`):

- GREEN at base: `gem-suite` (122/0), `wire-fixtures-digests`,
  `wire-parity`, `install-check` — the I51 deliverable is green going
  in; this entry must not regress them.
- RED at base BY DESIGN: `tool-overlap` (serial executor: no overlap,
  span ≈ 1.0 s, raise propagates), `batch-cancel` (at base the second
  tool never enters before the cancel; a hook-cancel still executes
  its own call), `docs-links` (no docs tree; four dangling links),
  `readme-fixture` (fixture does not exist at base),
  `changelog-concurrency` (0.1.0 claims serial execution). Each is the
  designed red proving its gate is non-vacuous; the builder's work
  turns each green.
- `scope` is RED at base (vacuous diff) and must be EXACT + non-vacuous
  on the integrated run: exactly the 19 declared files.
- `existing-pins-unmodified` GREEN at base (trivially — nothing
  changed); non-vacuous on the integrated tree.

**AC1 (suite + frozen pins + changelog).** `bundle exec rspec` from the
repo root exits 0 with 0 failures over the FULL suite — the 11
pre-existing spec files byte-UNMODIFIED from `4736ddc` (the frozen
regression net: chat_spec's serial-order/unknown-tool/hooks pins and
stream_cancel's D8 self-cancel pin `ran == ["a"]` all pass UNMODIFIED
under the concurrent executor) plus the three NEW spec files green.
`CHANGELOG.md` 0.1.0 no longer claims serial tool execution and
describes the concurrent batch. Pinned by `gem-suite` +
`existing-pins-unmodified` + `changelog-concurrency`.

**AC2 (wire parity EXACT — untouched).** The 11 wire fixtures' bytes
and SHA256s are untouched (the frozen pi capture table), and the
wire-parity spec passes: every canonical request body byte-identical.
Concurrency moved WHO runs tools, never a request/response byte (the
call-order append is the proof mechanism; Specification §1.1/Grounds
D7). Pinned by `wire-fixtures-digests` + `wire-parity`.

**AC3 (overlap + call order + failure isolation).**
`tool_concurrency_spec.rb` green: two sleep-tools in one batch
OVERLAP (windows intersect; span < 0.9 s vs serial ≈ 1.0 s — the I50
bound), tool-result Messages append in CALL order under inverted
completion (c2 finishes first), before hooks fire in call order, after
hooks fire in completion order (per-child, id-keyed), and one tool's
raised `StandardError` isolates into its own `is_error` result while
the sibling completes and both land in call order. Pinned by
`tool-overlap`.

**AC4 (cancel during the batch).** `batch_cancel_spec.rb` green: a
sibling cancel ~0.1 s into a two-call 0.5 s batch aborts BOTH in-flight
children (both provably entered), `CancelledError` surfaces ≤ 0.2 s
after the cancel (natural completion ≈ 0.4 s away — the I52 bound),
ZERO tool-result Messages, ZERO after-hook fires, no `:error`/`:done`
after the cancel (no phantom terminals); a cancel latched by a before
hook stops the batch at the next phase checkpoint with NO tool
executing. Pinned by `batch-cancel`.

**AC5 (builds + installs + smokes through the new executor).**
`script/install_check.sh` passes strict: the .gem builds (with lib/),
installs into a scratch GEM_HOME, requires outside the repo, and the
smoke chat turn — a full tool batch through the Chat — completes.
Prints `INSTALL_CHECK_OK`. Pinned by `install-check`.

**AC6 (docs: links land, quadrants, owner prose preserved).**
`docs_links_spec.rb` green: every reference/inline link in the scoped
markdown resolves (the four owner links land at their ruled
destinations — tools.md, dialects.md ×2, the async-http GitHub URL);
each diataxis quadrant non-empty; the README line-diff vs the
byte-frozen `4736ddc` fixture copy shows ONLY added link definitions +
the one moved Error-taxonomy section (pointer ≤ 6 lines linking
errors.md). The fixture itself is byte-identical to
`git show 4736ddc:gems/completions/README.md`. Pinned by `docs-links`
+ `readme-fixture`.

**AC7 (scope).** The integrated diff vs base `4736ddc` touches EXACTLY
the two lanes' declared 19-file union — nothing else in fast-llm
(gemspec, Gemfile, Gemfile.lock, .rspec, version.rb, install_check.sh,
mock server, every pre-existing spec/fixture all untouched), nothing
in any other repo; builders made no commits. Pinned by `scope`.

```gates
- id: gem-suite
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle install --quiet
    out=$(bundle exec rspec 2>&1); ec=$?
    printf "%s\n" "$out" | tail -3
    exit $ec
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: existing-pins-unmodified
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    viol=""
    for f in $(git ls-tree -r --name-only 4736ddc -- gems/completions/spec/); do
      if ! git diff --quiet 4736ddc -- "$f"; then viol="$viol $f"; fi
    done
    if [ -n "$viol" ]; then echo "MODIFIED PRE-EXISTING SPEC FILES:$viol"; exit 1; fi
    echo EXISTING_PINS_UNMODIFIED_OK
  expect:
    exit_code: 0
    stdout_match: EXISTING_PINS_UNMODIFIED_OK

- id: changelog-concurrency
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    if grep -qF "execute tool calls serially" gems/completions/CHANGELOG.md; then
      echo "STALE SERIAL CLAIM in CHANGELOG"; exit 1
    fi
    grep -qi "concurrent" gems/completions/CHANGELOG.md || { echo "CHANGELOG lacks the concurrent-batch description"; exit 1; }
    echo CHANGELOG_CONCURRENCY_OK
  expect:
    exit_code: 0
    stdout_match: CHANGELOG_CONCURRENCY_OK

- id: wire-fixtures-digests
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    ruby -rjson -rdigest -e '
      # The digest table is DERIVED from the authoritative frozen table in
      # wire_parity_spec.rb (itself pinned byte-unmodified by the
      # existing-pins-unmodified gate) - zero hand-transcription.
      src = File.read("gems/completions/spec/fast/completions/wire_parity_spec.rb")
      table = src[/FROZEN_DIGESTS\s*=\s*\{(.*?)\}/m, 1].scan(/"([a-z_]+)"\s*=>\s*"([0-9a-f]{64})"/).to_h
      abort "could not parse FROZEN_DIGESTS" unless table.size == 11
      table.each do |tag, want|
        path = "gems/completions/spec/fixtures/wire/#{tag}.json"
        abort "missing fixture #{tag}" unless File.file?(path)
        body = JSON.parse(File.read(path))["request_body"]
        got = Digest::SHA256.hexdigest(body)
        abort "fixture digest drift #{tag}: #{got} != #{want}" unless got == want
      end
      puts "WIRE_FIXTURES_OK #{table.size}"
    '
  expect:
    exit_code: 0
    stdout_match: WIRE_FIXTURES_OK

- id: wire-parity
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    out=$(bundle exec rspec gems/completions/spec/fast/completions/wire_parity_spec.rb 2>&1); ec=$?
    printf "%s\n" "$out" | tail -3
    exit $ec
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: tool-overlap
  ac: AC3
  cwd: repos/fast-llm
  cmd: |-
    out=$(bundle exec rspec gems/completions/spec/fast/completions/tool_concurrency_spec.rb 2>&1); ec=$?
    printf "%s\n" "$out" | tail -3
    exit $ec
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: batch-cancel
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    out=$(bundle exec rspec gems/completions/spec/fast/completions/batch_cancel_spec.rb 2>&1); ec=$?
    printf "%s\n" "$out" | tail -3
    exit $ec
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: install-check
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    if [ ! -f gems/completions/script/install_check.sh ]; then echo "install_check.sh missing"; exit 1; fi
    bash gems/completions/script/install_check.sh
  expect:
    exit_code: 0
    stdout_match: INSTALL_CHECK_OK

- id: docs-links
  ac: AC6
  cwd: repos/fast-llm
  cmd: |-
    out=$(bundle exec rspec gems/completions/spec/fast/completions/docs_links_spec.rb 2>&1); ec=$?
    printf "%s\n" "$out" | tail -3
    exit $ec
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: readme-fixture
  ac: AC6
  cwd: repos/fast-llm
  cmd: |-
    git show 4736ddc:gems/completions/README.md | diff -q - gems/completions/spec/fixtures/readme/owner-4736ddc.md \
      || { echo "FIXTURE IS NOT THE 4736ddc README"; exit 1; }
    echo README_FIXTURE_OK
  expect:
    exit_code: 0
    stdout_match: README_FIXTURE_OK

- id: scope
  ac: AC7
  cwd: repos/fast-llm
  cmd: |-
    ruby -e '
      expected = %w[
        README.md
        gems/completions/CHANGELOG.md
        gems/completions/README.md
        gems/completions/docs/explanation/fiber-native-design.md
        gems/completions/docs/explanation/why-dialects-as-data.md
        gems/completions/docs/explanation/why-streaming-only.md
        gems/completions/docs/how-to/add-a-tool.md
        gems/completions/docs/how-to/cancel-a-running-chat.md
        gems/completions/docs/how-to/declare-a-custom-dialect.md
        gems/completions/docs/reference/dialects.md
        gems/completions/docs/reference/errors.md
        gems/completions/docs/reference/stream-events.md
        gems/completions/docs/reference/tools.md
        gems/completions/docs/tutorials/first-run.md
        gems/completions/lib/fast/completions/chat.rb
        gems/completions/spec/fast/completions/batch_cancel_spec.rb
        gems/completions/spec/fast/completions/docs_links_spec.rb
        gems/completions/spec/fast/completions/tool_concurrency_spec.rb
        gems/completions/spec/fixtures/readme/owner-4736ddc.md
      ].sort
      actual = `git diff --name-only 4736ddc..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      abort "OUT OF SCOPE: #{extra.inspect}" unless extra.empty?
      abort "DECLARED BUT ABSENT: #{missing.inspect}" unless missing.empty?
      abort "VACUOUS: empty diff" if actual.empty?
      puts "SCOPE_OK #{actual.size} files"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## May touch (EXACTLY these 19; the ```lanes``` block is the frozen truth)

- `concurrency` (4): `gems/completions/lib/fast/completions/chat.rb`,
  `gems/completions/CHANGELOG.md`,
  `gems/completions/spec/fast/completions/tool_concurrency_spec.rb` (new),
  `gems/completions/spec/fast/completions/batch_cancel_spec.rb` (new).
- `docs` (15): `README.md` (root), `gems/completions/README.md`, the
  11 new `gems/completions/docs/**` pages (Specification §2.1 exact
  paths),
  `gems/completions/spec/fixtures/readme/owner-4736ddc.md` (new),
  `gems/completions/spec/fast/completions/docs_links_spec.rb` (new).

## Builder Prompt

# Builder Prompt — I53 gem-concurrency-docs

> Two lanes, repo fast-llm, disjoint by construction (4 + 15 files),
> INDEPENDENT — may dispatch concurrently; integrate in lane order
> (`concurrency`, then `docs`; no dependency either way). Each prompt
> below was assembled from its scratch file — lane `concurrency`:
> `build/i53-concurrency/prompt.md`; lane `docs`:
> `build/i53-docs/prompt.md` (verbatim copies; the coordinator copies
> each to `build/I53-gem-concurrency-docs-<lane>/prompt.md` at
> dispatch). Per the I26 binding carry-in each prompt opens with its
> lane name + its own touch/must-not lists and embeds ONLY its lane's
> spec section. Full frozen-region scratch copies (Grounds +
> Specification, identical bytes) sit beside each prompt at
> `build/i53-<lane>/spec.md`.

---

# Lane prompt — I53 gem-concurrency-docs, lane `concurrency`

You are lane `concurrency` of iteration I53 (gem-concurrency-docs),
freeze `e7202316`, repo **fast-llm** (your worktree; branch
`lane/i53-concurrency`, cut from `main` @ `4736ddc`). The frozen
iteration file is `architecture/I53-gem-concurrency-docs.md` in the
space — Grounds, Specification, Acceptance Criteria are read-only
truth; § cites below are that file's. A space scratch copy of the full
spec sits at `build/i53-concurrency/spec.md` (identical bytes to the
frozen sections you need: Specification §0–§1 + §3–§4 + Grounds §3–§5,
§7 D1–D7 — the sibling docs lane's §2 is NOT yours).

## Mission

Reopen I51's frozen D9: the gem's standalone Chat executes a tool
batch CONCURRENTLY (pi's `executeToolCallsParallel` shape, tart's I52
fiber mechanics) — WIRE-NEUTRAL (no request/response byte may move),
with the cancel discipline (I51 D8) extended to the batch. Two new
spec files pin it; one CHANGELOG bullet gets corrected.

## Your touch set (EXACTLY these 4 — anything else is out of scope)

1. `gems/completions/lib/fast/completions/chat.rb` (the ONLY lib file
   you may edit)
2. `gems/completions/CHANGELOG.md` (one bullet — Specification §1.4)
3. `gems/completions/spec/fast/completions/tool_concurrency_spec.rb` (NEW)
4. `gems/completions/spec/fast/completions/batch_cancel_spec.rb` (NEW)

MUST NOT touch: every pre-existing spec file + `spec/fixtures/**` +
`spec/support/mock_llm_server.rb` + `spec/spec_helper.rb` (the frozen
regression net — they must pass UNMODIFIED); every other lib file; the
gemspec, `Gemfile`, `Gemfile.lock`, `.rspec`, `version.rb`,
`script/install_check.sh` (packaging/deps frozen); any docs/ file or
README (sibling lane `docs` owns those); every other repo; no git
push/commit (the coordinator integrates).

## The contract (frozen Specification §1, condensed — § cites are the file's)

### §1.1 `run_tool_batch` becomes two-phase (chat.rb:132-150 today)

**Phase A — serial before-phase**, per tool_call block IN CALL ORDER,
on the calling fiber (pi agent-loop.ts:593-643):
1. Latch check (`@cancelled` ⇒ raise `CancelledError`) +
   `Cancellation.check` (today's :138/:141 per-iteration discipline).
2. Before hooks in registration order (unchanged contract).
3. Executability resolution: unknown tool ⇒ IMMEDIATE outcome — the
   exact today-bytes `{content: "no such tool: <name>", is_error: true}`
   — recorded inline in call order, NO child task. (Hooks fire for
   unknown tools too — gem continuity over pi's look-up-first,
   Grounds D2/D3.)
4. Executable calls collect as ordered specs.

**Phase B — concurrent execution**: one `Async::Task.current.async`
child per executable call (children of the STEP task — Sync-inline
reactor discipline; tart I52 D2 precedent). Each child, in body order:
1. Opening checkpoint: latch check + `Cancellation.check` (the frozen
   stream_cancel D8 pin `ran == ["a"]` depends on exactly this).
2. `execute` with the §11 outcome mapping (String verbatim / Hash ⇒
   JSON.generate / `{error:}` ⇒ error result — unchanged bytes).
3. Failure isolation: rescue ladder —
   `Fast::Completions::CancelledError` ⇒ re-raise (never a result);
   `Async::Cancel` ⇒ passes through (`< Exception`, NOT caught by
   StandardError — async 2.46.0 verified); other `StandardError` ⇒
   that call's result `{content: e.message.to_s, is_error: true}`
   (siblings unaffected, the join completes — pi
   executePreparedToolCall :824-837).
4. After hooks fire INSIDE the child as the call completes, keyed by
   tool_call id (hook exceptions still propagate — today's contract).
5. Message.tool_result collected INDEX-KEYED (call position), never
   completion-keyed.

**Join**: wait all children; a cancel during the join aborts in-flight
children, re-raises IMMEDIATELY (never waits out natural completion —
the I50 ARM-A class); `#step`'s existing ladder (:120-124) surfaces
`CancelledError`; NO phantom terminals (zero tool-result Messages, no
after hooks for aborted calls).

**After the join**: append tool-result Messages IN CALL ORDER. History
bytes identical to the serial executor's for every batch (Grounds D7).

Unchanged/frozen surface: `#step`'s stream path, assistant-append
ordering, `complete?`/`@tool_batch_pending` state machine,
`cancel`/`@in_flight` mechanics, hook registration-order contract,
`execute_tool_call`'s outcome bytes, `add_message`, the public method
set. NO concurrency knob (Grounds D6). Update the "SERIALLY (D9)"
comments to the new shape.

### §1.2 NEW `tool_concurrency_spec.rb` (mock-driven; chat_spec idioms)

1. **Overlap + span** [designed red at base]: two 0.5 s sleep-tools in
   ONE batch (Kernel#sleep in execute — scheduler-interruptible);
   tools record monotonic entry/exit stamps. Assert `max(entries) <
   min(exits)` AND wall span < 0.9 s AND both results land.
2. **Call-order under inverted completion** [red at base]: c1 sleeps
   0.5 s, c2 sleeps 0.2 s. Assert messages in call order `[c1, c2]`;
   after-hook fire order == completion order `[c2, c1]`; before-hook
   order == call order.
3. **Failure isolation** [red at base]: c1's execute raises
   StandardError("boom"), c2 sleeps 0.2 s clean. Assert step completes;
   c1 result `is_error: true`, content exactly `"boom"`; c2 clean; both
   in call order.
4. **Unknown tool inline in a multi-call batch** [guard]: batch
   [known c1, unknown "nope" c2] ⇒ results in call order; c2 content
   exactly `"no such tool: nope"`, is_error true; c1's hooks fired.

### §1.3 NEW `batch_cancel_spec.rb`

1. **Cancel during the join** [red at base via the entered-set]: two
   0.5 s sleep-tools; a sibling task (same reactor) waits for the
   FIRST entry signal (Queue handshake), settles ~0.05 s, then
   `chat.cancel`. Assert BOTH entered; wall cancel→CancelledError
   ≤ 0.2 s; step raised CancelledError; ZERO tool-result Messages;
   ZERO after-hook fires; no `:error`/`:done` event after the cancel.
2. **Hook-latched cancel stops the batch at the next phase checkpoint**
   [red at base]: two-call batch; c1's before hook calls `chat.cancel`.
   Assert CancelledError; NO tool executed (`ran == []`); c2's before
   hooks never fired; no tool-result Messages. Deterministic.

### §1.4 CHANGELOG

0.1.0's Chat bullet ("execute tool calls serially …") → rewrite to the
concurrent contract. No version bump, no new section.

## Verification (in your worktree — run cold, keep the outputs)

```
cd repos/fast-llm
bundle install --quiet && bundle exec rspec                      # 0 failures — the WHOLE suite incl. the unmodified frozen specs
bundle exec rspec gems/completions/spec/fast/completions/wire_parity_spec.rb   # green, untouched
bash gems/completions/script/install_check.sh                    # INSTALL_CHECK_OK — the smoke tool turn runs your executor
git diff --stat 4736ddc                                           # exactly your 4 files
```

## Standing rules

Builders zai/glm-5.3-flash; NEVER commit or push (the coordinator
integrates); no GitHub/rubygems actions; no mid-run contact_supervisor
— if blocked, write `build/I53-gem-concurrency-docs-concurrency/
blocked.md` with the raw facts and stop. Report to
`build/I53-gem-concurrency-docs-concurrency/report.md`: what you built,
the verification outputs verbatim (suite tail, INSTALL_CHECK_OK, diff
--stat), every deviation from this prompt's letter with a one-line
reason, and any concerns. The gem's mock server
(`spec/support/mock_llm_server.rb`) is your test instrument — read it
(script vocabulary: `:stream` + `tool_calls`, `rearm!`,
`captured_requests`) but never edit it.

---

# Lane prompt — I53 gem-concurrency-docs, lane `docs`

You are lane `docs` of iteration I53 (gem-concurrency-docs), freeze
`e7202316`, repo **fast-llm** (your worktree; branch
`lane/i53-docs`, cut from `main` @ `4736ddc`). The frozen iteration
file is `architecture/I53-gem-concurrency-docs.md` in the space —
Grounds, Specification, Acceptance Criteria are read-only truth; §
cites below are that file's. A space scratch copy of the full spec
sits at `build/i53-docs/spec.md` (identical bytes to the frozen
sections you need: Specification §0 + §2–§4 + Grounds §6–§7 D8–D10 —
the sibling concurrency lane's §1 implementation detail is summarized
for you in §2.1's tools.md row; you document the SPEC's frozen batch
contract, not the sibling's working tree).

## Mission

The diataxis docs pass + the owner's four dangling README links. THE
OWNER'S README PROSE IS BYTE-FROZEN (owner ruling 2026-10-14, commit
`4736ddc`): you fix/define links and move the one section the plan
names, and touch NO other prose — mechanically pinned by
`docs_links_spec.rb` (your deliverable) against a byte-frozen fixture
copy of the 4736ddc README (also your deliverable).

## Your touch set (EXACTLY these 15 — anything else is out of scope)

1. `README.md` (monorepo root — house-authored, minimal docs-tree link)
2. `gems/completions/README.md` (owner prose — the §2.2 surgery ONLY)
3.–13. the 11 NEW pages under `gems/completions/docs/` (exact paths in
   the table below)
14. `gems/completions/spec/fixtures/readme/owner-4736ddc.md` (NEW — a
    byte-verbatim copy of `git show 4736ddc:gems/completions/README.md`)
15. `gems/completions/spec/fast/completions/docs_links_spec.rb` (NEW)

MUST NOT touch: ANY file under `gems/completions/lib/` (a stray lib/
edit fails your scope gate); `gems/completions/CHANGELOG.md` (sibling
lane's); every pre-existing spec file + `spec/fixtures/wire/**` +
`spec/support/**` + `spec/spec_helper.rb`; the gemspec, `Gemfile`,
`Gemfile.lock`, `.rspec`, `script/`; any other repo; no git
push/commit.

## The contract (frozen Specification §2, condensed)

### §2.1 The page list (EXACTLY these 11 paths, all NEW)

One task per page, README the landing page (house pattern: fast-
prometheus 16-page / fast-protowire 11-page four-quadrant trees).

| Page | Required content (seeds — no inventions) |
|---|---|
| `docs/reference/tools.md` | Tool DSL: `description`/`tool_name`/`parameters` (literal + block)/`execute`; wire-name rule; parameters emitted VERBATIM; the §11 outcome contract (String verbatim, Hash ⇒ JSON, `{error:}` ⇒ error result); `with_tools`. THE FIBER-SAFETY CONTRACT: execute runs on a reactor child — never block the reactor; batch semantics per the frozen spec: one reactor task per call, CONCURRENT, results in CALL order, a raising execute isolates to an error result, cancel aborts with `CancelledError` and no results; hooks (registration order, id-keyed; after hooks fire in completion order). Target of `[see the tool docs]`. |
| `docs/reference/dialects.md` | All 13 VOCABULARY keys with defaults + allowed values (dialects.rb:17-31); the shipped `:zai`/`:deepseek`/`:fireworks` declarations verbatim (:150-168); custom declaration (block DSL + kwargs); `Fast::Completions.dialect(:x)` (KeyError), `.dialects`; last-wins; Model resolution; ArgumentError on unknown key/value. Target of `[see the dialect docs]` AND `[Dialect Docs]`. |
| `docs/reference/errors.md` | The README's error-taxonomy table MOVED here (rows verbatim) + expansion: status mapping; TimeoutError (TTFB + inactivity); ConnectionError (ECONN*); StreamError (emits `:error` first); CancelledError NOT under Error and why. |
| `docs/reference/stream-events.md` | The full Event vocabulary with per-type fields: `:start`, `:text_start/:text_delta/:text_end`, `:thinking_*`, `:tool_call_start/:tool_call_delta/:tool_call_end`, client-level `:error`/`:done` (reason); the `#step` block contract. |
| `docs/tutorials/first-run.md` | The README Quickstart grown: client + model + one tool, streamed (the `Async do` shape), `complete?`, the follow-up turn. |
| `docs/how-to/declare-a-custom-dialect.md` | Declare, mount on a Model, last-wins, closed-vocabulary failure. |
| `docs/how-to/cancel-a-running-chat.md` | `chat.cancel` mid-stream vs mid-batch (children abort, `CancelledError`, no phantom terminals, no results), connection discard + reuse, the latch. |
| `docs/how-to/add-a-tool.md` | Subclass, declare, register, outcome contract, fiber-safety link to tools.md. |
| `docs/explanation/why-streaming-only.md` | No synchronous requests: the fiber-native stance + why. |
| `docs/explanation/why-dialects-as-data.md` | The LiteLLM anti-shape: no universal translation, closed vocabulary, fail-loud, no base-URL detection. |
| `docs/explanation/fiber-native-design.md` | Caller's reactor, ONE persistent `Async::HTTP::Client`, requests as reactor tasks, `Async::Cancel` semantics, the batch executor (children of the step task), zero gem-owned threads. |

### §2.2 README surgery (gems/completions/README.md — owner prose BYTE-FROZEN)

1. ADD the four link definitions (house style: a definitions block at
   the end):
   `[see the tool docs]: docs/reference/tools.md` ·
   `[see the dialect docs]: docs/reference/dialects.md` ·
   `[Dialect Docs]: docs/reference/dialects.md` ·
   `[socketry/async-http]: https://github.com/socketry/async-http`
2. MOVE the Error-taxonomy section (`## Error taxonomy` + table,
   :109-123) → `docs/reference/errors.md`; replace with a pointer
   block ≤ 6 lines (heading kept + 1–2 sentences + a link resolving to
   `docs/reference/errors.md`).
3. NOTHING ELSE — every other line byte-identical to `4736ddc`.
   "Dialects as data" STAYS; Installation/Quickstart/Dialects/Parity
   pointers unchanged.

### §2.3 Root README + fixture

- Root `README.md`: a minimal edit linking the docs tree (e.g. the
  `gems/completions` bullet gains a docs/ link). No other changes.
- The fixture: byte-verbatim copy of
  `git show 4736ddc:gems/completions/README.md`.

### §2.4 NEW `docs_links_spec.rb` (rides the suite)

Mechanical properties, no network: (1) prose preservation — line-LCS
diff fixture→current README: every removed line ∈ the Error-taxonomy
section (`## Error taxonomy` inclusive … `## Parity` exclusive); every
added line is a link definition (`/\A\[[^\]]+\]:\s*\S/`) or part of
ONE contiguous ≤ 6-line replacement block linking
`docs/reference/errors.md`, located between "Dialects as data" and
`## Parity`; (2) link resolution — every reference definition + inline
link in the scoped markdown (repo `README.md`,
`gems/completions/README.md`, `gems/completions/CHANGELOG.md`,
`gems/completions/docs/**/*.md`; EXCLUDING `spec/fixtures/**`; fenced
code blocks skipped) resolves to an existing file (anchors stripped;
absolute http(s) URLs pass); (3) label closure — every used
`[label]` has a definition in the same file; (4) the four ruled
destinations exactly (tools.md; dialects.md; dialects.md; the
async-http GitHub URL); (5) each quadrant non-empty.

## Verification (in your worktree — run cold, keep the outputs)

```
cd repos/fast-llm
bundle install --quiet && bundle exec rspec    # 0 failures — docs_links_spec green; lib/ untouched so the suite is otherwise base-green
git show 4736ddc:gems/completions/README.md | diff - gems/completions/spec/fixtures/readme/owner-4736ddc.md   # empty
git diff 4736ddc -- gems/completions/README.md  # only link definitions + the one moved section
git diff --stat 4736ddc                          # exactly your 15 files
```

## Standing rules

Builders zai/glm-5.3-flash; NEVER commit or push; no GitHub/rubygems
actions; no mid-run contact_supervisor — if blocked, write
`build/I53-gem-concurrency-docs-docs/blocked.md` with the raw facts and
stop. Report to `build/I53-gem-concurrency-docs-docs/report.md`: the
page list as built, the verification outputs verbatim, every deviation
from this prompt's letter with a one-line reason, and any concerns.
Read the gem's lib sources for accuracy (tool.rb, dialects.rb,
errors.rb, protocol.rb, client.rb, chat.rb) — cite what the code does
today; the batch-concurrency CONTRACT you document is the frozen
spec's (§2.1 tools.md row), which the sibling lane is implementing in
parallel.

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
