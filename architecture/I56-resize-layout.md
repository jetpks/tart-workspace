# I56: resize-layout

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I56 resize-layout — Grounds

## §0 Entry, base, PHASE -1 verification

ENTRY C of PLAN 2 (live-run fixes rev3, `notes/plan-20261014T031751Z.md` lines 130-164):
owner findings problems.md items 1+2 — resize smaller and (a) the header help text
cuts off at the border instead of wrapping, (b) the ascii art cuts off, (c) the
editor input doesn't reflow until the cursor moves. "All three should react to
sigwinch itself."

Base: `repos/tart` `project/pi-port` @ `e099cf3` (I55's integrated tip, clean tree,
verified this session). pi oracle `repos/pi` @ f1b2e77f. Every plan cite verified
against the final tree:

- The I33 expandable-registration rebuild path EXISTS as cited —
  `lib/tart/render/transcript.rb` `set_tool_output_expanded` (:382-396) re-invokes
  every registered builder and splices rows in place (start/delta arithmetic);
  `push_expandable` (:789-791); the header registers at `chat.rb`
  `enqueue_motd_header` (:697-701) with its builder closing over boot-sampled
  `logo_lines`.
- `lib/tart/render/logos/` exists (10 pieces) with the plan's letter accurate.
- DRIFT (mechanism, not defect — same deliverable): the entry says the editor
  wrap "recomputes lazily on cursor movement". Verified at base: `Editor#window_layout`
  (editor.rb:909-925) re-wraps at the caller's width on EVERY render
  (`Chat#editor_content_lines` → `input_rows(editor_inner_width)` per frame). The
  live defect is UPSTREAM: the gem's `RatatuiRuby.viewport_area` answers the LAST
  DRAWN frame's area outside draw (gem ext `terminal/query.rs:118-124` —
  `LiveTerminal::viewport_area` = `t.get_frame().area()`; the area only refreshes
  in `Terminal::draw`'s autoresize). So the first post-SIGWINCH frame composes at
  the STALE width and NO second frame follows (nothing else marks the frame dirty)
  — proven live at §1. The fix composes the post-resize frame at the RESIZE
  EVENT's own width/height (`RatatuiRuby::Event::Resize` carries both), which
  makes the editor reflow on sigwinch with zero editor.rb changes.
- The entry's RECORDED DIVERGENCE paragraph (pi re-wraps the whole transcript;
  the port freezes scrollback rows) stays PARKED — not scoped here.

## §1 Live root-cause evidence (this session, real tmux, SIGWINCH path)

Calibration probe: `tmp/resize-calib/calib.rb` (rig primitives: boot 120×40 →
`resize-window` → settle → capture, no keypress). Artifacts under
`tmp/resize-calib/stage/`, `stage3/`:

- TART at base, pi identity, resized 120→50 with NO keypress: the hints row
  renders ` █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit` CLIPPED at 49 —
  the boot-width-wrapped rows frozen in the scrollback (`tart-resized50.txt`).
  Same for the notice and onboarding rows. Finding (a) reproduced.
- PI at the same flow re-wraps its header on SIGWINCH ALONE: hints row becomes
  two rows (`pi-resized50.txt` rows 3-4), notice and onboarding wrap too. pi's
  header is a live Text component; the port's header rows are frozen — the
  exact divergence the plan describes.
- TART editor: text typed at width 50, resize 50→30, capture with NO cursor
  movement: the input rows remain wrapped at 49 (`the quick brown fox jumps
  over` / `keeps running`) — clipped, not reflowed. ONE Right key re-wraps at 29
  (`tart-editor-w30-nocursor.txt` vs `tart-editor-w30-cursor.txt`). Finding (c)
  reproduced; mechanism per §0 drift note.
- tmux calibration: `resize-pane -x/-y` does NOT move a session created with
  `new-session -x/-y` (window-size manual — pane stayed 120×40); `resize-window
  -x/-y` DOES (pane 50×40 verified via display-message). The rig knob uses
  `resize-window`.

## §2 The gem/kernel resize mechanics (verified)

- `RatatuiRuby::Event::Resize` (gem `event/resize.rb`): carries `width`/`height`;
  `resize?` true; `moved?` → false via base-Event `method_missing` (ANY `?`
  predicate answers false on non-defining classes, and `respond_to?` answers true
  via `respond_to_missing?` — the existing `event.respond_to?(:mouse?) &&`
  `event.mouse?` guard pattern in `chat.rb:434` is therefore the correct house
  predicate form for a resize arm too).
- Kernel: `Core::Loop#process` marks the frame dirty for every non-mouse-move
  event (loop.rb:308-318) — the resize event DOES trigger one draw today; that
  draw composes at the stale area (§0). `request_draw` is reactor-context-safe
  from `on_event` (the loop fiber).
- Chat's `on_event` (chat.rb:431-438) explicitly IGNORES resize ("resize is
  ignored (the kernel marks the frame dirty either way…)") — the comment's premise
  is the defect: "the next frame recomposes from the session's fresh viewport" is
  false on a real terminal until a draw has run, and no second draw is scheduled.
