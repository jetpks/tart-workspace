# I40: model-catalog-polish

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

## 1. The plan letter vs the live tree (the honest re-scope)

Plan ENTRY 4 (`build/loop/plan-20261012T184702Z.md`) queues three I27/I28 residuals.
Base verified at spec time: `repos/tart` `project/pi-port` @ **9beb6a6a** (I39 integrated;
`git log --oneline -1` re-run this session). The plan text predates I28's freeze — its
item-1 claim "tart offers all 8 levels always" is doubly stale: the ladder is SEVEN
levels (`Settings::THINKING_LEVELS`, settings.rb:55; pi `THINKING_LEVEL_OPTIONS`
defaults.ts:6-14), and the gating has been live since I28 (verdict 2dfda3fa, "✓/·
cross-resolution + thinking gating closed") recomposed by I36 onto the thinkingLevelMap
tier (verdict 22deda27). This session re-verified every item against the live tree by
DRIVING the classes (scratch evidence `tmp/mcp_audit.rb`, run + deleted this session;
reproduced below) — the disposition:

- **Item 1 (thinking-level gating by model reasoning) — CLOSED in the live tree.**
  Live evidence (footer facts + a staged 2-model catalog driven through
  `Render::Chat`): non-reasoning model → `available_thinking_levels == ["off"]`
  (pi agent-session.ts:2656-2662 → getSupportedThinkingLevels, models.ts:1224-1233);
  reasoning map-less model → `["off","minimal","low","medium","high"]` (pi's map-less
  rule); the menu items, the shift+tab cycle, and the `/thinking <arg>` surface gate
  (`gate_thinking_level`, chat.rb:1030-1039) all read the gated set. The shipped
  regression pins: chat_test.rb:2429+ (non-reasoning → `[off]`), the I28 AC4 family.
  Residue shipped WITH a wrong-pi citation: `thinking_menu_items` FLOORS an
  out-of-set current level onto `levels.first` (chat.rb:1767-1768, comment cites
  "pi's session level is clamped to the model's set — setModel → _clampThinkingLevel").
  pi's letter is NO floor: the ✓ prefix is `level === currentLevel ? "✓ " : "  "`
  (thinking-selector.ts:69-73) — an out-of-set current marks NO row. Mostly
  unreachable once the re-clamp lands (below), but the floor is not pi's letter and
  its comment's premise (pi always clamps) is exactly what item 3 ports — align it.
- **Item 2 (✓/· marker cross-resolution under env boot) — CLOSED in the live tree**
  (I28 AC4, all 6 AC PASS at judge 2dfda3fa). Live evidence: footer facts
  `{model: "mock-1", default_provider: "openai"}` + a catalog keyed `mock` →
  `boot_model_ref == {provider: :mock, id: "mock-1"}` — both markers resolve onto
  the catalog entry. Shipped pin: chat_test.rb:2412
  (`test_model_menu_markers_match_the_runtime_model_across_the_wire_provider`).
  Two micro-residues stand, both recorded here as standing itemized deviations
  (no work this iteration, OQ-3): (a) an AMBIGUOUS bare id (same id under two
  providers) keeps the boot wire pair — markers drop; pi has no analog because its
  provider keys ARE wire slugs. (b) the · default badge ref is the RESOLVED BOOT
  pair (env > models.json > settings, chat.rb:1886-1893) where pi's badge is the
  SETTINGS pair `getDefaultProvider()+getDefaultModel()` and NO badge when either
  is unset (interactive-mode.ts:5358-5367); divergent only under an env boot that
  differs from the persisted default, or when no default is persisted at all.
- **Item 3 (stored-level re-clamp on model switch) — OPEN; the real work.** Live
  evidence: stored level `xhigh` survives a switch to a map-less reasoning model
  (pi: clamps to `high`) AND a switch to a non-reasoning model (pi: clamps to
  `off`) — `apply_model_selection` (chat.rb:1837-1855) never touches
  `@thinking_level` or the loop's stored level. Observable divergences vs pi: the
  footer's `model • <level>` segment and the editor border ladder render the
  UN-clamped stored level (chat.rb:1376-1382, footer_data view) while the wire
  silently clamps in the I36 request hook (loop.rb:574-600); pi's session state is
  the clamped value everywhere.

## 2. pi's switch path (verified in source this session — the contract to port)

- `setModel` (agent-session.ts:2477-2496): auth check → `previousModel` →
  `const thinkingLevel = this._getThinkingLevelForModelSwitch(model)` →
  `this.agent.state.model = model` → session `appendModelChange` → persist default
  when asked → `this.setThinkingLevel(thinkingLevel)` (NO options → persist:false) →
  `_emitModelSelect`. The level resolution happens for the NEW model and the clamp
  uses the NEW model's facts (model swapped first).
- `_getThinkingLevelForModelSwitch` (agent-session.ts:2670-2679):
  `explicitLevel ?? getModelThinkingLevel(provider,id) ?? getDefaultThinkingLevel() ?? this.thinkingLevel ?? DEFAULT_THINKING_LEVEL`.
  I.e. pi RE-APPLIES the persisted global default on every switch when one exists,
  and keeps the session level otherwise. `getModelThinkingLevel` reads the
  `modelThinkingLevels` per-model map (settings-manager.ts:768-770) — written by
  pi's scoped-models menu, a CUT surface in the port (I27's itemized reductions; no
  scoped models, no per-model levels). `getDefaultThinkingLevel()` reads
  `settings.defaultThinkingLevel` (settings-manager.ts:758-760) — **undefined unless
  a settings FILE declares it**; pi never bakes a default into the merged view.
