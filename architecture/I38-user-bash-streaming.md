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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section user-bash-streaming specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision user-bash-streaming`
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
`architect rehearse user-bash-streaming` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze user-bash-streaming` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse user-bash-streaming` — before the freeze, while
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
