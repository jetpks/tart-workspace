# I51: fast-completions-gem

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I51 fast-completions-gem

## 0. Control (this session)

- Space base: `4d871ee` ("I50: scaffold de-bridge" — the sibling spec's
  scaffold; the space metadata rule held: this session waited for
  `architecture/I50-de-bridge.md` before `architect new`).
- This iteration: ENTRY 2 of the successor program
  (`build/loop/plan-20261013T222728Z.md` — read in full this session). The
  predecessor program (I43–I49) is CLOSED and integrated; nothing of it is
  re-judged here.
- repos/tart at `project/pi-port` `2943ef0` (I49 integrated tip) —
  READ-ONLY for this entry (oracle cross-refs + the mock-server source only).
  This entry never edits tart.
- repos/pi at `f1b2e77f5` (the pinned fork, `main` behind origin by 92 —
  the pin is the fork, not origin) — the source oracle, read-only.
- Installed pi runtime: `@earendil-works/pi-coding-agent` 1.1.0 at
  `/Users/eric/.local/share/mise/installs/node/24.18.0/lib/node_modules/` —
  the SAME binary the tui-split-rig parity program ran as the pi oracle
  (I16-era capture headers prove it: `user-agent: pi (darwin …)`), with the
  bundled compiled `@earendil-works/pi-ai` 1.1.0 dist + `openai` 7.19.0.
- repos/fast-llm DID NOT EXIST. This session created it per the plan's
  provision rule: `git init -b main`, initial commit `b6ffad1` containing
  ONLY a placeholder README (the real monorepo scaffold is the builders'
  work). `architect provision` materializes lane worktrees from it.

## 1. The program frame (owner rulings 2026-10-13, plan preamble)

- Naming LOCKED: repo `fast-llm`; gem `fast-completions`
  (`Fast::Completions`, `require "fast/completions"` — house style per
  fast-protowire/fast-prometheus). Future siblings (fast-messages,
  fast-responses) are NOT this program.
- Dialects are DECLARATIONS inside the codec gem — never separate gems,
  never model catalogs. NO model catalog, NO pricing, NO provider registry,
  NO universal-translation ambition (LiteLLM is the anti-shape).
- Deps: async-http ONLY (+ its transitive async/io-event). Zero else.
- THE WIRE IS FROZEN — but for this entry that means the NEW gem must be
  byte-faithful to pi's wire; tart's wire is untouched (this entry never
  touches tart).
- Builders never commit; never push; NO GitHub/rubygems actions in-loop —
  per-gem release tags are the human's at landing; the loop stops at
  releasable.
- The done-bar is pi parity; the oracle IS the spec.

## 2. The oracle map (repos/pi/packages/ai/src, verified line-by-line this session)

`api/openai-completions.ts` (1,734 l) — THE single-protocol spec:
- `streamSimple` :736-768 — the simple entry: builds base options, clamps
  the thinking level (`clampThinkingLevel`), `off` ⇒ NO `reasoningEffort`
  (a clamped-off request sends no effort at all), delegates to `stream`.
- `stream` :304-734 — SSE consumption: output seed :312-327 (usage zeros,
  stopReason "pending"), streamed `reasoning_details` capture :334-341
  (replay metadata serialized ONCE at block finalize, :436-443), block
  machinery :445-560 (text/thinking/tool-call blocks; `toolCallBlocksByIndex`
  + `toolCallBlocksById` maps), per-chunk loop :558-655:
  `responseId`/`responseModel` capture, usage :568-573 + the Moonshot
  `choice.usage` fallback :582-585, finish_reason map :587-597, content
  deltas :599-614, reasoning-field detection :616-641 (first non-empty of
  `reasoning_content`, `reasoning`, `reasoning_text`; the field NAME is
  kept as the block signature), tool-call deltas :643-662 (index-then-id
  block resolution, raw string delta pushed, `partialArgs` accumulation),
  `reasoning_details` deltas :664-677. Stream-end discipline :679-707:
  aborted ⇒ throw; no finish_reason and `!supportsFinishReason` ⇒ infer
  toolUse/stop; `error` stopReason ⇒ throw; stream ended without
  finish_reason ⇒ throw. Error arm :709-733: blocks finalized (scratch
  buffers stripped), stopReason aborted/error, formatted error message.
- `buildParams` :802-1000 — THE request byte contract (key insertion
  order = wire order): `{model, messages, stream}` → `stream_options.
  {include_usage:true}` (iff `supportsUsageInStreaming`) → `store:false`
  (iff `supportsStore`) → max tokens (`max_tokens` iff `maxTokensField
  === "max_tokens"` else `max_completion_tokens`) → `temperature` (only
  when set) → `tools` + zai `tool_stream:true` (iff tools present; the
  tool-history fallback `tools: []` :860-863) → `tool_choice` (only when
  set) → thinking arms (below) → thinking budget field :961-963 →
  sampling params LAST.
