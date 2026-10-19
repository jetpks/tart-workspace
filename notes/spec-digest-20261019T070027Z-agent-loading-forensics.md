# spec-digest — I81 `agent-loading-forensics` — LIVE-RUN SUCCESSOR ENTRY 6 SPEC RUN (the plan's LAST entry)

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane; after the I81 verdict the successor plan is
COMPLETE — the next spec is whatever the owner queues). Iteration
`agent-loading-forensics` (I81), ONE lane `core` (repo tart, frozen 10-path
touch set, effort MEDIUM in the frozen lanes block). Frozen region at
`8ebd516c` (freeze commits `8ebd516` + the sha record `9758482`), fresh
rehearsal stamp `gates_digest
eebc499bae763fa60fe0870547525893a8b280a283c785339027b33e8ea4e9c5`
@ `2026-10-19T00:44:54-06:00` in space.yaml — never --skip-rehearse.

## The headline: three laws, five declared re-pins, all pre-freeze

- **Law 1 (warn-and-drop)**: unknown tool NAMES in a custom agent's `tools`
  frontmatter no longer reject the file — the profile loads with the known
  entries (declaration order), ONE warning diagnostic per file
  (`unknown tool(s) <names> — dropped (valid tools: <sorted>)`), surfaced at
  the interactive boot via the `bin/tart:556-559` skills/prompts
  `command_line` idiom (today's profile diagnostics are DARK — the rejection
  was only visible as `unknown agent`; this also lights up malformed-file
  warnings, declared). Shape-invalid `tools` still warn+skips (pi
  `agents.js:739-741` parity). All-unknown list → loads with ZERO tools.
- **Law 2 (nested grant)**: `TOOLS_UNIVERSE` gains `subagent`; Registry
  accepts the name without building it (the hooks registered-tools merge
  supplies it, LAST on the wire; a selection with no registered instance
  drops silently — pi loadout parity, near-unreachable in practice). Depth
  law = pi-subagents 0.79.1 verbatim semantics: default max 2
  (`types.js:134`), `<IDENTITY>_SUBAGENTS_{DEPTH,MAX_DEPTH}` env keys
  (closed pick list grows EXACTLY these two), child env always carries both,
  `spawn_run` raises pi's blocked bytes EXACTLY (`subagent-executor.js:6983-6993`)
  when own depth >= max. `allowNestedSubagents` stays tolerated-and-ignored
  (declared residual).
- **Law 3 (forensics)**: child argv `--session-root` ← `run[:dir]` (the
  doubling was the argv value + `session.rb:78-80`'s join; `session.rb`
  HARD-FROZEN); transcript lands `<run-dir>/sessions/<slug>/<file>`,
  `status.sessionRoot` (value unchanged) becomes the accurate container;
  the manager glob matches BOTH layouts (legacy doubled dirs keep adopting —
  pinned). `status.task` carries the RAW task verbatim (fork preamble
  excluded; taskChars = raw char count; box never renders a task row).
  Text-over-digest ruling: pi redacts prompt text from EVENTS/status
  descriptions but its RUNNER artifacts carry taskText
  (`async-execution.js:1254/:1910`); status.json is the port's runner
  artifact and must answer "what was this run asked to do" even when the
  child died before recording a transcript.

## Rehearsal vector (measured twice, identical — the second is the stamp)

**GREEN 87 / RED 5 / BROKEN 0 / EMPTY 0** at base tip `7b70e8a`:
`build/rehearse/I81-agent-loading-forensics-20261019T003021.194263.md` and
`…T004454.255180.md`. The 5 RED each verified for EXACTLY its declared
reason: the four new gates fail on the empty-filter runs=0 shape
(`/dropped/`, `/nested|depth_cap/`, `/forensic/`, e2e `/nested/` — all
name-grep-verified empty at base BEFORE drafting), `scope` on the empty
must-differ legs (leak-check legs exit 0 clean, packaging/render
hard-freeze legs quiet — judge-verified leg-by-leg). All 87 carried GREEN
cold both runs.

