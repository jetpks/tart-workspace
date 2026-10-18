# I74: session-sink

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 6 —
  `session-sink`. Coordinator deltas at dispatch (authoritative,
  `notes/briefs/i74-spec-task.md`): base = `repos/tart` @ **`8d81291`**
  ("Merge lane/I73-child-env-scrub-core", the I73 integrate tip, tracked
  tree clean). Entries I69 (tart-identity-herdr), I70
  (subagents-default-on), I71 (model-catalogue), I72
  (markdown-parity-revisit) and I73 (child-env-scrub) have LANDED — their
  behavior is baseline (default identity TART; subagents default-on with the
  rig staging the opt-out on every parity path; the vendored catalogue +
  live listing; the 48-case markdown battery; the ChildEnv scrub at every
  spawn seam).
- **The I73 env-scrub workaround is MOOT** (coordinator delta): the
  standing `env -u RUBYOPT … architect …` prefix is no longer required for
  architect-CLI calls from bundle-exec'd contexts — retain it only if a
  poisoned parent is observed in practice.
- **Measured base suite THIS session (fresh, cold, never predicted):** the
  first full run hit the standing chat-interrupt 900 s gate-hang class
  (note-and-pass per the frozen ledger); the COLD re-run →
  **1316 runs / 6237 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0, 229.0 s wall** (identical to the I73 integrate record), plus
  `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
  **`SEAM_BENCH_OK`**. This is the frozen regression floor.
- **Owner-backlog residuals NOT re-litigated here** (coordinator delta):
  the s9 frozen gate form's deep-tree out-dir geometry and the
  herdr-wire-probe 105-byte unix-socket path geometry. The lane-tree
  pre-declarations in the AC preamble carry their standing classes.
- The observation deck (the mouth's server) is a SIBLING SPACE on this
  disk: `~/architect/spaces/20261014-all-fax-no-printer` —
  `repos/pi-extensions/session-sink.ts` (THE contract reference) and
  `repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb` +
  `lib/space/server/normalizer/pi.rb` (the parser) are read there
  READ-ONLY this session; nothing was written into that space.

### The mouth contract (frozen at I08 on the deck side — cited, not restated)

- `repos/pi-extensions/session-sink.ts` (read line-by-line this session):
  - tuning (:29-40): `QUEUE_CAP 2000`, `DEBOUNCE_MS 250` (frozen ceiling
    ≤ 500 ms), `POST_TIMEOUT_MS 8000`, `MAX_ATTEMPTS 3`,
    `RETRY_BACKOFF_MS [500, 1000]`, `SHUTDOWN_WAIT_MS 1000`,
    `SHUTDOWN_POST_TIMEOUT_MS 2000` — total shutdown work ≤ ~3 s.
  - config (:50-90): `~/.pi/agent/session-sink.json`
    `{host, token, disabled}` + env overrides evaluated per field (env
    beats file both ways — for `disabled` ANY present env value decides:
    `"1"`/`"true"` mutes, any other present value unmutes); unreadable or
    malformed file = `{}` = unconfigured: inert and silent.
  - record ids (:185-190): content records `"<session-id>/<n>"`, n
    monotonic per session ACROSS rebinds, seeded at bind from the session
    file (count the entries the sink would emit; over-count safe,
    under-count not).
  - record projection (:221-240): `message_end` for roles user/assistant
    ONLY; `tool_execution_end` for every tool call incl. nested
    (`parentToolCallId`); the session record opens EVERY body (re-sent
    session records resolve to the same conversation — metadata no-op
    server-side); everything else skipped.
  - headers (:505-513): `Authorization: Bearer <token>`,
    `Content-Type: application/x-ndjson`, optional `X-Space-Slug`,
    `X-Parent-Session-Id`, `X-Agent-Name`, `X-Agent-Role`, and
    `X-Session-Complete: true` on the terminal POST (one-shot, no retry).
  - containment: enqueue-only handlers, ≤ 1 in-flight POST, order
    preserved, every failure caught, nothing thrown into the host;
    unconfigured/disabled = fully inert (zero queueing, zero network, no
    log noise); the token NEVER appears in any URL or error text.
- Server side (same space): `ingest.rb` — first record must be
  `{"type":"session", …, "version": N}` (`Normalizer.select` keys on
  `type == "session" && key?("version")`); find-or-create by session id;
  per-record idempotency on the top-level `id`; terminal header → status
  completed + one-shot terminal frame; **success = HTTP 202**
  (`app/actions/conversations/ingest.rb:39 render_json(res, json, status:
  202)`).
- `normalizer/pi.rb` (the parser the projection must satisfy):
  `message_end` is the SOLE source of message content; the assistant's
  `content` is walked as an ARRAY of typed blocks — `{"type"=>"text"}` →
  text_delta, `{"type"=>"thinking"}` → thinking text_delta,
  `{"type"=>"toolCall"}` (BLOCK_TYPES maps `toolCall`/`tool_use`) →
  tool_use block_open + args; `usage`, `model`, `stopReason` pass through
  (`STOP_REASONS` maps `stop`→end_turn, `toolUse`→tool_use,
  `max_tokens`→max_tokens, unknown verbatim-to-sym); `tool_execution_end`
  supplies tool_result from `result["content"]` (Array of text blocks or a
  plain String), `isError`, keyed by `toolCallId`.

### The projection is REAL WORK — measured this session (the key Grounds finding)

- The deck's own fixtures pin pi's actual `--mode json` bytes
  (`repos/all-fax-no-printer/test/fixtures/files/pi_streaming_session.jsonl`):
  a user message_end is
  `{"role":"user","content":[{"type":"text","text":"…"}],"timestamp":<epoch-ms>}`;
  an assistant is `content` blocks `[{"type":"thinking","thinking":"…","thinkingSignature":"…"},
  {"type":"text","text":"…"}, {"type":"toolCall","id":"…","name":"…","arguments":{…}}]`
  plus `api/provider/model/usage{input,output,cacheRead,cacheWrite,totalTokens,cost}/stopReason/timestamp`;
  a tool_execution_end is
  `{"toolCallId":"…","toolName":"…","result":{"content":[{"type":"text","text":"…"}]},"isError":false}`.
- tart's `Agent::Message#to_h` (message.rb:122-215, the recorded
  empirical shape) carries `content` as a **raw String** (BRIEF-recorded:
  "content is String or nil only"), tool calls as a separate
  `tool_calls` Hash, usage as FLAT `input_tokens`/`output_tokens`/… keys.
  A verbatim `to_h` projection would LOSE the deck-extracted text:
  `content_block_events` walks `Array(content)` → one String "block" →
  `block["type"]` nil → block_open with an unmapped type and NO text
  delta. **Consequence frozen into this spec: the sink PROJECTS the port's
  Message into pi's block shape (the law in the Specification) — it does
  not serialize `to_h` verbatim.**
- The stop-reason vocabulary also maps (port recorded spellings → pi
  stopReason): `stop`→`end_turn`, `tool_calls`→`toolUse`,
  `length`→`maxTokens`, everything else verbatim (`error` stays `error`).
  The port carries no pricing layer (BRIEF §2 house style; recorded
  convention: nothing reported persists nothing) → `usage` maps the four
  reported facts only, NEVER a fabricated `totalTokens`/`cost`.

### The event surface the sink observes (measured at `lib/tart/agent/loop.rb`)

- The loop emits eleven types through the hooks seam; the sink subscribes
  exactly THREE channels: `session_start` (bind), `message_end`
  (project user/assistant; skip `:tool` — emitted at :976 for tool
  messages — `:custom` at :905, `:system`), `tool_execution_end` (:981,
  payload `{tool_call:, result:, duration:}`; `tool_call` is the
  `Tart::Agent::ToolCall` Struct id/name/arguments/details).
- The user message_end fires at `add_user_message` (:875-880); the
  assistant at :763 (and the error assistant at :737 — role :assistant,
  projected like any assistant, `finish_reason "error"`); user events the
  recorder persists synchronously right AFTER the emit — the session file
  exists by the first debounced POST (the parent-id law depends on this).
- The tool result contract (chat.rb:262-290): `result` is the tool's raw
  return — a String (verbatim) or a Hash (failures carry
  `{"error" => "…"}`; `result_content` JSON-generates Hash/Array);
  `error_tool_result` (tool-not-found) returns BEFORE the hooks fire —
  no event, nothing for the sink. `isError` is therefore derivable ONLY
  from the result shape: a Hash carrying a truthy `"error"` key.
- The recorder (agent/session.rb `Recorder`) is DO-NOT-TOUCH (the plan's
  constraint; enforced mechanically by the scope gate hard-freezing
  `lib/tart/agent/session.rb`): the sink reads `recorder.id` /
  `recorder.path` ONLY through the hooks context's session ref
  (`{"agent_session_path" => …, "agent_session_id" => …}`, bin/tart
  :637-643). Session-file bytes are the session-golden guard's.

### The seams (cited)

- `lib/tart/hooks.rb` — the I47 seam: plain-channel handlers get
  registration-order dispatch with per-handler StandardError swallowed
  (the containment is structural), the event then forwards UNCHANGED to
  the base sink; `session_start`/`session_shutdown` are plain channels.
- `lib/tart/herdr.rb` — the native-module precedent: env-gated,
  inert-when-off, dedicated sender `Thread` + Mutex/ConditionVariable
  drain, every failure swallowed. The sink mirrors the shape (config
  resolved per bind instead of per boot — the config FILE can appear
  mid-process).
- `bin/tart` — the register sites: print boot :285-299 (Hooks built,
  Memory/Herdr registered, `session_start` emitted at :298; the post-run
  drain at :344-356 runs BEFORE `exit code` at :357 — the quit emission
  point); TUI boot :416-494 (Hooks built at :418, registers :424-425,
  `quit: -> { kernel.stop! }` at :529, `kernel.run` returns at :553 — the
  quit emission point).
