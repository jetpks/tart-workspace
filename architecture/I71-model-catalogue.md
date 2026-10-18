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

- **Suite: 1229 runs / 6047 assertions / 0 failures / 0 errors / 1 skips** (rake exit 0, measured cold this session — the
  floor the AC freezes; the loop-state's 1229/6047 record is superseded by
  this fresh measurement).
- `SEAM_BENCH_OK`: measured the same session: `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
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

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **61 gates — 53 carried from the I70
frozen block + 8 new/rewritten.** The carry audit ran clean BEFORE
rehearsal (`tmp/i71-spec/audit-gates.rb`: 53 OK — 33 byte-identical + 20
byte-identical after the DECLARED rebases, zero DIFF, zero UNDECLARED-DROP,
zero AC-DRIFT). **Declared DROPPED (1):** `scope` — per-iteration
(rewritten here, never carried). **Declared rebases (20 commands,
byte-verbatim except these):** the out-dir family `t70*`→`t71*` with s9
`t7s9`→the FIVE-char `t71s9` (the I71 lane tree is 79 chars —
`build/I71-model-catalogue-core/wt` — so the s9 wrap law (row = tree +
outdir + 32, fires > 120) puts s9's row at 116, inside the proven-green
boundary); `threads-budget`'s diff base `2a33f66`→`dd41ae1` (the
iteration base) AND a declared pathspec exclusion of
`lib/tart/models/listing.rb` (the ONE sanctioned new background thread —
R3's live-listing fetch; the budget law still covers every other lib path,
and the new `listing-thread-law` gate pins the exception to exactly one
`Thread.new` in `listing.rb` and none elsewhere in the models family);
the mktmpdir prefixes (`i70-hu-`/`i70-boot-`→`i71-*`) and the
rig-identity-assert scratch out — cosmetic, zero semantics. The carried
gates keep their I70 `ac:` labels verbatim — the 7 I70-new subagents gates
(default-law/default-boot/motd-units/motd-probe/e2e-default-on/
rig-staging-units) carry as STANDING regression pins of the landed I70
flip (they were GREEN at the I70 integrated tip and must stay green);
only the 8 new gates map to this iteration's AC1–AC4.

**The designed-RED vector (8, every one RED at base dd41ae1 for the
right reason — the iteration's own work does not exist at base):**
`vendored-attribution` (no `vendor/pi-models/` — declared-new),
`vendored-units` (no `/vendored/` pins, runs=0, and `dialect_for_entry`
is an undefined method — declared-new), `listing-units` (no
`test/models_listing_test.rb`, runs=0 — declared-new),
`model-menu-live-merge` (no `/live_list/` or `/refresh/` pins, runs=0 —
declared-new), `launcher-listing-thread` (no `/listing_endpoint/` pin,
runs=0 — declared-new), `vendored-no-boot-network` (the menu surface
never invokes a listing at base), `listing-thread-law` (no `listing.rb`
at base), `scope` (the must-differ legs untouched at base). Everything
else GREEN at base. **Measured base this session (dd41ae1, cold, fresh —
never a predicted floor): 1229 runs / 6047 assertions / 0 failures / 0 errors / 1 skips, rake exit 0** +
`SEAM_BENCH_OK` (measured the same session).

**AC1 — the vendored baseline lands, attributed, refreshable offline.**
All 44 provider JSON files from the pinned pi clone sit in
`vendor/pi-models/` byte-identical to the oracle (gated against the
pinned clone via the git-common-dir idiom), with `ATTRIBUTION.md`
(Mario Zechner / MIT / source / refresh command / local-only law) and
tart's own `.manifest.json` (source, revision, generatedAt, per-file
sha256 covering exactly the vendored `*.json` set). The refresh task
`rake models:vendor:refresh` exists, is listed by `rake -T`, reads a
local pi checkout (`ENV["PI_REPO"]`, default `../pi`),
fails loudly when absent, and carries NO network tokens (the Rakefile is
grepped). The vendored tier never touches the network at boot or on
demand — local file reads only. Gate: `vendored-attribution`.

**AC2 — merge semantics: fill-only, matched, order-preserving.** The
vendored tier fills ONLY absent fields (`contextWindow`, `maxTokens`,
`reasoning`, `thinkingLevelMap`, `compat`, `name`) for user-referenced
entries whose provider block matches a vendored provider by the frozen
rule — baseUrl EXACT (case-insensitive, one trailing slash tolerated)
first; the provider KEY only when the user block declares NO baseUrl;
model id equality within the matched provider; NO cross-provider
bare-id fallback. A user-declared value always wins; the loaded catalog
(`Models.load` output, `Config`, `model_entries`, `Shapes::Model#to_h`,
the schema contract) is byte-unchanged — the fill lives at the
fact-resolution seams (`entry_context_window`, `entry_max_tokens`,
`thinking_facts`'s map/reasoning tiers entry→vendored→known-tables, the
new `dialect_for_entry`) and nowhere else. The owner's live
models.json is a merge NO-OP; the hermetic staged catalogs
(`glm`@example.test, `zai`@localhost, `mock`@local-mock) match nothing
vendored and every frozen pin outside the declared set holds. The
resolution order (I27 env > user catalog > settings) is preserved — the
vendored tier informs, never overrides. Gate: `vendored-units`.

**AC3 — live listing on /model demand, merged presentation.** Opening
the /model menu fires ONE bounded (5 s) authenticated GET
`<api_base>/models` against the CONFIGURED provider (the current model
ref's provider block baseUrl/apiKey, falling back per-field to the
threaded boot endpoint facts; unresolvable ⇒ no attempt), off the UI
thread; the menu renders the user entries IMMEDIATELY and merges the
listed models in when the fetch lands — live entries are typed models
under the configured provider key, enriched with vendored facts by the
same match rule, deduped against user entries (user wins), selectable
through the unchanged switch seam (a vendored-enriched live entry
threads its window/map/compat exactly like a catalog entry). The
launcher threads the endpoint (`build_surface` → `Render::Chat` — the
I27 kwarg-lesson, pinned). Gate: `listing-units`,
`model-menu-live-merge`, `launcher-listing-thread`.

