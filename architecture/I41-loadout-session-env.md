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

# Specification — I41 loadout-session-env

- **Objective.** Close the three I32 residuals + the queued superset
  disposition (plan ENTRY 5): the boot tool loadout becomes pi's default-4
  honoring `defaultTools` (a DELIBERATE behavior change toward BRIEF §8 —
  Grounds 2), the bash tool exposes the session env to executed commands as
  the identity-prefixed analog of pi's five `PI_*` vars (Grounds 3), and the
  print path threads the resolved identity so the loop's env tier follows the
  face (Grounds 4). One seam family: the loadout feeds the prompt + wire from
  ONE resolved list; the env exposure feeds from the session state the
  launcher already owns; print identity is one kwarg. Why now: the owner's
  §8 bar is "indistinguishable" — the prompt's `<tools>`/`<rules>` and the
  request's tool array are model-visible on EVERY turn, and pi's own docs
  tell the model to read the session env vars.

- **Lane `core`** (repo `repos/tart`; ONE lane — all three items share
  bin/tart and the settings/registry machinery; chat.rb is single-writer):
  1. **The loadout base.** `Settings::DEFAULT_TOOLS` becomes
     `%w[read bash edit write]` — pi's `DEFAULT_TOOL_NAMES` order
     (settings-manager.ts:82) — and the stale "recorded divergence" comment
     flips to the parity note (pi's list, I41). The I10 modifier machinery
     (`selected_tools`/`apply_tool_modifiers`/`merge_default_tools`) is
     UNCHANGED — it already implements pi's semantics on the base.
     Re-pin the two base-bearing modifier tests (settings_test.rb:378-380 →
     `["+mcp"]` ⇒ `%w[read bash edit write mcp]`, `["-bash"]` ⇒
     `%w[read edit write]`); the base-independent merge/replain pins must NOT
     move. Document the new default + the escape hatch: README's
     `defaultTools` row (`read bash edit write`; `+find`/plain lists restore
     any superset) and `--help`'s Settings paragraph (name the default-4 and
     the +/− semantics).
  2. **The registry order.** `Tools::Registry.build` preserves the SELECTED
     list's order (today `TOOL_CLASSES.slice(*selected)` yields the
     receiver's order — registry.rb:53): the builtins hash is keyed in
     `selected` order, so `Agent::Loop`'s `with_tools(*tools.values)`
     (loop.rb:101) declares the wire tools in the resolved-list order —
     pi `_applyToolLoadout` (agent-session.ts:1571-1581). At default
     configuration the wire array is `["read","bash","edit","write"]` (this
     session's capture, Grounds 1); under modifiers, the resolved list's
     order. Pin in tools_test (order-sensitive keys assertion; the existing
     `.sort` assertions stay green).
  3. **The prompt at default = pi's bytes.** No system_prompt.rb change is
     needed for composition (it already composes from the resolved
     selected_tools, pi-ordered once the base flips). Freeze the golden:
     a system_prompt_test pin asserting the `<tools>` and `<rules>` sections
     built from `Settings.selected_tools({})` equal pi's captured bytes
     VERBATIM (the Grounds 5 literals — inlined with the derivation
     recorded in the test comment; never the port's own output). The
     loadout-conditional bullet ("Use bash for file operations like ls, rg,
     find") and the read → bash → edit → write guideline order are the
     loadout-bearing bytes this pin protects.
  4. **Session-env exposure (the port of `resolveSpawnContext`).**
     `Tools::Bash` gains `identity:` (default `Identity::DEFAULT`) and
     `session_env:` — a hash of SUFFIX ("SESSION_ID", "SESSION_FILE",
     "PROVIDER", "MODEL", "REASONING_LEVEL") → callable, resolved AT SPAWN
     TIME (pi resolves per command start — a mid-session model switch or
     level change reaches the next command). The TOOL path (`execute` →
     `spawn_and_stream`) composes the child env pi-exactly: base = a copy of
     ENV; DELETE the five `<PREFIX>_<SUFFIX>` keys from the copy (inherited
     parent values never leak — the scrub happens even when a reader nils);
     then, for each reader returning a truthy value, set
     `Identity.env_key(identity, suffix)`; spawn with the composed env
     (`unsetenv_others: true` so deletions are real). `run_user` (user
     `!`/`!!`) keeps today's plain inheritance — pi's user-bash executor
     passes no env and never scrubs (Grounds 3). No settings toggle (pi has
     none; exposure is always on where the launcher wires readers).
     `Tools::Registry.build` threads `identity:` + `session_env:` through to
     Bash (the other built-ins ignore them).
  5. **The reader wiring (both launcher paths).** `bin/tart` composes the
     session_env hash: INTERACTIVE — readers over the surface:
     `surface.agent&.recorder&.id` (SESSION_ID), `surface.agent&.recorder&.path`
     (SESSION_FILE — the recorder is persistent-shaped when present),
     `surface.current_model_ref` (PROVIDER/MODEL — the catalog provider key
     + id, OQ-2; make `current_model_ref` public — ONE line in chat.rb), and
     `surface.agent&.thinking_level` (REASONING_LEVEL). `/new` and resume swap
     `surface.agent`/the recorder — the readers are live through the
     accessor, so the env always describes the CURRENT session (pi's
     per-command resolution). `Agent::Loop` gains `attr_reader :recorder`
     (ONE line; loop.rb:84's field). PRINT — readers over the boot pair
     (`boot[:provider]`/`boot[:id]`) + the print level, with SESSION_ID a
     minted `Session.uuidv7` and SESSION_FILE nil (OQ-3: pi's ephemeral
     session shape; print recording is the standing I07 cut, out of scope).
     `build_tools` gains the `identity:`/`session_env:` passthrough; both
     call sites updated.
  6. **The print identity tier.** `Print.run` gains `identity:` (default
     `Identity::DEFAULT`), forwarded to `Agent::Loop.new` — the loop's env
     tier (loop.rb:358-362) then reads `<PREFIX>_CONTEXT_WINDOW` under the
     resolved face on the print path too. `bin/tart`'s print path passes the
     already-resolved identity (bin/tart:206). Existing `Print.run` tests
     pass no identity — the default keeps them green; add the forwarding pin.
  7. **The hermetic env-exposure pin family** (bash_tool_test): (a) the five
     vars present with correct sources when readers return values; (b) a
     nil-ing reader leaves its var UNSET but still SCRUBS an inherited value;
     (c) inherited parent `<PREFIX>_SESSION_ID` never reaches the child
     (set ENV in-test, restore); (d) `run_user` does NOT expose (and does
     NOT scrub — pi's user path); (e) identity prefixes — pi mode renders
     `PI_*`, tart `TART_*`, foo `FOO_*`; (f) values resolve at spawn (a
     reader whose value changes between two executes is honored twice);
     (g) pi-mode parity shape: exactly pi's five key names, no extras.

- **Output format.** Raw evidence to scratch: file list + wc; the seam table
  (pi mechanic → port seam, before/after: default loadout, registry order,
  session env, print identity); verbatim test tails + suite counts; s1–s9
  exit codes from YOUR worktree at the CANONICAL out dirs (Grounds 1's
  environmental note — long out-dir prefixes are not evidence); the loadout
  gate output verbatim (tart's wire tools + the golden section diff); the
  env-exposure pin output; the white-label smoke (identity `foo`: FOO_-prefixed
  session vars through the print path); itemized deviations/cuts. PHASE 0
  disagreements mandatory (a labeled PHASE 0 section). STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet
  && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/
  <s>.yml --out tmp/parity-gate-<sN>` (canonical SHORT out dirs). pi sources
  (read before coding; cite what you port): `src/core/settings-manager.ts:
  82-144` (DEFAULT_TOOL_NAMES + modifiers), `src/core/tools/bash.ts:186-280`
  (resolveSpawnContext + options + the prompt coupling), `src/core/tools/
  index.ts` + `src/core/agent-session.ts:1571-1581` (loadout order),
  `src/core/session-manager.ts:987-1080` (session id/file), `docs/
  environment-variables.md` (the five-var table + the user-bash exclusion),
  `src/utils/shell.ts:138-149` (getShellEnv). Port seams: settings.rb,
  tools/registry.rb, tools/bash.rb, agent/loop.rb, render/chat.rb
  (current_model_ref), print.rb, bin/tart (build_tools + both paths).

- **Boundaries.** Touch EXACTLY: `lib/tart/settings.rb`,
  `lib/tart/tools/registry.rb`, `lib/tart/tools/bash.rb`,
  `lib/tart/agent/loop.rb` (the `attr_reader :recorder` line + its doc
  comment ONLY — the I31/I36 estimator/thinking seams in your base stay
  intact), `lib/tart/render/chat.rb` (the `public :current_model_ref` line
  ONLY — nothing else in chat.rb moves), `lib/tart/print.rb`, `bin/tart`,
  `README.md`, `test/settings_test.rb`, `test/tools_test.rb`,
  `test/bash_tool_test.rb`, `test/system_prompt_test.rb`,
  `test/print_test.rb`, `test/agent_loop_test.rb` (additive only — the
  recorder reader + any env-tier pins). Must NOT touch:
  `lib/tart/agent/system_prompt.rb` (composes from the resolved list
  already — if you believe it needs an edit, STOP and raise it in PHASE 0),
  `lib/tart/agent/session.rb`, `lib/tart/agent/context_files.rb`,
  `lib/tart/identity.rb`, `lib/tart/models.rb`, `lib/tart/tools.rb`,
  `lib/tart/render/transcript.rb`, `lib/tart/compaction.rb`,
  `lib/tart/render/motd.rb`, `test/chat_test.rb`, `test/render/**`,
  `test/compaction_test.rb`, `test/support/**` (STOP and raise in PHASE 0 if
  you need it), `gems/tui-split-rig/**` (NO rig edits — Grounds 7), `bench/**`,
  `*.gemspec`, `Gemfile*`. Out of scope, itemize if tempted: print-mode
  session RECORDING (OQ-3), the process markers `AI_AGENT`/`PI_CODING_AGENT`
  (OQ-4), a settings toggle for exposure (pi has none), MCP env changes,
  getShellEnv's PATH-prepend (no shim dir to prepend), any prompt-text change
  beyond what the resolved loadout already composes.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/settings.rb
    - lib/tart/tools/registry.rb
    - lib/tart/tools/bash.rb
    - lib/tart/agent/loop.rb
    - lib/tart/render/chat.rb
    - lib/tart/print.rb
    - bin/tart
    - README.md
    - test/settings_test.rb
    - test/tools_test.rb
    - test/bash_tool_test.rb
    - test/system_prompt_test.rb
    - test/print_test.rb
    - test/agent_loop_test.rb
```

## Acceptance Criteria

# Acceptance Criteria — I41 loadout-session-env

Gate calibration: `loadout-pin`, `env-pin`, and `print-identity-pin` are the
iteration's NEW-capability gates — RED at base BY DESIGN (the base ships the
7-tool superset, no session env, and the pi-default print tier); they must be
GREEN on the integrated tree, non-vacuously (each asserts ≥1 matching test
run / exact wire content). The s-gates keep the CANONICAL short out dirs
(Grounds 1's environmental note). AC6's scope diff is against **9f8c8d7**
(the pre-iteration integrated tip).

**AC1 (the default-4 loadout).** `Settings.selected_tools({})` resolves to
pi's `DEFAULT_TOOL_NAMES` list — `["read","bash","edit","write"]`, in ORDER —
and the I10 modifier semantics hold on the new base (plain replace; `+name`
appends; `-name` removes; all-modifier lists ride the base; layered
mergeDefaultTools unchanged). The README `defaultTools` row and `--help`
state the new default and the `+find`-style escape hatch. Pinned by
re-pinned settings tests (the two base-bearing modifier cases move; the
base-independent pins do not).

**AC2 (wire + prompt order follow the resolved list).** `Tools::Registry.
build` preserves the SELECTED order: at default configuration the request's
tools array is exactly `["read","bash","edit","write"]` (pi's captured wire
order), and under modifiers the resolved list's order. The composed prompt's
`<tools>` rows and `<rules>` bullets follow the same list — at default the
`<rules>` section opens with the loadout-conditional bullet ("Use bash for
file operations like ls, rg, find") and orders per-tool guidelines read →
bash → edit → write. Pinned by the loadout-pin gate (wire array + both
sections byte-compared against pi's captured bytes, Grounds 5) and an
inlined-golden system_prompt test with the derivation recorded.

**AC3 (session-env exposure, pi's five).** The bash TOOL path composes the
child env as pi's `resolveSpawnContext` analog: the five
`<PREFIX>_<SUFFIX>` keys (`SESSION_ID`, `SESSION_FILE`, `PROVIDER`, `MODEL`,
`REASONING_LEVEL` under `Identity.env_key`) are scrubbed from a copy of ENV,
then set from LIVE readers resolved at spawn (nil reader → unset). Provider/
model are the CATALOG pair (surface `current_model_ref` / boot pair — OQ-2),
session id/file from the current recorder (interactive) or a minted
ephemeral id with no file (print — OQ-3), level from the loop's current
level. `run_user` (`!`/`!!`) exposes NOTHING and does not scrub (pi's user
path). No settings toggle exists (pi has none). Pinned by the hermetic
bash_tool family: sources, nil-conditionals + scrub, parent-leak guard,
run_user exclusion, identity prefixes (PI_/TART_/FOO_), per-spawn
resolution, exactly-pi's-five shape.

**AC4 (print identity tier).** `Print.run` forwards the resolved identity
into `Agent::Loop`, so the print path's loop env tier reads
`<PREFIX>_CONTEXT_WINDOW` under the resolved face (tart → `TART_`, foo →
`FOO_`) instead of the pi default. Pinned by print/agent-loop tests
(forwarding + the tier readback); existing no-identity Print.run tests stay
green on the default.

**AC5 (regression).** The default rake task fully green with run-count
delta > 0; s1–s9 exit 0 cold at the canonical out dirs; s1_tart (the
tart-mode scenario) completes: tart boots, connects, and completes its
expected requests; SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs 9f8c8d7 touches exactly the lane's
enumerated files, nothing else — in particular NO `gems/tui-split-rig/**`
file, and `lib/tart/agent/system_prompt.rb`, `lib/tart/identity.rb`,
`test/chat_test.rb`, and `lib/tart/agent/session.rb` are untouched.

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

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
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

- id: loadout-pin
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/loadout-gate-s1 && ruby -rjson -e 'req = JSON.parse(File.readlines("tmp/loadout-gate-s1/run-1/tart-requests.jsonl")[0]); tools = req["body"]["tools"].map { |t| t.dig("function", "name") }; abort "wire loadout: #{tools.inspect}" unless tools == %w[read bash edit write]; sys = req["body"]["messages"][0]["content"]; golden_tools = "- read: Read file contents\n- bash: Execute bash commands (ls, grep, find, etc.)\n- edit: Make precise changes with exact text replacement, including multiple disjoint edits in one call\n- write: Create or overwrite files\n\nIn addition to the tools above, you may have access to other custom tools depending on the project."; golden_rules = "- Use bash for file operations like ls, rg, find\n- Use read to examine files instead of cat or sed.\n- You can inspect PI_* environment variables for current model and session details.\n- Use edit for precise changes (edits[].oldText must match exactly)\n- When changing multiple separate locations in one file, use one edit call with multiple entries in edits[] instead of multiple edit calls\n- Each edits[].oldText is matched against the original file, not after earlier edits are applied. Do not emit overlapping or nested edits. Merge nearby changes into one edit.\n- Keep edits[].oldText as small as possible while still being unique in the file. Do not pad with large unchanged regions.\n- Use write only for new files or complete rewrites.\n- Be concise in your responses\n- Show file paths clearly when working with files"; tools_section = sys[/<tools>\n(.*?)\n<\/tools>/m, 1]; abort "tools section diverges:\n#{tools_section}" unless tools_section == golden_tools; rules_section = sys[/<rules>\n(.*?)\n<\/rules>/m, 1]; abort "rules section diverges:\n#{rules_section}" unless rules_section == golden_rules; puts "LOADOUT_PIN_OK"'
  expect:
    exit_code: 0
    stdout_match: LOADOUT_PIN_OK

- id: env-pin
  ac: AC3
  cwd: repos/tart
  cmd: |-
    out=$(bundle exec ruby -Itest test/bash_tool_test.rb -n /session_environment/ 2>&1); ec=$?; echo "$out" | tail -3; [ "$ec" -eq 0 ] && echo "$out" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo ENV_PIN_OK
  expect:
    exit_code: 0
    stdout_match: ENV_PIN_OK

- id: print-identity-pin
  ac: AC4
  cwd: repos/tart
  cmd: |-
    out1=$(bundle exec ruby -Itest test/print_test.rb -n '/identity/' 2>&1); ec1=$?; echo "$out1" | tail -3; out2=$(bundle exec ruby -Itest test/agent_loop_test.rb -n '/env_tier|recorder/' 2>&1); ec2=$?; echo "$out2" | tail -3; [ "$ec1" -eq 0 ] && echo "$out1" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && [ "$ec2" -eq 0 ] && echo "$out2" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo PRINT_IDENTITY_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_IDENTITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 9f8c8d7 HEAD | grep -qvE '^(lib/tart/settings\.rb|lib/tart/tools/registry\.rb|lib/tart/tools/bash\.rb|lib/tart/agent/loop\.rb|lib/tart/render/chat\.rb|lib/tart/print\.rb|bin/tart|README\.md|test/settings_test\.rb|test/tools_test\.rb|test/bash_tool_test\.rb|test/system_prompt_test\.rb|test/print_test\.rb|test/agent_loop_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

# Lane dispatch — I41 loadout-session-env, lane `core`

**You are lane `core`** — the single lane of iteration I41 (base
`project/pi-port` @ 9f8c8d7, the I40-integrated tip; working tree clean).

- **Touch (exactly these files):** `lib/tart/settings.rb`,
  `lib/tart/tools/registry.rb`, `lib/tart/tools/bash.rb`,
  `lib/tart/agent/loop.rb` (the `attr_reader :recorder` line + its doc
  comment ONLY — the I31/I36 estimator/thinking seams in your base stay
  intact), `lib/tart/render/chat.rb` (the `public :current_model_ref` line
  ONLY — nothing else in chat.rb moves), `lib/tart/print.rb`, `bin/tart`,
  `README.md`, `test/settings_test.rb`, `test/tools_test.rb`,
  `test/bash_tool_test.rb`, `test/system_prompt_test.rb`,
  `test/print_test.rb`, `test/agent_loop_test.rb` (additive only — the
  recorder reader + any env-tier pins).
- **Must not touch:** everything else — in particular
  `lib/tart/agent/system_prompt.rb` (it already composes from the resolved
  loadout; if you believe it needs an edit, STOP and raise it in PHASE 0),
  `lib/tart/agent/session.rb`, `lib/tart/agent/context_files.rb`,
  `lib/tart/identity.rb`, `lib/tart/models.rb`, `lib/tart/tools.rb`,
  `lib/tart/render/transcript.rb`, `lib/tart/compaction.rb`,
  `lib/tart/render/motd.rb`, `test/chat_test.rb`, `test/render/**`,
  `test/compaction_test.rb`, `test/support/**` (STOP and raise in PHASE 0 if
  you need it), `gems/tui-split-rig/**` (NO rig edits — the scenarios need
  none; Grounds 7), `bench/**`, `*.gemspec`, `Gemfile*`.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you
have with this spec, with reasons, citing real files in this repo. Silent
compliance is a failure. Silent scope additions are a failure. If you have
no disagreements, state what you checked before concluding the spec is
sound. Verify the named APIs/formats/versions against the live dependencies
before planning around them (notably: pi's `resolveSpawnContext`
bash.ts:186-208 and its five vars; `DEFAULT_TOOL_NAMES` +
`_applyToolLoadout`'s name-order rule; the port's `Settings.selected_tools`
base/modifier machinery; `Process.spawn` env semantics —
`unsetenv_others:`; `Session.uuidv7`; `Identity.env_key`).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them.
You have no access to the space's architecture/ directory; the architect
owns it. The ACCEPTANCE CRITERIA below are frozen — verify your work
against them; never weaken or work around them. If an AC's letter can only
be satisfied by making the artifact worse than the property the AC asserts,
build the right thing and raise the conflict in your report — name the AC,
the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No
placeholder implementations — search the codebase before implementing; full
implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions; well-factored and DRY-ish;
terse but clear; pragmatic, not clever — the smallest change that does the
job, no abstraction it doesn't need. Tests stay simple and terse,
exercising public behavior, no mock/stub of the class under test. Verify
your work by running the acceptance criteria's gate commands and record the
verbatim output. Do NOT commit and do NOT run any git write command. Do NOT
delete lock files or escalate privileges if a command fails; record the
exact error and continue. Do NOT use `run_in_background` (or shell `&`) for
your own work; run long commands serially in the foreground instead. Give
every potentially long command an explicit timeout (the parity rig runs
take tens of seconds each — allow 120s+ each). IMPORTANT tmux discipline: a
`tmux kill-server` from you kills every other agent's live sessions on the
shared server — NEVER run it; kill only sessions you created by exact name.
IMPORTANT out-dir discipline: the parity gates keep the CANONICAL short out
dirs (`tmp/parity-gate-sN`, `tmp/loadout-gate-s1`) — longer out-dir prefixes
move staged-path wrap points and produce exit-1 artifacts (Grounds 1; the
I39/I40 environmental family). If a runtime will not start unattended,
record the exact failure in your report and route around it — never
busy-wait or retry in a loop. When done, write your report to the scratch
file given to you below (an absolute path OUTSIDE your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE |
COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you
tried). Verdicts belong to the architect and the human. Persist until your
lane is fully handled end-to-end; do not stop at analysis or partial fixes.

Your scratch report (write RAW results here, never inside your worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I41-loadout-session-env-core/report.md

## Your lane's specification

- **Objective.** Close the three I32 residuals + the queued superset
  disposition: the boot tool loadout becomes pi's default-4 honoring
  `defaultTools` (a DELIBERATE behavior change toward BRIEF §8 — Grounds 2),
  the bash tool exposes the session env to executed commands as the
  identity-prefixed analog of pi's five `PI_*` vars (Grounds 3), and the
  print path threads the resolved identity so the loop's env tier follows
  the face (Grounds 4). Read the Grounds and Specification sections of
  architecture/I41-loadout-session-env.md — this dispatch carries the
  lane's Operating rules + boundaries; the spec's item numbers are
  normative.

- **Deliverable 1 — the loadout base (spec item 1).** `Settings::
  DEFAULT_TOOLS` becomes `%w[read bash edit write]` — pi's
  `DEFAULT_TOOL_NAMES` order (settings-manager.ts:82) — the stale
  "recorded divergence" comment flips to the parity note. The I10 modifier
  machinery is UNCHANGED. Re-pin the two base-bearing modifier tests
  (settings_test.rb:378-380 → `["+mcp"]` ⇒ `%w[read bash edit write mcp]`,
  `["-bash"]` ⇒ `%w[read edit write]`); the base-independent pins must NOT
  move. README's `defaultTools` row + `--help`'s Settings paragraph state
  the new default + the `+find`-style escape hatch.

- **Deliverable 2 — the registry order (spec item 2).** `Tools::Registry.
  build` preserves the SELECTED list's order (today `TOOL_CLASSES.slice
  (*selected)` yields the receiver's order — registry.rb:53): at default
  configuration the wire tools array is `["read","bash","edit","write"]`
  (pi's captured order; `_applyToolLoadout` iterates the name list,
  agent-session.ts:1571-1581). Pin in tools_test with an order-sensitive
  keys assertion; the existing `.sort` assertions stay green.

- **Deliverable 3 — the prompt golden (spec item 3).** No
  system_prompt.rb change (STOP + PHASE 0 if you think otherwise). Freeze a
  system_prompt_test pin: the `<tools>` and `<rules>` sections built from
  `Settings.selected_tools({})` equal pi's captured bytes VERBATIM — the
  Grounds 5 literals, inlined in the test with the derivation recorded in
  a comment (never the port's own output; tmp/ is gitignored). The
  loadout-conditional bullet first + the read → bash → edit → write
  guideline order are the loadout-bearing bytes.

- **Deliverable 4 — session-env exposure (spec item 4).** `Tools::Bash`
  gains `identity:` (default `Identity::DEFAULT`) and `session_env:` —
  SUFFIX ("SESSION_ID", "SESSION_FILE", "PROVIDER", "MODEL",
  "REASONING_LEVEL") → callable, resolved AT SPAWN TIME. The TOOL path
  (`execute` → `spawn_and_stream`) composes the child env pi-exactly: copy
  ENV; DELETE the five `<PREFIX>_<SUFFIX>` keys (scrub even when a reader
  nils); set `Identity.env_key(identity, suffix)` for each truthy reader
  value; spawn with the composed env (`unsetenv_others: true`). `run_user`
  keeps today's plain inheritance — pi's user-bash executor passes no env
  and never scrubs. No settings toggle (pi has none).
  `Tools::Registry.build` threads `identity:` + `session_env:` to Bash.

- **Deliverable 5 — the reader wiring (spec item 5).** `bin/tart` composes
  the session_env hash. INTERACTIVE: readers over the surface —
  `surface.agent&.recorder&.id` (SESSION_ID), `surface.agent&.recorder&.path`
  (SESSION_FILE), `surface.current_model_ref` (PROVIDER/MODEL — the CATALOG
  provider key + id, OQ-2; make `current_model_ref` public — ONE line in
  chat.rb, beside the :1945 public block), `surface.agent&.thinking_level`
  (REASONING_LEVEL). `/new`/resume swap `surface.agent` — the readers stay
  live through the accessor. `Agent::Loop` gains `attr_reader :recorder`
  (ONE line; loop.rb:84's field). PRINT: readers over the boot pair
  (`boot[:provider]`/`boot[:id]`) + the print level; SESSION_ID a minted
  `Session.uuidv7`; SESSION_FILE nil (pi's ephemeral session shape, OQ-3 —
  print recording is the standing I07 cut, out of scope). `build_tools`
  gains the `identity:`/`session_env:` passthrough; both call sites
  updated.

- **Deliverable 6 — the print identity tier (spec item 6).** `Print.run`
  gains `identity:` (default `Identity::DEFAULT`), forwarded to
  `Agent::Loop.new` — the loop's env tier (loop.rb:358-362) then reads
  `<PREFIX>_CONTEXT_WINDOW` under the resolved face on the print path.
  `bin/tart`'s print path passes the already-resolved identity. Existing
  no-identity `Print.run` tests stay green; add the forwarding pin
  (print_test, name matching `/identity/`).

- **Deliverable 7 — the hermetic env pin family (spec item 7).**
  bash_tool_test tests NAMED to contain `session_environment` (the gate's
  minitest filter): (a) the five vars present with correct sources; (b) a
  nil-ing reader leaves its var UNSET but still scrubs an inherited value;
  (c) inherited parent `<PREFIX>_SESSION_ID` never reaches the child (set
  ENV in-test, restore); (d) `run_user` does NOT expose and does NOT scrub;
  (e) identity prefixes — pi `PI_*`, tart `TART_*`, foo `FOO_*`; (f) values
  resolve at spawn (a reader whose value changes between two executes is
  honored twice); (g) exactly pi's five key names, no extras. The
  agent_loop_test additions (recorder reader + any env-tier pins) are
  additive and named to match `/env_tier|recorder/`.

- **In-worktree gate expectations:** suite/bench/s1–s9/s1-tart-mode GREEN;
  `loadout-pin`, `env-pin`, `print-identity-pin` GREEN in YOUR worktree
  (they are RED at base BY DESIGN — they are your deliverables' proofs);
  scope GREEN (your diff vs 9f8c8d7 = exactly the touch set).

- **Output format.** Raw evidence to scratch: file list + wc; the seam
  table (pi mechanic → port seam, before/after: default loadout, registry
  order, session env, print identity); verbatim test tails + suite counts;
  s1–s9 exit codes from YOUR worktree at the CANONICAL out dirs; the
  loadout gate output verbatim (tart's wire tools + the golden section
  diff); the env-exposure pin output; the white-label smoke (identity
  `foo`: `FOO_`-prefixed session vars through the print path); itemized
  deviations/cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0
  section). STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install
  --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`;
  parity: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/
  scenarios/<s>.yml --out tmp/parity-gate-<sN>` (canonical SHORT out dirs).
  Named test runs: `bundle exec ruby -Itest test/<file>_test.rb -n
  '/<filter>/'`. pi sources (read before coding; cite what you port):
  `src/core/settings-manager.ts:82-144`, `src/core/tools/bash.ts:186-280`,
  `src/core/tools/index.ts` + `src/core/agent-session.ts:1571-1581`,
  `src/core/session-manager.ts:987-1080`, `docs/environment-variables.md`,
  `src/utils/shell.ts:138-149`.

- **Out of scope, itemize if tempted:** print-mode session RECORDING
  (OQ-3), the process markers `AI_AGENT`/`PI_CODING_AGENT` (OQ-4), a
  settings toggle for exposure (pi has none), MCP env changes,
  getShellEnv's PATH-prepend (no shim dir), any prompt-text change beyond
  what the resolved loadout composes, ANY rig edit.

## Frozen ACCEPTANCE CRITERIA (verify against these; never weaken them)

Gate calibration: `loadout-pin`, `env-pin`, and `print-identity-pin` are the
iteration's NEW-capability gates — RED at base BY DESIGN; they must be GREEN
in your worktree, non-vacuously (each asserts ≥1 matching test run / exact
wire content). The s-gates keep the CANONICAL short out dirs. AC6's scope
diff is against **9f8c8d7**.

**AC1 (the default-4 loadout).** `Settings.selected_tools({})` resolves to
pi's `DEFAULT_TOOL_NAMES` list — `["read","bash","edit","write"]`, in ORDER —
and the I10 modifier semantics hold on the new base (plain replace; `+name`
appends; `-name` removes; all-modifier lists ride the base; layered
mergeDefaultTools unchanged). The README `defaultTools` row and `--help`
state the new default and the `+find`-style escape hatch. Pinned by
re-pinned settings tests (the two base-bearing modifier cases move; the
base-independent pins do not).

**AC2 (wire + prompt order follow the resolved list).** `Tools::Registry.
build` preserves the SELECTED order: at default configuration the request's
tools array is exactly `["read","bash","edit","write"]` (pi's captured wire
order), and under modifiers the resolved list's order. The composed prompt's
`<tools>` rows and `<rules>` bullets follow the same list — at default the
`<rules>` section opens with the loadout-conditional bullet ("Use bash for
file operations like ls, rg, find") and orders per-tool guidelines read →
bash → edit → write. Pinned by the loadout-pin gate (wire array + both
sections byte-compared against pi's captured bytes) and an inlined-golden
system_prompt test with the derivation recorded.

**AC3 (session-env exposure, pi's five).** The bash TOOL path composes the
child env as pi's `resolveSpawnContext` analog: the five
`<PREFIX>_<SUFFIX>` keys (`SESSION_ID`, `SESSION_FILE`, `PROVIDER`, `MODEL`,
`REASONING_LEVEL` under `Identity.env_key`) are scrubbed from a copy of ENV,
then set from LIVE readers resolved at spawn (nil reader → unset). Provider/
model are the CATALOG pair (surface `current_model_ref` / boot pair — OQ-2),
session id/file from the current recorder (interactive) or a minted
ephemeral id with no file (print — OQ-3), level from the loop's current
level. `run_user` (`!`/`!!`) exposes NOTHING and does not scrub (pi's user
path). No settings toggle exists (pi has none). Pinned by the hermetic
bash_tool family: sources, nil-conditionals + scrub, parent-leak guard,
run_user exclusion, identity prefixes (PI_/TART_/FOO_), per-spawn
resolution, exactly-pi's-five shape.

**AC4 (print identity tier).** `Print.run` forwards the resolved identity
into `Agent::Loop`, so the print path's loop env tier reads
`<PREFIX>_CONTEXT_WINDOW` under the resolved face (tart → `TART_`, foo →
`FOO_`) instead of the pi default. Pinned by print/agent-loop tests
(forwarding + the tier readback); existing no-identity Print.run tests stay
green on the default.

**AC5 (regression).** The default rake task fully green with run-count
delta > 0; s1–s9 exit 0 cold at the canonical out dirs; s1_tart (the
tart-mode scenario) completes: tart boots, connects, and completes its
expected requests; SEAM_BENCH_OK.

**AC6 (scope).** The integrated diff vs 9f8c8d7 touches exactly the lane's
enumerated files, nothing else — in particular NO `gems/tui-split-rig/**`
file, and `lib/tart/agent/system_prompt.rb`, `lib/tart/identity.rb`,
`test/chat_test.rb`, and `lib/tart/agent/session.rb` are untouched.

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

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
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

- id: loadout-pin
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/loadout-gate-s1 && ruby -rjson -e 'req = JSON.parse(File.readlines("tmp/loadout-gate-s1/run-1/tart-requests.jsonl")[0]); tools = req["body"]["tools"].map { |t| t.dig("function", "name") }; abort "wire loadout: #{tools.inspect}" unless tools == %w[read bash edit write]; sys = req["body"]["messages"][0]["content"]; golden_tools = "- read: Read file contents\n- bash: Execute bash commands (ls, grep, find, etc.)\n- edit: Make precise changes with exact text replacement, including multiple disjoint edits in one call\n- write: Create or overwrite files\n\nIn addition to the tools above, you may have access to other custom tools depending on the project."; golden_rules = "- Use bash for file operations like ls, rg, find\n- Use read to examine files instead of cat or sed.\n- You can inspect PI_* environment variables for current model and session details.\n- Use edit for precise changes (edits[].oldText must match exactly)\n- When changing multiple separate locations in one file, use one edit call with multiple entries in edits[] instead of multiple edit calls\n- Each edits[].oldText is matched against the original file, not after earlier edits are applied. Do not emit overlapping or nested edits. Merge nearby changes into one edit.\n- Keep edits[].oldText as small as possible while still being unique in the file. Do not pad with large unchanged regions.\n- Use write only for new files or complete rewrites.\n- Be concise in your responses\n- Show file paths clearly when working with files"; tools_section = sys[/<tools>\n(.*?)\n<\/tools>/m, 1]; abort "tools section diverges:\n#{tools_section}" unless tools_section == golden_tools; rules_section = sys[/<rules>\n(.*?)\n<\/rules>/m, 1]; abort "rules section diverges:\n#{rules_section}" unless rules_section == golden_rules; puts "LOADOUT_PIN_OK"'
  expect:
    exit_code: 0
    stdout_match: LOADOUT_PIN_OK

- id: env-pin
  ac: AC3
  cwd: repos/tart
  cmd: |-
    out=$(bundle exec ruby -Itest test/bash_tool_test.rb -n '/session_environment/' 2>&1); ec=$?; echo "$out" | tail -3; [ "$ec" -eq 0 ] && echo "$out" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo ENV_PIN_OK
  expect:
    exit_code: 0
    stdout_match: ENV_PIN_OK

- id: print-identity-pin
  ac: AC4
  cwd: repos/tart
  cmd: |-
    out1=$(bundle exec ruby -Itest test/print_test.rb -n '/identity/' 2>&1); ec1=$?; echo "$out1" | tail -3; out2=$(bundle exec ruby -Itest test/agent_loop_test.rb -n '/env_tier|recorder/' 2>&1); ec2=$?; echo "$out2" | tail -3; [ "$ec1" -eq 0 ] && echo "$out1" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && [ "$ec2" -eq 0 ] && echo "$out2" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo PRINT_IDENTITY_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_IDENTITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 9f8c8d7 HEAD | grep -qvE '^(lib/tart/settings\.rb|lib/tart/tools/registry\.rb|lib/tart/tools/bash\.rb|lib/tart/agent/loop\.rb|lib/tart/render/chat\.rb|lib/tart/print\.rb|bin/tart|README\.md|test/settings_test\.rb|test/tools_test\.rb|test/bash_tool_test\.rb|test/system_prompt_test\.rb|test/print_test\.rb|test/agent_loop_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Report

### core

### PHASE 0 (disagreements & verifications)

**Checked before coding** (all verified against live sources this session):
pi `packages/coding-agent/src/core/settings-manager.ts:82` (`DEFAULT_TOOL_NAMES = ["read","bash","edit","write"]`) + :104-133 (modifier/merge semantics); `src/core/tools/bash.ts:186-250` (`resolveSpawnContext`: env copy → delete the five `PI_*` → set from ctx; `exposeSessionEnvironment` defaults true, no settings key); `src/core/agent-session.ts:1565-1581` (`_applyToolLoadout` iterates the name list in order) + :911 (`selectedTools = getActiveToolNames()` feeds the prompt); `src/core/session-manager.ts:987-1080` (ephemeral shape: id always, file only when persisting); `docs/environment-variables.md:20-45` (five-var table, per-command resolution, user-bash exclusion); `src/utils/shell.ts:138-149` (getShellEnv). Port seams: `Settings.selected_tools`/`apply_tool_modifiers`/`merge_default_tools` (settings.rb:216-244, unchanged machinery); `Process.spawn(env, ..., unsetenv_others: true)` live-verified (child sees exactly the composed hash); `Session.uuidv7` (session.rb:54), `Recorder#id/#path` (session.rb:366), `Identity.env_key` (identity.rb:50), chat.rb `attr_accessor :agent` (:274), loop.rb env tier (loop.rb:358-362).

**Disagreement raised (the only one): the frozen `loadout-pin` gate's `golden_tools` literal has a one-word transcription error.** Gate literal: `- edit: Make precise changes with exact text replacement...`. The REAL bytes — pi's captured request (`tmp/i41-base-s8_zero_usage_compaction/run-1/pi-requests.jsonl` request 1, byte-verified), the I32-era capture (`tmp/parity-gate-s8/run-1/pi-requests.jsonl`, identical), pi's own source (`edit.ts:44` snippet), and the port's `system_prompt.rb:34` — all say `- edit: Make precise file edits with exact text replacement...`. The gate's `<rules>` literal matches the capture byte-for-byte. Per the operating rules (AC letter vs the property it asserts), I built to the REAL captured bytes (no `system_prompt.rb` edit — it already composes them), ran the gate VERBATIM, and recorded the abort + the one-word-diff proof. The supervisor was notified mid-run (progress_update). The gate literal needs the one-word fix in the architect-owned AC; with that fix the gate passes end-to-end (proof below).

No other disagreements: every named API/format/version checked out; `system_prompt.rb` needs NO edit (composes the golden bytes from the resolved list); `test/support/**` needed no edit.

### Files (git diff --stat 9f8c8d7, working tree)

```
 README.md                  |   6 ++-
 bin/tart                   |  52 +++++++++++++---
 lib/tart/agent/loop.rb     |   6 +++
 lib/tart/print.rb          |   7 ++-
 lib/tart/render/chat.rb    |   2 +-
 lib/tart/settings.rb       |   9 ++--
 lib/tart/tools/bash.rb     |  51 +++++++++++++--
 lib/tart/tools/registry.rb |  31 +++++++++---
 test/agent_loop_test.rb    |  42 +++++++++++++++
 test/bash_tool_test.rb     | 127 +++++++++++++++++++++++++++++++++++++++++
 test/print_test.rb         |  46 ++++++++++++++
 test/settings_test.rb      |   4 +-
 test/system_prompt_test.rb |  44 +++++++++++++++
 test/tools_test.rb         |  11 ++++
 14 files changed, 409 insertions(+), 29 deletions(-)
```

Untracked files: none. loop.rb diff = the `attr_reader :recorder` + doc comment only; chat.rb diff = the one `public` line only (verified via `git diff 9f8c8d7 --` on both).

### Seam table (pi mechanic → port seam, before/after)

| pi mechanic | port seam | before | after |
|---|---|---|---|
| `DEFAULT_TOOL_NAMES` (settings-manager.ts:82) | `Settings::DEFAULT_TOOLS` (settings.rb) | `%w[read write edit bash find grep ls]` ("recorded divergence") | `%w[read bash edit write]` (parity note) |
| `resolveDefaultTools`/`applyToolModifiers`/`mergeDefaultTools` | `Settings.selected_tools`/`apply_tool_modifiers`/`merge_default_tools` | already pi-exact | UNCHANGED (I10 machinery) |
| `_applyToolLoadout` name-list order (agent-session.ts:1571-1581) | `Tools::Registry.build` (registry.rb) | `TOOL_CLASSES.slice(*selected)` → receiver order (read,edit,write,bash,...) | `selected.to_h` → SELECTED order (read,bash,edit,write) |
| `resolveSpawnContext` (bash.ts:186-208) | `Tools::Bash#session_env_for_spawn` + `spawn_and_stream(env:)` | plain ENV inheritance, no scrub, no exposure | copy of ENV → scrub the identity's five → set truthy readers at spawn; `unsetenv_others: true`; `run_user` keeps plain inheritance |
| `ctx.sessionManager.getSessionId/getSessionFile`, `ctx.model.provider/.id`, `ctx.thinkingLevel` | launchers' readers (bin/tart): interactive `surface.agent&.recorder&.id/.path`, `surface.current_model_ref[:provider]/[:id]`, `surface.agent&.thinking_level`; print: minted `Session.uuidv7`, no file, boot pair, print level | n/a (no exposure) | SUFFIX → callable hash threaded `build_tools` → `Registry.build` → Bash |
| loop `identity` on print path (I32 ruling 2) | `Print.run(identity:)` → `Agent::Loop.new(identity:)` | print loop always `Identity::DEFAULT` (read PI_CONTEXT_WINDOW) | resolved face forwarded; tier reads `<PREFIX>_CONTEXT_WINDOW` |
| `current_model_ref` (chat.rb) | private → public | private | `public :..., :current_model_ref` (one line, :1945 block) |

### Gate results (this worktree)

| gate | result | evidence |
|---|---|---|
| suite | PASS | `790 runs, 3161 assertions, 0 failures, 0 errors, 1 skips` (run-count delta +13 vs base 777 — the 13 new tests; the 1 skip is the pre-existing opt-in LiveRunTest skip) |
| bench | PASS | `SEAM_BENCH_OK` |
| s1-parity | PASS | exit 0, `tmp/parity-gate-s1` |
| s2-parity | PASS | exit 0, `tmp/parity-gate-s2` |
| s3-parity | PASS | exit 0, `tmp/parity-gate-s3` |
| s4-parity | PASS | exit 0, `tmp/parity-gate-s4` |
| s5-parity | PASS | exit 0, `tmp/parity-gate-s5` |
| s6-parity | PASS | exit 0, `tmp/parity-gate-s6` |
| s7-parity | PASS | exit 0, `tmp/parity-gate-s7` |
| s8-parity | PASS | exit 0, `tmp/parity-gate-s8` |
| s9-parity | PASS | exit 0, `tmp/parity-gate-s9` |
| s1-tart-mode | PASS | rig exit 1 (gate-tolerated `ec<=1`), `pi: completed=true requests=1/1`, `tart: completed=true requests=1/1`, stdout `TART_MODE_OK` |
| loadout-pin | **FAIL (gate literal)** | verbatim output below; wire check PASSES, tools-section aborts on the one-word literal error |
| env-pin | PASS | `7 runs, 22 assertions, 0 failures` → `ENV_PIN_OK` |
| print-identity-pin | PASS | print `/identity/`: `2 runs, 6 assertions, 0 failures`; loop `/env_tier|recorder/`: `2 runs, 7 assertions, 0 failures` → `PRINT_IDENTITY_OK` |
| scope | PASS | frozen HEAD-based gate: `SCOPE_OK`; non-vacuous worktree diff vs 9f8c8d7 = exactly the 14 enumerated files (list above); untracked: none |

### loadout-pin gate, verbatim (frozen literal)

```
out dir: .../wt/tmp/loadout-gate-s1
tools section diverges:
- read: Read file contents
- bash: Execute bash commands (ls, grep, find, etc.)
- edit: Make precise file edits with exact text replacement, including multiple disjoint edits in one call
- write: Create or overwrite files

In addition to the tools above, you may have access to other custom tools depending on the project.
loadout-gate exit=1
```

Same capture, gate script re-run with ONLY the errant literal word corrected to the capture (`file edits`):

```
WIRE_OK: ["read", "bash", "edit", "write"]
LOADOUT_PIN_OK_WITH_CORRECTED_LITERAL
```

Capture-vs-gate byte diff (scripted): `RULES_MATCH_GATE` (10/10 lines); `TOOLS_DIFFER` line 2 only: gate `"- edit: Make precise changes with exact text replacement..."` vs capture `"- edit: Make precise file edits with exact text replacement..."`; both sources (`edit.ts:44`, `system_prompt.rb:34`) and both on-disk captures agree with the capture side.

### Focused test evidence (verbatim tails)

```
bash_tool_test -n /session_environment/:  7 runs, 22 assertions, 0 failures, 0 errors, 0 skips
settings_test (full):                    35 runs, 124 assertions, 0 failures, 0 errors, 0 skips
tools_test (full):                       21 runs, 54 assertions, 0 failures, 0 errors, 0 skips
system_prompt_test (full):               15 runs, 58 assertions, 0 failures, 0 errors, 0 skips
print_test -n /identity/:                 2 runs,  6 assertions, 0 failures, 0 errors, 0 skips
agent_loop_test -n /env_tier|recorder/:   2 runs,  7 assertions, 0 failures, 0 errors, 0 skips
```

New tests: tools_test `test_registry_preserves_the_selected_order` (default `%w[read bash edit write]` + modifier-resolved order); system_prompt_test `test_default_loadout_sections_are_pis_captured_bytes` (GOLDEN_TOOLS/GOLDEN_RULES inlined, derivation commented); bash_tool_test (a)-(g) seven `session_environment` tests; print_test `test_print_forwards_the_resolved_identity_to_the_loop` + `test_print_path_session_env_rides_the_resolved_identity`; agent_loop_test `test_env_tier_reads_the_identity_namespaced_context_window` + `test_recorder_reader_exposes_the_session_recorder`.

### White-label smoke (REAL bin/tart -p, `--identity foo`, mock endpoint, this worktree)

```
tart exit=0
stdout: "smoke complete\n"
env.txt: "sid=01a13381-26e7-7fee-b8b8-eab6d0b3ba8c sfile=[] provider=openai model=accounts/fireworks/models/glm-5p3-flash level=medium\n"
sid_uuidv7_shape=yes
```

FOO_-prefixed five via the print path: minted uuidv7 id, empty file (OQ-3), boot pair (no catalog match → env/settings pair `openai` + the default fireworks id), print level `medium`. Also proves the bash tool boots under the new default-4.

`--help` Settings paragraph (verbatim, live run):

```
          defaultTools (default read bash edit write; plain names replace
          it — e.g. ["find", "grep"] restores the search tools — +name
          adds, -name removes, e.g. "+find" appends to the default).
```

### Deviations / cuts / notes (itemized)

1. **Gate-literal conflict (AC2's loadout-pin):** the frozen `golden_tools` literal carries `Make precise changes` where pi's real captured bytes, pi's source (edit.ts:44), and the port compose `Make precise file edits`. Built to the real bytes (the AC's property); gate run verbatim fails at that one comparison; corrected-literal run passes end-to-end. Architect must fix the literal — no code change on my side can satisfy the errant letter without editing the forbidden `system_prompt.rb` and diverging from pi.
2. **Harness-env PI_* discovery:** the session's parent environment carries live `PI_*` vars (pi's own bash-tool exposure upstream). The bash_tool hermetic tests set/restore their own vars and scope cross-prefix assertions accordingly ((d),(e),(g)); (g) asserts pi's exact prefix-scoped rule (parent PI_* minus the five, plus the five composed).
3. **Print forwarding pin mechanics:** `Print.run` exposes no loop readback and its default compaction settings make a threshold compaction unobservable on a single seeded-less turn (cut point 0 — `find_cut_point` keeps everything under keep_recent 20000), so the forwarding pin witnesses `Agent::Loop` construction (kwargs captured, real loop delegated to — the define_singleton_method test precedent) + the tier readback in agent_loop_test (`send :resolved_context_window`, the mcp_test send precedent).
4. **`getShellEnv` PATH-prepend:** cut (no shim bin dir; Grounds 3 itemized) — base env is `ENV.to_h`.
5. **Process markers `AI_AGENT`/`PI_CODING_AGENT`:** out of scope (OQ-4), untouched.
6. **Out-dir discipline:** one early s2–s4 loop used long out-dirs (`tmp/parity-gate-s2_tool_turn` etc.) → exit 1 (the Grounds 1 environmental family); re-run all at canonical `tmp/parity-gate-sN` → exit 0. No rig file touched; no tmux commands run; no git write commands run.

STATUS: COMPLETE_WITH_CONCERNS (frozen loadout-pin gate's `golden_tools` literal has a one-word transcription error vs pi's real captured bytes — evidence above; gate needs the architect's one-word literal fix, everything else GREEN)

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
