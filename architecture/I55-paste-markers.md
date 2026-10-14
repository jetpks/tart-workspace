# I55: paste-markers

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I55 paste-markers

## 0. Control (this session)

- Space base: the I55 scaffold (`architect new paste-markers` →
  `architecture/I55-paste-markers.md`); I54 steering-queue is CLOSED
  (verdict 68e6443, lane merge `e61cb78` on `project/pi-port`, teardown
  done). The space sits at I54; this is the next successor entry.
- This iteration: **ENTRY B of the live-run fixes rev3 program**
  (`notes/plan-20261014T031751Z.md` — read in full this session; the
  standing-rules preamble governs: serial entries, escalation only via
  `build/loop/exception-*.md`, builders never commit, every entry's gates
  include the full no-regression battery cold, and NO entry may move a
  wire byte of the EXISTING scenarios — new behaviors get NEW
  scenarios/goldens, never edits to old ones).
- repos/tart at `project/pi-port` **`e61cb78`** (I54's integrated tip:
  the queue split, busy-or-not submit cure, surface mirror,
  `Editor#set_text`, rig `mid_run_keys` + s12/s13) — the frozen base.
  CLEAN worktree. This entry grounds against THAT tree (ENTRY B's editor
  surface includes I54's `Editor#set_text` and the I54 render changes).
- repos/pi at `main` `f1b2e77f` — oracle, read-only. **The installed pi
  binary** (mise symlink →
  `@earendil-works/pi-coding-agent@1.1.0/dist/bundle/chunks/chunk-OTL6MGLJ.js`)
  **carries the full paste-marker feature** (pasteCounter ×10,
  expandPasteMarkers ×3, the `[paste #…]` templates ×3 — grepped this
  session); the rig's oracle is live-current for this entry.
- PHASE −1 (plan-vs-tree verification, this session): every file:line
  cite in ENTRY B re-verified against the current trees. Cite drift
  (re-located, not defects): the entry's `editor.ts :1296-1317` (registry
  + marker insert) → the large-paste arm actually spans `:1302-1317`
  inside `handlePaste` `:1259-1325`; `:1291-1299` (niceties) → the
  path-prefix arm `:1290-1299`; `:1395-1419` (marker backspace) →
  `:1395-1420`; `:1090` (expandPasteMarkers) ✓ exact; `:1366` (submit
  expands) ✓ exact (submitValue `:1364-1377`); `PASTE_MARKER_REGEX :32`,
  `PASTE_MARKER_SINGLE :35` ✓ exact. **No premise invalidation**: the
  feature is absent from the port (grep `pastes|paste_marker|paste #` over
  `lib/` finds only the I35/I39 cut comments), `editor.ts` exists,
  nothing here was reshaped by I52–I54 beyond the documented set_text
  addition. No exception file needed.

## 1. The pi letter (editor.ts @ f1b2e77f, verified this session)

- **Bracketed-paste buffering** (`handleInput` `:725-750`): `\x1b[200~`
  arms paste mode, content buffers until `\x1b[201~`, then
  `handlePaste(content)`. Tart's analog already exists — the gem's native
  parser emits one `Paste` event (ratatui_ruby 1.5.0 bundle references
  `200~`; `TUI.paste_event` is the test seam) and `chat.rb:774-776`
  dispatches `@editor.insert_paste(event.content)` + autocomplete cancel.
- **handlePaste** (`:1259-1325`), in order: cancelAutocomplete /
  exitHistoryBrowsing / `lastAction = null` / ONE unconditional
  `pushUndoSnapshot` → CSI-u control-byte decode (`:1267-1274`, the tmux
  popup re-encode cure — **stays CUT in the port per the I35 ruling**,
  "the gem's paste events carry decoded content"; re-verified harmless on
  the rig path this session, §4) → `normalizeText` (`:1148-1150`: `\r\n`
  and `\r` → `\n`, tab → 4 spaces) → non-printable filter keeping `\n`
  (`:1281-1285`: `char === "\n" || charCodeAt(0) >= 32`) → **path-prefix
  space** (`:1286-1299`: filtered text starts `/ ~ .` AND the char before
  the cursor matches JS `\w` = ASCII `[A-Za-z0-9_]` → prepend one space) →
  large-paste check (`:1300-1317`): `lines > 10 || chars > 1000` (both
  strictly greater, over the FILTERED text) → store
  `pastes[pasteCounter++] = filteredText`, insert ONLY the marker
  `[paste #N +M lines]` (line form, when `lines > 10`) or
  `[paste #N C chars]` (char form otherwise) via
  `insertTextAtCursorInternal`; small pastes splice inline (single- and
  multi-line both `:1318-1325`).
