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

### Objective

`/model` knows what is available. The owner-ruled option C lands as ONE
lane: pi's MIT-licensed provider catalogue data vendored into tart as a
local, offline metadata baseline (gap-fill for models the user references)
PLUS a live listing from the configured provider's own `/v1/models`
endpoint, merged into the /model menu on demand — never at boot, never a
runtime third-party dependency, never an override of the env/user/settings
tiers. The owner's existing `~/.tart/models.json` keeps working
byte-unchanged (the merge is a no-op for a fully-specified catalog).

### The contract (one lane)

**R1 — the vendored data lands (vendor/pi-models/, NEW).** All 44 provider
JSON files from the pinned pi clone (`packages/ai/src/providers/data/*.json`)
copied VERBATIM (byte-identical, gated) into `vendor/pi-models/`, plus:

- `vendor/pi-models/ATTRIBUTION.md` — the visible attribution: source
  (the pi repo, the data dir path), license (MIT, "Copyright (c) 2025
  Mario Zechner", link to the LICENSE), the refresh command, and the
  local-clone-only law.
- `vendor/pi-models/.manifest.json` — tart's OWN manifest (pi's
  `.manifest.json` is NOT copied): `{source, revision, generatedAt,
  files: {<name>: <sha256>}}` covering exactly the vendored `*.json`
  files. `revision` records the source clone's HEAD sha at refresh time.
- The refresh task: `rake models:vendor:refresh` (Rakefile, NEW task) —
  OPERATOR-RUN, OFFLINE: reads a local pi checkout (`ENV["PI_REPO"]`,
  default `../pi` relative to the tart root), fails LOUDLY when it is
  missing, copies the data files verbatim, regenerates the manifest, and
  NEVER touches the network (no Net::HTTP/Async::HTTP/URI.open/open-uri
  tokens in the Rakefile — gated). Borrow pi's content-hash discipline,
  not its runtime.

**R2 — the vendored tier (lib/tart/models/vendored.rb, NEW).** A local-file
metadata tier consulted at the FACT-RESOLUTION seams — loaded catalog
entries are NEVER mutated (`Shapes` pins hold; `Config`/`model_entries`
byte-stable; the merge is fill-at-read, not merge-at-load):

- **Match rule (frozen):** a user provider block matches a vendored
  provider when (a) the user `baseUrl` EQUALS the vendored provider's
  `baseUrl` (string compare, case-insensitive, a single trailing `/`
  stripped on both sides) — evaluated across the vendored providers; or
  (b) the user provider declares NO `baseUrl` and its KEY equals the
  vendored provider name (case-insensitive). Priority (a) over (b); no
  bare-id cross-provider fallback (a `zai`-keyed localhost base must NOT
  match — the hermetic-test inertness law). Model match: the user model
  `id` equals the vendored model `id` (case-insensitive) within the
  matched provider.
- **Fill-only fields:** `contextWindow`, `maxTokens`, `reasoning`,
  `thinkingLevelMap`, `compat`, `name` — a field fills ONLY when the user
  entry omits it (nil/absent); a user-declared value ALWAYS wins. `compat`
  fills through the existing `build_compat` six-key pick (vendored
  superset keys tolerated-and-dropped, the I46 law).
- **Consultation seams (the only behavior changes):**
  `Models.entry_context_window` / `Models.entry_max_tokens` — the tier
  slots between the entry's declared value and the `DEFAULT_ENTRY_*`
  definition default (an ENTRY that omits the field + a vendored match ⇒
  the vendored value; no match ⇒ today's 128_000/16_384; nil entry ⇒ nil,
  unchanged); `Settings.thinking_facts` — the map slots between the
  entry's map and the known tables (entry → vendored → known-tables), the
  reasoning flag between the entry's flag and `model_reasoning_capable`
  (entry → vendored → capable); `Models.dialect_for_entry(entry)` (NEW
  public seam) — `dialect_for(entry.compat || vendored compat)`; the
  boot/switch threading call sites that today pass
  `dialect_for(entry.compat)` move to `dialect_for_entry(entry)`
  (`bin/tart` boot kwargs, `chat.rb` `apply_model_selection`; the
  `wire_model` signature and `dialect_for` are UNCHANGED — existing
  direct-call pins hold).