- `lib/tart/subagents/manager.rb` — child spawn: `spawn_argv_and_env`
  (:345-352) + `child_env` (:370-418; I73: pick source
  `ChildEnv.scrub(@env.to_h)`, CLOSED env, `unsetenv_others` at the
  :176 spawn; the identity picks ride `Identity.env_key(@identity, …)`;
  the live parent recorder is reachable via the `@agent` callable
  (`current_session_path` :355-366)). Each `bin/tart -p` child is a FULL
  tart boot — it reads its own config from its own HOME (the child env
  carries HOME) and its own identity (`TART_IDENTITY` literal).
- `lib/tart/identity.rb` — the env-prefix law (I69): the app env
  namespace follows the resolved identity (`env_key("pi","X")` →
  `PI_X`, `"tart"` → `TART_X`). The architect ruling (plan ENTRY 6):
  **tart's own namespace, NOT ~/.pi** — the config FILE is
  `~/.tart/session-sink.json` (tart's own home, the recorder's
  `default_root` convention), and env overrides are
  identity-namespaced per this law (`TART_SESSION_SINK_*` under the
  default identity; byte-matching pi's own `PI_SESSION_SINK_*` spellings
  when the identity is pi). The bearer token is shared per user (the
  same token value pi's own sink would carry).
- pi-subagents tags every agent child's system prompt
  (`<active_agent name="X"/>`, child-launch.js:208) — the deck contract
  resolves agent headers from that tag. tart's child prompts carry NO
  such tag today (grep-verified: no `active_agent` in `lib/` or `bin/`),
  and ADDING one would move the child LLM wire — forbidden by this
  entry's own regression floor (wire-delta green). The tart-native
  equivalent: the subagents manager PLUMBS the agent label + the parent
  session id into the child env (identity-namespaced sink keys); the
  sink resolves agent headers from the prompt tag when present, else the
  env plumbing, else omits the headers. This closes the pi extension's
  known boundary natively: foreground subagent children never load
  ambient extensions (pi-subagents design), but tart's children ARE tart
  boots — the sink registers in them like any print boot.

### Standing environment (carried, updated for the I73 landing)

Oracle: the pinned `repos/pi` clone @ v1.1.0 (branch `oracle-v1.1.0`) is
ENVIRONMENT guarded by `oracle-pin-state` — never re-performed from a
lane; `env -u PI_PACKAGE_DIR` for every direct oracle exec; the judge
runs gates at the LANE tree; scenario out dirs stay SHORT (≤ ~10 chars
rel the tart root); carry audit BEFORE every rehearsal; freeze ONLY on a
fresh clean rehearsal stamp. The architect-CLI env scrub from
bundle-exec'd contexts is MOOT since I73 (retain only on observed
poison). Routing rides `architect.yaml` as-is; the model-window tick is
DEAD. Landing is the human's.

### Prior handoffs

`notes/spec-digest-20261018T052855Z-child-env-scrub.md` (I73 — the
carry-audit/rehearsal/freeze mechanics, the no-apostrophes `-e` lesson,
the short-out-dir law, the flake ledger, the successor protocol:
coordinator owns the prompt copy at dispatch);
`notes/briefs/i74-spec-task.md` (the coordinator deltas: base, the moot
scrub, the sibling-space grounds, the owner-backlog exclusions); the I73
Verdict for the standing lane-tree geometry classes (s9 wrap,
herdr-wire-probe socket path) — NOT re-litigated here.

## Specification

### Objective

Close plan ENTRY 6 (`notes/plan-20261017T183001Z-tart-standalone.md`):
tart streams its sessions live to the all-fax-no-printer observation deck
— DIRECT native integration over the I47 hooks seam (BRIEF §6: features
built in natively over the minimal internal seam), not via any pi
extension. The mouth contract is frozen deck-side (I08, Grounds above);
this entry builds tart's side of it: a native `Tart::SessionSink` module
that OBSERVES the agent loop's event stream (the recorder's session bytes
are untouched — the sink rides the seam, never the session file), plus
boot wiring, plus subagent-child capture (the pi extension's known
boundary closed natively: every `bin/tart -p` child is a full tart boot
and streams its own session).

### THE MODULE (frozen — `lib/tart/session_sink.rb`, `Tart::SessionSink`)

One new file, the herdr.rb shape (module + engine class, one dedicated
flusher `Thread`, Mutex + ConditionVariable; the ONE new sanctioned
`Thread.new` site in `lib/` — the threads-budget gate carries a declared
exclusion for exactly this path). No recorder edits; no UI; no wire.

#### The config law (AC1)

- File: `<Dir.home>/.tart/session-sink.json` — `{"host", "token",
  "disabled"}` (tart's own home, NOT `~/.pi` — the architect ruling;
  overridable as a parameter for tests). Unreadable/malformed/non-object →
  `{}` (unconfigured; silent — never a log line).
- Env overrides, identity-namespaced per the env-prefix law
  (`Identity.env_key(identity, …)`): `<IDENTITY>_SESSION_SINK_HOST`,
  `<IDENTITY>_SESSION_SINK_TOKEN`,
  `<IDENTITY>_SESSION_SINK_DISABLED`. Env beats file both ways, exactly
  pi's semantics: host/token — the env value wins when non-empty, else
  the file's; disabled — ANY present env value decides (`"1"`/`"true"`
  → disabled; any other present value → enabled), else the file's
  `disabled == true`.
- Configured ⇔ host non-empty AND token non-empty AND not disabled.
  Unconfigured/absent/malformed/disabled → **fully inert**: zero
  queueing, no capture bound, zero network, zero log noise (the herdr
  discipline). Config is resolved at EVERY bind (session_start), not at
  boot — a file that appears mid-process arms the next session; a stale
  capture never re-resolves.
- `ingest_url(host)`: trailing slashes stripped + `/conversations/ingest`.
- The frozen tuning (constants, pinned by gate):
  `QUEUE_CAP = 2000`, `DEBOUNCE_MS = 250` (≤ 500 ceiling),
  `POST_TIMEOUT_MS = 8000`, `MAX_ATTEMPTS = 3`,
  `RETRY_BACKOFF_MS = [500, 1000]`, `SHUTDOWN_WAIT_MS = 1000`,
  `SHUTDOWN_POST_TIMEOUT_MS = 2000` → total shutdown work ≤ ~3 s. A
  `tuning:` kwarg (register-time, test seam only) may shrink the timing
  constants; production callers pass nothing.

#### The projection law (AC2) — the three record shapes, pi's `--mode json` bytes

- Session record (minted at bind, opens EVERY body):
  `{"type":"session","version":Tart::Agent::Session::CURRENT_VERSION,
  "id":<session-id>,"timestamp":<bind-time ISO-8601/Z>,"cwd":<context
  cwd>}`. (The minted timestamp is the sink's bind time, not the
  recorder's header timestamp — the server keys on `id`; re-sent session
  records are metadata no-ops. Declared.)
- Content records: top-level `"id"` = `record_id(session_id, n)` →
  `"<session-id>/<n>"`, n monotonic per session id ACROSS rebinds. At
  bind the counter seeds from the session file: count `type=="message"`
  entries whose `message.role` is `user`, `assistant`, or `tool` (the
  PORT's recorded spelling — pi counts `toolResult`; the port's recorded
  byte family uses `tool` — declared adaptation), skipping
  `custom_message`/`compaction`/`session` entries; unreadable file → 0;
  over-count safe, under-count not; `max(counter, seed)`.
- `message_end` (roles user/assistant ONLY; `tool`/`custom`/`system`
  and every other event type → nil, not emitted):
  - user: `{"type":"message_end","id":…,"message":{"role":"user",
    "content":[{"type":"text","text":<content>}],"timestamp":<emit
    epoch-ms>}}`.
  - assistant: `message` = `{"role":"assistant","content":<blocks>,
    "timestamp":<emit epoch-ms>}` where blocks, IN ORDER: the thinking
    block `{"type":"thinking","thinking":<text>,"thinkingSignature":
    <signature>}` when `message.thinking&.text`; the text block
    `{"type":"text","text":<content>}` when `content` is a String;
    then one `{"type":"toolCall","id":…,"name":…,"arguments":…}` per
    tool call in provider (insertion) order. Optional passthrough keys
    (present-only): `"provider"`, `"model"`, `"usage"`,
    `"stopReason"`, `"errorMessage"`.
  - `usage` mapping (the port's reported facts, camelCase per pi's
    stream; NOTHING fabricated): present only when any of
    input/output/cache_read/cache_write is reported positive; keys
    `input` (when positive), `output` (when positive), `cacheRead`
    (when positive), `cacheWrite` (the port's recorded convention:
    reported-or-0). NO `totalTokens`, NO `cost` (no pricing layer).
  - `stopReason` mapping: `stop`→`end_turn`, `tool_calls`→`toolUse`,
    `length`→`maxTokens`, everything else verbatim (`error` → `error`);
    absent finish_reason → key omitted.
- `tool_execution_end` (every tool call):
  `{"type":"tool_execution_end","id":…,"toolCallId":<call.id>,
  "toolName":<call.name>,"result":{"content":[{"type":"text","text":
  <content>}]},"isError":<bool>,"durationMs":<int ms>}` plus
  `"parentToolCallId"` when the event carries it (no emitter today —
  the projection is ready, pinned). `content` follows the port's
  `result_content` law (chat.rb): String verbatim, Hash/Array
  JSON-generated, else `to_s`. `isError` ⇔ the raw result is a Hash
  carrying a truthy `"error"` key.