- `setThinkingLevel` (agent-session.ts:2610-2634):
  `effectiveLevel = availableLevels.includes(level) ? level : _clampThinkingLevel(level, availableLevels)`
  (`_clampThinkingLevel` :2683-2685 = `clampThinkingLevel(this.model, level)`,
  models.ts:1235-1254 — the forward-then-backward scan the port already ships as
  `Models.clamp_thinking_level`, models.rb:210-224); stores
  `agent.state.thinkingLevel = effectiveLevel`; persists only when asked; appends a
  session `thinking_level_change` entry ONLY when the effective level changed;
  emits `thinking_level_changed` → interactive handler does `footer.invalidate() +
  updateEditorBorderColor()` (interactive-mode.ts:3495-3498) — **NO status row**;
  the only status on the switch path is the model selector's own
  `Model: <id>` / `Default model: <provider>/<id>` (interactive-mode.ts:5347-5351).
- **pi clamps at BOOT too** (found this session — the same defect family): createSdk
  (sdk.ts:271-279) — `thinkingLevel = clampThinkingLevel(model, thinkingLevel)`
  after the model-resolver cascade ("off" when no model). The port's boot composes
  `Settings.resolve_thinking_level(settings)` UNCLAMPED into both the loop kwargs
  and the footer fact (bin/tart:213/:280/:407) — same observable divergence (footer
  `• level` + border + ✓ marker) whenever a settings level is outside the boot
  model's supported set. The rig's staged boots make this REAL, not theoretical:
  s1–s9 boot mock-1 (`reasoning: false`, runner.rb:326) with the baked default
  "medium" — pi's state would be "off", tart's is "medium" (both render identically
  only because both surfaces gate the level display on reasoning; the stored states
  differ).
- The `· default` badge on the thinking menu: pi marks the row matching
  `getDefaultThinkingLevel() ?? DEFAULT_THINKING_LEVEL` — UNclamped
  (thinking-selector.ts:71-72 via showThinkingSelector :5187); an out-of-set
  default simply marks NO row (the badge only rides an existing gated row). The
  port's badge source must therefore stay UNCLAMPED even after the session level
  clamps — otherwise a default `xhigh` on a map-less model would badge `high`
  where pi badges nothing.

