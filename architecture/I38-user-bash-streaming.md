# I38: user-bash-streaming

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I38 user-bash-streaming

1. **The divergence (BRIEF §8 mid-flight program; standing backlog item; plan `build/loop/plan-20261012T184702Z.md` ENTRY 2).** User `!`/`!!` bash commands stream output chunks live in pi; tart renders only the completed block. The completed-block bytes are already parity-true (the I19-era block family, pinned by unit tests + the owner's live side-by-side runs) — only the mid-flight rows are missing. pi's mechanism (source-verified): `handleBashCommand` (interactive-mode.ts:6987-7062) constructs a `BashExecutionComponent` and adds it to the chat container (idle) or the pending container (agent streaming, :7008-7012) BEFORE execution starts, then `session.executeBash(command, chunkCb, …)` (:7050-7057) calls `bashComponent.appendOutput(chunk)` + `ui.requestRender()` per chunk; `setComplete(…)` (:7058-7064) finalizes the SAME component in place. The running component renders (bash-execution.ts): Spacer(1), DynamicBorder (bashMode, or `dim` for `!!`), `$ <command>` header (colorKey, bold, outputPad 1), the accumulated output (muted; context-tail-truncated, then collapsed preview = last `PREVIEW_LINES` 20 logical lines → `truncateToVisualLines` keep-end), then a `Loader` child — and the status rows (hidden-lines hint / `(exit N)` / `(cancelled)` / truncation warning) render ONLY when not running (:147-165: the loader branch replaces the whole statusParts block; NO hidden-lines hint mid-flight).

2. **pi's chunk pipeline (the sanitize + join discipline).** `executeBashWithOperations` (core/bash-executor.ts:48-160): per pipe data event → decode stream-mode → split incomplete ANSI suffix → `appendText` sanitizes `sanitizeBinaryOutput(stripAnsi(rawText)).replace(/\r/g, "")` (:76-78) — CR REMOVED, not mapped — then `options.onChunk(text)` (:96-98). The component's own `appendOutput` (:83-99) re-applies stripAnsi + `\r\n`→`\n` + `\r`→`\n` and the "first chunk piece appends to the last line" join — on the live path this is defensive dead code (the executor already sanitized); it matters for the replay/extension paths that feed raw text (:3871-3881). The port's stance at base mirrors the executor's live-path discipline: `Tools::Bash#run_user` returns `snapshot.content.to_s.gsub("\r", "")` (bash.rb:68-90) and the ANSI/binary strip is the standing itemized cut (no ANSI utility — recorded when the executor landed). **This iteration keeps that stance**: the on_chunk seam hands the SAME discipline the completed content carries (per-chunk `gsub("\r", "")` — CR-removal commutes with join and with tail-truncation's line accounting), so the mid-flight rows and the completed block agree on bytes. ANSI stripping is NOT added here (it would fork mid-flight from settled bytes); it stays the inherited itemized deviation, revisit only as its own slice.

3. **pi's Loader (the mid-flight spinner row — bytes).** loader.ts: `DEFAULT_FRAMES` ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏, `DEFAULT_INTERVAL_MS` 80 (:17-18); `render(width)` returns `["", …super]` — a LEADING BLANK ROW (:66-68); the row text is `"<spinner> <message>"` with `Text` padX=1 (:93-97, :56); the frame advances on the interval timer and each tick calls `ui.requestRender()` (:79-84) — the animation continues WITHOUT chunk arrivals. `BashExecutionComponent` constructs it per execution (:57-63) with `spinnerColorFn = theme.fg(colorKey)` and `messageColorFn = theme.fg("muted")` and the message `Running... (${keyText("tui.select.cancel")} to cancel)` — PLAIN text inside the muted message (the constructor comment: "Plain text for loader"); `keyText("tui.select.cancel")` resolves the default keys `["escape", "ctrl+c"]` (keybindings.ts:155-158) → **`Running... (escape/ctrl+c to cancel)`** (the hint names pi's select-cancel binding pair; the actual abort binding is escape — interactive-mode.ts:3074 routes onEscape → abortBash — a pi quirk the port copies byte-for-byte, behavior and all). Each component owns its loader instance (frame 0 at construction) — independent of the working-status spinner.

4. **tart's current mechanism (base `a48aaca9`, verified).** `Tart::Render::UserBash` (user_bash.rb:77-113) runs the command on a kernel task through `Agent::Bridge` — the worker thread executes `Tools::Bash#run_user(command)` (reader threads drain both pipes into an `OutputAccumulator`, bash.rb:153-253), the outcome lands in `@slot`, and `finish` (:143-151) renders via the constructor-injected `block_sink` → `Transcript#enqueue_user_bash_block` (transcript.rb:190-196) → `BashBlock.user_bash_block_rows` (bash_block.rb:152-175: blank / `─` border (bashMode or dim) / `$ command` bold / blank + last-20-of-last-20 output (muted) / status rows / `─` border). No mid-flight render exists; the class doc records "Streaming chunks are execution-transient in pi's Loader frames — the port renders the completed block (itemized)". The live-region precedent is chat.rb's assistant streaming: `display_lines = @transcript_state.lines + live_lines(viewport_width)` (:1539-1541) — the live rows render BELOW the transcript content and BELOW any streaming assistant rows (`live_lines`, :1560-1571), exactly pi's chat-container/pending-container placements. The frame cadence is gated on `busy?` alone (`render_frame` → `@kernel.animate(duration: BUSY_FRAME_SECONDS) if busy?`, :374-384) — a running user bash opens no animation window today.

5. **The bridge queue IS the streaming seam (verified empirically this session).** `Agent::Bridge#run` (bridge.rb:31-56) pops its `Async::Queue` (Thread::Queue-backed, thread-safe) in a loop and YIELDS every non-terminal item to the run block — currently `{ |_item| }` (user_bash.rb:100-107) discards them. Passing an `on_chunk:` proc into `run_user` whose reader-thread invocations push `{chunk: text}` items onto the bridge queue delivers each chunk to the reactor-side run block immediately, in per-pipe order, cross-pipe interleaved — pi's two-pipe `onData` semantics. The architect's scratch probes this session (`/tmp/qpop3.rb`, `/tmp/qpop4.rb`): with the reactor's frame loop ticking at 0.15 s, chunk items pushed from foreign threads were popped and yielded at push time (0.61 s push → 0.61 s pop), and an idle frame loop (event-queue pop) coexisted with the bridge pop. All render-state mutation then stays ON THE REACTOR (submit's run, the yielded chunks, finish, cancel) — no new cross-thread state; `request_draw`/`animate` are reactor-only (core/loop.rb:134-160) and every mutation site is a reactor fiber. Threading facts that bound the design: `UserBash` is deliberately unsynchronized (its doc: run/cancel on the frame-loop fiber, completion inside the kernel task) — the new sinks must land on those same fibers or the contract breaks.

