# I46: zai-provider

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I46 zai-provider

Program ENTRY 4 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding context folded in). The
dry-rb wave is COMPLETE (I43 `0c6ee246` / I44 `4c2e6a9a` / I45
`a236876` — schemas, shapes, and flow families INHERITED verbatim, never
re-litigated; this iteration CONSUMES their patterns — a typed struct in
`Shapes`, a contract rule in `Schemas::Models`). All measurements this
session (2026-10-13) at base **a236876** (`project/pi-port` tip, I45
merged — `git log --oneline -1` re-run at spec time; working tree
clean). Spec-time verification under `tmp/i46-spec/` (gitignored).

## 1. Control (this session, base a236876)

- Suite: `868 runs, 3713 assertions, 0 failures, 0 errors, 1 skips`
  (the pre-existing opt-in LiveRunTest skip) — identical to the I45
  close-out record. `SEAM_BENCH_OK` (fresh runs this session).
- Parity battery: this session re-ran suite + bench only; the s-gates
  ride frozen with the CANONICAL short out dirs (the standing I41/I44
  environmental note; the s9 lane-worktree deep-path artifact has SEVEN
  judge-proven precedents — I34/I36/I39/I40/I42/I43/I44 — and does not
  fail an iteration when the same tree exits 0 at canonical depth).
- Deps: NO new gem. ruby_llm 2.1.0 pinned (Gemfile.lock:138); the gem
  dir paths cited below are
  `…/gems/ruby_llm-2.1.0/lib/ruby_llm/…` (verified `gem which ruby_llm`).
- Live probe: **NOT RUN — no ZAI key in this session's environment**
  (`printenv ZAI_API_KEY` unset; the only provider credential present is
  `FIREWORKS_API_KEY`, the I36 standing path). Per the letter: static
  grounding + flagged for the judge (§6).

## 2. pi's zai dialect — every letter cite re-verified this session

The plan letter's citations were re-read line-by-line against
`repos/pi/packages/ai/src` (the I43 standing discipline — verify counts
and line numbers before freezing them). All hold; the exact anchors:

- **Provider** (`providers/zai.ts`): `baseUrl:
  "https://api.z.ai/api/coding/paas/v4"` at **:10** — the CODING plan
  endpoint. Auth at :11: `envApiKeyAuth("Z.AI API key", ["ZAI_API_KEY"])`
  — pi reads a stored credential or the `ZAI_API_KEY` env var.
- **Detection** (`api/openai-completions.ts:1593-1605`): `detectCompat`
  — `isZai = provider === "zai" || provider === "zai-coding-cn" ||
  baseUrl.includes("api.z.ai") || baseUrl.includes("open.bigmodel.cn")`
  (:1597-1601). The zai rows of the detected table (:1621 `isNonStandard`,
  :1630-1637 `useMaxTokens`, :1645 `supportsStore: !isNonStandard`,
  :1646 `supportsDeveloperRole`, :1648-1649
  `supportsReasoningEffort` — zai EXCLUDED (false), :1651
  `maxTokensField: useMaxTokens ? "max_tokens" : …` — zai
  `max_tokens`, :1656-1658 `thinkingFormat: isZai ? "zai" : …`,
  :1675 `supportsStrictMode: false` detected, `zaiToolStream: false`
  detected). Model compat OVERRIDES merge key-wise:
  `model.compat.<key> ?? detected.<key>` (:1701-1722).
- **The dialect branch (:880-892, verified)**: under
  `compat.thinkingFormat === "zai" && model.reasoning` —
  `thinking = options?.reasoningEffort ? {type: "enabled",
  clear_thinking: false} : {type: "disabled"}` (:886-887 —
  `clear_thinking` ONLY on enabled); ADDITIONALLY when
  `options?.reasoningEffort && compat.supportsReasoningEffort` (:888):
  `mappedEffort = model.thinkingLevelMap?.[options.reasoningEffort]`;
  `effort = mappedEffort === undefined ? options.reasoningEffort :
  mappedEffort`; `if (typeof effort === "string")
  reasoning_effort = effort` (:889-891 — a null map value sends NO
  reasoning_effort; a MISSING key sends the raw level). The branch is
  one arm of an else-if chain — for zai models it REPLACES the generic
  `reasoning_effort` arms (:969-976).
