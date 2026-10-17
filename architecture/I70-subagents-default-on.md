# I70: subagents-default-on

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

Plan `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 2 — iteration
`subagents-default-on`, repo `repos/tart`, ONE lane `core`. Base = tart
`project/pi-port` @ **2a33f66** (the I69-integrated tip; `git status
--short` EMPTY this session, clean tree, no owner-state swap needed).
Gem: fast-completions 0.5.0 (pin-only). **Measured base suite THIS session
(fresh): 1219 runs / 5948 assertions / 0 failures / 0 errors / 1 skip, rake
exit 0 + `SEAM_BENCH_OK`** (bench exit 0). The oracle pin (`repos/pi`
branch `oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by
`oracle-pin-state` — never re-performed from a lane; `env -u PI_PACKAGE_DIR`
for every direct oracle exec. Landing is the human's. Routing rides
`architect.yaml` as-is; the model-window tick stays DEAD.

### The defect and the two rulings

**The crash (reproduced live this session at 2a33f66).** The owner's
2026-10-17 live case: settings `{"subagents": true}` → boot dies. Re-run
this session (staged HOME, staged settings, mock provider, identity `pi`):
`NoMethodError: undefined method 'start_with?' for nil` at
`lib/tart/render/motd.rb:306` (`under?`) ← `scope_group` :299 ←
`prompt_scope_entries` :317 ← `sections` :282 ← chat.rb:845/:807/:448
(`render_frame`) ← loop.rb:354 (`draw_frame`) — the FIRST frame kills the
process. Trace preserved at `tmp/probe-subag/tart.stderr`. The chain: the
six workflow templates ship with `file_path: nil`
(`lib/tart/subagents/workflows.rb` — programmatic by design, I49 Spec §7),
and motd's prompt scope path classifies by PATH
(`prompt_scope_entries` → `scope_group` → `under?`), so a nil path crashes.
The NEXT crash behind it: `scope_group_rows` :331 `sort_by { |entry|
entry[:path] }` — also nil. The cure must cover the WHOLE prompt-scope
section, not just the first nil deref.

**The owner ruling (2026-10-17):** subagents on by default, after an
interactive test-drive in a functional state. **The architect ruling
(recorded in the plan, binding here):** the crash fix and the default flip
land in the SAME iteration, behind e2e gates that prove the functional
state; the owner's interactive test-drive is the named POST-INTEGRATION
checkpoint; the verdict documents the one-line revert (settings/env
opt-out) as the safety path if live pain surfaces — the loop cannot block
on human presence without dying.

### The oracle (live capture this session, hermetic)

pi-subagents ships its prompts as REAL .md files: the npm package manifest
(`~/.pi/agent/npm/node_modules/pi-subagents/package.json` `"pi": {"prompts":
["./prompts"]}`) → pi's package-manager loads them as user-scope package
resources (`repos/pi/packages/coding-agent/src/core/package-manager.ts`
:2126-2134 the user-scope npm install path; `resource-loader.ts` :864-883
the sourceInfo lookup) → sourceInfo `{source: "npm:pi-subagents", scope:
"user"}`. pi therefore NEVER has a path-less template; and pi's grouping is
sourceInfo-based (`interactive-mode.ts` `getScopeGroup` :1610-1619 —
missing metadata degrades gracefully to project), with a PACKAGE tier
(`isPackageSource` :1613-1617, `npm:`/`git:` prefixes) rendered by
`buildScopeGroups` :1624-1659 + `formatScopeGroups` :1661-1693: group label
row (2-space indent, accent), then plain path members (4-space, dim,
path-sorted), then package sub-lists (label row 4-space mdLink, then
6-space dim item rows, both localeCompare-sorted).

**Live MOTD [Prompts] capture (this session, `tmp/probe-subag/`):** the
pinned oracle clone booted in tmux (staged HOME, staged agent dir with
`settings.json {"theme":"dark","packages":["npm:pi-subagents"]}` +
symlinked installed pi-subagents package, mock provider, `PI_OFFLINE=1`,
`PI_PACKAGE_DIR` scrubbed). Owner-environment facts: no
`~/.pi/agent/prompts` dir exists; `pi-web-access` and the git `pi-extensions`
package ship no prompts — the owner's live pi [Prompts] section is EXACTLY
the six pi-subagents templates. Captured bytes (collapsed, then expanded
after ctrl+o):

