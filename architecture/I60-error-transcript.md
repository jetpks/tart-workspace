# I60: error-transcript

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

ENTRY B of live-run fixes rev4 (notes/plan-20261014T195224Z.md — ENTRY A
closed by I59). Base `24e89ba` (I59's integrated tip on project/pi-port,
verified clean this session). Serial after I59 — this entry owns
agent/loop.rb's error arm; I59 touched its boot/switch arms only. The
oracle is the space-pinned shim (`bin/pi` → repos/pi @ f1b2e77f, 1.1.0);
every rig invocation below ran with `<space>/bin` first on PATH and
PI_*/TART_* scrubbed (the standing environment directive).

### 1. The defect (measured this session, offline, mock)

The owner's failing live session (the plan's exhibit): an API failure
that kills a turn leaves NO trace in the session jsonl — the file holds
exactly two lines (header + user message); `--resume` shows a clean
session with a dangling user turn. Reproduced against BOTH apps at base
with the rig (scenario `tmp/i60-spec/s18_error_base.yml` in the space —
one scripted HTTP 400 on the first request, `replay: true`; artifacts
archived `repos/tart/tmp/i60-spec-base/`, gitignored):

- pi settles `[hello, blank, blank, " Error: 400: {json}", " If this
  looks like a pi bug, /bug sends a report…"]` live; its session file
  holds SIX lines whose last is `{type: "message", …, message:
  {role: "assistant", content: [], …, stopReason: "error",
  errorMessage: "400: {…}", …}}`; its resume (`--continue`) renders
  `hello` + the error row again.
- tart settles `[hello, blank, "error: 400: …"]` live (the unpadded,
  lowercase agent_end scrollback line); its session file holds TWO
  lines (header + user); its resume (`-r`) renders `hello` +
  `Resumed session` — no error anywhere.

Both apps made exactly ONE request (pi's auto-retry does not fire for a
plain 400 — "400" is absent from RETRYABLE_PROVIDER_ERROR_PATTERN,
pi-ai utils/retry.ts:30-56; enabled/maxRetries defaults are irrelevant
here).

### 2. pi's contract (why pi records it)

- The stream layer NEVER throws for request/model failures — the
  StreamFn contract (packages/agent/src/types.ts:26-33): failures are
  encoded as a final AssistantMessage with `stopReason "error"` +
  `errorMessage`. openai-completions.ts:707-731 is the live arm: the
  catch sets `output.stopReason = "error"` (content = whatever blocks
  streamed, `[]` pre-stream) and `output.errorMessage =
  formatProviderError(normalizeProviderError(error))` (utils/
  error-body.ts:128-140 — `"<status>: <body>"`, the openai SDK message
  carrying the raw body).
- agent-loop.ts streamAssistantResponse :443-468: the `done`/`error`
  case takes the stream's final message; when NO partial was added
  (pre-stream failure — no `start` event ever fired) it emits
  `message_start` with the FINAL error message, then `message_end` —
  so a pre-stream 400 still gets message_start + message_end.
- Persistence is the generic message_end arm: agent-session.ts
  :1144-1163 → `sessionManager.appendMessage(event.message)` — ANY
  assistant message, including the failure message, lands as a
  SessionMessageEntry (session-manager.ts:1204-1215) whose `message`
  carries `stopReason`/`errorMessage` verbatim (the measured pi file
  above). The loop then returns through turn_end/agent_end carrying
  the failure message (agent-loop.ts:245-256).
- A SECOND, older arm exists for executor-level throws:
  agent.ts:532-548 `handleRunFailure` — synthesizes `{role:
  "assistant", content: [{type:"text",text:""}], usage: EMPTY_USAGE,
  stopReason: "error", errorMessage: error.message, timestamp}` and
  runs it through message_start + message_end + turn_end + agent_end
  (types.ts:31 documents the contract). Same persistence, same render.
- Render (assistant-message.ts:184-198): an assistant message with
  `stopReason === "error"` and no tool calls appends `Spacer(1)` +
  `Error: ${errorMessage}` in `error` fg (after any partial content);
  `stopReason === "aborted"` renders the abort message; `=== "length"`
  renders "Response was truncated before completion." — this one
  component serves live AND replay (resume renders through
  renderSessionEntries → the same component).
- The interactive agent_end arm renders NO error text — it only clears
  the status indicator and drops the streaming component
  (interactive-mode.ts:3653-3668); the error row comes from the
  assistant component at message_end. The separate muted
  `If this looks like a pi bug, /bug sends a report to the developers.`
  row (interactive-mode.ts:2168-2179 suggestBugReport, fired from
  maybeSuggestBugReport :2181-2186 for non-retryable errors, once per
  session) is the /bug machinery's surface — it does NOT re-render on
  resume (a live-session flag).

### 3. tart today (why the file never hears about it)

- step_on_reactor's rescue ladder (lib/tart/agent/loop.rb:667-694):
  `rescue Async::Cancel` re-raises (the interrupt arm), `rescue
  Fast::Completions::CancelledError` returns nil (defensive), `rescue
  StandardError => e` → `record_terminal_error(e)` — the gem RAISES
  API errors (Fast::Completions §8; Chat#step has no error rescue —
  chat.rb:208-237), so the loop's rescue IS the failure boundary.
