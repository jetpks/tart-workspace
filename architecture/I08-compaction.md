# I08: compaction

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds

Inline research done at spec time (no external dependencies — the oracle repo + the pinned gem answer everything; no research fan-out triggered).

**What pi ships** (`repos/pi/packages/coding-agent/src/core/compaction/compaction.ts`, 1119 lines; `utils.ts`, 163 lines):

- **Pure functions, no I/O** (file header :1-6): token estimation, cut-point selection, prompt construction, preparation. Session manager handles I/O; after compaction the session is reloaded from entries.
- **Settings** (:120-135): `CompactionSettings {enabled, reserveTokens: 16384, keepRecentTokens: 20000}`, defaults `enabled: true`. pi loads per-model overrides from settings.jsonl; the port has no settings system — kwargs/env seam instead (BRIEF §6: grow on demand).
- **Token accounting** (:140-231): `calculateContextTokens(usage) = totalTokens || input+output+cacheRead+cacheWrite`; last-assistant usage is authoritative, skipping aborted/error/all-zero assistant messages; trailing messages after the last usage estimated at chars/4 (`estimateTokens` :298-355 — text/thinking/toolCall name+args per block, images ≈4800 chars, ceil(chars/4)).
- **Threshold** (:267-272): `shouldCompact(contextTokens, contextWindow, settings) = enabled && contextTokens > contextWindow - reserveTokens`; `contextWindow <= 0` disables the threshold check (agent-session.ts:768-771).
- **Cut point** (:412-522): walk backwards over entries accumulating estimated tokens until `>= keepRecentTokens`; cut at user/assistant-role entries, **never at tool results** (a tool result must follow its tool call); never at compaction entries; adjacent metadata entries absorb backwards; split-turn detection (`isSplitTurn` + the turn-start user message).
- **Summarization** (:535-771 + utils.ts :114-163): `SUMMARIZATION_SYSTEM_PROMPT` (utils.ts :161-163), structured `SUMMARIZATION_PROMPT`, `UPDATE_SUMMARIZATION_PROMPT` (merge into previous summary), `TURN_PREFIX_SUMMARIZATION_PROMPT` (split turns); conversation serialized to `[User]:/[Assistant thinking]:/[Assistant]:/[Assistant tool calls]:/[Tool result]:` lines with tool results truncated (`serializeConversation`, utils.ts :114-153); summary `maxTokens = min(0.8 * reserveTokens, model.maxTokens)` (turn prefix 0.5×); failure checks: error/length stopReason → throw, toolCall in the response → throw.
- **File-op tracking** (utils.ts :30-113): extract read/modified files from tool calls + previous compaction details; appended to the summary via `formatFileOperations`.
- **Triggers** (`agent-session.ts`): (a) **overflow** — context-length error on the assistant response → the overflowing attempt is omitted, compaction runs, the turn retries once (:3007-3047); (b) **threshold** — post-turn check from provider-reported usage (fallback chars/4 estimate for error/zero-usage responses) → compaction, no retry (:3050-3088).

**Session format** (`session-manager.ts`): `CompactionEntry {type: "compaction", id, parentId, timestamp, summary, firstKeptEntryId, tokensBefore, details {readFiles, modifiedFiles}, usage?}` (:91-104, appended :1260-1285). **Replay is compaction-aware** (`buildContextEntries` :475-513): the context = the latest compaction entry (projected as a `compactionSummary` message, `messages.ts:109-121`) + entries from `firstKeptEntryId` onward + everything after the compaction entry; pre-compaction summarized entries are omitted; system messages in the kept range are skipped. `estimateProjectedContextTokens` (:227-261) distrusts usage captured before a later compaction — re-estimates from message sizes.

**What the port already has:** `Agent::Loop` (chat/tools/recorder/seed_messages kwargs, `:tool_message` items, error path), `Agent::Session` (header + message entries only — I07 scope; `context_messages`, `find_most_recent`, tolerant parse skipping unknown entry types), MockLLMServer (scripts stream/tool_calls/message/error responses, captures request payloads), 157 runs / 599 assertions green at `project/pi-port` tip 593e881d.

**ruby_llm 2.1.0 surfaces (gem source, verified this session):** `Message#tokens` → `Tokens` with `input/output/cache_read/cache_write/...` (message.rb :99-110) — provider-reported usage on each assistant message; `ContextLengthExceededError` raised by transport error middleware on context-length 4xx (error_middleware.rb :125-158); `Chat#model` → `RubyLLM::Model#context_window` (model.rb :33, :82) — but `assume_model_exists: true` falls back to `Model.default` with **no context_window** (models.rb :686-715, model.rb :65-74), so the port's default fireworks chat resolves `context_window` to nil unless the registry finds the model — an explicit context-window source is required for the threshold trigger. Overflow needs no window: the error is authoritative.

## Specification

# Specification

## Objective

Port pi's context compaction (BRIEF §7.6 — "compaction triggers and recovers correctly on long sessions"; design sketch BRIEF §4 "Compaction"). A long session's context grows until it threatens the context window; pi compacts by summarizing the old turns with an LLM call, cutting the history at a safe boundary, and continuing with `[summary, kept recent tail]`. The port wires this into `Agent::Loop` so interactive, print, and resumed sessions all survive long runs: a **threshold** trigger after each completed turn (provider-reported usage vs the model's context window) and an **overflow** trigger (`RubyLLM::ContextLengthExceededError` → omit the overflowing attempt, compact, retry the turn once). Compaction is recorded as a session entry and **resume after compaction** rebuilds the compacted context (BRIEF §7.1 session format grows by the compaction entry type — pi `session-manager.ts:91-104`).

pi's design is pure functions + thin wiring (`compaction.ts` header :1-6: "Pure functions for compaction logic"); keep that split — the port's compaction module must be testable with no LLM at all except the one-call summarization seam.

## Output format

Raw tables/JSON only in the report (absolute path `build/I08-compaction-core/report.md`): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the context-window resolution; the summary-message role mapping; the overflow retry boundary; how the summarization one-shot call is routed hermetically), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

**Verification (exact, from ARCHITECT.md):**

```
cd ~/architect/spaces/20261009-pi-port/repos/raspberry-pi
bundle install --quiet && bundle exec rake        # suite (test/**/*_test.rb)
```

