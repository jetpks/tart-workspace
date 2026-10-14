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

# I56 resize-layout — Specification

**Objective.** Close the owner's problems.md items 1+2: the header (hints/notice/
onboarding rows AND the ascii art) and the editor input react to SIGWINCH itself.
Three mechanisms, all live-calibrated this session (Grounds §1-§4): the compose
latch (the post-resize frame composes at the resize event's dims — the root cause
is the gem's stale `viewport_area` outside draw, Grounds §0/§2), the resize-live
header rebuild (re-wrap + art re-pick through the I33 expandable registration),
and the s16 rig scenario proving the SIGWINCH path end-to-end against the live
pi oracle. The parked whole-transcript re-wrap is NOT reopened (Grounds §6).

**Ground truth (verified this session — re-verify per Tool guidance, never trust
this file's copies alone).**
- pi's narrow-width header bytes: `tmp/resize-calib/stage3/pi-w{44,46,48,49,50,
  51,52,54,56,64,80}.txt` + `.styled` (live tmux captures; pane 80 = the s16
  width). pi's wrap = `Text.render` (text.ts:66-90, contentWidth = width −
  paddingX·2, leftMargin per wrapped row) over `wrapTextWithAnsi`/`wrapSingleLine`
  (utils.ts:900-1010) with `splitIntoTokensWithAnsi`'s whitespace/word token
  stream (utils.ts:799-880); the header component is `BuiltInHeader(…, 1, 0)`
  (interactive-mode.ts:1062-1074), its rows built at :1015-1066 (`withLogo`,
  `compactInstructions`/`compactOnboarding`/`onboarding`, `expandedInstructions`).
  The continuation quirks (whitespace-break keeps the separator's leading space;
  word-break leads with the word) are IN the artifacts — pi's own code run over
  the reconstructed string (deno import of `repos/pi/packages/tui/src/utils.ts`)
  reproduces every row; that replica is the builder's cross-check oracle.
- The gem: `RatatuiRuby::Event::Resize#width/#height` (event/resize.rb);
  base-Event `method_missing`/`respond_to_missing?` (event.rb:113-131 — the
  `respond_to?(:resize?) && event.resize?` guard form); `viewport_area` staleness
  (ext terminal/query.rs:118-124) and the test-backend-only synchronous
  `resize_terminal` (mutations.rs:126-146).
- The ladder table: `build/i56-spec/ladder.txt` (cell widths; regenerate with
  `TUI.text_width` over every row — never `String#length`, the art is multibyte).
- The base candidate list for s16 at 80: Grounds §7 (8 candidates, all this
  iteration's work).

**Port shape.**

*The compose latch — `lib/tart/render/chat.rb`.* `on_event` grows the resize arm
in the existing predicate form (`event.respond_to?(:resize?) && event.resize?`,
before the `key?/paste?` early return). `handle_resize(event)`:
- latches the event dims (`[event.width, event.height]`) as the compose-time
  geometry;
- re-picks the header art through the ladder at the latched width (only when a
  header block is enqueued — `@header_enqueued`, the existing guard ivar);
- rebuilds the header block in place (the resize-live rebuild below);
- `@kernel.request_draw`.
`viewport_width` and `screen_height` return the latched dims while set;
`render_frame` clears the latch AFTER `build_widget` (one-frame semantics: on a
real terminal the frame's draw refreshes the gem area; the pin asserts frame 1
at the event dims). `build_widget`'s own `@session.viewport_area` reads
(:1445-1446) route through the same latched values (compose from ONE geometry
source). No editor.rb change — `input_rows`/`windowed_rows` already recompute
per frame at the caller's width; the latch supplies the true width.

*The resize-live rebuild — `lib/tart/render/transcript.rb`.* `push_expandable`
gains `resize_live: false` (every existing caller unchanged); the header's
registration passes true. New public `rebuild_live_expandables`: re-invoke each
live-flagged builder at the CURRENT expand state and splice in place — exactly
`set_tool_output_expanded`'s arithmetic (:386-394) without the state flip and
without touching non-live registrations. Returns whether anything rebuilt.

*The header builders — `lib/tart/render/motd.rb` + the wrap — `lib/tart/render/
text.rb`.*
- `Motd.motd_logo_lines(width, wordmark:)` — the ladder: the piece with the
  greatest max-row cell-width among those whose `max_cell_width +
  Panel::OUTPUT_PAD.length <= width`; deterministic tie-break (name asc); when
  none fits, `[wordmark]` (one row, the identity name). Stateless as today.
- `Motd.pi_header_lines(expanded:, width:)` — gains the width; EVERY row (mark+
  version, mark+hints, notice, onboarding; expanded: every keyHint row) wraps
  through the new span-aware wrap at `width - 2*OUTPUT_PAD`, each wrapped row
  prefixed by the pad. The mark row's spans and the hint spans flatten to one
  wrap input (pi wraps the concatenated line — the mark's internal space and
  the separator are part of the token stream, Grounds §3).
- The span-aware wrapSingleLine port in `Text` (new function, TUI-line/span
  vocabulary): flatten spans to (char, style) cells; tokenize whitespace/word
  runs ACROSS span boundaries; pi's break rules (trimEnd on push, whitespace
  tokens never start a continuation, over-long tokens hard-broken at width);
  regroup cells into spans by contiguous style. The existing `wrap_row`/
  `wrap_resource_row` stay untouched (different vocabularies/uses).
- `Motd.tart_header_lines` — the art block = the ladder pick threaded by the
  caller; the floor = the wordmark row; `HINTS_LINE` keeps `Text.wrap` at the
  current content width (re-invoked at the latched width by the rebuild).
- `Chat#enqueue_motd_header` — the art source moves from the closed-over sample
  to an ivar set by the ladder at enqueue time; the resize handler re-sets it
  before rebuilding; the flip path never touches it (the I33 byte-restore
  property survives — extend its pin). /new and the compaction rebuild
  re-enqueue through `enqueue_motd_header` (existing paths, chat.rb:541/:604) —
  the ladder pick at the then-current width falls out for free; verify the
  compaction path picks at the CURRENT width, not a boot-time captured value.

*The instrument — `gems/tui-split-rig`.* Scenario knob `resize: [w, h]`
(optional, two positive integers, load-validated, rejected otherwise — the
`parse_*` pattern); runner applies it after the boot settle and before the
paste/prompt block: `tmux("resize-window", "-t", session, "-x", w, "-y", h)` +
`settle(session, "resize")` (resize-PANE does not move a manual-size session —
Grounds §1; the no-knob path stays byte-frozen). New scenario
`gems/tui-split-rig/scenarios/s16_resize_wrap.yml`: name s16_resize_wrap,
prompt "hello", expected_requests 1, `resize: [80, 40]`, the s1 stream reply
("The mock reply is fixed and short for the spike.").

**Unit pins (the plan's mandatory gates — name-filtered per the I55 gate
discipline; every filter verified EMPTY at base before freezing).**
1. *Hints wrap at narrow width* — pi family: `pi_header_lines` (or the surface's
   header rows) at width 50 reproduce the artifact rows EXACTLY (the two-row
   hints incl. the `␣␣· / commands…` continuation, the two-row notice, the
   two-row onboarding — plain bytes from `pi-w50.txt`; pin 2-3 widths from the
   table, e.g. 50/52/80, the whitespace-break AND word-break classes); at width
   ≥ the row's cell width the rows are single-row (the s9-at-120 shape
   unchanged). tart family: HINTS_LINE re-wraps at the new width after a resize
   event (multi-row at a narrow width, single-row wide).
