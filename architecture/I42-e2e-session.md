# I42: e2e-session

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I42 e2e-session

Plan ENTRY 6 (`build/loop/plan-20261012T184702Z.md`, verbatim in the
dispatch; the coordinator addendum's binding context folded in). All
measurements and probes this session (2026-10-12/13) at base **d1a4209**
(`project/pi-port` tip, I41 loadout-session-env merged — `git log --oneline
-3` re-run at spec time; working tree clean). Probes live in the space's
`tmp/` (`i42-probe1-print-recorder.rb` retired — see §3; `i42-probe1b-headless-compaction.rb`,
`i42-probe2-space-launcher.rb`, `i42-probe2b-print-cwd.rb` stand as the
record; tmp/ is gitignored, the findings are transcribed here).

## 1. Control (this session, base d1a4209)

- Suite: `790 runs, 3161 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip); `SEAM_BENCH_OK`.
- Parity spot-cold at the CANONICAL out dirs: s1_text_turn, s7_compaction,
  s8_zero_usage_compaction all exit 0. The remaining scenarios are the I41
  judge's fresh-session cold record: 16/16 gates PASS on this exact tip
  (verdict ee2e2bfb, decisions log 2026-10-13). Environmental carry-in
  (I41 Grounds 1): every frozen gate keeps the canonical SHORT out paths —
  long out-dir prefixes are path-length artifacts, not evidence.

## 2. The letter's machinery vs the port today (three measured gaps)

The plan letter demands "a print-mode run over a scripted multi-tool
scenario against THIS space …, then a `--resume` continuation asserting the
recorded context lands, then a long-run compaction pass … asserting the
compaction entry records and usage drops." Three port gaps block exactly
that, all measured this session:

- **Gap 1 — print runs record nothing.** Probe 2 (the REAL launcher:
  `bin/tart -p` as a subprocess, cwd = the real space root, staged HOME,
  MockLLMServer via the `PI_API_BASE` env seam): exit 0, final response on
  stdout, the `read` tool round-trips REAL bytes (repos/tart/README.md,
  first line `# tart` in the captured tool result), 2 requests — and the
  staged `~/.tart/sessions` tree is EMPTY. `Print.run` accepts no
  `recorder:` (ArgumentError, probe 1) and `bin/tart`'s print path
  constructs none (print.rb:41-58). pi's print mode RECORDS by default —
  `main.ts:447-448` `SessionManager.create(cwd, sessionDir, …)`, persist;
  only `--no-session` opts out (`main.ts:361-363` inMemory). The port's
  standing I07 cut ("print mode constructs NO recorder") was RE-AFFIRMED at
  I41 OQ-3 with its own reopener: "print recording reopens as its own item
  only on owner demand" — the plan letter's `--resume` leg IS that demand
  (nothing to resume without a recording).
- **Gap 2 — `--resume` refuses print mode.** `bin/tart:206` aborts
  `tart: --resume is interactive-only (--print runs single-shot).`
  (reproduced this session, exit 1). pi resolves `--resume` in
  `createSessionManager` BEFORE the mode split (`main.ts:415-431`
  `SessionManager.open`), so `pi --resume <id> -p "…"` runs the resumed
  session headless and the print run continues it.
- **Gap 3 — a resumed file is not self-contained.** The port's resume model
  (I15, ruled) is pi's FORK shape: a NEW file whose header carries
  `parentSession`. But pi's `forkFrom` COPIES the source's non-header
  entries into the new file (`session-manager.ts:1847-1853`, the appendFileSync
  loop); the port's `Recorder.new(parent_session:)` writes ONLY the header
  (session.rb:369-378). Measured: parent file entries
  `[session, message, message]` → resumed recorder `@entries` = header
  only → `Session.context_messages(resumed.path)` = `[]`. Seed messages are
  added to the CHAT (loop.rb:103) but never re-recorded, so a SECOND resume
  hop silently drops the first hop's context — the e2e's long-run leg
  (resume → more turns → resume again → compact) cannot compose honestly
  without the copy.

## 3. The instrument's proven primitives (what already works at base)

- **The headless compaction machinery is COMPLETE below Print.run.** Probe
  1b (exactly what `Print.run` does internally — `Core::Loop` over a null
  terminal session, `Agent::Loop` with `recorder:` + `context_window: 12` +
  zeroed compaction knobs, two scripted responses: turn + summarization):
  entries land `[session, message, message, compaction]`, the compaction
  entry carries `tokensBefore: 15`, and a re-seed via
  `Session.context_messages` yields `[user(summary), assistant]` with the
  `compacted into the following summary` marker present — the summarization
  call's worker bridge works on the print path's reactor. The ONLY missing
  wiring is `Print.run`'s kwargs + `bin/tart`'s construction (Gap 1).
- **The trigger lever is the rig's s7/s8 seam, already proven both sides**:
  `<PREFIX>_CONTEXT_WINDOW` env (the loop's env tier, loop.rb:358-366 — the
  e2e stages `PI_CONTEXT_WINDOW=10`) + staged-HOME settings
  `compaction {enabled, reserveTokens: 0, keepRecentTokens: 0}` (the knobs
  MUST reach the loop: `bin/tart`'s interactive path passes
  `compaction: Settings.compaction_kwargs(settings)` at :283 — the print
  path passes NOTHING today, and the loop's built-in keepRecent 20000 would
  keep the whole tail and refuse to compact). The mock reports
  `usage {prompt_tokens: 10, …}` on every response by default
  (mock_llm_server.rb respond_message/respond_stream), so window 10 fires
  the Case-direct trigger deterministically (I29's structure).
- **The env seam drives the real launcher hermetically** (probe 2 +
  launcher_smoke_test): staged `HOME`, `PI_API_KEY`, `PI_API_BASE`,
  absent `TART_MCP_CONFIG`; gems resolve from the ruby's gem home (no
  BUNDLE_* needed — the rig's verified staging note, runner.rb:326-330).
  `Settings.load(cwd: <space>)` reads only `<space>/.tart/settings.json`
  (absent — the space carries no .tart); skills/context-files discovery at
  the space root finds nothing (no AGENTS.md/CLAUDE.md/.tart there) — the
  space is a clean cwd for a staged run.
- **The I41 loadout interplay (coordinator addendum 2)**: boot now ships
  pi's default-4; the e2e's grep/find turns require the documented escape
  hatch — the staged HOME's `settings.json` carries `defaultTools:
  ["read","bash","edit","write","find","grep","ls"]` (the exact full-7
  restore the I41 README row documents; no repo change). I41's session-env
  exposure rides FREE in the e2e's bash turn: `printenv PI_SESSION_ID` /
  `PI_SESSION_FILE` — with Gap 1 fixed these become recorder-backed (pi's
  shape when a file exists, bash.ts:196-197), retiring I41's minted-
  ephemeral print readers (print.rb's `print_session_env`,
  bin/tart:529-540) whose own comment ties them to the recording cut.
- **"On this very space" resolution**: from the tart checkout (suite,
  rehearsal, judge gates — `cwd: repos/tart`) the space root is the main
  checkout's parent; from a LANE WORKTREE the space root resolves through
  `git rev-parse --git-common-dir` (the worktree's git dir points back at
  `repos/tart/.git`). Validated by markers (a `repos/tart` child + a
  `space.yaml`/`architecture/` entry); when absent (a standalone fresh
  clone of the repo) the instrument falls back to the CHECKOUT ROOT itself
  as the session cwd — still real files, still no fixtures — and PRINTS the
  chosen root (the gate output records it). Scratch targets always live
  under `<root>/tmp/` (gitignored both places).

## 4. What the e2e asserts, leg by leg (the frozen contract preview)

Leg A (multi-tool, real space): 6 scripted tool turns — `read`
(lib/tart/agent/loop.rb, a must-not-touch file → stable first lines),
`grep` (pattern `SEAM_BENCH_OK` under repos/tart/bench), `find`
(`*.rb` under repos/tart/lib/tart/tools), `bash` (`pwd` + `printenv
PI_SESSION_ID` + `printenv PI_SESSION_FILE`), `edit` + `write` (targets
pre-staged by the TEST under `<root>/tmp/i42-e2e-<token>/`) — then the
final text. 7 requests. Asserts: exit 0, final response on stdout, the
scratch edit/write landed, the session JSONL recorded (header + the
message entries), the bash turn's result names the space root and the
session id/file matches the recorded session.
Leg B (`--resume <id>`): 1 request; the payload carries A's recorded turns
(user → tool round-trips → final) ahead of the new prompt (the I07
MockLLM payload-proof pattern); the new file's header parentSession links
A; its entries now INCLUDE the copied lineage (Gap 3 fix).
Leg C (long-run compaction, resume by PATH): staged window 10 + zeroed
knobs; 2 requests (turn + summarization); the file gains a compaction
entry (tokensBefore ≥ 10).
Leg C2 (compacted re-resume, `--resume` with NO id = most-recent): 1
request; the payload carries the summary marker, does NOT carry A's first
prompt, and its serialized message list is SMALLER than leg C's first
request (the usage-drop proof).

## 5. Design decisions (the plan letter + §8; alternatives for the judge)

- **OQ-1 — print-mode recording + print `--resume` are IN (the letter
  demands them).** Alternative: keep the I07 cut, prove resume at library
  level only (`Print.run(seed_messages:)` without CLI recording) —
  rejected: the letter names `--resume` explicitly ("runnable via
  `-p`/`--resume`", backlog item 4) and pi's print mode records; the I41
  OQ-3 ruling's own reopener clause covers this. Scope stays the kwarg
  passthrough + bin/tart wiring (probe-proven small); print-mode
  MULTI-prompt runs (pi's `messages` array) and `--no-session` stay OUT
  (itemized cuts — the port's `-p` is single-prompt; recording is
  always-on like the interactive default).
- **OQ-2 — the fork entry copy is IN-LANE.** pi's forkFrom copies
  (session-manager.ts:1847-1853); the port's fork does not — a latent
  incompleteness since I07 that this instrument surfaces (Gap 3), ~10 lines
  in `Recorder#initialize` + ONE stale pin re-pin (session_test.rb:139-144,
  whose comment "prior turns are not re-recorded" documents the old shape).
  Alternative: judge-note only, legs re-anchored on leg A's file (leg C
  resumes A, silently dropping B's turn) — rejected: it papers over a real
  defect with the instrument watching.
- **OQ-3 — print resume follows the PORT'S resume model (fork), not pi's
  append-in-place `--resume`.** pi's `--resume` opens the SAME file and
  appends (SessionManager.open); the port's I15-ruled resume lands a new
  parent-linked file everywhere (interactive picker, CLI, /resume). The
  print path joins the PORT'S one landing (consistency; the deviation is
  standing, itemized here). With OQ-2's copy the fork is content-complete,
  which is pi's own fork contract.
