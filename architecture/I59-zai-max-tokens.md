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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section zai-max-tokens specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision zai-max-tokens`
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
`architect rehearse zai-max-tokens` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze zai-max-tokens` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse zai-max-tokens` — before the freeze, while
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
subsection per lane. A copy is written to build/I59-zai-max-tokens-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section zai-max-tokens prompt --append --lane <lane> --from build/I59-zai-max-tokens-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I59-zai-max-tokens-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence zai-max-tokens --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
