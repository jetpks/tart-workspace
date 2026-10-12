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
`architect rehearse compaction-usage` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze compaction-usage` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse compaction-usage` — before the freeze, while
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
subsection per lane. A copy is written to build/I29-compaction-usage-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section compaction-usage prompt --append --lane <lane> --from build/I29-compaction-usage-<lane>/prompt.md`. -->

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
