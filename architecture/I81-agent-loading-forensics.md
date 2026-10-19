# I81: agent-loading-forensics

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I81 `agent-loading-forensics` (live-run successor plan ENTRY 6, the LAST entry)

Plan: `notes/plan-20261018T1745Z-live-run-successor.md` ENTRY 6 (verbatim above in
the plan doc; owner-signed). Repo tip: `repos/tart` @ `project/pi-port` `7b70e8a`
(the I80 merge; I77–I80 verdicts CONTINUE). This entry closes the plan — entries
1–6 complete after it.

## The three defects, root-caused at the current tip

**(a) Unknown tools in a custom agent's `tools` frontmatter REJECT the whole file.**
`tart`'s profile contract (`repos/tart/lib/tart/schemas/subagents.rb:92-104`,
`rule(:tools)`) fails the contract on any name outside `ProfileFields::TOOLS_UNIVERSE`
(`read edit write bash find grep ls contact_supervisor`, :29-31);
`Profiles.build_profile` (`lib/tart/subagents/profiles.rb:139-152`) maps contract
failure to warn+SKIP — the agent never loads. Live proof (the 07:40Z devstral
session, `~/.tart/sessions/--Users-eric-architect-spaces-20261018-devstral-docs--/2026-10-18T07-40-42-220Z_01a14df4-a96c-7070-a1ee-21512a279518.jsonl`):
the coordinator playbook (`tools: subagent, bg_wait, read, grep, find, ls, bash`)
and the builder playbook (`web_search`, `fetch_content`, `get_search_content`)
were both invisible at spawn — the only surface was
`{"error":"unknown agent \"architect-coordinator\". Available agents: …"}`; the
file-rejection diagnostic itself is DARK today (`Profiles.resolve` → `resolve_table`
discards `discover`'s diagnostics; no boot surface renders them — contrast
`bin/tart:556-559`, which DOES render skills + prompts diagnostics as
`command_line` rows). After stripping `bg_wait` the coordinator was STILL rejected —
**(b)** is the remaining blocker.

pi's behavior (the parity bar): pi-subagents 0.79.1 NEVER validates tool NAMES at
load — `agents.js:739-741` throws only on a structurally invalid `tools` value
(non-array/non-strings); unknown names flow to the child and pi's loadout filter
drops them (`repos/pi/packages/coding-agent/src/core/agent-session.ts:1575-1582`,
`_applyToolLoadout` — `flatMap` over the registry, unknown names simply absent).
So pi hosts the coordinator playbook verbatim; tart cannot. The plan's law:
warn-and-drop — load the agent, drop only the unknown entries, warn.

**(b) `subagent` is not grantable to custom agents — the coordinator role is
unhostable.** Three stacked barriers at the tip:
1. `TOOLS_UNIVERSE` (schemas/subagents.rb:29-31) omits `subagent` → any profile
   declaring it is rejected (defect (a)'s mechanism).
2. Even if the profile loaded, `Tools::Registry.build`
   (`lib/tart/tools/registry.rb:66-69`) raises `ArgumentError, "Unknown tool:
   subagent"` — `TOOL_CLASSES` has no entry — so the child argv
   `--tools subagent,…` (`manager.rb:395-399`, `spawn_argv_and_env`) would die at
   the child's boot (`print.rb:90` builds the loadout from exactly the
   `--tools` list).
3. Nothing bounds recursion: there is no depth marker anywhere in the child env
   (the I48 closed pick list, `manager.rb:430-505`, carries no depth).

