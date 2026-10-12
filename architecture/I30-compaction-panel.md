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

# Specification — I30 compaction-panel

- **Objective.** Port pi's compaction render to close the s7/s8 settled-screen
  divergence (BRIEF §8 full settled-screen parity — the owner's done bar): pi renders
  compaction as a customMessageBg `[compaction]` panel AND rebuilds the whole
  transcript from the post-compaction kept entries on the live path; the port renders
  a dim `✻ compacted` line over an un-wiped scrollback (Grounds 2-3, 5, 7). Deliver:
  (a) the panel component (collapsed + expanded, riding the existing skill-panel
  family + the ctrl+o global expand state); (b) the live rebuild (clear + re-render
  kept entries + panel last); (c) the replay panel (compaction entries render as the
  panel on resume); (d) the agent-side seams the render needs — the `:compaction`
  event's `entries:` payload and the recorder's `usage` persistence (pi
  CompactionEntry parity) — plus the I29-ruled switch window tier. Why now: s7/s8 are
  the only red rigs left, their candidate lists ARE this spec (Grounds 7), and every
  other queued render item is sequenced behind the chat.rb single-writer lane this
  iteration owns.

- **THE FROZEN CONTRACT (both lanes build against this; PHASE 0 is the place to
  dispute it, never to silently drift it).** The `:compaction` event payload becomes
  exactly: `emit(type: :compaction, reason:, tokens_before:, summary:, entries:)`
  where `entries` is an Array of replay-entry Hashes — the SAME shape
  `Agent::Session.load_entries` / `Transcript#replay_entries` consume (message
  entries with `type`/`message` keys, bashExecution entries, etc.) — holding the
  post-compaction KEPT context entries in chronological order (the entries after the
  cut point, i.e. from `first_kept_entry_id` onward; NOT the system messages, NOT
  the summary message — pi's `renderSessionEntries(entries.slice(1))` equivalent,
  Grounds 3). The panel lane's chat tests inject events in exactly this shape; the
  agent lane's loop tests assert emission in exactly this shape. No other keys are
  added to the event; `usage` does NOT ride the event (nothing renders it — the cost
  notice is default-off in pi, Grounds 3 — it persists on the recorder entry only).

- **Lane `agent`** (repo `repos/tart`; touch: `lib/tart/agent/loop.rb`,
  `lib/tart/agent/session.rb`, `test/agent_loop_test.rb`, `test/session_test.rb`):
  1. **The `entries:` payload** (the frozen contract above). Derive the kept entries
     on the loop/recorder side — the recorder holds the chronological entry list and
     the compaction entry records `first_kept_entry_id`; verify the cleanest
     derivation (recorder projection vs loop-side collection) and build it. Do not
     reshape the existing replay-entry format.
  2. **`usage` persistence** (pi CompactionEntry parity, Grounds 4):
     `Recorder#append_compaction` persists the summarization call's usage (the
     I29 `Preparation#usage` — the gem `Message#tokens`) on the entry in pi's
     persisted `Usage` shape — READ pi's `Usage` interface + the gem's `Tokens`
     readers first and map faithfully (pi's entry keys are camelCase — the standing
     I07/I08 format rule); `estimated_tokens_after` is NOT persisted (pi doesn't).
     The `:compaction` EVENT SHAPE otherwise stays the frozen I12 contract
     (additive key only).
  3. **The switch window tier** (the I29-ruled residual, Grounds 6):
     `switch_model`'s re-resolve consults the boot chain's known-models tier —
     catalog-declared window → `@chat.model&.context_window` →
     `Settings::MODEL_CONTEXT_WINDOWS` — so switching to a known-models-table entry
     without a declared window resolves the table's window instead of nil
     (threshold disabled). Reuse `Settings.resolve_context_window` if it fits;
     itemize the tier set you land. Tests: agent_loop pins the payload shape (the
     kept-entry semantics + a two-message cut fixture) + the usage persistence
     round-trip; session_test pins the entry shape; the switch tier pins a
     known-models entry resolving the table window + the footer denominator refresh.
     No MockLLM changes expected (existing idioms); `test/support/**` is NOT in your
     touch set — if you find you need it, STOP and report the conflict in PHASE 0.

- **Lane `panel`** (repo `repos/tart`; touch: `lib/tart/render/chat.rb`,
  `lib/tart/render/transcript.rb`, `test/chat_test.rb`, `test/render/**` (new files
  only if a direct-class pin needs a home), `gems/tui-split-rig/**`):
  1. **The panel component** (pi compaction-summary-message.ts, Grounds 2): rides
     the existing skill-panel family (transcript.rb:347-377 — same
     `custom_message_bg` Box shape, bold `custom_message_label` `[compaction]` span,
     prose over `custom_message_text`, bg on every span). Collapsed content row:
     `Compacted from <grouped> tokens (ctrl+o to expand)` — `custom_message_text`
     fg with the `ctrl+o` key in `dim` (pi composes three fg runs; match the span
     split). Expanded: `**Compacted from <grouped> tokens**` header + blank line +
     the summary, markdown-rendered over the panel (the skill panel's
     markdown-over-prose-override machinery). The number uses pi's
     `toLocaleString()` comma grouping — search the repo for the existing grouping
     helper before writing one (the footer's token counters likely have it). The
     panel joins the ctrl+o GLOBAL expand family (`@tool_output_expanded` — the
     I25/I06 machinery): toggling re-renders collapsed/expanded in place. MouseRegion
     click-to-toggle stays CUT (the standing skill-panel deviation — mouse owns
     selection).
  2. **The live rebuild** (pi compaction_end, Grounds 3): the `:compaction` handler
     becomes: clear the transcript (WITHOUT the /new footer-usage reset — pi
     invalidates, never resets; split the clear if `clear_transcript` conflates
     them), replay the event's `entries` through the existing `replay_entries`
     machinery (pi's own load/rebuild reuse precedent, Grounds 3), then enqueue the
     panel region LAST. The MOTD/[Context] header is wiped by the clear and NOT
     re-rendered (s7's @@ -8 candidate). Editor history must not duplicate
     (`replay_user` feeds `@history_sink`, transcript.rb:407 — measure and handle:
     pi's rebuild path does not re-populate history). The dim `✻ compacted` line and
     its blank region are REPLACED (s7's ✻ candidate); the `:compaction_start`
     border-status machinery is untouched (the frozen I12 contract).
  3. **The replay panel** (pi renderSessionEntries compactionSummary, Grounds 2):
     the resume path renders a persisted compaction entry as the panel ( Spacer(1) +
     the panel at its chronological position with the global expand state) —
     replacing the bare-markdown render (transcript.rb:395-402). The "compacted N
     times" resume notice: verify against pi's resume path whether it survives
     alongside the panels (grep pi for the notice's source; if pi has no such line
     post-panel, cut it and itemize — it predates the panel port).
  4. **The rig**: s7 AND s8 exit 0 cold (the deliverable's proof — Grounds 7);
     s8's style_unknown empty-dim candidate is expected to vanish with the ✻-line
     removal — if it survives, root-cause it against the capture (do not sanction it
     away). Registry additions-only vs a622ee03. s1–s6 must stay exit 0 (the rebuild
     must not leak into non-compaction turns). Tests: chat tests pin the rebuild
     (cleared transcript, kept entries re-rendered, panel last, MOTD gone, footer
     usage NOT reset, history not duplicated), the panel's collapsed/expanded bytes
     (both states + the ctrl+o toggle), the replay panel, and the grouped number.

- **Output format.** Raw evidence to scratch: file list + wc; the render table
  (pi mechanic → port seam, before/after: panel/rebuild/replay/usage/tier); verbatim
  test tails + suite counts; s1–s8 exit codes from YOUR worktree run (s7+s8 expected
  0, s1–s6 expected 0); the s8 style_unknown disposition; itemized
  deviations/cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0 section —
  the I28 report's deviation-table framing was a reporting defect; don't repeat it).
  STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet &&
  bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources: `packages/coding-agent/src/modes/interactive/
  components/compaction-summary-message.ts` (the whole file), `interactive-mode.ts`
  (:3686-3725 compaction_end, :3903-3904 + :4086-4110 renderSessionEntries,
  :4118-4130 the cost notice), `core/session-manager.ts` (:85-101 CompactionEntry,
  :1265-1290 appendCompactionEntry), `core/settings-defaults.ts:27` — read before
  coding; cite what you port. The gem at
  ~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
  (tokens.rb readers) for the usage mapping.

- **Boundaries.** Lane `agent` must not touch anything outside its four files — in
  particular `lib/tart/render/**` ALL (chat.rb/transcript.rb are lane `panel`'s
  single-writer territory), `test/chat_test.rb`, `gems/**`, `test/support/**`,
  `lib/tart/models.rb`, `lib/tart/settings.rb` (READ `Settings.resolve_context_window`
  / `MODEL_CONTEXT_WINDOWS` freely; if a change there is genuinely required, STOP and
  raise it in PHASE 0 instead of touching). Lane `panel` must not touch anything
  outside its set — in particular `lib/tart/agent/**` (loop.rb/session.rb are lane
  `agent`'s), `test/agent_loop_test.rb`, `test/session_test.rb`,
  `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/compaction.rb`,
  `bin/tart`. No placeholders; search before implementing. Out of scope, itemize if
  tempted: the compaction_cost notice (no settings seam — Grounds 3),
  estimated_tokens_after persistence (pi doesn't persist it), MouseRegion
  click-to-toggle, the compaction FAILURE render paths (pi's aborted/errorMessage
  arms — the port's failure handling is I08-era and unmeasured by any rig scenario;
  queue, do not build), the footer ↑/↓ count divergence (sanctioned
  footer-provider-prefix class, existing debt), pi's `systemMessage` on the
  CompactionEntry (out of lane, session format extension beyond usage).

```lanes
- name: agent
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - lib/tart/agent/session.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: panel
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
    - test/render/**
    - gems/tui-split-rig/**
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
