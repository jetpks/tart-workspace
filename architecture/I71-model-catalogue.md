# I71: model-catalogue

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan ENTRY 3 (`notes/plan-20261017T183001Z-tart-standalone.md`): owner
  ruling 2026-10-17, option C — vendor pi's MIT-licensed provider catalogue
  data as the metadata baseline PLUS live listing from the CONFIGURED
  provider's own `/v1/models`; the baseline must not create a runtime
  third-party dependency (no fetching from pi.dev at boot or on demand).
- Base this session: `repos/tart` `project/pi-port` @ **dd41ae1** (I70
  integrated, tip, clean; `git log --oneline -1` + `git status --short`
  re-run this session). fast-completions 0.5.0 published.
- Routing/environment standing law (the plan's standing context + the I70
  digest): rides `architect.yaml` as-is; the z.ai direct quota is dead until
  ~2026-10-19 13:51Z (openrouter is the wire); the model-window tick is
  DEAD (never re-armed in-loop); every `architect` CLI call from this
  environment carries the full bundler scrub
  (`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u
  BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION`).
- The oracle: `repos/pi` @ branch `oracle-v1.1.0` (== tag v1.1.0) is
  ENVIRONMENT, guarded by the carried `oracle-pin-state` gate — never
  re-performed from a lane; direct oracle execs use `env -u PI_PACKAGE_DIR`.
- I68 preserved artifacts (consumed by ENTRY 4, not this iteration):
  `build/I68-markdown-parity-core/lane-core.diff`, the retained worktree
  `build/I68-markdown-parity-core/wt`, `tmp/i68-spec/markdown_battery.json`
  — untouched, not cleaned up.

### The catalogue being vendored (read this session, pinned clone)

