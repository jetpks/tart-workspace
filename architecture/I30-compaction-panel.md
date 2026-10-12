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

# Acceptance Criteria — I30 compaction-panel

**AC1 (the panel).** The compaction panel renders pi's bytes: the customMessageBg
Box family (outputPad 1, padY 1, bg on every span — the skill-panel precedent),
collapsed = bold `customMessageLabel` `[compaction]` + the `customMessageText`
`Compacted from <grouped> tokens (` + `dim` `ctrl+o` + ` to expand)` prose; expanded
= the label + markdown `**Compacted from <grouped> tokens**` + blank + summary over
the panel; the number comma-grouped (pi `toLocaleString`); the panel rides the ctrl+o
GLOBAL expand state (toggling re-renders in place); MouseRegion click-to-toggle stays
cut (itemized). Replay renders persisted compaction entries as this panel at their
chronological position. Pinned by chat tests on both states + the replay path.

**AC2 (the live rebuild).** On the `:compaction` event (the frozen payload), the
surface clears the transcript (MOTD/[Context] wiped, NOT re-rendered), re-renders the
event's kept entries chronologically through the replay machinery, and appends the
panel LAST; footer usage is NOT reset (invalidate, not /new's reset) and editor
history is not duplicated; the dim `✻ compacted` line + its blank region are gone.
Proof: s7_compaction exits 0 cold + the chat-test pins. The `:compaction_start`
border-status contract is untouched.

**AC3 (the agent seams).** The `:compaction` event payload is exactly
`reason/tokens_before/summary/entries` with `entries` = the kept post-compaction
replay-entry Hashes in chronological order (no system, no summary message) — asserted
by agent_loop tests on a real cut fixture. The recorder persists the summarization
call's `usage` on the compaction entry in pi's CompactionEntry `Usage` shape
(camelCase keys per the standing format rule); `estimated_tokens_after` is NOT
persisted. `switch_model`'s re-resolve consults the known-models tier (a
known-models-table entry with no declared window resolves the table's window; the
footer denominator refreshes). Pinned by agent_loop + session tests.

**AC4 (the zero-usage path).** s8_zero_usage_compaction exits 0 cold — the Case-3
path renders identically through the panel + rebuild; s8's style_unknown empty-dim
candidate is resolved (vanished with the ✻-line removal, or root-caused against the
capture in the report — never sanctioned away silently).