Process-level nesting ALREADY works at the tip: a gate-on print child registers
its own Manager (`bin/tart:306-310`) and the hooks registered-tools merge
(`registry.rb:80-86`) appends `subagent` to the child's wire loadout REGARDLESS of
the `--tools` list — the I49-recorded residual "children-of-gate-on-parents declare
`subagent` on their wire". What is missing is the AUTHORING path: no agent can be
DECLARED with the tool. pi's grant law (pi-subagents 0.79.1
`src/runs/shared/child-tool-plan.js:200-204`): fanout is authorized when the
effective tools allowlist includes `subagent` OR `allowNestedSubagents: true` (the
playbooks carry BOTH — `tools:` lists `subagent` explicitly, so the tools-list
grant covers the live case; `allowNestedSubagents` stays tolerated-and-ignored in
the port, a declared residual). pi's recursion bound: `DEFAULT_SUBAGENT_MAX_DEPTH
= 2` (`src/shared/types.js:134`), operator override via `PI_SUBAGENT_MAX_DEPTH`
(`types.js:178-183`), children inherit (`resolveChildMaxSubagentDepth`,
`types.js:184-187`; `resolveChildDepth` = parent depth + 1, `types.js:196-201`),
blocked when `depth >= maxDepth` (`checkSubagentDepth`, `types.js:188-195`). The
blocked-spawn bytes, pi verbatim
(`src/runs/foreground/subagent-executor.js:6983-6993`):
`Nested subagent call blocked (depth=<d>, max=<m>). You are running at the maximum
subagent nesting depth. Complete your current task directly without delegating to
further subagents.`

**(c) Forensics blindness.** Live specimen
`~/.tart/subagents/01a14df7-f99a-7244-a23e-e172ebd97383/` (the 07:44Z devstral
worker run): status.json carries `"task": null, "taskChars": 3140` (the I48
taskChars-only redaction, `manager.rb:1153`), and the transcript sits at
`…/sessions/sessions/--Users-eric-architect-spaces-20261018-devstral-docs--/2026-10-18T07-44-19-606Z_….jsonl`
— a DOUBLED `sessions/` segment. Mechanism: the child argv passes
`--session-root <run-dir>/sessions` (`manager.rb:398`) but the Recorder composes
`File.join(root, "sessions", safe_path)` (`lib/tart/agent/session.rb:78-80`) —
root already IS the sessions dir, so the path doubles. `status.sessionRoot`
(`manager.rb:1160`) points at `<dir>/sessions` — today the PARENT of the real
(doubled) dir. The manager's transcript glob (`manager.rb:1225`,
`sessions/**/*.jsonl`) matches both layouts, so adoption of historical doubled
dirs keeps working under a cure.

Task-text ruling (the plan offers text or digest): pi redacts prompt text from
EVENTS and status step descriptions (`chain-append.js:140-146` `PROMPT_REDACTED`;
`async-execution.js:1511`) — but the RUNNER's own launch artifacts carry the task
text (`async-execution.js:1254` `task: params.task`, `:1910` `task: taskText`).
The port's `status.json` is the run's own artifact (the runner-artifact analog),
and the plan's forensics bar — "a post-mortem can answer what was this run asked
to do from disk" — must hold even when the child died before recording a
transcript (the dead-run specimen class, I78). DECISION: carry the RAW task text
verbatim in `status.task` (fork preamble excluded — it is harness boilerplate,
recorded in full in the transcript); `taskChars` stays the raw char count; the
I79 box NEVER renders a task row (`render/subagent_box.rb:27-28`, pi's redaction
law) — unchanged.

## Standing context the spec rides on

- I48 subagents core (the closed child env — OQ-7 law; the sanctioned-key pin at
  `test/subagents_test.rb:292-320`), I49 profiles+intercom (the contract, the
  bridge union, the registered-tools merge order), I70 subagents default-ON (the
  child's gate resolves ON from the settings default — the stale "children never
  nest" argv comment predates the flip), I78 runner health, I79 status box, I80
  child encoding (the locale law; the sanctioned list now carries
  `LANG LC_ALL LC_CTYPE`).
- BRIEF §8 exact-parity bar: pi in one tab, tart in another, indistinguishable —
  the parity target for subagents behavior is the INSTALLED pi-subagents
  0.79.1 (`~/.pi/agent/npm/node_modules/pi-subagents/`) + the pinned pi clone
  `repos/pi` (the rig oracle at tag v1.1.0 for the render battery; subagents
  seams cite the installed module, the I49/I80 precedent).
- Verification gate floor (tart): full suite + `SEAM_BENCH_OK` + the carried
  88-gate battery (rebased this spec to 92: 87 carried + scope rewritten + 4 new).
- Constraints (plan ENTRY 6): NO rig scenario-content edits; the I70 MOTD
  prompt-scope package tier law untouched; `.pi/` stays agents-only.

## Facts measured this session (controls actually run)

- Base suite floor at `7b70e8a`, cold: `bundle install --quiet && bundle exec rake`
  → **1453 runs / 6846 assertions / 0F / 0E / 1S, exit 0**;
  `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Remote ancestry: `git -C repos/tart merge-base --is-ancestor 7b70e8a origin/main`
  → **exit 1 (NOT an ancestor)** — `origin/main` holds squashed PR merges;
  provision needs `--base 7b70e8a` (re-verify immediately before provisioning).
