# I32: prompt-identity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I32 prompt-identity

Measured this session (2026-10-12, the I30 judging session) at base 276eda3d
(`project/pi-port` tip after I30; I31 lands before this iteration builds —
see the fast-follow note in the Specification).

1. **The port already contains the faithful prompt — unwired.** `lib/tart/
   agent/system_prompt.rb` is a section-for-section port of pi's
   `system-prompt.ts`: verbatim PREAMBLE ("You are an expert coding assistant
   operating inside pi, a coding agent harness…"), `<tools>` (TOOL_SNIPPETS
   covers all 7 port tools), `<rules>` (build_rules — the loadout-conditional
   bullets incl. the edit-oldText discipline), `<docs>` (docs_paths param),
   `<addendum>`, `<project_context>` (context_files param), `<skills>`
   (reader-gated), `<cwd>`. `test/system_prompt_test.rb` pins the composition
   against goldens. `Agent::SystemPrompt.build` is called from exactly ONE
   place in the repo: its own tests. The live seam is `bin/tart:389`
   `system_prompt(workdir, skills)` — a 203-char custom string ("You are a
   coding assistant working in … keep answers brief") + the skills block —
   feeding BOTH interactive (:199) and print (:232). No ruling in
   ARCHITECT.md or BRIEF ever sanctioned the terse prompt; it is greenfield
   scaffolding that calcified. The owner ruled this session: take pi's
   harness prompt, identity-branded.

2. **The missing seam: project context.** pi discovers context files
   (resource-loader.ts:175-280: candidates `AGENTS.override.md`, `AGENTS.md`,
   `AGENTS.MD`, `CLAUDE.md`, `CLAUDE.MD` per directory, ancestor walk,
   worktree-shadowing) and injects them as `<project_context>`. The port has
   ZERO context-file discovery — the user's AGENTS.md (persona, language
   idioms, project rules) never reaches the model. The `context_files`
   parameter already exists in SystemPrompt; the discovery is the missing
   half. Highest-leverage §3 daily-driver gap in the port.

3. **Owner rulings, 2026-10-12 (this session, recorded for the builders).**
   (1) **Branding follows Identity — white-labelable out of the box**: any
   identity value works (`foo` renders "inside foo" and loads `FOO_` vars);
   it is not "support pi and tart", it is "configure the identity any way and
   it works". (2) **`<docs>` paths KEEP pi's for now** (they are the spec the
   port implements). (3) **The `PI_*` env-var rule follows Identity**: pi
   mode → `PI_`, tart mode → `TART_`, `foo` → `FOO_`.

4. **Identity today** (identity.rb, I16): VALUES locked `%w[pi tart]`
   (anything else raises); DEFAULT pi; ENV_KEY `TART_IDENTITY`; SETTINGS_KEY
   `identity`; pi mode renders ORACLE_VERSION "1.1.0" (the oracle's
   package.json), tart mode Tart::VERSION. The parity scenarios stage NO
   identity (tart runs in pi mode — that is why the rigs pass); `s1_tart.yml`
   stages `TART_IDENTITY: tart` (scenario_test.rb:22 pins it).

5. **Measured wire facts (this session's s8 request logs).** pi: role
   `system`, 2,930 content chars, 4 tools (2,841 tool JSON). tart: role
   `developer`, 203 content chars, 7 tools (4,971 tool JSON — MORE than pi).
   The `<tools>`/`<rules>` sections therefore differ BY LOADOUT at the same
   identity — loadout parity (4 vs 7) is a standing tart superset, queued,
   NOT this iteration; the prompt golden is pinned at the SAME loadout.
   pi's `PI_*` session envs are real behavior (bash.ts:221 exposes session
   metadata as `PI_*` envs to bash, default true; the rule text at bash.ts:47)
   — the port's bash sets none; the rule text is prompt parity only, the
   exposure feature is queued (itemize).