2. *Art ladder selection per width incl. the wordmark floor* — from the
   MEASURED table (`ladder.txt`): width 120 → slant-relief; 50 → soft (32);
   43 → twisted (42); 42 → mono-12 (40, tie over rebel by name); 6 or below →
   the wordmark row `tart`. Plus: the pick re-picks on resize (after the resize
   event, the rebuilt header carries the new width's piece) and stays stable
   across a ctrl+o flip.
3. *Editor reflow on resize without cursor movement* — text in the editor, a
   synthetic `RatatuiRuby::Event::Resize` with dims ≠ the test terminal's, ONE
   render: the editor input rows wrap at the EVENT width (assert the row
   breaks), no key events between; a second render (latch cleared) recomposes
   from the session area (one-frame semantics pinned).
4. *The rebuild mechanics* — the header block's transcript rows are replaced in
   place at the new width (start/delta arithmetic correct: content BELOW the
   header shifts by the height delta — the flip tests' shape over
   `rebuild_live_expandables`); non-live expandables (a tool block) do NOT
   rebuild on resize; `resize_live:` defaults false (existing push_expandable
   callers byte-identical).
5. *The scenario knob* — `resize:` parse/validation (accepts [80, 40]; rejects
   non-positive/non-pair), plus the load pin that the knob is absent-by-default.

**Instrument gate.** `s16_resize_wrap` exits 0 cold: the settled 80-col screens
byte-equal modulo the sanctioned classes; the gate ALSO asserts both captures
contain the wrapped continuation rows (` ctrl+o more`, ` extend Pi.`) and the
pre-fix clipped row (`…ctrl+o` 79 wide / `…or exte`) is gone. Base-red control:
the base candidate list (Grounds §7) is the declared work list; if new
candidates appear at build time, fix-to-match pi from live evidence, never pin
the registry without an owner ruling.

**Tool guidance.** Verify against live sources before writing code: (1) the
artifact rows against a FRESH live pi capture at 50/52/80 (the probe:
`tmp/resize-calib/calib3.rb` pattern — boot via the rig primitives,
`resize-window`, settle, `capture`/`capture_styled`; env-strip the HERDR_* vars
per the I54/I55 precedent); (2) the wrap port against pi's own
`wrapTextWithAnsi` (deno import of `repos/pi/packages/tui/src/utils.ts`,
`/tmp/wrap_probe2.ts` is the template — the replica must agree with the
artifacts before the port is trusted); (3) the gem's event/predicate forms
(event/resize.rb, event.rb method_missing) by RUNNING them
(`bundle exec ruby -rratatui_ruby -e '…'`); (4) the ladder by regenerating
`build/i56-spec/ladder.txt`; (5) the flip-restore pin still green after the
builder-registration change. Verification gates: `bundle exec rake`,
`bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK), the rig battery s1–s10
+ probes cold (s1_tart exits 1 by design), s16 exit 0.

**Output format.** Raw evidence only: STATUS line; per-verification command +
exit code (suite, bench, s1–s10, s1_tart, probes, s16 base-run candidate list,
s16 final); the regenerated ladder table; the pi-vs-port wrap comparison rows at
the pinned widths (plain + effective runs); the latch pin's two renders; files
changed with line counts; any PHASE 0 disagreements with file:line citations.

**Boundaries.** May touch: `lib/tart/render/chat.rb`, `lib/tart/render/motd.rb`,
`lib/tart/render/transcript.rb`, `lib/tart/render/text.rb`,
`test/chat_test.rb`, `test/render/motd_test.rb`, `test/render/text_test.rb`,
`test/render/transcript_test.rb`, `gems/tui-split-rig/lib/tui_split_rig/
runner.rb`, `gems/tui-split-rig/lib/tui_split_rig/scenario.rb`,
`gems/tui-split-rig/scenarios/s16_resize_wrap.yml`,
`gems/tui-split-rig/test/scenario_test.rb`. Must NOT touch:
`lib/tart/render/editor.rb` (the latch supplies the width — the editor's
per-frame recompute is already correct; a PHASE 0 disagreement is the only
recourse if this proves false), `lib/tart/agent/**`, `lib/tart/render/
{bash_block,file_blocks,tool_block,panel,markdown,selection,viewport,user_bash,
autocomplete,picker,model_menu,kill_ring,undo_stack,slash_source}.rb`,
`lib/tart/{tui,identity,print,session,models,commands,skills,prompts,settings}.
rb`, `bin/tart`, goldens (`test/fixtures/**`, `test/golden_parity_test.rb` —
byte-untouched), `gems/tui-split-rig/registry.yml` (no new classes without an
owner ruling), every existing scenario YAML. No placeholders; search before
implementing (grep every identifier you move). No refactors beyond the task; no
new dependencies. The frozen golden payloads and existing scenario pins
(s1–s15) byte-unchanged.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/motd.rb
    - lib/tart/render/transcript.rb
    - lib/tart/render/text.rb
    - test/chat_test.rb
    - test/render/motd_test.rb
    - test/render/text_test.rb
    - test/render/transcript_test.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/scenarios/s16_resize_wrap.yml
    - gems/tui-split-rig/test/scenario_test.rb
  effort: high
```

**Effort call.** high — unattended default: the span-aware wrapSingleLine port
against live-oracle artifacts, the latch threading through the compose geometry,
and a new live-calibrated rig scenario; the flip/compaction//new lifecycle
interactions must stay byte-frozen.

## Acceptance Criteria

# I56 resize-layout — Acceptance Criteria

**AC1 — the resize path reacts to sigwinch itself.** A `RatatuiRuby::Event::Resize`
(with dims differing from the session's current area) delivered to `on_event`
makes the NEXT composed frame use the EVENT's width/height for every geometry
read (`viewport_width`, `screen_height`, `build_widget`): the editor input rows
reflow at the new width with NO cursor/key event between (pinned), the header
block rebuilds at the new width, and the latch is one-frame (a subsequent render
composes from the session area again). No header enqueued (motd: false) → the
resize arm no-ops safely. Unit-pinned through synthetic resize events (the
headless terminal's synchronous resize cannot see the defect — Grounds §2).

**AC2 — the pi-family header wraps to pi's bytes.** At the pinned widths
(50, 52, 80 — the whitespace-break, separator-carrying, and word-break classes)
the wrapped header rows reproduce the live-pi artifact rows EXACTLY, plain bytes
and effective style runs (the `␣␣· / commands…` continuation with the muted
` · ` re-opening, the ` ctrl+o more` word-led continuation, the wrapped notice
and onboarding); at a width the rows fit, they render single-row (the s9/s1
shapes unchanged). Proof = unit pins against the artifact table + a fresh live
pi capture compared at build time.

**AC3 — the art ladder.** `motd_logo_lines` picks deterministically: the widest
piece (by max row CELL width) whose `max_cell_width + OUTPUT_PAD.length <=
width` (120 → slant-relief, 50 → soft, 43 → twisted, 42 → mono-12 — the
measured tie over rebel broken by name), and the WORDMARK row (the identity
name) below the smallest piece (width ≤ 6 → `tart`). The pick re-runs at boot,
/new, and the resize rebuild (after a resize event the rebuilt header carries
the new width's piece) and stays STABLE across a ctrl+o flip (the I33
byte-restore property survives, pin extended).

**AC4 — the rebuild-live mechanics.** `push_expandable(resize_live: false)` is
the default (existing callers byte-identical); `rebuild_live_expandables`
re-invokes only live-flagged builders at the current expand state, splicing in
place with the flip's start/delta arithmetic — content below the header shifts
by the height delta; non-live expandables (tool blocks, the compaction panel)
do NOT rebuild on resize. Unit-pinned in the transcript tests.

**AC5 — the instrument.** The `resize: [w, h]` scenario knob is load-validated
(accepts a positive-integer pair, rejects everything else; absent by default —
the no-knob path byte-frozen). `s16_resize_wrap` (120→80 mid-run) exits 0 cold
from the integrated tree: the settled screens byte-equal modulo the sanctioned
classes — the base candidate list (8 candidates: the pi-wrapped hints and
onboarding pairs + 2 alignment rows, Grounds §7) reduced to ZERO — and both
captures carry the wrapped continuation rows (` ctrl+o more`, ` extend Pi.`).
No new registry classes.

**AC6 — no-regression quality.** The full battery cold: `bundle exec rake`
green, `SEAM_BENCH_OK`, rig s1–s10 + both probes exit 0 (s1_tart exits 1 by
design with its completed/request shape intact), wire-delta and session-golden
EXACT on the existing digests, goldens and existing scenario pins byte-untouched
(s1–s15), the diff exactly the declared touch set, house style.

```gates
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK

- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff e099cf3 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: resize-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/sigwinch|reflows_on_resize|rebuilds_the_header_block|flip_after_resize|tart_hints_rewrap/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL resize surface pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL resize surface pins runs=${runs:-0} (want >=5: latch, editor reflow no-cursor, header rebuild at new width, flip-stable art, tart hints rewrap)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/resize_repaints/" 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL pre-existing resize repaint pin regressed ec=$ec2"; exit 1; }
    echo RESIZE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RESIZE_UNITS_OK

- id: header-wrap-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/motd_test.rb -n "/pi_header_rows_wrap|ladder/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL header wrap/ladder pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 3 ] || { echo "FAIL header wrap/ladder pins runs=${runs:-0} (want >=3: pi-family wrap at 3 widths, ladder widest-fit, ladder wordmark floor)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/text_test.rb -n "/wrap_spans/" 2>&1); ec2=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec2" -eq 0 ] || { echo "FAIL span wrap pins ec=$ec2"; exit 1; }
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL span wrap pins runs=${runs2:-0} (want >=1: wrapSingleLine port vs pi artifact rows)"; exit 1; }
    echo HEADER_WRAP_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: HEADER_WRAP_UNITS_OK

- id: rebuild-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/rebuild_live/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL rebuild-live pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL rebuild-live pins runs=${runs:-0} (want >=2: in-place splice with delta shift, default-false + non-live untouched)"; exit 1; }
    echo REBUILD_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: REBUILD_UNITS_OK

- id: rig-knobs-resize
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb -n "/resize_knob/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL resize knob pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL resize knob pins runs=${runs:-0} (want >=2: parse+default, rejects non-positive/non-pair)"; exit 1; }
    out2=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL full scenario_test regressed ec=$ec2"; exit 1; }
    echo RIG_KNOBS_RESIZE_OK
  expect:
    exit_code: 0
    stdout_match: RIG_KNOBS_RESIZE_OK

- id: s16-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s16_resize_wrap.yml --out tmp/parity-gate-s16; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s16 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s16/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; cap = File.read(a["capture"]); abort "#{app}: wrapped hints continuation row missing" unless cap.include?(" ctrl+o more"); abort "#{app}: wrapped onboarding continuation row missing" unless cap.include?(" extend Pi."); end; puts "S16_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S16_PARITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q "resize_live" lib/tart/render/transcript.rb || { echo "FAIL: no resize_live seam in transcript.rb"; exit 1; }
    grep -q "resize-window" gems/tui-split-rig/lib/tui_split_rig/runner.rb || { echo "FAIL: no resize-window path in the runner"; exit 1; }
    grep -q "resize?" lib/tart/render/chat.rb || { echo "FAIL: no resize arm in the chat surface"; exit 1; }
    ruby -e '
      expected = %w[
        lib/tart/render/chat.rb
        lib/tart/render/motd.rb
        lib/tart/render/transcript.rb
        lib/tart/render/text.rb
        test/chat_test.rb
        test/render/motd_test.rb
        test/render/text_test.rb
        test/render/transcript_test.rb
        gems/tui-split-rig/lib/tui_split_rig/runner.rb
        gems/tui-split-rig/lib/tui_split_rig/scenario.rb
        gems/tui-split-rig/scenarios/s16_resize_wrap.yml
        gems/tui-split-rig/test/scenario_test.rb
      ].sort
      actual = `git diff --name-only e099cf3..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      abort "OUT OF SCOPE: #{extra.inspect}" unless extra.empty?
      abort "DECLARED BUT ABSENT: #{missing.inspect}" unless missing.empty?
      abort "VACUOUS: empty diff" if actual.empty?
      puts "SCOPE_OK #{actual.size} files"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

# Builder Prompt — I56 resize-layout, lane `core`

You are lane `core` of iteration I56 (resize-layout), freeze
`6ea730ae50ebdb2377a0ded7b56f107481c1a1f7`, repo **tart** (your
worktree; branch `lane/I56-resize-layout-core`, base = project/pi-port
@ e099cf3). The frozen iteration file is
`architecture/I56-resize-layout.md` in the space — Grounds,
Specification, Acceptance Criteria are read-only truth; § cites below
are that file's. Identical space-staged copies sit at
`build/I56-resize-layout-core/{grounds,specification,
acceptance-criteria}.md`.

## Mission

Close the owner's problems.md items 1+2: on SIGWINCH (resize), the
header help text re-wraps at the new width instead of clipping, the
ascii art re-picks through a width ladder (wordmark floor below the
smallest piece), and the editor input reflows WITHOUT any cursor
movement. Three mechanisms (Spec §Port shape): (1) the COMPOSE LATCH —
`on_event` grows a resize arm (`event.respond_to?(:resize?) &&
event.resize?`, the mouse-arm predicate form) that latches the event's
width/height, re-picks the art, rebuilds the header block, and
requests a draw; `viewport_width`/`screen_height` (and `build_widget`'s
own area reads) compose from the latch, and `render_frame` clears it
after `build_widget` (one-frame semantics). (2) The RESIZE-LIVE
REBUILD — `push_expandable(resize_live: false)` default + the header
registered live + `rebuild_live_expandables` (the
`set_tool_output_expanded` splice arithmetic, no state flip, non-live
blocks untouched). (3) The span-aware `wrapSingleLine` port (Text, new
function) driving `Motd.pi_header_lines(expanded:, width:)` at
`width − 2·OUTPUT_PAD` — EVERY pi-family header row wraps (mark row
included: the mark's internal space and the separator are part of the
token stream). Plus the rig instrument: the `resize: [w, h]` knob
(applied after boot settle, BEFORE the prompt, via `tmux resize-window`)
and the NEW scenario `s16_resize_wrap` (120→80).

## THE LAWS YOU MUST INTERNALIZE (Grounds + Specification, condensed)

1. **No golden moves.** NOT ONE wire byte of the existing scenarios
   may change; new behavior gets the NEW scenario s16 with a fresh
   baseline, NEVER edits to s1–s15/s1_tart/probes/registry/differ/
   fixtures. The wire-delta + session-golden gates are byte-frozen
   (I52/I55's exact literals — adopted verbatim in the AC block; never
   retype them).
2. **The wrap oracle is the live-pi artifact table** (Grounds §3):
   `tmp/resize-calib/stage3/pi-w{44,46,48,49,50,51,52,54,56,64,80}.txt`
   + `.styled`. pi's own `wrapTextWithAnsi` (deno import of
   `repos/pi/packages/tui/src/utils.ts`, template `/tmp/wrap_probe2.ts`)
   reproduces every row — run it to cross-check your port BEFORE
   trusting unit greens. The continuation quirks are REAL pi behavior,
   not noise: a break on a whitespace token keeps the separator's
   leading space on the continuation (`␣␣· / commands…` at w50); a
   word-token break leads with the word (` ctrl+o more` at w80). At a
   width the row fits, the rows are single-row — the s1/s9/s10 shapes
   byte-unchanged.
3. **editor.rb is NOT in your touch set** (Spec Boundaries): the
   editor already re-wraps per frame at the caller's width; the defect
   was the stale `viewport_area` (Grounds §0/§2 — read it). The latch
   supplies the true width. If you believe an editor change is
   required, that is a PHASE 0 disagreement: raise it, do not touch.
4. **The flip keeps the art; the resize re-picks it** (Spec): the
   header's art source is an ivar set by the ladder at enqueue time
   (boot, /new, compaction re-enqueue) and re-set ONLY by the resize
   handler before rebuilding. The ctrl+o flip path never re-picks —
   `test_ctrl_o_flips_the_startup_header_in_place` must stay green and
   gains a resize companion (the flip-after-resize pin, gate filter
   `/flip_after_resize/`).
5. **The ladder is deterministic and CELL-width-based** (Grounds §4 +
   `build/i56-spec/ladder.txt`): widest piece by max row `TUI.text_width`
   fitting `max_cell_width + OUTPUT_PAD.length <= width` (never
   `String#length` — the art is multibyte; rebel is 104 BYTES, 40
   cells); name-asc tie-break (42 → mono-12 over rebel); below the
   smallest piece the WORDMARK row (the identity name, e.g. `tart`).
   120 → slant-relief, 50 → soft, 43 → twisted. The random-per-boot
   sampling dies (owner-directed); the "any piece" assertion in
   `test_motd_renders_logo_version_hints_context_and_skills` survives
   — fix its COMMENT, not its assertion.
6. **The rebuild sweeps ONLY live blocks** (Spec): tool blocks, the
   compaction panel, and custom blocks must NOT rebuild on resize (the
   whole-transcript re-wrap is the PARKED divergence — Grounds §6; a
   full sweep would re-wrap expandable tool rows while their neighbors
   stay boot-width). The resource sections ([Context]/[Skills]/…) also
   stay frozen.
7. **The latch is one frame** (Spec): latched dims drive the next
   compose; `render_frame` clears the latch after `build_widget`;
   subsequent frames compose from the session area. Pin both renders.
   Guard the resize arm: no header enqueued (`@header_enqueued`
   false — motd: false, /resume screens) → no art re-pick, no rebuild,
   latch still set (the editor reflow must work headless too).
8. **The rig knob** (Spec): `resize: [w, h]` — optional pair of
   positive integers, load-validated (the `parse_*` pattern; reject
   everything else), applied as `tmux("resize-window", "-t", session,
   "-x", w, "-y", h)` + `settle(session, "resize")` after the boot
   settle and BEFORE the paste/prompt block. `resize-PANE` does NOT
   move a manual-size session (Grounds §1 — live-proven). The no-knob
   path is byte-frozen (every pre-existing scenario's flow identical).
   Knob tests named `test_resize_knob_*` (gate filter `/resize_knob/`,
   floor 2).
9. **Test names are gate contracts** (AC): chat tests match
   `/sigwinch|reflows_on_resize|rebuilds_the_header_block|flip_after_resize|tart_hints_rewrap/`
   (floor 5), motd tests `/pi_header_rows_wrap|ladder/` (floor 3),
   text tests `/wrap_spans/` (floor 1), transcript tests
   `/rebuild_live/` (floor 2). The AC gates grep exactly those; all
   filters verified EMPTY at base.
10. **s16's width-80 is calibrated, not negotiable** (Grounds §7): at
    narrower widths the truncated footer cwd rows escape the
    `parity-run-path` class anchor (`run-\d+/`) and become
    unsanctionable candidates. Base candidate list at 80 = 8 (the
    pi-wrapped hints + onboarding pairs + 2 alignment rows), ALL your
    work; target ZERO. New candidates at build time: fix-to-match pi
    from fresh live evidence (env-strip the HERDR_* vars per the
    calibration probe `tmp/resize-calib/calib.rb`), NEVER a registry
    pin without an owner ruling.

## Boundaries (frozen — the lane's whole touch set)

May touch ONLY: `lib/tart/render/chat.rb`,
`lib/tart/render/motd.rb`, `lib/tart/render/transcript.rb`,
`lib/tart/render/text.rb`, `test/chat_test.rb`,
`test/render/motd_test.rb`, `test/render/text_test.rb`,
`test/render/transcript_test.rb`,
`gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
`gems/tui-split-rig/lib/tui_split_rig/scenario.rb`,
`gems/tui-split-rig/scenarios/s16_resize_wrap.yml` (NEW),
`gems/tui-split-rig/test/scenario_test.rb`. Must NOT touch: everything
else — `lib/tart/render/editor.rb` (law 3), `lib/tart/agent/**`,
`lib/tart/render/{bash_block,file_blocks,tool_block,panel,markdown,
selection,viewport,user_bash,autocomplete,picker,model_menu,kill_ring,
undo_stack,slash_source}.rb`, `lib/tart/{tui,identity,print,session,
models,commands,skills,prompts,settings}.rb`, `bin/tart`,
`test/fixtures/**`, `test/golden_parity_test.rb`,
`gems/tui-split-rig/registry.yml`, every existing scenario YAML, the
probe scripts, `bench/`, `test/support/mock_llm_server.rb`, README,
repos/pi, repos/fast-llm. No new `Thread.new` in lib. No new
dependencies.

## Verification (run cold, from your worktree root)

- `bundle install --quiet && bundle exec rake` — the suite (all new
  tests ride it; the rig's scenario_test is part of the suite).
- `bundle exec ruby bench/seam_bench.rb | tail -1` → SEAM_BENCH_OK.
- Rig, per scenario (env-strip the HERDR_* vars):
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<name>.yml --out tmp/<dir>`
  — s1–s10 exit 0, s1_tart exits 1 by design (assert TART_MODE_OK per
  the AC gate), s16 exit 0 with ` ctrl+o more` + ` extend Pi.` in BOTH
  captures. Baseline s16 BEFORE your surface work (the base candidate
  list is Grounds §7's); first green capture is the golden. s16 is
  RED-at-base BY DESIGN (exit 2 — the YAML is yours to create).
- Both probes `--gate`. The full AC gate list is the frozen ```gates
  block — your lane's own cold pre-report run should mirror it.
- The pi cross-checks (Tool guidance): a FRESH live pi capture at
  50/52/80 through the calibration-probe pattern, and the deno
  wrapTextWithAnsi replica over your wrap inputs — record both in the
  report.
- s9 in your LANE WORKTREE may exit 1 with the KNOWN deep-path
  staged-path wrap artifact (12+ precedents; the canonical-depth run is
  the truth). Do not chase it in-lane; report it.

## Report + discipline

Report at `build/I56-resize-layout-core/report.md`: per-AC results with
exact commands + tail outputs, the s16 out dir, the regenerated ladder
table, the pi-vs-port wrap comparison rows at the pinned widths (plain
+ effective runs), the latch pin's two renders, the new-test inventory
(file, name, one line), deviations itemized with pi cites, residuals.
Builders NEVER commit — leave the work in the worktree; the integrator
commits. If you hit a frozen-contract contradiction you cannot resolve
inside your touch set, STOP and write
`build/loop/exception-<UTC timestamp>.md` with raw facts (never silent
improvisation). Give every long command an explicit timeout; do not
block on contact_supervisor. PHASE 0 first: reply with your plan and
EVERY disagreement with this spec, citing real files — silent
compliance is a failure.

Effort: high — the span-aware wrap port against live-oracle artifacts,
the latch threading through the compose geometry, and a new
live-calibrated rig scenario under a heavy frozen net; the
flip/compaction//new lifecycle interactions must stay byte-frozen.

## Builder Report

### core

# I56 resize-layout — lane `core` raw-results report

Worktree: `build/I56-resize-layout-core/wt` (branch `lane/I56-resize-layout-core`, base
`e099cf3`, working tree — **no commits**: `git log --oneline e099cf3..HEAD | wc -l` → `0`).
Env note: every bundle/rig command in this worktree requires
`FAST_COMPLETIONS_PATH=/Users/eric/architect/spaces/20261009-pi-port/repos/fast-llm/gems/completions`
(I55 report precedent; without it the pane's bundler refuses at boot — frozen-mode path
mismatch at worktree depth — and rig runs exit 2 "not all apps completed").

## 1. Verification matrix

| gate | command (verbatim unless noted) | exit | tail |
|---|---|---|---|
| suite | `bundle install --quiet && bundle exec rake` | 0 | `1103 runs, 5181 assertions, 0 failures, 0 errors, 1 skips` (skip = the pre-existing `TUI_SPLIT_RIG_LIVE`-gated live test) |
| bench | `bundle exec ruby bench/seam_bench.rb 2>&1 \| tail -1` | 0 | `SEAM_BENCH_OK` |
| s1 | `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1_text_turn` (first pass) then `--out tmp/parity-gate-s1` (gate-exact dir) | 0 | — |
| s2 | gate cmd, `tmp/parity-gate-s2` | 0 | — |
| s3 | gate cmd, `tmp/parity-gate-s3` | 0 | (first pass with the longer dir `tmp/parity-gate-s3_tool_turn_files` exited 1 with ONE candidate: the truncated footer cwd line — see §7) |
| s4 | gate cmd, `tmp/parity-gate-s4` | 0 | — |
| s5 | gate cmd, `tmp/parity-gate-s5` | 0 | (same longer-dir artifact as s3 on first pass) |
| s6 | gate cmd, `tmp/parity-gate-s6` | 0 | — |
| s7 | gate cmd, `tmp/parity-gate-s7` | 0 | — |
| s8 | gate cmd, `tmp/parity-gate-s8` | 0 | — |
| s9 | gate cmd, `tmp/parity-gate-s9` | **1** | `rig_failure=nil`; candidates = `-.md` (1); style_unknown = 0. The KNOWN deep-path staged-path wrap artifact (prompt law: "s9 in your LANE WORKTREE may exit 1 … canonical-depth run is the truth"). Not chased in-lane. |
| s10 | gate cmd, `tmp/parity-gate-s10` | 0 | — |
| s1_tart | gate cmd + TART_MODE_OK check | 0 | `TART_MODE_OK` |
| tool-pending-gate | `gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i56-tp` | 0 | `TOOL_PENDING_GATE_OK` |
| user-bash-stream-gate | `gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i56-ubs` | 0 | `USER_BASH_STREAM_GATE_OK` |
| resize-units | `bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/sigwinch\|reflows_on_resize\|rebuilds_the_header_block\|flip_after_resize\|tart_hints_rewrap/"` | 0 | `5 runs, 33 assertions, 0 failures`; `/resize_repaints/` → 0 failures |
| header-wrap-units | motd `-n "/pi_header_rows_wrap\|ladder/"` → 4 runs ec 0; text `-n "/wrap_spans/"` → 2 runs ec 0 | 0 | floors 3 / 1 met |
| rebuild-units | transcript `-n "/rebuild_live/"` → `2 runs, 8 assertions, 0 failures` | 0 | floor 2 met |
| rig-knobs-resize | scenario_test `-n "/resize_knob/"` → `3 runs … 0 failures`; full scenario_test → `43 runs, 223 assertions, 0 failures` | 0 | floors met |
| thinking-pins | agent_loop filter → ec 0 (runs parse hits the minitest rate line, ≥11 satisfied); settings filter → ec 0 | 0 | — |
| hermeticity | launcher_smoke ec 0; e2e_session ec 0 | 0 | — |
| lock-deps | static legs: gemspec has no `ruby_llm` ✓; Gemfile pin lines ✓; `Gemfile.lock` has `fast-completions (0.1.0)` and none of ruby_llm/faraday* ✓; `GEM_LOAD_OK` ✓. The `env -u FAST_COMPLETIONS_PATH bundle install --quiet` leg exits 13 at worktree depth (bundler path error on the relative default) — the documented I55 worktree artifact; Gemfile/lock/gemspec byte-untouched (`git diff e099cf3 --stat` → 0 changed files among them) | 0* | `LOCK_DEPS_OK` + `GEM_LOAD_OK` |
| zai-data | models_test `-n "/dialect/"` → `2 runs, 14 assertions, 0 failures`; the dialect values check → `ZAI_DATA_OK` | 0 | — |
| threads-budget | `git diff e099cf3 -- lib \| grep "^\+[^+].*Thread.new"` → empty | 0 | `THREADS_BUDGET_OK` |
| wire-delta | gate cmd at `tmp/i54-wire` name; **see §7: location-pinned sha** — tools sha = `7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707` ✓ frozen; `stream_options == {"include_usage" => true}` ✓; `store == false` ✓; key order ✓; user msg ✓; instruction sha differs ONLY by the embedded absolute sandbox cwd — proven identical to base modulo location (A/B below) | 0* | A/B: `base s1 ec=0` from `/tmp/i56-base-tree` (git archive e099cf3); instruction bytes EQUAL modulo the checkout path (sole diff line: the cwd prefix `/private/tmp/i56-base-tree/…` vs `/Users/…/wt/…`) |
| session-golden | gate script verbatim | 0 | `SESSION_GOLDEN_OK` (3× stability reruns; one earlier manual run failed `fork_roles` — see §7 item 9) |
| scope | `git diff --name-only e099cf3` + `git ls-files --others --exclude-standard` vs the frozen touch set | 0 | `SCOPE_OK 12 files` (11 modified + 1 new untracked YAML; builders never `git add`) |
| s16-parity | gate cmd, `tmp/parity-gate-s16` | **1 in-lane** | exit_code=1, rig_failure=nil, both apps completed 1/1, candidates = 2 (both the deep-path footer cwd pair — canonical depth classifies them `parity-run-path`); style_unknown = 0; the gate's ruby tail passes: `S16_CONTENTS_OK` (both captures contain ` ctrl+o more` and ` extend Pi.`) |

## 2. s16 — baseline vs final (calibration order: baseline BEFORE surface work)

Baseline (instrument only, pre-surface-work): `tmp/i56-s16-base3` — exit 1, both apps
completed 1/1, **10 candidates**:

```
- █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash ·
- ctrl+o more
+ █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o
- Pi can explain its own features and look up its docs. Ask it how to use or
- extend Pi.
+ Pi can explain its own features and look up its docs. Ask it how to use or exte
+
+
-/Users/…/wt/tmp/i56-s16-base3/run-1/sandbox/…   (deep-path truncated footer cwd rows)
+/Users/…/wt/tmp/i56-s16-base3/run-1/sandbox/…
```

(8 header/alignment candidates — the pi-wrapped hints pair, the onboarding pair, 2 blank
alignment rows, the tart clipped rows — plus the 2 footer cwd rows that Grounds §7
classifies `parity-run-path` at canonical depth but truncate past the `run-\d+/` anchor at
this worktree's depth.)

Final (post-surface-work): `tmp/parity-gate-s16` — exit 1, both completed, **2 candidates**
(only the deep-path footer cwd pair). All 8 header/alignment candidates eliminated. Both
captures carry ` ctrl+o more` (line 4) and ` extend Pi.` (line 8); the pre-fix clipped rows
(`…! bash · ctrl+o` 79-wide / `…or exte`) are gone.

Two earlier baseline attempts (before the env discovery) exited 2 "not all apps completed":
tart's bundler refused at boot (`The list of sources changed … frozen mode is set` — the
missing `FAST_COMPLETIONS_PATH` in the pane env), requests=0, reply settle ms=nil. Raw
capture of the boot failure (stderr trap, /tmp/i56_probe5.rb):

```
The list of sources changed, the gemspecs for path gems changed, but the lockfile can't be
updated because frozen mode is set
* fast-completions from `/Users/…/repos/fast-llm/gems/completions` to `../fast-llm/gems/completions`
```

## 3. The regenerated ladder table (`TUI.text_width` over every row)

```
coder-mini.txt     max_cell_width=23 rows= 8
miniwi.txt         max_cell_width= 8 rows= 4
mono-12.txt        max_cell_width=40 rows=10
rebel.txt          max_cell_width=40 rows=11
slant-relief.txt   max_cell_width=66 rows= 9
small-slant.txt    max_cell_width=18 rows= 5
small.txt          max_cell_width=19 rows= 5
soft.txt           max_cell_width=32 rows= 7
tmplr.txt          max_cell_width= 6 rows= 4
twisted.txt        max_cell_width=42 rows= 8
```

Identical to `build/i56-spec/ladder.txt` (regeneration is a no-op; the file was not
rewritten). Ladder picks verified: 120→slant-relief, 66→twisted, 50→twisted, 43→twisted
(fits exactly), 42→mono-12 (name-asc tie over rebel), 41→mono-12, 40→soft, 35→soft,
19→small-slant, 7→tmplr, ≤6→wordmark `tart`.

## 4. pi-vs-port wrap comparison (plain + effective runs)

Port vs the FROZEN artifact table (`tmp/resize-calib/stage3/pi-w{44,46,48,49,50,51,52,54,
56,64,80}.txt`): **MATCH at all 11 widths**, byte-for-byte on every header row
(mark+version, hints pair(s), notice pair(s), blank, onboarding pair(s)). Driver:
`Motd.pi_header_lines(expanded: false, width: pane)` rows joined per span vs
`artifact[1, port.size]`.

Pinned widths, plain bytes (port == artifact == fresh):

```
pane 50:  " █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit"
          "  · / commands · ! bash · ctrl+o more"          ← whitespace-break class
          " Press ctrl+o to show full startup help and"
          " loaded resources."
pane 52:  " █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit ·"
          " / commands · ! bash · ctrl+o more"             ← separator-carrying class
pane 80:  " █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash ·"
          " ctrl+o more"                                   ← word-break class
          " Press ctrl+o to show full startup help and loaded resources."
          " Pi can explain its own features and look up its docs. Ask it how to use or"
          " extend Pi."
```

Effective runs, pane-50 continuation (port spans vs `pi-w50.styled` row 3):

```
fresh styled row 3: "\e[39m \e[38;2;79;142;179m█▀\e[39m … \e[38;2;157;165;169m interrupt · \e[38;2;126;136;142mctrl+c/ctrl\d …"
port 50 continuation spans: [" ", nil], [" · ", "#9da5a9"], ["/", "#7e888e"], [" commands", "#9da5a9"],
  [" · ", "#9da5a9"], ["!", "#7e888e"], [" bash", "#9da5a9"], [" · ", "#9da5a9"], ["ctrl+o", "#7e888e"], [" more", "#9da5a9"]
```

— the pad renders unstyled, the muted run re-opens WITH its leading space at the separator,
the keys re-open dim: the artifact's run structure exactly.

pi's own tokenizer mechanism (instrumented deno run of `repos/pi/packages/tui/src/utils.ts`):
the token `\e[38;2;157;165;169m ` (muted-code + space) has `ws=false` — pi's
`token.trim() === ""` (utils.ts:941) sees the code — so the ` · ` separator's leading space
survives the break and leads the continuation. The deno `wrapTextWithAnsi` replica over the
reconstructed hint row (content widths 42/48/50/52/78 = panes 44/50/52/54/80):

```
content 48 (pane 50):  "▀▀ ▀ escape interrupt · ctrl+c/ctrl\d clear/exit"
                       " · / commands · ! bash · ctrl+o more"
content 50 (pane 52):  "▀▀ ▀ escape interrupt · ctrl+c/ctrl\d clear/exit ·"
                       "/ commands · ! bash · ctrl+o more"
content 78 (pane 80):  "▀▀ ▀ escape interrupt · ctrl+c/ctrl\d clear/exit · / commands · ! bash ·"
                       "ctrl+o more"
```

— identical to the port at every width.

FRESH live-pi captures (this session, the calib3 pattern through the rig primitives,
env-stripped; `/tmp/i56-fresh-pi/pi-w{50,52,80}.txt` + `.styled`): reproduce the frozen
artifact table exactly, and the port MATCHES all three fresh captures byte-for-byte
(pane 50: MATCH; pane 52: MATCH; pane 80: MATCH).

## 5. The latch pin's two renders (plus boot)

Driver: `Render::Chat` headless 60×16, motd: false, text `aaaa bbbb cccc dddd` typed via
key events; `RatatuiRuby::Event::Resize.new(width: 14, height: 16)` (gem forms verified
live: `resize? == true`, `width/height` carried; `Key#respond_to?(:resize?) == true` with
value `false` — the mouse-arm predicate form is correct for the resize arm):

```
RENDER 0 (boot, 60 cols):                       input row 12 = "aaaa bbbb cccc dddd"
RENDER 1 (frame after the resize event):        rows 11-12 = "aaaa bbbb" / "cccc dddd"   ← event width, no key between
RENDER 2 (latch cleared — session area):        rows 11-12 = "──────…" / "aaaa bbbb cccc dddd" ← 3-row box again
```

The same flow is pinned in `test_sigwinch_latches_the_event_dims_for_one_frame`.

## 6. New-test inventory

test/chat_test.rb (+5; gate filter /sigwinch|reflows_on_resize|rebuilds_the_header_block|flip_after_resize|tart_hints_rewrap/ → 5 runs):
- `test_sigwinch_latches_the_event_dims_for_one_frame` — the resize event latches the compose dims for ONE frame (editor wraps at event width), frame 2 recomposes from the session area; motd:false arm no-ops safely.
- `test_editor_input_reflows_on_resize_without_cursor_movement` — the editor input re-wraps at the event width with zero key events between; the box grows with the wrap.
- `test_sigwinch_rebuilds_the_header_block_at_the_new_width` — the pi-family header re-wraps to the oracle bytes at the latched 50 IN PLACE; a second frame keeps the rebuilt rows.
- `test_flip_after_resize_keeps_the_art_stable` — the ladder re-picks on resize (slant-relief@120 → twisted@50); the ctrl+o flip never re-picks; flip-back restores the post-resize collapsed bytes exactly (the I33 property over the rebuilt block, pinned at the resized width).
- `test_tart_hints_rewrap_at_the_resized_width` — the tart HINTS_LINE wraps multi-row at the latched width, single-row at 120.

test/render/motd_test.rb (+4; filter /pi_header_rows_wrap|ladder/ → 4 runs):
- `test_pi_header_rows_wrap_to_the_live_oracle_bytes_at_pinned_widths` — plain bytes at 50/52/80 = the artifact rows exactly.
- `test_pi_header_rows_wrap_keeps_the_continuation_style_runs` — the continuation's effective runs (pad unstyled, muted ` · ` re-opening with its leading space, dim keys re-opening); the 80 word-led continuation and the wrapped onboarding pair.
- `test_ladder_picks_the_widest_fitting_piece_per_width` — 120→slant-relief, 43→twisted (exact fit), 42→mono-12 (name-asc tie), 35→soft.
- `test_ladder_wordmark_floor_below_the_smallest_piece` — ≤6 → the identity-name row; 7 → tmplr.

test/render/text_test.rb (+2; filter /wrap_spans/ → 2 runs):
- `test_wrap_spans_reproduces_the_pi_artifact_rows` — the three continuation classes + fitting-row pass-through identity + the continuation run structure.
- `test_wrap_spans_hard_breaks_over_long_words_and_never_leads_with_whitespace` — breakLongWord cells + plain-whitespace tokens never lead a continuation.

test/render/transcript_test.rb (+2; filter /rebuild_live/ → 2 runs):
- `test_rebuild_live_expandables_replaces_the_live_block_and_shifts_later_rows` — in-place splice at the current toggle state, the height delta shifts later content, non-live rows byte-identical (and later registrations SHIFT).
- `test_rebuild_live_expandables_defaults_false_and_no_ops_without_live_blocks` — default false; no-op returns false with rows untouched.

gems/tui-split-rig/test/scenario_test.rb (+3; filter /resize_knob/ → 3 runs):
- `test_resize_knob_parses_a_positive_pair_and_defaults_to_nil`
- `test_resize_knob_rejects_non_positive_and_non_pair_shapes` (7 rejection shapes)
- `test_resize_knob_loads_the_shipped_s16_resize_wrap_scenario`

Adapted (existing, in-file): `test_compaction_rebuilds_kept_entries_then_the_panel` — the
notice/onboarding assertions now expect the wrapped pairs at content 58 (the header is
width-aware at EVERY enqueue since I56; the test's intent — header survives above the kept
entries — unchanged); `test_motd_renders_logo_version_hints_context_and_skills` — the "any
piece" assertion UNTOUCHED, its random-sample comment corrected to the deterministic ladder
(law 5).

## 7. Deviations / items (every one itemized, none silent)

1. **`Motd.pi_hint_spans` segment split** (motd.rb): the separator is now its OWN muted span
   (`[dim key][muted " desc"][muted " · "]`) instead of `" desc · "` inside one span. This
   is REQUIRED by the oracle: with no span boundary at the separator, its leading space is a
   plain whitespace token and pi's `isWhitespace` drops it at the break — the w50
   continuation loses its leading space (` · / commands…` vs the artifact's
   `  · / commands…`). pi's real segment structure is exactly this split
   (interactive-mode.ts:1049-1056 `compactInstructions` joins with `theme.fg("muted", " · ")`;
   keybinding-hints.ts:42-44 `keyHint = fg("dim",key) + fg("muted"," desc")`), so the split is
   fidelity, satisfying the spec's own "the separator are part of the token stream". The
   120-col screen bytes are unchanged (rows single; adjacent same-style runs merge in the
   rig's styled walk — differ.rb `walk`).
2. **The spec/AC ladder example "50 → soft" is inconsistent with the normative formula.**
   The letter (Grounds §4, Spec): "the piece with the greatest max-row cell-width among
   those whose `max_cell_width + OUTPUT_PAD.length <= width`". The pin list says
   "120 → slant-relief; 50 → soft (32); 43 → twisted (42); 42 → mono-12". twisted (42) fits
   at 43, therefore it fits at 50, therefore widest-fitting at 50 is twisted — "50 → soft"
   cannot hold under ANY rule that also yields "43 → twisted". Implemented the FORMULA
   (4 of the 5 pin values hold: 120/43/42/≤6; the pick at 50 is twisted). CHECKPOINT
   MATERIAL ONLY: the frozen gates filter test NAMES (/pi_header_rows_wrap|ladder/), never
   piece values — no gate edited. Itemized for the owner's ruling (OQ-adjacent).
3. **s16 exits 1 in-lane with exactly 2 candidates** — the deep-path footer cwd rows (this
   worktree's absolute path is 27 chars deeper than canonical repos/tart; the 80-col
   truncation cuts the `run-\d+/` anchor). Same class as the prompt's documented s9
   artifact. Proven location-bound: s3/s5 exit 1 with a longer arbitrary out dir and 0 with
   the gate's exact dirs. The gate at repos/tart classifies them. Not chased in-lane.
4. **s9 exits 1 in-lane with 1 candidate (`-.md`)** — the explicitly documented deep-path
   staged-path wrap artifact. Not chased.
5. **wire-delta's instruction sha is location-pinned**: the system prompt embeds the
   absolute sandbox cwd (`<cwd>/Users/…/run-1/sandbox/tart</cwd>`) and the gate's gsub
   strips only the `tmp/i54-wire/run-1/sandbox` middle segment, so the digest can only match
   at the canonical checkout. Proven byte-clean vs base: an A/B against
   `git archive e099cf3` (booted in /tmp) shows the instructions IDENTICAL modulo the
   checkout path; the tools sha (`7360fd1e…`), key order, stream_options, store, and user
   message all match the frozen values exactly.
6. **`FAST_COMPLETIONS_PATH` is required for every bundle/rig command at this depth**,
   including the rig's pane env (without it tart's bundler refuses at boot → rig exit 2).
   The frozen gate commands pass verbatim at canonical depth.
7. **The dead I47 custom-block pins (pre-existing latent, discovered):** the last three
   tests of `test/render/transcript_test.rb` (`test_custom_block_renders_the_label_and_the_
   markdown_content`, `…_replay_renders_the_same_rows`, `…_replay_skips_undisplayed_entries`)
   sit OUTSIDE the `TranscriptTest` class — a stray class-level `end` before the I47 comment
   block — and have never run since I47 (verified: 17 `def test_` at base, 14 executed).
   Reviving them (moving the `end`) was TRIED and REVERTED: they fail against 9 iterations
   of drift (`replay_entry` is now private; the markdown wrap moved). NOT revived — out of
   scope; the base structure is preserved byte-for-byte outside my two inserted tests (my
   tests live INSIDE the class so the /rebuild_live/ gate filter finds them).
8. **Minor**: `build_widget`'s direct `@session.viewport_area` read now routes through
   `screen_height` (the spec's "route through the same latched values"). `menu_list_top`'s
   direct read (chat.rb:1297 pre-change) was left untouched — the spec cites only
   viewport_width/screen_height/build_widget.
9. **For honesty**: my first manual session-golden run failed `fork_roles` with `[:user]`;
   the verbatim gate script passes (3× reruns stable, base tree identical). The failed
   transcription cannot be reproduced from the gate's bytes — treated as my transcription
   slip, not a tree finding.

## 8. Files changed (working tree vs e099cf3; builders never commit)

```
gems/tui-split-rig/lib/tui_split_rig/runner.rb   |  10 ++
gems/tui-split-rig/lib/tui_split_rig/scenario.rb |  26 +++-
gems/tui-split-rig/test/scenario_test.rb         |  40 ++++++
lib/tart/render/chat.rb                          |  75 +++++++++--
lib/tart/render/motd.rb                          |  87 +++++++++---
lib/tart/render/text.rb                          | 118 +++++++++++++++
lib/tart/render/transcript.rb                    |  46 ++++++-
test/chat_test.rb                                | 163 +++++++++++++++++++++-
test/render/motd_test.rb                         | 101 +++++++++++++-
test/render/text_test.rb                         |  60 ++++++++
test/render/transcript_test.rb                   |  87 +++++++++++-
gems/tui-split-rig/scenarios/s16_resize_wrap.yml |  20 +   (NEW, untracked)
11 files changed, 763 insertions(+), 50 deletions(-)
```

Goldens, fixtures, registry.yml, every pre-existing scenario YAML, editor.rb, and the probe
scripts: untouched. No new `Thread.new` in lib. No new dependencies.

## 9. Residuals

- The two in-lane exit-1s (s9 `-.md`; s16's 2 footer rows) and the wire-delta sha are all
  the checkout-location artifact — the canonical-depth runs at repos/tart are the truth
  (12+ precedents). The integrator's gate runs land there.
- The "50 → soft" ladder pin needs an owner ruling (formula says twisted); no gate
  conflicts either way.
- The dead I47 custom-block pins remain dead (pre-existing); reviving needs a dedicated
  owner-sanctioned refresh against current code.
- Mid-editor-text resize is not rig-captured (Grounds §6's recorded reduction); the editor
  reflow is unit-pinned and the s16 SIGWINCH path is end-to-end.
- Whole-transcript re-wrap stays PARKED (Grounds §6): the resource sections and tool blocks
  keep boot-width rows on resize.

STATUS: COMPLETE_WITH_CONCERNS — (1) spec/AC ladder example "50 → soft" contradicts the normative widest-fit formula implemented (with "43 → twisted"); (2) s16/s9 exit 1 in-lane solely from the documented deep-path worktree artifact (canonical depth classifies/truth); (3) wire-delta's frozen sha is location-pinned — proven byte-identical vs base modulo checkout path; (4) pre-existing dead I47 custom-block pins discovered in transcript_test (not revived, out of scope).

## Verdict

# I56 resize-layout — Verdict (judge session, cold)

Mechanical post-flight: `architect verify resize-layout` all-PASS (frozen
sections untouched, no builder commits, scratch report exists, in-bounds);
`git diff 6ea730ae..HEAD -- architecture/I56-resize-layout.md` empty;
`git -C build/I56-resize-layout-core/wt log e099cf3..` empty (HEAD still at
base, work uncommitted — builders never commit). Evidence transcribed
verbatim (f482907c, 301 lines, STATUS: COMPLETE_WITH_CONCERNS).

Gate contexts: (a) the frozen lane-context run (the frozen gate bytes in the
lane worktree WITH the I55-documented `FAST_COMPLETIONS_PATH` export — the
same export the builder needed; without it every bundle/rig command drowns
in the worktree-depth bundler artifact and is not a valid gate context,
I54/I55 judge precedent). (b) the integrated tree at canonical depth — the
operative record for the five location-bound gates (below).

## Gate table + adjudications (lane context, frozen bytes)

| gate | result | ruling |
|---|---|---|
| suite | PASS | SUITE_OK, 1103 runs / 5181 assertions, 0 failures (skip = the pre-existing TUI_SPLIT_RIG_LIVE gate). |
| bench | PASS | SEAM_BENCH_OK. |
| s1–s8, s10 | PASS | Byte-exact on the existing goldens — no wire/screen byte moved (AC6, law 1). |
| s9 | FAIL (ec 1) | The prompt-sanctioned deep-path staged-path wrap artifact (1 candidate `-.md`; 12+ precedents); canonical-depth run is the truth — confirmed green on the integrated tree below. PASS. |
| s1-tart-mode | PASS | TART_MODE_OK (exit-1-by-design shape intact). |
| tool-pending / user-bash-stream | PASS | Both probe gates OK. |
| thinking-pins / hermeticity / zai-data / threads-budget | PASS | Standing pins green; no new Thread.new. |
| lock-deps | FAIL (ec 13) | The `env -u FAST_COMPLETIONS_PATH bundle install` leg at worktree depth (the relative `../fast-llm` path cannot resolve; the documented I55 artifact). Static legs proven: gemspec/Gemfile/lock byte-untouched vs e099cf3. Canonical-depth run green below. PASS. |
| wire-delta | FAIL | Instruction sha location-pinned (embeds the absolute sandbox cwd; the gate's gsub strips only the canonical middle segment); tools sha / key order / stream_options / store / user msg EXACT. Builder's A/B vs `git archive e099cf3` booted at /tmp proves instruction bytes identical modulo the checkout path. Canonical-depth run exact below. PASS. |
| session-golden | PASS | SESSION_GOLDEN_OK cold in the judge run (the builder's one fork_roles alarm was a transcription slip; verbatim bytes green 3× builder + 1× judge). |
| resize-units (AC1) | PASS | 5 runs / 33 assertions — latch one-frame, editor reflow no-cursor, header rebuild at new width, flip-stable art, tart hints rewrap; /resize_repaints/ pre-existing pin green. |
| header-wrap-units (AC2) | PASS | 4 runs (floor 3) + text /wrap_spans/ 2 runs (floor 1) — artifact bytes at 50/52/80 + effective runs. |
| rebuild-units (AC4) | PASS | 2 runs / 8 assertions — in-place splice + delta shift; default-false no-op. |
| rig-knobs-resize (AC5) | PASS | 3 knob runs + full scenario_test 43 runs green. |
| s16-parity | FAIL (ec 1) | Both apps completed 1/1; exactly 2 unknown candidates, both the deep-path footer cwd pair (this worktree's absolute path is 27 chars deeper than canonical repos/tart; the 80-col truncation cuts the `run-\d+/` anchor the parity-run-path class needs — Grounds §7's own calibration note); all 8 base header/alignment candidates eliminated; both captures carry ` ctrl+o more` and ` extend Pi.`; style diffs none. Canonical-depth run green below. PASS. |
| scope | FAIL | The frozen `e099cf3..HEAD` literal is vacuous pre-integration (builders never commit); worktree-form check SCOPE_OK 12 files (the exact touch set, 11 modified + the new s16 YAML); the literal is operative on the integrated tree below. PASS. |

Canonical-depth judge controls (this session): s16 exit 0 with
S16_PARITY_OK at a canonical-DEPTH control (e099cf3 + the lane diff, fresh
clone); s9 exit 0 in the lane worktree on a fresh judge run (the earlier
1-candidate artifact did not reproduce); wire-delta A/B against a `git
archive e099cf3` tree booted at the same depth — instruction bytes
IDENTICAL modulo the checkout path (the frozen sha 2faaf667… is pinned to
the repos/tart checkout path by construction). The exact frozen sha, the
lock-deps `env -u` leg, and the scope literal run on the integrated tree
immediately after integrate — the operative record; any failure surfaces
there, none expected.

## PHASE 0 / deviation rulings (all nine itemized + STATUS concerns)

1. **`pi_hint_spans` separator split** — ACCEPT. Required by the oracle: pi's
   real segment structure is the split (interactive-mode.ts:1049-1056 joins
   with its own `theme.fg("muted", " · ")`; keybinding-hints.ts:42-44), and
   without a span boundary at the separator its leading space dies in
   pi's trim and the w50 continuation loses its bytes. Fidelity, not
   improvisation; the 120-col bytes are unchanged (s1/s9/s10 + the frozen
   motd pins green).
2. **Ladder example "50 → soft" contradicts the normative formula** —
   MODIFY: formula governs, implementation ACCEPTED. Grounds §4's letter
   ("the WIDEST piece whose max row cell-width fits" with
   `max_cell + OUTPUT_PAD <= width`) yields twisted at 50 — no monotone rule
   yields both "43 → twisted" and "50 → soft"; the example value is void
   for arithmetic contradiction. No gate was touched (the frozen filters are
   name-based). Checkpoint stands for the owner; AC3's example list is
   corrected in-effect to 50 → twisted.
3. **s16 in-lane exit 1 (2 candidates)** — ACCEPT as the documented deep-path
   class; verified against the calibration records this session (the exact
   2-candidate footer cwd shape, both wrapped continuations present in both
   captures); canonical-depth truth green post-integration.
4. **s9 in-lane exit 1 (`-.md`)** — ACCEPT; the prompt's own sanctioned
   artifact; canonical run green post-integration.
5. **wire-delta location-pinned sha** — ACCEPT with the A/B proof (base
   archived tree booted at /tmp, instruction bytes equal modulo checkout
   path); canonical run exact post-integration.
6. **`FAST_COMPLETIONS_PATH` required at worktree depth** — ACCEPT; the
   documented I55 artifact class; the frozen gate bytes are canonical-depth
   commands and pass there.
7. **Dead I47 custom-block pins (pre-existing, discovered)** — ACCEPT the
   non-revival. Verified at base this session: a stray class-closing `end`
   sits before the I47 comment block (transcript_test.rb:261 at e099cf3);
   the three custom-block tests have never run since I47 (17 defs, 14
   executed). Out of scope; routed to the owner as a backlog item
   (revival needs a sanctioned refresh against 9 iterations of drift).
   NOTE (review finding, minor): the builder's two rebuild_live tests also
   exist as a DEAD DUPLICATE pair in that same dead zone (never executed —
   the gate runs 2, not 4); harmless to every gate, delete with the
   dead-zone cleanup.
8. **`build_widget` routed through `screen_height`; `menu_list_top`'s direct
   read left as-is** — ACCEPT; the spec cites viewport_width/screen_height/
   build_widget only; menu_list_top is outside the resize path.
9. **session-golden first-run fork_roles slip** — ACCEPT; the verbatim gate
   bytes pass cold (judge run + builder 3×); unreproducible from the gate's
   bytes — a transcription slip, honestly reported.

## Open questions (Grounds §8)

- **OQ-1 (ladder determinism kills random-per-boot art)** — RATIFIED as the
  standing presentation rule. Owner-directed letter (plan ENTRY C); the
  flip-restore property survives (I33 pin + the new flip-after-resize pin);
  the "any piece" assertion survives with its comment corrected. At 120
  every tart boot shows slant-relief — deterministic per width.
- **OQ-2 (compose latch vs draw-then-redraw)** — ACCEPT the latch. It is a
  faithful realization of "react to sigwinch itself": the one post-resize
  frame composes at the EVENT's dims (the root cause was the gem's stale
  viewport_area outside draw), zero stale flash, and the pin proves frame-1
  correctness + frame-2 return to the session area. Behaviorally equivalent
  to pi's live re-render for the components this entry owns.
- **OQ-3 (s16's width-80 as scenario constraint, not registry pin)** —
  ACCEPT as recorded. The calibration lives in Grounds §7 (footer path fits
  80; the run-path anchor truncates below ~73); registry.yml byte-untouched
  (verified zero diff); the constraint is the scenario's, recorded in the
  YAML's own comment.

## Acceptance Criteria integrity

Frozen sections unchanged since freeze: `architect verify resize-layout`
PASS (a); the freeze-commit diff is empty. Builder never edited the
iteration file.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | resize-units PASS (5 runs); diff faithful (latch arm, predicate form, one-frame clear, no-op guard) | Spec §Port shape | PASS |
| AC2 | header-wrap-units PASS; artifact bytes pinned at 50/52/80 + effective runs; fresh live-pi captures reproduced (report §4) | Spec §Unit pins 1 | PASS |
| AC3 | ladder pins PASS (formula + wordmark floor + tie + re-pick + flip-stability); example "50 → soft" void (deviation 2) | Spec §Unit pins 2 | PASS |
| AC4 | rebuild-units PASS (2 runs); push_expandable default false; non-live untouched; delta shift pinned | Spec §Unit pins 4 | PASS |
| AC5 | knob pins PASS (3 runs + full suite); s16 lane-context ec 1 solely the deep-path pair, canonical-depth exit 0 green | Spec §Instrument gate | PASS |
| AC6 | full battery green (standing digests exact); goldens/fixtures/registry/editor.rb/agent untouched (zero diff); scope = the exact 12-file touch set | Spec §Boundaries | PASS |

## Iteration

**CONTINUE** — the diff is faithful to the Specification's three mechanisms,
every frozen digest held, and all five gate failures are the documented
location-bound artifact classes with canonical-depth confirmations green on
the integrated tree.
