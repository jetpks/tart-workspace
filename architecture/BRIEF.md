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

**Toggle seam (owner decision 2026-10-10, post-I04):** the write-boundary normalization is plumbed as a **default-off config seam now** (edit/write/bash write paths), so the post-parity flip is a config change, not a refactor. Default remains byte-exact pi parity; both modes test-proven. pi itself stays untouched (no upstream patch while porting — oracle discipline).

I04 outcome (2026-10-09): root cause established as pi's TUI-layer per-line width padding (see I04 Builder Report / Verdict) — not the tool pipeline, vindicating the defer decision. The port's renderer does not reproduce it (wraps, never pads); port-side exposure is a bounded transient residual only.

### §5.1 Foundation-mechanics carve-out (owner decision 2026-10-09, I03 Verdict)

**Signal delivery, process spawn/reap, and startup/shutdown/teardown ordering are a sanctioned deviation category.** The port swaps the foundation under pi's behavior — Node's single-process signal handling for Ruby + `async`'s fiber scheduler — and abstractions are not perfectly abstract: the foundation sometimes legitimately changes things further up. Where the Ruby/fiber ecosystem dictates a different mechanism, the port does what is idiomatic **for Ruby**, not what pi's Node implementation happened to do. Ruling instance: bash timeout-kill is two-phase `-TERM` → (bounded grace) → `-KILL` on the process group, vs pi's single-phase `-SIGKILL` (`shell.ts:187–207`) — kept (I03 deviation #1, resolved).

Discipline within the carve-out: (a) deviations are still **itemized in the parity table** every iteration — sanctioned, not silent; (b) each must be individually defensible on Ruby-ecosystem grounds, not convenience ("TERM gives children a graceful-shutdown chance" is a foundation argument; "we preferred different output text" is not); (c) **observable tool-pipeline behavior the model/user sees stays parity-first** — the carve-out covers the *mechanism* (how a process is stopped, how teardown is ordered), never the *contract* (what results, content, and status shapes come back).

## §6 Extension surface (amended 2026-10-13 — owner ruling on the interface probe's evidence)

pi's dispatch surface is **41 event channels** (57 payload shapes counting per-tool subtypes — this §'s original "~54 events" overstated; source `types.ts:1586-1657`). **Owner ruling: build features in natively over a minimal internal seam; the interface is not a TS-extension porting vehicle** — ~half the surface is pure data contract, but every real extension's value is JS-runtime/ecosystem code, and pi-subagents is SDK-bound beyond the interface (a facsimile that could host it would be a Ruby rebuild of pi's SDK). §8 parity flows through FEATURES, not mechanism — extensions are screen-observable only through what they do. The seam: the existing 10-event loop core + `register_tool`/`register_command` into the existing registry/tables, with `tool_call` block semantics (permission gates) and nextTurn message injection (memory) FIRST — the two that carry owner features. Built in natively: subagents (the delegation core), memory, herdr reporter. Loading stays Ruby-native (plain `.rb` files, project/global dirs) — a thin loader over the seam for owner-authored Ruby drop-ins only. Capped unless third-party extensions become a product goal: renderer registration, provider/MCP/virtual-model registration, any jiti analog. Skills, themes, keybindings, and prompt templates remain as resource kinds with pi-compatible discovery locations where cheap.

## §7 Definition of done

The harness is the owner's daily driver:

1. Interactive TUI: streaming render, inline viewport chat, working input/approval gates, resumable JSONL sessions.
2. All §3 tools functional with schema-gated safety and approval gates; bash timeouts kill process groups.
3. MCP servers connectable and usable.
4. Print mode works for headless runs (this project's own builder lanes can eventually run on it).
5. The §5 whitespace behavior is fixed and covered by tests (post-parity, per §5).
6. Compaction triggers and recovers correctly on long sessions.
7. A real multi-tool session run on this very space end-to-end, judged by gates.
8. **The §8 exact-parity bar: every pinned pty-tester scenario exits 0 cold from the project branch.**

## §8 The exact-parity program (owner course change, 2026-10-10)

The done bar moves from "port the used parts" to **full settled-screen parity**: run pi and tart
under identical scripted conditions, and an owner using pi in one tab and tart in another cannot
tell which is which — same header, glyphs, transcript rendering, footer, colors, everything.
Scope stays the §3 daily-driver surface; §5/§5.1 discipline is unchanged (deviations itemized,
never silent), and the instrument decides, not eyeballs.

- **Instrument:** pty-tester (merged `df0ece9`) — staged/sandboxed side-by-side runs of the pi
  oracle (1.1.0) and tart, settled `tmux capture-pane` diffing with a minimal difference-class
  registry (per-run path normalization only). A parity gate is `bin/pty-tester run <scenario>`
  exiting 0. Known divergences surface as unknown-candidate lines — **that candidate list IS the
  work list.** A difference class is pinned only by owner ruling, never to hide a defect
  (pty-tester BRIEF §2 discipline carries over verbatim).
- **Identity seam — the one sanctioned mechanism deviation:** tart renders **pi's identity by
  default** (pi's logo, name, version line, hints, onboarding text — byte-for-byte). The tart
  identity (the owner's art collection, `tart v0.1.0`, tart hints) returns across the app through
  a configuration seam pi does not have: settings key + env var + CLI flag, CLI > env > settings,
  default `pi`. This supersedes the 2026-10-10 ruling "do NOT copy pi's ascii art — the owner
  designs tart's own": the art collection lives behind the toggle; pi-mode copies pi's mark
  exactly.
- **Version string in pi-mode:** the MOTD version line renders the oracle's version (a tracked
  constant, e.g. `v1.1.0`), not tart's — indistinguishability is the point; it bumps when the
  oracle pin moves.
- **The toggle is identity-only.** Everything behind the identity seam is presentation (logo,
  name, version line, hints text). Behavior, colors, and rendering rules are parity-first in BOTH
  modes — tart-mode is the same engine with tart's name on it, not a fork of the render path.