**Verify against the live oracle + gem before writing code (PHASE 0 — every item needs file:line evidence):**

1. **pi's exact prompt strings** — transcribe verbatim into the port, byte-identical: `SUMMARIZATION_SYSTEM_PROMPT` (`utils.ts:161-163`), `SUMMARIZATION_PROMPT` and `UPDATE_SUMMARIZATION_PROMPT` (`compaction.ts:537-583`), `TURN_PREFIX_SUMMARIZATION_PROMPT` (`compaction.ts:985-993`). `SUMMARIZATION_PROMPT`'s full body runs :537-560 — copy the whole template.
2. **pi's file-op format** — `formatFileOperations` (`utils.ts:77-112`) exact output shape (headers/section text) and `computeFileLists` (:67-75); `extractFileOpsFromMessage` (:30-65) — which tool names produce reads vs edits (read/write/edit/bash shapes; verify against the port's actual tool result messages, which are ruby_llm `role: :tool` messages — the mapping from the port's tool calls is a judgment call to report, not assume).
3. **pi's `serializeConversation` + `truncateForSummary`** — `utils.ts:100-153`; note `TOOL_RESULT_MAX_CHARS` (find its value) and the exact `[User]:`/`[Assistant thinking]:`/`[Assistant]:`/`[Assistant tool calls]:`/`[Tool result]:` prefixes; map each to the port's ruby_llm message shapes (content strings, `tool_calls` with arguments, thinking replay) and itemize any that cannot apply.
4. **ruby_llm usage surface** — `Message#tokens` → `Tokens` (gem `message.rb:99-110`): confirm `input/output/cache_read/cache_write` accessors (gem `tokens.rb`) and that `Chat#step` results carry them; write `calculate_context_tokens` as pi's `totalTokens || input+output+cache_read+cache_write` against the gem's actual accessor set (report the exact formula used).
5. **ruby_llm context-window surface** — `Chat#model.context_window` (gem `model.rb:33,82`); confirm what the port's default chat (`assume_model_exists: true`, fireworks) resolves it to in this repo (nil unless the registry carries the model — `models.rb:686-715`). Decide + report the resolution order: `RASPBERRY_PI_CONTEXT_WINDOW` env override → `chat.model.context_window` → nil (nil/<= 0 disables the threshold trigger only; overflow still fires).
6. **ruby_llm one-shot summarization call** — how to make a standalone completion (fresh `RubyLLM.context`+`chat` or `context.chat` reuse) with a system prompt + single user message, `max_tokens` support, and **route it hermetically in tests through MockLLMServer** (a second scripted response on the same mock, or a separate mock instance — report which). Confirm the gem's retry surface (context `max_retries`) applies; itemize the deviation if pi's dedicated `retryAssistantCall` (:619-644) has no gem equivalent worth adding.
7. **ruby_llm overflow error** — `ContextLengthExceededError` (gem `transport/error_middleware.rb:125-158`): confirm what the mock must return to trigger it (status/body shape — read `context_length_exceeded?` in the same file) and how it surfaces through `Chat#step`/`Chat#run_tools` in the port's loop. Confirm the overflowing assistant message is NOT added to `chat.messages` when the step raises (or is removed) — pi omits the attempt (agent-session.ts :3007-3047); report the actual port mechanics.
8. **pi's overflow retry-once boundary** — agent-session.ts `_runAutoCompaction("overflow", willRetry)` (:3044-3047) + the `_overflowRecoveryAttempted` latch (:3040): verify a second consecutive overflow after compaction does NOT retry again (surfaces as the error). Port the latch.
9. **Port message shapes for estimation** — the port's messages are ruby_llm `Message`/attribute hashes (roles `:system/:user/:assistant/:tool`): map pi's per-role `estimateTokens` (`compaction.ts:298-355`) onto them (assistant: text + thinking + tool_calls name/JSON(args); tool: content; system/user: content). Itemize unrepresentable roles (pi's bashExecution/custom/branchSummary/compactionSummary are pi-internal; the port's live context holds none — say so).
10. **Cut-point safety in a flat message list** — pi cuts over session *entries* with "never at tool results" (:356-470); the port's live context is a flat `chat.messages` array. Verify the flat-list equivalent: a cut index may land on a user message or an assistant message, but must never orphan `role: :tool` messages from their preceding assistant tool-call message (they follow it in the array). Verify with a test where the budget boundary falls mid-turn.
11. **Session parse tolerance** — the port's `Agent::Session` parse skips unknown/malformed entry lines (I07); confirm adding the `compaction` entry type does not break existing session files, and that `context_messages` becomes compaction-aware per pi's `buildContextEntries` (`session-manager.ts:475-513`): latest compaction entry (summary → a seeded context message) + entries from `first_kept_entry_id` onward + everything after the compaction entry; system messages in the kept range skipped. The summary-as-context-message role mapping (pi projects a `compactionSummary` role; ruby_llm supports system/user/assistant/tool) is a judgment call to report with evidence, not assume.

## Boundaries

**May touch (this lane's exhaustive set):**

- `lib/raspberry_pi/compaction.rb` (new — pure functions + settings struct + summarization call)
- `lib/raspberry_pi/agent/loop.rb` (threshold check after completed turns; overflow rescue→compact→retry-once with the latch; compaction event emission; `context_window:`/`compaction:` kwargs with safe defaults)
- `lib/raspberry_pi/agent/session.rb` (compaction entry append via the recorder; compaction-aware `context_messages`)
- `lib/raspberry_pi.rb` (registration only, if needed)
- `test/compaction_test.rb` (new)
- `test/session_test.rb`, `test/agent_loop_test.rb` (additions; existing tests must pass unmodified where feasible — API is additive)
- `README.md` (Sessions/compaction section: what triggers, `RASPBERRY_PI_CONTEXT_WINDOW`, settings kwargs)

**Must not touch:** `bin/raspberry-pi`, `lib/raspberry_pi/tools/**`, `lib/raspberry_pi/mcp.rb`, `lib/raspberry_pi/mcp/**`, `lib/raspberry_pi/print.rb`, `lib/raspberry_pi/tui.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/core/**`, `test/print_test.rb`, `test/mcp_test.rb`, `test/golden_parity_test.rb`, `test/tui_test.rb`, `test/chat_test.rb`, `test/support/mock_llm_server.rb` (read-only; if it cannot express a needed script — a context-length 400, or a second summary response — raise it in PHASE 0 with evidence; do not edit), `Gemfile`, `Gemfile.lock`, `bench/`. `~/.raspberry-pi` must never be touched (fake `$HOME`/tmp dirs in tests, as I07).

**Out of scope:** pi's branch summaries, context_edit/omission projection, settings.jsonl persistence (kwargs/env seam only), compaction progress UI beyond a loop event (the reduced event set grows by a compaction event; TUI rendering of it is optional polish — don't restructure the TUI), json event-stream mode, `--mode json` anything, custom instructions/hook interception, models.dev registry refreshes. No new runtime dependencies (gem-pins gate). No refactors beyond the task.