**AC4 — degradation and the network laws.** Every failure class
(connection refused, timeout, non-200, malformed body) degrades
gracefully: the fetch returns nil, NOTHING raises into the surface, the
menu keeps the user entries, exactly ONE muted `(live listing
unavailable)` row renders after the list, and there are NO retries (one
request per menu open — pinned from the captured request log). NO
network at boot (the vendored tier is local-file only — grepped; the
listing is invoked exclusively from the menu-open path — grepped); the
refresh task is offline and operator-run. The ONE background thread is
the listing fetch and nothing else (the threads-budget exclusion is
pinned to exactly it). Gates: `vendored-no-boot-network`,
`listing-thread-law`.

**AC5 — the parity surface and the standing regression pins hold.** The
carried battery is green: the parity family s1–s10, s17, s1-tart-mode
(short out dirs, own `rm -rf`), `wire-delta` + `session-golden` +
`zai-max-tokens-wire` EXACT (the staged catalogs are fill-inert), the
oracle gates under the pin, the render/markdown/error-transcript/
tool-pending/user-bash standing pins, and the I70 flip's regression pins
(default-on law/boot, motd units + live probe, e2e default-on, rig
staging). The scope gate confines the tree to the frozen touch set
(tracked diff AND untracked sweep, the rehearsal out-dir family
excluded), with the must-differ legs in place. Gate: `scope` + the
carried `ac: AC4/AC5` family.

