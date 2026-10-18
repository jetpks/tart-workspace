# spec-digest — I74 `session-sink` — TART-STANDALONE ENTRY 6 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
I74 builder/judge read the arch file; the next ITERATION's spec reads
this). Iteration `session-sink` (I74), ONE lane `core` (repo tart,
6-path touch set, effort medium). Frozen at `732f5103` (the
AC-establishing commit; bookkeeping `01803d3`), clean rehearsal stamp
`gates_digest
3f26505a4f32c39e8806d1c84f16ba17bdac062e692cd9bdaf3afb3c0e695771` @
`2026-10-18T01:30:10-06:00` in space.yaml, frozen region verified
byte-unchanged post-freeze.

## Base measurements (this session, cold, fresh — never predicted)

- `repos/tart` @ `8d81291` ("Merge lane/I73-child-env-scrub-core",
  tracked tree clean): FIRST full suite run hit the standing
  chat-interrupt **900 s gate-hang class** (note-and-pass, the frozen
  ledger); the COLD re-run → `bundle exec rake` → **1316 runs / 6237
  assertions / 0F / 0E / 1S, exit 0, 229.0 s** (identical to the I73
  integrate record); `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1`
  → `SEAM_BENCH_OK`. The suite gate ALSO ran green INSIDE the clean
  rehearsal (SUITE_OK). The flake fired once in three suite executions.
- The rehearsal regenerated the frozen SHORT out dirs `t74s1..t74s10,
  t74s17, t74s1t, t74tp, t74ub, t74wir, t74zwr, t74hwp, t74mot` +
  `tmp/render-perf-gate` — untracked scratch, self-owned by each gate's
  `rm -rf`; do NOT commit.

## The carry audit + rehearsal + freeze (exact mechanics)

- Carry audit BEFORE rehearsal: `tmp/i74-spec/audit-gates.py` (python;
  extracts both ```gates fences, applies the DECLARED rebases, splits on
  `- id:`, byte-compares) → **AUDIT_OK 74 gates: 69 carried
  byte-identical after the declared rebases, 1 declared drop (scope,
  rewritten), 4 new (session-sink-config-units, -projection-units,
  -engine-e2e, -child-e2e), zero drift, zero undeclared drops.**
- Declared rebases: `t73*`→`t74*` out-dir family,
  `tmp/i73-unused`→`tmp/i74-unused`, mktmpdir prefixes `i73-*`→`i74-*`
  (`i65-foot-`/`t70rs-` carry as-is, the I73 precedent), and the ONE
  semantic-bearing rebase: `threads-budget` diff base `ff235e4`→`8d81291`
  PLUS the pathspec exclusion `':(exclude)lib/tart/session_sink.rb'` —
  the ONE new sanctioned `Thread.new` site (the sink's flusher). Carried
  gates keep their origin `ac:` labels verbatim; mapping declared in the
  AC preamble (carried members → I74 AC5, except suite/bench → AC6).
- Rehearsal #1 (commit `732f5103`) was CLEAN ON THE FIRST RUN: **GREEN
  69 / RED 5 / BROKEN 0 / EMPTY 0** — the REDs are EXACTLY the frozen
  designed-RED vector, every one verified for the right reason in the
  transcript (the 4 new gates: `runs=0 … filter empty, declared-new` —
  the module/tests do not exist at base; `scope`: session_sink.rb
  missing = the must-differ leg). s9-parity GREEN at canonical depth
  (the checkout), herdr-wire-probe GREEN (the ~74-char class, socket
  path ~92 bytes < the 104-byte sun_path bound).
  Transcript: `build/rehearse/I74-session-sink-20261018T013010.369997.md`.
- `architect freeze session-sink` accepted BARE (no --skip-rehearse):
  **freeze_sha `732f51030a88eb5c3fcc23f5792a2391db723b37`**, bookkeeping
  commit `01803d3` (space.yaml: freeze_sha, lanes [core / tart / 6-path
  touch set], rehearsal stamp). Embedded `-e '…'` bodies were
  apostrophe-scanned BEFORE rehearsing (the I73 lesson) — zero hits.

## Builder Prompt provenance

NONE assembled in this spec session — per the committed successor
protocol (the I72/I73 precedent), the COORDINATOR provisions, copies the
lane prompt to `build/I74-session-sink-core/prompt.md`, and appends the
Builder Prompt section at dispatch. The section remains a template. The
arch file's frozen sections were assembled from scratch sources:
`tmp/i74-spec/grounds.md` (→ commit `fed0676`),
`tmp/i74-spec/specification.md` (→ `f99a284`),
`tmp/i74-spec/acceptance-criteria.md` (prose + the 74-gate fence built
from `gates-carried.yaml` + `gates-new.yaml` + `gates-scope.yaml` →
`732f5103`). The authoritative contract is
`architecture/I74-session-sink.md` (the builder executes gates
mechanically from the arch file — the I69 self-copy-defect lesson).

## The headline spec decisions (frozen in the arch file, one-line reasons)

- **The projection is REAL WORK, not `to_h` verbatim** — tart's
  `Agent::Message#to_h` content is a raw String (the recorded empirical
  shape) while the deck's parser walks `content` as a TYPED BLOCK ARRAY
  (a String "block" yields `block["type"]` nil → NO text delta → the
  text would be LOST). The sink PROJECTS: user/assistant into
  `[thinking?, text?, toolCall…]` blocks, usage flat→camelCase four-key
  (never fabricated totalTokens/cost), stopReason stop→end_turn /
  tool_calls→toolUse / length→maxTokens / else verbatim. Evidence: the
  deck's own fixtures (`test/fixtures/files/pi_streaming_session.jsonl`
  in the sibling space) + `normalizer/pi.rb`.