- **The effort input (:749-755)**: `clampedReasoning = options.reasoning
  ? clampThinkingLevel(model, options.reasoning) : undefined`;
  `reasoningEffort = clampedReasoning === "off" ? undefined :
  clampedReasoning` — i.e. the zai branch sees the CLAMPED level, and
  a clamped `"off"` means NO effort (disabled thinking), regardless of
  any String `off` map value. pi's generic off-arm (:971-976, String
  `off` map floor) is UNREACHABLE for zai-format models (the zai arm
  takes the branch first).
- **tool_stream (:855-860, verified)**: when
  `transcriptTools.requestTools.length > 0`, tools attach AND
  `if (compat.zaiToolStream) params.tool_stream = true` (:858-859 —
  `:857-859` in the letter = the tools-attach line through the
  assignment). NO tool_stream when the request carries no tools (the
  empty-tools fallback at :861-863 sends `tools: []` without
  tool_stream).
- **The instruction role (:1233)**: `instructionRole =
  model.reasoning && compat.supportsDeveloperRole ? "developer" :
  "system"` — developer requires BOTH the model's reasoning flag AND
  the compat override/detection.
- **maxTokensField (:841-848)**: `compat.maxTokensField ===
  "max_tokens"` sends `max_tokens`, else `max_completion_tokens`
  (only when a maxTokens option exists at all).
- **Compaction summarization carries the level** (compaction/
  compaction.ts:605-607): options set `maxTokens` and, when
  `model.reasoning && thinkingLevel && thinkingLevel !== "off"`,
  `reasoning = thinkingLevel` — pi's summarization request rides the
  SAME dialect branch (thinking enabled at the session level for zai).
- **User-file compat schema** (coding-agent/core/model-config.ts:32-77):
  `ModelDefinitionSchema.compat`/`ModelOverrideSchema.compat`/
  `ProviderConfigSchema.compat` are all Optional `ProviderCompatSchema`
  (providers/compat-schema.ts) — every compat property Optional, the
  object `additionalProperties: true` (UNKNOWN COMPAT KEYS TOLERATED),
  `thinkingFormat` a union of 11 literals (openai, openrouter, deepseek,
  together, baseten, zai, qwen, chat-template, qwen-chat-template,
  string-thinking, ant-ling), `maxTokensField` a union of the two
  literals, booleans boolean.
- pi also sends `store: false` when `compat.supportsStore` (:838-839)
  and `strict` on function tool defs when `compat.supportsStrictMode !==
  false` (:1505-1513) — see §7 OQ items.

## 3. The owner's live catalog (read this session)

`~/.pi/agent/models-store.json` provider `zai` — 7 models; glm-5.3,
glm-5.3-flash, glm-5.3-highspeed all carry:

```json
"baseUrl": "https://api.z.ai/api/coding/paas/v4",
"reasoning": true,
"thinkingLevelMap": {"off": null, "minimal": null, "low": "low",
                     "medium": null, "high": "high", "xhigh": null,
                     "max": "max"},
"compat": {"supportsStore": false, "supportsDeveloperRole": false,
           "supportsReasoningEffort": true, "maxTokensField": "max_tokens",
           "thinkingFormat": "zai", "supportsStrictMode": true,
           "zaiToolStream": true}
```

(contextWindow 1000000, maxTokens 131072.) So the owner's glm-5.3 wire:
thinking object ALWAYS (enabled + clear_thinking:false at any resolved
effort; disabled at off), `reasoning_effort = <mapped>` (the catalog
OVERRIDES pi's detected false — BOTH the thinking object AND the effort
go out), `tool_stream: true` when tools ride, instruction role
`system`, `max_tokens`. The map's supported ladder is [low, high, max]
(off/minimal/medium/xhigh null-marked): DEFAULT level `medium` clamps
FORWARD to `high` — the owner's typical wire carries
`reasoning_effort: "high"`. `supportsStore`/`supportsStrictMode` are in
the owner's catalog but NOT in the letter's five-key parse subset (§7).

## 4. ruby_llm 2.1.0 (the gem, verified this session)