**AC6 — the regression floor is green and grown.** The full suite passes
cold with 0 failures / 0 errors / the standing 1 skip, at a run count
STRICTLY GREATER than the measured base floor 1229 (the new pins
are additive; nothing is deleted); `SEAM_BENCH_OK`. The one pre-declared
behavioral shift outside the gates (Grounds): the `strict_sampling`
staged config's UN-PINNED wire dimensions (max_tokens, reasoning_effort)
move under the fill — its own assertions stay green. Gates: `suite`,
`bench`.
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
    added=$(git diff dd41ae1 -- lib ':(exclude)lib/tart/models/listing.rb' | grep -E "^\+[^+].*Thread\.new" || true)
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
    --gate --out t71tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t71ub
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
  cmd: rm -rf t71s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t71s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t71s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t71s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t71s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t71s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t71s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t71s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t71s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t71s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t71s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t71s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t71s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t71s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t71s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t71wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t71wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t71wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t71zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t71zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t71zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
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
    home = Dir.mktmpdir("i71-boot-")
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
    dir = Dir.mktmpdir("i71-hu-")
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
    rm -rf t71hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t71hwp
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
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i71-unused")
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
- id: vendored-attribution
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK
- id: vendored-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i71-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK
- id: listing-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK
- id: model-menu-live-merge
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK
- id: launcher-listing-thread
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK
- id: vendored-no-boot-network
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK
- id: listing-thread-law
  ac: AC4
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: 'git diff --quiet dd41ae1 -- Gemfile Gemfile.lock tart.gemspec bench gems/tui-split-rig/scenarios
    gems/tui-split-rig/lib gems/tui-split-rig/bin gems/tui-split-rig/test lib/tart/tui.rb
    lib/tart/herdr.rb lib/tart/commands.rb lib/tart/prompts.rb lib/tart/skills.rb
    lib/tart/schemas.rb lib/tart/shapes.rb lib/tart/agent lib/tart/subagents lib/tart/tools
    lib/tart/mcp lib/tart/core && ! (git diff --name-only dd41ae1; git status --porcelain
    | grep "^??" | cut -c4-) | grep -vE "^(lib/tart/models\.rb|lib/tart/models/vendored\.rb|lib/tart/models/listing\.rb|lib/tart/render/chat\.rb|lib/tart/render/model_menu\.rb|lib/tart/settings\.rb|bin/tart|Rakefile|vendor/pi-models/.*|vendor/pi-models/|test/models_test\.rb|test/settings_test\.rb|test/models_listing_test\.rb|test/chat_test\.rb|test/render/model_menu_test\.rb|test/launcher_smoke_test\.rb|test/support/mock_llm_server\.rb|t71[0-9a-z]*/?)$"
    | grep -q . && [ -n "$(git diff dd41ae1 -- lib/tart/models.rb)" ] && [ -n "$(git
    diff dd41ae1 -- lib/tart/render/chat.rb)" ] && [ -f vendor/pi-models/ATTRIBUTION.md
    ] && [ -f vendor/pi-models/.manifest.json ] && [ -f lib/tart/models/vendored.rb
    ] && [ -f lib/tart/models/listing.rb ] || { echo "FAIL: scope — the tree bites
    outside the frozen touch set or a must-differ member is untouched (models.rb/chat.rb/the
    vendored dir)"; exit 1; } && echo SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

You are the builder for iteration `model-catalogue` (I71), lane `core`.
Work ONLY in the provisioned worktree on branch
`lane/I71-model-catalogue-core` (base tart `project/pi-port` @ `dd41ae1`
— the I70-integrated tip, clean); NEVER commit (the integrator lands your
tree), NEVER touch the space repo, NEVER push, NEVER touch any gem
(published fast-completions 0.5.0 and ratatui_ruby 1.5.0 are dependencies
— consume, never modify), NEVER write anything under `repos/pi` (the
pinned oracle clone @ v1.1.0, branch `oracle-v1.1.0`, is ENVIRONMENT,
guarded by the `oracle-pin-state` gate — read-only reference: you COPY its
committed data files, you never modify the clone). The full iteration
contract is the frozen Grounds/Specification/Acceptance Criteria in the
arch file (authoritative) — read them first; this header is the lane's
operating brief. You are the ONLY lane.

THE TASK IN ONE PARAGRAPH: `/model` learns what is available — the owner's
option-C ruling. (1) THE VENDORED BASELINE: copy all 44 provider JSON
files from the pinned pi clone's `packages/ai/src/providers/data/`
VERBATIM (byte-identical) into a NEW `vendor/pi-models/` dir, plus
`ATTRIBUTION.md` (source, MIT / "Copyright (c) 2025 Mario Zechner", link,
the refresh command, the local-clone-only law) and tart's OWN
`.manifest.json` (`{source, revision, generatedAt, files: {name: sha256}}`
covering exactly the vendored `*.json` set; pi's own `.manifest.json` is
NOT copied); add the offline operator-run rake task
`models:vendor:refresh` to the Rakefile (reads `ENV["PI_REPO"]`, default
`../pi` rel the tart root; fails LOUDLY when the clone is missing; copies
verbatim + regenerates the manifest; ZERO network — no Net::HTTP /
Async::HTTP / URI.open / open-uri tokens anywhere in the Rakefile, gated).
(2) THE VENDORED TIER (`lib/tart/models/vendored.rb`, NEW): a local-file
metadata tier consulted at the FACT seams only — the loaded catalog is
NEVER mutated (`Models.load`/`Config`/`model_entries`/`Shapes::Model#to_h`
byte-stable). MATCH RULE (frozen): a user provider block matches a
vendored provider by baseUrl EXACT (case-insensitive, one trailing `/`
stripped both sides) FIRST; the provider KEY (case-insensitive) ONLY when
the user block declares NO baseUrl; model id equality (case-insensitive)
within the matched provider; NO cross-provider bare-id fallback — a
`zai`-keyed `http://localhost:1/v1` block matches NOTHING (the
hermetic-suite inertness law). FILL-ONLY: `contextWindow`, `maxTokens`,
`reasoning`, `thinkingLevelMap`, `compat`, `name` fill ONLY when the user
entry omits the field; a declared value ALWAYS wins; compat fills through
the existing `build_compat` six-key pick. SEAMS: `entry_context_window` /
`entry_max_tokens` slot the tier between the declared value and the
`DEFAULT_ENTRY_*` constants (no match ⇒ today's 128_000/16_384; nil entry
⇒ nil, unchanged); `Settings.thinking_facts` slots the map between the
entry's map and the known tables and the reasoning flag between the
entry's flag and `model_reasoning_capable`; a NEW public
`Models.dialect_for_entry(entry)` = `dialect_for(entry.compat ||
vendored compat)` and the threading call sites that pass
`dialect_for(entry.compat)` move to it (bin/tart boot kwargs, chat.rb
`apply_model_selection`); `dialect_for` and `wire_model` signatures are
UNCHANGED. LOADER: raw JSON parse (NEVER through the models.json
CatalogContract — pi's schema is a superset), lazy per-file, cached,
`__dir__`-relative path to `vendor/pi-models/`; missing/corrupt file ⇒
that provider absent from the tier — never raises, never blocks boot, no
MOTD noise. (3) THE LIVE LISTING (`lib/tart/models/listing.rb`, NEW):
`Tart::Models::Listing.fetch(base_url:, api_key:, timeout: 5)` →
`Array<String>` of ids or `nil` on ANY failure — ONE attempt, bounded
timeout (5 s frozen constant), GET `<base_url>/models` with
`Authorization: Bearer <key>`, a one-off Async::HTTP client inside ONE
dedicated background thread (the `lib/tart/herdr.rb` sender discipline:
off the reactor, never blocks the UI) — the ONE sanctioned new
`Thread.new` site (the threads-budget gate excludes exactly
`lib/tart/models/listing.rb`; the `listing-thread-law` gate pins exactly
one `Thread.new` there and none in `models.rb`/`vendored.rb`). Every
failure class (refused, timeout, non-200, malformed) ⇒ nil, nothing
raised into the caller, NO retries. (4) THE MENU MERGE
(`lib/tart/render/chat.rb` + `model_menu.rb`): `Render::Chat` gains an
`endpoint:` kwarg (default nil ⇒ no listing — every existing test
construction unchanged); `open_model_menu` fires ONE fetch per open
(plain or seeded) — NEVER at boot, NEVER print mode, NEVER subagent
children, NEVER the `/model <ref>` direct-switch path — resolving the
endpoint at open time for the CURRENT model ref's provider (provider
block baseUrl/apiKey, per-field fallback to the threaded boot facts;
unresolvable ⇒ no attempt); the menu renders the user entries
IMMEDIATELY and merges the listed ids in when the fetch lands (merge
under the Chat mutex, `request_draw`); live entries are typed
`Shapes::Model` under the configured provider key, enriched by the
vendored tier through the SAME match rule (no match ⇒ bare entry, name =
id), deduped against user entries (user wins on provider+id collision);
selecting one rides `apply_model_selection` UNCHANGED. `ModelMenu` gains
`refresh(entries:)` (rebuild items, re-filter with the CURRENT query,
clamp selection per the existing empty-query rule; row shape/sort/
markers/`Model Name:` row UNCHANGED — no new glyphs) and a failure flag
rendering ONE muted `  (live listing unavailable)` row after the list
rows when the fetch failed (absent otherwise). (5) THE LAUNCHER
THREADING (`bin/tart`): `build_surface` gains an `endpoint:` parameter
threading the boot `endpoint_facts` into `Render::Chat` — the I27
live-defect lesson: ship it with the launcher-seam regression pin.
(6) THE TESTS (additive, enumerated in R6): `test/models_test.rb`
`/vendored/` ≥6; `test/settings_test.rb` `/vendored/` ≥1;
`test/models_listing_test.rb` NEW ≥5 (happy path via the mock, GET path +
Bearer pinned from the captured request log, dead endpoint ⇒ nil +
bounded elapsed, single attempt — server request_count == 1, malformed/
non-200 ⇒ nil, boot-inert: constructing the Chat and reading footer facts
makes ZERO requests); `test/chat_test.rb` `/live_list/` ≥3 (merge-in with
vendored enrichment, user-wins dedup, failure row + no crash + single
attempt, live-entry switch threads vendored facts);
`test/render/model_menu_test.rb` `/refresh/` ≥2; `test/launcher_smoke_test.rb`
`test_build_surface_threads_the_listing_endpoint`; the mock server gains
a `:models` spec type answering `{"object":"list","data":[{"id":…,
"object":"model"}…]}` (the request log keeps method/path/headers as
today).

LAWS YOU MUST NOT BREAK: the fill-only law (a user-declared value ALWAYS
wins, at every seam); the loaded-catalog byte-stability law (fill at the
fact seams, never merge-at-load); the resolution order (I27 env > user
catalog > settings — vendored informs, never overrides); the dialect
boundary (I46/I64: ONLY a zai thinkingFormat builds the zai dialect — the
vendored `openrouter`/`deepseek` formats ride the DEFAULT dialect,
tolerated-and-dropped; do NOT extend the wire vocabulary); no network at
boot, no runtime pi.dev fetch EVER; `~/.tart/models.json` format
unchanged and the owner's live file is a merge NO-OP; the wire/session
guards hold EXACT (the staged parity catalogs are fill-inert); no new
gems; no rig changes; `lib/tart/agent/**`, `commands.rb`, `schemas.rb`,
`shapes.rb`, `prompts.rb`, `skills.rb`, `subagents/**`, `tools/**`,
`mcp/**`, `core/**`, `tui.rb`, `herdr.rb` are OUT OF BOUNDS.

RUN DISCIPLINE: ground read-only first (the R-list in Tool guidance);
land R1 (data + task) then R2 and RUN THE FULL SUITE EARLY — a frozen pin
shifting on the fill outside the pre-declared set (Grounds: the
strict_sampling staged config's UN-PINNED wire dimensions move BY DESIGN —
max_tokens 16_384→131_072, reasoning_effort `medium`→`high` under the
vendored map; its own assertions stay green) is STOP-AND-DISCLOSE for the
judge. Then R3/R4 (listing + menu), R5/R6 (launcher + pins). Before
reporting: `cd repos/tart && bundle install --quiet && bundle exec rake`
(full suite, 0F/0E, the standing 1 skip, runs STRICTLY greater than the
frozen base floor), `bundle exec ruby bench/seam_bench.rb`
(SEAM_BENCH_OK), and the gate table below — EVERY one of the 61 frozen
gates, one line each, executed verbatim from the frozen gates block (an
absent gate in the table is a REJECT-class violation — the I68 lesson).
The 8 designed-RED gates are RED at BASE; on your tree they must go GREEN
for the right reason (the work existing), never RED-for-a-defect.

OUTPUT (your scratch report, `build/I71-model-catalogue-core/report.md`):
the one-paragraph result; the suite summary line (runs/assertions/F/E/S);
the 61-line gate table (gate id, GREEN/RED/BROKEN, the load-bearing token
or the failing line); the itemized deviation list (every moved pin or
judgment call named — never silent); residual risks (the live
`/v1/models` against a REAL provider key is the named human checkpoint —
statically pinned only; the vendor dir does not ship in the gem package —
from-source daily driver only, flagged for the human).

## Builder Report

### core

# I71 model-catalogue — lane core — Builder Report

## Result (one paragraph)

`/model` knows what is available. R1 landed `vendor/pi-models/` — all 42 provider JSON files copied byte-verbatim from the pinned oracle clone (`repos/pi/packages/ai/src/providers/data/`, verified byte-identical + sha256-manifested by the `vendored-attribution` gate) plus `ATTRIBUTION.md` (Mario Zechner / MIT / source link / refresh command / local-clone-only law) and tart's own `.manifest.json` (source, revision `abe508e1…` = the clone HEAD, generatedAt, per-file sha256 over exactly the vendored set; pi's own manifest NOT copied) — and the offline operator-run `rake models:vendor:refresh` (reads `ENV["PI_REPO"]`, default `../pi`; fails LOUDLY when absent — exercised; zero network tokens in the Rakefile — gated). R2 landed the vendored tier (`lib/tart/models/vendored.rb`): raw-JSON lazy per-file cached loader, `__dir__`-relative, never-raise (missing/corrupt ⇒ provider absent); the frozen match rule (baseUrl EXACT case-insensitive one-trailing-slash first across the vendored providers — indexed per-model because 8 vendored files legitimately serve models under multiple baseUrls; provider KEY only when the block declares no baseUrl, with load-path-registered block baseUrls carried on a WeakMap keyed by the typed entry objects so hand-built test catalogs are inert by construction); fill-only at the four seams — `entry_context_window`/`entry_max_tokens` (declared → vendored → `DEFAULT_ENTRY_*`; nil entry ⇒ nil), `Settings.thinking_facts` (map: entry → vendored → known-tables; reasoning: entry flag → vendored → today's flag), and the new public `Models.dialect_for_entry(entry)` = `dialect_for(resolved_compat(entry))` with the boot kwargs + `apply_model_selection` threading the vendored-filled compat; the loaded catalog (`Models.load`/`Config`/`model_entries`/`Shapes::Model#to_h`) is byte-stable (pinned). R3 landed `Models::Listing.fetch` — ONE bounded (5 s frozen constant) authenticated GET `<base_url>/models` inside ONE dedicated background thread (the tree's single new thread site, gate-pinned), Async::HTTP one-off client, every failure class ⇒ nil, no retries; an optional `on_result:` callback delivers fire-and-forget so the surface never blocks. R4/R5 landed the menu merge + launcher threading: `Render::Chat` gains `endpoint:` (default nil ⇒ no listing — every pre-existing construction unchanged; the lazy require keeps the async stack out of boot), `open_model_menu` (plain and seeded) fires exactly one fetch per open resolved for the CURRENT model ref's provider (block baseUrl/apiKey, per-field fallback to the threaded boot facts, unresolvable ⇒ no attempt), the menu renders user entries immediately and merges when the fetch lands (merge under the Chat mutex + `request_draw`, open-generation guard), live entries are typed `Shapes::Model` under the configured provider key, vendored-enriched through the same match rule, deduped (user wins), selectable through the unchanged switch seam; `ModelMenu#refresh(entries:)` re-sorts/re-filters with the query preserved and clamps per the existing empty-query rule, and the failure flag renders exactly one muted `  (live listing unavailable)` row after the list rows; `bin/tart`'s `build_surface` threads the boot `endpoint_facts` via the new `endpoint:` parameter. R6 added the enumerated pins: `test/models_test.rb` /vendored/ ×8, `test/settings_test.rb` /vendored/ ×1, `test/models_listing_test.rb` ×10 (NEW), `test/chat_test.rb` /live_list/ ×4, `test/render/model_menu_test.rb` /refresh/ ×2, `test/launcher_smoke_test.rb` /listing_endpoint/ ×1, and the mock server's `:models` spec type. Final tree: **1255 runs / 6141 assertions / 0 failures / 0 errors / 1 skips** (base floor 1229/6047 — strictly greater, nothing deleted), `SEAM_BENCH_OK`, and 59 of the 61 frozen gates GREEN; the 2 REDs (s9-parity, scope) are disclosed below with decisive evidence — neither is a lane regression.

