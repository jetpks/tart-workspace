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
`architect rehearse agent-loop` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze agent-loop` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse agent-loop` — before the freeze, while
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
subsection per lane. A copy is written to build/I03-agent-loop-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section agent-loop prompt --append --lane <lane> --from build/I03-agent-loop-<lane>/prompt.md`. -->

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
