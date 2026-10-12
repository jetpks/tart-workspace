# I29: compaction-usage

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I29 compaction-usage

Measured this session (2026-10-12) at base **8c7a438** (= `project/pi-port` tip after
I27 + the `build_surface` wiring fix):

1. **Owner ruling (2026-10-12, decisions log).** The compaction arithmetic goes
   **usage-backed**: ruby_llm 2.1.0 exposes `Message#tokens` (input/output/cache_read/
   cache_write, aggregated per provider attempt) and `Chat#tokens` (gem chat.rb:940-956)
   — the gem was never the blocker. The own-client hypothesis is dead (parked unless a
   live gap appears). pi's reference math: `calculateContextTokens` (compaction.ts:140)
   with pi's Case-3 estimate fallback for error/zero-usage messages.

2. **pi's trigger arithmetic (measured, packages/coding-agent/src/core/).**
   `compaction.ts`: `calculateContextTokens` :140 (`usage.totalTokens ||` the four-part
   sum); `getAssistantUsage` :146 (skips aborted/error stop-reasons and all-zero
   usage); `estimateContextTokens` :196 (usage-backed through the LAST valid assistant
   usage, chars/4 estimates trailing); `estimateProjectedContextTokens` :222 (the
   context-edit projection); `shouldCompact` :292; DEFAULT_COMPACTION_SETTINGS :120.
   `agent-session.ts` ~:3049-3100, the threshold trigger's Case structure:
   **the just-completed assistant's DIRECT usage is the primary context-tokens
   source**; Case 3 (stopReason error OR direct tokens == 0) falls back to
   `estimateContextTokens` over the messages; the stale pre-compaction guard lives
   INSIDE the fallback (a usage message at-or-before the compaction entry's timestamp
   cannot trigger — kept messages carry stale, larger-context usage).