## Suite summary line

```
1255 runs, 6141 assertions, 0 failures, 0 errors, 1 skips   (rake exit 0; base floor 1229/6047/0/0/1)
SEAM_BENCH_OK   (bundle exec ruby bench/seam_bench.rb)
```

(The standing chat_test interrupt-during-streaming timing flake reproduced once mid-iteration; re-run cold → green, per the carried Grounds note.)

## The 61-gate table

Executed mechanically from the frozen gates block in `architecture/I71-model-catalogue.md` (extracted byte-verbatim by `/tmp/i71-gates/run_gates.rb`, never hand-retyped), cwd = the lane tree (`build/I71-model-catalogue-core/wt` standing in for `repos/tart`).

| gate | verdict | load-bearing token / failing line |
|---|---|---|
| suite | GREEN | 1255 runs, 6141 assertions, 0 failures, 0 errors, 1 skips; SUITE_OK |
| bench | GREEN | SEAM_BENCH_OK |
| md-repro | GREEN | MD_REPRO_OK |
| md-inline-units | GREEN | MD_INLINE_UNITS_OK (markdown ≥3, transcript-reasoning ≥1) |
| pending-registry-units | GREEN | PENDING_REGISTRY_UNITS_OK (≥4) |
| footer-window | GREEN | FOOTER_WINDOW_OK 1000000 |
| thinking-pins | GREEN | THINKING_PINS_OK (agent-loop ≥11, settings ≥8) |
| hermeticity | GREEN | HERMETICITY_OK (launcher 12 runs, e2e ≥4) |
| lock-deps | GREEN | LOCK_DEPS_OK + GEM_LOAD_OK |
| zai-data | GREEN | ZAI_DATA_OK |
| threads-budget | GREEN | THREADS_BUDGET_OK (no new Thread.new in lib outside the listing exclusion) |
| session-golden | GREEN | SESSION_GOLDEN_OK (7 digests exact) |
| strict-wire | GREEN | 8 runs, 76 assertions, 0 failures, 0 errors |
| error-transcript-units | GREEN | ERROR_TRANSCRIPT_UNITS_OK |
| error-transcript-render-units | GREEN | ERROR_TRANSCRIPT_RENDER_UNITS_OK |
| render-perf-units | GREEN | 7 runs, 29 assertions, 0 failures |
| render-perf-probe | GREEN | RENDER_PERF_OK (BP2 238.2 ≤ 250) |
| tool-pending-gate | GREEN | TOOL_PENDING_GATE_OK |
| user-bash-stream-gate | GREEN | USER_BASH_STREAM_GATE_OK |
| zai-max-tokens-units | GREEN | ZAI_MAX_TOKENS_UNITS_OK |
| rail-bg | GREEN | RAIL_BG_OK |
| jump-pill-units | GREEN | JUMP_PILL_UNITS_OK |
| rail-bg-units | GREEN | RAIL_BG_UNITS_OK |
| viewport-probe | GREEN | VIEWPORT_PROBE_OK |
| oracle-pin-state | GREEN | ORACLE_PIN_OK (repos/pi @ oracle-v1.1.0 == v1.1.0, clean, cli 1.1.0) |
| oracle-bin-units | GREEN | ORACLE_BIN_UNITS_OK |
| oracle-resolve | GREEN | ORACLE_RESOLVE_OK |
| s1-parity … s8-parity | GREEN | rig exit 0 each (t71s1…t71s8) |
| **s9-parity** | **RED** | rig exit 1 — diff candidates `['-d']`: the staged-path rows wrap at the frozen 120-col rig width (see disclosure D1) |
| s10-parity | GREEN | rig exit 0 (t71s10) |
| s17-parity | GREEN | rig exit 0 (t71s17) |
| s1-tart-mode | GREEN | TART_MODE_OK |
| wire-delta | GREEN | WIRE_DELTA_OK (instruction digest 4209f4…, tools digest 7360fd… exact) |
| zai-max-tokens-wire | GREEN | ZAI_WIRE_OK tart=pi=512 (staged catalog fill-inert) |
| identity-law | GREEN | IDENTITY_LAW_OK |
| default-face | GREEN | DEFAULT_FACE_OK |
| default-boot | GREEN | DEFAULT_BOOT_OK |
| herdr-units | GREEN | HERDR_UNITS_OK |
| herdr-wire-probe | GREEN | HERDR_WIRE_OK |
| rig-identity-assert | GREEN | RIG_IDENTITY_OK |
| subagents-default-law | GREEN | SUBAGENTS_DEFAULT_LAW_OK |
| subagents-default-boot | GREEN | SUBAGENTS_DEFAULT_BOOT_OK (default-on digest 2c744e…, opt-out digest 7360fd…) |
| subagents-motd-units | GREEN | SUBAGENTS_MOTD_UNITS_OK |
| subagents-motd-probe | GREEN | SUBAGENTS_MOTD_OK |
| subagents-e2e-default-on | GREEN | SUBAGENTS_E2E_DEFAULT_OK (4 runs) |
| rig-staging-units | GREEN | RIG_STAGING_OK |
| vendored-attribution | GREEN | VENDORED_ATTRIBUTION_OK 42 (byte-identical to the pinned oracle, manifest hashes exact, rake -T lists the task, Rakefile grep clean) |
| vendored-units | GREEN | VENDORED_UNITS_OK + /vendored/ pins 8 runs green + settings /vendored/ 1 run green |
| listing-units | GREEN | LISTING_UNITS_OK (10 runs) |
| model-menu-live-merge | GREEN | MODEL_MENU_LIVE_MERGE_OK (/live_list/ 4 runs, /refresh/ 2 runs) |
| launcher-listing-thread | GREEN | LAUNCHER_LISTING_THREAD_OK |
| vendored-no-boot-network | GREEN | VENDORED_NO_BOOT_NETWORK_OK |
| listing-thread-law | GREEN | LISTING_THREAD_LAW_OK (exactly one thread site in listing.rb, none elsewhere in the models family) |
| **scope** | **RED** | FAIL — the frozen untracked sweep flags the COLLAPSED directory names `lib/tart/models/` and `vendor/` (see disclosure D2); tracked frozen-path diff clean, must-differ legs all pass |

