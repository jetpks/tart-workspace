# I74: session-sink

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 6 —
  `session-sink`. Coordinator deltas at dispatch (authoritative,
  `notes/briefs/i74-spec-task.md`): base = `repos/tart` @ **`8d81291`**
  ("Merge lane/I73-child-env-scrub-core", the I73 integrate tip, tracked
  tree clean). Entries I69 (tart-identity-herdr), I70
  (subagents-default-on), I71 (model-catalogue), I72
  (markdown-parity-revisit) and I73 (child-env-scrub) have LANDED — their
  behavior is baseline (default identity TART; subagents default-on with the
  rig staging the opt-out on every parity path; the vendored catalogue +
  live listing; the 48-case markdown battery; the ChildEnv scrub at every
  spawn seam).
- **The I73 env-scrub workaround is MOOT** (coordinator delta): the
  standing `env -u RUBYOPT … architect …` prefix is no longer required for
  architect-CLI calls from bundle-exec'd contexts — retain it only if a
  poisoned parent is observed in practice.
- **Measured base suite THIS session (fresh, cold, never predicted):** the
  first full run hit the standing chat-interrupt 900 s gate-hang class
  (note-and-pass per the frozen ledger); the COLD re-run →
  **1316 runs / 6237 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0, 229.0 s wall** (identical to the I73 integrate record), plus
  `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
  **`SEAM_BENCH_OK`**. This is the frozen regression floor.
- **Owner-backlog residuals NOT re-litigated here** (coordinator delta):
  the s9 frozen gate form's deep-tree out-dir geometry and the
  herdr-wire-probe 105-byte unix-socket path geometry. The lane-tree
  pre-declarations in the AC preamble carry their standing classes.
- The observation deck (the mouth's server) is a SIBLING SPACE on this
  disk: `~/architect/spaces/20261014-all-fax-no-printer` —
  `repos/pi-extensions/session-sink.ts` (THE contract reference) and
  `repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb` +
  `lib/space/server/normalizer/pi.rb` (the parser) are read there
  READ-ONLY this session; nothing was written into that space.

### The mouth contract (frozen at I08 on the deck side — cited, not restated)

- `repos/pi-extensions/session-sink.ts` (read line-by-line this session):
  - tuning (:29-40): `QUEUE_CAP 2000`, `DEBOUNCE_MS 250` (frozen ceiling
    ≤ 500 ms), `POST_TIMEOUT_MS 8000`, `MAX_ATTEMPTS 3`,
    `RETRY_BACKOFF_MS [500, 1000]`, `SHUTDOWN_WAIT_MS 1000`,
    `SHUTDOWN_POST_TIMEOUT_MS 2000` — total shutdown work ≤ ~3 s.
  - config (:50-90): `~/.pi/agent/session-sink.json`
    `{host, token, disabled}` + env overrides evaluated per field (env
    beats file both ways — for `disabled` ANY present env value decides:
    `"1"`/`"true"` mutes, any other present value unmutes); unreadable or
    malformed file = `{}` = unconfigured: inert and silent.
  - record ids (:185-190): content records `"<session-id>/<n>"`, n
    monotonic per session ACROSS rebinds, seeded at bind from the session
    file (count the entries the sink would emit; over-count safe,
    under-count not).
  - record projection (:221-240): `message_end` for roles user/assistant
    ONLY; `tool_execution_end` for every tool call incl. nested
    (`parentToolCallId`); the session record opens EVERY body (re-sent
    session records resolve to the same conversation — metadata no-op
    server-side); everything else skipped.
  - headers (:505-513): `Authorization: Bearer <token>`,
    `Content-Type: application/x-ndjson`, optional `X-Space-Slug`,
    `X-Parent-Session-Id`, `X-Agent-Name`, `X-Agent-Role`, and
    `X-Session-Complete: true` on the terminal POST (one-shot, no retry).
  - containment: enqueue-only handlers, ≤ 1 in-flight POST, order
    preserved, every failure caught, nothing thrown into the host;
    unconfigured/disabled = fully inert (zero queueing, zero network, no
    log noise); the token NEVER appears in any URL or error text.
- Server side (same space): `ingest.rb` — first record must be
  `{"type":"session", …, "version": N}` (`Normalizer.select` keys on
  `type == "session" && key?("version")`); find-or-create by session id;
  per-record idempotency on the top-level `id`; terminal header → status
  completed + one-shot terminal frame; **success = HTTP 202**
  (`app/actions/conversations/ingest.rb:39 render_json(res, json, status:
  202)`).
- `normalizer/pi.rb` (the parser the projection must satisfy):
  `message_end` is the SOLE source of message content; the assistant's
  `content` is walked as an ARRAY of typed blocks — `{"type"=>"text"}` →
  text_delta, `{"type"=>"thinking"}` → thinking text_delta,
  `{"type"=>"toolCall"}` (BLOCK_TYPES maps `toolCall`/`tool_use`) →
  tool_use block_open + args; `usage`, `model`, `stopReason` pass through
  (`STOP_REASONS` maps `stop`→end_turn, `toolUse`→tool_use,
  `max_tokens`→max_tokens, unknown verbatim-to-sym); `tool_execution_end`
  supplies tool_result from `result["content"]` (Array of text blocks or a
  plain String), `isError`, keyed by `toolCallId`.

### The projection is REAL WORK — measured this session (the key Grounds finding)

- The deck's own fixtures pin pi's actual `--mode json` bytes
  (`repos/all-fax-no-printer/test/fixtures/files/pi_streaming_session.jsonl`):
  a user message_end is
  `{"role":"user","content":[{"type":"text","text":"…"}],"timestamp":<epoch-ms>}`;
  an assistant is `content` blocks `[{"type":"thinking","thinking":"…","thinkingSignature":"…"},
  {"type":"text","text":"…"}, {"type":"toolCall","id":"…","name":"…","arguments":{…}}]`
  plus `api/provider/model/usage{input,output,cacheRead,cacheWrite,totalTokens,cost}/stopReason/timestamp`;
  a tool_execution_end is
  `{"toolCallId":"…","toolName":"…","result":{"content":[{"type":"text","text":"…"}]},"isError":false}`.
- tart's `Agent::Message#to_h` (message.rb:122-215, the recorded
  empirical shape) carries `content` as a **raw String** (BRIEF-recorded:
  "content is String or nil only"), tool calls as a separate
  `tool_calls` Hash, usage as FLAT `input_tokens`/`output_tokens`/… keys.
  A verbatim `to_h` projection would LOSE the deck-extracted text:
  `content_block_events` walks `Array(content)` → one String "block" →
  `block["type"]` nil → block_open with an unmapped type and NO text
  delta. **Consequence frozen into this spec: the sink PROJECTS the port's
  Message into pi's block shape (the law in the Specification) — it does
  not serialize `to_h` verbatim.**