**No placeholders; search before implementing** (the repo's `grep`/`find` tools + gem source are in the worktree; pi oracle at `~/architect/spaces/20261009-pi-port/repos/pi`).

## Lane plan

One lane — the work is serial (pure functions → loop wiring → session recording → resume all share one mental model), and a seam between them would be artificial. High effort: subtle cut-point logic, overflow latch, and compaction-aware replay.

```lanes
- name: core
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/compaction.rb
    - lib/raspberry_pi/agent/loop.rb
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi.rb
    - test/compaction_test.rb
    - test/session_test.rb
    - test/agent_loop_test.rb
    - README.md
```

## Effort

`architect dispatch compaction --effort high` — subtle boundary logic (cut points that never orphan tool results, overflow retry-once latch, compaction-aware replay) + exact-string prompt transcription; a routine implementation error here silently corrupts long-session recovery.

## Acceptance Criteria

# Acceptance Criteria

**AC1 (pure functions ported — BRIEF §4, §7.6).** The compaction module's pure functions are test-proven with no LLM: token estimation (chars/4 per role incl. assistant tool-calls name+JSON-args and thinking), provider-usage accounting (`calculate_context_tokens` over the gem's actual Tokens accessors), `should_compact?` (enabled && tokens > context_window - reserve_tokens; nil/<=0 window disables), cut-point selection that keeps approximately `keep_recent_tokens` and **never orphans a `role: :tool` message from its preceding assistant tool-call message** (test-proven with a budget boundary falling mid-turn), and file-op extraction/format. Prompt strings (`SUMMARIZATION_SYSTEM_PROMPT`, `SUMMARIZATION_PROMPT`, `UPDATE_SUMMARIZATION_PROMPT`, `TURN_PREFIX_SUMMARIZATION_PROMPT`) and `serialize_conversation`'s exact prefixes/truncation are **byte-identical to pi's** — architect-read from the report's citations (a grep tripwire gate checks presence; identity is architect-read).

**AC2 (threshold trigger — BRIEF §7.6).** After a completed turn whose context tokens (last assistant message's provider-reported usage, per AC1) exceed `context_window - reserve_tokens`, the loop compacts: the chat history is replaced by `[summary message, kept recent tail]`. **MockLLMServer proof**: the captured next request payload contains the summary text and the kept messages, and none of the summarized-away messages. Settings are injectable kwargs with pi's defaults (enabled, reserve 16384, keep-recent 20000); `enabled: false` performs no compaction (test-proven). The context-window source is `RASPBERRY_PI_CONTEXT_WINDOW` → `chat.model.context_window` → nil, as reported in PHASE 0 (the report names what the default model actually resolves to in this repo).

**AC3 (overflow trigger — BRIEF §7.6, §4).** A step that raises `RubyLLM::ContextLengthExceededError` compacts and **retries the turn once** — MockLLMServer scripts the 400-overflow then a successful response, test-proven end-to-end; the overflowing attempt does not remain in the history that gets summarized or kept. A second consecutive overflow after compaction **does not retry again** (the latch) — the error surfaces to the caller (test-proven: script overflow, compact, overflow again → the run ends with the error surfaced, no third LLM call for the same turn).

**AC4 (compaction entry + resume-after-compaction — BRIEF §7.1, §7.6).** A compaction is recorded as a session entry with pi's `CompactionEntry` shape (type `"compaction"`, id, parentId, timestamp, summary, `firstKeptEntryId`, `tokensBefore`, details `{readFiles, modifiedFiles}` — the port's subset, deviations itemized). **Resume after compaction is test-proven**: `context_messages` on a compacted session file yields the latest compaction's summary (as the reported context-message mapping) + the entries from `firstKeptEntryId` onward + everything after the compaction entry, and **none** of the pre-compaction summarized messages — the seeded next-request payload (MockLLMServer) demonstrates exactly that. Pre-existing session files without compaction entries still load unmodified (existing session tests pass).

**AC5 (PHASE 0 + parity discipline + no regressions — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. All measured regression gates stay green with compaction wired in.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: compaction-guard
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/compaction_test.rb && echo COMPACTION_OK
  expect:
    exit_code: 0
    stdout_match: COMPACTION_OK

- id: session-agent-guard
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest -e 'require "./test/session_test.rb"; require "./test/agent_loop_test.rb"' && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC5
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

- id: prompts-verbatim
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'You are a context summarization assistant' lib/raspberry_pi/compaction.rb && grep -q '## Goal' lib/raspberry_pi/compaction.rb && grep -q 'conversation to summarize' lib/raspberry_pi/compaction.rb && echo PROMPTS_OK
  expect:
    exit_code: 0
    stdout_match: PROMPTS_OK

- id: tui-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
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
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration, per the freeze discipline): `prompts-verbatim` is a **tripwire** — keyword presence only; byte-identity of all four prompt templates and the serialize prefixes is architect-read from the report's pi citations, never gate-proven. `suite-green` proves the merged whole (AC5's regression floor); the per-file guards prove the touched areas run standalone. `session-agent-guard` uses the corrected multi-file require shape (the I07 INVALID lesson: `ruby -Itest a.rb b.rb` runs only the first file — ARGV quirk). Thresholds are floors by construction (run/assert counts grow with additions; no counts are frozen).

## Builder Prompt

### core

