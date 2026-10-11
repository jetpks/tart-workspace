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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section viewport-parity specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision viewport-parity`
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
`architect rehearse viewport-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze viewport-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse viewport-parity` — before the freeze, while
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
subsection per lane. A copy is written to build/I20-viewport-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section viewport-parity prompt --append --lane <lane> --from build/I20-viewport-parity-<lane>/prompt.md`. -->

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