- **Loader discipline:** raw JSON parse (NEVER through the models.json
  `CatalogContract` — the vendored files carry pi's full schema, not the
  port's subset), lazy per-file parse, cached after first use, resolved
  from `lib/tart/models/` by a `__dir__`-relative path to
  `vendor/pi-models/`; a missing or unparseable vendor file degrades to
  that provider being absent (never raises, never blocks boot).

**R3 — the live listing (lib/tart/models/listing.rb, NEW).**
`Tart::Models::Listing.fetch(base_url:, api_key:, timeout: 5)` →
`Array<String>` of model ids, or `nil` on ANY failure:

- ONE attempt, bounded `timeout:` (5 s default, a frozen constant),
  GET `<base_url>/models` (the OpenAI-compatible `/v1/models` convention;
  the configured base already carries `/v1`), `Authorization: Bearer
  <key>`; a one-off `Async::HTTP::Client` inside ONE dedicated background
  thread (the herdr-sender discipline: off the reactor, never blocks the
  UI, joined/cleaned by the caller) — the ONE sanctioned new
  `Thread.new` site (the threads-budget gate carries the declared
  exclusion, `listing-thread-law` pins it).
- Every failure class (connect refused, timeout, non-200, malformed body)
  returns nil; NOTHING is raised into the caller; NO retries, NO
  backoff, NO retry storm (one fetch per menu open, user-initiated).
- **Trigger (frozen):** `Render::Chat#open_model_menu` ONLY — every menu
  open (plain or seeded) fires ONE fetch; NEVER at boot, NEVER in print
  mode, NEVER from subagent children (no interactive surface), NEVER from
  `/model <ref>` direct switches (the exact-match path needs no listing).
- **Endpoint resolution (frozen):** at menu-open time, for the CURRENT
  model ref's provider key — the provider block's `baseUrl`/`apiKey` from
  the user catalog, falling back per-field to the threaded boot endpoint
  facts (which carry the env tier); a base+key that still does not
  resolve ⇒ NO attempt (menu = user entries only, no failure row).

**R4 — the menu merge (lib/tart/render/model_menu.rb +
lib/tart/render/chat.rb).**

- `Render::Chat` gains an `endpoint:` kwarg (default nil = no listing —
  every existing test construction is unchanged); the fetch is spawned at
  menu open, the menu renders IMMEDIATELY with the user entries, and the
  listing MERGES IN when it lands (merge under the Chat mutex, then
  `request_draw`).
- `ModelMenu#refresh(entries:)` (NEW public): rebuilds the item list from
  the merged entries, re-runs the fuzzy filter with the CURRENT query
  preserved, clamps the selection per the existing empty-query rule; the
  row shape, the sort, the ✓/· markers, the `Model Name:` row are
  UNCHANGED — no new glyphs, no new columns.
- Live entries are constructed as typed `Shapes::Model` under the
  CONFIGURED provider key: `id` = the listed id verbatim, the fill fields
  from the vendored tier (same match rule against the configured
  provider's vendored counterpart; no match ⇒ bare entry, `name` = id),
  `context_window`/`max_tokens` nil (the entry-fact seams resolve them —
  a vendored match fills, no match ⇒ the definition defaults, the
  declared gap-entry semantics).
- Collision rule: a live id that already exists as a user entry (same
  provider key + id) is NOT duplicated — the user entry wins. Selecting a
  live entry rides `apply_model_selection` UNCHANGED (the merged entry
  threads its facts; persist writes settings, never models.json).
- Failure presentation: `ModelMenu` gains a failure flag — when the fetch
  failed, ONE muted row `  (live listing unavailable)` renders after the
  list rows; absent on success and before the fetch settles. No transcript
  status, no MOTD row, no log noise.

**R5 — the launcher threading (bin/tart).** `build_surface` gains an
`endpoint:` parameter and threads the boot endpoint facts (the same
`endpoint_facts` chain `build_chat` uses) into `Render::Chat`. The I27
live-defect lesson is the law: every new surface kwarg ships with a
launcher-seam regression pin (`launcher_smoke_test` leg
`test_build_surface_threads_the_listing_endpoint` — a staged catalog +
mock listing server through `build_surface`, the menu merges live rows).

**R6 — the tests (additive; the enumerated pins).** NEW/extended pins:
`test/models_test.rb` `/vendored/` family (≥6 runs: the match rule both
arms, the fill-only truth table, the no-match inertness, the owner-catalog
no-op, `dialect_for_entry` both arms); `test/settings_test.rb` `/vendored/`
(≥1: the `thinking_facts` tier order entry → vendored → known-tables);
`test/models_listing_test.rb` (NEW, ≥5 runs: fetch happy path against the
mock, GET path + Bearer header pinned from the captured request log, dead
endpoint ⇒ nil + bounded elapsed, single attempt (server request_count ==
1), malformed/non-200 ⇒ nil, boot-inert (constructing the Chat + footer
facts makes ZERO requests)); `test/chat_test.rb` `/live_list/` (≥3: the
merge-in with vendored enrichment, the user-entry-wins dedup, the failure
row + no-crash + single attempt, the live-entry switch threading vendored
facts); `test/render/model_menu_test.rb` `/refresh/` (≥2: refresh
preserves query/clamps selection, the failure row shape);
`test/launcher_smoke_test.rb` `/listing_endpoint/` (≥1);
`test/support/mock_llm_server.rb` gains a `:models` spec type (responds
`{"object":"list","data":[{"id":…,"object":"model"}…]}` to any request —
the recorded-wire log keeps method/path/headers as today). NOTHING is
deleted; moved pins itemized if any frozen pin legitimately shifts (none
expected outside the declared strict_sampling wire dimensions — its own
assertions do not pin them).

### Frozen expectations (do not redesign)

- The resolution-order law (I27): env > models.json (user entries + the
  "default" key) > settings — the vendored tier INFORMS (fills absent
  fields, enriches live ids), NEVER overrides any tier. A user-declared
  value always wins; the env tiers (`<IDENTITY>_CONTEXT_WINDOW` etc.) sit
  above the catalog facts exactly as today.
- The loaded catalog is byte-stable: `Models.load` output, `Config`,
  `model_entries`, `Shapes::Model#to_h`, the `resolve` match tables, the
  schema contract — UNCHANGED. The fill happens at the fact-resolution
  seams only.
- `dialect_for` and the Dialect vocabulary are FROZEN (I46/I64/I70): only
  a zai `thinkingFormat` builds the zai dialect; every other compat
  (incl. the vendored `openrouter`/`deepseek` formats) rides the DEFAULT
  dialect with tolerated-and-dropped keys. The vendored compat does NOT
  extend the wire vocabulary.
- The wire/session guards hold EXACT: the parity family, `wire-delta`,
  `session-golden`, `zai-max-tokens-wire` stage full-fact or non-matching
  catalogs — byte-identical before/after.
- The never-raise boot law (I27): a missing/corrupt vendor file is a
  degraded tier, never a boot error, never a warning on the MOTD.
- No network at boot; no runtime fetch from pi.dev EVER (the refresh task
  is the only updater and it is offline + operator-run).
- `~/.tart/models.json` format unchanged (no new keys required, no
  migration); the owner's live file is a merge no-op.
- The suite's standing 1 skip stays; `SEAM_BENCH_OK` stays; the suite
  grows past the measured floor.
- The I70 flip's regression pins (default-on law/boot, motd units/probe,
  e2e default-on, rig staging) carry as the standing battery.

### Named exclusions (Constraints, itemized)

- NO rig changes at all (`gems/tui-split-rig/**` outside the touch set);
  no scenario-content edits; the parity family carries byte-identical.
- NO changes to the LLM request path beyond the fact threading named in
  R2 (`lib/tart/agent/**`, the Chat client, `wire_model`, the gem
  untouched); no dialect vocabulary extension; no new wire keys.
- NO models.json persistence of live listings (the menu is ephemeral; the
  persist path stays settings-only).
- NO new runtime gems (the listing rides the existing async-http stack
  already in the lockfile); no Gemfile/Gemfile.lock/tart.gemspec changes.
- NO caching layer, TTL, or debounce for listings (one fetch per menu
  open — simplicity over cleverness, no retry surface).
- NO vendor-time pruning/rewriting of the pi data (verbatim copies only;
  the manifest records provenance).
- NO boot-time listing, NO print-mode listing, NO listing in subagent
  children; NO MOTD/settings surface for the vendored tier.
- The model-window tick stays DEAD; landing is the human's; routing rides
  `architect.yaml` as-is.

### Output format

Builder Report per the standing template: the one-paragraph result, the
suite summary line, the gate one-liners table (EVERY frozen gate — the
I68/I70 lesson: an absent gate in the table is a REJECT-class violation),
the itemized deviation list (any moved pin named), residual risks.

### Tool guidance

Read-only grounding first: `lib/tart/models.rb` (the fact seams),
`lib/tart/settings.rb` (`thinking_facts`), `lib/tart/render/chat.rb`
(`open_model_menu`/`apply_model_selection`/`model_menu_entries`),
`lib/tart/render/model_menu.rb`, `bin/tart` (`build_surface`,
`endpoint_facts`, the three boot fact-threading sites),
`lib/tart/herdr.rb` (the background-thread discipline),
`test/models_test.rb` + `test/support/mock_llm_server.rb` (the staged
catalog idioms), `repos/pi/packages/ai/src/providers/data/` (the data being
vendored). Then R1 (data + task) → R2 (the tier, run the suite EARLY to
catch inertness misses — a frozen pin shifting on the fill is
STOP-and-disclose) → R3/R4 (listing + menu) → R5/R6 (launcher + pins).
Run `bundle exec ruby bench/seam_bench.rb` before reporting.

### Boundaries

Touch set (the scope gate's whitelist, exactly):
`lib/tart/models.rb`, `lib/tart/models/vendored.rb` (NEW),
`lib/tart/models/listing.rb` (NEW), `lib/tart/settings.rb`,
`lib/tart/render/chat.rb`, `lib/tart/render/model_menu.rb`, `bin/tart`,
`Rakefile`, `vendor/pi-models/**` (NEW data + attribution + manifest),
`test/models_test.rb`, `test/settings_test.rb`,
`test/models_listing_test.rb` (NEW), `test/chat_test.rb`,
`test/render/model_menu_test.rb`, `test/launcher_smoke_test.rb`,
`test/support/mock_llm_server.rb`. Must-differ: `lib/tart/models.rb`,
`lib/tart/render/chat.rb`, the vendored dir (existence-gated:
`ATTRIBUTION.md`, `.manifest.json`, `vendored.rb`, `listing.rb`).
Must-not-touch (pinned by the scope gate): `gems/tui-split-rig/**`,
Gemfile/Gemfile.lock/tart.gemspec, `bench/`, `lib/tart/agent/**`,
`lib/tart/commands.rb`, `lib/tart/prompts.rb`, `lib/tart/skills.rb`,
`lib/tart/schemas.rb`, `lib/tart/shapes.rb`, `lib/tart/subagents/**`,
`lib/tart/tools/**`, `lib/tart/mcp/**`, `lib/tart/core/**`,
`lib/tart/tui.rb`, `lib/tart/herdr.rb`, and every other path. A test
OUTSIDE the whitelist breaking on the fill: STOP and disclose (the I69
blast-radius rule) — the one pre-declared exception is the
`strict_sampling` staged-config wire dimensions (Grounds), which its own
assertions do not pin.

### Lane plan

- id: core
  repo: tart
  base: dd41ae1
  integration_branch: project/pi-port
  effort: high
  lanes_required: 1
  rationale: the code deltas are moderate (one data dir, two small
    modules, three seam insertions, one menu refresh path) but the audit
    surface is exacting: the fill-only law must hold at every fact seam,
    the hermetic-test inertness depends on the baseUrl-first match rule,
    the live-listing failure matrix must be pinned cold, and any frozen
    pin shift outside the declared set is a lane failure.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/models.rb
    - lib/tart/models/vendored.rb
    - lib/tart/models/listing.rb
    - lib/tart/settings.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/model_menu.rb
    - bin/tart
    - Rakefile
    - vendor/pi-models/ATTRIBUTION.md
    - vendor/pi-models/.manifest.json
    - vendor/pi-models/*.json
    - test/models_test.rb
    - test/settings_test.rb
    - test/models_listing_test.rb
    - test/chat_test.rb
    - test/render/model_menu_test.rb
    - test/launcher_smoke_test.rb
    - test/support/mock_llm_server.rb
  effort: high
```

### Effort call

High — not for code volume but for enumerated exactness: the match rule
carries the hermetic-suite inertness load, the fill-only law must be
proven at four seams, the live-listing failure matrix needs cold-reliable
pins against a mock, and the launcher threading carries the I27
live-defect lesson.

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