```
[Prompts]
  /council, /gather-context-and-clarify, /parallel-cleanup, /parallel-research, /parallel-review,
/review-loop
```

```
[Prompts]
  user
    npm:pi-subagents
      /council
      /gather-context-and-clarify
      /parallel-cleanup
      /parallel-research
      /parallel-review
      /review-loop
```

Styled capture (`-e`): the group label `user` renders `38;2;167;152;215`
(accent `#a798d7`), the package label `npm:pi-subagents`
`38;2;105;173;208` (mdLink `#69add0` = the port's `Theme[:md_link]`,
theme.rb:86), every `/name` row `38;2;126;136;142` (dim `#7e888e`); the
indents ride OUTSIDE the SGR runs (two-run label rows; the whole entry row
inside one dim run). The port already owns all three tokens. pi's [Skills]
section renders the same package tier (`skills/council-mode/SKILL.md` rows)
— shared machinery, one shape.

### tart today (the seams, base 2a33f66)

- `lib/tart/subagents/workflows.rb` — six `Prompts::Template.new` with
  `file_path: nil`, descriptions/argument-hints byte-carried from
  pi-subagents 0.77.0 (pinned at `test/subagents_intercom_test.rb`
  :574-648 incl. `merge_workflow_templates` lowest-tier + user-wins).
- `lib/tart/prompts.rb` — the `Template` struct
  (name/description/argument_hint/content/file_path); every FILE load is
  file-backed (load_template_file always sets `file_path:`) — **nil
  file_path ⇒ the builtin workflow tier, exclusively** (the classification
  is total, no other producer). `lib/tart/prompts.rb`/`skills.rb` are
  frozen seams OUTSIDE this lane's touch set.
- `lib/tart/render/motd.rb` — `prompt_scope_entries` :316-321 (entry
  `{path:, display: "/<name>", group:}`), `scope_group` :298-306 (path
  classification: project/user/path), `scope_group_rows` :327-346 (group
  order project → user → path, label rows accent, entries dim path-sorted,
  every row through `wrap_resource_row`). NO package tier today.
- `lib/tart/settings.rb` — `DEFAULTS["subagents"] => false` :65 (the one
  literal to flip), `RESOLUTION_ENV["subagents"] => "SUBAGENTS"` :94,
  `resolve_setting` :163-165 (env > file > default, RAW env values).
  `bin/tart` :606-608 `subagents_enabled?` (true/"true"/"1" = on, anything
  else = off — the env tier already speaks the opt-out).
- `bin/tart` — three gate call sites, mechanics unchanged by the flip:
  :295 print-mode register, :381-384 the interactive workflow-templates
  merge (before build_surface), :431-437 the interactive register
  (kernel bridge + endpoint). Comments describe the default-off
  zero-byte invariant — they move with the flip (help text has NO
  subagents row today; none is added).
- `lib/tart/subagents/manager.rb` :369-380 — I69's cured `child_env` (the
  literal `TART_IDENTITY` bootstrap key): children spawn correctly; the
  child env is CLOSED with no subagents gate row (children never nest,
  I48 AC4). NOT touched this iteration.
- The I48/I49 e2e machinery (`test/subagents_e2e_test.rb`): legs A-D
  (foreground round-trip, async + notify + print-parent drain, steer
  receipt, stop) staging `{"subagents": true}` + staged
  `<IDENTITY>_SUBAGENTS_HOME` + closed env + explicit `TART_IDENTITY=pi`;
  MockLLMServer + real `bin/tart -p` subprocess parents.

### Measured wire facts (this session, base 2a33f66, staged-HOME print boots)

- **OFF** (staged `{"subagents": false}`, default 4-tool loadout): tools
  array digest `7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707`
  — byte-identical to the standing wire-delta constant (the tools array is
  env/path-independent). **ON** (`{"subagents": true}`): digest
  `2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88`,
  names `["read", "bash", "edit", "write", "subagent"]` — the subagent tool
  declared LAST (the I47 merge order). The instruction (system-prompt)
  digest is IDENTICAL off vs on in the same staged env
  (`1435dd80…` both) — the tool registration moves ONLY the tools array.
- Print-mode boots with the gate on exit 0 (measured) — print never
  renders the MOTD, so the crash is interactive-only.

### The rig law (the parity surface and the flip)

