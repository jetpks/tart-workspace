# I47: seam-memory

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I47 seam-memory

Program ENTRY 5 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding rules folded in): the minimal
internal extension seam (BRIEF §6 amended 2026-10-13, commit `baa9b9e`) plus
the owner's memory and herdr behaviors built natively — the bridge entry the
subagents wave (ENTRY 6–7) mounts on. Inherited patterns: I43 schemas / I44
shapes / I45 flow / I46 zai — every letter cite below was re-verified against
the sources this session (the I43/I46 count-correction precedent). All
measurements 2026-10-13 at base **cac2612** (`project/pi-port` tip, I46 merged;
`git log --oneline -1` re-run, tree clean). Spec-time scratch under
`tmp/i47-spec/` (gitignored).

**Probe-report note (grounding provenance).** The plan preamble cites
`build/pi-extension-interface-probe/report.md`; that path is ABSENT in the
space (empty `build/`, gitignored tree — the probe ran under the coordinator
run that authored the plan). Its findings survive in three independent forms,
all re-verified this session: (a) the owner ruling recorded in ARCHITECT.md +
BRIEF §6 (commit `baa9b9e`); (b) the raw probe prompt
`tmp/prompts/pi-extension-interface-probe-025600.md`; (c) EVERY letter cite
below re-read line-by-line against `repos/pi`, `repos/tart`, the owner's
extension sources, and the herdr 0.9.3 binary. Nothing in this spec rests on
the missing file.

## 1. Control (this session, base cac2612)

- Suite: `886 runs, 3823 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip) — fresh run this session.
- `SEAM_BENCH_OK` (fresh run this session).
- Deps: NO new gem. ruby_llm 2.1.0 pinned; gem paths below are
  `…/gems/ruby_llm-2.1.0/lib/ruby_llm/…` (verified `bundle show ruby_llm`).
- Live probe: NONE needed — every piece of this iteration is statically or
  hermetically groundable (the recall-line probe below was run against staged
  pi offline, no network).

## 2. The seam today (tart, base cac2612 — verified)

- **Loop events — letter count CORRECTED.** The letter says "10 loop events
  (agent/loop.rb:33-40)". The header comment at loop.rb:29-33 indeed lists ten,
  but the file EMITS **eleven** types — `emit(type: …)` grep, this session:
  `:agent_start :turn_start :message_start :message_update :message_end
  :tool_execution_start :tool_execution_end :turn_end :compaction_start
  :compaction :agent_end` (`:compaction_start` landed with the I30-era border
  status; the header comment was never updated — recorded, comment fix rides
  this iteration's loop edit). The `on_event:` constructor seam is real
  (loop.rb:87-88, `@on_event&.call(event)` at :703).
- **Tool execution path.** Tools are `RubyLLM::Tool` subclasses
  (`Tools::Registry.build` → Hash{String => Tool}); `@chat.with_tools` at loop
  construction (loop.rb:119). ruby_llm executes pending calls inside `#step`:
  `execute_tool_with_callbacks` (chat.rb:1625-1635) runs
  `run_callbacks(:before_tool_call, tool_call)` whose RETURN IS IGNORED, then
  `execute_tool` → `invoke_tool` (chat.rb:1682-1694) →
  `tool.call(**arguments, tool_call:)` with `arguments = tool_call.arguments`
  re-read at execute time. ToolCall#arguments is an unfrozen Hash
  (attr_reader; tool_call.rb:28-46) — but the SAME object the recorded
  assistant message's `tool_calls` array holds (mutation would reach the wire
  on replay — the replay-probe invariant forbids it).
- **Input validation** is INSIDE each tool's `execute` via the I43 one-seam
  `validate_input(**args)` (safe_execute.rb:38-42; every built-in opens with
  it), returning `{error: <pinned string>}` results.
- **Wire declarations**: `tool_for(tool)` (protocols/chat_completions/tools.rb
  :30-45) reads `tool.name/description/parameters_schema/provider_options` —
  the tools digest gate (`7360fd1e…`) is the byte bar any wrapping must hold.
- **Commands**: `Commands::BUILTINS` (commands.rb:46-56, nine entries) +
  `Commands.builtin_name` match shapes (:59-64) + `Commands::Handler#dispatch`
  (:141-160); the autocomplete reads `Render::SlashSource.new(commands:
  Commands::BUILTINS, …)` (bin/tart:515).
- **MOTD [Extensions] row exists already**: `Render::Chat.new(extensions:)`
  receives "the loaded MCP server names" (chat.rb:132, bin/tart:518) and the
  collapsed section renders them sorted comma-joined (chat_test.rb:1703-1727).
- **Theme tokens for the recall block are already carried**: `custom_message_
  bg/text/label` (theme.rb:52-57, the I11 token table — pi dark.json:34-36).

## 3. pi's seam semantics (re-verified line-by-line this session)

### 3.1 tool_call BLOCK semantics

- `emitToolCall` (extensions/runner.ts:1242-1262): iterates
  `snapshotEventHandlers(extensions, "tool_call")` — registration order,
  handler list SNAPSHOTTED before dispatch; a handler result with `block`
  RETURNS immediately (later handlers skipped); NO per-handler isolation —
  the first thrown error propagates.
- `_beforeToolCall` (agent-session.ts:661-687): wraps emitToolCall; an `Error`
  rethrows AS-IS, a non-Error wraps as
  `"Extension failed, blocking execution: <String(err)>"`.
- `prepareToolCall` (agent/src/agent-loop.ts:711-781): `validateToolArguments`
  runs BEFORE the hook (invalid args → immediate error result, handlers NEVER
  see the call); `beforeResult?.block` → immediate error tool result with
  `reason || "Tool execution was blocked"`, `terminate: true` copied onto the
  result (types.ts:61-73); the whole thing sits in a try/catch — a hook error
  becomes the tool's error result (fail-safe BLOCK, agent-session.ts:685-687).
