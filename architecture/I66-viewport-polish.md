# I66: viewport-polish

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T005042Z-live-render-correctness.md` ENTRY 2 (this
  iteration; ENTRY 1 landed as I65 → merged `9db6370`), standing context block.
  Done bar: **BRIEF §8** exact parity ("pi in one tab, tart in another,
  indistinguishable") on the **BRIEF §3** daily-driver surface; frozen stack
  **BRIEF §2** (ratatui_ruby 1.5.0, all calls behind `lib/tart/tui.rb`).
- **Base = tart `project/pi-port` @ `9db6370`** (the I65 merge — tip, in sync
  with origin). fast-completions **0.4.0** published/pinned (Gemfile pin-only,
  no path branch, no `FAST_COMPLETIONS_PATH` — measured cold at 1b83e05 by
  I65, unchanged by the merge).
- **Measured base suite this session** (scratch worktree @ 9db6370, published
  gem): **1192 runs / 5709 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0** (matches the I65 landing record; the 1 skip is the standing rig
  live-run test). `bench/seam_bench.rb` → `SEAM_BENCH_OK` (measured).
- **pi oracle drift standing** (installed pi 1.2.0 vs `Identity::
  ORACLE_VERSION` 1.1.0): every rig-scenario gate exits 1 `unknown-candidate`;
  per the plan BOTH entries are UNIT-PINNED — the rig family stays EXCLUDED
  (itemized in the AC preamble). No rig/oracle work in scope.
- **The canonical checkout carries the owner's intentional uncommitted diff**
  (6 files: Gemfile path-branch, lock checksum, `lib/tart/subagents/manager.rb`,
  3 test files) — LEAVE untouched; provisioned lanes are cut from the
  committed branch and never see it. Rehearsal protocol: snapshot/restore the
  owner's Gemfile/Gemfile.lock + `git diff` sha around bundler-touching
  rehearsals (I65 digest, `tmp/i65-owner-state/` shape).
- **`repos/RatatuiRuby` is a READ-ONLY reference** the owner added for this
  audit: clone @ `10dd180` (v1.5.2), the installed gem tart runs against is
  **1.5.0** (Gemfile.lock). The probe targets the INSTALLED gem's real
  buffer/terminal API; the repo is for source reading and the upstream
  finding's file citations. NO commits, submodules, or vendored copies.
- Owner findings: `new_problems.md` "rendering weirdness" + "missing a
  jump-to-bottom button"; folded in `problems.md` `### friday october 16,
  2026 18:18 mdt`. Prior handoffs: `notes/spec-digest-20261017T014847Z.md`
  (the I65 digest — rehearsal protocol, carried-battery audit discipline,
  kit assembly) + `notes/spec-digest-20261016T002403Z.md`.

### F1 — the missing jump-to-bottom affordance (the pi port)

Owner finding: `new_problems.md` "missing a jump-to-bottom button" — "if you
scroll up while an answer is generating, pi places a jump-to-bottom button at
the bottom of the screen, we're missing that."

- **tart today has nothing of the kind** (verified in source): the transcript
  surface's only overlay composites are the selection highlight, the rail
  (`transcript_widget`, chat.rb :1665-:1678), and the flash on row 0
  (:1674-:1676); the viewport (viewport.rb) exposes wheel/scroll/window/mark
  — no indicator state, no end-jump seam, no `following?` readback.
- **pi's machinery** (installed-dist-verified citations): `compositeScrollToEndIndicator`
  (tui-alt-screen.ts :1638-:1667) — trigger: the indicator option is set AND
  `scrollView.followEnd` (mode) AND `!scrollView.isFollowingEnd` (detached);
  row = `clip.y + clip.height - 1` (the transcript area's LAST row); label
  truncated to the clip width then `column = clip.x + floor((clip.width −
  labelWidth)/2)` (CENTERED); when the rail is visible the label truncates
  LEFT of the scrollbar column (`rightEdge = scrollbarColumn ?? clip.x +
  clip.width`); skips image lines; composites via `compositeTuiLine`
  (tui.ts :426-:452 — the overlay's own SGR covers its cells, SEGMENT_RESET
  at both edges); records `scrollToEndIndicatorRect = {row, column, width:
  textWidth}` — the click rect.
- **The click** (`handleScrollToEndIndicatorMouseEvent`, tui-alt-screen.ts
  :1037-:1044): checked FIRST in the SGR mouse route (:940, before scrollbar
  and selection); a plain left PRESS inside the rect (`event.y === rect.row`,
  `rect.column <= event.x < rect.column + rect.width`) consumes the event and
  calls `scrollToBottom` (:497-:510) → `scrollView.scrollToEnd()`
  (scroll-view.ts :177-187: `scrollTop = max(0, contentHeight −
  viewportHeight)`, `followingEnd = followEnd`, and **marks scrollbar
  activity when changed**) + one render.
- **The label** (tui-renderer.ts :30-:34): `" ↓ Jump to latest message${shortcut
  ? ` · ${shortcut}` : ""} "` on `selectedBg` bg + `text` fg, where `shortcut =
  keyDisplayText("tui.altScreen.bottom")`; keybindings.ts :209 binds it
  `ctrl+end` (display "Ctrl+End"). **Survey result: tart has NO transcript
  bottom/jump-equivalent KEY binding** — the transcript is wheel-only since
  I35 (page keys page the EDITOR, chat.rb :1031-:1042; `home`/`end` are
  editor cursor moves, :1049-:1050; viewport.rb :62-:69 documents the
  retirement) → the shortcut segment is OMITTED and the missing binding is
  ITEMIZED as a deviation (not invented — adding a keybinding is outside this
  lane's frozen surface).
- **The theme token does not exist yet**: pi dark.json :27 `"selectedBg":
  "blueBg"` — the same blueBg var as `userMessageBg` (dark.json :33, already
  resolved in theme.rb :56-:57 as `#213b49`). The port's TOKENS table
  (theme.rb :34-:92) has no `selected_bg`; the pill needs it. The theme
  test's full-table equality pin (theme_test.rb :63 `assert_equal EXPECTED,
  Theme::TOKENS`) is the ONE itemized golden re-pin of this lane.

### F2 — the rail's neutral background over colored blocks (CONFIRMED tart-side, measured)

Owner finding: "also, the scrollbar shouldn't be replacing the background
color with the neutral background anyway, it should flow seamlessly across
it."

- **Root cause, verified in source** (`lib/tart/render/viewport.rb
  `overlay_rail_cell`, :121-:135): the overlay clips the row to width−1
  (keeping span styles), pads with `TUI.span(" " * pad)` — a **bg-less pad
  span** (:129-:130) — and appends `glyph.spans.first`, the rail glyph line's
  span, which carries its theme **fg only** (built by `scrollbar_glyphs`
  :142-:149 via `TUI.scrollbar_lines` tui.rb :193-:209). Every cell the rail
  covers (the pad and the glyph column) is composed with a NEUTRAL
  background; inside a colored tool-call block the panel bg is interrupted
  for exactly those cells.