- **NO zai provider**: `providers/` = anthropic, azure, bedrock, cohere,
  deepgram, deepseek, elevenlabs, gemini, gpustack, hetzner, mistral,
  ollama(+cloud), openai, openrouter, perplexity, vertexai, xai.
  `deepseek/` is the single-file-provider precedent (its
  `chat.rb#configure_thinking_payload` writes pi-deepseek's
  `thinking:{type:…}` object — the gem PARSES a `thinking` object on
  responses fine; nothing provider-side is needed for zai).
- **The letter's `chat_completions/chat.rb:85-88` resolves to
  `lib/ruby_llm/protocols/chat_completions/chat.rb`** (the 2.1.0 layout):
  `render_payload` :56-94 — `payload[max_output_tokens_field(model)] =
  max_output_tokens unless nil` :67; **`max_output_tokens_field` :96-99:
  `:max_completion_tokens` iff the provider slug is `openai`/`azure`,
  else `:max_tokens`** — tart rides the `openai` slug (Models::
  WIRE_PROVIDER), so the gem names the field `max_completion_tokens`
  today; `effort = resolve_effort(thinking)` :85 →
  `payload[:reasoning_effort] = effort if effort` :86 (the letter's
  :85-88 region — the gem's OWN effort path, inert for tart: the port
  never sets gem thinking config, I36); `format_role` :376-383 —
  **`:system` renders `"developer"` UNLESS
  `config.openai_use_system_role`** (:379) — the replay probe's
  §4.1 finding (developer-role default on this protocol; the probe's
  raw output `tmp/replay-probe/out/part1.txt` shows fireworks wire
  carrying `role: "developer"` for the instruction); `resolve_effort`
  :385-390.
- **The hook seam** (`protocol.rb:134-157`): `render_payload` → end_user
  → compaction → provider_options → provider_tools → tool_search →
  **`apply_before_request_hooks(payload, before_request)` LAST** — the
  I36 hook's standing grounding; the payload is symbol-keyed with
  `:messages` (symbol-keyed message hashes, string role values) and
  `:tools`. tart's hook owns `reasoning_effort` outright today
  (`loop.rb#install_thinking_seam` :612-625: set-or-delete per
  `Models.resolve_reasoning_effort`, then the replay normalization
  deleting assistant `:reasoning`).
