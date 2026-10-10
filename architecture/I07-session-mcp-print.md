# I07: session-mcp-print

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
no research. Write + commit: `architect section session-mcp-print grounds --from <file>`. -->

## Specification

- **Objective:** Close three BRIEF §7 definition-of-done gaps in one iteration through parallel lanes — **§7.1 resumable JSONL sessions** (the last interactive-TUI gap: a conversation survives restart), **§7.3 MCP servers** (connectable + usable — external tools via stdio), **§7.4 print mode** (headless single-shot runs; eventually this project's own builder lanes can run on it) — plus a wave-2 CLI-wiring fast-follow surfacing all three through `bin/raspberry-pi`. **Why this shape (per the human's direction: maximize parallel builders per iteration):** session, mcp, and print are library-level work with disjoint touch sets — session lives in the agent layer, mcp in a new `mcp` module + the tool registry, print in a new mode module; the only shared surface is the CLI launcher and README, so per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`; proven in I06), wave 1 is three mutually disjoint lanes and `cli` is the wave-2 lane provisioned off the integrated tip after wave 1 merges. Compaction (§7.6) is deliberately **out** — it builds on session persistence and lands as its own later iteration.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the session entry subset + id scheme as ported; the resume mechanism; the MCP transport/client shape; the tool-wrapper seam; print-mode approval semantics), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the JSONL session store, the JSON-RPC MCP client, and print mode are all hand-rolled by default; proposing a gem (mcp gem, thor-like CLI gem) is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ruby_llm --path`), each item in the findings table: how a `RubyLLM::Chat` accumulates and replays message history (what `chat.messages` holds after turns, how prior messages are seeded for a new chat — the resume mechanism must re-feed prior turns so the model sees them; prove via the captured request payload); the `RubyLLM::Tool` contract for `chat.with_tools` (subclass interface: name/description/schema/execute — the port's `Tools::Read` etc. are the working examples; the MCP wrapper must satisfy whatever the gem actually requires); how a tool result/exception surfaces into the message history (what the session recorder observes for a tool turn).
  - **pi reference (read-only oracle, `repos/pi`):**
    - **Sessions:** `packages/coding-agent/src/core/session-manager.ts` — `CURRENT_SESSION_VERSION = 3` (:41), `SessionHeader` (:43–51: `type: "session"`, version, id, timestamp, cwd, `parentSession?`), `SessionEntryBase` (:57–63: type, id, parentId, timestamp), `SessionMessageEntry` (:64–68: `type: "message"`, `message: AgentMessage`), `SessionEntry` union (:183), `parseSessionEntries` (:355, malformed lines skipped), `sessionEntryToContextMessages` (:439–474 — message-entry → context messages, with null/missing-content tolerance), `getDefaultSessionDir` (:596) + the session-dir/file layout it resolves (verify the exact path shape and file naming), `loadEntriesFromFile` (:627), `findMostRecentSession` (:749 — most-recent-for-cwd selection). Port the **message-entry subset only** (header + message entries); other entry types are out of scope.
    - **Print mode:** `packages/coding-agent/src/modes/print-mode.ts` — `PrintModeOptions` (:30–39: mode text/json, messages, initialMessage), the interface comment (:10–11: text = final response only, json = all events), exit-code semantics (the return values + signal handlers), raw stdout writes (`core/output-guard.ts` `writeRawStdout`/`flushRawStdout` — no buffering, no TUI anywhere). What pi `-p` does with approval-gated tools (auto-deny/auto-approve/flag — verify in the runtime path and port it; itemize if pi's choice can't port cleanly). json event mode is **out of scope**.
    - **MCP:** `packages/mcp/src/client.ts` (JSON-RPC client: state machine, `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (:40), initialize handshake, tools/list with pagination (`MAX_LIST_PAGES`), tools/call), `packages/mcp/src/protocol/jsonrpc.ts` (message validation — request/response/notification shapes, error codes), `packages/mcp/src/protocol/types.ts` (`Tool`, `InitializeResult`, protocol versions), `packages/mcp/src/transports/stdio.ts` (stdio framing: newline-delimited JSON over the child's stdin/stdout; stderr + child reaping on close), `packages/coding-agent/src/core/mcp-servers.ts` (`mcp.json` shape: `mcpServers: {name: {command, args?, env?}}` validated at :292–304 with pi's exact error strings; `isMcpToolName` — `mcp__<server>__<tool>`; the tool-exposure modes at the file head — the port ships `direct` only, itemized). MCP resources/prompts/sampling/notifications-handled and the streamable-http transport are **out of scope**.
  - **Hermetic discipline:** no real LLM traffic (agent-level tests run on the existing `test/support/mock_llm_server.rb` — read-only); MCP tests run against a **pure-Ruby fixture MCP server** (`test/support/mcp_echo_server.rb`, the mcp lane's new file) spawned as a subprocess over real stdio pipes — no network, no keys; session tests write to tmp dirs (never `~/.pi` or `~/.raspberry-pi`); print tests run headless on the mock server with no terminal session. No changes to the mock server or shared fixtures.
  - **House style:** as I02–I06 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared `RaspberryPi::Test` base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `session`/`mcp`/`print`, mutually disjoint; `cli` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, `~/.raspberry-pi`, no git write commands, no real LLM or MCP API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `session` may touch:** `lib/raspberry_pi/agent/session.rb` (new), `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/session_test.rb` (new). Registration is yours via `require_relative "session"` in `agent/loop.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `mcp` may touch:** `lib/raspberry_pi/mcp.rb` (new) + `lib/raspberry_pi/mcp/**` (new dir, exclusively yours), `lib/raspberry_pi/tools/registry.rb`, `test/mcp_test.rb` (new), `test/support/mcp_echo_server.rb` (new fixture). Registration is yours from `tools/registry.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `print` may touch:** `lib/raspberry_pi/print.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/print_test.rb` (new).
  - **Lane `cli` (fast-follow) may touch:** `bin/raspberry-pi`, `README.md` (usage sections only). It must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/support/mock_llm_server.rb`, `test/golden_parity_test.rb`, `test/fixtures/**`, `test/test_helper.rb`, `bench/**`, `Gemfile`/`Gemfile.lock` are in **no** lane's touch set — raise in PHASE 0 if a change is needed; do not touch. `lib/raspberry_pi.rb` is `print`'s; `tools/registry.rb` is `mcp`'s; `agent/loop.rb` is `session`'s — others raise in PHASE 0. Wave-1 lanes must not depend on each other's new files: `print` runs on the base `Agent::Loop`/`Tools::Registry` interfaces (unchanged optional kwargs only), `mcp` merges behind an optional `Registry.build` kwarg, `session` adds an optional recorder kwarg to `Agent::Loop` — all existing call sites stay green unmodified.
  - **Out of scope:** compaction + all non-message session entry types (thinking_level_change, model_change, usage, label, branch_summary, custom), session listing/switching UI, session export (markdown/HTML), session share, MCP resources/prompts/sampling/roots, MCP streamable-http + OAuth, tool exposure modes beyond `direct`, deferred tools, json event mode (`--mode json`), print-mode images/@file mentions, print-mode multi-prompt chaining beyond what pi's options port trivially, any TUI changes.
- **Deliverables:**
  1. **Session recording (`session`):** `Agent::Loop` accepts an optional session recorder (nil = off; all existing behavior and tests unchanged). A recorded turn writes a JSONL session file: line 1 is the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one **message entry** per message in order — user messages and assistant messages (tool calls/results included as they occur) — each `type: "message"` with the pi entry-base fields (id, parentId, timestamp, message). One JSON object per line, parseable by a line-oriented reader with malformed lines skipped (pi :355 semantics). Injectable path; tests write tmp dirs.
  2. **Resume (`session`):** a session file loads back to the message history the model sees — message entries → context messages (`sessionEntryToContextMessages` semantics for the message subset, including null/missing-content tolerance), seeded into the chat so the **captured request payload contains the prior turns** (MockLLMServer proof — the model demonstrably sees them); most-recent-session-for-cwd selection (pi `findMostRecentSession` semantics); a resumed conversation continues recording into a **new** session file whose header links the old via `parentSession`.
  3. **MCP client (`mcp`):** a hand-rolled stdio MCP client — spawn (`command`, `args`, `env`), newline-delimited JSON-RPC over the child's stdio (stderr passthrough; child reaped on close), initialize handshake (protocol version, capabilities, client/server info), `tools/list` (pagination tolerated), `tools/call` with the 30 s default request timeout; JSON-RPC message validation and error codes per pi's `jsonrpc.ts`; transport + client split mirroring pi's shape. Hermetic tests against the fixture echo server.
  4. **MCP integration (`mcp`):** servers configured from an `mcp.json`-shaped source — `{"mcpServers": {name: {command, args?, env?}}}` — validated with pi's exact error strings (mcp-servers.ts:292–304); default path `~/.raspberry-pi/mcp.json`, overridable, missing file = no servers, no error. Configured servers' tools register into the loadout behind the schema gate named `mcp__<server>__<tool>`, declared `direct` (exposure simplification itemized); an unconfigured/absent server never connects. Agent-level round-trip proof: the model calls an MCP tool (MockLLMServer script), the fixture echo server answers over real stdio, the result returns to the model as the tool result.
  5. **Print mode (`print`):** a headless single-shot run — prompt → `Agent::Loop` to completion with a stdout event sink, no TUI anywhere on the path; text mode writes the **final response only** (pi's text-mode contract) to raw stdout unbuffered; exit code 0 on success, pi's non-zero semantics on agent error (verify :print-mode.ts); pi's print-mode approval disposition for gated tools (verify, port, itemize). Hermetic: MockLLMServer, no terminal session, tmp cwd.
  6. **CLI wiring (`cli`, wave-2 fast-follow):** `bin/raspberry-pi` gains `-p/--print PROMPT` (non-interactive single-shot; flag shape verified against pi's `cli/args.ts`), `--resume [ID]` (interactive resume, default most-recent-for-workdir), session recording on by default for interactive runs (pi records every session), and MCP config loading (default `~/.raspberry-pi/mcp.json`, env override) into `Tools::Registry.build`; `--help` documents all of it and stays headless-safe; `README.md` usage sections updated.
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — every named file in exactly one set; the `mcp/**` dir is new and exclusively the mcp lane's): `session` (JSONL recording + resume), `mcp` (client + registry integration), `print` (headless single-shot mode). **Wave 2:** `cli` (launcher flags + README; the shared-surface seam, rooted at the integrated tip per the fast-follow pattern).
- **Effort call:** session high (resume semantics + history-seeding mechanism against gem source + wire-capture proofs), mcp high (protocol client + transport + schema translation + integration), print medium (event-sink mode over existing loop; the mechanism is plumbing), cli medium (flag surface + wiring, roots at the tip where all three exist). Recorded: mcp and session are the load-bearing lanes; both run at high.

```lanes
- name: session
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: mcp
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/mcp.rb
    - lib/raspberry_pi/mcp/**
    - lib/raspberry_pi/tools/registry.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
- name: print
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/print.rb
    - lib/raspberry_pi.rb
    - test/print_test.rb
- name: cli
  repo: raspberry-pi
  touch:
    - bin/raspberry-pi
    - README.md
```

## Acceptance Criteria

**AC1 (session recording — BRIEF §7.1).** A recorded agent turn writes a JSONL session file: line 1 the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one message entry per message in order (user, assistant incl. tool calls/results) with the pi entry-base fields — test-proven by parsing the file back (line-oriented, malformed-line-skip tolerance) and asserting the recorded sequence matches the conversation. The recorder is optional (nil = off) and every existing agent-loop test passes unmodified. Format parity vs pi's session-manager.ts is architect-read from the lane's citations.

**AC2 (resume — BRIEF §7.1).** A resumed conversation makes the model see prior turns — proven by the **captured MockLLMServer request payload containing the prior turns' messages**; most-recent-session-for-cwd selection is test-proven; the resumed run records into a new session file whose header links the old via `parentSession`. Tolerance for null/missing content entries is ported from pi (`sessionEntryToContextMessages` :439–474) — itemized in the findings table.

**AC3 (MCP client — BRIEF §7.3).** The hand-rolled stdio MCP client completes a round trip against the fixture echo server — initialize handshake, `tools/list`, `tools/call` returning the tool result — over real stdio pipes, with the 30 s default request timeout and pi's JSON-RPC validation/error semantics; child process reaped on close. Hermetic (no network, no keys, no real MCP traffic). No new runtime dependencies (gem-pins gate).

**AC4 (MCP integration — BRIEF §7.3, §2).** Configured servers' tools register into the loadout behind the schema gate, named `mcp__<server>__<tool>`, declared `direct`; an agent-level round trip is test-proven: the model calls the MCP tool (MockLLMServer script), the fixture server answers over stdio, the result returns to the model as the tool result. Config validation carries pi's exact error strings (mcp-servers.ts:292–304); a missing config file means no servers, no error; an unconfigured server never connects (test-proven). The `direct`-only exposure simplification is itemized in the parity table.

**AC5 (print mode — BRIEF §7.4).** A single-shot headless run sends the prompt and writes the **final response only** to raw stdout (unbuffered), with pi's exit-code semantics (0 on success, the verified non-zero path on agent error) and pi's verified approval disposition for gated tools; no TUI anywhere on the path (architect-read + the tests run with no terminal session). Hermetic on MockLLMServer with a tmp cwd.

**AC6 (CLI wiring — wave-2 fast-follow, BRIEF §7.1/§7.3/§7.4).** `bin/raspberry-pi` wires `-p/--print PROMPT`, `--resume` (default most-recent-for-workdir), default-on session recording for interactive runs, and MCP config loading; `--help` documents all of it and runs headless-safe (gate `cli-help`); `README.md` usage sections updated (architect-read). Judged at final integration after the cli lane merges (cli-help is RED until then by construction — the wave-2 seam).

**AC7 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: session-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC3, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: print-guard
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: tui-seam
  ac: AC3, AC5, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC3, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: cli-help
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK
  expect:
    exit_code: 0
    stdout_match: CLI_OK
```

## Builder Prompt

### session

### LANE session — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-session/wt
  (a git worktree of the raspberry-pi repo, branch lane/I07-session-mcp-print-session, based on
  project/pi-port at a8ec14e8 — everything through I06: kernel, agent loop (error-terminal +
  thinking strip), seven parity tools with safety/approval gating, TUI seam with style vocabulary,
  chat surface with the input-line editor (fake cursor, history, word ops) and markdown-rendered
  assistant completions, the Render::Markdown converter, §5 toggle seam (off). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-session/report.md
- You may touch ONLY:
  lib/raspberry_pi/agent/session.rb (new), lib/raspberry_pi/agent/loop.rb, test/agent_loop_test.rb,
  test/session_test.rb (new). Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - You build spec deliverables 1 (session recording) and 2 (resume). Your changes to
    Agent::Loop's public interface must be OPTIONAL kwargs only (recorder nil = off; resume
    seeding opt-in) — a parallel lane (print) builds on the base Agent::Loop interface in its own
    worktree, and every existing call site (bin/raspberry-pi, tests) stays green unmodified.
  - Registration is yours via `require_relative "session"` at the top of agent/loop.rb (you own
    that file); lib/raspberry_pi.rb belongs to the print lane — raise in PHASE 0, never touch it.
  - test/support/mock_llm_server.rb is NO lane's to touch — read it and use it read-only for the
    AC2 wire-capture proof (it already backs golden_parity_test's wire-payload capture; if it
    cannot capture what you need, raise it in PHASE 0 — do not modify it).
  - test/test_helper.rb and test/golden_parity_test.rb are no lane's — raise in PHASE 0 if needed.
  - The session dir/file layout: port pi's shape (session-manager.ts getDefaultSessionDirPath +
    the session-file naming — verify both in the oracle) under an INJECTABLE root; tests write
    tmp dirs only, never ~/.pi or ~/.raspberry-pi.
  - The lanes block in the spec lists a fourth lane cli — it is a wave-2 fast-follow, NOT running
    now; ignore it except to know bin/raspberry-pi and README.md are not yours.
  - Gates session-guard and suite-green are your proof. The other gates run other lanes' files:
    run them only if runnable in your worktree — test/mcp_test.rb and test/print_test.rb do NOT
    exist yet (record 'NOT RUNNABLE: wave-1 deliverable', do not create them); cli-help is the
    wave-2 lane's (record NOT RUNNABLE: wave-2 deliverable — `--help` does not carry the flags
    yet). Do not create or weaken any gate's files to make a gate pass.

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.


=== SPECIFICATION ===

### mcp

### LANE mcp — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-mcp/wt
  (a git worktree of the raspberry-pi repo, branch lane/I07-session-mcp-print-mcp, based on
  project/pi-port at a8ec14e8 — everything through I06: kernel, agent loop (error-terminal +
  thinking strip), seven parity tools with safety/approval gating, TUI seam with style vocabulary,
  chat surface with the input-line editor (fake cursor, history, word ops) and markdown-rendered
  assistant completions, the Render::Markdown converter, §5 toggle seam (off). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-mcp/report.md
- You may touch ONLY:
  lib/raspberry_pi/mcp.rb (new) + lib/raspberry_pi/mcp/** (new dir, exclusively yours),
  lib/raspberry_pi/tools/registry.rb, test/mcp_test.rb (new),
  test/support/mcp_echo_server.rb (new fixture). Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - You build spec deliverables 3 (the MCP client: stdio transport + JSON-RPC) and 4 (the
    registry integration). tools/registry.rb is yours: Registry.build gains an OPTIONAL kwarg
    (server config, default = none) — a parallel lane (print) builds on the base Registry
    interface in its own worktree, and every existing call site (bin/raspberry-pi, tests) stays
    green unmodified.
  - Registration is yours from tools/registry.rb (you own it — require_relative "../mcp" there
    or lazily at use); lib/raspberry_pi.rb belongs to the print lane — raise in PHASE 0, never
    touch it.
  - The MCP tool wrapper must satisfy whatever the ruby_llm chat.with_tools contract actually
    requires — verify the gem's Tool interface in gem source first; Tools::Read and its siblings
    (lib/raspberry_pi/tools/*.rb) are the working examples of that contract in this repo.
  - test/support/mcp_echo_server.rb is YOUR new file (the fixture: a pure-Ruby stdio MCP server
    answering initialize/tools/list/tools/call — no gems, spawned as a subprocess by tests over
    real pipes). test/support/mock_llm_server.rb is NO lane's to touch — read it and use it
    read-only for the AC4 agent-level round-trip proof; if it cannot script what you need, raise
    in PHASE 0 — do not modify it.
  - test/test_helper.rb and test/golden_parity_test.rb are no lane's — raise in PHASE 0 if needed.
  - Out of scope (spec): streamable-http transport, OAuth, resources/prompts/sampling/roots,
    deferred/codemode/hidden exposure — direct only, itemized in your parity table.
  - The lanes block in the spec lists a fourth lane cli — it is a wave-2 fast-follow, NOT running
    now; ignore it except to know bin/raspberry-pi and README.md are not yours.
  - Gates mcp-guard and suite-green are your proof. The other gates run other lanes' files:
    run them only if runnable in your worktree — test/session_test.rb and test/print_test.rb do
    NOT exist yet (record 'NOT RUNNABLE: wave-1 deliverable', do not create them); cli-help is the
    wave-2 lane's (record NOT RUNNABLE: wave-2 deliverable). Do not create or weaken any gate's
    files to make a gate pass.

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.


=== SPECIFICATION ===

### print

### LANE print — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-print/wt
  (a git worktree of the raspberry-pi repo, branch lane/I07-session-mcp-print-print, based on
  project/pi-port at a8ec14e8 — everything through I06: kernel, agent loop (error-terminal +
  thinking strip), seven parity tools with safety/approval gating, TUI seam with style vocabulary,
  chat surface with the input-line editor (fake cursor, history, word ops) and markdown-rendered
  assistant completions, the Render::Markdown converter, §5 toggle seam (off). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-print/report.md
- You may touch ONLY:
  lib/raspberry_pi/print.rb (new), lib/raspberry_pi.rb (the require-registration line ONLY —
  exactly one added line: require_relative "raspberry_pi/print"), test/print_test.rb (new).
  Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - You build spec deliverable 5 (print mode: headless single-shot). You run on the BASE
    Agent::Loop and Tools::Registry interfaces — the session and mcp lanes run in parallel
    worktrees and their new optional kwargs are NOT in your base; use the existing public
    interface only (Agent::Loop.new(chat:, tools:, system_prompt:, on_event:, approval:),
    Tools::Registry.build(selected:, cwd:)). Do not depend on or anticipate their work.
  - print.rb must carry NO TUI anywhere on its path: no require of the tui, no terminal
    session, no ratatui involvement (the tui-seam gate greps all of lib for RatatuiRuby —
    only tui.rb is exempt). Your tests run without any TUI.run / terminal.
  - Approval disposition in print mode (what happens when a gated tool is called with no
    human to approve): verify what pi -p does (print-mode.ts + the runtime path) and port
    exactly that; itemize any simplification in your parity table — never invent.
  - test/support/mock_llm_server.rb is NO lane's to touch — read it and use it read-only for
    your hermetic tests; if it cannot script what you need, raise in PHASE 0 — do not modify it.
  - test/test_helper.rb and test/golden_parity_test.rb are no lane's — raise in PHASE 0 if needed.
  - The lanes block in the spec lists a fourth lane cli — it is a wave-2 fast-follow, NOT
    running now; bin/raspberry-pi and README.md are the cli lane's, never yours. Your module
    is the library the cli lane will wire the -p/--print flag onto.
  - Gates print-guard and suite-green are your proof. The other gates run other lanes' files:
    run them only if runnable in your worktree — test/session_test.rb and test/mcp_test.rb do
    NOT exist yet (record 'NOT RUNNABLE: wave-1 deliverable', do not create them); cli-help is
    the wave-2 lane's (record NOT RUNNABLE: wave-2 deliverable — the -p/--print flag is wired
    by the cli lane). Do not create or weaken any gate's files to make a gate pass.

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.


=== SPECIFICATION ===

### cli

### LANE cli — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-cli/wt
  (a git worktree of the raspberry-pi repo, branch lane/I07-session-mcp-print-cli, based on
  project/pi-port at 114354d — everything through I07 wave 1: kernel, agent loop (error-terminal
  + thinking strip; optional `recorder:`/`seed_messages:` kwargs), seven parity tools with
  safety/approval gating, TUI seam with style vocabulary, chat surface with the input-line
  editor and markdown-rendered completions, §5 toggle seam (off), the JSONL session store
  (Agent::Session + Agent::Session::Recorder), the stdio MCP client + registry integration
  (`Registry.build(mcp_servers:)`), and print mode (Print.run). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I07-session-mcp-print-cli/report.md
- You may touch ONLY:
  bin/raspberry-pi, README.md (usage sections only). Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - You build spec deliverable 6 (CLI wiring — the wave-2 fast-follow seam). All three wave-1
    deliverables exist at your base — read them, wire them, do NOT modify them:
    - Sessions (lib/raspberry_pi/agent/session.rb): `Agent::Session.find_most_recent(dir,
      cwd:)` → a session-file path (the dir is the workdir's session dir — read `ensure_dir`
      / `default_root` for the exact `<root>/sessions/--<encoded-cwd>--/` shape);
      `Agent::Session.context_messages(path)` → chat-ready attribute hashes;
      `Agent::Session::Recorder.new(cwd:, root:, parent_session:)`; `Agent::Loop.new` accepts
      `recorder:` (nil = off) and `seed_messages:` — pass them from the launcher.
    - MCP (lib/raspberry_pi/mcp.rb + mcp/): `Mcp::Config.load(path = Mcp::Config::DEFAULT_PATH)`
      → `{name => raw server config}` (missing file = empty, no error); pass it as
      `Tools::Registry.build(selected:, cwd:, strip_trailing_whitespace:, mcp_servers: ...)`.
    - Print (lib/raspberry_pi/print.rb): `Print.run(prompt:, chat:, tools:, system_prompt:,
      on_event:, stdout:, stderr:)` → the exit code.
  - Flag shapes: verify against pi's `packages/coding-agent/src/cli/args.ts` before coding —
    `--print`/`-p` (:177–184: boolean flag, the following non-flag argument becomes the
    message), `--resume`/`-r` (:113–114: boolean; pi pops an interactive session-picker UI).
    The port's spec shape is `--resume [ID]` (optional value; default most-recent-for-workdir —
    the port has no session-picker UI) and `-p/--print PROMPT` — deliberate deviations, itemize
    each in your parity table with the args.ts line evidence.
  - MCP config env override: pi has none (agent-dir `mcp.json` only); the port's spec adds one —
    name it consistently with the existing `RASPBERRY_PI_*` vocabulary in bin/raspberry-pi;
    itemize as a port addition in the parity table.
  - `--help` must stay headless-safe: it prints and exits before any environment or terminal
    interaction (follow the existing `usage` module-function pattern; the cli-help gate runs it
    with no tty). The usage text must document `-p/--print`, `--resume`, session recording
    (default-on for interactive runs), and MCP config (default path + env override).
  - Session recording default-ON for interactive runs (pi records every session): construct a
    Recorder for the workdir in the interactive path. Print-run session recording is
    spec-scoped OUT (Print.run exposes no recorder): verify what pi's print mode does
    (main.ts runtime creation + print-mode.ts session usage) and itemize the deviation in your
    parity table — do NOT touch print.rb.
  - `--resume` seeds the chat via `Agent::Session.context_messages` + the loop's
    `seed_messages:` kwarg, and links the old session file via the Recorder's
    `parent_session:`.
  - Gates cli-help and suite-green are your proof. session-guard/mcp-guard/print-guard,
    stderr-quiet, stderr-clean, tui-seam, bench-seam, and gem-pins are all runnable at your
    base — run them and record verbatim; they must stay green (they prove you broke nothing).
    Do not weaken any gate's files.
  - No test file is in your touch set: the launcher is exercised by the cli-help gate and the
    existing suite. If you believe a test is needed, raise it in PHASE 0 — do not add one.

Execute the architect spec below. Operating rules:
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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===

## Specification

- **Objective:** Close three BRIEF §7 definition-of-done gaps in one iteration through parallel lanes — **§7.1 resumable JSONL sessions** (the last interactive-TUI gap: a conversation survives restart), **§7.3 MCP servers** (connectable + usable — external tools via stdio), **§7.4 print mode** (headless single-shot runs; eventually this project's own builder lanes can run on it) — plus a wave-2 CLI-wiring fast-follow surfacing all three through `bin/raspberry-pi`. **Why this shape (per the human's direction: maximize parallel builders per iteration):** session, mcp, and print are library-level work with disjoint touch sets — session lives in the agent layer, mcp in a new `mcp` module + the tool registry, print in a new mode module; the only shared surface is the CLI launcher and README, so per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`; proven in I06), wave 1 is three mutually disjoint lanes and `cli` is the wave-2 lane provisioned off the integrated tip after wave 1 merges. Compaction (§7.6) is deliberately **out** — it builds on session persistence and lands as its own later iteration.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the session entry subset + id scheme as ported; the resume mechanism; the MCP transport/client shape; the tool-wrapper seam; print-mode approval semantics), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the JSONL session store, the JSON-RPC MCP client, and print mode are all hand-rolled by default; proposing a gem (mcp gem, thor-like CLI gem) is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ruby_llm --path`), each item in the findings table: how a `RubyLLM::Chat` accumulates and replays message history (what `chat.messages` holds after turns, how prior messages are seeded for a new chat — the resume mechanism must re-feed prior turns so the model sees them; prove via the captured request payload); the `RubyLLM::Tool` contract for `chat.with_tools` (subclass interface: name/description/schema/execute — the port's `Tools::Read` etc. are the working examples; the MCP wrapper must satisfy whatever the gem actually requires); how a tool result/exception surfaces into the message history (what the session recorder observes for a tool turn).
  - **pi reference (read-only oracle, `repos/pi`):**
    - **Sessions:** `packages/coding-agent/src/core/session-manager.ts` — `CURRENT_SESSION_VERSION = 3` (:41), `SessionHeader` (:43–51: `type: "session"`, version, id, timestamp, cwd, `parentSession?`), `SessionEntryBase` (:57–63: type, id, parentId, timestamp), `SessionMessageEntry` (:64–68: `type: "message"`, `message: AgentMessage`), `SessionEntry` union (:183), `parseSessionEntries` (:355, malformed lines skipped), `sessionEntryToContextMessages` (:439–474 — message-entry → context messages, with null/missing-content tolerance), `getDefaultSessionDir` (:596) + the session-dir/file layout it resolves (verify the exact path shape and file naming), `loadEntriesFromFile` (:627), `findMostRecentSession` (:749 — most-recent-for-cwd selection). Port the **message-entry subset only** (header + message entries); other entry types are out of scope.
    - **Print mode:** `packages/coding-agent/src/modes/print-mode.ts` — `PrintModeOptions` (:30–39: mode text/json, messages, initialMessage), the interface comment (:10–11: text = final response only, json = all events), exit-code semantics (the return values + signal handlers), raw stdout writes (`core/output-guard.ts` `writeRawStdout`/`flushRawStdout` — no buffering, no TUI anywhere). What pi `-p` does with approval-gated tools (auto-deny/auto-approve/flag — verify in the runtime path and port it; itemize if pi's choice can't port cleanly). json event mode is **out of scope**.
    - **MCP:** `packages/mcp/src/client.ts` (JSON-RPC client: state machine, `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (:40), initialize handshake, tools/list with pagination (`MAX_LIST_PAGES`), tools/call), `packages/mcp/src/protocol/jsonrpc.ts` (message validation — request/response/notification shapes, error codes), `packages/mcp/src/protocol/types.ts` (`Tool`, `InitializeResult`, protocol versions), `packages/mcp/src/transports/stdio.ts` (stdio framing: newline-delimited JSON over the child's stdin/stdout; stderr + child reaping on close), `packages/coding-agent/src/core/mcp-servers.ts` (`mcp.json` shape: `mcpServers: {name: {command, args?, env?}}` validated at :292–304 with pi's exact error strings; `isMcpToolName` — `mcp__<server>__<tool>`; the tool-exposure modes at the file head — the port ships `direct` only, itemized). MCP resources/prompts/sampling/notifications-handled and the streamable-http transport are **out of scope**.
  - **Hermetic discipline:** no real LLM traffic (agent-level tests run on the existing `test/support/mock_llm_server.rb` — read-only); MCP tests run against a **pure-Ruby fixture MCP server** (`test/support/mcp_echo_server.rb`, the mcp lane's new file) spawned as a subprocess over real stdio pipes — no network, no keys; session tests write to tmp dirs (never `~/.pi` or `~/.raspberry-pi`); print tests run headless on the mock server with no terminal session. No changes to the mock server or shared fixtures.
  - **House style:** as I02–I06 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared `RaspberryPi::Test` base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `session`/`mcp`/`print`, mutually disjoint; `cli` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, `~/.raspberry-pi`, no git write commands, no real LLM or MCP API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `session` may touch:** `lib/raspberry_pi/agent/session.rb` (new), `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/session_test.rb` (new). Registration is yours via `require_relative "session"` in `agent/loop.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `mcp` may touch:** `lib/raspberry_pi/mcp.rb` (new) + `lib/raspberry_pi/mcp/**` (new dir, exclusively yours), `lib/raspberry_pi/tools/registry.rb`, `test/mcp_test.rb` (new), `test/support/mcp_echo_server.rb` (new fixture). Registration is yours from `tools/registry.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `print` may touch:** `lib/raspberry_pi/print.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/print_test.rb` (new).
  - **Lane `cli` (fast-follow) may touch:** `bin/raspberry-pi`, `README.md` (usage sections only). It must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/support/mock_llm_server.rb`, `test/golden_parity_test.rb`, `test/fixtures/**`, `test/test_helper.rb`, `bench/**`, `Gemfile`/`Gemfile.lock` are in **no** lane's touch set — raise in PHASE 0 if a change is needed; do not touch. `lib/raspberry_pi.rb` is `print`'s; `tools/registry.rb` is `mcp`'s; `agent/loop.rb` is `session`'s — others raise in PHASE 0. Wave-1 lanes must not depend on each other's new files: `print` runs on the base `Agent::Loop`/`Tools::Registry` interfaces (unchanged optional kwargs only), `mcp` merges behind an optional `Registry.build` kwarg, `session` adds an optional recorder kwarg to `Agent::Loop` — all existing call sites stay green unmodified.
  - **Out of scope:** compaction + all non-message session entry types (thinking_level_change, model_change, usage, label, branch_summary, custom), session listing/switching UI, session export (markdown/HTML), session share, MCP resources/prompts/sampling/roots, MCP streamable-http + OAuth, tool exposure modes beyond `direct`, deferred tools, json event mode (`--mode json`), print-mode images/@file mentions, print-mode multi-prompt chaining beyond what pi's options port trivially, any TUI changes.
- **Deliverables:**
  1. **Session recording (`session`):** `Agent::Loop` accepts an optional session recorder (nil = off; all existing behavior and tests unchanged). A recorded turn writes a JSONL session file: line 1 is the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one **message entry** per message in order — user messages and assistant messages (tool calls/results included as they occur) — each `type: "message"` with the pi entry-base fields (id, parentId, timestamp, message). One JSON object per line, parseable by a line-oriented reader with malformed lines skipped (pi :355 semantics). Injectable path; tests write tmp dirs.
  2. **Resume (`session`):** a session file loads back to the message history the model sees — message entries → context messages (`sessionEntryToContextMessages` semantics for the message subset, including null/missing-content tolerance), seeded into the chat so the **captured request payload contains the prior turns** (MockLLMServer proof — the model demonstrably sees them); most-recent-session-for-cwd selection (pi `findMostRecentSession` semantics); a resumed conversation continues recording into a **new** session file whose header links the old via `parentSession`.
  3. **MCP client (`mcp`):** a hand-rolled stdio MCP client — spawn (`command`, `args`, `env`), newline-delimited JSON-RPC over the child's stdio (stderr passthrough; child reaped on close), initialize handshake (protocol version, capabilities, client/server info), `tools/list` (pagination tolerated), `tools/call` with the 30 s default request timeout; JSON-RPC message validation and error codes per pi's `jsonrpc.ts`; transport + client split mirroring pi's shape. Hermetic tests against the fixture echo server.
  4. **MCP integration (`mcp`):** servers configured from an `mcp.json`-shaped source — `{"mcpServers": {name: {command, args?, env?}}}` — validated with pi's exact error strings (mcp-servers.ts:292–304); default path `~/.raspberry-pi/mcp.json`, overridable, missing file = no servers, no error. Configured servers' tools register into the loadout behind the schema gate named `mcp__<server>__<tool>`, declared `direct` (exposure simplification itemized); an unconfigured/absent server never connects. Agent-level round-trip proof: the model calls an MCP tool (MockLLMServer script), the fixture echo server answers over real stdio, the result returns to the model as the tool result.
  5. **Print mode (`print`):** a headless single-shot run — prompt → `Agent::Loop` to completion with a stdout event sink, no TUI anywhere on the path; text mode writes the **final response only** (pi's text-mode contract) to raw stdout unbuffered; exit code 0 on success, pi's non-zero semantics on agent error (verify :print-mode.ts); pi's print-mode approval disposition for gated tools (verify, port, itemize). Hermetic: MockLLMServer, no terminal session, tmp cwd.
  6. **CLI wiring (`cli`, wave-2 fast-follow):** `bin/raspberry-pi` gains `-p/--print PROMPT` (non-interactive single-shot; flag shape verified against pi's `cli/args.ts`), `--resume [ID]` (interactive resume, default most-recent-for-workdir), session recording on by default for interactive runs (pi records every session), and MCP config loading (default `~/.raspberry-pi/mcp.json`, env override) into `Tools::Registry.build`; `--help` documents all of it and stays headless-safe; `README.md` usage sections updated.
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — every named file in exactly one set; the `mcp/**` dir is new and exclusively the mcp lane's): `session` (JSONL recording + resume), `mcp` (client + registry integration), `print` (headless single-shot mode). **Wave 2:** `cli` (launcher flags + README; the shared-surface seam, rooted at the integrated tip per the fast-follow pattern).
- **Effort call:** session high (resume semantics + history-seeding mechanism against gem source + wire-capture proofs), mcp high (protocol client + transport + schema translation + integration), print medium (event-sink mode over existing loop; the mechanism is plumbing), cli medium (flag surface + wiring, roots at the tip where all three exist). Recorded: mcp and session are the load-bearing lanes; both run at high.

```lanes
- name: session
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: mcp
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/mcp.rb
    - lib/raspberry_pi/mcp/**
    - lib/raspberry_pi/tools/registry.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
- name: print
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/print.rb
    - lib/raspberry_pi.rb
    - test/print_test.rb
- name: cli
  repo: raspberry-pi
  touch:
    - bin/raspberry-pi
    - README.md
```


=== ACCEPTANCE CRITERIA (frozen) ===

## Acceptance Criteria

**AC1 (session recording — BRIEF §7.1).** A recorded agent turn writes a JSONL session file: line 1 the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one message entry per message in order (user, assistant incl. tool calls/results) with the pi entry-base fields — test-proven by parsing the file back (line-oriented, malformed-line-skip tolerance) and asserting the recorded sequence matches the conversation. The recorder is optional (nil = off) and every existing agent-loop test passes unmodified. Format parity vs pi's session-manager.ts is architect-read from the lane's citations.

**AC2 (resume — BRIEF §7.1).** A resumed conversation makes the model see prior turns — proven by the **captured MockLLMServer request payload containing the prior turns' messages**; most-recent-session-for-cwd selection is test-proven; the resumed run records into a new session file whose header links the old via `parentSession`. Tolerance for null/missing content entries is ported from pi (`sessionEntryToContextMessages` :439–474) — itemized in the findings table.

**AC3 (MCP client — BRIEF §7.3).** The hand-rolled stdio MCP client completes a round trip against the fixture echo server — initialize handshake, `tools/list`, `tools/call` returning the tool result — over real stdio pipes, with the 30 s default request timeout and pi's JSON-RPC validation/error semantics; child process reaped on close. Hermetic (no network, no keys, no real MCP traffic). No new runtime dependencies (gem-pins gate).

**AC4 (MCP integration — BRIEF §7.3, §2).** Configured servers' tools register into the loadout behind the schema gate, named `mcp__<server>__<tool>`, declared `direct`; an agent-level round trip is test-proven: the model calls the MCP tool (MockLLMServer script), the fixture server answers over stdio, the result returns to the model as the tool result. Config validation carries pi's exact error strings (mcp-servers.ts:292–304); a missing config file means no servers, no error; an unconfigured server never connects (test-proven). The `direct`-only exposure simplification is itemized in the parity table.

**AC5 (print mode — BRIEF §7.4).** A single-shot headless run sends the prompt and writes the **final response only** to raw stdout (unbuffered), with pi's exit-code semantics (0 on success, the verified non-zero path on agent error) and pi's verified approval disposition for gated tools; no TUI anywhere on the path (architect-read + the tests run with no terminal session). Hermetic on MockLLMServer with a tmp cwd.

**AC6 (CLI wiring — wave-2 fast-follow, BRIEF §7.1/§7.3/§7.4).** `bin/raspberry-pi` wires `-p/--print PROMPT`, `--resume` (default most-recent-for-workdir), default-on session recording for interactive runs, and MCP config loading; `--help` documents all of it and runs headless-safe (gate `cli-help`); `README.md` usage sections updated (architect-read). Judged at final integration after the cli lane merges (cli-help is RED until then by construction — the wave-2 seam).

**AC7 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: session-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC3, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: print-guard
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: tui-seam
  ac: AC3, AC5, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC3, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: cli-help
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK
  expect:
    exit_code: 0
    stdout_match: CLI_OK
```

## Specification

- **Objective:** Close three BRIEF §7 definition-of-done gaps in one iteration through parallel lanes — **§7.1 resumable JSONL sessions** (the last interactive-TUI gap: a conversation survives restart), **§7.3 MCP servers** (connectable + usable — external tools via stdio), **§7.4 print mode** (headless single-shot runs; eventually this project's own builder lanes can run on it) — plus a wave-2 CLI-wiring fast-follow surfacing all three through `bin/raspberry-pi`. **Why this shape (per the human's direction: maximize parallel builders per iteration):** session, mcp, and print are library-level work with disjoint touch sets — session lives in the agent layer, mcp in a new `mcp` module + the tool registry, print in a new mode module; the only shared surface is the CLI launcher and README, so per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`; proven in I06), wave 1 is three mutually disjoint lanes and `cli` is the wave-2 lane provisioned off the integrated tip after wave 1 merges. Compaction (§7.6) is deliberately **out** — it builds on session persistence and lands as its own later iteration.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the session entry subset + id scheme as ported; the resume mechanism; the MCP transport/client shape; the tool-wrapper seam; print-mode approval semantics), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the JSONL session store, the JSON-RPC MCP client, and print mode are all hand-rolled by default; proposing a gem (mcp gem, thor-like CLI gem) is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ruby_llm --path`), each item in the findings table: how a `RubyLLM::Chat` accumulates and replays message history (what `chat.messages` holds after turns, how prior messages are seeded for a new chat — the resume mechanism must re-feed prior turns so the model sees them; prove via the captured request payload); the `RubyLLM::Tool` contract for `chat.with_tools` (subclass interface: name/description/schema/execute — the port's `Tools::Read` etc. are the working examples; the MCP wrapper must satisfy whatever the gem actually requires); how a tool result/exception surfaces into the message history (what the session recorder observes for a tool turn).
  - **pi reference (read-only oracle, `repos/pi`):**
    - **Sessions:** `packages/coding-agent/src/core/session-manager.ts` — `CURRENT_SESSION_VERSION = 3` (:41), `SessionHeader` (:43–51: `type: "session"`, version, id, timestamp, cwd, `parentSession?`), `SessionEntryBase` (:57–63: type, id, parentId, timestamp), `SessionMessageEntry` (:64–68: `type: "message"`, `message: AgentMessage`), `SessionEntry` union (:183), `parseSessionEntries` (:355, malformed lines skipped), `sessionEntryToContextMessages` (:439–474 — message-entry → context messages, with null/missing-content tolerance), `getDefaultSessionDir` (:596) + the session-dir/file layout it resolves (verify the exact path shape and file naming), `loadEntriesFromFile` (:627), `findMostRecentSession` (:749 — most-recent-for-cwd selection). Port the **message-entry subset only** (header + message entries); other entry types are out of scope.
    - **Print mode:** `packages/coding-agent/src/modes/print-mode.ts` — `PrintModeOptions` (:30–39: mode text/json, messages, initialMessage), the interface comment (:10–11: text = final response only, json = all events), exit-code semantics (the return values + signal handlers), raw stdout writes (`core/output-guard.ts` `writeRawStdout`/`flushRawStdout` — no buffering, no TUI anywhere). What pi `-p` does with approval-gated tools (auto-deny/auto-approve/flag — verify in the runtime path and port it; itemize if pi's choice can't port cleanly). json event mode is **out of scope**.
    - **MCP:** `packages/mcp/src/client.ts` (JSON-RPC client: state machine, `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (:40), initialize handshake, tools/list with pagination (`MAX_LIST_PAGES`), tools/call), `packages/mcp/src/protocol/jsonrpc.ts` (message validation — request/response/notification shapes, error codes), `packages/mcp/src/protocol/types.ts` (`Tool`, `InitializeResult`, protocol versions), `packages/mcp/src/transports/stdio.ts` (stdio framing: newline-delimited JSON over the child's stdin/stdout; stderr + child reaping on close), `packages/coding-agent/src/core/mcp-servers.ts` (`mcp.json` shape: `mcpServers: {name: {command, args?, env?}}` validated at :292–304 with pi's exact error strings; `isMcpToolName` — `mcp__<server>__<tool>`; the tool-exposure modes at the file head — the port ships `direct` only, itemized). MCP resources/prompts/sampling/notifications-handled and the streamable-http transport are **out of scope**.
  - **Hermetic discipline:** no real LLM traffic (agent-level tests run on the existing `test/support/mock_llm_server.rb` — read-only); MCP tests run against a **pure-Ruby fixture MCP server** (`test/support/mcp_echo_server.rb`, the mcp lane's new file) spawned as a subprocess over real stdio pipes — no network, no keys; session tests write to tmp dirs (never `~/.pi` or `~/.raspberry-pi`); print tests run headless on the mock server with no terminal session. No changes to the mock server or shared fixtures.
  - **House style:** as I02–I06 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared `RaspberryPi::Test` base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `session`/`mcp`/`print`, mutually disjoint; `cli` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, `~/.raspberry-pi`, no git write commands, no real LLM or MCP API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `session` may touch:** `lib/raspberry_pi/agent/session.rb` (new), `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/session_test.rb` (new). Registration is yours via `require_relative "session"` in `agent/loop.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `mcp` may touch:** `lib/raspberry_pi/mcp.rb` (new) + `lib/raspberry_pi/mcp/**` (new dir, exclusively yours), `lib/raspberry_pi/tools/registry.rb`, `test/mcp_test.rb` (new), `test/support/mcp_echo_server.rb` (new fixture). Registration is yours from `tools/registry.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `print` may touch:** `lib/raspberry_pi/print.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/print_test.rb` (new).
  - **Lane `cli` (fast-follow) may touch:** `bin/raspberry-pi`, `README.md` (usage sections only). It must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/support/mock_llm_server.rb`, `test/golden_parity_test.rb`, `test/fixtures/**`, `test/test_helper.rb`, `bench/**`, `Gemfile`/`Gemfile.lock` are in **no** lane's touch set — raise in PHASE 0 if a change is needed; do not touch. `lib/raspberry_pi.rb` is `print`'s; `tools/registry.rb` is `mcp`'s; `agent/loop.rb` is `session`'s — others raise in PHASE 0. Wave-1 lanes must not depend on each other's new files: `print` runs on the base `Agent::Loop`/`Tools::Registry` interfaces (unchanged optional kwargs only), `mcp` merges behind an optional `Registry.build` kwarg, `session` adds an optional recorder kwarg to `Agent::Loop` — all existing call sites stay green unmodified.
  - **Out of scope:** compaction + all non-message session entry types (thinking_level_change, model_change, usage, label, branch_summary, custom), session listing/switching UI, session export (markdown/HTML), session share, MCP resources/prompts/sampling/roots, MCP streamable-http + OAuth, tool exposure modes beyond `direct`, deferred tools, json event mode (`--mode json`), print-mode images/@file mentions, print-mode multi-prompt chaining beyond what pi's options port trivially, any TUI changes.
- **Deliverables:**
  1. **Session recording (`session`):** `Agent::Loop` accepts an optional session recorder (nil = off; all existing behavior and tests unchanged). A recorded turn writes a JSONL session file: line 1 is the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one **message entry** per message in order — user messages and assistant messages (tool calls/results included as they occur) — each `type: "message"` with the pi entry-base fields (id, parentId, timestamp, message). One JSON object per line, parseable by a line-oriented reader with malformed lines skipped (pi :355 semantics). Injectable path; tests write tmp dirs.
  2. **Resume (`session`):** a session file loads back to the message history the model sees — message entries → context messages (`sessionEntryToContextMessages` semantics for the message subset, including null/missing-content tolerance), seeded into the chat so the **captured request payload contains the prior turns** (MockLLMServer proof — the model demonstrably sees them); most-recent-session-for-cwd selection (pi `findMostRecentSession` semantics); a resumed conversation continues recording into a **new** session file whose header links the old via `parentSession`.
  3. **MCP client (`mcp`):** a hand-rolled stdio MCP client — spawn (`command`, `args`, `env`), newline-delimited JSON-RPC over the child's stdio (stderr passthrough; child reaped on close), initialize handshake (protocol version, capabilities, client/server info), `tools/list` (pagination tolerated), `tools/call` with the 30 s default request timeout; JSON-RPC message validation and error codes per pi's `jsonrpc.ts`; transport + client split mirroring pi's shape. Hermetic tests against the fixture echo server.
  4. **MCP integration (`mcp`):** servers configured from an `mcp.json`-shaped source — `{"mcpServers": {name: {command, args?, env?}}}` — validated with pi's exact error strings (mcp-servers.ts:292–304); default path `~/.raspberry-pi/mcp.json`, overridable, missing file = no servers, no error. Configured servers' tools register into the loadout behind the schema gate named `mcp__<server>__<tool>`, declared `direct` (exposure simplification itemized); an unconfigured/absent server never connects. Agent-level round-trip proof: the model calls an MCP tool (MockLLMServer script), the fixture echo server answers over real stdio, the result returns to the model as the tool result.
  5. **Print mode (`print`):** a headless single-shot run — prompt → `Agent::Loop` to completion with a stdout event sink, no TUI anywhere on the path; text mode writes the **final response only** (pi's text-mode contract) to raw stdout unbuffered; exit code 0 on success, pi's non-zero semantics on agent error (verify :print-mode.ts); pi's print-mode approval disposition for gated tools (verify, port, itemize). Hermetic: MockLLMServer, no terminal session, tmp cwd.
  6. **CLI wiring (`cli`, wave-2 fast-follow):** `bin/raspberry-pi` gains `-p/--print PROMPT` (non-interactive single-shot; flag shape verified against pi's `cli/args.ts`), `--resume [ID]` (interactive resume, default most-recent-for-workdir), session recording on by default for interactive runs (pi records every session), and MCP config loading (default `~/.raspberry-pi/mcp.json`, env override) into `Tools::Registry.build`; `--help` documents all of it and stays headless-safe; `README.md` usage sections updated.
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — every named file in exactly one set; the `mcp/**` dir is new and exclusively the mcp lane's): `session` (JSONL recording + resume), `mcp` (client + registry integration), `print` (headless single-shot mode). **Wave 2:** `cli` (launcher flags + README; the shared-surface seam, rooted at the integrated tip per the fast-follow pattern).
- **Effort call:** session high (resume semantics + history-seeding mechanism against gem source + wire-capture proofs), mcp high (protocol client + transport + schema translation + integration), print medium (event-sink mode over existing loop; the mechanism is plumbing), cli medium (flag surface + wiring, roots at the tip where all three exist). Recorded: mcp and session are the load-bearing lanes; both run at high.

```lanes
- name: session
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: mcp
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/mcp.rb
    - lib/raspberry_pi/mcp/**
    - lib/raspberry_pi/tools/registry.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
- name: print
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/print.rb
    - lib/raspberry_pi.rb
    - test/print_test.rb
- name: cli
  repo: raspberry-pi
  touch:
    - bin/raspberry-pi
    - README.md
```


=== ACCEPTANCE CRITERIA (frozen) ===

## Acceptance Criteria

**AC1 (session recording — BRIEF §7.1).** A recorded agent turn writes a JSONL session file: line 1 the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one message entry per message in order (user, assistant incl. tool calls/results) with the pi entry-base fields — test-proven by parsing the file back (line-oriented, malformed-line-skip tolerance) and asserting the recorded sequence matches the conversation. The recorder is optional (nil = off) and every existing agent-loop test passes unmodified. Format parity vs pi's session-manager.ts is architect-read from the lane's citations.

**AC2 (resume — BRIEF §7.1).** A resumed conversation makes the model see prior turns — proven by the **captured MockLLMServer request payload containing the prior turns' messages**; most-recent-session-for-cwd selection is test-proven; the resumed run records into a new session file whose header links the old via `parentSession`. Tolerance for null/missing content entries is ported from pi (`sessionEntryToContextMessages` :439–474) — itemized in the findings table.

**AC3 (MCP client — BRIEF §7.3).** The hand-rolled stdio MCP client completes a round trip against the fixture echo server — initialize handshake, `tools/list`, `tools/call` returning the tool result — over real stdio pipes, with the 30 s default request timeout and pi's JSON-RPC validation/error semantics; child process reaped on close. Hermetic (no network, no keys, no real MCP traffic). No new runtime dependencies (gem-pins gate).

**AC4 (MCP integration — BRIEF §7.3, §2).** Configured servers' tools register into the loadout behind the schema gate, named `mcp__<server>__<tool>`, declared `direct`; an agent-level round trip is test-proven: the model calls the MCP tool (MockLLMServer script), the fixture server answers over stdio, the result returns to the model as the tool result. Config validation carries pi's exact error strings (mcp-servers.ts:292–304); a missing config file means no servers, no error; an unconfigured server never connects (test-proven). The `direct`-only exposure simplification is itemized in the parity table.

**AC5 (print mode — BRIEF §7.4).** A single-shot headless run sends the prompt and writes the **final response only** to raw stdout (unbuffered), with pi's exit-code semantics (0 on success, the verified non-zero path on agent error) and pi's verified approval disposition for gated tools; no TUI anywhere on the path (architect-read + the tests run with no terminal session). Hermetic on MockLLMServer with a tmp cwd.

**AC6 (CLI wiring — wave-2 fast-follow, BRIEF §7.1/§7.3/§7.4).** `bin/raspberry-pi` wires `-p/--print PROMPT`, `--resume` (default most-recent-for-workdir), default-on session recording for interactive runs, and MCP config loading; `--help` documents all of it and runs headless-safe (gate `cli-help`); `README.md` usage sections updated (architect-read). Judged at final integration after the cli lane merges (cli-help is RED until then by construction — the wave-2 seam).

**AC7 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: session-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC3, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: print-guard
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: tui-seam
  ac: AC3, AC5, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC3, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: cli-help
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK
  expect:
    exit_code: 0
    stdout_match: CLI_OK
```

## Specification

- **Objective:** Close three BRIEF §7 definition-of-done gaps in one iteration through parallel lanes — **§7.1 resumable JSONL sessions** (the last interactive-TUI gap: a conversation survives restart), **§7.3 MCP servers** (connectable + usable — external tools via stdio), **§7.4 print mode** (headless single-shot runs; eventually this project's own builder lanes can run on it) — plus a wave-2 CLI-wiring fast-follow surfacing all three through `bin/raspberry-pi`. **Why this shape (per the human's direction: maximize parallel builders per iteration):** session, mcp, and print are library-level work with disjoint touch sets — session lives in the agent layer, mcp in a new `mcp` module + the tool registry, print in a new mode module; the only shared surface is the CLI launcher and README, so per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`; proven in I06), wave 1 is three mutually disjoint lanes and `cli` is the wave-2 lane provisioned off the integrated tip after wave 1 merges. Compaction (§7.6) is deliberately **out** — it builds on session persistence and lands as its own later iteration.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the session entry subset + id scheme as ported; the resume mechanism; the MCP transport/client shape; the tool-wrapper seam; print-mode approval semantics), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the JSONL session store, the JSON-RPC MCP client, and print mode are all hand-rolled by default; proposing a gem (mcp gem, thor-like CLI gem) is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ruby_llm --path`), each item in the findings table: how a `RubyLLM::Chat` accumulates and replays message history (what `chat.messages` holds after turns, how prior messages are seeded for a new chat — the resume mechanism must re-feed prior turns so the model sees them; prove via the captured request payload); the `RubyLLM::Tool` contract for `chat.with_tools` (subclass interface: name/description/schema/execute — the port's `Tools::Read` etc. are the working examples; the MCP wrapper must satisfy whatever the gem actually requires); how a tool result/exception surfaces into the message history (what the session recorder observes for a tool turn).
  - **pi reference (read-only oracle, `repos/pi`):**
    - **Sessions:** `packages/coding-agent/src/core/session-manager.ts` — `CURRENT_SESSION_VERSION = 3` (:41), `SessionHeader` (:43–51: `type: "session"`, version, id, timestamp, cwd, `parentSession?`), `SessionEntryBase` (:57–63: type, id, parentId, timestamp), `SessionMessageEntry` (:64–68: `type: "message"`, `message: AgentMessage`), `SessionEntry` union (:183), `parseSessionEntries` (:355, malformed lines skipped), `sessionEntryToContextMessages` (:439–474 — message-entry → context messages, with null/missing-content tolerance), `getDefaultSessionDir` (:596) + the session-dir/file layout it resolves (verify the exact path shape and file naming), `loadEntriesFromFile` (:627), `findMostRecentSession` (:749 — most-recent-for-cwd selection). Port the **message-entry subset only** (header + message entries); other entry types are out of scope.
    - **Print mode:** `packages/coding-agent/src/modes/print-mode.ts` — `PrintModeOptions` (:30–39: mode text/json, messages, initialMessage), the interface comment (:10–11: text = final response only, json = all events), exit-code semantics (the return values + signal handlers), raw stdout writes (`core/output-guard.ts` `writeRawStdout`/`flushRawStdout` — no buffering, no TUI anywhere). What pi `-p` does with approval-gated tools (auto-deny/auto-approve/flag — verify in the runtime path and port it; itemize if pi's choice can't port cleanly). json event mode is **out of scope**.
    - **MCP:** `packages/mcp/src/client.ts` (JSON-RPC client: state machine, `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (:40), initialize handshake, tools/list with pagination (`MAX_LIST_PAGES`), tools/call), `packages/mcp/src/protocol/jsonrpc.ts` (message validation — request/response/notification shapes, error codes), `packages/mcp/src/protocol/types.ts` (`Tool`, `InitializeResult`, protocol versions), `packages/mcp/src/transports/stdio.ts` (stdio framing: newline-delimited JSON over the child's stdin/stdout; stderr + child reaping on close), `packages/coding-agent/src/core/mcp-servers.ts` (`mcp.json` shape: `mcpServers: {name: {command, args?, env?}}` validated at :292–304 with pi's exact error strings; `isMcpToolName` — `mcp__<server>__<tool>`; the tool-exposure modes at the file head — the port ships `direct` only, itemized). MCP resources/prompts/sampling/notifications-handled and the streamable-http transport are **out of scope**.
  - **Hermetic discipline:** no real LLM traffic (agent-level tests run on the existing `test/support/mock_llm_server.rb` — read-only); MCP tests run against a **pure-Ruby fixture MCP server** (`test/support/mcp_echo_server.rb`, the mcp lane's new file) spawned as a subprocess over real stdio pipes — no network, no keys; session tests write to tmp dirs (never `~/.pi` or `~/.raspberry-pi`); print tests run headless on the mock server with no terminal session. No changes to the mock server or shared fixtures.
  - **House style:** as I02–I06 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared `RaspberryPi::Test` base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `session`/`mcp`/`print`, mutually disjoint; `cli` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, `~/.raspberry-pi`, no git write commands, no real LLM or MCP API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `session` may touch:** `lib/raspberry_pi/agent/session.rb` (new), `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/session_test.rb` (new). Registration is yours via `require_relative "session"` in `agent/loop.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `mcp` may touch:** `lib/raspberry_pi/mcp.rb` (new) + `lib/raspberry_pi/mcp/**` (new dir, exclusively yours), `lib/raspberry_pi/tools/registry.rb`, `test/mcp_test.rb` (new), `test/support/mcp_echo_server.rb` (new fixture). Registration is yours from `tools/registry.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `print` may touch:** `lib/raspberry_pi/print.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/print_test.rb` (new).
  - **Lane `cli` (fast-follow) may touch:** `bin/raspberry-pi`, `README.md` (usage sections only). It must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/support/mock_llm_server.rb`, `test/golden_parity_test.rb`, `test/fixtures/**`, `test/test_helper.rb`, `bench/**`, `Gemfile`/`Gemfile.lock` are in **no** lane's touch set — raise in PHASE 0 if a change is needed; do not touch. `lib/raspberry_pi.rb` is `print`'s; `tools/registry.rb` is `mcp`'s; `agent/loop.rb` is `session`'s — others raise in PHASE 0. Wave-1 lanes must not depend on each other's new files: `print` runs on the base `Agent::Loop`/`Tools::Registry` interfaces (unchanged optional kwargs only), `mcp` merges behind an optional `Registry.build` kwarg, `session` adds an optional recorder kwarg to `Agent::Loop` — all existing call sites stay green unmodified.
  - **Out of scope:** compaction + all non-message session entry types (thinking_level_change, model_change, usage, label, branch_summary, custom), session listing/switching UI, session export (markdown/HTML), session share, MCP resources/prompts/sampling/roots, MCP streamable-http + OAuth, tool exposure modes beyond `direct`, deferred tools, json event mode (`--mode json`), print-mode images/@file mentions, print-mode multi-prompt chaining beyond what pi's options port trivially, any TUI changes.
- **Deliverables:**
  1. **Session recording (`session`):** `Agent::Loop` accepts an optional session recorder (nil = off; all existing behavior and tests unchanged). A recorded turn writes a JSONL session file: line 1 is the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one **message entry** per message in order — user messages and assistant messages (tool calls/results included as they occur) — each `type: "message"` with the pi entry-base fields (id, parentId, timestamp, message). One JSON object per line, parseable by a line-oriented reader with malformed lines skipped (pi :355 semantics). Injectable path; tests write tmp dirs.
  2. **Resume (`session`):** a session file loads back to the message history the model sees — message entries → context messages (`sessionEntryToContextMessages` semantics for the message subset, including null/missing-content tolerance), seeded into the chat so the **captured request payload contains the prior turns** (MockLLMServer proof — the model demonstrably sees them); most-recent-session-for-cwd selection (pi `findMostRecentSession` semantics); a resumed conversation continues recording into a **new** session file whose header links the old via `parentSession`.
  3. **MCP client (`mcp`):** a hand-rolled stdio MCP client — spawn (`command`, `args`, `env`), newline-delimited JSON-RPC over the child's stdio (stderr passthrough; child reaped on close), initialize handshake (protocol version, capabilities, client/server info), `tools/list` (pagination tolerated), `tools/call` with the 30 s default request timeout; JSON-RPC message validation and error codes per pi's `jsonrpc.ts`; transport + client split mirroring pi's shape. Hermetic tests against the fixture echo server.
  4. **MCP integration (`mcp`):** servers configured from an `mcp.json`-shaped source — `{"mcpServers": {name: {command, args?, env?}}}` — validated with pi's exact error strings (mcp-servers.ts:292–304); default path `~/.raspberry-pi/mcp.json`, overridable, missing file = no servers, no error. Configured servers' tools register into the loadout behind the schema gate named `mcp__<server>__<tool>`, declared `direct` (exposure simplification itemized); an unconfigured/absent server never connects. Agent-level round-trip proof: the model calls an MCP tool (MockLLMServer script), the fixture echo server answers over real stdio, the result returns to the model as the tool result.
  5. **Print mode (`print`):** a headless single-shot run — prompt → `Agent::Loop` to completion with a stdout event sink, no TUI anywhere on the path; text mode writes the **final response only** (pi's text-mode contract) to raw stdout unbuffered; exit code 0 on success, pi's non-zero semantics on agent error (verify :print-mode.ts); pi's print-mode approval disposition for gated tools (verify, port, itemize). Hermetic: MockLLMServer, no terminal session, tmp cwd.
  6. **CLI wiring (`cli`, wave-2 fast-follow):** `bin/raspberry-pi` gains `-p/--print PROMPT` (non-interactive single-shot; flag shape verified against pi's `cli/args.ts`), `--resume [ID]` (interactive resume, default most-recent-for-workdir), session recording on by default for interactive runs (pi records every session), and MCP config loading (default `~/.raspberry-pi/mcp.json`, env override) into `Tools::Registry.build`; `--help` documents all of it and stays headless-safe; `README.md` usage sections updated.
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — every named file in exactly one set; the `mcp/**` dir is new and exclusively the mcp lane's): `session` (JSONL recording + resume), `mcp` (client + registry integration), `print` (headless single-shot mode). **Wave 2:** `cli` (launcher flags + README; the shared-surface seam, rooted at the integrated tip per the fast-follow pattern).
- **Effort call:** session high (resume semantics + history-seeding mechanism against gem source + wire-capture proofs), mcp high (protocol client + transport + schema translation + integration), print medium (event-sink mode over existing loop; the mechanism is plumbing), cli medium (flag surface + wiring, roots at the tip where all three exist). Recorded: mcp and session are the load-bearing lanes; both run at high.

```lanes
- name: session
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: mcp
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/mcp.rb
    - lib/raspberry_pi/mcp/**
    - lib/raspberry_pi/tools/registry.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
- name: print
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/print.rb
    - lib/raspberry_pi.rb
    - test/print_test.rb
- name: cli
  repo: raspberry-pi
  touch:
    - bin/raspberry-pi
    - README.md
```


=== ACCEPTANCE CRITERIA (frozen) ===

## Acceptance Criteria

**AC1 (session recording — BRIEF §7.1).** A recorded agent turn writes a JSONL session file: line 1 the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one message entry per message in order (user, assistant incl. tool calls/results) with the pi entry-base fields — test-proven by parsing the file back (line-oriented, malformed-line-skip tolerance) and asserting the recorded sequence matches the conversation. The recorder is optional (nil = off) and every existing agent-loop test passes unmodified. Format parity vs pi's session-manager.ts is architect-read from the lane's citations.

**AC2 (resume — BRIEF §7.1).** A resumed conversation makes the model see prior turns — proven by the **captured MockLLMServer request payload containing the prior turns' messages**; most-recent-session-for-cwd selection is test-proven; the resumed run records into a new session file whose header links the old via `parentSession`. Tolerance for null/missing content entries is ported from pi (`sessionEntryToContextMessages` :439–474) — itemized in the findings table.

**AC3 (MCP client — BRIEF §7.3).** The hand-rolled stdio MCP client completes a round trip against the fixture echo server — initialize handshake, `tools/list`, `tools/call` returning the tool result — over real stdio pipes, with the 30 s default request timeout and pi's JSON-RPC validation/error semantics; child process reaped on close. Hermetic (no network, no keys, no real MCP traffic). No new runtime dependencies (gem-pins gate).

**AC4 (MCP integration — BRIEF §7.3, §2).** Configured servers' tools register into the loadout behind the schema gate, named `mcp__<server>__<tool>`, declared `direct`; an agent-level round trip is test-proven: the model calls the MCP tool (MockLLMServer script), the fixture server answers over stdio, the result returns to the model as the tool result. Config validation carries pi's exact error strings (mcp-servers.ts:292–304); a missing config file means no servers, no error; an unconfigured server never connects (test-proven). The `direct`-only exposure simplification is itemized in the parity table.

**AC5 (print mode — BRIEF §7.4).** A single-shot headless run sends the prompt and writes the **final response only** to raw stdout (unbuffered), with pi's exit-code semantics (0 on success, the verified non-zero path on agent error) and pi's verified approval disposition for gated tools; no TUI anywhere on the path (architect-read + the tests run with no terminal session). Hermetic on MockLLMServer with a tmp cwd.

**AC6 (CLI wiring — wave-2 fast-follow, BRIEF §7.1/§7.3/§7.4).** `bin/raspberry-pi` wires `-p/--print PROMPT`, `--resume` (default most-recent-for-workdir), default-on session recording for interactive runs, and MCP config loading; `--help` documents all of it and runs headless-safe (gate `cli-help`); `README.md` usage sections updated (architect-read). Judged at final integration after the cli lane merges (cli-help is RED until then by construction — the wave-2 seam).

**AC7 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: session-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC3, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: print-guard
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: tui-seam
  ac: AC3, AC5, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC3, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: cli-help
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK
  expect:
    exit_code: 0
    stdout_match: CLI_OK
```

## Specification

- **Objective:** Close three BRIEF §7 definition-of-done gaps in one iteration through parallel lanes — **§7.1 resumable JSONL sessions** (the last interactive-TUI gap: a conversation survives restart), **§7.3 MCP servers** (connectable + usable — external tools via stdio), **§7.4 print mode** (headless single-shot runs; eventually this project's own builder lanes can run on it) — plus a wave-2 CLI-wiring fast-follow surfacing all three through `bin/raspberry-pi`. **Why this shape (per the human's direction: maximize parallel builders per iteration):** session, mcp, and print are library-level work with disjoint touch sets — session lives in the agent layer, mcp in a new `mcp` module + the tool registry, print in a new mode module; the only shared surface is the CLI launcher and README, so per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`; proven in I06), wave 1 is three mutually disjoint lanes and `cli` is the wave-2 lane provisioned off the integrated tip after wave 1 merges. Compaction (§7.6) is deliberately **out** — it builds on session persistence and lands as its own later iteration.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the session entry subset + id scheme as ported; the resume mechanism; the MCP transport/client shape; the tool-wrapper seam; print-mode approval semantics), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the JSONL session store, the JSON-RPC MCP client, and print mode are all hand-rolled by default; proposing a gem (mcp gem, thor-like CLI gem) is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ruby_llm --path`), each item in the findings table: how a `RubyLLM::Chat` accumulates and replays message history (what `chat.messages` holds after turns, how prior messages are seeded for a new chat — the resume mechanism must re-feed prior turns so the model sees them; prove via the captured request payload); the `RubyLLM::Tool` contract for `chat.with_tools` (subclass interface: name/description/schema/execute — the port's `Tools::Read` etc. are the working examples; the MCP wrapper must satisfy whatever the gem actually requires); how a tool result/exception surfaces into the message history (what the session recorder observes for a tool turn).
  - **pi reference (read-only oracle, `repos/pi`):**
    - **Sessions:** `packages/coding-agent/src/core/session-manager.ts` — `CURRENT_SESSION_VERSION = 3` (:41), `SessionHeader` (:43–51: `type: "session"`, version, id, timestamp, cwd, `parentSession?`), `SessionEntryBase` (:57–63: type, id, parentId, timestamp), `SessionMessageEntry` (:64–68: `type: "message"`, `message: AgentMessage`), `SessionEntry` union (:183), `parseSessionEntries` (:355, malformed lines skipped), `sessionEntryToContextMessages` (:439–474 — message-entry → context messages, with null/missing-content tolerance), `getDefaultSessionDir` (:596) + the session-dir/file layout it resolves (verify the exact path shape and file naming), `loadEntriesFromFile` (:627), `findMostRecentSession` (:749 — most-recent-for-cwd selection). Port the **message-entry subset only** (header + message entries); other entry types are out of scope.
    - **Print mode:** `packages/coding-agent/src/modes/print-mode.ts` — `PrintModeOptions` (:30–39: mode text/json, messages, initialMessage), the interface comment (:10–11: text = final response only, json = all events), exit-code semantics (the return values + signal handlers), raw stdout writes (`core/output-guard.ts` `writeRawStdout`/`flushRawStdout` — no buffering, no TUI anywhere). What pi `-p` does with approval-gated tools (auto-deny/auto-approve/flag — verify in the runtime path and port it; itemize if pi's choice can't port cleanly). json event mode is **out of scope**.
    - **MCP:** `packages/mcp/src/client.ts` (JSON-RPC client: state machine, `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (:40), initialize handshake, tools/list with pagination (`MAX_LIST_PAGES`), tools/call), `packages/mcp/src/protocol/jsonrpc.ts` (message validation — request/response/notification shapes, error codes), `packages/mcp/src/protocol/types.ts` (`Tool`, `InitializeResult`, protocol versions), `packages/mcp/src/transports/stdio.ts` (stdio framing: newline-delimited JSON over the child's stdin/stdout; stderr + child reaping on close), `packages/coding-agent/src/core/mcp-servers.ts` (`mcp.json` shape: `mcpServers: {name: {command, args?, env?}}` validated at :292–304 with pi's exact error strings; `isMcpToolName` — `mcp__<server>__<tool>`; the tool-exposure modes at the file head — the port ships `direct` only, itemized). MCP resources/prompts/sampling/notifications-handled and the streamable-http transport are **out of scope**.
  - **Hermetic discipline:** no real LLM traffic (agent-level tests run on the existing `test/support/mock_llm_server.rb` — read-only); MCP tests run against a **pure-Ruby fixture MCP server** (`test/support/mcp_echo_server.rb`, the mcp lane's new file) spawned as a subprocess over real stdio pipes — no network, no keys; session tests write to tmp dirs (never `~/.pi` or `~/.raspberry-pi`); print tests run headless on the mock server with no terminal session. No changes to the mock server or shared fixtures.
  - **House style:** as I02–I06 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared `RaspberryPi::Test` base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `session`/`mcp`/`print`, mutually disjoint; `cli` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, `~/.raspberry-pi`, no git write commands, no real LLM or MCP API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `session` may touch:** `lib/raspberry_pi/agent/session.rb` (new), `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/session_test.rb` (new). Registration is yours via `require_relative "session"` in `agent/loop.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `mcp` may touch:** `lib/raspberry_pi/mcp.rb` (new) + `lib/raspberry_pi/mcp/**` (new dir, exclusively yours), `lib/raspberry_pi/tools/registry.rb`, `test/mcp_test.rb` (new), `test/support/mcp_echo_server.rb` (new fixture). Registration is yours from `tools/registry.rb` (owned) — do not touch `lib/raspberry_pi.rb` (print lane's).
  - **Lane `print` may touch:** `lib/raspberry_pi/print.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/print_test.rb` (new).
  - **Lane `cli` (fast-follow) may touch:** `bin/raspberry-pi`, `README.md` (usage sections only). It must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/support/mock_llm_server.rb`, `test/golden_parity_test.rb`, `test/fixtures/**`, `test/test_helper.rb`, `bench/**`, `Gemfile`/`Gemfile.lock` are in **no** lane's touch set — raise in PHASE 0 if a change is needed; do not touch. `lib/raspberry_pi.rb` is `print`'s; `tools/registry.rb` is `mcp`'s; `agent/loop.rb` is `session`'s — others raise in PHASE 0. Wave-1 lanes must not depend on each other's new files: `print` runs on the base `Agent::Loop`/`Tools::Registry` interfaces (unchanged optional kwargs only), `mcp` merges behind an optional `Registry.build` kwarg, `session` adds an optional recorder kwarg to `Agent::Loop` — all existing call sites stay green unmodified.
  - **Out of scope:** compaction + all non-message session entry types (thinking_level_change, model_change, usage, label, branch_summary, custom), session listing/switching UI, session export (markdown/HTML), session share, MCP resources/prompts/sampling/roots, MCP streamable-http + OAuth, tool exposure modes beyond `direct`, deferred tools, json event mode (`--mode json`), print-mode images/@file mentions, print-mode multi-prompt chaining beyond what pi's options port trivially, any TUI changes.
- **Deliverables:**
  1. **Session recording (`session`):** `Agent::Loop` accepts an optional session recorder (nil = off; all existing behavior and tests unchanged). A recorded turn writes a JSONL session file: line 1 is the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one **message entry** per message in order — user messages and assistant messages (tool calls/results included as they occur) — each `type: "message"` with the pi entry-base fields (id, parentId, timestamp, message). One JSON object per line, parseable by a line-oriented reader with malformed lines skipped (pi :355 semantics). Injectable path; tests write tmp dirs.
  2. **Resume (`session`):** a session file loads back to the message history the model sees — message entries → context messages (`sessionEntryToContextMessages` semantics for the message subset, including null/missing-content tolerance), seeded into the chat so the **captured request payload contains the prior turns** (MockLLMServer proof — the model demonstrably sees them); most-recent-session-for-cwd selection (pi `findMostRecentSession` semantics); a resumed conversation continues recording into a **new** session file whose header links the old via `parentSession`.
  3. **MCP client (`mcp`):** a hand-rolled stdio MCP client — spawn (`command`, `args`, `env`), newline-delimited JSON-RPC over the child's stdio (stderr passthrough; child reaped on close), initialize handshake (protocol version, capabilities, client/server info), `tools/list` (pagination tolerated), `tools/call` with the 30 s default request timeout; JSON-RPC message validation and error codes per pi's `jsonrpc.ts`; transport + client split mirroring pi's shape. Hermetic tests against the fixture echo server.
  4. **MCP integration (`mcp`):** servers configured from an `mcp.json`-shaped source — `{"mcpServers": {name: {command, args?, env?}}}` — validated with pi's exact error strings (mcp-servers.ts:292–304); default path `~/.raspberry-pi/mcp.json`, overridable, missing file = no servers, no error. Configured servers' tools register into the loadout behind the schema gate named `mcp__<server>__<tool>`, declared `direct` (exposure simplification itemized); an unconfigured/absent server never connects. Agent-level round-trip proof: the model calls an MCP tool (MockLLMServer script), the fixture echo server answers over real stdio, the result returns to the model as the tool result.
  5. **Print mode (`print`):** a headless single-shot run — prompt → `Agent::Loop` to completion with a stdout event sink, no TUI anywhere on the path; text mode writes the **final response only** (pi's text-mode contract) to raw stdout unbuffered; exit code 0 on success, pi's non-zero semantics on agent error (verify :print-mode.ts); pi's print-mode approval disposition for gated tools (verify, port, itemize). Hermetic: MockLLMServer, no terminal session, tmp cwd.
  6. **CLI wiring (`cli`, wave-2 fast-follow):** `bin/raspberry-pi` gains `-p/--print PROMPT` (non-interactive single-shot; flag shape verified against pi's `cli/args.ts`), `--resume [ID]` (interactive resume, default most-recent-for-workdir), session recording on by default for interactive runs (pi records every session), and MCP config loading (default `~/.raspberry-pi/mcp.json`, env override) into `Tools::Registry.build`; `--help` documents all of it and stays headless-safe; `README.md` usage sections updated.
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — every named file in exactly one set; the `mcp/**` dir is new and exclusively the mcp lane's): `session` (JSONL recording + resume), `mcp` (client + registry integration), `print` (headless single-shot mode). **Wave 2:** `cli` (launcher flags + README; the shared-surface seam, rooted at the integrated tip per the fast-follow pattern).
- **Effort call:** session high (resume semantics + history-seeding mechanism against gem source + wire-capture proofs), mcp high (protocol client + transport + schema translation + integration), print medium (event-sink mode over existing loop; the mechanism is plumbing), cli medium (flag surface + wiring, roots at the tip where all three exist). Recorded: mcp and session are the load-bearing lanes; both run at high.

```lanes
- name: session
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/session_test.rb
- name: mcp
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/mcp.rb
    - lib/raspberry_pi/mcp/**
    - lib/raspberry_pi/tools/registry.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
- name: print
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/print.rb
    - lib/raspberry_pi.rb
    - test/print_test.rb
- name: cli
  repo: raspberry-pi
  touch:
    - bin/raspberry-pi
    - README.md
```


=== ACCEPTANCE CRITERIA (frozen) ===

## Acceptance Criteria

**AC1 (session recording — BRIEF §7.1).** A recorded agent turn writes a JSONL session file: line 1 the header (`type: "session"`, version, id, timestamp, cwd, `parentSession` when resumed), then one message entry per message in order (user, assistant incl. tool calls/results) with the pi entry-base fields — test-proven by parsing the file back (line-oriented, malformed-line-skip tolerance) and asserting the recorded sequence matches the conversation. The recorder is optional (nil = off) and every existing agent-loop test passes unmodified. Format parity vs pi's session-manager.ts is architect-read from the lane's citations.

**AC2 (resume — BRIEF §7.1).** A resumed conversation makes the model see prior turns — proven by the **captured MockLLMServer request payload containing the prior turns' messages**; most-recent-session-for-cwd selection is test-proven; the resumed run records into a new session file whose header links the old via `parentSession`. Tolerance for null/missing content entries is ported from pi (`sessionEntryToContextMessages` :439–474) — itemized in the findings table.

**AC3 (MCP client — BRIEF §7.3).** The hand-rolled stdio MCP client completes a round trip against the fixture echo server — initialize handshake, `tools/list`, `tools/call` returning the tool result — over real stdio pipes, with the 30 s default request timeout and pi's JSON-RPC validation/error semantics; child process reaped on close. Hermetic (no network, no keys, no real MCP traffic). No new runtime dependencies (gem-pins gate).

**AC4 (MCP integration — BRIEF §7.3, §2).** Configured servers' tools register into the loadout behind the schema gate, named `mcp__<server>__<tool>`, declared `direct`; an agent-level round trip is test-proven: the model calls the MCP tool (MockLLMServer script), the fixture server answers over stdio, the result returns to the model as the tool result. Config validation carries pi's exact error strings (mcp-servers.ts:292–304); a missing config file means no servers, no error; an unconfigured server never connects (test-proven). The `direct`-only exposure simplification is itemized in the parity table.

**AC5 (print mode — BRIEF §7.4).** A single-shot headless run sends the prompt and writes the **final response only** to raw stdout (unbuffered), with pi's exit-code semantics (0 on success, the verified non-zero path on agent error) and pi's verified approval disposition for gated tools; no TUI anywhere on the path (architect-read + the tests run with no terminal session). Hermetic on MockLLMServer with a tmp cwd.

**AC6 (CLI wiring — wave-2 fast-follow, BRIEF §7.1/§7.3/§7.4).** `bin/raspberry-pi` wires `-p/--print PROMPT`, `--resume` (default most-recent-for-workdir), default-on session recording for interactive runs, and MCP config loading; `--help` documents all of it and runs headless-safe (gate `cli-help`); `README.md` usage sections updated (architect-read). Judged at final integration after the cli lane merges (cli-help is RED until then by construction — the wave-2 seam).

**AC7 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: session-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC3, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: print-guard
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: tui-seam
  ac: AC3, AC5, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC3, AC7
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC7
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: cli-help
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK
  expect:
    exit_code: 0
    stdout_match: CLI_OK
```

## Builder Report

### session

### PHASE 0 findings (spec-vs-reality, file:line evidence)

| Verify item | Reality | Evidence |
|---|---|---|
| Session header | `{type:"session", version:3, id, timestamp(ISO ms, Z), cwd, parentSession?}`; `parentSession` = previous session **file path** when persisting | pi `session-manager.ts:43-51`, `:1060-1070` (newSession), `:1698-1703` (fork) |
| Entry base / message entry | `{type, id, parentId, timestamp}`; message entry carries `message` (AgentMessage) | pi `session-manager.ts:57-68`, `:1197-1208` (appendMessage) |
| Entry ids | 8 hex chars, collision-checked 100×, fallback full uuid | pi `session-manager.ts:275-281` (generateId); port: `SecureRandom.hex(4)` + Set check |
| Session id | uuidv7 (`createSessionId`) | pi `session-manager.ts:264`; port hand-rolls uuidv7 (Ruby has no v7 builtin) |
| Dir/file layout | `<agentDir>/sessions/--<resolvedCwd with leading / stripped, [/\:]→"-"-->--/<ISO ts with [:.]→"-"--><id>.jsonl`; `getDefaultSessionDir` mkdirs | pi `session-manager.ts:596-604`, `:1080`; pi `config.ts:600-610,649` (`~/.pi/agent/sessions`) |
| Lazy file creation | file created (`wx`, header + buffer) only when session holds a user/assistant message; else append one line | pi `session-manager.ts:1166-1188` (`_hasConversation`/`_persist`) |
| Malformed-line skip | blank/malformed lines skipped on parse | pi `session-manager.ts:355-370` (parseSessionEntries) |
| Header validation on load | `[]` unless first entry is `type:"session"` with String id | pi `session-manager.ts:627-650` (loadEntriesFromFile) |
| Null-content tolerance | system role → `""`; user/assistant/toolResult → `[]` | pi `session-manager.ts:439-474` (sessionEntryToContextMessages) |
| Most-recent-for-cwd | `*.jsonl` by mtime desc; first valid header whose resolved cwd matches; races → null | pi `session-manager.ts:749-775` (findMostRecentSession) |
| `RubyLLM::Chat` history | `Chat#messages` plain reader; `Chat#add_message(Message\|Hash)` appends; `step` formats **all** messages into the request payload | gem `chat.rb:43,1034-1050,236-245`; gem `protocols/chat_completions/chat.rb:308-330` (format_messages) |
| Message serialization round-trip | `Message#to_h` is JSON-safe/compact; `Message.new` coerces the symbolized hash back (roles to_sym, `coerce_tool_calls` hash-of-hashes) | gem `message.rb:258-282,307-323,88-125` |
| Tool result surface | tool result = `Message` role `:tool`, `tool_call_id` + content; arrives atomically via `after_message` → loop's `:tool_message` item — exactly what the recorder observes | gem `chat.rb:236-245`; loop.rb `handle_item` |
| MockLLMServer sufficiency for AC2 | `captured_requests` exposes full parsed request bodies — sufficient; **no changes made** | test/support/mock_llm_server.rb (`@requests`, `captured_requests`) |

### Disagreements / parity deviations (all itemized; none silent)

| # | Item | pi behavior | Port behavior | Reason |
|---|---|---|---|---|
| 1 | Null-content tolerance mapping | user/assistant/toolResult null content → `[]` (content-block array) | → `""` for all roles | `RubyLLM::Message.normalize_content` raises `ArgumentError` on non-String/non-nil content (gem `message.rb:120-128`); `[]` cannot be seeded into a chat. `""` is the benign non-crashing equivalent; system role matches pi exactly |
| 2 | Message role vocabulary | pi roles `user`/`assistant`/`toolResult` | recorded `message` field carries ruby_llm roles (`"tool"` in JSON) | the recorded message is the port's actual `RubyLLM::Message` (`to_h`); renaming roles both ways would be a lossy cosmetic rewrite |
| 3 | Sessions root | `~/.pi/agent/sessions` | `~/.raspberry-pi/sessions` under an **injectable root** | matches the spec's own `~/.raspberry-pi/mcp.json` convention; tests inject tmp dirs only, `~` never touched |
| 4 | Session id scheme | uuidv7 via `crypto.randomUUID` variants | hand-rolled uuidv7 (~10 lines, version-7/variant bits asserted by test) | no Ruby builtin; time-ordering is load-bearing in pi's scheme |

No disagreements on: mock_llm_server (sufficient read-only), test_helper/golden_parity_test (unneeded), `lib/raspberry_pi.rb` (registration via `require_relative "session"` in `agent/loop.rb` works), gem pins (no new deps), Rakefile (already globs `test/**/*_test.rb`).

### Judgment calls (per output format)

- **Entry subset ported:** header + message entries only (spec scope); usage/model_change/etc. project to nothing on load.
- **Id scheme:** header id = uuidv7; entry ids = 8-hex collision-checked; `parentId` = leaf chain (first message `parentId: null`).
- **Resume mechanism:** `Agent::Session.context_messages(path)` → chat-ready attribute hashes → `Agent::Loop` `seed_messages:` kwarg → `chat.add_message` pre-run → prior turns appear in the captured wire payload (test-proven).
- **parentSession:** the previous session file's path (pi fork semantics).

### Files (my lane only)

| File | Change |
|---|---|
| `lib/raspberry_pi/agent/session.rb` | NEW — `Agent::Session` (uuidv7, ids, dir/file naming, parse/load, tolerant projection, most-recent) + `Agent::Session::Recorder` (lazy-flush JSONL appender, pi `_persist` semantics) |
| `lib/raspberry_pi/agent/loop.rb` | `require_relative "session"`; optional kwargs `recorder:` (nil = off) + `seed_messages: []`; `record` at the three message-materialization points (user, assistant step, tool result). All pre-existing call sites unchanged |
| `test/session_test.rb` | NEW — 7 tests, 50 assertions |
| `test/agent_loop_test.rb` | UNTOUCHED (kwargs optional; passes unmodified as required) |

Not touched: `lib/raspberry_pi.rb`, `test/support/mock_llm_server.rb`, `test/test_helper.rb`, `test/golden_parity_test.rb`, `Gemfile*`, gates' files. No commits, no git writes (`git status` shows the two modified/new files only).

### Gate outputs (verbatim, this run)

| Gate | Result | Verbatim evidence |
|---|---|---|
| suite-green | PASS | `135 runs, 484 assertions, 0 failures, 0 errors, 0 skips` / `SUITE_OK` |
| session-guard | PASS | `timeout 120 bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb` → `7 runs, 50 assertions, 0 failures, 0 errors, 0 skips` + `SESSION_OK` |
| stderr-quiet | PASS | `NO_WARN` |
| stderr-clean | PASS | `NO_EPIPE` |
| tui-seam | PASS | `SEAM_OK` |
| bench-seam | PASS | `SEAM_BENCH_OK` |
| gem-pins | PASS | `PINS_OK` |
| mcp-guard | NOT RUNNABLE: wave-1 deliverable (test/mcp_test.rb does not exist; not created) | `test -f test/mcp_test.rb` → missing |
| print-guard | NOT RUNNABLE: wave-1 deliverable (test/print_test.rb does not exist; not created) | `test -f test/print_test.rb` → missing |
| cli-help | NOT RUNNABLE: wave-2 deliverable — `--help` carries no `--print`/`--resume`/mcp yet | `ruby bin/raspberry-pi --help` output lacks the flags |

Both lane test files together via explicit require (both orders): `15 runs, 106 assertions, 0 failures, 0 errors, 0 skips`.

### Notes / concerns

1. **Gate quirk (session-guard), not weakened:** `ruby -Itest test/session_test.rb test/agent_loop_test.rb` only *executes* the first file — the second path becomes ARGV (Ruby does not chain-load scripts). The gate passes on session_test alone; agent_loop_test passes when actually loaded (verified above, 15 runs both orders). Flagging for the architect; gates are frozen so I changed nothing.
2. **One-time stderr warning from Ruby 4.0 IO internals:** `.../lib/raspberry_pi/agent/session.rb:232: warning: IO::Buffer is experimental...` fires once per process in my tests (interleaves kernel fibers with net/http streaming; attribution lands on my `File.open` frame, but no `IO::Buffer` is referenced by my code and the warning is not reproducible with the same IO idioms outside the kernel/streaming flow — plain `File.open("a")`/`readlines`/socket probes are silent). No gate checks it (stderr-quiet greps `unhandled exception`, stderr-clean greps `Broken pipe`); both pass.
3. **Defect found & fixed during build:** the first recorder draft flushed once and never appended later entries (file held only the user message) — caught by test 1, restructured `persist` to flush-then-append (pi `_persist`'s two branches).

STATUS: COMPLETE_WITH_CONCERNS (concern 1: session-guard's second file arg is ignored by ruby — gate proves session_test only; concern 2: one-time Ruby 4.0 `IO::Buffer` experimental warning attributed inside my test flow, gates unaffected; concern 3: parity deviations table is non-empty by construction — items 1–4 above are reported, never silent)

### mcp

### PHASE 0 findings (spec-vs-reality, file:line evidence)

| # | Verify item | Spec | Reality | Verdict |
|---|---|---|---|---|
| 1 | `RubyLLM::Tool` contract for `chat.with_tools` | wrapper must satisfy the gem | `with_tools` keys the tool hash by `tool.name.to_sym` (gem chat.rb:472-477); wire declaration = `tool.name/description/parameters_schema` (gem protocols/chat_completions/tools.rb:29-41, `tool_for`); `parameters(Hash)` accepted raw via `SchemaDefinition#resolve_direct_schema` (gem tool.rb:467-469: `deep_dup` for Hash); instance-level `#name` override is the repo's established seam (lib/raspberry_pi/tools/safe_execute.rb:22-24) | OK — `Mcp::Tool` overrides `#name`, `#description`, `#parameters_schema` (per-instance schema: the schema is the server's, not the class's) |
| 2 | Tool result/exception surfacing into history | what the session/tool layer observes | `invoke_tool` → `Tool#call` → `#execute` (gem chat.rb:1680-1700); **concurrency mode re-raises worker exceptions** (`tool_concurrency.rb:107-108` → `collect_results` raises `errors.first`) — a raising MCP tool would kill the step, so the wrapper must return `{error:}` itself; house idiom = `SafeExecute` (CancelledError propagates, StandardError → `{error: e.message}`) | OK — `Mcp::Tool#execute` mirrors that idiom without including SafeExecute (its `#name` definition would fight the wire-name override) |
| 3 | Client defaults | 30 s timeout, pagination | `DEFAULT_REQUEST_TIMEOUT_MS = 30_000` (pi client.ts:40), `MAX_LIST_PAGES = 1_000` (client.ts:41); initialize handshake + validation `client.ts:200-249`; unsupported-version error string `client.ts:216`; dispatch order response→request→notification (`handleMessage`, client.ts:398-409) | OK |
| 4 | JSON-RPC validation + error codes | jsonrpc.ts | codes -32700/-32600/-32601/-32602/-32603; `isJsonRpcResponse` result-XOR-error (jsonrpc.ts:86-92); `"Invalid JSON-RPC message"` (jsonrpc.ts:120-124); response for unknown id → error `"Received response for unknown MCP request …"` (client.ts:425-427) | OK |
| 5 | stdio framing + lifecycle | stdio.ts | newline-delimited JSON-RPC; trailing `\r` stripped, blank lines skipped (stdio.ts:237-247); `DEFAULT_MAX_MESSAGE_BYTES = 16MiB` (transport.ts:3); stderr capped 64KB (stdio.ts:211-218); close: stdin close → 500ms grace (`STDIN_CLOSE_GRACE_MS`, :9) → SIGTERM → `closeTimeoutMs` 2000 (:8) → SIGKILL; process groups (`detached`/`killProcessTree` negative-pid); incomplete-message-on-close error string (stdio.ts:105-108); exit hook kills live groups (stdio.ts:37-46) | OK — ported via `Process.spawn(pgroup: true)` + group kill + `at_exit` hook |
| 6 | config validation error strings | mcp-servers.ts:292-304 | exact strings verified: `server "x" must be an object` (:251), `server "x": args must be an array of strings` (:297), `server "x": env must map names to strings` (:300), `server "x": cwd must be a string` (:302), `server "x" needs either "command" (stdio) or "url" (streamable HTTP)` (:304); file-level `expected an object with an "mcpServers" object` (extensions/mcp/config.ts:102-105); missing file → no servers, no error (config.ts:94-95); per-file prefix `"{path}: "` (config.ts:96, :107) | OK |
| 7 | tool naming | `mcp__<server>__<tool>` | `createMcpToolName` (extensions/mcp/tools.ts:94-104): sanitize `[^A-Za-z0-9_]→_`, cap 64 chars (`MAX_TOOL_NAME_LENGTH`, tools.ts:31), sha256 8-hex suffix on overflow/collision; `isMcpToolName` prefix check (mcp-servers.ts:38-40) | OK — ported fully including hash-suffix tail |
| 8 | protocol versions | types.ts | `LATEST_PROTOCOL_VERSION = "2025-11-25"` (:4); `SUPPORTED_PROTOCOL_VERSIONS` = + 2025-06-18, 2025-03-26, 2024-11-05 (:9) | OK |
| 9 | exposure modes | `direct` only | codemode/deferred/direct/hidden (mcp-servers.ts:69-77, default `codemode`); port ships direct only | OK — itemized in parity table |
| 10 | registry seam | optional kwarg, default none | existing `Registry.build(selected:, cwd:, strip_trailing_whitespace:)` — all 17 existing call sites (bin/raspberry-pi:69, test/*) pass no MCP args | OK — added `mcp_servers: nil` kwarg; all call sites stay green |

### PHASE 0 disagreements / judgment calls

| # | Item | Decision |
|---|---|---|
| 1 | ruby_llm 2.1 ships its own MCP client (`RubyLLM::MCP`, gem lib/ruby_llm/mcp/) — no new dep needed | Followed spec: hand-rolled client mirroring pi's transport/client split. The gem's `with_mcp` integration bypasses the port's Registry seam and carries its own naming/visibility/OAuth semantics. Flagged for the architect; no dep added. |
| 2 | `url` entries in mcp.json: pi accepts them (streamable-http); port is stdio-only per spec | Port rejects with a port-specific string `server "x": streamable HTTP transport is not supported (stdio only)` — invented string, itemized here (pi would have accepted). |
| 3 | pi's per-server `timeout` field (seconds, default 60, mcp-servers.ts:237) | Not in the spec's `{command, args?, env?}` shape; skipped. Client default = pi's client.ts:40 30 s (pi's runtime layer overrides to 60 s per server; port skips that layer). |
| 4 | pi's `McpAbortError`/AbortSignal support (jsonrpc.ts, client.ts) | No signal machinery in the port's synchronous request path; cancellation is loop-level. Out of the ported surface. |
| 5 | `Registry.build` kwarg name (spec: "optional kwarg, default = none", unnamed) | Chose `mcp_servers:` — Hash `name → raw mcp.json-shaped config` (the `Mcp::Config.load` return shape). Wave-2 CLI passes `Mcp::Config.load`. |
| 6 | connect-failure semantics | pi degrades: server state `"failed"` (runtime.ts:57), session continues, error surfaced in UI. Port has no UI surface at build time → warn on `$stderr` (`raspberry-pi: mcp server "x" failed to connect: …`) and continue without that server's tools. Test-proven (`test_registry_skips_a_server_that_fails_to_connect`). |

### Parity-deviation table (itemized)

| # | pi behavior | Port behavior | Where |
|---|---|---|---|
| 1 | Exposure modes codemode/deferred/direct/hidden, default codemode (mcp-servers.ts:69-77) | `direct` only: MCP tools are declared to the model like any built-in; no codemode/deferred/hidden machinery | Mcp::Tool::EXPOSURE = "direct"; lib/raspberry_pi/mcp/tool.rb |
| 2 | streamable-http transport + OAuth | Out of scope per spec; url entries rejected (see disagreement 2) | lib/raspberry_pi/mcp/config.rb |
| 3 | Per-server `timeout` (seconds, default 60) | Not ported; 30 s client default | lib/raspberry_pi/mcp/client.rb |
| 4 | MCP result images/audio/resource blocks mapped to model-facing attachments / resource-link notes (tools.ts blockToContent) | Text blocks only (joined `\n`); non-text blocks dropped. resources/prompts out of scope per spec | lib/raspberry_pi/mcp/tool.rb#model_facing_text |
| 5 | 20KB middle-truncation, full text saved to a `pi-mcp` managed output dir (tools.ts limitMcpContent + writeOutputFile) | Ported: same 20KB + pi's exact warning/full-output text format, but the temp file lands in `Dir.tmpdir` (`raspberry-pi-mcp-<pid>-<n>.txt`), not pi's managed output dir (the port has no output-file manager) | lib/raspberry_pi/mcp/tool.rb |
| 6 | `createMcpToolName` hash suffix (tools.ts:94-104) | Ported 1:1 (sanitize, 64 cap, sha256 suffix) — no deviation | Mcp::Tool.tool_name |
| 7 | Server connect failure → state "failed", UI error, session continues | $stderr warning, session continues without the server's tools (no UI surface) | lib/raspberry_pi/mcp.rb#tools_for |
| 8 | `notifications/progress` handling (progress resets request timeout) | Notifications consumed and ignored (progress out of scope) | lib/raspberry_pi/mcp/client.rb#handle_message |

### Files (all in my touch set)

| File | Status |
|---|---|
| lib/raspberry_pi/mcp.rb | new — Mcp facade (`tools_for`/`server_tools`) |
| lib/raspberry_pi/mcp/jsonrpc.rb | new — error vocab + message validation (port of jsonrpc.ts) |
| lib/raspberry_pi/mcp/stdio.rb | new — stdio transport (port of transports/stdio.ts) |
| lib/raspberry_pi/mcp/client.rb | new — JSON-RPC client (port of client.ts) |
| lib/raspberry_pi/mcp/config.rb | new — mcp.json config load/validate (port of config.ts + validateMcpServerConfig) |
| lib/raspberry_pi/mcp/tool.rb | new — RubyLLM::Tool wrapper (port of extensions/mcp/tools.ts) |
| lib/raspberry_pi/tools/registry.rb | modified — `build` gains `mcp_servers: nil` kwarg (+ `require_relative "../mcp"`, +12/-2 lines) |
| test/mcp_test.rb | new — 18 tests |
| test/support/mcp_echo_server.rb | new — pure-Ruby fixture stdio MCP server (no gems; initialize/ping/tools/list/tools/call; failure-injection toggles) |

Untouched: `lib/raspberry_pi.rb`, `agent/loop.rb`, `bin/`, `README.md`, `test/test_helper.rb`, `test/golden_parity_test.rb`, `test/support/mock_llm_server.rb` (read-only, used for the AC4 agent round trip). No commits made (git log head unchanged at a8ec14e; working tree shows only my files).

### Gate results (verbatim)

```
# suite-green
... 169 dots
Finished in 16.331115s, 8.9400 runs/s, 32.4534 assertions/s.
146 runs, 530 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK   (baseline pre-lane: 128 runs, 434 assertions — +18 mcp tests)

# stderr-quiet
NO_WARN

# stderr-clean
NO_EPIPE

# mcp-guard (timeout 120 bundle exec ruby -Itest test/mcp_test.rb)
Finished in 1.544453s, 11.6546 runs/s, 62.1579 assertions/s.
18 runs, 96 assertions, 0 failures, 0 errors, 0 skips
MCP_OK

# tui-seam
SEAM_OK

# bench-seam (timeout 90 bundle exec ruby bench/seam_bench.rb)
SEAM_BENCH_OK

# gem-pins
PINS_OK
```

Not runnable in this worktree:

| Gate | Status |
|---|---|
| session-guard | NOT RUNNABLE: wave-1 deliverable (test/session_test.rb does not exist; I did not create it). test/agent_loop_test.rb itself is green inside suite-green and unmodified. |
| print-guard | NOT RUNNABLE: wave-1 deliverable (test/print_test.rb does not exist; I did not create it). |
| cli-help | NOT RUNNABLE: wave-2 deliverable. |

### AC evidence summary

| AC | Evidence |
|---|---|
| AC3 | test_client_initialize_list_and_call_round_trip (handshake fields asserted), test_close_reaps_the_child_process (`Errno::ECHILD` after close = reaped), test_request_timeout_raises_with_the_default_message ("MCP request timed out after 250ms"), test_jsonrpc_validation_matches_pis_predicates_and_codes, test_transport_passes_child_stderr_through — all over real pipes to test/support/mcp_echo_server.rb; no network, no keys, no new deps (gem-pins PINS_OK) |
| AC4 | test_registry_registers_mcp_tools_behind_the_schema_gate (wire names, description, server inputSchema through `parameters_schema`, execute round trip, no approval gate), test_registry_without_mcp_servers_never_connects_anything, test_config_error_strings_match_pi (7 exact strings), test_missing_config_file_means_no_servers_no_error, test_agent_round_trip_model_calls_mcp_tool_result_returns_to_the_model (MockLLMServer scripts `mcp__echo__echo`; tool message in the captured payload contains "echo: ping"), test_registry_skips_a_server_that_fails_to_connect; direct-only exposure itemized above |

STATUS: COMPLETE_WITH_CONCERNS (concerns: disagreement/parity items 1-8 above — all spec-sanctioned stdio-scope simplifications plus the invented url-rejection error string and the $stderr connect-failure surface; `mcp_servers:` kwarg name was architect-unnamed and is a wave-2 CLI seam)

### print

### PHASE 0 findings (spec-vs-reality, file:line evidence)

| # | Verify item | Spec claim | Reality (evidence) | Verdict |
|---|---|---|---|---|
| 1 | pi print-mode options | PrintModeOptions :30-39 (mode text/json, messages, initialMessage) | Confirmed: `repos/pi/packages/coding-agent/src/modes/print-mode.ts:30-39`; interface comment :10-11 ("text = final response only") | matches |
| 2 | pi text-mode tail | final response only; error/aborted → stderr + exit 1 | Confirmed: print-mode.ts:143-158 — last of `state.messages`; `stopReason === "error" \|\| "aborted"` → `console.error(errorMessage \|\| ...)` + `exitCode = 1` (:145-147); else each `content.type === "text"` → `writeRawStdout(`${content.text}\n`)` (:149-152); non-assistant last message → nothing, exit 0 | matches |
| 3 | pi print exit codes | 0 success, non-zero on error | Confirmed: `exitCode = 1` on error/aborted (:147); catch-all → stderr + `return 1` (:160-162); main.ts:986-993 sets `process.exitCode` from the return value | matches |
| 4 | pi print signal handlers | SIGTERM/SIGHUP | Confirmed: print-mode.ts:51-66 — SIGTERM → exit 143, SIGHUP → 129 (non-win32). NOT ported into the library: a Ruby library must not install global `Signal.trap`s (process concern of the future cli wiring); itemized in parity table | itemized simplification |
| 5 | raw stdout | writeRawStdout/flushRawStdout, no buffering, no TUI | Confirmed: `core/output-guard.ts:85` writeRawStdout (unbuffered raw write, serial tail-promise), flushRawStdout :103. Port: `$stdout.sync = true` + direct `IO#write` | matches |
| 6 | **pi -p approval disposition** | verify and port exactly | **pi has NO tool-approval mechanism at all.** `grep -rn approval packages/*/src` matches only `extensions/llama/index.ts` (HuggingFace access terms, unrelated). `agent-loop.ts:826-860 executePreparedToolCall` → `prepared.tool.execute(...)` unconditionally; no gate, no prompt. So `pi -p` executes gated tools without asking. Port: `Print.run` passes `approval: ->(_) { true }` (auto-approve) — pi's exact behavior. See parity table | ported exactly, itemized |
| 7 | ruby_llm history accumulation/replay | chat.messages after turns; seeding a new chat | Confirmed: ruby_llm-2.1.0 `chat.rb:43 attr_reader :messages` (accumulates every turn incl. tool results); `chat.rb:1015 messages=` replaces history coercing each element into Message; `chat.rb:1034 add_message` appends. (Session lane's resume path builds on `messages=`; print lane only consumes the final message) | matches |
| 8 | ruby_llm Tool contract | name/description/schema/execute | Confirmed: `tool.rb:259 name` (class-name demodulized/underscored), `:264 description`, `:313 call` → `:340 execute`, params from keyword signature (:349). Port's `Tools::*` already satisfy it; print registers the existing loadout unchanged | matches |
| 9 | tool result/exception surfacing into history | what the recorder/model sees | Confirmed in-port: `Agent::Loop` `:tool_message` item → tool result message reaches `chat.messages` and the next request payload (agent_loop_test.rb:45-50 pattern; print test asserts the tool result message in the captured 2nd request) | matches |
| 10 | port Agent::Loop kernel constraint | Loop.run must run on Core::Loop work block | Confirmed: `lib/raspberry_pi/agent/loop.rb` doc ("Must be called on the kernel reactor fiber") + Bridge requires the async reactor. Print runs `Core::Loop.new(session: Print::NullSession)` — a null terminal session (poll blocks one frame, never yields events, never draws); no TUI required, no terminal opened | sound |
| 11 | mock server capabilities | can script what print tests need | Confirmed: `test/support/mock_llm_server.rb` scripts `{type: :stream, tool_calls:}`, `{type: :message}`, `{type: :error, status:, message:}` (:84-91, respond_error :122-127) — exactly the print test's needs. Read-only; untouched | sound |
| 12 | TUI-seam gate scope | print.rb must carry no RatatuiRuby | print.rb requires only `agent/loop` + `core/loop`; `core/loop.rb` references `TUI.ctrl_c?` but never `RatatuiRuby.`; gate grep stays clean (verified below) | sound |

Disagreements with the spec: **none.** Checked before concluding sound: pi's print-mode.ts (full file), output-guard.ts, agent-loop.ts tool-execution path, the approval grep across all pi packages, ruby_llm-2.1.0 chat.rb/tool.rb/message.rb gem source, the port's Agent::Loop/Core::Loop/Poller/TestChat/mock-server sources. The one genuinely surprising finding (item 6 — pi has no approval gate to disposition) is ported exactly and itemized below rather than silently "improved".

### PHASE 1 note (frozen contracts)

No shared contract touched. `lib/raspberry_pi.rb` changed by exactly one added line (`require_relative "raspberry_pi/print"`), per the lane grant. All existing call sites/tests unmodified (132 runs / 453 assertions green).

### Files (this lane's complete touch set)

| File | Status |
|---|---|
| `lib/raspberry_pi/print.rb` | new (Print module: run/error_exit/final_response/text_parts + NullSession) |
| `lib/raspberry_pi.rb` | +1 line registration only |
| `test/print_test.rb` | new (4 tests, public behavior, hermetic) |

### Gate results (verbatim output)

**print-guard** — PASS
```
Run options: --seed 14108

# Running:

....

Finished in 0.186475s, 21.4506 runs/s, 101.8906 assertions/s.

4 runs, 19 assertions, 0 failures, 0 errors, 0 skips
PRINT_OK
```

**suite-green** — PASS
```
Run options: --seed 44497

# Running:

....................................................................................................................................

Finished in 15.134746s, 8.7217 runs/s, 29.9311 assertions/s.

132 runs, 453 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

**stderr-quiet** — PASS
```
NO_WARN
```

**stderr-clean** — PASS
```
NO_EPIPE
```

**tui-seam** — PASS
```
SEAM_OK
```

**bench-seam** — PASS (exit 0, full JSON recorded; verdict lines)
```
"timeout_kill": { "verdict": "clean", "kill_calls": 1, "termsig": 15, "zombie_gone": true, "seconds_to_reap": 0.0014 },
"sse_delivered": 500, "sse_expected": 500, "timer_ticks": 100, "timer_expected": 100,
"fps_while_animating": { "mean": 60.0 }, "cpu_pct": 4.2
SEAM_BENCH_OK
```

**gem-pins** — PASS
```
PINS_OK
```

**session-guard** — NOT RUNNABLE: wave-1 deliverable (`test/session_test.rb` does not exist yet; session lane's file)
**mcp-guard** — NOT RUNNABLE: wave-1 deliverable (`test/mcp_test.rb` does not exist yet; mcp lane's file)
**cli-help** — NOT RUNNABLE: wave-2 deliverable (`-p/--print` flag is wired by the cli lane)

### Parity-deviation table

| pi behavior | Port | Classification |
|---|---|---|
| No tool-approval mechanism exists; `pi -p` executes every tool unconditionally (agent-loop.ts:826-860) | `Print.run` passes `approval: ->(_) { true }` — gated tools (bash/edit/write) execute without any approval prompt | exact port of pi's behavior, itemized per lane note. Note for the architect: this mirrors pi, but it means a print run with `bash` selected executes destructive tools with no gate — pi's own tradeoff, kept deliberately, not silently |
| `--mode json` event stream (print-mode.ts:30-39) | out of scope per spec | itemized exclusion |
| `messages` array (additional prompts after initialMessage), initialImages/@file mentions | out of scope per spec (single-shot, one prompt) | itemized exclusion |
| SIGTERM→143 / SIGHUP→129 handlers (print-mode.ts:51-66) | not ported: global `Signal.trap`s are a process concern; the run is synchronous and the future cli wiring owns process lifecycle | itemized simplification |
| writeRawStdout's raw-fd takeover + ENOBUFS/EAGAIN retry loop + tail-promise queue (output-guard.ts:38-103) | `$stdout.sync = true` + direct `IO#write` on an injectable stream | itemized simplification (no stdout takeover exists in the Ruby port; no TUI to guard against) |
| pi's text-mode "non-assistant last message prints nothing" | ported verbatim (`final&.role == :assistant`) | match |
| error/aborted → stderr message, exit 1 | `last_error` → `error.message`; `interrupted?` → `"Request aborted"`; exit 1 | match (aborted path unexercisable in tests without signal wiring; branch mirrors pi's `Request ${stopReason}` fallback) |

### STATUS: COMPLETE_WITH_CONCERNS
- Concern 1 (parity note, not a defect): print mode auto-approves approval-gated tools because pi has no approval mechanism and the lane note required porting pi exactly (finding 6 / parity row 1). If the architect judges the port's I0x safety gating should outrank pi's behavior in print mode, the change is one line (`approval: nil` = deny) — flagging for arbitration rather than deciding silently.

### cli

### PHASE 0 findings (spec-vs-reality, verified this run)

| Verify item | Reality | Evidence |
|---|---|---|
| pi `--print`/`-p` flag shape | Boolean flag; the next non-flag argument (not starting with `-`, unless `---`) is popped into `result.messages` | repos/pi/packages/coding-agent/src/cli/args.ts:177–184 |
| pi `--resume`/`-r` flag shape | Boolean only (`result.resume = true`); main.ts then opens `selectSession` picker UI; no value | args.ts:113–114; main.ts:415–430 |
| pi `-p` with no message / piped stdin | pi reads piped stdin as prompt content (`readPipedStdin`) and dispatches print mode when stdin/stdout is not a tty | main.ts:112–119, 893–897 |
| pi print mode records sessions | Yes — `createSessionManager` returns in-memory only for `--no-session`/`--help`/`--list-models` (main.ts:362); print mode drives `runtimeHost.session.prompt` (print-mode.ts:132–136). Port's `Print.run` exposes no recorder → print runs unrecorded (spec-scoped-out deviation, itemized below) | main.ts:362; print-mode.ts:36,132–136 |
| pi print-mode approval disposition | `executePreparedToolCall` executes tools unconditionally — no approval gate in the agent loop | repos/pi/packages/agent/src/agent-loop.ts:822–840 |
| pi print exit codes | 0 on success; 1 when the last assistant message stopReason is error/aborted (message to stderr) or an exception escapes | print-mode.ts:143–162 |
| pi MCP config path | `<agentDir>/mcp.json` only (`path.join(getAgentDir(), "mcp.json")`); **no env override** | src/modes/interactive/interactive-mode.ts:6378 |
| pi MCP validation strings | Exact strings match the port's `Mcp::Config` (args/env/cwd/command-or-url) | src/core/mcp-servers.ts:292–304 |
| ruby_llm chat seeding | `Chat#add_message(message_or_attributes)` appends verbatim; `Agent::Loop#initialize` seeds after `with_instructions`, so the model sees system → prior turns on the wire | ruby_llm-2.1.0 lib/ruby_llm/chat.rb:1034–1038, 441–447 |
| Port APIs used | `Agent::Session.dir_path/find_most_recent/context_messages/read_header`, `Recorder.new(cwd:, root:, parent_session:)`, `Agent::Loop` `recorder:`/`seed_messages:`, `Registry.build(mcp_servers:)`, `Print.run` → exit code | all read in this worktree |
| Baseline before change | 157 runs, 599 assertions, 0 failures; `ruby bin/raspberry-pi --help` headless OK | this run |

### Disagreements raised in PHASE 0 (none blocking)

1. `-p/--print PROMPT` takes a required value (spec-mandated) vs pi's boolean-with-popped-next-arg; pi also reads piped stdin (not ported — out of scope). Itemized below.
2. `--resume` + `-p` combined → abort with a clear message (port addition). `Print.run` accepts no `seed_messages:`/`recorder:`, so a resumed print run could not actually seed; silently ignoring `--resume` would be worse.
3. `--resume` with no sessions found → abort exit 1 with stderr message (pi's picker exits 0 with "No session selected"). Headless launcher: silently starting a fresh session on a typo'd `--resume` is the worse failure.
4. Session-id resolution scope: exact file path, or session id within the workdir's session dir only (filename `_<id>.jsonl` suffix or header id). pi's `resolveSessionPath` also searches global history — out of port scope.

### Gate outputs (verbatim, final run)

```
=== suite-green ===
Finished in 16.556135s, 9.4829 runs/s, 36.1799 assertions/s.

157 runs, 599 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
=== stderr-quiet ===
NO_WARN
=== stderr-clean ===
NO_EPIPE
=== session-guard ===
7 runs, 50 assertions, 0 failures, 0 errors, 0 skips
SESSION_OK
=== mcp-guard ===
18 runs, 96 assertions, 0 failures, 0 errors, 0 skips
MCP_OK
=== print-guard ===
4 runs, 19 assertions, 0 failures, 0 errors, 0 skips
PRINT_OK
=== tui-seam ===
SEAM_OK
=== bench-seam ===
SEAM_BENCH_OK
=== gem-pins ===
PINS_OK
=== cli-help ===
CLI_OK
```

cli-help cmd verbatim: `out=$(timeout 30 ruby bin/raspberry-pi --help) && echo "$out" | grep -q -- '--print' && echo "$out" | grep -q -- '--resume' && echo "$out" | grep -qi 'mcp' && echo CLI_OK` → `CLI_OK`, exit 0.

### Judgment calls (raw behavior, this run)

| Behavior | Result |
|---|---|
| `ruby bin/raspberry-pi --resume` (no sessions for workdir, dummy key, fake `$HOME`) | `raspberry-pi: no session found for /private/tmp/rp-smoke-empty`, exit 1 |
| `ruby bin/raspberry-pi -r` (same) | same abort, exit 1 |
| `ruby bin/raspberry-pi --resume abc -p "hi"` | `raspberry-pi: --resume is interactive-only (--print runs single-shot).`, exit 1 |
| invalid `mcp.json` (`{"mcpServers":{"x":{"args":[1]}}}`, `RASPBERRY_PI_MCP_CONFIG`) | `raspberry-pi: /tmp/rp-bad-mcp.json: server "x": args must be an array of strings`, exit 1 (pi's exact error string, aborted before any TUI/LLM traffic) |
| `ruby bin/raspberry-pi -p` (missing value) | `raspberry-pi: missing argument: -p (see --help).`, exit 1 |
| `ruby bin/raspberry-pi --bogus` | `raspberry-pi: invalid option: --bogus (see --help).`, exit 1 |
| `ruby bin/raspberry-pi --help` (headless, no tty) | prints usage, exit 0, no terminal/env interaction |
| `bin/raspberry-pi -p "say the thing"` against local MockLLMServer (hermetic) | exit 0; stdout `"printed answer\n"` (final response only); stderr `""`; 1 request captured by the mock |
| interactive `--resume` wiring, TUI.run stubbed, fake `$HOME`, no tty | recorder header `parentSession` = the old session file's path; recorder dir `<fakehome>/.raspberry-pi/sessions/--private-tmp-rp-smoke-empty--`; seeded chat messages = `[:system, "You are a coding assistant..."], [:user, "hello earlier"]` |
| interactive run headless WITHOUT stub (real path) | TUI init fails at `ratatui_ruby` terminal init (`Device not configured`, exit 1) — expected: pre-TUI wiring (resume resolution, recorder, seed) had already succeeded; the TUI itself requires a real terminal by design |

### Parity deviations (itemized; none silent)

| # | Deviation | pi evidence | Reason |
|---|---|---|---|
| 1 | Port `-p/--print PROMPT` requires the value; no piped-stdin prompt | args.ts:177–184 (boolean + next-non-flag pop); main.ts:893–897 (piped stdin) | Spec-mandated shape (`-p/--print PROMPT`); stdin piping out of scope |
| 2 | Port `--resume [ID]`: optional value, default most-recent-for-workdir; no picker UI | args.ts:113–114 (boolean); main.ts:415–430 (`selectSession` UI) | Spec-mandated; the port has no session-picker UI |
| 3 | `RASPBERRY_PI_MCP_CONFIG` env override for the mcp.json path | pi: none — `<agentDir>/mcp.json` only (interactive-mode.ts:6378) | Spec-mandated port addition, named in the existing `RASPBERRY_PI_*` vocabulary |
| 4 | Print runs are not session-recorded | pi records print-mode sessions by default (main.ts:362 + print-mode.ts:36,132–136) | Spec-scoped out: `Print.run` exposes no recorder; did not touch print.rb |
| 5 | `--resume` rejected when combined with `-p` | pi permits print with a resumed session (session manager is created before mode dispatch, main.ts:653+) | Port's `Print.run` has no seed/recorder surface; aborting is honest |
| 6 | `--resume` with no matching session aborts exit 1 | pi's picker prints "No session selected" and exits 0 (main.ts:428–429) | No picker; silently launching a fresh session on a failed resume is the worse failure |
| 7 | Resume-id resolution: exact session-file path or session id within the workdir's session dir (filename `_<id>.jsonl` suffix or header id) | pi `resolveSessionPath` also resolves global-history names (main.ts:386+) | Port scope: workdir-scoped sessions only |
| 8 | Invalid mcp.json aborts the launcher (exit 1, pi's exact error strings) | pi surfaces validation errors at startup and exits | Headless launcher must fail before any TUI/LLM traffic |

### Files

| File | Change |
|---|---|
| bin/raspberry-pi | `-p/--print PROMPT`, `-r/--resume [ID]`, `-h/--help`; default-on interactive session recording (`Agent::Session::Recorder`, `parent_session:` on resume, `Agent::Session.context_messages` → `seed_messages:`); MCP config via `RASPBERRY_PI_MCP_CONFIG` (default `Mcp::Config::DEFAULT_PATH`) → `Tools::Registry.build(mcp_servers:)`; shared chat/tools/system-prompt builders for both paths; parse-error abort; expanded headless-safe usage |
| README.md | Usage section: flags table rows (`RASPBERRY_PI_MCP_CONFIG`), new "Sessions", "MCP servers", "Print mode" subsections; Development adds a `-p` example line |

No commits made; no git write commands run; no files outside the touch set modified (`git status` = `M README.md`, `M bin/raspberry-pi` only). `~/.raspberry-pi` never touched (all session/fixture writes used fake `$HOME` or tmp dirs). Two accidental hermetic-discipline notes: two early `-p` smoke checks with a dummy key against the real default endpoint returned 401 before I routed verification to the MockLLMServer — no valid key was ever involved, no further real traffic after that.

STATUS: COMPLETE

## Verdict

Judged in a fresh session (this session did not dispatch; wave-1 judged 2026-10-10 ~20:35, wave-2 dispatched by that session). Post-flight clean: all four lanes — frozen region untouched vs freeze 66fb0291 (diff begins at Builder Prompt append only), no builder commits off the lane bases, scratch reports present and raw-evidence-only, worktrees in-bounds (cli: `M README.md`, `M bin/raspberry-pi` exactly). Evidence transcribed (71126b6f session / db3e5286 mcp / cbd3c288 print / 7cb9ef17 cli). Integrated: session → mcp → print → cli, merged `--no-ff` to `project/pi-port` at **593e881d** (wave-1: a8ec14e8 → 114354d), teardown done.

**Gates cold at 593e881d: 10/10 PASS** — suite-green (157 runs, 599 assertions, 0 failures), stderr-quiet, stderr-clean, session-guard, mcp-guard (18/96), print-guard (4/19), tui-seam, bench-seam (SEAM_BENCH_OK), gem-pins, **cli-help GREEN** (the wave-2 seam, RED by construction at wave 1).

### Per-AC rulings

| AC | Ruling | Evidence |
|----|--------|----------|
| AC1 session recording | **PASS** | session_test.rb parses recorded JSONL back, asserts the recorded sequence matches the conversation; header/entry format matches pi session-manager.ts :43-68, :1197-1208 (architect-read from the findings table); recorder optional (`nil` = off), agent_loop_test.rb untouched and green in suite |
| AC2 resume | **PASS** | MockLLMServer captured request payload contains prior turns (test-proven); most-recent-for-cwd selection test-proven; new file links old via `parentSession`; null-content tolerance ported with the `""`-vs-`[]` deviation itemized (ruled below) |
| AC3 MCP client | **PASS** | initialize/tools-list/tools/call round trip over real stdio pipes vs the pure-Ruby fixture echo server; 30 s default timeout test-proven; pi's JSON-RPC codes/strings; child reaped (`Errno::ECHILD` asserted); hermetic; gem-pins green (no new deps) |
| AC4 MCP integration | **PASS** | `mcp__<server>__<tool>` naming incl. the sha256 hash-suffix tail (ported 1:1); schema-gate registration; agent-level round trip — MockLLMServer scripts the mcp tool call, fixture server answers over stdio, result returns to the model; pi's exact validation strings (7) test-proven; unconfigured server never connects (test-proven); direct-only exposure itemized |
| AC5 print | **PASS** | final-response-only to raw stdout unbuffered (`$stdout.sync = true`); pi's exit codes (0/1, error→stderr); approval disposition ruled below; no TUI anywhere (Print::NullSession; tests run with no terminal) |
| AC6 CLI wiring (wave-2 seam) | **PASS** | `bin/raspberry-pi` wires `-p/--print PROMPT`, `-r/--resume [ID]` (default most-recent-for-workdir), default-on interactive recording (`Recorder` + `parent_session:` + `context_messages` → `seed_messages:`), `RASPBERRY_PI_MCP_CONFIG` → `Registry.build(mcp_servers:)`; cli-help GREEN cold; README usage expanded (sessions/MCP/print sections — architect-read); diff well-factored (`parse`/`run` split, shared `build_chat`/`build_tools`/`system_prompt`, house `abort` idiom) |
| AC7 PHASE 0 + parity discipline | **PASS** | all four lanes: findings tables with gem/oracle file:line evidence, deviations itemized (session 4 / mcp 8 / print 6 / cli 8) — none silent; all regression gates stay green with everything in place |

### Disagreement & deviation rulings (all queued items, no deferrals)

1. **Print approval disposition (print lane concern — arbitration requested).** Builder verified pi has **no tool-approval mechanism at all** (`grep -rn approval` across pi packages → only an unrelated llama access-terms hit; `executePreparedToolCall` runs unconditionally, agent-loop.ts:826-860). Port `Print.run` passes `approval: ->(_) { true }` — pi's exact behavior. **ACCEPT (pi parity).** BRIEF §5's oracle discipline applies: the port stays pi-faithful; pi's own tradeoff kept deliberately, not silently. Flag for the human: headless `-p` runs execute `bash`/`edit`/`write` ungated — if you want deny-by-default headless, it's a one-line flip (`approval: nil` = deny) and belongs in a post-parity iteration, not smuggled in here.
2. **session-guard gate INVALID-as-written.** Verified this session: `bundle exec ruby -Itest test/session_test.rb test/agent_loop_test.rb` → 7 runs/50 assertions = session_test.rb only; the second path becomes ARGV (Ruby does not chain-load scripts; agent_loop_test.rb's 8 tests never load). The instrument measured session_test, not "both files." Coverage **intent** is proven by suite-green (157 runs include both). **INVALID (mechanism), substance sound.** Corrected gate shape carries into the next iteration's freeze: `bundle exec ruby -Itest -e 'require "./test/session_test.rb"; require "./test/agent_loop_test.rb"' && echo SESSION_OK`.
3. **mcp invented url-rejection error string.** Spec named command/args/env/cwd only; pi accepts `url` (streamable-http), port is stdio-only and rejects with a port-invented string. **ACCEPT** — the string names the actual port constraint, is itemized (mcp deviation 2), and the 7 pi-exact strings that AC4 requires are test-proven. Stdio-only is the spec's own scope.
4. **mcp $stderr connect-failure surface.** pi degrades: state `"failed"`, session continues, error surfaced in UI. Port has no UI at build time → warns on `$stderr`, continues without that server's tools, test-proven. **ACCEPT** — correct headless analog of pi's degradation.
5. **`mcp_servers:` Registry.build kwarg name.** Architect-unnamed at spec time; mcp lane chose `mcp_servers:` (the `Mcp::Config.load` return shape's own vocabulary); cli lane consumes it as specced (verified in the integrated diff). **ACCEPT.**
6. **Session null-content `""` vs `[]`.** pi maps user/assistant/toolResult null content → `[]` (content-block array); port maps → `""` because ruby_llm `Message#normalize_content` raises `ArgumentError` on non-String/non-nil (gem message.rb:120-128) — `[]` cannot be seeded. System role matches pi exactly. **ACCEPT (MODIFY-class deviation, defensible on ecosystem grounds per BRIEF §5.1).**
7. **Print SIGTERM→143 / SIGHUP→129.** Not wired as `Signal.trap`s (print lane itemized it as a process concern; cli lane relies on Ruby's default disposition — an untrapped fatal signal kills the process and the parent observes 128+sig, i.e. 143/129, the same observable pi produces by setting `process.exitCode` explicitly for Node's plumbing). Foundation-mechanics carve-out (BRIEF §5.1). **ACCEPT** — observable exit-status parity holds without the trap; the print-lane itemization stands for the library, the cli-lane table not re-listing it is noted, not penalized.
8. **Print runs unrecorded** (cli deviation 4). pi records print-mode sessions by default; the port's `Print.run` exposes no recorder and the spec scoped recording to interactive runs. **ACCEPT** — itemized, spec-scoped. Backlog candidate for post-§7.1 polish: record print sessions the way pi does.
9. **`--resume`+`-p` abort, `--resume` no-match abort exit 1, workdir-scoped resume-id resolution, `-p` requires a value** (cli deviations 1-2, 5-7). **ACCEPT all** — spec-mandated shapes; the aborts are the honest headless behavior (silently starting fresh on a typo'd resume, or silently ignoring `--resume`, are the worse failures).
10. **Hermetic-discipline note (cli):** two early `-p` smoke checks hit the real fireworks endpoint with a dummy key (401) before the builder routed verification to MockLLMServer — no valid key involved, no further real traffic. Noted; not a defect of the deliverable.

### Verdict

**CONTINUE.** All 7 AC PASS; 10/10 gates PASS cold on the integrated tree 593e881d; every deviation raised and ruled, none silent; the single instrument defect (session-guard's ARGV quirk) is a gate-authoring lesson carried to the next freeze, not a code defect. I07 delivers BRIEF §7.1 (resumable JSONL sessions — the last interactive-TUI gap), §7.3 (MCP), and §7.4 (print mode). Remaining toward §7 DoD: §7.2 approval polish nuance (print-mode auto-approve is pi-parity, ruled #1), §7.6 compaction, §7.7 end-to-end session on this space (now runnable via `-p`/`--resume`).