- `validateToolArguments` (ai/src/utils/validation.ts) does
  `structuredClone(toolCall.arguments)` — handlers mutate a CLONE: pi's
  recorded assistant message NEVER carries mutated args (replay/wire bytes
  untouched by mutation).
- Terminate batch rule: `shouldTerminateToolBatch` (agent-loop.ts:690-691) —
  `finalizedCalls.length > 0 && every(result.terminate === true)`;
  `hasMoreToolCalls = !executedToolBatch.terminate` (:272) — the INNER loop
  stops after the batch; the outer loop's queued-message continuation is
  untouched.
- Plain events (`emit`, runner.ts:1089-1120): registration order, per-handler
  try/catch — handler errors are REPORTED (emitError) and SWALLOWED, dispatch
  continues. `ToolCallEventResult` = `{block?, reason?, terminate?}`
  (extensions/types.ts:1426-1435); "To modify arguments, mutate `event.input`
  in place instead."
- Tool registration: `registerTool` (loader.ts:289-300) stores into the
  extension's tool map; `_refreshToolRegistry` (agent-session.ts:3495+)
  merges base definitions FIRST, extension/custom tools after (same-name
  OVERRIDES). Extension tools ride the wire like any other
  (`convertTools`, ai/src/api/openai-completions.ts:1482-1518).

### 3.2 nextTurn message injection

- `sendCustomMessage` (agent-session.ts:2293-2331): `deliverAs: "nextTurn"`
  pushes onto `_pendingNextTurnMessages` — NO session append, NO events at
  send time.
- Injection at the next user prompt (`_handleUserPrompt`, :2086-2095): the
  user message is pushed FIRST, then every pending nextTurn message, then the
  queue clears — wire order [user, *customs].
- `runAgentLoop` (agent/src/agent-loop.ts:105-126) emits
  `message_start`/`message_end` per initial message in array order.
- On `message_end` (agent-session.ts:1144-1160): role `custom` →
  `sessionManager.appendCustomMessageEntry(customType, content, display,
  details)` — entry shape `{type: "custom_message", customType, content,
  display, details, id, parentId, timestamp}` (session-manager.ts:1339-1360);
  extension `message_end` handlers run first (emitMessageEnd, :1315-1340).