- Base test counts (gate floors): `test/subagents_profiles_test.rb` 15,
  `test/subagents_test.rb` 34, `test/subagents_e2e_test.rb` 11 (all GREEN at
  base); the discriminator filters `/dropped/`, `/nested|depth_cap/`,
  `/forensic/`, `/nested/` (e2e) are EMPTY at base — the four new gates are
  declared-RED there (verified by name-grep over the three files: zero matches).
- The carried-pin audit (the I80 lesson, run BEFORE freeze): the I81 laws
  contradict exactly FIVE carried pins, ALL in the frozen touch set as DECLARED
  re-pins — `subagents_profiles_test.rb:129-134` (the unknown-tool reject
  message), `subagents_test.rb:257` (task never recorded), `:290` (the
  session-root argv value), `:292-320` (the closed-env sanctioned list — the two
  new depth keys), `subagent_box_test.rb:301` (`assert_equal nil, status["task"]`).
  No pin OUTSIDE the touch set contradicts the laws (audited: health fixtures
  fabricate LEGACY task-null dirs — correct post-change too, adoption tolerance;
  `tools_test.rb:114` pins the raise for `rm_rf` — still unknown post-change;
  intercom/health `spawn_argv_and_env` pins assert PI_MODEL/PI_PROVIDER only —
  additive keys survive; the e2e `sessions/**/*.jsonl` globs match both layouts).
- Live specimens on disk (read-only evidence): the doubled-path run dir +
  task-null status above; the 07:40Z transcript (the rejection debugging).

## Open questions (ruled at spec time; none deferred)

- **OQ-1 (plan's own OQ) — pi-parity grants + recursion bound: RULED.** Grant =
  the tools list (pi `child-tool-plan.js:200-204`; the playbooks list `subagent`
  explicitly). Bound = pi's depth law verbatim: default 2, env override, child
  inherits, blocked raise carries pi's bytes. `allowNestedSubagents` stays
  tolerated-and-ignored (declared residual — a pi playbook relying on it ALONE
  would not gain nesting in tart; no known playbook does).
- **OQ-2 — warn surface: RULED.** The diagnostic is unit-pinned in
  `Profiles.discover`'s Result (the Skills::Diagnostic shape), AND the
  interactive boot renders one `command_line` row per profile diagnostic
  (the `bin/tart:556-559` idiom) — this also makes today's DARK malformed-file
  warnings visible (declared behavior change, same channel, same idiom). Print
  children have no boot surface — the drop itself is pinned on the child wire.
- **OQ-3 — all-unknown tools list: RULED.** Loads with ZERO tools + the warning
  (an explicit empty list is meaningful — pi's loadout makes it so; the
  builtin-seven default applies ONLY to an omitted/nil tools line, unchanged).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section agent-loading-forensics specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision agent-loading-forensics`
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
`architect rehearse agent-loading-forensics` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze agent-loading-forensics` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse agent-loading-forensics` — before the freeze, while
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
subsection per lane. A copy is written to build/I81-agent-loading-forensics-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section agent-loading-forensics prompt --append --lane <lane> --from build/I81-agent-loading-forensics-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I81-agent-loading-forensics-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence agent-loading-forensics --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section agent-loading-forensics verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify agent-loading-forensics`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