- **Registry + counters**: `pastes: Map<number,string>` `:338`,
  `pasteCounter` `:339` — ids stay contiguous `1..n` (monotonic store,
  decrement+shift on marker delete). `validPasteIds()` `:385-387`.
- **Atomic segments** (`segmentWithMarkers` `:43-105` + `this.segment`
  `:389-393`): markers with VALID ids merge into single grapheme/word
  segments — cursor motion, deletion, and word-wrap treat a marker as one
  unit. `isPasteMarker` `:38-40`.
- **Expansion**: `expandPasteMarkers` `:1090-1097` — per-id
  `result.replace(new RegExp("\\[paste #id( (\\+\\d+ lines|\\d+ chars))?\\]"), () => content)`:
  id-driven, suffix-agnostic (a hand-typed marker whose id is in the
  registry expands — pi quirk, parity), and the replacer is a FUNCTION
  (content never interpreted as a replacement pattern).
  `getExpandedText()` `:1100-1103`.
- **Submit**: `submitValue` `:1364-1377` — expand → trim → reset state →
  `pastes.clear()` + `pasteCounter = 0` → `undoStack.clear()` →
  `onSubmit(result)`. So EVERY downstream consumer (commands if-chain,
  steer/followUp queueing, bash intercept, session recording, history)
  receives the EXPANDED text. **Read points at the interactive layer**
  (verified): `handleFollowUp` `interactive-mode.ts:4476`
  (`getExpandedText?.() ?? getText()`), external editor `:4598` (same),
  main submit = `editor.onSubmit` set at `:3200` (fed by submitValue).
  **`restoreQueuedMessagesToEditor` `:4753` reads `getText()` RAW** — the
  dequeue-restore path joins the (already-expanded) queue texts with the
  RAW editor text through `setText`, which clears the registry
  (`:1115-1127`, `pastes.clear()` `:1124-1125`) — a live marker at
  dequeue-restore dies as literal text. Pi's exact shape; the port pins
  it.
- **Marker delete** (`handleBackspace` `:1383-1428`): the grapheme before
  the cursor is a merged marker (`PASTE_MARKER_SINGLE.exec` `:1395`) →
  delete the whole marker, `pastes.delete(id)`, `pasteCounter--`, shift
  higher registry ids down in ascending order (`:1406-1410`), and
  renumber every text marker `x > id` → `x-1` across ALL lines preserving
  each marker's suffix verbatim (`:1412-1418`). **Forward delete**
  (`handleForwardDelete` `:1781-1815`) removes the whole merged-marker
  span (first grapheme = the marker, `:1792-1800`) but does NOT touch the
  registry — pi's exact quirk (stale entry is inert: expansion is
  marker-driven).
- **Undo**: `pushUndoSnapshot` `:2116-2119` snapshots `{state, pastes,
  pasteCounter}` — `UndoStack` clone-on-push (`undo-stack.ts:20`,
  structuredClone covers the Map) — and `undo` `:2121-2134` restores
  registry + counter with the state triple. **The port's I39 snapshot is
  "exactly pi's EditorState triple"** (editor.rb:54-56, :1007-1011
  comment) — the pastes/pasteCounter halves come back with this entry.
- **setText** `:1115-1127` clears the registry AFTER the
  push-if-content-differs (the snapshot carries the old registry; undo
  restores it). pi has NO other public clear — the port's `clear`
  (escape/ctrl+c + submit surface, editor.rb:113-122) realizes
  interactive-mode's `clearEditor` → `setText("")`, so it clears the
  registry too.

## 2. The port's current state (base e61cb78, verified this session)

- `lib/tart/render/editor.rb` (1052 lines): `insert_paste` `:167-176`
  already does exit-history/last-action/ONE unconditional undo push →
  `normalize_text` → non-printable filter → `insert_multiline`
  (`:957-978`, = pi `insertTextAtCursorInternal`). **Cut and itemized in
  its comment**: the CSI-u decode, the path-prefix space, and the
  large-paste markers. This entry lands the latter two (the CSI-u decode
  STAYS cut).
- `lib/tart/render/chat.rb` (2204 lines): submit `:990-1024` reads
  `@editor.input.dup.strip` `:994`; `submit_follow_up` `:1044-1064` reads
  raw `:1052`; `dequeue_queued_messages` `:1118-1136` joins the mirrored
  queues with RAW `@editor.input` `:1122` through `set_text` (I54).
  `Chat#input` `:332` (raw readback), autocomplete reads raw via
  `slash_token`/`input` — all pi-parity raw (pi `getText()`), unchanged.