- `repos/pi/packages/ai/src/providers/data/` — **44 provider JSON files**
  (~1.9 MB), each a `{api-bucket: {"chat:<id>": {model facts}}}` map. The
  facts per entry: `id`, `name`, `api`, `provider`, `baseUrl`,
  `reasoning`, `input`, `cost`, `contextWindow`, `maxTokens`,
  `thinkingLevelMap` (Partial Record level→String|null),
  `compat` (a superset of the port's six-key subset), `inputLimits`, `type`.
- License: `repos/pi/LICENSE` — MIT, "Copyright (c) 2025 Mario Zechner".
  The repo is PUBLIC and the data ships committed in-tree, so vendoring is
  license-clean (the owner ruling's premise, verified).
- pi's own refresh discipline: `repos/pi/scripts/update-model-catalog-pin.mjs`
  — fetches `pi.dev/api/models` revisions, verifies a `sha256-…` content
  hash per revision, refuses a body that does not match its revision, and
  writes the per-file `.manifest.json` (`schemaVersion`, `generatedAt`,
  `structureHash`, per-file sha256). We borrow the DISCIPLINE
  (content-hashed, revision-recorded, operator-run) — never the network
  (the refresh task reads a local pi checkout only).
- The facts the owner's key models need (read this session):
  - `zai.json` `chat:glm-5.3`: `contextWindow` 1_000_000, `maxTokens`
    131_072, full `thinkingLevelMap` (off/minimal/medium/xhigh null, low/max
    String), `compat` with the seven keys incl. `zaiToolStream:true`,
    `thinkingFormat:"zai"`.
  - `openrouter.json`: 385 `openai-completions` entries; `z-ai/glm-5.3`
    carries `contextWindow` 1_048_576, `maxTokens` 943_718,
    `thinkingLevelMap` identical to zai's, and `compat`
    `{supportsDeveloperRole:false, thinkingFormat:"openrouter",
    supportsStrictMode:true, sendSessionAffinityHeaders:true}` —
    `thinkingFormat:"openrouter"` is NOT zai, so the dialect rides the
    frozen I46/I64 boundary (non-zai compat → the DEFAULT dialect,
    tolerated-and-dropped keys). Vendoring does NOT extend the dialect
    vocabulary — that boundary is frozen.
- The owner's live catalog (read this session, `~/.tart/models.json`):
  two providers — `zai` (baseUrl `https://api.z.ai/api/coding/paas/v4`) and
  `openrouter` (baseUrl `https://openrouter.ai/api/v1`) — 4 entries, every
  one FULLY specified (id/reasoning/contextWindow/maxTokens/
  thinkingLevelMap/compat), `default` = `openrouter/z-ai/glm-5.3`. This
  file is the byte-unchanged bar: the merge must be a NO-OP for it
  (every field declared ⇒ nothing fills).

### tart today (the seams, base dd41ae1)

- `lib/tart/models.rb` — `Models.load` (root `~/.tart`, JSONC+BOM, the
  never-raise error-as-field contract, I27), `Config` (model_entries /
  `resolve` exact-match / provider), `entry_context_window` /
  `entry_max_tokens` (the I59 definition-defaults tier: a declared value
  passes verbatim; an ENTRY that omits the field carries
  `DEFAULT_ENTRY_CONTEXT_WINDOW` 128_000 / `DEFAULT_ENTRY_MAX_TOKENS`
  16_384; NO entry ⇒ nil — the no-entry chain), `dialect_for` (compat →
  Dialect; nil/non-zai → `DEFAULT_DIALECT`), `wire_model`,
  `resolve_boot_model` (I27: env > models.json default > settings).
- `lib/tart/settings.rb` `thinking_facts` (I36): reasoning = the entry's
  flag when an entry exists else `model_reasoning_capable`; the map = the
  entry's map else the known table (`THINKING_LEVEL_MAPS`). The vendored
  tier slots BETWEEN entry and known-tables.
- `lib/tart/render/chat.rb` — `open_model_menu` (the I27 selector; the
  network refresh was CUT at I27, itemized — this iteration restores a
  different, owner-ruled form), `model_menu_entries` (catalog entries,
  degenerate boot-entry fallback), `apply_model_selection` (the typed-entry
  switch seam: facts + window + compat threading, persist path writes
  SETTINGS, never models.json), `boot_model_ref` cross-resolution.
- `lib/tart/render/model_menu.rb` — `ModelMenu.model` (items built from
  entries, sort by [rank, provider, id], the model_row shape `id
  [provider] · default`, fuzzy filter, `Model Name:` bottom row). No
  refresh path exists today (items are fixed at construction).
- `bin/tart` — `build_surface` (constructs `Render::Chat`; the I27 live
  defect — models: never threaded — is the named lesson: every new surface
  kwarg gets a launcher-seam regression pin), `endpoint_facts` (the boot
  key/base chain: env > the boot provider's models.json block > settings),
  `build_chat` (the Chat client carries the endpoint), the boot threads
  `entry_context_window`/`entry_max_tokens`/`thinking_facts` at three
  sites (:325, :475, :665-703).
- `lib/tart/commands.rb` `dispatch_model` — no-arg opens the selector,
  exact catalog match switches directly, else seeded selector. NOT touched
  this iteration.
- Test staged catalogs are hermetic by construction: `models_test` uses
  provider key `glm` @ `https://example.test/v1`; the launcher/footer gates
  stage `zai` @ `http://localhost:1/v1`; the rig parity family stages
  `mock` @ a local mock server — none can match a vendored baseUrl
  (the match rule below is baseUrl-first), so every frozen pin outside the
  declared moves is inert.
- ONE deliberate exception, declared here:
  `test/strict_sampling_test.rb` `ZAI_MODELS_JSON` stages the REAL zai
  baseUrl with a GAP entry (no `thinkingLevelMap`, no `maxTokens`). Its own
  assertions pin the tool-rewrite digests and loadout order only — they do
  NOT pin `max_tokens`/`reasoning_effort` — so the file stays green, but
  the un-pinned wire dimensions of that staged config CHANGE BY DESIGN
  under the fill (max_tokens 16_384→131_072; reasoning_effort for a
  `medium` session level clamps `medium`→`high` through the vendored map).
  This is the feature working, not a regression; the suite floor and the
  frozen wire-delta/session-golden guards (which stage full-fact or
  non-matching catalogs) hold EXACT.

### Measured base (this session, dd41ae1, fresh)

- **Suite: FRESH_MEASURED** (rake exit 0, measured cold this session — the
  floor the AC freezes; the loop-state's 1229/6047 record is superseded by
  this fresh measurement).
- `SEAM_BENCH_OK`: BASE_BENCH (measured after the suite, same session).
- Lane-tree prediction: `build/I71-model-catalogue-core/wt` = 79 chars
  absolute — the s9 wrap law (row = tree + outdir + 32, fires > 120) gives
  s9 the FIVE-char out dir `t71s9` (row 116, the proven-green boundary
  family).

### The rig law (standing)

Parity scenarios s1–s10, s17, s1-tart-mode carry untouched (short out dirs,
`rm -rf` at gate START, the HERDR_* scrub on every tart boot); no rig
scenario-content edits; `gems/tui-split-rig/**` is entirely outside this
iteration's touch set.

### Prior handoffs (the I70 digest, honored)

- Gates are GENERATED from the previous frozen block (`tmp/i71-spec/
  build-gates.rb` off `architecture/I70-subagents-default-on.md`) with the
  carry audit (`tmp/i71-spec/audit-gates.rb`) run BEFORE rehearsal; every
  rebase and drop declared in the AC preamble.
- Every frozen gate that writes an out dir carries its own `rm -rf`;
  rehearsal leaves out dirs in the tart tree — the spec session cleans them
  after freeze (I70 precedent).
- Judge runs gates at the LANE tree; freeze validates the rehearsal stamp
  by gates-digest match; `provision` leaves its space.yaml hunk for the
  spec session to commit as bookkeeping; freeze_sha = the commit carrying
  the frozen region.
- The builder prompt file must actually be written to disk and the
  `architect section … prompt --append` must land byte-verbatim (the I70
  prompt-embedding gap: the arch file is authoritative, gate commands are
  executed mechanically from it).
- Suite timing flake (chat_test interrupt-during-streaming): re-run cold
  before adjudicating; a reproducible cold failure is a different class.
- The advisory scope-asymmetry "not analyzed" tail in every rehearsal is
  structural (pipeline/stdin greps + `grep -v` outside the static parser) —
  NOT a blocker, NOT missing verdicts; never "fix" gates for it.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section model-catalogue specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision model-catalogue`
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
`architect rehearse model-catalogue` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze model-catalogue` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse model-catalogue` — before the freeze, while
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
subsection per lane. A copy is written to build/I71-model-catalogue-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section model-catalogue prompt --append --lane <lane> --from build/I71-model-catalogue-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I71-model-catalogue-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence model-catalogue --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section model-catalogue verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify model-catalogue`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