- Serialization: `JSON.generate` per line, LF-joined; key order is the
  constructor order above (stable bytes, no sorting).

#### The header law (metadata, resolved lazily at FIRST POST — the system prompt may not be built at session_start)

- `Authorization: Bearer <token>`, `Content-Type: application/x-ndjson`
  on every POST. Optional headers present-only:
- `X-Space-Slug`: walk up from the bind cwd for `space.yaml`
  (YAML.safe_load; malformed → treated as absent, walk continues);
  slug = `slugify(title)` (downcase, `[^a-z0-9]+`→`-`, trim edge
  dashes) when the title is a non-empty String, else the `id`; no
  space.yaml to the filesystem root → header omitted (the server groups
  by the session record cwd).
- `X-Parent-Session-Id`, priority order: (1) the recorder file's header
  `parentSession` (a session FILE path) — resolve its id from that
  file's FIRST line `"id"` (bounded first-line read, never the whole
  file), fallback the `_<uuid>.jsonl` filename segment; (2) the env
  `<IDENTITY>_SESSION_SINK_PARENT_SESSION_ID` pick (a bare session id,
  verbatim); (3) omitted. (The port's resume model forks to a NEW
  session id, so (1) covers resumed/fork binds that have turned; (2) is
  the subagent-child plumbing; a resumed session that never turns
  omits the header — harmless metadata, declared.)
- `X-Agent-Name` / `X-Agent-Role`: (1) the system prompt opens with
  `<active_agent name="X"/>` (regex
  `/\A\s*<active_agent name="([^"]*)"\s*\/>/`, the deck contract's
  source seam) → name X; (2) else the env
  `<IDENTITY>_SESSION_SINK_AGENT_NAME` pick (the tart subagent-child
  seam — pi-subagents tags prompts; the port plumbs the label, keeping
  the child LLM wire untouched); (3) else both omitted. Role =
  the name with a leading `architect-` prefix stripped, else the name.
- `X-Session-Complete: true` on the terminal POST only.

#### The engine law (AC3) — containment, the herdr discipline

- `register(hooks:, identity: Identity::DEFAULT, env: ENV,
  config_path: <default>, system_prompt: nil, tuning: {})` — subscribes
  `session_start`, `message_end`, `tool_execution_end`,
  `session_shutdown` on the seam. Registration is unconditional (config
  resolves per bind). `system_prompt:` is a callable (or String)
  evaluated lazily at first POST.
- `session_start`: previous capture bound → flush it NON-terminally
  (best-effort splice + POST) and unbind; resolve config; unconfigured →
  no capture (inert); bind a new capture (session id/file from the
  context session ref, cwd/mode from the context, counter seeded).
- `message_end`/`tool_execution_end`: project (nil-projection = skipped,
  consumes NO id); enqueue-only — mutex + signal, never a POST on the
  caller's thread. Queue cap: overflow drops the OLDEST records and
  reports the loss.
- ONE flusher thread: ≤ 1 in-flight POST by construction; coalescing
  debounce (first pending enqueue sets due = now + DEBOUNCE_MS; the
  flusher waits to due, splices the WHOLE queue, posts); FIFO order
  preserved end to end.
- POST: `Net::HTTP` (stdlib — no new gems), per-POST connection,
  open/read/write timeouts = the timeout budget; success ⇔ code 202;
  non-202/exception → retry the same batch, `MAX_ATTEMPTS` total, sleeps
  `RETRY_BACKOFF_MS[min(attempt-1, last)]` between attempts; final
  failure → drop the batch + one loss line.
- `session_shutdown` (the boot wiring emits it — below): reason
  `"quit"` → TERMINAL flush, bounded: wait ≤ SHUTDOWN_WAIT_MS for an
  in-flight POST, clear any pending debounce, splice the queue (pending
  content rides the terminal body, order preserved), ONE terminal POST
  with `X-Session-Complete: true`, SHUTDOWN_POST_TIMEOUT_MS budget, NO
  retry — even with an empty queue (the session record alone re-creates
  the conversation completed). Any other reason → non-terminal flush +
  unbind (the rebind case is handled by session_start; today nothing
  emits other reasons). The handler returns within ≤ ~3 s ALWAYS.
- Loss reporting: `session-sink: <first line, ≤ 200 chars>` on stderr;
  the TOKEN never appears in any message. Non-TUI: one line per dropped
  batch; TUI: at most ONE line per capture (bounded noise — the port has
  no ui.notify surface for this; declared deviation from pi's
  notify-then-stderr ladder). Inert captures NEVER log.
- Every handler rescues StandardError (the hooks seam already swallows
  per-handler errors — the sink adds its own belt): nothing thrown into
  the host, ever. Fast::Completions::CancelledError is not raised on
  this path (no reactor involvement).

#### Boot wiring (`bin/tart`, AC3) — the only launcher changes

- Print boot: `Tart::SessionSink.register(hooks:, identity:, env: ENV,
  system_prompt: -> { prompt })` beside the Herdr register (:291);
  AFTER the post-run manager drain (:344-356) and BEFORE `exit code`
  (:357): `hooks.emit({"type" => "session_shutdown", "reason" =>
  "quit"}, context: {cwd: workdir, mode: "print", session:
  session_ref(recorder), identity:})`.
- TUI boot: register beside `Herdr.register` (:425), the same shape;
  after `kernel.run` returns (:553, the quit path — all of ctrl+d /
  ctrl+c-quit / /quit land here): the same `session_shutdown` emission
  with `mode: "tui"` and the CURRENT recorder ref. The emission flows
  through the seam's plain-channel dispatch (handler-order, then the
  base sink; the chat surface's event case has no `:session_shutdown`
  arm — ignored, verified).
- NO MOTD row (RULING, pinned by gate): the sink is silent ambient
  capture — the deck contract's own discipline ("capture must never log
  noise into a session that never asked for it"). herdr got a row
  because it is owner-visible pane state; the sink gets none. No
  `extensions <<` change anywhere; `lib/tart/render/` is hard-frozen by
  the scope gate.
- The `session_start` contexts are byte-unchanged (no new context keys —
  the parent-id law reads the recorder file, not the context).

#### Subagent children captured (AC4) — the manager plumbing (`lib/tart/subagents/manager.rb`)

- `child_env` grows exactly FIVE identity-namespaced picks (the env
  stays CLOSED — `unsetenv_others`; the I73 scrub source unchanged):
  `SESSION_SINK_HOST`, `SESSION_SINK_TOKEN`, `SESSION_SINK_DISABLED`
  (present-non-empty pass-throughs from the scrubbed source env —
  env-configured parents propagate; FILE-configured parents need no
  pick, the child reads the same file via its HOME), plus
  `SESSION_SINK_AGENT_NAME = run[:agent]` and
  `SESSION_SINK_PARENT_SESSION_ID = <the live parent recorder id>` (the
  same `@agent` resolution `current_session_path` uses; nil → key
  omitted). All via `Identity.env_key(@identity, …)`.
- Each child is a full print boot: its own sink registers, binds its
  OWN session id, streams its own records, terminal-POSTs at its exit —
  with `X-Parent-Session-Id` (env plumbing; fork children also carry the
  header route) and `X-Agent-Name`/`X-Agent-Role` (the label; role =
  label sans an `architect-` prefix). The pi extension's boundary
  (foreground subagent children never load ambient extensions) is closed
  natively: tart's children ARE tart boots.

### Tests (the builder's pins, filter-frozen by the gates)

- NEW `test/session_sink_test.rb`:
  - `/config_law/` ≥ 8: file/env both ways (host/token non-empty env
    beats file; empty env falls to file; DISABLED any-present-value
    semantics both directions), malformed file = unconfigured, absent =
    unconfigured, disabled = unconfigured, `ingest_url` form, inert
    discipline (unconfigured → register binds nothing on session_start),
    tuning constants.
  - `/projection/` ≥ 10: the three record shapes (user, assistant with
    thinking/text/toolCall blocks, tool_execution_end), the id law +
    monotonicity + skip-consumes-no-id, the seeding law (user/assistant/
    tool counted; custom_message/compaction not; unreadable → 0; max
    with the in-process counter), the stopReason map, the usage map
    (reported-or-0 cacheWrite; all-unreported → key omitted),
    isError (String vs `{"error" => …}` Hash), parentToolCallId
    present-only, skip rules (tool/custom roles → nil; other types →
    nil), `space_slug_for` (title slug, id fallback, malformed-yaml
    walk, none → nil), agent headers (tag, architect- role strip, env
    fallback, neither → nil), parent-id resolution (header file →
    first-line id → filename fallback; env; omitted).
  - `/engine/` ≥ 8 (module-level, mock ingest, tuned-down constants):
    debounce coalescing (two quick events → ONE POST with both records
    in order), queue-cap overflow drops the OLDEST + a loss line, ≤ 1
    in-flight + FIFO order under a slow mock, retry (500, 500, 202 →
    the batch lands on attempt 3 with tuned backoff), final failure →
    drop + one loss line + the engine keeps accepting, session_start
    rebind flushes the previous capture non-terminally, terminal
    shutdown bounded (a dead host → the handler returns within the
    tuned bound, no raise), the token never appears in any loss line.
  - `/boot/` ≥ 5 (process-level, Open3 like launcher_smoke): the
    driven multi-turn session (mock LLM: a bash tool-call turn, then
    the final text) against the mock ingest server → received records
    assert the contract end to end (session record opens every body,
    ids `<sid>/<n>` monotonic, the four content records in order,
    headers bearer/content-type/X-Space-Slug, the terminal POST with
    `X-Session-Complete: true` arriving BEFORE process exit, no
    X-Parent/X-Agent on a plain boot); inert legs — no config → zero
    connections; malformed file (no env) → zero; DISABLED env over a
    good file → zero.
  - `/child_capture/` ≥ 4: the child_env picks through the PUBLIC
    `spawn_argv_and_env` (the five key spellings identity-namespaced,
    values from the parent env/recorder, absent → keys omitted); a
    real child round-trip (the subagents_test spawn pattern, mock LLM
    + mock ingest): the child session record carries its OWN id ≠ the
    parent's, `X-Parent-Session-Id` == the parent recorder id,
    `X-Agent-Name`/`X-Agent-Role` == the plumbed label, content records
    present, terminal POST at child exit.
