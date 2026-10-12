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

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I27-model-menus-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence model-menus --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
