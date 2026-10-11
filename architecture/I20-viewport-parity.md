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

### rig

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

=== LANE: rig (I20 viewport-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I20-viewport-parity-rig/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program: the parity rig's next two measured slices, as
scenarios + baselines — the instrument's work list for the NEXT iteration.
No exit-0 is frozen for them (their baselines are the deliverable); a
parallel render lane is fixing the s4 viewport defects in
lib/tart/render/chat.rb + test files in its own worktree — stay out of
lib/** and test/chat_test.rb entirely.

Author two scenarios (the s2-s4 authoring pattern — house comment header
naming what each scenario measures, shell-neutral commands, fixed mock
replies):

1. **s5_bash_truncation** — one bash tool call whose output exceeds the
   model-facing tail cap (2000 lines — e.g. `seq 1 2100`), then a short final
   reply; 3 mock requests. Measures: the collapsed preview (last-5 + the
   earlier-lines hint) over a 2000-line output; the truncation notice
   (`[Showing lines … of N. Full output: <path>]`) composing AFTER the
   collapsed block (I19's landing); the spill-file path (expect the
   `parity-run-path` class (`run-\d+/`) to cover it if the spill lands under
   the per-run staging root — VERIFY with the baseline run, do not assume);
   and the notice fg pair (pi renders the notice `warning` fg, the port's is
   `tool_output` — the parallel render lane is fixing it; on YOUR base it
   WILL appear as a candidate; record it verbatim, expected).

2. **s6_long_calls** — one bash tool call with a >120-char command (the
   `$ <command>` call row), one write tool call with a long (>100-char)
   staged path, then a short final reply; 3-4 mock requests. Measures the
   I18 no-wrap CUT: pi's Text wraps call rows to the viewport; the port
   renders them un-wrapped (clipped). Long paths must stay under the staged
   sandbox so the path classes cover them. The write's content: short
   (the write renderer's preview is I18-landed; only the CALL row's wrap is
   the target).

Pin both scenarios' loads in `test/parity/scenario_test.rb` per the existing
s1-s4 pin pattern (name, prompt, expected_requests, responses, env), then
baseline each live: both apps complete the expected requests and settle; the
EXPECTED outcome is **exit 1** with the candidate lists recorded verbatim —
the candidates ARE the deliverable. Do NOT pin new registry classes for render
defects (candidates are the work list; the registry stays owner-ruled minimal);
pin a class ONLY if a baseline proves a path-shaped candidate the existing
classes fail to cover, with the evidence in the report.

=== EXPECTED STATE (read twice) ===

Your worktree provisions off the merged base where I19 landed (the bash
preview collapse; s4 exits 1 on base with two viewport classes — the render
lane's work, not yours). Your baselines run against THAT base: s5's candidate
list should show the truncation-shape candidates (notice fg pair + any
path/padding noise); s6's should show the call-row wrap candidates. If a
baseline instead shows rig failure (exit 2) or app boot failure — that is a
BLOCKER to record, not a scenario defect to chase.

=== OUTPUT FORMAT ===

- The two scenario files, verbatim.
- The load-pin tests (names + the assertions they pin).
- Each baseline run: command + exit code + classes + candidates verbatim.
- Any registry decision, evidenced (or "registry untouched" + why).
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (minitest).
- Live rig: `bin/pty-tester run parity/scenarios/<s>.yml --out <scratch-dir>`
  (tmux + pi on PATH, present; exit 0 = parity, 1 = unknown candidates,
  2 = rig failure).
- Read `parity/scenarios/s2_tool_turn.yml`, `s3_tool_turn_files.yml`,
  `s4_bash_variants.yml` IN FULL (the authoring pattern, the env staging) and
  `test/parity/scenario_test.rb` IN FULL (the pin pattern) before writing.
- The mock's tool_calls scripting shape: id/name/arguments (s4's `seq 1 12`
  is the worked example for bash). For the WRITE tool call, s3 has the worked
  example (path/content arguments).
- The truncation seam (for the comment headers, read-only context):
  the port's tail cap + notice live in `lib/tart/tools/bash.rb` (≈:216-237);
  pi's in `packages/coding-agent/src/core/tools/bash.ts` + the renderers
  (`renderers/bash.ts:88` — the notice's warning fg). Do NOT touch those
  files — they are context for the scenario comments only.

=== BOUNDARIES ===

MAY touch: `parity/scenarios/s5_bash_truncation.yml` (new),
`parity/scenarios/s6_long_calls.yml` (new), `test/parity/scenario_test.rb`
(load pins). MUST NOT touch: `lib/**`, `bin/**`, any other scenario file,
`parity/registry.yml` (unless a baseline proves a path-class gap — evidence
required), `test/chat_test.rb` (the render lane's), any other test file,
`test/support/**`, `tart.gemspec`/`Gemfile*`. No refactors beyond the
authoring; no placeholders; `rg` before writing (check every pin pattern).

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC4 (rig scenarios — the next measured work list). `parity/scenarios/
s5_bash_truncation.yml` and `parity/scenarios/s6_long_calls.yml` exist, load
(pinned in `test/parity/scenario_test.rb` per the s1-s4 pattern), and each
baselines live: both apps complete the expected requests and settle, exit
**1**, classes + candidates recorded verbatim in the report (expected
classes: the truncation-notice fg pair on base, spill/long-path noise if the
path classes don't cover it). No registry pin without a baseline-proven
path-class gap, evidenced in the report.

AC5 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors); `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime
dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    test -f parity/scenarios/s5_bash_truncation.yml && \
      test -f parity/scenarios/s6_long_calls.yml && echo SCENARIOS_OK
    bin/pty-tester run parity/scenarios/s5_bash_truncation.yml --out <scratch-dir>
      # EXPECTED on your base: exit 1 (the baseline — candidates recorded)
    bin/pty-tester run parity/scenarios/s6_long_calls.yml --out <scratch-dir>
      # EXPECTED on your base: exit 1 (the baseline — candidates recorded)

## Builder Report

### render

LANE: render (I20 viewport-parity) — files touched: `lib/tart/render/chat.rb`, `lib/tart/core/loop.rb` (one seam), `test/chat_test.rb`, `test/loop_test.rb`. No commits, no git writes. `lib/tart/tui.rb` untouched (`scrollbar_lines` intact).

### PHASE 0 — disagreements/deviations (numbered; full detail in session transcript)

1. **loop.rb seam required**: shape (i)'s "wakes a redraw" had no API — `animate(duration: 0)` draws nothing (`draw_frame` gates on `@dirty || animating?`; `animating?` is `now < now`; loop.rb `when WAKE then nil`), and overloading WAKE-as-dirty broke `test_bare_pointer_motion_does_not_redraw` (the poller pushes plain `:wake` for synthetic draining — poller.rb:53). Shipped seam: new public `Core::Loop#request_draw` (`@dirty = true; signal(WAKE)`) — one method, no behavior change for existing callers.
2. **`█` active thumb is unreachable in the port**: `rg setScrollbarActive` in pi shows the only driver is mouse hover on the rail column (`tui-alt-screen.ts:1057-1065 setScrollbarHover`). No hover seam exists; cut itemized in `overlay_rail_cell`'s comment. At-rest `┃` + theme routing (the reachable subset) already ported.
3. **`content_point` gutter exclusion removed** (beyond the spec's letter): chat.rb's selection x-clamp excluded the carved column while overflowing; with the carve retired the gutter doesn't exist (pi clamps to the scrollview box, full width for "auto" — scroll-view.ts:80-82).
4. **Pre-existing test contradicted AC2**: `test_scrollbar_renders_only_when_content_overflows` pinned persistent-on-overflow rail; rewritten into the transient named tests below.
5. **Citation**: the warning fg call is bash.ts:99 (line 88 is a `warnings.push`); comment anchored `bash.ts:88-99` so the gate passes and the citation is accurate.
6. **Interface additions (declared)**: `Chat#scrollbar_hide_delay_ms=` writer (test injects 10_000 for "fresh" legs, 0 for hide legs — no real-second sleeps); `IdleKernel` grows an async-timer recorder (`async` records, `fire_timers` fires) and a nil `request_draw`.

### Design shipped (itemized)

- **(A) budget**: `DOCK_SPACER_ROWS = 1`; `dock_spacer_rows(height)` = `min(max(height − editor − footer − 1, 0), 1)` — pi widgetsAbove `shrink:1, minSize:0` (chat-viewport.ts:29): one blank dock row normally, the row that YIELDS on cramped screens (keeps `test_list_windows…`'s 12-row geometry intact — pi's shrink semantics); `transcript_area_rows` = residual after spacer+editor+footer; `build_widget` renders a blank spacer row between transcript and editor (picker path included).
- **(B1) shape (i) chosen**: `mark_scrollbar_activity` (pi scroll-view.ts:97-110 name) sets `@scrollbar_activity_at` + bumps `@scrollbar_timer_epoch` (stale-timer retirement = pi's clearTimeout) and arms a one-shot `@kernel.async { sleep(delay); …; @kernel.request_draw }`. `SCROLLBAR_HIDE_DELAY_MS = 1000` (pi :55 name). Mark site: `scroll_by` ONLY when the offset moved (pi `moved !== 0`), with pi's `start = followingEnd ? maxScrollTop : scrollTop` rule added so wheel-down-while-following clamps to a no-op (no spurious mark). The render-time follow-end adjustment never marks; force-hide (`@scrollbar_activity_at = nil`) when content fits (pi updateLayout :200). No pi scrollTo/scrollToStart/scrollToEnd analogs exist in the port's key surface — nothing else to mark.
- **(B2) overlay**: the carved horizontal layout is retired; `transcript_widget` always renders one full-width paragraph; while visible, each row is recomposed content-clipped at width−1 + plain-space pad + the glyph span grafted from `scrollbar_glyphs`' own output (theme fg preserved) — `replaceScrollbarCell` semantics.
- **(C)**: notice rows `fg: Theme[:warning]` (bash.ts:88-99).

### Named tests (test/chat_test.rb, all green)

- `test_dock_spacer_row_renders_between_transcript_and_editor` — 8 display rows / viewport 6 at h12: offset 2; buffer[5]=" p3" (budget ends at row 5); buffer[6] blank (the spacer); buffer[7][0]="─".
- `test_settled_window_overflow_by_one_scrolls_the_top_mark_off` — probe shape at h13 (viewport 7, 8 rows): offset 1; first visible row " probe p01", last " probe p04" (top row off-window).
- `test_scrollbar_is_hidden_at_settle_and_when_content_fits` — fit and overflow×20: every transcript last-column cell is blank at settle.
- `test_scrollbar_shows_while_fresh_and_hides_after_the_delay` — page_up → thumb `┃` theme-fg at (19,4) (offset 28/34 → thumb rows 3-4), track `│` above/below; after `fire_timers` (delay 0) + redraw → blank.
- `test_user_scroll_marks_scrollbar_activity_follow_end_does_not` — new output while following: hidden (updateLayout never marks); page_up: marks; wheel: marks; clamped scroll_down while following: no mark (pi `moved === 0`).
- `test_scrollbar_overlays_the_last_column_without_a_carved_gutter` — settled widget rows end at content (" line19" exact, no 20-char pad); while visible rows[0] ends `│` and rows[1] keeps " line14" under the overlay.
- `test_bash_truncation_notice_renders_the_warning_fg` — cell fg of the "[Showing lines … Full output: …]" row == `Theme[:warning]` (beside the I19 composition test).
- `test_request_draw_wakes_exactly_one_frame` (test/loop_test.rb) — `request_draw` = exactly one dirty frame, no animation window.

### Probe re-run (recreated at /tmp/i20-render/probe/probe_reply25.yml from the Grounds' probe_reply25.yml)

- Base (pre-fix): `bin/pty-tester run /tmp/i20-render/probe/probe_reply25.yml --out /tmp/i20-render/probe/base` → **exit 1** (70× unknown-candidate; tart first row "▀▀█ v1.1.0" = offset 1, persistent padded rail).
- After fixes: same command `--out /tmp/i20-render/probe/after` → **exit 0**. Captures (run-1, 40 rows each): first content row (row 1) both sides ` █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more` (offset 2); row 33 ` probe p24`; row 34 ` probe p25` (ends at the reply); row 35 blank (the widgets-above spacer); row 36 editor top border; row 38 footer pwd; row 40 `↑10 ↓5 0.0%/33k (auto)`. Geometry: offset 2 both sides, no rail glyphs, no carved padding.

### Gate scenario runs

- `bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out /tmp/i20-render/s4_bash_variants` → **exit 0**; per-class diff: `2x parity-run-path` (sandbox cwd line — sanctioned) only. tart row 1 = pi row 1 (hints line, offset 2), row 34 " The bash tools ran; fixed final reply for the spike.", row 35 blank — captures identical except the run-path line (verified by `diff`).
- `bin/pty-tester run parity/scenarios/s1_text_turn.yml --out /tmp/i20-render/s1_text_turn` → **exit 0**
- `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out /tmp/i20-render/s2_tool_turn` → **exit 0**
- `bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out /tmp/i20-render/s3_tool_turn_files` → **exit 0**
- `parity/registry.yml` untouched; gemspec runtime deps untouched.

### Suite / bench / gates

- `bundle install --quiet && bundle exec rake` → `391 runs, 1542 assertions, 0 failures, 0 errors, 1 skips` (the 1 skip is pre-existing), exit 0.
- `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`
- `grep -q "mark_scrollbar_activity" lib/tart/render/chat.rb && echo TRANSIENT_OK` → `TRANSIENT_OK`
- `grep -qiE "spacer.?when.?empty|widgets?-above" lib/tart/render/chat.rb && echo SPACER_OK` → `SPACER_OK`
- `grep -q "bash.ts:88" lib/tart/render/chat.rb && echo NOTICE_FG_OK` → `NOTICE_FG_OK`

### Legitimate test updates (itemized)

1. `test_scrollbar_renders_only_when_content_overflows` — deleted/rewritten: pinned the persistent-on-overflow rail AC2 retires (split into the four transient/overlay tests above).
2. `transcript_height` helper — `buffer.size − 5` → `− 6` (mirrors the new DOCK_SPACER_ROWS row).
3. `test_page_up_pans_the_transcript_and_the_tail_refollows` — offset 26 → 28 (page 6 off max 34); page-back content " line13" → " line14".
4. `test_a_scrolled_up_view_stays_put_as_new_output_arrives` — offset 26 → 28.
5. `test_fullscreen_composition_draws_transcript_editor_and_footer` — editor block bounds shifted by the spacer row (top+1..top+3); adds a spacer-row-blank assertion.
6. `with_chat` now yields `(chat, session, kernel)` — extra positional arg silently ignored by existing 2-arg blocks (proc semantics); needed to reach `IdleKernel` for `fire_timers`.
7. `IdleKernel` — `async` timer recorder + `fire_timers` + nil `request_draw` (test seam, see PHASE 0 #6).
8. `test/loop_test.rb` — added `test_request_draw_wakes_exactly_one_frame` (loop.rb was touched).

No s1/s2/s3 scenario or registry changes were needed; no classes survived on s4.
STATUS: COMPLETE

### rig

### PHASE 0 — disagreements / deviations (evidence cited)

1. **`parity-run-path` cannot cover the spill path — spec's hedge resolved.** The port spills to `File.join(Dir.tmpdir, "tart-bash-#{pid}-#{hex}.log")` (`lib/tart/tools/output_accumulator.rb:181`, prefix passed by `lib/tart/tools/bash.rb`); pi spills to `join(tmpdir(), "pi-bash-<hex>.log")` (`repos/pi/packages/coding-agent/src/utils/output-files.ts:12-14`, prefix `pi-bash` at `core/bash-executor.ts:66`). Neither lands under `run-<n>/`. Baseline confirmed: the s5 notice lines carry OS-tempdir paths and were unknown-candidates before the pin.
2. **Spec's "3 mock requests" for s5 is unattainable under the rig's scripting.** One response is consumed per mock request (`test/support/mock_llm_server.rb` script queue; s2: tool call + final = 2; s4: 2 tool calls + final = 3). One bash call + final = **2** requests; a third scripted response would require a second turn, and a turn with no tool call ends the run at request 2 → `completed=false` → exit 2, contradicting AC4's "complete the expected requests and settle". Deviation: s5 uses `expected_requests: 2` / 2 responses. s6 (bash + write + final) = 3 requests, within the spec's "3-4".
3. **"The notice fg pair WILL appear as a candidate" — the fg itself cannot.** Captures come from `tmux capture-pane -p` (`lib/tart/parity/runner.rb:184-188`), which strips SGR attributes. What surfaces instead is the notice **text** divergence (pi composes `[Full output: … . Truncated: showing N of M lines]`, `renderers/bash.ts:96-111`; the port renders the model-facing `[Showing lines …]` notice as-is, `chat.rb:1140-1142` + `bash.rb:218-231`). Recorded verbatim below.
4. **s6's "port renders call rows un-wrapped (clipped)" is true only for the write call row.** The port's bash `$ <command>` row wraps via `padded_fg_rows`/`Chat.wrap` (`chat.rb:1133`, `496-514`); only `write_call_rows` emits one unwrapped `TUI.line` (`chat.rb:1267-1270`). Baseline: the bash row wrapped identically in both apps (zero candidates from it); the write row produced the wrap-vs-clip candidate pair.
5. **First s6 draft (112-char path) was a null measurement — corrected.** pad(1) + `write`(5) + space(1) + path(112) = 119 ≤ the 120-col pane, so no wrap, no clip: baseline exit 0, zero candidates. Path lengthened to 160 chars (still sandbox-relative); the re-run produced the expected candidates. The spec's ">100 chars" threshold is too low to cross the pane.
6. **Suite count**: `386 runs, 1533 assertions, 0 failures, 0 errors, 1 skips` — the skip is the opt-in `PTY_TESTER_LIVE` live-run test, pre-existing.

### Scenario files

Delivered verbatim in the worktree:
- `parity/scenarios/s5_bash_truncation.yml` — `seq 1 2100` bash call (crosses the 2000-line tail cap, `lib/tart/tools/support/truncate.rb:11`) + fixed final reply; `expected_requests: 2`; env `TART_MODEL_PROVIDER=mock`.
- `parity/scenarios/s6_long_calls.yml` — 132-char shell-neutral bash command, write of a 160-char sandbox-relative path with short content, fixed final reply; `expected_requests: 3`; env `TART_MODEL_PROVIDER=mock`.

### Load pins (test/parity/scenario_test.rb, s3/s4 pattern)

- `test_loads_the_shipped_s5_bash_truncation_scenario` — pins name `s5_bash_truncation`, prompt `run the long seq`, expected_requests 2, responses.size 2, `bash` + `{command: "seq 1 2100"}` ("2100 lines crosses the 2000-line model-facing tail cap"), final-reply content, footer env seam.
- `test_loads_the_shipped_s6_long_calls_scenario` — pins name, prompt, expected_requests 3, responses.size 3, `bash` call with `command.length > 120` ("crosses the 120-col viewport"), `write` call with `path.length > 100` + content `parity s6 note`, final-reply content, footer env seam.

### Baselines (verbatim)

Command: `bin/pty-tester run parity/scenarios/s5_bash_truncation.yml --out /tmp/i20-s5-pinned` → **exit 1**

```
- pi: completed=true requests=2/2 boot_settle=1092ms reply_settle=1118ms
- tart: completed=true requests=2/2 boot_settle=1391ms reply_settle=1134ms
per-class: 2x truncation-spill-path, 2x unknown-candidate, 2x parity-run-path
```

```
@@ -22,2 +21,2 @@
- [Full output: /var/folders/zn/swxnrrxx1pj6gw65sd_kzm2m0000gp/T/pi-bash-cdcfa975415db71b.log. Truncated: showing 2000
- of 2100 lines]
+ [Showing lines 101-2100 of 2100. Full output:
+ /var/folders/zn/swxnrrxx1pj6gw65sd_kzm2m0000gp/T/tart-bash-75447-acc1f33c.log]
@@ -39,1 +38,1 @@
-/private/tmp/i20-s5-pinned/run-1/sandbox/pi
+/tmp/i20-s5-pinned/run-1/sandbox/tart
```

Attribution: the two path-bearing notice lines → `truncation-spill-path`; `of 2100 lines]` and `+ [Showing lines 101-2100 of 2100. Full output:` → unknown-candidate (the notice divergence, on the work list); the sandbox footer lines → `parity-run-path`.

Pre-pin s5 run (`--out /tmp/i20-s5-baseline`, exit 1, pi+tart completed 2/2): `4x unknown-candidate, 2x parity-run-path` — all four notice lines unknown-candidates, paths verbatim `pi-bash-6cab84d3ae44a958.log` / `tart-bash-74441-fd2c7a4d.log`.

Command: `bin/pty-tester run parity/scenarios/s6_long_calls.yml --out /tmp/i20-s6-pinned` → **exit 1**

```
- pi: completed=true requests=3/3 boot_settle=1119ms reply_settle=1127ms
- tart: completed=true requests=3/3 boot_settle=1381ms reply_settle=1137ms
per-class: 6x unknown-candidate, 2x parity-run-path
```

```
@@ -26,3 +25,1 @@
- write
- s6-long-path-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-p
- ad-pad-pad-pad-pad-pad-pad-pad-pad-pad.txt
+ write s6-long-path-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-pad-
@@ -33,0 +34,2 @@
+
+
@@ -39,1 +38,1 @@
-/private/tmp/i20-s6-pinned/run-1/sandbox/pi
+/tmp/i20-s6-pinned/run-1/sandbox/tart
```

pi wraps the write row to three visual lines (`write` / path row 1 / path row 2); the port clips one row at the 120-col pane. The two `+` blank lines are the hunk-alignment slack from the missing wrapped rows. The bash `$ <command>` row wrapped identically in both apps — no candidate from it (consistent with `chat.rb:1133` wrapping like pi).

Pre-correction s6 run (112-char path, `--out /tmp/i20-s6-baseline`): **exit 0**, `2x parity-run-path` only, both apps 3/3 — the null measurement from disagreement 5.

### Registry decision (evidenced pin)

Pinned one class in `parity/registry.yml`:

```yaml
  - name: truncation-spill-path
    pattern: '/(pi|tart)-bash-[0-9a-f-]+\.log'
```

Evidence: the s5 baseline proved a path-shaped candidate the existing classes fail to cover — both apps' spill files live in the OS temp dir with per-run random segments (port `output_accumulator.rb:181` `Dir.tmpdir`; pi `output-files.ts:12-14` `tmpdir()`), not under `run-<n>/`, so `parity-run-path` (`run-\d+/`) and `staged-sandbox-path` (`sandbox/(pi|tart)-run-\d+`) cannot match. Philosophy matches the seed classes: path noise, not a rendering difference. The name satisfies the seed guard (`test_seed_registry_contains_only_path_or_sandbox_classes`, registry_test.rb:31-37 — matches /path|sandbox/). Post-pin s5 re-run: the two path-bearing lines classify `truncation-spill-path`; the notice divergence still surfaces as 2 unknown-candidates. Suite stays green (386 runs, 0 failures).

### Gates (verbatim)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
SUITE_OK
  (386 runs, 1533 assertions, 0 failures, 0 errors, 1 skips)

$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK

$ test -f parity/scenarios/s5_bash_truncation.yml && test -f parity/scenarios/s6_long_calls.yml && echo SCENARIOS_OK
SCENARIOS_OK

$ bin/pty-tester run parity/scenarios/s5_bash_truncation.yml --out /tmp/i20-s5-pinned
  exit 1  (the baseline — candidates recorded above)

$ bin/pty-tester run parity/scenarios/s6_long_calls.yml --out /tmp/i20-s6-pinned
  exit 1  (the baseline — candidates recorded above)
```

Gemspec runtime dependency set unchanged (`git diff --stat tart.gemspec Gemfile Gemfile.lock` → empty). No commits made; `git log -1` = `206af8d Merge lane/I19-bash-preview-collapse-rig`. Working tree touches: `parity/scenarios/s5_bash_truncation.yml` (new), `parity/scenarios/s6_long_calls.yml` (new), `test/parity/scenario_test.rb`, `parity/registry.yml` (evidenced pin) — no other files.

STATUS: COMPLETE_WITH_CONCERNS (s5 pinned at expected_requests: 2, not the spec's 3 — the rig's one-response-per-request scripting makes 3 unattainable for a one-tool-call scenario without a rig failure; spill-path registry class pinned per the baseline-proven gap; the s5 fg pair is invisible to capture-pane, the notice text divergence is the observable; s6 required a >113-char path to cross the pane)

## Verdict

- **Disagreement rulings (render PHASE 0):**
  1. `loop.rb` seam `request_draw` — **ACCEPT**: shape (i)'s "wakes a redraw" had no API (`draw_frame` gates on `@dirty || animating?`; a bare WAKE draws nothing), and overloading WAKE-as-dirty broke `test_bare_pointer_motion_does_not_redraw`. The seam is minimal (one method), mirrors pi's `requestRenderCallback`, and `loop.rb` was explicitly conditionally in-bounds ("ONLY a minimal timer/wake seam if shape (i) needs one"); `test/loop_test.rb` touched only because loop.rb was, as specced. Diff read: clean, anchored, no behavior change for existing callers.
  2. `█` active thumb unreachable — **ACCEPT** the cut: rg in pi shows the only driver is mouse hover on the rail (`tui-alt-screen.ts:1057-1065 setScrollbarHover`); the port has no hover seam. Cut itemized in `overlay_rail_cell`'s comment per the spec's "port the reachable subset, itemize any cut". Logged to the backlog as the residual divergence (a hover seam would be its own slice).
  3. `content_point` gutter exclusion removed — **ACCEPT**: with the carved column retired there is no gutter to exclude; pi clamps to the scrollview box, full width for `"auto"` (scroll-view.ts:80-82 — verified against the live source this session). Beyond the spec's letter, required by B2's spirit; the change is two lines and correct.
  4. Pre-existing test `test_scrollbar_renders_only_when_content_overflows` rewritten — **ACCEPT**: the old test pinned the persistent-on-overflow rail, which is precisely the defect AC2 retires; rewriting (not weakening — the four transient/overlay tests are strictly stronger) is the correct handling, itemized.
  5. Warning-fg citation `bash.ts:88` → `bash.ts:88-99` — **ACCEPT**: verified against the live source this session — `:88` is a `warnings.push`, the `theme.fg("warning", …)` is at `:99`; the anchor cites the true range and the frozen tripwire (`grep -q "bash.ts:88"`) passes on the accurate prefix. The gate is a tripwire; the substance is the unit test.
  6. Test seams (`scrollbar_hide_delay_ms=` writer; `IdleKernel` async-recorder + `fire_timers` + nil `request_draw`; `with_chat` yields a third positional) — **ACCEPT**: exactly the spec's "inject a short delay or control the clock; no real-second sleeps" guidance; the third yield arg is silently ignored by existing 2-arg blocks (proc semantics), zero churn.

- **Disagreement rulings (rig PHASE 0):**
  1. `parity-run-path` cannot cover spill paths — **ACCEPT**: verified this session against `output_accumulator.rb:181` (`Dir.tmpdir`) and pi `output-files.ts:12-14` (`tmpdir()`) — both spill to the OS temp dir with random segments, outside `run-\d+/`. The evidenced `truncation-spill-path` pin is sanctioned by AC4's explicit conditional grant. **Spec defect recorded**: the prose grant ("registry.yml UNLESS evidenced") could not be expressed in the frozen machine ` ```lanes ` block, so `integrate` correctly refused and this session overrode via `--accept-bounds` with the verified evidence — the defect is the declaration asymmetry (conditional touch grants need either a pre-declared touch entry or the authoring knowing `--accept-bounds` is the documented path), carried to future spec authoring.
  2. s5 pinned at `expected_requests: 2`, not the spec's 3 — **ACCEPT**: the rig's one-response-per-request scripting makes 3 unattainable for a one-tool-call scenario without a rig failure (a no-tool-call turn ends the run → exit 2, contradicting AC4's settle requirement). The spec's "3 mock requests" was an authoring error with no control run — same defect class as I09's baseline recount. AC4's substance (complete, settle, baseline exit 1, candidates verbatim) is fully met at 2.
  3. The s5 fg pair is invisible to `capture-pane -p` (SGR stripped) — **ACCEPT**: the observable is the notice TEXT divergence, recorded verbatim. Consequence ruled into AC6's measurement: the fg is unit-pinned; the live check confirms the text divergence (the next work list), not the fg.
  4. "Port renders call rows un-wrapped" is true only for the write call row (bash `$ <command>` rows wrap via `padded_fg_rows`/`Chat.wrap`) — **ACCEPT**: the baseline proves it (the bash row wrapped identically, zero candidates); the spec's parenthetical was over-broad. s6's candidates are exactly the write-row pair.
  5. First s6 draft (112-char path) was a null measurement; path lengthened to 160 — **ACCEPT**: pad(1)+`write`(5)+space(1)+112 = 119 ≤ 120-col pane, no wrap, no clip; the null run (exit 0, zero candidates) is recorded as the control. The spec's ">100 chars" threshold was set below the crossing point — authoring error, corrected with evidence.
  6. Suite count 386 (rig tree) vs 391 (render tree) vs 393 (integrated) — consistent per-tree counts, no defect.

- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (bfb40c06): `architect verify` PASS on both lanes' frozen-region checks; `git diff bfb40c06 HEAD -- architecture/I20-viewport-parity.md` shows only the Builder Prompt/Report appends. Post-flight: no builder commits in either worktree (`git log project/pi-port..` empty both), scratch reports present, raw-results only, PHASE 0 raised on both lanes (12 items total, none silent). The one mechanical FAIL — rig in-bounds (registry.yml) — is the prose-conditional grant the lanes block can't express, ruled ACCEPT above with verified evidence; `integrate` refusal + `--accept-bounds` override recorded in the commit trail.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | Gate `s4-parity` exit **0** cold on the integrated tree (per-class diff: `2x parity-run-path` sanctioned only); probe scenario re-run cold on the integrated tree: **exit 0**, offset 2 both sides, row 35 blank spacer, no rail, no carved pad | §8 | **PASS** — registry gains exactly one class (the rig's evidenced `truncation-spill-path` path-noise pin, AC4-sanctioned); AC1's "no new classes" letter read against its intent (no class masks an s4 render divergence — s4's only diff lines are the sanctioned run-path pair), the conflict is authoring imprecision, not a lane defect |
| AC2 | Budget: `DOCK_SPACER_ROWS`/`dock_spacer_rows` (pi `shrink:1, minSize:0` semantics) + `transcript_area_rows` residual; transient rail: `mark_scrollbar_activity` (pi name, scroll-view.ts:97-110), mark on moved user scrolls only (`moved !== 0`, `followingEnd ? maxScrollTop` clamp), follow-end adjustment never marks, force-hide on fit, `SCROLLBAR_HIDE_DELAY_MS = 1000`, one-shot epoch-guarded timer + `request_draw` hide frame; overlay `overlay_rail_cell` (clip width−1, pad, graft glyph) retiring the carve; 8 named tests green. Pi sources spot-verified this session (interactive-mode.ts:966 default spacer, scroll-view.ts:74-78/:55, bash.ts:88-99) | §8, §5.1 | **PASS** |
| AC3 | Gates `s1/s2/s3-parity` all exit **0** cold on the integrated tree | §8 | **PASS** |
| AC4 | Both scenario files exist (house comment headers, shell-neutral), load pins green (`test_loads_the_shipped_s5_…`/`s6_…`, s3/s4 pattern), baselines exit **1** with classes + candidates verbatim (s5: spill-path + notice-text candidates; s6: write-row wrap pair); registry pin evidenced; integrated-tree re-runs by this session reproduce both baselines exactly (s5: {truncation-spill-path 2, unknown-candidate 2, parity-run-path 2}; s6: {unknown-candidate 6, parity-run-path 2}) | §8 | **PASS** |
| AC5 | Gate `suite` exit 0: 393 runs, 1563 assertions, 0 failures, 0 errors, 1 pre-existing skip; `SEAM_BENCH_OK`; gemspec runtime deps unchanged (verified on both trees) | §3 | **PASS** |
| AC6 | Unit-pinned: `test_bash_truncation_notice_renders_the_warning_fg` (cell fg == `Theme[:warning]`, beside the I19 composition test); anchor cites the verified `bash.ts:88-99` range; live s5 ride: capture-pane strips SGR (rig PHASE-0 #3, ACCEPT) — the live run surfaces the notice-TEXT divergence as the next work list, the fg itself invisible by instrument, unit-pinned as AC6 pre-stated | §8 | **PASS** |

- **Iteration — CONTINUE.** The I19/I20 slice is closed: s4 settled-screen parity proven cold on the integrated tree (byte-identical windows modulo the sanctioned run-path pair), the two viewport defects fixed at mechanism (dock spacer budget + transient overlay rail) with pi-source anchors verified independently, and the instrument's next two measured work lists (s5 notice-text composition, s6 write call-row wrap) are baselined with verbatim candidates — the exact-parity program (BRIEF §8) now holds s1–s4 green end to end. Carry-outs: the write-row wrap (chat.rb `write_call_rows`) and the pi notice composition (bash.ts:96-111 single bracketed `warnings.join(". ")` line vs the port's two-line `[Showing lines …]` shape) are the next iteration's frozen targets; the rail-hover `█` thumb stays a logged cut (no hover seam). Spec-authoring carry: conditional touch grants can't live in the ` ```lanes ` block — either pre-declare the file in the touch set (evidence still demanded in prose) or accept `integrate --accept-bounds` as the documented path, and say so in the Specification.
