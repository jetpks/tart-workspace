# I60: error-transcript

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

ENTRY B of live-run fixes rev4 (notes/plan-20261014T195224Z.md — ENTRY A
closed by I59). Base `24e89ba` (I59's integrated tip on project/pi-port,
verified clean this session). Serial after I59 — this entry owns
agent/loop.rb's error arm; I59 touched its boot/switch arms only. The
oracle is the space-pinned shim (`bin/pi` → repos/pi @ f1b2e77f, 1.1.0);
every rig invocation below ran with `<space>/bin` first on PATH and
PI_*/TART_* scrubbed (the standing environment directive).

### 1. The defect (measured this session, offline, mock)

The owner's failing live session (the plan's exhibit): an API failure
that kills a turn leaves NO trace in the session jsonl — the file holds
exactly two lines (header + user message); `--resume` shows a clean
session with a dangling user turn. Reproduced against BOTH apps at base
with the rig (scenario `tmp/i60-spec/s18_error_base.yml` in the space —
one scripted HTTP 400 on the first request, `replay: true`; artifacts
archived `repos/tart/tmp/i60-spec-base/`, gitignored):

- pi settles `[hello, blank, blank, " Error: 400: {json}", " If this
  looks like a pi bug, /bug sends a report…"]` live; its session file
  holds SIX lines whose last is `{type: "message", …, message:
  {role: "assistant", content: [], …, stopReason: "error",
  errorMessage: "400: {…}", …}}`; its resume (`--continue`) renders
  `hello` + the error row again.
- tart settles `[hello, blank, "error: 400: …"]` live (the unpadded,
  lowercase agent_end scrollback line); its session file holds TWO
  lines (header + user); its resume (`-r`) renders `hello` +
  `Resumed session` — no error anywhere.

Both apps made exactly ONE request (pi's auto-retry does not fire for a
plain 400 — "400" is absent from RETRYABLE_PROVIDER_ERROR_PATTERN,
pi-ai utils/retry.ts:30-56; enabled/maxRetries defaults are irrelevant
here).

### 2. pi's contract (why pi records it)

- The stream layer NEVER throws for request/model failures — the
  StreamFn contract (packages/agent/src/types.ts:26-33): failures are
  encoded as a final AssistantMessage with `stopReason "error"` +
  `errorMessage`. openai-completions.ts:707-731 is the live arm: the
  catch sets `output.stopReason = "error"` (content = whatever blocks
  streamed, `[]` pre-stream) and `output.errorMessage =
  formatProviderError(normalizeProviderError(error))` (utils/
  error-body.ts:128-140 — `"<status>: <body>"`, the openai SDK message
  carrying the raw body).
- agent-loop.ts streamAssistantResponse :443-468: the `done`/`error`
  case takes the stream's final message; when NO partial was added
  (pre-stream failure — no `start` event ever fired) it emits
  `message_start` with the FINAL error message, then `message_end` —
  so a pre-stream 400 still gets message_start + message_end.
- Persistence is the generic message_end arm: agent-session.ts
  :1144-1163 → `sessionManager.appendMessage(event.message)` — ANY
  assistant message, including the failure message, lands as a
  SessionMessageEntry (session-manager.ts:1204-1215) whose `message`
  carries `stopReason`/`errorMessage` verbatim (the measured pi file
  above). The loop then returns through turn_end/agent_end carrying
  the failure message (agent-loop.ts:245-256).
- A SECOND, older arm exists for executor-level throws:
  agent.ts:532-548 `handleRunFailure` — synthesizes `{role:
  "assistant", content: [{type:"text",text:""}], usage: EMPTY_USAGE,
  stopReason: "error", errorMessage: error.message, timestamp}` and
  runs it through message_start + message_end + turn_end + agent_end
  (types.ts:31 documents the contract). Same persistence, same render.
- Render (assistant-message.ts:184-198): an assistant message with
  `stopReason === "error"` and no tool calls appends `Spacer(1)` +
  `Error: ${errorMessage}` in `error` fg (after any partial content);
  `stopReason === "aborted"` renders the abort message; `=== "length"`
  renders "Response was truncated before completion." — this one
  component serves live AND replay (resume renders through
  renderSessionEntries → the same component).
- The interactive agent_end arm renders NO error text — it only clears
  the status indicator and drops the streaming component
  (interactive-mode.ts:3653-3668); the error row comes from the
  assistant component at message_end. The separate muted
  `If this looks like a pi bug, /bug sends a report to the developers.`
  row (interactive-mode.ts:2168-2179 suggestBugReport, fired from
  maybeSuggestBugReport :2181-2186 for non-retryable errors, once per
  session) is the /bug machinery's surface — it does NOT re-render on
  resume (a live-session flag).

### 3. tart today (why the file never hears about it)

- step_on_reactor's rescue ladder (lib/tart/agent/loop.rb:667-694):
  `rescue Async::Cancel` re-raises (the interrupt arm), `rescue
  Fast::Completions::CancelledError` returns nil (defensive), `rescue
  StandardError => e` → `record_terminal_error(e)` — the gem RAISES
  API errors (Fast::Completions §8; Chat#step has no error rescue —
  chat.rb:208-237), so the loop's rescue IS the failure boundary.
