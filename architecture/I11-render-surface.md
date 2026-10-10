# I11: render-surface

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds

Inline research this session (no external dependencies; the oracle repo + the pinned gem, both read directly — no research fan-out triggered).

**Owner gap list (verbatim, first real interactive run 2026-10-11, ARCHITECT.md backlog item 1):** "we're not even close to parity as far as user experience goes — we need to redraw the screen, setup the editing area, we need color support, we need the footer with the current working directory / branch, the token counters, and the model/effort … i also typed /ar<tab> … and got no auto completion." This iteration = gaps (a)–(d); autocomplete (e) is the next iteration (BACKLOG).

**What pi ships (oracle, `repos/pi/packages/coding-agent/src/modes/interactive`):**

- **Fullscreen layout** (interactive-mode.ts:455-470, 876-881): the viewport-TUI mounts a `fullscreenLayoutRoot` via `tui.setLayoutRoot`; the component tree is `chatContainer` (+ `DynamicBorder` child), `transcriptScrollView` (a `TuiLayouts.ScrollView`), `statusContainer`, `editorContainer`, `pendingMessagesContainer` (:455-463). Alt-screen mode switches via `switchTuiMode` (:881-885). Fullscreen exit paths print the transcript (:881-885 `stopInteractiveTui`).
- **Editor area** (components/custom-editor.ts:6-13): `CustomEditor extends Editor` — "Render working, compaction, summarization, and retry status in the editor's top border." App-level keybindings layered over editor handling (:117-145); history bindings explicit (:127-131).
- **Footer** (components/footer.ts): shows pwd, token stats, and context usage (:59-60, "Computes token/context stats from session, gets git branch and extension statuses from provider"); `formatCwdForFooter` contracts `$HOME` to `~` (:33-43); git branch is cached/invalidated by the provider (:82-86, no-op methods — caching handled by provider); usage totals and context usage scan the whole session and the footer renders on every frame (:61-63 doc block); the context-window model is `routedModel?.model ?? model` (:65). Compaction/branch-summary entries carry their own usage (:136).
- **Theme** (theme/ dir: theme-tokens.ts, theme-controller.ts, system-theme.ts, theme-schema.ts, theme.ts): the full token vocabulary + custom-theme loading + a selector UI (components/theme-selector.ts) + themed-text.ts. The port needs the **token vocabulary** the chat surface actually renders; the selector/custom-theme machinery is a reduced-surface cut (BRIEF §6 — no backing feature).

**What the gem gives us (ratatui_ruby 1.5.0, verified against the installed gem this session):**

- `RatatuiRuby::Layout.split(area, direction:, constraints:)` (layout/layout.rb:156) and `split_with_spacers` (:231) — Constraint objects in layout/constraint.rb.
- `RatatuiRuby::Widgets::Block` (widgets/block.rb:25) — `Data.define(:title, :titles, :title_alignment, :title_style, :borders, :border_style, :border_type, :border_set, :style, :padding, :children)`; the full widget dir (paragraph, list, table, tabs, scrollbar, gauge, clear, overlay, canvas, sparkline…).
- Colors/styles: style/color.rb + style.rb (the gem's color mapping — the port rides the gem's mapping, no capability detection of its own).
- **`viewport: :fullscreen` is already a first-class seam param** (lib/tart/tui.rb:125-147 — `TUI.run(viewport:, height:, …)`, default `:fullscreen`); the headless test terminal honors the viewport type too (`RatatuiRuby.init_test_terminal(width, screen_height, viewport.to_s, height)`, tui.rb:140) — so the fullscreen surface is testable headlessly, no tty.

**What the port ships today (read this session):**

- `bin/tart` interactive boots `TUI.run(viewport: :inline, height: 8, bracketed_paste: true)` — the 8-row inline viewport the owner is complaining about.
- **The critical rework constraint:** `Session#insert_before` — the chat surface's completed-content path (scrollback) — *requires an inline viewport* (tui.rb:92-96, gem doc: insertion above the viewport may clobber/scroll it). In fullscreen there is no insert_before: the transcript must be **drawn into a layout area** every frame from a scrollback model the surface owns.
- The seam (lib/tart/tui.rb, 226 lines): `Session` (draw/poll/push/drain/cell_symbol/cell_fg/cell_modifiers/insert_before/buffer_content/viewport_area) + module helpers (`run`, `status_panel`, `paragraph`, `style`, `span`, `line`, `markdown_line`, `text_width`, event ctors, `ctrl_c?`). The standing **tui-seam gate** (`test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')"`) confines every `RatatuiRuby.` call to `lib/tart/tui.rb` — all new layout/block/footer/color code enters through **new seam helpers**, or the gate fails.
- **I06 input editor** (render/chat.rb): fake cursor with cell readback, full editing/history/word-ops — a one-line editor. The rework gives it a bordered **area** with the status line in the top border (pi custom-editor.ts:6-13); the I06 behaviors must survive (their tests are the proof).
- **I05 style vocabulary**: `FG` map in render/chat.rb (7 uses) + `TUI.markdown_line` (I06) for styled completions — the seed of the theme token table; both get absorbed into the theme module.
- **I10 carry-in available for the footer's context usage**: `Settings.resolve_context_window` (explicit → env → settings → model → registry table) — the footer's denominator; `MODEL_CONTEXT_WINDOWS` carries the default model's 1_048_573.
- Agent statuses (working/compacting/summarizing/retrying) already flow as events — the editor-border status consumes them (PHASE 0 verifies the exact seam: how the surface sees them today).

**The launcher-smoke defect class (first live boot, 2026-10-11):** `bin/tart` crashed on first real run (Settings::Result unwrap, fixed 53a08db) while all 13 I10 gates were green — the launcher wiring has zero test coverage. This iteration adds the missing pin: an **Open3 smoke test** that boots the real `bin/tart -p` against MockLLMServer (seed script already proven: `tmp/smoke_print.rb` in the space, exit 0 + response on stdout).

**Deferred (itemized, next iteration):** transcript scrolling (pi's ScrollView machinery — keyboard/wheel scroll of the history), command/skill autocomplete (owner's `/ar<tab>`), theme selector + custom-theme loading, mouse support. The transcript renders its visible tail (as the inline viewport did); scrolling unblocks the full history view next iteration.

## Specification

# Specification

## Objective

Close interactive-UX gaps (a)–(d) from the owner's first real daily-driver run (BRIEF §3 daily-driver parity — the interactive surface; Grounds, ARCHITECT.md backlog item 1): flip the launcher to pi's **fullscreen** viewport and compose the three-area surface — transcript area, bordered editor area, footer line — with **theme colors** throughout, plus the **launcher-boot smoke test** that pins the first-live-boot defect class. Autocomplete (e) and transcript scrolling are explicitly deferred to the next iteration (Grounds "Deferred").