## 3. The port's shipped machinery this composes with (no re-derivation)

- `Models.supported_thinking_levels / clamp_thinking_level / resolve_reasoning_effort`
  (models.rb:186-241) — pi models.ts:1224-1254, I36-verified line-for-line at judge.
- `Settings.thinking_facts` (settings.rb:226-236) — the ONE facts composer
  (catalog-entry-first, known-tables-second) used by the interactive boot, print
  boot, and the switch path (the I36 discipline; apply_model_selection already
  composes it at chat.rb:1845).
- `Agent::Loop#set_thinking_level` / `switch_model(..., model_reasoning:,
  thinking_level_map:)` (loop.rb:137-181) — stored-level seam + facts re-resolve;
  the request hook reads the stored level at request time.
- The surface's `thinking_level` reader fallback (chat.rb:1524-1527) and the
  per-frame `footer_data` overlay (chat.rb:1563-1571) — the footer/border refresh
  mechanism pi gets from `footer.invalidate` + `updateEditorBorderColor`.
- Settings files: user root `~/.tart/settings.json` + project `<cwd>/.tart/
  settings.json`, project over user (settings.rb:103-113); the surface already
  WRITES them via `Settings.save(@settings_root, ...)` on ctrl+s — a fresh read at
  switch time is live-true across mid-session persists, matching pi's in-memory
  settingsManager view.

## 4. Scope rulings baked here (plan letter + BRIEF §8 pi-exact; itemize-and-defend)

