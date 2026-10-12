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
   s1_tart exits 1 BY DESIGN (measured this session: tart-mode renders tart's
   own MOTD face vs pi's — 10 unknown-candidate branding lines; the scenario's
   property is tart-mode completion, not parity). All regression claims are
   against this baseline, all measured this session.

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
delta > 0; s1–s8 all exit 0 cold on the integrated tree; s1_tart (the
tart-mode scenario — branding diffs vs pi are BY DESIGN, exit 1) completes:
tart boots, connects through the identity-correct env namespace, and
completes its expected requests; SEAM_BENCH_OK.

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
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

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

### prompt

# Lane dispatch — I32 prompt-identity, lane `prompt`

**You are lane `prompt`** — the single lane of iteration I32 (a FAST-FOLLOW:
your worktree is provisioned off the post-I31 `project/pi-port` tip — I31's
estimator + header work is already in your base; build on it, do not
re-litigate it).

- **Touch (exactly these files):** `bin/tart`, `lib/tart/identity.rb`,
  `lib/tart/agent/system_prompt.rb`, `lib/tart/agent/context_files.rb` (new,
  allowed), `lib/tart/settings.rb`, `lib/tart/models.rb`,
  `lib/tart/render/motd.rb`, `test/system_prompt_test.rb`,
  `test/settings_test.rb`, `test/models_test.rb`,
  `test/launcher_smoke_test.rb`, `test/print_test.rb`,
  `test/identity_test.rb` (new, allowed), `test/chat_test.rb` (ONLY the
  MOTD-identity pins — I31's rebuild pins are in your base and must not be
  touched), `gems/tui-split-rig/runner.rb`, `gems/tui-split-rig/lib/**`,
  `gems/tui-split-rig/test/**`, `gems/tui-split-rig/scenarios/**` (only if
  staging requires).
- **Must not touch:** everything else — in particular
  `lib/tart/render/chat.rb`, `lib/tart/render/transcript.rb`,
  `lib/tart/compaction.rb`, `test/render/**`, `test/compaction_test.rb`,
  `test/agent_loop_test.rb`, `gems/tui-split-rig/registry.yml` (I31's class
  — read, never edit), `lib/tart/agent/loop.rb` BEYOND the :311 env-key line
  (I31's estimator threading is in your base — leave it intact),
  `lib/tart/agent/session.rb`, `lib/tart/prompts.rb`, `test/prompts_test.rb`
  (the /prompts templates feature — unrelated), `test/golden_parity_test.rb`
  (edit-tool goldens — unrelated), `test/support/**` (STOP and raise in
  PHASE 0 if you need it).

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you
have with this spec, with reasons, citing real files in this repo. Silent
compliance is a failure. Silent scope additions are a failure. If you have
no disagreements, state what you checked before concluding the spec is
sound. Verify the named APIs/formats/versions against the live dependencies
before planning around them (notably: pi's system-prompt.ts composition and
its getReadmePath/getDocsPath/getExamplesPath resolution; the
resource-loader context-file walk + worktree shadowing; the gem's
with_instructions; the request-capture oracle at
repos/tart/tmp/parity-gate-s8/run-1/pi-requests.jsonl).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them.
The `:compaction` event payload is I30's frozen contract. You have no access
to the space's architecture/ directory; the architect owns it. The
ACCEPTANCE CRITERIA below are frozen — verify your work against them; never
weaken or work around them. If an AC's letter can only be satisfied by
making the artifact worse than the property the AC asserts, build the right
thing and raise the conflict in your report — name the AC, the conflict, and
the evidence. This is not permission to skip work or weaken a criterion:
the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No
placeholder implementations — search the codebase before implementing; full
implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions; well-factored and DRY-ish;
terse but clear; pragmatic, not clever — the smallest change that does the
job, no abstraction it doesn't need. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim
output. Do NOT commit and do NOT run any git write command. Do NOT delete
lock files or escalate privileges if a command fails; record the exact
error and continue. Do NOT use `run_in_background` (or shell `&`) for your
own work; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout (the parity rig runs take tens
of seconds each — allow 120s+ each). IMPORTANT tmux discipline: a
`tmux kill-server` from you kills every other agent's live sessions on the
shared server — NEVER run it; kill only sessions you created by exact name.
If a runtime will not start unattended, record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When done,
write your report to the scratch file given to you below (an absolute path
OUTSIDE your worktree), with RAW results only — tables, numbers, command
output — no interpretation, no "promising". Every status claim must be
backed by a command result from this run. Keep the report compact — tables
and numbers, not prose. Do not title the report; keep any headings inside
the report at `###` or deeper. End it with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact
blocker + what you tried). Verdicts belong to the architect and the human.
Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