- The I54 surface pieces this entry builds on: `Editor#set_text`
  `editor.rb:519-536`; the steer/followUp mirror arrays + delivery echo;
  `clear_undo_stack` called from both submit surfaces.
- Editor state/private fields: `@lines/@cursor_line/@cursor_col` +
  render-window fields + `@history/@kill_ring/@undo_stack/@last_action`
  (constructor `:89-101`). `Snapshot` Struct 3 members `:55-56`.
  `delete_backward` `:185-198`; `delete_forward` `:200-215`;
  `push_undo_snapshot` `:1007-1011`; `undo` `:481-498`.
- Test homes verified: `test/render/editor_multiline_test.rb` (the two
  `insert_paste` behavior tests `:313-343`), `test/render/editor_undo_test.rb`
  (`:178-198` the paste undo atomicity pins), `test/chat_test.rb` (`:4369`
  multi-line paste through the dispatch; `:3035-3042` the paste-event
  dispatch).
- The rig (`gems/tui-split-rig`): `Scenario` `:80-141` (knob parse/validate
  — **`expected_requests` must be a POSITIVE integer `:86-88`; `responses`
  must be NON-empty `:90-92`**); `Runner#run_app` `:113-165` sends the
  prompt+Enter as ONE `tmux send-keys` call `:124`; boot/staging primitives
  PUBLIC for probes (`public :capture, :capture_styled, :settle, :teardown,
  :boot_session` `:534`); `runner.settle` = screen-quiescence (3 × 250 ms),
  request counting via the mock's DRAINING `captured_request_logs` written
  to `<out>/run-1/<app>-requests.jsonl` `:151-153`. Scenario files s1–s13;
  the rig is stdlib-only.

## 3. The owner rulings carried by this entry

- **problems.md item 8** (verbatim, the paste finding): "pasted content
  handling -- we need to do that thing where we inject a placeholder into
  the user message. also, i really like how claude-code does it where if
  you paste again immediately, it expands to the full text instead of the
  placeholder. perfect ux."
- **EMBEDDED OWNER RULING (beyond pi, sanctioned deviation)**: pasting
  again immediately OVER a marker replaces the marker with its full
  registry text inline (the claude-code behavior; pi does not have this).
  Test-pinned as the PORT's own behavior — a rig scenario can never pin it
  (pi lacks the arm; the differ would fail), so it is UNIT-pinned only.
  Realization (this spec's ruling, §spec D6): the arm triggers when a
  VALID marker span ENDS exactly at the cursor (the same detection as the
  backspace arm); the marker is replaced by its registry content inline
  (the `insert_multiline` splice shape), the registry entry is dropped
  with the backspace-arm renumber discipline (contiguity preserved), and
  the NEW paste then runs the normal path — cursor lands at the inserted
  tail.
- **Backlog item f** (I34–I42 loop-closure list, ARCHITECT.md:170f; I18→I35
  lineage): the "large-paste marker compaction cut" — the marker must
  survive session replay shape decisions. **Pi's answer, verified LIVE
  this session (§4): the session records the EXPANDED text** (pi's session
  JSONL user entry = the exact 195-byte pasted text, no marker bytes).
  The port pins the same (unit + the s15 session-file gate).

## 4. Spec-time live calibration (the I54 s12/s13 lesson applied — new
gate assertions pre-verified against a LIVE run, not assumed)

Probe: `tmp/paste-calib/calib.rb` (+ `stage/` artifacts, this session) —
drives BOTH apps through the exact s14/s15 flows with the rig's own
public primitives (`boot_session`/`settle`/`capture`/`teardown`), sending
a 12-line bracketed paste via `tmux load-buffer` + `paste-buffer -p`,
then Enter. Facts (env -u HERDR_* discipline matters — with the vars
leaked, pi loads a herdr extension and the diff grows an [Extensions]
block):

1. **tmux paste mechanics under rig staging**: `paste-buffer -p` wraps
   with `\e[200~ … \e[201~` only for panes that enabled bracketed paste
   (both apps do), newlines pass VERBATIM, no CSI-u re-encoding — the
   I35 CSI-u cut is safe on the rig path.
2. **pi's display after the 12-line paste: exactly one row
   `[paste #1 +12 lines]`** (stage/pi-display.txt:37), zero pasted-content
   rows. The `+12 lines` byte form confirmed live.
3. **base tart's display: the raw 12 lines in the editor** (12 rows) —
   the discriminating delta; s14 is RED-at-base by design (the I20/I35
   RED-at-base control class).
