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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section render-surface specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision render-surface`
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
