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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section model-menus specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision model-menus`
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