1. **The iteration's work = item 3's re-clamp FAMILY**, now precisely: (a) the
   switch re-clamp with pi's level-for-switch resolution (the named I28 residual);
   (b) the boot clamp (the same family, pi sdk.ts:271-279 — without it the stored
   level still diverges from pi at boot); (c) the ✓-floor removal (item 1's residue,
   pi's letter). Items 1+2 are verified-closed; their shipped pins are REGRESSION
   GUARDS this iteration must keep green (AC4).
2. **The declared-default tier (pi's `getDefaultThinkingLevel()` re-apply)** is
   ported pi-exactly: "a settings FILE declares `thinkingLevel`" (user root or
   project cwd, project over user; the port's baked `DEFAULTS["thinkingLevel"]`
   must NOT count — pi's undefined-unless-set distinction). Mechanism: a fresh
   `Settings` read at switch time (the surface owns `@settings_root`; cwd from the
   footer fact) — mid-session ctrl+s writes are picked up, as in pi. Values outside
   `THINKING_LEVELS` read as UNDECLARED (pi's settings schema cannot declare them;
   an invalid file is a load diagnostic in both). OQ-1 records the simpler
   clamp-only alternative; the plan letter ("verify pi's switch path in source and
   port the behavior") wins.
3. **CUT, itemized**: per-model thinking-level overrides (`modelThinkingLevels` —
   pi's scoped-models surface is a recorded I27 cut, and the port has no writer);
   session-file `thinking_level_change` / `model_change` entries (pi
   session-manager.ts:1217-1237; the port's session format carries
   session/message/compaction only — a recorded reduction since I07; resume-replay
   of mid-session switches is untouched) — OQ-2, backlog candidate, NOT this
   iteration (session-format work); pi's `checkAuth` on switch (the port's auth is
   boot-time; I27 shape); the badge-ref semantics realignment (OQ-3 — keep I28's
   frozen shape).
4. **Settled screens must not move**: the re-clamp changes no settled bytes on the
   staged rigs (mock-1 boots non-reasoning → the footer's level segment is gated
   off, the border token is `thinking_off` either way; glm's map supports every
   level so the launcher pins' "medium"/"off" hold). s1–s9 cold (AC4) is the guard.
5. Non-goals: model-menu layout/bytes (frozen I27/I28), the `Commands::Handler`
   full-ladder `/thinking` branch (chat.rb:1030-1039's comment records the frozen
   design: the SURFACE owns the runtime gate; the handler's branch is unreachable
   through the surface path — I36 residual note, unchanged), `ModelMenu.thinking`'s
   sealed full-ladder constructor (the I36 design: "the sealed family constructor
   pins the full ladder, so the gate builds here"), print-mode UI, compaction,
   session format, the rig (no scenario/registry changes; the probe re-run is
   evidence, not a parity gate — I27's own header says so).

## 5. Open questions for the judge (proceed on the plan-letter defaults above)

- **OQ-1** — the declared-default tier on switch: port pi's re-apply (default) vs
  clamp-only-the-session-level (simpler; diverges from pi exactly when a default is
  declared and differs from the session level — a switch then keeps the session
  level where pi reverts to the default). Default taken: PORT (BRIEF §8).
- **OQ-2** — session-file `thinking_level_change`/`model_change` entries: CUT
  (default) vs port now. Default taken: CUT — session-format work with resume
  ripple, outside "model-menu parity gaps"; backlog candidate.
- **OQ-3** — the · default badge ref under env boot (pi: settings pair / none when
  unset; port: resolved boot pair — I28-frozen) + the ambiguous-bare-id keep.
  Default taken: keep the I28 shape, standing itemized deviations; the declared-
  reader mechanism from ruling 2 generalizes if the owner wants alignment later.

## 6. Instrument notes

- The model-menu probe (`gems/tui-split-rig/bin/model-menu-probe`) is the plan's
  named re-run: it drives both apps through `/model` + `/thinking` under the rig's
  staged boot (tart: 2-model catalog, mock-1 non-reasoning boots; pi: staged
  models-store mock-1 non-reasoning, `--model mock/mock-1`) — both apps' /thinking
  menus show `[off]` alone today, the gating live. "Green" for this iteration =
  completes, all four (app × menu) captures non-TIMEOUT, output archived; the
  deterministic parity claims live in the unit pins (the probe's own header: NOT a
  parity gate).
- Suite at base: 763 runs / 3092 assertions (I39 verdict). Bench prints
  SEAM_BENCH_OK.
- The known lane-worktree s9 deep-path artifact (I34/I36/I39-ruled environmental,
  third independent confirmation at I39): s1–s9 gates are judged on the integrated
  tree, as in I39.

## Specification

## Objective

Close the model-menu parity gaps that remain OPEN on the live tree (base 9beb6a6a) —
pi's stored-thinking-level discipline across the model lifecycle (BRIEF §8
pi-exactness; plan ENTRY 4, the I28-residual re-clamp family):

1. **The switch re-clamp** — pi `setModel` (agent-session.ts:2477-2496) resolves a
   level FOR THE SWITCH (`_getThinkingLevelForModelSwitch` :2670-2679) and clamps it
   through the NEW model's supported set (`setThinkingLevel` :2610-2634 →
   `clampThinkingLevel` models.ts:1235-1254). The port's `apply_model_selection`
   (chat.rb:1837-1855) leaves the stored level untouched today.
2. **The boot clamp** — pi createSdk clamps the boot level through the boot model
   (sdk.ts:271-279); the port composes it unclamped (bin/tart:213/:280/:407).
3. **The ✓-floor removal** — pi marks NO thinking-menu row when the current level is
   outside the gated set (thinking-selector.ts:69-73); the port floors the marker
   onto the first row (chat.rb:1767-1768).

Items 1+2 of the plan letter (gating, marker cross-resolution) are verified CLOSED on
the live tree (Grounds §1) — their shipped pins are regression guards, not work.
Settled screens must not move: s1–s9 exit 0 cold unchanged.

## Deliverables

### `lib/tart/settings.rb` — the declared-default reader

`Settings.declared_thinking_level(root:, cwd:)` → String|nil: the `thinkingLevel`
value a settings FILE declares — user `<root>/settings.json` overridden by project
`<cwd>/.tart/settings.json` (project over user, the load precedence settings.rb:103-113);
re-read from disk per call (live across mid-session `Settings.save` writes, pi's
in-memory settingsManager view). nil when NEITHER file declares the key — the port's
baked `DEFAULTS["thinkingLevel"]` never counts (pi's defaultThinkingLevel is
undefined-unless-file-declared, settings-manager.ts:758-760). A declared value
outside `THINKING_LEVELS` reads as nil (undeclared — pi's settings schema cannot
declare it). Reuse `read_file`/`ROOT_KEY`; no Result surgery, no new state.

### `lib/tart/render/chat.rb` — the switch re-clamp + the ✓ letter

In `apply_model_selection(entry, persist:)`, AFTER `@runtime_model = entry` and the
`@agent&.switch_model(...)` call, compose pi's level-for-switch and clamp it through
the SWITCHED entry's facts (already composed at chat.rb:1845 —
`Settings.thinking_facts(entry, model_id: entry[:id])`):

- level-for-switch = `Settings.declared_thinking_level(root: @settings_root, cwd: <the surface's cwd resolution>) || <the session-level reader>` (chat.rb:1524-1527 — `@thinking_level ||` the footer fallback). Pi's per-model override tier is CUT
  (Grounds ruling 3); no explicitLevel tier exists in the port (no scoped models).
  cwd source: `@footer_data&.fetch(:cwd, nil) || Dir.pwd` (the existing idiom,
  chat.rb:673).
- effective = `Models.clamp_thinking_level(level_for_switch, map: facts[:thinking_level_map], reasoning: facts[:reasoning])`
  (pi's `availableLevels.includes ? level : clamp` collapses onto the clamp's
  exact-pass branch — equivalent).
- Store BOTH states: `@thinking_level = effective` (join the existing
  `@mutex.synchronize` block that sets `@runtime_model`) and
  `@agent&.set_thinking_level(effective)` (pi swaps the model FIRST, then
  setThinkingLevel — agent-session.ts:2484-2494; keep that order).
- NO `Thinking level:` status row on the switch path — pi's setModel shows only the
  model status; `thinking_level_changed` refreshes footer+border through the
  existing `footer_data` overlay machinery (no new wiring).
- persist:true (ctrl+s in the model menu) flows through the SAME re-clamp (pi
  setModel {persist} is one path).

In `thinking_menu_items` (chat.rb:1757-1773): DELETE the display-floor
`current = levels.first unless levels.include?(current)` — the ✓ marker rides exact
equality only (pi thinking-selector.ts:69-73); an out-of-set current marks NO row
(the ModelMenu preselect already lands on index 0 when no item matches —
pi's buildSelectList :101-107 shape).

In `default_thinking_level` (chat.rb:1909-1912): prefer the NEW unclamped footer
fact, falling back to `:thinking_level` then the built-in default (additive —
existing footer-fact fixtures keep behaving).

### `bin/tart` — the boot clamp (both boots, one composition)

- `footer_data` (bin/tart:385-407): `thinking_level:` becomes
  `Models.clamp_thinking_level(Settings.resolve_thinking_level(settings), map: facts[:thinking_level_map], reasoning: facts[:reasoning])`
  — the session level the surface reader falls back to AND the interactive loop ctor
  receives (bin/tart:280) — and the hash GAINS `default_thinking_level:` =
  `Settings.resolve_thinking_level(settings)` UNCLAMPED (the thinking menu's · default
  badge source — pi marks the unclamped default, no row when out-of-set,
  Grounds §2 last bullet).
- `boot_thinking_kwargs` (bin/tart:413-417) gains the same clamped
  `thinking_level:`; `print_mode` (bin/tart:212-214) drops its explicit
  `thinking_level: Settings.resolve_thinking_level(settings)` and takes the kwarg's
  (pi createSdk clamps for every mode; one helper, both boots — the I36 discipline).

### Tests

1. `test/chat_test.rb` (the `with_chat` idiom — footer facts + staged Config
   catalogs, as the existing I28 pins do):
   - switch re-clamp: stored `xhigh` → switch to a map-less reasoning entry →
     session level `high`; agent spy (`chat.agent=` double) received
     `set_thinking_level("high")` AFTER `switch_model` (order pin).
   - switch to a `reasoning: false` entry → session level `off`.
   - declared-default tier: staged settings file declaring `"thinkingLevel": "low"`
     at the surface's `settings_root`, session level `high`, switch (map-less
     reasoning) → `low` (declared wins, pi `_getThinkingLevelForModelSwitch`).
   - no declared default → the session level survives the switch unchanged when
     in-set (`high` → `high`).
   - out-of-set declared default clamps through the new model (`xhigh` declared +
     map-less switch → `high`).
   - no status row: after a switch that re-clamps, the transcript tail carries ONLY
     the `Model: <id>` row (refute any `Thinking level:` row).
   - ✓ letter: `thinking_menu_items` with a hand-driven out-of-set stored level →
     NO item flagged current (preselect index 0 via the sealed constructor's rule).
   - the I28 regression pins (cross-resolution :2412, non-reasoning gating :2429+)
     stay green untouched.
2. `test/settings_test.rb`: `declared_thinking_level` — user file declares → value;
   project overrides user; neither → nil; value outside THINKING_LEVELS → nil;
   visible across a `Settings.save` write (fresh read).
3. `test/launcher_smoke_test.rb`: `Executable.footer_data` — staged settings
   `"thinkingLevel": "xhigh"` + a map-less reasoning chat model →
   `data[:thinking_level] == "high"` AND `data[:default_thinking_level] == "xhigh"`;
   the existing glm pins (:67-89) stay green (glm's map supports every level — the
   clamped value equals the raw one).

## Boundaries

- **May touch (the lane's frozen set):** `lib/tart/render/chat.rb`,
  `lib/tart/settings.rb`, `bin/tart`, `test/chat_test.rb`, `test/settings_test.rb`,
  `test/launcher_smoke_test.rb`. Nothing else.
- **Must not touch:** `lib/tart/agent/loop.rb` (the seams exist:
  `set_thinking_level`/`switch_model`), `lib/tart/models.rb` (the clamp exists),
  `lib/tart/render/model_menu.rb`, `lib/tart/commands.rb`, `lib/tart/print.rb` (its
  internal default is dead through the CLI path), `lib/tart/render/transcript.rb`,
  `footer.rb`, `theme.rb`, `editor.rb`, `test/parity/**`, `gems/**` (the probe
  re-run is evidence, not an edit), every other test file.
- **Out of scope (itemized, Grounds §4/§5):** per-model thinking-level overrides;
  session-file `thinking_level_change`/`model_change` entries; the badge-ref
  semantics realignment (I28 shape stands); the `Commands::Handler` full-ladder
  branch (frozen I27 shape, surface-gated); `ModelMenu.thinking`'s sealed
  full-ladder constructor; any menu byte/layout change; the rig.
- No placeholders; search before implementing; PHASE 0 disagreements with
  citations mandatory.

## Tool guidance

- Verification (tart): `bundle install --quiet && bundle exec rake`;
  `bundle exec ruby bench/seam_bench.rb`. Parity gates (integrated tree at judge;
  in your tree use SHORT out-dirs, allow 60 s+ each):
  `bundle exec ruby gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s<N>.yml --out tmp/<short>`
  for s1–s9 (exit 0 cold each; the lane-worktree s9 deep-path exit 1 is the known
  I34/I36/I39-ruled environmental artifact — canonical-depth re-run is the record).
- Probe re-run (evidence, archive stdout + frames under
  `build/I40-model-catalog-polish/`): `ruby gems/tui-split-rig/bin/model-menu-probe --out tmp/mmp-i40`
  (stdlib only, no Bundler) — completes, both apps' model+thinking menus captured,
  no TIMEOUT.
- pi sources (read before coding; cite what you port):
  `packages/coding-agent/src/core/agent-session.ts` (:2477-2496 setModel,
  :2610-2634 setThinkingLevel, :2641-2653 cycleThinkingLevel, :2656-2662
  getAvailableThinkingLevels, :2670-2679 _getThinkingLevelForModelSwitch,
  :2683-2685 _clampThinkingLevel), `packages/ai/src/models.ts` (:1224-1254),
  `packages/coding-agent/src/core/sdk.ts` (:268-279 the boot clamp),
  `packages/coding-agent/src/core/settings-manager.ts` (:758-770),
  `packages/coding-agent/src/modes/interactive/components/thinking-selector.ts`
  (:69-73, :101-107), `packages/coding-agent/src/modes/interactive/interactive-mode.ts`
  (:5165-5191, :5342-5367, :3495-3498). Port seam cites: chat.rb:1030-1039,
  :1376-1382, :1524-1527, :1563-1571, :1692-1773, :1837-1912; settings.rb:55,
  :103-113, :145-156, :226-236, :238-252; models.rb:186-241; loop.rb:130-181,
  :574-600; bin/tart:194-214, :264-282, :385-417.
- Output format: file list + wc; the level-resolution table (each pin case: input
  state → level-for-switch → effective level, with the pi cite); verbatim test
  tails + suite counts (base 763/3092); probe re-run stdout tail; STATUS line last.

## Lane plan

One lane — the work is one seam family on chat.rb (single-writer by design).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/settings.rb
    - bin/tart
    - test/chat_test.rb
    - test/settings_test.rb
    - test/launcher_smoke_test.rb
```

## Effort

Set at dispatch (`architect dispatch --effort`): high — the changes are small in
line count but every one is a frozen-parity seam (the stored level feeds footer,
border, menu, and wire); the pin matrix is the deliverable's other half.

## Acceptance Criteria

# I40 model-catalog-polish — Acceptance Criteria (scratch → `architect section`)

**AC1 (the switch re-clamp, pi's setModel path).** Every model switch through
`Render::Chat#apply_model_selection` (the /model menu's select, the `/model <ref>`
direct switch, ctrl+s select-and-persist — one path) resolves the level pi's way:
level-for-switch = the FILE-DECLARED thinking-level default (project over user;
absent → keep the session level; per-model tier CUT itemized), then clamped through
the SWITCHED entry's composed facts (`Models.clamp_thinking_levels` family —
`clamp_thinking_level`); the effective level lands in BOTH the surface state and the
loop seam (`set_thinking_level` AFTER `switch_model`, pi's order); NO `Thinking
level:` status row is enqueued on the switch path. Pinned by chat tests: stored
`xhigh` → map-less reasoning switch → `high`; → non-reasoning switch → `off`;
declared default wins over the session level; no-declared keeps an in-set session
level; out-of-set declared default clamps; the agent spy's call order; the
no-status-row refute. The tripwire gate (`switch-tier`) is RED at base by design —
the machinery is this iteration's deliverable; the pins are the proof.

**AC2 (the boot clamp + the unclamped badge source).** Both boot compositions
(bin/tart's `footer_data` for interactive, `boot_thinking_kwargs` for print — one
clamp, both sites) clamp the settings-resolved level through the boot model's
composed facts: the interactive loop ctor and the surface's session-level fallback
receive the CLAMPED level; the thinking menu's · default badge source stays
UNCLAMPED via the new `default_thinking_level:` footer fact (pi marks the unclamped
default; an out-of-set default marks no row). Pinned by launcher pins
(`Executable.footer_data`: staged `xhigh` + map-less reasoning →
`thinking_level: "high"` AND `default_thinking_level: "xhigh"`) and the existing glm
footer pins stay green. Tripwire gate (`boot-fact`) RED at base by design.

**AC3 (the ✓ letter).** `thinking_menu_items` marks NO current row when the stored
level is outside the gated set (pi thinking-selector.ts:69-73 — the display-floor is
deleted); the sealed constructor's preselect rule lands on index 0 when nothing
matches (pi buildSelectList :101-107). Pinned by a chat test driving the out-of-set
corner. Tripwire gate (`floor-gone`) RED at base by design.

**AC4 (regression guards + settled screens + probe evidence).** The I28-delivered
gating and marker cross-resolution stay exactly as shipped (their existing pins
green, untouched); s1–s9 exit 0 cold on the integrated tree (settled screens
unmoved — the lane-worktree s9 deep-path exit 1 is the known I34/I36/I39-ruled
environmental artifact; canonical-depth is the record); the model-menu probe re-runs
to completion with both apps' model+thinking menu frames captured (no TIMEOUT) and
its stdout + frames archived under `build/I40-model-catalog-polish/` (evidence, not
a parity gate — I27's instrument header).

**AC5 (scope discipline).** The integrated diff touches exactly the frozen lane set
(`lib/tart/render/chat.rb`, `lib/tart/settings.rb`, `bin/tart`, `test/chat_test.rb`,
`test/settings_test.rb`, `test/launcher_smoke_test.rb`); the report itemizes the
cuts and the standing deviations (per-model overrides; session-file entries; badge
ref; the OQ dispositions from Grounds §5).

**AC6 (suite + bench).** `bundle exec rake` fully green with run-count delta > 0
(base 763 runs / 3092 assertions); `bundle exec ruby bench/seam_bench.rb` prints
`SEAM_BENCH_OK`.

```gates
- id: suite-green
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench-ok
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    stdout_match: SEAM_BENCH_OK

- id: s1-s9-cold
  ac: AC4
  cwd: repos/tart
  cmd: |-
    status=0
    for n in 1 2 3 4 5 6 7 8 9; do
      s="s${n}"
      case "$n" in 1) s=s1_text_turn;; 2) s=s2_tool_turn;; 3) s=s3_tool_turn_files;; 4) s=s4_bash_variants;; 5) s=s5_bash_truncation;; 6) s=s6_long_calls;; 7) s=s7_compaction;; 8) s=s8_zero_usage_compaction;; 9) s=s9_startup_help;; esac
      bundle exec ruby gems/tui-split-rig/bin/tui-split-rig run "gems/tui-split-rig/scenarios/${s}.yml" --out "tmp/g${n}" >/dev/null 2>&1 || status=1
    done
    test "$status" -eq 0 && echo S_COLD_OK
  expect:
    exit_code: 0
    stdout_match: S_COLD_OK

