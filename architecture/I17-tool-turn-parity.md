# I17: tool-turn-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8, backlog item B.** The exact-parity program's next measured slice: the plain tool turn. I16 closed s1_text_turn (exit 0, byte-identical settled screens); the instrument's second scenario, `s2_tool_turn` (mock scripts a bash tool call — `echo pty-tester` — plus a fixed final reply, 2 requests per app), still exits 1.

**Measured baseline (this session, post-I16-merge tree 0fccfc74, `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-baseline-s2`): exit 1, 10 unknown-candidate lines** (verbatim from `summary.json` candidates; `-` = pi-only, `+` = tart-only):

```
+  ⎿ bash: pty-tester
- $ echo pty-tester
+ The bash tool ran; fixed final reply for the spike.
- pty-tester
- Took 0.0s
- The bash tool ran; fixed final reply for the spike.
+
+
-↑20 ↓10 0.0%/33k (auto) … (mock) mock-1
+↑20 ↓10 0.0%/33k (auto) … (openai) mock-1
```

Attribution against the settled captures (pi rows 9–20 are the contract, verbatim):

| # | pi (oracle) settled bytes | tart today | Root cause class |
|---|---|---|---|
| 1 | tool block opens with blanks then ` $ echo pty-tester` (bold, `bashMode` color) | `  ⎿ bash: pty-tester` (the port's own invented tool-line shape, I05-era) | bash tool render (pi bash-execution.ts:141 `$ ${command}` header) |
| 2 | ` pty-tester` — tool output as its own muted lines | (folded into the ⎿ preview) | same |
| 3 | ` Took 0.0s` — muted duration line | none | timing: the port never measures tool-execution duration (loop.rb `:tool_execution_end` carries only tool_call + result) |
| 4 | blank-line structure around command/output/timing (pi rows: Spacer, command, blank, output, blank, timing, blank, blank, reply) | one blank either side of the ⎿ line | same render family |
| 5 | footer right segment `(mock) mock-1` | `(openai) mock-1` | s2 scenario predates I16's footer staging — `TART_MODEL_PROVIDER: mock` is not staged (data-only; s1 does stage it) |

pi source anchors (verified readable in `repos/pi` this session): `modes/interactive/components/bash-execution.ts:32-38,141` (`colorKey` = `dim` | `bashMode`; `$ ${command}` header, bold), `core/tools/renderers/bash.ts:20-28,105-109` (`formatDuration`: `<60s` → `X.Xs` one decimal, `<60m` → `Xm Ys`, else `Xh Ym Zs`; `Took`/`Elapsed`, muted; recorded duration wins over the renderer clock), `core/tools/renderers/bash.ts:141-149` (output lines muted, `\n`-separated children), `modes/interactive/components/tool-execution.ts:61,137` (`durationMs` on the tool result), `core/agent-session.ts:1358` (durationMs recorded in session entries — so pi's replay renders `Took` from the record), `modes/interactive/theme/theme-tokens.ts:100` / `system-theme.ts:112` (`bashMode` = green).

**The timing seam (cross-lane contract, the frozen boundary between two lanes).** The port's `:tool_execution_end` event (agent/loop.rb:437-442, 479-482) carries `tool_call` + `result` only — no duration. pi measures per execution (monotonic) and renders `Took` from it. The port needs the same: duration measured in the agent loop, carried on the event, rendered by the chat surface. The port's recorded session entries carry no duration (BRIEF §7.1 shape) — pi records it (agent-session.ts:1358) and renders `Took` on replay; that recorded gap stays itemized this iteration (the replay contract: recorded gaps itemized, never invented — I15).

**Instrument gap (feeds the NEXT work list, this iteration's rig lane): the port's non-bash tool renders are unmeasured.** The port renders every tool through one invented `⎿ name: preview` shape; pi has per-tool renderers (`core/tools/renderers/*.ts`: read/edit/write/grep/ls/find…). No scenario exercises any non-bash tool turn, so the divergence is invisible to the instrument. A third scenario (a file-tool turn: write + read in the sandbox) extends the rig and captures the baseline candidate list for the next iteration's work list.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section tool-turn-parity specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision tool-turn-parity`
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
`architect rehearse tool-turn-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze tool-turn-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse tool-turn-parity` — before the freeze, while
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
subsection per lane. A copy is written to build/I17-tool-turn-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tool-turn-parity prompt --append --lane <lane> --from build/I17-tool-turn-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I17-tool-turn-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tool-turn-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tool-turn-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tool-turn-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
