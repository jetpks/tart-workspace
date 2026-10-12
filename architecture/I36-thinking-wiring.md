# I36: thinking-wiring

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I36 thinking-wiring (plan-rev2 ENTRY P2)

1. **The defect (owner live run 2026-10-12, space 20261012-tmp-for-pi-testing; BRIEF §7 daily-driver bar).** Same prompt, same model (fireworks `accounts/fireworks/models/glm-5p3-flash`), pi finished in ~3.5 min; the owner killed tart after multi-minute turns. Session traces: tart turn 1 = 45,099 output tokens of which 45,076 thinking, 8m48s wall (`~/.tart/sessions/--Users-eric-architect-spaces-20261012-tmp-for-pi-testing-tart--/2026-10-12T18-45-45-427Z_*.jsonl`); pi same session = 11,764 reasoning tokens turn 1 (2m33s), turns 2+ = 7–727 (`~/.pi/agent/sessions/--...-pi--/2026-10-12T18-45-27-558Z_*.jsonl`; its first assistant entry carries a thinking block of 36,371 chars with `thinkingSignature: "reasoning_content"`). tart turn 2 burned another ~40K re-thinking. **This un-parks the 2026-10-11 ruling "request-side reasoning_effort wiring PARKED (unverified live)"** (ARCHITECT.md decisions log, six-findings entry, item 3): it is now live-verified. The pi trace also records the session's `thinking_level_change` to "high" before the fireworks model switch — pi's level machinery was active end-to-end; tart's never reached the wire.

2. **The param bounds fireworks thinking (live A/B, 2026-10-12, `tmp/repro_thinking_budget.rb`).** Identical small request: no thinking param → 453 completion tokens / 7.7s; `reasoning_effort: "high"` → 24 tokens / 1.0s. The server-default budget is the runaway; the param is the cure.