## Verification commands actually used (exact, tested this run)

- Base suite floor measured cold at `7b70e8a` (in `repos/tart`):
  `bundle install --quiet && bundle exec rake` → **1453 runs / 6846
  asserts / 0F / 0E / 1S, exit 0** + `bundle exec ruby bench/seam_bench.rb
  2>&1 | tail -1` → `SEAM_BENCH_OK`.
- Remote-ancestry check (forces `--base`):
  `git -C repos/tart merge-base --is-ancestor 7b70e8a origin/main` →
  **exit 1 (NOT an ancestor)** — re-verified immediately before
  provisioning. RE-VERIFY at the next provision (origin/main holds squashed
  PR merges).
- Rehearsal (the stamp source): `architect rehearse agent-loading-forensics`
  (run twice: once after AC record, once after the vector re-record —
  gates byte-identical between the two AC records, sha-verified
  `eebc499b…`).
- Sections: `architect section agent-loading-forensics {grounds,
  specification, acceptance-criteria} --from tmp/i81-spec/{grounds,
  specification, ac-with-gates}.md -m "…"`. **PROCESS NOTE (the I78-class
  fencing defect, self-caught this run): the first AC record closed the
  ```gates fence EMPTY (the scratch file had ```gates + an immediate ```) —
  `architect rehearse` reported EMPTY; fixed by rebuilding the scratch
  (prose → ```gates → yaml → ```) and re-recording. ALWAYS awk-extract the
  arch file's gates block after recording and YAML-parse it (92 gates)
  before rehearsing.**
- Freeze: `architect freeze agent-loading-forensics` → freeze_sha
  `8ebd516c`. The ```lanes block was written INTO the Specification BEFORE
  the first freeze (the I78/I79/I80 lesson held — provision materialized
  the lane with zero amendments).