- **OQ-4 — the space-root fallback (checkout root) over strict abort.**
  The gate must exit 0 cold on ANY fresh clone of the worktree; the letter's
  "this very space" holds wherever the space exists (suite, rehearsal,
  judge, builder worktrees — all under the space). The fallback keeps the
  instrument honest (real files either way) and VISIBLE (the test prints
  the resolved root; the gate output carries it).
- **`print_session_env` retires the minted-ephemeral readers** — with a
  recorder, SESSION_ID/SESSION_FILE become live recorder readers (pi's
  exposure when a session file exists); PROVIDER/MODEL/REASONING_LEVEL
  unchanged (the boot pair + level). No existing pin breaks (the hermetic
  I41 family pins the TOOL, not print's composition — grep clean).

## 6. Blast radius (measured)

- `test/session_test.rb:139-144` — the ONE stale pin (OQ-2's re-pin; the
  resumed-file entry enumeration gains the copied lineage; the
  request-payload assertions above it are copy-neutral — seeds still come
  from the parent's context_messages).
- `test/print_test.rb` — additive recording/resume pins; the six existing
  Print.run tests pass no recorder (nil default holds them green).
- README Sessions/Print-mode paragraphs rewrite (recording on, `-p -r`,
  the env lever); `bin/tart` usage text loses nothing (the `-r` row never
  claimed interactive-only; the abort at :206 goes).
- NO rig file, NO test/support file, NO loop.rb/compaction.rb/settings.rb
  edit — the e2e exercises them as-is (probe 1b is the evidence the loop
  needs nothing). `gems/tui-split-rig/**`, `bench/**`, `*.gemspec`,
  `Gemfile*` frozen.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section e2e-session specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision e2e-session`
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
`architect rehearse e2e-session` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze e2e-session` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse e2e-session` — before the freeze, while
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
subsection per lane. A copy is written to build/I42-e2e-session-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section e2e-session prompt --append --lane <lane> --from build/I42-e2e-session-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I42-e2e-session-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence e2e-session --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section e2e-session verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify e2e-session`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
