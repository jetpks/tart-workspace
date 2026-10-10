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
`architect rehearse compaction` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze compaction` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse compaction` — before the freeze, while
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
subsection per lane. A copy is written to build/I08-compaction-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section compaction prompt --append --lane <lane> --from build/I08-compaction-<lane>/prompt.md`. -->

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