- NEW `test/support/mock_ingest_server.rb` (the MockLLMServer pattern —
  test support, NOT shipped code): TCPServer, accept thread, minimal
  HTTP parse (request line, headers downcased, Content-Length body),
  records `{headers:, body:}`, scripted responses (202 default; a
  per-connection fail script for retry legs), `#url`, `#posts`
  (synchronized), `#wait_posts(n, timeout)`, `#connections`, `#stop`.
- `test/subagents_test.rb`: +1–2 `/child_env/` pins for the five new
  picks (the standing I73 pins keep holding — the poison/PATH/identity
  legs are untouched by additive picks).

### Frozen expectations (do not redesign)

- **Session-file bytes unchanged** — the recorder is untouched (the
  scope gate hard-freezes `lib/tart/agent/session.rb`; the session-golden
  guard carries byte-identical). **LLM wire untouched** — wire-delta
  (instruction `4209f40b…`, tools `7360fd1e…`), zai wire, and every
  frozen wire/screen/session digest carry EXACT (the sink observes
  events; it never emits onto the model wire, renders, or records).
- No UI noise: no MOTD row (the ruling above), no `extensions` list
  change, no footer/render change — `lib/tart/render/` hard-frozen.
- No rig scenario-content edits; no new gems (Net::HTTP is stdlib); no
  Gemfile/lock/gemspec changes; the ONE new `Thread.new` site is
  `lib/tart/session_sink.rb` (the threads-budget exclusion, declared).
- The herdr module, the Memory module, the subagent argv/timeout
  machinery, the ChildEnv law and its four arms: byte-preserved (the
  manager's child_env grows only the five declared picks).
- The frozen out dirs (`t74s1`…`t74s10`, `t74s17`, `t74s1t`, `t74tp`,
  `t74ub`, `t74wir`, `t74zwr`, `t74hwp`, `t74mot` — SHORT, ≤ 5 chars
  rel the tart root) carry the s9/herdr geometry precedents (AC
  preamble).

### Named exclusions (Constraints, itemized)

- The plan's post-landing follow-ups (owner backlog, NOT loop work):
  model-window automation re-arm; tart PR-to-main decision; the s9
  gate out-dir rebase / herdr-wire-probe socket-path re-freeze /
  wire-delta constant correction (the I72/I73 verdict residuals,
  carried in their frozen forms — NOT re-litigated).
- The live deck itself (a real host + token) is the owner's
  post-landing checkpoint — the loop proves against the mock ingest
  server only; nothing in the loop POSTs anywhere but 127.0.0.1 test
  servers.
- `problems.md`/`ARCHITECT.md` annotations are LANDING work
  (architect-owned), not lane work.
- Server-side deck behavior (dedup, terminal frames) is out of tart's
  scope; the sink's obligations end at well-formed 202-expected POSTs.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands
  the tree). The deliverable is the provisioned worktree's diff vs
  `8d81291`, exactly: `lib/tart/session_sink.rb` (NEW, MUST differ —
  the core touch), `bin/tart`, `lib/tart/subagents/manager.rb`,
  `test/session_sink_test.rb` (NEW),
  `test/support/mock_ingest_server.rb` (NEW), `test/subagents_test.rb`.
- Scratch report at `build/I74-session-sink-core/report.md`: the suite
  summary line, the FULL 74-gate table (every gate, one measured
  one-liner each — itemize-and-defend), deviations itemized, a final
  `STATUS:` line.

### Tool guidance