Your scratch report (write RAW results here, never inside your worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I32-prompt-identity-prompt/report.md

## Your lane's specification

- **Objective.** Wire the port's existing faithful prompt builder into the
  launcher, identity-branded and white-labelable: pi's full harness prompt
  (preamble, `<tools>`, `<rules>`, `<docs>`, `<project_context>`,
  `<skills>`, `<cwd>`) replaces the 203-char terse string at `bin/tart:389`,
  the branding and env namespace follow the configured identity
  (pi/tart/foo → `PI_`/`TART_`/`FOO_`), and the missing AGENTS.md discovery
  seam lands so the user's project instructions reach the model. The port's
  `Agent::SystemPrompt` (lib/tart/agent/system_prompt.rb) is a complete,
  golden-tested port of pi's system-prompt.ts currently called only from
  its own tests — you are wiring it in, not writing it.

- **Owner rulings, 2026-10-12 (frozen into this spec):**
  1. **Branding follows Identity — white-labelable out of the box**: any
     non-empty identity value works (`foo` renders "inside foo" and loads
     `FOO_` vars). Not "support pi and tart" — "configure the identity any
     way and it works".
  2. **`<docs>` paths KEEP pi's for now.**
  3. **The `PI_*` env-var rule follows Identity**: pi mode → `PI_`, tart
     mode → `TART_`, foo → `FOO_`.

- Deliver **identity free-form**: any non-empty identity string resolves
  (CLI flag > `TART_IDENTITY` env > settings `identity` > default `pi`);
  `pi` and `tart` keep their existing byte-exact rendering (pi goldens,
  s1_tart); any other identity renders the tart-family face with its own
  name and `Tart::VERSION`. Empty/whitespace-only → the clean-abort error
  path (the I16 seam). The env namespace is `"#{identity.upcase}_"`.

- Deliver **the prompt wiring**: `bin/tart`'s `system_prompt` seam composes
  `Agent::SystemPrompt.build(selected_tools:, cwd:, context_files:,
  docs_paths:, skills:, identity:)` — the terse string is GONE from both the
  interactive (:199) and print (:232) paths. The PREAMBLE templates the
  identity name ("…operating inside <name>, a coding agent harness…"); pi
  mode is byte-identical to pi's. The bash env-var rule bullet
  (system_prompt.rb TOOL_GUIDELINES) templates the prefix ("<PREFIX>_
  environment variables"); pi mode byte-identical to pi's bash.ts:47.
  `<docs>` keeps pi's resolved install paths — verify how pi resolves them
  (getReadmePath/getDocsPath/getExamplesPath) and cite. The golden for
  pi-mode byte parity is derived from pi's CAPTURED request
  (repos/tart/tmp/parity-gate-s8/run-1/pi-requests.jsonl — cwd section
  normalized; same-loadout comparison), never from the port's own output
  (the edit-goldens doctrine).

- Deliver **project-context discovery** (pi resource-loader.ts:175-280):
  the candidates `AGENTS.override.md`/`AGENTS.md`/`AGENTS.MD`/`CLAUDE.md`/
  `CLAUDE.MD`, per-directory first-match, the ancestor walk, and the
  worktree-shadowing rule — port faithfully (new
  `lib/tart/agent/context_files.rb` or inside system_prompt.rb, your call
  within the touch set); thread the found files as `context_files`. No
  files → no `<project_context>` section (the parity sandboxes find none —
  pi's rig requests carry none either; both sides stay bare).

- Deliver **the env namespace**: every app env read routes through the
  identity prefix — the settings ENV map (settings.rb:63-67),
  `TART_CONTEXT_WINDOW` (settings.rb:118 AND loop.rb:311), the
  model/provider/api-key seams (models.rb:123-126, bin/tart:345/:425-426).
  `TART_IDENTITY` and `TART_MCP_CONFIG` stay launcher-owned bootstrap knobs
  (itemized: the identity key cannot depend on its own output; pi reads no
  mcp env). Verify the settings load-order seam: the settings FILE loads,
  identity resolves, THEN env overrides apply with the resolved prefix
  (restructure Settings if needed — it is in your touch set). Launcher help
  text names the mechanism, not hardcoded `TART_MODEL` spellings.

- Deliver **the rig staging**: runner.rb stages prefix-aware env for tart
  (the scenario's identity decides `PI_*` vs `TART_*` keys; the parity
  scenarios run tart in pi mode → `PI_*`); scrub parent-env `PI_*`/`TART_*`
  inheritance so the operator's real `PI_API_KEY` cannot leak into a staged
  run; scenario_test pins update. s1_tart (tart mode) stages `TART_*`
  unchanged.

- **In-worktree gate expectations:** I31 is in your base — s1–s8 ALL
  expected exit 0, plus s1_tart completing (exit ≤ 1 + summary.json shows
  tart completed with expected requests). Your own RED-able gates:
  `prompt-wired` and `env-prefix` (the two tripwires) must pass in your
  worktree.

- **Output format.** Raw evidence to scratch: file list + wc; the seam
  table (pi mechanic → port seam, before/after: preamble/env-rule/docs/
  context discovery/env namespace/rig staging); verbatim test tails + suite
  counts; s1–s8 + s1_tart results from YOUR worktree; the pi-mode prompt
  golden diff (the composed prompt vs pi's captured message, cwd
  normalized, same loadout — verbatim); the white-label smoke (identity
  `foo`: preamble name, `FOO_` resolution, version); itemized
  deviations/cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0
  section). STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install
  --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`;
  parity: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/
  scenarios/<s>.yml --out tmp/<out>`. pi sources (read before coding; cite
  what you port): `packages/coding-agent/src/core/system-prompt.ts` (whole
  file), `src/core/resource-loader.ts:160-280`, `src/core/tools/bash.ts:47
  +221`, the settings env-override shapes in `src/core/settings-manager.ts`,
  `src/modes/interactive/interactive-mode.ts` (how the composed prompt
  reaches the request). The gem's `with_instructions`. The request-capture
  oracle: `repos/tart/tmp/parity-gate-s8/run-1/pi-requests.jsonl`.

- **Out of scope, itemize if tempted:** the 4-vs-7 tool loadout parity
  (queued; the golden pins at same-loadout), the `PI_*`/`FOO_*` session-env
  EXPOSURE feature (bash.ts:221 — the port's bash sets none; prompt-text
  parity only), rebranding pi's `<docs>` paths (owner: keep), identity-
  driven anything in the MCP config path beyond the itemized bootstrap knob.

## Frozen ACCEPTANCE CRITERIA (verify against these; never weaken them)

Gate calibration notes: `prompt-wired` and `env-prefix` are
tripwires/wiring proofs; the prompt's byte-parity substance is the pi-mode
golden test (AC2), architect-read.

**AC1 (identity free-form).** Any non-empty identity string resolves and
drives the branding: pi and tart keep their existing byte-exact rendering
(pi-mode goldens unchanged; s1_tart green); any other identity (e.g.
`foo`) renders its own name in the preamble and UI text with
`Tart::VERSION`, and its env namespace is `FOO_`. Empty/whitespace values
hit the clean-abort error path. Pinned by identity/launcher tests incl. a
`foo` smoke.

**AC2 (the wired prompt).** The launcher composes `Agent::SystemPrompt` on
both the interactive and print paths — the 203-char terse string is gone.
Pi-mode composition is byte-identical to pi's captured system message at
the SAME tool loadout (golden derived from pi's request capture, cwd
normalized, never from the port's own output); the preamble and the bash
env-var rule bullet template the identity (pi mode byte-identical to pi's
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
delta > 0; s1–s8 all exit 0 cold on the integrated tree; s1_tart (the
tart-mode scenario — branding diffs vs pi are BY DESIGN, exit 1) completes:
tart boots, connects through the identity-correct env namespace, and
completes its expected requests; SEAM_BENCH_OK.

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
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

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

## Builder Report

### prompt

### PHASE 0

Verified against live sources before coding (all confirmed):

| Claim | Verification |
| --- | --- |
| pi system-prompt.ts composition | port's `SystemPrompt.build` at pi's 4-tool loadout + capture docs paths + cwd normalized == captured system message, byte-for-byte (2813 B) — pre-build proof |
| pi docs-path resolution | `config.ts:443-457` resolve(join(getPackageDir)); live: `which pi` → symlink → `…/node/24.18.0/lib/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js`; realpath+walk-up reproduces the capture's paths byte-identically |
| resource-loader context walk :182-273 | 5 candidates, per-dir first-match, global agent-dir file first, ancestor walk root-most-first, seen-path dedup, worktree shadow rule (:211-230); feeds prompts via `agent-session.ts` `_rebuildSystemPrompt` :1700-1726 ← `getAgentsFiles` ← `loadProjectContextFiles` (resource-loader.ts:646-655) |
| gem `with_instructions` | ruby_llm 2.1 chat.rb:441-447 — replaces any prior system message; loop.rb:83 wires `@chat.with_instructions(system_prompt)` |
| oracle | `repos/tart/tmp/parity-gate-s8/run-1/pi-requests.jsonl` request 1: 4 tools (read/bash/edit/write), bare 2902 B system message, docs at pi's realpath install, no `<project_context>`/`<skills>` |
| pi settings env shapes | pi's settings-manager has NO model/provider/apiKey env overrides (only VISUAL/EDITOR, PI_CLEAR_ON_SHRINK, PI_HARDWARE_CURSOR) — the port's `RESOLUTION_ENV` is a recorded extension; nothing to mirror |
| env inventory | all `TART_*` literals enumerated (settings.rb:63-67+118, models.rb:123-126, loop.rb:311, bin/tart:345/425/426); only 3 test files stage app env, all in the touch set; no test pins the terse prompt string |
| parity sandboxes bare | no AGENTS.md/CLAUDE.md at any ancestor of the sandbox paths (/, /Users, /Users/eric, …, repos/tart) |

PHASE 0 disagreements (raised pre-code; outcomes):

1. **AC1 "own name in UI text" vs frozen chat.rb:559** — `Motd.tart_header_lines(viewport_width)` carries no identity argument and chat.rb is scope-gate-frozen. Resolution: launcher records the boot face on `Identity.current` (boot-applied render state, `Theme[]` precedent); `Motd.tart_header_lines(width, name = Identity.current)`; family default `tart` keeps the existing chat_test pins passing untouched. Flagged as the one process-global in a threaded seam.
2. **loop.rb env tier under print** — print.rb (frozen) constructs `Agent::Loop` without identity → loop's env tier defaults to pi's namespace. Deviation itemized below.
3. **Golden provenance** — capture lives under gitignored `tmp/`; inlined as the golden literal with derivation recorded instead of a runtime file dependency.
4. **Test-file granularity** — scope gate allows only `test/identity_test.rb` as a new file; context-discovery tests placed in `system_prompt_test.rb` (the `ContextFiles.load → SystemPrompt.build` pair).
5. Line cites in the spec: all checked, accurate; one addition — `Settings.resolve_context_window` is also called from bin/tart `footer_data`, covered by the same threading.

### Seam table (pi mechanic → port seam)

| Mechanic | Before | After |
| --- | --- | --- |
| Preamble | terse 203-char string, bin/tart:389 (both paths) | `Agent::SystemPrompt.build(...)` — identity-templated ("operating inside pi/tart/foo"), pi mode byte-identical; terse string gone from :199/:232 paths |
| Bash env rule (bash.ts:47) | literal `PI_*` | `%s`-templated prefix: pi `PI_*` (byte-identical), tart `TART_*`, foo `FOO_*` |
| `<docs>` | staged test paths only | `SystemPrompt.pi_docs_paths` — realpath(`pi` on PATH) → walk to package.json `@earendil-works/pi-coding-agent` (config.ts getPackageDir algorithm); launcher threads the resolved triple |
| Context discovery | absent (no seam) | new `lib/tart/agent/context_files.rb` — pi resource-loader.ts:182-273 port (5 candidates, first-match, global agent-dir file, ancestor walk, worktree shadowing); injected as `<project_context>`; none → no section |
| Env namespace | literal `TART_*` at 10 sites | `"#{identity.upcase}_"` via `Identity.env_key`; threaded: settings RESOLUTION_ENV (suffix map), resolve_context_window, resolve_boot_model, loop.rb:311 tier, bin/tart require_api_key/build_chat (both paths); `TART_IDENTITY` + `TART_MCP_CONFIG` remain literal bootstrap knobs |
| Settings load order | env read with static key | file loads → identity resolves (CLI > TART_IDENTITY > settings > pi) → env overrides with resolved prefix |
| Rig staging | 5 literal `TART_*` keys, parent env inherited | scenario identity decides prefix (parity → `PI_*`, s1_tart → `TART_*`); `TART_IDENTITY` staged literally; parent `PI_*`/`TART_*` scrubbed via `env -u` on both panes (staged keys exempt) |
| Identity resolution | `VALUES = [pi, tart]`, else error | free-form: any non-empty/non-whitespace; empty/whitespace → `Identity::Error` → `tart: <msg>` clean abort |
| MOTD wordmark | literal `"tart"` | `Identity.current` (boot-recorded), version always `Tart::VERSION` |

### Gates (in-worktree, verbatim)

| Gate | Result |
| --- | --- |
| suite | `586 runs, 2342 assertions, 0 failures, 0 errors, 1 skips` (skip = pre-existing opt-in `TuiSplitRig::LiveRunTest` "set TUI_SPLIT_RIG_LIVE=1") |
| bench | `SEAM_BENCH_OK` |
| s1-parity | exit 0 — pi: completed=true req=1/1, tart: completed=true req=1/1 |
| s2-parity | exit 0 — pi 2/2, tart 2/2, both completed |
| s3-parity | exit 0 — pi 3/3, tart 3/3 |
| s4-parity | exit 0 — pi 3/3, tart 3/3 |
| s5-parity | exit 0 — pi 2/2, tart 2/2 |
| s6-parity | exit 0 — pi 3/3, tart 3/3 |
| s7-parity | exit 0 — pi 2/2, tart 2/2 |
| s8-parity | exit 0 — pi 2/2, tart 2/2 |
| s1-tart-mode | exit 1 (by-design branding diffs) + `TART_MODE_OK` — tart completed=true req=1/1 |
| prompt-wired | `PROMPT_WIRED` (terse string absent; preamble/rules/docs/cwd present) |
| env-prefix | `ENV_PREFIX_OK` (`grep -rnE '"TART_[A-Z_]+"' lib bin/tart | grep -vE 'TART_IDENTITY|TART_MCP_CONFIG'` → empty) |
| scope | substance holds — see AC6 conflict below |

### Per-suite tails (touched suites)

```
test_system_prompt: 14 runs, 56 assertions, 0 failures, 0 errors, 0 skips
test_settings:      25 runs, 103 assertions, 0 failures, 0 errors, 0 skips
test_models:        17 runs, 45 assertions, 0 failures, 0 errors, 0 skips
test_identity:       2 runs,  7 assertions, 0 failures, 0 errors, 0 skips
test_launcher_smoke: 7 runs, 37 assertions, 0 failures, 0 errors, 0 skips
test_print:          4 runs, 17 assertions, 0 failures, 0 errors, 0 skips
test_chat:         170 runs, 716 assertions, 0 failures, 0 errors, 0 skips  (I31 pins untouched, green)
test_agent_loop:    19 runs, 134 assertions, 0 failures, 0 errors, 0 skips
test_compaction:    22 runs, 60 assertions, 0 failures, 0 errors, 0 skips
rig scenario_test:  25 runs, 132 assertions, 0 failures, 0 errors, 0 skips
```

### Pi-mode prompt golden diff (AC2)

Derived from `repos/tart/tmp/parity-gate-s8/run-1/pi-requests.jsonl` request 1 system message; `<cwd>` section normalized to CWD_PLACEHOLDER; composed at pi's 4-tool loadout with the capture's docs triple:

```
GOLDEN_DIFF_EMPTY (4-tool loadout, cwd normalized)   # norm(captured) == norm(port built) — zero diff
```

Live parity-gate capture facts (s1, both apps on this tree):

```
gate tart preamble: You are an expert coding assistant operating inside pi, a coding agent harness.
gate: pi vs tart <docs> sections identical: true
gate: pi project_context present: false | tart project_context present: false   # both sides bare
gate tart loadout: 7-tool default (queued 4-vs-7 parity: delta confined to the <tools> list + find/grep/ls rule bullets)
```

### White-label smoke (identity `foo`, real `bin/tart --identity foo -p hi` vs MockLLMServer)

```
exit=0 stdout="foo-ok"
preamble: You are an expert coding assistant operating inside foo, a coding agent harness. You help users by reading files, executing commands, editing code, and writing new files.
bash-rule: - You can inspect FOO_* environment variables for current model and session details.
auth: Bearer foo-key                                        # FOO_API_KEY reached the wire
MOTD wordmark (unit): " foo v0.1.0", no "tart v" leak       # test_identity_test 2 runs green
```

### Parity-rig catches during the lane (raw)

```
run 1: tart pane dead, 0 requests, empty capture → interactive call site still
       `system_prompt(workdir, skills.skills)` (arity crash) → fixed to
       `system_prompt(workdir, settings, skills.skills, identity)`
run 2: s1_tart stderr: `PI_API_KEY is not set (see --help).` → interactive
       `require_api_key(settings, models)` unthreaded → fixed to
       `require_api_key(settings, models, identity:)`
run 3: s1_tart exit 1 + TART_MODE_OK
```

### Files touched (all in the lane set)

```
 M bin/tart                                   492 lines
 M gems/tui-split-rig/lib/tui_split_rig/runner.rb
 M gems/tui-split-rig/test/scenario_test.rb
 M lib/tart/agent/loop.rb                     584 lines  (kwarg + :311 env line + docs only; I31 estimator intact)
 M lib/tart/agent/system_prompt.rb            203 lines
 M lib/tart/identity.rb                        66 lines
 M lib/tart/models.rb                         228 lines
 M lib/tart/render/motd.rb                    185 lines  (one signature line + name span)
 M lib/tart/settings.rb                       270 lines
 M test/launcher_smoke_test.rb
 M test/models_test.rb
 M test/settings_test.rb
 M test/system_prompt_test.rb
 A lib/tart/agent/context_files.rb            132 lines (new)
 A test/identity_test.rb                       48 lines (new)
```

Not touched: `test/chat_test.rb` (MOTD-identity pins passed unchanged), `lib/tart/print.rb`, `lib/tart/render/chat.rb`, `test/support/**`, `registry.yml`, all other out-of-scope files. No git write commands run (one `git stash` attempt was blocked by the builder guard — correct; no state changed).

### AC6 conflict (reported, not resolved)

The frozen `scope` gate regex cannot match its own intended prefixes: branches `test/render/`, `gems/tui-split-rig/lib/`, `gems/tui-split-rig/test/`, `gems/tui-split-rig/scenarios/` end at `/` before the pattern's `$` anchor, so no file under those directories can ever match.

Evidence:
```
$ echo gems/tui-split-rig/lib/tui_split_rig/runner.rb | grep -qE '<gate regex>' ; echo $?
1   (NO_MATCH — runner.rb is in the lane's enumerated set yet fails the gate)
$ git diff --name-only 276eda3d HEAD | grep -qvE '<gate regex>' ; # committed I31 base alone
gems/tui-split-rig/test/registry_test.rb   (base commit 64d30af fails the gate with zero lane work)
```
Substance holds — union of committed I31 diff + this lane's worktree vs 276eda3d contains nothing outside I31's enumerated files ∪ the lane set:
```
UNION_CLEAN — nothing outside I31 ∪ lane set
```
Also noted: the spec's touch-list entry `gems/tui-split-rig/runner.rb` has no such file; the runner lives at `gems/tui-split-rig/lib/tui_split_rig/runner.rb` (edited there).

### Itemized deviations/cuts

1. **`Identity.current` process-global** (disagreement 1): the MOTD wordmark reads the boot-recorded face because chat.rb:559's call carries no identity argument and chat.rb is scope-frozen. Launcher sets it in `resolve_identity` (both paths). Default `tart` = family mark; chat_test pins green untouched.
2. **Print-mode env tier** (disagreement 2): `print.rb` (frozen) constructs `Agent::Loop` without `identity:` → the loop's `<IDENTITY>_CONTEXT_WINDOW` env tier defaults to `PI_` in print mode. Pi-mode (default + all parity scenarios) and the interactive path (launcher-threaded) unaffected.
3. **`docs_paths: nil` → no `<docs>` section**: pi can never be in the unresolvable state; the previous behavior on nil was a crash in `sections`. On the parity target the resolver always resolves (pinned by `test_pi_docs_paths_resolve_pis_install`).
4. **7-tool loadout in live runs**: the launcher composes the settings-resolved loadout (7 default tools); the golden pins pi's captured 4-tool loadout. 4-vs-7 parity remains queued (spec out-of-scope).
5. **Session-env exposure (bash.ts:221)**: not implemented (spec out-of-scope); prompt-text parity only — the `PI_*`/`FOO_*` rule bullet renders, no env is SET by the port's bash tool.
6. **`<docs>` text/paths stay pi's for every identity** (owner ruling 2): foo/tart renders the same "Pi documentation …" block with pi's install paths.
7. **Help text**: Environment section now names the mechanism (`<IDENTITY>_*` rows + the two literal `TART_` bootstrap knobs); the `--identity` help says "any non-empty name (default pi)".
8. **`TART_IDENTITY`, `TART_MCP_CONFIG`**: the only literal `TART_` env keys in lib/ + bin/tart (env-prefix gate output).

STATUS: COMPLETE_WITH_CONCERNS — (a) frozen scope-gate regex has dead prefix branches and fails even on the committed I31 base (AC6 substance holds, evidence above — needs a gate-text fix by the architect); (b) `Identity.current` process-global introduced for the MOTD wordmark (chat.rb frozen — the only threadable-free path); (c) print-mode loop env tier defaults to pi's namespace for non-pi identities (print.rb frozen).

## Verdict

# Verdict — I32 prompt-identity

Judged 2026-10-12 in a fresh session (dispatched nothing). Integration: lane
`prompt` merged `--no-ff` → project/pi-port 8638aa72 (--accept-bounds, ruled
below). Diff vs BRIEF §3 (daily-driver parity) + §8 (settled-screen parity
program) — the highest-leverage §3 gap (the model never saw the user's
AGENTS.md; the terse 203-char prompt shaped every turn) is closed.

## Mechanical post-flight (all verified this session, not taken from the report)

- (a) Frozen region untouched: `git diff 8702bfbd HEAD -- architecture/I32-prompt-identity.md` shows only the Builder-Prompt placeholder replacement + appended Report/Verdict.
- (b) No builder commits: worktree HEAD == base 64d30af (the builder guard blocked its one `git stash` attempt — no state changed).
- (c) Scratch report present, raw evidence only (STATUS: COMPLETE_WITH_CONCERNS).
- (d) In-bounds: `architect verify` FAILed on `lib/tart/agent/loop.rb` — ruled a spec-authoring defect, `--accept-bounds` applied (below).

## Rulings — PHASE 0 disagreements (1–5) and STATUS concerns (a–c)

1. **MOTD wordmark via `Identity.current` process-global (disagreement 1 / concern b) — ACCEPT.** chat.rb:559 carries no identity argument and chat.rb is frozen for this lane; the boot-recorded face (`Theme[]` precedent) is the only threadable-free path, the default keeps chat_test pins green untouched, and the global is written once at resolve time. Carry-in for whenever chat.rb next opens: thread the face explicitly and retire the global.
2. **Print-mode loop env tier defaults to PI_ (disagreement 2 / concern c) — ACCEPT, itemized.** print.rb is frozen and constructs `Agent::Loop` without `identity:`; the kwarg defaults to pi. Interactive (the daily-driver path) and all parity scenarios thread the resolved face. Fix rides the next print.rb-opening iteration.
3. **Golden inlined as a test literal (disagreement 3) — ACCEPT, provenance verified.** tmp/ is gitignored; a runtime file dependency would be flaky. I re-derived it myself this session: the inlined literal == pi's captured system message byte-for-byte (cwd-normalized), and `SystemPrompt.build` at the 4-tool loadout == the capture. The doctrine (golden from pi's capture, never the port's output) is honored.
4. **Context tests in system_prompt_test.rb (disagreement 4) — ACCEPT.** The scope gate only admits test/identity_test.rb as new; the `ContextFiles.load → SystemPrompt.build` pair belongs together anyway.
5. **`Settings.resolve_context_window` also called from footer_data (disagreement 5) — ACCEPT.** Same threading covers it.
6. **Scope-gate regex defect (concern a) — ACCEPT as INVALID, AC6 proven directly (below).** Verified myself: the frozen pattern's directory branches (`test/render/`, `gems/tui-split-rig/lib/` …) end at `/` before `$` and can never match a file; the committed I31 base ALONE fails the gate (`registry_test.rb`). My independent union check (I31 diff ∪ lane worktree vs 276eda3d, prefix branches corrected): nothing outside I31 ∪ lane set. Gate INVALID; AC6 substance PASS.

## Spec-authoring defects (mine, recorded)

- **Scope-gate regex**: dead prefix branches + `gems/tui-split-rig/runner.rb` names a nonexistent file (the runner is `lib/tui_split_rig/runner.rb`). Corrected pattern for the next freeze needing one: `…|gems/tui-split-rig/(lib|test|scenarios)/`.
- **`lanes` touch-set omitted loop.rb** while the prose sanctioned the :311 env-key edit and the scope pattern lists the file — three boundary statements, one wrong. The builder's edit (identity kwarg + env-key line + docs) is exactly the minimal mechanical form of the sanctioned change; I31's estimator threading verified intact. `--accept-bounds` with reason recorded in space.yaml. Carry-in: the lanes block is the source of truth — prose and pattern must be generated from it, never hand-written alongside.

## Per-AC

- **AC1 (identity free-form) — PASS.** Free-form resolve with clean-abort on empty/whitespace; pi/tart byte-exact (s1_tart TART_MODE_OK cold; chat_test pins untouched); `foo` smoke on the wire: preamble "inside foo", FOO_API_KEY auth'd, MOTD " foo v0.1.0".
- **AC2 (the wired prompt) — PASS.** Terse string gone from both paths (bin/tart:204/:239); composed prompt == pi's captured system message byte-for-byte at the same loadout (verified independently this session); preamble + bash env-rule templated (pi mode byte-identical); `<docs>` resolves pi's real install (live resolver == capture triple).
- **AC3 (project context) — PASS.** Faithful resource-loader port (line-cited); candidates order, ancestor walk root-most-first with global-first, dedup, worktree shadowing (with control) all pinned by real-fixture tests; parity scenarios bare both sides (verified in the gate captures).
- **AC4 (env namespace) — PASS.** ENV_PREFIX_OK cold; `TART_IDENTITY`+`TART_MCP_CONFIG` the only literals (itemized); settings load order restructured (file → identity → prefixed env); rig staging prefix-aware with parent PI_*/TART_* scrub (`env -u`, staged keys win).
- **AC5 (regression) — PASS.** Suite 586 runs / 2342 assertions / 0 failures cold (delta +21 runs vs the 565 baseline); SEAM_BENCH_OK; s1–s8 exit 0 cold; s1_tart TART_MODE_OK.
- **AC6 (scope) — PASS** (gate INVALID, substance proven directly — see ruling 6). Integrated diff touches exactly I31's union ∪ the lane set.

## Gates (cold, integration tree 8638aa72)

13 PASS (suite, bench, s1–s8, s1-tart-mode, prompt-wired, env-prefix), 1 INVALID (scope — instrument defect, not a result defect).

## Iteration call: CONTINUE

The port's model-facing seam is now pi's: the harness prompt, the identity
namespace, and the user's project instructions all reach the wire. The one
decisive reason: AC2's byte-parity is proven against pi's own captured request,
not a self-derived golden — the strongest form of §8's oracle discipline.

Follow-ups queued (backlog, not blockers): print-mode identity threading (ruling
2), `Identity.current` retirement when chat.rb opens (ruling 1), 4-vs-7 tool
loadout parity (standing, out of scope by spec), session-env EXPOSURE (bash.ts:221).
