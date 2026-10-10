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
`architect rehearse session-mcp-print` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze session-mcp-print` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse session-mcp-print` — before the freeze, while
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
subsection per lane. A copy is written to build/I07-session-mcp-print-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section session-mcp-print prompt --append --lane <lane> --from build/I07-session-mcp-print-<lane>/prompt.md`. -->

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
