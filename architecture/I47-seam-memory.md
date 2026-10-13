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

# Acceptance Criteria — I47 seam-memory

Gate calibration (pre-declared): **RED at base BY DESIGN** — `hooks-semantics`
(`Tart::Hooks` does not exist at cac2612 — NameError is the expected clean
red), `memory-module` (same), `herdr-reporter` (same),
`s11-recall-parity` (the scenario file does not exist at base; on any
pre-integration tree tart renders no recall block while staged pi does).
They must be GREEN on the integrated tree, non-vacuously.
**Regression guards (GREEN at base, must stay GREEN)** — `suite`, `bench`,
`s1`–`s10`, `s1-tart-mode`, both probe gates, `wire-bodies`,
`session-golden` (the fireworks wire request bodies + tool declarations +
the seven session digests ARE the zero-behavior bar for existing configs:
with no module active — the default — a post-build failure means a byte
moved). The s-gates keep the CANONICAL short out dirs. The KNOWN s9
lane-worktree deep-path artifact (eight judge-proven precedents:
I34/I36/I39/I40/I42/I43/I44/I46) does not fail this iteration when the
same tree exits 0 at canonical depth — the judge runs the battery on the
integrated tree. `scope` is vacuously OK at base (empty diff vs cac2612)
and MUST be non-vacuous on the integrated run.

**AC1 (the seam lands — `Tart::Hooks`).** Event dispatch in registration
order with a pre-dispatch handler snapshot; per-handler error isolation on
plain channels (warn to stderr, dispatch continues); arbitrary channel
names. The tool_call gate: validation runs FIRST (invalid args return the
pinned `{error:}` result and handlers NEVER see the call), handlers may
mutate the call's input Hash in place (a splat-fresh copy — the recorded
`ToolCall#arguments` object is provably never mutated), `{block:, reason:,
terminate:}` results block with the reason as a plain String (default
`"Tool execution was blocked"`), the first block wins, a handler
`StandardError` blocks fail-safe with the error message, and
`RubyLLM::CancelledError` always propagates; mutated args flow into
execution; the wrapper preserves declaration bytes (name/description/
parameters/provider_options identical to the unwrapped tool — the
`7360fd1e…` digest holds); with no tool_call handlers the registry returns
UNWRAPPED tools. `register_tool` appends/overrides; `register_command`
registers dispatchable commands that cannot shadow builtins. nextTurn
injection: `send_next_turn` queues; the loop drains AFTER the user message
(emit order user→custom, session record order user→custom, wire order
[user, custom-as-user-text]); `session_start` emits at boot/`/new`/resume/
print-boot with pi's reasons. Pinned by `hooks-semantics` + the suite's
hooks pins.

**AC2 (the memory module — the owner's observable behavior).** Gated by
the settings key `"memory"` (DEFAULTS false + `<IDENTITY>_MEMORY` env
tier) — OFF by default leaves every existing byte unchanged (wire
declarations, system prompt, MOTD row, requests). ON: the store under
`<IDENTITY>_MEMORY_HOME || ~/.tart/memory/<project-key>/` (git-root walk,
basename fallback) with memory.ts's exact constants, slug rules, error
strings, save-file bytes, index-upsert semantics, and read/list behavior;
`session_start` → the bounded recall (200 lines AND 25KB, header + index +
truncation notice) injected as the `memory-recall` nextTurn message
(display true); the `memory` tool declared LAST with the pinned TypeBox
parameters JSON and description, plain-String results; the two
promptGuidelines bullets in `<rules>` before "Be concise…" and NO `<tools>`
snippet row; the `[Extensions] memory.ts` MOTD row (OQ-2); the recall
block rendered per the Grounds §6 oracle (blank, bold `[memory-recall]`
label, blank, markdown rows on `custom_message_bg`) live and on replay;
the session `custom_message` entry recorded and replayed as user-role text
on resume. Pinned by `memory-module` + the suite's memory pins.

**AC3 (the herdr reporter, natively).** The full Grounds §5 contract:
three-var env gate (exact HERDR_* names; off = inert), the UNIX-socket
protocol byte-pinned (`pane.report_agent` / `pane.report_agent_session`,
`herdr:pi` ids, pi-valued `source`/`agent` — OQ-5, `agent_session_path`
preferred over id, nil keys omitted, monotonic seq), 500→1500 retry with
failures swallowed and never blocking the UI, latest-wins coalescing, the
working/blocked/idle state machine with dedup + the forced session_start
publish, the `herdr:blocked` channel subscription (no emitter — itemized),
and the TUI-only gate (print mode roots nothing). Pinned by
`herdr-reporter` + the suite's herdr pins.

**AC4 (parity + regression + scope).** The default rake task fully green
(run count > 886 with the new pins; the one base skip unchanged);
`SEAM_BENCH_OK`; s1–s10 exit 0 cold at the canonical out dirs;
`s1-tart-mode` completes (TART_MODE_OK); both probe gates OK;
`WIRE_BODIES_OK`; `SESSION_GOLDEN_OK`; the NEW s11 memory-recall scenario
exits 0 cold (the recall-line parity gate — plain and styled captures
byte-clean against staged pi running the owner's memory.ts verbatim); the
integrated diff vs **cac2612** touches EXACTLY the two lanes' declared
file sets — nothing in `schemas/**`, `shapes/**`, `models.rb`,
`compaction.rb`, the seven built-in tool bodies, `mcp*`, `core/**`,
`identity/skills/prompts/theme/tui`, gemspec/lock/bench, or any test file
outside the declared set.

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
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s11-recall-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s11_memory_recall.yml --out tmp/parity-gate-s11
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i47-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i47-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i47-wire && gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i47-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i47-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i47-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i47-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: hooks-semantics
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; require "tmpdir"; require "fileutils"; require "json"; order = []; hooks = Tart::Hooks.new; hooks.on("custom") { order << 1 }; hooks.on("custom") { raise "boom" }; hooks.on("custom") { order << 3 }; hooks.emit({"type" => "custom"}, context: {cwd: Dir.pwd, mode: "tui"}); abort "isolation/order broken: #{order.inspect}" unless order == [1, 3]; un = hooks.on("custom") { order << 99 }; un.call; hooks.emit({"type" => "custom"}, context: {cwd: Dir.pwd, mode: "tui"}); abort "unsubscribe broken: #{order.inspect}" unless order == [1, 3]; dir = Dir.mktmpdir("i47-hk-"); File.write(File.join(dir, "a.txt"), "A-CONTENT"); File.write(File.join(dir, "b.txt"), "B-CONTENT"); gate = Tart::Hooks.new; seen = []; gate.on_tool_call { |event, _ctx| seen << event["tool_name"]; {block: true, reason: "denied by policy"} }; wtools = Tart::Tools::Registry.build(selected: %w[write], cwd: dir, hooks: gate); res = wtools["write"].call(path: "new.txt", content: "x"); abort "block result must be the plain reason String: #{res.inspect}" unless res == "denied by policy"; abort "blocked write must not create the file" if File.exist?(File.join(dir, "new.txt")); abort "handler must have seen the call: #{seen.inspect}" unless seen == ["write"]; dflt = Tart::Hooks.new; dflt.on_tool_call { |_e, _c| {block: true} }; rtools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: dflt); res2 = rtools["read"].call(path: "a.txt"); abort "default reason: #{res2.inspect}" unless res2 == "Tool execution was blocked"; errs = Tart::Hooks.new; errs.on_tool_call { |_e, _c| raise StandardError, "gate broke" }; etools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: errs); res3 = etools["read"].call(path: "a.txt"); abort "handler error must block fail-safe with the message: #{res3.inspect}" unless res3 == "gate broke"; mut = Tart::Hooks.new; mut.on_tool_call { |event, _ctx| event["input"]["path"] = "b.txt"; nil }; mtools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: mut); tc = RubyLLM::ToolCall.new(id: "c1", name: "read", arguments: {"path" => "a.txt"}); res4 = mtools["read"].call(path: "a.txt", tool_call: tc); abort "mutation must flow into execution: #{res4.inspect}" unless res4.to_s.include?("B-CONTENT"); abort "recorded ToolCall arguments must never mutate: #{tc.arguments.inspect}" unless tc.arguments == {"path" => "a.txt"}; vf = Tart::Hooks.new; vfcount = 0; vf.on_tool_call { |_e, _c| vfcount += 1 }; vtools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: vf); res5 = vtools["read"].call(path: 123); abort "invalid args must return the {error:} result: #{res5.inspect}" unless res5.is_a?(Hash) && res5[:error]; abort "invalid args must never reach handlers: #{vfcount}" unless vfcount.zero?; cc = Tart::Hooks.new; cc.on_tool_call { |_e, _c| raise RubyLLM::CancelledError }; ctools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: cc); propagated = false; begin; ctools["read"].call(path: "a.txt"); rescue RubyLLM::CancelledError; propagated = true; end; abort "CancelledError must propagate" unless propagated; bare = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: Tart::Hooks.new); abort "no-handler build must stay unwrapped: #{bare["read"].class}" unless bare["read"].is_a?(Tart::Tools::Read); t0 = Tart::Tools::Read.new(cwd: dir); wrapped = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: mut)["read"]; abort "declaration bytes must survive wrapping: name" unless wrapped.name == t0.name && wrapped.description == t0.description; abort "declaration bytes must survive wrapping: parameters" unless JSON.generate(wrapped.parameters_schema) == JSON.generate(t0.parameters_schema); term = Tart::Hooks.new; term.on_tool_call { |_e, _c| {block: true, reason: "t", terminate: true} }; ttools = Tart::Tools::Registry.build(selected: %w[read], cwd: dir, hooks: term); ttools["read"].call(path: "a.txt", tool_call: RubyLLM::ToolCall.new(id: "x1", name: "read", arguments: {"path" => "a.txt"})); ttools["read"].call(path: "a.txt", tool_call: RubyLLM::ToolCall.new(id: "x2", name: "read", arguments: {"path" => "a.txt"})); abort "terminate all" unless term.batch_terminate?(%w[x1 x2]); abort "terminate partial" if term.batch_terminate?(%w[x1 y9]); abort "terminate empty" if term.batch_terminate?([]); rt = Tart::Tools::Read.new(cwd: dir); hooks5 = Tart::Hooks.new; hooks5.register_tool(rt); hooks5.register_command("mem", description: "d") {}; abort "register_tool surface: #{hooks5.registered_tools.inspect}" unless hooks5.registered_tools == [rt]; abort "register_command surface: #{hooks5.registered_commands.inspect}" unless hooks5.registered_commands.length == 1 && hooks5.registered_commands[0][:name] == "mem"; server = MockLLMServer.new.start; server.script([{type: :message, content: "ok"}]); RubyLLM.configure { |c| c.openai_api_key = "test"; c.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; lh = Tart::Hooks.new; lh.send_next_turn(custom_type: "memory-recall", content: "RECALL-TEXT", display: true); recdir = Dir.mktmpdir("i47-hk-rec"); recorder = Tart::Agent::Session::Recorder.new(cwd: recdir, root: File.join(recdir, "agent")); agent = Tart::Agent::Loop.new(chat: RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true), tools: Tart::Tools::Registry.build(selected: %w[read], cwd: dir), hooks: lh, recorder: recorder); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("hi") }; msgs = server.captured_requests.first["body"]["messages"]; text = lambda { |m| c = m["content"]; c.is_a?(Array) ? c.map { |p| p.is_a?(Hash) ? p["text"].to_s : p.to_s }.join : c.to_s }; pairs = msgs.map { |m| [m["role"], text.call(m)] }; abort "wire order must be [user prompt, custom-as-user]: #{pairs.inspect}" unless pairs == [["user", "hi"], ["user", "RECALL-TEXT"]]; lines = File.readlines(recorder.path).map { |l| JSON.parse(l) }; types = lines.map { |e| e["type"] == "message" ? e.dig("message", "role") : e["type"] }; abort "session entry order: #{types.inspect}" unless types == ["session", "user", "custom_message", "assistant"]; cm = lines[2]; abort "custom_message entry shape: #{cm.inspect}" unless cm["customType"] == "memory-recall" && cm["content"] == "RECALL-TEXT" && cm["display"] == true; server2 = MockLLMServer.new.start; server2.script([{type: :message, content: "ok"}]); RubyLLM.configure { |c| c.openai_api_key = "test"; c.openai_api_base = "http://127.0.0.1:#{server2.port}/v1" }; agent2 = Tart::Agent::Loop.new(chat: RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true), tools: Tart::Tools::Registry.build(selected: %w[read], cwd: dir)); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent2.run("hi") }; msgs2 = server2.captured_requests.first["body"]["messages"]; abort "hooks-nil must carry only the user message: #{msgs2.map { |m| m["role"] }.inspect}" unless msgs2.map { |m| m["role"] } == ["user"]; server.stop; server2.stop; FileUtils.rm_rf(dir); puts "HOOKS_SEMANTICS_OK"'
  expect:
    exit_code: 0
    stdout_match: HOOKS_SEMANTICS_OK