## The strict_sampling declared move (evidence, as pre-declared in Grounds)

Probe against the staged `zai`@`https://api.z.ai/api/coding/paas/v4` gap entry (reasoning+contextWindow+compat declared; maxTokens+thinkingLevelMap omitted):

```
max_tokens seam: 131072 (base 16384 -> vendored 131072)
reasoning_effort for session level medium: "high" (base medium -> vendored-clamped high)
dialect: :zai (compat declared — does not move)
```

`strict_sampling_test.rb` itself: 8 runs / 76 assertions / 0 failures / 0 errors — its own assertions (tool-rewrite digests, loadout order, dialect pins) stay green. No OTHER staged catalog matches a vendored provider (verified by sweep: `http://localhost:1/v1`, `https://example.test/v1`, and the mock-server baseUrls match nothing; the hand-built `glm`/`zai` test catalogs are unregistered ⇒ inert, and their `glm-5-air` id does not exist in the vendored data anyway).

## Deviations and judgment calls (itemized — none silent)

1. **42 files, not 44.** Grounds says "44 provider JSON files (~1.9 MB)"; the pinned clone holds 42 non-hidden provider JSON files (~1.0 MB) — the 43rd json file is pi's own `.manifest.json` (a dotfile, explicitly NOT copied). The frozen `vendored-attribution` gate compares non-recursive `Dir` globs on both sides; 42 is what binds and what shipped. Disclosed to the supervisor mid-run.
2. **`dialect_for_entry` threading mechanics.** The brief names "the threading call sites that today pass `dialect_for(entry.compat)`" — no such literal call sites exist at base (the dialect derives inside `wire_model` from the threaded compat; grep-verified). Implemented as specified functionally: new public `Models.dialect_for_entry(entry)` = `dialect_for(resolved_compat(entry))`, with `Models.resolved_compat(entry)` (the compat fill: entry's declared compat || vendored compat through `build_compat`'s six-key pick) threaded at the named sites (`bin/tart` boot kwargs ×2 — `boot_thinking_kwargs` and the interactive `start_session` loop kwargs — and `chat.rb apply_model_selection`). `dialect_for` and `wire_model` signatures UNCHANGED.
3. **Provider-block baseUrl carrier for the match rule.** The seams receive the bare entry, which carries the provider KEY but not the block's baseUrl the rule needs. `Models.build_providers` records each typed entry's block baseUrl on an `ObjectSpace::WeakMap` (weak-keyed, dies with the entry); entries that never rode the load path (hand-built test configs) match NOTHING — which keeps every hand-staged hermetic catalog inert by construction (stricter than the frozen rule's letter, and the reason the blast-radius rule never fired).
4. **Per-model baseUrl indexing.** The vendored index is keyed (downcased model baseUrl → id → facts) + (downcased provider name → id → facts) rather than one baseUrl per file, because 8 vendored files (openrouter, fireworks, cloudflare×2, opencode×2, amazon-bedrock, vercel) legitimately carry models under multiple baseUrls; the frozen rule is evaluated per the model's OWN baseUrl. Rule (a) still dominates (b); collisions resolve first-in-sorted-file-order.
5. **reasoning fill semantics.** A loaded typed entry's omitted reasoning is indistinguishable from declared-false (the load normalizes `reasoning == true`), so the reasoning fill rides the slot order literally: entry flag true wins; else the matched vendored reasoning; else today's flag (false) — `model_reasoning_capable` remains reachable only on the no-entry arm, byte-today. Consequence (accepted, unobservable in the suite): a user DECLARING `reasoning: false` on a vendored-reasoning model would be filled to true. The owner's live file declares reasoning true on all four entries — the merge no-op holds.
6. **`name` fill locus.** The loaded catalog is byte-stable, so `name` fills only where construction happens: live entries (name = vendored name or id). Catalog-entry names ride the load's declared-or-id fallback (no seam consumes them).
7. **Listing delivery mechanism.** The frozen `fetch(base_url:, api_key:, timeout: 5) → Array|nil` contract has no non-blocking delivery path, and the threads-budget gate forbids a new Thread.new in chat.rb — so `fetch` gained an OPTIONAL `on_result:` kwarg (callback delivered ON the worker thread; fire-and-forget) while the no-callback form keeps the exact frozen synchronous contract (used by the tests). The Chat merges via the callback under its mutex + `request_draw` (herdr-sender discipline). Additive kwarg on a NEW module — no frozen signature touched.
8. **Open-generation guard.** A landed listing merges only when its menu open is still the latest (`@listing_seq`) — a closed/superseded menu never merges stale rows. Not spelled out in the brief; the natural reading of "merge under the Chat mutex".
9. **Refresh selection clamp.** Copied the existing `edit_query` empty-query rule verbatim (`[@selected, size-1].max`) PLUS an in-range bound (`[...].min`) — needed because a SHRINKING merged list can leave the frozen form out of range, which would crash the `Model Name:` row render. `edit_query` itself untouched.
10. **Live-entry seam registration.** Live entries are registered on the same WeakMap against the provider BLOCK's own baseUrl (not the env-fallback fetch URL) so `entry_max_tokens` at the switch seam re-derives the same vendored match the menu enrichment used.
11. **Two comment greps.** My Rakefile and listing.rb COMMENTS originally contained the literal tokens the frozen gates grep for ("Async::HTTP/URI.open/open-uri"; "Thread.new") — reworded to token-free prose. Behavior unchanged.
12. **Lazy listing require.** `Models::Listing` (and its async-http stack) loads only at the menu-open demand path (`require_relative` inside `spawn_listing_fetch`), keeping boot free of it.

## Disclosures: the 2 RED gates (neither is a lane regression)

**D1 — s9-parity RED: lane-tree wrap geometry, base-inherited (proven).** The frozen command runs the s9_startup_help rig with out dir `t71s9` from the lane tree whose absolute path is 79 chars. The staged-path rows are then 122 chars (pi: tree + `/t71s9` + `/run-1/sandbox/pi/.pi/skills/demo.md` = 79+6+37) and 125 (tart: …`/tart/.tart/skills/demo.md` = 79+6+40) against the frozen 120-column rig width; both wrap, and pi's lone wrapped fragment `-d` is an `unknown-candidate` for the rig's diff classifier → exit 1. Proof of base-inheritance: I extracted base `dd41ae1` via `git archive` (read-only) into a scratch tree of EXACTLY 79 chars (`build/sss…s/wt`, verified) and ran the IDENTICAL frozen command with the pinned oracle — identical RED with identical diff classes (`parity-run-path 6, unknown-candidate 1, staged-path-wrap-fragment 3, footer-provider-prefix 2`) and identical candidates `['-d']`. Scratch tree removed after. The arch's wrap-law formula ("row = tree + outdir + 32, fires > 120") undercounts the real suffix by ~6-8 chars (actual: pi 37, tart 40 after the out dir); at this tree no out-dir length is green (tart's row is ≥121 even with a 1-char dir; and 3-4-char dirs just move the unrecognized fragment). Green needs tree ≤ ~74 chars at `t71s9`. The lane's diff does not touch motd.rb, the rig, or the scenario; the diff classes are purely geometric plus the two standing known classes. **The frozen command as written cannot pass at this lane tree; it needs a re-freeze (shorter out dir from a shorter rehearsal tree, or a wider rig width).**