4. **Wire (request 1, both apps): the user content is the EXACT
   195-byte 12-line text, no marker bytes.** SHAPE divergence — pi
   serializes the user content as a PARTS ARRAY
   (`[{"type":"text","text":"line alpha one\n…"}]`), tart as a plain
   STRING. This is the I54-s12-adjudicated class (judge's
   shape-normalized re-run): the s15 gate extracts pi's text
   shape-normally (`content.is_a?(String) ? content :
   content.map { |p| p["text"] }.join`) — pre-verified live this
   session, not assumed.
5. **Session recording (both apps): the newest session JSONL's user
   entry is the exact expanded text** — pi at
   `home/pi/.pi/agent/sessions/<slug>/*.jsonl`, tart at
   `home/tart/.tart/sessions/<slug>/*.jsonl` (tart entry shape
   `{"type":"message",…,"message":{"role":"user","content":"…"}}`).
   Backlog item f's pi-side fact is LIVE-verified.
6. **Submit settled screens are parity-clean at base** (manual differ on
   the probe captures: only the sanctioned sandbox-path + footer-model
   rows) — s15 is green-at-base-class, i.e. regression cover for
   "the wire keeps the full content; the marker is display-only".

## 5. Recorded reductions carried forward (itemized, never silent)

- **Char-unit cursor motion / word ops / word-wrap** (I35's standing
  simplification, editor.rb:20-22 + :651-653): pi's merged-segment
  atomicity makes a marker one step for left/right/vertical motion, one
  word for ctrl+w-style ops, and an unbreakable unit in wordWrapLine
  (editor.ts `:150/:199/:174` — no wrap opportunity forms inside a
  marker). The port stays char-unit: motion walks INTO a marker, word ops
  split at its internal spaces, and a marker may wrap mid-span at a
  narrow width. Marker atomicity in THIS port is exactly the two
  deletion arms (backspace with registry cleanup + renumber; forward
  delete whole-span without cleanup). Untouched by this entry's gates;
  reopen on owner live-run pain.
- **CSI-u control-byte decode** (pi editor.ts:1267-1274): STAYS CUT per
  the I35 ruling (gem delivers decoded paste content; re-verified
  inert on the rig path this session). Tripwire: the s15 wire gate's
  exact-content assert — if a real tmux environment re-encodes pasted
  control bytes, the gate fires and the decode ports in-lane.
- **`isPasteMarker`'s length ≥ 10 fast-path** — subsumed by the regex.

## 6. House conventions this entry honors (from
notes/spec-digest-20261014T122538Z.md, verified)

- **NEVER hand-transcribe digest literals** — gate digests extracted
  programmatically from `architecture/I54-steering-queue.md` + comm-check
  both ways (the I54 session's own first-rehearsal catch).
- Gates run under /bin/sh — POSIX only, no bash process substitution;
  `architect section` key is `acceptance-criteria`; multi-step cmds end
  with `echo SENTINEL` + `stdout_match`.
- Re-rehearse after ANY AC edit so the freeze stamp covers the exact
  frozen bytes; freeze records the working tree.
- Lane scratch: `build/i55-core/{prompt,spec}.md` + staged copies at
  `build/I55-paste-markers-core/` (I53/I54 shape).
- s11 is STANDING-OPEN-RED (I47 verdict; human amendment) — NOT this
  program's bar; s13-parity likewise stays RED until the I54 amendment
  lands (owner decision recorded) — the standing battery for THIS entry
  runs s1–s10 + probes, NOT s11–s13.
- The rig's `expected_requests` count IS a discriminator — s15 pins 1.

## 7. Open questions for the judge (declared, not blocking)

- OQ-1: the paste-over-marker arm's exact realization (expand-then-
  process, cursor at the inserted tail, one undo unit) is the SPEC's
  ruling of the owner's one-line claude-code reference — no pi letter
  exists to diff against; the unit pins ARE the contract.
- OQ-2: forward-delete marker atomicity WITHOUT registry cleanup is
  pi's exact letter (a quirk) — ported faithfully rather than "improved";
  flagged so the judge sees it is deliberate parity, not an oversight.
- OQ-3: the rig's `expected_requests` validation relaxes to NON-NEGATIVE
  (0 allowed) for paste-only display flows — additive, no existing
  scenario's value changes; flagged as a shared-instrument change.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section paste-markers specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision paste-markers`
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
`architect rehearse paste-markers` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze paste-markers` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse paste-markers` — before the freeze, while
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
subsection per lane. A copy is written to build/I55-paste-markers-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section paste-markers prompt --append --lane <lane> --from build/I55-paste-markers-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I55-paste-markers-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence paste-markers --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section paste-markers verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify paste-markers`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