- **pi's semantics** (`replaceScrollbarCell`, layout.ts :249-:278, called by
  `paintScrollbar` :309-:330 with `preserveTargetBackground = scrollbar !==
  "always"` — TRUE for the auto rail): the target cell's ANSI prefix is read
  and ONLY its active background re-applied (`getActiveBackgroundAnsi`,
  utils.ts :786-:790) after the segment reset — the glyph keeps its own fg,
  the bg comes from the overlaid cell.
- **Measured this session at base** (scratch worktree @ 9db6370): a
  full-width tool-success panel row (`Panel.padded_fg_rows(..., bg:
  Theme[:tool_success_bg])`, 20 cells of `#254131`) through
  `overlay_rail_cell` yields a last span `"│"` with `fg="#484e52", bg=nil`;
  through the real headless test-terminal buffer the rail frame reads
  `cell_bg(19, y) = nil` on every row of the block while columns 17-18 read
  `#254131` (script: this session's scratch, shape frozen in the AC's
  rail-bg gate).

### F3 — the wide-grapheme straddle (measured tart-side; the "inset rail" artifact's root)

- **Root cause, verified in source**: `overlay_rail_cell` clips via
  `Text.clip_spans(line.spans, width − 1)` (text.rb :197-:219), whose
  `fit` helper's over-wide-first-grapheme arm (:243, `[line.chars.first, 1]`
  — "force progress", the wrap-loop guard) KEEPS a wide grapheme that
  straddles the width−1 bound while crediting only 1 cell: the clipped head
  EXCEEDS width−1, the pad goes negative (dropped), and the glyph makes the
  line **width+1 cells in a width-wide area**.
