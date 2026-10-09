# I03: agent-loop

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

<!-- WHY. Research/spec distilled: problem, decision + why, requirements,
non-goals, verified facts WITH citation URLs, open questions. If
architecture/BRIEF.md exists, cite **BRIEF §N** instead of restating — shrink this
to deltas + citations. Optional — delete this section for iterations that needed
no research. Write + commit: `architect section agent-loop grounds --from <file>`. -->

## Specification

- **Objective:** Build the **agent/tool loop** (BRIEF §3/§4) as a behavior-parity port of pi's agent core on the I02 kernel: the outer loop over queued user messages and inner loop over tool-call batches, driven through `ruby_llm` (`Chat#step`/`run_tools`-family APIs, BRIEF §2), with the seven built-in tools (`read`, `edit`, `write`, `bash`, `find`, `grep`, `ls`) ported **verbatim-parity** from `repos/pi/packages/coding-agent/src/core/tools/`, schema-gated safety, and approval gating. **Parity-first discipline (BRIEF §5, deferred 2026-10-09): pi is the oracle.** The tool pipeline round-trips trailing whitespace exactly as pi's does (edit strips only in match-space, `edit-diff.ts:29–44`); **no whitespace normalization at any write boundary** — the §5 fix is post-parity work and is explicitly out of scope here. Any place the port's semantics would differ from pi's is a *disagreement to raise*, never a silent improvement. Also folds in the six I02 carry-ins (kernel/bench hygiene, I02 Verdict) — they're small, kernel-local, and this lane touches the same files. **Why now:** the kernel substrate is gate-held in-repo (I02), and the TUI iteration needs real agent content to stream; building it the other way means mocking the message shapes and reworking them later.
- **Output format:** raw tables/JSON only in the report (absolute path below): PHASE 0 findings table (spec-vs-reality, with evidence — every ruby_llm verify item), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, list of files created, plus the recorded judgment calls: the approval mechanism as built (ruby_llm native vs hook wrapper — with the gem-source evidence), the mock endpoint's wire details, the system-prompt dynamic segments, the blockless-`run` disposition, and **a parity-deviation table (must be empty or itemized as raised disagreements — any silent deviation is a defect)**. No interpretation beyond what the spec asks to record. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Runtime deps → `raspberry-pi.gemspec`: keep `async ~> 2.46`, `ratatui_ruby` exact `1.5.0`; **add `ruby_llm ~> 2.1`** (BRIEF §2: ≥ 2.1.0). Dev deps → `Gemfile`: `minitest ~> 5.20`, `rake`, `irb`.
  - **Verify against the installed gems before coding** (read gem source: `bundle info <gem> --path`), record each in the findings table: `Chat#generate`/`step`/`complete?`/`waiting?`/`run_tools` semantics in the resolved 2.x (which exist, what they return, how a tool-call batch executes); the `Tool` definition API (parameter schemas) and **`requires_approval` mechanics — exactly what happens on pending/denied approval, and what result shape the model sees**; custom OpenAI-compatible endpoint registration (`base_url`/`api_key`) and the SSE wire format the client expects (your test mock must be wire-compatible — record it); streaming event shapes (text deltas, tool-call events) and how tool results return into the context; `RubyLLM::ContextLengthExceededError` presence (record only — compaction is out of scope).
  - **pi reference (read-only oracle, `repos/pi`):** `packages/agent/src/agent-loop.ts` (loop shape: `runAgentLoop`, `runToolCall`, `ToolCallHooks` — permission checks are hooks, line ~805), `packages/agent/src/types.ts` (AgentEvent shapes), `packages/coding-agent/src/core/tools/{read,write,edit,bash,find,grep,ls}.ts` + `edit-diff.ts`, `path-utils.ts`, `truncate.ts`, `file-mutation-queue.ts`, `output-accumulator.ts`, and `packages/coding-agent/src/core/system-prompt.ts` (port the composed prompt verbatim; record its dynamic segments). Port behavior, not TypeScript shape — Ruby-idiomatic code with pi-identical observable semantics.
  - **I02 carry-ins (defect ledger, file:line per the I02 Verdict):** (1) `Core::Loop#run` teardown (currently loop.rb:90–93) must be exception-safe (`ensure`) and `Signal.trap("INT")` (loop.rb:82) restored after run; (2) `Poller#stop` (poller.rb:32) must surface a missed `join`; (3) blockless `run` (supervise's early return skips STOP) — guard or documented event-only mode, recorded; (4) bench hardening: `state[:native_seen]` never initialized (seam_bench.rb:155), `finish` crashes on nil `extras` masking the original error, `drain.value` joined unbounded (seam_bench.rb:91), kill-probe spawned without fd redirection so it can hold the pty slave in its own pgroup (seam_bench.rb:295). Minor, fix if cheap and record: unlocked `stats`/`interrupted?` reads; single-use `Loop`.
  - **House style:** as I02 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true` everywhere, Rake default `:test`). The I02 `ScriptedSession` seam-double pattern extends to the model: **a local mock OpenAI-compatible endpoint over TCP (127.0.0.1, ephemeral port) serving scripted SSE responses** — the real ruby_llm HTTP + custom-endpoint path, hermetic, the same pattern the bench already uses for SSE.
  - Bench and every long command: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit the network beyond localhost or require API keys.
- **Boundaries:**
  - **May touch (repo `repos/raspberry-pi`, single lane — agent work and carry-ins share gemspec/Gemfile/test/README, so they run as one):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (dev/verification section only), `.gitignore`.
  - **Must not touch:** `repos/pi/**` and every other repo (read-only oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write command, no real LLM API calls or keys.
  - **Out of scope:** TUI widgets/streaming-render UX (the agent surfaces content via the existing minimal renderer/status-panel seam only), session persistence/JSONL, compaction, skills/settings/slash commands, MCP, print mode, reduced extension surface (§6 — only the event callbacks this iteration's tests and a later TUI need), and **the §5 whitespace normalization — forbidden (parity-first; see Objective)**. No placeholders; search pi and the gems before implementing; full implementations only.
- **Deliverables:**
  1. **`lib/raspberry_pi/agent/**` — the agent loop (BRIEF §4):** pi's loop shape on the I02 kernel — queued user messages, tool-call batches through ruby_llm, tool results back into the conversation, completion termination; runs as a task subtree on `Core::Loop` so a kernel interrupt cancels the in-flight turn; streaming text deltas accumulate and flow through the minimal status surface (no new TUI); a minimal event/callback surface (turn lifecycle, message deltas, tool-call lifecycle) sufficient for tests and the later TUI; the ported system prompt (`system-prompt.ts` verbatim, dynamic segments recorded).
  2. **`lib/raspberry_pi/tools/**` — the seven built-in tools, verbatim-parity (BRIEF §3/§5):** `read` (bytes verbatim — trailing WS, BOM, line endings per pi), `write` (verbatim), `edit` (pi's fuzzy matcher: match-space-only normalization incl. smart-quote/dash/space folding, unchanged-line byte preservation, line-ending detect/restore, context truncation), `bash` (`pgroup: true`, one fiber per output pipe, timeout kill by negative-pid `-TERM` escalating to `-KILL`, every pid reaped), `find`, `grep`, `ls` (pi semantics incl. path-utils/truncation). Where pi composes tools through wrappers (file-mutation-queue, output-accumulator), port the equivalent composition.
  3. **Safety gating (BRIEF §4):** schema-gating — disabled/unsafe tools never appear in the tool declarations sent to the model; approval gating — destructive tools behind approval using ruby_llm's native mechanism as verified (builder's call between `requires_approval` and a hook wrapper, recorded with gem-source evidence); injectable approval callback that runs on the kernel (interruptible); the denied-call outcome matches pi's semantics (recorded from pi source).
  4. **`test/**` — hermetic suite:** mock OpenAI-compatible endpoint (TCP, scripted SSE with tool calls) driving the real ruby_llm client; multi-turn round-trip; interrupt cancels in-flight turn; **golden parity tests for read/write/edit** — fixtures with expected outputs derived from pi's algorithm (trailing-WS cases included; §5 verbatim-parity is what's asserted), not from the port's own behavior; schema-gating asserted against the payload the mock endpoint receives; approval gate tests; bash timeout-kill tests (bounded, hermetic); carry-in tests (raising handler no longer leaks the poller; trap restored).
  5. **Carry-ins** per the defect ledger above; `bench/seam_bench.rb` stays green with the hardening in place.
- **Lane plan:** one lane, `agent-loop`, repo `raspberry-pi` — the carry-ins and the agent work share `Gemfile`/gemspec/`test/**`/README, so a second lane would overlap and must run as one. Touch set = the whole repo (as I02; the repo is otherwise untouched since bootstrap).
- **Effort call:** high — LLM-client seam verification (ruby_llm streaming/tool-call wire behavior), parity porting of seven tools against a TypeScript oracle, and concurrency-safe interrupt integration are all load-bearing.

```lanes
- name: agent-loop
  repo: raspberry-pi
  touch:
    - raspberry-pi.gemspec
    - Gemfile
    - Gemfile.lock
    - Rakefile
    - lib/**
    - test/**
    - bench/**
    - README.md
    - .gitignore
```

## Acceptance Criteria

**AC1 (the agent loop, on the substrate — BRIEF §2/§4).** After the lane, the suite proves via public behavior, **hermetically against a local mock OpenAI-compatible endpoint over TCP (the real ruby_llm client + custom-endpoint registration path — no network beyond localhost, no API keys)**: a scripted multi-turn conversation with tool calls round-trips — user message → model turn → tool-call batch → tool results returned to the model → model turn → completion; the agent runs as a task subtree on `Core::Loop`, and a kernel interrupt cancels the in-flight turn cleanly (interruption observable, no leaked tasks). pi's loop shape is the oracle (outer loop over queued messages, inner loop over tool-call batches — `repos/pi/packages/agent/src/agent-loop.ts`); the mapping onto ruby_llm is architect-read against the PHASE 0 findings. The `tui-seam` gate is a tripwire (agent/tools/tests never touch `RatatuiRuby`); `gem-pins` tripwires the ruby_llm `~> 2.1` dependency.

**AC2 (tools verbatim-parity — BRIEF §3, §5-deferred).** The seven built-in tools (`read`, `write`, `edit`, `bash`, `find`, `grep`, `ls`) are behavior-parity ports of pi's (`repos/pi/packages/coding-agent/src/core/tools/`): `read` returns bytes verbatim (trailing whitespace, BOM, line endings per pi's handling); `write` writes verbatim; `edit` implements pi's fuzzy matcher (match-space-only normalization incl. smart-quote/dash/space folding, unchanged-line byte preservation, line-ending detect/restore, context truncation); `bash` spawns `pgroup: true`, reads each pipe on its own fiber, kills timeouts by negative-pid `-TERM` escalating to `-KILL`, reaps every pid. **§5 verbatim-parity is the point: trailing whitespace round-trips exactly as pi's does — no normalization at any write boundary** — proven by golden tests whose fixtures and expected outputs are derived from pi's algorithm (trailing-WS cases included), never from the port's own output. The golden tests live in the suite (gate `suite-green`); the parity read against pi's source is architect-read, and the report's parity-deviation table must be empty or itemized as raised disagreements.

**AC3 (safety gating — BRIEF §4).** Schema-gating: a disabled/unsafe tool never appears in the tool declarations the model receives — asserted against the payload captured by the mock endpoint (the instrument, not a code-read). Approval gating: destructive tools gate behind approval via the mechanism the builder verified and recorded (ruby_llm native and/or a hook wrapper — the call is the lane's, the evidence must be gem-source or pi-source); an unapproved call produces the outcome shape pi produces (semantics recorded from pi source in the findings table); the approval callback is injectable and runs on the kernel (interruptible). Suite-proven.

**AC4 (bash safety, hermetic — BRIEF §4).** The suite proves the timeout-kill path end-to-end with bounded runtimes and explicit timeouts (no busy-wait): process-group child, timeout, negative-pid `-TERM` (escalating to `-KILL` when needed), reaped, no zombie, no leaked pipe readers.

**AC5 (I02 carry-ins honored — I02 Verdict).** Kernel teardown is exception-safe — a test raises inside the event handler/renderer and asserts the poller thread terminates (no orphan polling a restored terminal); `Signal.trap("INT")` disposition is restored after `run`; `Poller#stop` surfaces a missed join; blockless `run` is guarded or documented as an event-only mode (recorded); bench failure-path hardening: `native_seen` initialized, nil-`extras` guarded without masking the original error, bounded drain join, kill-probe fd redirection (the probe cannot hold the pty slave). Gates `suite-green` and `bench-seam` stay green with all of this in place — the hardening must not weaken the measured properties.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's tool guidance is recorded in the findings table with evidence, plus any disagreements with reasons — silent compliance is a defect. A parity deviation adopted silently is a defect (see AC2).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

## Builder Prompt

### agent-loop

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

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
No placeholder implementations — search the codebase (and the pi oracle)
before implementing; full implementations only. Write IDIOMATIC,
house-consistent code: read the neighbouring code and match its conventions
(naming, guards, predicates, error/persistence idioms, the language's
expressive collection/enumerable forms); well-factored and DRY-ish; terse but
clear; pragmatic, not clever — the smallest change that does the job, no
abstraction it doesn't need. Consistency with the surrounding code is part of
correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write)
is not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** Verify your
work by running the acceptance criteria's gate commands and record the
verbatim output. Do NOT commit and do NOT run any git write command
(commit/add/branch/reset/checkout) — the architect commits and merges after
verification, and verifies you made no commits. Do NOT delete lock files or
escalate privileges if a command fails; record the exact error and continue.
Do NOT use `run_in_background` (or shell `&`) for your own work — this process
terminates when you end your turn and reaps its own children, so backgrounded
work is SIGTERMed and its output lost while the run still exits 0; run long
commands serially in the foreground instead. Give every potentially long
command an explicit timeout; if a runtime will not start unattended
(interactive prompt, server with no timeout), record the exact failure in
your report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you,
/Users/eric/architect/spaces/20261009-pi-port/build/I03-agent-loop-agent-loop/report.md
(an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation,
no "promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report — the architect's tooling supplies the `### <lane>` heading
when it transcribes; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS
(list them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

Your working directory is the raspberry-pi worktree (a git worktree of the
raspberry-pi repo, branch lane/I03-agent-loop-agent-loop, based on the
project/pi-port branch — it contains the I02 event-loop kernel: TUI seam
module, Core::Loop, Core::Poller, the test suite, and bench/seam_bench.rb —
all of which must stay green). Space-root absolute paths given below are
READ-ONLY references.

=== OBJECTIVE (and why) ===

Build the **agent/tool loop** (BRIEF §3/§4) as a behavior-parity port of pi's
agent core on the I02 kernel: the outer loop over queued user messages and
inner loop over tool-call batches, driven through `ruby_llm`
(`Chat#step`/`run_tools`-family APIs, BRIEF §2), with the seven built-in tools
(`read`, `edit`, `write`, `bash`, `find`, `grep`, `ls`) ported
**verbatim-parity** from `repos/pi/packages/coding-agent/src/core/tools/`,
schema-gated safety, and approval gating. **Parity-first discipline (BRIEF §5,
deferred 2026-10-09): pi is the oracle.** The tool pipeline round-trips
trailing whitespace exactly as pi's does (edit strips only in match-space,
`edit-diff.ts:29–44`); **no whitespace normalization at any write boundary** —
the §5 fix is post-parity work and is explicitly out of scope here. Any place
the port's semantics would differ from pi's is a *disagreement to raise*,
never a silent improvement. Also folds in the six I02 carry-ins (kernel/bench
hygiene, I02 Verdict) — they're small, kernel-local, and this lane touches
the same files. Why now: the kernel substrate is gate-held in-repo (I02), and
the TUI iteration needs real agent content to stream.

Deliverables:

1. **`lib/raspberry_pi/agent/**` — the agent loop (BRIEF §4):** pi's loop
   shape on the I02 kernel — queued user messages, tool-call batches through
   ruby_llm, tool results back into the conversation, completion termination;
   runs as a task subtree on `Core::Loop` so a kernel interrupt cancels the
   in-flight turn; streaming text deltas accumulate and flow through the
   minimal status surface (no new TUI); a minimal event/callback surface
   (turn lifecycle, message deltas, tool-call lifecycle) sufficient for tests
   and the later TUI; the ported system prompt (`system-prompt.ts` verbatim,
   dynamic segments recorded).
2. **`lib/raspberry_pi/tools/**` — the seven built-in tools,
   verbatim-parity (BRIEF §3/§5):** `read` (bytes verbatim — trailing WS,
   BOM, line endings per pi), `write` (verbatim), `edit` (pi's fuzzy matcher:
   match-space-only normalization incl. smart-quote/dash/space folding,
   unchanged-line byte preservation, line-ending detect/restore, context
   truncation), `bash` (`pgroup: true`, one fiber per output pipe, timeout
   kill by negative-pid `-TERM` escalating to `-KILL`, every pid reaped),
   `find`, `grep`, `ls` (pi semantics incl. path-utils/truncation). Where pi
   composes tools through wrappers (file-mutation-queue,
   output-accumulator), port the equivalent composition.
3. **Safety gating (BRIEF §4):** schema-gating — disabled/unsafe tools never
   appear in the tool declarations sent to the model; approval gating —
   destructive tools behind approval using ruby_llm's native mechanism as
   verified (your call between `requires_approval` and a hook wrapper,
   recorded with gem-source evidence); injectable approval callback that runs
   on the kernel (interruptible); the denied-call outcome matches pi's
   semantics (recorded from pi source).
4. **`test/**` — hermetic suite:** mock OpenAI-compatible endpoint (TCP,
   scripted SSE with tool calls) driving the real ruby_llm client; multi-turn
   round-trip; interrupt cancels in-flight turn; **golden parity tests for
   read/write/edit** — fixtures with expected outputs derived from pi's
   algorithm (trailing-WS cases included; §5 verbatim-parity is what's
   asserted), not from the port's own behavior; schema-gating asserted
   against the payload the mock endpoint receives; approval gate tests; bash
   timeout-kill tests (bounded, hermetic); carry-in tests (raising handler no
   longer leaks the poller; trap restored).
5. **Carry-ins** per the defect ledger below; `bench/seam_bench.rb` stays
   green with the hardening in place.

=== OUTPUT FORMAT ===

Raw tables/JSON only: PHASE 0 findings table (spec-vs-reality, with evidence
— every ruby_llm verify item), test-suite output verbatim (pass/fail counts),
gate-command outputs verbatim, list of files created, plus the recorded
judgment calls: the approval mechanism as built, the mock endpoint's wire
details, the system-prompt dynamic segments, the blockless-`run` disposition,
and **a parity-deviation table (must be empty or itemized as raised
disagreements — any silent deviation is a defect)**. No interpretation
beyond what the spec asks to record. Every status claim backed by a command
result from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Environment: Ruby 4.0.7, arm64-darwin. Runtime deps → `raspberry-pi.gemspec`:
  keep `async ~> 2.46`, `ratatui_ruby` exact `1.5.0`; **add `ruby_llm ~> 2.1`**
  (BRIEF §2: ≥ 2.1.0). Dev deps → `Gemfile`: `minitest ~> 5.20`, `rake`, `irb`.
- **Verify against the installed gems before coding** (read gem source:
  `bundle info <gem> --path`), record each in the findings table:
  `Chat#generate`/`step`/`complete?`/`waiting?`/`run_tools` semantics in the
  resolved 2.x (which exist, what they return, how a tool-call batch
  executes); the `Tool` definition API (parameter schemas) and
  **`requires_approval` mechanics — exactly what happens on pending/denied
  approval, and what result shape the model sees**; custom OpenAI-compatible
  endpoint registration (`base_url`/`api_key`) and the SSE wire format the
  client expects (your test mock must be wire-compatible — record it);
  streaming event shapes (text deltas, tool-call events) and how tool results
  return into the context; `RubyLLM::ContextLengthExceededError` presence
  (record only — compaction is out of scope).
- **pi reference (read-only oracle, space-root absolute paths below):**
  `repos/pi/packages/agent/src/agent-loop.ts` (loop shape: `runAgentLoop`,
  `runToolCall`, `ToolCallHooks` — permission checks are hooks, line ~805),
  `packages/agent/src/types.ts` (AgentEvent shapes),
  `packages/coding-agent/src/core/tools/{read,write,edit,bash,find,grep,ls}.ts`
  + `edit-diff.ts`, `path-utils.ts`, `truncate.ts`, `file-mutation-queue.ts`,
  `output-accumulator.ts`, and `packages/coding-agent/src/core/system-prompt.ts`
  (port the composed prompt verbatim; record its dynamic segments). Port
  behavior, not TypeScript shape — Ruby-idiomatic code with pi-identical
  observable semantics.
- **I02 carry-ins (defect ledger, file:line per the I02 Verdict):**
  (1) `Core::Loop#run` teardown (currently loop.rb:90–93) must be
  exception-safe (`ensure`) and `Signal.trap("INT")` (loop.rb:82) restored
  after run; (2) `Poller#stop` (poller.rb:32) must surface a missed `join`;
  (3) blockless `run` (supervise's early return skips STOP) — guard or
  documented event-only mode, recorded; (4) bench hardening:
  `state[:native_seen]` never initialized (seam_bench.rb:155), `finish`
  crashes on nil `extras` masking the original error, `drain.value` joined
  unbounded (seam_bench.rb:91), kill-probe spawned without fd redirection so
  it can hold the pty slave in its own pgroup (seam_bench.rb:295). Minor, fix
  if cheap and record: unlocked `stats`/`interrupted?` reads; single-use
  `Loop`.
- **House style:** as I02 (gemspec-driven gem, `lib/raspberry_pi/**`, terse
  public-behavior minitest with the shared base, `# frozen_string_literal:
  true` everywhere, Rake default `:test`). The I02 `ScriptedSession`
  seam-double pattern extends to the model: **a local mock
  OpenAI-compatible endpoint over TCP (127.0.0.1, ephemeral port) serving
  scripted SSE responses** — the real ruby_llm HTTP + custom-endpoint path,
  hermetic, the same pattern the bench already uses for SSE.
- Bench and every long command: explicit timeout, serial foreground, never
  `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit
  the network beyond localhost or require API keys.
- Verification commands (run from the worktree root, record verbatim output):
  `bundle install --quiet && bundle exec rake` (suite) and
  `timeout 90 bundle exec ruby bench/seam_bench.rb` (bench).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

- **May touch (your worktree = the raspberry-pi repo):**
  `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`,
  `test/**`, `bench/**`, `README.md` (dev/verification section only),
  `.gitignore`.
- **Must not touch:** `repos/pi/**` and every other repo (read-only
  oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`,
  no git write command, no real LLM API calls or keys.
- **Out of scope:** TUI widgets/streaming-render UX (the agent surfaces
  content via the existing minimal renderer/status-panel seam only), session
  persistence/JSONL, compaction, skills/settings/slash commands, MCP, print
  mode, reduced extension surface (§6 — only the event callbacks this
  iteration's tests and a later TUI need), and **the §5 whitespace
  normalization — forbidden (parity-first; see OBJECTIVE)**. No placeholders;
  search pi and the gems before implementing; full implementations only.

=== DISAGREEMENT RULINGS (from prior sessions) ===

I01's findings (SyntheticEvents.push not inject_event; Async::Reactor not
bare Scheduler; the pty 0×0 trap; the gem pins) and I02's rulings (hybrid
sleep+spin pacing — SPIN_MARGIN is a measured necessity; dev deps in Gemfile;
exact ratatui_ruby 1.5.0 pin) are settled — absorbed into this spec as
binding carry-ins. **Parity-first is the newest settled ruling (BRIEF §5
deferred, 2026-10-09): the tool pipeline ports verbatim, whitespace
normalization is out of scope, and the copy/paste root cause is investigated
at the TUI iteration — not here.** Re-litigating settled rulings without new
evidence is noise; finding NEW spec-vs-reality conflicts (especially in
ruby_llm's actual 2.x API vs what this spec assumes) is your job.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

**AC1 (the agent loop, on the substrate — BRIEF §2/§4).** After the lane, the
suite proves via public behavior, **hermetically against a local mock
OpenAI-compatible endpoint over TCP (the real ruby_llm client +
custom-endpoint registration path — no network beyond localhost, no API
keys)**: a scripted multi-turn conversation with tool calls round-trips —
user message → model turn → tool-call batch → tool results returned to the
model → model turn → completion; the agent runs as a task subtree on
`Core::Loop`, and a kernel interrupt cancels the in-flight turn cleanly
(interruption observable, no leaked tasks). pi's loop shape is the oracle
(outer loop over queued messages, inner loop over tool-call batches —
`repos/pi/packages/agent/src/agent-loop.ts`); the mapping onto ruby_llm is
architect-read against the PHASE 0 findings. The `tui-seam` gate is a
tripwire (agent/tools/tests never touch `RatatuiRuby`); `gem-pins` tripwires
the ruby_llm `~> 2.1` dependency.

**AC2 (tools verbatim-parity — BRIEF §3, §5-deferred).** The seven built-in
tools (`read`, `write`, `edit`, `bash`, `find`, `grep`, `ls`) are
behavior-parity ports of pi's (`repos/pi/packages/coding-agent/src/core/tools/`):
`read` returns bytes verbatim (trailing whitespace, BOM, line endings per
pi's handling); `write` writes verbatim; `edit` implements pi's fuzzy matcher
(match-space-only normalization incl. smart-quote/dash/space folding,
unchanged-line byte preservation, line-ending detect/restore, context
truncation); `bash` spawns `pgroup: true`, reads each pipe on its own fiber,
kills timeouts by negative-pid `-TERM` escalating to `-KILL`, reaps every
pid. **§5 verbatim-parity is the point: trailing whitespace round-trips
exactly as pi's does — no normalization at any write boundary** — proven by
golden tests whose fixtures and expected outputs are derived from pi's
algorithm (trailing-WS cases included), never from the port's own output.
The golden tests live in the suite (gate `suite-green`); the parity read
against pi's source is architect-read, and the report's parity-deviation
table must be empty or itemized as raised disagreements.

**AC3 (safety gating — BRIEF §4).** Schema-gating: a disabled/unsafe tool
never appears in the tool declarations the model receives — asserted against
the payload captured by the mock endpoint (the instrument, not a code-read).
Approval gating: destructive tools gate behind approval via the mechanism
the builder verified and recorded (ruby_llm native and/or a hook wrapper —
the call is the lane's, the evidence must be gem-source or pi-source); an
unapproved call produces the outcome shape pi produces (semantics recorded
from pi source in the findings table); the approval callback is injectable
and runs on the kernel (interruptible). Suite-proven.

**AC4 (bash safety, hermetic — BRIEF §4).** The suite proves the
timeout-kill path end-to-end with bounded runtimes and explicit timeouts (no
busy-wait): process-group child, timeout, negative-pid `-TERM` (escalating
to `-KILL` when needed), reaped, no zombie, no leaked pipe readers.

**AC5 (I02 carry-ins honored — I02 Verdict).** Kernel teardown is
exception-safe — a test raises inside the event handler/renderer and asserts
the poller thread terminates (no orphan polling a restored terminal);
`Signal.trap("INT")` disposition is restored after `run`; `Poller#stop`
surfaces a missed join; blockless `run` is guarded or documented as an
event-only mode (recorded); bench failure-path hardening: `native_seen`
initialized, nil-`extras` guarded without masking the original error,
bounded drain join, kill-probe fd redirection (the probe cannot hold the pty
slave). Gates `suite-green` and `bench-seam` stay green with all of this in
place — the hardening must not weaken the measured properties.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's
tool guidance is recorded in the findings table with evidence, plus any
disagreements with reasons — silent compliance is a defect. A parity
deviation adopted silently is a defect (see AC2).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

### agent-loop

RESCUE DISPATCH — read this preamble first, then execute the spec below.

Your predecessor builder on this exact lane was killed mid-flight by an
infrastructure timeout (the architect's dispatch harness reaped it at 65
minutes) — NOT a builder failure and NOT an AC verdict. The last observed
action was running `test/kernel_carryin_test.rb`. The worktree you inherit
contains its uncommitted work:

- `M`: Gemfile.lock, bench/seam_bench.rb, lib/raspberry_pi.rb,
  lib/raspberry_pi/core/loop.rb, lib/raspberry_pi/core/poller.rb,
  raspberry-pi.gemspec, test/test_helper.rb
- `??`: lib/raspberry_pi/agent/, lib/raspberry_pi/tools.rb,
  lib/raspberry_pi/tools/, test/agent_loop_test.rb, test/bash_tool_test.rb,
  test/fixtures/, test/golden_parity_test.rb, test/kernel_carryin_test.rb,
  test/support/, test/tools_test.rb

Treat ALL of it as untrusted: audit every piece against the SPEC and the
frozen ACCEPTANCE CRITERIA below from first principles — verify tool
semantics against the pi oracle (`repos/pi/packages/coding-agent/src/core/tools/`)
and the ruby_llm findings against the installed gem source yourself, exactly
as PHASE 0 requires (do the PHASE 0 verification even though your
predecesser may have done some — your findings table must be yours, backed
by commands you ran). Repair or rewrite whatever is wrong; keep what is
right. Do NOT discard work wholesale; do NOT run any git write command
(the worktree must stay uncommitted — the architect commits after
verification). Then finish the remaining deliverables, run the gate
commands, and write your report to the scratch file as usual. Your report
covers the finished lane as a whole — including the audited inherited work.

Then execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

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
No placeholder implementations — search the codebase (and the pi oracle)
before implementing; full implementations only. Write IDIOMATIC,
house-consistent code: read the neighbouring code and match its conventions
(naming, guards, predicates, error/persistence idioms, the language's
expressive collection/enumerable forms); well-factored and DRY-ish; terse but
clear; pragmatic, not clever — the smallest change that does the job, no
abstraction it doesn't need. Consistency with the surrounding code is part of
correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write)
is not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** Verify your
work by running the acceptance criteria's gate commands and record the
verbatim output. Do NOT commit and do NOT run any git write command
(commit/add/branch/reset/checkout) — the architect commits and merges after
verification, and verifies you made no commits. Do NOT delete lock files or
escalate privileges if a command fails; record the exact error and continue.
Do NOT use `run_in_background` (or shell `&`) for your own work — this process
terminates when you end your turn and reaps its own children, so backgrounded
work is SIGTERMed and its output lost while the run still exits 0; run long
commands serially in the foreground instead. Give every potentially long
command an explicit timeout; if a runtime will not start unattended
(interactive prompt, server with no timeout), record the exact failure in
your report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you,
/Users/eric/architect/spaces/20261009-pi-port/build/I03-agent-loop-agent-loop/report.md
(an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation,
no "promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report — the architect's tooling supplies the `### <lane>` heading
when it transcribes; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS
(list them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

Your working directory is the raspberry-pi worktree (a git worktree of the
raspberry-pi repo, branch lane/I03-agent-loop-agent-loop, based on the
project/pi-port branch — it contains the I02 event-loop kernel: TUI seam
module, Core::Loop, Core::Poller, the test suite, and bench/seam_bench.rb —
all of which must stay green). Space-root absolute paths given below are
READ-ONLY references.

=== OBJECTIVE (and why) ===

Build the **agent/tool loop** (BRIEF §3/§4) as a behavior-parity port of pi's
agent core on the I02 kernel: the outer loop over queued user messages and
inner loop over tool-call batches, driven through `ruby_llm`
(`Chat#step`/`run_tools`-family APIs, BRIEF §2), with the seven built-in tools
(`read`, `edit`, `write`, `bash`, `find`, `grep`, `ls`) ported
**verbatim-parity** from `repos/pi/packages/coding-agent/src/core/tools/`,
schema-gated safety, and approval gating. **Parity-first discipline (BRIEF §5,
deferred 2026-10-09): pi is the oracle.** The tool pipeline round-trips
trailing whitespace exactly as pi's does (edit strips only in match-space,
`edit-diff.ts:29–44`); **no whitespace normalization at any write boundary** —
the §5 fix is post-parity work and is explicitly out of scope here. Any place
the port's semantics would differ from pi's is a *disagreement to raise*,
never a silent improvement. Also folds in the six I02 carry-ins (kernel/bench
hygiene, I02 Verdict) — they're small, kernel-local, and this lane touches
the same files. Why now: the kernel substrate is gate-held in-repo (I02), and
the TUI iteration needs real agent content to stream.

Deliverables:

1. **`lib/raspberry_pi/agent/**` — the agent loop (BRIEF §4):** pi's loop
   shape on the I02 kernel — queued user messages, tool-call batches through
   ruby_llm, tool results back into the conversation, completion termination;
   runs as a task subtree on `Core::Loop` so a kernel interrupt cancels the
   in-flight turn; streaming text deltas accumulate and flow through the
   minimal status surface (no new TUI); a minimal event/callback surface
   (turn lifecycle, message deltas, tool-call lifecycle) sufficient for tests
   and the later TUI; the ported system prompt (`system-prompt.ts` verbatim,
   dynamic segments recorded).
2. **`lib/raspberry_pi/tools/**` — the seven built-in tools,
   verbatim-parity (BRIEF §3/§5):** `read` (bytes verbatim — trailing WS,
   BOM, line endings per pi), `write` (verbatim), `edit` (pi's fuzzy matcher:
   match-space-only normalization incl. smart-quote/dash/space folding,
   unchanged-line byte preservation, line-ending detect/restore, context
   truncation), `bash` (`pgroup: true`, one fiber per output pipe, timeout
   kill by negative-pid `-TERM` escalating to `-KILL`, every pid reaped),
   `find`, `grep`, `ls` (pi semantics incl. path-utils/truncation). Where pi
   composes tools through wrappers (file-mutation-queue,
   output-accumulator), port the equivalent composition.
3. **Safety gating (BRIEF §4):** schema-gating — disabled/unsafe tools never
   appear in the tool declarations sent to the model; approval gating —
   destructive tools behind approval using ruby_llm's native mechanism as
   verified (your call between `requires_approval` and a hook wrapper,
   recorded with gem-source evidence); injectable approval callback that runs
   on the kernel (interruptible); the denied-call outcome matches pi's
   semantics (recorded from pi source).
4. **`test/**` — hermetic suite:** mock OpenAI-compatible endpoint (TCP,
   scripted SSE with tool calls) driving the real ruby_llm client; multi-turn
   round-trip; interrupt cancels in-flight turn; **golden parity tests for
   read/write/edit** — fixtures with expected outputs derived from pi's
   algorithm (trailing-WS cases included; §5 verbatim-parity is what's
   asserted), not from the port's own behavior; schema-gating asserted
   against the payload the mock endpoint receives; approval gate tests; bash
   timeout-kill tests (bounded, hermetic); carry-in tests (raising handler no
   longer leaks the poller; trap restored).
5. **Carry-ins** per the defect ledger below; `bench/seam_bench.rb` stays
   green with the hardening in place.

=== OUTPUT FORMAT ===

Raw tables/JSON only: PHASE 0 findings table (spec-vs-reality, with evidence
— every ruby_llm verify item), test-suite output verbatim (pass/fail counts),
gate-command outputs verbatim, list of files created, plus the recorded
judgment calls: the approval mechanism as built, the mock endpoint's wire
details, the system-prompt dynamic segments, the blockless-`run` disposition,
and **a parity-deviation table (must be empty or itemized as raised
disagreements — any silent deviation is a defect)**. No interpretation
beyond what the spec asks to record. Every status claim backed by a command
result from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Environment: Ruby 4.0.7, arm64-darwin. Runtime deps → `raspberry-pi.gemspec`:
  keep `async ~> 2.46`, `ratatui_ruby` exact `1.5.0`; **add `ruby_llm ~> 2.1`**
  (BRIEF §2: ≥ 2.1.0). Dev deps → `Gemfile`: `minitest ~> 5.20`, `rake`, `irb`.
- **Verify against the installed gems before coding** (read gem source:
  `bundle info <gem> --path`), record each in the findings table:
  `Chat#generate`/`step`/`complete?`/`waiting?`/`run_tools` semantics in the
  resolved 2.x (which exist, what they return, how a tool-call batch
  executes); the `Tool` definition API (parameter schemas) and
  **`requires_approval` mechanics — exactly what happens on pending/denied
  approval, and what result shape the model sees**; custom OpenAI-compatible
  endpoint registration (`base_url`/`api_key`) and the SSE wire format the
  client expects (your test mock must be wire-compatible — record it);
  streaming event shapes (text deltas, tool-call events) and how tool results
  return into the context; `RubyLLM::ContextLengthExceededError` presence
  (record only — compaction is out of scope).
- **pi reference (read-only oracle, space-root absolute paths below):**
  `repos/pi/packages/agent/src/agent-loop.ts` (loop shape: `runAgentLoop`,
  `runToolCall`, `ToolCallHooks` — permission checks are hooks, line ~805),
  `packages/agent/src/types.ts` (AgentEvent shapes),
  `packages/coding-agent/src/core/tools/{read,write,edit,bash,find,grep,ls}.ts`
  + `edit-diff.ts`, `path-utils.ts`, `truncate.ts`, `file-mutation-queue.ts`,
  `output-accumulator.ts`, and `packages/coding-agent/src/core/system-prompt.ts`
  (port the composed prompt verbatim; record its dynamic segments). Port
  behavior, not TypeScript shape — Ruby-idiomatic code with pi-identical
  observable semantics.
- **I02 carry-ins (defect ledger, file:line per the I02 Verdict):**
  (1) `Core::Loop#run` teardown (currently loop.rb:90–93) must be
  exception-safe (`ensure`) and `Signal.trap("INT")` (loop.rb:82) restored
  after run; (2) `Poller#stop` (poller.rb:32) must surface a missed `join`;
  (3) blockless `run` (supervise's early return skips STOP) — guard or
  documented event-only mode, recorded; (4) bench hardening:
  `state[:native_seen]` never initialized (seam_bench.rb:155), `finish`
  crashes on nil `extras` masking the original error, `drain.value` joined
  unbounded (seam_bench.rb:91), kill-probe spawned without fd redirection so
  it can hold the pty slave in its own pgroup (seam_bench.rb:295). Minor, fix
  if cheap and record: unlocked `stats`/`interrupted?` reads; single-use
  `Loop`.
- **House style:** as I02 (gemspec-driven gem, `lib/raspberry_pi/**`, terse
  public-behavior minitest with the shared base, `# frozen_string_literal:
  true` everywhere, Rake default `:test`). The I02 `ScriptedSession`
  seam-double pattern extends to the model: **a local mock
  OpenAI-compatible endpoint over TCP (127.0.0.1, ephemeral port) serving
  scripted SSE responses** — the real ruby_llm HTTP + custom-endpoint path,
  hermetic, the same pattern the bench already uses for SSE.
- Bench and every long command: explicit timeout, serial foreground, never
  `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit
  the network beyond localhost or require API keys.
- Verification commands (run from the worktree root, record verbatim output):
  `bundle install --quiet && bundle exec rake` (suite) and
  `timeout 90 bundle exec ruby bench/seam_bench.rb` (bench).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

- **May touch (your worktree = the raspberry-pi repo):**
  `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`,
  `test/**`, `bench/**`, `README.md` (dev/verification section only),
  `.gitignore`.
- **Must not touch:** `repos/pi/**` and every other repo (read-only
  oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`,
  no git write command, no real LLM API calls or keys.
- **Out of scope:** TUI widgets/streaming-render UX (the agent surfaces
  content via the existing minimal renderer/status-panel seam only), session
  persistence/JSONL, compaction, skills/settings/slash commands, MCP, print
  mode, reduced extension surface (§6 — only the event callbacks this
  iteration's tests and a later TUI need), and **the §5 whitespace
  normalization — forbidden (parity-first; see OBJECTIVE)**. No placeholders;
  search pi and the gems before implementing; full implementations only.

=== DISAGREEMENT RULINGS (from prior sessions) ===

I01's findings (SyntheticEvents.push not inject_event; Async::Reactor not
bare Scheduler; the pty 0×0 trap; the gem pins) and I02's rulings (hybrid
sleep+spin pacing — SPIN_MARGIN is a measured necessity; dev deps in Gemfile;
exact ratatui_ruby 1.5.0 pin) are settled — absorbed into this spec as
binding carry-ins. **Parity-first is the newest settled ruling (BRIEF §5
deferred, 2026-10-09): the tool pipeline ports verbatim, whitespace
normalization is out of scope, and the copy/paste root cause is investigated
at the TUI iteration — not here.** Re-litigating settled rulings without new
evidence is noise; finding NEW spec-vs-reality conflicts (especially in
ruby_llm's actual 2.x API vs what this spec assumes) is your job.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

**AC1 (the agent loop, on the substrate — BRIEF §2/§4).** After the lane, the
suite proves via public behavior, **hermetically against a local mock
OpenAI-compatible endpoint over TCP (the real ruby_llm client +
custom-endpoint registration path — no network beyond localhost, no API
keys)**: a scripted multi-turn conversation with tool calls round-trips —
user message → model turn → tool-call batch → tool results returned to the
model → model turn → completion; the agent runs as a task subtree on
`Core::Loop`, and a kernel interrupt cancels the in-flight turn cleanly
(interruption observable, no leaked tasks). pi's loop shape is the oracle
(outer loop over queued messages, inner loop over tool-call batches —
`repos/pi/packages/agent/src/agent-loop.ts`); the mapping onto ruby_llm is
architect-read against the PHASE 0 findings. The `tui-seam` gate is a
tripwire (agent/tools/tests never touch `RatatuiRuby`); `gem-pins` tripwires
the ruby_llm `~> 2.1` dependency.

**AC2 (tools verbatim-parity — BRIEF §3, §5-deferred).** The seven built-in
tools (`read`, `write`, `edit`, `bash`, `find`, `grep`, `ls`) are
behavior-parity ports of pi's (`repos/pi/packages/coding-agent/src/core/tools/`):
`read` returns bytes verbatim (trailing whitespace, BOM, line endings per
pi's handling); `write` writes verbatim; `edit` implements pi's fuzzy matcher
(match-space-only normalization incl. smart-quote/dash/space folding,
unchanged-line byte preservation, line-ending detect/restore, context
truncation); `bash` spawns `pgroup: true`, reads each pipe on its own fiber,
kills timeouts by negative-pid `-TERM` escalating to `-KILL`, reaps every
pid. **§5 verbatim-parity is the point: trailing whitespace round-trips
exactly as pi's does — no normalization at any write boundary** — proven by
golden tests whose fixtures and expected outputs are derived from pi's
algorithm (trailing-WS cases included), never from the port's own output.
The golden tests live in the suite (gate `suite-green`); the parity read
against pi's source is architect-read, and the report's parity-deviation
table must be empty or itemized as raised disagreements.

**AC3 (safety gating — BRIEF §4).** Schema-gating: a disabled/unsafe tool
never appears in the tool declarations the model receives — asserted against
the payload captured by the mock endpoint (the instrument, not a code-read).
Approval gating: destructive tools gate behind approval via the mechanism
the builder verified and recorded (ruby_llm native and/or a hook wrapper —
the call is the lane's, the evidence must be gem-source or pi-source); an
unapproved call produces the outcome shape pi produces (semantics recorded
from pi source in the findings table); the approval callback is injectable
and runs on the kernel (interruptible). Suite-proven.

**AC4 (bash safety, hermetic — BRIEF §4).** The suite proves the
timeout-kill path end-to-end with bounded runtimes and explicit timeouts (no
busy-wait): process-group child, timeout, negative-pid `-TERM` (escalating
to `-KILL` when needed), reaped, no zombie, no leaked pipe readers.

**AC5 (I02 carry-ins honored — I02 Verdict).** Kernel teardown is
exception-safe — a test raises inside the event handler/renderer and asserts
the poller thread terminates (no orphan polling a restored terminal);
`Signal.trap("INT")` disposition is restored after `run`; `Poller#stop`
surfaces a missed join; blockless `run` is guarded or documented as an
event-only mode (recorded); bench failure-path hardening: `native_seen`
initialized, nil-`extras` guarded without masking the original error,
bounded drain join, kill-probe fd redirection (the probe cannot hold the pty
slave). Gates `suite-green` and `bench-seam` stay green with all of this in
place — the hardening must not weaken the measured properties.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's
tool guidance is recorded in the findings table with evidence, plus any
disagreements with reasons — silent compliance is a defect. A parity
deviation adopted silently is a defect (see AC2).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

## Builder Report

### agent-loop

### PHASE 0 findings (spec-vs-reality, verified this run)

| Item | Reality (ruby_llm 2.1.0 / pi @ repos/pi) | Evidence |
|---|---|---|
| `Chat#generate` | One completion; appends response; block receives streamed `Chunk`s; tool calls NOT executed | gem chat.rb:203–212 |
| `Chat#step` | One move: pending tool batch → `run_tools` (returns new tool-result message), else `generate`; returns `nil` when `complete?`/`waiting?` | chat.rb:236–250 |
| `Chat#complete?`/`waiting?` | `complete?` = no pending batch && last msg isn't a tool call; `waiting?` = all remaining pending calls wait on approval/input | chat.rb:268–282, 308–323 |
| `Chat#run_tools` | Executes pending batch; `requires_approval` tools only execute after a decision; denied → `{error: "The user denied the <name> tool call."}`; undecided stay pending | chat.rb:221–232, 1525–1574 |
| Approval mechanics | `Tool.requires_approval` class macro (+optional resolver) → `requires_approval?`; `execution_decision` = resolver → recorded decision → `@approval_checker`; `pending_approvals` lists undecided; `approve`/`deny` record decisions | tool.rb:176–183; chat.rb:1559–1580, 337–349, 286–297 |
| Custom endpoint | `RubyLLM.context { config.openai_api_base; config.openai_api_key }` + `context.chat(model:, provider: "openai", protocol: :chat_completions, assume_model_exists: true)` | mock round-trips the real client (agent_loop_test 6/6 green) |
| SSE wire | `POST {base}/chat/completions`, `"stream":true`; reply `data: {choices:[{delta}]}` … `data: [DONE]`; non-stream = one JSON `{choices:[{message,finish_reason}],usage}` | served by mock; client parses (tests green) |
| `RubyLLM::ContextLengthExceededError` | Present | transport/error_middleware.rb:125 |
| `Support::Cancellation` | `watch(checkpoint)` installed around tool execution + per-chunk; `check` raises `CancelledError` after `chat.cancel` | support/cancellation.rb:7–32; chat.rb:1666, 1976 |
| pi `killProcessTree` | **Single-phase `-SIGKILL`** (group kill, fallback child), not TERM→KILL | utils/shell.ts:187–207 |
| pi find/grep binaries | pi downloads `fd`/`rg` at runtime (`ensureTool`); port uses PATH | find.ts:163; grep.ts:150 |
| pi system prompt | `buildSystemPromptSections` wraps each non-preamble section once; `getSystemMessageText` joins parts `"\n\n"` | system-prompt.ts:198–204; packages/ai/src/utils/text.ts:15–23 |
| **Kernel (new conflict found)** | async 2.46 `Async::Queue` delegates to `::Thread::Queue`; a push from another fiber **on the reactor thread** can fail to wake a fiber blocked in `#pop` (lost scheduler wakeup, reproduced in isolation) → inherited work hung `bundle exec rake` >600 s deterministically (`test_raising_work_terminates_poller_and_reraises`); fixed in `core/loop.rb` (below) | isolation repros this run; see fixes |

### Fixes to inherited work (audit results)

| Fix | File | Detail |
|---|---|---|
| Lost-wakeup hang | lib/raspberry_pi/core/loop.rb | Reactor-fiber-originated sentinels (`stop!`, `supervise`'s STOP, `animate`'s WAKE) now cross a thread boundary (`Thread.new { @events << x }.join`); cross-thread pushes are the proven-reliable path (poller, foreign-thread `stop!`) |
| Error swallowed | lib/raspberry_pi/core/loop.rb | async 2.x does not re-raise the root task body's exception (logs "unhandled exception", returns normally — reproduced): frame-loop errors (handler/renderer raise) are now captured into `@work_error` and re-raised after teardown |
| `PollerLingerError` masking | lib/raspberry_pi/core/loop.rb | `run`'s ensure calls `request_stop` before joining the poller, so a handler/renderer raise stops the poller instead of raising a linger error that masks the original error |
| SystemPrompt double-wrap | lib/raspberry_pi/agent/system_prompt.rb | `sections` already tags; `build` wrapped again → `<tools><tools>…`. Now joins tagged sections `"\n\n"` (pi's `getSystemMessageText`) |
| buildRules dedup | lib/raspberry_pi/agent/system_prompt.rb | pi's `addRule` trims + dedups; port now does |
| edit oldText param description | lib/raspberry_pi/tools/edit.rb | now pi-verbatim ("…unique in the original file and must not overlap…") |
| Wire-schema parity | lib/raspberry_pi/tools/{read,write,edit,bash,find,grep,ls}.rb | dropped `additionalProperties:false` (pi sends none) and `ls`'s empty `required`; programmatic diff of pi's **live** definitions vs port now byte-identical for all 7 tools (name/description/parameters) — `schema parity: CLEAN` |
| edit access check | lib/raspberry_pi/tools/edit.rb | missing file → `Error code: ENOENT` (pi's fsAccess semantics), unreadable → EACCES |
| ls read error | lib/raspberry_pi/tools/ls.rb | "Cannot read directory: #{e.message}" per pi |
| bash kill fallback | lib/raspberry_pi/tools/bash.rb | unreachable second rescue clause fixed (nested begin, group→child fallback per pi) |

### Verification against pi (commands run this session)

| Check | Result |
|---|---|
| Goldens re-derived from pi's **live** tool code (node 24 `--experimental-strip-types`, sources copied from repos/pi; renderers/photon stubbed — display-only) | 52/56 checks exact vs `test/fixtures/edit_golden.json`; 4 diffs are verifier artifacts: missing-file tmpdir path (`/private/tmp` vs `$WORKDIR`), generator's extra `content_base64` field, verifier filename (`out2` vs `out`), `legacy_args` (agent-loop hook, not a tool error — port handles it in `Tool#call`) |
| Tool definitions (name/description/parameters) of all 7 tools vs pi's live `create*ToolDefinition` | `schema parity: CLEAN` |
| SystemPrompt.build vs pi's live `buildSystemPrompt` (same inputs incl. toolSnippets/toolGuidelines) | byte-identical after macOS `/private/tmp` normalization: `PROMPT_PARITY_OK`, `BASHONLY_PARITY_OK` |

### Judgment calls (recorded)

- **Approval mechanism as built:** ruby_llm native — destructive tools (`edit`/`write`/`bash`) get `requires_approval?` via an extended module (registry.rb; semantics verified in gem source, chat.rb:1559–1580); the agent loop consults `chat.waiting? && awaiting_approval?`, runs the **injectable approval callback on the kernel fiber** (interruptible), and records via `chat.approve`/`chat.deny`. Denied outcome = ruby_llm's structured denial result `{error: "The user denied the <name> tool call."}` (chat.rb:1570); a denied call never executes (`refute_includes types, :tool_execution_start` in test). No hook wrapper needed.
- **Mock endpoint wire details:** TCPServer 127.0.0.1:0; HTTP/1.1; detects streaming by `Accept: text/event-stream` or `"stream":true` in body; streaming reply = `200`, `text/event-stream`, chunked, SSE `data: <openai-delta json>\n\n` lines (`{choices:[{delta:{role,content}|{tool_calls:[{index,id,type,function:{name,arguments}}]}}]}`, `finish_reason` `"tool_calls"`/`"stop"`, usage chunk, `data: [DONE]`); non-stream = `{choices:[{message:{role:"assistant",content},finish_reason:"stop"}],usage}`; `:pause` specs write a `: keepalive` comment after 0.1 s (real inter-chunk delay for the interrupt test). Captured request bodies exposed as `server.requests`/`captured_requests` (schema-gating asserts against the actual payload).
- **System-prompt dynamic segments:** selected-tools snippet list; rule bullets (loadout-conditional bash rule + per-tool guideline bullets + two fixed closers, trimmed/deduped); docs paths (`docs_paths:` replaces pi's `getReadmePath/getDocsPath/getExamplesPath`); `append_system_prompt` → `<addendum>`; `context_files` → `<project_context>` with `<project_instructions path=…>` blocks; `cwd` (backslashes→slashes). Recorded deviation: pi's `<skills>` section is never emitted (skills out of scope this iteration).
- **Blockless `run` disposition:** documented event-only mode (YARD on `Core::Loop#run`; runs until `stop!`/interrupt; no work task to push STOP) — locked by `test_blockless_run_is_event_only_mode`.

### Parity-deviation table (itemized raised disagreements; none silent)

| # | Deviation from pi | Why |
|---|---|---|
| 1 | bash timeout kill is two-phase `-TERM` → `-KILL` after a 5 s grace; pi is single-phase `-SIGKILL` (shell.ts:187–207) | AC4's letter mandates the escalation; recorded here as a spec-vs-pi conflict — AC4 wins |
| 2 | `read` images: bytes sent unresized (pi resizes via sharp/photon); note text otherwise pi-shaped | recorded in read.rb; image resizing out of parity scope |
| 3 | `find`/`grep` resolve `fd`/`rg` from PATH; pi downloads them at runtime (`ensureTool`) | hermetic lane; no runtime downloads |
| 4 | Runtime OS-error strings are runtime-native (e.g. missing read file: Node `ENOENT: no such file or directory, access '…'` vs Ruby's Errno message); the failure SHAPE (error result naming the path) is preserved | locked by `test_read_missing_file_is_an_error_result` |
| 5 | find: port pre-checks `File.exist?(search_path)` → `Path not found: …`; pi's fd path lets `fd` fail first | minor; both produce error results |
| 6 | pi's `prepareRequest`/`prepareNextTurn`/`finishTurn`/`spawnHook`/`PI_*` session env are not ported | §6 reduced extension surface, out of scope |
| 7 | pi's `<skills>` prompt section never emitted | skills out of scope |

### Gate outputs (verbatim)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
Run options: --seed 37425
# Running:
..........................................................
Finished in 12.976457s, 4.4696 runs/s, 18.8803 assertions/s.
58 runs, 245 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK      (suite_exit=0; 6 consecutive full-suite runs green)

$ timeout 90 bundle exec ruby bench/seam_bench.rb
{"fps_while_animating":{"mean":60.0,"p05_cadence_ms":16.54},
 "event_p50_ms":8.83,"event_p95_ms":17.4,
 "sse_delivered":500,"sse_expected":500,"sse_max_gap_ms":29.77,
 "subprocess_lines":100,
 "timeout_kill":{"verdict":"clean","kill_calls":1,"termsig":15,"zombie_gone":true,"seconds_to_reap":0.0013},
 "timer_ticks":100,"timer_expected":100,
 "static_wakes":0,"cpu_pct":4.7,
 "draws":380, ...}
SEAM_BENCH_OK  (bench_exit=0)

$ test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
SEAM_OK

$ grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
PINS_OK
```

Resolved versions: ruby_llm 2.1.0, async 2.46.0, ratatui_ruby 1.5.0, minitest 5.27.0, diff-lcs 1.6.2, ruby 4.0.7 arm64-darwin23.

### Files

- Modified: `lib/raspberry_pi/core/loop.rb`, `lib/raspberry_pi/agent/system_prompt.rb`, `lib/raspberry_pi/tools/{edit,ls,bash,read,write,find,grep}.rb` (schema edits); inherited-modified (audited, kept): `Gemfile.lock`, `raspberry-pi.gemspec`, `lib/raspberry_pi.rb`, `lib/raspberry_pi/core/poller.rb`, `test/test_helper.rb`, `bench/seam_bench.rb`
- Untracked (inherited, audited, kept + fixes): `lib/raspberry_pi/agent/{loop,bridge,status,system_prompt}.rb`, `lib/raspberry_pi/tools.rb`, `lib/raspberry_pi/tools/**`, `test/{agent_loop,bash_tool,golden_parity,kernel_carryin,tools}_test.rb`, `test/support/mock_llm_server.rb`, `test/fixtures/**`
- Created this run: `test/system_prompt_test.rb` (3 runs, 13 assertions, 0 failures)
- No git write commands; worktree left uncommitted.

STATUS: COMPLETE_WITH_CONCERNS — parity deviations itemized above (no. 1: AC4's two-phase bash kill conflicts with pi's single-phase SIGKILL — spec-internal conflict reported, AC4 implemented; nos. 2–7 recorded deviations), and the async-2.46 lost-wakeup kernel fix (loop.rb) is a cross-lane-relevant finding for I02: the architect may want the same thread-boundary signaling pattern reviewed for other lanes building on the kernel.

## Verdict

- **Disagreement rulings** (each PHASE 0 deviation the lane raised; none were silent — AC6 discipline held):

  | # | Deviation | Ruling | Why |
  |---|---|---|---|
  | 1 | bash timeout kill two-phase `-TERM`→`-KILL` (5 s grace) vs pi's single-phase `-SIGKILL` (shell.ts:187–207) | **MODIFY** | The conflict is a criterion-authoring defect, not the lane's: AC4's frozen letter mandated the escalation while BRIEF §5 makes pi the oracle — the lane built the AC's stated property and raised the conflict with evidence, exactly per contract. Keep the two-phase kill for I03 (it is the frozen letter and strictly safer for children trapping TERM); **reconcile at the next parity iteration** — either port pi's single-phase `-KILL` or amend BRIEF §5 to bless this one delta. Unattributable-delta discipline (the §5 rationale) demands it be decided, not left standing. |
  | 2 | `read` images sent unresized (pi resizes via sharp/photon) | **ACCEPT** | Image resizing needs a native image dependency pi buys via its toolchain; out of parity scope this iteration. Record in the backlog only if image reads matter to the port's users. |
  | 3 | `find`/`grep` resolve `fd`/`rg` from PATH; pi downloads at runtime | **ACCEPT** | Hermetic lane — no runtime downloads was the spec's own constraint. A later hardening pass may add ensureTool-equivalent resolution; itemized, not silent. |
  | 4 | Runtime OS-error strings are runtime-native (Ruby `Errno` vs Node's message text); failure shape preserved | **ACCEPT** | Faking Node's error strings would be worse than the deviation; the observable contract (error result naming the path) is preserved and test-locked. |
  | 5 | `find` pre-checks `File.exist?` → `Path not found:` (pi lets `fd` fail first) | **ACCEPT** | Minor, itemized; both produce error results naming the path. |
  | 6 | `prepareRequest`/`prepareNextTurn`/`finishTurn`/`spawnHook`/`PI_*` env not ported | **ACCEPT** | BRIEF §6 reduced extension surface — explicitly out of scope. |
  | 7 | pi's `<skills>` system-prompt section never emitted | **ACCEPT** | Skills out of scope this iteration; the omission is recorded in system_prompt.rb, and the live-parity check (`PROMPT_PARITY_OK`) covers the sections that are in scope. |
  | + | Kernel lost-wakeup fix in `core/loop.rb` (reactor-fiber-originated sentinel pushes cross a thread boundary) — new work beyond the carry-in ledger | **ACCEPT** | In-bounds (`lib/**`), evidence-based (isolated repro; deterministic >600 s suite hang pre-fix), and it unblocked the iteration's own gates. Cross-lane relevance noted: the fix rides this merge into `project/pi-port`, so the I02 kernel defect is cured going forward — no separate action needed. |

- **Acceptance Criteria integrity** — frozen sections byte-identical since freeze (`git diff c7ad8d5c..HEAD` on lines 1–108 empty; the `+AC…` diff lines are the AC text embedded in the appended Builder Prompt). No builder commits (`git log 6478902..` empty on the lane branch); worktree diff entirely within the declared touch set; scratch report raw-results-only with every status claim command-backed. `architect verify agent-loop` 4/4 PASS, each confirmed with session evidence.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | suite-green PASS cold (58 runs / 245 assertions, 0 failures, fresh seed); tui-seam PASS; gem-pins PASS (ruby_llm 2.1.0 pinned); multi-turn tool round-trip + steering continuation + kernel-interrupt-cancels-turn all suite-proven against the real ruby_llm client on a TCP mock endpoint; architect-read of `agent/loop.rb` confirms pi's outer/inner loop shape mapped onto `Chat#step` consistent with the PHASE 0 findings (chat.rb citations) | §2, §4 | PASS |
| AC2 | suite-green PASS; goldens generated from pi's **live** tool code (fixture provenance + verifier run 52/56, 4 diffs shown to be verifier artifacts); spot-check of `edit_diff.rb` vs `edit-diff.ts:29–53` — normalization order, character classes, and dash/quote/space sets identical; trailing-WS cases assert verbatim round-trip; schema parity CLEAN (programmatic diff vs pi's live definitions); parity-deviation table itemized, none silent | §3, §5 | PASS |
| AC3 | suite-green PASS; schema-gating asserted against the wire payload captured by the mock (the instrument, not a code-read); approval via ruby_llm native `requires_approval` (gem-source evidence chat.rb:1559–1580), injectable callback runs on the kernel fiber (`handle_pause` in agent/loop.rb), denied call never executes (test refutes tool_execution_start); judgment call recorded as required | §4 | PASS |
| AC4 | suite-green PASS; bash timeout-kill path proven hermetically (bounded, `pgroup: true`, negative-pid, reaped, no zombie) + bench `timeout_kill` verdict "clean"; letter-vs-spirit conflict with pi's single-phase SIGKILL raised with evidence — the authoring defect is ruled on above (deviation #1), lane not penalized | §4 | PASS (criterion authoring defect logged: reconcile at next parity iteration) |
| AC5 | suite-green + bench-seam PASS cold with all hardening in place (fps 60.0 mean, p95 17.84 ms, cpu 4.3% — measured properties held); all six carry-ins landed and test-locked: exception-safe teardown with post-teardown re-raise, trap restored, `PollerLingerError` surfaces missed join, blockless `run` documented event-only + test, bench failure-path hardening | I02 Verdict | PASS |
| AC6 | Findings table complete — every verify item the spec named (Chat APIs, approval mechanics, custom endpoint + SSE wire, `ContextLengthExceededError` recorded-only) plus four findings beyond the list (Cancellation, `killProcessTree`, find/grep binaries, system-prompt composition) and the kernel lost-wakeup discovery; all with file:line evidence; deviations all raised, none silent | — | PASS |

- **Idiomaticity/style read:** house-consistent throughout (`frozen_string_literal`, YARD, pi-citing comments, terse public-behavior minitest on the shared base, gemspec-driven deps). Two minor polish items, logged as carry-ins — neither gates this verdict: (a) `bash.rb` re-sends `-TERM` every 50 ms poll iteration after the deadline (and TERM+KILL each iteration past grace) rather than once as pi does — harmless (the group dies on the first KILL) but noisy; (b) the mock server's `write_sse` raises `Errno::EPIPE` to stderr after client teardown — rescue it for clean suite output. The async "unhandled exception: work boom" warn in the gate transcript is expected async-2.x logger noise for the intentional carry-in test raise (the port re-raises it properly after teardown); cosmetic only.
- **Rescue-dispatch integrity:** the first lane run died to an architect-side harness timeout at 65 min (my process error, not the builder's); the rescue re-dispatch audited the inherited worktree from first principles and itemized every fix it made to inherited files (audit table) — the inherited-work audit trail is complete and each fix is test-locked.
- **Iteration** — **CONTINUE** — diff vs BRIEF §1/§3/§4/§5 faithful: six AC PASS on cold gates, parity oracle discipline held (goldens machine-derived from pi's live code, every deviation raised and ruled on), and the kernel substrate came out stronger than spec'd (lost-wakeup cure). Next: TUI iteration per the backlog.