- **Config namespace**: file `~/.tart/session-sink.json` (tart's OWN
  home, the architect ruling — never `~/.pi`); env overrides
  identity-namespaced via `Identity.env_key` (`TART_SESSION_SINK_*`
  default; `PI_SESSION_SINK_*` under pi identity, byte-matching pi's own
  extension spellings). Env beats file both ways (disabled: ANY present
  env value decides). Malformed/absent/disabled = fully inert.
- **Agent headers for children WITHOUT touching the child LLM wire**:
  pi-subagents tags child prompts (`<active_agent name="X"/>`); tart
  has NO tag (grep-verified) and ADDING one would move the child wire
  (the entry's own wire-untouched floor forbids it). The tart-native
  seam: the subagents manager plumbs
  `<IDENTITY>_SESSION_SINK_AGENT_NAME` (run label) +
  `<IDENTITY>_SESSION_SINK_PARENT_SESSION_ID` (live parent recorder id)
  into child_env; the sink resolves tag-first, env-second, omits
  otherwise. Role = name sans a leading `architect-`.
- **X-Parent-Session-Id resolution** (lazy at first POST): (1) the
  recorder file header's `parentSession` path → first-line id →
  `_<uuid>.jsonl` filename fallback; (2) the env plumbing pick; (3)
  omitted. NO hooks-context change needed (the boot emissions are
  byte-unchanged). Residual declared: a resumed session that never
  turns omits the header (harmless metadata).
- **NO MOTD row** (ruled + pinned): the sink is silent ambient capture
  (the deck contract's own no-noise discipline); herdr got a row
  because it is owner-visible pane state. `lib/tart/render/` is
  hard-frozen by the scope gate — the ruling is mechanically enforced
  plus a `bin/tart` grep leg in the config gate.
- **Engine**: herdr.rb shape — ONE flusher Thread (Mutex +
  ConditionVariable), enqueue-only handlers, coalescing debounce
  (first-pending sets due), queue-cap overflow drops OLDEST loudly,
  retry ≤ 3 attempts [500,1000] backoff, success = HTTP **202**
  (verified in the deck action: `render_json(res, json, status: 202)`),
  Net::HTTP (stdlib, no new gems), terminal one-shot POST
  (SHUTDOWN_POST_TIMEOUT 2 s, no retry) still opening with the session
  record, total shutdown ≤ ~3 s. Loss lines: `session-sink: …` on
  stderr, ≤ 1 per capture in TUI (the port has no ui.notify surface —
  declared deviation from pi's notify-then-stderr ladder), token NEVER
  in text.
- **Boot wiring**: register beside `Herdr.register` in BOTH boots;
  `session_shutdown` reason "quit" emitted post-`kernel.run` (TUI,
  bin/tart :553) and post-drain pre-`exit` (print, :344-357); the chat
  surface's event case has no `:session_shutdown` arm (ignored —
  verified).
- **Seed counting counts the PORT's role spelling `tool`** (pi counts
  `toolResult` — the port's recorded byte family uses `tool`;
  declared adaptation), custom_message/compaction never counted,
  over-count safe.

## Repo seams touched / discovered

- `repos/tart`: UNTOUCHED at `8d81291` (this was a spec session; the
  builder lane owns the 6-path set: `lib/tart/session_sink.rb` NEW,
  `bin/tart`, `lib/tart/subagents/manager.rb`,
  `test/session_sink_test.rb` NEW,
  `test/support/mock_ingest_server.rb` NEW, `test/subagents_test.rb`).
- Sibling space `~/architect/spaces/20261014-all-fax-no-printer` was
  read READ-ONLY (session-sink.ts, ingest.rb, normalizer/{pi,event}.rb,
  the pi-stream fixtures, app/actions/conversations/ingest.rb) — never
  written.
- Discovered seams (cited in the Grounds for the builder):
  `agent/loop.rb` event inventory (user message_end at :875-880, error
  assistant at :737, tool message_end at :976 SKIP-worthy, tool exec at
  :981), `agent/chat.rb` result_content law (:~285) + after_tool_result
  (:268) + error_tool_result returns BEFORE hooks (no event), message
  `to_h` shapes (message.rb:122-215), `ToolCall`/`Tokens`/`Thinking`
  Structs (message.rb:10-24, constructible in tests), hooks.rb plain-
  channel containment (per-handler StandardError swallowed), bin/tart
  register sites (:291 print, :425 tui) + quit sites (:357, :553),
  manager child_env pick pattern (:370-418) + current_session_path
  (:355-366).
- Space repo: `architecture/I74-session-sink.md` (frozen region
  read-only after `732f5103`), space.yaml I74 record. Scratch:
  `tmp/i74-spec/` (grounds.md, specification.md,
  acceptance-criteria{,-prose}.md, gates-carried/new/scope.yaml,
  build-carried.py, audit-gates.py).

## House conventions the next spec must honor

- Carry-audit BEFORE every rehearsal; freeze ONLY on a fresh clean
  rehearsal stamp; any gates-byte edit invalidates the stamp. The next
  spec carries the I74 74-gate block (69+5 designed-RED→landed: after
  I74 lands, the 4 session-sink gates + scope become carried/rewritten
  — remember the threads-budget exclusion for `session_sink.rb` now
  STANDS and must be kept while re-basing the diff base to the new
  tip).
- The architect-CLI env scrub from bundle-exec'd contexts is MOOT since
  I73 — retained only on observed poison.
- Short out dirs (≤ ~10 chars rel tart root), each gate owns its
  `rm -rf`; oracle is ENVIRONMENT (`repos/pi` @ oracle-v1.1.0, never
  write under it, `env -u PI_PACKAGE_DIR` for direct execs); judge runs
  gates at the LANE tree.
- Embedded `-e '…'` gate bodies: NO apostrophes (grep before
  rehearsing). Standing flake classes: `chat_test.rb:1613`
  interrupt-timing BOTH forms (fired once this session as the 900 s
  hang — cold re-run green); `render_perf_test.rb:265` spinner-dwell.
- Itemize-and-defend: the builder's gate table carries EVERY frozen
  gate (74/74) with a measured one-liner; an absent gate is
  REJECT-class.
- Lane-tree geometry pre-declarations stay in the AC preamble: the
  I75-lane name length decides the s9/herdr-wire-probe expectations;
  the owner-backlog re-freezes (s9 out-dir rebase, herdr socket-path
  law, wire-delta constant) are NOT loop work.
- No inline long payloads in any subagent call; briefs land as
  committed files first.

## Known unknowns (for the judge / next spec)

- **Parity scenarios vs a really-configured shell**: the rig stages
  clean HOMEs, so the sink is inert in every parity scenario — but if
  the owner ever exports `TART_SESSION_SINK_HOST` in the interactive
  shell that runs the rig, the rig's tart panes would stream to the
  real deck (env pass-through). The file-based config (the expected
  owner form) is immune (staged HOME). Not gate-addressable without rig
  edits (forbidden); recorded for adjudication awareness.
- The mock ingest server (test support) asserts 202-expected,
  well-formed POSTs only; the LIVE deck (real host + token) is the
  owner's named post-landing checkpoint — nothing in the loop POSTs
  anywhere but 127.0.0.1 test servers.
- The driven-boot E2E (`/boot/` filter) boots real `bin/tart -p`
  processes against localhost mocks — ~1-2 s per leg; the child-capture
  leg spawns a REAL subagent child (the subagents_test pattern) — both
  are slow-but-hermetic; if the judge machine is loaded, the bounded
  waits in the tests may need the standing cold-re-run discipline.
- The terminal flush blocks the boot exit ≤ ~3 s (synchronous, frozen
  tuning) — a dead deck host still exits bounded (Net::HTTP open/read/
  write timeouts); pinned in the `/engine/` tests at tuned constants.
- `parentToolCallId` has NO emitter today (projection-ready, pinned);
  if nested tool calls ever exist, the projection already carries the
  field.