- The stop-reason vocabulary also maps (port recorded spellings → pi
  stopReason): `stop`→`end_turn`, `tool_calls`→`toolUse`,
  `length`→`maxTokens`, everything else verbatim (`error` stays `error`).
  The port carries no pricing layer (BRIEF §2 house style; recorded
  convention: nothing reported persists nothing) → `usage` maps the four
  reported facts only, NEVER a fabricated `totalTokens`/`cost`.

### The event surface the sink observes (measured at `lib/tart/agent/loop.rb`)

- The loop emits eleven types through the hooks seam; the sink subscribes
  exactly THREE channels: `session_start` (bind), `message_end`
  (project user/assistant; skip `:tool` — emitted at :976 for tool
  messages — `:custom` at :905, `:system`), `tool_execution_end` (:981,
  payload `{tool_call:, result:, duration:}`; `tool_call` is the
  `Tart::Agent::ToolCall` Struct id/name/arguments/details).
- The user message_end fires at `add_user_message` (:875-880); the
  assistant at :763 (and the error assistant at :737 — role :assistant,
  projected like any assistant, `finish_reason "error"`); user events the
  recorder persists synchronously right AFTER the emit — the session file
  exists by the first debounced POST (the parent-id law depends on this).
- The tool result contract (chat.rb:262-290): `result` is the tool's raw
  return — a String (verbatim) or a Hash (failures carry
  `{"error" => "…"}`; `result_content` JSON-generates Hash/Array);
  `error_tool_result` (tool-not-found) returns BEFORE the hooks fire —
  no event, nothing for the sink. `isError` is therefore derivable ONLY
  from the result shape: a Hash carrying a truthy `"error"` key.
- The recorder (agent/session.rb `Recorder`) is DO-NOT-TOUCH (the plan's
  constraint; enforced mechanically by the scope gate hard-freezing
  `lib/tart/agent/session.rb`): the sink reads `recorder.id` /
  `recorder.path` ONLY through the hooks context's session ref
  (`{"agent_session_path" => …, "agent_session_id" => …}`, bin/tart
  :637-643). Session-file bytes are the session-golden guard's.

### The seams (cited)

- `lib/tart/hooks.rb` — the I47 seam: plain-channel handlers get
  registration-order dispatch with per-handler StandardError swallowed
  (the containment is structural), the event then forwards UNCHANGED to
  the base sink; `session_start`/`session_shutdown` are plain channels.