This is the first iteration reaching pi's component/layout layer rather than its core — the port's equivalent machinery is ratatui_ruby's Layout/Block/widgets behind the existing TUI seam (Grounds), and every new rendering primitive enters through a new seam helper (the standing tui-seam gate enforces it).

## Output format

Raw tables/verbatim command output only, in `build/I11-render-surface-core/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the layout composition + constraint split; the theme token table — every token carried and every pi token cut, with reasons; the footer's data cadence — per-frame vs turn-boundary; the git-branch cache strategy; the status-line contents), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

**Verification (exact, per ARCHITECT.md):**

```
cd ~/architect/spaces/20261009-pi-port/repos/tart
bundle install --quiet && bundle exec rake        # suite (test/**/*_test.rb)
```

**Verify against the live oracle + gem before writing code (PHASE 0 — every item needs file:line evidence):**

1. **pi's fullscreen layout composition** (interactive-mode.ts:455-470, 876-881 + the component files): how the layout root stacks transcript / editor / footer areas (find the actual Constraint/split shape — TuiLayouts files in pi's tui package); what DynamicBorder is and where it sits; what happens on terminal resize (redraw cadence) and on alt-screen switching. Map onto `RatatuiRuby::Layout.split` + `Widgets::Block` (gem layout/layout.rb:156, widgets/block.rb:25) via new seam helpers; cite what you port and what you reduce.
2. **pi's editor area** (custom-editor.ts:6-13, :117-145): the editor's top-border status — the exact status strings/shapes ("working", compaction, summarization, retry — find them) and how they're driven (which events). Map the port's existing status events onto the border; keep every I06 editing behavior (cursor readback, history, word-ops — their tests are the frozen proof, they must survive unchanged in assertion content).
3. **pi's footer** (footer.ts:33-43, :59-136): the exact content and shape — cwd contraction, git branch source + cache invalidation strategy, token counters (which totals — last-turn, session, both), context-usage denominator (`routedModel?.model ?? model` — the port's equivalent is the I10 resolved window, Grounds), render cadence (every frame). Decide and record the port's reduced cadence if per-frame scanning is not idiomatic for the port's loop (BRIEF §5.1 foundation carve-out applies — itemize).
4. **pi's theme tokens** (theme/theme-tokens.ts + system-theme.ts): transcribe the default theme's token table (names → the colors the port's terminal actually renders — ride the gem's color mapping, no capability detection). Enumerate every token pi defines; carry the ones the port's surface renders (chat roles, markdown styles, borders, footer); cut the rest with reasons. The port's `FG` map (I05) and `TUI.markdown_line` styles (I06) are absorbed into the new theme module — their rendered output stays identical where tests pin it.
5. **The transcript model**: the inline `insert_before` path retires from the interactive surface (tui.rb:92-96 — inline-only, Grounds). The surface now owns a scrollback buffer and draws the visible tail into the transcript area every frame. Verify how the port's `enqueue_scrollback`/`render_markdown` paths work today (render/chat.rb) and route them into the buffer. `insert_before`/inline support stays in the seam for any other caller — not deleted, just no longer the surface's path.
6. **Gem seam surface** (ratatui_ruby 1.5.0): confirm `Layout.split` constraint objects (layout/constraint.rb — Percentage/Min/Max/Length forms), `Block` borders/title shapes, `Viewport::fullscreen` redraw behavior on resize (gem terminal/event layer — find the resize event shape), and that the headless test terminal honors fullscreen (tui.rb:140 `init_test_terminal` viewport arg). Confirm `cell_fg`/`cell_modifiers` readback works under fullscreen for cursor/theme tests.
7. **Launcher smoke** (Grounds): the Open3 boot pattern — `Tart::Test::MockLLMServer` + `Open3.capture3(RbConfig.ruby, "bin/tart", "-p", …, TART_API_KEY/TART_API_BASE → mock)`. Verify the env seam (`Settings.resolve_setting` env→settings→default) drives a mock-booted print run end-to-end; assert exit 0 + the final response on stdout. This is the gate that would have caught the first-live-boot unwrap crash (53a08db).

**Hermeticity**: no test touches a real tty, the real `~/.tart`, or the network (MockLLMServer + the gem's headless test terminal, I07/I08/I06 patterns). The smoke test runs the real launcher but against the mock only.

## Boundaries

**May touch (this lane's exhaustive set):**

- `lib/tart/tui.rb` (seam extensions only — new layout/block/footer/color helpers; existing seam surface additive)
- `lib/tart/theme.rb` (new — the token table)
- `lib/tart/render/chat.rb` (the surface rework: fullscreen layout composition, transcript buffer, editor area, footer, theme usage)
- `bin/tart` (viewport flip + footer/status data wiring: cwd, git branch, model id, resolved context window)
- `lib/tart.rb` (registration only)
- `test/tui_test.rb`, `test/chat_test.rb` (surface tests — I06 assertions' *content* must survive; their driving code may move)
- `test/theme_test.rb` (new), `test/launcher_smoke_test.rb` (new)
- `README.md` (fullscreen surface, theme, footer, keys)

**Must not touch:** `lib/tart/agent/**` (loop, session, status, bridge, system_prompt — the surface consumes their events; if a status/event seam is genuinely missing, raise it in PHASE 0 with evidence instead of editing), `lib/tart/compaction.rb`, `lib/tart/skills.rb`, `lib/tart/settings.rb`, `lib/tart/commands.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/render/markdown.rb` (theme colors apply at the span level in the surface/seam, not in the AST converter; raise in PHASE 0 if genuinely blocked), `lib/tart/core/**`, all other test files (including `test/golden_parity_test.rb`, `test/markdown_test.rb`, `test/compaction_test.rb`, `test/settings_test.rb`, `test/commands_test.rb`, `test/skills_test.rb`, `test/support/**` — read-only; raise in PHASE 0 if a fixture is missing), `Gemfile`, `Gemfile.lock`, `bench/`. `~/.tart` never touched.

**Out of scope (deferred, Grounds "Deferred" — itemize in the report's deviation table):** transcript scrolling (pi ScrollView), command/skill autocomplete (`/ar<tab>`), theme selector + custom-theme loading + terminal-capability detection, mouse support, alt-screen mode switching, overlay/popup components, pi's extension-status footer segments. No new runtime dependencies (gem-pins gate). No refactors beyond the task.

**No placeholders; search before implementing** (repo grep + gem source in the worktree; pi oracle at `~/architect/spaces/20261009-pi-port/repos/pi`).

## Lane plan

One lane — layout, editor area, footer, theme, and the surface rework interlock inside `render/chat.rb` + `tui.rb`; the seams would overlap in any split (high effort: first component-layer parity work, plus the exact-shape work of the theme table and footer data).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/tui.rb
    - lib/tart/theme.rb
    - lib/tart/render/chat.rb
    - bin/tart
    - lib/tart.rb
    - test/tui_test.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/launcher_smoke_test.rb
    - README.md
```

## Effort

`architect dispatch render-surface --effort high` — component-layer parity (layout composition, bordered editor, footer data cadence, theme token table) against an oracle whose tui package is a custom framework (pi's shapes map to ratatui_ruby's, not 1:1 — BRIEF §5.1 judgment calls, every one itemized), plus the fullscreen transcript rework that retires the inline `insert_before` path.

## Acceptance Criteria

# Acceptance Criteria

**AC1 (fullscreen layout — BRIEF §3, §5.1).** `bin/tart` boots the interactive surface in `:fullscreen` (pi interactive-mode.ts:876-881), composing three areas via new seam helpers over `RatatuiRuby::Layout.split` + `Widgets::Block` (gem layout/layout.rb:156, widgets/block.rb:25): a **transcript area** (the surface-owned scrollback buffer's visible tail, drawn every frame — the inline `insert_before` path is retired from the interactive surface, Grounds tui.rb:92-96), a bordered **editor area**, and a **footer line**. Terminal resize redraws without clobbering (headless-test-terminal proof). The goldens and all non-surface behavior stay byte-identical (the system prompt, session recording, compaction, and submit/steer paths are untouched by the layout).

**AC2 (editor area — BRIEF §3).** The I06 editor's full behavior survives inside the bordered area — cursor-with-cell-readback, editing, history, word-ops — with every I06 test assertion's *content* intact (their driving code may move with the layout; the assertions' substance is the frozen proof). The editor's top border renders the working/compaction/summarization/retry **status line** (pi custom-editor.ts:6-13 — exact shapes transcribed in PHASE 0), driven by the port's existing status events — test-proven headlessly (no new status plumbing inside `lib/tart/agent/**`; a missing event seam is raised in PHASE 0, not edited).

**AC3 (theme — BRIEF §3, §6).** A new `Tart::Theme` module carries pi's default-theme **token table** (theme/theme-tokens.ts, PHASE 0 transcribed — every pi token enumerated: carried or cut-with-reason, recorded in the judgment-call table). Every span the surface renders — chat roles, markdown styles (the I06 `markdown_line` mapping), borders, footer — resolves its color through the theme; the I05 `FG` map is absorbed. Rendered colors ride the gem's color mapping (no capability detection — reduced, itemized). Theme tokens are pure data + lookup, test-proven standalone (token table vs pi transcribed values; no LLM, no tty).

**AC4 (footer — BRIEF §3).** The footer line renders: cwd (~-contracted, pi formatCwdForFooter footer.ts:33-43), **git branch** (a cached, invalidated-per-turn strategy — pi's provider caching, PHASE 0 verified; the port's reduced strategy itemized), **token counters** (PHASE 0 transcribed from footer.ts:59-136 — which totals the port carries), **context usage** against the I10 resolved window (`Settings.resolve_context_window` — the denominator), and the **model id**. Test-proven headlessly (cell readback / buffer content — no tty); the cadence (per-frame vs per-turn) is a recorded judgment call (pi renders every frame; BRIEF §5.1 foundation carve-out may apply — itemize).

**AC5 (smoke + PHASE 0 + no regressions — BRIEF §2, §5).** A new `test/launcher_smoke_test.rb` boots the **real** `bin/tart -p` via Open3 against MockLLMServer (env seam `TART_API_KEY`/`TART_API_BASE` → mock) and asserts exit 0 + the final response on stdout — the pin for the first-live-boot unwrap-crash class (Grounds, 53a08db). Every PHASE 0 verify item is in the findings table with file:line evidence; the deviation table is empty or itemized (the four deferred features from Grounds appear there). All measured regression gates stay green: tui-seam (every `RatatuiRuby.` call still confined to `lib/tart/tui.rb` — the new helpers are the only door), gem-pins (no new deps), stderr gates, bench-seam; the goldens stay byte-identical.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-surface-guard
  ac: AC1, AC2
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  expect:
    exit_code: 0
    stdout_match: TUI_OK

- id: chat-surface-guard
  ac: AC1, AC2, AC3, AC4
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: theme-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  expect:
    exit_code: 0
    stdout_match: THEME_OK

- id: smoke-guard
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: fullscreen-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q ':fullscreen' bin/tart && grep -q 'Layout' lib/tart/tui.rb && echo FULLSCREEN_OK
  expect:
    exit_code: 0
    stdout_match: FULLSCREEN_OK

- id: footer-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qi 'footer' lib/tart/render/chat.rb && grep -qi 'branch' lib/tart/render/chat.rb && grep -q 'resolve_context_window' bin/tart && echo FOOTER_OK
  expect:
    exit_code: 0
    stdout_match: FOOTER_OK

- id: env-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration): `fullscreen-tripwire` and `footer-tripwire` are **tripwires** — presence only; the layout composition, editor status line, theme table fidelity, and footer content are architect-read from the report's citations and the tests, never gate-proven. `tui-surface-guard`, `chat-surface-guard`, `theme-guard` prove the reworked surface files run standalone; `smoke-guard` is the **deliverable proof** for AC5 (a real launcher boot, exit 0). `env-tripwire`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` are the standing regression guards (tui-seam is the load-bearing one this iteration — the new helpers are the only door to `RatatuiRuby.`). `suite-green` is the regression floor (no counts frozen). I06's editor assertions surviving is judged by reading the diff, not a gate.

## Builder Prompt

### core

### LANE core — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I11-render-surface-core/wt
  (a git worktree of the tart repo, branch lane/I11-render-surface-core, based on
  project/pi-port at ea9ea5bd — everything through I10: kernel + agent/tool loop with
  seven parity tools, safety/approval gating, thinking-replay strip, TUI seam with the
  input-line editor (fake cursor + editing/history/word-ops) and markdown-rendered
  completions, the §5 toggle seam (off), JSONL session recording + resume, the stdio
  MCP client + registry integration, print mode, the CLI launcher (-p/--print,
  -r/--resume, MCP env), compaction (threshold + overflow triggers + retry-once latch
  + compaction entry + compaction-aware resume), the I09 rename to tart, and I10's
  skills/settings/slash commands (registry-default context window 1_048_573 so the
  threshold fires out of the box). Suite 230 runs / 879 assertions green. All must stay
  green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I11-render-surface-core/report.md
- You may touch ONLY:
  lib/tart/tui.rb (seam extensions only — new layout/block/footer/color helpers,
  existing seam surface additive), lib/tart/theme.rb (new — the token table),
  lib/tart/render/chat.rb (the surface rework: fullscreen layout composition,
  transcript buffer, editor area, footer, theme usage), bin/tart (viewport flip +
  footer/status data wiring), lib/tart.rb (registration only), test/tui_test.rb,
  test/chat_test.rb (I06 assertion CONTENT must survive; driving code may move),
  test/theme_test.rb (new), test/launcher_smoke_test.rb (new), README.md. Nothing
  else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - This iteration closes owner gap list items (a)–(d) from the first real
    daily-driver run (backlog item 1, ARCHITECT.md): fullscreen layout + redraw,
    editor area, color support, footer (cwd/branch/token counters/model). Autocomplete
    and transcript scrolling are EXPLICITLY DEFERRED to the next iteration — do not
    build them; itemize both in the deviation table.
  - The port's TUI seam is lib/tart/tui.rb — the ONLY file that may contain
    `RatatuiRuby.` calls (the tui-seam gate enforces it). Every new rendering
    primitive (Layout.split, Widgets::Block, colors) enters through a NEW seam
    helper. render/chat.rb and bin/tart touch only seam helpers.
  - Key rework constraint: `Session#insert_before` (tui.rb:92-96) — the current
    completed-content path — REQUIRES an inline viewport. In fullscreen there is no
    insert_before: the surface must own a scrollback buffer and DRAW the visible
    tail into the transcript area every frame. Keep insert_before in the seam (not
    deleted) — it is just no longer the interactive surface's path.
  - The gem (ratatui_ruby 1.5.0) already supports `viewport: :fullscreen` in
    `TUI.run` (tui.rb:125-147) and the headless test terminal honors the viewport
    type (tui.rb:140 init_test_terminal) — the fullscreen surface is testable with no
    tty. Verify gem layout/constraint/block shapes in the installed gem
    (layout/layout.rb:156 split, widgets/block.rb:25 Block, layout/constraint.rb)
    before composing.
  - pi's oracle layout lives in repos/pi/packages/coding-agent/src/modes/interactive:
    fullscreen layout root (interactive-mode.ts:455-470, 876-881), CustomEditor with
    the status line in the editor's TOP BORDER (components/custom-editor.ts:6-13),
    footer (components/footer.ts:33-43 formatCwdForFooter ~-contraction, :59-136
    token/context/branch stats), theme tokens (theme/theme-tokens.ts +
    system-theme.ts). pi's tui package itself (TuiLayouts, ScrollView, Container) is
    its own custom framework — map its SHAPES onto ratatui_ruby's, do not re-create
    the framework (BRIEF §5.1 foundation carve-out — itemize every mapping judgment).
  - The footer's context-usage denominator is the I10 resolved window:
    `Settings.resolve_context_window` (lib/tart/settings.rb) — read-only for you;
    bin/tart wires it as data.
  - lib/tart/agent/** (loop, session, status, bridge, system_prompt),
    lib/tart/render/markdown.rb, and ALL other lib/test files are READ-ONLY for you:
    the surface consumes their events; if a status/event seam is genuinely missing,
    raise it in PHASE 0 with evidence instead of editing.
  - The launcher smoke test (test/launcher_smoke_test.rb, new — yours): Open3-boot
    the REAL `bin/tart -p` against Tart::Test::MockLLMServer with TART_API_KEY/
    TART_API_BASE pointing at the mock (require test_helper + support/
    mock_llm_server; the mock is inside Tart::Test). Assert exit 0 + the final
    response on stdout. This is the pin for the first-live-boot crash class
    (I10 shipped with all gates green while the first real boot crashed — a
    Settings::Result unwrap, since fixed).
  - I06's editor tests are the frozen proof of editor behavior: every assertion's
    CONTENT survives the rework (cursor cell-readback, editing, history, word-ops);
    the driving code may move with the layout.
  - Gates tui-surface-guard, chat-surface-guard, suite-green prove the reworked
    surface; theme-guard, smoke-guard, fullscreen-tripwire, footer-tripwire are your
    deliverable proof; env-tripwire, tui-seam, bench-seam, gem-pins, stderr-quiet,
    stderr-clean are all runnable at your base — run them and record verbatim; they
    must stay green. Do not weaken any gate's files.
  - bin/tart interactive wiring today: TUI.run(viewport: :inline, height: 8,
    bracketed_paste: true) — the flip to :fullscreen plus the three-area composition
    replaces it; --print and --resume paths must not regress (print mode never boots
    the TUI — keep it that way).

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** (BRIEF §5.1
foundation carve-out applies to this iteration's layer: pi's tui package is a
custom framework; map shapes onto ratatui_ruby's equivalents and itemize every
mapping judgment — never silently substitute.) Verify your work by running the
acceptance criteria's gate commands and record the verbatim output. Do NOT
commit and do NOT run any git write command (commit/add/branch/reset/checkout)
— the architect commits and merges after verification, and verifies you made
no commits. Do NOT delete lock files or escalate privileges if a command
fails; record the exact error and continue. Do NOT use `run_in_background`
(or shell `&`) for your own work — this process terminates when you end your
turn and reaps its own children, so backgrounded work is SIGTERMed and its
output lost while the run still exits 0; run long commands serially in the
foreground instead. Give every potentially long command an explicit timeout;
if a runtime will not start unattended (interactive prompt, server with no
timeout), record the exact failure in your report and route around it — never
busy-wait or retry in a loop. When done, write your report to the scratch
file given to you in your BOUNDARIES header (an absolute path outside your
worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a
command result from this run. Keep the report compact — tables and numbers,
not prose. Do not title the report — the architect's tooling supplies the
`### <lane>` heading when it transcribes; keep any headings inside the report
at `###` or deeper. End it with exactly one status line: STATUS: COMPLETE |
COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you
tried). Verdicts belong to the architect and the human. Persist until your
lane is fully handled end-to-end; do not stop at analysis or partial fixes.

=== SPECIFICATION ===
# Specification

## Objective

Close interactive-UX gaps (a)–(d) from the owner's first real daily-driver run (BRIEF §3 daily-driver parity — the interactive surface; Grounds, ARCHITECT.md backlog item 1): flip the launcher to pi's **fullscreen** viewport and compose the three-area surface — transcript area, bordered editor area, footer line — with **theme colors** throughout, plus the **launcher-boot smoke test** that pins the first-live-boot defect class. Autocomplete (e) and transcript scrolling are explicitly deferred to the next iteration (Grounds "Deferred").

This is the first iteration reaching pi's component/layout layer rather than its core — the port's equivalent machinery is ratatui_ruby's Layout/Block/widgets behind the existing TUI seam (Grounds), and every new rendering primitive enters through a new seam helper (the standing tui-seam gate enforces it).

## Output format

Raw tables/verbatim command output only, in `build/I11-render-surface-core/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the layout composition + constraint split; the theme token table — every token carried and every pi token cut, with reasons; the footer's data cadence — per-frame vs turn-boundary; the git-branch cache strategy; the status-line contents), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

**Verification (exact, per ARCHITECT.md):**

```
cd ~/architect/spaces/20261009-pi-port/repos/tart
bundle install --quiet && bundle exec rake        # suite (test/**/*_test.rb)
```

**Verify against the live oracle + gem before writing code (PHASE 0 — every item needs file:line evidence):**

1. **pi's fullscreen layout composition** (interactive-mode.ts:455-470, 876-881 + the component files): how the layout root stacks transcript / editor / footer areas (find the actual Constraint/split shape — TuiLayouts files in pi's tui package); what DynamicBorder is and where it sits; what happens on terminal resize (redraw cadence) and on alt-screen switching. Map onto `RatatuiRuby::Layout.split` + `Widgets::Block` (gem layout/layout.rb:156, widgets/block.rb:25) via new seam helpers; cite what you port and what you reduce.
2. **pi's editor area** (custom-editor.ts:6-13, :117-145): the editor's top-border status — the exact status strings/shapes ("working", compaction, summarization, retry — find them) and how they're driven (which events). Map the port's existing status events onto the border; keep every I06 editing behavior (cursor readback, history, word-ops — their tests are the frozen proof, they must survive unchanged in assertion content).
3. **pi's footer** (footer.ts:33-43, :59-136): the exact content and shape — cwd contraction, git branch source + cache invalidation strategy, token counters (which totals — last-turn, session, both), context-usage denominator (`routedModel?.model ?? model` — the port's equivalent is the I10 resolved window, Grounds), render cadence (every frame). Decide and record the port's reduced cadence if per-frame scanning is not idiomatic for the port's loop (BRIEF §5.1 foundation carve-out applies — itemize).
4. **pi's theme tokens** (theme/theme-tokens.ts + system-theme.ts): transcribe the default theme's token table (names → the colors the port's terminal actually renders — ride the gem's color mapping, no capability detection). Enumerate every token pi defines; carry the ones the port's surface renders (chat roles, markdown styles, borders, footer); cut the rest with reasons. The port's `FG` map (I05) and `TUI.markdown_line` styles (I06) are absorbed into the new theme module — their rendered output stays identical where tests pin it.
5. **The transcript model**: the inline `insert_before` path retires from the interactive surface (tui.rb:92-96 — inline-only, Grounds). The surface now owns a scrollback buffer and draws the visible tail into the transcript area every frame. Verify how the port's `enqueue_scrollback`/`render_markdown` paths work today (render/chat.rb) and route them into the buffer. `insert_before`/inline support stays in the seam for any other caller — not deleted, just no longer the surface's path.
6. **Gem seam surface** (ratatui_ruby 1.5.0): confirm `Layout.split` constraint objects (layout/constraint.rb — Percentage/Min/Max/Length forms), `Block` borders/title shapes, `Viewport::fullscreen` redraw behavior on resize (gem terminal/event layer — find the resize event shape), and that the headless test terminal honors fullscreen (tui.rb:140 `init_test_terminal` viewport arg). Confirm `cell_fg`/`cell_modifiers` readback works under fullscreen for cursor/theme tests.
7. **Launcher smoke** (Grounds): the Open3 boot pattern — `Tart::Test::MockLLMServer` + `Open3.capture3(RbConfig.ruby, "bin/tart", "-p", …, TART_API_KEY/TART_API_BASE → mock)`. Verify the env seam (`Settings.resolve_setting` env→settings→default) drives a mock-booted print run end-to-end; assert exit 0 + the final response on stdout. This is the gate that would have caught the first-live-boot unwrap crash (53a08db).

**Hermeticity**: no test touches a real tty, the real `~/.tart`, or the network (MockLLMServer + the gem's headless test terminal, I07/I08/I06 patterns). The smoke test runs the real launcher but against the mock only.

## Boundaries

**May touch (this lane's exhaustive set):**

- `lib/tart/tui.rb` (seam extensions only — new layout/block/footer/color helpers; existing seam surface additive)
- `lib/tart/theme.rb` (new — the token table)
- `lib/tart/render/chat.rb` (the surface rework: fullscreen layout composition, transcript buffer, editor area, footer, theme usage)
- `bin/tart` (viewport flip + footer/status data wiring: cwd, git branch, model id, resolved context window)
- `lib/tart.rb` (registration only)
- `test/tui_test.rb`, `test/chat_test.rb` (surface tests — I06 assertions' *content* must survive; their driving code may move)
- `test/theme_test.rb` (new), `test/launcher_smoke_test.rb` (new)
- `README.md` (fullscreen surface, theme, footer, keys)

**Must not touch:** `lib/tart/agent/**` (loop, session, status, bridge, system_prompt — the surface consumes their events; if a status/event seam is genuinely missing, raise it in PHASE 0 with evidence instead of editing), `lib/tart/compaction.rb`, `lib/tart/skills.rb`, `lib/tart/settings.rb`, `lib/tart/commands.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/render/markdown.rb` (theme colors apply at the span level in the surface/seam, not in the AST converter; raise in PHASE 0 if genuinely blocked), `lib/tart/core/**`, all other test files (including `test/golden_parity_test.rb`, `test/markdown_test.rb`, `test/compaction_test.rb`, `test/settings_test.rb`, `test/commands_test.rb`, `test/skills_test.rb`, `test/support/**` — read-only; raise in PHASE 0 if a fixture is missing), `Gemfile`, `Gemfile.lock`, `bench/`. `~/.tart` never touched.

**Out of scope (deferred, Grounds "Deferred" — itemize in the report's deviation table):** transcript scrolling (pi ScrollView), command/skill autocomplete (`/ar<tab>`), theme selector + custom-theme loading + terminal-capability detection, mouse support, alt-screen mode switching, overlay/popup components, pi's extension-status footer segments. No new runtime dependencies (gem-pins gate). No refactors beyond the task.

**No placeholders; search before implementing** (repo grep + gem source in the worktree; pi oracle at `~/architect/spaces/20261009-pi-port/repos/pi`).

## Lane plan

One lane — layout, editor area, footer, theme, and the surface rework interlock inside `render/chat.rb` + `tui.rb`; the seams would overlap in any split (high effort: first component-layer parity work, plus the exact-shape work of the theme table and footer data).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/tui.rb
    - lib/tart/theme.rb
    - lib/tart/render/chat.rb
    - bin/tart
    - lib/tart.rb
    - test/tui_test.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/launcher_smoke_test.rb
    - README.md
```

## Effort

`architect dispatch render-surface --effort high` — component-layer parity (layout composition, bordered editor, footer data cadence, theme token table) against an oracle whose tui package is a custom framework (pi's shapes map to ratatui_ruby's, not 1:1 — BRIEF §5.1 judgment calls, every one itemized), plus the fullscreen transcript rework that retires the inline `insert_before` path.

=== ACCEPTANCE CRITERIA ===
# Acceptance Criteria

**AC1 (fullscreen layout — BRIEF §3, §5.1).** `bin/tart` boots the interactive surface in `:fullscreen` (pi interactive-mode.ts:876-881), composing three areas via new seam helpers over `RatatuiRuby::Layout.split` + `Widgets::Block` (gem layout/layout.rb:156, widgets/block.rb:25): a **transcript area** (the surface-owned scrollback buffer's visible tail, drawn every frame — the inline `insert_before` path is retired from the interactive surface, Grounds tui.rb:92-96), a bordered **editor area**, and a **footer line**. Terminal resize redraws without clobbering (headless-test-terminal proof). The goldens and all non-surface behavior stay byte-identical (the system prompt, session recording, compaction, and submit/steer paths are untouched by the layout).

**AC2 (editor area — BRIEF §3).** The I06 editor's full behavior survives inside the bordered area — cursor-with-cell-readback, editing, history, word-ops — with every I06 test assertion's *content* intact (their driving code may move with the layout; the assertions' substance is the frozen proof). The editor's top border renders the working/compaction/summarization/retry **status line** (pi custom-editor.ts:6-13 — exact shapes transcribed in PHASE 0), driven by the port's existing status events — test-proven headlessly (no new status plumbing inside `lib/tart/agent/**`; a missing event seam is raised in PHASE 0, not edited).

**AC3 (theme — BRIEF §3, §6).** A new `Tart::Theme` module carries pi's default-theme **token table** (theme/theme-tokens.ts, PHASE 0 transcribed — every pi token enumerated: carried or cut-with-reason, recorded in the judgment-call table). Every span the surface renders — chat roles, markdown styles (the I06 `markdown_line` mapping), borders, footer — resolves its color through the theme; the I05 `FG` map is absorbed. Rendered colors ride the gem's color mapping (no capability detection — reduced, itemized). Theme tokens are pure data + lookup, test-proven standalone (token table vs pi transcribed values; no LLM, no tty).

**AC4 (footer — BRIEF §3).** The footer line renders: cwd (~-contracted, pi formatCwdForFooter footer.ts:33-43), **git branch** (a cached, invalidated-per-turn strategy — pi's provider caching, PHASE 0 verified; the port's reduced strategy itemized), **token counters** (PHASE 0 transcribed from footer.ts:59-136 — which totals the port carries), **context usage** against the I10 resolved window (`Settings.resolve_context_window` — the denominator), and the **model id**. Test-proven headlessly (cell readback / buffer content — no tty); the cadence (per-frame vs per-turn) is a recorded judgment call (pi renders every frame; BRIEF §5.1 foundation carve-out may apply — itemize).

**AC5 (smoke + PHASE 0 + no regressions — BRIEF §2, §5).** A new `test/launcher_smoke_test.rb` boots the **real** `bin/tart -p` via Open3 against MockLLMServer (env seam `TART_API_KEY`/`TART_API_BASE` → mock) and asserts exit 0 + the final response on stdout — the pin for the first-live-boot unwrap-crash class (Grounds, 53a08db). Every PHASE 0 verify item is in the findings table with file:line evidence; the deviation table is empty or itemized (the four deferred features from Grounds appear there). All measured regression gates stay green: tui-seam (every `RatatuiRuby.` call still confined to `lib/tart/tui.rb` — the new helpers are the only door), gem-pins (no new deps), stderr gates, bench-seam; the goldens stay byte-identical.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-surface-guard
  ac: AC1, AC2
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  expect:
    exit_code: 0
    stdout_match: TUI_OK

- id: chat-surface-guard
  ac: AC1, AC2, AC3, AC4
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: theme-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  expect:
    exit_code: 0
    stdout_match: THEME_OK

- id: smoke-guard
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: fullscreen-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q ':fullscreen' bin/tart && grep -q 'Layout' lib/tart/tui.rb && echo FULLSCREEN_OK
  expect:
    exit_code: 0
    stdout_match: FULLSCREEN_OK

- id: footer-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qi 'footer' lib/tart/render/chat.rb && grep -qi 'branch' lib/tart/render/chat.rb && grep -q 'resolve_context_window' bin/tart && echo FOOTER_OK
  expect:
    exit_code: 0
    stdout_match: FOOTER_OK

- id: env-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration): `fullscreen-tripwire` and `footer-tripwire` are **tripwires** — presence only; the layout composition, editor status line, theme table fidelity, and footer content are architect-read from the report's citations and the tests, never gate-proven. `tui-surface-guard`, `chat-surface-guard`, `theme-guard` prove the reworked surface files run standalone; `smoke-guard` is the **deliverable proof** for AC5 (a real launcher boot, exit 0). `env-tripwire`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` are the standing regression guards (tui-seam is the load-bearing one this iteration — the new helpers are the only door to `RatatuiRuby.`). `suite-green` is the regression floor (no counts frozen). I06's editor assertions surviving is judged by reading the diff, not a gate.

## Builder Report

### core

### PHASE 0 findings (spec-vs-reality, evidence)

| # | Verify item | Spec claim | Reality | Evidence |
|---|---|---|---|---|
| 1 | pi fullscreen layout root | interactive-mode.ts:455-470, 876-881 | Confirmed: `fullscreenLayoutRoot` comes from `createChatViewport(...)` (interactive-mode.ts:966-983), installed via `tui.setLayoutRoot` (:875-878). pi's root (packages/coding-agent/src/modes/interactive/chat-viewport.ts:25-42) = VStack of [ScrollView transcript (basis 0, grow 1, minSize 1), dock VStack (basis auto, grow 0, shrink 1)] where dock = [pendingMessages, status, widgetsAbove, editor (minSize 3), widgetsBelow, footer] all shrink:1 | Ported: root vertical split — transcript `Min(rest)`, editor block + footer `Length` (gem Layout renders `children[i]` into constraint rect i — layout/layout.rb:44, verified live). |
| 2 | DynamicBorder | — | A transcript rule line (`"─" × width`, theme border color) inserted between chat entries — NOT a box border (components/dynamic-border.ts:21-23) | Cut (see deviations). |
| 3 | Editor top-border status | custom-editor.ts:6-13 | `renderTopBorder` embeds a `StatusIndicator.renderInBorder` in the top border; kinds = working/retry/compaction/branchSummary (components/status-indicator.ts:10); working message "Working", compaction "Compacting context... (…to cancel)" / "Context overflow detected, Auto-compacting...", retry "Retrying (n/m) in Xs... (…to cancel)", summarization "Summarizing branch..." (status-indicator.ts:52-116). Driven by indicator objects set per state | Port's event surface (lib/tart/agent/loop.rb:66-70) carries NO retry and NO summarization/branch-summary event; `:compaction` fires only after completion (loop.rb:314). Border carries the live working/tool status; retry/summarization cut (missing event seam — raised, not edited). |
| 4 | Footer | footer.ts:33-43, 59-136 | 2 lines (footer.ts:169-171): [pwdLine, statsLine]. pwd = `formatCwdForFooter` ~-contraction (:33-43) + ` (${branch})` (:120-122). stats = `↑input ↓output RcacheRead WcacheWrite CH%` (:113-117), `$cost` when nonzero (:123-127), context `pct%/window (auto)` warning >70% / error >90% (:128-143), model id right-aligned with min-2 padding (:147-172), `formatTokens` compaction (:23-30). Context denominator `contextUsage?.contextWindow ?? state.model?.contextWindow ?? 0` (:108). Usage totals memoized per (session, leafId, entryCount, model) — scanned per render (:63-106). Branch: provider-cached, fs-watched (core/footer-data-provider.ts:104-139); detached HEAD → "detached" (:50-53) | Ported: 2 lines, all shapes above except cost (no cost data in ruby_llm tokens — cut); totals accumulated O(1) at `:message_end` (reduced cadence, see judgments); denominator = I10 `Settings.resolve_context_window` (lib/tart/settings.rb:95), bin-wired. |
| 5 | Theme tokens | theme-tokens.ts + system-theme.ts | THEME_TOKENS = 57 tokens (theme-tokens.ts:23-88); default theme values in theme/dark.json (okhsl strings). Port rides gem ANSI named colors (fg-only seam) | Table in judgment calls — 19 tokens carried, 38 cut with reasons. |
| 6 | Transcript model | tui.rb:92-96 retire | `insert_before` is inline-only (seam kept, unused by the surface). Surface now owns `@transcript` buffer; `flush_scrollback` concatenates into it; every frame draws the visible tail. Streaming live source = transient tail lines recomputed per frame | gem `resize_terminal` verified live on the test terminal (ext/ratatui_ruby/src/terminal/mutations.rs:126) — real resize proof possible. |
| 7 | Gem seam surface | layout/constraint.rb, widgets/block.rb:25, tui.rb:140 | `Layout.new(direction:, constraints:, children:)` renders children into rects (layout/layout.rb:25,114); `Constraint.length/percentage/min/max/fill/ratio` (layout/constraint.rb); `Block.new(title:, titles:, title_alignment:, title_style:, borders:, border_style:, border_type:, border_set:, style:, padding:, children:)` (widgets/block.rb:25); `init_test_terminal` parses non-"inline" → `Viewport::Fullscreen` (ext/.../terminal/init.rs:94-117); real init enters alt screen for fullscreen (init.rs:63-66); `Event::Resize` (event/resize.rb); `cell_fg`/`cell_modifiers` read back under fullscreen (verified live) | All verified live with headless draw probes (block title + border styles + layout children + footer readback + `resize_terminal`). |
| 8 | Launcher smoke | env seam | `Settings.load(cwd:, env:)` → `resolve_setting` env→settings→default (settings.rb:68,95); MockLLMServer.url gives `http://127.0.0.1:<port>/v1`; `Dir.home` drives `Agent::Session.default_root` (agent/session.rb:73-75) so HOME→tmpdir makes ~/.tart hermetic; `TART_MCP_CONFIG`→absent path avoids real MCP config. 53a08db was the unwrap crash class | Smoke test green (below). |
| 9 | test_helper.rb read-only | ScriptedSession records insert_before | Surface no longer calls insert_before; ScriptedSession.new(width:, height:) kwargs exist (test_helper.rb:36) — no test_helper edit needed. Kernel tests read the transcript via new `Render::Chat#transcript_lines` and the drawn tree via new seam `TUI.widget_lines` | No shared fixture missing. |
| 10 | Compaction status timing | AC2 | pi shows "Compacting context..." DURING compaction; the port's loop emits `:compaction` only after (loop.rb:314) — no compaction-start seam. Port renders a post-hoc "✻ compacted (reason, tokens)" transcript line from the event; border keeps working status during | Itemized deviation (missing seam — raised, not edited). |

### Judgment calls

**Layout composition + constraint split** (root vertical split; pi shapes → gem shapes):

| pi (chat-viewport.ts) | Port | Note |
|---|---|---|
| VStack root: transcript (basis 0, grow 1, shrink 1, minSize 1) | `TUI.constraint_min(rest)` | takes the remaining rows |
| dock VStack (basis auto, grow 0, shrink 1) | `TUI.constraint_length` per dock area | dock is fixed-height per frame |
| editor minSize 3 (chat-viewport.ts:33) | editor block = 3 rows (2 borders + 1 input), 5 with an approval (3 prompt rows) | pi's dialog replaces the editor content in the same container |
| footer shrink:1 minSize 0 | `constraint_length(2)` | 2 lines, pi footer.ts:169-171 |
| ScrollView transcript (DEFERRED) | Paragraph of the buffer tail, `wrap: false` (rows pre-wrapped) | no scroll state — the tail clip is the visible window |
| CustomEditor top border = status (custom-editor.ts:18-22) | `TUI.block(title: status, title_style: dim, border_style: border)` | gem renders the title on the top border (verified) |
| pi re-renders components at (possibly new) width every frame | whole tree recomposed from `viewport_area` every frame | resize-proof by construction |

Mapping judgments (BRIEF §5.1): (1) pi's VStack grow/shrink/basis → gem constraint `min`/`length` pairs (the gem has no flexbox — the [min(1), length, length] split is the closest ratatui idiom); (2) pi's ScrollView → plain tail-clipped Paragraph (scrolling deferred); (3) pi's per-component render(width) → whole-tree Paragraph/Block composition; (4) pi's editor status lives in the border STRING (its renderTopBorder draws the border itself) → gem Block title; (5) pi's Dock minSize/shrink interplay → explicit per-frame row budgeting with clamps (`editor_rows ≤ height-1`, `transcript ≥ 1`).

**Theme token table** (pi token → port value; house ANSI analogs are the I05/I06-established mappings — rendered output identical where tests pin it). CARRIED (19):

| pi token | dark.json value | port | used by |
|---|---|---|---|
| text | `text` (default) | nil | prose |
| dim | okhsl(229 8% 56%) | :dark_gray | status, footer |
| muted | okhsl(229 6% 67%) | :gray | command output |
| border / borderMuted | okhsl(231 57% 65%) / okhsl(229 8% 53%) | :gray | editor borders (port carries one border style — borderMuted's analog) |
| warning | yellow | :yellow | interrupts, context >70% |
| error | red | :red | errors, context >90% |
| accent | violet | :light_magenta | (reserved) |
| userMessageText | text (on userMessageBg) | :light_blue | user echo — carries userMessageBg's blue as fg (I05 recorded; I06 pins the color) |
| toolOutput | muted | :gray | tool output |
| mdHeading | yellow | :yellow | markdown |
| mdLink | blue | :light_blue | markdown |
| mdLinkUrl | muted | :gray | markdown |
| mdCode | violet | :light_magenta | markdown |
| mdCodeBlock | green | :green | markdown |
| mdCodeBlockBorder | muted | :gray | markdown |
| mdQuote / mdQuoteBorder / mdHr | muted | :gray | markdown |
| mdListBullet | violet | :light_magenta | markdown |

CUT (38, with reasons): selectedBg, searchMatchBg, searchMatchText, userMessageBg, customMessageBg/Text/Label, toolPendingBg/toolSuccessBg/toolErrorBg — background-slot tokens (the seam's span vocabulary is fg-only; I05 recorded). scrollbarTrack/Thumb — scrollbar deferred. toolTitle — the port has no tool box title styling. toolDiffAdded/Removed/Context — no diff rendering. syntax* (10) — no syntax highlighting in the markdown converter. thinkingText — thinking streams as plain live text. thinkingOff…Max (7) — no thinking-level border. bashMode — no bash mode. success — nothing renders a success state.

**Markdown fg routing**: the read-only converter (render/markdown.rb:44-55) emits raw symbols; the surface routes every markdown span through `Theme.md_fg` (converter symbol → token → color; value-identical today — the converter's symbols ARE the I06 transcription). The gray converter roles share one value, so they resolve through md_quote (recorded in theme.rb).

**Footer data cadence**: pi re-scans the whole session per render with a memo cache (footer.ts:63-106). Port reduced: token totals/context numerator accumulate O(1) at `:message_end` events; per-frame work is span assembly only. Per-frame rendering kept (pi parity); the expensive scan eliminated (no event surface to re-scan — the surface never sees the session's entry list).

**Git-branch cache strategy**: pi = provider cache + fs-watchers + unwatch/cleanup (footer-data-provider.ts:104-139). Port reduced: one `git --no-optional-locks symbolic-ref --quiet --short HEAD` per turn, cached across frames, invalidated at `submit` and `:agent_start`; nil on detached HEAD/no repo (segment omitted; pi labels it "detached" — cut, recorded). Test-proven with an injected counting reader.

**Status-line contents** (editor top border, title only while busy — pi IdleStatus renders empty): `⠋ thinking` / `⠋ …` / `⠋ tool: <name>` (the I06 shapes, moved into the border; dim). No compaction/retry/summarization border statuses — see deviations.

### Parity-deviation table (all itemized; none silent)

| Deviation | Reason |
|---|---|
| Transcript scrolling (pi ScrollView), scrollbar, scrollbarTrack/Thumb tokens | Deferred per Grounds "Deferred" — itemized as required. |
| Command/skill autocomplete (`/ar<tab>`) | Deferred per Grounds "Deferred". |
| Theme selector + custom-theme loading + terminal-capability detection | Deferred; the port rides the gem's color mapping (reduced, sanctioned). |
| Mouse support; alt-screen mode switching; overlay/popup components; pi's extension-status footer segments | Deferred per Grounds "Deferred". |
| Editor border statuses for retry / summarization / in-flight compaction | Missing event seam in `lib/tart/agent/loop.rb` (read-only; events enumerated at loop.rb:66-70; `:compaction` post-hoc at :314; ruby_llm retries are internal). Raised in PHASE 0, not edited. The `:compaction` event renders a post-hoc transcript line. |
| Footer `$cost` segment | ruby_llm tokens carry no cost data. |
| Footer CH% uses the latest assistant usage only (pi's latestCacheHitRate — same shape); toolResult usage not accumulated | The `:tool_message` event carries no usage in practice; assistant-message usage is the port's usage carrier. |
| Branch: no fs-watchers; detached HEAD omits the segment (pi: "detached") | Reduced strategy sanctioned by the spec ("cached, invalidated-per-turn"). |
| DynamicBorder transcript rule lines | Cut — the port's transcript never had separators; adding them would churn I06-frozen readback geometry. |
| Transcript rows wrap at enqueue width; a resize re-clips but does not re-wrap already-buffered lines | pi re-wraps per render from component state; the port's buffer stores final Lines. Recorded (AC1 requires clobber-free redraw, achieved). |
| Footer truncation: stats clip with `…` + model keeps a 2-cell margin (pi: `truncateToWidth(statsLeft, width, "...")` with colored ellipsis) | Same semantics, simpler shape. |
| Live region: streaming raw source renders as transient transcript-tail rows (pi fullscreen: streaming lands in the transcript flow) | I06's recorded deviation (markdown at completion only) unchanged. |
| Status border title is one styled string (spinner+message same dim color); pi colors spinner accent / message muted separately | Gem Block title takes one style; the I06-pinned dim readback preserved. |

### Files touched

| File | Change |
|---|---|
| lib/tart/theme.rb | new — pi dark-theme token table + lookup + markdown fg routing |
| lib/tart/tui.rb | seam additions only: `layout`, `constraint_length`, `constraint_min`, `block`, `widget_lines`, `Session#resize` (insert_before kept, now unused by the surface) |
| lib/tart/render/chat.rb | fullscreen three-area rework: transcript buffer, bordered editor + status title, footer (cwd/branch/tokens/context/model), theme-routed colors, usage accumulation |
| bin/tart | `viewport: :fullscreen` flip; footer_data wiring (cwd, model id, resolved context window, auto_compact); usage text |
| lib/tart.rb | `require_relative "tart/theme"` |
| test/tui_test.rb | +4 seam tests (layout split, block title/border styles, widget_lines, resize) |
| test/chat_test.rb | reworked driving code to fullscreen geometry; all I06 assertion content preserved; new composition/resize/footer/branch-cache tests |
| test/theme_test.rb | new — token table vs transcription, lookup, md_fg routing |
| test/launcher_smoke_test.rb | new — real `bin/tart -p` boot via Open3 vs MockLLMServer |
| README.md | fullscreen surface, theme, footer, editor keys |

### Gate output (verbatim)

```
bundle install --quiet && bundle exec rake
  247 runs, 954 assertions, 0 failures, 0 errors, 0 skips     (suite-green)

timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  13 runs, 37 assertions, 0 failures, 0 errors, 0 skips
TUI_OK

timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  44 runs, 172 assertions, 0 failures, 0 errors, 0 skips
CHAT_OK

timeout 120 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  5 runs, 16 assertions, 0 failures, 0 errors, 0 skips
THEME_OK

timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  1 runs, 3 assertions, 0 failures, 0 errors, 0 skips
SMOKE_OK

grep -q ':fullscreen' bin/tart && grep -q 'Layout' lib/tart/tui.rb && echo FULLSCREEN_OK
  FULLSCREEN_OK

grep -qi 'footer' lib/tart/render/chat.rb && grep -qi 'branch' lib/tart/render/chat.rb && grep -q 'resolve_context_window' bin/tart && echo FOOTER_OK
  FOOTER_OK

grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  ENV_OK

test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  SEAM_OK

timeout 90 bundle exec ruby bench/seam_bench.rb
  SEAM_BENCH_OK      (bench boots the REAL TUI.run fullscreen path in its pty — extra AC1 evidence)

grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  PINS_OK

bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN
  NO_WARN

bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE
  NO_EPIPE
```

Additional checks: test-method count 247 == 247 runs (no buried tests); `git status` shows only the lane's files; no commits made; goldens byte-identical (golden_parity_test green in suite).

STATUS: COMPLETE_WITH_CONCERNS — (1) editor border statuses for retry/summarization/in-flight compaction are absent: no event seam in the read-only agent loop (loop.rb:66-70, :314) — needs an owner decision on an agent-side event; (2) resize re-clip is clobber-free but does not re-wrap buffered transcript lines (pi re-wraps per render); (3) footer `$cost` segment cut (no cost data in ruby_llm tokens).

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section render-surface verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify render-surface`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
