# I20: viewport-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8, the s4 slice's two surviving viewport classes (I19 verdict + this session's spec-time forensics), + the I19 rig follow-ups (the next measured work list).**

I19 landed the bash preview collapse byte-correct (s4's convo rows byte-identical between the settled windows) but s4 still exits 1 on two viewport-level classes. The I19 Verdict's decomposition ("a trailing row after the final reply" + "tart stayed top-anchored") was PARTLY WRONG — this session's source read + probe re-derived both defects to mechanism:

**Probe (this session, `tmp/probe-reply25.yml` → `tmp/probe-reply25d/`, a plain 25-tight-paragraph reply sized to overflow by exactly one row):** pi settles at scroll offset 2 (window starts at the hints line, ends `[reply, blank]`), tart at offset 1 (window starts at the top mark, ends `[reply]`) — **the transcript BUFFERS are byte-identical 36 rows; there is NO trailing content row.** The observable difference is pure row-budget arithmetic:

- **Defect A — the transcript viewport budget.** pi's fullscreen layout is a VStack `[transcript ScrollView, dock]` (pi `chat-viewport.ts:22-45`); the dock's natural height = pendingMessages(0) + status(0) + **widgetsAbove(1)** + editor(3) + widgetsBelow(0) + footer(2) = 6 rows — because `renderWidgets()` initializes the widgets-above container with a DEFAULT `Spacer(1)` when no extension widgets exist (pi `interactive-mode.ts:966-968` → `renderWidgetContainer(container, widgets, spacerWhenEmpty: true, …)` — the spacer-when-empty branch). So **pi's transcript viewport = 34 rows**; the blank row below the settled transcript (pi window row 35) is that dock spacer, not scroll content. tart's budget models a 5-row dock (`transcript_area_rows`, chat.rb ≈:1601 — height − editor − footer), so tart's viewport = 35: one row too many → tart's settled window shows one more buffer row (the top mark pi scrolled off) and its transcript's bottom row is content where pi's is the spacer.
- **Defect B — the auto scrollbar's trigger.** pi's `"auto"` rail is **transient**: `isScrollbarVisible` requires `transientScrollbarVisible` (pi `scroll-view.ts:74-78`), which only `markScrollbarActivity` sets (scroll-view.ts:97-110) — called from the real scroll moves (`scrollTo` :144, `scrollBy` :159, `scrollToStart` :172, `scrollToEnd` :184, `setScrollbarActive` :123) and NOT from `updateLayout`'s follow-end adjustment (:180-192) — and auto-hides after `scrollbarHideDelayMs` (default 1000, :55) via a timer that clears the flag and re-renders (:113-118); it force-hides when content fits (:200). `paintScrollbar` paints only when `isScrollbarVisible` (pi `layout.ts:280-294` — the `includeHiddenAuto` param is for geometry queries, not painting). A settled screen NEVER shows the rail, even on overflow (pi overflows 36>34 on s4 and shows none). tart paints the rail persistently on ANY overflow (chat.rb `transcript_widget`/`scrollbar_glyphs` ≈:1902-1940 — its comment "hidden when the view fits" mis-states pi's settled semantics).
- **Defect B's second half — the carved rail column.** tart renders the rail as a DEDICATED 1-cell column (chat.rb transcript_widget's horizontal layout) whenever content overflows, so EVERY row pads to full width with trailing spaces even when the glyphs never show; pi's content wraps to the FULL width for `"auto"` (`getContentWidth`, scroll-view.ts:80-82: only `"always"` reserves a column) and the rail PAINTS OVER the last column only while visible (pi layout.ts:307-330 `replaceScrollbarCell`). On s4 this alone fails every row (tart rows carry trailing pad, pi's end at content). The transient fix must therefore also retire the permanent carve — overlay, not column.

