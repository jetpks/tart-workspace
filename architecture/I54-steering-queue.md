# I54: steering-queue

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I54 steering-queue

## 0. Control (this session)

- Space base: the I54 scaffold (`architect new steering-queue` →
  `architecture/I54-steering-queue.md`); I53 gem-concurrency-docs is CLOSED
  with its verdict (d5cadd7) — the space metadata rule held.
- This iteration: **ENTRY A (first) of the live-run fixes rev3 program**
  (`notes/plan-20261014T031751Z.md` — read in full this session; the
  standing-rules preamble governs: serial entries, checkpoint files for the
  human, builders never commit, every entry's gates include the full
  no-regression battery cold, and NO entry may move a wire byte of the
  EXISTING scenarios — new behaviors get NEW scenarios/goldens).
- repos/tart at `project/pi-port` `1a8ea775` (I52's integrated tip; I53
  touched only fast-llm) — the frozen base. CLEAN worktree.
- repos/fast-llm at `main` `33571e1` (I53's tip) — READ-ONLY, untouched by
  this entry.
- repos/pi at `main` `f1b2e77f` — oracle, read-only.
- PHASE −1 (plan-vs-tree verification, this session): every file:line cite
  in the entry was re-verified against the final integrated tree. Cite
  drift table (re-located, not defects): the entry's `chat.rb:961-963` →
  actual `lib/tart/render/chat.rb:961-962`; `:973-975` → `:971-972`;
  pi `agent-session.ts:1927-1934` (_tryExecuteExtensionCommand-before-
  queueing) → actual `prompt()` at `:1968-2024` with the command check at
  `:1975-1985` and the def at `:2116`; `:1947-1959` (expansion before
  queue) → `:2005-2010` + the streaming queue branch `:2012-2024`;
  `:2203-2208` (the steering-delivery doc) → `:2203-2209` ✓; `:1123-1126`
  (UI mirror removal) → `:1122-1134` ✓; `interactive-mode.ts:4486+`
  (handleFollowUp) → `:4475-4505`; `:4763+` (handleDequeue) → `:4507-4514`
  (`:4763` is actually `queueCompactionMessage`); `:3371-3381` (compaction
  queue) → `:3367-3378`; `:4708-4721` (clearAllQueues) → `:4707-4721` ✓;
  `:4725-4739` (pendingMessagesContainer) → `:4724-4740` ✓;
  `:1044-1045` (help hints) → exact ✓. No premise invalidated: the named
  files exist, the `!busy?` gates are live at the cited shapes, pi's
  architecture matches the entry's description.

## 1. The owner findings this closes (problems.md, committed 9d8bb8c)

- Item 4: "`/thinking` doesn't work while answer is streaming, but should
  -- OH NO it queued as a user message and sent to the model"
- Item 5: "queued messages in pi are shown above the editor box with a
  little help text that tells you how to edit queued messages -- tart
  seems to be missing that."
- Item 7: "queued message didn't fire until the assistant round ended
  completely -- i'm pretty sure we can slip those in around tool calls,
  at least, pi appears to do that. we might need to check traces."

## 2. pi's architecture (re-verified this session at f1b2e77f)

Submit path (`packages/coding-agent/src/modes/interactive/interactive-mode.ts`):

- The builtin command if-chain (`:3200-3365`: /settings … /compact) runs
  BEFORE the isCompacting (`:3367`) and isStreaming (`:3380-3389`)
  branches — **builtins dispatch regardless of streaming**.
- Compaction branch (`:3367-3378`): extension commands execute
  immediately; other text `queueCompactionMessage(text, "steer")`.
- Streaming branch (`:3380-3389`): `session.prompt(text,
  {streamingBehavior: "steer"})` then `updatePendingMessagesDisplay()`.

`AgentSession.prompt` (`packages/coding-agent/src/core/agent-session.ts:1968-2024`):

- `_tryExecuteExtensionCommand` runs FIRST, "even during streaming"
  (`:1975-1985`, def `:2116-2145`); skill + prompt-template expansion
  happens BEFORE queueing (`:2005-2010`); the streaming branch queues via
  `_queueSteer`/`_queueFollowUp` (`:2012-2024`) which push the UI mirror
  + `agent.steer(...)`/`agent.followUp(...)` (`:2238-2263`).
- `steer()`: "Delivered after the current assistant turn finishes
  executing its tool calls, before the next LLM call" (`:2203-2209`).
- `followUp()`: "Delivered only when agent has no more tool calls or
  steering messages" (`:2227-2232`).
- UI mirror removal on delivery (`:1122-1134`): on `message_start` of a
  user message, its text is spliced out of `_steeringMessages` (first
  index) else `_followUpMessages`, then `_emitQueueUpdate()`.
- `clearQueue()` (`:2402-2410`): copies + clears BOTH mirror arrays and
  calls `agent.clearAllQueues()`.
- Compaction submit throws in `prompt()` (`:1987-1993`: "Cannot submit a
  prompt while compaction is in progress") — the interactive surface
  never hits it (the :3367 branch queues at the surface instead).
- Manual compact aborts first: `compact()` `:2764-2765` `await
  this.abort()` — "Manual compaction never retries or continues the
  interrupted agent turn."
- `/new` on a live run also aborts first: the runtime's `newSession` →
  `teardownCurrent` → `await this.session.abort()`
  (`agent-session-runtime.ts:167-178`, comment: "Settle any active
  response first so the aborted turn … is persisted").

**The trace verification (the entry's spec-time mandate) — pi's drain
sites, read from `packages/agent/src/agent-loop.ts` `runLoop` this
session** (the plan sanctioned reading the drain sites in lieu of a live
trace):

- `:176` — initial steering poll at loop start ("user may have typed
  while waiting").
- `:183` — inner loop condition `while (hasMoreToolCalls ||
  pendingMessages.length > 0)` — the SAME run: `agent_end` is not
  emitted until `:307`/`:311`.
- `:212-220` — pending messages are emitted (`message_start`/`message_end`)
  and pushed into `currentContext.messages` BEFORE the request.
- `:242` — `streamAssistantResponse` (the LLM call).
- `:262-274` — the tool batch executes (`executeToolCalls`), results
  pushed.
- `:284-287` — `finishTurn`, then `turn_end` is emitted.
- **`:295-299` — THE steering delivery point: `pendingMessages = (await
  config.getSteeringMessages?.()) || []` AFTER the tool batch + turn_end,
  and the inner loop iterates again — the drained steering is processed
  at `:212-220` and rides `:242`'s NEXT request of the SAME run.**
- `:201-205` — a second poll after `prepareNextTurn` (long-running
  preparation, e.g. compaction): "Pick up steering queued while it ran.
  Only poll again if the earlier poll returned nothing; otherwise
  one-at-a-time mode would deliver two messages in this turn."
- `:302-308` — the follow-up outer poll: "Agent would stop here. Check
  for follow-up messages" — follow-ups start a NEW outer iteration.
- Queue plumbing (`packages/agent/src/agent.ts`): two
  `PendingMessageQueue`s (`:191-192`), default mode "one-at-a-time"
  (`:247-248`, settings `steeringMode`/`followUpMode`,
  settings-defaults.ts:6-7), `steer`/`followUp` (`:299-306`),
  `clearAllQueues`, and `getSteeringMessages`/`getFollowUpMessages`
  wired into the loop config (`:496-506`).

Display (`interactive-mode.ts`):

- `updatePendingMessagesDisplay` (`:4724-4740`): when either queue is
  non-empty — a `Spacer(1)`, then a dim `TruncatedText` per steering row
  `Steering: <text>` and per follow-up row `Follow-up: <text>`, then the
  dim hint `↳ ${keyDisplayText("app.message.dequeue")} to edit all queued
  messages`. `TruncatedText(text, 1, 0)` = one line only, clipped,
  paddingX 1 each side (truncated-text.ts:7-40). The hint renders
  `↳ Alt+Up to edit all queued messages` (keybindings.ts:71-74:
  `app.message.dequeue` default `alt+up`; `keyDisplayText` capitalizes,
  keybinding-hints.ts:38-55 — darwin's "Option+" spelling cut: the port
  targets Linux).
- The container sits between the transcript and the editor
  (`createChatViewport` `:969-976`: document → pendingMessages → status →
  widgetsAbove → editor …).
- Keybinds: `app.message.followUp` = `alt+enter` (keybindings.ts:67-70),
  `app.message.dequeue` = `alt+up` (:71-74); registered `:3116-3117`.
- `handleFollowUp` (`:4475-4505`): alt+enter — while compacting, queue as
  compaction-followUp; while streaming, `prompt(text,
  {streamingBehavior: "followUp"})`; **idle alt+enter behaves like
  regular Enter** (falls through to onSubmit).
- `handleDequeue` (`:4507-4514`): `restoreQueuedMessagesToEditor()` —
  WITHOUT abort; status "Restored N queued message(s) to editor" /
  "No queued messages to restore".
- `restoreQueuedMessagesToEditor` (`:4743-4761`): `clearAllQueues()`,
  join steering-then-followUp with `\n\n`, join with the current editor
  text with `\n\n` (empty texts filtered), `editor.setText(combined)`.
- `queueCompactionMessage` (`:4763-4772`): pushes to the surface's
  compaction queue, adds to editor history, clears the editor,
  `showStatus("Queued message for after compaction")`.
- `getAllQueuedMessages`/`clearAllQueues` (`:4691-4721`) merge the
  session queues with the compaction queue.
- `flushCompactionQueue` (`:4781+`, fired at compaction_end `:3733`,
  session-start `:2018`, `:5671`): re-sends the compaction-queued texts
  through steer/followUp (or as a fresh prompt when the run ended).
- The user message renders in the transcript at DELIVERY
  (`message_start` role user → `addMessageToChat` + 
  `updatePendingMessagesDisplay`, `:3503-3507`) — NOT at submit.
- Startup-help hint rows exist at `:1044-1045` (`to queue follow-up` / `to
  edit all queued messages`) — see D7 (frozen out).
- `/hotkeys` table rows: `Alt+Enter | Queue follow-up message`,
  `Alt+Up | Restore queued messages` (`:6893-6894`).

## 3. The port today (verified at 1a8ea775)

- `lib/tart/render/chat.rb#submit` (`:949-977`): the `!busy?` gates at
  `:961-962` — `return if !busy? && gate_thinking_level(text)` /
  `return if !busy? && @commands.dispatch(text)` — make EVERY slash
  command fall through to `@agent.push_message(text)` while streaming
  (`:971-972`) — the owner's finding 4, verified. The submit-time user
  echo `@transcript_state.enqueue_user_submission(text)` (`:970`) runs
  before the busy branch (the echo renders at submit, not delivery).
- `lib/tart/agent/loop.rb`: ONE queue `@steering_queue = Queue.new`
  (`:135`); `push_message` (`:162-165`); `queued_messages?`
  (`:168-171`); drains ONLY at (a) the outer-loop no-prompt opening
  (`:375-380`), (b) the inner loop's `complete?` arm — after the final
  tool-less answer (`:419-427`), (c) the outer `break if
  steering_messages.empty?` (`:386`) — i.e. at ROUND boundaries, exactly
  finding 7. The I03-locked recorded deviation stands: pre-run queued
  messages WITH a prompt ride the SECOND request
  (`test_queued_message_continues_the_outer_loop`, two requests —
  agent_loop_test.rb:560-573).
- The I48 file inbox folds into the same queue (`drain_steer_inbox`
  `:653-682`, drained at every consumption point); `#wake` (`:180-210`)
  no-ops while `running?`.
- The wind-down continuation (`chat.rb:547-552`): at `agent_end`, if
  messages sit queued with no run in flight, `@kernel.async {
  @agent.run }` continues the run.
- Compaction runs INLINE mid-run on the turn fiber (`run_compaction`
  `:488-547`, threshold arm at `:414-418`); the surface tracks
  `@compaction_reason` from `:compaction_start`/`:compaction` events.
- The escape interrupt path exists: `@kernel.interrupt_work!` while busy
  (`chat.rb:816`, the Task#stop mechanism, core/loop.rb:199-212).
- `lib/tart/render/editor.rb` has NO `set_text` (pi `setText`
  editor.ts:1115-1126: cancel autocomplete, exit history, normalize, undo
  snapshot when content differs, cursor at END — setTextInternal
  `:494-496` defaults "end").
- The queue display does not exist (finding 5): `build_widget`
  (`chat.rb:1281-1300`) lays out transcript / dock spacer / editor /
  footer; alt+enter inserts a NEWLINE (`:792`, pinned
  chat_test.rb:4104-4120 "pi's terminal fallback"); alt+up is unbound
  (`:860`).
- Standing battery (the last full cold run at I52, all green): suite
  1044 runs, SEAM_BENCH_OK, s1–s10 + s1-tart-mode (exit-1-by-design arm
  green), both probes, thinking-pins, hermeticity, lock-deps, zai-data,
  threads-budget, wire-delta (instruction `2faaf667…` + tools
  `7360fd1e…` digests + key order EXACT), session-golden (7 digests).
  **s11 is OPEN-red from I47 (three families, needs the human amendment —
  architecture/ARCHITECT.md 2026-10-13 entry): NOT this iteration's
  bar and NOT gated here.**
- pi's `agent_session.ts` `_handlePostAgentRun` continues the run when
  the agent settles with queued messages (`:1898` — `result.continue ||
  this.agent.hasQueuedMessages()`), including follow-ups — the port's
  wind-down arm is its analog.

## 4. Decisions (spec-session rulings, each with its reason)

- **D1 — one lane (`core`).** The loop/surface/rig changes couple through
  the submit→steer seam, the delivery-echo mirror, and the new scenario
  needs both sides landed; chat.rb is single-writer by the plan's
  standing rules. No disjoint file sets provable.
- **D2 — queue split on the Loop, pi's names.** `steer(text)` +
  `follow_up(text)`, `clear_queues`, thread-safe snapshot readbacks
  (`steering_texts`/`follow_up_texts`); `push_message` remains as the
  documented steer alias (9 existing test call sites unchanged — the
  alias is the compat seam, I44's frozen-pin-compat precedent);
  `queued_messages?` covers both queues (the wind-down arm's semantics
  unchanged, now also covering follow-ups per pi's hasQueuedMessages).
- **D3 — the drain points map 1:1 to pi's.** Tool-batch arm (NEW, after
  the step returns the tool results — post-batch, pre-next-request, the
  `:295` poll + `:212-220` processing), complete? arm (existing — pi's
  same poll after the final tool-less turn), no-prompt opening (steering
  first, else follow-up — pi's `continue()` precedence, agent.ts
  `:392-405`), outer break checks both queues. The I03-locked pre-run
  deviation is NOT reopened.
- **D4 — commands dispatch busy-or-not; /compact and /new get pi's
  abort-first busy arms.** pi's letter: session.compact aborts
  (`:2764-2765`), newSession aborts (runtime `:167-178`). The port's
  realization: the surface arms `kernel.interrupt_work!`, stores the
  command text, and re-dispatches it through `@commands.dispatch` at
  `agent_end` (idle then) via `kernel.async` — no Handler changes, no
  new bin/tart wiring, the exact idle paths re-run. Everything else
  (/thinking /model /help /skills /settings /resume-picker + hooks-
  registered commands) dispatches immediately, pi's letter.
- **D5 — surface queue mirror, pi's two-level shape.** The surface keeps
  `{steer: [], follow_up: []}` mirror arrays (pi's
  `_steeringMessages`/`_followUpMessages`); the render reads the mirror;
  delivery removes by text match (first index) at `:message_start` user
  role and renders the user echo AT DELIVERY (pi `:1122-1134` +
  `:3503-3507`). The idle submit keeps today's submit-time echo (pi
  renders from message events; the split is observably equivalent for
  idle — the event and the submit land within one frame — and keeps the
  stub-agent chat-test family intact). The compaction-time submit routes
  to the steer queue + the flash `Queued message for after compaction`
  (pi queueCompactionMessage's showStatus) — the port's inline
  compaction makes pi's separate surface compaction queue + flush
  machinery unnecessary: the loop's post-compaction drain
  (steering_messages at the complete? arm, AFTER run_threshold_compaction)
  is exactly pi's "pick up steering queued while preparation ran"
  (`:201-205`).
- **D6 — drain-all, not pi's one-at-a-time QueueMode.** pi's
  steeringMode/followUpMode are SETTINGS (default one-at-a-time) the port
  has not ported; the port's existing outer-boundary drain is drain-all
  and its tests pin multi-message drains. Recorded reduction; reopening
  is settings-scope creep beyond this entry.
- **D7 — the startup-help hint rows (interactive-mode.ts:1044-1045) are
  FROZEN OUT.** Adding rows to the port's expanded startup help moves
  the frozen s9_startup_help settled-screen golden — forbidden by the
  program's no-golden-moves rule. The discoverable hint lives in the
  queue block's `↳ Alt+Up to edit all queued messages` row.
- **D8 — alt+enter flips from newline to followUp** (pi's
  app.message.followUp binding shadows the editor's terminal fallback);
  newline keeps shift+enter/ctrl+j. Idle alt+enter = submit (pi
  :4497-4504). The existing alt+enter-newline pin is re-pinned. README
  keybinding rows updated to pi's /hotkeys letters.
- **D9 — `Editor#set_text` lands** (pi setText :1115-1126 discipline,
  cursor at end, undo snapshot when content differs) for dequeue-restore.
- **D10 — dequeue does NOT abort** (pi handleDequeue passes no abort;
  the abort-restore arm is pi's extension abortHandler — no extension
  seam, cut, itemized).
- **D11 — the rig gains `mid_run_keys`** (after_request: N, keys: [...])
  + a non-draining mock request counter; two NEW scenarios (s12 steer
  mid-tool-round, s13 command-while-streaming). s12's determinism: the
  tool call itself sleeps (bash `sleep 1.5 && echo …`) — keys sent after
  the mock serves request 1 land during the stream or the tool run, both
  before the post-batch drain. s13: `:slow_stream` (0.1 s/char × 40) —
  keys land mid-stream. Old-port discrimination: request COUNT (3 vs 2).
- **D12 — scope floor on memory churn:** the surface's queue state is
  additive; nothing in the frozen net is edited except the two chat_test
  stubs (:1404, :2976 — `push_message` → `steer`), the alt+enter pin
  (:4104-4120), and commands.rb's reduction comment (accuracy only).

## 5. Non-goals

- pi's QueueMode settings (one-at-a-time vs all) — D6.
- The startup-help hint rows — D7 (frozen golden).
- pi's extension abortHandler / restore-with-abort — D10.
- pi's separate surface compaction queue + flushCompactionQueue machinery
  — D5 (the port's inline compaction absorbs it).
- Reopening the I03-locked pre-run-queue deviation; changing
  turn_start/turn_end event semantics (the port's turn = the whole tool
  cascade — standing divergence, untouched).
- Paste markers (ENTRY B's territory — `getExpandedText` == getText here).
- s11 (standing open-red, the human's amendment); any edit to existing
  scenarios, goldens, wire fixtures, or the registry.
- subagents/herdr print paths (no submit surface); repos/fast-llm.

## 6. Open unknowns (judge adjudicates)

- OQ-1: D4's interrupt-then-re-dispatch realization of pi's
  abort-then-act for /compact + /new while busy (pi's host sequencing
  verified; the port's mechanism is the re-dispatch — behavioral
  equivalence argued, not pi-mechanical).
- OQ-2: D6's drain-all reduction (multi-steer deliveries batch at one
  boundary vs pi's one-per-boundary).
- OQ-3: D5's idle-submit echo staying submit-time (pi renders every user
  message from message events; the port splits by path).
- OQ-4: the darwin "Option+Up" hint spelling cut (Linux-only port).

## Specification

# Specification — I54 steering-queue

## Objective

Close the owner's problems.md items 4, 5, 7: the port's mid-flight input
handling gets pi's shape — slash commands dispatch busy-or-not (finding 4),
queued messages render above the editor with the dequeue hint and the
followUp/dequeue keybinds (finding 5), and steering is delivered after each
tool batch, INSIDE the same run, riding the next LLM request (finding 7) —
plus pi's followUp mode and the compaction-time submit disposition. The
queue splits into steer + followUp modes in the agent layer (pi's split);
session recording carries queued messages as user messages at their actual
delivery points.

pi sources (this file's §cites to repos/pi, verified this session):
interactive-mode.ts = I, agent-session.ts = S, agent-loop.ts = L,
agent.ts = A, keybindings.ts = K, editor.ts (pi tui) = E.

## §1 Agent layer — the queue split and the drain points

**lib/tart/agent/loop.rb.**

1.1 Replace the single `@steering_queue` (`Queue`, :135) with TWO queues —
`@steering_queue` and `@follow_up_queue` — each a mutex-guarded Array
(the surface snapshot readbacks need enumeration; `::Queue` cannot
snapshot). One `@queues_mutex` guards both. Public API:

- `steer(text)` — append to the steering queue (pi `Agent.steer` A:299).
- `follow_up(text)` — append to the follow-up queue (pi A:304).
- `push_message(text)` — RETAINED as the documented alias of `steer`
  (comment: the I03-era name; existing callers unchanged).
- `clear_queues` — atomically clears BOTH queues (pi `clearQueue` +
  `agent.clearAllQueues`, S:2402-2410). Returns nothing.
- `steering_texts` / `follow_up_texts` — thread-safe snapshot `Array`s
  (the surface mirror's render source, pi `getSteeringMessages`/
  `getFollowUpMessages` S:2418-2424).
- `queued_messages?` — either queue non-empty (existing method, now both
  queues; the wind-down arm's contract unchanged, now also covering
  follow-ups per pi's `hasQueuedMessages` continue S:1898).

1.2 The I48 file inbox (`drain_steer_inbox`) folds into the STEERING queue
only — unchanged code, unchanged consumption points.

1.3 Drain points — the pi 1:1 map (Grounds §2's trace verification):

- **NEW, the tool-batch arm**: in `inner_loop`'s `message.role == :tool`
  branch, AFTER the terminate-ledger consult (I47 — pi's end-decision
  precedes the poll, L:288-291), drain steering and deliver each message
  through the existing `add_user_message` (emits :message_start/
  :message_end, records the session entry, drains nextTurn — the port's
  existing delivery path). This is pi L:295 (post-turn poll) + L:212-220
  (pending processed before the next request): the steering text rides
  the next `step_on_reactor` request of the SAME run. Comment with the
  cites.
- The `complete?` arm (existing :419-427): unchanged — drains steering
  after the final tool-less answer, continues the inner loop (pi's same
  :295 poll after every turn).
- The no-prompt opening (`run_loop`'s else branch :375-380): drain
  steering; if (and only if) the steering drain was empty, drain
  follow-up — pi `continue()`'s precedence (A:392-405: steering branch
  returns immediately with follow-ups left queued). Never both in one
  opening.
- The outer `break` (:386): `break if steering_messages.empty? &&
  follow_up_messages.empty?` — the port's final-check race-closer,
  covering both queues.
- `#wake`'s emptiness check (:197): unchanged semantics via the both-
  queue `queued_messages?`.

1.4 `steering_messages` (the drain) and a new `follow_up_messages` (same
shape) drain their own queue; both remain private.

1.5 NO change to: `run`/`run_loop` prompt handling (the I03-locked
pre-run deviation stands), `step_on_reactor`, the complete?-arm
threshold-compaction ordering (`run_threshold_compaction` THEN the drain —
pi's "pick up steering queued while it ran", L:201-205), turn_start/
turn_end emission points, `recover_overflow?`, the wake shape.

## §2 Surface submit — commands busy-or-not, steer/followUp queueing

**lib/tart/render/chat.rb `#submit` (:949-977).**

2.1 The `!busy?` gates (:961-962) DROP. New order (pi I:3200-3389 —
builtins before the streaming branch; S:1968-2024 — command check →
expansion → queue):

```
if @commands && text.start_with?("/")
  text = @commands.expand_skill(text)      # expansion BEFORE queue (S:2005-2010) — unchanged position
  return if gate_thinking_level(text)      # busy-or-not
  return if busy_command_arm(text)         # §2.2 — false = fall through
  return if @commands.dispatch(text)       # busy-or-not
end
```

2.2 `busy_command_arm(text)` — private; returns false unless `busy?` AND
the text is the builtin `/compact` (exact or `/compact …` prefix) or
`/new` (exact). Then (pi S:2764-2765 compact aborts first; runtime
:167-178 newSession aborts first — Grounds §2): call
`@kernel.interrupt_work!`, store the command text in
`@pending_after_interrupt`, `@kernel.request_draw`, return true. The
`:agent_end` arm (§2.5) re-dispatches.

2.3 The busy branch of submit (after the `!`-bash intercept, unchanged
position):

- `busy?` → `@agent.steer(text)`; NO `enqueue_user_submission` echo (the
  echo renders at DELIVERY, §3.3); the queue mirror gets the text (§3.2);
  if `@compaction_reason` (compacting), also `flash("Queued message for
  after compaction")` (pi queueCompactionMessage I:4763-4772 — the port
  routes to the steer queue directly; pi's surface compaction queue +
  flush machinery is unnecessary because the port's compaction runs
  inline and the post-compaction drain is §1.3's complete? arm).
- else (idle) → today's shape verbatim: `enqueue_user_submission(text)`
  then `@kernel.async { @agent.run(text) }`.

2.4 **`app.message.followUp` — alt+enter** (K:67-70; registered I:3116):
in `edit_input`'s `"enter"` case, an `alt` modifier NO LONGER inserts a
newline — it is the follow-up submit: `submit_follow_up` (new private):
empty trimmed input → no-op; `busy?` → mirror + `@agent.follow_up(text)`
+ editor/history/undo discipline identical to submit's pre-queue lines +
NO submit echo; compacting → same + the compaction flash; **idle →
behaves exactly like plain Enter** (pi I:4497-4504 — falls through to
`submit`). The shift+enter and ctrl+j newline arms are byte-unchanged.
The autocomplete-apply arm precedence is preserved (enter applies the
selection; the alt arm is checked BEFORE the shift arm — pi's newline
keys are shift+enter/ctrl+j, K's tui table :143).

2.5 **`app.message.dequeue` — alt+up** (K:71-74): new `"up"` alt arm
(plain up/down unchanged). `dequeue_queued_messages` (new private, pi
handleDequeue I:4507-4514 + restoreQueuedMessagesToEditor :4743-4761):
NO abort (D10). `all = [steering…, followUp…]` from the SURFACE mirror;
`@agent.clear_queues`; if `all.empty?` → `flash("No queued messages to
restore")`; else `combined = [all.join("\n\n"), @editor.input].reject {
|t| t.strip.empty? }.join("\n\n")`; `@editor.set_text(combined)`
(§4); `flash("Restored #{n} queued message#{n > 1 ? "s" : ""} to
editor")`; clear the mirror; `@kernel.request_draw`.

2.6 The `:agent_end` arm (existing :526+): after today's interrupted/
error handling, BEFORE the wind-down continuation (:547-552), add the
deferred-arm consumption: if `@pending_after_interrupt` is set, clear it
and `@kernel.async { @commands&.dispatch(<the stored text>) }` (runs
outside the mutex — kernel.async schedules; the re-dispatch hits the
exact idle paths: /compact → dispatch_compact, /new → reset lambda) and
SKIP the wind-down continuation for THIS agent_end (manual compaction
never continues the interrupted turn — S:2762-2763). The wind-down
continuation itself is unchanged (`queued_messages?` now covers both
queues — pi S:1898 continues on either).

## §3 Surface queue display

**lib/tart/render/chat.rb.**

3.1 The mirror: `@queued = {steer: [], follow_up: []}` (guarded by the
existing `@mutex`). Appended by §2.3/§2.4; cleared by §2.5 and
delivery (§3.3).

3.2 Rendering (pi `updatePendingMessagesDisplay` I:4724-4740 +
TruncatedText truncated-text.ts:7-40): a new `pending_rows` source +
`pending_widget` child in `build_widget` between `dock_spacer_widget`
and the editor slot:

```
[transcript, dock_spacer, pending, picker_or_menu || editor, footer]
constraints: [min(transcript_rows), length(spacer), length(pending), length(editor), length(FOOTER)]
```

`transcript_area_rows` (existing :1088-1093) subtracts `pending_rows`
TOO (`[height - editor_area_rows - FOOTER_ROWS - dock_spacer_rows -
pending_rows, 1].max`) — the transcript yields (pi's document-area
shrink), the editor/footer never move (the selection's
`editor_area_top` math is untouched). `pending_rows` = 0 when both
mirror arrays are empty; else `2 + n_steer + n_follow_up`:

- row 0: blank (pi's `Spacer(1)`),
- per steering text: ONE row, dim (`Theme[:dim]`), text
  `Steering: <text>`, first line only (split on "\n"), clipped to the
  viewport width minus 2, one leading space, right-padded to the width,
- per follow-up text: same shape with `Follow-up: <text>`,
- last row: dim `↳ Alt+Up to edit all queued messages` (pi's
  `keyDisplayText("app.message.dequeue")` = "Alt+Up"; the port has no
  keybinding registry — the string is the rendered constant), same
  clip/pad discipline.

3.3 Delivery echo + mirror removal (pi S:1122-1134 + I:3503-3507): in
`on_agent_event`'s `:message_start` case, a `user`-role message whose
text matches the FIRST index of the mirror's `:steer` (else `:follow_up`)
array: remove it from the mirror and `@transcript_state
.enqueue_user_submission(<text>)` — the user echo renders AT DELIVERY
(inside the existing mutex; the arm ends with the redraw the event sink
already triggers). Non-queued user messages (the idle submit's opening
message) skip the arm — the idle path already echoed at submit (D5).
`@kernel.request_draw` after.

## §4 Editor seam

**lib/tart/render/editor.rb** — `set_text(text)` (pi setText E:1115-1126
+ setTextInternal :494-496): cancel the autocomplete context if any
(the port's autocomplete is surface-side; the editor seam clears
`last_action`-equivalent state per the port's existing discipline), exit
history browsing, normalize newlines, push an undo snapshot when the
normalized content differs from the current, replace the content, place
the cursor at the END. No paste-registry interaction (ENTRY B's
territory — the port has none).

## §5 Commands comment accuracy

**lib/tart/commands.rb** — `dispatch_compact`'s comment (:219-222)
updated to record the surface's busy arm (§2.2): pi aborts a running
turn first; the PORT arms interrupt + deferred re-dispatch in
`Render::Chat#busy_command_arm`; the Handler still only compacts an
idle agent. NO behavior change in this file.

## §6 Rig + mock (NEW scenarios only; nothing existing touched)

**test/support/mock_llm_server.rb** — add ONE method:
`request_count` (non-draining: `@request_logs.size`) — the runner's
mid-run poll needs a peek that does not consume `captured_request_logs`.

**gems/tui-split-rig/lib/tui_split_rig/scenario.rb** — new optional
scenario key (validated at load like the existing knobs):

```yaml
mid_run_keys:
  after_request: 1      # positive integer — the trigger
  keys: ["text", "Enter"]  # tmux key tokens, sent verbatim
```

**gems/tui-split-rig/lib/tui_split_rig/runner.rb** — in `run_app`, after
the prompt is sent and BEFORE the reply settle: when
`scenario.mid_run_keys` is set, poll `mock.request_count` every
`POLL_INTERVAL` until `>= after_request` (HARD_CAP-bounded; a dead pane
or a timeout fails the app's `completed`), then `tmux("send-keys", "-t",
session, *keys)` per token, then the existing `settle(session,
"reply")` continues. Default (no key): today's behavior byte-identical.

**gems/tui-split-rig/scenarios/s12_steering_mid_round.yml** (NEW):

```yaml
name: s12_steering_mid_round
prompt: "list the files"
expected_requests: 2
mid_run_keys:
  after_request: 1
  keys: ["wait, sort them by size", "Enter"]
responses:
  - type: stream
    content: ""
    tool_calls:
      - id: call_s12_1
        name: bash
        arguments:
          command: "sleep 1.5 && echo steering-window"
  - type: stream
    content: "Done after steering."
```

The tool's own sleep IS the determinism window (D11): keys sent after
request 1 is served land during the stream or the tool run — both before
the post-batch drain. OLD-port discrimination: the old drain-at-round-end
behavior sends THREE requests (request 2 = plain continuation, round
ends, the steer opens a NEW round) → `completed` fails (3 ≠ 2).

**gems/tui-split-rig/scenarios/s13_command_while_streaming.yml** (NEW):

```yaml
name: s13_command_while_streaming
prompt: "hello"
expected_requests: 2
mid_run_keys:
  after_request: 1
  keys: ["/thinking off", "Enter"]
responses:
  - type: slow_stream
    content: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  - type: stream
    content: "Reply after the command."
```

`:slow_stream` paces 0.1 s/char (mock spec_pause) — the keys land
mid-stream deterministically. `/thinking off` (not `high`): the rig's
mock-1 is `reasoning: false` and BOTH apps' gates offer only `off`
(pi models.ts:1224-1226 returns ["off"]; the port's
`available_thinking_levels` — chat.rb:1730+ — same) — so the command
EXECUTES in both apps (the cure demonstrated) and nothing queues.
OLD-port discrimination: `/thinking off` queued as steer → request 2
carries it as a user message → the round ends → the steer opens request
3 → count fails.

Both scenarios: no registry edits (exit 0 requires actual screen parity
modulo the existing sanctioned classes); baselines captured fresh at
build time as the new goldens.

## §7 Tests (the frozen net + new pins)

Re-pins (test-file edits, each with its reason in the diff):

- chat_test.rb:1404 — the stub's `push_message` → `steer` (the surface's
  collaborator seam renamed).
- chat_test.rb:2976 — same stub shape.
- chat_test.rb:4104-4120 — alt+enter no longer newlines; re-pin: idle
  alt+enter submits (pi I:4497-4504), newline = shift+enter/ctrl+j.

New unit pins (minitest, the existing families):

- **Loop (agent_loop_test.rb):** (a) steering submitted DURING a tool
  round rides the NEXT request of the SAME run — script [tool-call
  stream, final], push a steer between the steps (kernel-task timing per
  the existing mid-run tests — e.g. a slow tool or a chunk callback),
  assert 2 requests, request 2's LAST user message == the steer text, NO
  second `agent_start`; (b) followUp submitted mid-run waits for full
  completion — delivered only after the agent would stop (assert the
  follow-up text rides a request AFTER a complete tool-less answer, same
  run); (c) the session JSONL records the steer as a user message
  BETWEEN the tool result and the final assistant (delivery-point
  recording); (d) `clear_queues` empties both; `steering_texts`/
  `follow_up_texts` snapshot; `push_message` == `steer` alias; (e)
  pre-run push_message + prompt still = 2 requests (the I03-locked
  deviation un-regressed).
- **Chat surface (chat_test.rb):** (f) `/thinking off` while busy: the
  command dispatches (the thinking level changes on the surface+loop)
  and NOTHING queues (a recording agent's `steer` never receives
  "/thinking"); (g) plain text while busy: no submit echo, the queue
  mirror holds it, the rendered frame carries the dim `Steering: <text>`
  row + blank + hint rows (draw + read the widget rows — the
  transcript_lines-style readback or the drawn tree), the transcript
  budget shrinks by the pending rows; (h) alt+enter while busy: the
  `Follow-up:` row renders, `follow_up` (not `steer`) is called; idle
  alt+enter submits; (i) alt+up dequeue: mirror + loop queues cleared,
  editor = queued-then-current joined `\n\n`, the flash text, and the
  empty case's "No queued messages to restore"; (j) delivery: a user-
  role :message_start whose text is queued removes the row and echoes
  via enqueue_user_submission at that point; (k) /compact while busy:
  interrupt_work! fires, the command text is deferred, and at :agent_end
  the deferred dispatch runs the idle compact path (a scripted kernel);
  same for /new; (l) compaction-time submit: `@compaction_reason` set →
  steer + the "Queued message for after compaction" flash.
- **Editor (test/render/editor_test.rb):** (m) set_text replaces
  content, cursor at end, undo snapshot pushed (undo returns the prior
  content), history browsing exited.

## §8 README

The keybindings table row `Shift+Enter or Alt+Enter, Ctrl+J | insert a
newline` becomes `Shift+Enter, Ctrl+J | insert a newline`, plus two new
rows in pi's /hotkeys letters (I:6893-6894): `Alt+Enter | queue a
follow-up message (submits when idle)` and `Alt+Up | restore queued
messages to the editor`.

## Output format

Lane report at `build/I54-steering-queue-core/report.md`: per-AC results
with the exact commands + tail outputs, the two new scenarios' out dirs
(`tmp/parity-s12`, `tmp/parity-s13` — captures + request logs + summary
fresh), the re-pin list with reasons, deviations itemized with pi cites.
No commits (the integrator commits); the lane branch carries the work.

## Tool guidance (verify, do not trust)

- Full battery cold from `repos/tart`: `bundle install --quiet &&
  bundle exec rake`; `bundle exec ruby bench/seam_bench.rb | tail -1`;
  per-scenario `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u
  HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
  gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/<s>.yml --out tmp/<dir>`; the two probes
  (`--gate`).
- s9 in a LANE WORKTREE exits 1 with the KNOWN deep-path staged-path
  artifact (twelve+ precedents: pristine base fails identically at a
  same-depth path; canonical-depth run is the truth) — do not chase it
  in-lane; report it.
- The wire/session digest gates are byte-frozen (I52's standing forms) —
  copy them verbatim, never hand-transcribe digests.

## Boundaries

**May touch (the lane's frozen touch set — nothing else):**

```
lib/tart/agent/loop.rb
lib/tart/render/chat.rb
lib/tart/render/editor.rb
lib/tart/commands.rb            (comment accuracy only, §5)
test/support/mock_llm_server.rb (ONE additive method, §6)
test/agent_loop_test.rb
test/chat_test.rb
test/render/editor_test.rb
gems/tui-split-rig/lib/tui_split_rig/scenario.rb
gems/tui-split-rig/lib/tui_split_rig/runner.rb
gems/tui-split-rig/scenarios/s12_steering_mid_round.yml  (NEW)
gems/tui-split-rig/scenarios/s13_command_while_streaming.yml  (NEW)
README.md                        (keybinding rows only, §8)
```

**Must not touch:** every existing scenario YAML, the registry, the
differ, the probes' code paths, the frozen wire/session digest fixtures
and their tests' assertion bytes, `lib/tart/agent/chat.rb` +
`message.rb` (the gem seam — the steering message rides the existing
`add_message` path), `lib/tart/render/transcript.rb` (enqueue_user_
submission is reused as-is), session/print/subagents/herdr/hooks/mcp/
tools/settings/models, `bin/tart` (no wiring changes needed),
repos/fast-llm, repos/pi. No new Thread.new in lib (threads-budget).
No behavior change to any existing scenario's request stream (old
scenarios never submit mid-run — the request bodies are unchanged by
construction; the digest gates enforce it).

**Out of scope:** Grounds §5's non-goals (QueueMode settings, startup-
help rows, extension abortHandler, the surface compaction queue, the
I03-locked deviation, turn-event semantics, paste markers, s11, ENTRY
B–E surfaces).

## Lane plan

ONE lane — `core`, repo `tart`, the full touch set above. Justification
(D1): chat.rb is single-writer by the plan's standing rules and the
loop/surface/rig work couples at the submit→steer seam, the delivery
mirror, and the new scenarios (which require BOTH §1 and §2–3 landed to
pass); no disjoint file sets are provable.

Effort: high (the loop rework + surface seams + rig extension are one
coupled change; the frozen-net re-pins need care).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/editor.rb
    - lib/tart/commands.rb
    - test/support/mock_llm_server.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
    - test/render/editor_test.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/scenarios/s12_steering_mid_round.yml
    - gems/tui-split-rig/scenarios/s13_command_while_streaming.yml
    - README.md
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
`architect rehearse steering-queue` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze steering-queue` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse steering-queue` — before the freeze, while
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
subsection per lane. A copy is written to build/I54-steering-queue-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section steering-queue prompt --append --lane <lane> --from build/I54-steering-queue-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I54-steering-queue-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence steering-queue --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section steering-queue verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify steering-queue`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
