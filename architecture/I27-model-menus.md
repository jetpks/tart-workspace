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
`architect rehearse model-menus` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze model-menus` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse model-menus` — before the freeze, while
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
subsection per lane. A copy is written to build/I27-model-menus-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section model-menus prompt --append --lane <lane> --from build/I27-model-menus-<lane>/prompt.md`. -->

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