- record_terminal_error (loop.rb:684-689) sets `@last_error` and emits
  `message_end` only `if message&.role == :assistant` — `@last_message`
  was nil'd at step entry (loop.rb:668) and only a COMPLETED step sets
  it, so a pre-stream OR mid-stream API failure emits NOTHING; the
  error rides turn_end/agent_end only (stopped_on_error?, loop.rb
  :691-695).
- The recorder persists ONLY through `record(message)` →
  `Recorder#append_message` (session.rb:429-443, called from
  handle_item's :step arm and add_user_message — loop.rb:406-415,
  :807-818). No message, no entry — the file keeps the dangling user
  turn. `agent/session.rb` itself needs NO change: append_message
  serializes `Message#to_h` generically; the missing piece is the
  failure MESSAGE, not recorder plumbing (the plan's "recorder seam"
  phrasing resolves to the recording CALL SEAM in loop.rb, not a
  session.rb edit).
- Render: the surface's agent_end error arm (render/chat.rb:622-626)
  enqueues the unpadded lowercase `error: <msg>` scrollback line +
  finalizes pending tool blocks; replay_assistant (render/
  transcript.rb:711-744) returns early unless content/thinking/tool
  calls exist — an error entry would render nothing today even if it
  existed.

### 4. Facts that shape the design (all verified this session)

- The gem's codec SKIPS empty assistant messages on the wire
  (fast-llm codec.rb wire_assistant tail — pi openai-completions.ts
  :1394-1402 verbatim, "This handles aborted assistant responses that
  got no content"): seeding the failure message into the chat history
  is WIRE-NEUTRAL by pi's own rule. Measured corollary: the overflow
  retry pin `assert_equal %w[user user], retry_payload roles`
  (agent_loop_test.rb:1404) HOLDS with the failure message seeded.
- Message#to_h's recorded assistant shape (agent/message.rb
  assistant_to_h) is the frozen byte family; `finish_reason` is the
  recorded stop-reason key (String spellings pass through
  normalize_finish_reason — "error" needs no map entry). `error_message`
  is a NEW key that rides ONLY when present — no existing recorded
  byte moves.
- from_seed_hash (message.rb) reads declared fields only — a resumed
  failure message seeds as content ""/finish_reason "error";
  error_message stays display-side (replay renders from the RAW entry
  hash, not the seeded Message — transcript.rb:659+).