- Thinking/effort ladder arms :879-957 — `zai` :880-892 (thinking object
  `enabled`+`clear_thinking:false` when an effort is present, `disabled`
  otherwise; `reasoning_effort` only when effort AND `supportsReasoningEffort`,
  value = map[level] else the level string); `deepseek` :928-937 (thinking
  `{type:"enabled"}` when effort, `{type:"disabled"}` when no effort unless
  map.off === null; effort same map-else-level rule); the generic OpenAI
  arm :949-957 (effort present AND `supportsReasoningEffort` ⇒ map-else-
  level; NO effort AND model.reasoning AND supportsReasoningEffort ⇒ the
  map's `off` string if it is one).
- Thinking budget arm :961-963 + `resolveThinkingTokenBudgetField` :1005-
  1010 (`thinkingTokenBudgetField` else `supportsThinkingTokenBudget` ⇒
  `"thinking_token_budget"`) + `resolveClampedThinkingBudget` :1012-1023
  (`clampThinkingBudgetToAnswerRoom`, MIN_ANSWER_TOKENS=1024, simple-
  options.ts :84-101; DEFAULT_THINKING_BUDGETS minimal 1024 / low 2048 /
  medium 8192 / high 16384, simple-options.ts :67-73).
- `convertMessages` :1193-1465 — message conversion/replay: instruction
  role `developer` iff model.reasoning AND `supportsDeveloperRole` else
  `system` (:1233); user string passes verbatim; assistant replay
  :1300-1402 (text parts joined to a plain STRING; `requiresThinkingAsText`
  arm; same-block signature replay :1339-1348 — the first thinking
  block's signature, when it names one of `OPENAI_COMPLETIONS_REASONING_
  FIELDS` :273 (`reasoning`, `reasoning_content`, `reasoning_text`),
  sends the thinking text under that field; `preservedReasoningDetails`
  replay :1382-1386 — signature parses as a JSON array of valid
  reasoning_details ⇒ send `reasoning_details` and NOT the raw field;
  deepseek `reasoning_content:""` on every assistant message when
  `requiresReasoningContentOnAssistantMessages` :1387-1393; empty
  assistant messages (no content, no tool_calls) SKIPPED :1394-1402);
  tool-result replay :1404-1454 (text blocks joined "\n", placeholder
  "(no tool output)"/"(see attached image)", `tool_call_id`, optional
  `name`); tool_calls array shape {id, type:"function", function:{name,
  arguments: JSON.stringify}} :1365-1379.
- `convertTools` :1482-1508 — {type:"function", function:{name,
  description, parameters}}; `strict` key only when `supportsStrictMode
  !== false` (default detected false ⇒ absent).
- `parseChunkUsage` :1519-1547 — cacheRead = `prompt_tokens_details.
  cached_tokens` ?? `prompt_cache_hit_tokens` ?? `cached_tokens` ?? 0;
  cacheWrite = `prompt_tokens_details.cache_write_tokens` || 0; input =
  max(0, prompt − cacheRead − cacheWrite); output = completion_tokens
  (already includes reasoning); `reasoning` from `completion_tokens_
  details.reasoning_tokens`; totalTokens = input+output+cacheRead+
  cacheWrite.
- `mapStopReason` :1562-1589 — stop/end⇒stop, length⇒length,
  function_call/tool_calls⇒toolUse, content_filter/network_error/
  unknown⇒error with `Provider finish_reason: <r>` message.
- `detectCompat` :1593-1694 / `getCompat` :1696-1734 — the auto-detect
  defaults + explicit-compat override merge. Relevant detected facts: zai
  and deepseek are "non-standard" (no `store`, no developer role,
  `max_tokens`); zai detection suppresses `supportsReasoningEffort` (the
  LIVE zai behavior uses the catalog compat which re-enables it — the
  I46 five-key subset); deepseek adds `requiresReasoningContentOn
  AssistantMessages`; fireworks detects NOTHING (the plain arm).

`providers/compat-schema.ts` (629 l) — the dialect declaration
vocabulary: thinkingFormat union (openai/openrouter/deepseek/together/
baseten/zai/qwen/qwen-chat-template/chat-template/string-thinking/
ant-ling, :217-246), thinking budget field variants (:17-25:
thinking_token_budget= vLLM, thinking_budget= Qwen/DashScope/SGLang,
thinking_budget_tokens= llama.cpp), zaiToolStream (:266-272), session
affinity (:4-9 openai|openai-nosession|openrouter + headers at
openai-completions.ts :776-789), maxTokensField, supportsDeveloperRole,
supportsReasoningEffort, supportsUsageInStreaming, supportsFinishReason,
requiresReasoningContentOnAssistantMessages, supportsStore.

`utils/transform-messages.ts` (202 l) — REPLAY NORMALIZATION (the
cross-model rules): assistant identity = (provider, api, model) :97-99;
same-model keeps thinking blocks WITH signatures; cross-model folds
non-empty thinking into TEXT blocks and strips tool-call
thoughtSignatures :103-130; orphaned tool calls get synthetic
`{role:"toolResult", content:[{type:"text",text:"No result provided"}],
isError:true}` :158-180 (system messages held back between call and
results).

`types.ts` (893 l) — Message roles (:536+ SystemMessage w/ toolsAdded,
user, assistant content blocks, toolResult), ToolCall/ThinkingContent/
TextContent blocks, Usage (:136+ ThinkingBudgets; AssistantMessage usage
shape per parseChunkUsage), the event protocol :794-816 (`start`,
`text_start/text_delta/text_end`, `thinking_start/delta/end`,
`toolcall_start/delta/end`, `done{reason,message}`, `error{reason,error}`
— updates never precede `start`).

`utils/error-body.ts` + `utils/overflow.ts` — provider error formatting
and the 25-pattern context-overflow regex list (Anthropic/OpenAI/
LiteLLM/z.ai/DS4/… :33-96) — the ContextLengthExceededError detection
source.

`utils/sanitize-unicode.ts` — lone-surrogate stripping applied to every
text field before wire serialization (openai-completions.ts import :56;
JS strings carry lone surrogates that break provider JSON parsers; Ruby
UTF-8 strings cannot contain them — see Grounds §6 OQ-7).

`api/simple-options.ts` — `clampMaxTokensToContext` :13-19 (context −
estimate − 4096 safety floor), DEFAULT_THINKING_BUDGETS :67-73,
`thinkingBudgetForLevel` :81-85, `clampThinkingBudgetToAnswerRoom` :88-91.
`models.ts` `clampThinkingLevel` :133-155 + `getSupportedThinkingLevels`
:118-131 (EXTENDED ladder off/low/medium/high/xhigh/max; xhigh/max
supported only when the map names them; non-null mapped levels are
supported; clamp walks down then up).

## 3. THE CAPTURE INSTRUMENT (P0 probe, this session — the parity anchor)

The byte-parity bar is REAL pi bytes, not hand-derived ones. Proven this
session, hermetically, twice (deterministic ×2):

- Driver `tmp/i51-spec/capture/pi_wire_capture.mjs`: imports `streamSimple`
  from the INSTALLED pi-ai 1.1.0 dist (the compiled wire code the rig's
  pi binary runs), drives it against a hermetic node TCP mock (one OpenAI
  SSE reply per request; raw request body captured verbatim), over a
  fixed 11-scenario table with byte-stable inputs (fixed system text,
  one fixed `read` tool schema, fixed user texts, fixed ids/signatures,
  timestamp 0 — timestamps never serialize to the wire).
- Fixtures written to `tmp/i51-spec/capture/out/<tag>.json`
  (`{tag, request_path, request_body}`), digests in `manifest.json`.
- Determinism: two full runs produced IDENTICAL manifests
  (`out/` vs `out2/`, diff clean).
- Scenario table (frozen; the Specification §11 maps each to the gem-side
  construction):
  1. `fireworks_plain` — non-reasoning, tools, no dialect (the plain
     arm): `store:false`, `max_completion_tokens:512`, system role.
  2. `openai_ladder_on` — reasoning model, map {off:"none",low,medium,
     high}, effort high ⇒ `reasoning_effort:"high"`.
  3. `openai_ladder_off` — same model, effort off ⇒ `reasoning_effort:
     "none"` (the map's off string — NOT the I36 String-off floor).
  4. `zai_on` — the I46 five-key zai compat (+ `supportsStore:false`,
     pi's zai store rule) ⇒ `max_tokens`, `tool_stream:true`,
     `thinking:{type:"enabled",clear_thinking:false}`,
     `reasoning_effort:"high"`, NO store.
  5. `zai_off` — effort off ⇒ `thinking:{type:"disabled"}`, NO
     reasoning_effort, tool_stream still present.
  6. `deepseek_on` — deepseek compat ⇒ `thinking:{type:"enabled"}`,
     `reasoning_effort:"high"`, max_tokens, NO store.
  7. `tool_roundtrip` — replayed assistant tool_calls + tool result ⇒
     assistant `{content:null, tool_calls:[…]}`, tool-role message with
     `tool_call_id`.
  8. `thinking_replay` — same-model assistant with thinking block,
     signature `"reasoning_content"` ⇒ assistant carries
     `reasoning_content:"let me think"`, content the text only.
  9. `reasoning_details_replay` — signature parses as a JSON
     reasoning_details array ⇒ assistant carries `reasoning_details:[…]`
     and NO raw reasoning field.
  10. `cross_model_thinking_replay` — assistant identity from another
      provider ⇒ thinking folded to text, concatenated
      (`content:"let me thinkHi!"` — pi's literal behavior), no
      reasoning fields.
  11. `budget_field` — `thinkingTokenBudgetField:"thinking_token_budget"`,
      model maxTokens 4096, effort high ⇒ `thinking_token_budget:3072`
      (= min(16384, 4096−1024)) appended after the effort arm.
- FROZEN DIGESTS (SHA256 of the raw request body; the AC pins these —
  the gem's emitted bodies must hash identically):
  - fireworks_plain `0b9da927d3cab0b8b41ecb634fde099729e03f817ef6ba3aba26720df2130d93`
  - openai_ladder_on `b05b45aeb3a4f7bdfa12d142e839882855688a246ead4d016fbe474188dfaed2`
  - openai_ladder_off `60914406494e2e8403de6b932f01cd5d901c9ae4c4de75e283b25656fa6304b1`
  - zai_on `9a23aee6b115cce0bd6a608465f2c56332123e47a0f22c491793c0a4d0e45c13`
  - zai_off `88dd5af69ceb68bbc41aad9ddfbc4dcb36e0dd66fec3563054d484cc0f727f7c`
  - deepseek_on `ce98edaee2ecb634dcd4461e3e56cfc4f973cd37026fc390b63ac2bdfbfec5f5`
  - tool_roundtrip `940d8f5b262f59a3db7b27a70471ac96a40c170264edc83219bef83dce1e9038`
  - thinking_replay `c9259d5da9ca8c63186522c24b9bdfd1fe81aa0903187b0f50634b56eb3c7e6c`
  - reasoning_details_replay `c21da08d520e246652b33bedf76d89db581692a7775de5181dc8c63013a0ae4e`
  - cross_model_thinking_replay `809a9b7ecc99399379031524ed5810677e31c22cac2f64eb6e728602ea5939fc`
  - budget_field `fb29e70650e9708f394c319d3c8ecacb840c134d214f9ce2747151356b86d1b7`
- Fixture-body facts worth naming (all visible in the captures): wire key
  order is pi's insertion order (§2 buildParams); the assistant
  tool_calls arguments string is `{"path":"src.rb"}` (compact JSON,
  key order = the arguments Hash's); zai/deepseek carry NO `store` key
  while the plain arm carries `store:false`.

## 4. House conventions (fast-protowire 0.3.0 / fast-prometheus, verified)

- gemspec shape: `spec.authors = ["Eric Jacobs"]`, MIT,
  `homepage github.com/jetpks/<gem>`, `required_ruby_version >= 3.3`,
  `files = Dir.glob(["{lib}/**/*", "*.md"], …)`, metadata uris +
  `rubygems_mfa_required`; deps declared with pessimistic constraints
  (fast-prometheus: `add_dependency "async-http", "~> 0.95"`).
- README discipline: what it is / what it is NOT (fast-protowire: "It is
  not a replacement for google-protobuf…"), installation, quickstart
  runnable with `bundle exec ruby`, docs index, benchmarks page when
  performance is a claim.
- Flat `fast/<api>` require paths; `require "fast/completions"` loads
  the whole gem (its surface is one API).
- CHANGELOG.md with a section per version, prose entries.
- House test framework is sus (`config/sus.rb`) — the ENTRY overrides
  with RSpec ("gem RSpec suite green"); recorded as OQ-10. House uses
  `gems.rb`; the ENTRY names a root `Gemfile` — the entry governs
  (OQ-10 same item).
- fiber-native on the socketry stack is the house norm (fast-prometheus
  OTLP export runs on async-http) — the client pattern to follow.

## 5. tart cross-references (read-only)

- `test/support/mock_llm_server.rb` (287 l) — the protocol-agnostic
  parity-harness source: TCP OpenAI endpoint, script specs
  ({type: :stream, content:, reasoning_content:, tool_calls:, chunks:},
  :message, :slow_stream with 0.1s pauses, :error with status), full
  wire-entry capture ({method, path, streaming, headers, body}),
  `rearm!` for byte-identical re-service, `suppress_usage!`,
  empty-TCP-connect-consumes-nothing, EPIPE discipline. The gem gets
  its OWN copy (Specification §12) — no tart dependency, read-only copy
  access sanctioned by the plan.
- The I46 zai arm (`lib/tart/agent/loop.rb` `apply_zai_dialect`, the
  current tart implementation) — the live-verified zai behavior this
  gem's :zai declaration reproduces natively (the five-key subset + the
  store rule).
- The wire-digest gate discipline (I48 `wire-bodies`: SHA256 over
  captured request bodies vs frozen digests) — this entry's AC2 follows
  it against the §3 fixtures.
- The ENTRY 1 cancel discipline (de-bridge, in flight in the sibling):
  cancel mid-stream aborts the in-flight request and emits NO phantom
  terminal — this entry ports the same discipline gem-natively (AC3).

## 6. Design decisions (letter-grounded; OQs itemized for the judge)

- D1 The gem speaks EXACTLY ONE wire: OpenAI-compatible chat-completions
  (`POST {base}/chat/completions`, SSE streaming). No anthropic, no
  responses, no embeddings (scout D's headline: tart targets one
  protocol; ruby_llm's ~30 protocols are 95% dead weight).
- D2 Dialects are DATA (declarations) consumed by THREE codec arms:
  plain/openai (the default), zai, deepseek. The declaration vocabulary
  is pi's openai-completions compat vocabulary restricted to what the
  implemented arms + client read (Specification §4). Unknown
  thinking_format values are rejected AT DECLARATION TIME (fail loud,
  never silently mistranslate — the anti-universal-translation rule).
- D3 No auto-detection from base URLs. pi auto-detects because pi owns
  provider metadata; this gem's consumer owns models, so compat is
  explicit data (the well-known trio ships as declarations whose values
  ARE pi's real behavior for those providers — zai/deepseek store-
  suppression included; OQ-6).
- D4 The wire codec emits pi's EXACT key insertion order (§3 fixture
  facts). Ruby Hash insertion order + JSON.generate gives byte-parity;
  floats never appear on this wire in the pinned scenarios (temperature
  unset in all 11).
- D5 Timeout = time-to-first-byte deadline + same-value inactivity
  read-timeout during the stream (ruby_llm/net_http read-timeout
  semantics — what tart's tests already assume; a whole-request deadline
  would kill every long stream). OQ-1.
- D6 No built-in retries (tart runs max_retries 0 everywhere; pi's
  retryProviderRequest is a harness concern). OQ-2.
- D7 Images over the wire are CUT (tart sends none — scout D verified
  tools/read returns a note; BRIEF §3 scope). The message conversion
  handles text/thinking/toolCall/toolResult only. Itemized, reopen on
  consumer need.
- D8 Cancel: `Async::Cancel` at the in-flight wait closes the request
  body; the stream surfaces `Fast::Completions::CancelledError` (NOT an
  `Error` subclass — rescue ladders stay clean); no `:error`/`:done`
  event after a cancel (the no-phantom-terminal pin).
- D9 The Chat executes tool calls SERIALLY on the calling fiber after a
  toolUse turn (ruby_llm's tool_concurrency machinery is NOT ported —
  tart owns its own concurrency post-de-bridge; the gem's loop is one
  batch per step).
- D10 Version 0.1.0; CHANGELOG carries the 0.1.0 entry; release tags are
  the human's (never in-loop).

Open questions (judge adjudicates; none blocking):
- OQ-1 Timeout semantics (D5) — TTFB deadline + inactivity read-timeout.
- OQ-2 Retries cut (D6).
- OQ-3 Dialect vocabulary subset (§4 table); unported pi compat fields
  itemized in Specification §14 (routing, cache-control, grammar/strict
  tools, mid-convo system/tool additions, requires_tool_result_name,
  requires_assistant_after_tool_result, requires_thinking_as_text,
  prompt-cache fields) — reopen on consumer need.
- OQ-4 pi's `parseStreamingJson` mid-stream partial parse (npm
  partial-json) is simplified: the gem accumulates raw argument strings
  (delta events carry the RAW string delta exactly like pi), parses at
  finalize with control-character repair (pi utils/json-parse.ts
  repairJson semantics), `rescue {}` as the last resort.
- OQ-5 Budget arm INCLUDED (pi-cited, fixture-pinned) though no well-
  known trio dialect uses it.
- OQ-6 No base-URL auto-detection (D3).
- OQ-7 sanitizeSurrogates: Ruby UTF-8 strings cannot hold lone
  surrogates, so the pi sanitization step is a NO-OP by construction —
  documented in the codec with the pi cite, not implemented as dead code.
- OQ-8 Orphaned tool-call synthetic results (transform-messages.ts
  :158-180) ARE ported (replay normalization completeness).
- OQ-9 The gem's Usage carries `total_tokens` natively (pi semantics;
  ruby_llm's Tokens lacked total — tart's compaction re-summed).
- OQ-10 RSpec + root Gemfile per the ENTRY (house sus/gems.rb deviation
  recorded).
- OQ-11 No benchmark page this entry (the program close-out names the
  benchmark page draft AFTER ENTRY 3).
- OQ-12 No .github workflows this entry (GitHub is the human's at
  landing).

## 7. Environmental carry-ins (standing)

- Builders never commit, never push, no GitHub/rubygems in-loop; the
  loop stops at releasable.
- Scratch under tmp/ and build/ only (this session's capture lives at
  tmp/i51-spec/capture/ — local, uncommitted; the AC pins the digests so
  the bytes are judgeable without the scratch).
- Child-timeout discipline (coordinator): every spawn carries
  timeoutMs + toolTimeoutMs ≥ 3600000.
- The s-gates/wire digests of TART are NOT this entry's gates (no tart
  change); this entry's wire bar is the §3 fixture set.

## Specification

# Specification — I51 fast-completions-gem

## 0. Objective

Scaffold the `fast-llm` monorepo (repos/fast-llm, git-init'd at `b6ffad1`
with a placeholder README) and build the gem `fast-completions`
(`Fast::Completions`, `require "fast/completions"`): a standalone,
releasable, fiber-native OpenAI-compatible chat-completions client whose
wire bytes are pi's bytes (Grounds §3's fixture set is the bar) — the gem
ENTRY 3 swaps into tart. ONE wire protocol, dialects as data, async-http
as the only dependency. This entry NEVER touches repos/tart and never
performs GitHub/rubygems actions.

Output format: the file tree below, exactly; an RSpec suite; the wire
fixtures + parity spec; the install-check script. All verification runs
from the repo root of repos/fast-llm.

## 1. Monorepo scaffold (lane `core`)

```
fast-llm/
  .gitignore                 # pkg/, tmp/, Gemfile.lock? — see below
  Gemfile                    # root, dev deps only
  README.md                  # the monorepo read-me (§13)
  gems/completions/
    fast-completions.gemspec # §2
    README.md                # the gem read-me (§13)
    CHANGELOG.md             # §2
    lib/fast/completions.rb  # umbrella require + the dialect DSL entry
    lib/fast/completions/version.rb
    lib/fast/completions/types.rb        # §5
    lib/fast/completions/dialects.rb     # §4
    lib/fast/completions/errors.rb       # §8
    lib/fast/completions/sse.rb          # §7
    lib/fast/completions/client.rb       # §6
    lib/fast/completions/protocol.rb     # §9 (request build) + §10 (delta parse)
    lib/fast/completions/codec.rb        # §9.4 (replay normalization) — may fold into protocol.rb; the spec freezes the SURFACE not the split
    lib/fast/completions/tool.rb         # §11
    lib/fast/completions/cancellation.rb # §11
    lib/fast/completions/chat.rb         # §12
    spec/spec_helper.rb
    spec/support/mock_llm_server.rb      # §12.1 (the gem's OWN copy)
    spec/fast/completions/{sse,protocol,codec,dialects,errors,client,chat,tool,cancellation}_spec.rb
    spec/fixtures/wire/*.json            # §12.2 (lane `harness`)
    spec/fast/completions/wire_parity_spec.rb  # lane `harness`
    script/install_check.sh               # lane `harness`
```

The internal file split above is the DEFAULT; a lane may merge
`codec.rb` into `protocol.rb` (or split `protocol.rb` into
`request.rb`/`stream.rb`) as long as (a) the public surface of §3–§12 is
exactly as frozen, (b) the file-touch list stays within the lane's
declared set (amendations via the coordinator, never silently), and (c)
`require "fast/completions"` loads everything.

Root Gemfile (dev deps only — NOTHING becomes a runtime dep):

```ruby
# frozen_string_literal: true
source "https://rubygems.org"

gemspec path: "gems/completions"

group :development, :test do
  gem "rspec"
  gem "rake"
end
```

`.gitignore`: `pkg/`, `tmp/`, `coverage/`, `*.gem`, `.bundle/`. Root
`Gemfile.lock` IS committed (house commits its lockfile as `gems.locked`)
— it is a may-touch artifact of lane `core` (regenerated by bundle
install; must NOT contain faraday or rspec outside the dev group).

## 2. Gem metadata (lane `core`)

- `lib/fast/completions/version.rb`: `Fast::Completions::VERSION =
  "0.1.0"`.
- `fast-completions.gemspec` — house shape (fast-protowire/fast-
  prometheus, Grounds §4): `spec.name = "fast-completions"`,
  `spec.version = Fast::Completions::VERSION`, summary one line ("A
  fiber-native client for the OpenAI-compatible chat-completions wire,
  byte-faithful to pi."), `spec.authors = ["Eric Jacobs"]`, MIT,
  `spec.homepage = "https://github.com/jetpks/fast-completions"`,
  `spec.required_ruby_version = ">= 3.3"`,
  `spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH,
  base: __dir__)`, the metadata uri block + `rubygems_mfa_required`, and
  EXACTLY ONE runtime dependency:
  `spec.add_dependency "async-http", "~> 0.95"`.
  No other `add_dependency` line may exist (AC4).
- `CHANGELOG.md`: a `## 0.1.0` section describing the port (codec arms
  plain/zai/deepseek, dialects as data, async-http client, Chat/Tool,
  parity harness) in house changelog prose.

## 3. Public API surface (frozen names; both lanes build against THIS)

```ruby
require "fast/completions"

model = Fast::Completions::Model.new(
  id: "mock-1",              # required, String
  reasoning: true,           # required, boolean
  context_window: 128_000,   # required, Integer
  max_tokens: 512,           # required, Integer
  thinking_level_map: {off: "none", low: "low", medium: "medium", high: "high"}, # optional
  dialect: :zai,             # optional: Symbol name or Fast::Completions::Dialect
)
model.supported_thinking_levels   # pi getSupportedThinkingLevels (§9.3)
model.clamp_thinking_level(:xhigh) # pi clampThinkingLevel (§9.3)

client = Fast::Completions::Client.new(base_url:, api_key:, timeout: 30)
client.stream(model:, messages:, instructions: nil, tools: [], thinking: nil,
              max_tokens: nil) { |event| }   # → Fast::Completions::Message (final assistant)
client.close

Fast::Completions.dialect(:acme) { … }  # declare (§4); returns the Dialect
Fast::Completions.dialect(:zai)         # no block → lookup (raises KeyError if undeclared)
Fast::Completions.dialects              # Hash name→Dialect (frozen dup)

chat = Fast::Completions::Chat.new(client:, model:)
chat.with_instructions("…")       # chainable; may be called once (later call replaces)
chat.with_tools(MyTool, OtherTool) # chainable; Tool classes or instances; additive
chat.add_message(msg)              # Message (user/assistant replay/tool replay); chainable
chat.messages                      # dup'd Array of Message
chat.thinking_level = :high        # or chat.with_thinking_level(:high) chainable; nil = off-equivalent (no effort)
chat.with_max_output_tokens(1024)  # chainable; nil = model default
chat.step { |event| … }            # one assistant turn + tool execution (§12); returns final Message
chat.complete?                     # true when the last turn ended with no pending tool batch
chat.cancel                        # cancel the in-flight stream (D8)

Fast::Completions::Message.user("hello")
Fast::Completions::Message.user([{type: :text, text: "hello"}])
Fast::Completions::Message.system("You are …")
Fast::Completions::Message.assistant(blocks, provider: "mock", model: "mock-1")
Fast::Completions::Message.tool_result(tool_call_id:, content:, tool_name: nil)
# blocks: {type: :text, text:}, {type: :thinking, thinking:, signature:},
#         {type: :tool_call, id:, name:, arguments: Hash}
msg.role        # :system | :user | :assistant | :tool_result
msg.content     # String (user/system) or Array of block Hashes (assistant)
msg.provider / msg.model / msg.api   # assistant identity (replay normalization, §9.4)

class MyTool < Fast::Completions::Tool
  description "Read file contents."
  parameters {"type" => "object", "required" => ["path"], "properties" => {"path" => {"type" => "string"}}}
  def execute(path:) "contents" end   # String, Hash, or {error: "…"}
end
MyTool.new.name        # "MyTool" → underscored? NO: name = the class's declared
                       # `tool_name "my_tool"` if set, else the class name (§11)

Fast::Completions::Cancellation.check   # raises CancelledError if the current async task is cancelled
Fast::Completions::CancelledError       # NOT < Error (D8)
```

`Event` objects yielded to `#step`/`#stream` blocks (pi types.ts :794-816
vocabulary, Ruby symbols): `Event` with `.type` one of `:start,
:text_start, :text_delta, :text_end, :thinking_start, :thinking_delta,
:thinking_end, :tool_call_start, :tool_call_delta, :tool_call_end,
:done, :error` and fields `content_index` (Integer, present on block
events), `delta`/`content` (String, per type), `tool_call` (the finalized
ToolCall hash `{id:, name:, arguments:}` at `:tool_call_end`),
`message`/`reason` (at `:done`/`:error`), plus `partial` — the live
assistant Message so far (never frozen copies; `partial` is the shared
accumulator, exactly pi's contract). `:done` carries `reason:` one of
`:stop, :length, :tool_use`; `:error` carries `reason:` `:error` (the
stream ALSO raises the mapped error — §8 — the event is the terminal
record).

## 4. Dialects as data (`dialects.rb`)

DSL (declaration order irrelevant; keys frozen):

```ruby
Fast::Completions.dialect(:zai) do
  thinking_format :zai                # :openai (default) | :zai | :deepseek — ANY OTHER VALUE RAISES ArgumentError at declaration
  max_tokens_field "max_tokens"       # "max_completion_tokens" (default) | "max_tokens" — else ArgumentError
  supports_developer_role false       # default true
  supports_reasoning_effort true      # default true
  supports_store true                 # default true (emits store:false)
  supports_usage_in_streaming true    # default true (emits stream_options)
  supports_finish_reason true         # default true (false ⇒ §10 inference)
  requires_reasoning_content_on_assistant_messages false # default false
  zai_tool_stream false               # default false
  thinking_token_budget_field nil     # "thinking_token_budget" | "thinking_budget" | "thinking_budget_tokens" | nil (default nil)
  supports_thinking_token_budget false # default false; true ⇒ field "thinking_token_budget"
  send_session_affinity_headers false # default false
  session_affinity_format :openai     # :openai | :openai_nosession | :openrouter (default :openai)
end
```

- `Fast::Completions::Dialect` — value object, reader per key, `==` by
  keys, `to_h` (declaration-order-stable). The frozen DEFAULT dialect
  (used when `Model` has no `dialect:`) is the plain arm: every default
  above with `thinking_format :openai`.
- Well-known trio, SHIPPED as declarations inside `lib/fast/completions/
  dialects.rb` (registered at require time; a consumer re-declaring
  `:zai` OVERRIDES — last declaration wins, documented):
  - `:zai` — `thinking_format :zai, zai_tool_stream: true,
    max_tokens_field: "max_tokens", supports_developer_role: false,
    supports_reasoning_effort: true, supports_store: false` (the I46
    five-key subset + pi's zai store suppression, Grounds §2).
  - `:deepseek` — `thinking_format :deepseek, max_tokens_field:
    "max_tokens", supports_developer_role: false,
    supports_reasoning_effort: true, requires_reasoning_content_on_
    assistant_messages: true, supports_store: false` (pi's deepseek
    detection, Grounds §2).
  - `:fireworks` — the empty declaration (every default; names the
    live-verified trio's third member — fireworks needs nothing).
- Unknown keys inside the block RAISE ArgumentError (fail loud at
  declaration, never silently dropped — the no-universal-translation
  discipline). The vocabulary is CLOSED to exactly the 14 keys above.
- No model catalog, no pricing, no provider registry, no base-URL
  constants anywhere in lib/ (AC4 negative pins).

## 5. Types (`types.rb`)

- `Model` (§3 construction + readers; keyword-init value object; unknown
  keys ArgumentError).
- `Message` — keyword-init; roles above; assistant blocks are plain
  Hashes with symbol keys (the §3 shapes); `Message#to_h` /
  `Message.from_h` round-trip (the gem's own serialization — session
  recording is the consumer's, but the codec must be able to freeze and
  restore history; used by specs).
- `Usage` — value object: `input, output, cache_read, cache_write,
  reasoning, total_tokens` (pi parseChunkUsage semantics, Grounds §2;
  `total_tokens` native — OQ-9).
- `Event` — §3.
- All frozen value objects; defensive dups on construction.

## 6. Client (`client.rb`) — async-http, fiber-native

- ONE `Async::HTTP::Client` per `Client` instance (persistent
  connections, keep-alive), built from the parsed base URL
  (`Async::HTTP::Endpoint`). `#close` closes it. Requests run INSIDE the
  caller's reactor (`Async` — the caller wraps in `Async do … end` or
  runs under a scheduler; the client never creates its own reactor).
- `#stream(model:, messages:, instructions:, tools:, thinking:,
  max_tokens:)` — POST `{base}/chat/completions` (path join: base URL
  ending in `/v1` + `/chat/completions`; no other path surgery — the
  consumer's base URL is the API root prefix exactly like pi's
  `model.baseUrl`).
- Headers: `authorization: Bearer <key>`, `content-type: application/
  json`, `accept: application/json` (pi's SDK shape; SSE is body-
  negotiated). When `dialect.send_session_affinity_headers` and the chat
  supplies a session id (§12): `:openrouter` ⇒ `x-session-id`;
  `:openai` ⇒ `session_id` + `x-client-request-id` + `x-session-
  affinity`; `:openai_nosession` ⇒ the latter two (openai-completions.ts
  :776-789, compat-schema.ts :4-9).
- Body: `JSON.generate(request_hash)` — the §9 byte contract.
- Streaming: iterate the response body (`response.body.each`) through
  the §7 SSE parser; feed events to the block; the FULL terminal
  behavior of §10 applies (the parser drives protocol state).
- Timeout (D5/OQ-1): `timeout:` (seconds, default 30) is BOTH the
  time-to-first-byte deadline (connect + request + response headers) and
  the inactivity read-timeout between body chunks. On expiry:
  `Fast::Completions::TimeoutError` (§8); the request is aborted.
- Cancel (D8): `Async::Cancel` raised into the waiting fiber (or
  `#close` of the body from a sibling) aborts the in-flight request —
  the connection is discarded (never reused), `CancelledError` surfaces
  to the caller, and NO terminal event is emitted (AC3).
- Non-2xx: read the body, parse JSON when possible, map per §8. Network
  failures (ECONNREFUSED/ECONNRESET/…) ⇒ `ConnectionError`.
- 2xx with SSE error payloads inside the stream ⇒ §10 terminal error
  discipline.

## 7. SSE line parser (`sse.rb`)

- Input: arbitrary byte chunk boundaries. Output: per `data:` payload
  string, in order. Rules: events separated by blank line (`\n\n`);
  `data: ` prefix (one space) stripped; lines starting `:` are comments
  (ignored — the mock's keepalives); CR stripped (`\r\n` normalized);
  `data: [DONE]` is the terminal marker (yields a distinguished `:done`
  token, NOT a payload); multi-`data:`-line events are concatenated with
  `\n` (SSE spec). UTF-8 throughout. Unit-pinned against the mock's
  exact framing (chunked transfers arrive as arbitrary splits — pin a
  split-across-chunks case).

## 8. Errors (`errors.rb`)

Class tree (frozen):

```
Fast::Complet::Error (StandardError)            # Fast::Completions::Error
├─ ApiError(status:, body:)                      # message: "<status> <provider message>"
│  ├─ BadRequestError (400)
│  │  └─ ContextLengthExceededError              # detected via the pattern list
│  ├─ AuthenticationError (401)
│  ├─ PermissionError (403)
│  ├─ NotFoundError (404)
│  ├─ RateLimitError (429)
│  └─ ServerError (5xx)
├─ TimeoutError
└─ ConnectionError
Fast::Completions::CancelledError (StandardError, NOT < Error)
```

- 400-classification: `ContextLengthExceededError` when the response
  body (message, or any string in the parsed error JSON) matches ANY of
  pi's overflow patterns (utils/overflow.ts :33-96 — port the FULL list
  of 25 regexes verbatim, case-insensitive, as data); otherwise
  `BadRequestError`.
- ApiError#message = `"<status>: <message>"` where message is the
  provider's `error.message` when parseable, else the raw body
  (truncated to ~500 chars).
- `:error` stop reason from a finish_reason (§10) raises
  `Fast::Completions::Error` subclasses? NO — stream-terminal errors
  (finish_reason error classes, stream-ended-without-finish) raise
  `Fast::Completions::StreamError < Error` carrying `stop_reason:` and
  pi's message form (`Provider finish_reason: <r>` / `Stream ended
  without finish_reason`) — the `:error` event is still emitted first.

## 9. Request build — THE BYTE CONTRACT (`protocol.rb`)

Ruby Hash insertion order + `JSON.generate` MUST reproduce pi's wire
bytes for the Grounds §3 fixtures. Emission rules (pi buildParams
:802-1000, line-cited in comments):

1. `model` = model.id.
2. `messages` = §9.1–9.4 conversion of [instructions (when present)] +
   history.
3. `stream` = true (the client always streams).
4. `stream_options: {include_usage: true}` iff
   `dialect.supports_usage_in_streaming`.
5. `store: false` iff `dialect.supports_store`.
6. max tokens: `max_tokens` iff `dialect.max_tokens_field ==
   "max_tokens"` else `max_completion_tokens`; value = the effective cap
   (§9.5); the key is OMITTED when the effective cap is nil.
7. `temperature` only when explicitly set (Chat does not set it; the
   parameter exists on `Client#stream` — omit from the frozen scenarios;
   any float formatting risk is the consumer's).
8. `tools` (iff any tools): the §9.2 conversion; then `tool_stream:
   true` iff `dialect.zai_tool_stream` AND tools present. When NO tools
   but the history contains tool calls or tool results: `tools: []`
   (openai-completions.ts :860-863).
9. thinking arms, in this precedence (model.reasoning gates EVERY arm —
   a non-reasoning model emits NONE of these):
   - `:zai` — `thinking:` `{"type"=>"enabled","clear_thinking"=>false}`
     when an effort is present else `{"type"=>"disabled"}`;
     `reasoning_effort` (string) iff effort present AND
     supports_reasoning_effort — value = map[clamped] when it is a
     String else the clamped level to_s.
   - `:deepseek` — `thinking:` `{"type"=>"enabled"}` when effort
     present; when NO effort, `{"type"=>"disabled"}` UNLESS
     map[:off] == nil-for-null (pi: `model.thinkingLevelMap?.off !==
     null` — a map WITHOUT an :off key also emits disabled; an explicit
     `off: nil` (JSON null) suppresses the disabled object);
     `reasoning_effort` iff effort AND supports_reasoning_effort
     (map-else-level).
   - `:openai` (default) — `reasoning_effort` iff effort present AND
     supports_reasoning_effort (map-else-level); when NO effort AND
     model.reasoning AND supports_reasoning_effort: `reasoning_effort`
     = map[:off] WHEN map[:off] is a String (else omitted — the
     off-floor rule, Grounds fixture 3).
10. thinking budget (independent of format): field =
    `dialect.thinking_token_budget_field ||
    (dialect.supports_thinking_token_budget ? "thinking_token_budget" :
    nil)`; when field AND effort AND model.reasoning: budget =
    DEFAULT_THINKING_BUDGETS[clamped] (minimal 1024 / low 2048 / medium
    8192 / high 16384; xhigh/max clamp to high per pi
    `clampReasoning`), clamped to `min(budget, effective_max_tokens -
    1024)`; emit `field => budget` ONLY when budget > 0, AFTER the
    thinking arms.
11. NO other top-level keys. (`tool_choice`, sampling params, priority,
    prompt_cache_* are NOT implemented — Specification §14.)

### 9.1 Messages

- Instructions: ONE leading `{role:, content: String}` — role
  `"developer"` iff model.reasoning AND dialect.supports_developer_role
  else `"system"` (openai-completions.ts :1233).
- User: `{role: "user", content: <String or the block array verbatim>}`
  — String content passes as the JSON string (fixture fact); a block
  array passes as the array (text parts only — images cut, D7; a
  user message whose text blocks are all empty is SKIPPED).
- Tool result: `{role: "tool", content: <joined>, tool_call_id:}` —
  content = text blocks joined `"\n"`; when empty: `"(no tool output)"`
  (image-only placeholder CUT with D7); `name` key NOT emitted
  (requires_tool_result_name unported, §14).

### 9.2 Tools

`{"type" => "function", "function" => {"name" =>, "description" =>,
"parameters" =>}}` in declaration order. The parameters Hash is emitted
VERBATIM (insertion order preserved — the consumer's schema is the
bytes). NO `strict` key (pi's detected default suppresses it, Grounds
§2; strict-mode support unported, §14).

### 9.3 The thinking ladder

- Supported levels: `[:off]` when `!model.reasoning`; else the ladder
  `off, low, medium, high, xhigh, max` filtered — a level is supported
  when the map omits it or maps it to non-nil; `xhigh`/`max` are
  supported ONLY when the map names them (pi getSupportedThinkingLevels
  :118-131).
- Clamp (pi clampThinkingLevel :133-155): unsupported requested level →
  the next supported level ABOVE, else the nearest BELOW, else the first
  supported.
- "Effort present" = the Chat's thinking_level clamped ≠ `:off` (and
  thinking_level nil ⇒ no effort).

### 9.4 Assistant replay normalization (`codec.rb`; pi
transform-messages.ts + convertMessages, Grounds §2)

- Same-model = `(msg.provider, "openai-completions", msg.model) ==
  (model's provider-context)` — the gem compares `msg.provider`/`msg.
  model` against the CURRENT model's `id` + the `provider:` the consumer
  set on the replayed message (the gem has no provider registry: the
  Chat stamps its OWN assistant outputs with `provider:
  chat.model_context_provider` (default `"fast-completions"`) and
  `model: model.id`; replayed messages carry whatever the consumer
  built — same-model is a three-way equality the CONSUMER controls).
- Thinking blocks: same-model AND signature present ⇒ kept for §9.5
  replay; same-model without signature ⇒ kept; cross-model non-empty ⇒
  folded to a text block; empty (`""`/whitespace) ⇒ dropped; `redacted:
  true` blocks: same-model kept, cross-model dropped (pi :103-130).
- Tool-call `signature` (thoughtSignature analog): stripped cross-model,
  kept same-model (unused by the openai wire beyond replay).
- Orphaned tool calls (an assistant tool_call with NO following tool
  result for its id): a synthetic tool_result `content: "No result
  provided"`, `is_error: true` is INSERTED after the assistant message
  (pi :158-180; OQ-8). A system message BETWEEN a call and its results
  is held back and emitted after the results.
- Assistant WIRE shape (convertMessages :1300-1402): text blocks with
  non-whitespace text joined to ONE plain STRING content (an assistant
  with no text ⇒ `content: null`; an assistant with tool_calls and no
  text ⇒ `content: null` + `tool_calls`); `tool_calls` = [{id, type
  "function", function {name, arguments: JSON.generate(arguments)}}];
  thinking replay per §9.5; EMPTY assistants (no text after
  normalization, no tool_calls) are SKIPPED.

### 9.5 Thinking replay (same-model, kept thinking blocks)

- If the FIRST non-empty thinking block's signature parses as a JSON
  array of valid reasoning_details entries (objects with `type` one of
  `"reasoning.summary"` (summary String) / `"reasoning.encrypted"`
  (data String) / `"reasoning.text"` (text String, optional
  signature)) — pi isOpenAIReasoningDetail :135-165: emit
  `reasoning_details: <the parsed array>` and NO raw reasoning field.
- Else if the signature names one of `"reasoning"`, `"reasoning_
  content"`, `"reasoning_text"` (OPENAI_COMPLETIONS_REASONING_FIELDS
  :273): emit that field => all non-empty thinking texts joined `"\n"`.
- Else: no reasoning field.
- After the above, when `dialect.requires_reasoning_content_on_
  assistant_messages` AND model.reasoning AND no `reasoning_content`
  was emitted: emit `reasoning_content: ""` (deepseek; pi :1387-1393).
- Cross-model folded thinking rides as text content (§9.4) — NO
  reasoning fields (fixture 10's `"let me thinkHi!"` concatenation is
  pi's literal behavior).

### 9.6 Effective max tokens (pi simple-options.ts :13-19)

`clamp_max_tokens(requested || model.max_tokens)` = `min(requested ||
  model.max_tokens, model.context_window - estimate_tokens(messages) -
  4096)` but at least 1; `estimate_tokens` = ceil(chars / 3.5) over the
  message texts (pi CHARS_PER_TOKEN 3.5). When nil-able (no request cap
  and the Chat never sets one) the value still emits (model.max_tokens
  path) — the key omits ONLY when the Chat was told
  `with_max_output_tokens(nil)` AND model.max_tokens is nil (edge;
  fixtures always emit).

## 10. Delta parse + event stream (`protocol.rb`)

Per SSE payload (JSON chunk), in pi's exact order (openai-completions.ts
:558-707):

1. `chunk["id"]` ⇒ `partial.response_id ||= id` (first wins);
   `chunk["model"]` differing from model.id ⇒ `partial.response_model
   ||=`.
2. `chunk["usage"]` ⇒ parse per §10.1 (the `choices[0]["usage"]`
   fallback too).
3. `choices[0]["finish_reason"]` present ⇒ record raw stop reason, map
   per §10.2.
4. `choices[0]["delta"]`:
   - `delta["content"]` non-empty String ⇒ text block: `:text_start`
     (once), append, `:text_delta` with the RAW string delta.
   - reasoning: FIRST non-empty of `reasoning_content`, `reasoning`,
     `reasoning_text` (pi order :620-632) ⇒ thinking block; the FIELD
     NAME becomes the block's signature; `:thinking_start` once,
     append, `:thinking_delta` with the raw delta. (The opencode-go
     signature remap :638-641 is NOT ported — unported provider
     special-case, §14.)
   - `delta["tool_calls"]` array: per entry — resolve block by
     `index` (then by `id`; create on first sight with `id`/`name` from
     the delta), append `function.arguments` string deltas to the
     accumulator, push `:tool_call_delta` with the RAW string delta;
     `arguments` live-updated as best-effort parse (OQ-4).
   - `delta["reasoning_details"]` array (when present): validated
     entries accumulate (text/summary consecutive-merge semantics,
     pi appendOpenAIReasoningDetail :240-265) and serialize into the
     thinking block's signature at finalize.
5. `:done` semantics at stream end (`[DONE]` or body EOF): finalize all
   open blocks (`:text_end`/`:thinking_end`/`:tool_call_end` with the
   parsed `{id:, name:, arguments:}`); then the terminal discipline:
   - cancel observed ⇒ CancelledError (no events; D8).
   - stop_reason `:error` ⇒ emit `:error` event then raise StreamError.
   - no finish_reason observed AND `!dialect.supports_finish_reason` ⇒
     infer `:tool_use` when any tool-call block exists else `:stop`.
   - finish_reason expected (supports_finish_reason) but absent ⇒
     StreamError "Stream ended without finish_reason".
   - else `:done` with `reason:` mapped (`:stop`, `:length`,
     `:tool_use`) and the final Message.
6. `:start` is emitted BEFORE the first block event, carrying the seed
   partial. No event precedes `:start`.

### 10.1 Usage parse (pi :1519-1547)

`cache_read` = `prompt_tokens_details.cached_tokens` ??
`prompt_cache_hit_tokens` ?? `cached_tokens` ?? 0; `cache_write` =
`prompt_tokens_details.cache_write_tokens` || 0; `input` =
`[prompt_tokens - cache_read - cache_write, 0].max`; `output` =
`completion_tokens || 0`; `reasoning` =
`completion_tokens_details.reasoning_tokens || 0`; `total_tokens` =
input+output+cache_read+cache_write.

### 10.2 Stop reason map (pi :1562-1589)

`"stop"`/`"end"`/nil ⇒ `:stop`; `"length"` ⇒ `:length`;
`"function_call"`/`"tool_calls"` ⇒ `:tool_use`; anything else (incl
`"content_filter"`, `"network_error"`) ⇒ `:error` with message
`"Provider finish_reason: <raw>"`.

## 11. Tool + Cancellation (`tool.rb`, `cancellation.rb`)

- `Fast::Completions::Tool` — class-level `description`,
  `tool_name "…"` (optional override; default = class name),
  `parameters` (Hash, default `{"type"=>"object","properties"=>{}}`);
  instance `#execute(**arguments)` — the Chat calls it with the parsed
  arguments hash; a String/Hash return becomes the tool result content
  (Hash ⇒ JSON.generate for the text); `{error: "…"}` marks an error
  result (`is_error: true`). ~60 lines total.
- `Fast::Completions::Cancellation.check` — raises CancelledError when
  the current `Async::Task` (if any) is cancelled; a no-op outside a
  reactor. ~15 lines. `Chat` calls it before each tool execution and at
  stream start (D8 checkpoints).

## 12. Chat (`chat.rb`) + the parity harness

### Chat semantics

- History: `messages` starts empty; `with_instructions` sets THE
  instruction message; `add_message` appends (the gem never mutates a
  consumer message); Chat's OWN outputs are appended as assistant
  Messages stamped `provider:` (default `"fast-completions"`), `model:
  model.id`, `api: "openai-completions"` — and tool results as
  tool_result Messages — all via `add_message`.
- `#step` (one turn): build the §9 request from instructions + history +
  tools + thinking_level + max_output_tokens; `client.stream`; yield
  every event to the block; on `:done` with `:tool_use`: for EACH tool
  call in order — `Cancellation.check`, `before_tool_call` hook, execute,
  `after_tool_result` hook, append the tool_result Message (is_error per
  §11) — then return the final assistant Message (batch consumed on the
  NEXT step; `complete?` false while a batch is pending). On `:done`
  otherwise: return the Message. Hooks: `chat.before_tool_call { |tool_call| }`
  / `chat.after_tool_result { |tool_call, result| }` — MULTIPLE blocks
  register; dispatch IN REGISTRATION ORDER; the tool_call carries `id:/
  name:/arguments:` — attribution is BY tool_call id (the I49/thread-
  audit discipline; NO Thread/fiber-local pairing anywhere).
- `#cancel`: sets a cancel latch + `Async::Cancel` on the in-flight
  stream task; `step` raises CancelledError AFTER the stream aborted
  (no phantom terminal, AC3); tool executions between batches observe
  the latch via `Cancellation.check`.
- `thinking_level=` accepts the ladder + nil; clamped per §9.3 at
  request build.

### 12.1 The gem's OWN mock (lane `core`, `spec/support/`)

A copy of tart's `test/support/mock_llm_server.rb` (287 l; read-only
copy sanctioned by the plan) ADAPTED: drop the `Tart::Test`/
`TestChat` minitest nesting (the gem has no ruby_llm); keep the class
top-level as `MockLLMServer`; keep the script-spec vocabulary
({type: :stream, content:, reasoning_content:, tool_calls:, chunks:},
:message, :slow_stream + `spec_pause`, :error + status), `rearm!`,
`suppress_usage!`, `captured_requests`, `captured_request_logs`, the
empty-connect discipline, EPIPE discipline — behavior byte-equivalent.
Header comment records provenance ("copied from tart
test/support/mock_llm_server.rb at 2943ef0, I02/I17/I29 rig lineage;
ruby_llm adapter removed").

### 12.2 Wire fixtures + parity spec (lane `harness`)

- `spec/fixtures/wire/<tag>.json` — the 11 fixtures of Grounds §3,
  EXACT bytes: `{tag:, request_path:, request_body:}` with
  request_body the RAW pi body string (embed with JSON escaping; the
  file is JSON). The lane reproduces them by RUNNING the capture driver
  (verbatim copy at `spec/fixtures/wire/CAPTURE.mjs` — the Grounds §3
  driver, committed FOR PROVENANCE, never executed by the suite; its
  header documents the installed-pi path + the frozen digests) — the
  builder copies the bytes from the spec's fixture table BELOW (the
  Specification embeds each fixture's request_body verbatim in §12.3)
  OR re-runs the driver; EITHER WAY the AC2 digest gate is the judge's
  proof.
- `spec/fast/completions/wire_parity_spec.rb` — for EACH of the 11
  scenarios: construct the §12.3 gem-side scenario, run ONE request
  against a started MockLLMServer (script `{type: :stream, content:
  "ok"}`), take the captured request body (raw string), and assert
  `Digest::SHA256.hexdigest(captured) == fixture digest` AND byte
  equality against `request_body`. On mismatch the failure output
  shows a key-order-aware diff of the parsed bodies (usability pin).
- `script/install_check.sh` — the AC6 release check (§14 of the AC):
  `gem build`, scratch `GEM_HOME` install, `require "fast/completions"`
  from OUTSIDE the repo, smoke chat against a started MockLLMServer
  (booted by a tiny ruby -e wrapper), prints `INSTALL_CHECK_OK`.

### 12.3 The scenario table (frozen; driver ⇄ gem-side construction)

Common: instructions "You are a test assistant."; the ONE tool
`{"type"=>"object","required"=>["path"],"properties"=>{"path"=>
{"type"=>"string"},"offset"=>{"type"=>"number"}}}` under a Tool whose
description is "Read file contents."; client pointed at the mock; the
final user message per scenario; model id "mock-1", context_window
128_000 unless noted.

| tag | model kwargs (beyond common) | thinking_level | history before the final user message |
|---|---|---|---|
| fireworks_plain | reasoning: false, max_tokens: 512, dialect: :fireworks | nil | — |
| openai_ladder_on | reasoning: true, max_tokens: 512, thinking_level_map: {off:"none",low:"low",medium:"medium",high:"high"} | :high | — |
| openai_ladder_off | (same model) | :off | — |
| zai_on | reasoning: true, max_tokens: 512, map: {off:"disabled",low:"low",medium:"medium",high:"high"}, dialect: :zai | :high | — |
| zai_off | (same model) | :off | — |
| deepseek_on | reasoning: true, max_tokens: 512, map: {off:"disabled",high:"high"}, dialect: :deepseek | :high | — |
| tool_roundtrip | reasoning: false, max_tokens: 512, dialect: :fireworks | nil | user "read the file"; assistant(tool_call id "call_1" name "read" arguments {"path"=>"src.rb"}, provider: "fireworks", model: "mock-1"); tool_result "call_1" content "line 1\nline 2" |
| thinking_replay | reasoning: true, max_tokens: 512, map: {high:"high"} | nil | user "hello"; assistant(thinking "let me think" signature "reasoning_content", text "Hi!", provider: "fast-completions-context", model: "mock-1" → SAME-MODEL requires the chat's provider stamp; see note); user "thanks" |
| reasoning_details_replay | (same model) | nil | user "hello"; assistant(thinking "thought" signature `'[{"type":"reasoning.text","text":"t1","signature":"sig"}]'`, text "Hi!"); user "thanks" |
| cross_model_thinking_replay | (same model) | nil | user "hello"; assistant(thinking "let me think" signature "reasoning_content", text "Hi!", provider: "other-provider"); user "thanks" |
| budget_field | reasoning: true, max_tokens: 4096, map: {off:"none",high:"high"}, dialect: user-declared {thinking_token_budget_field: "thinking_token_budget"} | :high | — |

Note (same-model stamping): the driver built assistants with
`provider:"mock"` matching the model's driver-side provider field
("mock"). The GEM's Model has NO provider field (no registry); the
same-model comparison uses `(msg.provider, msg.model)` vs the Chat's
context — SO the parity spec constructs the replayed assistants with
`provider:` equal to the Chat's stamp context. The Chat's OWN outputs
use the default stamp `provider: "fast-completions"`; the parity spec
sets `chat.assistant_provider_stamp = "mock"` … NO — simpler, frozen:
`Fast::Completions::Model.new(..., provider: "mock")` — Model GAINS an
optional `provider:` (default "fast-completions"); same-model compares
`(msg.provider, msg.model)` against `(model.provider, model.id)`. The
parity table above then stamps replayed assistants `provider: "mock"`
for the same-model scenarios (thinking_replay, reasoning_details_
replay, tool_roundtrip) and `provider: "other-provider"` for
cross_model. This keeps the gem registry-free while the comparison
stays consumer-controlled. (Model#provider is metadata ONLY — never a
wire byte.)

Final user message: "hello" for the no-history scenarios (all but
tool_roundtrip/replay rows, which end with the user message shown).

## 13. READMEs (lane `core`)

- Root `README.md`: the monorepo — what lives here (gems/completions),
  the naming rule (gems named for the API they speak), pointer to the
  gem README, the "release tags are cut by hand" note.
- `gems/completions/README.md` (house discipline, Grounds §4):
  - Opens by naming THE WIRE: the gem speaks **"the OpenAI-compatible
    chat-completions wire"** and disambiguates from the LEGACY
    `/v1/completions` (text-completions) API — a sentence stating it
    does NOT speak the legacy completions endpoint (AC5 pins both
    facts).
  - What it is NOT: no model catalog, no pricing, no provider registry,
    no universal translation — the consumer owns models; dialects are
    declarations (LiteLLM named as the anti-shape is optional).
  - Installation, quickstart (Chat + Tool, runnable), the dialect DSL
    with the zai example, deps statement (async-http only), error
    taxonomy table, the parity statement (byte-faithful to pi's wire;
    the fixture harness), fiber-native note.

## 14. Boundaries

May touch (the ```lanes``` block is the frozen source of truth; this
prose summarizes):

- Lane `core` (repo fast-llm): the scaffold files of §1 EXCEPT the
  harness files (fixtures/, wire_parity_spec.rb, install_check.sh);
  the unit spec files listed in §1; root Gemfile.lock.
- Lane `harness` (repo fast-llm): `spec/fixtures/wire/**` (fixtures +
  CAPTURE.mjs), `spec/fast/completions/wire_parity_spec.rb`,
  `script/install_check.sh`.

Must not touch:

- EVERYTHING in repos/tart (read-only reference; the mock copy is a
  copy, not a move), repos/pi, every other repos/* path.
- `lib/fast/completions/**` is lane `core`'s ALONE; `spec/fixtures/**`
  + the parity spec + install script are lane `harness`'s ALONE.
- No GitHub/rubygems actions; no `git push` anywhere; builders never
  commit (the coordinator integrates); no release tags.
- No new runtime dependencies beyond async-http; no vendoring of pi
  TypeScript (this is a REWRITE per BRIEF §2 — ported semantics with
  citations, never copied TS).

Out of scope (itemized; reopen on consumer need): retries (OQ-2);
images over the wire (D7); tool_choice; sampling params; strict/
grammar tool modes; anthropic cache-control; openrouter/vercel
routing; vllm priority; prompt_cache_key/retention; mid-convo system
messages/tool additions; requires_tool_result_name /
requires_assistant_after_tool_result / requires_thinking_as_text;
thinking formats beyond openai/zai/deepseek (qwen, chat-template,
baseten, together, openrouter, string-thinking, ant-ling — D2);
non-streaming POSTs (the client always streams — the mock's
:message scripts serve streaming frames? NO: out of scope means the
gem NEVER issues non-streaming requests; parity specs script :stream);
tool concurrency modes (D9); token estimation beyond §9.6's
chars/3.5; benchmark page (OQ-11); .github workflows (OQ-12);
fast-messages/fast-responses siblings.

## 15. Lane plan

Two lanes, repo fast-llm, DISJOINT by construction:

1. `core` — the monorepo scaffold + the gem (lib, gemspec, version,
   changelog, READMEs, root Gemfile + lock) + the mock copy + the unit
   RSpec suite. Verification IN ITS WORKTREE: `bundle install &&
   bundle exec rspec` green (its own unit specs + a smoke spec that
   runs one chat turn against the mock).
2. `harness` — the wire fixtures (embedded from §12.3 / re-captured),
   the parity spec, the install-check script. RED AT BASE BY DESIGN
   (the gem does not exist in its worktree — the lane mounts on
   `core`'s integration; gate calibration in the AC declares this).
   Verification: fixture digests match the frozen table (a pure-data
   check green in ANY worktree) + the parity spec green on the
   integrated tree.

Dispatch note (coordinator): integrate `core` FIRST, then run
`harness`'s verification against the integrated tree (the I48/I49
core-then-e2e pattern). The AC's integrated-tree gates run after both.

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
`architect rehearse fast-completions-gem` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze fast-completions-gem` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse fast-completions-gem` — before the freeze, while
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
subsection per lane. A copy is written to build/I51-fast-completions-gem-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section fast-completions-gem prompt --append --lane <lane> --from build/I51-fast-completions-gem-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I51-fast-completions-gem-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence fast-completions-gem --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section fast-completions-gem verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify fast-completions-gem`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