3. **The port's state (measured at 8c7a438) — already further than the ruling
   assumed.** `lib/tart/compaction.rb` already mirrors pi's estimate family:
   `calculate_context_tokens` :164 (four-part sum; the gem's Tokens has no total
   accessor — itemized), `estimate_context_tokens` :171 (last-usage + trailing
   estimate, pi :196-225), `assistant_usage` :182 (**NO stop-reason guard** — the
   gem's `Message` surface must be checked for a stop-reason observable),
   `full_estimate` :191. The footer's usage accounting is usage-backed
   (footer.rb:62-75, accumulated from assistant `Message#tokens`), and the rig's
   MockLLM ALREADY emits usage (test/support/mock_llm_server.rb:159/:181 —
   10/5/15) with both apps' settled footers rendering `0.0%/33k` — usage flows live
   end-to-end today. The REAL deltas: (a) the port's threshold trigger
   (agent/loop.rb:282-290) is **estimate-always** — pi's is direct-usage-first with
   the Case-3 fallback; (b) `assistant_usage` lacks pi's stop-reason skip (verify
   the gem's observable); (c) pi's `CompactionResult` carries `estimatedTokensAfter?`
   + `usage?` (the compaction call's own usage) — the port's `prepare` result shape
   must be checked against what pi populates (the compaction-panel fast-follow
   iteration renders off these fields); (d) the rig has NO zero-usage knob — the
   Case-3 path is unexercised by any instrument; (e) the I27-verdict residual:
   `Agent::Loop#switch_model` keeps the OLD context window when the catalog entry
   declares none (loop.rb seam — chat.rb passes nil through).

4. **Sequencing (this session's ruling, refining the owner's sketch).** The owner's
   sketch ran compaction as panel+usage in one iteration; chat.rb (the `:compaction`
   render handler, chat.rb:393-404) is single-writer with the I28 selection wave
   running in parallel right now — the panel queues as the FAST-FOLLOW iteration off
   I28's integrated tip. The usage work (loop.rb + compaction.rb + tests + rig) is
   file-disjoint from I28 → it runs parallel NOW (both dispatched together this
   session, same base, both worktrees isolated).

5. **Control (this session, base 8c7a438).** Suite 526 runs / 2035 assertions / 0
   failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0 cold; s7 exit 1 by
   design (the panel — the fast-follow, untouched here). All regression claims below
   are against this baseline.

## Specification

# Specification — I29 compaction-usage

- **Objective.** Bring the compaction trigger arithmetic to pi's exact usage-backed
  shape (BRIEF §3 daily-driver reliability + the owner's 2026-10-12 usage ruling,
  Grounds 1-2): the port already carries pi's estimate family and live usage flow
  (Grounds 3) — the remaining deltas are the trigger's Case structure, the
  stop-reason guard, the result fields the panel fast-follow renders off, the rig's
  missing Case-3 instrument, and the I27 nil-window switch residual. Why now: the
  compaction-panel port (the fast-follow iteration) renders off this arithmetic —
  its spec needs these seams measured and true first; and a daily-driver session
  must not falsely trigger (or fail to trigger) compaction because the port
  re-derives context size pi reads directly off the just-completed turn.

- **Deliver the direct-first trigger** (pi agent-session.ts ~:3049-3100): the
  threshold check reads the just-completed assistant message's DIRECT usage first
  (`calculateContextTokens(message.tokens)`); Case 3 (error stop-reason OR
  zero/absent usage) falls back to `estimate_context_tokens` over the chat
  messages; the stale pre-compaction guard stays inside the fallback (the port's
  `@pre_compaction_messages` set is the standing equivalent of pi's
  timestamp-vs-compaction-entry check — keep it, itemize the divergence). The
  overflow trigger (:263) is untouched. Behavior-identical for the healthy path
  (the mock's 15-token usage today) — the parity gates are the guard.
- **Deliver the stop-reason guard** (pi getAssistantUsage :146-156): `assistant_usage`
  skips aborted/error messages. VERIFY the gem's `Message` surface for a stop-reason
  observable (ruby_llm 2.1.0 — gem source at
  ~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/):
  if the gem exposes it, port the guard; if it does not, itemize the cut with the
  gem citation (never fake an unobservable guard).
- **Sweep the arithmetic function-by-function** (pi compaction.ts ↔ the port's
  compaction.rb): `calculateContextTokens` (the gem's Tokens lacks `totalTokens` —
  the standing itemization stays), `estimateContextTokens`, `estimateTokens` shapes,
  `shouldCompact`, DEFAULT settings, and the `compact()` result flow — pi's
  `CompactionResult` carries `estimatedTokensAfter?` and `usage?` (the summarization
  call's own usage): verify whether pi's implementation POPULATES them; if it does,
  carry the fields on the port's preparation result (data only — the RENDER is the
  panel fast-follow's, do not touch render); if pi leaves them unset, itemize as cut.
  `estimateProjectedContextTokens` (pi's context-edit projection) is CUT (the port
  has no projection system) — itemize, do not build.
- **Deliver the rig's Case-3 instrument**: a MockLLM usage-suppression knob
  (scenario-level — responses without usage) + a scenario or probe extension
  proving BOTH apps compact under the zero-usage path (the Case-3 fallback parity:
  both apps' trigger fires on the estimate, both compact, the settled parity holds).
  s7's existing behavior is the template. s1–s6 must stay exit 0 (the healthy path
  is untouched — regression guard); s7 stays exit 1 (the panel is the fast-follow,
  not here); registry additions-only vs 8c7a438.
- **Deliver the I27 nil-window switch residual** (loop.rb seam): switching to a
  catalog entry that declares no contextWindow re-resolves the window instead of
  keeping the stale one (resolve from the chat's model — the gem's model registry /
  the port's known-models table, whichever the boot path already uses — verify and
  itemize the source); a footer-denominator refresh test pins it. Read pi's
  switchModel for the reference behavior first (does pi re-resolve when the model
  carries no window?).
- **Tests.** Direct-class compaction tests pin the trigger Case structure
  (direct-usage path, zero-usage fallback path, the stale guard inside the fallback)
  with the existing MockLLM idioms (zero-usage via the new knob — the knob is the
  mock's, not the class's); agent_loop tests pin the trigger wiring + the
  nil-window re-resolve; mock_llm_server's knob gets its own test. No mocks of the
  class under test.
- **Boundaries.** Touch: `lib/tart/compaction.rb`, `lib/tart/agent/loop.rb`,
  `test/compaction_test.rb`, `test/agent_loop_test.rb`,
  `test/support/mock_llm_server.rb`,
  `test/parity/mock_llm_extension_test.rb` (only if the knob's test belongs there —
  the mock's test home), `gems/tui-split-rig/**`. Must not: everything else — in
  particular `lib/tart/render/**` ALL (chat.rb, selection.rb, footer.rb are sibling
  iteration I28 whole-screen-selection's territory — a PARALLEL iteration is
  building there right now; touching it fails both iterations), `bin/tart`,
  `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/commands.rb`,
  `test/chat_test.rb`, `test/render/**`, `lib/tart/session*`. No placeholders;
  search before implementing. Out of scope, itemize if tempted: the compaction
  PANEL (the [compaction] customMessageBg rendering — the fast-follow iteration's),
  pi's projection system, own-client token counting (parked by the owner ruling).

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet &&
  bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources: `repos/pi/packages/coding-agent/src/core/compaction/
  compaction.ts` (the full arithmetic) and `repos/pi/packages/coding-agent/src/core/
  agent-session.ts` (~:3049-3100 the trigger Cases; :2657 the thinking-level gate is
  I28's, not yours). The gem source at
  ~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
  (chat.rb, message.rb, tokens.rb) — verify the Message surface live before building
  on it; cite what you port.

- **Output format.** Raw evidence to scratch: file list + wc; the function-by-function
  arithmetic table (pi function → port method, before/after, per delta); the trigger
  Case table (direct/Case-3/stale-guard paths with test names); the gem
  Message-surface verification (the exact methods, live-checked); the Case-3 rig
  proof (probe/scenario output, both apps compact); verbatim test tails + suite
  counts; itemized cuts. PHASE 0 disagreements mandatory. STATUS line last.

```lanes
- name: usage
  repo: tart
  touch:
    - lib/tart/compaction.rb
    - lib/tart/agent/loop.rb
    - test/compaction_test.rb
    - test/agent_loop_test.rb
    - test/support/mock_llm_server.rb
    - test/parity/mock_llm_extension_test.rb
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I29 compaction-usage

**AC1 (direct-first trigger).** The threshold trigger reads the just-completed
assistant message's direct usage first; Case 3 (error/zero/absent usage) falls back
to the estimate over the messages; the stale pre-compaction guard stays inside the
fallback. Pinned by direct-class tests naming all three paths. The healthy path is
behavior-identical to base (the parity gates are the guard).

**AC2 (stop-reason + arithmetic sweep).** `assistant_usage` skips aborted/error
messages IFF the gem exposes a stop-reason observable (live-verified against
ruby_llm 2.1.0; itemized as cut with the gem citation if unobservable). The
function-by-function compaction.ts↔compaction.rb sweep is delivered in the report
with every delta ruled ported/cut/itemized; pi's `estimatedTokensAfter?`/`usage?`
result fields are carried on the port's preparation result if pi populates them
(data only — render is the panel fast-follow's); the projection is cut, itemized.

**AC3 (Case-3 rig instrument).** The rig's MockLLM gains a scenario-level
usage-suppression knob, and a scenario or probe proves BOTH apps compact under the
zero-usage path (both apps' triggers fire on the estimate, both compact). s1–s6
exit 0 cold (the healthy path unshifted); s7 still exits 1; registry additions-only
vs 8c7a438.

**AC4 (nil-window switch).** Switching to a catalog entry with no declared
contextWindow re-resolves the window (from the chat's model — the source verified
against the gem's registry / the port's boot path and itemized) instead of keeping
the stale one; a test pins the footer denominator refresh.

**AC5 (scope discipline).** The integrated diff touches exactly the enumerated
files. Sealed (sibling iteration I28's territory + the rest): lib/tart/render/**
ALL (chat.rb, selection.rb, footer.rb), bin/tart, models.rb, settings.rb,
commands.rb, test/chat_test.rb, test/render/**.

**AC6 (suite + bench).** The default rake task fully green (run-count delta > 0 —
new tests) and the seam bench prints `SEAM_BENCH_OK`.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-still-baselined
  ac: AC3
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 8c7a438:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 8c7a438 HEAD | grep -qvE '^(lib/tart/compaction.rb|lib/tart/agent/loop.rb|test/compaction_test.rb|test/agent_loop_test.rb|test/support/mock_llm_server.rb|test/parity/mock_llm_extension_test.rb|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### usage

# Lane dispatch — I29 compaction-usage, lane `usage`

**You are lane `usage`.** You are ONE of TWO parallel lane agents dispatched together
(the other is lane `selection` of sibling iteration I28 whole-screen-selection,
isolated in its own worktree — its territory is `lib/tart/render/chat.rb`,
`lib/tart/render/selection.rb`, `lib/tart/render/footer.rb`, `test/chat_test.rb`, and
`test/render/selection_test.rb`, which you must NEVER touch). Your lane's territory,
exhaustively:

- **Touch (exactly these files):** `lib/tart/compaction.rb`,
  `lib/tart/agent/loop.rb`, `test/compaction_test.rb`, `test/agent_loop_test.rb`,
  `test/support/mock_llm_server.rb`, `test/parity/mock_llm_extension_test.rb` (only if
  the usage knob's test belongs there — the mock's test home), and
  `gems/tui-split-rig/**` (the whole rig).
- **Must not touch:** everything else — in particular `lib/tart/render/**` ALL
  (chat.rb, selection.rb, footer.rb are the sibling iteration I28's territory — a
  PARALLEL iteration is building there right now; touching it fails both lanes),
  `bin/tart`, `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/commands.rb`,
  `test/chat_test.rb`, `test/render/**`. Files outside this list belong to other
  agents or are sealed — touching them fails your lane AND the sibling's.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them (notably: the ruby_llm 2.1.0 `Message` surface for a
stop-reason observable — gem source at
~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
(message.rb, chat.rb, tokens.rb) — verify LIVE before building on it; and pi's
compact() result-field population).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive collection/enumerable forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Consistency with the surrounding code
is part of correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write) is
not done. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout (the parity
rig runs take tens of seconds each — allow 120s+ each). IMPORTANT tmux
discipline: a `tmux kill-server` from you kills every other agent's live
sessions on the shared server — NEVER run it; kill only sessions you created by
exact name (the runner's sessions are token-scoped). If a runtime will not
start unattended, record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the scratch
file given to you below (an absolute path OUTSIDE your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I29-compaction-usage-usage/report.md

## Your lane's specification (lane `usage` ONLY — the sibling iteration's deliverables are NOT yours)

- **Objective.** Bring the compaction trigger arithmetic to pi's exact usage-backed
  shape: the port already carries pi's estimate family and live usage flow
  (compaction.rb's estimate family; the footer's usage-backed accounting; the rig's
  MockLLM already emits usage and both apps' settled footers render `0.0%/33k`) —
  the remaining deltas are the trigger's Case structure, the stop-reason guard, the
  result fields the compaction-panel fast-follow renders off, the rig's missing
  Case-3 instrument, and the I27 nil-window switch residual. Why now: the
  compaction-panel port (the fast-follow iteration) renders off this arithmetic —
  its spec needs these seams measured and true first; and a daily-driver session
  must not falsely trigger (or fail to trigger) compaction because the port
  re-derives context size pi reads directly off the just-completed turn.

- Deliver **the direct-first trigger** (pi agent-session.ts ~:3049-3100): the
  threshold check reads the just-completed assistant message's DIRECT usage first
  (`calculate_context_tokens(message.tokens)`); Case 3 (error stop-reason OR
  zero/absent usage) falls back to `estimate_context_tokens` over the chat messages;
  the stale pre-compaction guard stays inside the fallback (the port's
  `@pre_compaction_messages` set is the standing equivalent of pi's
  timestamp-vs-compaction-entry check — keep it, itemize the divergence). The
  overflow trigger (agent/loop.rb:263) is untouched. Behavior-identical for the
  healthy path (the mock's 15-token usage today) — the parity gates are the guard.
- Deliver **the stop-reason guard** (pi getAssistantUsage :146-156): `assistant_usage`
  skips aborted/error messages. VERIFY the gem's `Message` surface for a stop-reason
  observable: if the gem exposes it, port the guard; if it does not, itemize the cut
  with the gem citation (never fake an unobservable guard).
- **Sweep the arithmetic function-by-function** (pi compaction.ts ↔ the port's
  compaction.rb): `calculateContextTokens` (:140 — the gem's Tokens lacks totalTokens,
  the standing itemization stays), `estimateContextTokens` (:196), `estimateTokens`
  shapes, `shouldCompact` (:292), DEFAULT settings (:120), and the compact() result
  flow — pi's `CompactionResult` carries `estimatedTokensAfter?` and `usage?` (the
  summarization call's own usage): verify whether pi's implementation POPULATES
  them; if it does, carry the fields on the port's preparation result (data only —
  the RENDER is the panel fast-follow's, do not touch render); if pi leaves them
  unset, itemize as cut. `estimateProjectedContextTokens` (:222, the context-edit
  projection) is CUT (the port has no projection system) — itemize, do not build.
- Deliver **the rig's Case-3 instrument**: a MockLLM usage-suppression knob
  (scenario-level — responses without usage) + a scenario or probe extension proving
  BOTH apps compact under the zero-usage path (both apps' triggers fire on the
  estimate, both compact, the settled parity holds). s7's existing behavior is the
  template. s1–s6 must stay exit 0 (the healthy path is untouched — regression
  guard); s7 stays exit 1 (the panel is the fast-follow, not here); registry
  additions-only vs 8c7a438.
- Deliver **the I27 nil-window switch residual** (loop.rb seam): switching to a
  catalog entry that declares no contextWindow re-resolves the window instead of
  keeping the stale one (resolve from the chat's model — the gem's model registry /
  the port's known-models table, whichever the boot path already uses — verify and
  itemize the source); a footer-denominator refresh test pins it. Read pi's
  switchModel for the reference behavior first (does pi re-resolve when the model
  carries no window?).
- Tests: direct-class compaction tests pin the trigger Case structure (direct-usage
  path, zero-usage fallback path, the stale guard inside the fallback) with the
  existing MockLLM idioms (zero-usage via the new knob — the knob is the mock's, not
  the class's); agent_loop tests pin the trigger wiring + the nil-window re-resolve;
  the knob gets its own test. No mocks of the class under test.
- **Boundaries for this lane:** the touch list above is exhaustive. Out of scope,
  itemize if tempted: the compaction PANEL (the [compaction] customMessageBg
  rendering — the fast-follow iteration's), pi's projection system, own-client token
  counting (parked by the owner's ruling).
- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet &&
  bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources: repos/pi/packages/coding-agent/src/core/compaction/
  compaction.ts (the full arithmetic) and repos/pi/packages/coding-agent/src/core/
  agent-session.ts (~:3049-3100 the trigger Cases; :2657 the thinking-level gate is
  the sibling iteration's, not yours). The gem source at
  ~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ruby_llm-2.1.0/
  (chat.rb, message.rb, tokens.rb) — verify the Message surface live before building
  on it; cite what you port.
- **Output format.** Raw evidence to scratch: file list + wc; the
  function-by-function arithmetic table (pi function → port method, before/after,
  per delta); the trigger Case table (direct/Case-3/stale-guard paths with test
  names); the gem Message-surface verification (the exact methods, live-checked);
  the Case-3 rig proof (probe/scenario output, both apps compact); verbatim test
  tails + suite counts; itemized cuts. PHASE 0 disagreements mandatory. STATUS line
  last.

## Acceptance Criteria (frozen — verify against these)

**AC1 (direct-first trigger).** The threshold trigger reads the just-completed
assistant message's direct usage first; Case 3 (error/zero/absent usage) falls back
to the estimate over the messages; the stale pre-compaction guard stays inside the
fallback. Pinned by direct-class tests naming all three paths. The healthy path is
behavior-identical to base (the parity gates are the guard).

**AC2 (stop-reason + arithmetic sweep).** `assistant_usage` skips aborted/error
messages IFF the gem exposes a stop-reason observable (live-verified against
ruby_llm 2.1.0; itemized as cut with the gem citation if unobservable). The
function-by-function compaction.ts↔compaction.rb sweep is delivered in the report
with every delta ruled ported/cut/itemized; pi's `estimatedTokensAfter?`/`usage?`
result fields are carried on the port's preparation result if pi populates them
(data only — render is the panel fast-follow's); the projection is cut, itemized.

**AC3 (Case-3 rig instrument).** The rig's MockLLM gains a scenario-level
usage-suppression knob, and a scenario or probe proves BOTH apps compact under the
zero-usage path (both apps' triggers fire on the estimate, both compact). s1–s6
exit 0 cold (the healthy path unshifted); s7 still exits 1; registry additions-only
vs 8c7a438.

**AC4 (nil-window switch).** Switching to a catalog entry with no declared
contextWindow re-resolves the window (from the chat's model — the source verified
against the gem's registry / the port's boot path and itemized) instead of keeping
the stale one; a test pins the footer denominator refresh.

**AC5 (scope discipline).** The integrated diff touches exactly the enumerated
files. Sealed: lib/tart/render/** ALL (chat.rb, selection.rb, footer.rb), bin/tart,
models.rb, settings.rb, commands.rb, test/chat_test.rb, test/render/**.

**AC6 (suite + bench).** The default rake task fully green (run-count delta > 0 —
new tests) and the seam bench prints `SEAM_BENCH_OK`.

Gate commands you can run to self-verify (frozen; run them from YOUR worktree):

```
bundle install --quiet && bundle exec rake && echo SUITE_OK     # expect exit 0, SUITE_OK
bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1             # expect SEAM_BENCH_OK
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/gate-s1      # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/gate-s2      # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/gate-s3  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/gate-s4  # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/gate-s5 # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/gate-s6     # exit 0
gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/gate-s7; test $? -eq 1 && echo S7_STILL_1
if git show 8c7a438:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY; fi
if git diff --name-only 8c7a438 HEAD | grep -qvE '^(lib/tart/compaction.rb|lib/tart/agent/loop.rb|test/compaction_test.rb|test/agent_loop_test.rb|test/support/mock_llm_server.rb|test/parity/mock_llm_extension_test.rb|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
```

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I29-compaction-usage-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence compaction-usage --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction-usage verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction-usage`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
