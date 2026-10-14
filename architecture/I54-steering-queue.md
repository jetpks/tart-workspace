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

# Acceptance Criteria — I54 steering-queue

- **AC1 — Steering delivers INSIDE the tool round (the loop).** A steer
  submitted while a tool batch is executing (or mid-stream) rides the
  NEXT LLM request of the SAME run: no new `agent_start` between the
  batch and the request, the steering text is the request's trailing
  user message, and the session JSONL records it as a user message at
  that delivery point (between the tool result and the next assistant
  message). A follow-up (alt+enter) submitted mid-run is delivered ONLY
  after the agent fully completes (no more tool calls, no pending
  steering) — as a new outer turn of the same session flow. The
  pre-run-queue + prompt behavior (two requests, the I03-locked
  recorded deviation) is un-regressed. Both queue modes are clearable
  (`clear_queues`) and snapshot-readable. [Property floor: the delivery
  POINT and the same-run identity, not implementation shape.]
- **AC2 — Commands dispatch busy-or-not (the submit cure).** While a
  turn streams, `/thinking off` EXECUTES (the session thinking level
  changes) and NOTHING is queued — the next request's user content does
  not contain the command text, and the loop's steer queue is never
  handed it. Expansion (skills/templates) happens before queueing. The
  remaining builtins and registered commands dispatch immediately while
  busy (pi's letter). `/compact` and `/new` while busy take the
  abort-first arm: the in-flight run is interrupted and the command is
  dispatched through the idle path at `agent_end`; nothing is ever sent
  to the model. A text submit during compaction steers (delivered after
  compaction at the next drain point) with pi's "Queued message for
  after compaction" feedback.
- **AC3 — The queue display and the keybinds (the surface).** While
  messages are queued, the frame renders — between the dock spacer and
  the editor — a blank row, one dim `Steering: <text>` row per steering
  message, one dim `Follow-up: <text>` row per follow-up (first line
  only, clipped, one-space padded), and the dim hint `↳ Alt+Up to edit
  all queued messages`; the transcript area yields the rows (min 1),
  the editor and footer do not move. On delivery the row is removed and
  the user echo renders at the delivery point (not at submit). alt+enter
  queues a follow-up while busy and submits while idle (never a
  newline); alt+up clears BOTH the surface mirror and the loop queues,
  restores queued-then-current joined with blank lines into the editor
  (set_text: content replaced, cursor at end, undo snapshot), and
  flashes the restore status (pi's texts). Newline keys remain
  shift+enter/ctrl+j.
- **AC4 — Rig parity pins (new scenarios, both apps).** `s12_steering_
  mid_round` and `s13_command_while_streaming` exit 0 cold: both apps
  complete with exactly 2 requests; s12's request 2 carries the steering
  text as its LAST user message in BOTH apps; s13's request 2 user
  content contains no `/thinking` in EITHER app; the settled screens
  match modulo the existing sanctioned classes (no registry edits). The
  old-port shape (3 requests, round-boundary drain) would fail both
  scenarios' `completed` checks. [Exactness is the deliverable: the
  request-count and trailing-user-message bytes are frozen equality;
  screen parity rides the standing rig bar.]
- **AC5 — The full no-regression battery, cold.** `bundle exec rake`
  green; `SEAM_BENCH_OK`; rig s1–s10 exit 0; s1_tart's designed exit-1
  arm green (`TART_MODE_OK`); both probes `--gate` OK; thinking-pins ≥
  11+8 runs; hermeticity ≥ 8+4 runs; lock-deps `GEM_LOAD_OK`; zai-data
  `ZAI_DATA_OK`; threads-budget clean vs `1a8ea77`; wire-delta EXACT
  (instruction `2faaf667…`, tools `7360fd1e…`, key order/store/max/
  stream_options/messages as frozen at I52); session-golden 7/7 digests
  EXACT.
- **AC6 — Scope and frozen bytes.** The integrated diff vs `1a8ea77` is
  EXACTLY the 13 declared files (no more, none absent, non-vacuous); no
  existing scenario/golden/fixture/registry file is touched; README
  changes are the keybinding rows only.

```gates
- id: steering-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/steering_delivered_inside_the_tool_round|follow_up_delivered_only_after_full_completion|steering_recorded_at_its_delivery_point|clear_queues_empties_both_queues/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL steering pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL steering pins runs=${runs:-0} (want >=4: mid-round delivery, follow-up timing, delivery-point recording, clear_queues)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/queued_message_continues_the_outer_loop/" 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL I03-locked deviation un-regressed ec=$ec2"; exit 1; }
    echo STEERING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: STEERING_UNITS_OK

- id: surface-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/thinking_command_while_busy|queued_messages_render|alt_enter_queues_follow_up|alt_up_restores_queued_messages|compact_while_busy_defers|new_while_busy_defers|compaction_submit_steers/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL surface pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 7 ] || { echo "FAIL surface pins runs=${runs:-0} (want >=7: busy-command cure, queue rows, alt+enter, alt+up, /compact defers, /new defers, compaction steer)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/editor_test.rb -n "/set_text/" 2>&1); ec2=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec2" -eq 0 ] && [ "${runs2:-0}" -ge 1 ] || { echo "FAIL set_text pin ec=$ec2 runs=${runs2:-0}"; exit 1; }
    echo SURFACE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SURFACE_UNITS_OK

- id: s12-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s12_steering_mid_round.yml --out tmp/parity-gate-s12 && ruby -rjson -e 'steer = "wait, sort them by size"; %w[pi tart].each do |app|; lines = File.readlines("tmp/parity-gate-s12/run-1/#{app}-requests.jsonl"); abort "#{app}: expected 2 requests, got #{lines.size}" unless lines.size == 2; body = JSON.parse(lines[1])["body"]; users = body["messages"].select { |m| m["role"] == "user" }; abort "#{app}: steering text not the trailing user message of request 2" unless users.last["content"] == steer; end; puts "S12_REQUESTS_OK"'
  expect:
    exit_code: 0
    stdout_match: S12_REQUESTS_OK

- id: s13-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s13_command_while_streaming.yml --out tmp/parity-gate-s13 && ruby -rjson -e '%w[pi tart].each do |app|; lines = File.readlines("tmp/parity-gate-s13/run-1/#{app}-requests.jsonl"); abort "#{app}: expected 2 requests, got #{lines.size}" unless lines.size == 2; body = JSON.parse(lines[1])["body"]; users = body["messages"].select { |m| m["role"] == "user" }; abort "#{app}: command text leaked to the model: #{users.last["content"].inspect}" if users.any? { |m| m["content"].to_s.include?("/thinking") }; end; puts "S13_REQUESTS_OK"'
  expect:
    exit_code: 0
    stdout_match: S13_REQUESTS_OK

- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK

- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 1a8ea77 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    ruby -e '
      expected = %w[
        lib/tart/agent/loop.rb
        lib/tart/render/chat.rb
        lib/tart/render/editor.rb
        lib/tart/commands.rb
        test/support/mock_llm_server.rb
        test/agent_loop_test.rb
        test/chat_test.rb
        test/render/editor_test.rb
        gems/tui-split-rig/lib/tui_split_rig/scenario.rb
        gems/tui-split-rig/lib/tui_split_rig/runner.rb
        gems/tui-split-rig/scenarios/s12_steering_mid_round.yml
        gems/tui-split-rig/scenarios/s13_command_while_streaming.yml
        README.md
      ].sort
      actual = `git diff --name-only 1a8ea77..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
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

## Pre-freeze calibration (this session's own check)

Designed-RED at base (the iteration's deliverables, reasons as
OBSERVED in this session's rehearsals): `steering-units` and
`surface-units` (0 runs match — the pins do not exist),
`s12-parity`/`s13-parity` (exit 2: `no such scenario file` — the
scenario YAMLs are declared-new; the `mid_run_keys` knob is the second
designed absence behind them), `scope` (empty diff = vacuous). Designed-GREEN
at base (the standing battery — I52's cold-verified set, unchanged
surfaces): `suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, both probes,
`thinking-pins`, `hermeticity`, `lock-deps`, `zai-data`,
`threads-budget` (diff vs 1a8ea77 = empty), `wire-delta`,
`session-golden`. The rehearsal must show exactly this vector; any
GREEN-at-design-RED or RED-at-design-GREEN is a calibration defect to
fix before freeze.

## Builder Prompt

# Builder Prompt — I54 steering-queue, lane `core`

You are lane `core` of iteration I54 (steering-queue), freeze
`0b03de5`, repo **tart** (your worktree; branch
`lane/I54-steering-queue-core`). The frozen iteration file is
`architecture/I54-steering-queue.md` in the space — Grounds,
Specification, Acceptance Criteria are read-only truth; § cites below
are that file's. Identical space-staged copies sit at
`build/I54-steering-queue-core/{grounds,specification,
acceptance-criteria}.md`.

## Mission

Close the owner's live-run findings 4, 5, 7 (problems.md): slash
commands dispatch busy-or-not (`/thinking` while streaming executes,
never queues to the model — today the `!busy?` gates at
lib/tart/render/chat.rb:961-962 make EVERY command fall through to
`push_message`); queued messages render as pi's dim
`Steering:`/`Follow-up:` rows above the editor with the
`↳ Alt+Up to edit all queued messages` hint; steering delivers INSIDE
the tool round (after the batch, before the next LLM call of the SAME
run — pi agent-loop.ts:295 + :212-220, the Grounds §2 trace
verification) instead of at round end. Plus pi's followUp mode
(delivered only at full completion), alt+enter/alt+up keybinds, and the
compaction-time submit disposition. The queue splits into steer +
followUp in the agent layer; session recording carries queued messages
as user messages at their actual delivery points.

## THE LAWS YOU MUST INTERNALIZE (Grounds + Specification, condensed)

1. **No golden moves.** NOT ONE wire byte of the existing scenarios may
   change; new behaviors get NEW scenarios (s12/s13) and their fresh
   baselines, NEVER edits to s1–s10/probes/registry/differ/fixtures.
   The wire-delta + session-golden gates are byte-frozen (I52's exact
   literals — copy them verbatim; the AC block already does).
2. **The drain points are frozen 1:1 to pi's** (Spec §1.3): the NEW
   tool-batch arm drains AFTER the terminate-ledger consult; the
   complete? arm stays; the no-prompt opening drains steer-else-
   followUp; the outer break checks both. The I03-locked pre-run
   deviation (push-then-prompt = second request) is NOT reopened — its
   pin must stay green unmodified.
3. **pi's submit order** (Spec §2): expansion BEFORE queue; the
   `/thinking` gate and dispatch run busy-or-not; `/compact` and `/new`
   while busy take the abort-first arm (interrupt_work! + the deferred
   re-dispatch at agent_end — Spec §2.2/§2.6, the port's realization of
   pi's session.compact/newSession aborts); everything else dispatches
   immediately.
4. **The surface mirror is pi's two-level shape** (Spec §3): mirror
   arrays on the surface + the loop's queues; delivery removes by
   first-index text match at :message_start user-role and echoes the
   user submission AT DELIVERY (the idle submit keeps today's
   submit-time echo — Spec D5); alt+enter flips from newline to
   followUp (idle = submit, pi interactive-mode.ts:4497-4504; the
   existing alt+enter-newline pin is re-pinned); alt+up restores
   queued-then-current joined "\n\n" via the NEW `Editor#set_text`
   (pi setText discipline, cursor at end, undo snapshot) and NEVER
   aborts.
5. **The startup-help hint rows are FROZEN OUT** (Grounds D7): adding
   `to queue follow-up`/`to edit all queued messages` rows to the
   expanded help would move s9's settled-screen golden. Do not touch
   motd.rb.
6. **Rig determinism** (Spec §6): s12's tool call itself sleeps
   (`sleep 1.5 && echo …`) — that is the steering window; s13 rides
   `:slow_stream` (0.1 s/char). The runner's `mid_run_keys` knob polls
   the mock's NEW non-draining `request_count`; `captured_request_logs`
   semantics are untouched. Old-port discrimination is the request
   COUNT (3 vs 2).
7. `/thinking off` (NOT another level) in s13: the rig's mock-1 is
   reasoning:false, so both apps' gates offer only `off` (pi
   models.ts:1224-1226) — the command EXECUTES in both apps.

## Boundaries (frozen — the lane's whole touch set)

May touch ONLY: `lib/tart/agent/loop.rb`, `lib/tart/render/chat.rb`,
`lib/tart/render/editor.rb`, `lib/tart/commands.rb` (comment accuracy
only, Spec §5), `test/support/mock_llm_server.rb` (ONE additive method),
`test/agent_loop_test.rb`, `test/chat_test.rb`,
`test/render/editor_test.rb`,
`gems/tui-split-rig/lib/tui_split_rig/{scenario,runner}.rb`,
`gems/tui-split-rig/scenarios/s12_steering_mid_round.yml` (NEW),
`gems/tui-split-rig/scenarios/s13_command_while_streaming.yml` (NEW),
`README.md` (keybinding rows only, Spec §8). Must NOT touch: existing
scenarios/registry/differ/probes, the wire/session digest fixtures and
assertions, `lib/tart/agent/chat.rb` + `message.rb`, transcript.rb,
session/print/subagents/herdr/hooks/mcp/tools/settings/models, bin/tart,
motd.rb, repos/fast-llm, repos/pi. No new `Thread.new` in lib.

## Verification (run cold, from your worktree root)

- `bundle install --quiet && bundle exec rake` — the suite (with the
  §7 re-pins: chat_test :1404/:2976 stubs `push_message`→`steer`,
  :4104-4120 alt+enter).
- `bundle exec ruby bench/seam_bench.rb | tail -1` → SEAM_BENCH_OK.
- Rig, per scenario:
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<name>.yml --out tmp/<dir>`
  — s1–s10 exit 0, s1_tart exits 1 by design (assert TART_MODE_OK per
  the AC gate), s12/s13 exit 0 BOTH apps with the request-log
  assertions the AC gates encode. Baseline s12/s13 fresh (first green
  captures are the goldens).
- Both probes `--gate`. The full AC gate list is the frozen ```gates
  block — your lane's own cold pre-report run should mirror it.
- s9 in your LANE WORKTREE may exit 1 with the KNOWN deep-path
  staged-path wrap artifact (12+ precedents: pristine base fails
  identically at a same-depth path; the canonical-depth run is the
  truth). Do not chase it in-lane; report it.

## Report + discipline

Report at `build/I54-steering-queue-core/report.md`: per-AC results
with exact commands + tail outputs, the s12/s13 out dirs, the re-pin
list with reasons, deviations itemized with pi cites, residuals.
Builders NEVER commit — leave the work in the worktree; the integrator
commits. If you hit a frozen-contract contradiction you cannot resolve
inside your touch set, STOP and write `build/loop/exception-<UTC
timestamp>.md` with raw facts (never silent improvisation). Give every
long command an explicit timeout; do not block on contact_supervisor.

Effort: high — the loop rework, the surface seams, and the rig
extension are one coupled change; the frozen net is heavy; precision
beats speed.

## Builder Report

### core

# Builder Report — I54 steering-queue, lane `core` (repo tart, worktree branch lane/I54-steering-queue-core, base 1a8ea77)

Builder: architect-builder child, session 2026-10-15. No commits (git log 1a8ea77.. empty — the
worktree carries the work; the integrator commits). Every long command ran with an explicit
timeout; nothing ran in the background.

## 0. Environment facts (raw)

- All `bundle`/rig commands ran with
  `FAST_COMPLETIONS_PATH=/Users/eric/architect/spaces/20261009-pi-port/repos/fast-llm/gems/completions`
  exported (the worktree cannot resolve the Gemfile's relative `../fast-llm/gems/completions`;
  I52 report line 5 precedent: "All bundle/gate commands ran with FAST_COMPLETIONS_PATH … exported").
- `git status --porcelain` (final): exactly the 13 declared files — 11 modified + 2 new scenarios.
  Gemfile.lock, lib/tart/models.rb, motd.rb, bin/tart, repos/fast-llm, repos/pi: untouched.
- The instruction (system-prompt) bytes embed the ABSOLUTE sandbox cwd and wrap by path length:
  the byte-frozen wire-delta gate's instruction sha only reproduces when the gate runs EXACTLY as
  frozen (cwd repos/tart, `--out tmp/i54-wire` relative). From the lane worktree the sha reads
  58ac97d1fc60d26387a32f5361e57320300302334403bb61ec2a908713cf932d (deep-path wrap artifact, the
  documented s9 family). Proofs below (§AC5): WIRE_DELTA_OK verbatim at repos/tart, and
  WIRE_DELTA_OK for the LANE worktree via `--tart-dir <wt>` at canonical depth — the lane moves
  no wire byte.
- The suite's "1 skips" is pre-existing (pristine repos/tart at 1a8ea77 reports the same).

## 1. Per-AC results (commands verbatim; outputs are tails)

### AC1 — the loop (steering inside the round; follow-up at full completion; recording; queues)

- `bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/steering_delivered_inside_the_tool_round|follow_up_delivered_only_after_full_completion|steering_recorded_at_its_delivery_point|clear_queues_empties_both_queues/"`
  → `4 runs, 18 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/queued_message_continues_the_outer_loop/"`
  → `1 runs, 3 assertions, 0 failures, 0 errors, 0 skips` (I03-locked deviation un-regressed, unmodified pin)
- Full agent_loop_test: `61 runs, 306 assertions, 0 failures, 0 errors, 0 skips`
- New pins: (a) steer mid-tool-round → 2 requests, no second agent_start, steer = request 2's
  trailing user message AFTER the tool result; (b) follow-up mid-run → 3 requests, the complete
  tool-less answer's request carries NO follow-up, one agent_start; (c) session JSONL roles
  `[user, assistant, tool, user, assistant]` with the steer text at the delivery point; (d)
  clear_queues/snapshots/alias.
- Live parity (s12, `gems/tui-split-rig/scenarios/s12_steering_mid_round.yml`): pi request 2 users
  `[..., "wait, sort them by size"]`; OLD-port base measured 3 requests (exp run at 1a8ea77:
  `request 1: ["list the files"]; request 2: ["list the files"]; request 3: ["list the files", "wait, sort them by size"]`).
  AC1: PASS (see §4 deviation 3 for the outer-break realization).

### AC2 — commands dispatch busy-or-not; /compact + /new abort-first; compaction submit

- `bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/thinking_command_while_busy|queued_messages_render|alt_enter_queues_follow_up|alt_up_restores_queued_messages|compact_while_busy_defers|new_while_busy_defers|compaction_submit_steers/"`
  → `7 runs, 38 assertions, 0 failures, 0 errors, 0 skips`
- `bundle exec ruby -Ilib -Itest test/render/editor_test.rb -n "/set_text/"` → `1 runs, 6 assertions, 0 failures, 0 errors, 0 skips`
- Pins: /thinking off while busy EXECUTES (loop level "off" + surface runtime level) and NOTHING
  queues; /compact + /new while busy record `interrupt_work!`, defer, and at :agent_end run the
  EXACT idle path (outputs "context compacted" / reset fired) with the wind-down SKIPPED;
  compaction-time submit steers + flashes "Queued message for after compaction".
- Live parity (s13): pi users across both requests contain no "/thinking"; tart: exactly 1 request,
  screen shows `Thinking level: off` + the streamed reply (see §4 deviation 1 for the gate defect).
  AC2: PASS (the cure proven; the s13 gate defect is a calibration matter, not a behavior gap).

### AC3 — the queue display and the keybinds

- Covered by the same 7-run chat_test gate above + `/queued_message_delivery_removes_the_row_and_echoes_at_delivery|newline_keys/`
  → `10 runs, 55 assertions, 0 failures, 0 errors, 0 skips` (with enter_while_running_steers).
- Observed pins: the blank row + dim `Steering: <text>` + dim `↳ Alt+Up to edit all queued messages`
  render between the dock spacer and the editor; the transcript yields exactly the pending rows
  (editor bottom border row unchanged); NO submit-time echo for busy submits; delivery removes the
  row and echoes AT DELIVERY; alt+enter busy → `follow_up` (not steer), idle → submits (never a
  newline; shift+enter/ctrl+j still newline — re-pinned test_newline_keys…); alt+up clears mirror +
  loop queues, restores `"first wish\n\nsecond wish"` via set_text, never aborts, flashes pi's
  restore/no-queue texts.
- s12 settled screens: pi and tart IDENTICAL modulo sanctioned classes (rig exit 0; both show the
  tool block, then the `wait, sort them by size` echo, then `Done after steering.`).
  AC3: PASS.

### AC4 — rig parity pins (new scenarios)

- `env -u … gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s12_steering_mid_round.yml --out tmp/parity-s12`
  → exit 0 (out dir kept; `run-1/{pi,tart}{,.capture.styled,-requests.jsonl}` + summary.json fresh).
- Frozen s12 gate post-assertion: `pi: steering text not the trailing user message of request 2`,
  exit 1 — pi's steering user content is a PARTS ARRAY ([{"type"=>"text","text"=>…}], _queueSteer
  agent-session.ts:2244-2256); the gate's bare-string equality can only pass for tart. With the
  content shape normalized, BOTH apps MATCH:
  `pi: trailing user content MATCHES (parts-array normalized) / tart: trailing user content MATCHES`.