**AC5 (regression).** s1–s6 all exit 0 cold (the rebuild leaks into no other turn);
the rig registry is additions-only vs a622ee03; the default rake task is fully green
with run-count delta > 0 (new tests); the seam bench prints SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs a622ee03 (the pre-iteration tip — the I29
parallel-sibling lesson) touches exactly the union of the two lanes' enumerated
files: loop.rb, session.rb, agent_loop_test.rb, session_test.rb, chat.rb,
transcript.rb, chat_test.rb, test/render/**, gems/tui-split-rig/**.

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

- id: panel-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q '\[compaction\]' lib/tart/render/transcript.rb lib/tart/render/chat.rb && echo PANEL_OK
  expect:
    exit_code: 0
    stdout_match: PANEL_OK

- id: payload-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q 'entries:' lib/tart/agent/loop.rb && echo PAYLOAD_OK
  expect:
    exit_code: 0
    stdout_match: PAYLOAD_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-panel
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-zero-usage
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git show a622ee03:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only a622ee03 HEAD | grep -qvE '^(lib/tart/agent/loop\.rb|lib/tart/agent/session\.rb|test/agent_loop_test\.rb|test/session_test\.rb|lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|test/chat_test\.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### agent

# Lane dispatch — I30 compaction-panel, lane `agent`

**You are lane `agent`.** You are ONE of TWO parallel lane agents dispatched together
(the other is lane `panel` of the SAME iteration, isolated in its own worktree — its
territory is `lib/tart/render/chat.rb`, `lib/tart/render/transcript.rb`,
`test/chat_test.rb`, `test/render/**`, and `gems/tui-split-rig/**`, which you must
NEVER touch). Your lane's territory, exhaustively:

- **Touch (exactly these files):** `lib/tart/agent/loop.rb`,
  `lib/tart/agent/session.rb`, `test/agent_loop_test.rb`, `test/session_test.rb`.
- **Must not touch:** everything else — in particular `lib/tart/render/**` ALL
  (chat.rb/transcript.rb are lane `panel`'s single-writer territory — a parallel lane
  is building there right now; touching it fails both lanes), `gems/**`,
  `test/chat_test.rb`, `test/render/**`, `test/support/**` (if you find you need a
  MockLLM change, STOP and raise it in PHASE 0 instead of touching),
  `lib/tart/models.rb`, `lib/tart/settings.rb` (READ `Settings.resolve_context_window`
  and `MODEL_CONTEXT_WINDOWS` freely; if a change there is genuinely required, STOP
  and raise it in PHASE 0), `lib/tart/compaction.rb`, `bin/tart`.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them (notably: pi's persisted `Usage` interface shape — read
pi's session-manager.ts Usage/appendCompactionEntry and the gem's tokens.rb
READERS live before mapping; and the cleanest kept-entries derivation from the
recorder's chronological list + `first_kept_entry_id`).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive collection/enumerable forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Consistency with the surrounding code
is part of correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write) is
not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout (the parity
rig runs take tens of seconds each — allow 120s+ each). IMPORTANT tmux
discipline: a `tmux kill-server` from you kills every other agent's live
sessions on the shared server — NEVER run it; kill only sessions you created by
exact name (the runner's sessions are token-scoped). If a runtime will not
start unattended, record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the scratch
file given to you below (an absolute path OUTSIDE your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I30-compaction-panel-agent/report.md

## Your lane's specification (lane `agent` ONLY — lane `panel`'s deliverables are NOT yours)

- **Objective (iteration context).** Port pi's compaction render to close the s7/s8
  settled-screen divergence: pi renders compaction as a customMessageBg `[compaction]`
  panel AND rebuilds the transcript from the post-compaction kept entries; the port
  renders a dim `✻ compacted` line. Lane `panel` builds the render; YOUR lane builds
  the agent-side seams the render needs — the event payload, the entry persistence,
  the switch window tier.

- **THE FROZEN CONTRACT (lane `panel` builds its consumer against this; never drift
  it).** The `:compaction` event payload becomes exactly:
  `emit(type: :compaction, reason:, tokens_before:, summary:, entries:)` where
  `entries` is an Array of replay-entry Hashes — the SAME shape
  `Agent::Session.load_entries` / the transcript's `replay_entries` consume (message
  entries with `type`/`message` keys, bashExecution entries, etc.) — holding the
  post-compaction KEPT context entries in chronological order (the entries after the
  cut point, i.e. from `first_kept_entry_id` onward; NOT the system messages, NOT the
  summary message — pi's `renderSessionEntries(entries.slice(1))` equivalent). No
  other keys are added; `usage` does NOT ride the event (nothing renders it — the
  cost notice is default-off in pi; it persists on the recorder entry only).

- Deliver **the `entries:` payload** (the frozen contract): derive the kept entries
  on the loop/recorder side — the recorder holds the chronological entry list and
  the compaction entry records `first_kept_entry_id`; verify the cleanest derivation
  (recorder projection vs loop-side collection) and build it. Do not reshape the
  existing replay-entry format. Pinned by agent_loop tests on a real two-message cut
  fixture (the kept-entry semantics, chronological order, no system/summary leakage).

- Deliver **`usage` persistence** (pi CompactionEntry parity): `Recorder#
  append_compaction` persists the summarization call's usage (the `Preparation#usage`
  the loop already carries — the gem `Message#tokens`) on the entry in pi's persisted
  `Usage` shape — READ pi's `Usage` interface (session-manager.ts) + the gem's
  `Tokens` readers (tokens.rb) first and map faithfully; pi's entry keys are camelCase
  (the standing I07/I08 format rule); `estimated_tokens_after` is NOT persisted (pi
  doesn't). The `:compaction` EVENT SHAPE otherwise stays the frozen I12 contract
  (additive key only). session_test pins the persisted entry shape round-trip.

- Deliver **the switch window tier** (the I29-ruled residual): `switch_model`'s
  re-resolve consults the boot chain's known-models tier — catalog-declared window →
  `@chat.model&.context_window` → `Settings::MODEL_CONTEXT_WINDOWS` — so switching to
  a known-models-table entry without a declared window resolves the table's window
  instead of nil (threshold disabled). Reuse `Settings.resolve_context_window` if it
  fits; itemize the tier set you land. Pinned by an agent_loop test (a known-models
  entry resolves the table window; the footer denominator refreshes).

- **Out of scope, itemize if tempted:** anything in `lib/tart/render/**`, the
  compaction_cost notice, `estimated_tokens_after` persistence, pi's `systemMessage`
  on the CompactionEntry, MockLLM changes.

- **Tool guidance.** Verification (from your worktree root):
  `bundle install --quiet && bundle exec rake` (expect fully green, run-count delta
  > 0 from your new tests); `bundle exec ruby bench/seam_bench.rb` (expect
  SEAM_BENCH_OK). pi sources (READ before coding; cite what you port):
  `repos/pi/packages/coding-agent/src/core/session-manager.ts` (:85-101
  CompactionEntry + the Usage interface, :1265-1290 appendCompactionEntry),
  `repos/pi/packages/coding-agent/src/modes/interactive/interactive-mode.ts`
  (:3686-3725 compaction_end — the rebuild's entries.slice(1) semantics),
  `repos/pi/packages/coding-agent/src/core/settings-defaults.ts:27`. The gem at
  ~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
  (tokens.rb readers) for the usage mapping.

- **Output format.** Raw evidence to scratch: file list + wc; the payload derivation
  table (mechanism → code, before/after); the usage mapping table (gem Tokens reader
  → pi Usage key); the tier table; verbatim test tails + suite counts; itemized
  deviations/cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0 section).
  STATUS line last.

## Acceptance Criteria (frozen — verify against these)

**AC1 (the panel).** [lane `panel`'s — listed for context; you build none of it]
The compaction panel renders pi's bytes: the customMessageBg Box family, collapsed =
bold `customMessageLabel` `[compaction]` + the `customMessageText` prose +
`dim` `ctrl+o` key; expanded = markdown header + summary; comma-grouped number; the
ctrl+o GLOBAL expand state; MouseRegion click-to-toggle stays cut. Replay renders
persisted compaction entries as this panel.

**AC2 (the live rebuild).** [lane `panel`'s render + YOUR payload] On the
`:compaction` event (the frozen payload), the surface clears the transcript, re-renders
the event's kept entries chronologically, and appends the panel LAST. Proof:
s7_compaction exits 0 cold + chat-test pins.

**AC3 (the agent seams — YOURS).** The `:compaction` event payload is exactly
`reason/tokens_before/summary/entries` with `entries` = the kept post-compaction
replay-entry Hashes in chronological order (no system, no summary message) — asserted
by agent_loop tests on a real cut fixture. The recorder persists the summarization
call's `usage` on the compaction entry in pi's CompactionEntry `Usage` shape
(camelCase keys); `estimated_tokens_after` is NOT persisted. `switch_model`'s
re-resolve consults the known-models tier (a known-models-table entry with no declared
window resolves the table's window; the footer denominator refreshes). Pinned by
agent_loop + session tests.

**AC4 (the zero-usage path).** s8_zero_usage_compaction exits 0 cold on the
integrated tree (the Case-3 path renders identically through the panel + rebuild);
s8's style_unknown empty-dim candidate is resolved.

**AC5 (regression).** s1–s6 all exit 0 cold on the integrated tree; the rig registry
is additions-only vs a622ee03; the default rake task is fully green with run-count
delta > 0; the seam bench prints SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs a622ee03 touches exactly the union of the two
lanes' enumerated files.

Gate commands you can run to self-verify (frozen; run from YOUR worktree — note the
rig gates judge the INTEGRATED tree; in YOUR worktree s7/s8 stay exit 1 because the
panel render is the sibling lane's, do NOT chase them):

```
bundle install --quiet && bundle exec rake && echo SUITE_OK     # expect exit 0, SUITE_OK, run delta > 0
bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1             # expect SEAM_BENCH_OK
grep -q 'entries:' lib/tart/agent/loop.rb && echo PAYLOAD_OK    # expect PAYLOAD_OK
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/gate-s1   # exit 0 (regression guard — your loop changes must not shift the healthy path)
```

### panel

# Lane dispatch — I30 compaction-panel, lane `panel`

**You are lane `panel`.** You are ONE of TWO parallel lane agents dispatched together
(the other is lane `agent` of the SAME iteration, isolated in its own worktree — its
territory is `lib/tart/agent/loop.rb`, `lib/tart/agent/session.rb`,
`test/agent_loop_test.rb`, and `test/session_test.rb`, which you must NEVER touch).
Your lane's territory, exhaustively:

- **Touch (exactly these files):** `lib/tart/render/chat.rb`,
  `lib/tart/render/transcript.rb`, `test/chat_test.rb`, `test/render/**` (new files
  only if a direct-class pin needs a home), `gems/tui-split-rig/**`.
- **Must not touch:** everything else — in particular `lib/tart/agent/**` ALL
  (loop.rb/session.rb are lane `agent`'s territory — a parallel lane is building
  there right now; touching it fails both lanes), `test/agent_loop_test.rb`,
  `test/session_test.rb`, `test/support/**`, `lib/tart/compaction.rb`,
  `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/commands.rb`, `bin/tart`.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them (notably: pi's CompactionSummaryMessageComponent — read
the whole file; pi's compaction_end handler; the existing skill-panel family in
transcript.rb; the I25 expandable/ctrl+o machinery).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive collection/enumerable forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Consistency with the surrounding code
is part of correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write) is
not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout (the parity
rig runs take tens of seconds each — allow 120s+ each). IMPORTANT tmux
discipline: a `tmux kill-server` from you kills every other agent's live
sessions on the shared server — NEVER run it; kill only sessions you created by
exact name (the runner's sessions are token-scoped). If a runtime will not
start unattended, record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the scratch
file given to you below (an absolute path OUTSIDE your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I30-compaction-panel-panel/report.md

## Your lane's specification (lane `panel` ONLY — lane `agent`'s deliverables are NOT yours)

- **Objective (iteration context).** Port pi's compaction render to close the s7/s8
  settled-screen divergence (the owner's done bar: full settled-screen parity): pi
  renders compaction as a customMessageBg `[compaction]` panel AND rebuilds the
  transcript from the post-compaction kept entries on the live path; the port renders
  a dim `✻ compacted` line over an un-wiped scrollback. Lane `agent` builds the
  event payload + persistence + window tier; YOUR lane builds the render: the panel,
  the rebuild, the replay panel, and the rig proof.

- **THE FROZEN CONTRACT (lane `agent` emits it; you consume it; never drift it).**
  The `:compaction` event payload is exactly:
  `{type: :compaction, reason:, tokens_before:, summary:, entries:}` where `entries`
  is an Array of replay-entry Hashes — the SAME shape `Agent::Session.load_entries` /
  `Transcript#replay_entries` consume — holding the post-compaction KEPT context
  entries in chronological order (no system messages, no summary message). Your chat
  tests inject events in EXACTLY this shape. In YOUR worktree the live loop does not
  emit `entries:` yet (lane `agent`'s file) — tolerate an absent `entries` gracefully
  (render the panel over the cleared transcript; an empty replay yields a blank
  transcript); the integrated tree always carries it.

- Deliver **the panel component** (pi compaction-summary-message.ts — read the whole
  file): rides the existing skill-panel family (transcript.rb:347-377 — same
  `custom_message_bg` Box shape, outputPad 1 / padY 1, bg on every span, bold
  `custom_message_label` span, prose over `custom_message_text`). Collapsed content
  row: `Compacted from <grouped> tokens (ctrl+o to expand)` — `custom_message_text`
  fg with the `ctrl+o` key in `dim` (pi composes three fg runs; match the span
  split). Expanded: `**Compacted from <grouped> tokens**` header + blank line + the
  summary, markdown-rendered over the panel (the skill panel's markdown-over-prose
  machinery). The number uses pi's `toLocaleString()` comma grouping — SEARCH the
  repo for an existing grouping helper before writing one (the footer's token
  counters likely have it). The panel joins the ctrl+o GLOBAL expand family
  (`@tool_output_expanded` — the I25/I06 machinery): toggling re-renders
  collapsed/expanded in place. MouseRegion click-to-toggle stays CUT (the standing
  skill-panel deviation — the port's mouse owns selection).

- Deliver **the live rebuild** (pi compaction_end, interactive-mode :3686-3725): the
  `:compaction` handler becomes: clear the transcript (WITHOUT the /new footer-usage
  reset — pi invalidates, never resets; split the clear if `clear_transcript`
  conflates them), replay the event's `entries` through the existing `replay_entries`
  machinery (pi's own load/rebuild reuse precedent — renderSessionEntries :4086),
  then enqueue the panel region LAST. The MOTD/[Context] header is wiped by the
  clear and NOT re-rendered (s7's @@ -8 candidate: pi's settled screen has no
  `[Context]` after compaction). Editor history must not duplicate (`replay_user`
  feeds the history sink — measure and handle; pi's rebuild path does not
  re-populate history). The dim `✻ compacted` line and its blank region are REPLACED
  (s7's ✻ candidate); the `:compaction_start` border-status machinery is untouched
  (the frozen I12 contract).

- Deliver **the replay panel** (pi renderSessionEntries case `compactionSummary`
  :3903-3904): the resume path renders a persisted compaction entry as the panel
  (Spacer(1) + the panel at its chronological position with the global expand state)
  — replacing the bare-markdown render (transcript.rb:395-402). The "compacted N
  times" resume notice: verify against pi's resume path whether it survives alongside
  the panels (grep pi for the notice's source; if pi has no such line post-panel, cut
  it and itemize — it predates the panel port).

- Deliver **the rig proof**: run s7 AND s8 from YOUR worktree. EXPECTED in your
  worktree: both still exit 1 — lane `agent` owns the payload emission, so the
  rebuild's kept-entry rows cannot render live yet. Your in-worktree acceptance:
  the tart side's remaining unknown candidates must be EXACTLY the kept-entry rows
  (the payload-dependent lines); the panel rows, the ✻ line, and the MOTD-vs-clear
  divergence must be GONE from the tart side; pi's settled capture in your run
  artifacts (run-1/pi.capture) is your BYTE ORACLE for the panel rows — diff your
  chat-test-rendered panel bytes against it. s8's style_unknown empty-dim candidate
  is expected to vanish with the ✻-line removal — if it survives, root-cause it
  against the capture (do not sanction it away). Registry additions-only vs a622ee03
  (this is a FIX-the-port iteration — additions should be zero or near-zero; every
  addition itemized). s1–s6 must stay exit 0 (the rebuild leaks into no other turn).

- **Tests.** chat_test pins: the rebuild (cleared transcript, kept entries
  re-rendered, panel last, MOTD gone, footer usage NOT reset, history not
  duplicated), the panel's collapsed/expanded bytes (both states + the ctrl+o toggle
  re-render), the replay panel (a persisted compaction entry renders the panel), the
  grouped number, and the absent-entries tolerance. Inject the frozen payload shape
  directly.

- **Out of scope, itemize if tempted:** the compaction_cost notice (no settings
  seam — pi defaults it OFF), MouseRegion click-to-toggle, the compaction FAILURE
  render paths (pi's aborted/errorMessage arms — unmeasured by any rig scenario;
  queue, do not build), the footer ↑/↓ count divergence (sanctioned
  footer-provider-prefix class, existing debt), anything in `lib/tart/agent/**`.

- **Tool guidance.** Verification (from your worktree root):
  `bundle install --quiet && bundle exec rake` (expect fully green, run-count delta
  > 0); `bundle exec ruby bench/seam_bench.rb` (expect SEAM_BENCH_OK); the rig:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources (READ before coding; cite what you port):
  `repos/pi/packages/coding-agent/src/modes/interactive/components/
  compaction-summary-message.ts` (the whole file — the panel),
  `repos/pi/packages/coding-agent/src/modes/interactive/interactive-mode.ts`
  (:3686-3725 compaction_end — the rebuild; :3903-3904 + :4086-4110
  renderSessionEntries — the replay; :4118-4130 the cost notice — context for the
  cut), `core/settings-defaults.ts:27` (the cost-notice gate defaults off).

- **Output format.** Raw evidence to scratch: file list + wc; the render table
  (pi mechanic → port seam, before/after: panel/rebuild/replay); verbatim test tails
  + suite counts; s1–s8 exit codes from YOUR worktree run with the candidate-class
  counts (s7/s8 expected exit 1 in-worktree with ONLY the kept-entry candidates
  remaining — show the classified diff tails proving it); the s8 style_unknown
  disposition; registry addition list (itemized); itemized deviations/cuts. PHASE 0
  disagreements mandatory (a labeled PHASE 0 section). STATUS line last.

## Acceptance Criteria (frozen — verify against these)

**AC1 (the panel — YOURS).** The compaction panel renders pi's bytes: the
customMessageBg Box family (outputPad 1, padY 1, bg on every span — the skill-panel
precedent), collapsed = bold `customMessageLabel` `[compaction]` + the
`customMessageText` `Compacted from <grouped> tokens (` + `dim` `ctrl+o` +
` to expand)` prose; expanded = the label + markdown `**Compacted from <grouped>
tokens**` + blank + summary over the panel; the number comma-grouped (pi
`toLocaleString`); the panel rides the ctrl+o GLOBAL expand state (toggling re-renders
in place); MouseRegion click-to-toggle stays cut (itemized). Replay renders persisted
compaction entries as this panel at their chronological position. Pinned by chat
tests on both states + the replay path.

**AC2 (the live rebuild — YOURS).** On the `:compaction` event (the frozen payload),
the surface clears the transcript (MOTD/[Context] wiped, NOT re-rendered), re-renders
the event's kept entries chronologically through the replay machinery, and appends
the panel LAST; footer usage is NOT reset (invalidate, not /new's reset) and editor
history is not duplicated; the dim `✻ compacted` line + its blank region are gone.
Proof: s7_compaction exits 0 cold (on the integrated tree; in your worktree — exactly
the kept-entry candidates remaining) + the chat-test pins. The `:compaction_start`
border-status contract is untouched.

**AC3 (the agent seams).** [lane `agent`'s — listed for context; you build none of
it] The `:compaction` event payload is exactly `reason/tokens_before/summary/entries`
with `entries` = the kept post-compaction replay-entry Hashes in chronological order;
the recorder persists usage; the switch re-resolve consults the known-models tier.

**AC4 (the zero-usage path).** s8_zero_usage_compaction exits 0 cold on the
integrated tree (the Case-3 path renders identically through the panel + rebuild);
s8's style_unknown empty-dim candidate is resolved (vanished with the ✻-line removal,
or root-caused against the capture in the report — never sanctioned away silently).

**AC5 (regression).** s1–s6 all exit 0 cold; the rig registry is additions-only vs
a622ee03; the default rake task is fully green with run-count delta > 0 (new tests);
the seam bench prints SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs a622ee03 touches exactly the union of the two
lanes' enumerated files.

Gate commands you can run to self-verify (frozen; run from YOUR worktree — note the
s7/s8 exit-0 gates judge the INTEGRATED tree; in YOUR worktree expect exit 1 with
ONLY the kept-entry candidates remaining, per the spec above):

```
bundle install --quiet && bundle exec rake && echo SUITE_OK     # expect exit 0, SUITE_OK, run delta > 0
bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1             # expect SEAM_BENCH_OK
grep -q '\[compaction\]' lib/tart/render/transcript.rb lib/tart/render/chat.rb && echo PANEL_OK  # expect PANEL_OK
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/gate-s1   # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/gate-s2      # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/gate-s3  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/gate-s4  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/gate-s5 # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/gate-s6     # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/gate-s7     # exit 1 in YOUR worktree, kept-entry candidates only
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/gate-s8  # exit 1 in YOUR worktree, kept-entry candidates only
if git show a622ee03:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY; fi
```

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
