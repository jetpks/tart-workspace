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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section compaction specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision compaction`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
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
