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
`architect rehearse session-sink` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze session-sink` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse session-sink` — before the freeze, while
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
subsection per lane. A copy is written to build/I74-session-sink-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section session-sink prompt --append --lane <lane> --from build/I74-session-sink-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I74-session-sink-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence session-sink --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section session-sink verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify session-sink`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