6. **Placement + lifecycle parity facts.** (a) Idle run: pi adds the component to the chat container below all existing content — the port's live region appends below transcript content: same visual position. (b) Run while a turn streams: pi parks the component in `pendingMessagesContainer` BELOW the streaming message (:7008-7012; flushed to chat at the next submit, :3389 + :4861-4867) — the port's live rows compose AFTER the assistant's live rows: same position. (c) The RECORD already defers while busy (the port's `@pending` flush at agent_end = pi's `_pendingBashMessages`). (d) BASE divergence, out of scope (the plan letter: "the completed block flushes to the transcript exactly as today"): when a turn is running at completion, pi's block sits below the streaming message while the port's `block_sink` enqueue lands above the live region — a completed-placement property unchanged by this iteration. (e) Replay never sees mid-flight state (records carry final output only; `replay_user_bash`, transcript.rb:600-630) — untouched. (f) Mid-run ctrl+o: pi's `setToolsExpanded` reaches the RUNNING component (`setExpanded` → `updateDisplay`) — the running preview toggles; the port's live rows re-compose per frame, so reading the same global flag (`Transcript#tool_output_expanded`, already a public reader, transcript.rb:108) at composition time gives pi's behavior; no hidden-lines hint renders mid-flight in either state (Grounds 1).