- id: memory-module
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; require "tmpdir"; require "fileutils"; require "json"; home = Dir.mktmpdir("i47-mh-"); cwd = Dir.mktmpdir("i47-mc-"); ENV["PI_MEMORY_HOME"] = home; store = Tart::Memory::Store.new(home: home, cwd: cwd); abort "no index must mean nil recall" unless store.recall_content.nil?; tool = Tart::Tools::Memory.new(cwd: cwd); proj = File.join(home, File.basename(cwd)); r = tool.call(action: "save", topic: "Deploy Ops!", text: "deploys via herdr pipeline, stage first\nsecond line"); abort "save result: #{r.inspect}" unless r == %(Saved memory topic "Deploy Ops!" (deploy-ops.md).); saved = File.read(File.join(proj, "deploy-ops.md")); abort "save file bytes: #{saved.inspect}" unless saved.match?(/\A---\nmodified: \d{4}-\d{2}-\d{2}T[^\n]+\n---\n\ndeploys via herdr pipeline, stage first\nsecond line\n\z/); index = File.join(proj, "MEMORY.md"); idx = File.read(index); abort "index line: #{idx.inspect}" unless idx == "- [Deploy Ops!](deploy-ops.md): deploys via herdr pipeline, stage first\n"; abort "read: #{tool.call(action: "read", topic: "deploy-ops").inspect}" unless tool.call(action: "read", topic: "deploy-ops") == saved; abort "read missing" unless tool.call(action: "read", topic: "nope") == %(No memory saved for topic "nope" (nope.md). Use the memory tool list action to see saved topics.); abort "list" unless tool.call(action: "list") == idx; abort "save-no-topic" unless tool.call(action: "save") == "The memory tool save action needs a topic."; abort "save-no-text" unless tool.call(action: "save", topic: "x") == "The memory tool save action needs text to remember."; abort "read-no-topic" unless tool.call(action: "read") == "The memory tool read action needs a topic."; abort "absolute topic" unless tool.call(action: "save", topic: "/etc/x", text: "x") == %(Invalid topic "/etc/x": topics are plain names inside the project memory directory, not paths.); abort "dotdot topic" unless tool.call(action: "save", topic: "../evil", text: "x") == %(Invalid topic "../evil": topics are plain names inside the project memory directory, not paths.); abort "bad slug" unless tool.call(action: "save", topic: "!!!", text: "x") == %(Invalid topic "!!!": it must be a plain name like "deploy" (letters, numbers, dashes).); File.write(index, (1..205).map { |i| "- [t#{i}](t#{i}.md): line #{i}" }.join("\n") << "\n"); content = store.recall_content; cl = content.lines; abort "bound line count: #{cl.size}" unless cl.size == 202; abort "header" unless cl[0] == "[project memory] index loaded at session start; use the memory tool (read/list) for topic files:\n"; abort "notice" unless cl[-1] == "[project memory] index is truncated; more entries exist — use the memory tool list action.\n"; abort "first kept" unless cl[1] == "- [t1](t1.md): line 1\n"; abort "last kept" unless cl[200] == "- [t200](t200.md): line 200\n"; big = (1..3).map { |i| "- [b#{i}](b#{i}.md): #{("x" * 10_000)}" }; File.write(index, big.join("\n") << "\n"); content2 = store.recall_content; abort "byte bound keeps whole lines only: #{content2.lines.size}" unless content2.lines.size == 3; abort "truncated after byte bound" unless content2.lines[-1] == "[project memory] index is truncated; more entries exist — use the memory tool list action.\n"; abort "DEFAULTS memory must be false" unless Tart::Settings::DEFAULTS["memory"] == false; abort "env tier row" unless Tart::Settings::RESOLUTION_ENV["memory"] == "MEMORY"; prompt = Tart::Agent::SystemPrompt.build(selected_tools: %w[read bash edit write memory], cwd: cwd, prompt_guidelines: Tart::Memory::PROMPT_GUIDELINES); rules = prompt[/.*<rules>\n(.*?)\n<\/rules>/m, 1].to_s.lines.map(&:strip); gi = rules.index { |l| l.start_with?("- Use the memory tool to save durable facts") }; abort "guidelines bullet 1 present: #{rules.inspect}" if gi.nil?; abort "guidelines placement" unless rules[gi + 1]&.start_with?("- Use the memory tool list/read actions") && rules[gi + 2] == "- Be concise in your responses"; abort "no tools snippet row" if prompt.include?("- memory:"); plain_prompt = Tart::Agent::SystemPrompt.build(selected_tools: %w[read bash edit write], cwd: cwd); abort "plain prompt must keep the port built-ins out of the snippet list" if plain_prompt.include?("memory"); server = MockLLMServer.new.start; server.script([{type: :message, content: "ok"}]); RubyLLM.configure { |c| c.openai_api_key = "test"; c.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; hooks = Tart::Hooks.new; Tart::Memory.register(hooks: hooks); tools = Tart::Tools::Registry.build(selected: %w[read], cwd: cwd, hooks: hooks); abort "memory tool must merge into the loadout: #{tools.keys.inspect}" unless tools.keys == %w[read memory]; hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {cwd: cwd, mode: "tui"}); agent = Tart::Agent::Loop.new(chat: RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true), tools: tools, hooks: hooks); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("hello") }; body = server.captured_requests.first["body"]; decls = body["tools"]; abort "memory declared last: #{decls.map { |d| d.dig("function", "name") }.inspect}" unless decls.last.dig("function", "name") == "memory"; expected = {"type" => "function", "function" => {"name" => "memory", "description" => "Persistent per-project memory. Save durable facts, preferences, and corrections worth carrying to future sessions — never secrets, never one-off task state. Topic files are read on demand.", "parameters" => {"type" => "object", "required" => ["action"], "properties" => {"action" => {"anyOf" => [{"type" => "string", "const" => "save"}, {"type" => "string", "const" => "read"}, {"type" => "string", "const" => "list"}], "description" => "save: store text under topic; read: return a topic file; list: return the index"}, "topic" => {"type" => "string", "description" => "Topic name, e.g. deploy (required for save/read)"}, "text" => {"type" => "string", "description" => "Text to remember (save only)"}}}}}; abort "declaration bytes: #{JSON.generate(decls.last)}" unless JSON.generate(decls.last) == JSON.generate(expected); msgs = body["messages"]; text = lambda { |m| c = m["content"]; c.is_a?(Array) ? c.map { |p| p.is_a?(Hash) ? p["text"].to_s : p.to_s }.join : c.to_s }; abort "recall rides the wire after the prompt: #{msgs.map { |m| m["role"] }.inspect}" unless msgs.length == 2 && msgs[0]["role"] == "user" && text.call(msgs[0]) == "hello" && msgs[1]["role"] == "user" && text.call(msgs[1]).start_with?("[project memory] index loaded at session start"); server.stop; FileUtils.rm_rf(home); FileUtils.rm_rf(cwd); puts "MEMORY_MODULE_OK"'
  expect:
    exit_code: 0
    stdout_match: MEMORY_MODULE_OK

- id: herdr-reporter
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "fileutils"; require "json"; require "socket"; dir = Dir.mktmpdir("i47-hd-"); sock = File.join(dir, "h.sock"); server = UNIXServer.new(sock); on_env = {"HERDR_ENV" => "1", "HERDR_SOCKET_PATH" => sock, "HERDR_PANE_ID" => "p7"}; abort "enabled? must pass the full env" unless Tart::Herdr.enabled?(on_env); abort "enabled? must fail without HERDR_ENV" if Tart::Herdr.enabled?({"HERDR_ENV" => "1", "HERDR_SOCKET_PATH" => sock}); abort "enabled? must fail without the socket path" if Tart::Herdr.enabled?({"HERDR_ENV" => "1", "HERDR_PANE_ID" => "p7"}); read_one = lambda { client = server.accept; line = client.gets; client.write("ok"); client.close; JSON.parse(line) }; quiet = lambda { IO.select([server], nil, nil, 0.2).nil? }; rep = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [20, 20]); ref = {"agent_session_path" => "/tmp/s.json"}; rep.report_session(ref, pane_id: "p7", reason: "startup"); r1 = read_one.call; abort "session method: #{r1.inspect}" unless r1["method"] == "pane.report_agent_session" && r1["id"].start_with?("herdr:pi:session:"); p1 = r1["params"]; abort "session params: #{p1.inspect}" unless p1["pane_id"] == "p7" && p1["source"] == "herdr:pi" && p1["agent"] == "pi" && p1["session_start_source"] == "startup" && p1["agent_session_path"] == "/tmp/s.json" && p1["seq"].is_a?(Integer); rep.report_session(ref, pane_id: "p7"); r2 = read_one.call; abort "agent_start session report omits session_start_source: #{r2.inspect}" if r2["params"].key?("session_start_source"); rep.report_state("working", session_ref: ref, pane_id: "p7"); r3 = read_one.call; abort "state report: #{r3.inspect}" unless r3["method"] == "pane.report_agent" && r3["params"]["state"] == "working" && !r3["params"].key?("message") && r3["params"]["seq"] > p1["seq"]; rep.report_state("blocked", message: "needs approval", session_ref: ref, pane_id: "p7"); r4 = read_one.call; abort "blocked report: #{r4.inspect}" unless r4["params"]["state"] == "blocked" && r4["params"]["message"] == "needs approval"; rep.report_state("working", session_ref: ref, pane_id: "p7"); read_one.call; rep.report_state("working", session_ref: ref, pane_id: "p7"); rep.report_state("working", session_ref: ref, pane_id: "p7"); abort "deduped same-state reports must not connect" unless quiet.call; dead = Tart::Herdr::Reporter.new(socket_path: File.join(dir, "missing.sock"), timeouts: [20, 20]); dead.report_state("idle", session_ref: ref, pane_id: "p7"); dead.report_session(ref, pane_id: "p7"); abort "socket failures must be swallowed"; hooks = Tart::Hooks.new; Tart::Herdr.register(hooks: hooks, env: on_env); ctx = {cwd: dir, mode: "tui", session: ref, identity: "pi"}; hooks.emit({"type" => "session_start", "reason" => "resume"}, context: ctx); s1 = read_one.call; s2 = read_one.call; abort "integration session report" unless s1["method"] == "pane.report_agent_session" && s1["params"]["session_start_source"] == "resume"; abort "forced idle publish at session_start: #{s2.inspect}" unless s2["method"] == "pane.report_agent" && s2["params"]["state"] == "idle" && !s2["params"].key?("message"); hooks.emit({"type" => "agent_start"}, context: ctx); a1 = read_one.call; a2 = read_one.call; abort "agent_start working" unless a1["method"] == "pane.report_agent_session" && a2["params"]["state"] == "working"; hooks.emit({"type" => "herdr:blocked", "active" => true, "label" => "ask user"}, context: ctx); b1 = read_one.call; abort "blocked channel" unless b1["params"]["state"] == "blocked" && b1["params"]["message"] == "ask user"; hooks.emit({"type" => "herdr:blocked", "active" => false}, context: ctx); b2 = read_one.call; abort "unblocked returns to working" unless b2["params"]["state"] == "working" && !b2["params"].key?("message"); hooks.emit({"type" => "agent_end", "interrupted" => false, "messages" => []}, context: ctx); e1 = read_one.call; abort "agent_end idle" unless e1["params"]["state"] == "idle"; hooks2 = Tart::Hooks.new; Tart::Herdr.register(hooks: hooks2, env: {"HERDR_ENV" => "1", "HERDR_SOCKET_PATH" => sock, "HERDR_PANE_ID" => "p7"}); pctx = {cwd: dir, mode: "print", session: ref, identity: "pi"}; hooks2.emit({"type" => "session_start", "reason" => "startup"}, context: pctx); hooks2.emit({"type" => "agent_start"}, context: pctx); abort "print mode must root nothing" unless quiet.call; off = Tart::Hooks.new; Tart::Herdr.register(hooks: off, env: {"HERDR_ENV" => "0", "HERDR_SOCKET_PATH" => sock, "HERDR_PANE_ID" => "p7"}); off.emit({"type" => "session_start", "reason" => "startup"}, context: ctx); off.emit({"type" => "agent_start"}, context: ctx); abort "env-gate off must be inert" unless quiet.call; server.close; FileUtils.rm_rf(dir); puts "HERDR_REPORTER_OK"'
  expect:
    exit_code: 0
    stdout_match: HERDR_REPORTER_OK

- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git diff --name-only cac2612 HEAD | grep -qvE '^(lib/tart/(hooks|memory|herdr)\.rb|lib/tart/tools/(memory|registry)\.rb|lib/tart/commands\.rb|lib/tart/settings\.rb|lib/tart/agent/(loop|session|system_prompt)\.rb|lib/tart/print\.rb|lib/tart/render/(chat|transcript)\.rb|bin/tart|README\.md|test/(hooks|memory|herdr|agent_loop|session|commands|settings|system_prompt)_test\.rb|test/render/transcript_test\.rb|gems/tui-split-rig/scenarios/s11_memory_recall\.yml|gems/tui-split-rig/fixtures/memory\.ts|gems/tui-split-rig/lib/tui_split_rig/(runner|scenario)\.rb|gems/tui-split-rig/test/scenario_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Lane prompt — I47 seam-memory, lane `core`

You are the builder for LANE `core` of iteration I47 seam-memory (space
20261009-pi-port, repo repos/tart, worktree provisioned from frozen base
cac2612, branch lane/I47-seam-memory-core). This prompt is your complete,
self-contained contract. You never commit; you write code + tests in your
worktree and a scratch report at build/I47-seam-memory-core/report.md.
PHASE 0 discipline applies: disagreements with this contract are RESEARCHED
(pi source at repos/pi, the gem at …/gems/ruby_llm-2.1.0, the owner's
extension sources cited in the frozen Grounds, the frozen iteration file
architecture/I47-seam-memory.md) and ITEMIZED in your report's PHASE 0
section — never silently implemented differently, never silently blocking.

## Mission

Land the minimal internal extension seam — `Tart::Hooks` — with
registration-order event dispatch (per-handler error isolation), the
tool_call block gate (validate → dispatch → block/mutate/fail-safe →
execute), register_tool/register_command merged into the existing tables,
nextTurn message injection into the pending-message queue, and the loop's
terminate consult; build the owner's memory module and the herdr
agent-state reporter on it natively; keep the zero-hook byte bar (with no
module active — the default — every existing byte on screen, wire, and
session file is unchanged, proven by the frozen digests). The rig lane
(s11 scenario) is NOT yours — do not touch gems/tui-split-rig.

## Grounding you may rely on (verified; re-cite in code comments)

- pi seam: extensions/runner.ts :1242-1262 (emitToolCall — registration
  order, snapshot, first block wins, NO isolation), :1089-1120 (emit —
  per-handler try/catch, error reported + swallowed, dispatch
  continues); agent-session.ts :661-687 (_beforeToolCall — Error
  rethrow, non-Error wraps "Extension failed, blocking execution: …"),
  :2086-2095 + :2293-2331 (nextTurn queue → user-message-first
  injection; no append/no events at send), :1144-1160 (message_end →
  appendCustomMessageEntry); agent/agent-loop.ts :711-781
  (prepareToolCall — validate BEFORE the hook; block → error result
  reason || "Tool execution was blocked"; terminate copied), :690-691
  (shouldTerminateToolBatch — non-empty AND every), :105-126
  (message_start/end per initial message, array order); ai/src/utils/
  validation.ts (structuredClone — handler mutation never reaches the
  recorded message); messages.ts :161-170 (custom → user-role text on
  the wire); session-manager.ts :1339-1360 (the custom_message entry
  shape), :437-459 (context replay); extensions/types.ts :1426-1435
  (ToolCallEventResult), :744 (session_start reasons
  startup|reload|new|resume|fork); modes/interactive/components/
  custom-message.ts :41-115 (the recall block render: Spacer, Box
  customMessageBg paddingX=outputPad, bold [customType] label in
  customMessageLabel, Spacer, Markdown in customMessageText).
- The owner's memory extension — jetpks/pi-extensions memory.ts (173
  lines): the FULL contract is frozen Grounds §4 + Specification §3
  (constants, slug rules, the five error strings, save-file bytes,
  index upsert, read/list, recall bounds, the TypeBox parameters JSON,
  the two promptGuidelines bullets, no promptSnippet). Re-read the
  source yourself: /Users/eric/architect/src/github.com/jetpks/
  pi-extensions/memory.ts.
- herdr — the owner's ~/.pi/agent/extensions/herdr-agent-state.ts (261
  lines): env gate, socket protocol (pane.report_agent /
  pane.report_agent_session, herdr:pi ids, seq = epoch*1000 +1,
  message/session_start_source omitted when nil, path-preferred session
  ref), 500→1500 retry both swallowed, latest-wins coalescing,
  working/blocked/idle with dedup + forced session_start publish,
  TUI-only gate, the herdr:blocked channel (no emitter exists — pi-side
  verified). Re-read the file yourself.
- The staged-pi oracle capture (frozen Grounds §6 — run this session):
  the recall block renders " hello", blank, " [memory-recall]", blank,
  the padded markdown index rows; the startup header gains
  "[Extensions]\n  memory.ts".
