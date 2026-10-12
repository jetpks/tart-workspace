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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section compaction-usage specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision compaction-usage`
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
