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

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I03-agent-loop-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence agent-loop --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section agent-loop verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify agent-loop`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