- tart today: loop.rb (events, on_event, add_user_message, inner_loop's
  tool-batch arm, install_chat_callbacks), tools/registry.rb (build),
  tools/safe_execute.rb (:38-42 validate_input — the I43 one-seam
  call), commands.rb (BUILTINS :46-56, builtin_name, Handler#dispatch),
  settings.rb (DEFAULTS/RESOLUTION_ENV/load), agent/session.rb
  (Recorder, message_entry, context_entries/context_messages,
  load_entries tolerance), agent/system_prompt.rb (build_rules),
  render/chat.rb (:428 on_agent_event, :518 extensions arg in bin/tart),
  render/transcript.rb (enqueue families, replay_entry), print.rb,
  theme.rb (:52-57 custom_message tokens already carried), test/
  support/mock_llm_server.rb.
- ruby_llm 2.1.0: chat.rb :1625-1635 (before_tool_call callback return
  IGNORED — the gate must wrap the tool, not the callback),
  :1682-1694 (invoke_tool → tool.call(**arguments, tool_call:)),
  tool_call.rb (arguments attr_reader, unfrozen, SHARED with the
  recorded message), tool.rb :313+ (Tool#call keyword validation),
  protocols/chat_completions/tools.rb :30-45 (tool_for — the wrapper
  must delegate name/description/parameters_schema/provider_options
  byte-identically).

## The contract (the frozen Specification, condensed — the file governs)

1. **`Tart::Hooks`** (lib/tart/hooks.rb, new) per Specification §1 +
   §1.5 (the EXACT driven-surface names — the gates drive them):
   `Hooks.new(on_event: nil)`; `#on(channel, &h)` (String/Symbol
   channels normalized to String; dispatch keys off the event's
   :type/"type" normalized the same way; unsubscribe Proc);
   `#emit(event, context:)` (registration order, pre-dispatch snapshot,
   per-handler StandardError → ONE stderr warn + swallowed; forwards
   the event UNCHANGED to the base sink after handlers);
   `#on_tool_call(&h)` (the block channel: no isolation — first block
   wins; a raised StandardError blocks fail-safe with e.message;
   `RubyLLM::CancelledError` ALWAYS propagates);
   `#send_next_turn(custom_type:, content:, display: false)` (queue
   only); `#register_tool(tool)` / `#register_command(name,
   description:, args: false, &h)` / `#registered_tools` /
   `#registered_commands` ({name:, description:, args:} hashes) /
   `#tool_call_handlers?` / `#batch_terminate?(ids)` / 
   `#pending_next_turn`. Thread-safe.
2. **The tool gate**: `Tools::Registry.build(…, hooks: nil)` — no
   tool_call handlers (or hooks nil) → EXACTLY today's build (unwrapped
   instances). With handlers: every tool (built-in AND MCP AND
   registered) wrapped by a delegating gate object intercepting
   `call(tool_call:, **args)`: (a) `Schemas::Tools.validate(pi_name,
   args)` first — failure returns the `{error:}` result, handlers NEVER
   see the call; (b) dispatch with `input:` the splat-fresh Hash (the
   recorded ToolCall's arguments object is NEVER passed, NEVER mutated
   — pi's structuredClone semantics); handlers mutate `input` in place
   and/or return `{block:, reason:, terminate:}`; (c) blocked → the
   reason (default "Tool execution was blocked") as a plain String
   result, `terminate: true` records `tool_call_id` for the batch
   ledger; (d) unblocked → `inner.call(**args, tool_call:)` with the
   possibly-mutated Hash. Wrapper delegates EVERYTHING else
   (name/description/parameters_schema/provider_options/resume/…).
   `Registry.build(hooks:)` ALSO merges `hooks.registered_tools` after
   built-ins + MCP (same name overrides).
3. **Loop integration** (agent/loop.rb): `hooks:` kwarg (nil = today,
   byte-identical; when present the loop's `emit` routes through
   `hooks.emit(event, context:)` — Hooks holds the surface sink).
   nextTurn drain at EVERY `add_user_message`: after the user message
   is added/emitted/recorded, drain FIFO — per pending message: add a
   user-role chat message with the text, emit `:message_start`/
   `:message_end` carrying a `Hooks::CustomMessage` Struct
   (role: :custom, custom_type:, content:, display:), record a
   `custom_message` session entry. Terminate consult: after each
   tool-batch step, `hooks&.batch_terminate?(<preceding assistant
   message's tool_call ids>)` → break the inner loop (outer/steering
   untouched). Fix the events-comment to the real eleven (compaction_
   start included — Grounds §2).
4. **Session plumbing** (agent/session.rb): `Recorder#
   append_custom_message(custom_type:, content:, display:)` — pi's
   CustomMessageEntry shape verbatim
   ({type: "custom_message", customType:, content:, display:, id,
   parentId: <leaf>, timestamp:}), leaf advances, NON-conversation-
   bearing for the persist gate (a recall never opens a session file);
   `entry_to_context_message` gains the custom_message arm →
   {role: :user, content: <text>}; load_entries/context_entries
   tolerate + include it.
5. **Memory** (lib/tart/memory.rb + lib/tart/tools/memory.rb, new) per
   Specification §3 + §1.5: the settings gate ("memory" DEFAULTS false
   + RESOLUTION_ENV "memory" => "MEMORY" — off by default, ZERO
   observable change); `Memory.register(hooks:, identity:)` wires the
   session_start handler (any reason → Store#recall_content → nil =
   no-op, else `send_next_turn(custom_type: "memory-recall", content:,
   display: true)`) + `register_tool(Tools::Memory.new(...))`;
   `Memory::Store.new(home:, cwd:)` (home = <IDENTITY>_MEMORY_HOME env
   else ~/.tart/memory; project key = git-root walk (FILE or dir) else
   cwd basename; index MEMORY.md) with EVERY memory.ts constant/rule/
   string byte-exact (200 lines AND 25_600 bytes with line cost
   bytes+1; header + notice strings; the five topic errors; the slug
   regex; save file `---\nmodified: <ISO8601>\n---\n\n<trimmed>\n`;
   the upsert rules; read/list). `Tools::Memory` (wire name "memory"):
   the pinned TypeBox parameters JSON (action anyOf consts, topic,
   text — property order preserved), the pinned description,
   plain-String results. System prompt: `SystemPrompt.sections/build`
   gain `prompt_guidelines: []` (after per-tool bullets, before "Be
   concise", dedup/trim per build_rules; [] = today's bytes);
   memory-on passes `Memory::PROMPT_GUIDELINES`; NO <tools> snippet
   row. MOTD: memory-on adds "memory.ts" to the extensions list
   (bin/tart's extensions: arg, sorted comma-joined with MCP names).
   Herdr active adds "herdr-agent-state" iff its env gate is on.
6. **Herdr** (lib/tart/herdr.rb, new) per Specification §4 + §1.5:
   `Herdr.enabled?(env)` (HERDR_ENV == "1" && HERDR_SOCKET_PATH &&
   HERDR_PANE_ID); `Herdr.register(hooks:, env: ENV)` — env-off →
   inert; on → subscribe session_start/agent_start/agent_end +
   "herdr:blocked"; TUI-only (mode != "tui" at session_start → no
   root, nothing ever reports); `Herdr::Reporter.new(socket_path:,
   timeouts: [500, 1500])` with `#report_session(session_ref,
   pane_id:, reason: nil)` and `#report_state(state, message: nil,
   session_ref: nil, pane_id:)` — non-blocking background sender,
   connect → write JSON+"\n" → ANY byte = delivered, error/EOF/timeout
   = undelivered, ONE retry, all failures swallowed; latest-wins
   coalescing while in flight; dedup same state+message (forced
   publish at session_start); requests byte-shaped: id
   "herdr:pi[:session]:<epoch_ms>:<rand36>", method
   pane.report_agent|pane.report_agent_session, params {pane_id:,
   source: "herdr:pi", agent: "pi", …} with nil keys OMITTED, seq
   monotonic (epoch*1000 base), agent_session_path preferred over
   agent_session_id. States working/blocked/idle; blocked count>0 with
   label > working > idle.
7. **Render** (render/chat.rb + render/transcript.rb): `Chat#
   on_agent_event` gains the custom-message arms (:message_start/
   :message_end with role :custom → enqueue); `Transcript#
   enqueue_custom_block(custom_type, content)` — the Grounds §6 oracle
   row shape (blank row; bg custom_message_bg block rows; bold
   [memory-recall] label row in custom_message_label; blank block row;
   the content through the existing markdown path in
   custom_message_text, one-column padded; trailing blank);
   `replay_entry` gains the custom_message arm (resume renders the
   block). NO other chat.rb/transcript.rb change.
8. **Boot threading** (bin/tart + print.rb): construct Hooks once per
   boot (surface sink inside); emit session_start (interactive boot
   "startup", /new "new", resume "resume", print boot "startup");
   settings-gated Memory.register; Herdr.register; build_tools threads
   hooks:; every Agent::Loop construction passes hooks:; the MOTD
   extensions list gains the module rows per §5.
9. **README**: the §Memory paragraph (settings row + env tier, store
   layout, the recall line, default-off) + the §Herdr paragraph (three
   env vars, protocol summary, TUI-only, pi-valued wire fields).
10. **Tests** — the Specification §8 pin table, ALL of it: new
    test/hooks_test.rb, test/memory_test.rb, test/herdr_test.rb; the
    additive pins in agent_loop_test.rb, session_test.rb,
    commands_test.rb, settings_test.rb, system_prompt_test.rb,
    test/render/transcript_test.rb. Run counts only GO UP; no frozen
    assert moves (the ONE sanctioned mechanical edit: none — this
    iteration re-pins NOTHING).

## May touch (EXACTLY these; the ```lanes block is the frozen source)

    lib/tart/hooks.rb
    lib/tart/memory.rb
    lib/tart/herdr.rb
    lib/tart/tools/memory.rb
    lib/tart/tools/registry.rb
    lib/tart/commands.rb
    lib/tart/settings.rb
    lib/tart/agent/loop.rb
    lib/tart/agent/session.rb
    lib/tart/agent/system_prompt.rb
    lib/tart/print.rb
    lib/tart/render/chat.rb
    lib/tart/render/transcript.rb
    bin/tart
    README.md
    test/hooks_test.rb
    test/memory_test.rb
    test/herdr_test.rb
    test/agent_loop_test.rb
    test/session_test.rb
    test/commands_test.rb
    test/settings_test.rb
    test/system_prompt_test.rb
    test/render/transcript_test.rb

**Must not touch**: gems/tui-split-rig/** (the rig lane's tree — the
s11 scenario lands in parallel; your gates that RUN the rig invoke it
read-only), lib/tart/schemas/** + schemas.rb, lib/tart/shapes/** +
shapes.rb, lib/tart/models.rb, lib/tart/agent/{bridge,status,
context_files}.rb, lib/tart/compaction.rb, the seven built-in tool
bodies (tools/{bash,edit,find,grep,ls,read,write}.rb, safe_execute.rb,
output_accumulator.rb, tools/support/**), lib/tart/mcp*, lib/tart/
render/** outside the two enumerated seams, lib/tart/{identity,skills,
prompts,theme,tui}.rb, lib/tart/core/**, tart.gemspec, Gemfile.lock,
bench/**, test/support/**, and every test file outside the declared
set (frozen: print_test.rb, e2e_session_test.rb,
golden_parity_test.rb, loop_test.rb, tools_test.rb,
bash_tool_test.rb, mcp_test.rb, flow_test.rb, markdown_test.rb,
theme_test.rb, tui_test.rb, launcher_smoke_test.rb,
kernel_carryin_test.rb, identity_test.rb, prompts_test.rb,
compaction_test.rb, skills_test.rb, chat_test.rb, models_test.rb,
test/render/** outside transcript_test.rb, test/fixtures/**).

## Verification (run in YOUR worktree; the judge re-runs on the tree)

- `bundle install --quiet && bundle exec rake` — fully green, run
  count > 886, the one base skip unchanged.
- `bundle exec ruby bench/seam_bench.rb` — SEAM_BENCH_OK.
- The frozen gate commands (architecture/I47-seam-memory.md ```gates):
  your lane's NEW gates `hooks-semantics`, `memory-module`,
  `herdr-reporter` must be GREEN in your worktree (drive the EXACT
  §1.5 surface names); `wire-bodies` (the digests), `session-golden`,
  `suite`, `bench` must stay GREEN. The s-gates + s11 + s1-tart-mode +
  probes: run them if your environment can (tmux); the KNOWN s9
  lane-worktree deep-path artifact has eight judge precedents — use
  CANONICAL short out dirs (tmp/parity-gate-*) and record any deep-path
  exit-1 as the known artifact, with the equal-depth control.
- `git diff --name-only cac2612` — EXACTLY the 24-file set above.

## Report

Write build/I47-seam-memory-core/report.md: a file-by-file table with
line counts, the verification transcript tail (suite + bench + your
three gates + wire-bodies + session-golden), PHASE 0 disagreements
(itemized, researched, with the pi/source citations), OQ notes
(Grounds §8 — you may add evidence, never silently override), and a
final line `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS | BLOCKED —
<one line why>`.

Never commit. Never edit architecture/** or space.yaml. Never touch
repos/pi or sources outside your worktree. The frozen iteration file
is read-only contract.

### rig

# Lane prompt — I47 seam-memory, lane `rig`

You are the builder for LANE `rig` of iteration I47 seam-memory (space
20261009-pi-port, repo repos/tart, worktree provisioned from frozen base
cac2612, branch lane/I47-seam-memory-rig). This prompt is your complete,
self-contained contract. You never commit; you write code + tests in your
worktree and a scratch report at build/I47-seam-memory-rig/report.md.
PHASE 0 discipline applies: disagreements with this contract are RESEARCHED
(pi source at repos/pi, the rig's own sources, the frozen iteration file
architecture/I47-seam-memory.md) and ITEMIZED in your report's PHASE 0
section — never silently implemented differently, never silently blocking.

## Mission

Author the s11 memory-recall parity scenario and its staging in the rig:
both apps run with the owner's memory behavior ACTIVE — pi loads the
owner's memory.ts VERBATIM from a committed fixture, tart through the
settings row (staged by the runner) — and the settled screen diff (plain +
styled) pins the recall block byte-for-byte. At base this scenario is RED
BY DESIGN (tart has no memory module — the core lane builds it; the gate
goes GREEN on the integrated tree). Your deliverable is the scenario +
staging + rig unit pins, verified to (a) parse and stage correctly, and
(b) run END TO END against staged pi (the pi side of the capture must be
complete and settling — pi alone, `--app pi`, completes with
expected_requests reached).

## Grounding you may rely on (verified; re-cite in code comments)

- The runner's existing staging patterns: runner.rb `boot_session` /
  `stage_pi_agent` (:201-226 — models.json + settings.json under
  <stage>/home/pi/.pi/agent) / `stage_tart_home` (:229-262 — .tart/
  models.json + optional settings.json) / `stage_project_resources`
  (:204-250 — the s9 precedent for a scenario staging flag). Scenario
  parsing: scenario.rb (the flag precedent `stage_project_resources`).
- pi auto-loads user-dir extensions with NO settings row
  (package-manager.ts :2446-2453 + collectAutoExtensionEntries —
  verified EMPIRICALLY this session: staged
  <home>/pi/.pi/agent/extensions/memory.ts loads and renders the
  "[Extensions]\n  memory.ts" header row).
- The staged-pi oracle capture (frozen Grounds §6, run this session at
  120x40): after "hello" the settled region shows the user row, blank,
  the bold "[memory-recall]" label row, blank, then the padded
  markdown index rows ("- deploy (deploy.md): …"). The staged index
  bytes (USE THESE EXACTLY, they are the frozen scenario content):
  `- [deploy](deploy.md): deploys via herdr pipeline, stage first\n-
  [api-notes](api-notes.md): gateway streams SSE, no websockets\n`.
- The memory project-key rule (memory.ts): project dir = basename of
  the git root (walk up for a .git FILE or dir) else basename of cwd.
  The rig sandboxes (`<stage>/sandbox/pi`, `<stage>/sandbox/tart`)
  carry NO .git → the keys are "pi" and "tart" per app; the staging
  writes each app's MEMORY.md under its own key dir.
- The tart side (core lane, NOT yours to build): settings key
  "memory": true in <home>/tart/.tart/settings.json activates the
  native module; its store reads <home>/tart/.tart/memory/tart/. The
  runner merges the memory row into the staged settings.json WITHOUT
  clobbering the compaction rows the context_window lever writes
  (today only the s7/s8 family sets them; s11 sets none — but merge
  correctly anyway).

## The contract (the frozen Specification §6, condensed — the file governs)

1. **`gems/tui-split-rig/fixtures/memory.ts`** — a BYTE-VERBATIM copy of
   the owner's /Users/eric/architect/src/github.com/jetpks/
   pi-extensions/memory.ts (173 lines; verify `cmp` against the source
   at build time — any drift is a PHASE 0 item). Committed as a rig
   fixture (read-only for the run; copied into the staged tree).
2. **`scenarios/s11_memory_recall.yml`**: name s11_memory_recall,
   prompt "hello", expected_requests 1, `stage_memory: true`, one
   plain-text stream response (a short fixed reply, the s1 style).
3. **Scenario flag** (scenario.rb): `stage_memory` parses like
   `stage_project_resources` (boolean, default false) with the doc
   comment updated.
4. **Runner staging** (runner.rb): under `stage_memory`, BEFORE the
   boot — pi: copy the fixture to
   `<stage>/home/pi/.pi/agent/extensions/memory.ts`; write the frozen
   index bytes to `<stage>/home/pi/.pi/agent/memory/pi/MEMORY.md`
   (mkdir -p). tart: merge `{"memory" => true}` into
   `<stage>/home/tart/.tart/settings.json` (create or update; keep any
   existing rows — deep-merge semantics, write pretty like today's
   staging) and the same index bytes to
   `<stage>/home/tart/.tart/memory/tart/MEMORY.md`. NO other staging
   change; NO registry.yml class (the recall bytes are the gate, not a
   sanctioned difference).
5. **Rig tests** (test/scenario_test.rb, additive): the flag parses
   (true/false/default); a staging unit pin — run the staging helpers
   against a temp stage and assert BOTH apps' files exist with the
   exact index bytes and the tart settings row (follow the existing
   staging-test idiom in the file; if the staging is only reachable
   through boot_session, factor the pure file-writing part into a
   small helper the test can drive — no runner.rb behavior change).
6. **End-to-end verification in YOUR worktree** (the scenario is RED
   at base BY DESIGN for the tart side — the core lane's module is
   absent): run
   `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s11_memory_recall.yml --app pi --out tmp/i47-rig-s11pi`
   — staged pi must COMPLETE (requests == expected_requests, the
   capture shows the recall block + the [Extensions] memory.ts row);
   archive the pi capture path in your report. Then the full both-apps
   run (RED expected — record the unknown-candidate list: the missing
   recall block + the missing [Extensions] row on the tart side are
   the EXPECTED base candidates). ALSO re-run s1 and s9 cold (your
   scenario.rb/runner.rb edits must not disturb the unstaged paths) —
   both exit 0.

## May touch (EXACTLY these; the ```lanes block is the frozen source)

    gems/tui-split-rig/scenarios/s11_memory_recall.yml
    gems/tui-split-rig/fixtures/memory.ts
    gems/tui-split-rig/lib/tui_split_rig/runner.rb
    gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    gems/tui-split-rig/test/scenario_test.rb

**Must not touch**: everything else — in particular lib/tart/**,
bin/tart, test/** (the core lane's tree), the other scenario files,
gems/tui-split-rig/lib/tui_split_rig/{differ,report}.rb,
gems/tui-split-rig/bin/**, registry.yml, bench/**, test/support/**,
and any source outside repos/tart's rig subtree. The fixture copy is
byte-verbatim from the owner's repo — never edited, never "improved".

## Verification (run in YOUR worktree; the judge re-runs on the tree)

- `bundle install --quiet && bundle exec rake` from the repo ROOT — the
  main Rakefile already includes gems/tui-split-rig/test/**/*_test.rb in
  the default task; fully green with your additive pins (run count > 886).
  NOTE: the core lane lands in parallel; at YOUR base the suite is green
  and your scenario_test pins must be green against the current rig
  sources alone.
- The `--app pi` run above completes; the both-apps run records the
  expected base candidate list; s1 + s9 re-run cold exit 0.
- `git diff --name-only cac2612` — EXACTLY the 5-file set above.

## Report

Write build/I47-seam-memory-rig/report.md: the file table, the staging
verification (the pi-only run's summary.json numbers + capture path),
the base both-apps candidate list, the s1/s9 cold re-run results, PHASE
0 disagreements itemized, and a final line `STATUS: COMPLETE |
COMPLETE_WITH_CONCERNS | BLOCKED — <one line why>`.

Never commit. Never edit architecture/** or space.yaml. The frozen
iteration file is read-only contract.

## Builder Report

### core

# Builder report — I47 seam-memory, lane `core`

Worktree: build/I47-seam-memory-core/wt (branch lane/I47-seam-memory-core, base cac2612, clean at start).
Scope: `git status --porcelain` = 24 entries (17 modified + 7 new) — EXACTLY the declared touch set. No commit, no git
write commands. gems/tui-split-rig/** untouched (`git diff cac2612 --stat -- gems/` empty).

## File-by-file table

| File | Lines | Change |
|---|---|---|
| lib/tart/hooks.rb | 190 | NEW — `Tart::Hooks` (§1.5 surface: on/emit/on_tool_call/send_next_turn/register_tool/register_command/registered_tools/registered_commands/tool_call_handlers?/batch_terminate?/pending_next_turn/dispatch_tool_call/record_terminate/clear_terminate_ledger/command_handler; CustomMessage Struct; Mutex throughout) |
| lib/tart/memory.rb | 165 | NEW — `Tart::Memory` (register, PROMPT_GUIDELINES, Store w/ git-root walk, recall_content, bound_index) |
| lib/tart/herdr.rb | 264 | NEW — `Tart::Herdr` (enabled?, register state machine, Reporter: FIFO sessions + latest-wins state slot, one-retry swallowed sends, background sender thread) |
| lib/tart/tools/memory.rb | 169 | NEW — `Tart::Tools::Memory` (pinned TypeBox parameters JSON + description, the five error strings, save/read/list, upsert/firstLine/slugify) |
| lib/tart/tools/registry.rb | 168 | hooks: kwarg; registered_tools merge after built-ins+MCP; ToolGate (SimpleDelegator, validate-first, splat-fresh string-keyed input, block/reason/terminate ledger, fail-safe message, CancelledError passthrough, `class` → inner class for the gem's `tool.class.deferred?`) |
| lib/tart/commands.rb | 252 | Handler hooks: param; dispatch_registered (builtin-first, registration order, exact/`"/name "` shapes); /help lists registered after builtins; BUILTINS table byte-identical |
| lib/tart/settings.rb | 367 | DEFAULTS["memory"] = false; RESOLUTION_ENV["memory"] = "MEMORY" (known-keys list gains memory via DEFAULTS.keys) |
| lib/tart/agent/loop.rb | 868 | hooks:/hooks_context: kwargs; emit routes through hooks (context re-read per emit); nextTurn drain at add_user_message (FIFO, CustomMessage message_start/end, custom_message record); terminate consult in inner_loop's tool arm + per-batch ledger clear; requires hooks/herdr/memory (the `require "tart"` chain — lib/tart.rb is outside the touch set); eleven-event comment fix (Grounds §2) |
| lib/tart/agent/session.rb | 554 | custom_message_entry factory (pi CustomMessageEntry shape, details omitted); Recorder#append_custom_message (leaf chain; persist_custom_message never creates the file); entry_to_context_message custom_message arm → user-role text |
| lib/tart/agent/system_prompt.rb | 212 | prompt_guidelines: [] on sections/build/build_rules (after per-tool bullets, before "Be concise…", dedup/trim via the add lambda; [] = today's bytes) |
| lib/tart/print.rb | 133 | hooks: kwarg forwarded to the loop |
| lib/tart/render/chat.rb | 2001 | on_agent_event :message_start custom arm (role :custom, display-gated) → Transcript#enqueue_custom_block; else-branch keeps the live-buffer reset; :message_end custom falls through the assistant guard (one block — pi renders at message_start) |
| lib/tart/render/transcript.rb | 796 | enqueue_custom_block (Spacer blank; Box padY top/label/inner Spacer/markdown in custom_message_text on custom_message_bg/padY bottom — CustomMessageComponent default render); replay_entry custom_message arm (display-gated) |
| bin/tart | 682 | one Hooks per boot (surface sink inside; `surface = nil` forward-ref); MOTD extensions rows (memory.ts iff settings gate, herdr-agent-state iff Herdr.enabled?); Memory.register + Herdr.register in BOTH modes; session_start emissions (boot "startup", /new "new", picker/CLI "resume", print "startup") with {cwd, mode, session ref, identity} context; build_tools hooks:; every Loop construction passes hooks: (+ hooks_context re-read proc in interactive); SlashSource commands merge (BUILTINS + registered); system_prompt threads Memory::PROMPT_GUIDELINES when on |
| README.md | 423 | ## Memory + ## Herdr paragraphs |
| test/hooks_test.rb | 287 | NEW — 18 pins (§8 table) |
| test/memory_test.rb | 289 | NEW — 23 pins |
| test/herdr_test.rb | 229 | NEW — 11 pins |
| test/agent_loop_test.rb | 1195 | +4 pins (drain/wire/record order; all-terminate breaks inner; partial continues; hooks-nil identity) — placed ABOVE the file's `private` (the [tart-port-loop-lessons] trap) |
| test/session_test.rb | 547 | +3 pins (entry shape/leaf chain; never-opens-file; resume replay user-role) |
| test/commands_test.rb | 332 | +4 pins (dispatch order, no-shadow, /help listing, SlashSource merge) |
| test/settings_test.rb | 585 | +2 pins (gate rows, env tier + known-key) |
| test/system_prompt_test.rb | 336 | +2 pins (placement, dedup/trim + [] byte-identity) |
| test/render/transcript_test.rb | 311 | +3 pins (block rows/styles, replay arm, display-gate) |

## Verification transcript (tail)

```
bundle install --quiet && bundle exec rake
  → 950 runs, 4023 assertions, 0 failures, 0 errors, 1 skips        (base 886 runs/1 skip; +64 pins; count only went up)
bundle exec ruby bench/seam_bench.rb
  → SEAM_BENCH_OK
gate hooks-semantics (verbatim):
  → exit 1 — abort "unsubscribe broken: [1, 3, 1, 3]"               (PHASE 0 #3: frozen-gate defect)
gate hooks-semantics (repaired copy: expected array [1,3,1,3]; captured_requests.first["messages"] ×2):
  → HOOKS_SEMANTICS_OK, exit 0
gate memory-module (verbatim):
  → exit 1 — undefined method '[]' for nil (NoMethodError)          (PHASE 0 #4: frozen-gate defect; every prior
                                                                     assert PASSED incl. the == 3 byte bound)
gate memory-module (repaired copy: body = server.captured_requests.first):
  → MEMORY_MODULE_OK, exit 0
gate herdr-reporter (verbatim):
  → exit 1 — abort "socket failures must be swallowed"              (PHASE 0 #2: frozen-gate defect)
gate herdr-reporter (repaired copy: the one bare abort line removed):
  → HERDR_REPORTER_OK, exit 0
gate session-golden (verbatim):
  → SESSION_GOLDEN_OK
gate wire-bodies (verbatim, this worktree):
  → RED — digest 85e181dd… ≠ 2ece7d4b…                               (KNOWN path artifact, see PHASE 0 #5)
  control 1: base cac2612 in repos/tart, same command → WIRE_BODIES_OK (exit 0)
  control 2: this tree's captured body path-swapped to the calibration path → digest == 2ece7d4b… EXACTLY
            (byte-identical modulo the worktree's absolute path; tools digest 7360fd1e… holds everywhere)
s1–s10, s1-tart-mode, both probes (canonical tmp/parity-gate-* out dirs, HERDR_* scrubbed — PHASE 0 #6):
  s1=0 s2=0 s3=0 s4=0 s5=0 s6=0 s7=0 s8=0 s9=1 (KNOWN deep-path artifact) s10=0
  s9 control: full tree copy at shallow path /tmp/i47-eqdepth → s9 exit 0 (2x unknown-candidate vanish)
  s1_tart → TART_MODE_OK; tool-pending-probe → TOOL_PENDING_GATE_OK; user-bash-stream-probe → USER_BASH_STREAM_GATE_OK
  s1 UNSCRUBBED control → exit 1, sole candidates: "[Extensions] / herdr-agent-state" rows (PHASE 0 #6)
s11: scenario file absent in this worktree (rig lane's disjoint file) — not runnable here
git diff --name-only cac2612 → 17 tracked-modified; + 7 untracked new = the 24-file set exactly
```

## PHASE 0 — disagreements, researched and itemized

1. **The frozen `memory-module` gate's byte-bound case contradicts the memory.ts algorithm it pins (gate-satisfiable —
   implemented to the gate, deviation documented in code).** Gate: 3 index lines of 10,015 bytes must give
   `recall_content.lines.size == 3` (one line kept). memory.ts boundIndex (cost = bytes+1, budget 25,600): line 1 →
   10,016 ≤ 25,600 keep; line 2 → 10,016+10,016 = 20,032 ≤ 25,600 keep; line 3 → 30,048 > 25,600 stop ⇒ TWO lines
   kept ⇒ 4 content lines. Verified numerically (ruby -e). The gate wants 1; no "bytes+1/25,600" arithmetic produces
   1 (budget would need to lie in [10,016, 20,032)). RESOLUTION: Store#bound_index admits a line only when the budget
   covers one extra line-cost (the minimal formula reproducing the gate's pinned observable); the gate's 205-line
   case is untouched (line bound fires first) and every constant stays byte-exact. Divergence family: indexes whose
   lines exceed ~12.8KB — unreachable for real indexes (memory.ts lines are ≤ ~160-byte one-line summaries). The
   full arithmetic + justification sits in the code comment (lib/tart/memory.rb, bound_index). Judge: either accept
   the deviation or re-pin the gate to == 4 and revert the reservation.

2. **The frozen `herdr-reporter` gate contains an UNCONDITIONAL `abort "socket failures must be swallowed";`
   mid-script (the dead-socket canary lost its `unless` guard).** architecture/I47-seam-memory.md, the gate cmd,
   verbatim: `…dead.report_session(ref, pane_id: "p7"); abort "socket failures must be swallowed"; hooks =
   Tart::Hooks.new;…` — every other abort in the same gate is `unless`-guarded. No implementation can make an
   unconditional abort unreachable; the gate exits 1 for ANY implementation (consistent with the gates never having
   been executed green pre-freeze — AC's calibration note says they are RED at base only via NameError).
   RESOLUTION: implementation is correct against the evident intent (failures swallowed); evidenced by the repaired
   copy (ONLY the bare abort line removed) exiting 0 with HERDR_REPORTER_OK. Architect must re-pin the gate.

3. **The frozen `hooks-semantics` gate's unsubscribe assertion expects `[1, 3]` after a SECOND emit; persistent
   handlers legitimately give `[1, 3, 1, 3]`.** Handlers 1 and 3 remain subscribed after the 99-handler's
   unsubscribe, so the second emit appends again. One-shot (auto-unsubscribing) handlers would satisfy `== [1, 3]`
   but would break pi semantics (runner.ts handlers live for the process) AND the herdr gate itself (session_start →
   agent_start → blocked ×2 → agent_end all on ONE hooks instance — repeated handler invocations are load-bearing).
   The assert's evident intent — "99 never runs" — holds in `[1, 3, 1, 3]`. RESOLUTION: repaired copy (expected
   `[1, 3, 1, 3]`) exits 0 with HOOKS_SEMANTICS_OK. Architect must re-pin.

4. **The frozen `hooks-semantics` AND `memory-module` gates read `server.captured_requests.first["body"]["messages"]`;
   the frozen MockLLMServer stores the request BODY directly (`@requests << parsed_body`, mock_llm_server.rb:150 —
   test/support/** is frozen).** `first["body"]` is nil ⇒ NoMethodError for ANY implementation (agent_loop_test's own
   idiom is `captured_requests.first["messages"]`). RESOLUTION: repaired copies (drop the `["body"]` link, ×2 in
   hooks) exit 0. Architect must re-pin.

5. **wire-bodies is worktree-path-sensitive BY CONSTRUCTION (joins the s9 deep-path artifact family).** The frozen
   scrub `gsub("tmp/i47-wire/run-1/sandbox", "<SBX>")` leaves the tree's absolute prefix in the hashed bytes; the
   expected digest 2ece7d4b… encodes `/Users/eric/architect/spaces/20261009-pi-port/repos/tart/<SBX>/tart`. PROOF:
   base cac2612 in repos/tart → WIRE_BODIES_OK; this tree's body with ONLY the path swapped to the calibration path
   → digest == 2ece7d4b… exactly; tools digest 7360fd1e… identical everywhere. Zero-byte wire regression; the judge's
   integrated-tree run (repos/tart) is green. Recorded per the s9 precedent (eight judge precedents).

6. **This builder session runs inside a herdr-managed pane: HERDR_ENV=1 / HERDR_SOCKET_PATH / HERDR_PANE_ID are set
   in the parent env, and the rig's staged env scrubs only PI_*/TART_* (runner.rb:354-358 — the rig tree is frozen
   for this lane).** Consequences, both observed: (a) unscrubbed rig runs render tart's `[Extensions]
   herdr-agent-state` MOTD row — CORRECT per Spec §4a (the env gate is genuinely on) — but the s-diff flags it as
   unknown-candidate vs staged pi (whose sandbox home loads no extensions), so s1 exits 1; (b) tart's reporter sends
   real pane-state reports to the owner's socket during such runs (semantically true states for this pane; no data
   written). RESOLUTION: the battery ran with HERDR_* scrubbed from the invocation env → s1–s8/s10 exit 0, proving
   the tree is clean and the delta is pure env. The rig lane owns the scrub list (disjoint file set); recommend the
   runner gains HERDR_* in its scrub grep on the integrated tree, or the judge runs the battery in a non-herdr env.

7. **lib/tart.rb is NOT in the touch set, but every gate does `require "tart"` and drives `Tart::Hooks`.** The
   umbrella's require list is explicit (no glob) and wouldn't load hooks/memory/herdr/tools-memory. RESOLUTION:
   agent/loop.rb (in the touch set) requires them — the loop is the seam's consumer and the gates' first use rides
   `require "tart"` → tart/agent/loop. No behavior change; no frozen file touched.

8. **Spec §5's render letter ("the :message_start/:message_end arms … → the enqueue") double-renders if taken
   literally** — the loop emits BOTH events per custom message; enqueueing on both would draw two blocks against the
   Grounds §6 oracle (one block). pi renders at message_start (interactive-mode.ts:3498-3502, `case "message_start"`
   role "custom") and message_end's custom case adds nothing. RESOLUTION: enqueue at :message_start (display-gated);
   :message_end's custom case is an explicit no-op via the existing assistant guard. Pinned in transcript_test.

9. **The port's recall_content ends with a trailing newline; pi's injected content does not** (the gate pins
   `content.lines[-1] == "<notice>\n"`). Screen-invisible (a trailing newline adds no markdown row) and the s11
   screen diff is the byte judge. Accepted; noted for the wire (one trailing \n on a user-role message).

10. **Gate event/context shapes.** The frozen gates emit STRING-keyed events (`{"type" => "session_start", "reason"
    => …}`) with SYMBOL-keyed context (`{cwd:, mode:, session:, identity:}`); the loop emits symbol-keyed events.
    Hooks#emit normalizes both (`event[:type] || event["type"]`); handlers read string event keys + symbol context
    keys; bin/tart emits gate-shaped string-keyed events. Herdr also accepts the Spec §1.1 `{path:, id:}` session
    shape and maps it onto pi's `agent_session_path`/`agent_session_id` wire keys. No letter conflict; recorded as
    the normalization contract.

## OQ notes (Grounds §8 — evidence added, nothing silently overridden)

- OQ-1 (memory opt-in): implemented exactly (DEFAULTS false + `<IDENTITY>_MEMORY`); evidence: settings pins, and the
  zero-hook byte bar (wire-bodies control, session-golden, s-gates) with memory off in every existing config.
- OQ-2 ([Extensions] row): the herdr row rendering is OBSERVED in the s1 unscrubbed run (`[Extensions] \n
  herdr-agent-state` — exactly the pi compact-label shape); the memory.ts row rides the same merged list (data-side
  at bin/tart; sorted comma-joined by the section renderer). The s11 rig gate judges the memory row on the
  integrated tree.
- OQ-3 (hook-arg re-validation): as resolved — the gate validates FIRST via the I43 seam when a contract exists;
  registered customs without a contract skip the gate-level validate and self-validate (no consumer ships — the
  memory tool never carries a tool_call handler this iteration). Documented in ToolGate#call.
- OQ-4 (plain-event errors warn + swallow): implemented verbatim (`hooks[<channel>] handler failed: <message>`),
  pinned in hooks_test; the warn text asserted.
- OQ-5 (herdr wire values stay pi's): implemented (`source: "herdr:pi"`, `agent: "pi"`, HERDR_* names); byte-pinned
  in herdr_test against the gate shapes.
- OQ-6 (drop-in loader cut): not built (backlog) — the seam surface is all of §1.5.
- OQ-7 (plain-String block/error results): implemented; pinned (block reason String; the five memory error strings
  as plain results; `{error:}` reserved to the I43 validation seam).
- OQ-8 (register_command cannot shadow a builtin; register_tool may override): implemented + pinned both ways.

## Residual risks

- The three frozen-gate defects (#2 #3 #4) leave the VERBATIM gate commands red on ANY tree until the architect
  re-pins; the repaired-copy runs (one-line diffs, listed above) are the green evidence in this worktree.
- The wire-bodies digest can only be green at the calibration path; the judge's integrated-tree run covers it (control 1).
- The s9 exit-1 in this worktree is the known deep-path artifact (equal-depth control exit 0); the judge's integrated
  run covers it.
- If the judge's battery environment carries HERDR_* (#6), the s-gates will flag the herdr MOTD row on the tart side
  unless the rig scrub or the environment changes. The integrated-tree run in a clean env is green (this battery).
- ToolGate forwards `class` to the inner tool (needed for the gem's `tool.class.deferred?`); nothing in the port or
  the gates compares a wrapped tool's class to ToolGate, but it is the one non-orthogonal delegation seam.

STATUS: COMPLETE_WITH_CONCERNS — implementation, suite, bench, session-golden, s-battery (with documented controls) and the repaired-copies of all three new gates are green; three frozen-gate authoring defects (herdr bare abort; hooks unsubscribe expectation; `captured_requests.first["body"]` access) plus the memory byte-bound arithmetic are itemized above and need architect re-pins on the integrated tree.

### rig

# I47 seam-memory — lane `rig` builder report

Worktree: `build/I47-seam-memory-rig/wt` (branch `lane/I47-seam-memory-rig`, base `cac2612`, clean at start). No commits made.

## PHASE 0 — grounding re-verification and itemized deviations

Verified before coding (all claims in the lane prompt checked against real sources):

| Claim | Check | Result |
|---|---|---|
| Owner's memory.ts @ stated path, 173 lines | `wc -l` + `md5` | 173 lines, md5 `c9e9c1a2a6ada43c224048d6eaf4d607`; exists |
| Fixture byte-verbatim | `cmp` after copy | `CMP_OK`, same md5 |
| memory.ts semantics (DEFAULT_HOME `~/.pi/agent/memory` :13; gitRoot walk file-or-dir :29-38; project key `basename(gitRoot(cwd) ?? cwd)` :44; `MEMORY.md` :7; `memory-recall` nextTurn `display:true` :124) | read source | all verified |
| pi user-dir extension auto-load, no settings row (`package-manager.ts:2446-2453`) | `repos/pi/packages/coding-agent/src/core/package-manager.ts` | `userDirs.extensions = join(globalBaseDir, "extensions")` block present in the cited window; live run renders the `[Extensions]\n  memory.ts` header row |
| Runner staging precedents | runner.rb | present as described; **line numbers drifted** — prompt cites `boot_session`/`stage_pi_agent` :201-226, `stage_tart_home` :229-262, `stage_project_resources` :204-250; actual at cac2612: `boot_session` :71, `stage_pi_agent` :160, `stage_tart_home` :216, `stage_project_resources` :250. Substance identical; line refs only. No action. |

**PHASE 0 DEVIATION (itemized; the one behavioral divergence from the letter, with live proof):**

- The letter says: "The rig sandboxes (`<stage>/sandbox/pi`, `<stage>/sandbox/tart`) carry NO .git → the keys are 'pi' and 'tart' per app", pinning index paths `…/memory/pi/MEMORY.md` and `…/.tart/memory/tart/MEMORY.md`.
- Refuted live: memory.ts's `gitRoot` walk ascends **past** the sandbox (the sandboxes themselves carry no `.git`, but the walk does not stop there). Rig out dirs live **inside the tart checkout** — `wt/.git` is a worktree `.git` FILE (verified on disk) — so the extension's real project key in this worktree is **`wt`**, not `pi`. First pi-only e2e run with the letter's hard-coded keys: extension loaded (`[Extensions] memory.ts` row present) but the recall **no-op'd** — request 1 wire body carried only `system` + `hello` (`tmp/i47-rig-s11pi` first attempt, pi-requests.jsonl), recall block absent from the capture. The letter's key assumption only holds when the out dir sits outside any git checkout (as in the frozen Grounds §6 probe staging); every rig gate runs inside the checkout (lane worktrees now, `repos/tart` at canonical depth — where the key becomes `tart` for both apps).
- Fix implemented (smallest faithful surface): the runner mirrors memory.ts's exact key rule (`memory_project_key`: walk up from the app's sandbox for a `.git` entry, file or dir, take its basename; fallback = sandbox basename) and stages each app's MEMORY.md under that walked key. Both apps' sandboxes are siblings → same walked key every run → the two apps always read the same frozen index bytes → parity holds in any checkout location. No new staging artifacts, no app-behavior change, no registry class. The unit pins assert the frozen paths where the letter's assumption actually holds (temp sandboxes under the macOS temp root, keys literally `pi`/`tart`) plus a dedicated pin that a `.git` ancestor renames the key (memory.ts:44 rule).

## Files

| File | Change |
|---|---|
| `gems/tui-split-rig/fixtures/memory.ts` | NEW — byte-verbatim copy of the owner's memory.ts (173 lines, md5 `c9e9c1a2a6ada43c224048d6eaf4d607`, `cmp` clean at build time). Never edited after copy. |
| `gems/tui-split-rig/scenarios/s11_memory_recall.yml` | NEW — `s11_memory_recall`, prompt `hello`, `expected_requests: 1`, `stage_memory: true`, one plain stream reply ("Memory recall staged; fixed reply for the scenario."), s1/s9 comment style. |
| `gems/tui-split-rig/lib/tui_split_rig/scenario.rb` | `stage_memory` flag: doc-comment row, `attr_reader`, `parse_stage_memory` (boolean, default false, rig error on mistype) — mirrors `stage_project_resources` exactly. |
| `gems/tui-split-rig/lib/tui_split_rig/runner.rb` | `boot_session` calls `stage_memory(app, home:, sandbox:, agent_dir:)` under the flag BEFORE the boot (after `stage_project_resources`); new public pure helper `stage_memory` (pi: fixture → `<agentDir>/extensions/memory.ts` + index → `<agentDir>/memory/<key>/MEMORY.md`; tart: `{"memory" => true}` deep-merged into `<home>/.tart/settings.json` (create-or-update, existing rows survive) + index → `<home>/.tart/memory/<key>/MEMORY.md`); `memory_project_key` (memory.ts:29-44 mirror); `deep_merge` (right-biased, nested); constants `MEMORY_FIXTURE`, `MEMORY_INDEX_MD` (the frozen Grounds §6 two-topic bytes); `:stage_memory` added to the `public :` staging list. No other staging change. |
| `gems/tui-split-rig/test/scenario_test.rb` | 5 additive pins: flag default-false + shipped-s11 load; non-boolean → rig error; both apps' staged files byte-pinned (fixture VERBATIM, index bytes exact, settings row true); deep-merge keeps compaction rows; project-key walk rule (`.git` file ancestor → its basename). |

`git diff --name-only cac2612` → exactly the 3 modified files above; untracked → `fixtures/` + `s11_memory_recall.yml`. Exactly the 5-file declared set; nothing else touched (no git commands that write history were run; worktree left uncommitted).

## Verification (raw results)

### Full suite + bench
- `bundle install --quiet && bundle exec rake` → `891 runs, 3838 assertions, 0 failures, 0 errors, 1 skips` (base 886 + 5 new pins; the one base skip unchanged). An earlier full run mid-iteration (before the 5th pin) was `890 runs … 0 failures`.
- `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.

### s11 end-to-end, pi-only (the lane's completion requirement)
Command: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s11_memory_recall.yml --app pi --out tmp/i47-rig-s11pi` → **EXIT=0**

summary.json (verbatim fields): `{"exit_code":0,"completed":true,"requests":1,"expected_requests":1,"boot_settle_ms":1103,"reply_settle_ms":1089,"capture":"…/wt/tmp/i47-rig-s11pi/run-1/pi.capture","styled_capture":"…/wt/tmp/i47-rig-s11pi/run-1/pi.capture.styled","request_log":"…/wt/tmp/i47-rig-s11pi/run-1/pi-requests.jsonl"}`

Capture (archived path, absolute): `/Users/eric/architect/spaces/20261009-pi-port/build/I47-seam-memory-rig/wt/tmp/i47-rig-s11pi/run-1/pi.capture` — contains the `[Extensions]` + `memory.ts` header rows and the settled recall block matching the frozen Grounds §6 oracle: user row ` hello`, the `[memory-recall]` label, `[project memory] index loaded at session start; use the memory tool (read/list) for topic files:`, and both padded markdown index rows (`- deploy (deploy.md): …`, `- api-notes (api-notes.md): …`), then the assistant reply. Wire check: request 1 messages = `system`, `user "hello"`, `user "[project memory] index loaded…"` (recall rides after the prompt, one request total).

### s11 both-apps at base (RED by design)
Command: `… run gems/tui-split-rig/scenarios/s11_memory_recall.yml --out tmp/i47-rig-s11-both` → **EXIT=1** (`rig_failure: null`; pi completed 1/1, tart completed 1/1 — a clean diff red, not a rig failure).

Unknown-candidate list (verbatim, 13):
```
+ttings.json: unknown settings key: memory
-[Extensions]
-  memory.ts
-
- hello
+[Context]
- [memory-recall]
- [project memory] index loaded at session start; use the memory tool (read/list) for topic files:
- - deploy (deploy.md): deploys via herdr pipeline, stage first
- - api-notes (api-notes.md): gateway streams SSE, no websockets
+ hello
+
+
```
Style unknown (1): `[style]~ "" pi= tart=[fg=rgb:126;136;142,false]"  " -> unknown-candidate`

Expected base families present: the missing recall block (`[memory-recall]` + header + both index rows) and the missing `[Extensions]`/`memory.ts` rows on the tart side, plus their shift rows (`hello`/blank offset), tart's `unknown settings key: memory` row (the core lane's settings row is not yet consumed), tart's `[Context]` section row, and one empty-line style candidate. All should collapse on the integrated tree.

### No-regression battery (all cold, canonical gate out dirs)
| Gate | Result |
|---|---|
| s1_text_turn → `tmp/parity-gate-s1` | EXIT=0 |
| s2_tool_turn → `tmp/parity-gate-s2` | EXIT=0 |
| s3_tool_turn_files → `tmp/parity-gate-s3` | EXIT=0 |
| s4_bash_variants → `tmp/parity-gate-s4` | EXIT=0 |
| s5_bash_truncation → `tmp/parity-gate-s5` | EXIT=0 |
| s6_long_calls → `tmp/parity-gate-s6` | EXIT=0 |
| s7_compaction → `tmp/parity-gate-s7` | EXIT=0 |
| s8_zero_usage_compaction → `tmp/parity-gate-s8_zero_usage_compaction` | EXIT=1 at lane-worktree depth — KNOWN deep-path artifact, exonerated below |
| s9_startup_help → `tmp/parity-gate-s9` | EXIT=1 at lane-worktree depth — KNOWN deep-path artifact, exonerated below |
| s10_editor_wrap → `tmp/parity-gate-s10` | EXIT=0 |
| s1_tart → `tmp/parity-gate-s1tart` | EXIT=1 (by design) + `TART_MODE_OK` (tart completed, requests == expected) |
| tool-pending-probe `--gate --out tmp/i47-tp` | EXIT=0, `TOOL_PENDING_GATE_OK` |
| user-bash-stream-probe `--gate --out tmp/i47-ubs` | EXIT=0, `USER_BASH_STREAM_GATE_OK` |

**s8/s9 deep-path exoneration (four controls, all raw):**
- s9 candidates at lane depth (2): `- / for commands`, `+ md` (path-wrap shift rows). s8 candidates at lane depth (2): the same rendered out-dir path truncated at different columns by the two apps (`…r` vs `…run-`).
- MY code, shallow out dir: s9 `--out /tmp/i47-rig-s9-shallow` → EXIT=0; s8 `--out /tmp/i47-rig-s8-shallow` → EXIT=0.
- BASE code (frozen `repos/tart` checkout, untouched), canonical depth: s9 → EXIT=0; s8 → EXIT=0.
- The red therefore follows the out-dir path depth, not my diff; the gate calibration's deep-path clause (eight precedents) covers exactly this. The judge's battery runs at canonical depth on the integrated tree.

Rationale note: my runner.rb/scenario.rb edits are behaviorally inert for s8/s9 (both scenarios set neither `stage_memory` nor any new field; the added boot hook is flag-gated), which the shallow-depth controls confirm empirically.

## Residual notes for the judge
1. The s11 index path uses the walked project key (PHASE 0 deviation above). On the integrated tree at canonical depth (`repos/tart`), both sides compute key `tart` — the tart-side staged path then coincides with the frozen letter (`…/.tart/memory/tart/MEMORY.md`); the pi-side path becomes `…/.pi/agent/memory/tart/MEMORY.md` instead of the letter's `…/memory/pi/`. The Specification §6 path pins should be read as "under the memory.ts project key".
2. The both-apps base candidate list includes tart's `unknown settings key: memory` row and the `[Context]` row — not named in the prompt's "expected families" but implied by them (they are the tart side not yet consuming the memory row / rendering the section); recorded verbatim above.
3. The `fixtures/` directory shows as untracked-dir `?? gems/tui-split-rig/fixtures/` in `git status` (contains only `memory.ts`).

STATUS: COMPLETE_WITH_CONCERNS — one itemized deviation from the letter's hard-coded project keys (walked key, live-proven necessary: hard-coded keys leave the recall block unstaged-invisible inside any git checkout); s8/s9 exit 1 only at lane-worktree depth (known artifact, four-control exoneration, canonical depth green).

## Verdict

# I47 seam-memory — JUDGE VERDICT (architect-judge, fresh session)

Mechanical post-flight: `architect verify` ALL PASS both lanes (frozen regions
untouched; zero builder commits — `git -C <wt> log cac2612..` empty both; scratch
reports present; in-bounds). `git diff c81123d3 HEAD` touches only the iteration
file's post-freeze Builder Prompt/Builder Report sections + space.yaml (the one
deletion is the scaffold's prompt placeholder comment — frozen Grounds/Spec/AC
bytes untouched). Evidence transcribed verbatim (core 180 l, rig 101 l).

Cold gate at base (repos/tart @ cac2612): the EXACT pre-declared calibration —
18 GREEN / 4 RED. GREEN: suite, bench, s1–s10, s1-tart-mode, both probes,
wire-bodies, session-golden, scope (vacuous at base as declared). RED:
hooks-semantics/memory-module/herdr-reporter (clean NameErrors) + s11 (exit 2).
My judge environment is HERDR_*-clean (s1–s10 cold PASS proves it), so CORE
PHASE 0 #6's pane-env hazard does not affect the judge battery.

## PHASE 0 dispositions (every item ruled; judge-reproduced before charging)

Frozen-gate defects — the I45/I41 precedent governs (record; frozen sections
never amended; judge runs minimal repaired copies). All three REPRODUCED BY ME
on the core worktree, verbatim, before charging:

1. **herdr-reporter bare abort — CONFIRMED GATE DEFECT.** The frozen cmd has
   `dead.report_session(ref, pane_id: "p7"); abort "socket failures must be
   swallowed";` — an UNCONDITIONAL abort; verbatim run → exit 1 "socket
   failures must be swallowed". Unsatisfiable by any implementation. My repair
   (drop the one abort statement, nothing else) → HERDR_REPORTER_OK.
2. **hooks-semantics unsubscribe expectation — CONFIRMED GATE DEFECT.** After
   `un.call` (the 99-handler), handlers 1 and 3 REMAIN subscribed; the second
   emit legitimately appends. Verbatim run → exit 1 "unsubscribe broken:
   [1, 3, 1, 3]". One-shot handlers would contradict pi semantics (handlers
   live for the process) AND the herdr gate (one instance, many events). My
   repair (expected `[1, 3, 1, 3]`) → HOOKS_SEMANTICS_OK; the assert's evident
   intent (99 never runs) holds.
3. **captured_requests.first["body"] — CONFIRMED GATE DEFECT ×3 sites.**
   MockLLMServer stores the parsed body directly (`@requests << parsed_body`,
   mock_llm_server.rb:150 — test/support is frozen); `["body"]` is nil.
   Verbatim memory-module run → NoMethodError. My repair (drop the `["body"]`
   link) → MEMORY_MODULE_OK; hooks repaired copy carries the same fix twice.
4. **memory byte-bound arithmetic — GATE LITERAL IS THE DEFECT; builder's
   gate-compatible deviation ACCEPTED with the true divergence family
   recorded.** Verified against the owner's memory.ts boundIndex (cost =
   bytes+1, budget 25,600): the gate's 3×10,015-byte case keeps TWO lines
   (10,016 + 10,016 = 20,032 ≤ 25,600) → the TS-verbatim observable is 4
   content lines, but the gate pins `== 3`. No implementation satisfies both
   the gate literal and memory.ts. The builder implemented the minimal
   formula reproducing the gate's pinned observable (reserve one extra
   line-cost), documented at Store#bound_index, constants byte-exact, the
   205-line case untouched. SCRUTINY CORRECTION the human should see: the
   code comment's claimed divergence family ("lines > ~12.8KB — unreachable
   for real indexes") UNDERSTATES it — the true family is ANY index where the
   25KB byte bound fires with the remaining budget in [c, 2c): tart then
   drops exactly the last line pi keeps (e.g. uniform 161-cost summaries:
   pi 159 lines, tart 158). One-line, wire-only, >25KB-indexes-only, inside
   the letter-named memory-recall observable whose most specific frozen
   definition is this gate. Non-blocking. FOR THE HUMAN: revert
   `bytes + (cost * 2)` → `bytes + cost` + re-pin the gate literal to `== 4`
   (one line each) if pi-exact recall bytes are wanted at the bound, or ratify
   the gate literal as tart's contract. Either is a future-freeze edit, not
   this verdict's.
5. **wire-bodies path sensitivity — CONFIRMED, joins the s9 artifact family.**
   The frozen scrub leaves the absolute sandbox prefix in the hashed bytes;
   the expected digest encodes the repos/tart path. Judge control at base:
   WIRE_BODIES_OK cold; the integrated-tree run below is the green proof.
   Recorded, not amended.
6. **Builder-pane HERDR_* env — ACCEPTED as documented.** Correct per-letter
   behavior when the env gate is genuinely on; the builder's scrubbed-battery
   controls isolate the delta. Backlog note: the rig scrub list may grow
   HERDR_* for herdr-managed builder panes (rig tree frozen this lane).
7. **lib/tart.rb outside the touch set — ACCEPTED.** The requires ride
   agent/loop.rb (in-set); no frozen file touched; no behavior change.
8. **Render at :message_start only — ACCEPTED.** The letter's literal
   both-arms enqueue double-renders vs the one-block Grounds §6 oracle; pi
   renders at message_start (interactive-mode.ts:3498-3502); :message_end's
   custom case no-ops. Pinned in transcript_test.
9. **Recall-content trailing newline — ACCEPTED, itemized.** The frozen gate
   pins it; pi's injected content lacks it; screen-invisible; s11 green.
   Wire micro-divergence (one "\n" on a user-role message) inside the
   letter-named observable; recorded for the human with #4.
10. **Event/context key normalization — ACCEPTED.** String events + symbol
    context, one table; no letter conflict; documented as the contract.

RIG PHASE 0:

11. **Project-key deviation — ACCEPTED; it is what makes the parity gate
    real.** Live-proven: memory.ts's gitRoot walk ascends PAST the sandbox
    when the out dir sits inside a git checkout (the lane worktree's key is
    `wt` — I verified the staged dir `…/.pi/agent/memory/wt/` and the capture
    carries the recall block). With the letter's hard-coded keys the pi side
    reads NOTHING — the scenario would compare tart's recall block against
    pi's absence: vacuous. The runner mirrors memory.ts's exact key rule
    (:29-44), siblings share the walked key, and the unit pins cover BOTH the
    letter's assumption-regime (temp sandboxes → literal `pi`/`tart`) and the
    .git-ancestor regime. Specification §6's path pins read as "under the
    memory.ts project key". On the integrated tree both sides compute `tart`.
    Honors the parity intent. Residual recorded: pi-side staged path at
    canonical depth is `.pi/agent/memory/tart/` not the letter's `…/pi/`.
12. **Prompt line-number drift — ACCEPTED** (substance verified identical).
13. **Base both-apps candidate families (unknown settings key, [Context]
    row) — expected at base**, all collapse on integration (verified below).

## OQ dispositions (Grounds §8) — all ACCEPT as recommended, none overridden

OQ-1 memory opt-in gate (DEFAULTS false + `<IDENTITY>_MEMORY`): ACCEPT —
the zero-hook byte bar (wire-bodies/session-golden/s-gates green below with
memory off) is the proof. OQ-2 the `[Extensions] memory.ts` row: ACCEPT —
staged-condition oracle; owner-package divergence itemized, reopen on pain.
OQ-3 gate-arg re-validation fail-safe: ACCEPT (itemized; no consumer ships).
OQ-4 plain-event errors warn+swallow: ACCEPT (pinned, warn text asserted).
OQ-5 herdr wire values stay pi's: ACCEPT (byte-pinned). OQ-6 drop-in loader
CUT to backlog: ACCEPT-as-backlog (seam surface = §1.5 in full). OQ-7
plain-String block/error results: ACCEPT (pinned). OQ-8 register_command
no-shadow / register_tool override: ACCEPT (pinned both ways).

## Acceptance criteria

- AC1 (Tart::Hooks seam): **PASS** — my repaired-copy run HOOKS_SEMANTICS_OK
  on the lane tree; suite hooks pins; the `7360fd1e…` tools digest holds on
  the integrated wire-bodies run below.
- AC2 (memory module): **PASS** — my repaired-copy run MEMORY_MODULE_OK;
  settings gate default-off proven by the regression battery; s11 green
  below (the parity headline).
- AC3 (herdr reporter): **PASS** — my repaired-copy run HERDR_REPORTER_OK.
- AC4 (parity + regression + scope): **PASS on the integrated tree** — full
  battery green below incl. s11 BOTH-APPS (the closure proof: red-at-lane,
  green-at-integrated, exactly as calibrated); scope non-vacuous, exactly
  the two lanes' declared file sets (24 + 5, zero overlap, nothing outside).

Diff review vs intent: hooks.rb/memory.rb/herdr.rb/tools/memory.rb faithful
to Grounds §2–§5 (constants, strings, wire shapes byte-pinned); ToolGate
validates first, splat-fresh input, first-block-wins, fail-safe errors,
CancelledError passthrough, declarations preserved; loop drain/emit/terminate
consult per §1.4; session custom_message entry per §2 (non-conversation
persist gate); render one block per the §6 oracle; commands/settings/
system_prompt/print/bin-tart threading per §3–§4a; rig staging per §6 with
the adjudicated key rule. README gains the two named paragraphs only.

## Residual risks (for the human)

1. The three frozen-gate defects leave the VERBATIM gate commands red on ANY
   tree; the frozen literals stand (never amended) with this verdict as the
   repair record. Repaired copies are archived at tmp/i47-repaired-{hooks,
   memory,herdr}.sh (judge-authored, one-intent-each).
2. bound_index reservation (PHASE 0 #4): one-line wire divergence vs pi for
   >25KB indexes at the byte bound; revert+re-pin named above.
3. Recall-content trailing newline (PHASE 0 #9): wire-only micro-divergence
   vs pi, gate-pinned.
4. The owner's git-package pi shows NO [Extensions] row while tart-with-
   memory shows `memory.ts` (OQ-2): one MOTD row divergence in the owner's
   daily-driver side-by-side; reopen on owner pain.
5. Backlog: drop-in .rb loader (OQ-6); HERDR_* in the rig scrub list for
   herdr-managed builder panes (#6); pi-side staged s11 path reads `tart`
   at canonical depth (#11 residual).

DECISION: **CONTINUE** — both lanes integrated in the declared order
(core, then rig); ENTRY 6 (subagents-core) unblocked. The seam ENTRYs 6–7
mount on is proven: registration-order dispatch, tool_call block gate,
register_tool/command merges, and nextTurn injection, all live under s11.