7. **Instrument shape (why a probe, not a scenario).** The settle runner can only see SETTLED screens — its quiescence loop waits out the run, and `post_settle_keys` (s9/s10 precedent) likewise captures after settle; user bash involves no model turn, so there is no turn edge to hang a capture on. The mid-flight frame-capture precedent is the I26/I34 `bin/tool-pending-probe --gate` (both apps booted through the same staging, frames captured at 0.5 s cadence until 4 identical, per-app facts, pi = oracle control, `TOOL_PENDING_GATE_OK`). Determinism for user bash: a command emitting one line per second for ~3 s (`for i in 1 2 3; do echo "probe line $i"; sleep 1; done`) guarantees, against the 0.5 s cadence, pre-settle frames that contain the loader row AND already-emitted output rows; the spinner's 80 ms glyph advance keeps pre-settle frames mutually distinct (settle detection = spinner gone). Scenario-loader constraints (scenario.rb:62-77): `expected_requests` must be positive and `responses` non-empty — the probe's driver yml carries one inert scripted reply that is never requested (the probe ignores request counts, like the tool-pending probe).

8. **Control (this session, base `a48aaca9` = the integrated I37 tip; coordinator-confirmed base).** Suite green per the I37 verdict (705 runs / 2899 assertions / 0 failures, +1 pre-existing skip); `SEAM_BENCH_OK`; s1–s9 exit 0 cold on this tree per the I37 verdict (15/15 gates), s10_editor_wrap exit 0 per the I35 verdict — the rehearsal re-runs all of them fresh as this freeze's control. pi source at `repos/pi` (1.1.0) is the oracle for every shape claim above; ruby_llm 2.1.0 / async 2.46.0 / ratatui_ruby 1.5.0 the dependency contracts (BRIEF §2).

9. **Open questions for the judge (plan-letter defaults chosen; alternatives itemized).**
   - **OQ-1 — live region vs pending transcript entry.** The plan letter's shape is "live-region rows … transient, never transcript entries". pi's mechanism parks the component in the chat/pending CONTAINERS (transcript side, finalized in place). Chosen: the plan letter — the live region (`live_lines`) already renders below transcript content and below streaming rows (both pi placements), is recomposed per frame (no registry/scrollback surgery on a block that grows every chunk), and dies without a trace at every terminal. Alternative (NOT taken): an I34-style pending block enqueued at run start and rebuilt in place per chunk — closer to pi's container mechanics but pays in-place-mutation churn (the I33 stale-start discipline) for a block whose size changes every chunk, and drags `transcript.rb` (this iteration's strongest must-not) into scope. Visible difference between the shapes: none when idle (both render below the transcript, viewport follows); while scrolled UP mid-run, pi's block scrolls with the buffer and live-region rows stay pinned to the region's tail — an edge the rig cannot see and the owner's follow-end habit does not exercise.
   - **OQ-2 — the loader hint's `escape/ctrl+c` bytes.** The port copies pi's `keyText` resolution byte-for-byte (`Running... (escape/ctrl+c to cancel)`), matching bytes over the port's actual esc-only abort binding — pi's own hint/behavior quirk, parity-first per BRIEF §8.
   - **OQ-3 — ANSI in chunk text.** Carried itemized cut (Grounds 2); if the owner ever streams ANSI-emitting commands and minds the mid-flight/settled bytes, the strip lands as its own slice touching BOTH paths.

