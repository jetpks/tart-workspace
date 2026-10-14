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

# Specification — I55 paste-markers

## Objective

Port pi's large-paste marker compaction into tart (ENTRY B of the live-run
fixes rev3 program, `notes/plan-20261014T031751Z.md`): a large paste
(> 10 lines OR > 1000 chars) stores the full text in an editor paste
registry and inserts ONLY a `[paste #N +M lines]` / `[paste #N C chars]`
marker at the cursor; submit expands markers (the wire, the session, the
history, and the queue all receive the EXPANDED text — the marker is
display-only); backspace over a marker deletes it atomically, drops the
registry entry, and renumbers; plus the owner's sanctioned
paste-over-marker deviation (Grounds §3). Pinned by unit tests and by two
NEW rig scenarios (s14 display / s15 submit-wire-session). No wire byte of
any EXISTING scenario moves. Durable context: BRIEF §8 (exact-parity
done bar) — this entry is parity-first against pi's editor.ts letter with
the owner's one deviation.

## Output format

The builder's scratch report (`build/I55-paste-markers-core/report.md`,
transcribed verbatim into Builder Report): a per-gate table (gate id,
command, exit code, tail), the new-test inventory (file, test name, one
line), the s14/s15 baseline narrative (candidates seen → resolution),
and a STATUS line. Raw command output paths under the lane worktree's
`tmp/`.

## Tool guidance — exact verification commands

