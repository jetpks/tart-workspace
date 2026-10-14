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
  the settings thinking tests are UNMODIFIED.

## 8. Dependencies

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

## 9. Boundaries

May touch: EXACTLY the 44 files of the ```lanes``` block (42 existing +
2 new). Must NOT touch:

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

## 10. Lane plan

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
```

(45 entries: 42 existing files + `lib/tart/agent/chat.rb` +
`lib/tart/agent/message.rb` NEW. `Gemfile.lock` regenerates via bundle
install. Additive NEW test files are NOT sanctioned — new pins land in
the declared test files; if a pin's natural home is outside the set, the
builder reports it and the coordinator amends, never silently.)

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
`architect rehearse fast-completions-integration` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze fast-completions-integration` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse fast-completions-integration` — before the freeze, while
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
subsection per lane. A copy is written to build/I52-fast-completions-integration-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section fast-completions-integration prompt --append --lane <lane> --from build/I52-fast-completions-integration-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I52-fast-completions-integration-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence fast-completions-integration --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