6. **The env-knob inventory (grep this session — every `TART_` literal in
   lib/ + bin/):** settings.rb:63-67 (ENV map: defaultModel/defaultProvider/
   apiBase/apiKey/modelReasoning → `TART_MODEL`/`TART_PROVIDER`/
   `TART_API_BASE`/`TART_API_KEY`/`TART_MODEL_REASONING`), settings.rb:118
   (`TART_CONTEXT_WINDOW`), identity.rb:17 (`TART_IDENTITY` — the bootstrap),
   loop.rb:311 (`TART_CONTEXT_WINDOW` — the loop's env tier), models.rb:123-
   126 (`TART_MODEL`/`TART_PROVIDER`), bin/tart:345/:425-426 (`TART_API_KEY`/
   `TART_API_BASE`), bin/tart:443 + motd.rb:154 (`TART_MCP_CONFIG`). pi reads
   NO mcp-config env (grep clean) — `TART_MCP_CONFIG` is a port-only knob;
   it stays launcher-owned with `TART_IDENTITY` (the identity key cannot
   depend on its own output; itemize both).

7. **The rig staging seam.** runner.rb:242-246 stages tart's env with
   `TART_*` literals. With identity-driven keys, the parity scenarios (tart
   in pi mode, default) need `PI_*` keys staged or the mock connection
   breaks — the runner becomes prefix-aware (staging follows the scenario's
   identity). Verify the runner's parent-env hygiene: the operator's real
   machine exports `PI_API_KEY` (they run real pi) — the staged env must not
   inherit parent `PI_*`/`TART_*` values.

8. **Why a fast-follow (sequencing ruling, this session).** I31 (dispatched
   in parallel with this spec) edits loop.rb (the estimator threading) and
   chat.rb/transcript.rb; this iteration must also edit loop.rb:311 (the env
   key) and chat_test.rb (MOTD-identity pins). Same-file overlap across
   parallel lanes is the merge-conflict spec defect the loop refuses to
   hand-resolve — so this iteration is the sanctioned fast-follow pattern:
   provisioned off the post-I31 `project/pi-port` tip, dispatched after I31
   integrates. Its builders see I31's tree; its gates prove on the integrated
   tree.

9. **Control (this session, base 276eda3d).** Suite 565 runs / 2217
   assertions / 0 failures / 1 pre-existing skip; s1–s6 exit 0; s7/s8 exit 1
   (I31's residuals — green on this iteration's base after I31 lands);
   s1_tart exit 0. All regression claims are against this baseline.

## Specification

# Specification — I32 prompt-identity

- **Objective.** Wire the port's existing faithful prompt builder into the
  launcher, identity-branded and white-labelable (BRIEF §3 daily-driver
  parity + the owner's 2026-10-12 rulings, Grounds 1-3): pi's full harness
  prompt (preamble, `<tools>`, `<rules>`, `<docs>`, `<project_context>`,
  `<skills>`, `<cwd>`) replaces the 203-char terse string, the branding and
  env namespace follow the configured identity (pi/tart/foo → `PI_`/`TART_`/
  `FOO_`), and the missing AGENTS.md discovery seam lands so the user's
  project instructions reach the model. Why now: the prompt shapes the
  model's tool discipline on every turn, the port's builder is already
  written and golden-tested, and the owner ruled the identity mechanics.

- **THE FAST-FOLLOW (sequencing).** This iteration provisions off the
  post-I31 `project/pi-port` tip and is dispatched only after I31
  integrates (Grounds 8): your worktree already contains I31's estimator +
  header changes. Do not re-litigate them; build on them.

- **Lane `prompt`** (repo `repos/tart`; ONE lane — identity, settings,
  launcher, and rig staging are one seam):
  1. **Identity free-form** (owner ruling 1, Grounds 3-4): any non-empty
     identity string resolves (CLI flag > `TART_IDENTITY` env > settings
     `identity` > default `pi`); `pi` and `tart` keep their existing
     byte-exact rendering (pi goldens, s1_tart); any other identity renders
     the tart-family face with its own name and `Tart::VERSION`. Empty or
     whitespace-only → the clean-abort error path (the I16 seam). The env
     namespace is `"#{identity.upcase}_"`.
  2. **The prompt wiring**: `bin/tart`'s `system_prompt` seam composes
     `Agent::SystemPrompt.build(selected_tools:, cwd:, context_files:,
     docs_paths:, skills:, identity:)` — the terse string is GONE from both
     the interactive (:199) and print (:232) paths. The PREAMBLE templates
     the identity name ("…operating inside <name>, a coding agent
     harness…"); pi mode is byte-identical to pi's. The bash env-var rule
     bullet (system_prompt.rb TOOL_GUIDELINES) templates the prefix
     ("<PREFIX>_* environment variables"); pi mode byte-identical to pi's
     bash.ts:47. `<docs>` keeps pi's resolved install paths (owner ruling 2)
     — verify how pi resolves them (getReadmePath/getDocsPath/
     getExamplesPath) and cite. The golden for pi-mode byte parity is
     derived from pi's CAPTURED request (repos/tart/tmp/parity-gate-s8/
     run-1/pi-requests.jsonl, this session's oracle — cwd section
     normalized; same-loadout comparison), never from the port's own output
     (the edit-goldens doctrine).
  3. **Project-context discovery** (pi resource-loader.ts:175-280): the
     candidates `AGENTS.override.md`/`AGENTS.md`/`AGENTS.MD`/`CLAUDE.md`/
     `CLAUDE.MD`, per-directory first-match, the ancestor walk, and the
     worktree-shadowing rule — port faithfully (new
     `lib/tart/agent/context_files.rb` or inside system_prompt.rb, your
     call within the touch set); thread the found files as `context_files`.
     No files → no `<project_context>` section (the parity sandboxes find
     none — pi's rig requests carry none either; both sides stay bare).
  4. **The env namespace** (owner ruling 3, Grounds 6): every app env read
     routes through the identity prefix — the settings ENV map
     (settings.rb:63-67), `TART_CONTEXT_WINDOW` (settings.rb:118 AND
     loop.rb:311), the model/provider/api-key seams (models.rb:123-126,
     bin/tart:345/:425-426). `TART_IDENTITY` and `TART_MCP_CONFIG` stay
     launcher-owned bootstrap knobs (itemized: the identity key cannot
     depend on its own output; pi reads no mcp env — Grounds 6). Verify the
     settings load-order seam: the settings FILE loads, identity resolves,
     THEN env overrides apply with the resolved prefix (restructure
     Settings if needed — it is in your touch set). Launcher help text
     names the mechanism, not hardcoded `TART_MODEL` spellings.
  5. **The rig staging** (Grounds 7): runner.rb stages prefix-aware env for
     tart (the scenario's identity decides `PI_*` vs `TART_*` keys; the
     parity scenarios run tart in pi mode → `PI_*`); scrub parent-env
     `PI_*`/`TART_*` inheritance so the operator's real `PI_API_KEY` cannot
     leak into a staged run; scenario_test pins update. s1_tart (tart mode)
     stages `TART_*` unchanged.

- **Output format.** Raw evidence to scratch: file list + wc; the seam table
  (pi mechanic → port seam, before/after: preamble/env-rule/docs/context
  discovery/env namespace/rig staging); verbatim test tails + suite counts;
  s1–s8 + s1_tart exit codes from YOUR worktree (I31 is in your base — ALL
  expected 0); the pi-mode prompt golden diff (the composed prompt vs pi's
  captured message, cwd normalized, same loadout — verbatim); the
  white-label smoke (identity `foo`: preamble name, `FOO_` resolution,
  version); itemized deviations/cuts. PHASE 0 disagreements mandatory (a
  labeled PHASE 0 section). STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet
  && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/
  <s>.yml --out tmp/<out>`. pi sources (read before coding; cite what you
  port): `packages/coding-agent/src/core/system-prompt.ts` (whole file),
  `src/core/resource-loader.ts:160-280` (context files), `src/core/tools/
  bash.ts:47+221` (the env rule + exposure), the settings env-override
  shapes in `src/core/settings-manager.ts`, `src/modes/interactive/
  interactive-mode.ts` (how the composed prompt reaches the request). The
  gem's `with_instructions` (chat instructions → the developer message).
  The request-capture oracle: `repos/tart/tmp/parity-gate-s8/run-1/
  pi-requests.jsonl`.

- **Boundaries.** Touch EXACTLY: `bin/tart`, `lib/tart/identity.rb`,
  `lib/tart/agent/system_prompt.rb`, `lib/tart/agent/context_files.rb` (new,
  allowed), `lib/tart/settings.rb`, `lib/tart/models.rb`,
  `lib/tart/render/motd.rb` (the `TART_MCP_CONFIG` read + the
  white-label name/version rendering), `test/system_prompt_test.rb`,
  `test/settings_test.rb`, `test/models_test.rb`,
  `test/launcher_smoke_test.rb`, `test/print_test.rb`,
  `test/identity_test.rb` (new, allowed), `test/chat_test.rb` (ONLY the
  MOTD-identity pins — I31's rebuild pins are in your base and must not be
  touched), `gems/tui-split-rig/runner.rb`, `gems/tui-split-rig/lib/**`,
  `gems/tui-split-rig/test/**`, `gems/tui-split-rig/scenarios/**` (only if
  staging requires). Must NOT touch: `lib/tart/render/chat.rb`,
  `lib/tart/render/transcript.rb`, `lib/tart/compaction.rb`,
  `lib/tart/agent/loop.rb` BEYOND the :311 env-key line (I31's estimator
  threading is in your base — leave it intact), `test/render/**`,
  `test/compaction_test.rb`, `test/agent_loop_test.rb`,
  `gems/tui-split-rig/registry.yml` (I31's class — read, never edit),
  `lib/tart/agent/session.rb`, `lib/tart/prompts.rb`, `test/prompts_test.rb`
  (the /prompts templates feature — unrelated), `test/golden_parity_test.rb`
  (edit-tool goldens — unrelated). No placeholders; search before
  implementing. Out of scope, itemize if tempted: the 4-vs-7 tool loadout
  parity (queued; the golden pins at same-loadout), the `PI_*`/`FOO_*`
  session-env EXPOSURE feature (bash.ts:221 — the port's bash sets none;
  prompt-text parity only), rebranding pi's `<docs>` paths (owner: keep),
  identity-driven anything in the MCP config path beyond the itemized
  bootstrap knob.

```lanes
- name: prompt
  repo: tart
  touch:
    - bin/tart
    - lib/tart/identity.rb
    - lib/tart/agent/system_prompt.rb
    - lib/tart/agent/context_files.rb
    - lib/tart/settings.rb
    - lib/tart/models.rb
    - lib/tart/render/motd.rb
    - test/system_prompt_test.rb
    - test/settings_test.rb
    - test/models_test.rb
    - test/launcher_smoke_test.rb
    - test/print_test.rb
    - test/identity_test.rb
    - test/chat_test.rb
    - gems/tui-split-rig/runner.rb
    - gems/tui-split-rig/lib/**
    - gems/tui-split-rig/test/**
    - gems/tui-split-rig/scenarios/**
```

## Acceptance Criteria

# Acceptance Criteria — I32 prompt-identity

Gate calibration notes: `prompt-wired` and `env-prefix` are tripwires/wiring
proofs (they prove the seam moved, not the bytes); the prompt's byte-parity
substance is the pi-mode golden test (AC2), architect-read. The s7/s8 gates
prove on the integrated tree (I31's class + estimator + header are in this
iteration's base — the fast-follow).

**AC1 (identity free-form).** Any non-empty identity string resolves and
drives the branding: pi and tart keep their existing byte-exact rendering
(pi-mode goldens unchanged; s1_tart green); any other identity (e.g. `foo`)
renders its own name in the preamble and UI text with `Tart::VERSION`, and
its env namespace is `FOO_`. Empty/whitespace values hit the clean-abort
error path. Pinned by identity/launcher tests incl. a `foo` smoke.

**AC2 (the wired prompt).** The launcher composes `Agent::SystemPrompt` on
both the interactive and print paths — the 203-char terse string is gone.
Pi-mode composition is byte-identical to pi's captured system message at the
SAME tool loadout (golden derived from pi's request capture, cwd normalized,
never from the port's own output); the preamble and the bash env-var rule
bullet template the identity (pi mode byte-identical to pi's
system-prompt.ts/bash.ts:47); `<docs>` keeps pi's resolved install paths
(owner ruling 2026-10-12). Pinned by the system_prompt goldens + the
launcher wiring test.

**AC3 (project context).** Context-file discovery follows pi's
resource-loader: the five candidates in pi's order, per-directory
first-match, the ancestor walk, the worktree-shadowing rule; found files
inject as `<project_context>`; none found → no section. Pinned by tests
incl. the shadowing case; the parity scenarios stay bare (neither app's
request carries a section).

**AC4 (the env namespace).** Every app env read routes through the identity
prefix (the settings ENV map, the context-window reads incl. loop.rb's env
tier, the model/provider/api-key seams); `TART_IDENTITY` and
`TART_MCP_CONFIG` remain the only launcher-owned `TART_` literals (both
itemized in the report). The rig stages prefix-aware env for tart and
scrubs parent `PI_*`/`TART_*` inheritance. Proof: the env-prefix gate + the
staging tests + the parity scenarios green.

**AC5 (regression).** The default rake task fully green with run-count
delta > 0; s1–s8 AND s1_tart all exit 0 cold on the integrated tree;
SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs 276eda3d (the pre-I31 tip — this
iteration's tree carries I31's merged work) touches exactly I31's union ∪
this lane's enumerated files, nothing else.

```gates
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart
  expect:
    exit_code: 0

- id: prompt-wired
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/prompt-gate-s1 && ruby -rjson -e 'c = JSON.parse(File.readlines("tmp/prompt-gate-s1/run-1/tart-requests.jsonl")[0])["body"]["messages"][0]["content"]; abort "terse prompt still wired" if c.include?("You are a coding assistant working in"); abort "no preamble" unless c.include?("You are an expert coding assistant operating inside"); abort "no rules section" unless c.include?("<rules>"); abort "no docs section" unless c.include?("<docs>"); abort "no cwd section" unless c.include?("<cwd>"); puts "PROMPT_WIRED"'
  expect:
    exit_code: 0
    stdout_match: PROMPT_WIRED

- id: env-prefix
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -rnE '"TART_[A-Z_]+"' lib bin/tart | grep -vE 'TART_IDENTITY|TART_MCP_CONFIG'; then exit 1; else echo ENV_PREFIX_OK; fi
  expect:
    exit_code: 0
    stdout_match: ENV_PREFIX_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 276eda3d HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|test/chat_test\.rb|test/render/|lib/tart/compaction\.rb|lib/tart/agent/loop\.rb|test/compaction_test\.rb|test/agent_loop_test\.rb|gems/tui-split-rig/registry\.yml|bin/tart|lib/tart/identity\.rb|lib/tart/agent/system_prompt\.rb|lib/tart/agent/context_files\.rb|lib/tart/settings\.rb|lib/tart/models\.rb|lib/tart/render/motd\.rb|test/system_prompt_test\.rb|test/settings_test\.rb|test/models_test\.rb|test/launcher_smoke_test\.rb|test/print_test\.rb|test/identity_test\.rb|gems/tui-split-rig/runner\.rb|gems/tui-split-rig/lib/|gems/tui-split-rig/test/|gems/tui-split-rig/scenarios/)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I32-prompt-identity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section prompt-identity prompt --append --lane <lane> --from build/I32-prompt-identity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I32-prompt-identity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence prompt-identity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section prompt-identity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify prompt-identity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
