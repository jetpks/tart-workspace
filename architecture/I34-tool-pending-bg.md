# I34: tool-pending-bg

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I34 tool-pending-bg

1. **The divergence (BRIEF §8 settled-screen program; the port half of the I26 rig finding).** pi renders the RUNNING tool call's block immediately, painted with the `toolPendingBg` background; tart enqueues nothing until `:tool_execution_end`, so mid-flight frames show no tool rows at all. Measured by the I26 rig lane (merged `fcf232f4`): `gems/tui-split-rig/bin/tool-pending-probe` + `scenarios/probe_tool_pending.yml` drive both apps through one slow bash call (`sleep 6`, mock LLM) and capture numbered frame pairs DURING the execution — 17 frames/app at 0.5 s cadence. Verbatim evidence (I26 rig report): pi mid-flight frames 02–12 show the `$ sleep 6` row with bg SGR `48;2;52;56;58` = #34383a (`toolPendingBg`, dark.json:36 okhsl(229 5% 24%)); raw styled bytes `` [1m[38;2;222;224;225m$ sleep 6[0m[48;2;52;56;58m `` (bold, fg #dee0e1 = `toolTitle`); tart mid-flight shows NO tool rows; both apps at settle show exactly one block, the row re-appearing under `48;2;37;65;49` = #254131 (`toolSuccessBg`). **The probe's frames are the spec** — the port must show the call row mid-flight under #34383a and exactly one settled block under the result bg.

2. **pi's mechanism (source-verified this session).** `ToolExecutionComponent` (packages/coding-agent/src/modes/interactive/components/tool-execution.ts) is constructed when the call first appears in the streamed message or at `:tool_execution_start` (interactive-mode.ts:3532, :3611) and added to the chat container immediately; `contentBox`/`contentText` are created with `theme.bg("toolPendingBg", …)` (:90-91). `updateDisplay()` (:271-277) picks the bg by state: `isPartial` → `toolPendingBg`, else `isError` → `toolErrorBg`, else `toolSuccessBg` — so mid-flight the block is the call rows alone (no result yet) under the pending bg; at `tool_execution_end` the SAME component mutates in place (`updateResult`, :3645-3652) — never a second block. Lifecycle: a `pendingTools` Map keyed by tool-call id; abort/error at `message_end` finalizes every pending component with the error text under `isError` (:3573-3586) — `stopReason === "aborted"` → `errorMessage = "Operation aborted"` (the retry-attempt variant is unreachable in the port: ruby_llm retries are Faraday-internal, the I11 CUT); `agent_end` clears the map (:3658-3666). pi's `tool_execution_update` (partial result streaming) has NO port analog — ruby_llm 2.1.0 exposes only `after_tool_result` — cut, itemized; irrelevant to the probe frames (call-row-only mid-flight).

3. **tart's current mechanism (source-verified this session, base `ecc6b2b`).** `lib/tart/render/chat.rb:413-421`: `:tool_execution_start` only records `@tool` (the footer border's `tool: <name>` detail, chat.rb:1310 — unchanged by this iteration); the block enqueues at `:tool_execution_end` through `@transcript_state.enqueue_tool_block` (lib/tart/render/transcript.rb:194-220 — the per-tool dispatch: bash → `BashBlock.bash_block_rows`, write/read → `FileBlocks`, generic → the `⎿` panel). The mid-tool draw path already exists: the kernel animates while busy and `render_frame` drains under the mutex (chat.rb:355-367) — a pending block pushed at start WILL paint.

4. **The in-place mutation precedent (I33 — read before designing).** `Transcript#set_tool_output_expanded` (transcript.rb:289-303) already rebuilds registered blocks in place: blocks register at drain time in ascending start order (`flush_scrollback`, :256-273, records `{start:, size:, builder:}`), and the walk threads the row DELTA so an earlier block's size change shifts every later block's start. The I33 verdict documents the stale-start latent this discipline cures — the pending→final replacement MUST follow it (replace at the recorded start, thread the delta to later registrations).

5. **The pending row shape (derived from the settled families — no new geometry).** Every settled block opens Spacer-blank (PLAIN — bash_block.rb:46 comment) + bg pad + call rows + … + bg pad. The pending variant is the same family truncated to the call: Spacer blank, `Panel.panel_blank_line(width, pending_bg)`, the family's CALL rows under the pending bg (bash: `$ <command>` — `Panel.padded_fg_rows(..., fg: toolTitle, modifiers: [:bold])`, the measured bytes; write: `write_call_rows`; read: `read_call_rows(args, width, false, bg:)`; generic: the wrapped `  ⎿ <name>` row over `ToolBlock.tool_line(name, nil)`), closing bg pad. No output rows, no `Took` row, no expand hint — nothing exists to show (pi renders renderCall only while `isPartial`).

6. **Facts that bound the design.** (a) The theme token exists: theme.rb:67 `tool_pending_bg: "#34383a"` — no theme work. (b) Tool execution is SEQUENTIAL in the port: ruby_llm 2.1.0 default `tool_concurrency = false` (gem configuration.rb:257; the port sets nothing) and the loop pairs start/end per-thread (loop.rb:495-511) — one pending block at a time; the machinery must still behave sanely if a second start arrives before a finalize (append fallback, documented). (c) The events already carry the full call on both edges (`tool_call:` with `.name`/`.arguments`; end adds `result:`/`duration:` — the frozen I17 contract) — no loop.rb changes. (d) Replay never sees mid-flight state: recorded sessions carry final results only, and `replay_entries` → `enqueue_tool_block` (transcript.rb:558-568) is the append path — it stays untouched and the pending machinery never engages on replay.