- `… run gems/tui-split-rig/scenarios/s13_command_while_streaming.yml --out tmp/parity-s13` → exit 2:
  pi 2 requests (the 2nd is pi's error-retry after `Error: Stream ended without finish_reason` —
  the mock's `:slow_stream` emits no finish_reason; pi renders `Reply after the command.` from the
  retry), tart exactly 1 request (`Thinking level: off` + the streamed reply; NOTHING queued — the
  cure demonstrated). The frozen `expected_requests: 2` + `lines.size == 2` cannot hold for the
  cured tart. lib/tart/models.rb (`supports_finish_reason: false`, I52 exception item 3) is frozen
  must-not-touch; the mock's ONE-additive-method cap blocks a finish_reason pacer (which would
  break pi's arm instead — pi would drop to 1 request).
- AC4: NOT-SATISFIED AS FROZEN — s12's rig arm passes, its gate assertion fails on pi's wire shape;
  s13's gate is unsatisfiable for the cured port. EXCEPTION FILED (see §4 items 1–2). The behaviors
  the gates were designed to prove (mid-round delivery bytes; no command text reaching the model)
  are BOTH demonstrated by the captured request logs.

### AC5 — the full no-regression battery, cold

| gate | command (abridged) | result |
|---|---|---|
| suite | `bundle install --quiet && bundle exec rake` | `1056 runs, 4960 assertions, 0 failures, 0 errors, 1 skips` (base 1044 + exactly the 12 new pins) |
| bench | `bundle exec ruby bench/seam_bench.rb 2>&1 \| tail -1` | `SEAM_BENCH_OK` |
| s1–s10 | per-scenario rig runs, `--out tmp/parity-gate-sN` | all `exit=0` (s9 included — the known deep-path artifact did NOT reproduce this run) |
| s1-tart-mode | rig run `--out tmp/parity-gate-s1tart` | exit 1 (by design) + `TART_MODE_OK` |
| tool-pending | `gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp` | `TOOL_PENDING_GATE_OK` |
| user-bash | `gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs` | `USER_BASH_STREAM_GATE_OK` |
| steering-units | frozen -n shapes | 4 runs + I03 pin 1 run, both exit 0 (§AC1) |
| surface-units | frozen -n shapes | 7 runs + set_text 1 run, both exit 0 (§AC2) |
| thinking-pins | frozen -n shapes | both exit 0 (`THINKING_PINS_OK`; note: the gate's runs-extraction grep picked up non-summary fragments — 4824/2630 — the anchors pass regardless; frozen text untouched) |
| hermeticity | launcher_smoke + e2e_session | `8 runs, 39 assertions, 0 failures` / `4 runs, 90 assertions, 0 failures`, both ec 0 |
| lock-deps | frozen command | `LOCK_DEPS_OK` (worktree note: the `env -u FAST_COMPLETIONS_PATH bundle install` leg prints "does not exist." at worktree depth — the lock file itself verified untouched, see §AC6) |
| zai-data | frozen command | `ZAI_DATA_OK` (dialect pins 2 runs, 0 failures) |
| threads-budget | `git diff 1a8ea77 -- lib \| grep -E "^\+[^+].*Thread\.new"` | empty → `THREADS_BUDGET_OK` |
| wire-delta | byte-frozen command, cwd repos/tart | `WIRE_DELTA_OK` (verbatim). Lane-worktree proof: same gate shape with `--tart-dir <worktree>` at canonical depth → `WIRE_DELTA_OK for the LANE worktree` |
| session-golden | byte-frozen command (worktree) | `SESSION_GOLDEN_OK` (7/7 digests) |
| s12/s13 gates | frozen commands (worktree) | s12: rig exit 0, post-assertion exit 1 (pi shape — §AC4); s13: rig exit 2 (§AC4) |

AC5: PASS on every standing gate; the two NEW gates carry the §4 calibration defects.

### AC6 — scope and frozen bytes

- `git status --porcelain` = exactly the 13 declared files.
- Scope check (worktree form — `git diff --name-only 1a8ea77` + `git ls-files --others`, since the
  frozen literal `1a8ea77..HEAD` is vacuous pre-integration): `SCOPE_OK 13 files`.
- Gemfile.lock byte-identical (`git diff --stat Gemfile.lock` empty); no existing
  scenario/golden/fixture/registry/differ/probe file touched; README diff = the three keybinding
  rows only (`| Shift+Enter, Ctrl+J | insert a newline |`, `| Alt+Enter | queue a follow-up message
  (submits when idle) |`, `| Alt+Up | restore queued messages to the editor |`).
- mock_llm_server.rb diff = the ONE additive method `request_count` (+7 lines) — Spec §6's cap held.
- AC6: PASS.

## 2. Re-pin list (with reasons)

1. test/chat_test.rb `with_recording_agent` (~:1404): stub `push_message` → `steer` — the surface's
   busy-submit collaborator is the pi-named seam (Spec §7).
2. test/chat_test.rb (~:2976, bang-bash agent stub): `push_message` → `steer` (same reason).
3. test/chat_test.rb `test_newline_keys_insert_newlines_without_submitting` (:4104-4120): alt+enter
   no longer newlines — re-pinned to shift+enter/ctrl+j newline + idle alt+enter SUBMITS
   (pi interactive-mode.ts:4497-4504); the joined-trim/history assertions re-derived.
4. test/chat_test.rb `test_slash_text_while_running_steers_like_any_message` (:1886) — REPLACED
   (not in the spec's three-item re-pin list; itemized): the I13-era pin asserted "/compact mid-turn
   steers" — the exact behavior §2 removes. It HANGS under the new law (the interrupt path means
   request 2 never arrives; observed live before replacement). Its coverage now lives in
   `test_compact_while_busy_defers_the_dispatch_to_agent_end` +
   `test_new_while_busy_defers_the_reset_to_agent_end` +
   `test_thinking_command_while_busy_dispatches_and_queues_nothing`.

## 3. New pins (12; suite 1044 → 1056)

agent_loop_test: steering_delivered_inside_the_tool_round_rides_the_next_request,
follow_up_delivered_only_after_full_completion, steering_recorded_at_its_delivery_point_in_the_session_jsonl,
clear_queues_empties_both_queues_and_snapshots_read_back.
chat_test: thinking_command_while_busy_dispatches_and_queues_nothing,
queued_messages_render_rows_and_shrink_the_transcript_budget,
alt_enter_queues_follow_up_while_busy_and_submits_while_idle,
alt_up_restores_queued_messages_to_the_editor,
queued_message_delivery_removes_the_row_and_echoes_at_delivery,
compact_while_busy_defers_the_dispatch_to_agent_end, new_while_busy_defers_the_reset_to_agent_end,
compaction_submit_steers_with_the_after_compaction_flash.
editor_test: set_text_replaces_content_cursor_at_end_and_pushes_undo.

## 4. Deviations from the frozen letter (ALL itemized; none silent)

1. **s13 gate unsatisfiable for the cured port (BLOCKER-class, adjudication needed).** The frozen
   YAML (`expected_requests: 2`) + gate (`lines.size == 2`) cannot pass: pi's 2nd request is an
   error-retry artifact (the mock's `:slow_stream` ends without finish_reason → pi
   `Error: Stream ended without finish_reason` → auto-retry consumes response 2), while the cured
   tart dispatches `/thinking off`, queues NOTHING, and the finish-less stream completes via
   I52's frozen `supports_finish_reason: false` (lib/tart/models.rb:145-170 — must-not-touch) →
   1 clean request. The spec's own old-port trace is internally inconsistent ("request 2 carries it
   … the steer opens request 3" — the steer is consumed BY request 2; measured at base:
   2 requests with the leak). No in-touch-set resolution exists (mock pacer = a second mock change +
   would drop pi to 1). LANDED VERBATIM, run RED, evidence: tmp/parity-s13/. Exception:
   build/loop/exception-2026-10-15T00:00:00Z.md.
