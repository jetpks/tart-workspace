# Project Brief: pi-rb — a modern async-Ruby port of the pi coding harness

## §1 Goal

Port/rewrite the parts of pi (the TypeScript coding-agent harness, forked at `repos/pi`) that we actually use, as a Ruby harness built on the socketry ecosystem. Motivations, in priority order:

1. **Owner-fixability** — software the owner can debug and change in a language they know deeply.
2. **Fix the trailing-whitespace copy defect** — see §5 (deferred to post-parity).
3. **Investment alignment** — the owner publishes adjacent Ruby AI tooling (`space-inference-gateway` is a production Falcon/async-Ruby service; `space-cadet`, `repo-tender`, `gigatoken-rb` set house style).

The deliverable is a single-user daily-driver harness, not a distribution product.

## §2 Constraints

- **Ruby**, targeting the owner's environment (arm64-darwin; ratatui_ruby ships prebuilt arm64-darwin gems, Ruby 3.2–4.0).
- **Concurrency:** the `async` gem (socketry) ≥ 2.46 — fiber-scheduler reactor as the core substrate. `async-io` is deprecated; build on `async`/`io-event` primitives.
- **TUI:** `ratatui_ruby` 1.5.0 — **LGPL-3.0-or-later**, young (first release 2025-12), single dominant maintainer. All ratatui_ruby calls must sit behind our own TUI interface module so the binding remains swappable. It provides no syntax highlighting or markdown rendering — that subsystem is ours.
- **LLM:** `ruby_llm` ≥ 2.1.0 — the harness drives the tool loop itself via `Chat#generate`/`run_tools`/`step`/`complete?`/`waiting?` with `Tool.requires_approval` as the native permission gate. No `provider.complete` bypass (the historical reason for bypassing is absorbed into 2.1). Registry + custom OpenAI-compatible endpoints must cover local inference (`space-inference-gateway`).
- **MCP:** ruby_llm's built-in client (stdio + Streamable HTTP + custom transports, plain Ruby). No separate MCP gem.
- **No Rails**, no web framework. Plain Ruby with a clean library/CLI seam (house style per the owner's gems).
- Out of respect for upstream: this is a rewrite, not a fork of pi's code; pi remains a design reference and a compatibility target for session/tool UX expectations.

## §3 Scope (evidence-backed; see `build/research/pi-port-report.md` §1)

**In scope:** the agent loop (pi `packages/agent`); the coding-agent core — built-in tools (`read`, `edit`, `write`, `bash`, `find`, `grep`, `ls`), session persistence (append-only JSONL, versioned, resumable), compaction, skills, settings, slash commands; interactive TUI mode; print mode; MCP via ruby_llm; reduced extension surface (§6).

**Out of scope (deferred, not lost):** the chord cluster — `chord`, `durable`, `env`, `protocol`, `client`, `server` (≈35k of pi's ~160k lines, reached only from experimental/RPC paths) — plus `evals`, `codemode`, `telemetry`, and RPC mode. Verified: interactive mode imports only `pi-agent-core`, `pi-ai`, `pi-tui`.

## §4 Architecture

- **One async reactor owns the process** (or the seam decision in §4.1 chooses the embedding): raw-TTY input, LLM SSE streaming, subprocess execution, and timers all live on fiber-scheduler primitives.
- **Core loop:** pi's loop shape — outer loop over queued user messages, inner loop over tool-call batches — mapped onto `Chat#step`/`run_tools` with `requires_approval` gating destructive tools. **Safety by schema-gating: unsafe tools are invisible (removed from the tool schema), not blocked at call time.**
- **Bash tool:** `pgroup: true` spawn; one fiber per output pipe (Open3 buffer-deadlock avoidance); timeout kill by negative-pid `Process.kill('-TERM', pgid)` escalating to `-KILL`; every pid reaped.
- **Interrupts:** raw mode disables ISIG — Ctrl+C is byte 0x03 handled in-band; a `Signal.trap` safety net only cancels tasks.
- **§4.1 The TUI seam (RESOLVED by I01 seam-spike — evidence: `architecture/I01-seam-spike.md`, raw artifacts in `build/I01-seam-spike-seam-probe/scratch/`):** Design **(b)** adopted — the reactor owns the process (`Async::Reactor`, which installs the Fiber scheduler; bare `Async::Scheduler` cannot be pumped standalone); a dedicated thread polls `RatatuiRuby.poll_event(timeout: 0.016)` (~60 Hz) and bridges native events into the reactor via thread-safe `Async::Queue`; synthetic/cross-thread events flow via `SyntheticEvents.push` + in-loop drain each frame — **not** `inject_event` (that API does not exist; the native inject queue is thread-local, `events.rs:17`, so cross-thread inject is invisible). **Frame pacing (human decision 2026-10-09): 60 fps while anything is animating, not constant** — frames are deadline-paced at 60 Hz (16.67 ms) while an animation window is open (measured floor ≥ 58 fps, held by a gate), and event-driven — no fixed-rate burn — while the screen is static. Measured basis (identical 30 s workload, two runs per design): B's latency is bounded and structural (p95 17.6 ms ≈ frame budget) vs (a)'s unbounded load-dependent cadence/CPU (97.7–106 fps, 1.9–16.6% CPU across identical runs) and (c)'s hard ~18 ms input-latency floor for the cheapest CPU (3.1–5.2%). (c) is the fallback if low-power CPU ever dominates. Any additional cross-thread shared state beyond the two sanctioned seams needs a mutex (observed requirement).
- **Compaction:** port pi's pure-function design (token estimation, cut-point selection) anchored on provider-reported token counts; drive from `RubyLLM::ContextLengthExceededError` and incremental usage.
- **Known footguns to design around:** ruby_llm fallbacks are per-request (a down vendor still eats timeout+retries each call — add circuit breaking if it bites); some providers 400 on non-default temperature; ratatui scroll offset caps at 65,535 lines (virtualize history).

## §5 The whitespace deviation (DEFERRED — parity first; owner decision 2026-10-09)

The original plan normalized trailing whitespace at the port's write boundaries. **Deferred until the port reaches behavioral parity with pi.** Two reasons:

1. **The root cause is not established.** The pipeline itself is confirmed to round-trip trailing whitespace verbatim (read verbatim; write verbatim; edit strips trailing WS *only in match-space* — `repos/pi/packages/coding-agent/src/core/tools/edit-diff.ts:29–44` — and deliberately re-copies original bytes on unchanged lines). The owner's actual annoyance is **copy/pasting out of the pi TUI**, which may be a TUI-layer artifact (space-filling for partial redraws) rather than the tool pipeline. That hypothesis is investigated with file:line evidence against pi's `tui` package when the port's TUI iteration lands — not assumed.
2. **Oracle discipline.** Porting with deliberate deviations intermixed makes parity mismatches unattributable — a diff against pi could be our delta or a real bug, and we can't tell. Parity first; annoyances fixed after, as isolated, tested changes.

So: the tool pipeline is ported **verbatim-parity** (trailing whitespace round-trips exactly as pi's does, including the match-space-only normalization in edit); the copy/paste investigation happens at the TUI iteration; the normalization itself lands as its own post-parity iteration with tests. The founding-defect framing is retained as motivation and end-state (§7.5), not as an in-flight requirement.

## §6 Extension surface

pi's contract is ~54 events + register APIs + jiti TS loading. The port starts with a **reduced core event set** — session lifecycle, turn lifecycle, message lifecycle, tool-call lifecycle, plus `register_tool`/`register_command` — and grows on demand. Loading is Ruby-native (plain `.rb` files from project/global dirs); no jiti analog. Skills, themes, keybindings, and prompt templates remain as resource kinds with pi-compatible discovery locations where cheap.

## §7 Definition of done

The harness is the owner's daily driver:

1. Interactive TUI: streaming render, inline viewport chat, working input/approval gates, resumable JSONL sessions.
2. All §3 tools functional with schema-gated safety and approval gates; bash timeouts kill process groups.
3. MCP servers connectable and usable.
4. Print mode works for headless runs (this project's own builder lanes can eventually run on it).
5. The §5 whitespace behavior is fixed and covered by tests (post-parity, per §5).
6. Compaction triggers and recovers correctly on long sessions.
7. A real multi-tool session run on this very space end-to-end, judged by gates.
