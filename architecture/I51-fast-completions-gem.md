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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section fast-completions-gem specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision fast-completions-gem`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
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
