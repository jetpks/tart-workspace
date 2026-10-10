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
`architect rehearse render-surface` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze render-surface` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse render-surface` — before the freeze, while
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
subsection per lane. A copy is written to build/I11-render-surface-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section render-surface prompt --append --lane <lane> --from build/I11-render-surface-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I11-render-surface-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence render-surface --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