- compaction.rb:194-198's comment premise ("a recorded finish_reason
  never carries aborted/error") becomes stale under this iteration —
  assistant_usage's nil-tokens guard already skips the failure message
  (pi getAssistantUsage's error-skip, equivalent net).
- The mock ALREADY scripts `{type: :error, status: 400, message: …}`
  (test/support/mock_llm_server.rb:189-196, respond_error writes the
  openai-shaped `{error: {message, type}}` body) and the rig hands
  scenario `responses` verbatim to it (scenario.rb:90-96) — the s18
  scenario needs NO mock/runner change; the `replay:` knob (I57) is
  the resume instrument.
- Measured pi-vs-tart divergences that will NOT close this iteration
  (both pinned as registry classes + itemized): the error-message TAIL
  (pi keeps the raw JSON body via the SDK message; the gem's frozen §8
  extracts `error.message` — "400: The max_tokens parameter is
  illegal." vs pi's "400: {json}"), and pi's /bug hint row (the port
  cuts the /bug machinery; rendering a hint for a nonexistent command
  would lie — the plan's scope is "the error row").

### 5. Open questions (judge)

- OQ-1: the two new s18 registry classes (`error-transcript-row-tail`,
  `pi-bug-report-hint`) — ratify as sanctioned divergences (the gem's
  frozen §8 formatting; the /bug cut) or order more (a gem error-format
  change is OUT of scope here; the hint row could be ported as a dead
  hint on owner demand).
- OQ-2: the abort path (escape/ctrl+c interrupt) stays divergent — pi
  records the partial + `stopReason "aborted"` message (the stream's
  abort catch) and renders "Operation aborted"; tart's Async::Cancel
  arm records NOTHING (the D3 cancel conversion eats the partial at
  the gem seam — no message object survives to record). Declared
  out-of-scope divergence, reopenable on owner pain (backlog
  candidate: a cancel-carrying partial would need gem cooperation).
- OQ-3: pi's `stopReason === "length"` row ("Response was truncated
  before completion.") stays unported (pre-existing, unpinned,
  orthogonal to the error row; backlog candidate with the length
  family).

## Specification

- **Objective** — close live-run rev4 ENTRY B: an API failure that kills
  a turn must leave the SAME trace pi leaves — a pi-shaped failure
  assistant message persisted to the session jsonl, rendered live, and
  rendered again on resume (BRIEF §8's indistinguishability bar at the
  error surface; the exact-parity program's settled-screen discipline
  extends to the failure row). Grounds §1's measured two-line file is
  the defect; pi's six-line file with the failure entry is the shape.

- **Output format** — source changes in repos/tart (12-file touch set);
  new unit pins under the `error_transcript` filter token; ONE new rig
  scenario (`s18_error_transcript.yml`) + TWO new registry classes; the
  measurement artifacts stay archived at `repos/tart/tmp/i60-spec-base/`
  (gitignored) with the space-side scratch scenario at
  `tmp/i60-spec/s18_error_base.yml`.

### The contract, decision by decision

**D1 — the failure message (agent/message.rb).**
`Tart::Agent::Message` gains an `error_message` reader (kwarg
`error_message: nil`, String/nil). `assistant_to_h` emits
`out[:error_message] = error_message if error_message` immediately
AFTER `finish_reason` (pi's errorMessage adjacency to stopReason). The
frozen no-tool-calls key pin (`{"role","content","tool_calls",
"finish_reason","input_tokens","output_tokens","cache_write_tokens"}`)
is UNCHANGED for every message without an error (the key rides only
when present). The synthesis factory lives on Message as
`Message.error_failure(error_message:, content: "", thinking: nil)` —
role :assistant, `content:` the accumulated partial ("" pre-stream),
`tool_calls: {}`, `finish_reason: "error"`, `error_message:`,
`tokens: nil` (the port's unreported-usage convention drops every token
key; pi's EMPTY_USAGE zeros are pi's own file format — the port's
recorded byte family governs, Grounds §3). `thinking:` is
`Thinking.new(text:, signature: "reasoning_content")` when a thinking
delta preceded the failure, else nil.

**D2 — the synthesis (agent/loop.rb, the plan's named seam).**
`step_on_reactor` accumulates the step's streamed chunks (text into a
local String, thinking deltas into a local String — the chunks the
`@chat.step` block already receives) and `record_terminal_error`
becomes the synthesis point, pi handleRunFailure/agent.ts:532-548's
shape on the no-message arm:

```ruby
def record_terminal_error(error)
  @last_error = error
  message = @last_message
  if message&.role == :assistant
    emit(type: :message_end, message:, error: true) # frozen arm, byte-identical
  else
    synthesize_failure_message(error) # D2's new arm
  end
end
```

`synthesize_failure_message(error)`: builds `Message.error_failure`
with the accumulated partials; emits `message_start` with it ONLY when
`@stream_started` is false (pi agent-loop.ts:443-448/:459-468 — the
no-partial case; a mid-stream failure already had its message_start);
runs `handle_item({type: :step, message:})`-equivalent bookkeeping —
`@last_message = message`, `@new_messages << message`,
`emit(type: :message_end, message:)`, `record(message)`, and
`@chat.add_message(message)` (pi pushes the failure message into agent
state AND the loop context at message_end — the in-session retry's
context mirrors pi) — but does NOT reset `@overflow_recovery_attempted`
(pi's reset is clean-response-only, agent-session.ts:1168-1171; a
synthesis during the overflow arm must not defeat the latch). The
existing ladder order above record_terminal_error is untouched:
Async::Cancel re-raises (no synthesis — OQ-2's declared divergence),
CancelledError returns nil (no synthesis), StandardError synthesizes.
`stopped_on_error?` then carries the failure message on turn_end and
new_messages on agent_end exactly as pi's loop return does
(agent-loop.ts:245-256) — no change needed there once @last_message is
set.

**D3 — the live render (render/chat.rb).**
The `:message_end` assistant arm gains the error row: when
`message.finish_reason == "error"` (the Message reader), after the
normal `complete`/`enqueue_message` flush, enqueue ONE region
`[Panel.blank_line, *Panel.padded_fg_rows("Error: #{message.error_message}",
viewport_width, fg: Theme[:error])]` — pi assistant-message.ts:184-198
(the Spacer(1) + `Error: ${errorMsg}` error-fg row, outputPad; the
measured pi row is ` ` + error-fg text; Panel.padded_fg_rows is the
port's pad-led wrapped error-fg row family — Grounds §1's measured
layout `[hello, blank, blank, Error]` matches row-for-row). A
surface-level flag (set by this arm, cleared at `:agent_start`) guards
the agent_end error arm: when set, the agent_end error arm SKIPS its
`error: <msg>` scrollback line (pi's agent_end renders no error text —
the component owns the row; without the guard the failure would
double-render) but KEEPS `finalize_pending_as_error` (defense). The
agent_end arm WITHOUT the flag set (the with-message failure case, no
synthesized message_end — pinned today by
test_error_finalizes_the_orphaned_pending_block_with_the_message)
renders today's line byte-identically. The interrupted arm is
untouched.

**D4 — the replay render (render/transcript.rb).**
`replay_assistant` gains the error arm: `has_error =
message["finish_reason"] == "error" && message["error_message"].is_a?
(String) && !message["error_message"].empty?`; the early-return guard
becomes `return unless has_content || has_reasoning || tool_calls.any?
|| has_error`; after the content/thinking rows (same order as the
component: content, then the error row), enqueue the SAME region shape
as D3. Pre-I60 session files (no `error_message` key) render exactly as
before (has_error false → the old guard). The live `:compaction` arm's
rebuild path (chat.rb:601) needs no change — it replays entries through
this same replay machinery, so a kept failure entry re-renders its row
(pi's rebuild renders it too, renderSessionEntries → the component).

**D5 — the rig instrument.**
`gems/tui-split-rig/scenarios/s18_error_transcript.yml`: name
`s18_error_transcript`, prompt "hello", `expected_requests: 1`,
`replay: true`, ONE response `{type: error, status: 400, message: "The
max_tokens parameter is illegal."}` (the owner's live failure shape;
the mock's existing error spec — no mock/runner change). TWO registry
classes, pinned with reasons: `error-transcript-row-tail` (pattern
`Error: \d{3}: ` — the tails are each app's frozen provider-error
formatting: pi's raw-body SDK message vs the gem's §8 extracted
message) and `pi-bug-report-hint` (pattern `If this looks like a pi
bug` — the /bug machinery cut, OQ-1). No other registry/scenario/
runner change. The gate asserts BOTH apps' live + replay rows, the
error-fg styled row, the padded row, and BOTH session files (pi's
oracle entry stopReason "error"; tart's 3rd line
`{"role"=>"assistant","content"=>"","tool_calls"=>{},
"finish_reason"=>"error","error_message"=>"400: …"}` — Grounds §1's
measured bytes).

**D6 — the declared re-pins (frozen letters that encode the old
no-trace behavior).** Exactly TWO: agent_loop_test.rb:122 and
flow_test.rb:42 — `assert_equal %i[user], agent.new_messages.map(&:role)`
→ `%i[user assistant]`. Everything else in the error-path pin family
(last_error classes, agent_end[:error], the overflow retry wire roles,
the interrupted arms) holds UNCHANGED (Grounds §4). compaction.rb:194-
198's comment premise is truthed (comment-only: the recorded
finish_reason CAN now carry "error"; the nil-tokens guard is the
operative skip).

- **Boundaries** — MAY TOUCH exactly the 12 files in the ```lanes
  block. MUST NOT: repos/fast-llm (any change — the gem's error
  formatting and empty-assistant wire-skip are the ORACLE, reproduce,
  never modify); lib/tart/agent/session.rb (the recorder persists
  Message#to_h generically — no recorder change; Grounds §3);
  lib/tart/agent/chat.rb (add_message already public; the wire-neutral
  skip is the gem's); bin/tart, lib/tart/print.rb (print's
  error_exit/EXIT_ERROR is already pi's print-mode tail — the
  synthesized message changes nothing there; verified at Grounds §2/
  print-mode read); the frozen rescue-ladder order in step_on_reactor
  (Cancel first, CancelledError second, StandardError third); the
  agent_end interrupted arm; Settings/Models/any wire key; any
  existing scenario, golden, or session digest (the failure path
  exists in NONE of them — the standing no-move letter holds
  absolutely here, no delta-audited exception is claimed). OUT OF
  SCOPE: the abort-path recording (OQ-2), the length-stop row (OQ-3),
  the /bug hint row (OQ-1), gem error-format changes.

- **Tool guidance** — the battery + new gates are in the frozen AC
  block (assembled programmatically by `build/i60-spec/assemble-gates.rb`
  from I59's frozen block: 27 standing verbatim — zai-max-tokens-units/
  wire promoted standing — threads-budget rebased 9b04d0d→24e89ba, ac:
  labels moved to AC4 commands byte-verbatim; 4 new). The rig env
  prefix (`env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u
  HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID`) is mandatory
  on every rig invocation; the pinned-oracle PATH prepend
  (`<space>/bin` first) is the gate-shell standing rule. Base
  measurement artifacts: `repos/tart/tmp/i60-spec-base/` (both apps'
  captures + session files at 24e89ba). Do NOT burn live z.ai credits
  — the mock's 400 is the whole evidence chain.

- **Effort** — model zai/glm-5.3-flash, effort HIGH (a
  failure-path contract change across the agent/render/recorder-call
  seams with frozen arm-preservation bars and a new both-apps rig
  gate; the mid-stream/no-stream discrimination and the no-double-
  render guard need the care).

```lanes
- name: core
  repo: tart
  touch:
    - gems/tui-split-rig/registry.yml
    - gems/tui-split-rig/scenarios/s18_error_transcript.yml
    - lib/tart/agent/loop.rb
    - lib/tart/agent/message.rb
    - lib/tart/compaction.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
    - test/flow_test.rb
    - test/render/transcript_test.rb
    - test/session_test.rb
  effort: high
```

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: 27 STANDING gates carried verbatim
from I59's frozen block (commands byte-identical; zai-max-tokens-units
+ zai-max-tokens-wire promoted standing per the digest convention;
threads-budget rebased 9b04d0d→24e89ba) + 4 new gates. The standing
battery was green cold on I59's integrated tip (the judge's own
post-integrate run, ARCHITECT.md I59 row); every new gate's RED-at-base
reason is MEASURED this session (Grounds §1), not asserted.

**Declared mechanical correction to the 27 STANDING gates' `ac:`
labels:** I59's frozen block labels its battery gates `ac: AC4` and the
two zai gates `ac: AC1`/`ac: AC3` after I59's own AC map; I60's battery
AC is **AC4**. The assembled block relabels all 27 to `ac: AC4` —
COMMANDS byte-verbatim, only the label moves (the I59 correction
precedent, itemized, never silent).

**AC1 — the failure message is synthesized and persisted exactly once,
through the normal message machinery (D1, D2).** On a step failure with
no assistant message, the loop synthesizes the pi-shaped failure
assistant message and runs it through message_start (pre-stream only —
mid-stream keeps its existing message_start), message_end, the recorder
(`append_message` — the file gains the entry on the leaf chain), the
chat history, and new_messages; turn_end carries the failure message;
agent_end carries it in messages beside `error:`. The recorded bytes are
the frozen family: `{"role"=>"assistant", "content"=><partial or "">,
"tool_calls"=>{}, "finish_reason"=>"error", "error_message"=>"<the
exception's message>"}` — no token keys. The with-assistant-message arm
(message_end `error: true`) and the whole cancel ladder (Cancel /
CancelledError — NO synthesis) are byte-unchanged; the overflow arm's
retry wire and the recovery latch hold (the empty-assistant wire-skip).
Judge: error-transcript-units (≥4 agent-loop + ≥2 session runs; filter
verified EMPTY at base).

**AC2 — the transcript shows the error row the way pi does, live and
on resume, with no double render (D3, D4).** Live: the failure
message_end renders one pad-led, error-fg, wrapped `Error: <msg>` row
region (after any streamed partial content — the mid-stream partial
survives into the transcript); the agent_end error arm renders NOTHING
extra on that path (the guard), while the flag-unset agent_end error
case keeps today's `error: <msg>` line byte-identically (the frozen
chat pin). Replay: a recorded failure entry renders the same row after
its content; pre-I60 session files render byte-identically to today.
The interrupted arm is untouched. Judge: error-transcript-render-units
(≥3 chat + ≥2 transcript runs; filter verified EMPTY at base).

**AC3 — both apps measured, both files pinned (D5).** On the s18
scenario (one scripted 400, replay leg), BOTH apps settle one request
with a padded live `Error: 400: …` row in error fg, BOTH replay
captures render the row again, pi's session file carries the oracle
failure entry (assistant, stopReason "error", errorMessage `400: …`),
and tart's session file is THREE lines whose third is the failure entry
with the D1 bytes — the measured two-line defect is dead. The rig exits
0 with the two new registry classes covering exactly the two declared
divergences (message tail, /bug hint — OQ-1). Judge: s18-error-
transcript (RED at base: the scenario file does not exist and tart's
row/entry are absent — Grounds §1).

**AC4 — no byte moves beyond the declared set + scope.** The standing
battery (27 gates: suite, bench, s1–s10, s1-tart-mode, both probes,
thinking-pins, hermeticity, lock-deps, zai-data, threads-budget rebased
to 24e89ba, wire-delta, session-golden, s17-parity, render-perf-units,
render-perf-probe, zai-max-tokens-units, zai-max-tokens-wire) is green
cold EXCEPT the three standing environment-class gates disclosed below;
NO existing scenario, golden, registry class, wire byte, or
session byte moves (this entry claims NO delta-audited exception — the
error path exists in no frozen artifact); exactly the 12 declared files
change (the TWO declared re-pins — agent_loop_test.rb:122,
flow_test.rb:42, `%i[user]`→`%i[user assistant]` — land inside them;
the compaction.rb comment truthing is comment-only). Judge: the battery
+ scope (non-vacuous at the lane's 12-file diff, base 24e89ba).

**The standing environment-class gates (this session's rehearsal
vector: 24 GREEN + 7 RED, every RED accounted).** Under the pinned-
oracle environment directive (space `bin/` first on PATH, PI_* unset),
THREE standing gates run RED at the CLEAN BASE for the I59-adjudicated
environment classes — re-verified this session at 24e89ba, pin
identities exact: `suite` (SystemPromptTest#test_pi_docs_paths_resolve_
pis_install NoMethodError + LauncherSmokeTest#test_print_boot_wires_
the_composed_harness_prompt missing `<docs>` — the shim's
no-package-dir consequence — plus LauncherSmokeTest#test_footer_data_
clamps_the_boot_level_but_keeps_the_badge_source_raw "Expected: high"
— unset-PI_MODEL + the owner's real ~/.tart catalog in footer_data),
`hermeticity` (the same launcher pins standalone), and `wire-delta`
(the E3 instruction literal: measured `b7debb5a…` — the `<docs>`
section absent; the operative proof is base-vs-lane instruction
identity modulo the ONE cwd line, the I59 ruling). These are the
coordinator-declared standing classes — do NOT re-litigate; the
builder reports them, never chases them. Every OTHER standing gate
was GREEN in this session's own rehearsal at the clean base (incl.
s1–s10, s17, both probes, and both promoted zai gates).

RED-at-freeze register: error-transcript-units + error-transcript-
render-units = runs 0 (filters verified EMPTY at base —
`grep -rn error_transcript test/` → nothing; rehearsal read
`FAIL agent-loop pins runs=0 (want >=4; 0 = filter empty,
declared-new)`); s18-error-transcript = RED at base (rehearsal read
`FAIL s18 rig ec=2` — the scenario file lands with the lane; tart's
row + entry absent — Grounds §1's measurement IS the red evidence);
scope = vacuous empty diff at base + the 12 missing files (rehearsal
read `extra=[] missing=[…12]`). The three standing environment-class
REDs are disclosed above (suite, hermeticity, wire-delta).

```gates
- id: suite
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

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
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
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
    added=$(git diff 24e89ba -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: s17-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/parity-gate-s17; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s17 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s17/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(a["capture"]); ls = File.read(a["styled_capture"]); abort "#{app}: live header row missing" unless live.include?(" edit edit-bg.txt"); abort "#{app}: live removed diff row missing" unless live.include?("-2 line two bravo"); abort "#{app}: live added diff row missing" unless live.include?("+2 line two charlie (edited)"); abort "#{app}: live intra-line inverse missing" unless ls.include?("\e[7m"); abort "#{app}: live success-bg missing" unless ls.include?("\e[48;2;37;65;49m"); abort "#{app}: generic defect row present" if live.include?("\u23bf edit:"); rep = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture")); reps = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture.styled")); abort "#{app}: replay header row missing" unless rep.include?(" edit edit-bg.txt"); abort "#{app}: replay removed diff row missing" unless rep.include?("-2 line two bravo"); abort "#{app}: replay success-bg missing" unless reps.include?("\e[48;2;37;65;49m"); end; puts "S17_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S17_PARITY_OK

- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
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

- id: zai-max-tokens-wire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i59-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i59-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "tmp/i59-wire/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK


- id: error-transcript-units
  ac: AC1
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
  ac: AC2
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

- id: s18-error-transcript
  ac: AC3
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s18 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s18_error_transcript.yml --out tmp/parity-gate-s18; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s18 rig ec=$ec (declared-new: scenario+registry land with the lane)"; exit 1; }
    ruby -rjson -e 'out = "tmp/parity-gate-s18"; s = JSON.parse(File.read(File.join(out, "summary.json")))["runs"][0]; stage = File.join(out, "run-1"); %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(File.join(stage, "#{app}.capture")); rows = live.lines.map(&:chomp).grep(/^\s*Error: 400:/); abort "#{app}: live error row missing" unless rows.size == 1; abort "#{app}: live error row unpadded" unless rows[0].start_with?(" "); styled = File.read(File.join(stage, "#{app}.capture.styled")); srow = styled.lines.find { |l| l.include?("Error: 400:") }; abort "#{app}: styled error row missing" unless srow; abort "#{app}: styled error row lacks the error fg" unless srow.include?("\e[38;2;234;127;129m"); rep = File.read(File.join(stage, "#{app}.replay.capture")); abort "#{app}: replay error row missing" unless rep.lines.map(&:chomp).grep(/^\s*Error: 400:/).size == 1; end; tart = Dir[File.join(stage, "home/tart/.tart/sessions/*/*.jsonl")]; pis = Dir[File.join(stage, "home/pi/.pi/agent/sessions/*/*.jsonl")]; [tart, pis].each { |d| abort "want exactly 1 session file, got #{d.size}" unless d.size == 1 }; pi_entry = File.readlines(pis[0]).map { |l| JSON.parse(l) }.find { |e| e["type"] == "message" && e.dig("message", "role") == "assistant" }; abort "pi oracle failure entry missing" unless pi_entry&.dig("message", "stopReason") == "error" && pi_entry.dig("message", "errorMessage").to_s.start_with?("400:"); tl = File.readlines(tart[0]).map { |l| JSON.parse(l) }; abort "tart session must be 3 lines, got #{tl.size}" unless tl.size == 3; m = tl[2].dig("message"); abort "tart failure entry missing/misshapen: #{m.inspect}" unless m["role"] == "assistant" && m["content"] == "" && m["tool_calls"] == {} && m["finish_reason"] == "error" && m["error_message"].to_s.start_with?("400:"); puts "S18_ERROR_TRANSCRIPT_OK"'
  expect:
    exit_code: 0
    stdout_match: S18_ERROR_TRANSCRIPT_OK

- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    ruby -e '
      expected = %w[
        gems/tui-split-rig/registry.yml
        gems/tui-split-rig/scenarios/s18_error_transcript.yml
        lib/tart/agent/loop.rb
        lib/tart/agent/message.rb
        lib/tart/compaction.rb
        lib/tart/render/chat.rb
        lib/tart/render/transcript.rb
        test/agent_loop_test.rb
        test/chat_test.rb
        test/flow_test.rb
        test/render/transcript_test.rb
        test/session_test.rb
      ].sort
      actual = %x(git diff --name-only 24e89ba...HEAD).split("\n").map { |f| f.strip }.reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      if !extra.empty? || !missing.empty?
        puts "FAIL scope: extra=#{extra.inspect} missing=#{missing.inspect}"
        exit 1
      end
      puts "SCOPE_OK #{actual.size}"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

You are the builder for iteration `error-transcript` (I60), lane `core`.
Work ONLY in the provisioned worktree on branch `lane/I60-error-transcript-core`
(base `24e89ba`); NEVER commit (the integrator lands your tree), NEVER
touch the space repo, NEVER push. The full iteration contract is the
frozen Grounds/Specification/Acceptance Criteria in this file (verbatim
below) — read them first; this header is the lane's operating brief.

THE TASK IN ONE PARAGRAPH: an API failure that kills a turn must leave
the SAME trace pi leaves — synthesize the pi-shaped failure assistant
message (`Message.error_failure`: role :assistant, content = the step's
accumulated partial ("" pre-stream), tool_calls {}, finish_reason
"error", error_message = the exception's message, NO token keys) at
`record_terminal_error`'s no-message arm and run it through the NORMAL
message machinery (message_start when no stream ever started — never
mid-stream; message_end; `record` → the session jsonl's failure entry;
`@chat.add_message`; `@new_messages`; turn_end/agent_end carry it), then
render ONE pad-led error-fg `Error: <msg>` row at the :message_end
assistant arm (render/chat.rb) AND on replay (replay_assistant's error
arm), with the surface flag guarding the agent_end error arm so the
failure never double-renders (the flag-unset orphan-finalize case stays
byte-identical). The s18 rig scenario (one scripted 400, replay leg) +
the two registry classes land with this lane. Grounds §1's measured
two-line tart session file is the dead defect; pi's six-line file with
the failure entry is the shape.

TOUCH SET (exactly 12 files; the scope gate enforces):
- lib/tart/agent/message.rb — D1: `error_message` reader (kwarg
  String/nil); `assistant_to_h` emits `out[:error_message] =
  error_message if error_message` immediately AFTER `finish_reason`
  (pi's errorMessage/stopReason adjacency); the frozen no-tool-calls key
  pin holds UNCHANGED for every message without an error (the key rides
  only when present); the factory `Message.error_failure(error_message:,
  content: "", thinking: nil)` — `tokens: nil` (the port's
  unreported-usage convention drops every token key), `Thinking.new(text:,
  signature: "reasoning_content")` only when a thinking delta preceded
  the failure.
- lib/tart/agent/loop.rb — D2: `step_on_reactor` accumulates the step's
  streamed chunks (text + thinking deltas into locals — the same chunks
  the `@chat.step` block receives); `record_terminal_error` keeps the
  with-assistant-message arm byte-identical (`emit(type: :message_end,
  message:, error: true)`) and gains the synthesis arm;
  `synthesize_failure_message(error)` — message_start ONLY when
  `@stream_started` is false; `@last_message`/`@new_messages`/emit
  message_end/`record(message)`/`@chat.add_message(message)`; does NOT
  reset `@overflow_recovery_attempted` (pi's reset is clean-response-
  only — a synthesis during the overflow arm must not defeat the latch).
  The rescue ladder order is untouched: Async::Cancel re-raises (NO
  synthesis — OQ-2's declared divergence), CancelledError returns nil
  (NO synthesis), StandardError synthesizes.
- lib/tart/render/chat.rb — D3: the :message_end assistant arm, when
  `message.finish_reason == "error"`, after the normal flush enqueues
  `[Panel.blank_line, *Panel.padded_fg_rows("Error:
  #{message.error_message}", viewport_width, fg: Theme[:error])]`;
  the surface flag (set by this arm, cleared at :agent_start) makes the
  agent_end error arm SKIP its `error: <msg>` scrollback line but KEEP
  `finalize_pending_as_error` (defense); the flag-UNSET agent_end error
  case renders today's line byte-identically (the frozen chat pin);
  the interrupted arm is untouched.
- lib/tart/render/transcript.rb — D4: `replay_assistant` gains
  `has_error` (`finish_reason == "error"` && error_message a non-empty
  String); the early-return guard becomes content||reasoning||
  tool_calls||has_error; the SAME region shape as D3 after the
  content/thinking rows; pre-I60 session files (no error_message key)
  render byte-identically to today.
- lib/tart/compaction.rb — comment-only: truth :194-198's premise (a
  recorded finish_reason CAN now carry "error"; the nil-tokens guard is
  the operative skip). No code change.
- gems/tui-split-rig/scenarios/s18_error_transcript.yml — D5: name
  `s18_error_transcript`, prompt "hello", `expected_requests: 1`,
  `replay: true`, ONE response `{type: error, status: 400, message:
  "The max_tokens parameter is illegal."}` (the mock's existing error
  spec — NO mock/runner change).
- gems/tui-split-rig/registry.yml — exactly TWO new classes with
  reasons: `error-transcript-row-tail` (pattern `Error: \d{3}: ` — the
  tails are each app's frozen provider-error formatting) and
  `pi-bug-report-hint` (pattern `If this looks like a pi bug` — the /bug
  machinery cut, OQ-1).
- test/agent_loop_test.rb — the declared re-pin at :122 (`%i[user]` →
  `%i[user assistant]`) + NEW pins under the `error_transcript` filter
  (≥4 runs): pre-stream 400 → the synthesized+recorded entry (no token
  keys; error_message carries the exception's message); mid-stream
  partial (content accumulates; NO second message_start); the cancel
  ladder (Cancel/CancelledError → NO synthesis); a synthesis during the
  overflow arm does NOT reset the recovery latch; the with-message arm
  emits `error: true` byte-identically.
- test/session_test.rb — NEW pins under the filter (≥2 runs): the
  failure entry round-trips through the recorder (the D1 byte family:
  `{"role"=>"assistant","content"=>"","tool_calls"=>{},
  "finish_reason"=>"error","error_message"=>"…"}` — no token keys);
  from_seed_hash seeds content ""/finish_reason "error" with
  error_message display-side; pre-I60 files unaffected.
- test/chat_test.rb — NEW pins under the filter (≥3 runs): the live
  error row (pad-led, error fg, wrapped) after any partial; the agent_end
  guard (no `error:` scrollback line when the flag is set — no double
  render); the flag-unset orphan-finalize case byte-identical; the
  interrupted arm untouched.
- test/render/transcript_test.rb — NEW pins under the filter (≥2 runs):
  a recorded failure entry renders the row after its content; pre-I60
  files (no error_message key) byte-identical.
- test/flow_test.rb — the declared re-pin at :42 (`%i[user]` →
  `%i[user assistant]`). Nothing else in the file moves.

MUST-NOT: no repos/fast-llm change of ANY kind (the gem's §8 error
formatting AND its empty-assistant wire-skip are the ORACLE — reproduce,
never modify; the wire-skip makes seeding the failure message
wire-neutral by pi's own rule, Grounds §4); no lib/tart/agent/session.rb
change (the recorder persists Message#to_h generically — Grounds §3);
no lib/tart/agent/chat.rb change (add_message is already public); no
bin/tart or lib/tart/print.rb change (print's error_exit/EXIT_ERROR is
already pi's print-mode tail); the rescue-ladder ORDER is frozen; the
agent_end interrupted arm is frozen; no Settings/Models/wire-key change;
NO existing scenario, golden, registry class, wire byte, or session byte
moves (this entry claims NO delta-audited exception — the failure path
exists in none of them); no /bug hint row, no abort-path recording, no
length-stop row (OQ-1/2/3 are OUT OF SCOPE); no new runtime deps; no
Thread.new.

OPERATING DISCIPLINE:
- Run the battery cold from the worktree (the 31 gates in the frozen AC
  block). THREE standing gates run RED at the CLEAN BASE for the
  coordinator-declared environment classes — `suite`, `hermeticity`,
  `wire-delta` (the pinned-oracle shim's no-<docs> consequence;
  unset-PI_MODEL + the owner's real ~/.tart catalog footer; the E3
  instruction literal b7debb5a… — see the AC preamble + ARCHITECT.md's
  standing rulings). Report them, NEVER chase them. Every other
  standing gate was GREEN in the freeze rehearsal at base 24e89ba.
- `error-transcript-units`, `error-transcript-render-units`, and
  `s18-error-transcript` are RED at base BY DESIGN (declared-new: your
  tests + scenario land with this lane). The cure turns them GREEN; if
  your tree leaves any of them RED, the synthesis is wrong — re-read
  Grounds §1/§3, do NOT touch the gates.
- Every rig invocation carries the mandatory env prefix (`env -u
  HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
  HERDR_WORKSPACE_ID -u HERDR_PANE_ID`). For any DIRECT pi/tart shell:
  export PATH with the space's `bin/` first and unset PI_PACKAGE_DIR
  PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW (the pinned 1.1.0 bundle honors
  PI_PACKAGE_DIR at runtime; rig panes self-scrub PI_*/TART_*).
- OFFLINE ONLY — the mock's scripted 400 (MockLLMServer respond_error,
  the openai-shaped error body) is the whole evidence chain; do NOT burn
  live z.ai credits. The base measurements are archived in the SPACE
  repo (repos/tart/tmp/i60-spec-base/ — both apps' live+replay captures
  and session files at 24e89ba; read them from the worktree's parent),
  and the spec-scratch scenario shape is at tmp/i60-spec/
  s18_error_base.yml (SPEC SCRATCH — the frozen s18 is yours to land).
- Exactly TWO existing letters re-pin (agent_loop_test.rb:122,
  flow_test.rb:42 — `%i[user]` → `%i[user assistant]`); grep the suite
  for other pins on the error path FIRST (last_error classes,
  agent_end[:error], the orphan-finalize chat pin) — they hold
  UNCHANGED per Grounds §4; itemize every re-pin in the report.
- If a frozen ruling fights reality (e.g. a pin you cannot satisfy
  without touching a MUST-NOT file), STOP and checkpoint
  build/loop/exception-<UTC>.md with the raw facts; never silently
  re-freeze, never widen scope.
- Report at build/I60-error-transcript-core/report.md (the staged
  architecture file's Builder Report section is transcribed from it):
  per-AC outcomes, the four declared-new gates' RED→GREEN ledger, the
  re-pin inventory (itemized), deviations, incidents. Include your
  PHASE 0 disagreements (the judge rules them) and a STATUS line.
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md. bg_wait abort with "Still active" →
  RE-ISSUE the wait.

The frozen sections follow verbatim.

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I60-error-transcript-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence error-transcript --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section error-transcript verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify error-transcript`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