**Exit-0 mechanism (evidence-backed this time, unlike I19's):** with both fixes, tart's viewport = 34, buffer 36 → offset 2 → window = pi's byte-for-byte (b3–b36, hints-line first, ends at the reply), row 35 = the dock spacer row, rows 36-40 chrome unchanged, rail hidden at settle, no carved padding → the s4 diff collapses to the two sanctioned path classes. The probe scenario (25-paragraph overflow-by-one) exits 0 under the same arithmetic — the lane's mid-flight sanity instrument.

**Rig follow-ups (the next measured work list, I19 verdict):** no scenario exercises (a) **bash output truncation** (the >2000-line tail cap + the `[Showing lines … Full output: …]` notice composing after the collapsed preview — and the notice's fg: pi renders it `warning`, the port's is `tool_output`, the I19 carry-forward gap) or (b) **call-row wrapping** (the I18 no-wrap CUT — pi's Text wraps the `$ <command>` and write-call rows to the viewport; s4's short paths/commands never exercised it). s5/s6 author + baseline those slices; their candidate lists are the NEXT iteration's measured work.

**CUTs carried:** `setScrollbarActive`'s driver (pi marks the thumb `█` vs `┃` when the scrollbar is "active" — layout.ts:317-319; what sets it in pi is a PHASE-0 verify — port the reachable subset, itemize the cut); ctrl+o expand binding (backlog C, unchanged).

## Specification

### Objective

Close the s4 slice of **BRIEF §8** — `bin/pty-tester run parity/scenarios/s4_bash_variants.yml` exits **0** — by fixing the two viewport defects the I20 Grounds root-caused (A: the transcript viewport budget — the missing widgets-above dock spacer row; B: the transient auto scrollbar — activity-gated visibility, auto-hide, overlay instead of a carved column), plus the small I19 carry-forward (the truncation notice's `warning` fg, pi bash.ts:88). In parallel, the rig seam authors + baselines the next two measured slices: **s5_bash_truncation** (output truncation + notice composition) and **s6_long_calls** (call-row wrapping) — evidence-only baselines whose candidate lists are the NEXT iteration's work list; no exit-0 is frozen for them.

The s4 exit-0 mechanism is evidence-backed (Grounds probe): with both fixes, tart's settled s4 window is byte-identical to pi's (offset 2, hints-line first, ends at the reply, spacer row below, no rail, no carved padding).

### Output format (raw evidence, no interpretation)

- render: the named test list (viewport budget + spacer row + settled-window geometry on the probe shape; transient rail: mark sites, hide timing, force-hide-on-fit, overlay shape incl. the no-carved-padding row shape; notice fg) with the per-row assertions they pin; the probe re-run (command + exit code + both captures' first/last content rows + geometry); the s4 + s1/s2/s3 run commands + exit codes; any legitimate test updates, itemized.
- rig: the two scenarios' files (verbatim), the load-pin tests, each baseline run's command + exit code + classes + candidates verbatim; any registry decision, evidenced.
- PHASE 0: numbered disagreements/deviations with file:line evidence, as ever.

### Tool guidance (verify against live sources BEFORE writing code)

- Verification: `bundle install --quiet && bundle exec rake` (minitest); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Parity instrument: `bin/pty-tester run parity/scenarios/<s>.yml --out DIR` (exit 0 = parity). **Control baselines (READ ONLY, architect's runs this session):** `tmp/probe-reply25d/` in `repos/tart` (the 25-paragraph probe: exit 1; pi offset 2 / tart offset 1, buffers identical) and `tmp/parity-gate-s4/` (I19's post-collapse state: exit 1, two classes). The probe scenario source: `tmp/probe_reply25.yml` — the lane re-creates it in ITS OWN scratch dir and re-runs; expected POST-FIX: **exit 0**.
- pi oracle (read-only, `repos/pi`):
  - `packages/coding-agent/src/modes/interactive/chat-viewport.ts:22-45` — the VStack `[transcript, dock]`; the dock's children and their natural heights.
  - `packages/coding-agent/src/modes/interactive/interactive-mode.ts:966-968, 2502-2517` — `renderWidgets` / `renderWidgetContainer(…, spacerWhenEmpty: true, …)` — the widgets-above default `Spacer(1)`.
  - `packages/tui/src/components/scroll-view.ts` IN FULL — `:46-55` (options, `scrollbarHideDelayMs` default 1000), `:74-82` (`isScrollbarVisible`, `getContentWidth` — full content width for `"auto"`), `:97-118` (`markScrollbarActivity`/`hideTransientScrollbar` — the timer + re-render), `:119-123` (`setScrollbarActive`), `:131-192` (the mark sites: scrollTo/scrollBy/scrollToStart/scrollToEnd; updateLayout does NOT mark), `:200` (force-hide on fit), `:215-220` (render).
  - `packages/tui/src/layout.ts:280-294, 307-330` — `getScrollbarGeometry` (`includeHiddenAuto` is for geometry queries, NOT painting) and `paintScrollbar` (paints only when `isScrollbarVisible`; overlays the last column via `replaceScrollbarCell`; thumb `█` when active, `┃` at rest, :317-319).
  - `packages/coding-agent/src/core/tools/renderers/bash.ts:88` — the truncation notice renders `theme.fg("warning", …)`.
  - PHASE 0 must ALSO verify what drives `setScrollbarActive` in pi (rg it) and port the reachable subset, itemizing any cut.
- Existing seams to build on (read IN FULL before writing): `lib/tart/render/chat.rb` — `transcript_area_rows` (≈:1601, the budget), `build_widget`/`transcript_widget` (≈:1890-1940, the layout + the carved rail column + the follow-end offset math + `scrollbar_glyphs`), the scroll-state section (`scroll_page`/`scroll_by`, ≈:1592-1612 — the user-scroll seams that map to pi's mark sites), `split_truncation_notice` (I19 — the notice's fg moves to `Theme[:warning]`), `Chat#initialize`'s `@kernel` (the Core::Loop). Timer/redraw seams: `lib/tart/core/loop.rb` — `animate(duration:)` (wakes an idle loop, deadline-paced frames while open), `async`/`every` (reactor-context timers), the dirty-gated `draw_frame`. Two legal port shapes for the auto-hide (builder's call, itemize the choice): (i) a one-shot reactor timer that clears the flag and wakes a redraw; (ii) an activity timestamp + a re-armed `@kernel.animate` window, the render checking elapsed ≥ delay to clear the flag. Either way: no busy redraw storm at idle, re-armed on new activity, and NO real-second sleeps in tests (inject a short delay or fake the clock — see how existing tests control time).
- House style: pi-source anchor comments, factored helpers, terse public-interface tests (the `with_chat`/`draw`/`cell_fg` idiom in `test/chat_test.rb`), no mock/stub of the class under test.

### Boundaries

- **render lane may touch:** `lib/tart/render/chat.rb`, `lib/tart/core/loop.rb` (ONLY a minimal timer/wake seam if shape (i) needs one — prefer no-change shapes first), `test/chat_test.rb`, `test/loop_test.rb` (only if loop.rb is touched). **Must not:** `lib/tart/tui.rb` (the scrollbar GEOMETRY helper `scrollbar_lines` is already pi-exact — the defect is the trigger, not the geometry), `lib/tart/tools/**`, `lib/tart/agent/**`, `bin/tart`, `parity/**`, `tart.gemspec`/`Gemfile*`, any other test file.
- **rig lane may touch:** `parity/scenarios/s5_bash_truncation.yml` (new), `parity/scenarios/s6_long_calls.yml` (new), `test/parity/scenario_test.rb` (load pins). **Must not:** `lib/**`, `bin/**`, `parity/registry.yml` UNLESS a baseline run proves a path class fails to cover a sanctioned-path candidate (evidence in the report; the registry stays owner-ruled minimal), any other file.
- All lanes: no refactors beyond the task; no placeholders; search before implementing (`rg` the whole repo before adding any helper); builders never commit; report raw evidence to `build/I20-viewport-parity-<lane>/report.md` with a final `STATUS:` line.
- PHASE 0 (mandatory): re-read this spec against the repo; raise every disagreement with file:line evidence — in particular verify the Grounds' arithmetic (the dock row counts, the probe offsets, the mark sites) against the live pi source and the port's current code before planning. Silent compliance is a defect.

### Lane plan (disjoint, same repo)

```lanes
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/core/loop.rb
    - test/chat_test.rb
    - test/loop_test.rb
- name: rig
  repo: tart
  touch:
    - parity/scenarios/s5_bash_truncation.yml
    - parity/scenarios/s6_long_calls.yml
    - test/parity/scenario_test.rb
```

Disjoint by construction (render seam vs parity data + pins). A conflict at integration is a spec defect to kill-and-respec, never hand-resolved.

### Rig-lane scenario guidance

- **s5_bash_truncation:** one bash tool call whose output exceeds the model-facing tail cap (2000 lines — e.g. `seq 1 2100`), then a short final reply; 3 mock requests. Measures: the collapsed preview (last-5 + hint) over a 2000-line output, the `[Showing lines … Full output: <path>]` notice composing AFTER the collapsed block (I19's landing), the spill-file path (expect the `parity-run-path` class to cover it if the spill lands under the staging root — verify with the baseline), and the notice fg pair (`warning` vs `tool_output` — the parallel render lane is fixing it; on THIS lane's base it will appear as a candidate; record it verbatim, expected). Shell-neutral commands only.
- **s6_long_calls:** one bash tool call with a >120-char command (the `$ <command>` call row), one write tool call with a long (>100-char) staged path, then a short final reply; 3-4 mock requests. Measures the I18 no-wrap CUT (pi's Text wraps call rows to the viewport; the port renders them un-wrapped). Long paths must stay under the staged sandbox so the path classes cover them.
- Both: author with the house comment header (why/what measured), pin loads in `test/parity/scenario_test.rb` per the existing s1-s4 pin pattern, baseline each live (record exit code + classes + candidates verbatim). EXPECTED baseline: exit 1 on both (they measure unported classes). Do NOT pin new registry classes for render defects — candidates are the work list; only path-shaped noise may be pinned, with evidence.

### Effort call

- **render: high** — two viewport mechanisms against a live rig, port-mechanics judgment (the timer shape), overlay-vs-carve row surgery, and byte-exact window geometry; tightly bounded file set.
- **rig: medium** — two scenario files + pins + two baseline runs, following the s2-s4 authoring pattern.

## Acceptance Criteria

Calibration: AC1 is the **deliverable-number criterion** (the exit code is the point — exact, and unlike I19 the exit-0 mechanism is evidence-backed by the Grounds' probe + source arithmetic); AC2 and AC6 assert **properties** (bounded from the defect side — the exact mechanism shape stays port freedom per BRIEF §5.1, itemized); AC3's guards are GREEN on base by design (chat.rb is the landed I17–I19 surface); AC4's deliverable is the **baseline record itself** (exit 1 on base is the expected, correct outcome — the candidate lists are the point); the tripwires are presence-greps (keyword-landed; substance is architect-read from the render evidence).

- **AC1 (s4 settled-screen parity — BRIEF §8, the I19/I20 slice).** `bin/pty-tester run parity/scenarios/s4_bash_variants.yml` exits **0**: the settled windows byte-identical — offset 2 both sides (top mark scrolled off, hints-line first, ends at the final reply), the widgets-above spacer row below the transcript both sides, NO rail glyphs at settle, no carved trailing padding (tart's rows end at content like pi's). `parity/registry.yml` gains no new classes. The probe scenario (the Grounds' 25-paragraph overflow-by-one) also exits 0 when re-run against the lane's tree.
- **AC2 (viewport parity — BRIEF §8, property).** The transcript's row budget matches pi's dock accounting: the widgets-above default spacer row renders between the transcript and the editor (a blank dock row), and the transcript viewport budget drops correspondingly (pi's arithmetic: dock = spacer 1 + editor + footer). The auto scrollbar is **transient** per pi's scroll-view.ts: it paints only while scroll activity is fresh — marked on the port's user-scroll seams (the analogs of pi's scrollTo/scrollBy/scrollToStart/scrollToEnd; NOT on the render-time follow-end adjustment), auto-hidden after the pi hide delay (default 1000 ms), force-hidden when content fits, with a redraw at hide and no busy redraw storm at idle; the rail renders as an OVERLAY on the last column while visible (full-width content wrap for `"auto"` — the permanent carved column is retired), thumb `█` while active / `┃` at rest ported-or-itemized per what drives pi's `setScrollbarActive`. The transient state, its marker, and the hide-delay constant carry pi's names (pi-source anchor comments, the I16-I19 idiom). Named tests in `test/chat_test.rb` pin: the budget arithmetic + spacer row; the settled-window geometry on the probe shape (overflow-by-one → offset 2, top mark off-window); rail hidden at settle/fit, visible on user scroll, hidden after the delay (no real-second sleeps in tests); the overlay row shape (no carved trailing pad on non-rail rows); the mark sites (user scroll marks, follow-end does not).
- **AC3 (s1/s2/s3 regression — BRIEF §8).** All three still exit 0 — the spacer row and budget change shift nothing that fits the viewport (short transcripts: the dock spacer is a blank row where viewport padding was blank), the overlay retirement changes no fitting row (the carve only applied on overflow), s2's echo/s3's write-read shapes untouched.
- **AC4 (rig scenarios — the next measured work list).** `parity/scenarios/s5_bash_truncation.yml` and `parity/scenarios/s6_long_calls.yml` exist, load (pinned in `test/parity/scenario_test.rb` per the s1-s4 pattern), and each baselines live: both apps complete the expected requests and settle, exit **1**, classes + candidates recorded verbatim in the report (expected classes: the truncation-notice fg pair on base, spill/long-path noise if the path classes don't cover it). No registry pin without a baseline-proven path-class gap, evidenced in the report.
- **AC5 (suite, bench — standing).** `bundle exec rake` green (0 failures, 0 errors) including the new tests; `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.
- **AC6 (truncation notice fg — the I19 carry-forward).** The truncation notice rows render pi's `warning` fg (bash.ts:88) instead of the inherited `tool_output`, unit-pinned beside the I19 notice-composition test; live measurement rides the judging session's s5 run on the integrated tree (NOT a frozen gate — s5's exit 0 belongs to a later freeze once its baseline is read).

```gates
- id: suite
  ac: AC2, AC5
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

- id: s4-parity
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s1-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: transient-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q "mark_scrollbar_activity" lib/tart/render/chat.rb && echo TRANSIENT_OK
  expect:
    exit_code: 0
    stdout_match: TRANSIENT_OK

- id: spacer-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -qiE "spacer.?when.?empty|widgets?-above" lib/tart/render/chat.rb && echo SPACER_OK
  expect:
    exit_code: 0
    stdout_match: SPACER_OK

- id: notice-fg-tripwire
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q "bash.ts:88" lib/tart/render/chat.rb && echo NOTICE_FG_OK
  expect:
    exit_code: 0
    stdout_match: NOTICE_FG_OK

- id: scenarios-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -f parity/scenarios/s5_bash_truncation.yml && test -f parity/scenarios/s6_long_calls.yml && echo SCENARIOS_OK
  expect:
    exit_code: 0
    stdout_match: SCENARIOS_OK
```

## Builder Prompt

### render

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT use run_in_background
(or shell `&`) for your own work — run long commands serially in the foreground
with explicit timeouts instead. When done, write your report to the scratch
file given below (an absolute path OUTSIDE your worktree), with RAW results
only — tables, numbers, command output — no interpretation. Every status claim
must be backed by a command result from this run. Keep the report compact.
Do not title the report; keep any headings at `###` or deeper. End with exactly
one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) |
BLOCKED (exact blocker + what you tried). Verdicts belong to the architect and
the human.

=== LANE: render (I20 viewport-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I20-viewport-parity-render/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, the s4 slice's two surviving viewport classes.
The I19 verdict attributed them to "a trailing row after the final reply" and
a "top-anchored view" — BOTH DISPROVEN by the architect's spec-time forensics
(this iteration's Grounds): a 25-tight-paragraph probe reply (overflow by
exactly one row) proves the transcript BUFFERS are byte-identical 36 rows; the
real defects are:

(A) THE TRANSCRIPT VIEWPORT BUDGET. pi's fullscreen layout is a VStack
[transcript ScrollView, dock] (pi chat-viewport.ts:22-45); the dock's natural
height = pending(0) + status(0) + widgetsAbove(1) + editor(3) + widgetsBelow(0)
+ footer(2) = 6 rows, because renderWidgets() initializes the widgets-above
container with a DEFAULT Spacer(1) when no extension widgets exist (pi
interactive-mode.ts:966-968, renderWidgetContainer(…, spacerWhenEmpty: true,
…)). So pi's transcript viewport = 34 rows; the blank row below pi's settled
transcript is that dock spacer, not scroll content. The port's budget
(transcript_area_rows, chat.rb ≈:1601) models a 5-row dock → viewport 35, one
row too many: tart's settled window shows one more buffer row than pi's (the
top mark pi scrolled off) and its transcript bottom row is content where pi's
is the spacer.

FIX: port the dock accounting — a blank spacer row renders between the
transcript and the editor, and the transcript budget drops by one. The port
has no extension widgets/pending/status containers (itemized cuts, as ever):
the fixed analog is transcript + spacer(1) + editor + footer.

(B) THE AUTO SCROLLBAR'S TRIGGER. pi's "auto" rail is TRANSIENT
(scroll-view.ts): isScrollbarVisible (:74-78) requires transientScrollbarVisible,
which only markScrollbarActivity (:97-110) sets — called from the real scroll
moves (scrollTo :144, scrollBy :159, scrollToStart :172, scrollToEnd :184,
setScrollbarActive :123) and NOT from updateLayout's follow-end adjustment
(:180-192) — and auto-hides after scrollbarHideDelayMs (default 1000, :55) via
a timer that clears the flag and re-renders (:113-118); force-hides when
content fits (:200). paintScrollbar paints only when isScrollbarVisible
(pi layout.ts:280-294; includeHiddenAuto is for geometry queries, not
painting). A settled screen NEVER shows the rail, even on overflow (pi
overflows 36>34 on s4 and shows none).

The port paints the rail persistently on ANY overflow (chat.rb
transcript_widget/scrollbar_glyphs ≈:1902-1940 — its comment "hidden when the
view fits" mis-states pi's settled semantics).

FIX, two parts:
(B1) TRANSIENT SEMANTICS: the rail paints only while scroll activity is fresh
— marked on the port's user-scroll seams (the analogs of pi's
scrollTo/scrollBy/scrollToStart/scrollToEnd: the wheel/key scroll paths,
scroll_by/scroll_page), NOT on the render-time follow-end adjustment;
auto-hidden after the pi hide delay (1000 ms), force-hidden when content
fits, with a redraw at hide and no busy redraw storm at idle. TWO legal port
shapes (your call, itemize the choice): (i) a one-shot reactor timer
(@kernel.async/every — reactor context) that clears the flag and wakes a
redraw; (ii) an activity timestamp + a re-armed @kernel.animate window, the
render checking elapsed >= delay to clear the flag. NO real-second sleeps in
tests — inject a short delay or control the clock; read how existing tests
control time.
(B2) OVERLAY, NOT CARVED COLUMN: today the port renders the rail as a
DEDICATED 1-cell column whenever content overflows, so EVERY row pads to full
width with trailing spaces even when the glyphs never show; pi's content
wraps to the FULL width for "auto" (getContentWidth, scroll-view.ts:80-82:
only "always" reserves a column) and the rail PAINTS OVER the last column
only while visible (pi layout.ts:307-330 replaceScrollbarCell). On s4 this
alone fails every row. Retire the permanent carve: content at full width; the
rail overlays the last column while visible (padded to the column, then the
glyph). The scrollbar GEOMETRY helper (tui.rb scrollbar_lines) is already
pi-exact — do not touch it; the defect is the trigger and the layout, not the
geometry. Also: pi styles the thumb `█` while the scrollbar is "active"
(setScrollbarActive, layout.ts:317-319) — rg what drives setScrollbarActive
in pi, port the reachable subset, itemize any cut.

(C) THE TRUNCATION NOTICE FG (the I19 carry-forward, small): the
model-facing truncation notice rows render pi's warning fg (pi renderers/
bash.ts:88) instead of the inherited tool_output — split_truncation_notice's
notice rows (I19, chat.rb). One span change + a unit test beside the I19
notice-composition test. Live measurement of this rides a parallel rig lane's
s5 baseline (on YOUR tree it is unmeasured — the unit test is the pin).

With (A) and (B) both landed, tart's settled s4 window is byte-identical to
pi's (offset 2, hints-line first, ends at the reply, spacer row below, no
rail, no carved padding) — the architect's probe arithmetic (Grounds) backs
the exit-0 mechanism, unlike I19's. If a class STILL survives after both
fixes, it is a REAL defect of its own — record it verbatim; do not chase it
outside your touch set.

=== EXPECTED STATE (read twice) ===

Your worktree provisions off the merged base where I19 landed (the collapse,
the write/read renderers, the duration seam). The s4 baseline on your base is
exit 1 with two classes (the architect's cold run: tmp/parity-gate-s4/ in the
main checkout — READ ONLY). The probe (25 tight paragraphs "probe p01".."probe
p25", prompt "hello", 1 request, env TART_MODEL_PROVIDER=mock — source:
tmp/probe_reply25.yml in the main checkout, READ ONLY) exits 1 on your base
(pi offset 2 / tart offset 1) and MUST exit 0 after your fixes — it is your
mid-flight sanity instrument (recreate it in your OWN scratch dir; the
pty-tester takes any scenario path). s1/s2/s3 must stay exit 0.

=== OUTPUT FORMAT ===

- The named test list (budget arithmetic + spacer row; settled-window
  geometry on the probe shape; rail hidden at settle/fit, visible on user
  scroll, hidden after the delay; the overlay row shape incl. no carved
  trailing pad on non-rail rows; mark sites; notice fg) with the per-row
  assertions they pin, and the timer shape you chose (itemized).
- The probe re-run: command + exit code + both captures' first/last content
  rows + the geometry (offsets).
- The s4 + s1 + s2 + s3 runs: commands + exit codes (+ classes/candidates for
  any non-zero exit, verbatim).
- Any legitimate test updates, itemized.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (your tests live
  in test/chat_test.rb — extend it; keep tests terse, public-behavior only,
  no mock/stub of the class under test).
- Live rig: `bin/pty-tester run parity/scenarios/<s>.yml --out <scratch-dir>`
  (exit 0 = parity). Control baselines (READ ONLY):
  /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-gate-s4/
  (I19 cold: exit 1, two classes) and
  /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/probe-reply25d/
  (the probe: exit 1, pi offset 2 / tart offset 1).
- pi oracle (read-only): /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  packages/coding-agent/src/modes/interactive/chat-viewport.ts:22-45 (the
  VStack + dock);
  packages/coding-agent/src/modes/interactive/interactive-mode.ts:966-968,2502-2517
  (renderWidgets/renderWidgetContainer spacerWhenEmpty);
  packages/tui/src/components/scroll-view.ts IN FULL (options :46-55,
  isScrollbarVisible :74-78, getContentWidth :80-82, markScrollbarActivity/
  hideTransientScrollbar :97-118, setScrollbarActive :119-123, the mark sites
  :131-192, force-hide :200, render :215-220);
  packages/tui/src/layout.ts:280-330 (getScrollbarGeometry includeHiddenAuto,
  paintScrollbar, replaceScrollbarCell, thumb active style :317-319);
  packages/coding-agent/src/core/tools/renderers/bash.ts:88 (notice warning fg).
- Existing machinery to build on: read lib/tart/render/chat.rb IN FULL —
  transcript_area_rows (≈:1601), build_widget/transcript_widget
  (≈:1890-1940), the scroll-state section (scroll_page/scroll_by ≈:1592-1612),
  split_truncation_notice (I19), Chat#initialize's @kernel (the Core::Loop);
  lib/tart/core/loop.rb — animate(duration:)/async/every + the dirty-gated
  draw_frame (the timer/wake seams). lib/tart/tui.rb scrollbar_lines is
  pi-exact geometry — do not touch it.

=== BOUNDARIES ===

MAY touch: `lib/tart/render/chat.rb`, `lib/tart/core/loop.rb` (ONLY a minimal
timer/wake seam if shape (i) needs one — prefer no-change shapes first),
`test/chat_test.rb`, `test/loop_test.rb` (only if loop.rb is touched).
MUST NOT touch: `lib/tart/tui.rb`, `lib/tart/tools/**`, `lib/tart/agent/**`,
`bin/tart`, `parity/**`, `tart.gemspec`/`Gemfile*`, any other test file,
`test/support/**`. No refactors beyond the task; no placeholders; `rg`
before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC1 (s4 settled-screen parity — BRIEF §8, the I19/I20 slice). `bin/pty-tester
run parity/scenarios/s4_bash_variants.yml` exits **0**: the settled windows
byte-identical — offset 2 both sides (top mark scrolled off, hints-line
first, ends at the final reply), the widgets-above spacer row below the
transcript both sides, NO rail glyphs at settle, no carved trailing padding
(tart's rows end at content like pi's). `parity/registry.yml` gains no new
classes. The probe scenario (the Grounds' 25-paragraph overflow-by-one) also
exits 0 when re-run against the lane's tree.

AC2 (viewport parity — BRIEF §8, property). The transcript's row budget
matches pi's dock accounting: the widgets-above default spacer row renders
between the transcript and the editor (a blank dock row), and the transcript
viewport budget drops correspondingly (pi's arithmetic: dock = spacer 1 +
editor + footer). The auto scrollbar is transient per pi's scroll-view.ts:
it paints only while scroll activity is fresh — marked on the port's
user-scroll seams (the analogs of pi's scrollTo/scrollBy/scrollToStart/
scrollToEnd; NOT on the render-time follow-end adjustment), auto-hidden after
the pi hide delay (default 1000 ms), force-hidden when content fits, with a
redraw at hide and no busy redraw storm at idle; the rail renders as an
OVERLAY on the last column while visible (full-width content wrap for
"auto" — the permanent carved column is retired), thumb `█` while active /
`┃` at rest ported-or-itemized per what drives pi's setScrollbarActive. The
transient state, its marker, and the hide-delay constant carry pi's names
(pi-source anchor comments, the I16-I19 idiom). Named tests in
test/chat_test.rb pin: the budget arithmetic + spacer row; the
settled-window geometry on the probe shape (overflow-by-one → offset 2, top
mark off-window); rail hidden at settle/fit, visible on user scroll, hidden
after the delay (no real-second sleeps in tests); the overlay row shape (no
carved trailing pad on non-rail rows); the mark sites (user scroll marks,
follow-end does not).

AC3 (s1/s2/s3 regression — BRIEF §8). All three still exit 0 — the spacer
row and budget change shift nothing that fits the viewport (short
transcripts: the dock spacer is a blank row where viewport padding was
blank), the overlay retirement changes no fitting row (the carve only
applied on overflow), s2's echo/s3's write-read shapes untouched.

AC5 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors) including the new tests; `bench/seam_bench.rb` prints
`SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

AC6 (truncation notice fg — the I19 carry-forward). The truncation notice
rows render pi's `warning` fg (bash.ts:88) instead of the inherited
`tool_output`, unit-pinned beside the I19 notice-composition test.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out <scratch-dir>
      # expected AFTER your fixes: exit 0
    bin/pty-tester run parity/scenarios/s1_text_turn.yml --out <scratch-dir>   # exit 0
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>   # exit 0
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out <scratch-dir>  # exit 0
    grep -q "mark_scrollbar_activity" lib/tart/render/chat.rb && echo TRANSIENT_OK
    grep -qiE "spacer.?when.?empty|widgets?-above" lib/tart/render/chat.rb && echo SPACER_OK
    grep -q "bash.ts:88" lib/tart/render/chat.rb && echo NOTICE_FG_OK

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I20-viewport-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence viewport-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section viewport-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify viewport-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
