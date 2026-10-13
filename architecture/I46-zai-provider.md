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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section zai-provider specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision zai-provider`
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
