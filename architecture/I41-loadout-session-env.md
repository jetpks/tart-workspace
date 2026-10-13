# I41: loadout-session-env

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I41 loadout-session-env

Plan ENTRY 5 (`build/loop/plan-20261012T184702Z.md`, verbatim in the dispatch).
All measurements this session (2026-10-13) at base **9f8c8d7** (`project/pi-port`
tip, I40 model-catalog-polish merged — `git log --oneline -3` re-run at spec
time; working tree clean).

## 1. Control (this session, base 9f8c8d7)

- Suite: `777 runs, 3122 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip); `SEAM_BENCH_OK`.
- Parity cold: s1–s8 exit 0; s9 exit 0 **at the canonical out dir
  `tmp/parity-gate-s9`**. Environmental finding (recorded for the gates): a
  LONGER out-dir prefix (`tmp/i41-base-s9_startup_help`) moves the staged-path
  wrap points and produces exit 1 on one `unknown-candidate` wrap fragment —
  the I39/I40 judge-proven environmental artifact family (out-dir path length
  changes where the staged skills path hard-breaks). **Every frozen gate keeps
  the canonical short out paths (`tmp/parity-gate-sN`)**; nothing in this
  iteration may be blamed for out-dir-sensitive runs.
- The I32 request-capture oracle regenerated fresh this session
  (`tmp/i41-base-s8_zero_usage_compaction/run-1/pi-requests.jsonl` — request 1):
  pi wire tools `["read","bash","edit","write"]`, system role `system`,
  2,902 chars, no `<project_context>`/`<skills>`. tart's same-run capture:
  7 tools `["read","write","edit","bash","find","grep","ls"]`.

## 2. Item 1 — pi's loadout contract vs the port's standing superset

- **pi's default is FOUR tools, in ORDER**: `DEFAULT_TOOL_NAMES = ["read",
  "bash", "edit", "write"]` (settings-manager.ts:82). The order is load-bearing
  TWICE: the wire tools array and the prompt `<tools>` section both follow the
  RESOLVED defaultTools list — `_applyToolLoadout` iterates the active-name
  list in order (agent-session.ts:1571-1581) and `selectedTools =
  getActiveToolNames()` feeds the system prompt (:911, :2073). This session's
  capture confirms both: wire `["read","bash","edit","write"]`, `<tools>` rows
  in the same order.
- **defaultTools +/− semantics** (settings-manager.ts:104-133): plain names
  REPLACE the base; `+name`/`-name` apply in order; a list of only modifiers
  rides the inherited base (`mergeDefaultTools` :119-125). The port ALREADY
  implements these semantics (settings.rb:216-244, I10) — only the BASE list
  is wrong.
- **The port today**: `DEFAULT_TOOLS = %w[read write edit bash find grep ls]`
  (settings.rb:57-59, the "recorded divergence" comment); the wire order is
  `TOOL_CLASSES` order (registry.rb:53 `TOOL_CLASSES.slice(*selected)` —
  Hash#slice keeps the RECEIVER's order, not the selection's) → captured tart
  wire order `read,write,edit,bash,find,grep,ls`. Two divergences compound at
  default configuration: the SET (7 vs 4) and the ORDER (read,write,edit,bash
  vs pi's read,bash,edit,write — the `<rules>` bullet order follows the same
  list, so even the guideline ORDER diverges). The loadout-conditional rule
  bullet "Use bash for file operations like ls, rg, find" is ABSENT in the
  port's 7-tool composition (system_prompt.rb:141 gates on `!grep && !find &&
  !ls`) but PRESENT first in pi's captured `<rules>`.
- **This is a DELIBERATE behavior change toward BRIEF §8** (the plan letter
  says so; the spec freezes it): boot loses find/grep/ls from the DEFAULT
  loadout; the daily-driver escape hatch is `defaultTools` (`"+find"` appends,
  plain lists replace — the I10 machinery, unchanged); README's `defaultTools`
  row and `--help`'s Settings paragraph document the new default + hatch.
- **Blast radius (measured, this session):**
  - `test/settings_test.rb:378-380` pin the OLD base in two modifier tests
    (`["+mcp"]` → `%w[read write edit bash find grep ls mcp]`,
    `["-bash"]` → `%w[read write edit find grep ls]`) — re-pin to
    `%w[read bash edit write mcp]` / `%w[read edit write]`. :371 reads the
    constant itself (self-consistent); the plain-replace/merge pins
    (:373-:397) are base-independent and MUST NOT move.
  - NO test pins a 7-tool count or a wire tool order (grep over test/: only
    `tools.keys.sort` comparisons, tools_test.rb:94/:99).
  - The rig scripts ONLY bash/write/read tool calls (scenario inventory:
    s2 bash, s3 write+read, s4/s5 bash, s6 write/read, s7/s8 compaction,
    s1/s9 text — `ls /definitely-not-here-s4` is a bash COMMAND string, not
    the ls tool). No scenario stages `defaultTools` (grep clean); the runner's
    staged settings.json carries compaction keys only (runner.rb:236-239).
  - s8's token rows ride the `compaction-token-estimate` registry class
    (registry.yml:53-54, pattern `Compacted from [\d,]+ tokens`) — each app
    measures its OWN prompt+tools estimate, so tart's estimate moving with the
    smaller loadout stays sanctioned BY THE EXISTING CLASS; no registry edit.
  - `Tools::ALL` (tools.rb:32) documents the seven BUILT-INS (the registry's
    vocabulary, not the default loadout) — unchanged.
  - ENTRY 6 (e2e-session) plans multi-tool runs incl. grep/find — it will
    stage `defaultTools` itself; NOT this iteration's concern (noted so the
    e2e spec doesn't rediscover it).

## 3. Item 2 — pi's session-env exposure, enumerated from source

`resolveSpawnContext` (bash.ts:186-208) is the whole mechanism, called per
command execution:

```
env = { ...getShellEnv() };
delete env.PI_SESSION_ID;      // the five are scrubbed from the copy FIRST —
delete env.PI_SESSION_FILE;    // inherited parent values never leak, even
delete env.PI_PROVIDER;        // when exposure is OFF
delete env.PI_MODEL;
delete env.PI_REASONING_LEVEL;
if (exposeSessionEnvironment && ctx) {
  env.PI_SESSION_ID = ctx.sessionManager.getSessionId();          // always
  if (sessionFile) env.PI_SESSION_FILE = sessionFile;             // only when set
  if (model) { env.PI_PROVIDER = model.provider; env.PI_MODEL = model.id; }
  if (ctx.thinkingLevel) env.PI_REASONING_LEVEL = ctx.thinkingLevel;
}
```

- **Exactly FIVE vars.** `PI_SESSION_ID` (always, when exposing —
  SessionManager assigns an id even to non-persisting sessions,
  session-manager.ts:1058-1075); `PI_SESSION_FILE` (only when the session has
  a file — unset for ephemeral); `PI_PROVIDER` + `PI_MODEL` (only when a model
  is selected — the CATALOG provider key + model id, e.g. `fireworks`, not a
  wire slug); `PI_REASONING_LEVEL` (only when a level is set). Documented in
  pi's docs/environment-variables.md "Shell Tool Session Environment" table.
- **Resolved AT COMMAND START** — docs: "The values are resolved when each
  command starts. Switching models or changing the reasoning level therefore
  affects the next shell command without restarting." The readers must be
  LIVE, not boot-frozen.
- **`exposeSessionEnvironment` defaults true** (bash.ts:250) and has NO
  settings key (settings-schema grep clean) — pi's toggle is SDK-programmatic
  only (docs "Custom Shell Tools"); powershell.ts:30 mirrors it. The port
  gains NO settings toggle: exposure is always on where session state exists.
  The prompt-side coupling (bash.ts:257: the guideline bullet is emitted only
  when exposing) is therefore always-true in real runs — the port's
  unconditional bullet (system_prompt.rb TOOL_GUIDELINES, I32's %s-templated
  prefix) is the correct analog, unchanged.
- **User `!`/`!!` bash is EXCLUDED** (docs: "They are not injected into
  user-entered `!` or `!!` commands"; bash-executor.ts:48-100 passes no env —
  its operations default `env ?? getShellEnv()`, UNSCRUBBED even). The port's
  `run_user` shares `spawn_and_stream` with the tool path — the env
  composition must ride ONLY the tool's `execute` path; `run_user` keeps
  today's plain inheritance.
- **The base env**: pi composes from `getShellEnv()` (shell.ts:138-149) =
  process.env + pi's own bin dir prepended to PATH (its bundled shims). The
  port has no shim bin dir — itemized cut, zero effect beyond PATH contents.
- **Adjacent, NOT in this letter — the process markers** `AI_AGENT=pi` /
  `PI_CODING_AGENT=true` (cli/setup.ts:6-7, set on the PROCESS at CLI setup,
  inherited by every child): a model running `env` inside pi sees them; inside
  tart it would not. A different mechanism from bash-tool exposure; out of the
  plan letter's citations (bash.ts:47/:220-222). OQ-4 records the disposition
  question for the judge; NO work this iteration.
- **The port's seams today**: bash.rb spawns inheriting ENV (`Process.spawn`
  with no env option, bash.rb:172-174) — no session vars, no scrub. What the
  port already owns for the readers: `Agent::Loop` carries `identity:` +
  `thinking_level` (public reader, loop.rb:131) and holds `@recorder`
  (loop.rb:84, no reader); the recorder carries `id` + `path` (session.rb:
  360-378 — the SESSION_FILE source; the port's recorder is always
  persistent-shaped when present); the SURFACE tracks the runtime catalog
  entry (`@runtime_model` → `current_model_ref`, chat.rb:1869/:1903-1907 —
  the exact `ctx.model` analog: catalog provider + id, boot-cross-resolved,
  switch-live); print mode constructs NO recorder/session (I07 scope).

## 4. Item 3 — the print-mode identity tier (I32 verdict ruling 2)

`Print.run` constructs `Agent::Loop` WITHOUT identity (print.rb:41-44) → the
loop's `@identity` defaults to `Identity::DEFAULT` ("pi"), so the loop's env
tier (loop.rb:358-362, `Identity.env_key(@identity, "CONTEXT_WINDOW")`) reads
`PI_CONTEXT_WINDOW` on the print path REGARDLESS of the resolved face — tart/
foo print runs read the wrong namespace. The interactive path already threads
`identity:` (bin/tart:277). The print path resolves identity at bin/tart:206,
before `Print.run` (bin/tart:210-220) — the kwarg threads through unchanged
call shapes. Existing `Print.run` tests pass no identity (default holds).

## 5. The golden doctrine (I32) and this session's derivation

The loadout pin's golden is DERIVED FROM PI'S CAPTURE, never the port's own
output. This session's fresh capture (Grounds 1) yields pi's `<tools>` and
`<rules>` sections verbatim (the loadout-conditional bytes the pin freezes):

`<tools>`:
```
- read: Read file contents
- bash: Execute bash commands (ls, grep, find, etc.)
- edit: Make precise changes with exact text replacement, including multiple disjoint edits in one call
- write: Create or overwrite files