- id: probe-rerun
  ac: AC4
  cwd: repos/tart
  cmd: |-
    ruby gems/tui-split-rig/bin/model-menu-probe --out tmp/mmp-gate >tmp/mmp-gate.log 2>&1
    grep -q TIMEOUT tmp/mmp-gate.log && exit 1
    grep -q 'model-menu-probe\|frames at' tmp/mmp-gate.log || exit 1
    echo PROBE_OK
  expect:
    exit_code: 0
    stdout_match: PROBE_OK

- id: switch-tier
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'declared_thinking_level' lib/tart/settings.rb && grep -q 'declared_thinking_level' lib/tart/render/chat.rb && echo SWITCH_TIER_OK
  expect:
    stdout_match: SWITCH_TIER_OK

- id: boot-fact
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q 'default_thinking_level' bin/tart && echo BOOT_FACT_OK
  expect:
    stdout_match: BOOT_FACT_OK

- id: floor-gone
  ac: AC3
  cwd: repos/tart
  cmd: |-
    ! grep -q 'levels.first unless levels.include?' lib/tart/render/chat.rb && echo NO_FLOOR_OK
  expect:
    stdout_match: NO_FLOOR_OK

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I40-model-catalog-polish-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section model-catalog-polish prompt --append --lane <lane> --from build/I40-model-catalog-polish-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I40-model-catalog-polish-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence model-catalog-polish --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section model-catalog-polish verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify model-catalog-polish`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
