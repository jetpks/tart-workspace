# I69: tart-identity-herdr

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 1 — iteration
`tart-identity-herdr`, repo `repos/tart`, ONE lane `core`. Base = tart
`project/pi-port` @ `3845f6a` (tip, CLEAN this session — `git status --short`
empty, `git diff | shasum` = the empty-tree sha `e3b0c442…`, no owner-state
swap needed; in sync with origin). Gem: fast-completions **0.5.0 published**
(pin-only Gemfile). Measured base suite THIS session (fresh):
**1211 runs / 5911 assertions / 0 failures / 0 errors / 1 skip, rake exit 0**
+ `SEAM_BENCH_OK` (bench exit 0). The oracle pin (`repos/pi` branch
`oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state` —
never re-performed from a lane; `env -u PI_PACKAGE_DIR` for every direct
oracle exec.

### The two owner rulings (2026-10-17, both live-proven)

1. **The default identity becomes tart.** After weeks of daily driving,
   tart's DEFAULT face is tart — `--identity pi` / `TART_IDENTITY=pi` remain
   the explicit pi-parity opt-in. This SUPERSEDES the BRIEF §8 identity-seam
   framing ("default `pi`", the parity-era indistinguishability ruling) for
   the DEFAULT only: pi-parity mode itself is untouched and byte-exact (the
   parity rig stages it explicitly already — Grounds "the rig audit" below).
   BRIEF §7 (the owner's daily driver) is the objective: the daily driver
   shows its own name.
2. **The OQ-5 "identical bytes" ruling is REVERSED.** tart reported as
   `source "herdr:pi"` / `agent "pi"` (lib/tart/herdr.rb `SOURCE`/`AGENT`),
   and herdr silently dropped every report: the pair is a RESERVED native
   integration (`repos/herdr/src/detect/mod.rs:330-348`
   `full_lifecycle_hook_authority` — `("herdr:pi", "pi")` and siblings) routed
   through a trust gauntlet (`src/terminal/state.rs:931`
   `route_full_lifecycle_hook_report`: stale-session, process-present, and
   session-anchoring checks a foreign reporter cannot pass). The GENERIC
   first-class interface — own source (NOT starting `herdr:`), own agent
   name — was live-proven this session to apply instantly:
   `source "tart"`/`agent "tart"` lit the pane up (`agent: tart`, working/
   idle/release all clean). The contract:
   `repos/herdr/docs/preview/website/src/content/docs/add-herdr-support.mdx`
   + `docs/socket-api.mdx:692` (`resume_argv` rules) + `src/app/api/panes.rs`
   (`handle_pane_report_agent` :1554, `handle_pane_report_agent_session`
   :1599, `report_agent_resume` — the pane-hold requirement).

### The identity seam today (lib/tart/identity.rb, 54 lines)

`DEFAULT = PI` (the flip: `DEFAULT = TART` — one constant); resolution order
CLI > `TART_IDENTITY` env > settings `"identity"` > default; the value is
FREE-FORM (I32); `ENV_KEY = "TART_IDENTITY"` stays literal (bootstrap: the
identity key cannot depend on its own output); `ORACLE_VERSION = "1.1.0"`
(pi-mode's logo line renders it; tart-mode renders `Tart::VERSION`) — **KEEP,
do not delete**. The env namespace follows the identity
(`env_key("pi","API_KEY") == "PI_API_KEY"`). The face dispatch:
`lib/tart/render/chat.rb:829` — `@identity == Identity::PI ?
Motd.pi_header_lines : Motd.tart_header_lines` — identity-only; NO motd.rb
change is needed for the flip. `bin/tart` help text carries three
default-naming rows (the `--identity` flag row "default pi" :70/:199-200, the
`TART_IDENTITY` env row "pi (default)" :172-173).

### The herdr reporter today (lib/tart/herdr.rb, 264 lines)

Port of `~/.pi/agent/extensions/herdr-agent-state.ts` (HERDR_INTEGRATION_
VERSION 9). Today: `SOURCE = "herdr:pi"`, `AGENT = "pi"`; the seq base
`Time.now.to_i * 1000` ≈ 1.79×10¹² — **WRONG SCALE**: pi's v9 uses
`Date.now() * 1000` ≈ 1.79×10¹⁵ (epoch-MS × 1000; the existing
`epoch_ms` helper × 1000 reproduces it). The OQ-5 header comment ("identical
bytes keep the owner's panes working") is REVERSED by Grounds ruling 2 —
rewrite it citing the plan. The reporter is REGISTERED IN BOTH MODES
(`bin/tart:291` print, `bin/tart:423` interactive; identity-blind), env-gated
(`HERDR_ENV == "1" && HERDR_SOCKET_PATH && HERDR_PANE_ID`; off → registers
nothing), TUI-rooted (print mode roots nothing), failures swallowed, state
reports coalesce latest-wins, session reports FIFO, one retry. pi's v9
reference: seq `Date.now() * 1000`, +1 per report; sends the session ref as
path-OR-id (tart sends BOTH today — kept, herdr accepts both:
`session_ref_from_report`); pi does NOT send `resume_argv` — **tart goes
further** per the plan. pi's v9 does NOT send `pane.release_agent` either
(herdr's idle-prompt safety net clears on exit).

### The herdr resume contract (frozen law, cited)

From add-herdr-support.mdx + socket-api.mdx:692 + panes.rs: `resume_argv` =
the command that reopens the current session; first element a PLAIN command
name on PATH (not a path); ≤64 elements, ≤8KiB total; NO element may contain
an apostrophe or control char — **an invalid argv fails the WHOLE report**
(`validate_optional_resume_argv` runs BEFORE the state event in both
handlers: panes.rs:1561-1563/:1603-1605 — so a poisoned argv must never be
attached); the reporter must HOLD the pane first (a state report with
`pane.report_agent` before or along with the command, else
`resume_not_accepted`); the command is kept only while the same source+agent
hold the pane. tart's resume CLI: `bin/tart` `-r, --resume [ID]` — "ID is a
session id or session-file path" (:68/:194-196). The frozen argv shape:
**`["tart", "-r", <agent_session_id>]`** (uuid ids are apostrophe-free;
fallback `<agent_session_path>` when no id), attached to every report that
carries a session ref (both `pane.report_agent_session` and ref-carrying
`pane.report_agent`), built ONLY when the arg passes herdr's validation
predicate — else attach NOTHING, never poison the report. herdr reopens the
pane in the same directory, so no workdir arg. `--seq` per-source
monotonic: `hook_report_is_newer` ignores non-higher seqs; the fresh
source `"tart"` starts clean (the dead `"herdr:pi"` seqs do not carry over).

### The live-probe record (tmp/probe-herdr/, built 2026-10-17 — gate machinery, REUSE)

`listener.rb` (fake herdr UNIX socket: accept-loop thread, appends
`<ts> <line>` to `received.log`, replies one byte per request),
`mock.rb` (MockLLMServer from `test/support`), `boot.sh`/`hold.sh`
(staged-HOME tmux boot). `received.log` holds tart's exact CURRENT wire
bytes — well-formed, connected, correct events:
`pane.report_agent_session` (startup, session_start_source) then
`pane.report_agent` (idle) with `source "herdr:pi"`, `agent "pi"`, seq
`1792261430001` (the wrong ~10¹² scale visible in the bytes), both
`agent_session_path` + `agent_session_id`. The lane's live gate
(`herdr-wire-probe`) reuses this machinery as a rig bin: listener + one
mock-driven tart boot (Runner, app: "tart", a Hash-built Scenario — the
render-perf-probe precedent, NO yaml content edit) + received-bytes asserts.

### The rig audit (measured — no scenario path rides the app default)

`gems/tui-split-rig/lib/tui_split_rig/runner.rb:535`:
`identity = @scenario.env.fetch("tart", {}).fetch("TART_IDENTITY", "pi")` —
the runner stages `TART_IDENTITY` EXPLICITLY on EVERY path (the fetch
default fills pi; `s1_tart.yml` stages `tart`); all three probe bins
(tool-pending, user-bash-stream, render-perf) drive the SAME Runner; the
parity scenario pins live at `gems/tui-split-rig/test/scenario_test.rb:399-417`
(the composed command carries `TART_IDENTITY=pi` / `=tart`). So after the
flip no rig path rides the app default — the runner OWNS the explicit
staging. The gap the lane pins: a scenario env override can stage a BLANK or
NIL identity (`env.tart.TART_IDENTITY: ""`), which composes through to the
pane command (`TART_IDENTITY=''` + a blank `_MODEL=` namespace — measured
this session via the rig-identity-assert probe) and aborts the boot. The
pin: the runner REFUSES loudly (raise `TuiSplitRig::Error`) on a blank/nil
staged identity — parity scenarios always carry an explicit identity.

### The flip's test blast radius (audited this session, file by file)

Every test that boots the REAL app staging `PI_*` env WITHOUT an identity
(clean-aborts at the lane) or resolves env/namespace via the DEFAULT
identity (reads the wrong keys at the lane) — the declared moves, all inside
the touch set's test files:
- `test/launcher_smoke_test.rb` — `smoke_env` (PI_API_KEY/PI_API_BASE,
  :262-268), `wire_env` (:271-280 + the PI_* nil-scrubs), the footer-window
  test's `ENV["PI_CONTEXT_WINDOW"]` (:409).
- `test/e2e_session_test.rb` — `tart_env` (:249-250).
- `test/subagents_e2e_test.rb` — the parent env stagings (:395-397, :409-410)
  and the child-env assertions (:783-784).
- `test/settings_test.rb` — the resolution pin `Identity.resolve(settings:
  {}, env: {}) == "pi"` (:208) + the default-key comment (:229).
- `test/models_test.rb` — `resolve_boot_model` env-tier legs without explicit
  identity (:213-223).
- `test/shapes_test.rb` — same (:204-208).
- `test/agent_loop_test.rb` — the env-tier compaction pin staging
  `ENV["PI_CONTEXT_WINDOW"]` through a DEFAULT-identity Loop (:1045).
- `test/herdr_test.rb` — the byte pins: `id.start_with?("herdr:pi:session:")`
  (:60), `source "herdr:pi"` (:63), agent "pi" (:64).
- `test/identity_test.rb` — new default-face pins land here.
Explicit-identity tests (subagents_test `new_manager` passes
`identity: "pi"`; bash_tool_test/env_tool explicit; chat_test's tart-mode
catalog test) are UNAFFECTED — audited, not in the move list.

### Environment / ops facts (measured this session)

- The **s9 wrap law** (measured from the retained I68 lane captures,
  `build/I68-markdown-parity-core/wt/tmp/i68s9/run-1/*.capture`): the staged
  AGENTS.md context row = `  ` + `<tree>/<outdir>/run-1/sandbox/tart/AGENTS.md`
  → **row = len(tree) + len(outdir) + 32**, and `Motd#wrap_resource_row`
  fires at **> 120**. Evidence: I67 lane tree 80 + `tmp/i67-s9` (10) → 122 →
  the wrap class FAILED (I67 verdict, judge-adjudicated); I68 lane tree 79 +
  `tmp/i68s9` (9) → exactly 120 → GREEN at the lane tree. The I69 lane tree is
  **83 chars** (`build/I69-tart-identity-herdr-core/wt`), so s9's out dir is
  `t69s9` (5 chars → row exactly 120, no wrap) and every other scenario's
  out dir `t69sN` (6) keeps the total sandbox-path class at 89 < the
  I67-proven-green 90. The judge recomputes this geometry if the provisioned
  tree ever differs from 83.
- The spec session runs INSIDE a herdr pane (6 HERDR_* vars) — every gate
  command that boots tart or the rig carries the standing
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
  -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID` scrub (the frozen gate forms all
  do).
- `architect` CLI calls from bundle-exec'd tart sessions need the full scrub
  (`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE
  -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`) —
  the child-env-scrub ENTRY is a SEPARATE iteration (plan ENTRY 5).
- I68 preserved artifacts (consumed by the plan's ENTRY 4
  markdown-parity-revisit, do not clean): `build/I68-markdown-parity-core/
  lane-core.diff`, the retained worktree `build/I68-markdown-parity-core/wt`,
  `tmp/i68-spec/markdown_battery.json` (sha `4ecd9cc2…`).

### Prior handoffs

`notes/spec-digest-20261017T083354Z.md` (I68): carry audit BEFORE every
rehearsal; gates GENERATED from the previous frozen block; declare every
rebase in the AC preamble; the MEASURED at-base vector beats prediction;
short scenario out dirs; the owner-state swap protocol applies only if an
owner diff exists (it does not at 3845f6a). The I68 markdown-battery gates
(4 + the I68 scope rewrite) are NOT carried here: the I68 lane was KILLED,
the battery never landed, and `lib/tart/render/markdown.rb` is outside this
lane's touch set — ENTRY 4 (`markdown-parity-revisit`) re-freezes them with
the O(n) delimiter guard. Standing I67 fixes that ARE carried: the
wire-delta tools-sha constant `…758831…` (the corrected value) and the
short-out-dir discipline.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section tart-identity-herdr specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision tart-identity-herdr`
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
`architect rehearse tart-identity-herdr` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze tart-identity-herdr` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse tart-identity-herdr` — before the freeze, while
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
subsection per lane. A copy is written to build/I69-tart-identity-herdr-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tart-identity-herdr prompt --append --lane <lane> --from build/I69-tart-identity-herdr-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I69-tart-identity-herdr-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tart-identity-herdr --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tart-identity-herdr verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tart-identity-herdr`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