3. **Live probes run THIS session by the architect (2026-10-12, scripts + raw outputs kept in the space's `tmp/`; FIREWORKS_API_KEY from the environment — the standing credential path, no new paths invented):**
   - `tmp/repro_thinking_replay.rb` / `.out` — raw-HTTP two-turn probe: (S) streaming deltas carry reasoning ONLY under `reasoning_content` (32 delta hits; `reasoning`/`reasoning_text` zero) — fireworks' delta signature is `reasoning_content`, the field pi replays under; (T1) non-streaming replies carry the thinking as `message.reasoning_content`; (T2a/T2b/T2c) the tool-call continuation WITHOUT replay / WITH `reasoning_content` / WITH BOTH `reasoning`+`reasoning_content` all return HTTP 200 today (turn-2 reasoning tokens 4/0/6 at effort "low" on a 30-char turn-1 thinking — noise-level at that scale; the hang-class differential is Grounds 1–2).
   - `tmp/repro_gem_replay.rb` / `repro_gem_replay_effort.out` — through ruby_llm 2.1.0 itself (the exact payload tart ships), run from `repos/tart`'s bundle: `chat.with_thinking(effort: :low)` puts `reasoning_effort: "low"` on the wire (`chat.render`); a follow-up turn after a thinking reply with the gem's NATIVE replay (`format_thinking`'s BOTH fields) completes HTTP 200 — **the I05 400 (`Extra inputs are not permitted, field: 'messages[n].reasoning'`) does NOT reproduce today**. The I05 defect was real and hermetically pinned on 2026-10-10 (test_agent_loop_test.rb:103-119 still scripts that 400 shape); fireworks' request schema now accepts both fields. Interpretation for the spec: replay is live-viable in both shapes; the pi-faithful single-field shape (`reasoning_content` only) is frozen because it is what pi sends, it survived the strict window the gem's `reasoning` field did not, and the live probe shows it accepted.

4. **pi's request-side mechanism (repos/pi 1.1.0, source-verified).** `streamSimple` clamps the session level then derives `reasoningEffort` ("off" → undefined) — openai-completions.ts:745-755. The generic branch (fireworks: `thinkingFormat: "openai"`, `supportsReasoningEffort` true — the compat derivation :1645-1648 excludes only grok/zai/moonshot/together/cloudflare-gateway/nvidia/ant-ling): `params.reasoning_effort = thinkingLevelMap[level] ?? level` when an effort is set (:969-972), and when NO effort (level resolved to off): `reasoning_effort` = the map's `off` value only when it is a String (:973-976). `clampThinkingLevel`/`getSupportedThinkingLevels` (models.ts:1224-1254): a map value of `null` means the level is unsupported; `xhigh`/`max` additionally require an explicit (non-undefined) map entry; an unsupported level clamps forward then backward through the ladder `["off","minimal","low","medium","high","xhigh","max"]` (defaults.ts:4-12 = the port's `Settings::THINKING_LEVELS` order, verified identical). Everything is gated on `model.reasoning` (models.ts:1225).
   - The live catalog (`~/.pi/agent/models-store.json`, fireworks): glm-5p3-flash `thinkingLevelMap = {off: null, minimal: null, low: "low", medium: null, high: "high", xhigh: null, max: "max"}` — supported levels [low, high, max]. The owner's `~/.pi/agent/models.json` override maps every level to a string (off→"low" for glm-5p3-flash; minimal→"low"). Both routes floor "off" to effort "low": the override maps it directly; the catalog does it through the clamp (off unsupported → forward-scan hits low). **pi's resolution code, not assumptions, is the contract to port.** `thinkingLevelMap` is schema-legit on both catalog model definitions and user overrides (model-config.ts:38/:54, `ThinkingLevelMapSchema` = Partial Record over the 7 levels, values String|null — model-schema.ts:14-15).

5. **pi's replay mechanism (source-verified).** Deltas map to thinking blocks keyed by the delta-carried signature ∈ {reasoning_content, reasoning, reasoning_text} (openai-completions.ts:611-627; opencode-go's `reasoning` remaps to `reasoning_content` :623-625). On request, prior assistant thinking is sent back as `assistantMsg[signature]` (joined with "\n") :1340-1352 — unless encrypted `reasoning_details` are preserved. pi records the thinking blocks (with signature) in its session, so resume replays too.

6. **tart's gaps (source-verified at the pre-iteration tip a5c05948).**
   - **No reasoning param is ever sent.** `bin/tart` `build_chat` (:445-458) and `lib/tart/print.rb` (:41) construct the ruby_llm chat with no thinking option; `Agent::Loop` has no thinking-level state. The port HAS the level machinery — settings `thinkingLevel` (settings.rb:45, resolve_thinking_level :141-144), `/thinking` set+cycle+menu (chat.rb:1484-1516, :1597-1605), the footer `model • <level>` segment and the level-driven editor border — but it is display-only; nothing reaches the wire.
   - **The strip wipes thinking everywhere.** `lib/tart/agent/loop.rb:560-580` `strip_thinking_replay` nils `@thinking`/`@raw_reasoning` on every assistant message at the `:step` boundary — the I05 cure for the then-live fireworks 400. Because it runs BEFORE `record`, it also wipes the SESSION FILE: the owner's live tart trace's assistant entries carry `thinking_tokens` but no `thinking` field (verified in the jsonl). So resume replays no thinking, and the recorded display replay has no reasoning rows — while pi's turn-2+ re-think is near zero BECAUSE it replays (Grounds 1).
   - **`Tart::Models` parses no map.** `build_model` (models.rb:146-155) reads {id, name, reasoning, contextWindow, maxTokens}; `chat.rb`'s `available_thinking_levels` (:1501-1503) offers the full 8-level ladder for any reasoning model — the I27 itemized deviation ("xhigh/max never filter").
   - **The owner boots tart with NO catalog** (`~/.tart/` holds sessions only): boot = `Settings::DEFAULTS` (glm-5p3-flash on the fireworks base URL). The known-models tables precedent (settings.rb `MODEL_CONTEXT_WINDOWS` / `MODEL_REASONING`, :70-82 — "ids RubyLLM's registry has no entry for, but the owner's daily-driver catalog declares") exists for exactly this; the map resolution needs the same tier.

7. **ruby_llm 2.1.0's request-parameter surface (gem source, verified this session — the plan's "search the gem before concluding anything is impossible").**
   - `Chat#with_thinking(effort:)` → `render_payload(thinking:)` → `payload[:reasoning_effort] = effort.to_s` (protocols/chat_completions/chat.rb:57, :85-86, `resolve_effort` :385-390): the effort String passes through as-is (mapped values like "low"/"max" work). BUT the no-arg and `false` forms are model-registry-driven (`Thinking::Controls`, thinking.rb:68-118 — raise "does not know how to …" for unregistered models; unusable under the port's `assume_model_exists:` boot), and nothing can RESET `@thinking` to nil once set — so per-turn level changes that resolve to "send nothing" cannot be expressed through `with_thinking` alone.
   - **`Chat#before_request(&block)` (chat.rb:909-914) is the seam**: hooks run LAST in `Protocol#render` (protocol.rb:143-155), after provider_options merge, mutating the payload Hash in place (symbol keys — `apply_before_request_hooks` protocol.rb:695-698) right before serialization; both the streaming and sync paths use the rendered payload (protocol.rb complete :100-135). One hook installed at chat construction can (a) set/delete `payload[:reasoning_effort]` from the loop's CURRENT level+map (always fresh — no gem state to reset), and (b) delete `payload[:messages][n][:reasoning]` on assistant entries (the replay-field normalization; `format_thinking` :417-431 sets BOTH `:reasoning` and `:reasoning_content`).
   - Replay/rebuild chain: `Message#to_h` serializes `thinking` (message.rb:268-269) so the recorder persists it once the strip is gone; `Message.new` coerces a String thinking back (message.rb:323-330) so resume seeding replays it; `format_message` merges `format_thinking` into every assistant wire message (chat.rb:329). The gem does NOT record which delta field reasoning arrived under (streaming.rb:28 merges `reasoning_content || reasoning`) — pi's per-signature replay is not recoverable through the gem; the port pins the replay field to `reasoning_content` (the delta-carried field for the daily driver, live-verified Grounds 3; itemized deviation).
   - The MockLLM already captures parsed request bodies (`MockLLMServer#captured_requests`, test/support/mock_llm_server.rb:81-86) — the request-pin instrument; no server change needed for assertions.

8. **Scope rulings baked here (plan letter + standing deviations discipline).** In: OpenAI-compat `reasoning_effort` (the fireworks/daily-driver shape), the map parse + pi's clamp/off-floor resolution, pi's replay protocol replacing the strip, the surface→loop seam, the menu ladder gating by supported levels (retires the I27 deviation), request pins per level, a session-recording pin, rig staging symmetry. CUT, itemized: pi's other thinking dialects (zai `thinking:{type…}`, deepseek, together, openrouter, ant-ling, string-thinking — openai-completions.ts:880-966: different request shapes for providers the port's hand-authored catalog does not target; fireworks needs none of them); `thinkingBudget` fields and `samplingParamsByThinkingLevel`; encrypted `reasoning_details` preservation (no provider payload for it here); the thinking-UX render slice (spinner/markdown — plan ENTRY P3, next); `with_thinking(false)` off-controls (registry-driven, unusable — the off resolution is the port's own, Grounds 4).

9. **Pins that flip meaning this iteration (fix the pin, not the property).** `test/agent_loop_test.rb` `test_thinking_replay_is_suppressed_on_followup_requests` (:130-152) asserts BOTH reasoning fields stripped — its property becomes "replayed under `reasoning_content`, `reasoning` absent, continuation completes". The scripted-400 worker-error test (:103-119) is untouched (the error path stays the error path). `chat.rb:218-221`'s comment cites `strip_thinking_replay` — re-pointed at the request-seam normalization.

10. **Control (this session, repos/tart @ a5c05948, clean tree).** Suite: `667 runs, 2746 assertions, 0 failures, 0 errors, 1 skips` (matches the I35 verdict); `SEAM_BENCH_OK`. s1–s9 exit 0 cold per the I35 close; the rehearse pass re-runs every gate at base. Settled screens do not move in this iteration (the wire param changes no rendering; the rig staging change adds catalog keys both apps tolerate).

11. **Non-goals.** Grounds 8's cuts; the I27 env-boot ✓/· marker residual; compaction arithmetic changes; protocol work beyond chat-completions; session-format changes beyond thinking now persisting (Message#to_h's existing key); footer/border visual changes (the level ladder already renders); any MockLLM wire-shape change beyond what request-pinning tests need (the server already captures bodies).

## Specification

# Specification — I36 thinking-wiring

- **Objective.** Close the live-run hang (Grounds 1; BRIEF §7): the resolved thinking level must reach the wire — for OpenAI-compat providers, `reasoning_effort` resolved through the model's `thinkingLevelMap` exactly as pi's generic branch does (clamp, off-floor, non-reasoning sends nothing; Grounds 4) — and the I05 `strip_thinking_replay` deviation is replaced by pi's replay protocol: prior assistant thinking persists (memory, session file, resume) and replays on later requests under the provider-accepted field (`reasoning_content`), with ruby_llm's duplicate `reasoning` field dropped at the request seam (Grounds 3/5/7). Settled screens must not move: s1–s9 stay exit 0 cold (Grounds 10).

- **Port shape (single-writer agent-side slice; one lane).**

  - **`Tart::Models` (lib/tart/models.rb) — the map + pi's resolution, pure functions.**
    - `build_model` parses `thinkingLevelMap` from models.json entries: hash of level-name → String|nil, symbolized keys (`:thinking_level_map`); `validate_model_fields` gains the shape check (hash; values String or null; unknown level keys tolerated — pi's Partial-Record default, Grounds 4).
    - `supported_thinking_levels(map:, reasoning:)` → Array (pi getSupportedThinkingLevels, models.ts:1224-1233): `["off"]` when not reasoning; else the ladder filtered — a `nil` (null) map value means unsupported, `xhigh`/`max` require a present (non-nil) entry.
    - `clamp_thinking_level(level, map:, reasoning:)` → String (pi clampThinkingLevel, models.ts:1235-1254): exact level if supported; else forward-then-backward scan through `Settings::THINKING_LEVELS` order; unknown level → first supported, else `"off"`.
    - `resolve_reasoning_effort(level, map:, reasoning:)` → String|nil (pi openai-completions.ts:745-755 + :969-976): nil unless reasoning; clamped = clamp(level); `nil` (send nothing) when clamped == "off" and the map's `off` is not a String; else the map's value for the clamped level, falling back to the level itself (`map[clamped] || clamped`), and for clamped "off" the map's String `off` value.
  - **`Settings` (lib/tart/settings.rb) — the known-models tier.** `THINKING_LEVEL_MAPS` beside `MODEL_CONTEXT_WINDOWS`/`MODEL_REASONING` (same documented class — ids with no registry entry that the owner's daily-driver declares): glm-5p3-flash → the owner's effective pi map (every level a String: off→"low", minimal→"low", low→"low", medium→"medium", high→"high", xhigh→"xhigh", max→"max" — Grounds 4's both-routes-floor rule; the out-of-box boot then never sends nothing on this model). `known_thinking_level_map(model_id)` reader. The boot facts compose catalog-entry-first, known-tables-second (one helper, used by `bin/tart` interactive boot, `lib/tart/print.rb` boot, and the switch path): reasoning = entry's flag when a catalog entry exists, else `Settings.model_reasoning_capable`; map = entry's map when present, else the known table.
  - **`Agent::Loop` (lib/tart/agent/loop.rb) — the request seam.** Constructor kwargs `thinking_level:` (String, default `"medium"` — pi DEFAULT_THINKING_LEVEL), `model_reasoning:` (Boolean), `thinking_level_map:` (Hash|nil); `attr_reader :thinking_level`; public `set_thinking_level(level)` (stores; the surface calls it); `switch_model` gains `model_reasoning:`/`thinking_level_map:` kwargs re-resolving the facts alongside the window (the I27 seam's shape). At construction the loop installs ONE `@chat.before_request` hook (Grounds 7 — the gem seam; runs last, mutates the symbol-keyed payload in place): (a) `effort = Models.resolve_reasoning_effort(@thinking_level, map: @thinking_level_map, reasoning: @model_reasoning)` → `payload[:reasoning_effort] = effort` or `payload.delete(:reasoning_effort)`; (b) replay normalization: each assistant entry in `payload[:messages]` loses `:reasoning` (ruby_llm's duplicate field; `:reasoning_content` stays — pi's signature replay, Grounds 5/7). Reading the level at request time means mid-session changes apply to the NEXT request with no gem state to reset. **`strip_thinking_replay` is DELETED** with its comment block (the deviation note moves to the hook; Grounds 6): recorded assistant messages keep their thinking — the session file (`Message#to_h` already serializes it), resume replay, and the display replay all regain it. `with_thinking` is never called (its no-arg/false forms are registry-driven and unusable under `assume_model_exists:`; its set-state cannot be unset — Grounds 7).
  - **`Render::Chat` (lib/tart/render/chat.rb) — the surface seam.** `apply_thinking_selection` additionally calls `@agent&.set_thinking_level(level)` (the `/thinking` command, shift+tab cycle, and the menu all land there); `available_thinking_levels` gates by pi's rule through `Models.supported_thinking_levels` using the runtime map — `footer_data` gains the boot map and the `@runtime_model` switch overlay carries the entry's map (retiring the I27 "xhigh/max never filter" deviation; the no-map fallback = pi's map-less rule: off..high, Grounds 4); `apply_model_selection` passes the switched entry's `model_reasoning:`/`thinking_level_map:` into `switch_model` (known-table fallback for the degenerate boot entry). The chat.rb:218-221 comment citing `strip_thinking_replay` re-points at the request-seam normalization (Grounds 9). No render/byte changes: the level ladder, footer, border, and status rows render exactly as today.
  - **`bin/tart` + `lib/tart/print.rb` — boot wiring.** Both `Agent::Loop.new` sites pass `thinking_level: Settings.resolve_thinking_level(settings)` plus the composed facts; `footer_data` gains the resolved `thinking_level_map` (the surface's ladder source). `build_chat` itself is unchanged.
  - **Rig staging symmetry (gems/tui-split-rig/lib/tui_split_rig/runner.rb).** The staged models.json mock-2 entry (reasoning:true — both apps' staging sites, `stage_pi_agent`/`stage_tart_home`) gains the same full-string `thinkingLevelMap`; mock-1 (reasoning:false) stays map-less. Inert for the pinned scenarios (settled screens unchanged — the param changes no rendering), keeps the parity environment exercising the same catalog shape both sides. No new scenario, no registry change.
  - **README.** Document `thinkingLevelMap` in the models.json schema note + the wire behavior (level → reasoning_effort via the map; off-floor on models that cannot turn thinking off).

- **Tests (the deterministic proof; MockLLMServer's captured request bodies are the instrument — Grounds 7).**
  1. `test/models_test.rb`: thinkingLevelMap parse (string/null values, symbolized) + validation errors; the resolution table as direct-function cases — the owner's override map (off→"low" floor, medium→"medium"), the live-catalog map ({off:null,…} → off floors to "low", minimal clamps to "low", medium clamps to "high", xhigh clamps forward to "max"), map-less (off sends nothing; xhigh/max clamp down to "high"), non-reasoning (no level ever sends), `supported_thinking_levels` per shape (the menu ladders).
  2. `test/agent_loop_test.rb`: surgery on `test_thinking_replay_is_suppressed_on_followup_requests` → the replay protocol pin (follow-up request bodies carry the assistant `reasoning_content`, NOT `reasoning`; the tool-continuation completes); NEW request pins through the real chat: `reasoning_effort` present with the resolved value per level (drive `set_thinking_level` between turns — the NEXT request changes); the off-floor (map with off:null → "low"); non-reasoning facts → NO `reasoning_effort` key; `switch_model` re-resolves the map; the scripted-400 worker-error test untouched. NEW session pin: a thinking reply's recorded entry in the session file carries the thinking text (no strip).
  3. `test/chat_test.rb`: `set_thinking_level`/cycle reaches an injected agent seam (spy); `available_thinking_levels` gates by the runtime map (footer_data/boot + switch overlay).
  4. `test/settings_test.rb`: `known_thinking_level_map` + the composition helper's tiering (catalog entry wins; known table when absent).
  5. Additive only elsewhere; existing pins that flip meaning are re-pointed, not deleted (Grounds 9).

- **Output format.** Raw evidence to scratch: file list + wc; the new/changed test list with verbatim run tails; suite counts before/after; the s1–s9 exit codes; the PHASE 0 disagreement list (the Grounds 3-8 premises are checkable against repos/pi + the gem — cite what you read). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s9 must stay exit 0 in YOUR tree — SHORT out-dirs; allow 60 s+ each, both apps boot). pi sources: `packages/ai/src/api/openai-completions.ts` (:745-755 clamp→effort, :969-976 the generic branch, :611-627 delta signatures, :1340-1352 replay), `packages/ai/src/models.ts` (:1224-1254 supported/clamp), `packages/coding-agent/src/core/defaults.ts` (:4-12 ladder order), `model-config.ts` (:38/:54 map schema). The gem (ruby_llm 2.1.0): `protocols/chat_completions/chat.rb` (:57/:85-86 render_payload effort, :329 format_message, :417-431 format_thinking), `protocol.rb` (:143-155/:695-698 hook application), `chat.rb` (:909-914 before_request, :669-687 with_thinking), `thinking.rb` (Controls — why with_thinking()/false are unusable), `message.rb` (:258-279 to_h, :323-330 coerce_thinking). The live probes for reference: the space's `tmp/repro_thinking_budget.rb`, `tmp/repro_thinking_replay.rb`(.out), `tmp/repro_gem_replay.rb` — do NOT re-run them live (cost; the recorded outputs are the evidence). Read loop.rb's switch_model + chat.rb's apply_thinking_selection/available_thinking_levels/footer_data before designing.

- **Boundaries.** May touch exactly: `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/agent/loop.rb`, `lib/tart/render/chat.rb`, `lib/tart/print.rb`, `bin/tart`, `test/models_test.rb`, `test/settings_test.rb`, `test/agent_loop_test.rb`, `test/chat_test.rb`, `README.md`, `gems/tui-split-rig/lib/tui_split_rig/runner.rb`. Must not: `lib/tart/agent/{bridge,session,status,system_prompt,context_files}.rb` (session recording rides Message#to_h unchanged), `lib/tart/render/{transcript,footer,editor,motd,viewport,selection,model_menu,picker,autocomplete,kill_ring,text,panel,user_bash,bash_block,file_blocks,tool_block,markdown,slash_source}.rb`, `lib/tart/{compaction,commands,identity,prompts,skills,theme,tools}.rb`, `lib/tart/tools/**`, `lib/tart/core/**`, `lib/tart/mcp*`, `test/support/mock_llm_server.rb` (it already captures bodies; no server change needed), `bench/**`, `gems/tui-split-rig/{bin,test}/**`, any scenario yml, `gems/tui-split-rig/registry.yml`, any golden. Out of scope: Grounds 8/11's cuts (pi's other thinking dialects, budget fields, encrypted reasoning_details, the thinking-UX render slice, with_thinking off-controls). No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/models.rb
    - lib/tart/settings.rb
    - lib/tart/agent/loop.rb
    - lib/tart/render/chat.rb
    - lib/tart/print.rb
    - bin/tart
    - test/models_test.rb
    - test/settings_test.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
    - README.md
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
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
`architect rehearse thinking-wiring` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze thinking-wiring` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse thinking-wiring` — before the freeze, while
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
subsection per lane. A copy is written to build/I36-thinking-wiring-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section thinking-wiring prompt --append --lane <lane> --from build/I36-thinking-wiring-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I36-thinking-wiring-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence thinking-wiring --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section thinking-wiring verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify thinking-wiring`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