7. **Control (this session, base `ecc6b2b`).** Suite `606 runs, 2487 assertions, 0 failures, 0 errors, 1 skips` (the pre-existing live-env skip); `SEAM_BENCH_OK`. Scenario set s1–s9 present under `gems/tui-split-rig/scenarios/` — all exit 0 cold per the I31/I33 verdicts; these are the settled-bytes pins this iteration must not move. pi source at `repos/pi` (1.1.0) is the oracle for every shape claim above.

8. **Non-goals.** User-bash live streaming (the NEXT plan entry — `!`/`!!` chunks, a different component family); partial tool-result streaming (`tool_execution_update` — no gem seam); the compaction-summary panel port (s7 closed at I31); any change to settled block bytes, the footer, or the live region. No new registry classes are expected (the probe is a bespoke capture, not a diff-pipeline scenario); if one is genuinely forced, additions-only (the I26 discipline).

## Specification

# Specification — I34 tool-pending-bg

- **Objective.** Close the last known mid-flight rendering divergence in the BRIEF §8 program (Grounds 1): enqueue the tool block at `:tool_execution_start` in a PENDING state — the call rows under `Theme[:tool_pending_bg]` (#34383a) — then replace it in place at `:tool_execution_end` with the final block (success/error bg). Exactly one block per tool call at settle; settled bytes unchanged (the s1–s9 pins must not move); replay (resume) renders final blocks only, by construction. The instrument already exists (the I26 probe) — this iteration promotes it to a deterministic gate and freezes that promotion.

- **Port shape (single-writer surface work; the I33 discipline is mandatory reading).**
  - **Transcript gains the pending surface** (lib/tart/render/transcript.rb): `enqueue_pending_tool_block(name, args)` pushes the pending region through the scrollback queue (order preserved vs queued submissions/statuses — never spliced ahead); the pending region's range registers at drain time in ascending start order exactly like `@expandable_blocks` (Grounds 4 — the stale-start cure); `finalize_tool_block(name, args, result, duration)` replaces the live pending registration IN PLACE with the SAME rows today's `enqueue_tool_block` composes (same dispatch, same builders, same `@tool_output_expanded` read at replacement time) and registers the final block in the expandable registry at the updated start; with NO live pending registration it falls back to today's append (the replay path never engages the pending machinery — `replay_entries`/`enqueue_tool_block` untouched). `finalize_pending_as_error(text)` finalizes an orphaned pending block pi's way (Grounds 2): the call rows + the error text rows under `Theme[:tool_error_bg]`. Both drain cases must hold: pending already flushed → replace `@transcript[start, size]` and thread the row delta to every later registration; pending still queued → swap the queued entry in place (the queue is mutated only under the coordinator's mutex — a drain-and-repush is acceptable, house judgment). `reset` clears the pending registration with the buffer (transcript.rb:312-319 — a stale registration surviving a reset is the I33-class latent).
  - **chat.rb wiring**: `:tool_execution_start` keeps `@tool = event[:tool_call].name` (footer border, unchanged) and adds the pending enqueue; `:tool_execution_end` routes through the finalize (the frozen I17 `duration:` contract rides through unchanged); the `:agent_end` interrupted arm finalizes any orphaned pending block with "Operation aborted" and the error arm with the error's message (pi interactive-mode.ts:3573-3586 — the existing `interrupted`/`error:` scrollback lines stay; the finalization is additive). Guard nil arguments the way `enqueue_tool_block` does (transcript.rb:195).
  - **Pending row shapes** (Grounds 5 — the settled families truncated to the call; the builders thread a bg or gain pending variants, house judgment, module-function style): bash → Spacer blank + pending pad + `$ <command>` (`Panel.padded_fg_rows`, fg `toolTitle`, bold — the measured bytes) + pending pad; write → its `write_call_rows` between the pads; read → `read_call_rows(args, width, false, bg:)` (the compact classification gate is `!expanded` — the pending call renders collapsed); generic → the wrapped `  ⎿ <name>` row (`ToolBlock.tool_line(name, nil)`) between the pads. No output rows, no `Took` row, no expand hint. The Spacer blank stays PLAIN (bash_block.rb:46).
  - **ctrl+o mid-flight** must corrupt nothing: the pending block may ride the expandable registry with a constant-size builder (toggle rebuilds it identically) or sit outside it (toggle never touches it) — either is acceptable; after finalize the block toggles normally. A second `enqueue_pending_tool_block` while one is live (unreachable under sequential execution, Grounds 6b) appends sanely and is documented.

- **Tests (the deterministic mid-flight proof, unit half).** New direct-class tests (test/render/ — drive the public surface, no stubs) + event-driven tests through chat_test.rb's existing `tool_start`/`tool_end` helpers (extended to carry arguments on start; additive surgery only): (1) pending visible — bash start → draw → the four pending rows with `style.bg == Theme[:tool_pending_bg]`, header span bold + toolTitle fg; (2) drained replace — start → draw → end → the transcript is BYTE-IDENTICAL (rows and position) to a control chat that received only `tool_end`, no pending bg anywhere; (3) fast path — start → end with no draw between → same byte-identity, no pending rows ever in the buffer; (4) ctrl+o mid-flight — start → draw → toggle → pending rows intact and the registry still resolves → end → the final block toggles both ways; (5) interrupt orphan — start → draw → `:agent_end(interrupted: true)` → the block finalized under `tool_error_bg` with "Operation aborted", the existing `interrupted` warning line still present, no pending bg; (6) replay pin — `replay_entries` over a recorded tool entry renders final blocks only, zero pending-bg spans; (7) per-family pending shapes — write/read/generic call-row-only under the pending bg; (8) sequential multi-tool turn — two start/end pairs → two blocks in order, no residue.

- **Rig (the deterministic mid-flight proof, live half — the frozen instrument).** `gems/tui-split-rig/bin/tool-pending-probe` gains a `--gate` mode (additive; the default evidence mode is UNCHANGED — still exit 0 with the frame digest): per app, PASS iff (a) at least one pre-settle frame shows ≥1 tool-mark row AND contains the pending-bg SGR `48;2;52;56;58`, and (b) the settled frame shows exactly one tool-mark row AND zero occurrences of that SGR; both apps must pass (pi = the oracle control); on pass print `TOOL_PENDING_GATE_OK` and exit 0, else print the per-frame digest of the failing condition and exit 1. No registry changes expected (additions-only if genuinely forced, each evidenced).

- **Output format.** Raw evidence to scratch: file list + wc; the pending/replay test list with verbatim run tails; the suite counts before/after; the probe gate command line + exit code + digest tail (both modes); the s1–s9 exit codes; PHASE 0 disagreements mandatory (the Grounds 2/4/5/6 premises are checkable against repos/pi and the gem). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` (s1–s9 exit 0; short out-dirs — deep paths trip the pre-existing footer-cwd truncation sensitivity); the new gate: `gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/<out>` (allow 120 s+; runs both apps ~30 s). pi sources: repos/pi/packages/coding-agent/src/modes/interactive/components/tool-execution.ts + interactive-mode.ts:3520-3670; the gem: ruby_llm 2.1.0 configuration.rb:257 (sequential default). Read transcript.rb's I33 rebuild block before designing (Grounds 4).

- **Boundaries.** May touch exactly: `lib/tart/render/{chat,transcript,bash_block,file_blocks,tool_block}.rb`, `test/chat_test.rb`, `test/render/**`, `gems/tui-split-rig/**`. Must not: `lib/tart/agent/loop.rb` (events already carry the payload), `lib/tart/theme.rb` (token exists), `lib/tart/render/panel.rb` (the pending bg is `Theme[:tool_pending_bg]` read directly — a helper, if wanted, lives in tool_block.rb), the wave-sealed render files (editor/motd/viewport/selection/footer/user_bash/kill_ring/model_menu), `bin/tart`, `test/**` beyond the two named homes, any golden or scenario yml. Out of scope: user-bash streaming, partial-result streaming, compaction-panel work, settled-block byte changes, new scenarios. No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - lib/tart/render/bash_block.rb
    - lib/tart/render/file_blocks.rb
    - lib/tart/render/tool_block.rb
    - test/chat_test.rb
    - test/render/**
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I34 tool-pending-bg

**AC1 — the pending state renders mid-flight.** At `:tool_execution_start` the surface enqueues the tool's PENDING block — Spacer blank (plain), pending-bg pad, the family's CALL rows under `Theme[:tool_pending_bg]` (#34383a; bash `$ <command>` bold toolTitle, write/read call lines, generic `  ⎿ <name>`), closing pending-bg pad; no output/Took/hint rows — and it paints on the next drawn frame while the tool runs. Unit-pinned per family (row shapes + span bgs + the bold header) and live-pinned by the frozen instrument (AC5).

**AC2 — exactly one block at settle; settled bytes unchanged.** `:tool_execution_end` replaces the pending registration in place (same transcript position) with the final block composed by the SAME dispatch/builders as today; BOTH drain cases (pending flushed to the buffer / still queued) produce a transcript byte-identical — rows and position — to a control chat that received only the end event; no pending-bg row survives any tool end. Post-integration, cold: s1–s9 all exit 0 (the settled-pins unmoved).

**AC3 — replay renders final blocks only.** `replay_entries` over recorded tool entries produces zero pending-bg spans and exactly the final blocks — the pending machinery never engages on the replay path (unit-pinned).

**AC4 — lifecycle discipline.** An orphaned pending block finalizes at `:agent_end` pi's way (interactive-mode.ts:3573-3586): interrupted → the call rows + "Operation aborted" under `tool_error_bg` (the existing `interrupted` warning line stays); error → the error's message. ctrl+o mid-flight corrupts neither the buffer nor the expandable registry, and the finalized block toggles normally afterward. Sequential multi-tool turns land their blocks in order with no residue; `Transcript#reset` clears the pending registration with the buffer. All unit-pinned.

**AC5 — the frozen instrument.** `gems/tui-split-rig/bin/tool-pending-probe --gate --out <dir>` exits 0 cold (no live keys, quiet tmux server), for BOTH apps: ≥1 pre-settle frame with a tool-mark row AND the pending-bg SGR `48;2;52;56;58`; the settled frame has exactly one tool-mark row and zero occurrences of that SGR; `TOOL_PENDING_GATE_OK` on stdout. The default (no `--gate`) evidence mode is unchanged — exit 0 with the frame digest. This gate and `pending-machinery` are RED at base BY DESIGN (the fix and the gate mode are this iteration's deliverables — the I14 wave-1 tripwire precedent).

**AC6 — quality.** Suite fully green with run-count delta > 0 (new tests; chat_test.rb surgery additive only); `SEAM_BENCH_OK`; the integrated diff touches exactly the declared set (scope gate); house style throughout (pi citations carried in comments, module-function shape preserved).

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i34-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i34-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i34-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i34-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i34-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i34-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i34-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i34-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i34-s9
  expect:
    exit_code: 0

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i34-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: pending-machinery
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def enqueue_pending_tool_block' lib/tart/render/transcript.rb && grep -q 'def finalize_tool_block' lib/tart/render/transcript.rb && grep -q 'enqueue_pending_tool_block' lib/tart/render/chat.rb && grep -q -- '--gate' gems/tui-split-rig/bin/tool-pending-probe && echo PENDING_MACHINERY_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_MACHINERY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only ecc6b2b HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|lib/tart/render/bash_block\.rb|lib/tart/render/file_blocks\.rb|lib/tart/render/tool_block\.rb|test/chat_test\.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# LANE: core — iteration I34 tool-pending-bg (the ONLY lane; you are not racing anyone, but your boundaries are still exact)

You are the `core` lane builder for iteration I34 in repo `tart` (worktree: the provisioned lane checkout, base = project/pi-port @ ecc6b2b). Everything below the rules is YOUR lane's spec — the whole iteration is yours.

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
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work — this
process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I34-tool-pending-bg-core/report.md (an absolute path outside
your worktree: /Users/eric/architect/spaces/20261009-pi-port/build/I34-tool-pending-bg-core/report.md),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop

=== SPECIFICATION (I34 core — the whole iteration is this lane) ===

# Specification — I34 tool-pending-bg

- **Objective.** Close the last known mid-flight rendering divergence in the BRIEF §8 program (Grounds 1): enqueue the tool block at `:tool_execution_start` in a PENDING state — the call rows under `Theme[:tool_pending_bg]` (#34383a) — then replace it in place at `:tool_execution_end` with the final block (success/error bg). Exactly one block per tool call at settle; settled bytes unchanged (the s1–s9 pins must not move); replay (resume) renders final blocks only, by construction. The instrument already exists (the I26 probe) — this iteration promotes it to a deterministic gate and freezes that promotion.

- **Port shape (single-writer surface work; the I33 discipline is mandatory reading).**
  - **Transcript gains the pending surface** (lib/tart/render/transcript.rb): `enqueue_pending_tool_block(name, args)` pushes the pending region through the scrollback queue (order preserved vs queued submissions/statuses — never spliced ahead); the pending region's range registers at drain time in ascending start order exactly like `@expandable_blocks` (Grounds 4 — the stale-start cure); `finalize_tool_block(name, args, result, duration)` replaces the live pending registration IN PLACE with the SAME rows today's `enqueue_tool_block` composes (same dispatch, same builders, same `@tool_output_expanded` read at replacement time) and registers the final block in the expandable registry at the updated start; with NO live pending registration it falls back to today's append (the replay path never engages the pending machinery — `replay_entries`/`enqueue_tool_block` untouched). `finalize_pending_as_error(text)` finalizes an orphaned pending block pi's way (Grounds 2): the call rows + the error text rows under `Theme[:tool_error_bg]`. Both drain cases must hold: pending already flushed → replace `@transcript[start, size]` and thread the row delta to every later registration; pending still queued → swap the queued entry in place (the queue is mutated only under the coordinator's mutex — a drain-and-repush is acceptable, house judgment). `reset` clears the pending registration with the buffer (transcript.rb:312-319 — a stale registration surviving a reset is the I33-class latent).
  - **chat.rb wiring**: `:tool_execution_start` keeps `@tool = event[:tool_call].name` (footer border, unchanged) and adds the pending enqueue; `:tool_execution_end` routes through the finalize (the frozen I17 `duration:` contract rides through unchanged); the `:agent_end` interrupted arm finalizes any orphaned pending block with "Operation aborted" and the error arm with the error's message (pi interactive-mode.ts:3573-3586 — the existing `interrupted`/`error:` scrollback lines stay; the finalization is additive). Guard nil arguments the way `enqueue_tool_block` does (transcript.rb:195).
  - **Pending row shapes** (Grounds 5 — the settled families truncated to the call; the builders thread a bg or gain pending variants, house judgment, module-function style): bash → Spacer blank + pending pad + `$ <command>` (`Panel.padded_fg_rows`, fg `toolTitle`, bold — the measured bytes) + pending pad; write → its `write_call_rows` between the pads; read → `read_call_rows(args, width, false, bg:)` (the compact classification gate is `!expanded` — the pending call renders collapsed); generic → the wrapped `  ⎿ <name>` row (`ToolBlock.tool_line(name, nil)`) between the pads. No output rows, no `Took` row, no expand hint. The Spacer blank stays PLAIN (bash_block.rb:46).
  - **ctrl+o mid-flight** must corrupt nothing: the pending block may ride the expandable registry with a constant-size builder (toggle rebuilds it identically) or sit outside it (toggle never touches it) — either is acceptable; after finalize the block toggles normally. A second `enqueue_pending_tool_block` while one is live (unreachable under sequential execution, Grounds 6b) appends sanely and is documented.

- **Tests (the deterministic mid-flight proof, unit half).** New direct-class tests (test/render/ — drive the public surface, no stubs) + event-driven tests through chat_test.rb's existing `tool_start`/`tool_end` helpers (extended to carry arguments on start; additive surgery only): (1) pending visible — bash start → draw → the four pending rows with `style.bg == Theme[:tool_pending_bg]`, header span bold + toolTitle fg; (2) drained replace — start → draw → end → the transcript is BYTE-IDENTICAL (rows and position) to a control chat that received only `tool_end`, no pending bg anywhere; (3) fast path — start → end with no draw between → same byte-identity, no pending rows ever in the buffer; (4) ctrl+o mid-flight — start → draw → toggle → pending rows intact and the registry still resolves → end → the final block toggles both ways; (5) interrupt orphan — start → draw → `:agent_end(interrupted: true)` → the block finalized under `tool_error_bg` with "Operation aborted", the existing `interrupted` warning line still present, no pending bg; (6) replay pin — `replay_entries` over a recorded tool entry renders final blocks only, zero pending-bg spans; (7) per-family pending shapes — write/read/generic call-row-only under the pending bg; (8) sequential multi-tool turn — two start/end pairs → two blocks in order, no residue.

- **Rig (the deterministic mid-flight proof, live half — the frozen instrument).** `gems/tui-split-rig/bin/tool-pending-probe` gains a `--gate` mode (additive; the default evidence mode is UNCHANGED — still exit 0 with the frame digest): per app, PASS iff (a) at least one pre-settle frame shows ≥1 tool-mark row AND contains the pending-bg SGR `48;2;52;56;58`, and (b) the settled frame shows exactly one tool-mark row AND zero occurrences of that SGR; both apps must pass (pi = the oracle control); on pass print `TOOL_PENDING_GATE_OK` and exit 0, else print the per-frame digest of the failing condition and exit 1. No registry changes expected (additions-only if genuinely forced, each evidenced).

- **Output format.** Raw evidence to scratch: file list + wc; the pending/replay test list with verbatim run tails; the suite counts before/after; the probe gate command line + exit code + digest tail (both modes); the s1–s9 exit codes; PHASE 0 disagreements mandatory (the Grounds 2/4/5/6 premises are checkable against repos/pi and the gem). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` (s1–s9 exit 0; short out-dirs — deep paths trip the pre-existing footer-cwd truncation sensitivity); the new gate: `gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/<out>` (allow 120 s+; runs both apps ~30 s). pi sources: repos/pi/packages/coding-agent/src/modes/interactive/components/tool-execution.ts + interactive-mode.ts:3520-3670; the gem: ruby_llm 2.1.0 configuration.rb:257 (sequential default). Read transcript.rb's I33 rebuild block before designing (Grounds 4).

- **Boundaries.** May touch exactly: `lib/tart/render/{chat,transcript,bash_block,file_blocks,tool_block}.rb`, `test/chat_test.rb`, `test/render/**`, `gems/tui-split-rig/**`. Must not: `lib/tart/agent/loop.rb` (events already carry the payload), `lib/tart/theme.rb` (token exists), `lib/tart/render/panel.rb` (the pending bg is `Theme[:tool_pending_bg]` read directly — a helper, if wanted, lives in tool_block.rb), the wave-sealed render files (editor/motd/viewport/selection/footer/user_bash/kill_ring/model_menu), `bin/tart`, `test/**` beyond the two named homes, any golden or scenario yml. Out of scope: user-bash streaming, partial-result streaming, compaction-panel work, settled-block byte changes, new scenarios. No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - lib/tart/render/bash_block.rb
    - lib/tart/render/file_blocks.rb
    - lib/tart/render/tool_block.rb
    - test/chat_test.rb
    - test/render/**
    - gems/tui-split-rig/**
```

=== ACCEPTANCE CRITERIA (frozen — judge your work against these) ===

# Acceptance Criteria — I34 tool-pending-bg

**AC1 — the pending state renders mid-flight.** At `:tool_execution_start` the surface enqueues the tool's PENDING block — Spacer blank (plain), pending-bg pad, the family's CALL rows under `Theme[:tool_pending_bg]` (#34383a; bash `$ <command>` bold toolTitle, write/read call lines, generic `  ⎿ <name>`), closing pending-bg pad; no output/Took/hint rows — and it paints on the next drawn frame while the tool runs. Unit-pinned per family (row shapes + span bgs + the bold header) and live-pinned by the frozen instrument (AC5).

**AC2 — exactly one block at settle; settled bytes unchanged.** `:tool_execution_end` replaces the pending registration in place (same transcript position) with the final block composed by the SAME dispatch/builders as today; BOTH drain cases (pending flushed to the buffer / still queued) produce a transcript byte-identical — rows and position — to a control chat that received only the end event; no pending-bg row survives any tool end. Post-integration, cold: s1–s9 all exit 0 (the settled-pins unmoved).

**AC3 — replay renders final blocks only.** `replay_entries` over recorded tool entries produces zero pending-bg spans and exactly the final blocks — the pending machinery never engages on the replay path (unit-pinned).

**AC4 — lifecycle discipline.** An orphaned pending block finalizes at `:agent_end` pi's way (interactive-mode.ts:3573-3586): interrupted → the call rows + "Operation aborted" under `tool_error_bg` (the existing `interrupted` warning line stays); error → the error's message. ctrl+o mid-flight corrupts neither the buffer nor the expandable registry, and the finalized block toggles normally afterward. Sequential multi-tool turns land their blocks in order with no residue; `Transcript#reset` clears the pending registration with the buffer. All unit-pinned.

**AC5 — the frozen instrument.** `gems/tui-split-rig/bin/tool-pending-probe --gate --out <dir>` exits 0 cold (no live keys, quiet tmux server), for BOTH apps: ≥1 pre-settle frame with a tool-mark row AND the pending-bg SGR `48;2;52;56;58`; the settled frame has exactly one tool-mark row and zero occurrences of that SGR; `TOOL_PENDING_GATE_OK` on stdout. The default (no `--gate`) evidence mode is unchanged — exit 0 with the frame digest. This gate and `pending-machinery` are RED at base BY DESIGN (the fix and the gate mode are this iteration's deliverables — the I14 wave-1 tripwire precedent).

**AC6 — quality.** Suite fully green with run-count delta > 0 (new tests; chat_test.rb surgery additive only); `SEAM_BENCH_OK`; the integrated diff touches exactly the declared set (scope gate); house style throughout (pi citations carried in comments, module-function shape preserved).

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i34-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i34-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i34-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i34-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i34-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i34-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i34-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i34-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i34-s9
  expect:
    exit_code: 0

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i34-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: pending-machinery
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def enqueue_pending_tool_block' lib/tart/render/transcript.rb && grep -q 'def finalize_tool_block' lib/tart/render/transcript.rb && grep -q 'enqueue_pending_tool_block' lib/tart/render/chat.rb && grep -q -- '--gate' gems/tui-split-rig/bin/tool-pending-probe && echo PENDING_MACHINERY_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_MACHINERY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only ecc6b2b HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|lib/tart/render/bash_block\.rb|lib/tart/render/file_blocks\.rb|lib/tart/render/tool_block\.rb|test/chat_test\.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Report

### core

### Phase 0 disagreements (flagged before implementation; none blocked)

| # | Disagreement / premise check | Evidence |
|---|---|---|
| 1 | `Panel.tool_panel_bg`'s comment (panel.rb:84-86, "the pending bg never reaches the scrollback — the port's blocks enqueue at completion") goes FACTUALLY STALE after I34: the pending bg now reaches the scrollback mid-flight. panel.rb is outside this lane's touch set — the comment cannot be corrected here. Comment-only, zero behavior impact. | `sed -n '82,86p' lib/tart/render/panel.rb` — "the pending bg never reaches the scrollback"; ground truth post-I34: probe frames show `48;2;52;56;58` in tart mid-flight captures (below) |
| 2 | All other premises verified against live sources, no disagreement: theme.rb:67 `tool_pending_bg: "#34383a"` (SGR `48;2;52;56;58`), toolTitle :61, tool_error_bg :69; chat.rb:413-421 base shape; transcript.rb I33 rebuild (`flush_scrollback` records `{start:, size:, builder:}`, `set_tool_output_expanded` threads the row delta); bash_block.rb:46-47 "Spacer blank stays PLAIN"; ruby_llm `configuration.rb` `option :tool_concurrency, false` (sequential default confirmed in the installed gem); pi interactive-mode.ts:3520-3670 (pendingTools Map, message_end abort arm → "Operation aborted" finalize loop, agent_end clears) + tool-execution.ts:90-91/:271-277 (`toolPendingBg` while isPartial); loop.rb:495-511 events carry the full call on both edges. Baseline suite 606 runs / 2487 assertions / 0F / 0E / 1 skip, `SEAM_BENCH_OK` — matches Grounds 7. | commands in Gate results |

### File inventory (wc)

| File | Lines | Status vs ecc6b2b |
|---|---|---|
| lib/tart/render/transcript.rb | 742 | M (+227/-89 region per diff --stat) |
| lib/tart/render/chat.rb | 1603 | M |
| lib/tart/render/bash_block.rb | 197 | M |
| lib/tart/render/file_blocks.rb | 232 | M |
| lib/tart/render/tool_block.rb | 58 | M |
| test/chat_test.rb | 4194 | M (additive: 2-line helper signature extension + 9 tests + 1 private helper) |
| test/render/transcript_test.rb | 264 | new |
| gems/tui-split-rig/bin/tool-pending-probe | 132 | M (additive --gate) |

`git status --short` = exactly those 8 entries. `git diff --name-only ecc6b2b | grep -qvE '<touch-set>'` → false → `SCOPE_OK`. No commits made (`git log` untouched).

### Gate results (this session, final tree)

| Gate | Command | Result |
|---|---|---|
| suite (before) | `bundle install --quiet && bundle exec rake` | `606 runs, 2487 assertions, 0 failures, 0 errors, 1 skips` (pre-existing live-env skip) |
| suite (after) | `bundle exec rake` | exit 0 — `629 runs, 2595 assertions, 0 failures, 0 errors, 1 skips` (delta +23 runs, +108 assertions) |
| bench | `bundle exec ruby bench/seam_bench.rb 2>&1 \| tail -1` | `SEAM_BENCH_OK` |
| s1-parity | rig run s1_text_turn --out tmp/i34-s1 | exit 0 |
| s2-parity | rig run s2_tool_turn --out tmp/i34-s2 | exit 0 |
| s3-parity | rig run s3_tool_turn_files --out tmp/i34-s3 | exit 0 |
| s4-parity | rig run s4_bash_variants --out tmp/i34-s4 | exit 0 |
| s5-parity | rig run s5_bash_truncation --out tmp/i34-s5 | exit 0 |
| s6-parity | rig run s6_long_calls --out tmp/i34-s6 | exit 0 |
| s7-parity | rig run s7_compaction --out tmp/i34-s7 | exit 0 |
| s8-parity | rig run s8_zero_usage_compaction --out tmp/i34-s8 | exit 0 |
| s9-parity | rig run s9_startup_help --out tmp/i34-s9 | **exit 1 from this worktree — PRE-EXISTING deep-path sensitivity, NOT this diff** (evidence below) |
| tool-pending-gate | `gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i34-tp` | exit 0, stdout ends `TOOL_PENDING_GATE_OK` |
| evidence mode | `gems/tui-split-rig/bin/tool-pending-probe --out tmp/i34-tp-evidence` | exit 0, per-frame digest (unchanged format) |
| pending-machinery | the spec's 4-grep chain | `PENDING_MACHINERY_OK` |
| scope | working-tree file set vs ecc6b2b | `SCOPE_OK` (exactly the declared touch set) |

### s9 deep-path evidence (base vs worktree, controlled)

This worktree's absolute path is ~35 chars deeper than repos/tart; the gate spec itself warns "deep paths trip the pre-existing footer-cwd truncation sensitivity". Controlled runs of the UNMODIFIED base tree (git archive ecc6b2b extracted outside the worktree; no git write in this worktree):

| Tree | AGENTS.md capture-row length | s9 exit |
|---|---|---|
| base @ /tmp/i34-base | 51 | 0 |
| base @ <space>/build/xx | 92 | 0 |
| base @ <space>/build/xxxx (**= repos/tart integration depth, 94**) | 94 | **0** |
| base @ <space>/build/I34-tool-pending-bg-core/wb (same depth as wt) | 118 | **1** |
| this worktree (I34 tree) @ wt | 118 | **1** |

The base-deep and worktree-deep failures are the SAME failure: `difference lines: 14 (sanctioned: 12, unknown-candidate: 2)` with the identical unknown-candidate pair — `- ctrl+g for external editor` (pi-only header row exposed by the one-row scroll shift) and the `[Context]` path-wrap blank. Conclusion: environmental at depth 118; the integration run at depth 94 is green at base (and the only content deltas my diff makes require tool events, which s9 — prompt "hi", no tools — never emits; the pending machinery's only s9-reachable code is the `@pending_tool&.region&.equal?` no-op in `flush_scrollback`).

### Probe gate (AC5) — verbatim tails

Default evidence mode (exit 0; digest format unchanged — same lines as the I26 probe):

```
pi frame 02: tool-mark-rows=1 bg=[48;2;33;59;73mx1,[48;2;52;56;58mx2,[48;2;79;142;179mx1
... (frames 02-12 identical shape)
pi frame 13: tool-mark-rows=1 bg=[48;2;33;59;73mx1,[48;2;37;65;49mx2,[48;2;79;142;179mx1
tart frame 02: tool-mark-rows=1 bg=[48;2;33;59;73mx1,[48;2;52;56;58mx2,[48;2;79;142;179mx1
... (frames 02-12 identical shape)
tart frame 13: tool-mark-rows=1 bg=[48;2;33;59;73mx1,[48;2;37;65;49mx2,[48;2;79;142;179mx1
frames at .../wt/tmp/i34-tp-evidence
evidence-mode exit=0
```

tart's mid-flight SGR signature is now frame-for-frame identical to pi's: pending `48;2;52;56;58`x2 frames 02–12 (17-frame captures both apps), settle `48;2;37;65;49`x2 (toolSuccessBg) from frame 13.

Gate mode (exit 0):

```
frames at .../wt/tmp/i34-tp
TOOL_PENDING_GATE_OK
gate exit=0
```

RED-at-base tripwire verified: `git show ecc6b2b:lib/tart/render/transcript.rb | grep -c 'def enqueue_pending_tool_block'` → 0; `git show ecc6b2b:gems/tui-split-rig/bin/tool-pending-probe | grep -c -- '--gate'` → 0 (both exit 1 at base, as AC5 specifies).

### Pending/replay test list (verbatim run tails)

`bundle exec ruby test/render/transcript_test.rb` (direct-class, 14 tests):

```
Pending shapes: pending_bash_renders_the_call_rows_under_the_pending_bg /
pending_write_renders_the_call_rows_alone / pending_read_renders_the_collapsed_call /
pending_generic_renders_the_mark_line_alone / pending_bash_guards_nil_args_to_the_placeholder_header
Settle: flushed_pending_settles_byte_identical_to_the_control /
queued_pending_settles_byte_identical_to_the_control /
flushed_settle_threads_the_row_delta_to_later_blocks /
generic_settle_drops_the_registration_and_matches_the_control
Lifecycle: orphaned_pending_finalizes_as_the_error_block /
finalize_without_a_pending_registration_appends /
second_pending_supersedes_and_the_stale_end_appends / reset_clears_the_pending_registration
Replay: replay_entries_render_final_blocks_only
14 runs, 60 assertions, 0 failures, 0 errors, 0 skips
```

`bundle exec ruby test/chat_test.rb -n "/pending|mid_flight|residue|orphan|resume_replays_render/"` (event-driven, 9 tests):

```
test_pending_block_paints_mid_flight (AC1 — 4 rows, header cell bg=#34383a fg=toolTitle bold)
test_flushed_pending_settles_byte_identical_to_the_control (AC2 drained — transcript_lines + buffer_content == control)
test_queued_pending_settles_byte_identical_to_the_control (AC2 fast path — no pending rows ever painted)
test_ctrl_o_mid_flight_and_the_settled_toggle (AC4 — constant-size rebuild; finalize reads the flipped state; round-trips)
test_interrupt_finalizes_the_orphaned_pending_block (AC4 — "Operation aborted" under toolErrorBg; "interrupted" line stays)
test_error_finalizes_the_orphaned_pending_block_with_the_message (AC4 — error arm)
test_resume_replays_render_no_pending_bg (AC3 — zero pending-bg spans on replay)
test_pending_shapes_per_family (AC1 — write/read/generic call-row-only)
test_sequential_multi_tool_turn_leaves_no_residue (AC4 — byte-identical to the end-only control)
9 runs, 48 assertions, 0 failures, 0 errors, 0 skips
```

All 9 chat tests sit BEFORE chat_test.rb's `private` (:3871) — the silently-skipped-tests latent does not apply.

### chat_test.rb surgery check

`git diff ecc6b2b -- test/chat_test.rb` removed lines = only the 2-line `tool_start` helper body (replaced by the arguments-carrying signature; existing call sites unchanged). Everything else is additions.

STATUS: COMPLETE_WITH_CONCERNS — (1) s9-parity exits 1 from THIS worktree at any out-dir: pre-existing deep-path sensitivity, reproduced byte-identically on the unmodified base tree at the same path depth (118-char capture rows) and green on base at the integration depth 94 (repos/tart) — the architect's gate run from repos/tart is expected green; (2) panel.rb:84-86's tool_panel_bg comment ("the pending bg never reaches the scrollback") is now stale and lives outside this lane's touch set — one-line architect-owned fix; (3) documented caveat (spec-sanctioned, Grounds 6b-unreachable): a second enqueue_pending_tool_block while one is live supersedes the registration; the superseded block renders on under the pending bg (its end falls back to the append) — pinned by test_second_pending_supersedes_and_the_stale_end_appends.

## Verdict

# Verdict — I34 tool-pending-bg

**CONTINUE** — judged cold 2026-10-12 in a fresh session (dispatch session did not judge).

## Post-flight (mechanical, by command)

`architect verify` 4/4 PASS (frozen untouched / no builder commits / report exists / in-bounds); `git -C wt log ecc6b2b..` empty; the iteration-file diff since freeze 9e194a19 is append-only (Builder Prompt + Builder Report). Evidence transcribed at 65b0937a.

## Cold gate run (repos/tart @ base ecc6b2b)

12/14 PASS. The two failures — `tool-pending-gate` (`invalid option: --gate`) and `pending-machinery` — are RED-at-base BY DESIGN per AC5's own text (the gate mode and the machinery are this iteration's deliverables); both PASS in the lane worktree, independently re-run cold by this session: `TOOL_PENDING_GATE_OK` exit 0. s9-parity PASSED cold at the repos/tart depth, confirming the builder's worktree s9 failure is the pre-existing deep-path environmental sensitivity (their controlled experiment: unmodified base at depth 118 fails byte-identically, base at depth 94 green).

## PHASE 0 rulings

- **panel.rb:84-86 stale comment — ACCEPT.** Comment-only, zero behavior; panel.rb sits in the spec's own Must-not list, so the lane correctly left it. Architect-owned one-line follow-up (recorded below, residual).
- **Premise verification (no disagreement) — ACCEPT.** Spot-checked this session against live sources: pi interactive-mode.ts:3573-3586 (pendingTools loop, updateResult isError, "Operation aborted" :3570), the I33 registry discipline in transcript.rb, and the theme token — the probe's live frames carry the exact SGR `48;2;52;56;58`.
- **s9 worktree exit 1 — ACCEPT (environmental).** Proven by the base-tree depth experiment + my cold s9 PASS at integration depth.
- **Supersede caveat (second pending while one is live) — ACCEPT.** The spec sanctioned "appends sanely and is documented" (Grounds 6b: unreachable under ruby_llm's sequential default); the builder implemented it, documented it in-code, and pinned it (`test_second_pending_supersedes_and_the_stale_end_appends`).

## Acceptance Criteria

- **AC1 PASS** — pending state renders mid-flight: unit-pinned per family (transcript_test shape tests + chat_test paint test: PLAIN Spacer, pending pads, bold toolTitle header) and live-pinned (probe frames 02–12: `$ sleep 6` under `48;2;52;56;58` ×2, frame-for-frame identical to pi).
- **AC2 PASS** — both drain cases byte-identical to the end-only control (unit + buffer-level); s1–s9 green cold at integration depth; no pending-bg row survives any settle (pinned).
- **AC3 PASS** — replay path untouched; zero pending-bg spans on replay (two unit pins).
- **AC4 PASS** — interrupt orphan ("Operation aborted" under toolErrorBg, warning line stays), error arm with the message, ctrl+o mid-flight (constant-size builder; final toggles both ways, round-trip), sequential multi-tool no residue, reset clears the registration. All green in this session's independent re-run (14 + 9 tests, 0F).
- **AC5 PASS** — `--gate` mode additive, default evidence mode unchanged; gate exit 0 cold for BOTH apps; RED at base verified.
- **AC6 PASS** — suite 629 runs / 2595 assertions / 0F / 0E / 1 skip (+23 runs; chat_test surgery additive: 3 removed lines = the old helper signature); SEAM_BENCH_OK; scope exactly the declared set (7 M + 1 new file, all inside touch); pi citations carried throughout, module-function shape preserved.

## Diff review (intent)

The implementation matches the spec's shape closely: `enqueue_pending_tool_block` pushes a constant-size MarkedRegion through the scrollback queue (order preserved), `flush_scrollback` links the region to its registry entry (the I33 stale-start cure), `finalize_tool_block` replaces at the recorded start with the rows the SHARED `tool_block_builder` composes (toggle state read at replacement time) and threads the row delta to later registrations; the queued case swaps via drain-and-repush (Ruby Queue is FIFO — order preserved); `finalize_pending_as_error` routes a synthetic error result through the same dispatch (pi's same-component updateResult); `reset` clears the registration; chat.rb wiring is exactly the spec's three edges with the I17 `duration:` contract riding through.

## Residuals (architect-owned, non-blocking)

1. panel.rb:84-86's `tool_panel_bg` comment ("the pending bg never reaches the scrollback") is now factually stale — one-line comment fix, out-of-loop.
2. The superseded-pending caveat is documented + tested but leaves the stale block under the pending bg until its own end appends below it — unreachable under sequential execution today; revisit only if tool concurrency ever lands.