- Wire: `convertToLlm` custom → **user-role text message** (messages.ts:161-
  170); resume replay: `sessionEntryToContextMessages` custom_message →
  createCustomMessage (session-manager.ts:437-459) — the recall text rides
  the wire again on resume, and a NEW session_start fires another recall at
  the next prompt (pi's actual owner-visible behavior).
- `session_start` reasons: `"startup" | "reload" | "new" | "resume" | "fork"`
  (extensions/types.ts:744; default `{type: "session_start", reason:
  "startup"}` agent-session.ts:509).
- Rendering: `CustomMessageComponent` (modes/interactive/components/
  custom-message.ts:41-115) — `Spacer(1)`, a `Box` with `customMessageBg`
  background, `setPaddingX(outputPad)`; first row `\x1b[1m[<customType>]\x1b[
  22m` in `customMessageLabel`; `Spacer(1)`; then the content as `Markdown`
  in `customMessageText`. No custom renderer is registered for
  "memory-recall" (memory.ts registers none) → the DEFAULT rendering is the
  parity target.

## 4. The owner's memory extension (jetpks/pi-extensions memory.ts @ ca12eb5)

173 lines (verified `wc -l`), loaded in the owner's pi via the settings
`packages` entry `git:git@github.com:jetpks/pi-extensions.git`
(~/.pi/agent/settings.json) — active in EVERY daily-driver session. pi has NO
builtin memory. The full behavior contract, re-verified:

- **Store**: `PI_MEMORY_HOME || ~/.pi/agent/memory` home; project dir =
  `<home>/<basename(gitRoot(cwd) ?? cwd)>` (walks up for a `.git` FILE or dir
  — worktrees use a file; fallback = cwd basename). Index `MEMORY.md`.
- **Recall** (session_start): no index → no-op; else bounded — first 200
  lines AND 25KB (line cost = bytes + 1), content =
  `"[project memory] index loaded at session start; use the memory tool
  (read/list) for topic files:"` + "\n" + bounded index + (truncated ?
  "\n" + `"[project memory] index is truncated; more entries exist — use the
  memory tool list action."` : ""), sent as
  `pi.sendMessage({customType: "memory-recall", content, display: true},
  {deliverAs: "nextTurn"})` — ONCE per session_start.
- **Tool "memory"** (registerTool): params `action` ∈ save|read|list
  (required), `topic`?, `text`?; results are plain text, errors flagged
  `isError`. Exact strings: save/read without topic → `The memory tool
  <action> action needs a topic.`; save without text → `The memory tool save
  action needs text to remember.`; save success → `Saved memory topic
  "<topic>" (<slug>.md).`; read missing → `No memory saved for topic
  "<topic>" (<slug>.md). Use the memory tool list action to see saved
  topics.`; list without index → `No project memory yet. Save some with the
  memory tool save action.`; invalid topic (absolute, `..` segment) →
  `Invalid topic "<topic>": topics are plain names inside the project memory
  directory, not paths.`; (bad slug) → `Invalid topic "<topic>": it must be
  a plain name like "deploy" (letters, numbers, dashes).`; (containment) →
  `Invalid topic "<topic>": it must stay inside the project memory
  directory.`
- **save**: file `<dir>/<slug>.md` gets `---\nmodified: <ISO8601>\n---\n\n
  <text.trim()>\n`; the index line upserts as
  `- [<topic.trim()>](<slug>.md): <firstLine(text)>` where firstLine = the
  first non-blank line of the RAW text, `…`-truncated past 120 chars (119 +
  ellipsis); kept rows = existing non-empty rows NOT containing
  `](<slug>.md)`; file written with a trailing newline. slugify =
  lowercase, `[^a-z0-9]+`→`-`, dash-trim, gate
  `^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$`.
- **read**: the file's bytes; **list**: the index file's bytes.
- **Tool declaration on the wire** (TypeBox → JSON Schema, generated this
  session against pi's typebox 1.3.27):
  `{"type":"object","required":["action"],"properties":{"action":{"anyOf":
  [{"type":"string","const":"save"},{"type":"string","const":"read"},
  {"type":"string","const":"list"}],"description":"save: store text under
  topic; read: return a topic file; list: return the index"},"topic":{"type":
  "string","description":"Topic name, e.g. deploy (required for
  save/read)"},"text":{"type":"string","description":"Text to remember (save
  only)"}}}` — description
  `"Persistent per-project memory. Save durable facts, preferences, and
  corrections worth carrying to future sessions — never secrets, never
  one-off task state. Topic files are read on demand."`
- **System prompt effects**: NO `promptSnippet` (custom tools without one are
  OMITTED from the `<tools>` snippet list — types.ts:572-587); two
  `promptGuidelines` bullets append to `<rules>` AFTER per-tool guidelines
  and BEFORE "Be concise…" (system-prompt.ts:121; the bullets verbatim in the
  Specification §5 table).

## 5. herdr-agent-state.ts (the owner's, 261 lines, HERDR_INTEGRATION_VERSION=9)

Installed by herdr at `~/.pi/agent/extensions/herdr-agent-state.ts` (managed
file; auto-discovered — pi loads user-dir extensions with NO settings row,
package-manager.ts:2446-2453 + collectAutoExtensionEntries). Behavior:

- **Gate**: active iff `HERDR_ENV === "1" && HERDR_SOCKET_PATH &&
  HERDR_PANE_ID`; otherwise the module returns at construction (no socket,
  no state). TUI-only reporting: the session_start handler returns unless
  `ctx.mode === "tui"` (RPC/print are headless).
- **Socket protocol** (UNIX socket at HERDR_SOCKET_PATH; newline-terminated
  JSON request; ANY received byte = delivered): request
  `{id, method, params}` with id `herdr:pi[:session]:<Date.now()>:<base36
  rand>`; methods `pane.report_agent` (params `{pane_id, source:
  "herdr:pi", agent: "pi", state, message?, seq}` + session ref) and
  `pane.report_agent_session` (params `{pane_id, source, agent, seq,
  session_start_source?}` + session ref); `message`/`session_start_source`
  omitted when undefined (JSON.stringify drops undefined); session ref =
  `agent_session_path` (absolute session file) preferred over
  `agent_session_id`. `seq` starts at `Date.now() * 1000`, +1 per report.
  Cross-verified against the herdr 0.9.3 binary's embedded strings
  (`pane.report_agent` / `pane.report_agent_session` present — the binary
  embeds the same integration source). The protocol is thus FULLY grounded
  — no guessing; the letter's cut-to-backlog clause does NOT fire.
- **Delivery**: one attempt at 500ms timeout, ONE retry at 1500ms; errors,
  EOF, and timeouts all resolve undelivered and are swallowed (the harness
  NEVER crashes on herdr); coalescing — while a send is in flight, later
  states only queue, and only the LATEST queued state is sent.
- **State machine**: states `working | blocked | idle`; `blockedCount>0`
  (message = the blocked label) beats `agentActive` beats idle. Reports are
  deduped (same state+message skipped) except a forced publish at
  session_start. Transitions: session_start (TUI) → root session, report
  session WITH `session_start_source = reason`, force-publish (idle —
  `agentActive = ctx.isIdle() === false` = false on a fresh session);
  agent_start → report session (no source field), working; agent_settled
  with `isIdle() === true` → idle. `updateSessionRef` re-reads the session
  file/id at session_start and agent_start.
- **`herdr:blocked` channel**: consumed via the event bus
  (`pi.events.on("herdr:blocked", {active, label})` — active→count+1, label
  remembered; inactive→count−1, label cleared at 0). NO emitter exists
  anywhere today: pi core has none, pi-subagents' docs state the bridge
  "never raises herdr:blocked" (docs/extension-api.md:547), the herdr binary
  embeds only the consumer — the channel is surface for future permission
  gates. The port mirrors the channel with no native emitter (itemized).
- **tart-side event mapping**: the loop's `:agent_start` ↔ pi agent_start;
  the loop's `:agent_end` (fires on completion AND on the interrupt rescue,
  loop.rb:211-216 — pi's `_emitAgentSettled` runs in the finally, also on
  abort) ↔ pi agent_settled; session lifecycle = the surface's boot / `/new`
  / resume points (pi reasons startup/new/resume — fork and reload have no
  port surface).

## 6. Live staged-pi probe (this session — the recall-line oracle)

Offline, staged HOME + PI_CODING_AGENT_DIR + PI_OFFLINE=1, pi 1.1.0 at 120x40
(tmux), memory.ts staged BOTH ways — user-dir file
(`<agentDir>/extensions/memory.ts`) and local package (a dir with
`package.json` `{"pi":{"extensions":["./memory.ts"]}}` + settings
`packages: ["<path>"]`). BOTH load it, and BOTH render the identical header
row:

```
[Extensions]
  memory.ts
```

(pi's compact label = the extension file's basename; pi's own git-package
loads — the owner's daily driver — are `git:`-sourced and EXCLUDED from this
compact list: interactive-mode.ts:1551-1565 `isPackageSource` filters
`npm:`/`git:` only. Recorded as OQ-2.) After typing `hello` (mock URL
refused — irrelevant to the capture), the settled region shows the recall
block verbatim:

```
 hello

 [memory-recall]

 [project memory] index loaded at session start; use the memory tool (read/list) for topic files:
 - deploy (deploy.md): deploys via herdr pipeline, stage first
 - api-notes (api-notes.md): gateway streams SSE, no websockets
```

— user row first, blank, the bold `[memory-recall]` label row, blank, then
the markdown-rendered index lines (each padded one column; the bg span + fg
colors ride the styled capture; the link renders as `text (href)`), then the
assistant region. This capture is the s11 scenario's byte target.

## 7. Rig staging cost (the s9 precedent — cheap)

The runner's `stage_project_resources` pattern (runner.rb:201-250) extends
naturally: a `stage_memory: true` scenario flag stages — pi: the fixture
`memory.ts` verbatim under `<home>/pi/.pi/agent/extensions/` (auto-load, no
settings row) + `MEMORY.md` at `<home>/pi/.pi/agent/memory/pi/MEMORY.md`;
tart: the settings row `{"memory": true}` merged into
`<home>/tart/.tart/settings.json` + `MEMORY.md` at
`<home>/tart/.tart/memory/tart/MEMORY.md` (project key = basename of the
sandbox dir — the staged sandboxes carry no `.git`, so the git-root walk
falls back to the cwd basename: "pi"/"tart" per app; the staged index bytes
are identical). The mock reply is plain text; `expected_requests: 1` (the
recall rides request 1 after the user message — no extra requests).

## 8. Interpretation items (letter-resolved; judge adjudicates — OQ-1…)

- **OQ-1 — memory is OPT-IN (settings key `"memory"` bool, default false +
  env tier `<IDENTITY>_MEMORY`).** The letter says "same observable
  behavior", but the standing bar ("existing-config behavior unchanged") +
  the frozen wire-tools digest (`7360fd1e…`) + the s1–s10 battery (staged
  pi has NO memory) force memory OFF in every existing config. pi's own
  analog is load-time presence (the owner declares the package once);
  tart's is one settings row. Recommend ACCEPT.
- **OQ-2 — the [Extensions] row.** Staged pi (file or local package) shows
  `[Extensions] memory.ts`; the owner's git-package pi shows NO row
  (npm:/git: filter, interactive-mode.ts:1619-1623). tart-with-memory
  renders the row `memory.ts` (the staged-condition oracle bytes; the
  module's display label). The owner's daily-driver side-by-side diverges
  by that one row (pi-package shows none) — a load-mechanism artifact,
  itemized; reopen on owner pain. Recommend ACCEPT.
- **OQ-3 — hook-arg re-validation.** pi validates ONCE (before the hook);
  mutated args execute UNVALIDATED. The port's validate_input lives inside
  each tool body, so gate-mutated args re-validate there — a mutated-into-
  invalid arg yields the port's `{error:}` result instead of executing
  garbage. Fail-safe-only divergence, unreachable by any current consumer
  (no tool_call hook ships this iteration). Recommend ACCEPT (itemized).
- **OQ-4 — plain-event handler errors warn to stderr and swallow** (pi
  reports via emitError to an error channel the port does not carry; the
  port's mcp.rb warn+skip idiom). No screen byte moves. Recommend ACCEPT.
- **OQ-5 — herdr wire values stay pi's** (`source: "herdr:pi"`,
  `agent: "pi"`, HERDR_* env names): the identity seam is presentation-only
  (BRIEF §8) and herdr has no tart key; identical bytes keep the owner's
  panes working. Recommend ACCEPT (reopen when herdr grows tart awareness).
- **OQ-6 — the drop-in loader CUT to backlog.** BRIEF §6 sanctions "a thin
  loader over the seam for owner-authored Ruby drop-ins"; the letter's
  Shape/Gates do NOT name it, and ENTRY 6–7 (native subagents) do not need
  it. Recommend ACCEPT-as-backlog.
- **OQ-7 — blocked tool results are plain reason Strings** (pi's
  createErrorToolResult text; the port's tool interface has no isError
  channel — the text is what the model and transcript see). The memory
  tool's error results are likewise plain Strings (pi isError=true has no
  port channel; texts byte-identical). Recommend ACCEPT.
- **OQ-8 — register_command cannot shadow a builtin** (builtins dispatch
  first — pi's submit if-chain); register_tool MAY override a builtin by
  name (pi's registry merge). Both pi-faithful. Recommend ACCEPT.

## 9. Environmental carry-ins (standing)

- The s9 lane-worktree deep-path exit-1 artifact now has EIGHT judge-proven
  precedents (I34/I36/I39/I40/I42/I43/I44/I46): lane worktrees keep the
  CANONICAL short out dirs; the judge's battery runs on the integrated tree.
- The parity battery rides the I46 gate set verbatim (s1–s10, s1-tart-mode,
  both probes, wire-bodies, session-golden) — canonical out dirs.

## Specification

# Specification — I47 seam-memory

Objective: land the minimal internal extension seam — `Tart::Hooks` — with
registration-order event dispatch, the tool_call block gate, register_tool /
register_command merges, and nextTurn message injection (BRIEF §6 amended);
build the owner's memory behavior and the herdr agent-state reporter on it
natively; pin the memory-recall line's screen parity with a new rig scenario
(s11). Everything lands BEHIND the no-hook byte bar: with no module active,
today's bytes hold on screen and on the wire (the frozen digests prove it).

## 1. `Tart::Hooks` (`lib/tart/hooks.rb` — new)

One instance per interactive/print boot (constructed in `bin/tart` /
`print.rb` wiring), threaded into every `Agent::Loop` construction and the
tool/command build. Thread-safe (handlers may register from boot; dispatch
happens on the loop fiber and worker threads).

### 1.1 Event dispatch

- `on(channel, &handler)` — appends (channel = String or Symbol, normalized
  to the String form; dispatch keys off the event's `:type`/`"type"` value
  normalized the same way — the loop's symbol-keyed events and String
  channels like `"herdr:blocked"` meet on one table). Returns an
  unsubscribe Proc.
- `emit(event, context:)` — dispatches to the channel's handlers in
  REGISTRATION order; the handler list is snapshotted before dispatch
  (mid-dispatch registrations take effect on the next emit); each handler is
  called `(event, context)`; a handler error is reported ONCE to stderr
  (`warn "hooks[<channel>] handler failed: <message>"`, the mcp.rb idiom)
  and SWALLOWED — dispatch continues (pi emit, runner.ts:1089-1120; OQ-4).
  After handler dispatch the event forwards to the base sink (the surface's
  `on_agent_event`), UNCHANGED.
- The context object carries what handlers need at emission sites:
  `{cwd:, mode: ("tui"|"print"), session: {path:, id:} or nil, identity:}` —
  built by the emitter (boot wiring), re-read per event where the source
  moves (`/new` swaps the recorder).

### 1.2 The tool_call gate

- `on_tool_call(&handler)` — the `tool_call` channel with BLOCK semantics:
  handlers see `(event, context)` where event =
  `{type: "tool_call", tool_name:, tool_call_id:, input: <Hash>}`; a handler
  may MUTATE `input` in place and/or return `{block: true, reason:,
  terminate:}` (pi ToolCallEventResult). Registration order; the first
  truthy `block` WINS and ends dispatch (pi emitToolCall :1242-1262). NO
  isolation on this channel: a raised `StandardError` is caught by the gate
  and converted to a block with the error's message (an `Error` rethrown
  as-is is pi's semantics; Ruby has one StandardError family — OQ-3's
  cousin; the wrap string is NOT used since every Ruby raise carries
  .message). `RubyLLM::CancelledError` ALWAYS propagates (never blocked-on).
- **Mechanism**: `Tools::Registry.build(selected:, …, hooks: nil)` wraps every
  built tool (built-ins AND MCP) in a delegating gate object when `hooks`
  has tool_call handlers — the wrapper intercepts `call(tool_call:, **args)`
  and delegates everything else (`name`, `description`,
  `parameters_schema`, `provider_options`, `resume`, …) so the wire
  declarations stay BYTE-IDENTICAL (the tools digest `7360fd1e…` is the
  gate's regression proof). Inside the intercepted call, in pi's order
  (agent-loop.ts:711-781):
  1. `Schemas::Tools.validate(pi_name, args)` — the I43 one-seam call; a
     validation failure returns the pinned `{error:}` result WITHOUT
     dispatching handlers (pi: invalid args never reach handlers). (The
     inner tool body re-validates — the fail-safe re-validation deviation,
     OQ-3.)
  2. dispatch handlers with `input:` the splat-fresh Hash (`**args` in the
     wrapper's signature is a NEW Hash per call — the recorded ToolCall's
     arguments object is NEVER handed to handlers and NEVER mutated;
     pi's structuredClone semantics held by construction, replay bytes
     untouched).
  3. blocked → return the `reason` (or `"Tool execution was blocked"`) as a
     plain String result (OQ-7); when `terminate: true`, record
     `tool_call_id → terminate` for the batch consult.
  4. unblocked → `inner.call(**args, tool_call:)` with the (possibly
     handler-mutated) Hash.
- **Loop consult**: after each tool-batch step (`message.role == :tool` in
  `inner_loop`), the loop asks `hooks&.batch_terminate?(ids)` where ids =
  the preceding assistant message's `tool_calls.map(&:id)`; TRUE iff the
  batch is non-empty AND every call was a terminate-marked block
  (shouldTerminateToolBatch, agent-loop.ts:690-691). TRUE → break the inner
  loop (outer steering semantics unchanged). The terminate ledger clears
  per batch.
- With NO tool_call handlers registered, `Registry.build` returns the
  UNWRAPPED tools (no gate object exists — zero behavior change).

### 1.3 register_tool / register_command

- `register_tool(tool)` — takes a `RubyLLM::Tool` instance; **`Registry.build(
  …, hooks:)` performs the merge**: registered tools append AFTER built-ins
  and MCP tools (pi: extension tools append; same-name OVERRIDES — OQ-8) and
  the merged loadout passes through the §1.2 gate uniformly (one wrap, never
  two). The memory tool is the first consumer (§3).
- `register_command(name, description:, args: false, &handler)` — merged
  into the command surface: `Commands.builtin_name` matching runs FIRST
  (a registered name can never shadow a builtin — OQ-8); registered
  commands match with pi's per-command shapes (exact when `args: false`,
  prefix `"/name "` when `args: true`), dispatch in registration order, and
  list in the autocomplete (`Render::SlashSource`) and `/help`. The
  Handler consults the hooks table via an injected callable — the frozen
  `Commands::BUILTINS` table stays byte-identical. `#registered_commands`
  entries are `{name:, description:, args:}` Hashes.
- No consumer ships this iteration beyond the unit pins (both APIs are seam
  surface for ENTRY 6–7).

### 1.4 nextTurn injection + session_start

- `send_next_turn(custom_type:, content:, display: false)` — queues
  `{custom_type:, content:, display:}` (pi sendCustomMessage :2293-2331:
  no append, no events at send).
- The LOOP drains the queue at every `add_user_message`: AFTER the user
  message is added/emitted/recorded, each pending message (FIFO) is
  delivered as pi delivers it — a user-role chat message carrying the text
  (`@chat.add_message(role: :user, content:)` — pi convertToLlm :161-170),
  `emit(:message_start)` / `emit(:message_end)` carrying a
  `Hooks::CustomMessage` Struct (`role: :custom, custom_type:, content:,
  display:`), and a session `custom_message` entry (§3). Wire order
  [system…, user prompt, *customs-as-user] (pi :2086-2095).
- `session_start`: the boot wiring emits
  `{type: :session_start, reason:}` through hooks at the three surface
  points — interactive boot (`"startup"`), `/new` (`"new"`), resume
  (`"resume"`), and print boot (`"startup"`). No fork/reload (no port
  surface).
- The loop's `emit` routes through hooks when present (`hooks:` kwarg,
  default nil = today's `@on_event` path, byte-identical); the eleven-event
  vocabulary comment at loop.rb:27-33 is corrected to include
  `:compaction_start` (the Grounds §2 count correction).

## 1.5 The driven surface (exact names — the gates and the suite drive these)

- `Tart::Hooks.new(on_event: nil)` — `#on(channel, &h)` (returns unsubscribe
  Proc), `#emit(event, context:)`, `#on_tool_call(&h)`,
  `#send_next_turn(custom_type:, content:, display: false)`,
  `#register_tool(tool)`, `#register_command(name, description:,
  args: false, &h)`, `#registered_tools`, `#registered_commands`,
  `#tool_call_handlers?` (Registry's wrap predicate), `#batch_terminate?
  (ids)`, `#pending_next_turn` (the drain source, loop-internal).
- `Tart::Tools::Registry.build(…, hooks: nil)` — the kwarg threads the
  gate; `hooks.tool_call_handlers?` false (or hooks nil) = unwrapped.
- `Tart::Memory` — `Memory.register(hooks:, identity: Identity::DEFAULT)`
  (bin/tart calls it only when the resolved settings gate is on; the
  registration wires the `session_start` handler + `register_tool`), the
  store `Tart::Memory::Store.new(home:, cwd:)` with `#recall_content`
  (nil when no index), the constant `Tart::Memory::PROMPT_GUIDELINES`
  (the two bullet Strings), and `Tart::Tools::Memory.new(cwd:, home: nil)`
  (the tool; `home` nil = the resolved default — `<IDENTITY>_MEMORY_HOME`
  env else `~/.tart/memory`).
- `Tart::Herdr` — `Herdr.register(hooks:, env: ENV)` (context comes from
  each emission) and `Tart::Herdr::Reporter.new(socket_path:, timeouts:
  [500, 1500])` with `#report_session(session_ref, pane_id:, reason: nil)`
  and `#report_state(state, message: nil, session_ref: nil, pane_id:)`
  (both non-blocking; the coalescing lives here), plus the predicate
  `Herdr.enabled?(env)`. The wire constants (`SOURCE = "herdr:pi"`,
  `AGENT = "pi"`) are frozen literals.

## 2. Session plumbing (`lib/tart/agent/session.rb`)

- `Recorder#append_custom_message(custom_type:, content:, display:)` — the
  pi `CustomMessageEntry` shape verbatim:
  `{type: "custom_message", customType:, content:, display:, details: nil
  (omitted), id:, parentId: leaf, timestamp:}`; leaf advances; the persist
  gate treats a custom_message as NON-conversation-bearing (pi: only
  user/assistant/bashExecution open the file — a recall never creates a
  session file alone).
- Read path: `Session.entry_to_context_message` gains the `custom_message`
  arm → `{role: :user, content: <text>}` (the wire replay arm — resume
  re-sends the recorded recall text, pi sessionEntryToContextMessages
  :437-459); `Session.load_entries`/`Shapes` tolerate the new type with the
  existing unknown-entry skip discipline; `context_entries` includes it.
- The seven frozen session-golden digests DO NOT MOVE (no custom entries in
  their fixtures).

## 3. Native memory (`lib/tart/memory.rb` — new; tool `lib/tart/tools/memory.rb` — new)

**Gate**: resolved settings key `"memory"` (bool; DEFAULTS gains
`"memory" => false`; env tier `<IDENTITY>_MEMORY` via RESOLUTION_ENV —
pi-mode `PI_MEMORY`, tart-mode `TART_MEMORY`; OQ-1). Off (default) → the
module never registers: no tool, no injection, no MOTD row — today's bytes.
On → register into hooks at boot (interactive + print) exactly as the
owner's pi loads memory every session.

**Store**: home = `<IDENTITY>_MEMORY_HOME` env or `~/.tart/memory` (the
agent root; pi's `~/.pi/agent/memory` → `~/.tart/memory` under the I09
mapping); project dir = `<home>/<project key>` where project key =
basename of the git root (walk up for a `.git` FILE or dir) else basename
of cwd; index `MEMORY.md`. Every constant, bound, slug rule, error string,
file format, and index-line rule is memory.ts verbatim (Groundings §4 is
the contract table — RECALL_MAX_LINES 200, RECALL_MAX_BYTES 25_600 with
line cost bytes+1, SUMMARY_MAX_CHARS 120 with the 119+`…` truncation, the
exact topic-validation strings and slug regex, the save file
`---\nmodified: <ISO8601>\n---\n\n<trimmed>\n`, the upsert semantics, and
the read/list behaviors).

**Recall**: a `session_start` handler (any reason) reads the project index;
missing → no-op; else the bounded content (header + index + optional
truncation notice, joined with "\n") goes out as
`send_next_turn(custom_type: "memory-recall", content:, display: true)` —
once per session_start.

**The tool** (`Tart::Tools::Memory < RubyLLM::Tool`, wire name `"memory"`):
parameters schema JSON EXACTLY the Grounds §4 TypeBox object (property
order action/topic/text; anyOf consts); description byte-exact; results
plain Strings (OQ-7); register via `hooks.register_tool` → declared LAST
in the tools array (after built-ins + MCP). Renders/records through the
existing tool-result paths.

**System prompt**: `SystemPrompt.sections/build` gain
`prompt_guidelines: []` — appended to `<rules>` AFTER per-tool guideline
bullets, BEFORE "Be concise in your responses" (dedup/trim per build_rules;
pi system-prompt.ts:121). Memory-on passes its two bullets verbatim
(memory.ts): `"Use the memory tool to save durable facts, user
preferences, and corrections worth carrying to future sessions — never
secrets and never one-off task state."` and `"Use the memory tool
list/read actions to recall saved topics on demand instead of guessing
what was remembered."` NO `<tools>` snippet row (memory has no
promptSnippet). Memory-off → `[]` → today's bytes.

**MOTD row**: memory-on adds `"memory.ts"` to the `[Extensions]` compact
list (sorted, comma-joined, merged with MCP server names — bin/tart's
`extensions:` argument; OQ-2). The herdr module adds `"herdr-agent-state"`
iff its env gate is on (§4a). Memory-off, herdr-off → today's row.

## 4. Native herdr (`lib/tart/herdr.rb` — new)

Registered at boot in BOTH modes (pi loads the file regardless); all
reporting gates on mode/context per the extension:

- **Env gate**: `HERDR_ENV == "1" && HERDR_SOCKET_PATH && HERDR_PANE_ID`
  (exact names, herdr's own namespace — never renamed). Off → the module
  registers but every handler returns immediately (no socket, no state).
- **Socket reporter** (a small inner class; timeouts injectable with pi's
  500/1500ms defaults — test seam only): connect to the UNIX socket,
  write `JSON.generate(request) + "\n"`, ANY read byte → delivered;
  error/EOF/timeout → undelivered; one attempt then ONE retry; failures
  swallowed; sends run OFF the reactor (a background thread; the UI never
  blocks).
- **Requests** (byte-pinned): `{id: "herdr:pi<:session>:<epoch_ms>:<rand36>",
  method: "pane.report_agent" | "pane.report_agent_session", params:
  {pane_id:, source: "herdr:pi", agent: "pi", …}}` — state reports add
  `{state:, seq:}` and `message:` only when present; session reports add
  `{seq:, session_start_source: <reason>}` only at session_start; every
  request carries the session ref `agent_session_path:` (absolute file,
  preferred) else `agent_session_id:`; `seq` = `Time.now.to_i * 1000` base,
  +1 per report, monotonic across the process (OQ-5 keeps pi's values).
- **State machine**: `working|blocked|idle`; blocked (count > 0, message =
  label) > working > idle; dedup same state+message; force at
  session_start; coalescing = latest-wins queue drained by one in-flight
  sender.
- **Transitions** (via hooks events, Groundings §5 mapping):
  `session_start` with mode "tui" → root session, report session (with
  `session_start_source`), re-read session ref, force-publish idle;
  `agent_start` → re-read ref, report session, working; `agent_end` →
  idle. Print mode: the session_start handler returns before rooting (no
  reports ever — pi's TUI-only gate).
- **Channel**: subscribes `"herdr:blocked"` `{active:, label:}` → count
  ++/--, label at 0 clears. NO emitter this iteration (pi-side none
  either — Groundings §5); the channel is exercised by unit pins through
  `hooks.emit` directly.

## 5. The recall render (`lib/tart/render/transcript.rb` + `chat.rb`)

- `Transcript#enqueue_custom_block(custom_type, content)` — pi
  CustomMessageComponent (custom-message.ts:41-115): one blank row
  (Spacer), then the block — rows styled `custom_message_bg` over the
  block width, first row the bold `[memory-recall]` label in
  `custom_message_label`, a blank block row, then the content rendered
  through the existing markdown path in `custom_message_text` (the Grounds
  §6 capture is the row shape: each content line padded one column; links
  render `text (href)`); the block ends with a blank row. The Grounds §6
  probe is the oracle; the s11 gate is the byte judge (plain + styled).
- `Chat#on_agent_event` gains the `:message_end` arm for
  `message.role == :custom` (and `:message_start` for it) → the enqueue
  above; assistant/user arms untouched.
- Replay: `Transcript#replay_entry` gains the `custom_message` arm → the
  same block (resume renders the recorded recall; pi renders it from the
  session entries).

## 6. Rig — scenario s11 (`gems/tui-split-rig/`)

- `scenarios/s11_memory_recall.yml`: `prompt: "hello"`,
  `expected_requests: 1`, one plain-text stream reply,
  `stage_memory: true`.
- Runner staging (`stage_memory`): pi — write the fixture
  `fixtures/memory.ts` VERBATIM (a byte copy of the owner's memory.ts,
  committed under the rig's fixtures) to
  `<home>/pi/.pi/agent/extensions/memory.ts`; write the fixed index
  (runner constant, the Grounds §6 two-topic bytes) to
  `<home>/pi/.pi/agent/memory/pi/MEMORY.md`. tart — merge
  `{"memory": true}` into `<home>/tart/.tart/settings.json` (coexisting
  with any compaction staging) and the same index bytes to
  `<home>/tart/.tart/memory/tart/MEMORY.md`. No registry.yml class is
  added — the recall row/block bytes are the gate, not a sanctioned
  difference.
- Scenario/runner unit pins (scenario_test.rb additive): the flag parses;
  the staging writes both apps' files (paths asserted).
- The gate is RED at base BY DESIGN (tart renders no recall block; pi
  does) — GREEN only on the integrated tree.

## 7. Docs (README.md)

A `## Memory` paragraph (the settings row + env tier, the store layout,
the recall line, the opt-in default-off) and a `## Herdr` paragraph (the
three env vars, the socket protocol summary, the TUI-only gate, the
pi-valued wire fields). No other doc surface moves.

## 8. Tests (the pin table)

NEW `test/hooks_test.rb`: dispatch order; snapshot-during-dispatch;
per-handler isolation (plain channels) + the warn; tool_call — block wins
first, reason default, terminate recording, handler-error fail-safe,
CancelledError propagation, recorded-args isolation (the ToolCall's
arguments hash never mutated), validation-first (invalid args never reach
handlers), mutation flows into execution, wrapper declarations
byte-identical (name/description/parameters/provider_options vs the
unwrapped tool), register_tool append/override, register_command dispatch
order + no-shadow, batch_terminate? (all/none/some).
NEW `test/memory_test.rb`: every §3 contract row (slugify table, the five
topic errors, save file bytes + index upsert/dedup/order, read/list,
recall bounds incl. the exact 200-line and 25KB edges + truncation
notice, recall no-op without index, the declaration JSON byte-exact, the
guidelines bullets, TART/PI memory-home env tiers, the settings gate
off/on).
NEW `test/herdr_test.rb`: env gate off inert; enabled + fake UNIXServer —
session_start/agent_start/agent_end request shapes (params, omitted-nil
keys, id format, seq monotonic), state dedup + force, blocked channel
count/label/clear, coalescing latest-wins, retry-once on silent socket,
TUI-only (print mode roots nothing).
ADDITIVE pins: `agent_loop_test.rb` (nextTurn drain order/emit/record +
wire user-message order via MockLLM; terminate breaks the inner loop —
requests count; hooks-off byte-identity), `session_test.rb`
(append_custom_message entry shape + leaf chain + non-conversation gate +
context_messages custom arm + resume replay), `commands_test.rb`
(registered command dispatch + autocomplete listing),
`settings_test.rb` (the memory row: DEFAULTS false, env tier, unknown-key
list gains memory), `system_prompt_test.rb` (guidelines placement),
`test/render/transcript_test.rb` (the custom block rows/styles + replay
arm). Rig: `gems/tui-split-rig/test/scenario_test.rb` additive.

## 9. May touch (the ```lanes block is the frozen source of truth)

Lane `core` (repo tart): the seam, memory, herdr, session/loop/registry/
commands/settings/system-prompt edits, render arms, boot threading, docs,
the core test pins.
Lane `rig` (repo tart): the scenario, runner/scenario staging, the
fixture, the rig test pins. DISJOINT from `core` (no shared file).

**Must not touch**: `lib/tart/schemas/**` + `schemas.rb`,
`lib/tart/shapes/**` + `shapes.rb`, `lib/tart/models.rb`,
`lib/tart/agent/{bridge,status,context_files}.rb`, `lib/tart/compaction.rb`,
`lib/tart/tools/{bash,edit,find,grep,ls,read,write}.rb` +
`safe_execute.rb` + `output_accumulator.rb` + `support/**` (the seven
built-ins' bodies stay frozen — the gate wraps, it never edits them),
`lib/tart/mcp*`, `lib/tart/render/**` outside the two enumerated seams
(transcript enqueue/replay arms; chat on_agent_event arm + the extensions
row data threading — no other chat.rb method),
`lib/tart/{identity,skills,prompts,theme,tui}.rb`, `lib/tart/core/**`,
`tart.gemspec`, `Gemfile.lock`, `bench/**`, `test/support/**`, and every
test file outside the declared set (frozen: `print_test.rb`,
`e2e_session_test.rb`, `golden_parity_test.rb`, `loop_test.rb`,
`tools_test.rb`, `bash_tool_test.rb`, `mcp_test.rb`, `flow_test.rb`,
`markdown_test.rb`, `theme_test.rb`, `tui_test.rb`,
`launcher_smoke_test.rb`, `kernel_carryin_test.rb`, `identity_test.rb`,
`prompts_test.rb`, `compaction_test.rb`, `skills_test.rb`,
`chat_test.rb`, `models_test.rb`, `test/render/**` outside
transcript_test.rb, `test/fixtures/**`).

**Out of scope** (itemized, not lost): the drop-in `.rb` loader (OQ-6,
backlog); `tool_result` / `message_end`-replacement hooks (pi surfaces the
BRIEF §6 cap keeps off the minimal seam); a herdr:blocked EMITTER (none
exists pi-side); renderer/provider/jiti registration surfaces (perma-
capped per BRIEF §6); any change to the herdr tool itself; fork/reload
session reasons.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/hooks.rb
    - lib/tart/memory.rb
    - lib/tart/herdr.rb
    - lib/tart/tools/memory.rb
    - lib/tart/tools/registry.rb
    - lib/tart/commands.rb
    - lib/tart/settings.rb
    - lib/tart/agent/loop.rb
    - lib/tart/agent/session.rb
    - lib/tart/agent/system_prompt.rb
    - lib/tart/print.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - bin/tart
    - README.md
    - test/hooks_test.rb
    - test/memory_test.rb
    - test/herdr_test.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
    - test/commands_test.rb
    - test/settings_test.rb
    - test/system_prompt_test.rb
    - test/render/transcript_test.rb
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/scenarios/s11_memory_recall.yml
    - gems/tui-split-rig/fixtures/memory.ts
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/test/scenario_test.rb
```

Two lanes: `core` owns every tart source/test file the seam touches;
`rig` owns the rig tree only — disjoint by construction, the I17/I18/I20
core+rig precedent. The s11 gate is the rig lane's deliverable evaluated
on the INTEGRATED tree (RED at base by design, both lanes' base).

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
`architect rehearse seam-memory` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze seam-memory` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse seam-memory` — before the freeze, while
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
subsection per lane. A copy is written to build/I47-seam-memory-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section seam-memory prompt --append --lane <lane> --from build/I47-seam-memory-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I47-seam-memory-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence seam-memory --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section seam-memory verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify seam-memory`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