- Verification (exact, measured at base `8d81291` this session):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1316 runs, 6237 assertions, 0 failures, 0 errors, 1 skips`, exit 0
  (post-lane: ≥ 1316 runs, 0F/0E); `bundle exec ruby bench/seam_bench.rb
  2>&1 | tail -1` → `SEAM_BENCH_OK`.
- The unit forms: `bundle exec ruby -Ilib -Itest
  test/session_sink_test.rb -n "/config_law/"` → ≥ 8 runs, 0F; the same
  file under `/projection/` (≥ 10), `/engine/` (≥ 8), `/boot/` (≥ 5),
  `/child_capture/` (≥ 4).
- The rig battery at YOUR tree (the lane worktree): the s-gate forms
  verbatim from the Acceptance Criteria (HERDR_* scrub prefix, the
  frozen SHORT out dirs, NO `--pi-bin` flag anywhere).
- Standing flake classes (`chat_test.rb:1613` interrupt-timing BOTH
  forms (failure and 900 s gate-hang), `render_perf_test.rb:265`
  spinner-dwell margin): re-run COLD before adjudicating; note-and-pass
  per the standing ledger.
- Embedded gate `-e '…'` bodies carry NO apostrophes (the I73 rehearsal
  lesson — grep before rehearsing).
- The architect-CLI env scrub from bundle-exec'd contexts is MOOT since
  I73; retain only on observed poison.

### Boundaries

- May touch: exactly the declared 6-path set (scope gate):
  `lib/tart/session_sink.rb` (NEW), `bin/tart`,
  `lib/tart/subagents/manager.rb`, `test/session_sink_test.rb` (NEW),
  `test/support/mock_ingest_server.rb` (NEW), `test/subagents_test.rb`.
- Must not touch: everything else — including
  `lib/tart/agent/session.rb` (THE RECORDER — hard-frozen by the scope
  gate), all of `lib/tart/render/` (the no-MOTD-row law, hard-frozen),
  `lib/tart/tools/find.rb` + `lib/tart/tools/grep.rb`, `lib/tart/herdr.rb`,
  the rig (`gems/tui-split-rig/**`), Gemfile/lock/gemspec, `bench/`,
  `vendor/`, and anything under `repos/pi`.
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.5.0); house style per AGENTS: commented citations
  at the touched seams, tests through public interfaces, no refactors
  beyond the task.

### Lane plan

One lane — one module, four gate families, the standing battery.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/session_sink.rb
    - bin/tart
    - lib/tart/subagents/manager.rb
    - test/session_sink_test.rb
    - test/support/mock_ingest_server.rb
    - test/subagents_test.rb
  effort: medium
```

### Effort call

`medium` — the contract is frozen deck-side with line-cited references
and the projection law is fully specified (the shapes, maps, and
skip-rules leave no design freedom); the engine mirrors the herdr
discipline with the pi tuning carried verbatim; but it still owes four
unit/boot/child gate families (~35 new pins), a new mock server, real
child-process round-trips, and the full 74-gate standing battery.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **74 gates — 69 carried from the I73
frozen block byte-verbatim after the DECLARED rebases + 4 new + 1
rewritten.** The carry audit ran clean BEFORE rehearsal (`tmp/i74-spec/`:
the extracted I73 block vs this one — 69 carried byte-identical after the
declared rebases, 1 declared drop (scope, rewritten per-iteration), 4
new (the session-sink config/projection/engine/child families), zero
duplicate ids, all 74 well-formed YAML). **Declared DROPPED (1):**
`scope` — per-iteration (rewritten here for this lane's 6-path touch
set). **Declared rebases (the carried commands, byte-verbatim except
these, zero semantics unless noted):** the out-dir family `t73*`→`t74*`
(incl. `t73hwp`→`t74hwp`, `t73mot`→`t74mot` — all SHORT, ≤ 5 chars rel
the tart root); the scratch cosmetic `tmp/i73-unused`→`tmp/i74-unused`;
the mktmpdir prefixes `i73-*`→`i74-*` (the `i65-foot-`/`t70rs-` spellings
carry as-is, the I73 precedent); and ONE semantic-bearing declared
rebase: `threads-budget` — diff base `ff235e4`→`8d81291` (this
iteration's base) PLUS the pathspec exclusion
`':(exclude)lib/tart/session_sink.rb'` — the ONE new sanctioned
`Thread.new` site in `lib/` (the sink's flusher; the standing
`lib/tart/models/listing.rb` exclusion rides unchanged). The carried
gates keep their origin `ac:` labels verbatim; the adjudication mapping:
every carried member EXCEPT the two AC6-labeled ones (suite, bench — they
map onto I74 AC6) maps onto **I74 AC5** (standing landed-behavior +
byte-freeze + battery guards).

**The designed-RED vector (5, every one RED at base `8d81291` for the
right reason — the iteration's own work does not exist at base):**
`session-sink-config-units` (`Tart::SessionSink` does not exist at base —
the constants leg dies on the missing module; the `/config_law/` filter
runs 0 tests in a file that does not exist),
`session-sink-projection-units` (same class — the repro leg + 0 filter
runs), `session-sink-engine-e2e` (0 runs on both filters),
`session-sink-child-e2e` (0 runs), `scope` (`lib/tart/session_sink.rb`
does not exist at base — the must-differ leg). **Every other member is
expected GREEN at base.** Measured this session (cold, fresh — never a
predicted floor): the first full suite run hit the standing chat-interrupt
900 s gate-hang class (note-and-pass per the frozen ledger); the COLD
re-run → suite **1316 runs / 6237 assertions / 0F / 0E / 1 skip, rake
exit 0** (229.0 s); `SEAM_BENCH_OK`; the carried members' green at this
base is the I73 judge record (**70/70 PASS cold at the integrated tip
`8d81291`** — this base IS that tip, tracked tree clean).

**Lane-tree geometry pre-declarations (the I72/I73 verdict residuals —
owner backlog, NOT re-litigated here):** the I74 lane tree is ~74 chars
(`I74-session-sink-core` is 5 shorter than I73's — the I71 depth class,
safely INSIDE it). (a) `s9-parity` is expected RED at the lane tree: the
standing AGENTS.md wrap-geometry class (the I71/I72/I73 precedent — the
judge's at-base equal-depth reproduction adjudicates it spec-side, zero
lane attribution; GREEN at canonical depth, where the rehearsal measures
it). (b) `herdr-wire-probe` is the measured GREEN class at ≤ 79-char
geometry (the I70/I73 precedent: the frozen out dir `t74hwp` = the
`t73hwp` length, and the ~74-char tree puts the frozen socket path at
~92 bytes < the 104-byte sun_path bound) — if it REDs by socket-path
geometry, the I69/I72 adjudication class applies. The standing chat
interrupt-timing class (BOTH forms — failure and 900 s gate-hang; it
fired ONCE this session, on the first base-suite run) and the
`render_perf_test.rb:265` spinner-dwell margin stay latent: re-run cold
before adjudicating; note-and-pass per the standing ledger. The rehearsal
measures the true at-base vector; any member that contradicts this
preamble is amended and re-rehearsed before the freeze (the I67/I71
protocol — never freeze on a stale or corrected-without-rerun vector).

**AC1 — the config law, inert discipline, frozen tuning, no UI row.**
`Tart::SessionSink` resolves config exactly per the frozen law:
`~/.tart/session-sink.json` `{host, token, disabled}` (tart's OWN home —
the architect ruling, never `~/.pi`), identity-namespaced env overrides
(`<IDENTITY>_SESSION_SINK_HOST/TOKEN/DISABLED`, env beats file both ways
— disabled: ANY present env value decides), malformed/absent =
unconfigured, unconfigured/disabled = **fully inert** (zero queueing,
zero network, zero log noise — no capture bound at session_start), config
re-resolved at EVERY bind. The frozen tuning constants (QUEUE_CAP 2000,
DEBOUNCE_MS 250 ≤ 500, POST_TIMEOUT_MS 8000, MAX_ATTEMPTS 3,
RETRY_BACKOFF_MS [500,1000], SHUTDOWN_WAIT_MS 1000,
SHUTDOWN_POST_TIMEOUT_MS 2000), the `ingest_url` form, and the NO-MOTD-row
ruling (no `session-sink` row ever joins the extensions list) are pinned.
Gates: `session-sink-config-units`.

**AC2 — the projection law, pi's `--mode json` bytes.** The three record
shapes exactly: the minted session record (type/version/id/timestamp/cwd,
version = the port's CURRENT_VERSION); `message_end` user/assistant ONLY
(tool/custom/system skipped, consuming no id) with content PROJECTED into
pi block arrays (thinking → text → toolCall order, the port's raw-String
content NEVER serialized verbatim — the deck's parser would lose it);
the usage map (reported facts, camelCase, cacheWrite reported-or-0,
nothing fabricated) and the stopReason map (stop→end_turn,
tool_calls→toolUse, length→maxTokens, else verbatim);
`tool_execution_end` with the `result_content` law and the Hash-error-key
`isError` rule; ids `"<session-id>/<n>"` monotonic per session across
rebinds, seeded from the session file (user/assistant/`tool` counted —
the port spelling; custom/compaction never; unreadable → 0; max with the
in-process counter). Gates: `session-sink-projection-units`.

**AC3 — the engine + boot wiring, end to end.** Enqueue-only handlers; ONE
flusher thread (≤ 1 in-flight POST by construction); FIFO order preserved;
coalescing debounce; queue-cap overflow drops the OLDEST loudly; retry the
same batch ≤ 3 attempts with [500,1000] backoff; success = HTTP 202; final
failure drops with ONE bounded loss line (the token NEVER logged); every
failure contained, nothing thrown into the host. Both boots register the
sink beside Herdr and emit `session_shutdown` reason "quit" at their exit
points (print: post-drain pre-exit; TUI: post-`kernel.run`), and the
terminal flush is bounded ≤ ~3 s with `X-Session-Complete: true` on a
one-shot no-retry POST that STILL opens with the session record (re-sent
session records are metadata no-ops server-side — the idempotency law).
The process-level boot legs prove it: a driven multi-turn session
(mock LLM, a bash tool-call turn + final text) against the mock ingest
server — received records assert the contract shapes, ids, headers
(bearer, content-type, X-Space-Slug from the walked space.yaml), and
ordering, with the terminal POST arriving before process exit; the three
inert legs (no config / malformed file / DISABLED env over a good file)
make ZERO connections. Gates: `session-sink-engine-e2e`.

**AC4 — subagent children captured (the pi boundary closed natively).**
The manager's `child_env` grows exactly the five identity-namespaced sink
picks (HOST/TOKEN/DISABLED pass-throughs from the scrubbed source,
AGENT_NAME = the run's agent label, PARENT_SESSION_ID = the live parent
recorder id; absent → keys omitted; the env stays CLOSED); a real
`bin/tart -p` child round-trip streams its OWN session id (≠ the
parent's) to the ingest server with `X-Parent-Session-Id` == the parent
session id and `X-Agent-Name`/`X-Agent-Role` == the plumbed label (role =
architect- prefix stripped), content records in order, and a terminal
POST at child exit. Gates: `session-sink-child-e2e`.

**AC5 — byte-freeze + scope + the standing battery.** (a) Exactly the
declared 6-path touch set changes vs `8d81291` —
`lib/tart/session_sink.rb` MUST differ (the core touch), `bin/tart` +
`lib/tart/subagents/manager.rb` + the three test paths move as declared —
NOTHING else; `lib/tart/agent/session.rb` (THE RECORDER), all of
`lib/tart/render/` (the no-MOTD-row law), `lib/tart/herdr.rb`,
`lib/tart/tools/find.rb`/`grep.rb`, the rig, and the Gemfile family are
hard-frozen by the scope gate (mechanically enforced). (b) Every
standing anchor holds at the lane tree: wire-delta (instruction
`4209f40b…`, tools `7360fd1e…`), session-golden (7/7 — the recorder
untouched), zai wire tart=pi=512, the oracle family, the threads-budget
law (rebased, the sink's ONE site excluded), the markdown battery family,
the child-env law + its four arms, the subagents/I69–I73
landed-behavior gates, and the pty battery (s1–s10, s17, s1-tart-mode)
with the frozen SHORT out dirs — an observing change never moves a
settled wire/session/screen byte. (c) Itemize-and-defend: the builder's
gate table includes EVERY frozen gate — 74 of 74 — an absent entry is a
REJECT-class violation. Gates: `scope` + all 69 carried members.

**AC6 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — ≥ 1316 runs, 0
failures, 0 errors (the standing 1 rig live-run skip unchanged; the new
sink pins grow the count) — and `bundle exec ruby bench/seam_bench.rb`
prints `SEAM_BENCH_OK`. Judge env note (the I59+ standing class): the
three launcher/SystemPrompt pins inside `suite` are
environment-dependent — if present in the judge's env they adjudicate
env-class, exactly as standing. Gates: `suite`, `bench`.

```gates
---
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
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
    added=$(git diff 8d81291 -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
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
    --gate --out t74tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t74ub
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
  cmd: rm -rf t74s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t74s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t74s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t74s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t74s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t74s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t74s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t74s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t74s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t74s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t74s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t74s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t74s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t74s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t74s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t74wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t74wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t74wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t74zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t74zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t74zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
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
    home = Dir.mktmpdir("i74-boot-")
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
    dir = Dir.mktmpdir("i74-hu-")
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
    rm -rf t74hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t74hwp
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
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i74-unused")
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
    rm -rf t74mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t74mot
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
    home = Dir.mktmpdir("i74-vu-")
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
    dir = Dir.mktmpdir("i74-belt-")
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
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: 'git diff --quiet 8d81291 -- Gemfile Gemfile.lock tart.gemspec bench gems lib/tart/render
    lib/tart/agent/session.rb lib/tart/tools/find.rb lib/tart/tools/grep.rb lib/tart/herdr.rb
    && ! (git diff --name-only 8d81291; git status --porcelain | grep "^??" | cut -c4-) |
    grep -vE "^(lib/tart/session_sink\.rb|bin/tart|lib/tart/subagents/manager\.rb|test/session_sink_test\.rb|test/support/mock_ingest_server\.rb|test/subagents_test\.rb|t74[0-9a-z]*/?|tmp/render-perf-gate/?)$"
    | grep -q . && [ -n "$(git diff 8d81291 -- lib/tart/session_sink.rb)" ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 6-path touch set, the
    recorder/render/rig seams moved (session.rb is THE RECORDER, render carries the
    no-MOTD-row law), or session_sink.rb is untouched (the core touch)"; exit 1; } &&
    echo SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Builder lane prompt — iteration `session-sink` (I74), lane `core`

You are the builder for iteration `session-sink` (I74), lane `core`, repo `tart`. You are the ONLY lane.

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I74-session-sink.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (the `Objective`, `THE MODULE`, `Tests`, `Frozen expectations`, `Named exclusions`, `Output format`, `Tool guidance`, `Boundaries`, `Lane plan`, the 74-gate frozen ```gates block). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting reads: `notes/spec-digest-20261018T074028Z-session-sink.md`, `tmp/i74-spec/` scratch, and (READ-ONLY) the deck contract references under `~/architect/spaces/20261014-all-fax-no-printer/` (`repos/pi-extensions/session-sink.ts`, `repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb`).

## Operating constraints (lane)

- Work ONLY in your provisioned worktree: `build/I74-session-sink-core/wt` in the space, on branch `lane/I74-session-sink-core`, base tart `project/pi-port` @ `8d81291`.
- NEVER commit (the integrator lands your tree). NEVER touch the space repo. NEVER push. NEVER write into the sibling all-fax-no-printer space.
- NEVER touch any gem (`ratatui_ruby 1.5.0`, `fast-completions 0.5.0` are dependencies). No new runtime gems (existing HTTP stack only); no Gemfile/gemspec/lock changes.
- NEVER write anything under `repos/pi` (pinned oracle clone @ v1.1.0, read-only). `env -u PI_PACKAGE_DIR` for direct oracle execs.
- Touch set is EXACTLY the 6 paths in `Boundaries`/`Lane plan` (scope gate): `lib/tart/session_sink.rb` (NEW, MUST differ — the core touch), `bin/tart`, `lib/tart/subagents/manager.rb`, `test/session_sink_test.rb` (NEW), `test/support/mock_ingest_server.rb` (NEW), `test/subagents_test.rb`. `lib/tart/agent/session.rb` (THE RECORDER) and all of `lib/tart/render/` are HARD-FROZEN.
- Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root); each gate owns `rm -rf` of its out dir. No rig scenario-content edits.
- Embedded gate `-e '…'` bodies carry NO apostrophes (the I73 rehearsal lesson — grep before rehearsing).
- Standing flake classes (`chat_test.rb` interrupt-timing BOTH forms incl. the 900s gate-hang; `render_perf_test.rb:265` spinner-dwell): re-run COLD before adjudicating; note-and-pass.
- ITEMIZE-AND-DEFEND: your gate table MUST carry EVERY frozen gate — 74 of 74 — each with a measured one-liner. An absent gate is a REJECT-class violation.

## Deliverable + report

- Deliverable: the worktree diff vs `8d81291` — exactly the 6-path set (session_sink.rb NEW + bin/tart wiring + manager.rb child-carry + 3 test files incl. the mock ingest server). NO lane commits.
- Scratch report at `build/I74-session-sink-core/report.md`: the suite summary line, the FULL 74-gate table (one measured one-liner each), deviations itemized, and a final `STATUS:` line.

## Builder Report

### core

# Builder report — I74 `session-sink`, lane `core` (repo `tart`)

Worktree: `build/I74-session-sink-core/wt`, branch `lane/I74-session-sink-core`, base tart `8d81291` (verified HEAD). NO commits (integrator lands the tree). Diff vs `8d81291` = EXACTLY the declared 6-path set (`git status --porcelain`: M bin/tart, M lib/tart/subagents/manager.rb, M test/subagents_test.rb; ?? lib/tart/session_sink.rb, ?? test/session_sink_test.rb, ?? test/support/mock_ingest_server.rb — plus the gates' self-owned `t74*` out-dir scratch).

## Suite summary line

- `bundle install --quiet && bundle exec rake` (gate `suite`, cold, gate-runner run): **`SUITE_OK` — 1368 runs, 6475 assertions, 0 failures, 0 errors, 1 skips, exit 0, 241 s** (floor was 1316/6237/1S at base; +52 runs = 50 new `test/session_sink_test.rb` pins + 2 new `test/subagents_test.rb` /child_env/ pins).
- `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → **`SEAM_BENCH_OK`** (16 s).

### Suite adjudication notes (standing flake + env classes, measured)

- Two earlier full-suite invocations were killed at my 600 s/900 s wrapper timeouts (SIGTERM) and one at 600 s — the standing chat-interrupt timing class (BOTH forms incl. the gate-hang form; the hang sat in the early chat region of the run). Two COLD full re-runs completed GREEN (241 s gate run; one `TESTOPTS=-v` run, same 1368/6475/0F/0E/1S) and every test file also passes individually — note-and-pass per the frozen ledger.
- From 02:56–02:58 the LIVE parent architect loop created `~/.tart/agents/architect-{judge,narrator,spec,builder,coordinator}.md` (the owner's real user-profile tier). After that, full-suite runs at the REAL HOME show exactly ONE failure: `Tart::SubagentsTest#test_unknown_agent_names_the_three` (test/subagents_test.rb:132) — the pin's Profiles scan root is the REAL `~/.tart` by standing design, so the merged "Available agents:" listing now includes the five new user profiles. Base-identical behavior (my diff does not touch Profiles.resolve or that pin's logic — manager.rb only grows additive child_env picks). Same adjudication class as the arch file's declared env-dependent launcher/SystemPrompt pins. Evidence it is env, not code: `HOME=<staged> bundle exec ruby -Ilib -Itest test/subagents_test.rb` → **34 runs, 282 assertions, 0 failures, 0 errors, 0 skips**; the file also ran green at the real HOME before the profiles appeared.
- (A full-suite run under a staged HOME fails a DIFFERENT standing pin — `chat_test.rb:1365` footer `~` abbreviation, which requires the cwd to sit under the real HOME — confirming the suite is real-HOME-bound by design.)

## The 74-gate table (itemize-and-defend — one measured one-liner each)

All gates executed verbatim from the frozen ```gates block (extracted to /tmp/i74-gates.yaml; 74 parsed).cwd repos/tart = the lane worktree. "rr" = re-run after the final test edits — all GREEN.

| # | gate id | result | measured one-liner |
|---|---------|--------|--------------------|
| 1 | suite | PASS | ec=0, 241 s — `SUITE_OK` 1368 runs / 6475 assertions / 0F / 0E / 1S (post-02:58 env: 1 env-class failure, see above; rr) |
| 2 | bench | PASS | ec=0, 16 s — `SEAM_BENCH_OK` |
| 3 | md-repro | PASS | ec=0 — `MD_REPRO_OK` |
| 4 | md-inline-units | PASS | ec=0 — `MD_INLINE_UNITS_OK` (≥3 + ≥1 filter runs) |
| 5 | pending-registry-units | PASS | ec=0 — `PENDING_REGISTRY_UNITS_OK` (≥4) |
| 6 | footer-window | PASS | ec=0 — `FOOTER_WINDOW_OK 1000000` (env tier 999 leg included) |
| 7 | thinking-pins | PASS | ec=0 — `THINKING_PINS_OK` (≥11 + ≥8) |
| 8 | hermeticity | PASS | ec=0, 9 s — `HERMETICITY_OK` (launcher ≥8, e2e ≥4) |
| 9 | lock-deps | PASS | ec=0 — `LOCK_DEPS_OK`/`GEM_LOAD_OK`, fast-completions 0.5.0 in lock, no ruby_llm |
| 10 | zai-data | PASS | ec=0 — `ZAI_DATA_OK` (dialect pins ≥2 + dialect_for bytes) |
| 11 | threads-budget | PASS | ec=0 — `THREADS_BUDGET_OK`; the rebased diff base 8d81291 + `':(exclude)lib/tart/session_sink.rb'` shows no new `Thread.new` in lib |
| 12 | session-golden | PASS | ec=0 — `SESSION_GOLDEN_OK` (7/7 digests byte-identical; the recorder untouched) |
| 13 | strict-wire | PASS | ec=0 — 8 runs, 76 assertions, 0 failures, 0 errors |
| 14 | error-transcript-units | PASS | ec=0 — `ERROR_TRANSCRIPT_UNITS_OK` (≥4 + ≥2) |
| 15 | error-transcript-render-units | PASS | ec=0 — `ERROR_TRANSCRIPT_RENDER_UNITS_OK` (≥3 + ≥2) |
| 16 | render-perf-units | PASS | ec=0 — 7 runs, 29 assertions, 0 failures, 0 errors |
| 17 | render-perf-probe | PASS | ec=0, 146 s — `RENDER_PERF_OK` |
| 18 | tool-pending-gate | PASS | ec=0, 20 s — `TOOL_PENDING_GATE_OK` (out t74tp) |
| 19 | user-bash-stream-gate | PASS | ec=0, 13 s — `USER_BASH_STREAM_GATE_OK` (out t74ub) |
| 20 | zai-max-tokens-units | PASS | ec=0, 3 s — `ZAI_MAX_TOKENS_UNITS_OK` (4+2+2) |
| 21 | rail-bg | PASS | ec=0 — `RAIL_BG_OK` |
| 22 | jump-pill-units | PASS | ec=0 — `JUMP_PILL_UNITS_OK` (≥6) |
| 23 | rail-bg-units | PASS | ec=0 — `RAIL_BG_UNITS_OK` (≥4) |
| 24 | viewport-probe | PASS | ec=0 — `VIEWPORT_PROBE_OK` |
| 25 | oracle-pin-state | PASS | ec=0 — `ORACLE_PIN_OK` (clone @ oracle-v1.1.0 == v1.1.0, clean, cli 1.1.0) |
| 26 | oracle-bin-units | PASS | ec=0 — `ORACLE_BIN_UNITS_OK` (≥5) |
| 27 | oracle-resolve | PASS | ec=0 — `ORACLE_RESOLVE_OK` (pinned cli + flag/env overrides + missing-clone raise) |
| 28 | s1-parity | PASS | ec=0, 5 s — out t74s1 |
| 29 | s2-parity | PASS | ec=0, 5 s — out t74s2 |
| 30 | s3-parity | PASS | ec=0, 5 s — out t74s3 |
| 31 | s4-parity | PASS | ec=0, 5 s — out t74s4 |
| 32 | s5-parity | PASS | ec=0, 5 s — out t74s5 |
| 33 | s6-parity | PASS | ec=0, 5 s — out t74s6 |
| 34 | s7-parity | PASS | ec=0, 5 s — out t74s7 |
| 35 | s8-parity | PASS | ec=0, 5 s — out t74s8 |
| 36 | s9-parity | RED (declared) | ec=1, 7 s — the AC-preamble-declared lane-tree wrap-geometry class: measured diff classes = `unknown-candidate:2` (wrapped-path fragment "demo."/"md"), `staged-path-wrap-fragment:2`, plus the standing known `parity-run-path`/`footer-provider-prefix`; GREEN at canonical depth (the rehearsal measured it there) |
| 37 | s10-parity | PASS | ec=0, 7 s — out t74s10 |
| 38 | s17-parity | PASS | ec=0, 8 s — out t74s17 |
| 39 | s1-tart-mode | PASS | ec=0, 5 s — `TART_MODE_OK` (completed + requests==expected) |
| 40 | wire-delta | PASS | ec=0, 5 s — `WIRE_DELTA_OK` (instruction 4209f40b…, tools 7360fd1e…, key order, store false) |
| 41 | zai-max-tokens-wire | PASS | ec=0, 5 s — `ZAI_WIRE_OK tart=pi=512` |
| 42 | identity-law | PASS | ec=0 — `IDENTITY_LAW_OK` |
| 43 | default-face | PASS | ec=0 — `DEFAULT_FACE_OK` |
| 44 | default-boot | PASS | ec=0 — `DEFAULT_BOOT_OK` (i74-boot- staging; tart preamble + TART_* namespace) |
| 45 | herdr-units | PASS | ec=0 — `HERDR_UNITS_OK` |
| 46 | herdr-wire-probe | PASS | ec=0, 3 s — `HERDR_WIRE_OK` (out t74hwp, ~92-byte socket path < 104 bound) |
| 47 | rig-identity-assert | PASS | ec=0 — `RIG_IDENTITY_OK` |
| 48 | subagents-default-law | PASS | ec=0, rr — `SUBAGENTS_DEFAULT_LAW_OK` |
| 49 | subagents-default-boot | PASS | ec=0, rr — `SUBAGENTS_DEFAULT_BOOT_OK` (default-on digest 2c744efc…, opt-out 7360fd1e…) |
| 50 | subagents-motd-units | PASS | ec=0, rr — `SUBAGENTS_MOTD_UNITS_OK` |
| 51 | subagents-motd-probe | PASS | ec=0, 3 s, rr — `SUBAGENTS_MOTD_OK` (out t74mot) |
| 52 | subagents-e2e-default-on | PASS | ec=0, 37 s, rr — `SUBAGENTS_E2E_DEFAULT_OK` (≥4) |
| 53 | rig-staging-units | PASS | ec=0 — `RIG_STAGING_OK` |
| 54 | vendored-attribution | PASS | ec=0 — `VENDORED_ATTRIBUTION_OK` (byte-identical to the pinned oracle data) |
| 55 | vendored-units | PASS | ec=0 — `VENDORED_UNITS_OK` (≥6 + ≥1 + i74-vu- repro) |
| 56 | listing-units | PASS | ec=0, 6 s — `LISTING_UNITS_OK` (≥5) |
| 57 | model-menu-live-merge | PASS | ec=0 — `MODEL_MENU_LIVE_MERGE_OK` (≥3 + ≥2) |
| 58 | launcher-listing-thread | PASS | ec=0 — `LAUNCHER_LISTING_THREAD_OK` (≥1) |
| 59 | vendored-no-boot-network | PASS | ec=0 — `VENDORED_NO_BOOT_NETWORK_OK` |
| 60 | listing-thread-law | PASS | ec=0 — `LISTING_THREAD_LAW_OK` |
| 61 | md-battery-fixture | PASS | ec=0 — `MD_BATTERY_FIXTURE_OK` (sha 4ecd9cc2…, 48 cases) |
| 62 | md-battery-units | PASS | ec=0 — `MD_BATTERY_UNITS_OK` (≥48) |
| 63 | md-regression-units | PASS | ec=0 — `MD_REGRESSION_UNITS_OK` (≥79) |
| 64 | md-flanking-repro | PASS | ec=0 — `MD_FLANKING_OK` (R1a–I65 legs) |
| 65 | md-micro-perf | PASS | ec=0, 2 s — `MD_MICRO_OK 4.15 ms/conv ratio 2.22` (budgets 8.0 / 3.0) |
| 66 | child-env-law-repro | PASS | ec=0, rr — `CHILD_ENV_LAW_OK` |
| 67 | child-env-units | PASS | ec=0, rr — `CHILD_ENV_UNITS_OK` (≥8) |
| 68 | child-env-site-units | PASS | ec=0, 5 s, rr — `CHILD_ENV_SITE_UNITS_OK` (bash ≥2, subagents ≥1, mcp ≥1) |
| 69 | bash-child-env-live | PASS | ec=0, rr — `BASH_CHILD_ENV_LIVE_OK` |
| 70 | session-sink-config-units | PASS | ec=0, rr — `SESSION_SINK_CONFIG_UNITS_OK`: /config_law/ 12 runs 0F, no MOTD/extensions row grep hit, `SESSION_SINK_CONSTANTS_OK` (all 7 constants + ingest_url frozen) |
| 71 | session-sink-projection-units | PASS | ec=0, rr — `SESSION_SINK_PROJECTION_UNITS_OK`: /projection/ 17 runs 0F + `SESSION_SINK_PROJECTION_REPRO_OK` (the full frozen repro: shapes, maps, skip rules, ids) |
| 72 | session-sink-engine-e2e | PASS | ec=0, 7 s, rr — `SESSION_SINK_ENGINE_E2E_OK`: /engine/ 12 runs 0F + /boot/ 5 runs 0F |
| 73 | session-sink-child-e2e | PASS | ec=0, 4 s, rr — `SESSION_SINK_CHILD_E2E_OK`: /child_capture/ 4 runs 0F (five env picks + real `bin/tart -p` child round-trip) |
| 74 | scope | RED (structural) | ec=1 — the must-differ leg `git diff 8d81291 -- lib/tart/session_sink.rb` is EMPTY because the file is UNTRACKED in the no-commit lane tree (git add forbidden); the other two legs measured clean: `git diff --quiet 8d81291 -- <frozen paths>` exit 0, and the 6-path bite filter `grep -vE …` output EMPTY; turns GREEN when the integrator tracks the file |

Tally: 72 PASS / 2 RED, both REDs non-code and pre-declared (36 = the AC-preamble geometry class; 74 = structural untracked-file blindness in a never-commit lane tree).

## New pins delivered (filter counts, all 0F)

- `test/session_sink_test.rb` — 50 runs total: `/config_law/` 12 (≥8), `/projection/` 17 (≥10), `/engine/` 12 (≥8), `/boot/` 5 (≥5), `/child_capture/` 4 (≥4).
- `test/subagents_test.rb` — +2 `/child_env/` pins (`test_child_env_session_sink_picks_the_five_identity_namespaced_keys`, `test_child_env_session_sink_picks_omitted_when_the_parent_has_none`); file total 34 runs.
- `test/support/mock_ingest_server.rb` — the MockLLMServer pattern: TCPServer/accept-thread, minimal HTTP parse, `{headers:, body:, records:}` posts, per-connection fail script + delay, `#url/#posts/#post_count/#connections/#max_concurrent/#wait_posts/#stop`.

## Deviations (itemized)

1. **The sink's require site is `lib/tart/subagents/manager.rb`** (comment-cited in the file): the frozen session-sink gates run `ruby -Ilib -e 'require "tart"'` and expect `Tart::SessionSink` defined, but `lib/tart.rb` and `lib/tart/agent/loop.rb` (herdr's require site) are outside the frozen 6-path touch set. The manager is the ONLY require-"tart"-reachable touch-set path (lib/tart.rb → print.rb → subagents.rb → manager.rb — verified), and the sink is semantically coupled to the manager's child-capture law. bin/tart also requires the file directly.
2. **`test/subagents_test.rb` sanctioned-env list grew the five PI_SESSION_SINK_* spellings** — the standing `assert_empty(env.keys - sanctioned)` closure pin (I49/I69 form) would otherwise fail on the declared unconditional `AGENT_NAME` pick. The I73 poison/PATH/identity legs themselves are untouched and hold.
3. **`prompt = nil` pre-declaration above both register sites** in bin/tart: Ruby 4.0 does NOT capture a local assigned later in the method (a lambda created before the assignment raises NameError at call time — measured). The lazy `-> { prompt }` system-prompt seam needs the local pre-declared.
4. **`Engine#stop` lifecycle**: Ruby 4.0 removed `Thread#daemon`/`daemonize` (measured NoMethodError), so the ONE flusher thread is stopped explicitly — after the terminal POST, via the test seam in teardown, and production exits are safe (print exits via `exit code`; verified Ruby kills cond-waiting threads at main-thread exit).
5. **Boot-test record-order reality**: with the instant mock LLM, the whole driven turn coalesces inside the 250 ms debounce, so the four content records ride the TERMINAL body (observed `message_end user → message_end assistant(toolCall) → tool_execution_end → message_end assistant(final)`, matching the loop's emission order — assistant step fires before the tool batch). The /boot/ pins assert the union across posts in order rather than a fixed post split.
6. **Mock ingest DNS hygiene**: no test points a spawned child at a resolvable name — pin hosts use `http://127.0.0.1:1` (dead loopback); `deck.test` appears only in pure string-transform asserts (ingest_url).

## STATUS: COMPLETE_WITH_CONCERNS
- Concern 1: `scope` gate RED at the lane tree for a structural reason (untracked new file invisible to `git diff 8d81291 -- lib/tart/session_sink.rb`; no git writes allowed) — every other scope leg measured clean; GREEN after the integrator tracks the file.
- Concern 2: `s9-parity` RED at the lane tree per the standing declared wrap-geometry class (owner backlog; adjudicates spec-side at canonical depth).
- Concern 3: post-02:58 environment (live parent loop's `~/.tart/agents/architect-*.md` user profiles) deterministically fails the standing `test_unknown_agent_names_the_three` pin in real-HOME full-suite runs — base-identical behavior, env-class adjudication, staged-HOME file run green (34/0F).
- Concern 4: the frozen session-sink gates' `require "tart"` leg forced the manager.rb require site (deviation 1) — if the architect prefers lib/tart.rb to carry the require instead, that requires widening the touch set (a spec contradiction to resolve at landing).

## Verdict

- **Disagreement rulings** — the builder raised no dispute against the frozen contract; the six itemized deviations are declared adaptations, each ruled for the record:
  - D1 (the sink's require site is `lib/tart/subagents/manager.rb`): **ACCEPT** — the frozen gates require `require "tart"` to define `Tart::SessionSink`, while `lib/tart.rb` and `lib/tart/agent/loop.rb` (herdr's site) are hard-frozen outside the 6-path touch set; the manager is the only require-"tart"-reachable touch-set path (chain verified), and the sink is semantically coupled to the manager's child-capture law — the alternative (widening the scope gate for `lib/tart.rb`) is the spec contradiction, so the builder picked the only consistent resolution.
  - D2 (`test/subagents_test.rb` sanctioned-env list grows the five identity-namespaced sink spellings): **ACCEPT** — additive picks only; the `assert_empty(env.keys - sanctioned)` closure pin keeps its discrimination, and the I73 poison/PATH/identity legs are untouched (judge-verified in the diff).
  - D3 (`prompt = nil` pre-declaration above both register sites): **ACCEPT** — measured Ruby closure semantics (a lambda created before the first assignment raises NameError at call); required for the frozen lazy `system_prompt:` seam; the later assignment mutates the same binding.
  - D4 (explicit `Engine#stop` instead of a daemon thread): **ACCEPT** — Ruby 4.0 removed `Thread#daemon` (measured NoMethodError); the flusher is stopped after the terminal POST and via the test seam; production exits are safe (main-thread exit kills cond-waiting threads).
  - D5 (boot-test record-order reality — the driven turn coalesces into the terminal body; pins assert the union across posts in order): **ACCEPT** — a test-shape adaptation, not a product deviation; the observed order (`message_end user → assistant(toolCall) → tool_execution_end → assistant(final)`) matches the loop's emission order.
  - D6 (mock ingest DNS hygiene — dead loopback hosts only): **ACCEPT** — hygiene discipline; `deck.test` appears only in pure string-transform asserts.

- **Acceptance Criteria integrity** — `architect verify session-sink` **4/4 PASS** (frozen sections untouched, no builder commits, scratch report present, in-bounds; the initial in-bounds FAIL was the `t74*` rig out-dir scratch the battery gates generate — judge-cleared to the I73 no-untracked-residue standard, re-verified 4/4). `git diff 732f5103 HEAD` shows only Builder Prompt + Builder Report appended (transcription verified byte-verbatim in-file). `git -C <lane wt> log 8d81291..` empty; worktree HEAD == base. The judge ran `architect gate session-sink core` COLD at the lane tree: **70/74 PASS**; all four FAILs adjudicated, none a lane defect (below).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | `session-sink-config-units` PASS cold (12 runs ≥ 8 floor, `SESSION_SINK_CONSTANTS_OK` — all 7 tuning constants + `ingest_url` pinned; no MOTD/extensions row); judge read `resolve_config`/`configured?` — file+env both ways, ANY-present-value disabled semantics, malformed/absent = unconfigured, inert discipline (no capture bound when unconfigured) | the frozen config law | PASS |
| AC2 | `session-sink-projection-units` PASS cold (17 runs ≥ 10 + the full frozen repro); judge read the projection code — user/assistant-only `message_end` with PROJECTED block arrays (thinking → text → toolCall order), the usage map (reported facts, cacheWrite reported-or-0, nothing fabricated) and stopReason map exact, `tool_execution_end` under the `result_content` + Hash-error-key isError rules, ids `<sid>/<n>` seeded per the port-spelling law, nil-projections consume no id | the frozen projection law | PASS |
| AC3 | `session-sink-engine-e2e` PASS cold (/engine/ 12 ≥ 8 + /boot/ 5 ≥ 5); judge read the Engine — enqueue-only handlers, ONE flusher thread with post-lock (≤ 1 in-flight by construction), coalescing debounce, OLDEST-drop cap with a loss line, 202-success retry/backoff law, terminal one-shot no-retry POST opening with the session record and bounded ≤ ~3 s; both boots register beside Herdr and emit `session_shutdown` "quit" at the exact frozen points (print post-drain pre-exit; TUI post-`kernel.run`) | the frozen engine law | PASS |
| AC4 | `session-sink-child-e2e` PASS cold (4 runs ≥ 4 — the five env picks through the public `spawn_argv_and_env` + a real `bin/tart -p` child round-trip); judge read the manager diff — exactly the five identity-namespaced picks (present-non-empty HOST/TOKEN/DISABLED pass-throughs, unconditional AGENT_NAME, PARENT_SESSION_ID nil→omitted), the env stays CLOSED, the I73 scrub source untouched | the frozen child-capture law | PASS |
| AC5 | `scope` RED **adjudicated structural**: the must-differ leg is blind to untracked files in a never-commit lane tree — judge-verified the other legs cold (frozen-paths `git diff --quiet 8d81291 -- …` clean; the 6-path bite filter clean; `session_sink.rb` exists, 781 lines, new at base) and confirmed **SCOPE_OK at the integrated tip** (file tracked). **s9-parity RED adjudicated spec-side with the judge's OWN triangle**: lane tree (76 chars) ec=1 classes `2x unknown-candidate, 6x parity-run-path, 2x staged-path-wrap-fragment, 2x footer-provider-prefix`; judge's equal-depth BASE reproduction (`repos/tart` @ `8d81291` cloned at a constructed 76-char path) ec=1 IDENTICAL class shape; judge's canonical-depth BASE (`repos/tart` @ `8d81291`, out `t74s9`) ec=0, zero unknown-candidate — lane RED ≡ equal-depth base RED ≢ canonical GREEN → the pre-declared AGENTS.md wrap-geometry class, ZERO lane attribution. All other 67 carried members PASS cold (wire-delta `4209f40b…`/`7360fd1e…`, session-golden 7/7, zai wire, oracle family, threads-budget rebased+excluded, md battery, child-env family, subagents-default family, pty battery with the frozen SHORT out dirs) | §scope/byte-freeze/battery | PASS |
| AC6 | bench `SEAM_BENCH_OK` cold. `suite` RED **adjudicated env-class**: 1368 runs / 6461 assertions / **1 failure** / 0 errors / 1 skip — the single failure is `Tart::SubagentsTest#test_unknown_agent_names_the_three`, the pre-declared class (the live parent architect loop's `~/.tart/agents/architect-*.md` user profiles vs a pin that scans the real `~/.tart` by design); judge controls: the IDENTICAL failure reproduces at the untouched base `repos/tart` @ `8d81291` under the real HOME, and the lane-tree file run under a staged HOME is green (34 runs / 282 assertions / 0F) — base-identical, zero lane attribution, note-and-pass per the frozen env-class protocol. The ≥ 1316 floor is met (+52 new pins). `render-perf-probe` RED **adjudicated judge-env load**: BP2 render-ms/s 256.1 vs the ≤ 250 budget, and the judge's BASE control fails identically (254.5) under the same machine load (~3.3) — the builder's quiet-box PASS (ec=0, 146 s) stands; zero lane attribution | the standing verification gates | PASS |

- **Iteration** — **CONTINUE** — the diff vs the frozen Specification is faithful at every seam the judge read: one self-contained `Tart::SessionSink` (config law → projection law → engine law, the herdr discipline, the pi tuning carried verbatim), boot wiring at the exact cited points with the no-MOTD-row ruling honored, and the pi extension's known subagent boundary closed natively through five identity-namespaced env picks — an observing change with every settled wire/session/screen byte frozen (67 carried guards green). 70/74 cold at the lane tree; all four FAILs adjudicated (suite env-class judge-reproduced at base; render-perf-probe judge-reproduced at base under load; s9 the pre-declared lane-tree geometry class, triangle-closed; scope the structural untracked-file blindness, GREEN at the integrated tip). STATUS COMPLETE_WITH_CONCERNS matches the deliverable — every concern adjudicated above.

Judge-run evidence this session: gate transcript `build/gate/I74-session-sink-20261018T033948.055192.md` (70 PASS / 4 adjudicated); base pin control (`repos/tart` @ `8d81291`, real HOME, identical failure); staged-HOME lane control (34 runs 0F); s9 triangle (lane / equal-depth base clone `build/I74-s9-base-repro0001/wt` / canonical base, all judge-owned); render-perf-probe base control (BP2 254.5 under load ~3.3); scope legs run manually cold; transcription verified byte-verbatim.

Residuals (owner/loop, none blocking): (1) the live-deck confirmation (real host+token) is the owner's post-landing checkpoint — the loop proved against the mock ingest server only; (2) the `~/.tart/agents/architect-*.md` env class will keep failing `test_unknown_agent_names_the_three` in real-HOME full-suite runs until that pin stages its HOME (owner backlog; base-identical); (3) the s9/herdr gate-geometry residuals stay owner-backlog per the I72/I73 verdicts (NOT re-litigated); (4) `render-perf-probe` BP2 (render-ms/s ≤ 250) measured 254–258 under machine load ~3.3 — the budget has no load guard; a margin or load-note amendment is a candidate for the next spec's carried-gate rebase; (5) the sink's require site rides `manager.rb` (D1) — if a later entry ever freezes the manager harder, move the require to `lib/tart.rb` explicitly with a declared scope widening.