- `lib/tart/herdr.rb` — the native-module precedent: env-gated,
  inert-when-off, dedicated sender `Thread` + Mutex/ConditionVariable
  drain, every failure swallowed. The sink mirrors the shape (config
  resolved per bind instead of per boot — the config FILE can appear
  mid-process).
- `bin/tart` — the register sites: print boot :285-299 (Hooks built,
  Memory/Herdr registered, `session_start` emitted at :298; the post-run
  drain at :344-356 runs BEFORE `exit code` at :357 — the quit emission
  point); TUI boot :416-494 (Hooks built at :418, registers :424-425,
  `quit: -> { kernel.stop! }` at :529, `kernel.run` returns at :553 — the
  quit emission point).
- `lib/tart/subagents/manager.rb` — child spawn: `spawn_argv_and_env`
  (:345-352) + `child_env` (:370-418; I73: pick source
  `ChildEnv.scrub(@env.to_h)`, CLOSED env, `unsetenv_others` at the
  :176 spawn; the identity picks ride `Identity.env_key(@identity, …)`;
  the live parent recorder is reachable via the `@agent` callable
  (`current_session_path` :355-366)). Each `bin/tart -p` child is a FULL
  tart boot — it reads its own config from its own HOME (the child env
  carries HOME) and its own identity (`TART_IDENTITY` literal).
- `lib/tart/identity.rb` — the env-prefix law (I69): the app env
  namespace follows the resolved identity (`env_key("pi","X")` →
  `PI_X`, `"tart"` → `TART_X`). The architect ruling (plan ENTRY 6):
  **tart's own namespace, NOT ~/.pi** — the config FILE is
  `~/.tart/session-sink.json` (tart's own home, the recorder's
  `default_root` convention), and env overrides are
  identity-namespaced per this law (`TART_SESSION_SINK_*` under the
  default identity; byte-matching pi's own `PI_SESSION_SINK_*` spellings
  when the identity is pi). The bearer token is shared per user (the
  same token value pi's own sink would carry).
- pi-subagents tags every agent child's system prompt
  (`<active_agent name="X"/>`, child-launch.js:208) — the deck contract
  resolves agent headers from that tag. tart's child prompts carry NO
  such tag today (grep-verified: no `active_agent` in `lib/` or `bin/`),
  and ADDING one would move the child LLM wire — forbidden by this
  entry's own regression floor (wire-delta green). The tart-native
  equivalent: the subagents manager PLUMBS the agent label + the parent
  session id into the child env (identity-namespaced sink keys); the
  sink resolves agent headers from the prompt tag when present, else the
  env plumbing, else omits the headers. This closes the pi extension's
  known boundary natively: foreground subagent children never load
  ambient extensions (pi-subagents design), but tart's children ARE tart
  boots — the sink registers in them like any print boot.

### Standing environment (carried, updated for the I73 landing)

Oracle: the pinned `repos/pi` clone @ v1.1.0 (branch `oracle-v1.1.0`) is
ENVIRONMENT guarded by `oracle-pin-state` — never re-performed from a
lane; `env -u PI_PACKAGE_DIR` for every direct oracle exec; the judge
runs gates at the LANE tree; scenario out dirs stay SHORT (≤ ~10 chars
rel the tart root); carry audit BEFORE every rehearsal; freeze ONLY on a
fresh clean rehearsal stamp. The architect-CLI env scrub from
bundle-exec'd contexts is MOOT since I73 (retain only on observed
poison). Routing rides `architect.yaml` as-is; the model-window tick is
DEAD. Landing is the human's.

### Prior handoffs

`notes/spec-digest-20261018T052855Z-child-env-scrub.md` (I73 — the
carry-audit/rehearsal/freeze mechanics, the no-apostrophes `-e` lesson,
the short-out-dir law, the flake ledger, the successor protocol:
coordinator owns the prompt copy at dispatch);
`notes/briefs/i74-spec-task.md` (the coordinator deltas: base, the moot
scrub, the sibling-space grounds, the owner-backlog exclusions); the I73
Verdict for the standing lane-tree geometry classes (s9 wrap,
herdr-wire-probe socket path) — NOT re-litigated here.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section session-sink specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision session-sink`
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
`architect rehearse session-sink` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze session-sink` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse session-sink` — before the freeze, while
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
subsection per lane. A copy is written to build/I74-session-sink-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section session-sink prompt --append --lane <lane> --from build/I74-session-sink-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I74-session-sink-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence session-sink --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section session-sink verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify session-sink`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
