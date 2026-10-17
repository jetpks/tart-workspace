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