- Standing battery (adopted verbatim from the I54 freeze;
  `architecture/I54-steering-queue.md` gates block — digests extracted
  programmatically, never hand-transcribed): `bundle exec rake`;
  `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK); the rig runs
  for s1–s10 + s1_tart + both probes; thinking-pins / hermeticity /
  lock-deps / zai-data / threads-budget (vs `e61cb78`) / wire-delta /
  session-golden — all in the frozen gates block below.
- Unit runs (forms verified this session):
  `bundle exec ruby -Ilib -Itest test/render/editor_multiline_test.rb -n /…/`,
  `… test/render/editor_undo_test.rb …`, `… test/chat_test.rb …`,
  `bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb -n /…/`.
- New-scenario gates: `env -u HERDR_ENV -u HERDR_TAB_ID -u
  HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u
  HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/<name>.yml --out tmp/<dir>` (the env-strip
  discipline is load-bearing — Grounds §4).
- pi oracle: `repos/pi` @ f1b2e77f sources; the installed `pi` binary
  carries the feature (Grounds §0).

## The contract, area by area

### D1 — Editor paste registry (`lib/tart/render/editor.rb`)

- Constants (pi editor.ts:32/:35, byte-faithful):
  `PASTE_MARKER_REGEX = /\[paste #(\d+)( (\+\d+ lines|\d+ chars))?\]/`
  (Ruby non-global — used via `String#scan`/`gsub` with a block) and
  `PASTE_MARKER_SINGLE = /\A\[paste #(\d+)( (\+\d+ lines|\d+ chars))?\]\z/`.
- State: `@pastes` (Hash Integer ⇒ String) + `@paste_counter`
  (Integer, 0). Invariant after every op: registry ids are exactly
  `1..n` contiguous and `@paste_counter == @pastes.size` (pi's
  store-increment / delete-decrement+shift arithmetic).
- `expanded_text` (pi getExpandedText :1100-1103 → expandPasteMarkers
  :1090-1097): over the joined input, for each registry id replace
  `[paste #<id>( (suffix))?]` with the stored content — id-driven and
  SUFFIX-AGNOSTIC (a hand-typed marker whose id is in the registry
  expands — pi quirk, pinned). **The replacement MUST use block-form
  `gsub` (or equivalent) — never a String replacement argument**: paste
  content containing `\1`/`\\`-shaped bytes must expand verbatim
  (pi's JS replacer-function parity; pinned with a regex-danger
  fixture).
- `set_text` (editor.rb:519-536) and `clear` (editor.rb:113-122) clear
  the registry + counter (pi setText :1124-1125; the port's `clear`
  realizes pi's clearEditor→setText("")). In `set_text` the clear comes
  AFTER the push-if-content-differs, so the snapshot carries the OLD
  registry and one undo restores it (pi order, pinned).

### D2 — `insert_paste` (pi handlePaste :1259-1325)

In order (the port's realization; the CSI-u decode stays CUT — Grounds
§5):
1. `exit_history_browsing`; `@last_action = nil`; ONE unconditional
   `push_undo_snapshot` (existing behavior, unchanged — the whole
   composite below is ONE undo unit).
2. **OWNER ARM (Grounds §3, the port's own behavior — pi has NO
   analog)**: if a marker with an id in `@pastes` ENDS exactly at the
   cursor on the current line, replace that span with its registry
   content inline (the `insert_multiline` splice shape: the span is
   removed, the content spliced at the span start, cursor lands at the
   end of the expanded content / before the following text), then drop
   the registry entry and renumber with exactly the D3 discipline
   (counter decrement, higher-id shift, text renumber). Then continue
   with the NEW paste through 3–5. (The path-space rule in 4 therefore
   reads the post-expansion line.)
3. Normalize (`self.class.normalize_text`) + filter non-printables
   keeping `\n` (existing behavior, unchanged).
4. **Path-prefix space (pi :1290-1299, NEW)**: if the filtered text
   starts with `/`, `~`, or `.` AND the character before the cursor
   (current line, col−1) matches ASCII `\w` = `[A-Za-z0-9_]` (pi's JS
   `\w` — NOT the port's unicode-wide `WORD_CHAR`), prepend one space.
5. **Large-paste check (pi :1300-1317, NEW)**: over the FILTERED text,
   `split("\n", -1).length > 10 || length > 1000` (both strictly
   greater; the `-1` limit reproduces JS split's trailing-empty
   counting) → `@paste_counter += 1`; `@pastes[id] = filtered`; insert
   ONLY the marker via the multiline splice — line form
   `` `[paste ##{id} +#{lines} lines]` `` when `lines > 10`, else char
   form `` `[paste ##{id} #{chars} chars]` `` (chars = filtered
   length). Otherwise the filtered text splices inline (existing
   behavior).
- The marker bytes are frozen by the live calibration: 12 pasted lines
  → `[paste #1 +12 lines]` (Grounds §4.2).

### D3 — Marker deletion arms

- **Backspace (pi handleBackspace :1383-1428)**: inside the existing
  `@cursor_col.positive?` branch (after its undo push), if a
  `PASTE_MARKER_REGEX` match on the current line ENDS exactly at
  `@cursor_col` AND its id is in `@pastes`: drop the id, decrement the
  counter, shift every higher registry id down one (ascending order),
  renumber every marker in EVERY line with id greater than the deleted
  one to id−1 (each marker's suffix preserved verbatim; block-form
  gsub), then delete the whole marker span from the current line and
  set the cursor to the span start. A marker whose id is NOT in the
  registry (hand-typed) deletes char-wise — pi parity (unmerged
  segment), pinned.
- **Forward delete (pi handleForwardDelete :1781-1815)**: if a valid
  marker match STARTS exactly at `@cursor_col`, delete the whole span
  in one op and leave the registry UNTOUCHED — pi's exact letter
  (the stale entry is inert: expansion is marker-driven), pinned as
  deliberate parity (Grounds OQ-2).

### D4 — Undo carries the registry (pi :2116-2134)

The `Snapshot` struct gains `pastes` + `paste_counter` members;
`push_undo_snapshot` populates them (the stack's deep-copy detaches the
Hash); `undo` restores them alongside the state triple (direct
assignment, the existing discipline). One undo after any marker op
(backspace-delete, paste-over) restores the pre-op marker text AND
registry (`expanded_text` round-trips).

### D5 — The submit surface delivers EXPANDED text (`lib/tart/render/chat.rb`)

- `submit` (:990-1024) and `submit_follow_up` (:1044-1064): the single
  read line in each changes from `@editor.input.dup.strip` to
  `@editor.expanded_text.dup.strip` (pi submitValue :1364-1377 expands
  BEFORE onSubmit; pi handleFollowUp :4476 reads getExpandedText).
  Everything downstream is then automatic and pi-parity: commands
  if-chain, skill expansion, steer/followUp queueing + mirrors, the
  user echo (`enqueue_user_submission`), history
  (`add_to_history` — expanded, pi :4482/:4494/:3356-3396), the bash
  intercept, the agent run, the session recording, the wire.
- UNCHANGED raw readers (pi parity — do NOT "fix"): `Chat#input`
  (:332), autocomplete (`slash_token`/`input`), bash-mode/backslash
  checks, and **`dequeue_queued_messages` (:1122) — RAW
  `@editor.input` joined through `set_text`** (pi
  restoreQueuedMessagesToEditor :4753 reads getText() raw; a live
  marker at dequeue dies as literal text because set_text clears the
  registry — pi's exact shape, pinned).
- No `lib/tart/agent/**` or session-recording change exists — the text
  is expanded at the surface seam (pi's architecture; verified live,
  Grounds §4.4–4.5).

### D6 — The rig instrument (`gems/tui-split-rig`)

- `Scenario` (`lib/tui_split_rig/scenario.rb`): two new optional knobs
  with load-time validation — `paste:` (String; the text sent as a
  bracketed paste BEFORE the prompt) and `submit:` (boolean, DEFAULT
  TRUE; false = never send Enter — paste-only display flows).
  **`expected_requests` validation relaxes to NON-NEGATIVE integer**
  (0 now valid; negative still rejected) — paste-only scenarios make no
  requests (Grounds OQ-3). The `responses` non-empty rule is unchanged
  (a paste-only scenario carries one never-served response). Header
  comment documents the knobs (house style).
- `Runner#run_app` (`lib/tui_split_rig/runner.rb`): when `paste` is
  set, after the boot settle and before the prompt: write the text to a
  file under the out dir, `tmux load-buffer -b <token-scoped-name>`,
  `tmux paste-buffer -b … -p -t <session>` (the bracketed-paste wrap —
  live-calibrated, Grounds §4.1), `delete-buffer`. **The no-knob path
  is byte-frozen**: when `paste` is absent and `submit` is true (every
  pre-existing scenario), the runner sends EXACTLY today's single
  `tmux send-keys <prompt> Enter` call (:124) — the knob branches must
  not split or reorder it (the s1–s10 battery is the regression net).
  In the knob path: the prompt is sent only when non-empty; Enter only
  when `submit`.
- `test/scenario_test.rb`: knob tests named `test_paste_knob_*`,
  `test_submit_knob_*`, `test_expected_requests_zero_*` (parse,
  defaults, rejections, 0-accepted) — the gate's name filter matches
  those.

### D7 — The two NEW scenarios (`gems/tui-split-rig/scenarios/`)

Both carry doc-comment headers (house style); the paste text is the
EXACT calibrated 12-line block (Grounds §4):

```
line alpha one / line bravo two / line charlie three / line delta four /
line echo five / line foxtrot six / line golf seven / line hotel eight /
line india nine / line juliet ten / line kilo eleven / line lima twelve
```

(one per line, no trailing newline — YAML `|-`).

- **`s14_paste_marker_display.yml`**: `prompt: ""`, the paste block,
  `submit: false`, `expected_requests: 0`, one never-served stream
  response. Pins: the settled screen shows the marker row
  `[paste #1 +12 lines]` in the editor and NO pasted-content row, in
  BOTH apps, screens identical (RED-at-base by design — Grounds §4.3).
- **`s15_paste_marker_submit.yml`**: `prompt: ""`, the paste block,
  `expected_requests: 1`, stream reply `copy that, twelve lines`. Pins:
  request 1's user content is the EXACT 12-line text in BOTH apps
  (shape-normal extraction for pi — parts array vs string, Grounds
  §4.4), zero marker bytes on the wire, the settled screens show the
  EXPANDED user echo and no marker, and tart's session JSONL records
  the expanded text with no marker bytes (Grounds §4.5 — backlog item
  f's pin).
- NO existing scenario/golden/fixture/registry file is touched.

### D8 — Unit pins (name filters are the gate contract)

- `test/render/editor_multiline_test.rb` — ≥ 12 tests matching
  `/paste_marker|expanded_text|paste_over|path_prefix/`, covering at
  minimum: both marker forms (line + char, exact bytes, cursor after
  the marker, registry stored); the >10-lines and >1000-chars
  boundaries (10 lines / 1000 chars inline; 11 lines / 1001 chars
  marker); the path-prefix space rules (word-char-before → space;
  non-word / line-start / unicode-é-before → none — ASCII `\w`); the
  non-printable filter still holding with markers; `expanded_text`
  (multi-marker join, regex-danger content verbatim, hand-typed
  marker with a valid id expands, suffix-mismatch expands);
  paste-over-marker (large-then-large: old content inline + new
  marker, ids contiguous 1..1; large-then-small: expanded + inline
  text; cursor-not-adjacent: the normal second marker `#2`;
  single-undo round-trip); backspace renumber (two markers, delete #1
  → text shows `[paste #1 +N lines]` for the survivor, registry size
  1, suffix preserved); hand-typed marker backspace char-wise;
  forward-delete span without registry cleanup.
- `test/render/editor_undo_test.rb` — ≥ 3 tests matching `/marker/`:
  marker-delete-then-undo restores text + registry
  (`expanded_text` round-trip); paste-over is ONE undo unit;
  set_text-clears-registry with undo restoring it.
- `test/chat_test.rb` — ≥ 4 tests matching `/paste_marker/`: submit
  delivers the expanded text to the agent (stub) with history
  expanded and the editor cleared; busy submit_follow_up queues the
  expanded text; the marker string never reaches the agent
  (submit + follow-up arms); dequeue-restore keeps a live marker's
  TEXT literally with the registry empty (pi :4753 parity).

## Boundaries

- **May touch (the complete set — the scope gate freezes exactly this
  list)**: `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`,
  `gems/tui-split-rig/lib/tui_split_rig/scenario.rb`,
  `gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
  `gems/tui-split-rig/scenarios/s14_paste_marker_display.yml` (NEW),
  `gems/tui-split-rig/scenarios/s15_paste_marker_submit.yml` (NEW),
  `gems/tui-split-rig/test/scenario_test.rb`,
  `test/render/editor_multiline_test.rb`,
  `test/render/editor_undo_test.rb`, `test/chat_test.rb`.
- **Must not touch**: everything else — including `lib/tart/agent/**`,
  session recording, `bench/`, `test/support/mock_llm_server.rb`,
  `registry.yml`, every existing scenario/golden, `README.md` (no
  keybinding change this entry), the probes' `bin/` scripts, and
  `lib/tart/render/` files other than editor/chat.
- **Out of scope (recorded reductions, Grounds §5)**: cursor-motion /
  word-op / word-wrap marker atomicity; the CSI-u decode (tripwire =
  the s15 wire gate); pi's external-editor and jump-mode surfaces;
  s11/s13 (standing-open, not this program's bar).

## Lane plan

ONE lane, `core` (chat.rb and editor.rb are co-designed with the rig
scenarios that pin them; the rig delta is 2 lib files + 2 YAMLs + 1
test file — below any sane split threshold; I54's single-lane
precedent for this program). Declaration:

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/scenarios/s14_paste_marker_display.yml
    - gems/tui-split-rig/scenarios/s15_paste_marker_submit.yml
    - gems/tui-split-rig/test/scenario_test.rb
    - test/render/editor_multiline_test.rb
    - test/render/editor_undo_test.rb
    - test/chat_test.rb
  objective: the paste registry, the marker insert/delete/expand ops, the
    expanded submit seam, the rig paste/submit knobs, the s14/s15
    scenarios, and the unit pins.
  output: scratch report at build/I55-paste-markers-core/report.md
    (per-gate table, test inventory, baseline narrative, STATUS line).
  boundaries: the ten-file touch set above; must-not-touch per
    Boundaries; builders never commit.
```

## Effort

Dispatched at the coordinator's default for this program's single-lane
entries (I54 precedent); no escalation keywords required — the contract
above is fully mechanical.

## PHASE 0 (builder discipline, unchanged)

Disagreements with this spec's letter go in the report's PHASE 0 section
with file:line evidence — never silent improvisation; builders never
commit; escalation via `build/loop/exception-*.md` only.

## Acceptance Criteria

# Acceptance Criteria — I55 paste-markers

Property-level, each independently judgeable. Gate-pass is necessary,
not sufficient — the architect reads the diff against BRIEF §8 and this
spec's letter before the verdict.

**AC1 — The editor paste registry and its marker ops (pi editor.ts
letter + the owner's one deviation).** A paste over the
`>10 lines OR >1000 chars` bar (strictly greater, over the FILTERED
text, JS-split counting) stores the full text in a registry
(ids contiguous 1..n, counter == size) and inserts ONLY the marker —
line form `[paste #1 +12 lines]` when >10 lines, char form
`[paste #1 1234 chars]` otherwise; smaller pastes splice inline
unchanged; the path-prefix space rule fires exactly on `/ ~ .`-leading
filtered text with an ASCII-`\w` char before the cursor;
`expanded_text` replaces every registry marker id-driven and
suffix-agnostically, with regex-danger content (`\1`, `\\`-shaped
bytes) expanding verbatim (block-form replacement only); backspace
over a valid marker deletes the whole span, drops the entry, and
renumers registry + every text marker (suffix preserved), while a
hand-typed marker deletes char-wise; forward delete removes a whole
valid marker span WITHOUT registry cleanup (pi's exact quirk);
deleting/creating marker ops undo as single units with the registry
restored; `set_text`/`clear` clear the registry after the snapshot
push; pasting again with a valid marker ending exactly at the cursor
replaces that marker with its full text inline (the owner's
sanctioned deviation), renumbers, then processes the new paste
normally — all unit-pinned (D8 floors: ≥12 multiline-editor tests,
≥3 undo tests).

**AC2 — The submit surface delivers the EXPANDED text everywhere
downstream.** Enter and busy alt+enter submit the expanded, trimmed
text: the agent run, the steer/follow-up queues and mirrors, the user
echo, history, and (by construction) the session recording and the
wire receive the full content; the marker string never reaches the
agent in any submit arm; `dequeue_queued_messages` still joins the RAW
editor text through `set_text` (a live marker dies as literal text,
registry cleared — pi :4753 parity); `Chat#input` and the autocomplete
seam stay raw. Unit-pinned (D8 floor: ≥4 chat tests) + live-pinned by
AC4's wire/session gate.

**AC3 — The rig instrument gains the paste/submit knobs without moving
the no-knob path.** `paste:` (validated String) sends a bracketed
paste before the prompt via `load-buffer`/`paste-buffer -p`;
`submit:` (default true) gates the Enter; `expected_requests` accepts
0 (negative still rejected); when no knob is set the runner sends
EXACTLY today's single `send-keys <prompt> Enter` call — proven by the
s1–s10 battery (AC5) and the knob unit tests (D8 floor: ≥3).

**AC4 — The two NEW scenarios pin display and wire/session.**
`s14_paste_marker_display` (paste-only, no submit, 0 requests): BOTH
apps' settled screens show the marker row `[paste #1 +12 lines]` and
NO pasted-content row, screens identical — RED-at-base by design
(Grounds §4.3). `s15_paste_marker_submit` (paste + Enter, 1 request):
BOTH apps' request 1 carries the EXACT 12-line pasted text as the user
content (pi's parts-array extracted shape-normally — the live-calibrated
I54-s12 precedent), zero marker bytes on the wire, the settled screens
show the expanded user echo with no marker row, and tart's session
JSONL records the expanded text with zero marker bytes anywhere
(backlog item f's pin). No existing scenario/golden/registry file is
touched.

**AC5 — The full no-regression battery, cold.** `bundle exec rake`
green; `SEAM_BENCH_OK`; rig s1–s10 exit 0; s1_tart's designed exit-1
arm green (`TART_MODE_OK`); both probes `--gate` OK; thinking-pins ≥
11+8 runs; hermeticity ≥ 8+4 runs; lock-deps `GEM_LOAD_OK`; zai-data
`ZAI_DATA_OK`; threads-budget clean vs `e61cb78`; wire-delta EXACT
(instruction `2faaf667…`, tools `7360fd1e…`, key order/store/max/
stream_options/messages as frozen at I52); session-golden 7/7 digests
EXACT.

**AC6 — Scope and frozen bytes.** The integrated diff vs `e61cb78` is
EXACTLY the 10 declared files (no more, none absent, non-vacuous); the
registry constants exist in editor.rb, the submit surfaces read
`expanded_text`, and the runner carries the bracketed-paste path
(presence greps — tripwires, never the proof); no existing
scenario/golden/fixture/registry file is touched.

```gates
- id: paste-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/editor_multiline_test.rb -n "/paste_marker|expanded_text|paste_over|path_prefix/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL paste registry pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 12 ] || { echo "FAIL paste pins runs=${runs:-0} (want >=12: both marker forms, both boundaries, path-prefix rules, expansion incl. regex-danger + hand-typed-id, paste-over arms, backspace renumber, hand-typed char-wise, fwd-delete span)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/editor_multiline_test.rb -n "/insert_paste/" 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL pre-existing insert_paste pins regressed ec=$ec2"; exit 1; }
    echo PASTE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PASTE_UNITS_OK

- id: paste-undo-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/editor_undo_test.rb -n "/marker/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL marker undo pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 3 ] || { echo "FAIL marker undo pins runs=${runs:-0} (want >=3: delete-then-undo restores registry, paste-over single undo unit, set_text clears + undo restores)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/editor_undo_test.rb -n "/paste/" 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL pre-existing paste undo pins regressed ec=$ec2"; exit 1; }
    echo PASTE_UNDO_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PASTE_UNDO_UNITS_OK

- id: submit-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/paste_marker/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL submit-surface paste pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL submit pins runs=${runs:-0} (want >=4: expanded submit, expanded follow-up queue, marker never reaches the agent, dequeue-restore raw pi-parity)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/multi_line_paste/" 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL pre-existing paste dispatch pin regressed ec=$ec2"; exit 1; }
    echo SUBMIT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBMIT_UNITS_OK

- id: rig-knobs
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb -n "/paste_knob|submit_knob|expected_requests_zero/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL rig knob pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 3 ] || { echo "FAIL rig knob pins runs=${runs:-0} (want >=3: paste parse/reject, submit default/false, expected_requests zero-accepted/negative-rejected)"; exit 1; }
    out2=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL full scenario_test regressed ec=$ec2"; exit 1; }
    echo RIG_KNOBS_OK
  expect:
    exit_code: 0
    stdout_match: RIG_KNOBS_OK

- id: s14-display
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s14_paste_marker_display.yml --out tmp/parity-gate-s14; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s14 rig ec=$ec"; exit 1; }
    ruby -rjson -e '%w[pi tart].each do |app|; cap = File.read("tmp/parity-gate-s14/run-1/#{app}.capture"); abort "#{app}: marker row missing from the editor display" unless cap.include?("[paste #1 +12 lines]"); abort "#{app}: pasted content leaked into the display" if cap.include?("line alpha one"); end; s = JSON.parse(File.read("tmp/parity-gate-s14/summary.json")); %w[pi tart].each do |app|; a = s["runs"][0]["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == 0; end; puts "S14_DISPLAY_OK"'
  expect:
    exit_code: 0
    stdout_match: S14_DISPLAY_OK

- id: s15-wire-session
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s15_paste_marker_submit.yml --out tmp/parity-gate-s15; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s15 rig ec=$ec"; exit 1; }
    ruby -ryaml -rjson -e 'expected = YAML.safe_load_file("gems/tui-split-rig/scenarios/s15_paste_marker_submit.yml", aliases: false).fetch("paste"); %w[pi tart].each do |app|; lines = File.readlines("tmp/parity-gate-s15/run-1/#{app}-requests.jsonl"); abort "#{app}: expected 1 request, got #{lines.size}" unless lines.size == 1; body = JSON.parse(lines[0])["body"]; user = body["messages"].reverse.find { |m| m["role"] == "user" }; abort "#{app}: no user message on request 1" unless user; content = user["content"]; text = content.is_a?(String) ? content : content.map { |p| p["text"] }.join; abort "#{app}: full pasted text not on the wire" unless text == expected; abort "#{app}: marker bytes leaked to the wire" if text.include?("[paste #"); cap = File.read("tmp/parity-gate-s15/run-1/#{app}.capture"); abort "#{app}: expanded user echo missing from the settled screen" unless cap.include?("line alpha one"); abort "#{app}: marker row survived submit on screen" if cap.include?("[paste #"); end; sess = Dir["tmp/parity-gate-s15/run-1/home/tart/.tart/sessions/**/*.jsonl"].sort_by { |f| File.mtime(f) }.last; abort "tart session file not found" unless sess; recorded = false; File.readlines(sess).each do |l|; j = JSON.parse(l); next unless j["type"] == "message" && j.dig("message", "role") == "user"; recorded = true if j.dig("message", "content") == expected; end; abort "session did not record the EXPANDED text" unless recorded; abort "session contains marker bytes" if File.read(sess).include?("[paste #"); puts "S15_WIRE_SESSION_OK"'
  expect:
    exit_code: 0
    stdout_match: S15_WIRE_SESSION_OK


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
    added=$(git diff e61cb78 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
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

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q "PASTE_MARKER_REGEX" lib/tart/render/editor.rb || { echo "FAIL: registry constants absent from editor.rb"; exit 1; }
    grep -q "expanded_text" lib/tart/render/chat.rb || { echo "FAIL: the submit surface never reads expanded_text"; exit 1; }
    grep -q "paste-buffer" gems/tui-split-rig/lib/tui_split_rig/runner.rb || { echo "FAIL: no bracketed-paste path in the runner"; exit 1; }
    ruby -e '
      expected = %w[
        lib/tart/render/editor.rb
        lib/tart/render/chat.rb
        gems/tui-split-rig/lib/tui_split_rig/scenario.rb
        gems/tui-split-rig/lib/tui_split_rig/runner.rb
        gems/tui-split-rig/scenarios/s14_paste_marker_display.yml
        gems/tui-split-rig/scenarios/s15_paste_marker_submit.yml
        gems/tui-split-rig/test/scenario_test.rb
        test/render/editor_multiline_test.rb
        test/render/editor_undo_test.rb
        test/chat_test.rb
      ].sort
      actual = `git diff --name-only e61cb78..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
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