- The headless test terminal CANNOT see this: `TUI.resize` →
  `RatatuiRuby.resize_terminal` (test backend only, mutations.rs) updates the
  area synchronously. The unit pins must therefore drive a SYNTHETIC
  `RatatuiRuby::Event::Resize` with dims differing from the test terminal's
  (chat_test's existing synthetic-event seams), not `session.resize`.

## §3 pi's header wrap — the oracle (live table + code-replica agreement)

pi's header is ONE Text component (paddingX 1, paddingY 0 — `BuiltInHeader(…, 1,
0)`, interactive-mode.ts:1071-1074) whose content is the \n-joined rows
(`withLogo(compactInstructions())` etc., :1015-1066). `Text.render`
(text.ts:66-90) wraps each line at `contentWidth = width - paddingX*2` through
`wrapTextWithAnsi` → `wrapSingleLine` (utils.ts:925-1010, whitespace/word token
stream, trimEnd on break, whitespace tokens never start a continuation,
breakLongWord for over-long words) and prefixes every wrapped row with the
paddingX left margin.

Empirical table captured live (pane 44→80, plain + styled): 
`tmp/resize-calib/stage3/pi-w{44,46,48,49,50,51,52,54,56,64,80}.txt` + `.styled`.
Shape examples: at pane 50 the hints row wraps `…ctrl+c/ctrl+d clear/exit` /
`␣␣· / commands · ! bash · ctrl+o more` (the break lands on the whitespace
token after `clear/exit` and the continuation KEEPS the separator's leading
space — muted run ` · ` re-opens at the pad column); at pane 80 it wraps
`…! bash ·` / `␣ctrl+o more` (word-token break, no leading space); at pane 52
`…clear/exit ·` / `␣/ commands…`; at pane 54 `…clear/exit · /` / `␣␣commands…`.

Cross-check: pi's OWN `wrapTextWithAnsi` run over the reconstructed hint-row
string (deno, `repos/pi/packages/tui/src/utils.ts` imported directly,
`/tmp/wrap_probe2.ts`) reproduces EVERY live row across content widths
42-62+80 including the leading-space quirks. The port ports the algorithm; the
artifact table is the byte oracle either way.

Current port state: `Motd.pi_header_lines` (motd.rb:146-166) builds the rows as
unwrapped span rows — the compact hint row, notice and onboarding are ONE row
each regardless of width (clipped by the buffer). `Motd.wrap_resource_row`
(:288-310, I33) is the PLAIN-text approximation of wrapSingleLine used by the
resource sections — it drops whitespace at breaks and cannot reproduce the
span-split continuation shapes above. `Text.wrap_row` (text.rb:41-52) is the
markdown-vocabulary span wrap (the port's own `fit` idiom) — also not
wrapSingleLine. A faithful span-aware port is new code (§5).

## §4 The art ladder (owner-directed, measured this session)

Cell-width table (`TUI.text_width` over every row, `build/i56-spec/ladder.txt`
regenerable): slant-relief 66/9 rows, twisted 42/8, rebel 40/11, mono-12 40/10,
soft 32/7, coder-mini 23/8, small 19/5, small-slant 18/5, miniwi 8/4, tmplr 6/4.
(The byte lengths differ wildly — rebel is 104 BYTES — cell width is the honest
measure.) Today `Motd.motd_logo_lines` (motd.rb:122-126) picks a RANDOM piece
per MOTD render with zero width awareness — the owner's finding (b): at narrow
widths a 66-cell piece renders clipped.

Ladder letter (plan, owner-directed): at header render pick the WIDEST piece
whose max row cell-width fits; if none fits, render the wordmark (the identity
name, e.g. `tart`). Re-pick at every header render event the plan enumerates:
boot, /new, resize rebuild. NOT the ctrl+o flip — the I33-frozen property
"a second ctrl+o restores the collapsed bytes exactly" (pinned:
`test_ctrl_o_flips_the_startup_header_in_place`, chat_test.rb:1717) requires the
art stable across a flip. Consequence (sanctioned by the owner's ladder letter):
the random-per-boot presentation becomes DETERMINISTIC per width — at the rig's
120 cols every tart-mode boot shows slant-relief. The existing
`test_motd_renders_logo_version_hints_context_and_skills` "any piece" assertion
survives; its "random" comment is corrected, not the assertion.

## §5 The mechanisms (spec owns the detail)

1. **The compose latch (Chat).** `on_event` grows a resize arm (the mouse-arm
   predicate form). `handle_resize(event)`: latch `[event.width, event.height]`;
   re-pick the header art at the latched width; rebuild the header block in
   place (2); `@kernel.request_draw`. `viewport_width`/`screen_height`
   (chat.rb:764-767/:1240-1243) prefer the latched dims; `render_frame`
   (chat.rb:410-425) clears the latch after `build_widget` (on a real terminal
   the draw's autoresize has refreshed the gem area by then; on the test
   terminal the latch is the only source of the new dims for that frame —
   one-frame semantics, unit-pinned). Guard: no-op when no header is enqueued
   (motd: false / resume screens).
2. **The resize-live rebuild (Transcript).** `push_expandable(builder,
   resize_live: false)` (default false — every existing call byte-identical);
   the header registers live. New `rebuild_live_expandables`: the
   `set_tool_output_expanded` splice arithmetic (:386-394) re-invoking ONLY
   live-flagged builders at the CURRENT expand state. Tool blocks / compaction
   panel / custom blocks stay frozen (the parked whole-transcript divergence —
   a full sweep would re-wrap the expandable tool rows while their neighbors
   stay boot-width, an inconsistent half-state).
3. **The header builder re-wraps (both families).** The builder
   (`motd_header_rows`) already reads `viewport_width` at invocation — with the
   latch set during the rebuild it re-wraps at the new width. The art source
   moves from a closed-over sample to a Chat ivar set by the ladder at
   enqueue/re-pick time (flip-stable within a width regime, re-picked on
   resize). `Motd.pi_header_lines` gains the width and wraps EVERY row through
   the new span-aware wrapSingleLine port at `width - 2*OUTPUT_PAD`
   (content width), each wrapped row prefixed by the pad — the §3 artifact
   bytes. `Motd.tart_header_lines` keeps `Text.wrap` for HINTS_LINE (the port's
   own presentation) at the current width; the art block = the ladder pick;
   the floor = the wordmark row.
4. **The editor needs NOTHING.** The per-frame recompute at the (latched) width
   IS the fix. editor.rb is OUT of the touch set; the unit pin proves the
   reflow-on-resize-without-cursor-movement property through the latch.

## §6 Deviations / reductions (itemized)

- Whole-transcript re-wrap on resize: PARKED (the entry's recorded divergence).
  The resource sections ([Context]/[Skills]/…) also stay boot-frozen — pi keeps
  them live, but the plan's letter is "header + art + editor only"; the same
  rebuild-live seam can carry them later.
- Mid-editor-text resize is NOT rig-captured (the runner captures once at
  settle; a mid-editor capture phase is new machinery beyond "if cheap") — the
  editor reflow is unit-pinned (the plan's mandatory pin) + the s16 SIGWINCH
  path is proven end-to-end.
- The pi-family wrap is ported for the HEADER rows only (the component the
  owner named); other components keep their current wrap paths.
- Random-per-boot art → deterministic ladder (§4, owner-directed).

## §7 The instrument: s16_resize_wrap (pre-calibrated live)

Runner knob `resize: [w, h]` (optional; two positive integers, validated at
load like the other knobs): after the boot settle, BEFORE the prompt,
`tmux resize-window -t <session> -x w -y h` + re-settle. No-knob path
byte-frozen (s1–s10 untouched).

Scenario `s16_resize_wrap`: prompt "hello", 1 request, the s1 reply,
`resize: [80, 40]`. Width 80 chosen by calibration: the hints row wraps
(content 84 > 78) AND the onboarding wraps (88 > 78) while the full staged
footer path (…/run-N/sandbox/<app>, ~-contracted) still FITS 80 cols — at 50
the truncated footer cwd rows escape the `parity-run-path` class and become
unsanctionable candidates (measured: `tmp/resize-calib/stage/` part D at 50 vs
80; the run-path classes anchor on `run-\d+/` which truncation removes).

Base candidate list at 80 (live, this session, `diff-d.rb` through the rig's
own Differ+Registry): 8 unknown candidates — the pi-wrapped hints pair (4
lines), the pi-wrapped onboarding pair (4 lines incl. 2 blank alignment rows)
— plus classified `parity-run-path` 2 + `footer-provider-prefix` 2. Every
candidate is this iteration's work; post-fix expectation: 0 candidates, exit 0.
The styled pass compares effective runs per identical-text line (differ.rb
:44-77) — the wrapped continuations' run structure (dim key re-opening, the
muted ` · ` re-opening with its leading space) is pinned by the §3 artifact and
must match.

## §8 Open questions (for the judge)

- OQ-1: the ladder's determinism kills random-per-boot art (owner-directed
  letter; the flip-restore property survives). Ratify as the standing
  presentation rule.
- OQ-2: the compose latch is the port's realization of "react to sigwinch
  itself" — one frame composed at the EVENT's dims rather than a draw-then-
  redraw pair. Behaviorally equivalent, zero stale flash; judge adjudicates the
  mechanism choice.
- OQ-3: s16's width-80 choice bakes the "footer path must fit" calibration
  (the class anchor truncates below ~73 cols) — recorded as the scenario's
  constraint, not a registry pin.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section resize-layout specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision resize-layout`
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
`architect rehearse resize-layout` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze resize-layout` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse resize-layout` — before the freeze, while
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
subsection per lane. A copy is written to build/I56-resize-layout-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section resize-layout prompt --append --lane <lane> --from build/I56-resize-layout-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I56-resize-layout-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence resize-layout --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section resize-layout verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify resize-layout`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