- **Measured this session at base** (real test-terminal buffer, width 20): a
  bg row ending in `漢` occupying columns 18-19 — the railed line's span
  width measures **21**; on the rail frame the straddle row's
  `cell_symbol(19, y)` reads `" "` (the glyph CLIPPED OFF) while every
  neighbor row shows `┃` at column 19 — the visible "rail appears one or
  more columns in from the right-hand edge for just a few rows" class, on
  exactly the rows whose last cell is a wide grapheme.
- **pi's semantics** (`getGraphemeCellRange`, utils.ts :335-:352 + layout.ts
  :258-:266): the grapheme covering the rail column is replaced WHOLE —
  `start..end` widen to its full cell range, the line's before-part clips at
  `start`, and the cells become `cellPaddingBefore + replacement +
  cellPaddingAfter`, all under the target's active background (F2's rule).
  For a 2-wide grapheme at [width−2, width−1]: one pad cell + the glyph at
  the LAST column, the grapheme gone. Note `Text.take_cells` (text.rb
  :252-:260) already implements exactly this "straddler moves whole to the
  remainder" clip discipline on strings — the span-level analog is the fix's
  shape.

### F4 — the two unknown-home artifacts and the probe (bounded, first-class)

- Owner artifacts of unknown home: (i) "the scrollbar appears one or more
  columns in from the right-hand edge for just a few rows inside the tool
  call blocks" — F3 root-causes a tart-side mechanism for the straddle rows
  (measured), but the owner's "one or more columns" wording may include
  shapes F3 does not explain; (ii) "when the scrollbar fades out, the
  background in the artifacted area under where the scrollbar goes stays
  dark instead of going back to green".
- **Probe facts measured this session** (the method the AC freezes — a
  3-frame drive through the gem's own headless test terminal, cells read
  via `RatatuiRuby.get_cell_at` per frame): the fade frame at base
  RESTORES `cell_bg(19, y) = #254131` on every non-straddle row (the
  stuck-dark artifact did NOT reproduce in-buffer for these shapes); the
  straddle row's column 19 reads `bg = nil` even on the PRE-RAIL plain
  frame (the gem's wide-char continuation cell) — so the probe must compare
  the fade frame against the settle frame's own reads, never against the
  nominal bg. Both outcomes are still live for the builder to classify
  honestly.
- **RatatuiRuby API surface the probe rides** (gem 1.5.0, all behind
  tart's `TUI` seam, tui.rb): `init_test_terminal(w, h, viewport,
  height)` + `restore_terminal` (`TUI.run(headless: true, ...)`,
  tui.rb :146-:168), `RatatuiRuby.draw(widget)` (:329-:343 of the gem's
  ratatui_ruby.rb — the native diff/draw path), `get_cell_at(x,y)` →
  Cell{symbol, fg, bg, modifiers} (Session :73-:100), `get_buffer_content`.
  Buffer/Cell modules: buffer.rb, buffer/cell.rb of the repo clone.

### Environment facts the lane inherits

- Verification gate (tart): `bundle install --quiet && bundle exec rake`
  (minitest, `test/**/*_test.rb` + `gems/tui-split-rig/test/**/*_test.rb`) +
  `bundle exec ruby bench/seam_bench.rb` (prints SEAM_BENCH_OK).
- `BUNDLE_GEMFILE` leaks from tart/bundler contexts and kills bare
  `architect` calls — run as `env -u BUNDLE_GEMFILE architect …`. The
  pty-family probes need the `env -u HERDR_*` strip prefix (house idiom).
- Provision: tart lanes target integration_branch `project/pi-port` —
  VERIFY THE LANE-LEVEL FIELD at provision (the I50/I52 nil-class; tart
  has resolved via slug fallback, I64/I65 did).
- The plan's constraint set: chat.rb edits confined to the
  viewport/overlay/mouse/widget-assembly family (the spec freezes the touch
  set); the ENTRY-1 transcript content paths (markdown, pending registry,
  replay) must not change; no new gems; `repos/RatatuiRuby` read-only.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section viewport-polish specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision viewport-polish`
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
`architect rehearse viewport-polish` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze viewport-polish` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse viewport-polish` — before the freeze, while
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
subsection per lane. A copy is written to build/I66-viewport-polish-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section viewport-polish prompt --append --lane <lane> --from build/I66-viewport-polish-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I66-viewport-polish-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence viewport-polish --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section viewport-polish verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify viewport-polish`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
