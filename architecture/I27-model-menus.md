# I27: model-menus

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I27 model-menus

Measured this session (2026-10-12) at base **fcf232f4** (= `project/pi-port` tip after I26):

1. **Owner rulings (this session, decisions log 2026-10-12).** (a) `/model` + multi-model
   config is the next daily-driver blocker — models defined via pi's `models.json` shape,
   tart reads `~/.tart/models.json`; (b) `/model` and `/thinking` open SELECTOR MENUS
   (the owner: "the same component insofar as they seem to work the same way") — fuzzy
   text input across word + description, arrow navigation, click-to-select, help line
   `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel`; (c) both menus
   observable via the rig; (d) the compaction arithmetic goes usage-backed next
   iteration (NOT this one — chat.rb single-writer forces waves; see Lane plan).

2. **pi's selector family (measured, packages/coding-agent/src/modes/interactive/components/):**
   `model-selector.ts` (421 l) and `thinking-selector.ts` (154 l) — one family, two classes.
   Shared shape: DynamicBorder top/bottom, Spacer(1), a title line ("Thinking Level" /
   the model list's scope hint), an `Input` search field whose typing fuzzy-filters
   (`fuzzyFilter`, tui/src/fuzzy.ts:100 — query tokens split `/[\s/]+/`), the list
   (model-selector hand-rolls it; thinking-selector uses `SelectList` with a
   primary-column layout), and a dim help line built from `keyDisplayText`:
   `<confirm> to select · <save> to set as default · <cancel> to cancel` (resolves to
   `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel`).
   Navigation (both): up/down with WRAP (model-selector :392-401), Enter selects,
   Escape/Ctrl+C cancels, ctrl+s = select-and-persist; everything else goes to the
   search input and re-filters. Thinking items carry `✓ ` for current +
   `<description> · default` badge (LEVEL_DESCRIPTIONS table :22-31: "No reasoning",
   "Very brief reasoning (~1k tokens)", … "Maximum reasoning"). Model rows:
   `→ ` cursor (accent) + `✓ ` current marker + `<id>` + dim `[<provider>]` +
   ` · default` badge; a `(n/N)` scroll indicator when the 10-row window truncates;
   a dim `  Model Name: <name>` line for the selected row; sorted current-first,
   default-second, then provider (model-selector :255-273). SelectList handles
   click-to-select via mouse press/release index tracking (select-list.ts:109-134).
   Scope: model-selector has an all|scoped tab toggle + "Only showing models from
   configured providers. Use /login to add providers." warning when unscoped —
   tart has one provider config surface, scopedModels is empty there.

3. **Command flow (interactive-mode.ts:5142-5205, 5355-5392).** `/model` no-arg →
   selector; arg exact-matching a known model reference (`provider/model` or `model`)
   → switch directly + status `Model: <id>`; unknown arg → selector pre-seeded with
   the search text. `/thinking` no-arg → selector (the port's current no-arg CYCLE is
   the pre-menu stand-in — replaced); arg must exactly name a level else error
   listing available levels. `selectThinkingLevel(level, persist)` /
   `selectModel(model, persist)`: session swap + `footer.invalidate()` +
   `updateEditorBorderColor()` + status (`Default thinking level: <lvl>` /
   `Default model: <provider>/<id>` when persisted). **showSelector mechanics
   (:4884-4906): the selector REPLACES the editor** — `editorContainer.clear();
   addChild(selector)`, `done()` restores the editor + focus — exactly the port's
   Picker precedent (I15: "renders the session list in place of the editor").

4. **Keybindings (core/keybindings.ts).** `app.model.select` = **ctrl+l** (open model
   selector); `app.model.cycleForward/cycleBackward` = ctrl+p / shift+ctrl+p;
   `app.thinking.cycle` = shift+tab (the port HAS this); `app.thinking.save` /
   `app.models.save` = **ctrl+s**; `tui.select.confirm/cancel` = enter / escape,ctrl+c;
   `app.message.copy` = ctrl+x (copy selection or last assistant — rides the
   whole-screen-selection wave, NOT this iteration).

5. **pi's models.json (core/model-config.ts).** Agent-dir `models.json`, JSONC
   (comments stripped) + BOM-tolerant, validated by schema: `providers: {<id>:
   {name?, baseUrl?, apiKey?, api?, headers?, models?: [{id, name?, api?, baseUrl?,
   reasoning?, contextWindow?, maxTokens?, …}], modelOverrides?}}`; invalid file →
   error message naming the file (never a crash). `settings.json` carries
   `defaultProvider` + `defaultModel` (settings-manager getDefaultProvider/
   getDefaultModel — the WRITE path persists the ctrl+s "set as default").

6. **The port's current state (measured at fcf232f4).** `Settings::DEFAULTS` already
   has `defaultModel`/`defaultProvider` (+ `TART_MODEL`/`TART_PROVIDER` env resolution,
   settings.rb:37-63); `bin/tart build_chat` (:358-370) constructs ONE RubyLLM chat
   from resolved settings (openai-completions protocol, `assume_model_exists: true`)
   — no models.json, no switching; `Commands::BUILTINS` has `/thinking`
   (cycle/set-text, no menu) and NO `/model`; chat.rb has the Picker in-place-editor
   precedent + the I22 autocomplete fuzzy trio + footer model segment
   (footer_data=` seam) + the thinking-level editor-border ladder (5af076d);
   `Agent::Loop` takes `context_window:` at construction (no recompute seam);
   ruby_llm 2.1.0 `Chat#with_model(model_id, provider:)` exists (gem chat.rb:609) —
   switching mid-session has a gem path to verify against.

7. **Rig state.** s1–s6 exit 0 cold at fcf232f4 (this session's gate run); s7 exit 1
   by design (the compaction panel — I28, untouched here); the rig stages pi's
   models.json already (mock provider, `context_window:` seam from I26); the probe
   precedent (I26 `bin/tool-pending-probe` — drives panes directly through Runner's
   public seams) extends naturally to menus: boot, settle, `send-keys` the
   `/model`/`/thinking` opening keystrokes, capture mid-menu frames, drive a
   selection, capture the result. **Known rig defect (backlog, queued into this
   iteration's rig lane):** `assert_clean_sessions!` counts sibling lanes'
   `tui-split-rig-*` sessions on the shared default tmux server (spurious exit 2;
   one agent's kill-server kills every agent's sessions — observed mid-probe in I26).

8. **Control (this session, base fcf232f4).** Suite 471 runs / 1855 assertions /
   0 failures / 0 errors / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0 cold;
   s7 exit 1 (by design). All regression claims below are against this baseline.

**Lane plan:** two parallel lanes, disjoint by construction — `model`
(lib/tart/models.rb new, settings.rb, commands.rb, render/chat.rb,
render/model_menu.rb new, render/footer.rb, agent/loop.rb, bin/tart, test/**) and
`rig` (gems/tui-split-rig/** only). chat.rb is single-writer: the whole-screen
selection slice (owner nit) and the compaction family (panel + usage-backed
arithmetic, owner-ruled) are deliberately NOT here — they queue as I27 wave 2
(selection: chat.rb + selection.rb) and I28 (compaction: panel lane + usage lane,
parallel), sequenced off this iteration's integrated tip.

## Specification

# Specification — I27 model-menus

- **Objective.** The owner's next daily-driver blocker (BRIEF §3, Grounds 1): make tart
  a multi-model client — models defined via pi's `models.json` shape
  (`~/.tart/models.json`), switchable at runtime through `/model` and the thinking
  menu through `/thinking`, both as selector menus ported from pi's selector family
  (Grounds 2-3), with the ctrl+s set-as-default persistence (Grounds 5). Second
  deliverable, parallel: the rig gains menu observability (probes for both menus, the
  I26 probe precedent) + the tmux shared-server hardening (Grounds 7) so menu parity
  is measurable and the rig stops flaking under parallel lanes. Why now: the owner
  cannot switch models without restarting tart with different env vars today; the
  selector menus are the last major editor-area surface unported; and every future
  rig lane pays the tmux flake tax until hardened.

- **Lane `model` (high effort — the owner's blocker; new config + new component + switching seams).**
  - Deliver **config**: `lib/tart/models.rb` — `Tart::Models` loading `~/.tart/models.json`
    (pi model-config.ts: JSONC-tolerant, BOM-stripped, schema-validated subset:
    providers `{name, baseUrl, apiKey, api, models: [{id, name, reasoning,
    contextWindow, maxTokens}]}`; invalid file → error naming the file, never a
    crash). Resolution order for the boot model: `TART_MODEL`/`TART_PROVIDER` env >
    models.json default > `Settings` defaultModel/defaultProvider (verify against pi's
    model-resolver precedence; itemize any deviation). Env keys (`TART_API_KEY`,
    `TART_API_BASE`) keep working against the resolved provider.
  - Deliver **the selector component**: `lib/tart/render/model_menu.rb` — one component
    family serving BOTH menus (pi has two classes sharing one shape; unify or mirror,
    the builder's call — itemize the choice). Ported surface (Grounds 2): bordered
    (DynamicBorder analog), title ("Thinking Level" for the thinking menu), fuzzy
    `Input` over word+description (thinking) / id+provider+name (model —
    getModelSelectorSearchText's text), up/down with wrap, enter selects,
    escape/ctrl+c cancels, ctrl+s selects-and-persists, click-to-select
    (press/release index tracking, select-list.ts:109-134), the dim help line
    resolving to `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to
    cancel`, current `✓` marker, `· default` badge, `(n/N)` scroll indicator at the
    10-row window, the model menu's `  Model Name: <name>` line and current-first
    default-second-provider sort, the thinking menu's LEVEL_DESCRIPTIONS table and
    description column. In-place-of-the-editor mounting (the Picker/showSelector
    precedent, Grounds 3) — done restores the editor + focus.
  - Deliver **commands + switching**: `Commands::BUILTINS` gains `/model`
    (argumentHint `<provider/model>`); `/model` no-arg → menu, exact arg → direct
    switch + `Model: <id>` status, unknown arg → menu pre-seeded with the arg;
    `/thinking` no-arg → the MENU (replacing the cycle stand-in; shift+tab cycle
    stays), exact arg → direct set, bad arg → the error listing levels (unchanged).
    Model switching mid-session: the gem path (`Chat#with_model` — verify live) or
    an equivalent seam; `Agent::Loop` gains a model/context-window recompute seam
    (switch must re-resolve the window); footer model segment refreshes
    (footer_data= / invalidate path) and the editor border re-ladders
    (thinking-level switch). ctrl+l opens the model menu (app.model.select);
    ctrl+p / shift+ctrl+p model cycling is a STRETCH item — itemize as cut if not
    delivered, never silent.
  - Deliver **persistence**: the ctrl+s set-as-default writes `defaultProvider` +
    `defaultModel` to `~/.tart/settings.json` (pi settings-manager write path;
    Settings gains its first write surface — preserve unknown keys on write, never
    clobber) + status `Default model: <provider>/<id>` / `Default thinking level:
    <level>`.
  - Tests: direct-class tests for Models (load/validate/JSONC/errors) and the menu
    component (filter/nav/select/persist/cancel/click — drive public behavior); the
    existing edit_input/chat_test pattern for the command dispatches + ctrl+l/ctrl+s
    key routes + the switch seams (footer refresh, border re-ladder, window
    recompute). Model the assertions on pi's editor/menu behavior where observable.
  - Touch: `lib/tart/models.rb` (new), `lib/tart/settings.rb`,
    `lib/tart/commands.rb`, `lib/tart/render/chat.rb`,
    `lib/tart/render/model_menu.rb` (new), `lib/tart/render/footer.rb`,
    `lib/tart/agent/loop.rb`, `bin/tart`, `test/chat_test.rb` (binding/dispatch
    cases), `test/commands_test.rb` (/model dispatch), `test/settings_test.rb`
    (the write path), `test/agent_loop_test.rb` (the switching seam, if
    loop-tested), `test/models_test.rb` (new), `test/render/model_menu_test.rb`
    (new). Must not: gems/**, `test/parity/**`,
    `lib/tart/render/selection.rb`, `lib/tart/render/editor.rb`,
    `lib/tart/render/transcript.rb`, `lib/tart/compaction.rb`, `lib/tart/theme.rb`,
    `lib/tart/tui.rb`, any scenario or registry file.

- **Lane `rig` (high effort — new probe family + hardening).**
  - Deliver **menu probes** (the I26 tool-pending-probe precedent — drive panes
    directly through Runner's public seams): a probe that boots each app, settles,
    `send-keys` opens `/model` (and `/thinking`) — verify the exact keystrokes each
    app needs (tart's editor dispatch vs pi's) — captures mid-menu frames (plain +
    styled), drives a selection (enter on the highlighted row), and captures the
    post-selection settled screen. Deliver the captured evidence + a candidate
    table (pi's menu bytes vs tart's — the settled-screen comparator does not apply
    to transient menus; the diff table IS the deliverable, the s4/s5/s6/s7 pattern).
    Staging: the rig stages `~/.tart/models.json` for tart (pi's models.json staging
    already exists — mirror it: ≥2 mock models so the menu has something to select)
    — the frozen contract is pi's models.json schema at `~/.tart/models.json`
    (Grounds 5/6).
  - Deliver **tmux hardening** (backlog, Grounds 7): scoped session naming or a
    per-run server socket so concurrent rig processes cannot flake each other's
    `assert_clean_sessions!` or kill each other's sessions — prove it with a
    CONCURRENT run of two scenarios both exiting 0 (the gate does this).
  - Hard constraint: s1–s7 exit codes unchanged (s1–s6 = 0, s7 = 1 — the compaction
    panel is I28, untouched here); registry changes ADDITIONS ONLY.
  - Touch: `gems/tui-split-rig/**` (scenarios, probes, lib, bin, registry, test).
    Must not: anything outside gems/tui-split-rig/, esp. `lib/tart/**`, `test/**`,
    `bin/tart`.

- **Output format (both lanes).** Raw evidence to scratch: file list + wc; for model —
  the command/keybinding table (pi → port, before/after) + verbatim test tails +
  suite counts + the models.json resolution-precedence table; for rig — the probe
  command lines + exit codes + the menu-bytes candidate table + the concurrent-run
  proof output + the registry diff. PHASE 0 disagreements mandatory (the Grounds 2-6
  premises are checkable). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`,
  `bundle exec ruby bench/seam_bench.rb`; rigs:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources at `repos/pi/packages/coding-agent/src/` (the selector
  components, interactive-mode.ts:4884-5440, core/keybindings.ts, core/model-config.ts,
  core/model-resolver.ts) and `repos/pi/packages/tui/src/` (fuzzy.ts, select-list.ts) —
  read before coding; cite what you port. ruby_llm 2.1.0 gem source at
  `~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/`
  (chat.rb:609 with_model) — verify the switching path live before building on it.

- **Boundaries.** Sanctioned scope is exactly the two lanes above. Out of scope: the
  whole-screen selection slice (footer/editor rows — wave 2), the compaction panel +
  usage-backed arithmetic (I28), toolPendingBg, model CATALOG refresh (pi's
  refreshModelCatalogs network path — tart reads the static models.json; itemize as
  cut), the scopedModels/all-scope tab toggle (pi's multi-provider scope machinery —
  cut, itemized; one models.json is the whole catalog), /login, the ctrl+x
  copy-selection-or-last-message key (rides the selection wave), undo-stack,
  multi-line editor. No placeholders; search before implementing.

```lanes
- name: model
  repo: tart
  touch:
    - lib/tart/models.rb
    - lib/tart/settings.rb
    - lib/tart/commands.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/model_menu.rb
    - lib/tart/render/footer.rb
    - lib/tart/agent/loop.rb
    - bin/tart
    - test/chat_test.rb
    - test/commands_test.rb
    - test/settings_test.rb
    - test/agent_loop_test.rb
    - test/models_test.rb
    - test/render/model_menu_test.rb
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I27 model-menus

**AC1 (models config).** `lib/tart/models.rb` loads `~/.tart/models.json` with pi's
schema subset (providers with models; JSONC-tolerant, BOM-stripped); a missing file
falls back to the Settings defaults cleanly; an INVALID file surfaces an error naming
the file (never a crash). The boot model resolves env > models.json > Settings
(precedence verified against pi's model-resolver, any deviation itemized). Direct-class
tests pin load/validate/error behavior.

**AC2 (the selector menus).** `/thinking` with no arg opens the Thinking Level menu
(fuzzy input over level word + description, ✓ current marker, · default badge,
description column); `/model` with no arg opens the model menu (fuzzy over
id+provider+name, ✓/default badges, `(n/N)` scroll indicator, `  Model Name: <name>`
line, current-first sort); both: arrow navigation with wrap, enter selects,
escape/ctrl+c cancels, ctrl+s selects-and-persists, click-to-select, the dim help
line `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel`, mounted
in place of the editor (done restores the editor). Direct-class tests pin
filter/nav/select/persist/cancel; chat_test pins the dispatch wiring. `/model <arg>`
exact-match switches directly (`Model: <id>` status); unknown arg opens the menu
pre-seeded. shift+tab thinking cycle unchanged.

**AC3 (switching + persistence).** Selecting a model swaps the runtime chat model,
re-resolves the context window (the loop seam), refreshes the footer model segment,
and re-ladders the editor border; the gem switching path (`Chat#with_model` or
verified equivalent) is exercised by a test. ctrl+s persists `defaultProvider` +
`defaultModel` to `~/.tart/settings.json` preserving unknown keys, with the
`Default model: <provider>/<id>` / `Default thinking level: <level>` status lines.
ctrl+l opens the model menu.

**AC4 (parity + registry discipline).** Cold from the integrated tree: s1–s6 all
exit 0 (settled screens unshifted); s7 still exits 1 (compaction panel untouched);
registry.yml additions-only (`git show fcf232f4:... | diff -` shows no `<` lines).

**AC5 (scope discipline).** The integrated diff touches exactly the two lanes'
enumerated files (AC-listed model set + gems/tui-split-rig/**). selection.rb,
editor.rb, transcript.rb, compaction.rb, theme.rb, tui.rb, and test/parity/** are
untouched.

**AC6 (suite + bench).** The default rake task fully green (run-count delta > 0 —
new tests) and the seam bench prints `SEAM_BENCH_OK`.

**AC7 (rig: menu probes + hardening).** The menu probe captures both apps'
`/model` and `/thinking` menus mid-flight (plain + styled frames) and the
post-selection settled screen, with a candidate table (pi's menu bytes vs tart's)
in the rig lane's report; tart's staged `~/.tart/models.json` carries ≥2 mock
models; the tmux hardening lets two scenarios run CONCURRENTLY with both exiting 0
(the gate runs exactly that).

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: models-class
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/models.rb && grep -q 'module Models\|class Models' lib/tart/models.rb && test -f test/models_test.rb && echo MODELS_OK
  expect:
    exit_code: 0
    stdout_match: MODELS_OK

- id: menu-class
  ac: AC2
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/model_menu.rb && test -f test/render/model_menu_test.rb && grep -q 'to select' lib/tart/render/model_menu.rb && echo MENU_OK
  expect:
    exit_code: 0
    stdout_match: MENU_OK

- id: model-command
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q '"model"' lib/tart/commands.rb && grep -q 'model_menu\|ModelMenu\|Menu' lib/tart/render/chat.rb && echo MODEL_CMD_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_CMD_OK

- id: ctrll-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q 'when "l"' lib/tart/render/chat.rb && grep -q 'when "s"' lib/tart/render/chat.rb && echo CTRL_KEYS_OK
  expect:
    exit_code: 0
    stdout_match: CTRL_KEYS_OK

- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-still-baselined
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git show fcf232f4:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: concurrent-rig
  ac: AC7
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/conc-a > tmp/conc-a.log 2>&1 &
    p1=$!
    sleep 2
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/conc-b > tmp/conc-b.log 2>&1 &
    p2=$!
    wait $p1; e1=$?
    wait $p2; e2=$?
    if [ "$e1" -eq 0 ] && [ "$e2" -eq 0 ]; then echo CONCURRENT_OK; else echo "concurrent exits: $e1 $e2 (b started 2s after a — each run's end-of-run leftover check must not see the other's live sessions)"; exit 1; fi
  expect:
    exit_code: 0
    stdout_match: CONCURRENT_OK

- id: sealed-files-untouched
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only fcf232f4 HEAD | grep -qvE '^(lib/tart/models.rb|lib/tart/settings.rb|lib/tart/commands.rb|lib/tart/render/chat.rb|lib/tart/render/model_menu.rb|lib/tart/render/footer.rb|lib/tart/agent/loop.rb|bin/tart|test/chat_test.rb|test/commands_test.rb|test/settings_test.rb|test/agent_loop_test.rb|test/models_test.rb|test/render/model_menu_test.rb|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### model

# Lane dispatch — I27 model-menus, lane `model`

**You are lane `model`.** You are ONE of two parallel lane agents (the other is lane
`rig`, isolated in its own worktree — its territory is `gems/tui-split-rig/**`,
which you must NEVER touch). Your lane's territory, exhaustively:

- **Touch (exactly these files):** `lib/tart/models.rb` (new), `lib/tart/settings.rb`,
  `lib/tart/commands.rb`, `lib/tart/render/chat.rb`,
  `lib/tart/render/model_menu.rb` (new), `lib/tart/render/footer.rb`,
  `lib/tart/agent/loop.rb`, `bin/tart`, `test/chat_test.rb`, `test/commands_test.rb`,
  `test/settings_test.rb`, `test/agent_loop_test.rb`, `test/models_test.rb` (new),
  `test/render/model_menu_test.rb` (new).
- **Must not touch:** everything else — in particular `gems/tui-split-rig/**`
  (lane rig's), `lib/tart/render/selection.rb`, `lib/tart/render/editor.rb`,
  `lib/tart/render/transcript.rb`, `lib/tart/compaction.rb`, `lib/tart/theme.rb`,
  `lib/tart/tui.rb`, `test/parity/**`. Files outside this list belong to other
  agents or are sealed — touching them fails your lane.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them (notably: ruby_llm 2.1.0 `Chat#with_model` — gem source at
~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
chat.rb:609 — verify the switching path live before building on it; and pi's
model-resolver precedence in repos/pi/packages/coding-agent/src/core/).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive collection/enumerable forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Consistency with the surrounding code
is part of correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write) is
not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout (the rig runs
below take tens of seconds each — allow 120s+ each). If a runtime will not
start unattended, record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the scratch
file given to you below (an absolute path OUTSIDE your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I27-model-menus-model/report.md

## Your lane's specification (lane `model` ONLY — the other lane's deliverables are NOT yours)

- **Objective.** The owner's next daily-driver blocker: make tart a multi-model
  client — models defined via pi's `models.json` shape (`~/.tart/models.json`),
  switchable at runtime through `/model`, with `/thinking` upgraded from the
  cycle stand-in to the full selector menu — both menus ported from pi's selector
  family, with the ctrl+s set-as-default persistence.

- Deliver **config**: `lib/tart/models.rb` — `Tart::Models` loading
  `~/.tart/models.json` (pi model-config.ts: JSONC-tolerant, BOM-stripped,
  schema-validated subset: providers `{name, baseUrl, apiKey, api, models:
  [{id, name, reasoning, contextWindow, maxTokens}]}`; invalid file → error
  naming the file, never a crash). Resolution order for the boot model:
  `TART_MODEL`/`TART_PROVIDER` env > models.json default > `Settings`
  defaultModel/defaultProvider (verify against pi's model-resolver precedence;
  itemize any deviation). Env keys (`TART_API_KEY`, `TART_API_BASE`) keep working
  against the resolved provider.
- Deliver **the selector component**: `lib/tart/render/model_menu.rb` — one
  component family serving BOTH menus (pi has two classes sharing one shape;
  unify or mirror, your call — itemize the choice). Ported surface: bordered,
  title ("Thinking Level" for the thinking menu), fuzzy `Input` over
  word+description (thinking) / id+provider+name (model — pi's
  getModelSelectorSearchText text shape), up/down with wrap, enter selects,
  escape/ctrl+c cancels, ctrl+s selects-and-persists, click-to-select
  (press/release index tracking, pi select-list.ts:109-134), the dim help line
  resolving to `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to
  cancel`, current `✓` marker, `· default` badge, `(n/N)` scroll indicator at
  the 10-row window, the model menu's `  Model Name: <name>` line and
  current-first default-second-provider sort, the thinking menu's
  LEVEL_DESCRIPTIONS table ("No reasoning", "Very brief reasoning (~1k tokens)",
  … "Maximum reasoning") and description column. In-place-of-the-editor mounting
  (the port's Picker precedent + pi showSelector :4884-4906) — done restores the
  editor + focus.
- Deliver **commands + switching**: `Commands::BUILTINS` gains `/model`
  (argumentHint `<provider/model>`); `/model` no-arg → menu, exact arg → direct
  switch + `Model: <id>` status, unknown arg → menu pre-seeded with the arg;
  `/thinking` no-arg → the MENU (replacing the cycle stand-in; shift+tab cycle
  stays), exact arg → direct set, bad arg → the error listing levels (unchanged).
  Model switching mid-session: the gem path (`Chat#with_model` — verify live) or
  an equivalent seam; `Agent::Loop` gains a model/context-window recompute seam
  (switch must re-resolve the window); footer model segment refreshes and the
  editor border re-ladders (thinking-level switch). ctrl+l opens the model menu
  (pi app.model.select); ctrl+p / shift+ctrl+p model cycling is a STRETCH item —
  itemize as cut if not delivered, never silent.
- Deliver **persistence**: the ctrl+s set-as-default writes `defaultProvider` +
  `defaultModel` to `~/.tart/settings.json` (pi settings-manager write path;
  Settings gains its first write surface — preserve unknown keys on write, never
  clobber) + status `Default model: <provider>/<id>` / `Default thinking level:
  <level>`.
- Tests: direct-class tests for Models (load/validate/JSONC/errors) and the menu
  component (filter/nav/select/persist/cancel/click — drive public behavior);
  the existing edit_input/chat_test pattern for the command dispatches +
  ctrl+l/ctrl+s key routes + the switch seams (footer refresh, border re-ladder,
  window recompute). Model the assertions on pi's editor/menu behavior where
  observable.
- **Boundaries for this lane:** the touch list above is exhaustive. Out of
  scope: model CATALOG refresh (pi's refreshModelCatalogs network path — tart
  reads the static models.json; itemize as cut), the scopedModels/all-scope tab
  toggle (cut, itemized; one models.json is the whole catalog), /login, the
  ctrl+x copy-selection-or-last-message key, undo-stack, multi-line editor. No
  placeholders; search before implementing.

- **Tool guidance.** Verification: `bundle install --quiet && bundle exec rake`,
  `bundle exec ruby bench/seam_bench.rb`. pi sources at
  `repos/pi/packages/coding-agent/src/` (components/model-selector.ts,
  components/thinking-selector.ts, interactive-mode.ts:4884-5440,
  core/keybindings.ts, core/model-config.ts, core/model-resolver.ts) and
  `repos/pi/packages/tui/src/` (fuzzy.ts, select-list.ts) — read before coding;
  cite what you port. Output format: file list + wc; the command/keybinding
  table (pi → port, before/after) + verbatim test tails + suite counts + the
  models.json resolution-precedence table. PHASE 0 disagreements mandatory.
  STATUS line last.

## Acceptance Criteria (frozen — verify against these)

**AC1 (models config).** `lib/tart/models.rb` loads `~/.tart/models.json` with pi's
schema subset (providers with models; JSONC-tolerant, BOM-stripped); a missing file
falls back to the Settings defaults cleanly; an INVALID file surfaces an error naming
the file (never a crash). The boot model resolves env > models.json > Settings
(precedence verified against pi's model-resolver, any deviation itemized). Direct-class
tests pin load/validate/error behavior.

**AC2 (the selector menus).** `/thinking` with no arg opens the Thinking Level menu
(fuzzy input over level word + description, ✓ current marker, · default badge,
description column); `/model` with no arg opens the model menu (fuzzy over
id+provider+name, ✓/default badges, `(n/N)` scroll indicator, `  Model Name: <name>`
line, current-first sort); both: arrow navigation with wrap, enter selects,
escape/ctrl+c cancels, ctrl+s selects-and-persists, click-to-select, the dim help
line `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel`, mounted
in place of the editor (done restores the editor). Direct-class tests pin
filter/nav/select/persist/cancel; chat_test pins the dispatch wiring. `/model <arg>`
exact-match switches directly (`Model: <id>` status); unknown arg opens the menu
pre-seeded. shift+tab thinking cycle unchanged.

**AC3 (switching + persistence).** Selecting a model swaps the runtime chat model,
re-resolves the context window (the loop seam), refreshes the footer model segment,
and re-ladders the editor border; the gem switching path (`Chat#with_model` or
verified equivalent) is exercised by a test. ctrl+s persists `defaultProvider` +
`defaultModel` to `~/.tart/settings.json` preserving unknown keys, with the
`Default model: <provider>/<id>` / `Default thinking level: <level>` status lines.
ctrl+l opens the model menu.

**AC5 (scope discipline).** The integrated diff touches exactly the two lanes'
enumerated files. selection.rb, editor.rb, transcript.rb, compaction.rb, theme.rb,
tui.rb, and test/parity/** are untouched.

**AC6 (suite + bench).** The default rake task fully green (run-count delta > 0 —
new tests) and the seam bench prints `SEAM_BENCH_OK`.

Gate commands you can run to self-verify (frozen; the suite and bench are yours,
the parity gates run on the integrated tree later):

```
bundle install --quiet && bundle exec rake && echo SUITE_OK     # expect exit 0, SUITE_OK
bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1             # expect SEAM_BENCH_OK
test -f lib/tart/models.rb && grep -q 'module Models\|class Models' lib/tart/models.rb && test -f test/models_test.rb && echo MODELS_OK
test -f lib/tart/render/model_menu.rb && test -f test/render/model_menu_test.rb && grep -q 'to select' lib/tart/render/model_menu.rb && echo MENU_OK
grep -q '"model"' lib/tart/commands.rb && grep -q 'model_menu\|ModelMenu\|Menu' lib/tart/render/chat.rb && echo MODEL_CMD_OK
grep -q 'when "l"' lib/tart/render/chat.rb && grep -q 'when "s"' lib/tart/render/chat.rb && echo CTRL_KEYS_OK
```

### rig

# Lane dispatch — I27 model-menus, lane `rig`

**You are lane `rig`.** You are ONE of two parallel lane agents (the other is lane
`model`, isolated in its own worktree — its territory is `lib/tart/**`, `bin/tart`,
and `test/**`, which you must NEVER touch). Your lane's territory, exhaustively:

- **Touch (exactly this tree):** `gems/tui-split-rig/**` — scenarios, probes, lib,
  bin, registry, test. The whole rig is yours.
- **Must not touch:** anything outside `gems/tui-split-rig/` — in particular
  `lib/tart/**`, `test/**` (including `test/parity/**`), and `bin/tart` (all lane
  model's). Touching them fails your lane.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive collection/enumerable forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Consistency with the surrounding code
is part of correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write) is
not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout (the rig runs
below take tens of seconds each — allow 120s+ each; the concurrent proof takes
~1 minute). If a runtime will not start unattended, record the exact failure in
your report and route around it — never busy-wait or retry in a loop. IMPORTANT
tmux discipline: a `tmux kill-server` from you kills every other agent's live
sessions on the shared server — NEVER run it; kill only sessions you created by
exact name. When done, write your report to the scratch file given to you below
(an absolute path OUTSIDE your worktree), with RAW results only — tables,
numbers, command output — no interpretation, no "promising". Every status claim
must be backed by a command result from this run. Keep the report compact —
tables and numbers, not prose. Do not title the report; keep any headings
inside the report at `###` or deeper. End it with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker +
what you tried). Verdicts belong to the architect and the human. Persist until
your lane is fully handled end-to-end; do not stop at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I27-model-menus-rig/report.md

## Your lane's specification (lane `rig` ONLY — the other lane's deliverables are NOT yours)

- **Objective.** Make the rig able to SEE the selector menus (the owner: both
  `/model` and `/thinking` must be rig-observable) and stop the rig from flaking
  under parallel lanes — so menu parity becomes measurable and future lanes stop
  paying the shared-tmux-server tax.

- Deliver **menu probes** (the I26 `bin/tool-pending-probe` precedent — drive
  panes directly through Runner's public seams): a probe that boots each app,
  settles, `send-keys` opens `/model` (and `/thinking`) — verify the exact
  keystrokes each app needs (tart's editor dispatch vs pi's) — captures mid-menu
  frames (plain + styled), drives a selection (enter on the highlighted row),
  and captures the post-selection settled screen. Deliver the captured evidence
  + a candidate table (pi's menu bytes vs tart's — the settled-screen comparator
  does not apply to transient menus; the diff table IS the deliverable, the
  s4/s5/s6/s7 pattern). Staging: the rig stages `~/.tart/models.json` for tart
  (pi's models.json staging already exists — mirror it: ≥2 mock models so the
  menu has something to select). NOTE: tart's `/model` menu does not exist at
  your base — the model lane builds it in parallel. Your probe must therefore
  (a) probe PI unconditionally (pi's menus exist), (b) probe tart best-effort:
  capture whatever tart renders for the same keystrokes at your base (likely
  nothing/the fallback), and RECORD that the tart side of the table is a
  pre-model-lane snapshot — the architect re-runs the probe post-integration.
  The probe CODE is your deliverable; the pi captures + the candidate-table
  shape are the evidence.
- Deliver **tmux hardening**: scoped session naming or a per-run server socket
  so concurrent rig processes cannot flake each other's end-of-run
  `assert_clean_sessions!` leftover check (runner.rb:92/327-330 — it greps
  `tmux ls` for `tui-split-rig-` and fails on ANY match, including another
  process's live sessions) or kill each other's sessions. Prove it with the
  frozen concurrent gate: scenario s1 started, then s2 started 2s later, both
  must exit 0 (at base this exits `2 0` — the s1 finisher's check sees s2's live
  sessions; reproduce it FIRST as your control, then cure it).
- Hard constraint: s1–s7 exit codes unchanged (s1–s6 = 0, s7 = 1 — the
  compaction panel is a later iteration, untouched here); registry changes
  ADDITIONS ONLY (no existing line removed or modified).
- Output format: file list + wc; the probe command lines + exit codes + the
  menu-bytes candidate table + the concurrent-run proof output (the base `2 0`
  control + the cured `0 0`) + the registry diff. PHASE 0 disagreements
  mandatory. STATUS line last.

- **Tool guidance.** Verification:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>` (s1–s6 exit 0; s7 exits 1 by design). The rig's runner
  mechanics: I21's extraction shape (`TuiSplitRig`, `TUI_SPLIT_RIG_LIVE`,
  cross-tree MockLLMServer dev require); the I26 seams (`context_window:`,
  `compaction:`, boot_session/public staging seams) are the probe's substrate —
  read bin/tool-pending-probe before writing yours. pi's menus: the probe sends
  keystrokes to a live pi pane — read repos/pi/packages/coding-agent/src/core/
  keybindings.ts (ctrl+l opens the model selector) and the slash command paths
  (`/model` + enter, `/thinking` + enter) to choose the opening keystrokes.

## Acceptance Criteria (frozen — verify against these)

**AC4 (parity + registry discipline).** Cold: s1–s6 all exit 0 (settled screens
unshifted); s7 still exits 1 (compaction panel untouched); registry.yml
additions-only.

**AC7 (rig: menu probes + hardening).** The menu probe captures both apps'
`/model` and `/thinking` menus mid-flight (plain + styled frames) and the
post-selection settled screen, with a candidate table (pi's menu bytes vs
tart's) in your report; tart's staged `~/.tart/models.json` carries ≥2 mock
models; the tmux hardening lets two scenarios run CONCURRENTLY (s2 started 2s
after s1) with both exiting 0.

**AC5 (scope discipline).** The integrated diff touches exactly the two lanes'
enumerated files (the model lane's list + gems/tui-split-rig/**).

Gate commands you can run to self-verify (frozen):

```
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/gate-s1      # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/gate-s2      # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/gate-s3  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/gate-s4  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/gate-s5 # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/gate-s6     # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/gate-s7; test $? -eq 1 && echo S7_STILL_1
# registry additions-only (no '<' lines):
git show fcf232f4:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep '^<' ; test $? -eq 1 && echo REGISTRY_ADDITIONS_ONLY
# the concurrent proof (the frozen gate verbatim) — expect 0 0 AFTER your cure (2 0 at base):
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/conc-a > tmp/conc-a.log 2>&1 & p1=$!
sleep 2
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/conc-b > tmp/conc-b.log 2>&1 & p2=$!
wait $p1; e1=$?
wait $p2; e2=$?
echo "concurrent exits: $e1 $e2"
```

## Builder Report

### model

Lane: model (I27 model-menus)

### Files (touch list respected — `git status --short` at end of run)

```
 M bin/tart                                (458 lines)
 M lib/tart/agent/loop.rb                  (548)
 M lib/tart/commands.rb                    (219)
 M lib/tart/render/chat.rb                 (1240)
 M lib/tart/settings.rb                    (264)
 M test/agent_loop_test.rb                 (476)
 M test/chat_test.rb                       (3330)
 M test/commands_test.rb                   (267)
 M test/settings_test.rb                   (355)
?? lib/tart/models.rb  (new)               (227)
?? lib/tart/render/model_menu.rb (new)     (358)
?? test/models_test.rb (new)               (188)
?? test/render/model_menu_test.rb (new)    (233)
```

`git diff --stat | tail -1` → `9 files changed, 740 insertions(+), 91 deletions(-)` (untracked news above excluded from stat). Scope check: `git diff --name-only | grep -E "selection|editor|transcript|compaction|theme|tui|parity|gems/"` → no match (SCOPE_OK). AC5: the diff touches exactly the two lanes' enumerated files. Note: I briefly added a require to `lib/tart.rb` (not enumerated) and reverted it; the Models requires live in `commands.rb` and `chat.rb` instead.

### Gates (frozen commands, run verbatim, this run)

| command | result |
|---|---|
| `bundle install --quiet && bundle exec rake && echo SUITE_OK` | exit 0, `523 runs, 2023 assertions, 0 failures, 0 errors, 1 skips`, `SUITE_OK` |
| `bundle exec ruby bench/seam_bench.rb 2>&1 \| tail -1` | `SEAM_BENCH_OK` |
| `test -f lib/tart/models.rb && grep -q 'module Models\|class Models' lib/tart/models.rb && test -f test/models_test.rb && echo MODELS_OK` | `MODELS_OK` |
| `test -f lib/tart/render/model_menu.rb && test -f test/render/model_menu_test.rb && grep -q 'to select' lib/tart/render/model_menu.rb && echo MENU_OK` | `MENU_OK` |
| `grep -q '"model"' lib/tart/commands.rb && grep -q 'model_menu\|ModelMenu\|Menu' lib/tart/render/chat.rb && echo MODEL_CMD_OK` | `MODEL_CMD_OK` |
| `grep -q 'when "l"' lib/tart/render/chat.rb && grep -q 'when "s"' lib/tart/render/chat.rb && echo CTRL_KEYS_OK` | `CTRL_KEYS_OK` |

### Suite counts

- Full suite: `523 runs, 2023 assertions, 0 failures, 0 errors, 1 skips` (the 1 skip and the two `bin/tart` already-initialized warnings are pre-existing at HEAD).
- Run-count delta: +51 test methods over HEAD (52 added: models 16, model_menu 21, chat 9, commands 2, settings 3, agent_loop 1; 1 removed — see "pre-existing defect" below).
- Per-file tails (this run): `test/models_test.rb + test/render/model_menu_test.rb` → `21 runs, 68 assertions, 0 failures, 0 errors, 0 skips`; `test/commands_test.rb + test/settings_test.rb + test/agent_loop_test.rb` → `17 runs, 74 assertions, 0 failures, 0 errors, 0 skips`.
- Pre-existing defect fixed in-lane (chat_test is lane territory; the standing lesson on runs-vs-`def test_` reconciliation): HEAD's `test/chat_test.rb` carried a byte-identical duplicate of `test_bash_mode_border_renders_the_bash_mode_token` (lines 2058 + 2204) — the second definition shadowed the first. Dropped the copy; source tests now reconcile with run count (523/523, no duplicate names).

### Command / keybinding table (pi → port)

| pi binding/command (source) | before | after |
|---|---|---|
| `/model [term]` (slash-commands; interactive-mode.ts handleModelCommand :5192-5216) | absent (cut builtin) | `Commands::BUILTINS["model"]`, args: true, argument_hint `<provider/model>`; no-arg → model menu; exact catalog ref → direct switch + `Model: <id>` border status; unknown arg → menu pre-seeded (initialSearchInput) |
| bare `/thinking` (handleThinkingCommand :5145-5163, showThinkingSelector :5168-5183) | cycled (stand-in) | opens the Thinking Level menu (cycle stand-in removed from the dispatcher) |
| `/thinking <level>` / bad arg | set / error text | unchanged (exact set via `thinking:` callable; pi's showError text) |
| `app.model.select` ctrl+l (keybindings.ts:49) | unwired | `edit_input` `when "l"` ctrl → `open_model_menu` |
| `app.models.save` / `app.thinking.save` ctrl+s (keybindings.ts:119, :37) | unwired | menu branch intercept + `when "s"` ctrl → `ModelMenu#select_as_default` → on_select_as_default → apply + Settings write; closes the menu (pi selectLevel → done()) |
| `tui.select.cancel` escape/ctrl+c in selectors | n/a | menu `handle`: esc closes; ctrl+c closes; menu keys never reach the editor while open |
| `app.thinking.cycle` shift+tab (keybindings.ts:33-35) | NOT wired (verified: no shift handling in edit_input at HEAD; cycle only reachable via bare /thinking) | `when "tab"` shift → `cycle_thinking_level` (the cycle genuinely "stays") |
| click-to-select (select-list.ts:109-134 press/release) | n/a | left press moves selection + records row; release on the same row selects + closes; `menu_list_top` maps terminal rows; wheel still scrolls the transcript behind the menu |
| `session.setModel { persist }` | n/a | `Chat#switch_model` / `apply_model_selection(persist:)` → `Agent::Loop#switch_model` seam |
| ctrl+s persistence (settings-manager.ts setDefaultModelAndProvider :713-720) | Settings had no write surface | `Settings.save(root, updates)` — deep-merges over current file contents (unknown keys preserved verbatim), pretty-prints; first write surface |

Ported menu surface (one component family, `Render::ModelMenu`, variant :thinking/:model — unified, spec-invited choice; pi ships two classes over one SelectList shape): bordered block, title row "Thinking Level" + shift+tab hint (thinking), fuzzy Input over `value + description` (thinking) / `getModelSelectorSearchText` text `provider provider/id provider id name` (model-search.ts:15-19), up/down wrap, enter selects, ✓ current marker (preselect on the current row), `· default` badge, (n/N) scroll indicator at the 10-row window, current-first / default-second / by-provider sort (pi sortModels), `  Model Name: <name>` line, LEVEL_DESCRIPTIONS table + muted description column, help line `Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel`, mounted in place of the editor (picker precedent; done restores the editor).

### models.json boot resolution (as built)

| priority | source | notes |
|---|---|---|
| 1 | `TART_MODEL` (+`TART_PROVIDER`) / `TART_PROVIDER` alone | env pair wins; TART_MODEL alone keeps the settings provider |
| 2 | models.json `"default": "<provider/model-id>"` | **port extension** — pi's models.json schema (model-config.ts:44-66) has no default key and pi's resolver puts the settings saved-default FIRST (findInitialModel :511-580, step 3 before first-available :579-585). Deviation itemized per the spec's "itemize any deviation": the port prefers a declared catalog default over its compiled-in `Settings::DEFAULTS` fireworks model. Resolution goes through `Config#resolve` (exact reference match) |
| 3 | `Settings.defaultModel` / `defaultProvider` | unchanged fallback |

- Env keys against the resolved provider: `TART_API_KEY` / `TART_API_BASE` > the resolved provider's models.json `apiKey`/`baseUrl` > Settings `apiKey`/`apiBase` (build_chat; also feeds `require_api_key`).
- **Live-verified ruby_llm constraint:** `Chat#with_model` (gem chat.rb:609-620) re-resolves via `Models.resolve` → `Provider.resolve!` (models.rb:203, provider.rb:608-611) which raises for any non-registered provider slug. Consequence: models.json provider KEYS are endpoint configs (baseUrl/apiKey/api), not wire providers; `Models.wire_provider(key)` passes native slugs through and maps everything else onto the port's single chat-completions seam (`WIRE_PROVIDER = "openai"`). Verified end-to-end: fake-HOME boot with `~/.tart/models.json` (JSONC comment + trailing comma) against a MockLLMServer → `exit=0 stdout="catalog answer"`, clean stderr.
- Error surface (pi model-config.ts:145-170, error-as-field): `Models.load` never raises — parse/schema/read failures set `Config#error` naming the path, catalog empty; bin/tart reports it (warn in print mode, command_line in interactive); boot proceeds on Settings defaults.

### Live verification records

- `Chat#with_model(model_id, provider:, protocol:, assume_model_exists:)` — gem chat.rb:609-620 read + exercised: swaps `@model`/`@provider`/`@connection` in place, sets `@protocol` to the passed value (nil would let the openai provider pick :responses) → the seam passes `protocol: :chat_completions, assume_model_exists: true`, matching bin/tart build_chat.
- `test_switch_model_swaps_the_runtime_chat_and_re_resolves_the_window` (agent_loop_test, MockLLMServer): after `switch_model("glm-5.3", provider: "openai", context_window: 200_000)` — `chat.model.id == "glm-5.3"`, `agent.context_window == 200_000`, and a real request round-trips on the switched chat (`"switched"`).

### Items cut (declared, per spec's itemize requirement)

- Model catalog network refresh (pi refreshModelCatalogs) — tart reads the static `~/.tart/models.json` only.
- scopedModels / all-scoped tab toggle (model-selector tab scope switch).
- pi's isDefaultSearch query boost (filter-ranking nicety) and the "Only showing models… /login" hint line.
- **Stretch: ctrl+p / shift+ctrl+p model cycling — CUT.** pi derives cycle order from scopedModels + runtime model history; the port carries neither (declared in PHASE 0, not silent).
- Select-list wheel-over-list (wheel keeps scrolling the transcript behind the menu).
- Degenerate catalog extension (added, not cut): with no/empty/invalid models.json the model menu offers the single boot model so ctrl+s set-as-default works out of the box.

### Concerns

1. `switch_model` to an entry with no `contextWindow` declared leaves the previous context window in place (loop seam keeps the old value on nil); the footer denominator overlay likewise only overlays present fields. Switching between catalog models with and without declared windows can show a stale denominator until the next `/new`.
2. `Settings.save` treats an unparseable existing settings.json as empty (the read_file idiom) — a corrupt file plus a ctrl+s save rewrites it from the merged updates; the corrupt content is not otherwise preserved.
3. The models.json `"default"` key is a port extension (see precedence table) — pi's schema has no such key; flagged here rather than silently resolved.
4. A native non-openai provider slug (e.g. `anthropic`) passes through as the wire provider, but the port's context only configures the openai endpoint keys — a native provider with its own api is beyond the carried protocol (standing reduction).

Process notes: no git writes performed (one `git stash` attempt was blocked by the builder guard before any state change; nothing was committed). All long commands ran serially in the foreground with explicit timeouts; no backgrounding. Scratch report only — no lane files outside the touch list.

STATUS: COMPLETE

### rig

## Lane `rig` — files

| file | state | wc |
|---|---|---|
| gems/tui-split-rig/lib/tui_split_rig/runner.rb | M | 460 (+56/-11 vs base) |
| gems/tui-split-rig/test/scenario_test.rb | M | 215 (+34) |
| gems/tui-split-rig/bin/model-menu-probe | A | 112 |
| gems/tui-split-rig/scenarios/probe_model_menus.yml | A | 15 |

No other file touched. `git status --porcelain` shows exactly those four. No commits made.

## Gate commands (frozen, post-change)

```
s1_text_turn exit: 0
s2_tool_turn exit: 0
s3_tool_turn_files exit: 0
s4_bash_variants exit: 0
s5_bash_truncation exit: 0
s6_long_calls exit: 0
s7 exit: 1  →  S7_STILL_1
```
Each via `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/gate-<s>`.

## Registry diff (additions-only check)

```
$ git show fcf232f4:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep '^<' ; test $? -eq 1 && echo REGISTRY_ADDITIONS_ONLY
REGISTRY_ADDITIONS_ONLY
$ git show fcf232f4:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml ; echo "diff exit: $?"
diff exit: 0        ← zero changes of any kind; no new classes needed
```

## Concurrent proof (frozen gate verbatim)

Control at BASE (before any edit): `concurrent exits: 2 0`
Failure evidence from `tmp/conc-a/summary.json`: `rig_failure: leftover tui-split-rig-* tmux sessions: tui-split-rig-tart-s2_tool_turn-r1-5600` (s1's finisher saw s2's live session).

Cured (post-change), run twice:
```
concurrent exits: 0 0
concurrent exits (repeat): 0 0
```
Post-run: both `summary.json` → `exit 0, failure None`; `tmux ls | grep -c tui-split-rig-` → `0`.

## Menu probe runs

```
$ gems/tui-split-rig/bin/model-menu-probe --out tmp/model-menu-probe ; echo "probe exit: $?"
pi model: menu=captured selected=captured
pi thinking: menu=captured selected=captured
tart model: menu=captured selected=captured
tart thinking: menu=captured selected=captured
probe exit: 0
```
Captured files (tmp/model-menu-probe/): per app × {model,thinking} × {menu,selected} × {.txt,.styled} = 16 frames. Styled frames carry SGR (e.g. `pi-model-menu.styled` 23 escape-bearing lines; `tart-thinking-selected.styled` 12). Staged tart menu file: `tmp/model-menu-probe/home/tart/.tart/models.json` → models `['mock-1', 'mock-2']`, baseUrl `http://127.0.0.1:62221/v1`.

Opening keystrokes used for BOTH apps: literal `/model` + Enter, then `/thinking` + Enter (slash paths; pi's ctrl+l is pi-only). Keystroke verification at source: pi `keybindings.ts:49` (ctrl+l = app.model.select), `interactive-mode.ts:5196/5145` (no-arg /model → showModelSelector, /thinking → showThinkingSelector), `pi-tui keybindings.ts:154` (enter = tui.select.confirm); tart `lib/tart/commands.rb:41-50` (/model cut from BUILTINS → plain-text submission), `chat.rb:556-558` (Enter applies completion then submits).

## Candidate table — model menu (pi mid-menu bytes vs tart mid-menu bytes; raw line diff, blank-line run collapsed to one row marked `(blanks)`)

Tart side is a PRE-MODEL-LANE SNAPSHOT (no /model builtin at base fcf232f4; re-run post-integration).

```
   (common boot/MOTD rows elided: identical)
+  /model
+  The fallback reply for a text submission.
- ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
- Only showing models from configured providers. Use /login to add providers.
- >
- → ✓ mock-1 [mock]
-     accounts/fireworks/models/deepseek-v4p1-flash [fireworks]
-     accounts/fireworks/models/ember-1 [fireworks]
-     accounts/fireworks/models/gpt-oss-120b [fireworks]
-     accounts/fireworks/models/inkling [fireworks]
-     accounts/fireworks/models/minimax-m3 [fireworks]
-     accounts/fireworks/models/nemotron-3-ultra-nvfp4 [fireworks]
-     accounts/fireworks/models/nemotron-lightning-3p5-30b-a3b [fireworks]
-     accounts/fireworks/models/qwen3p8-2p4t-a95b [fireworks]
-     accounts/fireworks/models/qwen3p8-max [fireworks]
-   (1/23)
-   Model Name: Mock 1
-   Model catalogs refreshed.
-   Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel
+ (blanks ×12)
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
- /Users/…/tmp/model-menu-probe/sandbox/pi (lane/I27-...)
- 0.0%/33k (auto)                                     (mock) mock-1
+ /Users/…/tmp/model-menu-probe/sandbox/tart
+ ↑10 ↓5 0.0%/33k (auto)                             mock-1
```
diff-lines=38 full.

## Candidate table — thinking menu

```
-  Model: mock-1            ← pi (post-model-selection status, still on screen)
+  /model                   ← tart's editor still holds the un-dispatched "/model"
+  The fallback reply for a text submission.
- ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
- Thinking Level
- Shift+Tab cycles thinking levels in-session
- >
- → ✓ off       No reasoning
-   Enter to select · Ctrl+S to set as default · Escape/Ctrl+C to cancel
+ (blanks ×3)
+  Thinking level: high ──────────────────────────────────────────────────────────────────────────────────────────────────
  (footer path/percentage rows as above)
```
diff-lines=18 full.

## Post-selection settled screens

- pi model: status ` Model: mock-1` rendered; footer `(mock) mock-1`.
- pi thinking: status ` Thinking level: off` (mock model declares reasoning: false → its available level set is `[off]`; the selector offered and selected `off`).
- tart model: fallback — the submission echo + mock LLM reply rendered (1 mock request consumed by tart; pi made 0 for /model).
- tart thinking: ` Thinking level: high ─…` — bare `/thinking` cycles (commands.rb:146-147), started from the port default medium, cycled to high. No menu.

## Tests

```
$ bundle exec ruby gems/tui-split-rig/test/scenario_test.rb
20 runs, 84 assertions, 0 failures, 0 errors, 0 skips       (20 def test_ — no buried tests)
$ bundle exec rake test
473 runs, 1864 assertions, 0 failures, 0 errors, 1 skips    (skip = opt-in TUI_SPLIT_RIG_LIVE live test)
```
New tests: `test_session_names_and_leftover_check_are_token_scoped` (token uniqueness + session-name shape), `test_tart_home_stages_two_mock_models` (pi-shape models.json, ≥2 models, settings.json stays context_window-gated).

### AC cross-check
| AC | result |
|---|---|
| AC4 | s1–s6 exit 0, s7 exits 1, registry additions-only (zero diff) — all recorded above |
| AC7 | probe captures both apps' /model + /thinking mid-menu (plain+styled) + post-selection; candidate tables above; `~/.tart/models.json` staged with 2 mock models; concurrent s1/s2 → 0 0 |
| AC5 | diff touches exactly gems/tui-split-rig/** (4 files above) |

### Notes for the architect
- The staged `~/.tart/models.json` shape mirrors pi's `models.json` (providers → {baseUrl, apiKey, api, models:[{id,name,reasoning,contextWindow,maxTokens}]}). Base tart has NO reader for it (verified: no `models.json` reference under lib/tart; Settings.load reads settings.json only). The model lane's reader contract must match this shape — reconcile at merge if it chose differently. Inert at base: AC4 cold gates passed with the staging in place.
- pi's staged agent-dir `models.json` was NOT touched (1 mock model + built-in catalog; keeps s1–s6 settled screens unshifted).
- Trade-off accepted by the token-scoping cure: leftovers from a crashed FOREIGN process no longer fail a later run (only own-token leftovers do). `test/live_run_test.rb:53` still greps for any `tui-split-rig-*` leftover — opt-in test, unmodified, remains concurrency-sensitive if two lanes run it simultaneously.

STATUS: COMPLETE_WITH_CONCERNS — (1) staged tart models.json shape is an unratified contract with the parallel model lane (mirrored pi's shape; needs reconciliation at merge); (2) tart sides of both candidate tables are pre-model-lane snapshots (probe re-run required post-integration); (3) token scoping narrows leftover detection to own-process sessions.

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section model-menus verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify model-menus`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