- `openai_use_system_role` is a provider CONFIG option
  (`providers/openai.rb:86` `configuration_options`), set at context
  build — but tart's `with_model` switch keeps ONE context per chat, so
  a config flip is stale across mid-session model switches; the HOOK
  rewrite is the correct mechanism (the letter's "hook rewrites if
  needed").

## 5. tart today (base a236876, verified)

- **The default boot** (`settings.rb:38-49`): DEFAULTS hardcode
  fireworks — `defaultModel accounts/fireworks/models/glm-5p3-flash`,
  `defaultProvider "openai"`, `apiBase
  https://api.fireworks.ai/inference/v1`. UNTOUCHED by this iteration
  (the letter: default boot stays fireworks, zero behavior change; zai
  activates from the catalog).
- **The catalog** (`models.rb`, 263 l; schemas `schemas/models.rb`
  136 l; shapes `shapes/model.rb` 64 l): `Models.load` →
  `Schemas::Models.validate` (CatalogContract — every rejection line
  ours via `key.failure`) → `build_providers`/`build_model` → typed
  `Shapes::Model` entries `{id, name, reasoning, context_window,
  max_tokens, thinking_level_map, provider}` (DECLARED order = to_h
  emission, provider LAST — the I44 byte pin). `Config#entry_field`
  bridges legacy raw-hash entries. `Models.wire_provider` maps
  non-native provider keys onto the single `openai` chat-completions
  seam (a zai provider key rides it unchanged — NO gem provider work).
  `build_chat` (bin/tart :520-533): `config.openai_api_base = ENV
  [<IDENTITY>_API_BASE] || provider&.base_url || resolved.api_base` —
  the zai endpoint arrives via the catalog provider block, the key via
  its `apiKey` or `<IDENTITY>_API_KEY`.
- **The thinking seam** (`agent/loop.rb`): ctor kwargs
  `thinking_level:`/`model_reasoning:`/`thinking_level_map:` (:92-95,
  stored :104-106); `switch_model` re-resolves the facts (:170-186);
  `install_thinking_seam` (:592-625) sets/deletes `reasoning_effort`
  per `Models.resolve_reasoning_effort` (the I36 map+clamp+off-floor —
  `models.rb:239-262`, pi :749-755 + :969-976) and the replay
  normalization. The hook reads loop state at REQUEST time — mid-session
  level/model changes apply to the next request with no gem state.
- **The threading map** (where a `compat:` kwarg must flow):
  - boot kwargs `boot_thinking_kwargs` (bin/tart :458-464) →
    `Print.run` (print.rb :66-79 → Loop ctor) and the interactive
    `Agent::Loop.new` (bin/tart :300-313, via the `facts` hash);
  - the switch seam: `Render::Chat#apply_model_selection`
    (render/chat.rb :1861-1881) → `@agent&.switch_model(…,
    model_reasoning:, thinking_level_map:)`; the legacy-kwarg wrap
    (:1870-1871) and `boot_model_entry` (:1908-1921) construct
    `Shapes::Model` directly (both need the new defaulted key);
  - `Settings.thinking_facts` (settings.rb:297-302) composes
    ThinkingFacts{reasoning, thinking_level_map} catalog-entry-first —
    STAYS UNTOUCHED (compat is a wire fact, not a footer fact; the
    footer/border bytes do not move).
- **The frozen re-pin inventory** (grep-verified, complete): adding a
  `compat` attribute to `Shapes::Model` changes `to_h` →
  `test/shapes_test.rb:49-57` (the to_h + key-order pin) and
  `:94-111` (the loaded-entries to_h table, 2 entries) need `compat:
  nil` added; `test/models_test.rb:69-71` (entry to_h) likewise; the
  switch-seam signature pin `test/chat_test.rb:2290-2305` defines a
  `switch_model` singleton with the EXACT kwarg list and asserts the
  exact kwargs hash — passing a new `compat:` kwarg RAISES there
  (unknown keyword) → mechanical re-pin (signature + expected hash gain
  `compat: nil`; the fixture's glm entry declares none). Every other
  entry-hash/to_h/switch-signature assert was grepped and needs
  nothing (`models_test.rb:159-200` = ModelRef to_h; chat_test :1635/
  :2568 legacy-kwarg switches flow through the wrap).
- **Test idioms for the new pins**: `agent_on_kernel(**loop_kwargs)`
  (agent_loop_test.rb :355-364) threads Loop ctor kwargs against
  `MockLLMServer` (`test/support/mock_llm_server.rb`) whose
  `captured_requests` expose the parsed JSON bodies (the I36/I45 wire
  pins); the compaction summarization request is capturable the same
  way (with_max_output_tokens rides the SAME chat → the same hook).

## 6. Live probe — NOT RUN (flagged for the judge)

The letter's conditional ("If a ZAI key is present in the environment…")
resolves FALSE this session: no `ZAI_API_KEY` (nor any zai credential)
in the environment; the I36 standing rule forbids new credential paths
(~/.pi/agent/auth.json is pi's store — NOT an environment key). Static
grounding is complete (pi source + the gem source + the owner's live
catalog read this session); the one live-only unknown is z.ai's
response-side acceptance of the exact dialect bytes (the request shape
is pi's, byte-modeled above; fireworks' request schema accepting the
gem shapes was the I36/T2b precedent — for zai the analogous 200 has
NOT been observed by this space). The builder adds NO live call; the
judge may direct one from an environment that holds the key
(one scripted request, I36 `tmp/repro_*` shape).

## 7. Interpretation items (letter-resolved, judge-adjudicated)

- **OQ-1 (supportsStrictMode — the one REAL wire divergence).** The
  owner's catalog says `supportsStrictMode: true`; pi then sends
  `strict` on function tool defs (openai-completions :1505-1513). The
  letter's parse subset names five keys — strict is NOT parsed and the
  gem's tool rendering (no `strict` key) is untouched. Itemized
  deviation: the port's zai tool declarations carry no `strict`; the
  field is a capability hint (absent = non-strict), not a requirement
  — RECOMMEND ACCEPT (letter enumeration governs); live verification
  needs the key (§6).
- **OQ-2 (no URL detection).** pi's detectCompat fallback is NOT
  ported: the dialect activates ONLY from catalog compat (the letter:
  "the zai provider activates from the catalog"). A zai endpoint
  reached without compat entries behaves exactly like today (no
  thinking object, no tool_stream) — RECOMMEND ACCEPT (smaller,
  zero-change-safe; detection can be a follow-up on pain).
- **OQ-3 ($ENV templates in apiKey NOT expanded).** pi expands
  `$VAR`/`!command` config values (core/resolve-config-value.ts:1-9,
  33-95 — the owner's pi models.json uses `"$FIREWORKS_API_KEY"`).
  tart passes `apiKey` through verbatim (existing behavior, unchanged
  here): a literal key or `<IDENTITY>_API_KEY` env override. A copied
  `"$ZAI_API_KEY"` catalog value would be sent literally — documented
  in the README (the iteration's docs row); expansion is a follow-up on
  owner demand. RECOMMEND ACCEPT.
- **OQ-4 (supportsStore tolerated, not parsed).** In the owner's
  catalog; pi sends `store: false` only when TRUE — for zai compat
  false, pi sends NO store, and the gem never sends one either: no
  divergence for zai. (For supportsStore-true providers like detected
  fireworks, pi sends `store:false` and the port does not — a
  PRE-EXISTING standing divergence outside compat scope, unchanged.)
  Unknown compat keys are TOLERATED (pi additionalProperties:true) —
  the owner's catalog loads clean. RECOMMEND ACCEPT.
- **OQ-5 (the zai off-edge supersedes the I36 off-floor).** For a
  zai-format model with a String `off` map value at level `off`, pi's
  zai arm sees reasoningEffort undefined (:751) → `thinking:
  {type:"disabled"}` and NO reasoning_effort — the I36 String-off
  floor (reasoning_effort = the floor value) does NOT apply on the zai
  arm. The port's zai branch keys on the CLAMPED level (`"off"` ⇒
  disabled), exactly pi. The owner's catalog (off:null) never hits the
  edge; the unit table pins it anyway. RECOMMEND ACCEPT.
- **OQ-6 (compat-nil role note).** With NO compat entry the port sends
  the gem-default `developer` role regardless of the model's reasoning
  flag; pi's detected table would send `system` for non-reasoning
  models on fireworks-class URLs. PRE-EXISTING divergence (no catalog
  compat existed before this iteration), unchanged by the zero-change
  bar. RECOMMEND ACCEPT (itemized, not fixed here).

## 8. Environmental carry-ins (standing)

- Frozen gates keep the CANONICAL short out dirs (I41/I44); the judge
  runs the battery on the integrated tree.
- s1_tart exits 1 BY DESIGN (the staged identity work-list); s7's
  design exit is 0 (compaction parity landed I30).
- The fireworks wire digests (`2ece7d4b…` bodies / `7360fd1e…` tools)
  and the session-golden digests are the byte bar for "zero behavior
  change for existing configs" — captured at base, judge-proven
  three-way in I44/I45.

## Specification

# Specification — I46 zai-provider

One lane (`zai`). The port's first per-model dialect: pi's zai compat
subset parsed from the catalog and applied at the ONE request seam (the
I36 before_request hook), so tart runs glm-5.3 on
`https://api.z.ai/api/coding/paas/v4` exactly as the owner's pi does —
while EVERY existing config (no compat entries) produces byte-identical
wire, screen, and session output. The fireworks default boot is
untouched.

## 1. The catalog compat subset (Schemas + Shapes + Models)

**1.1 Schema (Schemas::Models CatalogContract).** A model entry MAY
carry `compat` (an object). Validated per the pi subset, in the rule
order AFTER contextWindow/maxTokens (pi's ModelDefinitionSchema declares
compat last):

- `compat` present but not an object →
  `expected an object` at path `providers.<key>.models[<i>].compat`;
- `thinkingFormat` present but not one of pi's 11 literals →
  `expected a thinking format` at `…compat.thinkingFormat`;
- `maxTokensField` present but not `"max_tokens"` or
  `"max_completion_tokens"` →
  `expected "max_tokens" or "max_completion_tokens"` at
  `…compat.maxTokensField`;
- `supportsDeveloperRole` / `supportsReasoningEffort` / `zaiToolStream`
  present but not boolean → `expected a boolean` at their paths;
- UNKNOWN compat keys (e.g. the owner's `supportsStore`,
  `supportsStrictMode`) → NO error (pi additionalProperties:true — the
  owner's live catalog must load clean).

Error lines keep today's shape (`  - <path>: <message>`, dotted keys,
bracketed indices) and interleave in parsed order with the existing
rules; the failure surface stays error-as-field (never raises).

**1.2 Shape (Shapes).** New `Shapes::ModelCompat` (dry-struct, sibling
of Model): five optional attributes, nil-defaulted and omittable at
construction — `thinking_format` (String, constrained to the 11
literals), `max_tokens_field` (String, constrained to the two
literals), `supports_developer_role` / `supports_reasoning_effort` /
`zai_tool_stream` (Bool). `Shapes::Model` gains `compat`
(`Shapes::ModelCompat` optional, default nil) DECLARED between
`thinking_level_map` and `provider` (a model field precedes the
appended provider key) — the DECLARED order is the to_h emission order
(I44 rule). `Model#to_h` therefore gains `compat:` — the three frozen
entry-hash asserts re-pin consciously (Grounds §5's inventory:
shapes_test :49-57 + :94-111, models_test :69-71; mechanical
`compat: nil` additions — no assert deleted).

**1.3 Parse (Models).** `build_model` builds the struct when the entry
carries compat (symbolized keys, the five picked, the rest ignored).
`Config` gains a compat reader bridging legacy raw-hash entries the
`entry_field` way (`respond_to?(:compat) ? compat : hash[:compat]` —
nil default). No resolution/wire_provider/boot-default change.

## 2. The request seam — the zai branch (agent/loop.rb)

**2.1 Threading.** `Loop#initialize` and `Loop#switch_model` gain
`compat:` (Shapes::ModelCompat, default nil) stored as `@compat` and
read at REQUEST time by the hook (the thinking_level idiom —
mid-session switches apply to the next request; nil IS "the switched
model declares none", re-resolved wholesale like the other facts).

**2.2 The hook** (install_thinking_seam, ONE hook, both paths —
unchanged installation). The existing body becomes the NON-zai arm; a
zai arm is added in front. The full contract table (pi
openai-completions :880-892 + :749-755 + :855-860 + :1233 +
:841-848; compaction.ts :605-607):

- **compat nil (or thinking_format != "zai")**: TODAY'S hook
  BYTE-EXACT — reasoning_effort set-or-deleted per
  `Models.resolve_reasoning_effort`; NO thinking object; NO
  tool_stream; NO role rewrite; NO max-token rename. (The zero-change
  bar; fireworks default and every compat-less catalog ride this arm.)
- **zai arm** (`compat.thinking_format == "zai"`):
  - if `@model_reasoning`: `clamped =
    Models.clamp_thinking_level(@thinking_level, map:
    @thinking_level_map, reasoning: true)`;
    `effort_present = clamped && clamped != "off"` (pi :751 — a
    clamped `"off"` is NO effort, the String-off floor does NOT apply
    on this arm);
    `payload[:thinking] = effort_present ? {type: "enabled",
    clear_thinking: false} : {type: "disabled"}` (clear_thinking ONLY
    on enabled);
    if `effort_present && compat.supports_reasoning_effort == true`:
    `mapped = @thinking_level_map&.[](clamped.to_sym)`;
    `payload[:reasoning_effort] = mapped.is_a?(String) ? mapped :
    clamped` (pi :889-891 — a MISSING key sends the level; a null
    value cannot reach here: supported levels never carry null);
    else: `payload.delete(:reasoning_effort)` (no effort, or the
    compat says the endpoint refuses the field — pi's detected-false
    default for zai);
    if NOT `@model_reasoning`: NO thinking object and NO
    reasoning_effort (pi :880 gates the arm on model.reasoning; the
    generic arms cannot fire for a non-reasoning model) — delete
    reasoning_effort.
  - `tool_stream`: if `compat.zai_tool_stream == true` AND
    `payload[:tools]` is a non-empty Array → `payload[:tool_stream] =
    true`; otherwise nothing (pi :855-860 — no tools, no field).
  - **instruction role**: `supports_developer_role_effective =
    compat.supports_developer_role.nil? ? (compat.thinking_format ==
    "zai" ? false : true) : compat.supports_developer_role` (nil falls
    to pi's DETECTION stand-in: zai URLs detect false, standard URLs
    true); the wire role is `"developer"` iff `@model_reasoning &&
    supports_developer_role_effective`, else `"system"` — the hook
    rewrites every `payload[:messages]` entry whose `:role ==
    "developer"` to `"system"` when the effective role is system (the
    gem's developer default, Grounds §4). With compat nil: NO rewrite.
  - **max tokens**: if `compat.max_tokens_field == "max_tokens"` and
    `payload.key?(:max_completion_tokens)` → `payload[:max_tokens] =
    payload.delete(:max_completion_tokens)` (pi :841-848; today only
    the compaction summarization sets max output tokens — the rename
    lands there; `"max_completion_tokens"` and nil compat rename
    nothing).
  - The replay normalization (assistant `:reasoning` deletion) runs
    unchanged for BOTH arms.
- NO store field is ever added (OQ-4); NO `strict` on tool defs (OQ-1).

## 3. Threading (boot, print, switch)

- `bin/tart#boot_thinking_kwargs` composes `compat:` from
  `resolve_boot_entry(models, boot)&.compat` (nil without a catalog) —
  the interactive `Agent::Loop.new` (via its facts hash) and
  `Print.run` forward it to the Loop ctor.
- `print.rb#run` gains the `compat:` kwarg (default nil), forwarded.
- `Render::Chat#apply_model_selection` passes
  `compat: facts-source entry.compat` to `@agent&.switch_model`; the
  legacy-kwarg wrap adds `compat: entry.fetch(:compat, nil)`;
  `boot_model_entry` constructs with `compat: nil`.
- `Render::Chat#apply_thinking_selection`, `footer_data`,
  `Settings.thinking_facts`, the footer/border renderers: UNTOUCHED
  (compat is a wire fact; no screen byte moves).

## 4. Docs (README §Models)

A short compat paragraph + the owner's zai catalog block verbatim
(baseUrl, one glm-5.3 model with the live thinkingLevelMap + compat
from Grounds §3, apiKey elided): what the five keys do, that unknown
compat keys are tolerated, that `$ENV` apiKey references are NOT
expanded (OQ-3 — literal key or `<IDENTITY>_API_KEY`), and that the
fireworks default is unchanged.

## 5. Tests (the pin table)

Additive pins + the three enumerated mechanical re-pins (Spec 1.2):

- `test/schemas_test.rb`: the compat accept/reject table — valid
  subset rows (each of the five keys alone; all five; unknown-key
  tolerance with the owner's catalog object verbatim → NO error), each
  rejection line + path + interleave with an existing error.
- `test/shapes_test.rb`: ModelCompat construction pins (subset
  construction, nil defaults, the enum rejections);
  `Model#compat`/to_h re-pins.
- `test/models_test.rb`: catalog parse pins — a models.json with the
  owner's zai block loads clean; `build_model` yields the typed
  compat (each field); compat absent → nil; the legacy-hash reader.
- `test/agent_loop_test.rb` (the wire pins, MockLLM captured bodies;
  the zai compat object built as Shapes::ModelCompat):
  1. zai + reasoning + level "medium" (the owner's map) → request
     carries `thinking == {"type"=>"enabled","clear_thinking"=>false}`
     and `reasoning_effort == "high"` (medium clamps forward);
  2. zai + level "off" on a map whose off is a String → `thinking ==
     {"type"=>"disabled"}` and NO reasoning_effort key (OQ-5 edge);
  3. zai + `supports_reasoning_effort` false/nil → thinking object
     still emitted, NO reasoning_effort (pi's detected-false default);
  4. zai + tools registered → `tool_stream == true`; the same session's
     tool-less request carries NO tool_stream (pi :861-863);
  5. zai → `messages.first["role"] == "system"` (the rewrite);
  6. zai + a compaction-triggered summarization → that request's
     max-token key is `"max_tokens"` (never `max_completion_tokens`);
     the thinking object rides it too (pi compaction.ts:605-607);
  7. zai non-reasoning → NO thinking object, NO reasoning_effort,
     system role;
  8. compat nil zero-change: NO thinking/tool_stream keys, developer
     role, `max_completion_tokens` on the summarization request —
     today's exact shapes (the wire-bodies digests pin the rig path;
     this pins the loop path);
  9. switch seam: `switch_model(…, compat:)` swaps the dialect — the
     next request carries the zai shape (and compat:nil restores the
     default arm);
  10. print-mode threading: a Print.run-driven request (compat passed)
      carries the zai shape (the I36 third-wire-site idiom).
- `test/chat_test.rb`: the :2290-2305 seam re-pin ONLY (signature +
  expected kwargs gain `compat: nil`) — no other chat_test edit.

## 6. May touch (the ```lanes block is the frozen source of truth)

    lib/tart/schemas/models.rb
    lib/tart/shapes/model.rb
    lib/tart/models.rb
    lib/tart/agent/loop.rb
    lib/tart/print.rb
    lib/tart/render/chat.rb      (apply_model_selection + boot_model_entry ONLY)
    bin/tart                     (boot threading ONLY)
    README.md                    (§Models compat paragraph ONLY)
    test/schemas_test.rb         (additive)
    test/shapes_test.rb          (additive + the 2 enumerated re-pins)
    test/models_test.rb          (additive + the 1 enumerated re-pin)
    test/agent_loop_test.rb      (additive pins only)
    test/chat_test.rb            (the 1 enumerated seam re-pin ONLY)

**Must not touch**: everything else, in particular — `lib/tart/
schemas/{settings,mcp,tools}.rb` + `schemas.rb`, `lib/tart/shapes/
{types,settings,session}.rb` + `shapes.rb` (model.rb is the ONLY
shapes file in scope), `lib/tart/settings.rb`, `lib/tart/agent/{bridge,
session,status,system_prompt,context_files}.rb`, `lib/tart/compaction.rb`,
`lib/tart/tools/**`, `lib/tart/mcp*`,
`lib/tart/render/**` outside the two enumerated methods, `lib/tart/
core/**`, `lib/tart/{commands,identity,skills,prompts,theme,tui}.rb`,
`tart.gemspec`, `Gemfile.lock`, `bench/**`, `gems/tui-split-rig/**`,
`test/support/**`, and every test file outside the five above (the
frozen set: `print_test.rb`, `e2e_session_test.rb`,
`golden_parity_test.rb`, `loop_test.rb`, `tools_test.rb`,
`bash_tool_test.rb`, `session_test.rb`, `mcp_test.rb`,
`flow_test.rb`, `test/render/**`, `test/fixtures/**`).

**Out of scope** (itemized, not lost): pi compat keys beyond the five
(OQ-1 strict, OQ-4 store — tolerated unparsed); URL-based compat
detection (OQ-2); `$ENV`/`!command` apiKey expansion (OQ-3); provider-
level and modelOverrides-level compat (pi has three; the port's subset
is per-model); gem-side changes of any kind (no provider patch — zai
rides the openai seam; upstream PRs are PARKED per the program); any
live z.ai call (Grounds §6 — static + judge-flagged); the fireworks
default or any Settings/DEFAULTS row.

```lanes
- id: zai
  name: zai dialect (catalog compat + the request seam)
  files:
    - lib/tart/schemas/models.rb
    - lib/tart/shapes/model.rb
    - lib/tart/models.rb
    - lib/tart/agent/loop.rb
    - lib/tart/print.rb
    - lib/tart/render/chat.rb
    - bin/tart
    - README.md
    - test/schemas_test.rb
    - test/shapes_test.rb
    - test/models_test.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
```

One lane: the seam files interlock (the struct feeds the parse feeds
the hook feeds the threading) — parallel lanes would collide on the
same files.

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
`architect rehearse zai-provider` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze zai-provider` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse zai-provider` — before the freeze, while
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
subsection per lane. A copy is written to build/I46-zai-provider-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section zai-provider prompt --append --lane <lane> --from build/I46-zai-provider-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I46-zai-provider-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence zai-provider --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section zai-provider verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify zai-provider`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