10. **Non-goals.** Any change to completed-block bytes, the enqueue/expandable machinery, or the replay path (`transcript.rb` is must-not-touch); the tool (model-facing) bash's render (I34's pending block owns that surface; `execute` keeps `on_chunk: nil`); the deferred-completed-placement divergence (Grounds 6d); the editor's bash-TYPING mode border (existing parity); ANSI/binary sanitization (OQ-3); an s11 settled `!`-scenario for the differ (the completed bytes are claimed parity-true and the probe's settled frame carries per-app facts — a byte-diff scenario is a cheap backlog note if the owner wants it pinned); footer, MOTD, compaction, session recording (the record already carries the final output only — unchanged).

## Specification

# Specification — I38 user-bash-streaming

- **Objective.** Close the user-bash mid-flight divergence (BRIEF §8; Grounds 1): while a `!`/`!!` command runs, tart renders pi's RUNNING block in the live region — blank, `─` border (bashMode, `dim` for `!!`), `$ <command>` bold header, the accumulated output rows (muted, the completed block's last-20 preview discipline, toggle-aware), a blank + the loader row (`Running... (escape/ctrl+c to cancel)`, spinner in the block's colorKey, message muted, 80 ms time-derived dwell, anchored at run start), `─` border — appended BELOW transcript content and BELOW any streaming assistant rows (pi's chat/pending placements, Grounds 6). Chunks flow through an `on_chunk` seam on `Tools::Bash#run_user` over the EXISTING bridge queue to the reactor, where they mutate render state and request a draw. The completed block flushes exactly as today (byte-identical, same enqueue, same expandable registration); the live rows are transient — never transcript entries — and every terminal path clears them. Settled screens must not move (s1–s10).

