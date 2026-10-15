# I59: zai-max-tokens

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### §0 — plan entry + cite verification (PHASE −1, re-verified at `9b04d0d` this session)

Plan ENTRY A of notes/plan-20261014T195224Z.md (`zai-max-tokens` — successor
program rev4, first entry; the total outage of the owner's default provider).
The coordinator's PHASE −1 recon (2026-10-15) held: no entry work pre-done,
no named file gone, no API reshaped by rev3 ENTRY D/E. The plan's cites were
re-verified against the integrated tip `9b04d0d` this session and the moved
line numbers are recorded (the plan's cites were authored against `41f0a5f`):

- bin/tart interactive boot `context_window:` now :458; the `compat:`
  resolve_boot_entry threading now :464; `def resolve_boot_entry` :682-684;
  the print boot (`Models.resolve_boot_model` :278, `build_chat` :279,
  `boot_thinking_kwargs` :280 → `Print.run` :308) threads compat via
  `**thinking` (:669-676) but no window/cap.
- lib/tart/agent/loop.rb: ctor `MODEL_CONTEXT_WINDOWS.fetch` arm :158-161;
  `def switch_model` :300 (kwarg list :302-303 — STILL no `max_tokens:`;
  the resolved-window apply_facts :318-324); `def summarization_max_tokens`
  :643-647; `record_terminal_error` :684.
- lib/tart/agent/chat.rb: placeholder `apply_facts(context_window: nil)` :61;
  `def apply_facts` :163-182 — ALREADY carries a `max_tokens:` kwarg (default
  nil) that NO caller passes today; `def summary_chat` :188-197 threads
  `context_window: @facts.context_window` but no cap.
- lib/tart/models.rb: `def wire_model` :124-139 (`max_tokens: max_tokens ||
  context_window` — the window fallback :130); `def build_model` :225-238
  (loads maxTokens into `Shapes::Model`, consumed by NOTHING on the wire).
- lib/tart/render/chat.rb: `def switch_model` :2147; `def
  apply_model_selection` :2204-2240 (the `@agent&.switch_model(...,
  context_window: entry.context_window, ...)` call :2233-2237 — the ONE seam
  that threads the catalog window, and it drops `entry.max_tokens`).
- lib/tart/agent/session.rb `def append_message` :438 (read for context; NOT
  touched by this entry — that is ENTRY B error-transcript's seam).
- The gem clamp is EXACT at the current layout:
  repos/fast-llm gems/completions/lib/fast/completions/protocol.rb:59-67
  `clamp_max_tokens` — `requested = max_tokens || model.max_tokens`; `nil
  only when both nil`; `context_window <= 0` → `[1, requested].max`;
  else `[requested, [1, window − Codec.estimate_tokens(instructions,
  messages) − 4096].max].min`. The gem is NOT touched (owner ruling — rev4
  is tart-side threading only).
- The deterministic repros (all offline, this space): tmp/
  repro_max_tokens_20261014.rb (window-fallback 985K vs catalog cap), tmp/
  repro5_wire.rb (placeholder wire 0/0 → clamp sends 1), tmp/
  repro6_workaround.rb (PI_CONTEXT_WINDOW=120000 → ~105K LEGAL).

No premise invalidation: every mechanism claim in the plan entry reproduced
against `9b04d0d` (the repros run clean; the boot chain reads exactly as
itemized below).

### §1 — the defect chain (every link re-verified at `9b04d0d`)

Both faces of one defect — the boot threads NONE of the catalog entry's
facts, and the one seam that threads the window still drops the cap:

1. **Face 2 (one-token responses, run 2, 2026-10-14T19:58Z).** The
   interactive boot (bin/tart :448-465) passes `context_window:
   Settings.resolve_context_window(settings:, model: chat.model, identity:)`
   — but `chat.model` at that moment is the CONSTRUCTOR PLACEHOLDER
   (agent/chat.rb :61: `apply_facts(..., context_window: nil)`), whose
   ModelFacts carry `context_window: nil` (chat.rb :175-181). Every tier
   misses: explicit nil → env unset → no settings contextWindow →
   placeholder nil → `MODEL_CONTEXT_WINDOWS` has no "glm-5.3"
   (settings.rb :104-106). The Loop ctor (:158-161) then applies
   `resolved_context_window || Settings::MODEL_CONTEXT_WINDOWS.fetch(
   @chat.model_id, 0)` → **0**; `Chat#apply_facts` → `Models.wire_model`
   (models.rb :124-139) builds the gem Model with `context_window: 0,
   max_tokens: nil || 0` → **0**; the gem clamp (protocol.rb :63-64)
   `context_window <= 0` → `[1, 0].max` = **max_tokens: 1 on every
   request**. Reproduced offline end-to-end (tmp/repro5_wire.rb).
2. **Face 1 (the live 400, run 1, 2026-10-14T19:39Z — the /model seam).**
   The TUI's model selection (render/chat.rb :2204-2240 — the /model menu's
   on_select AND `/model <ref>` via switch_model :2147) is the ONE place the
   catalog window reaches the wire: `@agent.switch_model(entry.id, provider:,
   context_window: entry.context_window, ...)` (:2233-2237) → Loop#
   switch_model :300-325 → the explicit tier wins → wire window 1,000,000,
   but **max_tokens is STILL unthreaded** (loop.rb :302-303 has no such
   kwarg) → `Models.wire_model` falls back `max_tokens: nil || 1_000_000` →
   the gem clamp sends ~1M − est − 4096 ≈ 985K → z.ai rejects ("限制数值
   范围[1,131072]"). Owner CONFIRMED 2026-10-14T20:5xZ: run 1's model was
   picked via /model; run 2 booted plain (items above). z.ai accepts
   max_tokens 1 with thinking enabled (run 2 streamed it) — the two faces
   are mutually discriminating, and both are pinned.
3. **The orphaned cap.** models.json `maxTokens` (the owner's live catalog:
   131072 for glm-5.3) is loaded by `build_model` (models.rb :225-238) and
   consumed by NOTHING — the only `.max_tokens` readers hit the gem wire
   model (verified by grep this session; wire_model's fallback :130 is the
   sole construction site). The original Face-0 finding
   stands.

### §2 — the measured parity delta (this session, base `9b04d0d`, the s1 rig)

The rig stages BOTH apps with the same catalog (mock-1: contextWindow
32768, maxTokens 512 — runner.rb :244/:295) AND exports
`PI_CONTEXT_WINDOW`/`TART_CONTEXT_WINDOW`=32768 for tart (runner.rb :489).
Measured cold this session (`tmp/i59-spec-wire/`, s1_text_turn, exit 0):

| | tart @ 9b04d0d | pi @ f1b2e77f |
|---|---|---|
| request max key | `max_completion_tokens` | `max_completion_tokens` |
| request max value | **27841** (env window 32768 − est − 4096; cap un-threaded window-fallback) | **512** (catalog cap, min'd with the clamp) |

Same key, same key order, divergent VALUE — a live wire divergence between
the apps in EVERY rig scenario today (tart threads none of the model's
facts; pi threads the model's cap everywhere). The s7/s8 tiny-window
scenarios (context_window: 10) send 1 from BOTH apps (available floors at
1) — unchanged by this iteration. This measurement is the delta the cure
moves (Specification §D-deviation): threading the catalog cap moves tart's
s1 wire value 27841 → 512 = pi's byte exactly. The standing frozen anchors
(key set/order, instruction digest `2faaf667…`, tools digest `7360fd1e…`,
all session goldens, settled screens) pin NONE of the max VALUE — the
wire-delta gate asserts the key's presence and positivity only — so the
battery holds while the value moves TOWARD pi.

### §3 — pi's letter (verified against pi @ f1b2e77f, not assumed)

The plan ordered the precedence verified against pi sources. Findings:

1. **pi has NO env and NO settings context-window/max-tokens override.**
   grep over pi packages (no CONTEXT_WINDOW env anywhere outside eval
   fixtures; settings-manager/settings-defaults carry no window/maxTokens
   keys; model-resolver.ts carries no window/maxTokens handling). The
   custom model's contextWindow/maxTokens ARE the model's facts, sourced
   only from the model definition.
2. **The definition defaults** (provider-composer.ts modelFromJson :242-243):
   `contextWindow: definition.contextWindow ?? 128000`, `maxTokens:
   definition.maxTokens ?? 16384` — applied at model-DEFINITION time, i.e.
   only for models a models.json DECLARES. Built-in/registry models carry
   their registry facts; a models.json override merges per-key
   (`override.contextWindow ?? model.contextWindow`, :190-198).
3. **The request seam** (the gem is the byte-port): simple-options.ts :19-23
   `clampMaxTokensToContext(model, context, options?.maxTokens ??
   model.maxTokens)` → `min(requested, window − est − 4096)` floored at 1;
   openai-completions.ts :842-847 sends the key iff truthy. The AGENT
   passes no options.maxTokens for normal turns (agent-loop.ts sets none);
   the value on the wire is the MODEL's cap, clamped. For the owner's
   glm-5.3 (window 131072, maxTokens 131072, server-counted input 8,267):
   min(131072, 131072 − est − 4096) ≈ 118K — legal, and > 1 (the cure's
   arithmetic, reproduced by tmp/repro_max_tokens_20261014.rb).
4. **The compaction one-shot** (compaction.ts :712-714): `min(floor(0.8 ×
   reserveTokens), model.maxTokens > 0 ? model.maxTokens : ∞)` — tart's
   `summarization_max_tokens` (loop.rb :643-647) is already this exact
   formula; it reads `@chat.model&.max_tokens` (ModelFacts), so it needs NO
   change — it "rides the same threading" by the ModelFacts populating.

### §4 — the rulings the plan ordered (a/b/c) + the deviation declared

**(a) Precedence — the catalog entry slots at the MODEL tier, BELOW tart's
env and settings tiers, ABOVE the known-tables.** pi's only source is the
model definition (§3.1); tart's `<IDENTITY>_CONTEXT_WINDOW` env tier and
settings `contextWindow` tier are pre-existing tart extensions (I30/I41)
that the rig staging (runner.rb :489), the owner's documented workaround
(`PI_CONTEXT_WINDOW=120000`), and the subagent child env passthrough
(subagents/manager.rb :383) all depend on — they STAY above the catalog.
The catalog tier fills exactly the hole the placeholder leaves: today the
`model&.context_window` tier in `Settings.resolve_context_window`
(settings.rb :176-189) reads the placeholder's nil at boot; after this
iteration the boot threads the resolved catalog window below env/settings.
The known-tables tier (`MODEL_CONTEXT_WINDOWS`) and the 0 fallback stay —
they are the NO-ENTRY tiers (ruling b).

**(b) No-entry fallback — today's chain stays EXACTLY.** When the boot
model has NO catalog entry (env-tier model id not in models.json —
`resolve_boot_entry` nil): window = env → settings → known-tables → 0
(unchanged); cap = nil → `Models.wire_model`'s window fallback
(`max_tokens: max_tokens || context_window`, models.rb :130 — pinned by
settings_test's wire_model helper) — unchanged. The Face-2 max_tokens:1
shape remains reachable ONLY here (no entry, no env, no settings, no table
row) — declared and pinned as the fallback, no longer the DEFAULT-model
path (the outage).

**(c) Undeclared-maxTokens fallback — pi's 16384, never the window.** When
a catalog ENTRY exists but declares no `maxTokens`, the cap is pi's
modelFromJson default **16384** (provider-composer.ts :243), NOT the window
fallback — the window fallback with a big declared window is exactly what
400'd Face 1. Same clause, same ruling for the window: an entry that
declares no `contextWindow` carries pi's **128000** (provider-composer.ts
:242). The defaults apply ONLY where an entry EXISTS (pi applies them at
definition time; a no-entry boot has no definition and keeps ruling b's
chain). The defaults live at the FACTS-THREADING seam (a `Models` helper),
NOT at catalog load (`Shapes::Model#to_h`'s DECLARED == parsed-entry pin,
shapes_test :33-56, must hold) and NOT inside `Settings
.resolve_context_window` (its frozen ladder pins hold).

**The declared deviation (itemized for the judge, the I52 delta-audited
bar).** The plan's standing rule "no wire byte of an EXISTING scenario may
move" collides with the deliverable: threading the catalog cap moves the
`max_completion_tokens` VALUE in every existing rig scenario (s1 measured:
27841 → 512, Grounds §2) — and 512 is pi's byte for the identical staged
catalog. The rule's intent (parity + frozen anchors) is SERVED by the
move: the frozen anchors (key set/order, instruction digest, tools digest,
session goldens, settled screens, s17 replay captures) all hold EXACT —
none pins the max value — and the wire VALUE becomes byte-IDENTICAL to pi.
The deviation is frozen here, re-stated in the Acceptance Criteria, and
gated by a NEW gate (zai-max-tokens-wire) that pins the AFTER value on
BOTH apps; no existing gate letter is edited.

**Scope discipline.** The gem (repos/fast-llm) is NOT touched. No rig
runner/scenario/registry/golden file is touched (the rig already stages
the catalog both sides — the cure needs no new staging). No new wire keys:
the request key set and order are byte-frozen; only the VALUE of the
existing max key moves (toward pi). The owner's `PI_CONTEXT_WINDOW`
workaround keeps working (env tier above catalog — repro6's shape
verified); no code depends on it.

## Specification

### Objective

Close successor-rev4 ENTRY A: BOTH faces of the catalog-facts outage — the
boot that threads NONE of the catalog entry's facts (Face 2: window 0/0 →
`max_tokens: 1` on every request, one-token responses) and the /model
switch seam that threads the window but drops the cap (Face 1: window
fallback ≈ 985K → z.ai 400). The model's catalog facts (contextWindow +
maxTokens) reach the wire model on EVERY construction path — boot
(interactive + print) and switch — with pi's precedence and pi's
undeclared-field defaults. Screen bytes, session bytes, wire key
set/order, and every frozen digest anchor are unchanged; the ONE
deliberate byte-level move is the max VALUE in existing rig scenarios
toward pi's exact byte (Grounds §2/§4, gated).

### The deliverables

**D1 — the entry-facts helpers (pi's definition defaults, one seam).**

`Tart::Models` gains two pure helpers over the typed entry
(`Shapes::Model` or nil):

- `Models.entry_context_window(entry)` — `entry.context_window` when the
  entry declares one, else pi's modelFromJson default **128_000**
  (provider-composer.ts :242) when an entry EXISTS, else **nil** (no
  entry: the no-entry chain of Grounds §4-b owns the window).
- `Models.entry_max_tokens(entry)` — `entry.max_tokens` when declared,
  else pi's default **16_384** (provider-composer.ts :243) when an entry
  EXISTS, else **nil**.

The defaults ride the FACTS-THREADING seam only — NOT catalog load
(`Shapes::Model#to_h` stays DECLARED == the parsed entry, key order
included; shapes_test :33-56 holds) and NOT `Settings
.resolve_context_window` (its frozen ladder + pins hold; the helper
threads BELOW env/settings — Grounds §4-a). Constants named + frozen
here: `DEFAULT_ENTRY_CONTEXT_WINDOW = 128_000`,
`DEFAULT_ENTRY_MAX_TOKENS = 16_384`, with the pi cites in the comment.

**D2 — `Agent::Loop` ctor threads the cap.**

The ctor (agent/loop.rb :112-113) gains `max_tokens: nil`; stored
`@max_tokens`; the ctor's `apply_facts` call (:158-162) threads
`max_tokens: @max_tokens` beside the resolved window. The window
expression `resolved_context_window || Settings::MODEL_CONTEXT_WINDOWS
.fetch(@chat.model_id, 0)` is byte-unchanged (the known-tables/0 tiers
are the no-entry chain). The kwarg doc follows the existing
`@param context_window` shape.

**D3 — the interactive boot threads the entry's pair (bin/tart).**

In `start_session` (bin/tart :448-465): the entry the `compat:` arm
already resolves (`resolve_boot_entry(models, boot)` :464) is resolved
ONCE into a local BEFORE the `Agent::Loop.new` (one call site, same
helper, no behavior change to the resolve), and the ctor call threads:

```ruby
context_window: Settings.resolve_context_window(settings:, model: chat.model, identity:) ||
  Models.entry_context_window(entry),
max_tokens: Models.entry_max_tokens(entry),
compat: entry&.compat
```

Precedence frozen (Grounds §4-a): env → settings → CATALOG →
known-tables → 0. `resolve_context_window` already folds env+settings;
the catalog value threads only when both miss; the loop's fetch arm
catches the no-entry case. `chat.model` stays the constructor
placeholder in that call (its nil window is what makes the `||` chain
correct).

**D4 — the print boot threads the same pair.**

`Tart::Print.run` (print.rb :72-79) gains `max_tokens: nil`, forwarded
to the `Agent::Loop.new` (:86-88). The print boot (bin/tart :278-309)
resolves the entry via the same `resolve_boot_entry` helper and threads
the same pair as D3 (`context_window:` = `Settings
.resolve_context_window(...) || Models.entry_context_window(entry)`).
The frozen comment's contract ("env tier resolves
`<IDENTITY>_CONTEXT_WINDOW` itself") is preserved in outcome — resolve
checks the env tier FIRST, so a set env still wins; the update to the
comment states the new truth. Subagent children (CONTEXT_WINDOW env
passthrough, subagents/manager.rb :383) are unaffected: their env rides
the same folded tier.

**D5 — `Loop#switch_model` threads the cap (the Face-1 seam).**

The signature (:302-303) gains `max_tokens: nil` (after
`context_window:`); `@max_tokens = max_tokens`; BOTH `apply_facts` calls
(:310-313 pre-resolve, :318-324 resolved) thread
`max_tokens: @max_tokens`. The WINDOW threading is byte-unchanged (raw
`context_window:` kwarg + the loop's re-resolution ladder — its I30
known-tables pins hold).

**D6 — the render switch seam passes the cap.**

`apply_model_selection` (render/chat.rb :2204-2240) adds
`max_tokens: Models.entry_max_tokens(entry)` to the
`@agent&.switch_model(...)` call (:2233-2237); `context_window:
entry.context_window` stays RAW (today's exact shape). Declared
asymmetry, itemized: BOOT threads the defaulted window (windowless entry
→ 128_000), SWITCH threads the raw window (windowless entry → the loop's
env/known-tables re-resolution, today's behavior) — the minimal change;
pi's setModel carries the definition's default, recorded as a declared
divergence reopenable on owner pain (switching to a windowless ENTRY
with no env/table row).

**D7 — `Chat#summary_chat` mirrors the cap.**

The compaction one-shot factory (agent/chat.rb :188-197) threads
`max_tokens: @facts.max_tokens` beside `context_window:
@facts.context_window` — the one-shot's wire model mirrors the session
model exactly. `summarization_max_tokens` (loop.rb :643-647) needs NO
change (Grounds §3.4: it is already pi's formula, and ModelFacts
populates from the threaded facts).

**D8 — declared re-pins (no assertion semantics weakened).**

- test/chat_test.rb: the switch-family agent doubles' `switch_model`
  signatures (:2667, :2896 and any sibling asserting exact kwargs) gain
  the `max_tokens:` kwarg with the expected `Models.entry_max_tokens`
  value; the screen assertions stay verbatim.
- test/settings_test.rb's `wire_model` helper (:31-36) NEEDS NO change
  (the no-entry fallback is its shape) — listed so the builder verifies
  rather than re-pins.
- Any further suite pin asserting the boot/switch construction kwargs or
  the wire max value: re-pin per the standing discipline (grep inventory
  first, itemize every re-pin in the report). Known-touched files are in
  the touch set; anything outside it is a deviation to itemize.

**D9 — the new pins (the plan's verification beyond the battery).** All
new test names carry the `zai_max_tokens` filter token; the filter is
verified EMPTY at base (`grep -rn zai_max_tokens test/` → nothing).

- **P1 boot-shaped unit** (test/agent_loop_test.rb): a placeholder-shaped
  `Agent::Chat` (mock client) + `Agent::Loop.new(context_window: 131_072,
  max_tokens: 131_072, reasoning/compat kwargs)` — assert the wire model
  (`chat`'s `@model`) carries `context_window == 131_072` and
  `max_tokens == 131_072`; run one scripted turn; assert the captured
  request body's max value `== Fast::Completions::Protocol
  .clamp_max_tokens(<that wire model>, <the request's instructions>,
  <the request's messages>, nil)` (the gem's own arithmetic on the same
  inputs — exact, path-independent) AND `> 1`. This is the plan's pin
  (1): `min(catalog cap, window − est − 4096) > 1`.
- **P2 no-entry fallback unit** (test/agent_loop_test.rb): (i) env tier —
  no entry kwargs, `PI_CONTEXT_WINDOW=120000` in ENV around construction:
  wire window 120_000, wire max 120_000 (the window fallback), clamp
  output ≤ 120_000 − 4_096 (the workaround's verified shape,
  tmp/repro6_workaround.rb); (ii) no env, id in no table: wire 0/0 and
  the request max value `== 1` — the declared no-entry fallback (the
  Face-2 shape, now confined to entry-less boots; Grounds §4-b).
- **P3 the Face-2 regression bar at the REAL boot**
  (test/launcher_smoke_test.rb, real `bin/tart -p` subprocess, staged
  HOME, MockLLMServer): (i) catalog leg — staged `~/.tart/models.json`
  (provider `mock`, baseUrl = the mock server, model `glm-5.3`
  contextWindow 131_072 maxTokens 131_072, `default: "mock/glm-5.3"`),
  NO context-window env: the captured request's max value is an Integer
  in `(120_000, 131_072]` — never 1 (the harness prompt's estimate is
  checkout-depth-sensitive, so the range is the path-robust exact bar;
  Face 2 sends exactly 1 — five orders of magnitude of discrimination);
  (ii) no-entry leg — no models.json, `PI_MODEL=custom-x
  PI_PROVIDER=openai` (env-tier boot), no context-window env: the
  request max value `== 1` (today's chain, pinned at the real boot).
- **P4 the Face-1 bar** (test/agent_loop_test.rb):
  `Loop#switch_model("glm-5.3", provider: "zai", context_window:
  131_072, max_tokens: 131_072, compat: <zai>)` → wire carries both; the
  clamped send value `<= 131_072` (the 985K face can never recur) and
  `> 1`.

**D10 — the wire-value gate (the deliverable's parity pin).**

NEW gate `zai-max-tokens-wire` (declared-RED at base with the measured
numbers, Grounds §2): run s1 via the rig, parse BOTH apps' first request
bodies, assert `max_completion_tokens` is EQUAL across apps AND `== 512`
(the staged catalog cap: min(512, 32768 − est − 4096) = 512 both sides).
At base tart sends 27841 — the gate is the defect made mechanical; after
the cure it is the parity pin (tart's byte == pi's byte).

### Boundaries

MUST-NOT (the judge's tripwires): no `repos/fast-llm` change of ANY kind
(owner ruling); no rig `runner.rb`/`scenario.rb`/`registry.yml`/golden
edits (the rig already stages the catalog both sides); no new wire keys,
no key-order change — the request body's key set/order is byte-frozen,
only the existing max key's VALUE moves (the declared deviation); no
`Settings.resolve_context_window` reorder (env/settings stay above the
catalog; its pins hold); no `Models.wire_model` fallback change (the
no-entry chain; settings_test's helper pin holds); no catalog-load
defaulting (`Shapes::Model#to_h` DECLARED pin holds); no `agent/
session.rb` recorder/session-entry changes (ENTRY B's surface); no gem
clamp arithmetic touched; no new runtime deps; no Thread.new; the
`compat:` threading (I46) and the thinking-facts seams stay
byte-unchanged. Standing battery: all 25 standing gates green cold; the
s7/s8 tiny-window scenarios send 1 from BOTH apps before and after
(verified — the clamp floors at available), no golden moves.

### Lane plan

ONE lane `core` — bin/tart + agent/loop.rb + models.rb are one
co-designed threading chain, and the re-pins touch the same files; no
disjoint file sets are provable (I54-I58 single-lane precedent).

```lanes
- name: core
  repo: tart
  touch:
    - bin/tart
    - lib/tart/agent/chat.rb
    - lib/tart/agent/loop.rb
    - lib/tart/models.rb
    - lib/tart/print.rb
    - lib/tart/render/chat.rb
    - test/agent_loop_test.rb
    - test/chat_test.rb
    - test/launcher_smoke_test.rb
    - test/models_test.rb
  effort: high
```

### Tool guidance (exact verification)

- Battery (standing 25 + 3 new gates; assembled programmatically in
  `build/i59-spec/gates.yaml` by `build/i59-spec/assemble-gates.rb` from
  I58's frozen block — FIRST ```gates fence only; digests comm-checked,
  zero strays; render-perf-units + render-perf-probe promoted standing;
  threads-budget rebased 41f0a5f→9b04d0d).
- The spec-time measurement artifacts (base 9b04d0d, this session):
  `repos/tart/tmp/i59-spec-wire/` — run-1 tart/pi requests jsonl (the
  27841-vs-512 record); repros `tmp/repro_max_tokens_20261014.rb`,
  `tmp/repro5_wire.rb`, `tmp/repro6_workaround.rb` (offline,
  deterministic — run them; do NOT burn live z.ai credits, a live
  rig/live-API check is NOT required).
- NEVER hand-transcribe digest literals; gates are assembled from I58's
  frozen block.
- The rig gate env prefix (`env -u HERDR_ENV -u HERDR_TAB_ID -u
  HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u
  HERDR_PANE_ID`) is mandatory on every rig invocation.

### Effort

Model zai/glm-5.3-flash, effort HIGH (a boot-chain threading change with
frozen precedence rulings, a declared wire-value deviation to defend,
and subprocess-level regression bars; the Face-1/Face-2 discrimination
needs the care).

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
at the end is the machine-checkable form — the 25 standing commands were
run cold at base `9b04d0d` by the rehearsal this session (render-perf-
units + render-perf-probe promoted standing per the digest convention;
threads-budget rebased 41f0a5f→9b04d0d); every new gate is declared-new
with its RED-at-base reason MEASURED this session, not asserted.

**Declared mechanical correction to the 25 STANDING gates' `ac:`
labels:** I58's frozen block labels its battery gates `ac: AC5` (and
render-perf-units `AC4` / render-perf-probe `AC3`) after I58's own AC
map; I59's battery AC is **AC4**. The assembled block relabels all 25
to `ac: AC4` — COMMANDS byte-verbatim, only the label moves to match
this iteration's AC numbering (the I58 thinking-pins extractor
correction precedent: semantics unchanged, itemized, never silent).

**The declared deviation, restated as the contract (Grounds §2/§4; the
I52 delta-audited bar):** the `max_completion_tokens` VALUE in existing
rig scenarios moves toward pi's byte (s1 measured: tart 27841/27842 →
512 = pi's 512 — the only byte-level move this iteration may cause on
existing scenarios). Every frozen anchor holds EXACT — wire key
set/order, instruction digest `2faaf667…`, tools digest `7360fd1e…`,
all session goldens, settled screens, s17 replay captures — and the
s7/s8 tiny-window scenarios send 1 from BOTH apps before and after
(verified: the clamp floors at available). ANY other wire, session,
golden, or screen byte that moves is a FAIL, not part of the deviation.

**AC1 — the catalog facts reach the wire on every construction path
(D2-D7, D9).** With a catalog entry behind the boot model, the
placeholder-boot construction (Chat + Agent::Loop ctor with the threaded
pair) yields a wire model carrying the entry's context_window and
max_tokens; the request seam then sends
`min(catalog cap, window − est − 4096)` — the plan's pin (1), exact via
the gem's own clamp on the same inputs, and `> 1`. The REAL boot proves
it end-to-end: a staged-catalog `bin/tart -p` subprocess sends a max
value in `(120_000, 131_072]` — never 1 (Face 2's regression bar); the
switch seam threads the cap (Face 1's bar: the clamped send value is
`<= 131_072`, never ~985K); the compaction one-shot's wire model mirrors
the session model's pair. Judge: zai-max-tokens-units (≥4 agent-loop +
≥2 models + ≥2 launcher runs; 0 runs at base — filter verified EMPTY:
`grep -rn zai_max_tokens test/` → nothing).

**AC2 — the rulings hold (D1, D3-D5; Grounds §4).** Precedence
env → settings → CATALOG → known-tables → 0 is pinned: a set
`PI_CONTEXT_WINDOW` still wins over the catalog (the workaround shape,
120_000 → wire window 120_000, max = the window fallback, clamp ≤
120_000 − 4_096); the no-entry chain stays EXACTLY today's (entry-less
boot: env → settings → known-tables → 0; cap nil → wire_model's window
fallback; no tier resolves → wire 0/0 → the request sends `max_tokens:
1` — the declared fallback, pinned at the unit seam AND the real
launcher boot); an entry that declares maxTokens gets it verbatim, an
entry that declares none gets pi's 16_384, an entry with no
contextWindow gets pi's 128_000, and NO entry gets NO default (the
helpers return nil — the no-entry chain owns it). `Shapes::Model#to_h`
stays DECLARED == the parsed entry (the shapes pin holds — defaults
live at the threading seam, never at load), and
`Settings.resolve_context_window`'s ladder is unchanged (its pins
hold). Judge: zai-max-tokens-units + suite (settings/shapes/models pins
unmoved except the declared re-pins of D8).

**AC3 — the wire parity pin (D10; the deliverable made mechanical).**
On the s1 rig scenario BOTH apps' first request carries
`max_completion_tokens == 512` — equal across apps and equal to the
staged catalog cap (mock-1 maxTokens 512, min'd with the clamp at
window 32768). At base tart sends 27841/27842 vs pi's 512 — the gate is
RED by the defect itself; after the cure it is the parity pin. Judge:
zai-max-tokens-wire (RED at base, measured this session:
`tart (27842) != pi (512)`).

**AC4 — no byte moves beyond the declared value + scope.** The standing
battery (25 gates: suite, bench, s1–s10, s1-tart-mode, both probes,
thinking-pins, hermeticity, lock-deps, zai-data, threads-budget rebased
to 9b04d0d, wire-delta, session-golden, s17-parity, render-perf-units,
render-perf-probe) is green cold; NO existing scenario, golden,
registry, wire KEY, or session byte moves beyond the declared
max-VALUE deviation above; exactly the 10 declared files change (the
D8 re-pins land inside them; anything outside is an itemized
deviation). Judge: the battery + scope (non-vacuous at the lane's
10-file diff, base 9b04d0d).

RED-at-freeze register: zai-max-tokens-units = runs 0 (filter verified
EMPTY at base — the declared-new names); zai-max-tokens-wire = RED at
base (tart 27842 ≠ pi 512 — the measured defect); scope = vacuous empty
diff at base + the 10 missing files. All 25 standing gates green in
I58's post-integrate canonical run; the rehearsal re-runs them cold at
this tree.

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
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0


- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0


- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0


- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0


- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0


- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0


- id: s7-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0


- id: s8-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0


- id: s9-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0


- id: s10-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0


- id: s1-tart-mode
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK


- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK


- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK


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
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
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
    added=$(git diff 9b04d0d -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK


- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK


- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK


- id: s17-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/parity-gate-s17; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s17 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s17/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(a["capture"]); ls = File.read(a["styled_capture"]); abort "#{app}: live header row missing" unless live.include?(" edit edit-bg.txt"); abort "#{app}: live removed diff row missing" unless live.include?("-2 line two bravo"); abort "#{app}: live added diff row missing" unless live.include?("+2 line two charlie (edited)"); abort "#{app}: live intra-line inverse missing" unless ls.include?("\e[7m"); abort "#{app}: live success-bg missing" unless ls.include?("\e[48;2;37;65;49m"); abort "#{app}: generic defect row present" if live.include?("\u23bf edit:"); rep = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture")); reps = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture.styled")); abort "#{app}: replay header row missing" unless rep.include?(" edit edit-bg.txt"); abort "#{app}: replay removed diff row missing" unless rep.include?("-2 line two bravo"); abort "#{app}: replay success-bg missing" unless reps.include?("\e[48;2;37;65;49m"); end; puts "S17_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S17_PARITY_OK


- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
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


- id: zai-max-tokens-units
  ac: AC1
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

- id: zai-max-tokens-wire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i59-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i59-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "tmp/i59-wire/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK

- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    ruby -e '
      expected = %w[
        bin/tart
        lib/tart/agent/chat.rb
        lib/tart/agent/loop.rb
        lib/tart/models.rb
        lib/tart/print.rb
        lib/tart/render/chat.rb
        test/agent_loop_test.rb
        test/chat_test.rb
        test/launcher_smoke_test.rb
        test/models_test.rb
      ].sort
      actual = %x(git diff --name-only 9b04d0d...HEAD).split("\n").map { |f| f.strip }.reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      if !extra.empty? || !missing.empty?
        puts "FAIL scope: extra=#{extra.inspect} missing=#{missing.inspect}"
        exit 1
      end
      puts "SCOPE_OK #{actual.size}"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

### core

You are the builder for iteration `zai-max-tokens` (I59), lane `core`.
Work ONLY in the provisioned worktree on branch `lane/I59-zai-max-tokens-core`
(base `9b04d0d`); NEVER commit (the integrator lands your tree), NEVER
touch the space repo, NEVER push. The full iteration contract is the
frozen Grounds/Specification/Acceptance Criteria in this file (verbatim
below) — read them first; this header is the lane's operating brief.

THE TASK IN ONE PARAGRAPH: thread the catalog entry's context_window +
max_tokens into the WIRE MODEL on every construction path — the
interactive boot (bin/tart), the print boot (Print.run), and the
/model switch seam — with pi's precedence (env → settings → CATALOG →
known-tables → 0) and pi's undeclared-field defaults (window 128_000,
cap 16_384, ONLY where an entry exists). This closes both faces of the
owner's live outage: the plain boot's window 0/0 → `max_tokens: 1`
one-token responses (Face 2), and the /model switch's uncapped
window-fallback ≈ 985K z.ai 400 (Face 1). Screen bytes, session bytes,
wire KEY set/order, and every frozen digest anchor hold; the ONE
declared byte-level move is the max VALUE in existing rig scenarios
TOWARD pi's byte (s1: tart 27841/27842 → 512 = pi's 512) — do NOT try
to preserve 27841; the 512 move is the deliverable, gated by
zai-max-tokens-wire.

TOUCH SET (exactly 10 files; the scope gate enforces):
- lib/tart/models.rb — the D1 helpers `Models.entry_context_window`
  / `Models.entry_max_tokens` + the two frozen constants (pi
  provider-composer.ts :242-243 cites in the comments). Defaults ride
  the threading seam ONLY — never catalog load (`Shapes::Model#to_h`
  DECLARED pin holds), never `Settings.resolve_context_window`.
- lib/tart/agent/loop.rb — ctor gains `max_tokens: nil` (stored,
  threaded into the ctor's `apply_facts` beside the resolved window —
  the window expression byte-unchanged); `switch_model` gains
  `max_tokens: nil` threaded into BOTH its `apply_facts` calls (the
  WINDOW threading byte-unchanged — raw kwarg + the re-resolution
  ladder, its I30 pins hold).
- lib/tart/agent/chat.rb — `summary_chat` threads
  `max_tokens: @facts.max_tokens` beside `context_window:
  @facts.context_window` (ONE line; `apply_facts` already accepts the
  kwarg — no signature change).
- lib/tart/print.rb — `Print.run` gains `max_tokens: nil` forwarded to
  the Loop ctor; the print-path comment updates to the new truth (env
  still wins — resolve folds it first).
- bin/tart — BOTH boots resolve the entry ONCE via the existing
  `resolve_boot_entry` helper and thread
  `context_window: Settings.resolve_context_window(settings:, model: chat.model, identity:) || Models.entry_context_window(entry)`
  + `max_tokens: Models.entry_max_tokens(entry)` (+ keep `compat:`
  threading byte-identical). The interactive site is the Agent::Loop.new
  call (:448-465); the print site is the Print.run call (:278-309).
- lib/tart/render/chat.rb — `apply_model_selection` adds
  `max_tokens: Models.entry_max_tokens(entry)` to the
  `@agent&.switch_model` call; `context_window: entry.context_window`
  stays RAW (the declared boot/switch asymmetry, Specification D6).
- test/models_test.rb — NEW pins (filter token `zai_max_tokens`):
  the D1 helper truth table (declared passthrough; windowless →
  128_000; capless entry → 16_384; nil entry → nil/nil). ≥2 runs.
- test/agent_loop_test.rb — NEW pins (filter token `zai_max_tokens`):
  P1 boot-shaped (placeholder chat + Loop ctor with the threaded pair →
  wire model attrs + request max == the gem's own
  `Protocol.clamp_max_tokens` on the same inputs, > 1); P2 no-entry
  (env tier 120000 → wire 120_000/max fallback/clamp ≤ 115_904; and no
  tier at all → wire 0/0 → request sends 1 — the DECLARED fallback);
  P4 switch cap (switch_model with the pair → clamped send ≤ 131_072,
  never ~985K). ≥4 runs.
- test/launcher_smoke_test.rb — NEW subprocess pins (filter token
  `zai_max_tokens`, real `bin/tart -p`, staged HOME, MockLLMServer):
  catalog leg (staged ~/.tart/models.json, glm-5.3 window 131_072 cap
  131_072, default "mock/glm-5.3", NO context-window env → request max
  Integer in (120_000, 131_072] — never 1); no-entry leg (no
  models.json, PI_MODEL=custom-x PI_PROVIDER=openai, no window env →
  request max == 1). The harness prompt's estimate is
  checkout-depth-sensitive — pin the RANGE on the catalog leg, never an
  exact number. ≥2 runs.
- test/chat_test.rb — the declared D8 re-pins: the switch-family agent
  doubles' `switch_model` signatures gain the `max_tokens:` kwarg with
  the expected `Models.entry_max_tokens` value; screen assertions stay
  verbatim. grep the suite for other pins on the construction kwargs /
  wire max value FIRST; re-pin per the standing discipline and itemize
  every re-pin in the report (D8 also lists settings_test's wire_model
  helper as verified-NO-change, not a re-pin).

MUST-NOT: no repos/fast-llm change of ANY kind (owner ruling — the gem
clamp arithmetic is the ORACLE, reproduce with
`Fast::Completions::Protocol.clamp_max_tokens`, never modify it); no
gems/tui-split-rig changes (runner/scenarios/registry — the rig already
stages the catalog both sides); no new wire keys or key-order change;
no `Settings.resolve_context_window` reorder (env/settings stay ABOVE
the catalog — the workaround + rig staging + subagent children depend
on it); no `Models.wire_model` fallback change (the no-entry chain);
no catalog-load defaulting; no lib/tart/agent/session.rb changes
(ENTRY B's surface); no new runtime deps; no Thread.new; the I46 compat
threading and thinking-facts seams byte-unchanged.

OPERATING DISCIPLINE:
- Run the battery cold from the worktree (the 28 gates in the frozen AC
  block; s9's known deep-path artifact in a lane worktree = report, do
  not chase). The two rig gates (wire-delta, zai-max-tokens-wire) each
  run s1 (~40 s); render-perf-probe takes ~3 min — budget your runs.
- The repros are OFFLINE and deterministic (tmp/repro_max_tokens_
  20261014.rb, tmp/repro5_wire.rb, tmp/repro6_workaround.rb in the
  SPACE repo — read them from the worktree's parent). Do NOT burn live
  z.ai credits: a live rig/live-API check is NOT required; the owner
  already paid for the evidence.
- If a frozen ruling fights reality (e.g. a pin you cannot satisfy
  without touching a MUST-NOT file), STOP and checkpoint
  build/loop/exception-<UTC>.md with the raw facts; never silently
  re-freeze, never widen scope.
- The zai-max-tokens-wire gate is RED at base BY DESIGN (tart 27842 ≠
  pi 512 — the measured defect). Your cure turns it GREEN; if your tree
  leaves it RED, the threading is wrong — re-read Grounds §1, do not
  touch the gate.
- Report at build/I59-zai-max-tokens-core/report.md (the staged
  architecture file's Builder Report section is transcribed from it):
  per-AC outcomes, the measured wire before/after values, the re-pin
  inventory (every re-pin itemized), deviations, incidents.
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md. bg_wait abort with "Still active" →
  RE-ISSUE the wait.

The frozen sections follow verbatim.

## Builder Report

### core

# I59 zai-max-tokens — lane `core` builder report

Worktree `build/I59-zai-max-tokens-core/wt`, branch `lane/I59-zai-max-tokens-core`, base
`9b04d0d`. No commits, no git write commands, no pushes, space repo untouched (verified
clean; only gitignored `tmp/` artifacts added under `repos/tart/tmp/` for the base-drift
proof). Final tree diff = exactly the 10 frozen files, +310/−21 (scope below). No live
z.ai credits burned; no rig/gem/settings/session file touched.

## Per-AC outcomes

**AC1 — the catalog facts reach the wire on every construction path: PASS.**
- D1 `Models.entry_context_window` / `Models.entry_max_tokens` + frozen constants
  `DEFAULT_ENTRY_CONTEXT_WINDOW = 128_000` / `DEFAULT_ENTRY_MAX_TOKENS = 16_384`
  (pi provider-composer.ts:242-243 cites in the comments) landed in `lib/tart/models.rb`.
- D2 ctor: `max_tokens: nil` kwarg (after `context_window:`), stored `@max_tokens`,
  threaded beside the resolved window into the ctor's `apply_facts`; the window
  expression (`resolved_context_window || Settings::MODEL_CONTEXT_WINDOWS.fetch(...)`)
  byte-unchanged; `@param max_tokens` doc follows the house shape. D5 `switch_model`:
  `max_tokens: nil` after `context_window:`, stored, threaded into BOTH `apply_facts`
  calls; window threading byte-unchanged (I30 pins pass unmodified).
- D3/D4 bin/tart: BOTH boots resolve the entry ONCE via `resolve_boot_entry` into a
  local and thread `context_window: Settings.resolve_context_window(...) ||
  Models.entry_context_window(entry)` + `max_tokens: Models.entry_max_tokens(entry)`;
  interactive `compat:` now rides the hoisted local (`compat: entry&.compat` — the
  frozen D3 snippet's exact shape); print `compat:` stays byte-identical via `**thinking`.
  Print.run gained `max_tokens: nil` forwarded to the Loop; both print-path comments
  updated to the new truth (env still wins — resolve folds it first).
- D6 `apply_model_selection` adds `max_tokens: Models.entry_max_tokens(entry)`;
  `context_window: entry.context_window` stays RAW (the declared boot/switch asymmetry).
- D7 `summary_chat` threads `max_tokens: @facts.max_tokens` (one line). Suite summary
  pins 6/8 (zai rename + compat-nil shapes) pass unmodified.
- Pins: P1 (boot-shaped ctor → wire 131072/131072; request max == the gem's own
  `Protocol.clamp_max_tokens` on the request's own inputs; > 1); P4 (switch cap → wire
  carries the pair; clamped send ≤ 131072, > 1, == the gem clamp); P3-i (real
  `bin/tart -p`, staged catalog: max = **126149** ∈ (120_000, 131_072] — never 1);
  P3-ii (no-entry boot: max == **1**, the declared fallback, at the real boot).
- All new pins carry `zai_max_tokens`; filter verified EMPTY at base
  (`grep -rn zai_max_tokens test/` → no matches, exit 1).

**AC2 — the rulings hold: PASS.**
- Precedence (Grounds §4-a): P2-i pins `PI_CONTEXT_WINDOW=120000` (no entry kwargs) →
  wire window 120_000, wire max 120_000 (wire_model's window fallback), clamped send
  ≤ 120_000 − 4_096. Env tier still sits above the catalog (the `||` in both boots).
- No-entry chain (§4-b): P2-ii pins wire 0/0 → request sends exactly 1 (unit seam), and
  P3-ii pins the same at the REAL launcher boot. `Models.wire_model` untouched;
  `Settings.resolve_context_window` untouched; known-tables/0 tiers untouched.
- Undeclared-field defaults (§4-c): truth-table pins — declared passthrough verbatim;
  windowless ENTRY → 128_000; capless ENTRY → 16_384 (never the window fallback); nil
  entry → nil/nil. `Shapes::Model#to_h` DECLARED pin (shapes_test :33-56) untouched and
  green (the loaded entry still carries the raw nil — asserted in the new models pin).

**AC3 — the wire parity pin: PASS.** `ZAI_WIRE_OK tart=pi=512` — on the s1 rig artifact
(`tmp/i59-wire/run-1/`), both apps' first request carries `max_completion_tokens == 512`
(equal across apps, equal to the staged catalog cap). The gate's embedded rig run exits 1
in this environment for the drift reason (E2 below) BEFORE its assertion runs; the gate's
own assertion body was executed against the gate's artifact and passes. Measured:

| wire value (s1, first request) | base `9b04d0d` | this tree | pi |
|---|---|---|---|
| tart `max_completion_tokens` | **27840** (fresh base run in this env; spec-time measured 27841/27842) | **512** | **512** |
| launcher catalog leg (`bin/tart -p`, glm-5.3 131072/131072) | (n/a — Face 2 shape sends 1) | **126149** | — |
| launcher no-entry leg | 1 (declared) | **1** (unchanged) | — |

**AC4 — no byte moves beyond the declared value + scope: PASS with environment-class
exceptions (E1–E5, all checkpointed/mechanism-proven).**
- Scope: exactly the 10 frozen files. Worktree-adapted form: `SCOPE_OK 10`
  (`git diff --name-only 9b04d0d` + untracked). The VERBATIM gate command
  (`git diff --name-only 9b04d0d...HEAD`) prints
  `FAIL scope: extra=[] missing=[...all 10...]` in any uncommitted worktree (three-dot
  diff of HEAD==base is empty) — I58 deviation E1 precedent; it is integrator-side by
  construction. Raw output recorded above.
- Suite: GREEN cold (run A: **1154 runs, 5408 assertions, 0 failures, 0 errors,
  1 pre-existing skip, RAKE_EXIT=0**, log `/tmp/i59-suite.log`). Run B hit ONE failure of
  the documented environment class (E4) — zero failures in any lane surface; the 8
  `zai_max_tokens` pins and the D8 re-pin passed in every run.
- Unit/probe gates green: bench `SEAM_BENCH_OK`; thinking-pins 18/9 (≥11/8);
  hermeticity 10/4; lock-deps `LOCK_DEPS_OK` + `GEM_LOAD_OK`; zai-data `ZAI_DATA_OK`
  (2 runs); threads-budget OK (no new `Thread.new` in lib); render-perf-units 7 runs;
  zai-max-tokens-units 4/2/2 runs; render-perf-probe `RENDER_PERF_OK` (BP1 2.62 ≤ 3.0,
  BP2 246.5 ≤ 250, BP3 9.3 ≤ 25, BP4 21.9 ≤ 35, BP5 9.7 ≤ 40; anti-vacuity all PASS:
  window 141.9s, marker observed, requests 3, frames 3057, live 44677, rows 12538).
- Byte-freeze anchors: wire key set/order `["model","messages","stream","stream_options",
  "store","max_completion_tokens","tools"]` EXACT; `store:false`; user message exact;
  `stream_options {"include_usage"=>true}` EXACT; tools digest
  `7360fd1e…c23707` EXACT (verified equal base↔lane); instruction bytes identical
  base↔lane modulo the checkout-depth sandbox path (the frozen `2faaf667…` literal is
  environment-moved at BASE too — E3); session-golden `SESSION_GOLDEN_OK` (all seven
  digests); s17 `S17_PARITY_OK` (exit 0, full assertion body incl. replay captures).
- s7/s8 tiny-window anchor: first request sends `1` from BOTH apps before and after
  (measured on both trees); the compaction one-shot's `0`-vs-`nil` max shape is
  byte-identical at base (measured, base s7 run) — pre-existing, not this lane's.
- Parity rig gates s1–s10 exit 1 with the drift signature PROVEN byte-identical at the
  clean base checkout (E2). Functional parity holds in every scenario: both apps
  completed with exactly the expected request counts, zero boot/reply timeouts:
  s1 1/1, s2 2/2, s3 3/3, s4 3/3, s5 2/2, s6 3/3, s7 2/2, s8 2/2, s9 1/1, s10 1/1,
  s17 4/4. s1-tart-mode `TART_MODE_OK` (exit-code-tolerant gate; tart completed,
  requests == expected). tool-pending `TOOL_PENDING_GATE_OK`; user-bash-stream
  `USER_BASH_STREAM_GATE_OK`.

## Re-pin inventory (D8 — grep-first, every change itemized)

1. **RE-PINNED** `test/chat_test.rb` `test_model_menu_enter_switches_the_model_and_refreshes_the_surface`
   (the :2667 exact-kwargs double): the `switch_model` double's signature gains
   `max_tokens: nil`; the expected hash gains
   `max_tokens: Models.entry_max_tokens(model_catalog.model_entries.first)` (= 16_384 —
   the capless glm-5.3 catalog entry rides pi's definition default); the assertion
   message states the I59 D8 re-pin. Screen assertions (footer segment, "Model: glm-5.3"
   status) stay verbatim.
2. **VERIFIED NO CHANGE** — `test/chat_test.rb` :2896 `switching_agent` spy: `do |*|`
   absorbs any kwargs and asserts call ORDER only; it cannot carry and does not assert
   an expected value (the D8 letter names it; a cosmetic edit would be change-worship).
3. **VERIFIED NO CHANGE** — `test/settings_test.rb` `wire_model` helper (:31-36):
   `Models.wire_model` is untouched; the no-entry fallback shape stands.
4. **VERIFIED NO CHANGE** — `test/print_test.rb` forwarding pin: fetch-based key asserts
   (`captured.fetch(:context_window)` etc.); `Print.run`'s added `max_tokens:` kwarg is
   transparent to it.
5. **VERIFIED NO CHANGE** — `test/agent_loop_test.rb` summary pins 6/8: they assert the
   one-shot's max KEY NAME and shapes, never its VALUE; in those constructions
   `@facts.max_tokens` equals the same window-fallback value (14) the fallback produced
   before, so the wire is byte-identical.
6. Grep inventory run first: `switch_model` (test/ → chat_test, agent_loop_test only),
   `Agent::Loop.new` construction pins, `Print.run` call sites, `summary_chat` (no test
   references), `max_completion_tokens`/`:max_tokens` value assertions — no other pin
   asserts the boot/switch construction kwargs or the wire max VALUE.

## New pins (all `zai_max_tokens`-named)

- `test/models_test.rb`: 2 runs / 9 assertions — D1 truth tables (declared passthrough;
  windowless → 128_000 == the constant; capless → 16_384 == the constant; nil entry →
  nil/nil; no catalog-load defaulting).
- `test/agent_loop_test.rb`: 4 runs / 17 assertions — P1 boot-shaped ctor (wire pair +
  gem-clamp equality + > 1); P2-i env tier (120000 → 120_000/120_000, clamp ≤ 115_904);
  P2-ii no-entry (wire 0/0 → sends 1); P4 switch cap (pair on the wire; ≤ 131_072, > 1,
  gem-clamp equality). P1/P4 read the clamp inputs from the captured request body (the
  D9 letter's "the request's instructions, the request's messages"); P4 reads the max
  key dialect-aware (`max_tokens` under `zai_compat` rename, per existing pin 6).
- `test/launcher_smoke_test.rb`: 2 subprocess runs / 7 assertions — P3-i staged-catalog
  boot (max 126149 ∈ (120_000, 131_072]); P3-ii no-entry boot (== 1). New `wire_env`
  helper scrubs the model-shaping env (PI/TART MODEL/PROVIDER/CONTEXT_WINDOW) because
  Process.spawn MERGES the parent env — discovered live: this agent session's own parent
  env carries `PI_MODEL`/`PI_PROVIDER`, which leaked into the first pin run.

## Deviations & incidents (all environment-class; none touch the frozen letter)

- **E1 scope-gate form** — verbatim `9b04d0d...HEAD` is vacuous in an uncommitted
  worktree; worktree-adapted equivalent used (`SCOPE_OK 10`). I58 deviation E1 precedent.
- **E2 pi v1.2.0 environment drift (checkpointed)** — this environment's `pi --version`
  is 1.2.0 (tart oracle banner pinned `ORACLE_VERSION = "1.1.0"`, rig registry has no
  class for the banner/Extensions delta). s1–s10 parity gates exit 1 with
  `unknown-candidate` classes. PROVEN PRE-EXISTING: the identical rig command from the
  clean base checkout (`repos/tart` @ 9b04d0d, `git status` clean) produces the
  byte-identical drift signature (s1: same 8 candidates, same class counts). Checkpoint:
  `build/loop/exception-2026-10-15T03:30:00Z.md`. Artifacts: lane
  `wt/tmp/parity-gate-s1/`, base `repos/tart/tmp/i59-base-drift-s1/` (+ base s7). The
  integrator's judge environment needs pi pinned 1.1.0, or a registry class, or accepts
  the identical-signature proof.
- **E3 wire-delta instruction digest** — the frozen `2faaf667…` literal is unattainable
  in this environment AT BASE AND LANE: the harness prompt's `<docs>` section embeds the
  pi v1.2.0 install's doc paths/content; base and lane instruction bytes are IDENTICAL
  modulo the checkout-depth sandbox path (diff shown: 1 line, the out-dir prefix). Every
  other wire-delta assertion passes on the lane tree (key set/order, store, user message,
  stream_options, tools digest `7360fd1e…`, max positive; max = 512).
- **E4 Gemfile.lock flip-flop / suite flake class** — lane worktree runs export
  `FAST_COMPLETIONS_PATH=<space>/repos/fast-llm/gems/completions` (matches the COMMITTED
  lock's absolute remote); the worktree's `../fast-llm` is a symlink I created OUTSIDE
  the repo (`build/I59-zai-max-tokens-core/fast-llm` — I58 protocol). bin/tart's own
  `Bundler.setup` + env-scrubbed boot children re-lock through the symlink to the
  RELATIVE remote; exported bundle installs re-lock to ABSOLUTE (bundler compares the
  Gemfile path LEXICALLY — the native repos/tart layout matches textually and is
  immune). Consequence: one suite run failed on `test_leg_c_steer_reaches_a_running_child`
  + `test_foreground_delegation_end_to_end` and a later run on
  `test_leg_e_print_parent_intercom_shape` — all the SAME class: a boot child printed
  `Resolving dependencies...` into asserted stdout during a re-lock. Run A (green,
  RAKE_EXIT=0) is the gate evidence; no failure ever touched a lane surface. An early
  broken-lock state (before the protocol was in place) also produced the same class.
  `Gemfile.lock` RESTORED to committed bytes; final `git status` = the 10 files exactly.
  The rig's panes run under `BUNDLE_FROZEN` and cannot rewrite the lock (mismatch =
  loud abort — observed once as the render-perf-probe "can't find pane" when the lock
  was in the absolute form; the probe passed with the lock in the relative form).
- **E5 s9 known artifact** — `staged-path-wrap-fragment` ×6 (the brief's known
  lane-worktree deep-path class): reported, not chased.
- **D8 :2896 note** — the letter's ":2896 gains the kwarg" is recorded as verified-no-
  change (order-spy, `|*|`); itemized above rather than cosmetically edited.

## Gate ledger (28 frozen gates)

| gate | result |
|---|---|
| suite | PASS (run A: 1154 runs, 0 failures, RAKE_EXIT=0; run B: 1 environment-class failure, E4) |
| bench | PASS (`SEAM_BENCH_OK`) |
| s1–s10-parity | RED-in-this-environment at base AND lane, byte-identical drift signature (E2); functional parity exact (per-scenario completion table above) |
| s1-tart-mode | PASS (`TART_MODE_OK`) |
| tool-pending-gate | PASS (`TOOL_PENDING_GATE_OK`) |
| user-bash-stream-gate | PASS (`USER_BASH_STREAM_GATE_OK`) |
| thinking-pins | PASS (18/9 runs) |
| hermeticity | PASS (10/4 runs) |
| lock-deps | PASS (`LOCK_DEPS_OK` + `GEM_LOAD_OK`) |
| zai-data | PASS (`ZAI_DATA_OK`, 2 runs) |
| threads-budget | PASS (no new `Thread.new` in lib) |
| wire-delta | all assertions PASS except the instruction-digest literal (E3 — environment-moved at base too); max=512 |
| session-golden | PASS (`SESSION_GOLDEN_OK`) |
| s17-parity | PASS (`S17_PARITY_OK`, exit 0, full assertion body) |
| render-perf-units | PASS (7 runs) |
| render-perf-probe | PASS (`RENDER_PERF_OK`, all budgets + anti-vacuity) |
| zai-max-tokens-units | PASS (4/2/2 runs; 0 at base — filter verified empty) |
| zai-max-tokens-wire | PASS (`ZAI_WIRE_OK tart=pi=512`) |
| scope | verbatim form vacuous-red in the uncommitted worktree (raw output recorded); worktree-adapted form `SCOPE_OK 10` |

Offline repros (space tmp/, run clean, deterministic): `repro_max_tokens_20261014.rb`
(window fallback 995895 vs capped 131072), `repro5_wire.rb` (wire 0/0 → sends 1),
`repro6_workaround.rb` (env 120000 → 105516 LEGAL).

Worktree left UNCOMMITTED for the integrator; branch `lane/I59-zai-max-tokens-core`;
`git status` = the 10 declared files exactly.

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section zai-max-tokens verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify zai-max-tokens`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