- Provision: `architect provision agent-loading-forensics --base 7b70e8a`
  → worktree `build/I81-agent-loading-forensics-core/wt` @ `7b70e8a`,
  branch `lane/I81-agent-loading-forensics-core` (verified `git log -1` in
  the wt). The space.yaml provision write is UNCOMMITTED (the standing
  class; the coordinator's dispatch bookkeeping commits it).

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I81-agent-loading-forensics.md` (frozen region
  read-only after `8ebd516c`); space.yaml I81 record (freeze_sha
  `8ebd516c`, lane `core` base_sha `7b70e8a…`, worktree, rehearsal stamp,
  10-path touch_set).
- Scratch: `tmp/i81-spec/` — grounds.md, specification.md,
  acceptance-criteria.md (the BROKEN first cut), ac-prose.md,
  ac-with-gates.md, gates-i80-raw.yaml (the extracted post-verdict I80
  block — NOTE: the I80 verdict amended scope 5→6 paths, so the arch file,
  not the I80 digest, is the extraction source), gates-carried-rebased.yaml
  (87, textual rebase `t80→t81` + `34ba69af→7b70e8a`), gates-new.yaml
  (scope + 4 new), gates-final.yaml (92, sha `eebc499b…`),
  prompt-core.md (the lane prompt), rehearsal transcripts under
  `build/rehearse/`.
- `repos/tart` @ `7b70e8a`: untouched by spec (the `t81*` rehearsal out
  dirs + the standing `t75*`/`t78*`/`t79*`/`t80*` scratch are untracked,
  never committed). The frozen seams the builder lands:
  `lib/tart/schemas/subagents.rb` (universe + shape-only tools rule),
  `lib/tart/subagents/profiles.rb` (warn-and-drop + the diagnostic),
  `lib/tart/subagents/manager.rb` (session-root argv :398, status task
  :1153, depth picks in child_env), `lib/tart/subagents.rb` (the depth
  shared-types home — pi `types.js` analog), `lib/tart/tools/registry.rb`
  (the `subagent` selected-name acceptance), `bin/tart` (the boot
  diagnostics idiom), and the four test files (the five declared re-pins +
  the new pin batteries + the nested e2e leg).
- Mechanism seams CITED (read-only): pi-subagents 0.79.1
  `~/.pi/agent/npm/node_modules/pi-subagents/src/` — `shared/types.js:134-201`
  (the depth law), `runs/foreground/subagent-executor.js:6983-6993` (the
  blocked bytes), `runs/shared/child-tool-plan.js:200-204` (the grant),
  `agents/agents.js:739-741` (shape-only validation),
  `runs/background/async-execution.js:1254/:1910` (runner artifacts carry
  taskText) + `chain-append.js:140-146`/`async-execution.js:1511`
  (PROMPT_REDACTED on events/status descriptions); pi core
  `agent-session.ts:1575-1582` (`_applyToolLoadout` drops unknown names);
  tart `agent/session.rb:78-80` (the join that doubles),
  `render/subagent_box.rb:27-28` (the no-task-row law); live specimens
  `~/.tart/subagents/01a14df7-f99a-7244-a23e-e172ebd97383/` (doubled path +
  task null) and the 07:40Z devstral transcript
  `~/.tart/sessions/--Users-eric-architect-spaces-20261018-devstral-docs--/2026-10-18T07-40-42-220Z_*.jsonl`
  (the bg_wait/subagent rejection debugging).

## House conventions the next spec must honor

- **Carry the 92-gate floor onward** (I81 carried 87 with the standing
  rebases: `t81*` era prefix, diff bases `7b70e8a`, scope rewritten to the
  10-path set). The NEXT entry re-bases again: era prefix → its own, diff
  bases → the then-tip, scope → its own touch set. Carried gates keep
  origin `ac:` labels verbatim (AC6-labeled members are historical
  anchors).
- **Extract the carried block from the ARCH FILE, not the previous digest**
  — verdicts amend frozen gates (I80's scope went 5→6 paths at verdict; the
  I80 digest still said 5).
- **After every AC section record: awk-extract the gates block and
  YAML-parse it before rehearsing** — the empty-fence defect class (this
  run, self-caught; a rehearse would otherwise report EMPTY and waste a
  battery run).
- Write the Lane plan + ```lanes``` block into the Specification BEFORE
  the first freeze — held this run (zero amendments).
- provision on tart needs `--base <pin>` while origin/main holds squashed
  PR merges; re-verify `merge-base --is-ancestor` immediately before.
- Declared-RED gates: each verified in-sim AND by rehearsal to fail for
  EXACTLY its declared reason; the AC preamble states the MEASURED vector
  (recorded once, re-recorded with the vector, gates sha-identical).
- **Audit carried closed-env/closed-list pins + must-differ legs against
  the frozen touch set BEFORE freeze** (the I80 lesson; done this run —
  exactly five contradicting pins, all in-touch as declared re-pins; the
  audit is recorded inside the frozen AC preamble).
- All-existing touch paths → tracked-file must-differ legs only; NO
  `[ -f ]` legs needed this run (the I79 lesson applies only when a
  NEW file joins the set; if a future lane adds one, use `[ -f path ]`
  FROM THE START and declare new dirs as `dir/**`).
- Suite floors pin RUN counts (1453 at `7b70e8a`); the assert counter is
  dynamic (6846 this run).
- Short out dirs; judge runs gates at the LANE tree; never gates under
  nohup; `env -u HERDR_ENV…` for rig execs; itemize-and-defend EVERY
  frozen gate.
- The `t81*` rehearsal dirs in the MAIN checkout are scratch, never
  committed; the integrator's out-of-bounds guard may trip on them.
- Inherited space-repo working tree carries owner/agent-regen ops — NOT
  touched, NOT reverted, they are the owner's.
- **KNOWN space.yaml METADATA DISCREPANCY (disclosed, the standing I77
  class)**: the frozen lanes block declares `effort: medium`, but
  `architect provision` recorded `effort: high` (the CLI does not parse
  effort from the lanes block — no provision flag exists). The arch file
  is the authority. Also the lane-level `integration_branch` was recorded
  EMPTY (the standing class; the slug fallback resolves
  `project/pi-port`).

## Builder Prompt provenance

Assembled THIS run at **`tmp/i81-spec/prompt-core.md`** (modeled on the I80
prompt shape + this iteration's three frozen Laws and the five declared
re-pins). NOT yet copied anywhere. **The COORDINATOR copies it to
`build/I81-agent-loading-forensics-core/prompt.md`** at dispatch and
appends the Builder Prompt section (`architect section
agent-loading-forensics prompt --append --lane core --from
build/I81-agent-loading-forensics-core/prompt.md`) — the I77–I80 recorded
split of labor.

## Decisions taken this session (one-line reasons)

- **Warn-and-drop lives at profile build, contract validates shape only** —
  pi rejects shape (`agents.js:739-741`) but never names; the drop must
  keep the file loadable.
- **Universe widens by exactly `subagent`** — the coordinator playbook's
  grant path; `rm_rf`-class names stay unknown (the `tools_test.rb:114`
  pin survives untouched, out-of-touch-set).
- **One diagnostic per affected file, declaration-order names, sorted
  universe listing** — port-own vocabulary (pi has no warn analog),
  continuity with the retired reject message.
- **Boot surfacing via the skills/prompts command_line idiom** — the
  established channel; makes today's DARK profile diagnostics (incl.
  malformed files) visible; NO MOTD surface (the I70 law).
- **Registry accepts-but-never-builds `subagent`; silent drop when
  unregistered** — the hooks merge already supplies the instance LAST
  (I49); pi's loadout drops unknown/unregistered silently.
- **Depth law = pi verbatim (default 2, env override, inherit, blocked
  bytes)** — the plan's OQ answered from `types.js:134-201` +
  `subagent-executor.js:6983-6993`; shared constants home =
  `lib/tart/subagents.rb` (the pi `types.js` analog).
- **`--session-root` ← `run[:dir]`, session.rb hard-frozen** — the doubling
  is the argv value; the `<root>/sessions/<slug>` layout law is
  load-bearing everywhere else (session goldens).
- **`status.task` = raw task text verbatim, not a digest** — pi's runner
  artifacts carry taskText; the run's own status.json is that analog, and
  the text answers the post-mortem question even with no transcript.
- **Box never renders a task row** — the I79 redaction law (pi
  formatters.js); only the field's VALUE changes.
- **All-unknown tools → loads with zero tools** — an explicit empty list is
  meaningful in pi's loadout; the builtin-seven default applies only to a
  nil line.

## Known unknowns (for the judge / next spec)

- The nested e2e leg's runtime (three process generations, each ~a few
  seconds at mock pace + the leg-A watchdog discipline; the standing
  battery runs it once — expect it to be the slowest new member but well
  inside the 180s parent deadline).
- The gate-off child's silent `subagent` drop is near-unreachable live (a
  `subagents: false` settings row disables the parent's own tool first) —
  pinned as a no-raise unit; richer loudness is owner-backlog if it ever
  bites.
- `allowNestedSubagents` alone does not authorize nesting in the port
  (tolerated-ignored) — no known playbook relies on it alone; reopen on
  live pain.
- Per-agent `maxSubagentDepth` frontmatter (pi `launch-contract.js:69`)
  deliberately out of scope; the env override covers the operator need.
- The `effort: medium` vs space.yaml `high` discrepancy + the empty
  lane-level `integration_branch` (disclosed above) — judge reads the arch
  file.
- Standing I78/I79/I80 residuals untouched: the adopter/owner write race,
  `staleAlivePidMs`/`events.jsonl`/fuzzy-suggestions, the pi box residuals
  (belowEditor fleet roster, live tool/turn/token facts, ctrl+o expanded
  form, queued state), the s9/herdr gate-geometry re-freezes, json 3.1.0
  warn→raise upgrade, richer `first_error_line` classification (owner
  backlog).
- **The live-run successor plan (entries 1–6) COMPLETES with I81's verdict
  — no queued next entry. The next spec session expects an owner-directed
  successor (or closure bookkeeping).**
