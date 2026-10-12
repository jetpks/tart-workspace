# I34: tool-pending-bg

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I34 tool-pending-bg

1. **The divergence (BRIEF §8 settled-screen program; the port half of the I26 rig finding).** pi renders the RUNNING tool call's block immediately, painted with the `toolPendingBg` background; tart enqueues nothing until `:tool_execution_end`, so mid-flight frames show no tool rows at all. Measured by the I26 rig lane (merged `fcf232f4`): `gems/tui-split-rig/bin/tool-pending-probe` + `scenarios/probe_tool_pending.yml` drive both apps through one slow bash call (`sleep 6`, mock LLM) and capture numbered frame pairs DURING the execution — 17 frames/app at 0.5 s cadence. Verbatim evidence (I26 rig report): pi mid-flight frames 02–12 show the `$ sleep 6` row with bg SGR `48;2;52;56;58` = #34383a (`toolPendingBg`, dark.json:36 okhsl(229 5% 24%)); raw styled bytes `` [1m[38;2;222;224;225m$ sleep 6[0m[48;2;52;56;58m `` (bold, fg #dee0e1 = `toolTitle`); tart mid-flight shows NO tool rows; both apps at settle show exactly one block, the row re-appearing under `48;2;37;65;49` = #254131 (`toolSuccessBg`). **The probe's frames are the spec** — the port must show the call row mid-flight under #34383a and exactly one settled block under the result bg.

2. **pi's mechanism (source-verified this session).** `ToolExecutionComponent` (packages/coding-agent/src/modes/interactive/components/tool-execution.ts) is constructed when the call first appears in the streamed message or at `:tool_execution_start` (interactive-mode.ts:3532, :3611) and added to the chat container immediately; `contentBox`/`contentText` are created with `theme.bg("toolPendingBg", …)` (:90-91). `updateDisplay()` (:271-277) picks the bg by state: `isPartial` → `toolPendingBg`, else `isError` → `toolErrorBg`, else `toolSuccessBg` — so mid-flight the block is the call rows alone (no result yet) under the pending bg; at `tool_execution_end` the SAME component mutates in place (`updateResult`, :3645-3652) — never a second block. Lifecycle: a `pendingTools` Map keyed by tool-call id; abort/error at `message_end` finalizes every pending component with the error text under `isError` (:3573-3586) — `stopReason === "aborted"` → `errorMessage = "Operation aborted"` (the retry-attempt variant is unreachable in the port: ruby_llm retries are Faraday-internal, the I11 CUT); `agent_end` clears the map (:3658-3666). pi's `tool_execution_update` (partial result streaming) has NO port analog — ruby_llm 2.1.0 exposes only `after_tool_result` — cut, itemized; irrelevant to the probe frames (call-row-only mid-flight).

3. **tart's current mechanism (source-verified this session, base `ecc6b2b`).** `lib/tart/render/chat.rb:413-421`: `:tool_execution_start` only records `@tool` (the footer border's `tool: <name>` detail, chat.rb:1310 — unchanged by this iteration); the block enqueues at `:tool_execution_end` through `@transcript_state.enqueue_tool_block` (lib/tart/render/transcript.rb:194-220 — the per-tool dispatch: bash → `BashBlock.bash_block_rows`, write/read → `FileBlocks`, generic → the `⎿` panel). The mid-tool draw path already exists: the kernel animates while busy and `render_frame` drains under the mutex (chat.rb:355-367) — a pending block pushed at start WILL paint.

4. **The in-place mutation precedent (I33 — read before designing).** `Transcript#set_tool_output_expanded` (transcript.rb:289-303) already rebuilds registered blocks in place: blocks register at drain time in ascending start order (`flush_scrollback`, :256-273, records `{start:, size:, builder:}`), and the walk threads the row DELTA so an earlier block's size change shifts every later block's start. The I33 verdict documents the stale-start latent this discipline cures — the pending→final replacement MUST follow it (replace at the recorded start, thread the delta to later registrations).

5. **The pending row shape (derived from the settled families — no new geometry).** Every settled block opens Spacer-blank (PLAIN — bash_block.rb:46 comment) + bg pad + call rows + … + bg pad. The pending variant is the same family truncated to the call: Spacer blank, `Panel.panel_blank_line(width, pending_bg)`, the family's CALL rows under the pending bg (bash: `$ <command>` — `Panel.padded_fg_rows(..., fg: toolTitle, modifiers: [:bold])`, the measured bytes; write: `write_call_rows`; read: `read_call_rows(args, width, false, bg:)`; generic: the wrapped `  ⎿ <name>` row over `ToolBlock.tool_line(name, nil)`), closing bg pad. No output rows, no `Took` row, no expand hint — nothing exists to show (pi renders renderCall only while `isPartial`).

6. **Facts that bound the design.** (a) The theme token exists: theme.rb:67 `tool_pending_bg: "#34383a"` — no theme work. (b) Tool execution is SEQUENTIAL in the port: ruby_llm 2.1.0 default `tool_concurrency = false` (gem configuration.rb:257; the port sets nothing) and the loop pairs start/end per-thread (loop.rb:495-511) — one pending block at a time; the machinery must still behave sanely if a second start arrives before a finalize (append fallback, documented). (c) The events already carry the full call on both edges (`tool_call:` with `.name`/`.arguments`; end adds `result:`/`duration:` — the frozen I17 contract) — no loop.rb changes. (d) Replay never sees mid-flight state: recorded sessions carry final results only, and `replay_entries` → `enqueue_tool_block` (transcript.rb:558-568) is the append path — it stays untouched and the pending machinery never engages on replay.

7. **Control (this session, base `ecc6b2b`).** Suite `606 runs, 2487 assertions, 0 failures, 0 errors, 1 skips` (the pre-existing live-env skip); `SEAM_BENCH_OK`. Scenario set s1–s9 present under `gems/tui-split-rig/scenarios/` — all exit 0 cold per the I31/I33 verdicts; these are the settled-bytes pins this iteration must not move. pi source at `repos/pi` (1.1.0) is the oracle for every shape claim above.

8. **Non-goals.** User-bash live streaming (the NEXT plan entry — `!`/`!!` chunks, a different component family); partial tool-result streaming (`tool_execution_update` — no gem seam); the compaction-summary panel port (s7 closed at I31); any change to settled block bytes, the footer, or the live region. No new registry classes are expected (the probe is a bespoke capture, not a diff-pipeline scenario); if one is genuinely forced, additions-only (the I26 discipline).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section tool-pending-bg specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision tool-pending-bg`
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
`architect rehearse tool-pending-bg` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze tool-pending-bg` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse tool-pending-bg` — before the freeze, while
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
subsection per lane. A copy is written to build/I34-tool-pending-bg-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tool-pending-bg prompt --append --lane <lane> --from build/I34-tool-pending-bg-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I34-tool-pending-bg-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tool-pending-bg --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tool-pending-bg verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tool-pending-bg`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