- **Port shape (single-writer surface work; the constructor-seam idiom of decomp-wave4 is the house style).**
  - **The execution seam (lib/tart/tools/bash.rb).** `run_user(command, on_chunk: nil)` threads the proc through `spawn_and_stream` into `drain_pipe`: after each pipe read appends to the accumulator, `on_chunk&.call(text.gsub("\r", ""))` — CR-REMOVED per chunk, the same rule the returned content applies (Grounds 2; pi's executor discipline). `execute` (the model-facing tool) passes nothing — its render is I34's pending block, unchanged. The rolling accumulator, truncation, spill, and cancellation contracts are untouched; a cancelled run's partial chunks may still fire the seam after the reactor-side wait died (harmless — see the UserBash wiring).
  - **The UserBash wiring (lib/tart/render/user_bash.rb).** The bridge run block currently discards yielded items; it now forwards each chunk item to a new constructor-injected `stream_chunk_sink` (reactor fiber — the bridge yields there; Grounds 5). Run start notifies a `stream_start_sink` with `(command, excluded)` before the task spawns; EVERY terminal path — `finish`'s outcome arm, `finish`'s worker-error arm, and `cancel` — notifies a `stream_end_sink` exactly once (the clear is explicit, never implicit in a render sink). The seam names are the contract; Chat owns the state they mutate. The single-flight gate, escape-cancel handshake, slot/sleep-loop, deferred records, and `request_draw` discipline are unchanged.
  - **The live region (lib/tart/render/chat.rb).** Chat holds the running block's render state (command, excluded, accumulated text, the bash loader's spinner anchor) mutated ONLY by the three sinks under the surface mutex; `live_lines` appends the running rows after the assistant rows (empty-assistant case: the running rows alone, own leading blank — the `return []` gate extends to the running state). The loader glyph derives from the injected `clock:` at render (the I37 `spinner_glyph` discipline — extract/share the math, house judgment) from a bash-run anchor set at `stream_start` (pi: a new Loader per component — independent of the border status's anchor). The running preview reads `@transcript_state.tool_output_expanded` at composition (mid-run ctrl+o toggles it, pi Grounds 6f). Per chunk: append + `@kernel.request_draw`. The animation window extends: `render_frame` re-arms while `busy?` OR a user-bash run is in flight (the 80 ms glyph must advance between chunks; `@busy` itself stays false — no border "Working" status from a bash run).
  - **The row composer (lib/tart/render/bash_block.rb).** A module-function `running_user_bash_rows(command, width, content:, excluded:, spinner_glyph:, expanded:)` composes the family above, sharing the completed path's exact primitives (`TUI.line` borders, `Panel.padded_fg_rows` header with `modifiers: [:bold]`, muted output rows, `USER_BASH_PREVIEW_LINES` last-20-of-last-20 discipline, `Panel.blank_line` spacers) and the loader row: one-space pad, spinner span in the block's colorKey, message span muted with pi's literal bytes `Running... (escape/ctrl+c to cancel)` (Grounds 3). The observable CONTRACT (property, not implementation): for any accumulated text T, the running rows == `user_bash_block_rows(command, content: T, <zero-status fields>, excluded:, expanded:)` with the status block replaced by [blank, loader row] — i.e. header/output/borders byte-shared with the completed family; and an empty T renders header + blank + loader row + border.

- **Tests (deterministic, in-repo; drive the public surface, no stubs).** New direct-class tests (test/render/ for the composer; test/bash_tool_test.rb for the seam) + chat-level tests through the existing kernel-task pattern (the escape-cancel test's `kernel.submitted` manual-reactor idiom, chat_test.rb:2861-2880): (1) mid-flight rows — a chunking command (`printf 'alpha\n'; sleep 0.2; printf 'beta\n'`) with a draw between chunks shows the running family (header, `alpha` row, loader row bytes) while the transcript has NO block; (2) settled replacement — after completion the transcript is byte-identical (rows + position) to a control chat that received only `enqueue_user_bash_block` with the same fields, and `live_lines` is empty; (3) the prefix property — composer-level: running rows for text T equal the completed family minus status plus [blank, loader row], for T empty / short / >20 lines / wrapped-long-line, both toggle states; (4) chunk-join discipline — sink-fed chunks `["par", "tial\r\nline2", "tail"]` render `partial` then the unterminated `line2tail` row (the appendOutput join, string-buffer equivalent); a CR-only chunk vanishes; (5) the seam — `run_user` with `on_chunk:` on a real quick command: the joined chunks equal the returned content after its CR-strip, and `execute` never fires a callback; (6) every terminal clears — outcome, worker-error (the ENOENT arm), and escape-cancel all leave zero live rows and zero `Running...` anywhere; the cancelled block keeps its partial output (existing behavior); (7) spinner — the injected clock advances the glyph at 80 ms boundaries, the anchor resets at run start, and it is independent of the border-status anchor; (8) the animation window — while a run is in flight, two draws with no chunk between advance the glyph (frames keep pacing; `@busy` false throughout — no border status renders); (9) replay — `replay_user_bash` over a recorded entry renders zero loader rows; (10) `!!` — the running block's border/header/spinner ride `Theme[:dim]`; (11) mid-run ctrl+o toggles the running preview (collapsed last-20 ↔ whole), no hint row either state; (12) the single-flight warning and escape-routing tests stay green unchanged.

- **Rig (the frozen instrument — the I34 probe discipline).** New `gems/tui-split-rig/bin/user-bash-stream-probe` + driver `scenarios/probe_user_bash.yml` (name `probe_user_bash`; `prompt:` = the `!`-command line `!for i in 1 2 3; do echo "probe line $i"; sleep 1; done`; `expected_requests: 1` with one inert scripted stream reply that is never requested — loader constraints, Grounds 7). The probe boots BOTH apps through the runner's staging (the tool-pending probe's shape), settles boot, `send-keys` the command line + Enter, captures plain+styled frame pairs at 0.5 s until 4 identical (settled = spinner gone). Default (evidence) mode: numbered frame pairs + a digest line per frame (header row? loader row? output-row count), exit 0. `--gate` mode: per app PASS iff (a) ≥1 pre-settle frame shows the header row AND the loader row AND ≥1 OUTPUT row (a `probe line N` row that is not the header line — chunk rows painted before completion, the iteration's core claim), (b) the settled frame shows the header row and all three output rows and ZERO loader rows, (c) every loader-bearing frame also carries the header row (the loader rides the block). Both apps must pass (pi = oracle control); on pass print `USER_BASH_STREAM_GATE_OK` and exit 0, else the failing condition's per-frame digest and exit 1. No registry or scenario changes beyond the new probe yml (additions-only if genuinely forced, each evidenced).

- **Output format.** Raw evidence to scratch: file list + wc; the new tests with verbatim run tails; suite counts before/after; the probe gate command line + exit code + digest tail (both modes); the s1–s10 exit codes; PHASE 0 disagreements mandatory (the Grounds 2/3/5/7 premises are checkable against repos/pi, the gem, and the bridge). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s10 exit 0; SHORT out-dirs — deep paths trip the pre-existing footer-cwd truncation sensitivity; allow 60 s+ each, both apps boot); the new gate: `gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i38-ubs` (allow 120 s+; runs both apps ~20 s). pi sources: `repos/pi/packages/coding-agent/src/modes/interactive/components/bash-execution.ts` (whole file), `interactive-mode.ts:6987-7062` + `:3074` + `:3389` + `:4861-4867`, `core/bash-executor.ts:48-160`, `packages/tui/src/components/loader.ts`, `packages/tui/src/keybindings.ts:155-158`. Read user_bash.rb's threading doc and bridge.rb's yield loop before designing (Grounds 5).

- **Boundaries.** May touch exactly: `lib/tart/tools/bash.rb`, `lib/tart/render/{user_bash,chat,bash_block}.rb`, `test/chat_test.rb`, `test/render/**`, `test/bash_tool_test.rb`, `gems/tui-split-rig/bin/user-bash-stream-probe`, `gems/tui-split-rig/scenarios/probe_user_bash.yml`, `gems/tui-split-rig/test/**`. Must not: `lib/tart/render/transcript.rb` (the completed path, the expandable registry, and the `tool_output_expanded` reader are frozen — the live region reads, never writes), `lib/tart/agent/{loop,bridge,session}.rb` (the events and the yield loop are the contract as-is), `lib/tart/render/{editor,motd,viewport,selection,footer,kill_ring,model_menu,picker,text,panel,file_blocks,tool_block}.rb`, `lib/tart/{theme,settings,commands,models,identity}.rb`, `bin/tart`, `bench/**`, any existing scenario yml, `gems/tui-split-rig/registry.yml` (additions-only if genuinely forced — then evidenced), any golden. Out of scope: Grounds 10's list. No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/tools/bash.rb
    - lib/tart/render/user_bash.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/bash_block.rb
    - test/chat_test.rb
    - test/render/**
    - test/bash_tool_test.rb
    - gems/tui-split-rig/bin/user-bash-stream-probe
    - gems/tui-split-rig/scenarios/probe_user_bash.yml
    - gems/tui-split-rig/test/**
```

## Acceptance Criteria

# Acceptance Criteria — I38 user-bash-streaming

**AC1 — the running block renders mid-flight (the iteration's core claim).** While a `!`/`!!` command executes, the live region renders pi's running block below transcript content and below any streaming assistant rows: leading blank, `─` border in the block's colorKey (`bashMode`; `dim` for `!!`), `$ <command>` bold header, the accumulated output rows (muted, the completed family's last-20-of-last-20 preview discipline, `ctrl+o`-toggle-aware, NO hidden-lines hint while running), blank, the loader row (one-space pad, spinner in the colorKey advancing on the 80 ms time dwell, message span muted with pi's exact bytes `Running... (escape/ctrl+c to cancel)`), `─` border. For any accumulated text T the running rows share the completed family's header/output/border bytes (the prefix property), and T empty renders header + blank + loader row + border. Unit-pinned (composer + chat-level mid-flight draws) and live-pinned by AC5.

**AC2 — the completed block flushes exactly as today; the live rows are transient.** At every terminal path — normal completion, worker error (the ENOENT arm), and escape-cancel — the completed block (or the existing error/cancelled shapes) enqueues through today's `enqueue_user_bash_block` path with byte-identical rows and position to a control chat that received only that enqueue, the live rows are gone, and no frame ever shows both the live rows and the completed block. Replay renders zero loader rows. Post-integration, cold: s1–s10 all exit 0 (settled screens unmoved).

**AC3 — the chunk seam discipline.** `run_user(command, on_chunk:)` fires the callback per pipe-read with CR-REMOVED text (the returned content's own rule); the joined callback stream equals the returned content after its CR-strip; the model-facing `execute` path fires nothing. Mid-flight, an unterminated trailing line renders as its own row and the next chunk's first piece continues it (pi's appendOutput join, string-buffer equivalent); CR-only chunks vanish. `transcript.rb` is untouched (scope gate).

**AC4 — animation and spinner mechanics.** Frames keep pacing while a run is in flight (the glyph advances across draws with no chunk between — the animation window is open for the run) without `@busy` or any border working-status rendering from a bash run; the bash loader's anchor resets at each run start and is independent of the border status's anchor (pi: one Loader per component). Unit-pinned via the injected clock seam.

**AC5 — the frozen instrument.** `gems/tui-split-rig/bin/user-bash-stream-probe --gate --out <dir>` exits 0 cold (no live keys, quiet tmux server), for BOTH apps: (a) at least one pre-settle frame shows the header row AND the loader row AND at least one OUTPUT row (a `probe line N` row distinct from the header line — chunks painted before completion); (b) the settled frame shows the header row, all three output rows, and zero loader rows; (c) every loader-bearing frame also carries the header row. `USER_BASH_STREAM_GATE_OK` on stdout. The default (no `--gate`) evidence mode is exit 0 with the frame digest. This gate and the machinery tripwire are RED at base BY DESIGN (the streaming rows and the probe are this iteration's deliverables — the I34/I35 tripwire precedent; the gate's `test -x` guard makes the pre-build state a clean RED, not a 127).

**AC6 — quality.** Suite fully green with run-count delta > 0 (new tests; chat_test.rb surgery additive only); `SEAM_BENCH_OK`; the integrated diff touches exactly the declared set (scope gate); house style throughout (pi citations carried in comments, constructor-seam/module-function shapes preserved).

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
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i38-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i38-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i38-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i38-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i38-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i38-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i38-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i38-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i38-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/i38-s10
  expect:
    exit_code: 0

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i38-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: stream-machinery
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'on_chunk' lib/tart/tools/bash.rb && grep -q 'stream_chunk_sink' lib/tart/render/user_bash.rb && grep -q 'running_user_bash_rows' lib/tart/render/bash_block.rb && test -x gems/tui-split-rig/bin/user-bash-stream-probe && grep -q 'USER_BASH_STREAM_GATE_OK' gems/tui-split-rig/bin/user-bash-stream-probe && echo STREAM_MACHINERY_OK
  expect:
    exit_code: 0
    stdout_match: STREAM_MACHINERY_OK

- id: transcript-frozen
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git diff --name-only a48aaca9 HEAD -- lib/tart/render/transcript.rb | grep -q .; then exit 1; else echo TRANSCRIPT_FROZEN_OK; fi
  expect:
    exit_code: 0
    stdout_match: TRANSCRIPT_FROZEN_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only a48aaca9 HEAD | grep -qvE '^(lib/tart/tools/bash\.rb|lib/tart/render/user_bash\.rb|lib/tart/render/chat\.rb|lib/tart/render/bash_block\.rb|test/chat_test\.rb|test/render/|test/bash_tool_test\.rb|gems/tui-split-rig/bin/user-bash-stream-probe|gems/tui-split-rig/scenarios/probe_user_bash\.yml|gems/tui-split-rig/test/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I38-user-bash-streaming-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section user-bash-streaming prompt --append --lane <lane> --from build/I38-user-bash-streaming-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I38-user-bash-streaming-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence user-bash-streaming --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section user-bash-streaming verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify user-bash-streaming`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