The parity scenarios stage tart with NO subagents row today (the rig's
`stage_tart_home` writes settings.json ONLY for the context_window
compaction scenarios s7/s8, runner.rb:359-363). Post-flip, every default
boot registers the tool + renders the [Prompts] section while the staged
pi side (no packages) shows NEITHER — the s-family, wire-delta, and
zai-max-tokens-wire gates would fail BY DEFAULT. The I69 explicit-staging
ruling is the law: **the runner OWNS explicit staging; no parity path
rides the app default.** The cure: `stage_tart_home` writes settings.json
ALWAYS, carrying `"subagents" => false` (the explicit opt-out — the parity
target remains staged-pi vs tart-opted-out, the I48-off shape); the
compaction rows still ride only the context_window scenarios;
`stage_memory`'s deep-merge (runner.rb:462) composes with the row
unchanged. The default-ON shape is proven by NEW gates, not by the parity
scenarios (the owner's live pi-subagents-vs-tart parity is the
post-integration interactive test-drive's domain, not rig-observable — the
rig's pi is the pinned package-less clone).

### The flip's blast radius (audited this session)

- Pins that MOVE (the default flips): `test/settings_test.rb` :83-88 (the
  DEFAULTS row + the no-file default-tier resolution) and :91+ (the
  known-key load's default tier); `test/subagents_test.rb` :102 (the
  DEFAULTS row) and :105-108 (the "off = no tool" pin re-words to the
  opt-out shape — the mechanics are the register call, unchanged).
- Boots default-on post-flip, audited GREEN at base with the gate on:
  `launcher_smoke_test` (print boot exit 0 — measured), `e2e_session_test`
  (tools presence assertions only, :140-141; the drain no-ops with no
  runs; staged HOME hermetic), `subagents_e2e_test` legs A-D (stage
  `true` explicitly — the opt-in tier unchanged), the rig s-family
  (protected by the R3 staging).
- NO other file pins the default (grep `"subagents"` across test/lib/bin:
  the full enumeration is settings.rb, bin/tart, the subagents module, the
  tests named above). In-process registry/loop tests build their own
  loadouts — identity-blind to the default.

### Environment / ops facts (measured this session)

- The lane tree is predicted at **84 chars**
  (`build/I70-subagents-default-on-core/wt`, absolute) — the s9 wrap law
  (row = tree + outdir + 32, fires > 120) gives s9's out-dir budget
  **4 chars** (`t7s9` → row exactly 120, the I68/I69 proven-green
  boundary); every other scenario's out dir stays ≤ 6 (`t70sN`).
- This spec session itself runs inside a herdr pane — every gate that
  boots tart carries the `env -u HERDR_*` scrub (the I47/I69 lesson).
- The spec session's shell is clean (no bundler poison) — the full
  `architect` env scrub is needed only from bundle-exec'd tart sessions.
- The I69 hygiene law: every frozen gate that writes an out dir carries
  its own `rm -rf` (the herdr-wire-probe amendment precedent).
- Gates are GENERATED from the previous frozen block (`tmp/i70-spec/
  build-gates.rb` re-pointed at the I69 pair), carry audit BEFORE
  rehearsal, every rebase + drop declared in the AC preamble (the I32
  law: prose list and gate pattern generated from the lanes block, never
  hand-written alongside).

### Prior handoffs

- `notes/spec-digest-20261017T185618Z-tart-identity-herdr.md` (I69): the
  conventions above, the explicit-staging ruling, the s9 wrap law, the
  probe-naming rule (one load-bearing stdout token per gate).
- `architecture/I48-subagents-core.md` +
  `architecture/I49-subagents-profiles-intercom.md`: the subagent
  machinery contracts (manager/supervisor/profiles/intercom), the e2e
  harness discipline, the boot-discipline pins.
- Plan ENTRY 2 (the objective, constraints, acceptance direction).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section subagents-default-on specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision subagents-default-on`
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
`architect rehearse subagents-default-on` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze subagents-default-on` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse subagents-default-on` — before the freeze, while
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
subsection per lane. A copy is written to build/I70-subagents-default-on-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section subagents-default-on prompt --append --lane <lane> --from build/I70-subagents-default-on-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I70-subagents-default-on-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagents-default-on --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section subagents-default-on verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify subagents-default-on`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