2. **s12 gate's pi arm unsatisfiable as frozen.** pi's steering user content is a parts array
   ([{"type"=>"text","text"=>…}], agent-session.ts:2244-2256); the gate's
   `users.last["content"] == steer` (bare string) fails for pi, passes for tart. The RIG exits 0
   (both apps 2 requests; screens identical). Shape-normalized, both MATCH. Never rehearsed
   pre-freeze (designed-RED at base). Same exception file, item 6.
3. **The outer break realized as consume-and-HOLD** (loop.rb run_loop): the frozen expression
   `break if steering_messages.empty? && follow_up_messages.empty?` drains destructively — the
   follow-up was EATEN by the check before the opening could deliver it (observed: 2 requests, no
   delivery, second turn_start then agent_end). Realized as pi's poll semantics
   (agent-loop.ts :295→:212-220, :302-308 — pendingMessages): `held = steering_messages +
   follow_up_messages; break if held.empty?`, the opening consumes `held + steering_messages` first.
   This also fixes a base race (a steering message landing in the wind-down window was silently
   eaten by the destructive check). The I03-locked pin stayed green unmodified; the §1.3
   "never both in one opening" precedence applies to the queue drains (held leftovers ride
   `steering` in arrival order, pi's pendingMessages processing order).
4. **submit_follow_up expands skills/prompt-templates** (chat.rb): Spec §2.4 omits expansion, but
   pi's alt+enter routes through session.prompt(text, {streamingBehavior: "followUp"}) which
   expands BEFORE queueing (agent-session.ts:2005-2010 → :2012-2024). Added for pi fidelity
   (`text = @commands.expand_skill(text) if @commands`). The builtin dispatch + thinking gate +
   !-bash intercept intentionally do NOT run on the follow-up path (pi's handleFollowUp skips the
   if-chain; the text queues verbatim post-expansion).
5. **Re-pin 4 above** (test_slash_text_while_running_steers_like_any_message replaced) — beyond the
   spec's named three.
6. **InterruptKernel double placement** (chat_test): defined after IdleKernel (Ruby constant
   load-order inside the test class body) — cosmetic, noted for completeness.

## 5. Residual risks

- The two NEW-gate calibration defects (§4 items 1–2) need an architect amendment before the
  s12/s13 frozen gates can go green; the raw evidence + amendment options are in the exception file.
- s13's settled-SCREEN parity is undemonstrable while the gate is mis-calibrated (pi renders the
  retry's Error + answer rows that the port never produces); s12's screen parity IS demonstrated.
- Dequeue while a suggestion list is open: Editor#set_text cannot cancel the surface-side
  autocomplete (the spec's own §4 discipline note); a stale list persists until the next key. pi
  cancels inside setText. Minor UX edge, unfixed per the frozen seam split.
- The wire-delta/session gates are depth-sensitive (instruction embeds the absolute cwd); lane
  worktree runs show the wrap-artifact sha. Canonical-depth runs (the gates' frozen cwd) are the
  truth — both provided.
- The thinking-pins gate's runs-extraction grep is loose (picks up non-summary "N runs" fragments);
  anchors pass regardless; frozen gate text untouched.

## 6. Out dirs kept (evidence)

tmp/parity-s12, tmp/parity-s13 (fresh runs + captures + request logs + summary.json),
tmp/parity-gate-s1..s10, tmp/parity-gate-s1tart, tmp/parity-gate-s12, tmp/parity-gate-s13,
tmp/i54-tp, tmp/i54-ubs, tmp/i54-wire (worktree), tmp/i54-wire-canon, and the canonical-depth runs
inside repos/tart/tmp (i54-wire, i54-wire-lane — repos/tart git status clean before/after).

STATUS: COMPLETE_WITH_CONCERNS

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