In addition to the tools above, you may have access to other custom tools depending on the project.
```

`<rules>` (the FULL list at the default-4 loadout — note the loadout-conditional
bullet FIRST and the per-tool guideline order read → bash → edit → write,
following DEFAULT_TOOL_NAMES):
```
- Use bash for file operations like ls, rg, find
- Use read to examine files instead of cat or sed.
- You can inspect PI_* environment variables for current model and session details.
- Use edit for precise changes (edits[].oldText must match exactly)
- When changing multiple separate locations in one file, use one edit call with multiple entries in edits[] instead of multiple edit calls
- Each edits[].oldText is matched against the original file, not after earlier edits are applied. Do not emit overlapping or nested edits. Merge nearby changes into one edit.
- Keep edits[].oldText as small as possible while still being unique in the file. Do not pad with large unchanged regions.
- Use write only for new files or complete rewrites.
- Be concise in your responses
- Show file paths clearly when working with files
```

tmp/ is gitignored — the pin inlines these bytes as literals with the
derivation recorded in the test/gate comment (the I32 precedent).

## 6. Design decisions (made by the plan letter + §8; alternatives for the judge)

- **OQ-1 — the WIRE tool-declaration order rides the loadout change.** The
  plan letter pins "the composed harness prompt's `<tools>` matches pi's";
  pi's wire array follows the SAME resolved list (Grounds 2), and the port's
  wire order today is TOOL_CLASSES order — divergent even at the same set.
  This spec pins the registry to preserve the SELECTED order (pi
  `_applyToolLoadout`'s rule), so wire + prompt + `<rules>` ordering all
  follow the resolved defaultTools list, at default AND under modifiers.
  Alternative (narrower): prompt-only parity, wire keeps TOOL_CLASSES order —
  rejected under §8 (the wire payload is model-visible), itemized here.
- **OQ-2 — `PI_PROVIDER`'s VALUE is the CATALOG provider key** (pi's
  `model.provider`: `fireworks`/`mock`), NOT the port's wire slug (`openai`).
  The readers therefore source the surface's `current_model_ref` (interactive)
  / the boot pair (print), not `chat.model.provider`. Alternative:
  `chat.model.provider` (mechanically simpler) — rejected: a staged
  `printenv PI_PROVIDER` would read `openai` where pi reads `mock`.
- **OQ-3 — print-mode SESSION_ID is a minted ephemeral id, SESSION_FILE
  unset.** The port's print mode records no session (standing I07 cut); pi's
  real print path DOES persist a session file (main.ts:448
  SessionManager.create, persist=true) — porting print-mode session RECORDING
  is out of this letter (scope creep); the honest analog of what the port has
  is pi's ephemeral session SHAPE (id set, file unset — SessionManager with
  persist=false). A SESSION_FILE pointing at a file that does not exist would
  be worse than the shape divergence. Reopen print recording as its own item
  if the owner wants pi-exact print sessions.
- **OQ-4 — the process markers (`AI_AGENT`/`PI_CODING_AGENT`) stay OUT.**
  Different mechanism (Grounds 3); queued disposition for the judge, no work.
- **The scrub is prefix-scoped** — pi deletes only its OWN five `PI_*` keys; a
  tart-mode port nested inside a real pi parent still sees the parent's
  `PI_*` (pi's exact rule; cross-identity scrubbing would be an invention).

## 7. Rig interplay (why no scenario edits)

The parity scenarios run tart in PI mode (I32 staging) → the exposure is
`PI_*`-prefixed inside staged runs; no scenario command reads env (Grounds 2
inventory); the runner's parent-env scrub already prevents parent
`PI_*`/`TART_*` leakage into staged panes (runner.rb:351-357). The staged
bash commands therefore settle byte-identically — s1–s9 exit 0 cold is the
regression bar, with NO rig file in the touch set. The loadout gate rides the
s1 request capture (tart-requests.jsonl, asserted against pi's captured
bytes); the env-exposure gate is a hermetic unit family on the bash tool
itself (no rig dependency).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section loadout-session-env specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision loadout-session-env`
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
`architect rehearse loadout-session-env` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze loadout-session-env` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse loadout-session-env` — before the freeze, while
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
subsection per lane. A copy is written to build/I41-loadout-session-env-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section loadout-session-env prompt --append --lane <lane> --from build/I41-loadout-session-env-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I41-loadout-session-env-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence loadout-session-env --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section loadout-session-env verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify loadout-session-env`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
