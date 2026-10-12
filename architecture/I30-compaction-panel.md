# I30: compaction-panel

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I30 compaction-panel

Measured this session (2026-10-12) at base **a622ee03** (= `project/pi-port` tip after
I28 + I29):

1. **Owner directive (this session).** Spec & dispatch as much as possible in
   parallel. chat.rb is the single-writer bottleneck (the panel handler, the rebuild,
   and every other queued render item all live there), so the maximum parallel split
   is ONE iteration cut at the agent/render seam: an agent-side lane (`loop.rb` +
   `session.rb` — the event payload + persistence + the I29 window-tier residual)
   parallel with a render-side lane (`chat.rb` + `transcript.rb` + the rig), joined by
   a frozen event-payload contract. Everything else queued (header startup-help flip,
   user-bash live streaming, editor undo, toolPendingBg, §7.7 e2e) is chat.rb-bound
   or depends on this landing — sequenced behind it.

2. **pi's panel (measured, compaction-summary-message.ts, full file read).**
   `CompactionSummaryMessageComponent extends Box(outputPad=1, padY=1, (t) =>
   theme.bg("customMessageBg", t))`. Collapsed: bold `customMessageLabel` `[compaction]`
   + `Spacer(1)` + `customMessageText` `` `Compacted from ${tokensBefore.toLocaleString()} tokens (` ``
   + `dim` keyText("app.tools.expand") + `` ` to expand)` `` — s7's settled capture shows
   the key renders as `ctrl+o`. Expanded: the label + `Markdown(`**Compacted from
   <N> tokens**\n\n` + summary)` with `customMessageText` color.
   `tokensBefore.toLocaleString()` = comma grouping (s8's pi capture: `Compacted from
   1,487 tokens`). Replay (`renderSessionEntries` case `compactionSummary`,
   interactive-mode :3903-3904, :4086 "Used for initial load and rebuild after
   compaction"): `Spacer(1)` + the panel with `setExpanded(this.toolOutputExpanded)`
   — the GLOBAL expand state. MouseRegion click-to-toggle is a standing cut (the
   port's mouse owns selection — the skill-panel precedent).

3. **pi's live rebuild (measured, interactive-mode :3686-3725 `compaction_end`).**
   On success: `chatContainer.clear()` → `renderSessionEntries(entries.slice(1))`
   (the kept post-compaction entries re-rendered at their chronological positions)
   → the panel appended LAST (`createCompactionSummaryMessage(result.summary,
   result.tokensBefore, now)`) → `footer.invalidate()` (recompute, NOT reset). The
   clear wipes the MOTD/[Context] header (s7's @@ -8 candidate: pi's settled screen
   has no `[Context]` after compaction). The `compaction_cost` usage notice
   (`addCompactionCostNotice` :4118-4130, warning-fg `Compaction: N tokens billed
   (~$X.XX)`) is gated on `showCacheMissNotices` — **default FALSE**
   (settings-defaults.ts:27) → does not render in the rig; CUT for this iteration,
   itemized (no settings seam in the port; the entry persists usage so a future seam
   can render it).

4. **pi persists usage on the entry (measured, session-manager.ts :85-101,
   :1265-1290).** `CompactionEntry` carries `usage?: Usage` ("Usage from the LLM
   call(s) that generated this summary") — appended by `appendCompactionEntry(…
   usage?, …)`. The port's `Recorder#append_compaction` (session.rb:383-398) persists
   summary/first_kept_entry_id/tokens_before/details — **usage missing** (the I29
   residual: `Preparation#usage` exists in memory, never persisted). pi does NOT
   persist estimatedTokensAfter (live computation only) — the port must not either.

5. **The port's state (measured at a622ee03).** The `:compaction` event (loop.rb:357)
   carries `reason/tokens_before/summary` — the rebuild needs the kept ENTRIES, which
   only the agent side holds → the payload extension is the lane contract. The
   surface's handler (chat.rb:413-427) enqueues a dim `✻ compacted (reason, N tokens)`
   line + a blank region — replaced wholesale by the rebuild + panel. Replay renders
   the compaction entry as BARE markdown (transcript.rb:395-402) — becomes the panel.
   The skill-panel family (transcript.rb:347-377) already builds the exact
   customMessageBg Box shape (bold label span, prose markdown over
   `custom_message_text`, bg on every span — the port's own precedent); the I25
   expandable/ctrl+o machinery and `@tool_output_expanded` global state exist.
   `clear_transcript` (the /new path) also resets footer usage — the rebuild must NOT
   (pi invalidates, never resets; s7's footer parity rides on it). replay_user feeds
   `@history_sink` (transcript.rb:407) — a live rebuild through `replay_entries`
   must not duplicate editor history (measure + handle).

6. **The switch window tier (measured; the I29-ruled residual).**
   `Settings.resolve_context_window` (settings.rb:115-127) chains explicit → env →
   `model.context_window` → `MODEL_CONTEXT_WINDOWS[model.id]`; `switch_model`
   (loop.rb:127) re-resolves only `context_window || @chat.model&.context_window` —
   the known-models tier is skipped, so switching to a known-models entry without a
   declared window disables the threshold instead of resolving the table's window.

7. **The measured targets.** s7's candidate list (this session's cold gate run at
   a622ee03): 9x unknown-candidate = the panel (2 lines) + the rebuild shift
   (blank/first-turn-reply/[Context]/hello-compact lines) + the ✻ line; 3x
   parity-run-path + 2x footer-provider-prefix already sanctioned. s8 (I29's
   zero-usage scenario) shares the panel divergence + one style_unknown candidate
   (an empty dim-fg `"  "` spacer row on tart's side of the settled compaction
   screen — raw evidence, likely the ✻ line's blank region; expected to vanish with
   the rebuild). **Target: s7 AND s8 exit 0 cold.**

8. **Control (this session, base a622ee03).** Suite 553 runs / 2134 assertions / 0
   failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0 cold; s7 + s8 exit 1
   by design (this iteration's targets). All regression claims below are against
   this baseline.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section compaction-panel specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision compaction-panel`
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
`architect rehearse compaction-panel` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze compaction-panel` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse compaction-panel` — before the freeze, while
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
subsection per lane. A copy is written to build/I30-compaction-panel-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section compaction-panel prompt --append --lane <lane> --from build/I30-compaction-panel-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I30-compaction-panel-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence compaction-panel --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction-panel verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction-panel`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