- record_terminal_error (loop.rb:684-689) sets `@last_error` and emits
  `message_end` only `if message&.role == :assistant` — `@last_message`
  was nil'd at step entry (loop.rb:668) and only a COMPLETED step sets
  it, so a pre-stream OR mid-stream API failure emits NOTHING; the
  error rides turn_end/agent_end only (stopped_on_error?, loop.rb
  :691-695).
- The recorder persists ONLY through `record(message)` →
  `Recorder#append_message` (session.rb:429-443, called from
  handle_item's :step arm and add_user_message — loop.rb:406-415,
  :807-818). No message, no entry — the file keeps the dangling user
  turn. `agent/session.rb` itself needs NO change: append_message
  serializes `Message#to_h` generically; the missing piece is the
  failure MESSAGE, not recorder plumbing (the plan's "recorder seam"
  phrasing resolves to the recording CALL SEAM in loop.rb, not a
  session.rb edit).
- Render: the surface's agent_end error arm (render/chat.rb:622-626)
  enqueues the unpadded lowercase `error: <msg>` scrollback line +
  finalizes pending tool blocks; replay_assistant (render/
  transcript.rb:711-744) returns early unless content/thinking/tool
  calls exist — an error entry would render nothing today even if it
  existed.

### 4. Facts that shape the design (all verified this session)

- The gem's codec SKIPS empty assistant messages on the wire
  (fast-llm codec.rb wire_assistant tail — pi openai-completions.ts
  :1394-1402 verbatim, "This handles aborted assistant responses that
  got no content"): seeding the failure message into the chat history
  is WIRE-NEUTRAL by pi's own rule. Measured corollary: the overflow
  retry pin `assert_equal %w[user user], retry_payload roles`
  (agent_loop_test.rb:1404) HOLDS with the failure message seeded.
- Message#to_h's recorded assistant shape (agent/message.rb
  assistant_to_h) is the frozen byte family; `finish_reason` is the
  recorded stop-reason key (String spellings pass through
  normalize_finish_reason — "error" needs no map entry). `error_message`
  is a NEW key that rides ONLY when present — no existing recorded
  byte moves.
- from_seed_hash (message.rb) reads declared fields only — a resumed
  failure message seeds as content ""/finish_reason "error";
  error_message stays display-side (replay renders from the RAW entry
  hash, not the seeded Message — transcript.rb:659+).
- compaction.rb:194-198's comment premise ("a recorded finish_reason
  never carries aborted/error") becomes stale under this iteration —
  assistant_usage's nil-tokens guard already skips the failure message
  (pi getAssistantUsage's error-skip, equivalent net).
- The mock ALREADY scripts `{type: :error, status: 400, message: …}`
  (test/support/mock_llm_server.rb:189-196, respond_error writes the
  openai-shaped `{error: {message, type}}` body) and the rig hands
  scenario `responses` verbatim to it (scenario.rb:90-96) — the s18
  scenario needs NO mock/runner change; the `replay:` knob (I57) is
  the resume instrument.
- Measured pi-vs-tart divergences that will NOT close this iteration
  (both pinned as registry classes + itemized): the error-message TAIL
  (pi keeps the raw JSON body via the SDK message; the gem's frozen §8
  extracts `error.message` — "400: The max_tokens parameter is
  illegal." vs pi's "400: {json}"), and pi's /bug hint row (the port
  cuts the /bug machinery; rendering a hint for a nonexistent command
  would lie — the plan's scope is "the error row").

### 5. Open questions (judge)

- OQ-1: the two new s18 registry classes (`error-transcript-row-tail`,
  `pi-bug-report-hint`) — ratify as sanctioned divergences (the gem's
  frozen §8 formatting; the /bug cut) or order more (a gem error-format
  change is OUT of scope here; the hint row could be ported as a dead
  hint on owner demand).
- OQ-2: the abort path (escape/ctrl+c interrupt) stays divergent — pi
  records the partial + `stopReason "aborted"` message (the stream's
  abort catch) and renders "Operation aborted"; tart's Async::Cancel
  arm records NOTHING (the D3 cancel conversion eats the partial at
  the gem seam — no message object survives to record). Declared
  out-of-scope divergence, reopenable on owner pain (backlog
  candidate: a cancel-carrying partial would need gem cooperation).
- OQ-3: pi's `stopReason === "length"` row ("Response was truncated
  before completion.") stays unported (pre-existing, unpinned,
  orthogonal to the error row; backlog candidate with the length
  family).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section error-transcript specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision error-transcript`
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
`architect rehearse error-transcript` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze error-transcript` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse error-transcript` — before the freeze, while
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
subsection per lane. A copy is written to build/I60-error-transcript-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section error-transcript prompt --append --lane <lane> --from build/I60-error-transcript-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I60-error-transcript-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence error-transcript --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section error-transcript verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify error-transcript`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
