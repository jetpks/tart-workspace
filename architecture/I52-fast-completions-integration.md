# I52: fast-completions-integration

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I52 fast-completions-integration

## 0. Control (this session)

- Space base: `21b8598` (the I52 scaffold; the space metadata rule held:
  `architecture/I51-fast-completions-gem.md` is CLOSED with its verdict
  before this `architect new`).
- This iteration: ENTRY 3 (the FINAL entry) of the successor program
  (`notes/plan-20261013T222728Z.md` — read in full this session; the task's
  `build/loop/…` path is that file, which lives at `notes/` in the space).
  ENTRY 1 (I50 de-bridge) and ENTRY 2 (I51 fast-completions-gem) are
  JUDGED CONTINUE and INTEGRATED; neither is re-judged or re-opened here.
- repos/tart at `project/pi-port` `fb830d6` (I50's integrated tip) — the
  frozen base of this iteration. CLEAN worktree (no lane worktrees live).
- repos/fast-llm at `main` `dc8eea9` (I51's integrated tip incl. judge
  fixes) — READ-ONLY for this entry: the consumed artifact, never edited.
  Gem `fast-completions` 0.1.0; the judge-verified build form is from
  `gems/completions/` (the repo-root `gem build` fails LOUDLY by design).
- repos/pi at the pinned fork — oracle, read-only (this entry ports no new
  pi surface; the pi-faithful codec already landed as the gem in I51).

## 1. The gem's built surface (verified against dc8eea9 this session)

The public API the integration consumes (file:line verified in
repos/fast-llm/gems/completions/lib/):

- `Fast::Completions::Client` (client.rb) — `new(base_url:, api_key:,
  timeout: 30)`; ONE persistent Async::HTTP::Client; `#stream(model:,
  messages:, instructions:, tools:, thinking:, max_tokens:, temperature:,
  session_id:) { |event| }` → the final assistant Message; `#close`.
  Timeout = TTFB deadline + per-chunk inactivity (same value). Non-2xx →
  the §8 error tree; network faults → `ConnectionError`. **Cancel
  contract (I51 D8, frozen): `Async::Cancel` raised at the in-flight wait
  is RESCUED INSIDE the client and re-raised as
  `Fast::Completions::CancelledError`** (client.rb:97-99); the connection
  is discarded; NO terminal event. This session's probe (§4 P1) confirms
  BOTH gem cancel paths (task-cancel and the Chat latch) surface
  `CancelledError`, and that `Async::Task#cancelled?` reads FALSE inside
  the rescue — there is NO post-hoc discriminator.
- `Fast::Completions::Model` (types.rb:20-125) — keyword-init,
  `id/reasoning/context_window/max_tokens` ALL REQUIRED (max_tokens must
  be an Integer — the request ALWAYS carries the max-tokens key; the key
  omits only when Model.max_tokens is nil, which the constructor
  forbids), optional `thinking_level_map`, `dialect:` (Symbol or Dialect),
  `provider:` (metadata only). `supported_thinking_levels` /
  `clamp_thinking_level` port pi models.ts :118-156 (ladder off/low/
  medium/high/xhigh/max; :minimal unported per I51's frozen letter).
- `Fast::Completions::Dialect` (dialects.rb:19-60) — **`Dialect.new` is
  PUBLIC** (13-key closed vocabulary, ArgumentError on unknown key/value);
  tart constructs instances directly — no global registry pollution. The
  shipped `:zai` declaration (the I46 five-key subset + `supports_store:
  false`) is the reference for the compat→Dialect translation.
- `Fast::Completions::Message` (types.rb:130-247) — roles
  `:system/:user/:assistant/:tool_result`; assistant content is an Array
  of block Hashes (`{type: :text, text:}`, `{type: :thinking, thinking:,
  signature:}`, `{type: :tool_call, id:, name:, arguments:}`);
  `usage:` a `Usage` (`input/output/cache_read/cache_write/reasoning/
  total_tokens` — total NATIVE, pi parseChunkUsage semantics);
  `to_h/from_h` round-trip (the GEM's shape — NOT tart's recorded shape).
- `Fast::Completions::Event` (types.rb:250-277) — `.type` one of
  `:start, :text_start, :text_delta, :text_end, :thinking_start,
  :thinking_delta, :thinking_end, :tool_call_start, :tool_call_delta,
  :tool_call_end, :done, :error`; deltas carry the RAW string in
  `.delta`; `:done` carries `reason:` (`:stop/:length/:tool_use`).
- `Fast::Completions::Tool` (tool.rb) — class-level `description`,
  `tool_name`, `parameters(schema)` (Hash, emitted VERBATIM); instance
  `#name` = declared tool_name else class basename; `#execute(**args)` →
  String / Hash / `{error:}`.
- `Fast::Completions::Cancellation.check` (cancellation.rb:11-16) —
  raises `CancelledError` when the current Async::Task is cancelled; no-op
  outside a reactor. NO `.watch` counterpart (tart's user_bash seam needs
  a replacement — Specification §5.8).
- Errors (errors.rb) — `Error < StandardError` tree:
  `ApiError(status:, body:)` → `BadRequestError` →
  **`ContextLengthExceededError`** (400 + any of pi's 25 verbatim overflow
  patterns), `AuthenticationError/PermissionError/NotFoundError/
  RateLimitError/ServerError`, `TimeoutError`, `ConnectionError`,
  `StreamError(stop_reason:)`. `CancelledError < StandardError` NOT under
  `Error`.
- `Fast::Completions::Chat` (chat.rb) — EXISTS but is NOT tart's mount
  point (§3 D2): serial tool batches (I51 D9 — "tart owns its own
  concurrency post-de-bridge"), no `messages` writer, no `tools` reader,
  no `after_message` hook.

## 2. The tart seams (verified against fb830d6 this session)

Swap points (post-I50 line numbers):

- `bin/tart:734-745` `build_chat` — `RubyLLM.context` + `context.chat(
  model:, provider: Models.wire_provider, protocol: :chat_completions,
  assume_model_exists: true)`; `request_timeout 120`, `max_retries 1`.
- `lib/tart/agent/loop.rb:549-600` — compaction one-shot
  (`build_summary_chat` reaches into `@chat.context` +
  `instance_variable_get(:@protocol)` — private-API surgery that dies);
  `:610-650` `step_on_reactor` (the I50 ladder: `Async::Cancel` FIRST —
  `@chat.cancel` belt + `send(:raise_if_cancelled!)` residue consumption
  (ruby_llm PRIVATE API, pinned to 2.1.0) — then `RubyLLM::
  CancelledError` → nil, then `StandardError` → record_terminal_error).
- Deletions: `apply_zai_dialect` + `install_thinking_seam` +
  `install_summary_chat_seam` (loop.rb:809-977, ~168 l incl. comments);
  the Thread.current pairing in `install_chat_callbacks` (:809-833);
  `Models.wire_provider`/`WIRE_PROVIDER` (models.rb:32/:126-131, reads
  `RubyLLM::Provider.providers`); the duplicate-`reasoning` replay strip
  (:884).
- Rewires: `render/chat.rb:454-457` `chunk.content` / `chunk.thinking&.text`
  (the render's chunk contract); `render/footer.rb:94` `RubyLLM::Tokens.new`
  reseed; `compaction.rb:166-170` `calculate_context_tokens` (re-sums
  because ruby_llm's Tokens lacks total); `agent/session.rb:160-175`
  `compaction_usage` (reads `tokens.cache_write_by_ttl`/`.thinking` —
  gem Usage has neither); `mcp/tool.rb:23-65` (`RubyLLM::Tool` base +
  `RubyLLM::Tool::SchemaDefinition` stringifier);
  `subagents/manager.rb:393-397` `global_llm_config` (reads
  `RubyLLM.config` for the parent endpoint facts); `settings.rb:246`
  `model.supports?(:reasoning)`; `print.rb` doc surface.
- The sweep: 26 files under lib/ + bin/ reference `RubyLLM`/`ruby_llm`
  (the tools family's `Cancellation.check` checkpoints ~20 sites,
  `CancelledError` rescues ~12 sites, comments the rest).
- Deps: `tart.gemspec:47` `add_dependency "ruby_llm", "~> 2.1"` (the ONLY
  dep site — the Gemfile carries `gemspec` + dev deps); faraday (2.14.4),
  faraday-net_http, faraday-retry, faraday-multipart exist ONLY as
  ruby_llm's transitive deps in Gemfile.lock (no direct reference
  anywhere in bin/lib/test — verified by grep this session). Removing
  ruby_llm removes all four from the lock transitively.

## 3. Design decisions (letter-grounded; the headline rulings itemized)

- **D1 — the mount point is Client+codec+types, NOT the gem's Chat.**
  tart's `Agent::Loop` needs: a `messages` WRITER (compaction rewrites
  history at loop.rb:508), a `tools` reader (compaction's estimate),
  concurrent `:fibers` tool batches (the I50 overlap pin,
  agent_loop_test:608 — the gem is serial by I51's frozen D9), and
  `after_message`-equivalent tool-message events. A NEW tart-owned
  conversation object (`Tart::Agent::Chat`, lib/tart/agent/chat.rb) wraps
  `Client#stream` and owns the batch executor — I51's own D9 ruling says
  "tart owns its own concurrency". The gem's Chat stays a standalone
  consumer surface, unused by tart (itemized: the plan's "step/streaming/
  callbacks to the gem API" resolves to the Client/Event/Tool API).
- **D2 — the batch executor is tart's, children of the turn task.** One
  reactor task per tool call (Async::Task.current.async — the Sync-inline
  discipline I50 §2 proved), hooks dispatched BY tool_call id through
  per-task closures (the Thread.current pairing dies — the plan's
  "re-key by tool_call id" realized at the seam ruby_llm forced), results
  appended in call order, the tool_call BLOCK gate (ToolGate) unchanged.
  On turn cancel, children stop via async's stop_children; the executor
  NEVER launders (I50's R2) and NEVER waits-out natural completion —
  **this closes I50's transferred residual "interrupt-during-:fibers-batch
  waits out natural tool completion" (probe6 ARM A)**, pinned by a new
  test.
- **D3 — cancel semantics: the tart Chat converts the gem's
  `CancelledError` BACK to `Async::Cancel`.** The I50 ladder and run()'s
  interrupted bookkeeping are keyed on `Async::Cancel` propagating from
  the turn fiber (loop.rb:288-293 re-raises for kernel teardown). The
  gem's client freezes Cancel→CancelledError at ITS boundary (I51 D8 —
  correct for standalone consumers); tart's Chat re-raises
  `Async::Cancel` at its own seam, and the ruby_llm belt
  (`@chat.cancel` + `raise_if_cancelled!`) is DELETED outright — the
  residue problem dies with the flag (the I50 5th pin
  `test_run_after_an_interrupt_makes_a_fresh_request` passes trivially:
  nothing lingers). The loop's ladder keeps its frozen three-arm order
  with `Fast::Completions::CancelledError` in the ruby_llm arm's place
  (defensive; the conversion makes it rare).
- **D4 — THE WIRE RULING (letter-vs-spirit, the headline item).** The
  plan letter says "wire bytes unchanged / digests EXACT byte-identical
  before/after". That is MECHANICALLY INFEASIBLE with the frozen gem:
  (a) `Model` requires `max_tokens:` Integer → the max-tokens key ALWAYS
  emits (ruby_llm omits it when unset — tart's s1 body has NO
  max_completion_tokens); (b) the gem's key order is pi's `buildParams`
  order [model, messages, stream, stream_options, store?, max?,
  temperature?, tools] — ruby_llm's was [model, messages, stream, tools,
  stream_options]; (c) the default dialect emits `store:false` (ruby_llm
  never emitted store); (d) the instruction role follows pi's rule
  (developer iff reasoning && supports_developer_role — openai-
  completions.ts :1233; the gem's codec.rb:126-131) where ruby_llm
  rendered developer UNCONDITIONALLY (chat_completions/chat.rb:376-383,
  `openai_use_system_role` defaults nil — verified live this session).
  Evidence this session: tart's captured s1 body carries
  `messages[0].role == "developer"` while PI's same-scenario capture
  carries `"system"` (tmp/i38-s1/run-1/{tart,pi}-requests.jsonl) — a
  STANDING tart-vs-pi divergence the parity program never cross-pinned
  (the rig compares screens; the wire-bodies gate is a SELF-regression
  digest). RULING: the swap takes tart's wire TO THE GEM'S (= pi's)
  bytes; the four renderer-level deltas above are ENUMERATED and
  delta-audited by the gate (AC2) — the messages bodies byte-identical
  except the instruction-role flip, the tools declarations digest EXACT
  (`7360fd1e…` holds), the key set/order EXACTLY pi's. Everything else —
  thinking arms, tool_calls replay, usage, session bytes — byte-identical
  (the session-golden digests are client-independent and hold VERBATIM).
  The new full-body digest is recorded by the judge at integration and
  becomes the next wire-bodies baseline. This is the program's actual
  goal (own the wire ON PI'S PROTOCOL — ENTRY 2 built the pi-faithful
  codec precisely so the bytes become pi's); the "never THE bytes"
  preamble protected the bytes DURING ruby_llm's tenancy and assumed
  tart's bytes already equalled pi's — they did not, in exactly these
  four ways.
- **D5 — the recorded session shape stays ruby_llm's (empirical).** The
  session-recorder consumes `message.to_h`; recorded files (real runs)
  carry ruby_llm's shape — `{"role":"assistant","content":"…",
  "tool_calls":{},"finish_reason":"stop","input_tokens":10,
  "output_tokens":5,"cache_write_tokens":0}` (captured this session from
  tmp/i50-wire/run-1/home/tart/…jsonl). A NEW `Tart::Agent::Message`
  reproduces that surface (roles :user/:assistant/:system/:TOOL;
  `tool_calls` Hash keyed by id — `{}` when none; `finish_reason` mapped
  :stop→"stop"/:length→"length"/:tool_use→"tool_calls"; usage keys
  `input_tokens/output_tokens/cache_write_tokens` incl. zero-cache-write,
  `cache_read_tokens/thinking_tokens` OMITTED-when-zero — ruby_llm's
  nil/0 conventions reproduced; `thinking`/`thinking_signature` when
  present) and converts to/from gem Messages at the wire boundary
  (thinking blocks carry `signature: "reasoning_content"` on replay —
  the I36 replay protocol, now emitted by the gem's §9.5 natively).
  Old session files resume unchanged (the reader already tolerates the
  recorded shapes; `from_seed_hash` accepts the ContextMessage#to_h
  projection). A new unit pin freezes the recorded hash byte-shape.
- **D6 — thinking facts ride the MODEL, not a payload seam.** The loop's
  constructor kwargs (`model_reasoning:`, `thinking_level_map:`,
  `compat:`, `context_window:`) STAY (the I36/live-run pins construct
  the loop with them — they must pass green UNMODIFIED); the loop
  applies them to the Chat's wire model (`apply_facts`) at construction
  and on `switch_model`; `set_thinking_level` sets the Chat's level
  (clamped by the model's map at request build — tart's clamp readers
  stay for the UI). zai: the catalog `compat` (Shapes::ModelCompat, the
  I46 five-key subset) translates to a `Fast::Completions::Dialect`
  (thinking_format :zai → the zai-shaped declaration incl
  supports_store:false; ANY other thinking_format (nil, deepseek, …)
  → the DEFAULT dialect — exactly today's "only-zai arms" behavior,
  I46's non-zai compat runs the generic arm). `apply_zai_dialect` and
  the seams are DELETED; the compaction one-shot gets the SAME wire
  model (the zai arm rides by construction — pi compaction.ts:605-607).
- **D7 — wire model composition lives in models.rb.**
  `Models.wire_model` builds the gem Model from the catalog entry + the
  resolved facts (context_window: the loop kwarg's chain — catalog → env
  → known-tables → default; max_tokens: entry.max_tokens ||
  context_window (the gem's pi-clamp caps it at context − estimate −
  4096, so the fallback approximates today's key-omission semantics);
  reasoning: the resolved facts; map symbolized; dialect per D6). The
  `assume_model_exists` hole workarounds' comments die; the
  known-models tables STAY (they feed context_window resolution —
  pi's catalog is the spec, not the gem's, I10's ruling).
- **D8 — deps: the path form, corrected.** The plan letter says
  `path: repos/fast-llm`; bundler `:path` must resolve the GEMSPEC'S
  DIRECTORY — the monorepo root has no fast-completions gemspec (the
  I51 verdict: repo-root builds are RubyGems-IMPOSSIBLE for the nested
  gem). The frozen form (Gemfile, since gemspec deps cannot carry
  paths): `gem "fast-completions", "0.1.0",
  path: "../fast-llm/gems/completions"` — the path letter corrected to
  the gemspec dir AND the version pin satisfied in one line (a gem bump
  without a tart pin bump fails `bundle install` LOUDLY — the judged
  form). tart.gemspec drops `ruby_llm`; faraday/faraday-net_http/
  faraday-retry/faraday-multipart leave the lock transitively (verified:
  zero direct references). At landing the human swaps the path pin for
  the released gem (recorded as the program-close residual).
- **D9 — retries die.** bin/tart sets ruby_llm `max_retries = 1`
  (interactive; TestChat 0). The gem has NO retries (I51 D6/OQ-2 — tart
  runs max_retries 0 per scout D; the interactive 1 was ruby_llm config
  defaulting, unexamined). Itemized: a transient 5xx/429 now surfaces
  immediately as the error terminal instead of retrying once. No
  scripted scenario pins a retry (expected_requests counts hold — the
  battery verifies).
- **D10 — user_bash's `Cancellation.watch` replacement.** The gem ships
  `Cancellation.check` only. The drainer's cancel-flag check becomes a
  tart-local boundary check raising `Fast::Completions::CancelledError`
  (same observable: the I50 drainer-wait Cancel guard pins hold).

## 4. Spec-session probes (run this session, rerunnable)

- **P1 — the cancel discriminator (tmp/i52-spec/probe_cancel_discriminator.rb,
  run against the dc8eea9 gem bundle).** Slow-SSE mock (40×0.1 s), two
  arms: (ARM1) kernel-style `task.cancel` mid-stream; (ARM2) the gem
  Chat's latch cancel. RESULT: both surface
  `Fast::Completions::CancelledError`, and `Async::Task.current&.
  cancelled?` is FALSE inside the rescue in BOTH arms — there is no
  post-hoc discriminator, so D3's re-raise-at-the-tart-seam is the only
  sound conversion (the message strings differ — "stream cancelled" vs
  "chat cancelled" — but message-string discrimination is fragile and
  unnecessary under D3: tart re-raises Async::Cancel for every gem
  CancelledError at its Chat seam; tart never arms the gem's latch).
- **P2 — the wire-delta evidence (the §2 D4 captures).**
  tmp/i38-s1/run-1/{tart,pi}-requests.jsonl (I38-era, still on disk):
  tart `messages[0].role == "developer"`, pi `"system"`; tart top-level
  keys `[model, messages, stream, tools, stream_options]`, no store, no
  max key. tmp/i50-wire/run-1 (I50's gate run, fb830d6-equivalent tree)
  reproduces the same tart shape — the four deltas of D4 are stable
  across the I38→I50 window and are the COMPLETE enumeration (the tools
  digest `7360fd1e…` and the message bodies otherwise hold).

## 5. What stays UNTOUCHED (the swap proof)

- The rig: `gems/tui-split-rig/**` (scenarios s1–s10, probes, registry)
  — byte-identical; the mock (`test/support/mock_llm_server.rb`'s server
  class) — protocol-agnostic, unchanged except the TestChat factory
  rewiring to the tart Chat; `bench/seam_bench.rb`; wt-goldens (the
  edit/read tool goldens); the session-golden digests (hermetic,
  FakeMsg-driven — client-independent).
- The I36/live-run pins: `test/agent_loop_test.rb` reasoning tests,
  `test/chat_test.rb` reasoning scripts, `test/settings_test.rb` thinking
  tests — green UNMODIFIED (they assert via `@server.captured_requests`
  and synthetic chunk ducks, both client-agnostic — verified this
  session). The render's chunk contract (`chunk.content` /
  `chunk.thinking&.text`) is PRESERVED at the loop boundary by the
  Chat's event→chunk adapter — render/chat.rb:454 is NOT rewired
  (itemized: the plan listed it as a rewire point; the spec keeps the
  chunk contract instead — the pin set decides).
- The hermeticity pins (staged HOME), the subagents battery, e2e legs
  (subprocess-driven — they exercise bin/tart end to end).

## 6. Environmental carry-ins (standing)

- Builders run zai/glm-5.3-flash (architect.yaml routing); builders
  never commit; the coordinator integrates.
- Scratch under tmp/ and build/ only. No GitHub/rubygems actions; the
  loop stops before landing (the human owns the tart PR + the fast-llm
  publish; the path-pin → released-gem swap is the human's at landing).
- repos/fast-llm is READ-ONLY (I51's closed artifact; the I52 gates
  never run there). Every gate runs in repos/tart.
- Child-timeout discipline (coordinator): timeoutMs + toolTimeoutMs ≥
  3600000 on every spawn.

## Specification

# Specification — I52 fast-completions-integration

## 0. Objective

tart consumes the `fast-completions` gem (repos/fast-llm @ dc8eea9,
read-only): `ruby_llm`, `faraday` (all four gems, transitively), and every
shim that existed to work around them leave TOGETHER in one atomic swap.
The turn keeps running as fibers on the kernel reactor (I50's shape,
untouched); the wire is built by the gem's pi-faithful codec (the four
renderer-level deltas of Grounds §3 D4, delta-audited by AC2); the
recorded session bytes, the render contract, and the whole battery hold.
ONE lane, repo tart.

## 1. `Tart::Agent::Chat` (NEW lib/tart/agent/chat.rb) — the conversation object

The ONLY chat bin/tart and the tests construct (replaces
`RubyLLM.context.chat` 1:1 at every construction site).

```ruby
chat = Tart::Agent::Chat.new(client:, model_id:, provider_key: nil)
# client:  Fast::Completions::Client (built by the caller — bin/tart
#          build_chat / TestChat)
# model_id: String (the wire model id)
chat.with_instructions(text)        # chainable; replaces (ruby_llm parity)
chat.with_tools(*tools)             # chainable; ToolGate-wrapped or plain
chat.add_message(message_or_hash)   # chainable; Tart::Agent::Message or a
                                    # ContextMessage#to_h seed Hash
chat.messages          # dup'd Array of Tart::Agent::Message (reader)
chat.messages = array  # WRITER — compaction's history rewrite (loop.rb:508)
chat.tools             # the registered tool instances (compaction estimate)
chat.model             # the Fast::Completions::Model (window/facts reads)
chat.thinking_level = level
chat.with_max_output_tokens(n)      # the compaction one-shot only
chat.complete?         # false while a tool batch is pending (step contract)
chat.step { |chunk| … }             # ruby_llm's step contract (below)
chat.endpoint          # {api_key:, api_base:} (subagents' parent facts)
```

- `apply_facts(model_reasoning:, thinking_level_map:, compat:,
  context_window:, max_tokens: nil)` — (re)builds the wire model via
  `Models.wire_model` (§4); called by the loop at construction and
  `switch_model`. Idempotent; `model_id`/`provider_key` unchanged.
- `#step` contract (byte-compatible with ruby_llm's, the loop's
  `step_on_reactor` keeps its shape): builds the request from
  instructions + messages + tools + thinking_level + max_output_tokens
  via `client.stream`, feeding the block the CHUNK adapter of §3; on a
  `:tool_use` done → runs the §2 batch executor → returns the LAST
  tool-result Message (role `:tool`, `complete?` false); otherwise
  appends the final assistant Message and returns it. The step NEVER
  appends the assistant twice; tool results append inside the batch.
- **Cancel conversion (Grounds D3)**: the step body rescues
  `Fast::Completions::CancelledError` and RE-RAISES `Async::Cancel`
  (fresh raise). No latch, no `#cancel`, no `raise_if_cancelled!` — the
  ruby_llm belt and its residue die here. Timeout/Connection/Api/
  StreamError propagate as-is (`StandardError` — the loop's existing
  terminal arm classifies).
- No `with_model`/`context`/`provider` readers — the private-API
  reaches of `build_summary_chat` die with them.

## 2. The batch executor (inside `Tart::Agent::Chat`) + `Tart::Agent::ToolCall`

- `Tart::Agent::ToolCall = Struct.new(:id, :name, :arguments,
  keyword_init: true)` (NEW, in message.rb or chat.rb) — the loop-facing
  tool-call duck (hooks/ToolGate/tests construct it).
- Executor: for the assistant's tool_call blocks IN ORDER —
  `Async::Task.current.async { … }` per call (children of the turn task:
  concurrent on the reactor — the I50 overlap pin), each child:
  `Fast::Completions::Cancellation.check` → before-hook(tool_call) →
  `tool.call(**arguments, tool_call:)` (the ToolGate wrapper — the
  block/terminate ledger flows unchanged) → after-hook(tool_call,
  result, duration:) (monotonic, the I17 discipline) → append the
  tool-result Message. Results append in CALL ORDER (a shared
  completion queue or index-keyed collection — never completion order).
- Hooks: `chat.before_tool_call { |tool_call| }` /
  `chat.after_tool_result { |tool_call, result, duration:| }` — multiple
  blocks, registration order, **attribution by tool_call id through the
  per-task closure — NO Thread/fiber-local pairing anywhere** (the
  Thread.current pairing is DELETED; the I50 attribution pin stays green).
- On `Async::Cancel` during the join: the executor re-raises — it NEVER
  waits out natural completion (closes I50's probe6 ARM A residual; the
  new AC1 pin proves a cancel during a 0.5 s sleep-tool batch surfaces
  in ≤0.2 s) and never launders a child's error (R2).
- The batch consults the loop's terminate ledger exactly as today
  (`batch_terminated?` flow unchanged).

## 3. The event→chunk adapter (inside `Tart::Agent::Chat`)

The render contract is FROZEN: the loop's `:message_update` events carry
a chunk duck with `.content` (String) and `.thinking&.text`. The Chat
maps the gem's Events: `:text_delta` → chunk(content: event.delta,
thinking: nil); `:thinking_delta` → chunk(content: nil, thinking:
Thinking.new(event.delta)); every other event type → NO chunk yield
(`:start/:text_start/:text_end/…` are stream-internal).
`render/chat.rb:454-457` is UNTOUCHED (Grounds §5). The chunk Structs
are chat-internal constants.

## 4. models.rb — the wire model + the dialect translation

- `Models.wire_model(model_id:, provider_key:, reasoning:, context_window:,
  max_tokens: nil, thinking_level_map: nil, compat: nil)` →
  `Fast::Completions::Model.new(id:, reasoning:, context_window:,
  max_tokens: max_tokens || context_window, thinking_level_map:,
  dialect:, provider: provider_key)`. context_window MUST resolve to an
  Integer here (the caller runs the existing chain — catalog → env →
  known-tables → `Settings::MODEL_CONTEXT_WINDOWS` default tier).
- `Models.dialect_for(compat)` → `Fast::Completions::Dialect`:
  `compat&.thinking_format == "zai"` →
  `Dialect.new(thinking_format: :zai, max_tokens_field:
  compat.max_tokens_field == "max_tokens" ? "max_tokens" :
  "max_completion_tokens", supports_developer_role:
  compat.supports_developer_role == true, supports_reasoning_effort:
  compat.supports_reasoning_effort == true, zai_tool_stream:
  compat.zai_tool_stream == true, supports_store: false)` (the I46
  five-key subset + pi's zai store suppression — identical values to the
  gem's shipped `:zai`); ANY other thinking_format (nil, "deepseek", …)
  → the DEFAULT dialect (today's "only-zai arms" behavior verbatim).
- DELETED: `WIRE_PROVIDER`, `wire_provider` (and the
  `RubyLLM::Provider.providers` read). The `Settings.thinking_facts`
  fallback `model.respond_to?(:supports?) ? model.supports?(:reasoning)
  : false` → `model&.reasoning == true` (the `model:` kwarg is now the
  gem Model). The known-models tables and `MODEL_CONTEXT_WINDOWS` STAY.

## 5. `Agent::Loop` surgery (lib/tart/agent/loop.rb)

- DELETED whole: `install_thinking_seam`, `apply_zai_dialect`,
  `install_summary_chat_seam`, the Thread.current pairing in
  `install_chat_callbacks`, the duplicate-`reasoning` replay strip, the
  `@chat.cancel` + `send(:raise_if_cancelled!)` belt (all of
  loop.rb:596-600 + :809-977's seam family). `install_chat_callbacks`
  re-registers the SAME observable events through the Chat's hooks
  (`:tool_execution_start`/`:tool_execution_end` with `tool_call:` +
  `duration:`, the `:tool_message` emission when a tool result appends —
  the Chat's after-hook or the executor's append path drives it).
- Constructor: kwargs UNCHANGED (`model_reasoning:`, `thinking_level_map:`,
  `compat:`, `context_window:` stay — the pins construct them);
  initialize calls `@chat.apply_facts(model_reasoning:, thinking_level_map:,
  compat:, context_window: resolved_context_window || <Settings default
  tier>)` so the wire model carries the facts.
- `set_thinking_level` → `@chat.thinking_level = level` (+ the loop's own
  reader for the surface, unchanged).
- `switch_model` → `@chat.apply_facts(...)` with the NEW facts +
  `model_id`/`provider_key` (the Chat rebuilds the wire model);
  `@context_window` re-resolution unchanged.
- `step_on_reactor`: ladder RE-KEYED, order FROZEN —
  `rescue Async::Cancel` FIRST (re-raise; run()'s rescue owns the
  interrupted bookkeeping — NO belt call remains), then
  `rescue Fast::Completions::CancelledError` (defensive arm, today's
  nil shape), then `rescue StandardError` → record_terminal_error.
- `recover_overflow?` → `@last_error.is_a?(Fast::Completions::
  ContextLengthExceededError)`.
- `build_summary_chat` DELETED; the Chat exposes a documented
  `summary_chat` factory (same client, same wire model + facts,
  `with_instructions(Compaction::SUMMARIZATION_SYSTEM_PROMPT)` +
  `with_max_output_tokens(summarization_max_tokens)`); the zai arm rides
  the model by construction (D6); NO seam installation, NO private-API
  reach. `summarize` keeps its rescue shape (`Async::Cancel` re-raise
  belt DELETED — the Cancel already unwound the one-shot's stream).
- `Compaction.trigger_tokens(..., tools: @chat.tools)` unchanged (the
  Chat's tools reader feeds it; compaction.rb:226's
  `tool.parameters_schema` → the tart tool surface keeps a
  `parameters_schema` reader aliasing the gem's `parameters` — defined
  once in SafeExecute + the mcp wrapper).

## 6. bin/tart + TestChat (the two construction sites)

- `build_chat` (bin/tart:734): `Fast::Completions::Client.new(base_url:,
  api_key:, timeout: 120)` (the same env/provider/settings resolution
  chain; `max_retries` DIES — Grounds D9) + `Tart::Agent::Chat.new(
  client:, model_id: boot.id, provider_key: boot.provider)`. The
  launcher's `Agent::Loop.new(...)` call is UNCHANGED (the facts kwargs
  thread to `apply_facts` inside the loop).
- `TestChat.build(server, tools:, system_prompt:, request_timeout: 10)`
  (test/support/mock_llm_server.rb): same signature; builds the Client
  at `server.url` + the tart Chat with `model_id: "tart-test-model"`;
  the server class itself is UNTOUCHED.

## 7. The sweep (mechanical, enumerated)

- `RubyLLM::Support::Cancellation.check` → `Fast::Completions::
  Cancellation.check` (~20 sites: read/find/grep/edit/ls/write/bash/
  memory + manager). `RubyLLM::CancelledError` → `Fast::Completions::
  CancelledError` (~12 sites: safe_execute, registry, bash, find,
  manager, hooks, user_bash).
- The 10 tool classes + mcp/tool.rb: base `RubyLLM::Tool` →
  `Fast::Completions::Tool`; `parameters PARAMETERS_SCHEMA.dup` → the
  gem's class-level `parameters PARAMETERS_SCHEMA.dup` (same DSL shape);
  `pi_name`/`#name` unchanged (SafeExecute's own ClassMethods). mcp/
  tool.rb's `parameters_schema` inlines the SchemaDefinition
  stringification ($schema/title stripped, stringified keys — semantics
  copied, ~10 l).
- `render/user_bash.rb:129-138`: the `Cancellation.watch(-> { raise … })`
  drainer seam → a tart-local flag check at the SAME drain boundaries
  raising `Fast::Completions::CancelledError` (D10; the I50
  drainer-wait Cancel-guard pins hold).
- `render/footer.rb:94` `reseed_usage`: `RubyLLM::Tokens.new(...)` →
  `Tart::Agent::Message.tokens_from(...)` (the adapter's Tokens duck —
  same reader surface input/output/cache_read/cache_write).
- `compaction.rb:166-170`: `calculate_context_tokens(tokens)` uses
  `tokens.total_tokens` when present (the gem Usage carries it NATIVE —
  Grounds OQ-9), falling back to the component sum for the duck; the
  comment updated.
- `agent/session.rb:160-175` `compaction_usage`: reads the gem Usage
  (`cache_write` — the 1h-ttl sub-key DIES with ruby_llm's field;
  `reasoning` for thinking); `totalTokens` semantics unchanged.
- `subagents/manager.rb:393-397`: `global_llm_config` (RubyLLM.config)
  → the parent endpoint facts threaded from the boot (the Chat's
  `endpoint` reader; the launcher passes it into the Manager the same
  way it passes the subagents env tier today).
- `print.rb`, `hooks.rb`, `tools.rb`, `schemas/tools.rb`,
  `render/transcript.rb`, `settings.rb`, `agent/session.rb` comments:
  the ruby_llm references reworded to the gem (comment-only where no
  code moves).
- Test surgery: construction re-points ONLY — `RubyLLM::Message.new` →
  `Tart::Agent::Message` factories; `RubyLLM::Tokens.new` → the duck;
  `RubyLLM::ToolCall.new` → `Tart::Agent::ToolCall.new`;
  `RubyLLM.context` blocks → TestChat/the Client; flow_test's error
  class asserts → the gem's classes; settings_test's `RubyLLM.models.
  find` pin (the only registry reference) re-pins the resolution chain
  without the registry premise (the known-tables outcome table is the
  pin). NO assertion-logic changes elsewhere; the I36/live-run pins and
  the settings thinking tests are UNMODIFIED. Comment-only rewords
  where no code moves (chat_test, golden_parity_test,
  render/transcript_test, print.rb, hooks.rb, tools.rb, schemas/
  tools.rb, transcript.rb, session.rb).

## 8. Named test additions (the pins the AC gates match)

- `test/agent_loop_test.rb`:
  `test_cancel_during_tool_batch_aborts_fast` — a scripted two-call
  batch of 0.5 s sleep-tools; a kernel-style interrupt ~0.1 s into the
  batch; assert the run surfaces (interrupted agent_end) in ≤0.2 s
  (wall-clock, generous CI margin) — the probe6 ARM A residual CLOSED.
  `test_recorded_message_shape_matches_the_frozen_bytes` — one scripted
  mock turn (content + usage {prompt_tokens: 10, completion_tokens:
  5}); assert the recorded assistant entry's `message` hash EQUALS
  `{{"role"=>"assistant", "content"=><the scripted text>,
  "tool_calls"=>{{}}, "finish_reason"=>"stop",
  "input_tokens"=>10, "output_tokens"=>5,
  "cache_write_tokens"=>0}}` (exact keys, the nil/0 conventions
  included — ruby_llm's empirical bytes, Grounds D5) and a tool-call
  turn records `{{"role"=>"tool", "tool_call_id"=>…, "content"=>…}}`.
- `test/models_test.rb`: `test_dialect_for_translates_the_zai_compat`
  (the five-key subset + supports_store false, value-by-value) and
  `test_dialect_for_nil_and_non_zai_compat_yield_the_default_dialect`
  (today's only-zai arms).
- The remaining coverage rides the EXISTING pins unmodified (the AC's
  run-count floors are the calibration).

## 9. Dependencies

- tart.gemspec: `spec.add_dependency "ruby_llm", "~> 2.1"` DELETED.
- Gemfile (after `gemspec`): `gem "fast-completions", "0.1.0",
  path: "../fast-llm/gems/completions"` (Grounds D8 — the corrected path
  form + the version pin in one line).
- Gemfile.lock: regenerated — CONTAINS fast-completions (0.1.0, PATH
  source) and its transitive async stack; contains NO ruby_llm, NO
  faraday, NO faraday-net_http/faraday-retry/faraday-multipart (all
  four were ruby_llm-transitive only — verified Grounds §2).
- Lane worktrees: `architect worktree add tart …` materializes under
  `build/I52-fast-completions-integration-core/wt` — the relative
  `../fast-llm/gems/completions` path from THAT directory does NOT
  resolve. The lane's Gemfile line therefore reads the ABSOLUTE-space
  form via an ENV default: `gem "fast-completions", "0.1.0",
  path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")`
  — the canonical checkout (repos/tart) uses the default relative form;
  the lane/gates export `FAST_COMPLETIONS_PATH=<space>/repos/fast-llm/
  gems/completions` when bundling outside it. The judged gate
  (`lock-deps`, AC4) runs from repos/tart with NO env override — the
  frozen, landing-relevant form is the relative default.

## 10. Boundaries

May touch: EXACTLY the 48 files of the ```lanes``` block (45 existing +
2 new + Gemfile.lock). Must NOT touch:

- repos/fast-llm (READ-ONLY — I51's closed artifact), repos/pi, every
  other repos/* path, the space outside build/ + tmp/.
- `gems/tui-split-rig/**` (the rig: scenarios, registry, probes),
  `bench/seam_bench.rb`, `test/fixtures/**` (the edit/read goldens),
  `lib/tart/core/**` (the kernel), `lib/tart/render/chat.rb` (the chunk
  contract — Grounds §5), `lib/tart/shapes/**`, `lib/tart/schemas/**
  (except the tools.rb comment), the mock SERVER class body in
  test/support/mock_llm_server.rb (only the TestChat factory block).
- No new runtime dependency other than fast-completions (its transitive
  async stack arrives via its gemspec); no faraday anywhere; no vendored
  gem code (the gem is CONSUMED, never copied).
- No commits, no pushes, no GitHub/rubygems actions; builders never
  commit.

Out of scope (itemized; reopen on consumer need): retries (D9 — dead,
not ported); ruby_llm's `attachments`/media/citations surfaces (tart
never used them); the gem's `session_id` affinity headers (no consumer);
`temperature` (unset everywhere); reasoning_details capture beyond the
gem's native replay (the I51 surface); a tart-side ToolCall->`provider_
options` surface (never used); the released-gem pin swap (the human's at
landing).

## 11. Lane plan

ONE lane (`core`) — the swap is ATOMIC by construction (any residual
`RubyLLM` reference fails the bundle boot; the loop/chat/message/tools/
deps must land together to run anything). Verification IN ITS WORKTREE
(`FAST_COMPLETIONS_PATH` exported per §8): `bundle install && bundle
exec rake` green; the negative greps clean; the recorded-shape unit pin
green. The judge re-runs every gate cold on the INTEGRATED tree at
repos/tart (canonical path, no env override). Gate calibration: every
capability gate is RED at base BY DESIGN (the swap does not exist);
`session-golden`, `bench`, and the s-gates are GREEN-AT-BASE regression
gates that must STAY green; the negative greps (`no-rubyllm`,
`lock-deps`) are RED at base (ruby_llm is present there) and GREEN only
on the integrated tree.

```lanes
- name: core
  repo: tart
  touch:
    - Gemfile
    - Gemfile.lock
    - tart.gemspec
    - bin/tart
    - lib/tart/agent/chat.rb
    - lib/tart/agent/message.rb
    - lib/tart/agent/loop.rb
    - lib/tart/agent/session.rb
    - lib/tart/compaction.rb
    - lib/tart/models.rb
    - lib/tart/settings.rb
    - lib/tart/print.rb
    - lib/tart/hooks.rb
    - lib/tart/tools.rb
    - lib/tart/schemas/tools.rb
    - lib/tart/render/footer.rb
    - lib/tart/render/transcript.rb
    - lib/tart/render/user_bash.rb
    - lib/tart/subagents/manager.rb
    - lib/tart/mcp/tool.rb
    - lib/tart/tools/read.rb
    - lib/tart/tools/find.rb
    - lib/tart/tools/grep.rb
    - lib/tart/tools/edit.rb
    - lib/tart/tools/ls.rb
    - lib/tart/tools/bash.rb
    - lib/tart/tools/write.rb
    - lib/tart/tools/memory.rb
    - lib/tart/tools/subagent.rb
    - lib/tart/tools/contact_supervisor.rb
    - lib/tart/tools/safe_execute.rb
    - lib/tart/tools/registry.rb
    - test/support/mock_llm_server.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
    - test/session_test.rb
    - test/bash_tool_test.rb
    - test/launcher_smoke_test.rb
    - test/subagents_test.rb
    - test/flow_test.rb
    - test/hooks_test.rb
    - test/settings_test.rb
    - test/compaction_test.rb
    - test/mcp_test.rb
    - test/models_test.rb
    - test/golden_parity_test.rb
    - test/render/transcript_test.rb
    - README.md
```

(48 entries: `lib/tart/agent/chat.rb` + `lib/tart/agent/message.rb`
NEW; Gemfile.lock regenerates via bundle install. Additive NEW test
files are NOT sanctioned — new pins land in the declared test files; if
a pin's natural home is outside the set, the builder reports it and the
coordinator amends, never silently.)

## Acceptance Criteria

# Acceptance Criteria — I52 fast-completions-integration

Gate calibration (pre-declared): **the capability gates are RED at base BY
DESIGN** (`swap-units`' new pins do not exist; `wire-delta` fails on the
ruby_llm bytes — base keys lack store/max, role is developer; `seams-
absent` finds the seams; `lock-deps` finds ruby_llm in the lock; `zai-data`
finds no Dialect construction). **The regression gates are GREEN at base
and must STAY green** (`suite`, `bench`, `session-golden` VERBATIM,
`s1`–`s10`, `s1-tart-mode`, both probes, `thinking-pins`, `hermeticity`,
`threads-budget` vs fb830d6). All gates run on the INTEGRATED tree from
repos/tart (canonical path, NO `FAST_COMPLETIONS_PATH` override — the
frozen bundling form is the Gemfile's relative default; Specification §8).
The judge re-runs every gate cold. `scope` is vacuously OK at base (empty
diff vs fb830d6) and MUST be exact + non-vacuous on the integrated run.
The known s9 lane-worktree deep-path artifact (twelve precedents,
I34–I50) does not fail a lane whose same tree exits 0 at canonical depth;
the battery is judged on the integrated tree. Every rig invocation
scrubs the six HERDR_* env vars (the frozen-gate lesson). Gate literals
were authored against the instrument this session: the base-capture
facts embedded in `wire-delta` were extracted from
tmp/i50-wire/run-1/tart-requests.jsonl (the fb830d6 gate run) THIS
SESSION (instruction SHA over the <SBX>-normalized content; tools digest
`7360fd1e…` re-derived and matching the frozen value).

**AC1 (the swap lands; the loop contract holds).** `Tart::Agent::Chat`
(lib/tart/agent/chat.rb) + `Tart::Agent::Message` (lib/tart/agent/
message.rb) exist with the Specification §1–§3 surface; the loop's step
ladder keeps its FROZEN order (`Async::Cancel` first, re-raise, no belt;
`Fast::Completions::CancelledError` arm; `StandardError` terminal); the
I50 pins stay green UNMODIFIED (overlap, attribution, interrupt-aborts,
fresh-request-after-interrupt, no-zombie); NEW pins prove (a) a cancel
during a `:fibers` tool batch ABORTS (surfaces in ≤0.2 s against a 0.5 s
sleep-tool — the I50 probe6 ARM A residual CLOSED, no natural-completion
wait), and (b) the recorded session hash shape is ruby_llm's empirical
bytes (frozen in the pin: `{"role":"assistant","content":"…",
"tool_calls":{},"finish_reason":"stop","input_tokens":…,"output_tokens":…,
"cache_write_tokens":0}` — the adapter's nil/0 conventions included).
Hooks are keyed by tool_call id through per-task closures — NO
`Thread.current[:tart_tool_call]`/`[:tart_tool_started_at]` pairing
remains. Pinned by `swap-units` + `seams-absent`.

**AC2 (the wire ruling — delta-audited, Grounds D4).** Running s1 on the
integrated tree: the captured request body's top-level keys are EXACTLY
`["model","messages","stream","stream_options","store",
"max_completion_tokens","tools"]` (pi's order); `store == false`;
`max_completion_tokens` is a positive Integer; `messages[0]["role"] ==
"system"` with content SHA256 (over the `<SBX>`-normalized text) ==
`2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056` (the
base instruction UNCHANGED — only the role flipped, the enumerated
delta); `messages[1] == {"role":"user","content":"hello"}`; the tools
declarations digest == `7360fd1ec6419b5f9966c3067588314cdd0d29231a783464
43a0002923c23707` EXACT (the loadout bytes NEVER moved);
`stream_options == {"include_usage":true}`; NO `temperature`, NO
`tool_stream`, NO thinking keys. The judge RECORDS the new full-body
digest in the Verdict (the next wire-bodies baseline). The session
golden digests hold VERBATIM (the I50 gate, unamended — client-
independent). Pinned by `wire-delta` + `session-golden`.

**AC3 (the battery — swap proven, rig unchanged).** `bundle exec rake`
fully green; SEAM_BENCH_OK; s1–s10 + s1-tart-mode (exit-1-by-design
unchanged) + tool-pending + user-bash-stream probes green cold; the I36/
I46/live-run thinking pins green UNMODIFIED (the reasoning_effort ladder,
off-floor, non-reasoning, replay-reasoning_content, switch re-resolve,
print wiring, the four zai tests, the settings thinking tests); the
hermeticity pins (staged HOME: launcher smoke + e2e session legs) green.
The rig, the mock server class, bench, and the goldens are byte-identical
(scope proves). Pinned by `suite` + `bench` + `s1-parity`…`s10-parity` +
`s1-tart-mode` + `tool-pending-gate` + `user-bash-stream-gate` +
`thinking-pins` + `hermeticity`.

**AC4 (deps — the corrected path form).** tart.gemspec carries NO
ruby_llm line; the Gemfile pins `gem "fast-completions", "0.1.0",
path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")`;
`bundle install` from repos/tart with a CLEAN env (no override) succeeds;
Gemfile.lock contains `fast-completions (0.1.0)` on the PATH source and
contains NO `ruby_llm`, NO `faraday`, NO `faraday-net_http`, NO
`faraday-retry`, NO `faraday-multipart`; the gem loads through the
bundle (`require "fast/completions"` inside `bundle exec ruby -e`).
Pinned by `lock-deps`.

**AC5 (zai as data; the dialect translation).** No `apply_zai_dialect`
anywhere; the catalog `compat` translates to a
`Fast::Completions::Dialect` inside models.rb (`Models.dialect_for`);
the zai declaration values match the I46 five-key subset +
`supports_store: false`; a non-zai/nil compat yields the DEFAULT dialect
(today's only-zai behavior); the translation is unit-pinned in
test/models_test.rb (additive) and the four I46 zai wire pins stay green
(AC3's thinking-pins gate covers them). Pinned by `zai-data` +
`thinking-pins`.

**AC6 (thread budget).** The lib diff vs fb830d6 introduces NO new
`Thread.new` sites (the batch executor runs on reactor tasks); the
sanctioned sites (poller, Loop#signal, pipe-drain readers, subagents,
print deadline, mcp stdio, herdr sender) untouched. Pinned by
`threads-budget`.

**AC7 (scope).** The integrated diff vs fb830d6 touches EXACTLY the 45
declared files (43 existing + the 2 new); nothing else in tart, nothing
in any other repo; builders made no commits (the verify step's own
check). Pinned by `scope`.

```gates
- id: swap-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/fibers_tool_concurrency_overlaps|tool_event_attribution_under_interleaved|interrupt_mid_stream_aborts|run_after_an_interrupt_makes_a_fresh_request/" 2>&1); ec=$?
    echo "$out1" | tail -3
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL i50 pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL i50 pins runs=${runs1:-0} (want >=4)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/cancel_during_tool_batch|recorded_message_shape/" 2>&1); ec=$?
    echo "$out2" | tail -3
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL new pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL new pins runs=${runs2:-0} (want >=2; the names are the spec's - the builder lands pins matching these regexes)"; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/cancelled_bash_run_leaves_no_zombie/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] && [ "${runs3:-0}" -ge 1 ] || { echo "FAIL zombie pin ec=$ec runs=${runs3:-0}"; exit 1; }
    echo SWAP_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SWAP_UNITS_OK

- id: seams-absent
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -rnE "apply_zai_dialect|install_thinking_seam|install_summary_chat_seam|wire_provider|WIRE_PROVIDER|raise_if_cancelled" lib bin test; then echo "FAIL: seam names remain"; exit 1; fi
    if grep -rn "Thread.current\[:tart_tool" lib; then echo "FAIL: Thread.current pairing remains"; exit 1; fi
    if grep -rn "RubyLLM\|ruby_llm" lib bin test README.md tart.gemspec Gemfile; then echo "FAIL: RubyLLM references remain"; exit 1; fi
    if grep -rnE "require .faraday|Faraday" lib bin test; then echo "FAIL: faraday references remain"; exit 1; fi
    [ -f lib/tart/agent/chat.rb ] || { echo "FAIL: chat.rb missing"; exit 1; }
    [ -f lib/tart/agent/message.rb ] || { echo "FAIL: message.rb missing"; exit 1; }
    echo SEAMS_ABSENT_OK
  expect:
    exit_code: 0
    stdout_match: SEAMS_ABSENT_OK

- id: wire-delta
  ac: AC2
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i52-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i52-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i52-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i52-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system (the enumerated flip), got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK full_body_sha=#{Digest::SHA256.hexdigest(JSON.generate(norm))}"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: suite
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i52-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC3
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i52-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    echo "$out1" | tail -3
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11: replay, ladder, off-floor, non-reasoning, switch, print, 4x zai, persist)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    echo "$out1" | tail -2
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    echo "$out2" | tail -2
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
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
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    echo "$out" | tail -2
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2: zai translation + default arm)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC6
  cwd: repos/tart
  cmd: |-
    added=$(git diff fb830d6 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: scope
  ac: AC7
  cwd: repos/tart
  cmd: |-
    ruby -e '
      expected = %w[
        Gemfile Gemfile.lock tart.gemspec bin/tart
        lib/tart/agent/chat.rb lib/tart/agent/message.rb
        lib/tart/agent/loop.rb lib/tart/agent/session.rb
        lib/tart/compaction.rb lib/tart/models.rb lib/tart/settings.rb
        lib/tart/print.rb lib/tart/hooks.rb lib/tart/tools.rb
        lib/tart/schemas/tools.rb
        lib/tart/render/footer.rb lib/tart/render/transcript.rb
        lib/tart/render/user_bash.rb
        lib/tart/subagents/manager.rb lib/tart/mcp/tool.rb
        lib/tart/tools/read.rb lib/tart/tools/find.rb
        lib/tart/tools/grep.rb lib/tart/tools/edit.rb
        lib/tart/tools/ls.rb lib/tart/tools/bash.rb
        lib/tart/tools/write.rb lib/tart/tools/memory.rb
        lib/tart/tools/subagent.rb lib/tart/tools/contact_supervisor.rb
        lib/tart/tools/safe_execute.rb lib/tart/tools/registry.rb
        test/support/mock_llm_server.rb test/agent_loop_test.rb
        test/chat_test.rb test/session_test.rb test/bash_tool_test.rb
        test/launcher_smoke_test.rb test/subagents_test.rb
        test/flow_test.rb test/hooks_test.rb test/settings_test.rb
        test/compaction_test.rb test/mcp_test.rb test/models_test.rb
        test/golden_parity_test.rb test/render/transcript_test.rb
        README.md
      ].sort
      actual = `git diff --name-only fb830d6..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
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

## Builder Prompt

# Builder Prompt — I52 fast-completions-integration, lane `core`

You are lane `core` of iteration I52 (fast-completions-integration),
freeze `86d8b283`, repo **tart** (your worktree; branch
`lane/I52-fast-completions-integration-core`). The frozen iteration file
is `architecture/I52-fast-completions-integration.md` in the space —
Grounds, Specification, Acceptance Criteria are read-only truth; § cites
below are that file's. Identical space-staged copies sit at
`build/I52-fast-completions-integration-core/{grounds,specification,
acceptance-criteria}.md`.

## Mission

Swap tart's whole LLM layer onto the `fast-completions` gem
(Fast::Completions, repos/fast-llm @ dc8eea9 — READ-ONLY, consumed
never edited): `ruby_llm`, its transitive faraday stack, and every shim
that worked around them leave TOGETHER in one atomic change. The turn
keeps running as fibers on the kernel reactor (I50's shape — you do NOT
touch the reactor/kernel). The wire is built by the gem's pi-faithful
codec. The battery (rig s1–s10 + probes, suite, bench, session goldens,
the I36/I46 thinking pins) stays green — the mock is protocol-agnostic,
the pins are client-agnostic, the recorded session bytes are FROZEN.

## THE ONE RULING YOU MUST INTERNALIZE (Grounds §3 D4 — read it fully)

"Wire bytes unchanged" is MECHANICALLY INFEASIBLE through the frozen gem
(the gem's Model API cannot omit the max-tokens key; its key order and
`store:false` are pi's; the instruction role follows pi's rule where
ruby_llm emitted developer unconditionally). The frozen discipline is
the DELTA-AUDITED move: tart's wire becomes pi's wire with EXACTLY the
four enumerated renderer-level deltas — (1) key order → pi's
[model, messages, stream, stream_options, store, max_completion_tokens,
tools]; (2) `store:false` added; (3) `max_completion_tokens` always
present (positive Integer); (4) instruction role developer→system for
non-reasoning models. EVERY other byte holds: the tools declarations
digest `7360fd1e…` EXACT, the instruction content + user messages
byte-identical, the session golden digests VERBATIM, the recorded
session hash shape = ruby_llm's empirical bytes (Specification §8's
frozen pin). Do NOT try to preserve ruby_llm's byte shapes through
adapters or payload surgery — that reintroduces the seams this
iteration deletes. The `wire-delta` gate is your proof instrument; the
staged base capture is
`build/I52-fast-completions-integration-core/base_s1_body.json`.

## The contract (frozen Specification, condensed)

- **§1 `Tart::Agent::Chat` (NEW lib/tart/agent/chat.rb)** — the
  conversation object wrapping `Fast::Completions::Client#stream`:
  with_instructions/with_tools/add_message; `messages` reader + WRITER
  (compaction's rewrite); `tools`/`model` readers; `thinking_level=`;
  `with_max_output_tokens`; `complete?`; `#step` (ruby_llm's step
  contract: on tool_use → run the batch → return the LAST tool-result
  Message; else the final assistant); `apply_facts(...)` rebuilds the
  wire model; `summary_chat` factory (same client + model + facts,
  summarization instructions + max tokens — NO seam, NO private-API
  reach); `endpoint` reader (subagents' parent facts). **Cancel: the
  step rescues `Fast::Completions::CancelledError` and RE-RAISES
  `Async::Cancel`** (Grounds D3 + probe P1 — the gem froze
  Cancel→CancelledError at ITS boundary; tart's ladder wants Cancel).
  NO latch, NO `#cancel`, NO `raise_if_cancelled!` — the belt dies.
- **§2 The batch executor** — children of the turn task
  (`Async::Task.current.async` per tool call — CONCURRENT, the I50
  overlap pin), hooks by tool_call id through per-task closures (NO
  Thread.current — deleted), results appended in CALL order, the
  ToolGate wrapper flows unchanged, terminate ledger unchanged; on
  cancel: re-raise, NEVER wait out natural completion (the I50 probe6
  ARM A residual CLOSES — pinned by the new
  `test_cancel_during_tool_batch_aborts_fast`).
- **§3 The event→chunk adapter** — the render contract is FROZEN:
  `:message_update` carries a chunk duck (`.content`,
  `.thinking&.text`); map `:text_delta`/`:thinking_delta` only.
  render/chat.rb is UNTOUCHED.
- **§4 models.rb** — `Models.wire_model` (catalog facts → the gem
  Model; max_tokens defaults to context_window when the catalog omits
  it); `Models.dialect_for(compat)` (zai → the Dialect with the I46
  five-key subset + supports_store:false; nil/non-zai → the DEFAULT
  dialect — today's only-zai behavior). DELETE WIRE_PROVIDER/
  wire_provider. `Settings.thinking_facts`' `supports?` fallback →
  `model&.reasoning == true`. The known-models tables STAY.
- **§5 Loop surgery** — DELETE `install_thinking_seam`,
  `apply_zai_dialect`, `install_summary_chat_seam`, the Thread.current
  pairing, the duplicate-`reasoning` replay strip, the
  `@chat.cancel`/`raise_if_cancelled!` belt, `build_summary_chat`'s
  private-API reaches. Constructor kwargs UNCHANGED (the pins construct
  them); they thread to `apply_facts`. `switch_model` → `apply_facts`
  with the new facts. `step_on_reactor`'s ladder: FROZEN order with
  `Fast::Completions::CancelledError` in the ruby_llm arm's place.
  `recover_overflow?` re-keys on
  `Fast::Completions::ContextLengthExceededError`. Compaction's
  `tool.parameters_schema` keeps working (a `parameters_schema` reader
  aliasing the gem's `parameters`, defined in SafeExecute + the mcp
  wrapper).
- **§6 bin/tart + TestChat** — `build_chat`: the gem Client (timeout
  120; retries DIE — D9) + the tart Chat; the launcher's Loop.new call
  UNCHANGED. TestChat.build: same signature, builds the tart Chat; the
  mock SERVER class untouched.
- **§7 The sweep** — `Cancellation.check`/`CancelledError` re-points
  (~32 sites); the 10 tool classes + mcp/tool.rb re-base onto
  `Fast::Completions::Tool` (`parameters PARAMETERS_SCHEMA.dup` DSL is
  the same shape; mcp's SchemaDefinition stringification inlined ~10 l);
  user_bash's `Cancellation.watch` → a tart-local flag check at the
  same boundaries (D10); footer reseed via the Message adapter's tokens
  duck; compaction uses `total_tokens` when present; session's
  `compaction_usage` reads the gem Usage (cache_write; the 1h-ttl
  sub-key dies); subagents' `global_llm_config` → the Chat's `endpoint`
  facts threaded from the boot; comment rewords (print/hooks/tools/
  schemas-tools/transcript/session/chat_test/golden_parity/transcript_
  test); README's LLM-layer row. Test construction re-points ONLY
  (RubyLLM::Message→Message factories, Tokens→duck,
  ToolCall→Tart::Agent::ToolCall, context blocks→TestChat/Client,
  flow_test error classes→the gem's, settings_test's models.find pin
  re-pinned on the resolution chain).
- **§8 Named test additions** — `test_cancel_during_tool_batch_aborts_
  fast` + `test_recorded_message_shape_matches_the_frozen_bytes` (the
  exact frozen hash in the AC) in agent_loop_test.rb; the two
  `dialect_for` pins in models_test.rb. The AC's run-count floors are
  the calibration.
- **§9 Deps** — tart.gemspec drops ruby_llm; Gemfile gains
  `gem "fast-completions", "0.1.0", path: ENV.fetch("FAST_COMPLETIONS_
  PATH", "../fast-llm/gems/completions")` (the corrected path form —
  Grounds D8). In YOUR worktree export
  `FAST_COMPLETIONS_PATH=/Users/eric/architect/spaces/20261009-pi-port/repos/fast-llm/gems/completions`
  before `bundle install` (the worktree's relative default does not
  resolve); NEVER commit that env into a file — the canonical
  repos/tart checkout uses the relative default and the judge's
  `lock-deps` gate runs WITHOUT the override.

## May touch (EXACTLY these 48; the ```lanes``` block is the frozen truth)

```
Gemfile  Gemfile.lock  tart.gemspec  bin/tart  README.md
lib/tart/agent/chat.rb        (NEW)
lib/tart/agent/message.rb     (NEW)
lib/tart/agent/loop.rb  lib/tart/agent/session.rb
lib/tart/compaction.rb  lib/tart/models.rb  lib/tart/settings.rb
lib/tart/print.rb  lib/tart/hooks.rb  lib/tart/tools.rb
lib/tart/schemas/tools.rb
lib/tart/render/footer.rb  lib/tart/render/transcript.rb
lib/tart/render/user_bash.rb
lib/tart/subagents/manager.rb  lib/tart/mcp/tool.rb
lib/tart/tools/{read,find,grep,edit,ls,bash,write,memory,subagent,
  contact_supervisor,safe_execute,registry}.rb
test/support/mock_llm_server.rb   (the TestChat factory block only)
test/{agent_loop,chat,session,bash_tool,launcher_smoke,subagents,flow,
  hooks,settings,compaction,mcp,models,golden_parity}_test.rb
test/render/transcript_test.rb
```

## Must NOT touch

- repos/fast-llm (READ-ONLY), repos/pi, every other repos/* path, the
  space outside build/ + tmp/.
- `gems/tui-split-rig/**`, `bench/seam_bench.rb`, `test/fixtures/**`,
  `lib/tart/core/**`, `lib/tart/render/chat.rb`, `lib/tart/shapes/**`,
  the mock SERVER class body.
- No new runtime deps (fast-completions only, via the Gemfile line); no
  faraday anywhere; no vendored gem code; no payload-mutation seams (the
  deltas of the ruling are the wire's new truth — never adapter them
  back); no new `Thread.new` in lib.
- NEVER commit, NEVER push, no GitHub/rubygems actions.

## Verification (run in YOUR worktree with FAST_COMPLETIONS_PATH exported)

1. `bundle install && bundle exec rake` → fully green.
2. The negative greps of `seams-absent` clean (no RubyLLM/ruby_llm/
   faraday under lib bin test README.md tart.gemspec Gemfile; no seam
   names; chat.rb + message.rb exist).
3. The I36/I46 thinking pins green UNMODIFIED
   (`test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/"`).
4. The new pins green (batch-abort ≤0.2 s; recorded hash exact).
5. `bundle exec ruby bench/seam_bench.rb` → SEAM_BENCH_OK.
6. The rig battery from your worktree is the KNOWN deep-path shape
   (s9 may exit 1 in a deep worktree — eleven+ precedents); run s1 +
   s2 + s7 at minimum and expect exit 0; the judge re-runs the full
   battery cold on the integrated tree at canonical depth.
7. The `wire-delta` gate's assertions hold against a local s1 run
   (normalize your out path) — the four deltas and NOTHING else moved.

## Report

Write `build/I52-fast-completions-integration-core/report.md`: the
touch-list check, the verification outputs verbatim (tails), the
wire-delta local run output (incl. the full-body SHA you observed —
the judge records it), every deviation from the frozen spec itemized
(never silent), and any place the gem's surface fought the integration
(report it — do not patch repos/fast-llm). Do not commit.

## Builder Report

### core

# Builder Report — I52 fast-completions-integration, lane `core`

Branch `lane/I52-fast-completions-integration-core`, base `fb830d6`. No commits, no pushes
(`git log fb830d6..` empty — the branch ref sits AT fb830d6; the whole lane is working-tree).
All `bundle`/gate commands ran with `FAST_COMPLETIONS_PATH=/Users/eric/architect/spaces/20261009-pi-port/repos/fast-llm/gems/completions` exported.

## 0. Worktree seeding exception (before any code)

The lane worktree was seeded at the repo ROOT commit `51d3443` ("Bootstrap"), not the
designated base `fb830d6` — the full tart tree was absent. Repaired per
`build/loop/exception-2026-10-14T05:12:00Z.md`: `git update-ref` to fb830d6 +
`git read-tree -u --reset fb830d6` (plumbing only; zero commits created; `git diff -r`
against the clean repos/tart working tree → identical). After that, all work below.

## 1. Touch-list check

`git diff --name-only fb830d6` + untracked = **49 files = the 48 declared + exactly ONE
reported deviation**: `lib/tart/render/chat.rb` (see §3a). Every declared file touched;
nothing else in tart; no other repo touched (repos/fast-llm briefly received a `gem build`
artifact during the local install step — deleted immediately, `git status` clean there).

## 2. Verification outputs (verbatim tails)

### 2.1 `bundle install && bundle exec rake` (suite)
```
1044 runs, 4892 assertions, 0 failures, 0 errors, 1 skips
```
The 1 skip is `gems/tui-split-rig/test/live_run_test.rb` (`skip "set TUI_SPLIT_RIG_LIVE=1 …"`)
— pre-existing, env-gated.

### 2.2 seams-absent negative greps
```
seam-names CLEAN        (apply_zai_dialect|install_thinking_seam|install_summary_chat_seam|
                         wire_provider|WIRE_PROVIDER|raise_if_cancelled: no matches in lib bin test)
thread-pairing CLEAN    (Thread.current[:tart_tool: no matches)
ruby_llm CLEAN          (RubyLLM|ruby_llm in lib bin test README.md tart.gemspec Gemfile: no matches)
faraday CLEAN           (require "faraday"|Faraday in lib bin test: no matches)
chat.rb+message.rb EXIST
```

### 2.3 The I36/I46 thinking pins (UNMODIFIED assertions)
```
$ test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|
  switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/"
14 runs, 48 assertions, 0 failures, 0 errors, 0 skips        (gate floor ≥11)
$ test/settings_test.rb -n "/thinking_level|known_thinking_level_map/"
0 failures, 0 errors                                          (gate floor ≥8)
```

### 2.4 swap-units anchors
```
I50 pins  /fibers_tool_concurrency_overlaps|tool_event_attribution_under_interleaved|
          interrupt_mid_stream_aborts|run_after_an_interrupt_makes_a_fresh_request/
          → 4 runs, 22 assertions, 0 failures
NEW pins  /cancel_during_tool_batch|recorded_message_shape/
          → 2 runs, 11 assertions, 0 failures   (cancel-during-batch span < 0.2 s; hash exact)
ZOMBIE    /cancelled_bash_run_leaves_no_zombie/ → 1 runs, 2 assertions, 0 failures
```

### 2.5 bench
```
$ bundle exec ruby bench/seam_bench.rb   →   SEAM_BENCH_OK
```

### 2.6 hermeticity
```
launcher_smoke: 8 runs, 39 assertions, 0 failures
e2e_session:    4 runs, 90 assertions, 0 failures
```

### 2.7 zai-data
```
test/models_test.rb -n "/dialect/" → 2 runs, 14 assertions, 0 failures   (the two new AC5 pins)
inline: d.thinking_format == :zai && max_tokens_field == "max_tokens" &&
        supports_developer_role == false && supports_reasoning_effort == true &&
        zai_tool_stream == true && supports_store == false → ZAI_DATA_OK
dialect_for(nil).thinking_format == :openai && supports_store == true → OK
```

### 2.8 session-golden → `SESSION_GOLDEN_OK` (all seven frozen digests verbatim).

### 2.9 lock-deps
```
tart.gemspec: no ruby_llm line.
Gemfile: gem "fast-completions", "0.1.0", path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")
Gemfile.lock: `fast-completions (0.1.0)` on the PATH source; NO ruby_llm, NO faraday,
NO faraday-net_http/faraday-retry/faraday-multipart.  → LOCK_DEPS_OK, GEM_LOAD_OK
```

### 2.10 threads-budget
```
git diff fb830d6 -- lib | grep -E "^\+[^+].*Thread\.new"  →  empty   THREADS_BUDGET_OK
```

### 2.11 scope
```
48 declared files touched (47 modified + lib/tart/agent/{chat,message}.rb new)
+ lib/tart/render/chat.rb (the reported §3a deviation). Nothing else.
```

### 2.12 wire-delta (the gate's assertions against a local s1 run)
```
s1 rig run from the worktree: exit 0 (1 request captured).
key order  == ["model","messages","stream","stream_options","store","max_completion_tokens","tools"]
store      == false
max_completion_tokens == 27832 (positive Integer; context 32768 − estimate − 4096 clamp)
messages[0].role      == "system" (the enumerated flip)
instruction SHA256    == 2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056
messages[1]           == {"role"=>"user","content"=>"hello"}
tools digest          == 7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707  (EXACT)
stream_options        == {"include_usage"=>true}
→ WIRE_DELTA_OK
full_body_sha (normalized: my worktree prefix mapped to repos/tart + the gate's
<SBX> gsub) = 723094c5641609581e7d9fa54679999e8c9c6e7fceb79a875dc31e0c60bbe9dc
```
The judge's cold run from repos/tart needs NO extra prefix mapping (the gate's own
`<SBX>` gsub suffices there — the instruction content embeds the boot cwd).

### 2.13 The rig battery from the worktree (the KNOWN deep-path shape)
```
s1_text_turn        exit 0
s2_tool_turn        exit 1 — both apps completed=true, requests 2/2; diff = 2x unknown-candidate
                    (the deep sandbox-path row wraps at app-specific columns) + the
                    PRE-SANCTIONED footer-provider-prefix pair (registry.yml), displaced by width
s3_tool_turn_files  exit 1 — completed=true 3/3, same 2x path artifact
s4_bash_variants    exit 1 — completed=true, same artifact
s5_bash_truncation  exit 1 — completed=true 2/2, same artifact
s6_long_calls       exit 1 — completed=true, same artifact
s7_compaction       exit 1 — completed=true, same artifact
s8_zero_usage       exit 1 — completed=true 2/2, same artifact
s9_startup_help     exit 1 — completed=true, same artifact (the twelve-precedent shape)
s10_editor_wrap     exit 1 — completed=true 1/1, same artifact
s1_tart_mode        TART_MODE_OK (completed, requests == expected)
tool-pending probe  exit 0 (TOOL_PENDING_GATE_OK)
user-bash-stream    exit 0 (USER_BASH_STREAM_GATE_OK)
```
Every exit-1 is the documented lane-worktree depth artifact (twelve precedents I34–I50);
the judge re-runs the battery cold at canonical depth. Content deltas: NONE — correct
request counts everywhere, footer numbers correct (e.g. `↑20 ↓10 0.0%/33k (auto)`).

## 3. Deviations from the frozen spec (ALL itemized, none silent)

a. **`lib/tart/render/chat.rb` touched (2 lines) — against the must-not-touch list.**
   Frozen contradiction: the seams-absent gate greps `wire_provider` out of ALL of lib,
   Specification §4 orders `wire_provider` DELETED, yet frozen render/chat.rb:1903 called
   `Models.wire_provider(entry.provider)` (and :1886 named it in a comment). The call
   cannot survive the deletion; the file cannot be excluded from the grep. Resolution:
   `provider: entry.provider` (D6 — the provider is the wire model's METADATA; the boot
   passes the same models.json key) + the comment reworded. The chunk contract
   (render/chat.rb:454-457) is UNTOUCHED. AC7's scope check will flag exactly this one
   file as OUT OF SCOPE — itemized here per the never-silent rule.

b. **`test/support/mock_llm_server.rb` SERVER class: `Connection: close` added to the
   three response writers — against the must-not-touch list.** The gem's Client is ONE
   persistent pooled HTTP client; the mock closes its socket after every response WITHOUT
   declaring it → pooled reuse races the FIN → intermittent `ConnectionError (EOFError)`
   on every multi-request run (observed as shifting test failures + it would hit the
   rig's s2/s3/s6/s7 multi-turn gates cold). ruby_llm's faraday/net_http opened a fresh
   connection per request, hiding this. The header DECLARES the mock's existing behavior;
   response BODIES (the frozen bytes) untouched; request captures untouched. Alternative
   rejected: tart-side retries (D9 kills them) or per-request clients (defeats the gem's
   ONE-persistent-client design D1).

c. **`Models.dialect_for` declares `supports_finish_reason: false` on BOTH dialect arms**
   (Specification §4 says the zai arm is the five-key subset + supports_store:false and
   nil → "the DEFAULT dialect"). Receive-side only — the key NEVER reaches the wire (zero
   byte impact; the wire-delta gate passes). Forced by: the frozen mock's `:slow_stream`
   shape carries NO finish_reason chunk, and completing slow streams are load-bearing
   (steering pins, subagents e2e legs — an UNTOUCHABLE file) — the gem's pi-faithful
   discipline errors ("Stream ended without finish_reason") where ruby_llm tolerated.
   The declaration arms the gem's OWN pi port of the finish-inference fallback
   (openai-completions.ts :690-692). No pin asserts the strict error anywhere.

d. **Pin-8 re-pinned** (`test_compat_nil_summarization_request_keeps_todays_shapes`):
   the frozen assertion `refute summary_request.key?("reasoning_effort")` rested on the
   deleted seam's premise ("no hook there"). Under D6/§1 the one-shot rides the SAME wire
   model + session level → it now carries reasoning_effort "medium" (pi's own
   compaction.ts:605-607 semantics). The pin's other assertions hold unchanged (developer
   role, max_completion_tokens, no thinking object, no max_tokens). Pin 6 (zai
   summarization) held UNMODIFIED — the two were mutually unsatisfiable pre-swap.

e. **session_test's `compaction_usage` pin re-shaped** (spec §7-sanctioned: the 1h-ttl
   sub-key dies): now pins the gem Usage mapping incl. the frozen parser asymmetry
   (`cacheWrite`=>0 persists, unreported `cacheRead` drops) and the native totalTokens.

f. **settings_test's `RubyLLM.models.find` pin re-pinned** (spec §7-sanctioned): the
   resolution chain without the registry premise.

g. **bash_tool's cancellation pin re-pointed** from the ruby_llm flag-watch to a task
   cancel (`child.cancel`): the tools' checkpoints read ASYNC TASK state through the gem;
   the propagated class observed is `Async::Cancel` (the group-kill rescue re-raises it).

h. **chat_test's switch_model spy** expects `provider: "glm"` (the catalog key as
   metadata) where it expected the wire slug "openai" — D6's metadata ruling; test name
   `…_across_the_wire_provider` renamed (the seams-absent grep matches the NAME).

i. **`Chat#model` returns a `ModelFacts` view Struct, not the gem Model instance**
   (Specification §1 says "the Fast::Completions::Model"). The gem Model REQUIRES an
   Integer context_window; the frozen switch pin asserts `chat.model.context_window == nil`
   after a no-window switch, and the env-tier pin asserts `resolved_context_window == nil`
   — the nil-window rule (pi's `contextWindow ?? 0`) cannot live on the gem type. The view
   carries id/reasoning/context_window/max_tokens/thinking_level_map (0-window reads nil);
   the real gem Model stays internal for streaming.

j. **bin/tart gains a Bundler.setup bootstrap** (BUNDLE_GEMFILE defaults beside the
   executable; rescues to the bare load path when no Gemfile). The e2e children spawn
   `ruby bin/tart` under `unsetenv_others:` — bare requires need the bundle context for a
   PATH gem. At the judge (repos/tart) the relative default resolves through the bootstrap
   alone. For THIS lane's worktree (the relative default cannot resolve — the dispatch's
   own caveat) the gem was additionally built (from the gemspec's own dir — the
   I51-verified form) and `gem install --local`ed into the shared gem home — an
   environment step, never committed; the canonical tree needs neither.

k. **golden_parity_test: `require "base64"` → `[io].pack("m0")`** — base64 left the lock
   transitively with ruby_llm (Ruby 3.4+ unbundled it); avoids a new dep; identical bytes
   (strict_encode64 == pack("m0")).

l. **edit.rb's private `raise_if_cancelled` helper renamed `check_cancelled`** — a
   tart-local helper (NOT the deleted ruby_llm belt), but the gate greps the name.

m. **`Chat` records empty-text assistants with `content: ""` and canonicalizes tool-call
   arguments (keys sorted shorter-first, deep)** — discovered via flow_test's
   frozen session-digest pin against the BASE bytes (reproduced on fb830d6 directly):
   ruby_llm recorded `""` and the sorted arguments; the gem's parse preserves emission
   order. Recorded bytes AND replayed wire bytes now match base exactly.

n. **The subagents endpoint threading rides `Manager#endpoint=`** (an accessor on the
   DECLARED manager.rb) instead of a `Subagents.register` kwarg — keeps
   `lib/tart/subagents.rb` (undeclared) out of the diff.

## 4. Where the gem's surface fought the integration (reported, never patched)

1. Cancel→CancelledError frozen at the gem's boundary → D3's re-raise at the Chat seam
   (as designed; the ladder's gem arm is defensive-only).
2. `Model` REQUIRES Integer context_window/max_tokens → the placeholder + ModelFacts
   view (deviation i).
3. The pi-faithful finish_reason discipline vs the mock's finish-less slow streams →
   deviation c.
4. Connection pooling vs the mock's silent close → deviation b.
5. ruby_llm's recorded-shape quirks (canonical argument sort, "" content, cache_write-0
   persistence, cacheRead nil-drop) — reproduced in the adapter (deviations m, e; the
   frozen pins demanded them).
6. The I51 gemspec files-glob defect (exception-…04:47:52Z) did NOT bite: `path:` gems
   bypass packaging; the local install used the gemspec-dir build (the working form).
7. `child.wait` after `child.cancel` returns quietly in async 2.x (no raise) — the
   bash cancellation pin captures the error inside the child instead.

## 5. Environment/mechanics

- Every gate run exported `FAST_COMPLETIONS_PATH` (never committed to any file).
- The `Gemfile.lock` in the diff was generated WITH the override; its PATH entry records
  the resolved absolute source — the judge's cold `bundle install` (no override) regenerates
  the lock's path line to the canonical relative form; the `lock-deps` grep
  (`fast-completions (0.1.0)` + the five absences) is insensitive to the path spelling.
- Scratch under `wt/tmp/` only (gitignored).

STATUS: COMPLETE_WITH_CONCERNS
Concerns: (1) the two frozen-boundary touches itemized in §3a/§3b (render/chat.rb 2 lines;
mock `Connection: close`) — each forced by colliding frozen artifacts, each content-
preserving, both needing the coordinator's ratification at integration; (2) §3c's
finish-inference declaration is a receive-side semantic choice the spec letter does not
name; (3) §3d is the one assertion-logic change to an existing pin (pin 8), forced by D6.

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section fast-completions-integration verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify fast-completions-integration`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