### LANE core — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I08-compaction-core/wt
  (a git worktree of the raspberry-pi repo, branch lane/I08-compaction-core, based on
  project/pi-port at 593e881d — everything through I07: kernel, agent loop (error-terminal
  + thinking strip; optional `recorder:`/`seed_messages:` kwargs), seven parity tools with
  safety/approval gating, TUI seam with style vocabulary, chat surface with the input-line
  editor and markdown-rendered completions, §5 toggle seam (off), the JSONL session store
  (Agent::Session + Agent::Session::Recorder, message-entry subset), the stdio MCP client +
  registry integration, print mode, and the CLI launcher (-p/--print, -r/--resume, MCP env).
  All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I08-compaction-core/report.md
- You may touch ONLY:
  lib/raspberry_pi/compaction.rb (new), lib/raspberry_pi/agent/loop.rb,
  lib/raspberry_pi/agent/session.rb, lib/raspberry_pi.rb (registration only, if needed),
  test/compaction_test.rb (new), test/session_test.rb, test/agent_loop_test.rb, README.md.
  Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - You build BRIEF §7.6 (compaction — "triggers and recovers correctly on long sessions"):
    pi's pure-function design (token estimation, cut-point selection) ported to a new
    `lib/raspberry_pi/compaction.rb`; two triggers wired into `Agent::Loop` — threshold
    (post-turn, provider-reported usage vs the model's context window) and overflow
    (`RubyLLM::ContextLengthExceededError` → omit the overflowing attempt, compact,
    retry the turn ONCE, latched); the compaction session entry recorded via the existing
    Recorder; and compaction-aware `context_messages` (resume after compaction).
  - pi's oracle layout for everything compaction: `repos/pi/packages/coding-agent/src/core/
    compaction/compaction.ts` + `compaction/utils.ts` + the trigger paths in
    `src/core/agent-session.ts` (:3007-3088) + `src/core/session-manager.ts` (CompactionEntry
    :91-104, appendCompactionEntry :1260-1285, buildContextEntries :475-513,
    createCompactionSummaryMessage in `src/core/messages.ts:109-121`). Read them before
    coding; every ported constant/prompt string/algorithm cites its pi line.
  - The four prompt templates must be byte-identical transcriptions (SUMMARIZATION_SYSTEM_PROMPT
    utils.ts:161-163, SUMMARIZATION_PROMPT compaction.ts:537-560, UPDATE_SUMMARIZATION_PROMPT
    :562-583, TURN_PREFIX_SUMMARIZATION_PROMPT :985-993) — transcribe from the oracle, do not
    paraphrase.
  - The context-window resolution (env `RASPBERRY_PI_CONTEXT_WINDOW` → `chat.model.context_window`
    → nil; nil/<=0 disables threshold only, overflow always fires) is a spec decision — verify
    what the port's default chat actually resolves (`assume_model_exists: true` may leave it
    nil; gem `models.rb` resolve path) and report it; pi guards `contextWindow <= 0` the same
    way (agent-session.ts:768-771).
  - The summarization call is a standalone one-shot (system = SUMMARIZATION_SYSTEM_PROMPT,
    one user message with the serialized conversation; NOT the chat history, NOT tools);
    `max_tokens = min(0.8 * reserve_tokens, model max)` (turn prefix 0.5x). Route it through
    MockLLMServer in tests — if the mock cannot script a second response on a fresh chat,
    report the mechanics you used; do NOT edit mock_llm_server.rb (read-only; raise in PHASE 0
    if it genuinely cannot express the needed scripts).
  - The overflow test needs the mock to return whatever the gem's transport middleware maps
    to `ContextLengthExceededError` (gem `transport/error_middleware.rb:125-158` — read
    `context_length_exceeded?` for the exact trigger shape); verify how the error surfaces
    through `Chat#step` and that the failed attempt does not remain in `chat.messages`.
  - Existing session files (message entries only) must load unchanged after your
    compaction-aware `context_messages` change; existing session/agent_loop tests pass
    unmodified where the API is additive. The recorded entry shape is pi's CompactionEntry
    port subset (type/id/parentId/timestamp/summary/firstKeptEntryId/tokensBefore/details
    {readFiles, modifiedFiles}) — snake_case keys per the port's existing session format.
  - Gates compaction-guard, session-agent-guard, and suite-green are your deliverable proof;
    prompts-verbatim, mcp-guard, print-guard, tui-seam, bench-seam, gem-pins, stderr-quiet,
    stderr-clean are all runnable at your base — run them and record verbatim; they must
    stay green (they prove you broke nothing). Do not weaken any gate's files.
  - Compaction is a loop-level concern: interactive, print, and resumed sessions all get it
    through Agent::Loop. Do NOT touch print.rb/mcp.rb/bin/ — compaction must work through
    the existing Agent::Loop call sites without modifying them (additive optional kwargs
    with safe defaults only).

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

# Specification

## Objective

Port pi's context compaction (BRIEF §7.6 — "compaction triggers and recovers correctly on long sessions"; design sketch BRIEF §4 "Compaction"). A long session's context grows until it threatens the context window; pi compacts by summarizing the old turns with an LLM call, cutting the history at a safe boundary, and continuing with `[summary, kept recent tail]`. The port wires this into `Agent::Loop` so interactive, print, and resumed sessions all survive long runs: a **threshold** trigger after each completed turn (provider-reported usage vs the model's context window) and an **overflow** trigger (`RubyLLM::ContextLengthExceededError` → omit the overflowing attempt, compact, retry the turn once). Compaction is recorded as a session entry and **resume after compaction** rebuilds the compacted context (BRIEF §7.1 session format grows by the compaction entry type — pi `session-manager.ts:91-104`).

pi's design is pure functions + thin wiring (`compaction.ts` header :1-6: "Pure functions for compaction logic"); keep that split — the port's compaction module must be testable with no LLM at all except the one-call summarization seam.

## Output format

Raw tables/JSON only in the report (absolute path `build/I08-compaction-core/report.md`): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the context-window resolution; the summary-message role mapping; the overflow retry boundary; how the summarization one-shot call is routed hermetically), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

**Verification (exact, from ARCHITECT.md):**

```
cd ~/architect/spaces/20261009-pi-port/repos/raspberry-pi
bundle install --quiet && bundle exec rake        # suite (test/**/*_test.rb)
```

**Verify against the live oracle + gem before writing code (PHASE 0 — every item needs file:line evidence):**

1. **pi's exact prompt strings** — transcribe verbatim into the port, byte-identical: `SUMMARIZATION_SYSTEM_PROMPT` (`utils.ts:161-163`), `SUMMARIZATION_PROMPT` and `UPDATE_SUMMARIZATION_PROMPT` (`compaction.ts:537-583`), `TURN_PREFIX_SUMMARIZATION_PROMPT` (`compaction.ts:985-993`). `SUMMARIZATION_PROMPT`'s full body runs :537-560 — copy the whole template.
2. **pi's file-op format** — `formatFileOperations` (`utils.ts:77-112`) exact output shape (headers/section text) and `computeFileLists` (:67-75); `extractFileOpsFromMessage` (:30-65) — which tool names produce reads vs edits (read/write/edit/bash shapes; verify against the port's actual tool result messages, which are ruby_llm `role: :tool` messages — the mapping from the port's tool calls is a judgment call to report, not assume).
3. **pi's `serializeConversation` + `truncateForSummary`** — `utils.ts:100-153`; note `TOOL_RESULT_MAX_CHARS` (find its value) and the exact `[User]:`/`[Assistant thinking]:`/`[Assistant]:`/`[Assistant tool calls]:`/`[Tool result]:` prefixes; map each to the port's ruby_llm message shapes (content strings, `tool_calls` with arguments, thinking replay) and itemize any that cannot apply.
4. **ruby_llm usage surface** — `Message#tokens` → `Tokens` (gem `message.rb:99-110`): confirm `input/output/cache_read/cache_write` accessors (gem `tokens.rb`) and that `Chat#step` results carry them; write `calculate_context_tokens` as pi's `totalTokens || input+output+cache_read+cache_write` against the gem's actual accessor set (report the exact formula used).
5. **ruby_llm context-window surface** — `Chat#model.context_window` (gem `model.rb:33,82`); confirm what the port's default chat (`assume_model_exists: true`, fireworks) resolves it to in this repo (nil unless the registry carries the model — `models.rb:686-715`). Decide + report the resolution order: `RASPBERRY_PI_CONTEXT_WINDOW` env override → `chat.model.context_window` → nil (nil/<= 0 disables the threshold trigger only; overflow still fires).
6. **ruby_llm one-shot summarization call** — how to make a standalone completion (fresh `RubyLLM.context`+`chat` or `context.chat` reuse) with a system prompt + single user message, `max_tokens` support, and **route it hermetically in tests through MockLLMServer** (a second scripted response on the same mock, or a separate mock instance — report which). Confirm the gem's retry surface (context `max_retries`) applies; itemize the deviation if pi's dedicated `retryAssistantCall` (:619-644) has no gem equivalent worth adding.
7. **ruby_llm overflow error** — `ContextLengthExceededError` (gem `transport/error_middleware.rb:125-158`): confirm what the mock must return to trigger it (status/body shape — read `context_length_exceeded?` in the same file) and how it surfaces through `Chat#step`/`Chat#run_tools` in the port's loop. Confirm the overflowing assistant message is NOT added to `chat.messages` when the step raises (or is removed) — pi omits the attempt (agent-session.ts :3007-3047); report the actual port mechanics.
8. **pi's overflow retry-once boundary** — agent-session.ts `_runAutoCompaction("overflow", willRetry)` (:3044-3047) + the `_overflowRecoveryAttempted` latch (:3040): verify a second consecutive overflow after compaction does NOT retry again (surfaces as the error). Port the latch.
9. **Port message shapes for estimation** — the port's messages are ruby_llm `Message`/attribute hashes (roles `:system/:user/:assistant/:tool`): map pi's per-role `estimateTokens` (`compaction.ts:298-355`) onto them (assistant: text + thinking + tool_calls name/JSON(args); tool: content; system/user: content). Itemize unrepresentable roles (pi's bashExecution/custom/branchSummary/compactionSummary are pi-internal; the port's live context holds none — say so).
10. **Cut-point safety in a flat message list** — pi cuts over session *entries* with "never at tool results" (:356-470); the port's live context is a flat `chat.messages` array. Verify the flat-list equivalent: a cut index may land on a user message or an assistant message, but must never orphan `role: :tool` messages from their preceding assistant tool-call message (they follow it in the array). Verify with a test where the budget boundary falls mid-turn.
11. **Session parse tolerance** — the port's `Agent::Session` parse skips unknown/malformed entry lines (I07); confirm adding the `compaction` entry type does not break existing session files, and that `context_messages` becomes compaction-aware per pi's `buildContextEntries` (`session-manager.ts:475-513`): latest compaction entry (summary → a seeded context message) + entries from `first_kept_entry_id` onward + everything after the compaction entry; system messages in the kept range skipped. The summary-as-context-message role mapping (pi projects a `compactionSummary` role; ruby_llm supports system/user/assistant/tool) is a judgment call to report with evidence, not assume.

## Boundaries

**May touch (this lane's exhaustive set):**

- `lib/raspberry_pi/compaction.rb` (new — pure functions + settings struct + summarization call)
- `lib/raspberry_pi/agent/loop.rb` (threshold check after completed turns; overflow rescue→compact→retry-once with the latch; compaction event emission; `context_window:`/`compaction:` kwargs with safe defaults)
- `lib/raspberry_pi/agent/session.rb` (compaction entry append via the recorder; compaction-aware `context_messages`)
- `lib/raspberry_pi.rb` (registration only, if needed)
- `test/compaction_test.rb` (new)
- `test/session_test.rb`, `test/agent_loop_test.rb` (additions; existing tests must pass unmodified where feasible — API is additive)
- `README.md` (Sessions/compaction section: what triggers, `RASPBERRY_PI_CONTEXT_WINDOW`, settings kwargs)

**Must not touch:** `bin/raspberry-pi`, `lib/raspberry_pi/tools/**`, `lib/raspberry_pi/mcp.rb`, `lib/raspberry_pi/mcp/**`, `lib/raspberry_pi/print.rb`, `lib/raspberry_pi/tui.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/core/**`, `test/print_test.rb`, `test/mcp_test.rb`, `test/golden_parity_test.rb`, `test/tui_test.rb`, `test/chat_test.rb`, `test/support/mock_llm_server.rb` (read-only; if it cannot express a needed script — a context-length 400, or a second summary response — raise it in PHASE 0 with evidence; do not edit), `Gemfile`, `Gemfile.lock`, `bench/`. `~/.raspberry-pi` must never be touched (fake `$HOME`/tmp dirs in tests, as I07).

**Out of scope:** pi's branch summaries, context_edit/omission projection, settings.jsonl persistence (kwargs/env seam only), compaction progress UI beyond a loop event (the reduced event set grows by a compaction event; TUI rendering of it is optional polish — don't restructure the TUI), json event-stream mode, `--mode json` anything, custom instructions/hook interception, models.dev registry refreshes. No new runtime dependencies (gem-pins gate). No refactors beyond the task.

**No placeholders; search before implementing** (the repo's `grep`/`find` tools + gem source are in the worktree; pi oracle at `~/architect/spaces/20261009-pi-port/repos/pi`).

## Lane plan

One lane — the work is serial (pure functions → loop wiring → session recording → resume all share one mental model), and a seam between them would be artificial. High effort: subtle cut-point logic, overflow latch, and compaction-aware replay.

```lanes
- name: core
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/compaction.rb
    - lib/raspberry_pi/agent/loop.rb
    - lib/raspberry_pi/agent/session.rb
    - lib/raspberry_pi.rb
    - test/compaction_test.rb
    - test/session_test.rb
    - test/agent_loop_test.rb
    - README.md
```

## Effort

`architect dispatch compaction --effort high` — subtle boundary logic (cut points that never orphan tool results, overflow retry-once latch, compaction-aware replay) + exact-string prompt transcription; a routine implementation error here silently corrupts long-session recovery.


=== ACCEPTANCE CRITERIA ===

## Acceptance Criteria

# Acceptance Criteria

**AC1 (pure functions ported — BRIEF §4, §7.6).** The compaction module's pure functions are test-proven with no LLM: token estimation (chars/4 per role incl. assistant tool-calls name+JSON-args and thinking), provider-usage accounting (`calculate_context_tokens` over the gem's actual Tokens accessors), `should_compact?` (enabled && tokens > context_window - reserve_tokens; nil/<=0 window disables), cut-point selection that keeps approximately `keep_recent_tokens` and **never orphans a `role: :tool` message from its preceding assistant tool-call message** (test-proven with a budget boundary falling mid-turn), and file-op extraction/format. Prompt strings (`SUMMARIZATION_SYSTEM_PROMPT`, `SUMMARIZATION_PROMPT`, `UPDATE_SUMMARIZATION_PROMPT`, `TURN_PREFIX_SUMMARIZATION_PROMPT`) and `serialize_conversation`'s exact prefixes/truncation are **byte-identical to pi's** — architect-read from the report's citations (a grep tripwire gate checks presence; identity is architect-read).

**AC2 (threshold trigger — BRIEF §7.6).** After a completed turn whose context tokens (last assistant message's provider-reported usage, per AC1) exceed `context_window - reserve_tokens`, the loop compacts: the chat history is replaced by `[summary message, kept recent tail]`. **MockLLMServer proof**: the captured next request payload contains the summary text and the kept messages, and none of the summarized-away messages. Settings are injectable kwargs with pi's defaults (enabled, reserve 16384, keep-recent 20000); `enabled: false` performs no compaction (test-proven). The context-window source is `RASPBERRY_PI_CONTEXT_WINDOW` → `chat.model.context_window` → nil, as reported in PHASE 0 (the report names what the default model actually resolves to in this repo).

**AC3 (overflow trigger — BRIEF §7.6, §4).** A step that raises `RubyLLM::ContextLengthExceededError` compacts and **retries the turn once** — MockLLMServer scripts the 400-overflow then a successful response, test-proven end-to-end; the overflowing attempt does not remain in the history that gets summarized or kept. A second consecutive overflow after compaction **does not retry again** (the latch) — the error surfaces to the caller (test-proven: script overflow, compact, overflow again → the run ends with the error surfaced, no third LLM call for the same turn).

**AC4 (compaction entry + resume-after-compaction — BRIEF §7.1, §7.6).** A compaction is recorded as a session entry with pi's `CompactionEntry` shape (type `"compaction"`, id, parentId, timestamp, summary, `firstKeptEntryId`, `tokensBefore`, details `{readFiles, modifiedFiles}` — the port's subset, deviations itemized). **Resume after compaction is test-proven**: `context_messages` on a compacted session file yields the latest compaction's summary (as the reported context-message mapping) + the entries from `firstKeptEntryId` onward + everything after the compaction entry, and **none** of the pre-compaction summarized messages — the seeded next-request payload (MockLLMServer) demonstrates exactly that. Pre-existing session files without compaction entries still load unmodified (existing session tests pass).

**AC5 (PHASE 0 + parity discipline + no regressions — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. All measured regression gates stay green with compaction wired in.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: compaction-guard
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/compaction_test.rb && echo COMPACTION_OK
  expect:
    exit_code: 0
    stdout_match: COMPACTION_OK

- id: session-agent-guard
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest -e 'require "./test/session_test.rb"; require "./test/agent_loop_test.rb"' && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: mcp-guard
  ac: AC5
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

- id: prompts-verbatim
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'You are a context summarization assistant' lib/raspberry_pi/compaction.rb && grep -q '## Goal' lib/raspberry_pi/compaction.rb && grep -q 'conversation to summarize' lib/raspberry_pi/compaction.rb && echo PROMPTS_OK
  expect:
    exit_code: 0
    stdout_match: PROMPTS_OK

- id: tui-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
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
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration, per the freeze discipline): `prompts-verbatim` is a **tripwire** — keyword presence only; byte-identity of all four prompt templates and the serialize prefixes is architect-read from the report's pi citations, never gate-proven. `suite-green` proves the merged whole (AC5's regression floor); the per-file guards prove the touched areas run standalone. `session-agent-guard` uses the corrected multi-file require shape (the I07 INVALID lesson: `ruby -Itest a.rb b.rb` runs only the first file — ARGV quirk). Thresholds are floors by construction (run/assert counts grow with additions; no counts are frozen).

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I08-compaction-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section compaction prompt --append --lane <lane> --from build/I08-compaction-<lane>/prompt.md`. -->

## Builder Report

### core

### Files

| File | Change |
|---|---|
| lib/raspberry_pi/compaction.rb | new — pure functions + Settings + 4 verbatim prompts + serialization |
| lib/raspberry_pi/agent/loop.rb | threshold trigger, overflow rescue→compact→retry-once w/ latch, `context_window:`/`compaction:` kwargs, :compaction event |
| lib/raspberry_pi/agent/session.rb | compaction entry factory + Recorder#append_compaction + compaction-aware context_messages |
| test/compaction_test.rb | new — 16 tests, no LLM |
| test/agent_loop_test.rb | +5 tests (threshold, disabled, overflow retry, latch, latch reset) |
| test/session_test.rb | +3 tests (entry shape, replay, resume end-to-end) |
| README.md | Sessions/Compaction section |

`lib/raspberry_pi.rb` untouched (loop.rb requires compaction.rb). No commits made (HEAD stays 593e881 "Merge lane/I07-session-mcp-print-cli"). git status: 5 modified + 2 untracked, all in the lane's exhaustive set.

### PHASE 0 findings (spec-vs-reality, file:line evidence)

| # | Verify item | Finding |
|---|---|---|
| 1 | Prompt strings | All four transcribed byte-identical. Verification script (this run): `SUMMARIZATION_SYSTEM_PROMPT: IDENTICAL` (utils.ts:161-163), `SUMMARIZATION_PROMPT: IDENTICAL` (compaction.ts:537-560), `UPDATE_SUMMARIZATION_PROMPT: IDENTICAL (after TS interpolation)` (:543-564; pi interpolates UPDATE_SUMMARIZATION_INSTRUCTIONS — one extra blank line in the first transcription was removed after byte-compare, 1257B both), `TURN_PREFIX_SUMMARIZATION_PROMPT: IDENTICAL` (:985-993). Ruby heredocs use `<<~PROMPT.chomp` (pi template literals have no trailing newline). |
| 2 | File-op format | `extract_file_ops` = utils.ts:36-65 restricted to port shapes: assistant `tool_calls` (ToolCall#name/#arguments, `path` arg), read/write/edit only; tool-result `nestedCalls` unrepresentable (port has no codemode). `compute_file_lists` = utils.ts:67-75 (read-only = read − modified, sorted). `format_file_operations` = utils.ts:77-95 (`<read-files>`/`<modified-files>` sections, `"\n\n"` join, `""` when empty). |
| 3 | serializeConversation | utils.ts:110-153. `TOOL_RESULT_MAX_CHARS = 2000` (utils.ts:103); truncation marker `"\n\n[... N more characters truncated]"` (utils.ts:111-113); prefixes `[User]: `/`[Assistant thinking]: `/`[Assistant]: `/`[Assistant tool calls]: `/`[Tool result]: `, parts joined `"\n\n"`, tool-call args `k=JSON.generate(v)` joined `", "` (utils.ts:135-139). Mapping: user/assistant/tool content strings; thinking via `Message#thinking.text`; tool calls via `ToolCall#name`/`#arguments` (tool_call.rb:17-24). System messages skipped (prompt state, pi convertToLlm). Port test compares the full joined string. |
| 4 | Usage surface | `Message#tokens` → `RubyLLM::Tokens` (message.rb:199-204); accessors `input/output/cache_read/cache_write` (tokens.rb:47-73, READERS tokens.rb:35-37). `Chat#step` returns the Message carrying them. Formula shipped: `calculate_context_tokens = [input, output, cache_read, cache_write].compact.sum`. **Deviation:** gem Tokens has NO total accessor (no `total`/`total_tokens` method in tokens.rb), so pi's `totalTokens ||` branch (compaction.ts:138-140) is unrepresentable; the component sum is the whole formula. |
| 5 | Context-window surface | `Chat#model.context_window` (chat.rb:37; model.rb:33,82). **Verified live resolution:** `assume_model_exists: true` → `Models.find` rescue → `Model.default(model_id, slug)` (models.rb:210) and `Model.default` sets no `context_window` (model.rb:65-75) → **the port's default chat resolves nil** → threshold disabled unless env set. Shipped resolution: explicit `context_window:` kwarg → `ENV["RASPBERRY_PI_CONTEXT_WINDOW"]` (digits only) → `chat.model.context_window` → nil; nil/<=0 disables threshold only (loop.rb `resolved_context_window`; matches pi's `model.contextWindow <= 0` guard agent-session.ts:768-771). |
| 6 | One-shot summarization | Fresh `@chat.context.chat(model:, provider: @chat.provider&.slug, assume_model_exists: true)` (Chat#context chat.rb:93, #provider :40, Context#chat context.rb:38), `with_instructions(SUMMARIZATION_SYSTEM_PROMPT)` + `with_max_output_tokens` (chat.rb:648), non-streaming `generate(prompt)`. `max_tokens = min(floor(0.8 * reserve_tokens), model.max_output_tokens>0 ? it : ∞)` (compaction.ts:683-686; gem's model max is `max_output_tokens`, model.rb:36). Hermetic routing: **the same MockLLMServer instance** — its script is a request queue; the summary call is simply the next captured request (no mock changes needed). Retry: pi's dedicated `retryAssistantCall` (:619-644) not ported — the gem's per-context `max_retries` config covers the summary chat (TestChat sets it); **deviation itemized**. |
| 7 | Overflow error | `ContextLengthExceededError` raised on 400 when the error message matches `CONTEXT_LENGTH_PATTERNS` (error_middleware.rb:69-77, :125-131, :163-165); mock trigger = `{type: :error, status: 400, message: "This model's maximum context length is 8 tokens"}` (matches `/context length/i`). Surfacing: `provider_completion` raises → `add_message` never runs (chat.rb:1213-1224: `record_generated_message` is only reached on return) → **the overflowing attempt is never in `chat.messages`**; the error crosses the Bridge as a `:error` terminal → `@last_error` (bridge.rb:54-55). |
| 8 | Overflow retry-once boundary | pi: `_overflowRecoveryAttempted` latch :3040, set before `_runAutoCompaction("overflow", willRetry)` :3042-3044; second overflow emits failure, returns false (:3019-3038). Port: same latch in `Loop#recover_overflow?` (set before compaction; compaction failure also surfaces the error); latch resets on a clean assistant response (pi :1168-1171) — test-proven. |
| 9 | Per-role estimation | `estimate_tokens` maps pi's :298-355 onto ruby_llm shapes: user/system/tool content strings; assistant text + `thinking.text` + tool calls (`name.length + JSON.generate(arguments).length`). Unrepresentable roles: pi's bashExecution/custom/branchSummary/compactionSummary are pi-internal — **the port's live context holds none** (live context = ruby_llm system/user/assistant/tool only). |
| 10 | Cut-point safety | `find_cut_point` over the flat list: cut points are user/assistant messages only (`:tool` and `:system` never); backwards walk accumulates `estimate_tokens`, budget-exceeded → closest valid cut point at/after that message, falling back to the last cut point (pi :449-452's "trailing tool results exceed the budget by themselves" case). Test-proven mid-turn: budget crossed at the tool result cuts at the next assistant (:356-470 semantics). |
| 11 | Session tolerance | `parse_entries`/`load_entries` unchanged (skip malformed lines, header-gated) — a `compaction` entry line is just another parsed Hash; existing files without compaction entries replay unchanged (all I07 session tests pass unmodified). `context_messages` = pi `buildContextEntries` (:475-513): latest compaction (rindex) → `[compaction]` + entries from `firstKeptEntryId` up to the compaction (system-role message entries skipped) + everything after. Summary role mapping: **user message** wrapped in `COMPACTION_SUMMARY_PREFIX/SUFFIX` (pi messages.ts:11-19, compactionSummary→user branch messages.ts:176-184) — evidence-cited, not assumed. |

### Parity-deviation table

| Deviation | Reason | Evidence |
|---|---|---|
| `calculate_context_tokens` drops pi's `totalTokens \|\|` branch | gem Tokens has no total accessor | tokens.rb:35-37, 81-89 |
| Overflow compaction ignores `settings.enabled` (threshold respects it) | pi parity: pi's overflow path never checks enabled | agent-session.ts:3007-3047, :3097+ vs compaction.ts:292-296 |
| Split-turn / turn-prefix summarization (two-summary path, compaction.ts:816-828, :1072-1119) not wired live; TURN_PREFIX_SUMMARIZATION_PROMPT transcribed but unwired | flat-list cut contract per spec item 10 requires only never-orphaning cut points; turn-prefix splitting is entry-projection machinery | spec item 10; compaction.ts |
| `previous_summary`/UPDATE_SUMMARIZATION_PROMPT transcribed but unwired live; re-compaction re-serializes the prior summary message as ordinary conversation text | the port's fork-subset resume does not re-record parent entries, so there is no in-file previous-summary chain | session_test.rb:140 ("prior turns are not re-recorded") |
| `firstKeptEntryId` falls back to the compaction entry's own id when the first kept message was not recorded in the current file (resumed seed messages) | same resume-shape reason; identical to pi's `firstKeptEntryId ?? id` fallback | session-manager.ts:1264 |
| No dedicated `retryAssistantCall` port | gem per-context `max_retries` covers the summary chat | compaction.ts:619-644; TestChat config |
| Compaction entry omits `usage`/`fromHook`/`systemMessage` fields | AC4's stated port subset | session-manager.ts:91-104 |
| Custom-instructions focus (`Additional focus:`, compaction.ts:690-692) not ported | spec out-of-scope: custom instructions/hook interception | spec "Out of scope" |
| Entry keys are pi's camelCase (`firstKeptEntryId`, `tokensBefore`, `details{readFiles, modifiedFiles}`), not "snake_case" | the port's existing format preserves pi's camelCase (`parentId`); AC4's letter names these keys | session.rb message_entry; session_test `header["parentSession"]` |

### Judgment calls (spec-requested)

- Context-window resolution: verified in PHASE 0 item 5 — the default chat resolves **nil**; env is the only live source unless a registry model is used.
- Summary-message role mapping: `:user` with pi's exact prefix/suffix strings (item 11).
- Overflow retry boundary: retry re-enters `step_via_bridge` in the same inner loop; the original error is cleared only after successful compaction, and the failed attempt is absent from the summarized/kept history (gem never appends it — item 7).
- Summarization one-shot routing: fresh chat from the run chat's own `RubyLLM::Context`, run through the existing `Bridge` (kernel-interrupt cancellable via `on_cancel { summary_chat.cancel }`); hermetic via the same MockLLMServer request queue.

### Gate results (verbatim, this run)

| Gate | Result |
|---|---|
| suite-green | `176 runs, 671 assertions, 0 failures, 0 errors, 0 skips` / `SUITE_OK` |
| compaction-guard | `16 runs, 48 assertions, 0 failures, 0 errors, 0 skips` / `COMPACTION_OK` |
| session-agent-guard | `18 runs, 130 assertions, 0 failures, 0 errors, 0 skips` / `SESSION_OK` |
| mcp-guard | `18 runs, 96 assertions, 0 failures, 0 errors, 0 skips` / `MCP_OK` |
| print-guard | `4 runs, 19 assertions, 0 failures, 0 errors, 0 skips` / `PRINT_OK` |
| prompts-verbatim | `PROMPTS_OK` |
| tui-seam | `SEAM_OK` |
| bench-seam | `SEAM_BENCH_OK` |
| gem-pins | `PINS_OK` |
| stderr-quiet | `NO_WARN` |
| stderr-clean | `NO_EPIPE` |
| prompt byte-identity (extra, architect-read aid) | `SYSTEM IDENTICAL / SUMMARIZATION IDENTICAL / UPDATE_SUMMARIZATION_PROMPT IDENTICAL (after TS interpolation) / TURN_PREFIX IDENTICAL` |

Note: one pre-existing `IO::Buffer is experimental` warning from session.rb's `File.write(..., mode: "a")` (present before this lane; stderr gates grep only for 'unhandled exception'/'Broken pipe').

STATUS: COMPLETE_WITH_CONCERNS (concerns: the four unwired transcriptions — split-turn turn-prefix summarization, UPDATE/previous-summary live path — are itemized deviations above, not gaps in the gates; and the default model resolves `context_window: nil`, so threshold compaction is inert in production unless `RASPBERRY_PI_CONTEXT_WINDOW` is set — this is the spec's own resolution order, verified live)

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I08-compaction-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence compaction --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
