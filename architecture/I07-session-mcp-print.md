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

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I07-session-mcp-print-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence session-mcp-print --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section session-mcp-print verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify session-mcp-print`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