**D2 — scope RED: frozen-gate/untracked-collapse collision, tree itself clean.** The frozen sweep uses plain `git status --porcelain`, which COLLAPSES the two fully-untracked directories to `lib/tart/models/` and `vendor/`; the frozen whitelist lists only the file forms (`lib/tart/models/vendored.rb`, `lib/tart/models/listing.rb`, `vendor/pi-models/.*`, `vendor/pi-models/`). Evidence captured: the identical sweep under `git status --porcelain -uall` is CLEAN (exit 1 = nothing outside the whitelist), and `git diff --quiet dd41ae1 -- <every frozen must-not-touch path>` passes; all must-differ legs (models.rb, chat.rb, ATTRIBUTION.md, .manifest.json, vendored.rb, listing.rb) pass. The gate needs `-uall` (or intent-to-add entries) to pass in a never-committed lane tree; `git add`/commit is forbidden to this lane, so I could not make the collapsed form disappear.

## Residual risks (named for the human)

1. **The live `/v1/models` against a REAL provider key is statically pinned only** — every pin runs against the hermetic mock; the real z.ai/openrouter endpoints were never fetched (by law — no live keys, no network). The named human checkpoint.
2. **The vendor dir does not ship in the gem package** (`vendor/` is outside the gemspec's file list) — the vendored tier resolves `__dir__`-relative and degrades to provider-absent in an installed gem. From-source daily driver only.
3. **s9-parity re-freeze needed** (D1): the frozen out-dir law cannot pass at this tree length; the judge/spec session should re-freeze with the corrected suffix constants (pi 37 / tart 40, not 32) or run from a ≤74-char tree.
4. **scope gate mechanics** (D2): add `-uall` to the frozen sweep (or accept intent-to-add trees) at re-freeze.
5. **reasoning fill on a declared-false typed entry** (deviation 5): the fill-only law is unenforceable for that one normalized field; the owner's live catalog is unaffected (all entries declare true), but a user pinning `reasoning: false` against a vendored reasoning model would see it flipped to true at the thinking_facts seam.
6. **First seam consultation parses all 42 vendored files once** (~1 MB JSON, cached) — the owner's fully-specified catalog never triggers it (declared values short-circuit); a gap entry pays it once at boot. Unmeasured beyond "suite unchanged"; no timeout risk observed.
7. **The listing fetch-per-open** has no cache/TTL by design (frozen); a user toggling the /model menu rapidly fires one bounded fetch per open against their provider.

## PHASE 0 disagreements with the task spec

Checked before concluding the spec sound: the frozen arch file (Grounds/Specification/AC + the 61-gate block) vs the prompt header vs the actual base tree (all seam files read; the oracle data dir enumerated; the suite floor re-measured). Disagreements found — none blocking, all resolved as itemized deviations above: (a) the "44 provider JSON files" Grounds count vs the actual 42 (deviation 1); (b) the non-existent `dialect_for(entry.compat)` call sites (deviation 2); (c) the wrap-law constant that cannot hold at this tree (disclosure D1 — discovered at gate time, not Phase 0, since it is a rehearsal-tree property); (d) the scope sweep's porcelain collapse (D2, same). No gate command was edited, no arch file touched, nothing committed, nothing pushed, `repos/pi` untouched (oracle-pin-state gate re-verified GREEN post-run).

## Changed files

Tracked (12): `Rakefile`, `bin/tart`, `lib/tart/models.rb`, `lib/tart/render/chat.rb`, `lib/tart/render/model_menu.rb`, `lib/tart/settings.rb`, `test/chat_test.rb`, `test/launcher_smoke_test.rb`, `test/models_test.rb`, `test/render/model_menu_test.rb`, `test/settings_test.rb`, `test/support/mock_llm_server.rb` (+777/−33). Untracked (new): `lib/tart/models/vendored.rb` (146 lines), `lib/tart/models/listing.rb` (110), `test/models_listing_test.rb` (147), `vendor/pi-models/` (42 data JSON + `ATTRIBUTION.md` + `.manifest.json`). Nothing committed; nothing under `repos/` modified; Gemfile/Gemfile.lock/tart.gemspec/bench/rig untouched.

Report also mirrored byte-identically to `build/I71-model-catalogue-core/report.md` per the arch's transcription law.

STATUS: COMPLETE_WITH_CONCERNS (s9-parity RED — base-inherited wrap geometry at this lane tree, proven by a base-at-same-path-length experiment, needs gate re-freeze; scope RED — frozen untracked sweep collides with git's untracked-directory collapse, sweep clean under -uall; live /v1/models against a real provider key remains the named human checkpoint; vendor dir does not ship in the gem package)

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Concise result + residual risks delivered above: suite 1255/6141/0F/0E/1S (base floor 1229 strictly exceeded), SEAM_BENCH_OK, 61/61 frozen gates executed mechanically with a per-gate verdict table, 59 GREEN / 2 RED with decisive base-inheritance and mechanics evidence for each RED, 12-itemized deviation list, 7 residual risks."
    }
  ],
  "changedFiles": [
    "Rakefile",
    "bin/tart",
    "lib/tart/models.rb",
    "lib/tart/models/vendored.rb",
    "lib/tart/models/listing.rb",
    "lib/tart/settings.rb",
    "lib/tart/render/chat.rb",
    "lib/tart/render/model_menu.rb",
    "vendor/pi-models/ATTRIBUTION.md",
    "vendor/pi-models/.manifest.json",
    "vendor/pi-models/*.json (42 files)",
    "test/models_test.rb",
    "test/settings_test.rb",
    "test/models_listing_test.rb",
    "test/chat_test.rb",
    "test/render/model_menu_test.rb",
    "test/launcher_smoke_test.rb",
    "test/support/mock_llm_server.rb"
  ],
  "testsAddedOrUpdated": [
    "test/models_test.rb (/vendored/ x8)",
    "test/settings_test.rb (/vendored/ x1)",
    "test/models_listing_test.rb (NEW x10)",
    "test/chat_test.rb (/live_list/ x4)",
    "test/render/model_menu_test.rb (/refresh/ x2)",
    "test/launcher_smoke_test.rb (/listing_endpoint/ x1)",
    "test/support/mock_llm_server.rb (:models spec type)"
  ],
  "commandsRun": [
    {"command": "bundle exec rake (full suite, lane tree)", "result": "passed", "summary": "1255 runs, 6141 assertions, 0 failures, 0 errors, 1 skips"},
    {"command": "bundle exec ruby bench/seam_bench.rb", "result": "passed", "summary": "SEAM_BENCH_OK"},
    {"command": "61 frozen gates via /tmp/i71-gates/run_gates.rb (extracted verbatim from the arch gates block)", "result": "passed", "summary": "59 GREEN; s9-parity and scope RED with disclosed causes"},
    {"command": "git archive dd41ae1 | tar -x into a 79-char scratch tree; re-ran the frozen s9 command there", "result": "passed", "summary": "identical RED at BASE — proves s9 is base-inherited geometry, not a lane regression (scratch removed)"},
    {"command": "git status --porcelain -uall sweep against the frozen scope whitelist", "result": "passed", "summary": "clean — the scope RED is purely the porcelain directory collapse"},
    {"command": "PI_REPO=<pinned clone> bundle exec rake models:vendor:refresh; PI_REPO=/nope …; default ../pi …", "result": "passed", "summary": "copies 42 files verbatim + regenerates manifest; fails LOUDLY when the clone is missing"}
  ],
  "validationOutput": [
    "1255 runs, 6141 assertions, 0 failures, 0 errors, 1 skips",
    "SEAM_BENCH_OK",
    "VENDORED_ATTRIBUTION_OK 42; VENDORED_UNITS_OK; LISTING_UNITS_OK; MODEL_MENU_LIVE_MERGE_OK; LAUNCHER_LISTING_THREAD_OK; VENDORED_NO_BOOT_NETWORK_OK; LISTING_THREAD_LAW_OK; THREADS_BUDGET_OK; SCOPE: RED (collapse only)",
    "strict_sampling declared move confirmed: max_tokens 16384->131072, reasoning_effort medium->high, dialect stays :zai; its own 8 runs green"
  ],
  "residualRisks": [
    "Live /v1/models against a REAL provider key statically pinned only — the named human checkpoint",
    "vendor/pi-models does not ship in the gem package — from-source daily driver only",
    "s9-parity frozen command cannot pass at this 79-char lane tree (wrap geometry, base-inherited, proven) — needs re-freeze",
    "scope frozen sweep needs -uall (or intent-to-add) in a never-committed lane tree — collapse collision, tree itself clean",
    "reasoning fill flips a user-DECLARED reasoning:false on a vendored-reasoning model (normalization ambiguity, itemized)",
    "first seam consultation parses all 42 vendored files once (cached; never triggered by fully-declared catalogs)",
    "no listing cache/TTL by design — one bounded fetch per menu open"
  ],
  "noStagedFiles": true,
  "diffSummary": "12 tracked files (+777/−33) plus new vendored.rb/listing.rb/models_listing_test.rb and vendor/pi-models/ (42 verbatim oracle data files + ATTRIBUTION.md + tart's own .manifest.json); fill-only fact seams, one gate-pinned background thread, menu merge + refresh + failure row, launcher endpoint threading, additive pins",
  "reviewFindings": [
    "blocker (gate-level, not code): s9-parity frozen command RED at this lane tree — base-inherited wrap geometry, proven by base-at-identical-path-length experiment",
    "blocker (gate-level, not code): scope frozen untracked sweep RED via porcelain directory collapse — clean under -uall",
    "no code blockers found; no frozen pin shifted outside the pre-declared strict_sampling wire dimensions"
  ],
  "manualNotes": "Report mirrored to build/I71-model-catalogue-core/report.md. Oracle pin re-verified (oracle-pin-state GREEN). Nothing committed/pushed; repos/pi untouched; rig untouched. Two mid-run comments were reworded because their prose contained the frozen gates' literal grep tokens (Async::HTTP/URI.open/open-uri in the Rakefile; Thread.new in listing.rb) — behavior unchanged.",
  "notes": ""
}
```

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
