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

### Objective

Make the native subagents core functional with the gate on, then
DEFAULT-ON — the plan ENTRY 2 objective. The crash cure (the MOTD
[Prompts] scope path, the whole section) and the default flip
(`"subagents" => true`) land as ONE lane, behind e2e gates that prove the
functional state; the parity surface pins the explicit OPT-OUT shape
(the I69 explicit-staging ruling); the owner's interactive test-drive is
the named POST-INTEGRATION checkpoint with the one-line revert
(settings/env opt-out) as the documented safety path.

### The contract (one lane)

**R1 — the MOTD cure (lib/tart/render/motd.rb, the pi-faithful package
tier).** The prompt scope path gains pi's PACKAGE tier, with the
builtin workflow templates classified by their shape (the classification
is total: `file_path` nil ⇒ the builtin tier, Grounds "tart today"):

- `prompt_scope_entries`: a template with a nil `file_path` becomes a
  package member — `{path: nil, display: "/<name>", group: "user",
  package: "subagents"}` (pi's installed-package scope is "user"; the
  label is the port's own source name — pi's row reads
  `npm:pi-subagents`, the port's builtin tier IS its subagents source;
  declared mapping). File-backed templates classify EXACTLY as today
  (project/user/path by path).
- `scope_group_rows`: per group (project → user → path, order
  unchanged), the plain path members render EXACTLY as today (4-space
  dim rows, path-sorted), THEN the package sub-lists (label-sorted):
  a label row `    <label>` — 4-space indent UNSTYLED + the label in
  `Theme[:md_link]` (two spans, the group-label row's shape) — then one
  `      /<name>` row per member (6-space indent + display inside ONE
  dim span, name-sorted — byte-equal to pi's package-path sort for
  `<label>/<name>.md`). Every row through `wrap_resource_row` (the s9
  instrument). NO crash anywhere in the section for ANY template mix
  (nil-path builtins, file-backed user/project templates, both).
- The COLLAPSED [Prompts] compact list is unchanged in shape (the six
  names join the sorted `/name` list — already flows today).
- NO other section moves: [Context]/[Skills]/[Extensions] byte-identical
  (skills are always file-backed — their path classification is
  untouched).

**R2 — the default flip (lib/tart/settings.rb).** `DEFAULTS["subagents"]
=> true` — the ONE literal. The gate comment block is rewritten to the
default-on law (default on; opt-out via settings `{"subagents": false}`
or the `<IDENTITY>_SUBAGENTS` env tier — any non-on value, today's
semantics). `RESOLUTION_ENV`, `resolve_setting`'s tier order, and
`bin/tart`'s `subagents_enabled?` predicate are BYTE-UNCHANGED. The three
`bin/tart` gate call-site comment blocks may be reworded to the same law
(allowed, not required; no behavior change — the call sites ride the
resolved value).

**R3 — the rig staging pin (gems/tui-split-rig/lib/runner.rb + its
test).** `stage_tart_home` writes the staged settings.json ALWAYS (not
just the context_window scenarios), carrying `"subagents" => false`; the
compaction rows still ride ONLY the context_window scenarios
(byte-identical to today's staged bytes when present); `stage_memory`'s
deep-merge composes unchanged. Every parity path (s1–s10, s17,
s1-tart-mode, the probe gates that boot through the Runner) therefore
stages the explicit opt-out — the I48-off shape, no default rides the
rig. Pins in `gems/tui-split-rig/test/scenario_test.rb`: the staged
settings row (always present, false), the compaction coexistence
(context_window scenario: both the row and the knobs), and the existing
staging pins stay green.

**R4 — the live MOTD gate (gems/tui-split-rig/bin/subagents-motd-probe,
NEW).** A rig bin in the herdr-wire-probe shape (stdlib + optparse;
`--out DIR`; scrubs its own `HERDR_*` env) that boots tart DIRECTLY in
tmux (the tmp/probe-subag boot pattern — NOT through the Runner, which
stages the opt-out): a staged HOME with NO settings.json (the default-on
boot), a staged sandbox cwd, a CLOSED pane env staging only
`TART_MODEL`/`TART_API_KEY`/`TART_API_BASE` (mock facts — no request is
made; the MOTD renders at boot), the DEFAULT identity (no
`TART_IDENTITY` staged — the post-I69 default boot shape), pane stderr
redirected to a log. Boot → bounded settle → `ctrl+o` → capture-pane
(plain + `-e`) → assert → teardown (tmux kill-session, token-scoped
session name). Asserts:
1. NO crash: the pane is alive with the chat surface, and the stderr log
   carries no `NoMethodError`/motd trace (the crash repro is the
   designed-RED at base);
2. the collapsed [Prompts] row lists the six names sorted;
3. the expanded [Prompts] block byte-matches the frozen oracle shape
   (Grounds capture) with the port's label: the `  user` row (accent SGR
   run), the `    subagents` label row (mdLink SGR run), then the six
   `      /<name>` rows (dim SGR runs) in alphabetical order — checked
   against the styled capture's exact truecolor codes;
4. print `SUBAGENTS_MOTD_OK` / exit 0, else the failing line + exit 1.
   The gate command carries its own `rm -rf` of the out dir (the I69
  hygiene law) and the `env -u HERDR_*` scrub.

**R5 — the e2e default-on legs (test/subagents_e2e_test.rb).** A NEW leg
family (the E legs) driving the I48/I49 harness with NO settings.json
staged (the parent boots default-on; only the staged
`<IDENTITY>_SUBAGENTS_HOME` + the closed env + explicit
`TART_IDENTITY=pi` + `PI_*` mock facts, the harness convention):
E1 foreground child round-trip (the leg-A shape); E2 async detached +
completion notify + the print-parent drain (the leg-B shape); E3 the
steering receipt (correlated consumption, the leg-C shape); E4 stop (the
leg-D shape). The A–D opt-in legs stay green byte-unchanged (the opt-in
tier is not re-litigated). The leg names carry `default_on` (the gate's
`-n` filter).

**R6 — the test moves + new pins.** The declared moves (Grounds "the
flip's blast radius"): `settings_test`/`subagents_test` DEFAULT pins move
to true (itemized, discrimination preserved — the opt-out tiers gain
pins so the off shape stays pinned). NEW pins:
`test/render/motd_test.rb` — the package-tier unit pins (nil-path
entries render the `user`/label/`      /name` rows with the accent/
md_link/dim styles; mixed tiers keep the plain path rows; the collapsed
list unchanged; the nil-crash class stays dead);
`test/chat_test.rb` — a MOTD render pin with a nil-path template in the
prompts list (the section renders, no crash, the collapsed row carries
the name). Nothing is DELETED; the suite grows past the measured 1219
floor.

### Frozen expectations (do not redesign)

- NO subagent machinery rewrite: `manager.rb`/`supervisor.rb`/
  `profiles.rb`/`intercom`/the tool body/`workflows.rb` content are
  untouched (workflows.rb stays in the whitelist only for a
  builder-found need; the six prompt/description bytes are pinned by
  `subagents_intercom_test`).
- The wire/session digests: the rig-staged parity family holds EXACT
  (instruction `4209f40b…`, tools `7360fd1e…758831…`, the session
  goldens — the parity surface pins the OPT-OUT shape via R3); the
  DEFAULT-on wire is pinned by the NEW default-boot gate (tools
  `2c744efc…` + the instruction-identity law, Grounds "measured wire
  facts"). NO un-declared digest moves.
- The opt-in tier is unchanged (the A–D e2e legs, the register
  mechanics, the I47 merge order — subagent declared LAST).
- The I48 boot-discipline invariant MOVES ITEMIZED: "default off = zero
  bytes change" becomes "default on, OPT-OUT = the I48-off shape" (the
  R3 staging + the opt-out digest pin are the proof).
- The suite's standing 1 skip stays; `SEAM_BENCH_OK` stays.
- `lib/tart/prompts.rb`/`skills.rb` are frozen seams — NOT touched.

### Named exclusions (Constraints, itemized)

- NO [Extensions] MOTD row for subagents (the I49 ruling stands:
  subagents is a tool, not an extension-module row).
- NO pi package-manager port: the port's package tier is the builtin
  classification (nil file_path), not an npm/git source machinery —
  itemized as the deliberate mechanism choice (the plan's "template
  shape or the motd scope seam — the spec picks": the SEAM).
- NO rig scenario-content edits (`gems/tui-split-rig/scenarios/**`
  pinned untouched by the scope gate); the motd probe boots tart
  directly, not through a Scenario.
- NO memory-gate default change (memory stays default-off); no
  identity, herdr, models, markdown, or render changes beyond the
  motd prompt-scope path.
- NO new gems; no Gemfile/Gemfile.lock/tart.gemspec/bench changes.
- The model-window tick stays DEAD; landing stays the human's.

### Output format

Builder Report per the standing template: the one-paragraph result, the
suite summary line, the gate one-liners table (EVERY frozen gate — the
I68 lesson: an absent gate in the table is a REJECT-class violation),
the itemized deviation list (every moved test pin named), residual
risks.

### Tool guidance

Read-only grounding first: `lib/tart/render/motd.rb` (the prompt scope
path), `lib/tart/subagents/workflows.rb`, `lib/tart/prompts.rb`,
`lib/tart/settings.rb`, `bin/tart` (the three gate call sites),
`test/render/motd_test.rb`, `test/subagents_e2e_test.rb` (the harness),
`gems/tui-split-rig/bin/herdr-wire-probe` (the probe shape),
`gems/tui-split-rig/lib/tui_split_rig/runner.rb` (stage_tart_home).
pi's interactive-mode.ts :1610-1693 + package-manager.ts are REFERENCE
(the oracle shape, Grounds). Then edit; run the suite EARLY — right
after the settings flip, before the motd work — to enumerate any
blast-radius miss (a test outside the whitelist breaking on the flip is
STOP-and-disclose, the judge adjudicates).

### Boundaries

Touch set (the scope gate's whitelist, exactly):
`lib/tart/render/motd.rb`, `lib/tart/settings.rb`,
`lib/tart/subagents/workflows.rb` (allowed-if-needed),
`gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
`gems/tui-split-rig/bin/subagents-motd-probe` (NEW),
`gems/tui-split-rig/test/scenario_test.rb`,
`test/render/motd_test.rb`, `test/chat_test.rb`,
`test/settings_test.rb`, `test/subagents_test.rb`,
`test/subagents_e2e_test.rb`, and `bin/tart` (comment rewords only).
Must-differ: `motd.rb`, `settings.rb`, `runner.rb` (the three legs of
the flip+cure+staging). Must-not-touch (pinned by the scope gate):
`gems/tui-split-rig/scenarios/**`, Gemfile/Gemfile.lock/tart.gemspec,
`bench/`, `lib/tart/prompts.rb`, `lib/tart/skills.rb`,
`lib/tart/subagents/manager.rb`, `lib/tart/subagents/supervisor.rb`,
`lib/tart/subagents/profiles.rb`, `lib/tart/tools/subagent.rb`, and
every other path. A test OUTSIDE the whitelist breaking on the flip:
STOP and disclose (the I69 blast-radius rule).

### Lane plan

- id: core
  repo: tart
  base: 2a33f66
  integration_branch: project/pi-port
  effort: high
  lanes_required: 1
  rationale: the code deltas are small (one literal, one section, one
    staging row) but the audit surface is broad — every real-boot and
    default-implicit test path must be found and moved with its
    discrimination preserved, the live probe must be reliable cold, and
    a missed default-on path is a lane failure.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/motd.rb
    - lib/tart/settings.rb
    - lib/tart/subagents/workflows.rb
    - bin/tart
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/bin/subagents-motd-probe
    - gems/tui-split-rig/test/scenario_test.rb
    - test/render/motd_test.rb
    - test/chat_test.rb
    - test/settings_test.rb
    - test/subagents_test.rb
    - test/subagents_e2e_test.rb
  effort: high
```

### Effort call

High — not for code volume but for enumerated audit: the flip's blast
radius (every default-implicit boot path), the live probe's cold
reliability (tmux settle + capture), and the rig staging change touching
byte-frozen parity paths (any drift in the staged settings bytes fails
the s-family).

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **54 gates — 47 carried from the I69
frozen block (25 byte-identical + 22 rebased exactly as declared; the
carry audit ran clean this session, `tmp/i70-spec/audit-gates.rb`:
AUDIT_OK, zero DIFF, zero UNDECLARED-DROP) + 7 new/rewritten.** The
carried gates keep their I69 `ac:` labels verbatim — they map to the
STANDING battery (this iteration's AC5, with `suite`/`bench` = AC6 by the
standing collapse); only the 7 new gates map to this iteration's AC1–AC5.
**Declared DROPPED (1):** `scope` — per-iteration (rewritten here, never
carried). **Declared rebases (22, commands byte-verbatim except these):**
the out-dir family `t69*`→`t70*` with s9 → the FOUR-char `t7s9` (the I70
lane tree is 84 chars — `build/I70-subagents-default-on-core/wt` — so the
s9 wrap law (row = tree + outdir + 32, fires >120) pins s9's out dir at
exactly 120, the I68/I69 proven-green boundary); `threads-budget`'s diff
base `3845f6a`→`2a33f66` (the iteration base); the mktmpdir prefixes
(`i69-hu-`/`i69-boot-`→`i70-*`) and the rig-identity-assert scratch out —
cosmetic, zero semantics; and ONE wording fix inside `default-face`: the
I69 verdict-session amendment left a shell apostrophe inside the
single-quoted `ruby -e` script (the comment `identity_test's byte-pi
pin` — the exact /bin/sh quote-termination trap the I69 digest warns
about; the gate exits 2 BROKEN, never RED or GREEN) — the reword
`identity_test pin (byte-pi)` is ruby-comment-only, zero semantics.
Rehearsal #1 (this session) caught it as BROKEN; the fix is the rehearsal
loop working as designed.

**The designed-RED vector (7, every one verified RED-for-the-right-reason
at base 2a33f66 by direct runs this session):** `subagents-default-law`
("the DEFAULTS row did not flip: false"), `subagents-default-boot`
("default-on tool names: [read, bash, edit, write] (the gate must default
ON)"), `subagents-motd-units` (the nil-path NoMethodError at
motd.rb:317/:306 — the defect itself), `subagents-motd-probe` (the bin
does not exist — declared-new), `subagents-e2e-default-on` (runs=0 — the
legs are declared-new), `rig-staging-units` (no settings.json in the
no-window path at base), `scope` (the must-differ legs untouched at
base). Everything else GREEN at base. Base = tart `project/pi-port` @
`2a33f66` (tip, clean this session; no owner-state swap); gem =
fast-completions 0.5.0 published; **measured base suite this session:
1219 runs / 5948 assertions / 0 failures / 0 errors / 1 skip, rake exit
0** + `SEAM_BENCH_OK**.

**AC1 — the MOTD cure, oracle-pinned (boot green with the gate on).**
With the subagents gate on (any tier), an interactive boot renders the
MOTD [Prompts] section with the six workflow templates and NO crash
anywhere in the section — the whole prompt-scope path
(`prompt_scope_entries` → `scope_group` → `under?` →
`scope_group_rows`), not just the first nil deref. The expanded section
byte-matches the captured pi oracle shape (Grounds): the group label
`user` (2-space indent unstyled + accent), the package label row
(4-space indent unstyled + `md_link` label), then the six `/<name>`
member rows (6-space indent, dim, name-sorted — byte-equal to pi's
package-path sort), with plain file-backed templates classified and
rendered EXACTLY as today (project/user/path groups, path-sorted, the
same styles) and the collapsed compact list shape unchanged (the six
names join the sorted list). [Context]/[Skills]/[Extensions]
byte-identical (skills are always file-backed). Gates:
`subagents-motd-units` (the unit pins incl. the style runs),
`subagents-motd-probe` (the LIVE interactive boot: default identity, NO
settings staged — no crash, the collapsed row lists the six, the expanded
block matches the oracle shape with the styled SGR runs
`38;2;167;152;215`/`38;2;105;173;208`/`38;2;126;136;142`; the gate
carries its own `rm -rf` and the HERDR_* scrub).

**AC2 — default ON, the opt-out tiers, the wire law.** With NO settings
file and NO env row, a boot registers the subagents machinery: the
`subagent` tool exists on the wire (declared LAST; default-loadout tools
digest `2c744efc…`; names `read bash edit write subagent`), and the
e2e legs prove the watcher/notify machinery (AC3). The instruction
(system-prompt) bytes are IDENTICAL off vs on in the same staged env —
the registration moves ONLY the tools array. The opt-out tiers: staged
settings `{"subagents": false}` → the wire IS the I48-off shape (tools
digest `7360fd1e…` — the standing wire-delta constant, the itemized move
of the I48 "default off = zero bytes" invariant); the env tier
(`<IDENTITY>_SUBAGENTS` = any non-on value) opts out, "1"/"true" beats
the file tier; the resolution ladder (env > file > default) and the
identity namespacing unchanged. Gates: `subagents-default-law`,
`subagents-default-boot` (both designed-RED at base, the flip's own
discriminators).

**AC3 — e2e default-on (the functional state the owner test-drives).**
With NO settings staged, the I48/I49 harness legs pass end to end:
foreground child round-trip (the child output rides back verbatim as the
tool result, the run artifacts under the staged
`<IDENTITY>_SUBAGENTS_HOME`), async detached + completion notify + the
print-parent drain, the steering receipt (correlated consumption by
request id, never mere inbox acceptance), stop (graceful interrupt,
state `stopped`). Hermeticity preserved (fresh staged HOME per leg, the
closed child env, no owner `~/.tart` writes, full teardown). The opt-in
legs A–D stay green byte-unchanged (the opt-in tier is not re-litigated).
Gate: `subagents-e2e-default-on` (≥4 legs, the `-n /default_on/` filter;
designed-RED at base: runs=0).

**AC4 — the parity surface: explicit staging, the frozen digests hold.**
Every rig parity path stages the explicit opt-out: `stage_tart_home`
writes the staged settings.json ALWAYS, carrying `"subagents" => false`;
the compaction rows still ride ONLY the context_window scenarios
(byte-identical staged bytes when present); `stage_memory`'s deep-merge
composes unchanged. The s-family (s1–s10, s17, s1-tart-mode),
`wire-delta` (instruction `4209f40b…`, tools `7360fd1e…758831…`),
`zai-max-tokens-wire`, and `session-golden` all hold EXACT at the lane
tree — the parity surface pins the OPT-OUT shape (the I69
explicit-staging ruling: no parity path rides the app default; the
owner's live pi-subagents-vs-tart parity is the post-integration
interactive test-drive's domain, not rig-observable). Gate:
`rig-staging-units` (designed-RED at base) + the carried s/wire/session
family.

**AC5 — regression floor + scope.** The default rake task fully green
with runs > the measured 1219 floor and assertions > 5948 (the moved
pins are MOVED with their discrimination preserved — a deleted pin fails
the floor by design; new pins grow: the motd/chat units, the settings
opt-out pins, the e2e default-on legs, the rig staging pins); the 1
standing skip unchanged; `SEAM_BENCH_OK`; the standing battery green
(every carried gate); the oracle pin state holds. The integrated diff vs
`2a33f66` touches EXACTLY the declared touch set (the ```lanes block,
identical to the scope gate's whitelist); a test OUTSIDE the whitelist
breaking on the flip is a STOP-and-disclose (deviation adjudication),
never a silent widening. Gates: `suite`, `bench`, `scope` (designed-RED
at base: the must-differ legs untouched) + every carried member.

Gate calibration (pre-declared): the 7 designed-RED gates must all cure
at the lane tree (GREEN, non-vacuous — the crash repro, the flip
discriminators, the new legs, the new bin, the staging row, the
must-differ diffs); the 47 carried gates must stay GREEN. The s-gates
keep CANONICAL short out dirs (s9's is `t7s9` — the 84-char lane tree
budget); the known s9 lane-worktree deep-path artifact (the I34…
I69 precedent class) does not fail this iteration when the same tree
exits 0 at canonical depth — the judge runs the battery on the integrated
tree. The three launcher/SystemPrompt environment-dependent pins inside
`suite` adjudicate env-class exactly as standing (the I59+ class).

**Suite flake note (rehearsal #1, this session):** the `suite` gate TIMED
OUT at the 900 s default in rehearsal #1 while the pristine base tree
ran `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_
coherent` (chat_test:1613/1620, a timing-sensitive interrupt test) — the
run stopped emitting output ~2.5 min in and never recovered. Direct
re-runs of the SAME suite at the SAME base THIS session are green:
three full runs (176.9 s / ~175 s / seed 40850 — the rehearsal's own
seed) all 1219 runs / 5948 assertions / 0F / 0E / 1S. Class: the
environmental-timing flake the I38 rehearsal precedent recorded
("transient … clean on re-run"), not a tree defect — the rehearsal ran
the PRISTINE base with zero lane work. If the judge's `suite` run hits
the same timeout, re-run cold before adjudicating (the standing
practice); a reproducible cold failure is a different class and must be
root-caused before any verdict.

```gates
---
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 2a33f66 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t70tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t70ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t70s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t70s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t70s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t70s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t70s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t70s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t70s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t70s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t7s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t7s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t70s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t70s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t70s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t70s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t70s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t70wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t70wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t70wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t70zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t70zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t70zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i70-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i70-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t70hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t70hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i70-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: subagents-default-law
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK
- id: subagents-default-boot
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK
- id: subagents-motd-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK
- id: subagents-motd-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t70mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t70mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK
- id: rig-staging-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: 'git diff --quiet 2a33f66 -- Gemfile Gemfile.lock tart.gemspec bench gems/tui-split-rig/scenarios
    lib/tart/prompts.rb lib/tart/skills.rb lib/tart/subagents/manager.rb lib/tart/subagents/supervisor.rb
    lib/tart/subagents/profiles.rb lib/tart/tools/subagent.rb && ! git diff --name-only
    2a33f66 | grep -vE "^(lib/tart/render/motd\.rb|lib/tart/settings\.rb|lib/tart/subagents/workflows\.rb|bin/tart|gems/tui-split-rig/lib/tui_split_rig/runner\.rb|gems/tui-split-rig/bin/subagents-motd-probe|gems/tui-split-rig/test/scenario_test\.rb|test/render/motd_test\.rb|test/chat_test\.rb|test/settings_test\.rb|test/subagents_test\.rb|test/subagents_e2e_test\.rb)$"
    | grep -q . && [ -n "$(git diff 2a33f66 -- lib/tart/render/motd.rb)" ] && [ -n
    "$(git diff 2a33f66 -- lib/tart/settings.rb)" ] && [ -n "$(git diff 2a33f66 --
    gems/tui-split-rig/lib/tui_split_rig/runner.rb)" ] || { echo "FAIL: scope — the
    tree bites outside the frozen touch set or a must-differ member is untouched (motd.rb/settings.rb/runner.rb)";
    exit 1; } && echo SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
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
