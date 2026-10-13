# I44: dry-rb-shapes

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I44 dry-rb-shapes

Program ENTRY 2 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch). Composes on ENTRY 1 (I43, integrated `0c6ee246`): the
`Tart::Schemas` family, its 5-rule error discipline, and the pinned
dry-schema ~>1.16 + dry-validation ~>1.11 production deps are INHERITED,
never re-litigated. All measurements and probes this session (2026-10-13)
at base **0c6ee246** (`project/pi-port` tip, I43 merged — `git log
--oneline -1` re-run at spec time; working tree clean). Spec-time probes
live in `tmp/i44-probe1/` (gitignored; findings transcribed here).

## 1. Control (this session, base 0c6ee246)

- Suite: `823 runs, 3511 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip — identical to the I43 close-out
  record); `SEAM_BENCH_OK`.
- Deps present in the local ruby (4.0.7, mise): **dry-struct 1.8.1**,
  dry-types 1.9.1 (already transitive via I43's tree), dry-core 1.2.0 —
  `gem list` this session; resolves with no network. Neither is yet in
  tart's `Gemfile.lock` (grep: dry-schema/dry-validation only). Reference
  clones read for this spec: `~/architect/src/github.com/dry-rb/dry-struct`
  (1.8.1 — `lib/dry/struct.rb`, `examples/*.rb`), `dry-types` (1.9.1 —
  `lib/dry/types.rb`, schema/key behavior).

## 2. The consumer inventory (verified this session — the migration's
   work list, `grep -n` over the tree)

- **Model entry hashes** (`{provider:, id:, name:, reasoning:,
  context_window:, max_tokens:, thinking_level_map:}`, built by
  `Models.build_model` models.rb:145-153 then `merge(provider: key)` at
  Config#model_entries :35): consumed at models.rb `resolve` :43-53
  (`entry[:provider]`, `entry[:id]`, `entry[:name]`), bin/tart
  `resolve_boot_entry` :457-458 + `thinking_facts` threading, chat.rb
  `apply_model_selection` :1854-1878 (entry[:id]/[:provider]/
  [:context_window], `@runtime_model = entry`), `boot_model_entry`
  :1893-1899 (footer-facts-built hash), `boot_model_ref` :1928-1930,
  model_menu.rb :77-83 (`entry[:provider]`/`entry[:id]`,
  `entry.merge(value:, label:, …)` UI rows) + `ref_key` :85
  (`ref[:provider]`/`ref[:id]` — also over boot refs), settings.rb
  `thinking_facts` :253-261 (`entry.fetch(:reasoning, false)`,
  `entry[:thinking_level_map]`). commands.rb:184 passes the resolved
  entry through UNINDEXED (`@model&.call(entry)`) — untouched.
- **Provider config hashes** (`{name:, base_url:, api_key:, api:,
  models:}` at `build_providers` models.rb:137-144): `Config#provider`
  :30-33 returns the hash; bin/tart :395 + :513-516 read
  `.fetch(:api_key)`/`.fetch(:base_url)`; models_test :71-72 pin
  `.fetch(:base_url)`/`.fetch(:api_key)`.
- **Boot refs** (`{provider:, id:}` from `resolve_boot_model`
  models.rb:120-136): bin/tart :395, :417-418, :419-420, :430-431,
  :447-448, :513, :521, :554-555 (`boot[:provider]`, `boot[:id]`);
  chat.rb `boot_model_ref` :1928-1930 builds the same two-key shape.
- **Resolved-settings scatter**: bin/tart's `Settings.resolve_setting`
  sites (:396 apiKey, :417-418 defaultProvider/defaultModel legacy
  footer shape, :515-516 apiBase/apiKey in build_chat); chat.rb's
  `Settings::DEFAULTS.fetch("thinkingLevel")` ×3 (:1733, :1768, :1942);
  the known-models tables settings.rb :91-115 (MODEL_CONTEXT_WINDOWS,
  MODEL_REASONING, THINKING_LEVEL_MAPS — plain Hash literals, frozen,
  no shape check).
- **Session entries (READ path)**: string-keyed Hash indexing with guard
  chains — `entry_to_context_message` session.rb:174-187 (type check,
  `message["role"].is_a?(String)`, role `.to_sym`, content nil→""),
  `bash_execution_context_message` :189-211 (8 field reads with
  per-field `is_a?` guards), `compaction_summary_message` :213-220
  (summary String guard), `context_entries` :229-247 (compaction scan on
  `entry["type"]`/`["id"]`/`["firstKeptEntryId"]`), `message_entry_with_role?`
  :277-280, `preview` :330-341, `read_header` :358-368 (type+id String
  guard), chat.rb `resume_session` :584-590 (assistant-text filter +
  compaction count), bin/tart :586 (`read_header(path)&.fetch("id",
  nil)`). The WRITE path (`header`/`message_entry`/`compaction_entry`
  factories :118-138 + Recorder#persist `JSON.generate` :497-503) is the
  byte-frozen surface — I07 pi-parity, byte-pinned below.
- **Struct-ish precedents** (the letter's grounding): ruby_llm's
  `Thinking`/`ToolCall` (value structs inside `Message#to_h`), the port's
  `Identity` (module, not struct), `Compaction::Settings` (a keyword
  `::Struct` with `.resolve` — compaction.rb:18-30, the loop's typed
  seam ALREADY), `Models::Config`/`Settings::Result`/`Diagnostic`
  (keyword `::Struct`s — stay).

## 3. dry-struct API facts verified by probe (tmp/i44-probe1/p1..p5)

- **to_h emits ATTRIBUTE-DECLARATION order** (p1/p5): a Model struct
  declared id, name, reasoning, context_window, max_tokens,
  thinking_level_map, provider yields `to_h` EXACTLY equal to today's
  `build_model(...).merge(provider: key)` hash (p5 asserts equality) —
  key order included. Attribute NAMES are the emitted keys: a
  snake_case attribute emits a snake_case key (p5: a `parent_session`
  attribute ≠ JSON's `parentSession` — why the WRITE path stays hashes).
- **String-keyed input RAISES by default; `transform_keys(&:to_sym)`
  declared in the struct class fixes it** (p1b) — the idiom for structs
  fed parsed JSON (session-entry envelopes).
- Unknown keys are TOLERATED in input (p1b); missing required and
  wrong-typed values raise `Dry::Struct::Error` (p1b — the
  MissingKeyError/SchemaError subclasses both surface as
  `Dry::Struct::Error`). The tolerance wrap idiom `rescue Dry::Struct::Error
  → nil` reproduces today's guard-chain nil-skips EXACTLY (p4: bad type,
  missing role, nil body, non-hash → all nil, no stray raises).
- `attribute?` (optional key) OMITS the attribute from `to_h` when not
  provided (p2/p5 — the parentSession-omission semantics), but an
  EXPLICIT nil still type-checks against the declared type (a
  `Strict::String` optional rejects nil — use `.optional` types where
  nil is legal, p2).
- **Typed constants** (p3): `Types::Strict::Hash.map(K, V)[literal]`
  applies the type and returns the plain Hash (NOT frozen — apply then
  `.freeze`); a bad literal raises `Dry::Types::MapError` at load.
  Nested `Hash.map(Symbol, String | Nil)` works (p3 — the
  THINKING_LEVEL_MAPS shape, sum types inside map keys/values).
- Coercing constructor types work as attributes (p3):
  `Types::Constructor(Strict::Symbol) { |v| v.to_sym }` (role
  symbolization) and a nil→`""` String constructor (content) — the
  entry-coercion table expressible as TYPE declarations.
- Nested `Array.of(Model)` + hash-fed nested construction (p4):
  `Provider.new(models: [{id:, provider:}])` builds Model instances
  directly from hash input.
- dry-struct 1.8.1 depends only on dry-types ~> 1.7 + dry-core ~> 1.0
  (already in I43's transitive tree) — the gemspec addition is
  dry-struct (+ dry-types declared directly: lib requires it).

## 4. Byte-stability goldens captured at base (the frozen pins)

- **Session JSONL** (tmp/i44-probe1/capture_session_bytes.rb — Recorder
  sequence: user/assistant+tool_calls/tool-result/assistant turns, a
  bashExecution record, a compaction entry, then a FORK resume appending
  one turn; volatile values masked: id/parentId/timestamp/parentSession/
  cwd/firstKeptEntryId, then per-line `JSON.generate` digest — pins key
  ORDER, field presence, entry sequence, fork verbatim-copy):
  plain `928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728`
  (roles `[:user, :assistant, :tool, :assistant]`, context-projection
  digest `d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee`),
  compaction-bearing `cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29`,
  forked `3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d`
  (context roles `[:user, :user]` — summary + post-fork prompt),
  compaction context digest `f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029`.
  Deterministic across two runs (verified).
- **Wire request bodies** (rig s1 run TWICE at base): the full rendered
  body is NOT byte-deterministic across runs for ONE reason — the system
  prompt's `<cwd>` embeds the run's sandbox path (the I41-known
  environmental artifact; `walk` diff isolates it as the ONLY
  divergence). With the sandbox path normalized to `<SBX>`, the s1
  single-request body digest is deterministic:
  `2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2`;
  the tools-array digest is I43's pin `7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707`
  (re-verified green at base both runs).
- The replay probe's byte-stability findings (ARCHITECT.md program
  handoff; the probe's scratch lives under tmp/replay-probe/) hold at
  base: request N+1 is a byte-superset of N; resume round-trip
  byte-identical — this iteration must not regress them (the wire-body
  + session-golden gates are the enforcement).

## 5. Test surgery enumeration (the conscious re-pins — every existing
   assertion that indexes the migrated shapes)

- `test/models_test.rb`: :69-70 (entry hash equality → `to_h`
  comparison), :71-72 (`.fetch(:base_url)`/`.fetch(:api_key)` →
  attribute reads), :138-140 (`.fetch(:provider)`/`.fetch(:name)` →
  attribute reads), :157/:162/:166/:172/:175/:180/:186/:192/:197 (boot
  `{provider:, id:}` hash equality → ModelRef `.to_h`/attribute
  assertions), :213 (`entry[:thinking_level_map]`), :219, :349.
- `test/schemas_test.rb`: :69-74 (entry hash equality → `to_h`).
- `test/settings_test.rb`: :335-353 (literal entry hashes → struct
  construction; `facts[:reasoning]`/`facts[:thinking_level_map]` →
  attribute reads; `entry[:id]`).
- `test/session_test.rb`: :175-179 (`projected[:role]`/`[:content]` on
  `entry_to_context_message` output → attribute reads), :191 (`[:content]`).
  The `context_messages`-output pins (:107-108, :160, :319-320, :344)
  stay UNTOUCHED — the output shape is unchanged (Grounds §6).
- `test/chat_test.rb`: :2245-2254 + :2406-2413 (the two
  `Models::Config.new` catalog fixtures — hash-fed providers/models →
  struct-built fixtures). Everything else in these files: additive only.

## 6. The seams that do NOT move (itemized, each with its reason)

- **The gem seam**: `RubyLLM::Chat#add_message` accepts Hash | Message
  and calls `.merge(config:)` on hashes (gem chat.rb:1138-1147) — a
  struct cannot ride it. `Session.context_messages` therefore KEEPS its
  public output shape (Array of `{role:, content:, …}` symbol-keyed
  Hashes; session_test :107/:160 pins, e2e payload proof) — the port
  -internal projection becomes typed, `.to_h` applied at the boundary.
- **The Recorder write path**: the three entry factories + `entry_line`
  + the fork-copy block stay Hash literals — the JSONL bytes are the
  I07 frozen surface (byte-pinned by §4, not re-derived).
- **footer_data** (launcher→render facts hash): stays a Hash — render
  data, not a settings/model shape; boot_model_entry/boot_model_ref READ
  it and build typed shapes from it.
- **Settings' internal hash domain**: `Settings.load`/`read_file`/
  `deep_merge`/`save`/`resolve_*` helpers and `Models.resolve_boot_model`'s
  settings-tier reads keep the merged Hash (the merged file shape is
  byte-pinned by settings_test + the I43 no-filter pin — `Result#settings`
  carries malformed values verbatim). The helpers' public signatures are
  unchanged.
- **Compaction::Settings** (compaction.rb:18-30): already a typed
  `::Struct` seam consumed by the loop — untouched.

## 7. Open questions (itemized for the judge; resolved by plan letter in
   the Specification — none blocking)

- **OQ-1 (the gem seam).** `context_messages` maps structs back to
  Hashes at the add_message boundary (the port cannot re-type the gem's
  API). Specification ruling: typed port-side, `.to_h` at the boundary,
  the Hash output shape pinned unchanged. Judge may re-rule (e.g. demand
  port-side `RubyLLM::Message` construction — rejected here: it moves
  the Message round-trip into port code with wire-byte risk).
- **OQ-2 (ResolvedSettings' honest typing).** pi flows-through malformed
  settings values (settings-manager.ts:126, the I43 no-filter pin), so a
  strict struct over file-sourced scalars would RAISE where today the
  value lands verbatim. Specification ruling: strict types ONLY where
  resolution guarantees the type (identity String, thinking_level
  vocab String, context_window Integer|nil via the file-tier contract,
  default_tools Array); file-sourced scalars ride `Types::Nominal::Any`
  (documented flows-through view). Judge may re-rule.
- **OQ-3 (test re-pins).** The §5 surgery is mechanical accessor/to_h
  re-pinning, semantics-neutral by enumeration; the byte goldens (§4)
  are frozen gate literals captured at base. Judge verifies
  semantics-neutrality on the diff.
- **OQ-4 (boot entry completeness).** The footer-facts-built boot entry
  gains an explicit `max_tokens: nil` (struct completeness) — its hash
  shape is unpinned (menu rows read name/provider/id only). Itemized.
- **OQ-5 (read_header's return type).** `Agent::Session.read_header`
  moves Hash → `Shapes::SessionHeader` (public API) — consumers
  enumerated (§2: find_most_recent/list internals, bin/tart:586); no
  test pins the hash shape. Intended API move, itemized.

## Specification

# Specification — I44 dry-rb-shapes

## Objective

Program ENTRY 2 (`build/loop/plan-20261013T092136Z.md`): dry-types/dry-struct
for tart's internal shapes — typed structs replace the hash-table masses at
the Model catalog, the resolved-settings reads, and the session-entry load
path. Composes on ENTRY 1 (I43): the `Tart::Schemas` family and its 5-rule
error discipline are inherited unchanged; this iteration adds the VALUE side
(structs), not new validation. Parity track: internal only — ZERO observable
byte moves on screen or wire. HARD constraint (the letter): session-file
bytes and wire bytes do not move — the JSONL format is pi-parity I07 and the
replay probe proved byte-stability; the Grounds §4 goldens are frozen gate
literals. Known-models tables become typed constants. Consumers read the
structs; no hash-shape aliasing is left behind at the migrated seams
(enumerated in Grounds §2; the seams that do NOT move are Grounds §6).

## The shape contract (composes on I43's pattern contract)

- **Home + naming.** One module family: `lib/tart/shapes.rb` (aggregate
  require, house style of `lib/tart/schemas.rb`) +
  `lib/tart/shapes/{types,model,settings,session}.rb`, namespace
  `Tart::Shapes`. `shapes/types.rb` defines `Tart::Shapes::Types`
  (`include Dry::Types()`), the one shared Types module — member files
  `require_relative "types"` and reference `Shapes::Types::…`. `lib/tart.rb`
  gains `require_relative "tart/shapes"`. Consumers require their own
  shapes member directly (the existing require discipline).
- **Structs are `Dry::Struct` subclasses**, one class per shape, attribute
  names snake_case (the Ruby-facing vocabulary), `Types` from
  `Shapes::Types`. Structs fed parsed-JSON input declare
  `transform_keys(&:to_sym)` (Grounds §3). No schema re-validation rides
  struct construction (shape typing ≠ boundary validation — I43 rule 1).
- **Error discipline (I43's rules, applied to values).** Structs never
  construct where today's code does not branch: the session-entry
  envelopes' tolerant wrap (`rescue Dry::Struct::Error → nil`) reproduces
  today's guard-chain nil-skips EXACTLY (Grounds §3 p4); NO new raise
  reaches a user surface. The known-table type literals raise
  `MapError` at LOAD time only (compile-time constants).
- **Byte rule.** No struct's `to_h` output crosses a byte-frozen surface
  (Grounds §6): the write path stays hashes; the gem seam gets `.to_h`.
  `Shapes::Model#to_h`'s key order is DECLARED to equal today's
  `build_model.merge(provider:)` hash (Grounds §3, p5-verified) — pinned
  by unit test.
- **No filtering, no coercion beyond today.** Where a struct types a
  flows-through value, it uses `Types::Nominal::Any` (documented);
  coercing types appear ONLY where today's code already coerces (role
  `.to_sym`, content nil→`""` — the entry-coercion table as types).

## B1 — the Model family (lib/tart/shapes/model.rb + models.rb + consumers)

- `Shapes::Model` — attributes IN ORDER: `id`, `name`
  (`Strict::String`), `reasoning` (`Strict::Bool`), `context_window`,
  `max_tokens` (`Strict::Integer.optional`), `thinking_level_map`
  (`Strict::Hash.map(Strict::Symbol, Strict::String | Strict::Nil).optional`),
  `provider` (`Strict::String`). `to_h` == today's entry hash, key order
  included (unit-pinned). `thinking_level_map` values are the
  symbolized Partial-Record shape (I36 semantics ride unchanged).
- `Shapes::Provider` — `name`, `base_url`, `api_key`, `api`
  (`Strict::String.optional` — today's parse may omit them), `models`
  (`Strict::Array.of(Model)`).
- `Shapes::ModelRef` — `provider`, `id` (`Strict::String`).
- `Shapes::ThinkingFacts` — `reasoning` (`Strict::Bool`), `thinking_level_map`
  (the map type above).
- `Models.build_providers`/`build_model` construct the structs (the
  provider key feeds `Model#provider` at build); `Config` keeps its
  `::Struct` shell with `providers` now `Hash[String => Shapes::Provider]`;
  `Config#model_entries` → `Array[Shapes::Model]` (flat_map over
  `provider.models` — no merge); `Config#resolve` → `Shapes::Model|nil`
  with today's exact match table (canonical/scoped/bare, ambiguity =
  no match); `Config#provider(key)` → `Shapes::Provider|nil`.
- `Models.resolve_boot_model` returns `Shapes::ModelRef` (same precedence
  table; the settings-tier reads keep the merged Hash — Grounds §6).
  `Settings.thinking_facts` returns `Shapes::ThinkingFacts` (same
  catalog-entry-first/known-tables-second table).
- **Consumers** (Grounds §2's work list, ALL migrated): bin/tart
  (`boot.provider`/`boot.id`; `provider&.api_key`/`&.base_url`;
  `facts.reasoning`/`facts.thinking_level_map`), chat.rb
  (`apply_model_selection` reads `entry.id`/`.provider`/`.context_window`;
  `@runtime_model` holds the struct; `boot_model_entry` builds a
  `Shapes::Model` (the `max_tokens: nil` completeness note — Grounds OQ-4);
  `boot_model_ref` builds a `Shapes::ModelRef`), model_menu.rb
  (`model()` builds UI-row hashes FROM the struct — `{value:, label:,
  provider:, id:, name:, current:, default:}` rows stay plain Hashes
  (render rows); `ref_key` reads `.provider`/`.id` — Model and ModelRef
  both respond). commands.rb passes entries through unindexed —
  untouched.

## B2 — resolved settings + typed tables (lib/tart/shapes/settings.rb +
settings.rb + consumers)

- `Shapes::ResolvedSettings` — the typed view of the RESOLVED settings,
  built ONCE per boot by `.from_load(settings_or_result, identity:,
  env: ENV)` which runs today's exact resolution arithmetic per key
  (env tier via `Identity.env_key`, then the merged file hash, then
  DEFAULTS — the `resolve_setting` table; thinking level via
  `resolve_thinking_level`; the file-tier context window via
  `Schemas::Settings.context_window_value`; tools via
  `selected_tools`; compaction via the `compaction_kwargs` key set):
  - strict where resolution guarantees the type: `identity`
    (`Strict::String` — Identity.resolve validates), `thinking_level`
    (`Strict::String` — the vocab-resolved value or "medium"),
    `context_window` (`Strict::Integer.optional` — the file-tier
    contract output), `default_tools` (`Strict::Array`).
  - `Types::Nominal::Any` where pi flows-through (documented in the
    class): `default_model`, `default_provider`, `api_base`, `api_key`
    (raw staged values ride verbatim — Grounds OQ-2).
  - `compaction` → `Shapes::CompactionSettings` (`attribute?` for
    `enabled`/`reserve_tokens`/`keep_recent_tokens`, nominal values —
    the present-keys slice `compaction_kwargs` produces today).
- Consumed at the launcher's scattered sites (Grounds §2): print +
  interactive construct it once after identity resolution;
  `require_api_key`'s settings tier, `footer_data`'s legacy boot shape +
  level, `build_chat`'s api tiers read struct attributes. chat.rb's
  three `DEFAULTS.fetch("thinkingLevel")` sites (:1733, :1768, :1942)
  AND print.rb's fourth (:65 — `Print.run`'s default-level fallback)
  read the typed constant (the same migration class; print.rb's touch
  is that one line). The Settings helpers' public signatures stay
  (they remain the Settings domain's API; the struct is the consumer
  view).
- **Typed constants** in settings.rb via `Shapes::Types` map types
  applied at load, then `.freeze`: `MODEL_CONTEXT_WINDOWS`
  (`Hash.map(Strict::String, Strict::Integer)`), `MODEL_REASONING`
  (`Hash.map(Strict::String, Strict::Bool)`), `THINKING_LEVEL_MAPS`
  (`Hash.map(Strict::String, Hash.map(Strict::Symbol, Strict::String |
  Strict::Nil))`) — CONTENT byte-identical (values compared key-for-key
  in unit pins); a malformed literal fails at load (MapError). New
  `DEFAULT_THINKING_LEVEL = "medium"` (`Strict::String` literal) becomes
  the single source of `DEFAULTS["thinkingLevel"]`; chat.rb's three
  `DEFAULTS.fetch("thinkingLevel")` sites (:1733, :1768, :1942) read the
  constant. `DEFAULTS` itself (the merged-file tier source, byte-pinned
  by settings_test) stays a frozen Hash.

## B3 — session-entry typed views, READ path only
(shapes/session.rb + agent/session.rb + chat.rb resume block)

- `Shapes::MessageEntry` — `transform_keys(&:to_sym)`; `type`
  (`Strict::String.enum("message")`), `role` (`Strict::String` — read
  from `message["role"]`), `message` (`Strict::Hash` — the open
  recorded-message body). Class method `.of(raw)` = constructor inside
  `rescue Dry::Struct::Error → nil` (the tolerance idiom) — a non-Hash,
  wrong-typed, role-less, or body-less entry reads nil, exactly today's
  guard outcomes (unit-pinned against the §2 read sites' inputs).
- `Shapes::CompactionEntry` — `type` (`enum("compaction")`), `id`,
  `first_kept_entry_id` (`Nominal::Any` — the scan's raw reads; strict
  typing would change malformed-entry outcomes, Grounds §2), `summary`
  (`Nominal::Any` — the projection's own String guard stays).
  `.of(raw)` as above.
- `Shapes::SessionHeader` — `type` (`enum("session")`), `id`
  (`Strict::String`), `cwd` (`Nominal::Any` — `cwd_matches?` guards),
  `version`/`timestamp`/`parentSession` (`attribute?`, nominal).
  `Session.read_header` returns it (or nil) — the Grounds OQ-5 API move;
  `find_most_recent`/`list` pass `header.cwd` into the unchanged
  `cwd_matches?`; bin/tart reads `.id`.
- `Shapes::ContextMessage` — `role`
  (`Types::Constructor(Strict::Symbol) { _1.to_sym }`), `content`
  (nil→`""` String constructor) — the projection OUTPUT. The three
  projection functions (`entry_to_context_message`,
  `bash_execution_context_message`, `compaction_summary_message`)
  consume the envelope wraps and return `Shapes::ContextMessage` (the
  bash record's per-field `is_a?` guards stay verbatim inside the
  projection — its field reads go through the envelope's `message`
  hash, unchanged tolerance table); `context_messages` applies `.to_h`
  at the gem seam (output shape unchanged — Grounds §6, unit-pinned).
  `message_entry_with_role?` and `preview` ride the MessageEntry wrap;
  `context_entries`' compaction scan rides the CompactionEntry wrap
  (kept-entry matching semantics unchanged); chat.rb's `resume_session`
  block reads the wraps (assistant-text filter + compaction count).
- The Recorder write path, the three entry factories, and
  `Recorder#context_entries`' deep-copy stay Hash literals (Grounds
  §6) — the JSONL bytes are the frozen surface, byte-pinned by the
  Grounds §4 goldens.

## Dependency changes

`tart.gemspec` gains `spec.add_dependency "dry-struct", "~> 1.8"` and
`spec.add_dependency "dry-types", "~> 1.9"` (production deps — lib
requires them at boot; dry-types is declared directly because shapes
files require it, even though I43's tree already carries it
transitively). No other gemspec change; `Gemfile.lock` regenerates and
is committed. No path/git vendoring; no `required_ruby_version` change.

## New unit pins (test/shapes_test.rb + the re-pinned sites)

- **Construction + coercion failures** (the letter's pin set): every
  struct constructs from its feeding input (Model from a catalog-hash
  fixture, Provider with nested models, ModelRef, ThinkingFacts,
  ResolvedSettings from a merged-hash fixture per precedence row,
  ContextMessage role/content coercions, envelopes from JSON-string-keyed
  lines); wrong-typed input raises `Dry::Struct::Error` (Model id:5,
  reasoning:"true"; envelope type:"usage"; header id:nil); the
  `.of(raw)` tolerance table (nil outcomes for every malformed class
  today's guards skip — the null-content, role-less, non-Hash,
  wrong-type rows).
- **`Shapes::Model#to_h` byte-shape pin**: key order + values == the
  Grounds §3 merged-hash shape, including `thinking_level_map`
  symbolization and the provider-last order.
- **Catalog equivalence**: `Models.load` on the models_test CATALOG
  fixture yields `model_entries.map(&:to_h)` == today's entry hashes
  (line-for-line); `Config#resolve`'s match table re-pinned through
  attribute reads; `resolve_boot_model` → ModelRef `.to_h` rows (env /
  catalog-default / settings tiers, both identity namespaces).
- **ResolvedSettings outcome table**: per key, env-only / file-only /
  default-only / env+file / all / none (the I43 precedence matrix's
  keys), asserting each attribute equals today's `resolve_setting`
  output for the same fixture — including the malformed flows-through
  rows (`"contextWindow": "abc"` lands verbatim in the nominal
  attributes; no raise, no filter).
- **Typed-constant pins**: the three tables' contents compared
  key-for-key with today's literals; `DEFAULT_THINKING_LEVEL ==
  Settings::DEFAULTS.fetch("thinkingLevel")`; a doctored bad literal
  raises `Dry::Types::MapError` (a load-time check demonstrated in-test
  via `Types[...]` application on a bad literal).
- **Session projection pins** (additive in session_test): the wrap
  tolerance rows; `context_messages` output == today's Hash shape (the
  :107/:160 pins stay green untouched); the read_header struct's
  fields.

## Tool guidance (verify against live deps before writing code)

- Read the installed versions' sources first: reference clones at
  `~/architect/src/github.com/dry-rb/{dry-struct,dry-types}` (1.8.1 /
  1.9.1). Probed idioms that work on this exact stack (Grounds §3):
  `attribute`/`attribute?`; `transform_keys(&:to_sym)`;
  `Types::Strict::…`; `.optional`; sum types inside `Hash.map`;
  `Types::Constructor(type) { … }`; `Strict::Array.of(Model)`; the
  `rescue Dry::Struct::Error → nil` wrap idiom; `Types[...]`
  application on literals (MapError on mismatch, apply-then-freeze).
  Do NOT invent: `Dry.Struct` old macros, `schema.strict` input
  processors, per-call type redefinition.
- Verification (exact, per repo): `bundle install --quiet && bundle
  exec rake` (suite), `bundle exec ruby bench/seam_bench.rb`
  (SEAM_BENCH_OK), `gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/<s>.yml --out tmp/<canonical-short-dir>`
  for s1–s10 + the two `--gate` probes (cold; s1_tart exits 1 by
  design). The byte gates below are the freeze-time literals — if one
  fails, a byte moved: STOP and report, never adjust the literal.
- Comment phrasing: the no-aliasing gates grep source text — phrase
  comments to avoid the literal patterns (write "the boot ref", never
  `boot[`).

## Boundaries

**May touch** (the ```lanes block is the frozen source of truth):
`tart.gemspec`, `Gemfile.lock`, `lib/tart.rb`, `lib/tart/shapes.rb`,
`lib/tart/shapes/{types,model,settings,session}.rb` (new),
`lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/agent/session.rb`,
`lib/tart/render/chat.rb`, `lib/tart/render/model_menu.rb`,
`lib/tart/print.rb` (the :65 constant-read line ONLY), `bin/tart`,
`test/shapes_test.rb` (new), `test/{models,schemas,settings,session,
chat}_test.rb` (the Grounds §5 enumerated re-pins + additive pins only).

**Must not touch**: everything else, in particular — `lib/tart/schemas*
` (ENTRY 1's family, inherited verbatim), `lib/tart/tools/**`,
`lib/tart/mcp/**`, `lib/tart/agent/{loop,bridge,status,context_files,
system_prompt}.rb`, `lib/tart/compaction.rb`,
`lib/tart/commands.rb` (pass-through consumer — zero reads to migrate),
`lib/tart/identity.rb`, `lib/tart/skills.rb`, `lib/tart/prompts.rb`,
`lib/tart/theme.rb`, `lib/tart/tui.rb`, `lib/tart/core/**`,
`lib/tart/render/**` except `chat.rb`+`model_menu.rb`, `bench/**`,
`gems/tui-split-rig/**`; the frozen test files (`golden_parity_test.rb`,
`e2e_session_test.rb`, `launcher_smoke_test.rb`, `agent_loop_test.rb`,
`loop_test.rb`, `print_test.rb`, `tools_test.rb`, `bash_tool_test.rb`,
`mcp_test.rb`, `commands_test.rb`, `skills_test.rb`, `identity_test.rb`,
`theme_test.rb`, `tui_test.rb`, `markdown_test.rb`, `prompts_test.rb`,
`system_prompt_test.rb`, `compaction_test.rb`,
`kernel_carryin_test.rb`), `test/render/**`, `test/support/**`,
`test/fixtures/**`.

**Out of scope** (itemized, not lost): the gem seam (add_message Hash |
Message boundary — Grounds OQ-1); the Recorder write path + entry
factories (byte-frozen); footer_data (render facts); the render-side
session replay reads (transcript.rb :305/:594 `entry["message"]` —
the render family is the byte-critical parity surface; the shapes
family covers the AGENT-side load/resume path); Compaction::
Settings + the loop's compaction seam; Agent::Loop/MCP-client
dry-monads (ENTRY 3); the settings helpers' internal hash domain;
pi Value.Convert tool-arg coercion and the bash >2147483.647s tier
(I43 residuals); `Models::Schemas` behavior; any new validation, any
new diagnostics, any settings value filtering.

## Lane plan

ONE lane (single-writer — Model and Settings consumers share chat.rb/
bin/tart; parallel lanes would collide on the same files):

- **shapes** — target `repos/tart`, the full touch set above, the whole
  objective. Effort: HIGH at dispatch (3 deliverable families, ~13
  consumer files, deps, the byte-pin discipline).

```lanes
- name: shapes
  repo: tart
  touch:
    - tart.gemspec
    - Gemfile.lock
    - lib/tart.rb
    - lib/tart/shapes.rb
    - lib/tart/shapes/types.rb
    - lib/tart/shapes/model.rb
    - lib/tart/shapes/settings.rb
    - lib/tart/shapes/session.rb
    - lib/tart/models.rb
    - lib/tart/settings.rb
    - lib/tart/agent/session.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/model_menu.rb
    - lib/tart/print.rb
    - bin/tart
    - test/shapes_test.rb
    - test/models_test.rb
    - test/schemas_test.rb
    - test/settings_test.rb
    - test/session_test.rb
    - test/chat_test.rb
```

## Acceptance Criteria

# Acceptance Criteria — I44 dry-rb-shapes

Gate calibration (pre-declared): **RED at base BY DESIGN** —
`deps-shapes`, `shapes-presence`, `no-aliasing` (the dry-struct/dry-types
deps, the `Tart::Shapes` family, and the migrated accessor surface do not
exist at 0c6ee246); they must be GREEN on the integrated tree,
non-vacuously. **Regression guards (GREEN at base, must stay GREEN)** —
`suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, both probe gates,
`wire-bodies`, `session-golden` (the two byte-pin gates were captured at
base this session — Grounds §4 — and verified deterministic across two
base runs; a post-build failure means a byte moved). The s-gates keep the
CANONICAL short out dirs (I41 Grounds 1's environmental note). The KNOWN
s9 lane-worktree deep-path artifact (I34/I36/I39/I40/I42/I43 precedent)
does not fail this iteration when the same tree exits 0 at canonical
depth — the judge runs the battery on the integrated tree.

**AC1 (the shapes family lands).** `Tart::Shapes` exists at the specified
home (`lib/tart/shapes.rb` + `shapes/{types,model,settings,session}.rb`)
with the specified classes (`Model`, `Provider`, `ModelRef`,
`ThinkingFacts`, `ResolvedSettings`, `CompactionSettings`,
`MessageEntry`, `CompactionEntry`, `SessionHeader`, `ContextMessage`);
`tart.gemspec` declares `dry-struct ~> 1.8` + `dry-types ~> 1.9` as
PRODUCTION deps and `Gemfile.lock` carries them. The shape contract
(naming, transform_keys for JSON-fed structs, the tolerance wrap idiom,
nominal-for-flows-through, byte rule) is followed. Pinned by
`deps-shapes` + `shapes-presence` + judge read of the diff.

**AC2 (Model-family equivalence).** `Models.load`'s valid-path outputs
are `to_h`-equal to today's entry hashes (key order included — the
`to_h` shape pin); `Config#model_entries`/`#resolve`/`#provider` return
the typed shapes with today's exact match tables;
`resolve_boot_model` → `ModelRef` (same precedence table);
`Settings.thinking_facts` → `ThinkingFacts` (same catalog-first/
known-tables-second outcomes); every Grounds §2 Model-family consumer
(bin/tart, chat.rb's model family, model_menu.rb) reads struct
attributes — no `[:provider]`/`[:id]`-style entry indexing at the
migrated seams; the Grounds §5 re-pins land (mechanical, enumerated).
Pinned by `no-aliasing` + the new unit pins + the existing pins green.

**AC3 (resolved settings + typed tables).** `ResolvedSettings.from_load`
reproduces today's resolution outcome table per key (env > file >
DEFAULTS incl. every malformed flows-through row — nominal attributes
carry raw values verbatim, no raise, no filter); it is consumed at the
launcher's Grounds §2 sites; the three known-models tables are
type-checked constants with contents byte-identical to today's literals;
`DEFAULT_THINKING_LEVEL` single-sources the default and chat.rb's three
`DEFAULTS.fetch("thinkingLevel")` sites plus print.rb's fourth (:65)
read it; `Result#settings`'
merged-hash shape and the I43 no-filter pin are untouched. Pinned by
the new unit pins + `no-aliasing` + the existing settings/schemas pins
green (the I43 precedence matrix untouched).

**AC4 (session entries typed, bytes frozen).** The read path
(`entry_to_context_message` family, `message_entry_with_role?`,
`context_entries`' scan, `preview`, `read_header`, chat.rb's resume
block) consumes the envelope wraps with today's EXACT tolerance table
(every malformed class projects nil; null content → ""; the bash
per-field guards verbatim); `context_messages`' output Hash shape is
unchanged (`.to_h` at the gem seam — the untouched session_test/
e2e_session pins prove it); the write path (factories, Recorder#persist,
fork copy) is Hash-literal-untouched. The byte goldens hold: session
JSONL digests (plain/compaction/fork/context) and the wire request-body
digest identical to the Grounds §4 literals. Pinned by `session-golden`
+ `wire-bodies` + session_test/e2e_session green UNTOUCHED at their
un-re-pinned lines.

**AC5 (parity + regression + scope).** The default rake task fully green
(run count > 823 with the new pins); `SEAM_BENCH_OK`; s1–s10 exit 0
cold at the canonical out dirs; `s1-tart-mode` completes (TART_MODE_OK);
both probe gates OK (TOOL_PENDING_GATE_OK, USER_BASH_STREAM_GATE_OK);
the integrated diff vs **0c6ee246** touches EXACTLY the lane's declared
file set — no schemas file, no tools/mcp/agent file, no frozen test
file, no rig file.

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

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
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

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i44-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i44-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i44-wire && gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i44-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i44-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i44-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i44-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: deps-shapes
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'dry-struct' tart.gemspec && grep -q 'dry-types' tart.gemspec && grep -q 'dry-struct' Gemfile.lock && grep -q 'dry-types' Gemfile.lock && bundle install --quiet && bundle exec ruby -e 'require "dry-struct"; require "dry-types"; puts "DEPS_SHAPES_OK"'
  expect:
    exit_code: 0
    stdout_match: DEPS_SHAPES_OK

- id: shapes-presence
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; need = %w[Model Provider ModelRef ThinkingFacts ResolvedSettings CompactionSettings MessageEntry CompactionEntry SessionHeader ContextMessage]; missing = need.reject { |c| Tart::Shapes.const_defined?(c, false) }; abort "Tart::Shapes missing: #{missing.inspect}" unless missing.empty? && defined?(Tart::Shapes::Types); abort "test/shapes_test.rb missing" unless File.file?("test/shapes_test.rb"); puts "SHAPES_OK"'
  expect:
    exit_code: 0
    stdout_match: SHAPES_OK

- id: no-aliasing
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if grep -q 'boot\[' bin/tart; then echo "FAIL boot ref indexing in bin/tart"; exit 1; fi; if grep -qnE 'entry\[:' lib/tart/render/chat.rb lib/tart/render/model_menu.rb lib/tart/settings.rb; then echo "FAIL entry hash indexing at migrated seams"; exit 1; fi; if grep -qnE 'fetch\(:api_key|fetch\(:base_url' bin/tart; then echo "FAIL provider config hash indexing in bin/tart"; exit 1; fi; if grep -qn 'DEFAULTS.fetch("thinkingLevel")' lib/tart/render/chat.rb lib/tart/print.rb; then echo "FAIL DEFAULTS hash read in chat.rb/print.rb"; exit 1; fi; if grep -q 'provider.fetch(:models)' lib/tart/models.rb; then echo "FAIL models hash indexing in models.rb"; exit 1; fi; if grep -qnE 'entry\.fetch\(:reasoning|entry\[:thinking_level_map\]' lib/tart/settings.rb; then echo "FAIL thinking_facts hash indexing"; exit 1; fi; if grep -qnE '\["message"\]' lib/tart/agent/session.rb lib/tart/render/chat.rb; then echo "FAIL session envelope hash indexing"; exit 1; fi; if grep -qnE 'facts\[:' bin/tart lib/tart/render/chat.rb; then echo "FAIL thinking_facts hash indexing at consumers"; exit 1; fi; echo NO_ALIASING_OK
  expect:
    exit_code: 0
    stdout_match: NO_ALIASING_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 0c6ee246 HEAD | grep -qvE '^(tart\.gemspec|Gemfile\.lock|lib/tart\.rb|lib/tart/shapes\.rb|lib/tart/shapes/types\.rb|lib/tart/shapes/model\.rb|lib/tart/shapes/settings\.rb|lib/tart/shapes/session\.rb|lib/tart/models\.rb|lib/tart/settings\.rb|lib/tart/agent/session\.rb|lib/tart/render/chat\.rb|lib/tart/render/model_menu\.rb|lib/tart/print\.rb|bin/tart|test/shapes_test\.rb|test/models_test\.rb|test/schemas_test\.rb|test/settings_test\.rb|test/session_test\.rb|test/chat_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### shapes

# Lane prompt — I44 dry-rb-shapes, lane `shapes` (sole lane)

You are the builder for LANE `shapes` of iteration I44 dry-rb-shapes
(space 20261009-pi-port, repo repos/tart, branch worktree provisioned from
frozen base 0c6ee246). This prompt is your complete, self-contained contract.
You never commit; you write code + tests in your worktree and a scratch
report at build/I44-dry-rb-shapes-shapes/report.md. PHASE 0 discipline
applies: disagreements with this contract are RESEARCHED (you may read
~/architect/src/github.com/dry-rb/* reference clones — dry-struct 1.8.1,
dry-types 1.9.1) and ITEMIZED in your report's PHASE 0 section — never
silently implemented differently, never silently blocking. If a frozen
byte-gate literal fails, a byte moved: STOP and report, never adjust the
literal.

Your may-touch set (EXACTLY these files, nothing else):

    tart.gemspec
    Gemfile.lock
    lib/tart.rb
    lib/tart/shapes.rb            (new)
    lib/tart/shapes/types.rb      (new)
    lib/tart/shapes/model.rb      (new)
    lib/tart/shapes/settings.rb   (new)
    lib/tart/shapes/session.rb    (new)
    lib/tart/models.rb
    lib/tart/settings.rb
    lib/tart/agent/session.rb
    lib/tart/render/chat.rb
    lib/tart/render/model_menu.rb
    lib/tart/print.rb             (the :65 DEFAULTS-read line ONLY)
    bin/tart
    test/shapes_test.rb           (new)
    test/models_test.rb           (the Grounds §5 enumerated re-pins + additive)
    test/schemas_test.rb          (the Grounds §5 enumerated re-pins + additive)
    test/settings_test.rb         (the Grounds §5 enumerated re-pins + additive)
    test/session_test.rb          (the Grounds §5 enumerated re-pins + additive)
    test/chat_test.rb             (the two Models::Config fixtures at
                                   :2245/:2406 + additive)

Must-not (binding): lib/tart/schemas* (ENTRY 1's family) untouched;
lib/tart/tools/**, lib/tart/mcp/**, lib/tart/agent/{loop,bridge,status,
context_files,system_prompt}.rb, lib/tart/compaction.rb,
lib/tart/commands.rb, lib/tart/identity.rb, lib/tart/skills.rb,
lib/tart/prompts.rb, lib/tart/theme.rb, lib/tart/tui.rb, lib/tart/core/**,
lib/tart/render/** except chat.rb + model_menu.rb, bench/**,
gems/tui-split-rig/** untouched; the frozen test files (golden_parity,
e2e_session, launcher_smoke, agent_loop, loop, print, tools, bash_tool,
mcp, commands, skills, identity, theme, tui, markdown, prompts,
system_prompt, compaction, kernel_carryin), test/render/**,
test/support/**, test/fixtures/** untouched; the session-JSONL write path
(entry factories + Recorder#persist + fork copy) stays Hash literals;
no new validation, no new diagnostics, no settings value filtering; no
re-validation riding struct construction.

─ ENTRY 2 of the program plan (verbatim from
  build/loop/plan-20261013T092136Z.md) ────────────────────────────────

ITERATION: dry-rb-shapes

dry-types/dry-struct for tart's internal shapes — typed structs replace
hash-table masses. Runs second so it composes on ENTRY 1's schemas.

Grounding:
- session.rb: entry coercion on load/resume (Message.new round-trip, tool
  call coercion; the JSONL format is pi-parity I07 — serialization bytes are
  FROZEN).
- models.rb: Model/thinking-map hashes; settings.rb: resolved-settings
  Hash access scattered through chat.rb/bin/tart.
- Existing struct-ish precedents: Thinking, ToolCall (gem); the port's
  Identity.

Shape: dry-struct classes for Model, resolved Settings (and its nested
tables), and the internal view of session entries where it cleans — with the
HARD constraint that session-file bytes and wire bytes do not move (to_h
output byte-pinned by existing tests; the replay probe proved byte-stability
— do not regress it). Known-models tables become typed constants. Consume
via the structs at read sites; no hash-shape aliasing left behind at the
migrated seams.

Gates: suite + bench + s1–s10 + probes cold unchanged; byte-pins: session
JSONL round-trip identical, rendered request bodies identical (MockLLM
captured-body pins); new struct unit pins (construction, coercion failures).

Coordinator standing rules (binding): you run under zai/glm-5.3-flash
thinking-high; never commit; scratch under tmp/ and build/ in the SPACE
repo, never inside repos/tart's tracked tree. The parity battery gates this
iteration: bundle exec rake, bundle exec ruby bench/seam_bench.rb
(SEAM_BENCH_OK), rig s1–s10 + probes exit 0 cold (s1_tart exit 1 by design)
— ZERO observable byte moves on screen or wire.

─ The frozen Grounds (verbatim from architecture/I44-dry-rb-shapes.md,
  freeze 55ca77a) ──────────────────────────────────────────────────────
# Grounds — I44 dry-rb-shapes

Program ENTRY 2 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch). Composes on ENTRY 1 (I43, integrated `0c6ee246`): the
`Tart::Schemas` family, its 5-rule error discipline, and the pinned
dry-schema ~>1.16 + dry-validation ~>1.11 production deps are INHERITED,
never re-litigated. All measurements and probes this session (2026-10-13)
at base **0c6ee246** (`project/pi-port` tip, I43 merged — `git log
--oneline -1` re-run at spec time; working tree clean). Spec-time probes
live in `tmp/i44-probe1/` (gitignored; findings transcribed here).

## 1. Control (this session, base 0c6ee246)

- Suite: `823 runs, 3511 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip — identical to the I43 close-out
  record); `SEAM_BENCH_OK`.
- Deps present in the local ruby (4.0.7, mise): **dry-struct 1.8.1**,
  dry-types 1.9.1 (already transitive via I43's tree), dry-core 1.2.0 —
  `gem list` this session; resolves with no network. Neither is yet in
  tart's `Gemfile.lock` (grep: dry-schema/dry-validation only). Reference
  clones read for this spec: `~/architect/src/github.com/dry-rb/dry-struct`
  (1.8.1 — `lib/dry/struct.rb`, `examples/*.rb`), `dry-types` (1.9.1 —
  `lib/dry/types.rb`, schema/key behavior).

## 2. The consumer inventory (verified this session — the migration's
   work list, `grep -n` over the tree)

- **Model entry hashes** (`{provider:, id:, name:, reasoning:,
  context_window:, max_tokens:, thinking_level_map:}`, built by
  `Models.build_model` models.rb:145-153 then `merge(provider: key)` at
  Config#model_entries :35): consumed at models.rb `resolve` :43-53
  (`entry[:provider]`, `entry[:id]`, `entry[:name]`), bin/tart
  `resolve_boot_entry` :457-458 + `thinking_facts` threading, chat.rb
  `apply_model_selection` :1854-1878 (entry[:id]/[:provider]/
  [:context_window], `@runtime_model = entry`), `boot_model_entry`
  :1893-1899 (footer-facts-built hash), `boot_model_ref` :1928-1930,
  model_menu.rb :77-83 (`entry[:provider]`/`entry[:id]`,
  `entry.merge(value:, label:, …)` UI rows) + `ref_key` :85
  (`ref[:provider]`/`ref[:id]` — also over boot refs), settings.rb
  `thinking_facts` :253-261 (`entry.fetch(:reasoning, false)`,
  `entry[:thinking_level_map]`). commands.rb:184 passes the resolved
  entry through UNINDEXED (`@model&.call(entry)`) — untouched.
- **Provider config hashes** (`{name:, base_url:, api_key:, api:,
  models:}` at `build_providers` models.rb:137-144): `Config#provider`
  :30-33 returns the hash; bin/tart :395 + :513-516 read
  `.fetch(:api_key)`/`.fetch(:base_url)`; models_test :71-72 pin
  `.fetch(:base_url)`/`.fetch(:api_key)`.
- **Boot refs** (`{provider:, id:}` from `resolve_boot_model`
  models.rb:120-136): bin/tart :395, :417-418, :419-420, :430-431,
  :447-448, :513, :521, :554-555 (`boot[:provider]`, `boot[:id]`);
  chat.rb `boot_model_ref` :1928-1930 builds the same two-key shape.
- **Resolved-settings scatter**: bin/tart's `Settings.resolve_setting`
  sites (:396 apiKey, :417-418 defaultProvider/defaultModel legacy
  footer shape, :515-516 apiBase/apiKey in build_chat); chat.rb's
  `Settings::DEFAULTS.fetch("thinkingLevel")` ×3 (:1733, :1768, :1942);
  the known-models tables settings.rb :91-115 (MODEL_CONTEXT_WINDOWS,
  MODEL_REASONING, THINKING_LEVEL_MAPS — plain Hash literals, frozen,
  no shape check).
- **Session entries (READ path)**: string-keyed Hash indexing with guard
  chains — `entry_to_context_message` session.rb:174-187 (type check,
  `message["role"].is_a?(String)`, role `.to_sym`, content nil→""),
  `bash_execution_context_message` :189-211 (8 field reads with
  per-field `is_a?` guards), `compaction_summary_message` :213-220
  (summary String guard), `context_entries` :229-247 (compaction scan on
  `entry["type"]`/`["id"]`/`["firstKeptEntryId"]`), `message_entry_with_role?`
  :277-280, `preview` :330-341, `read_header` :358-368 (type+id String
  guard), chat.rb `resume_session` :584-590 (assistant-text filter +
  compaction count), bin/tart :586 (`read_header(path)&.fetch("id",
  nil)`). The WRITE path (`header`/`message_entry`/`compaction_entry`
  factories :118-138 + Recorder#persist `JSON.generate` :497-503) is the
  byte-frozen surface — I07 pi-parity, byte-pinned below.
- **Struct-ish precedents** (the letter's grounding): ruby_llm's
  `Thinking`/`ToolCall` (value structs inside `Message#to_h`), the port's
  `Identity` (module, not struct), `Compaction::Settings` (a keyword
  `::Struct` with `.resolve` — compaction.rb:18-30, the loop's typed
  seam ALREADY), `Models::Config`/`Settings::Result`/`Diagnostic`
  (keyword `::Struct`s — stay).

## 3. dry-struct API facts verified by probe (tmp/i44-probe1/p1..p5)

- **to_h emits ATTRIBUTE-DECLARATION order** (p1/p5): a Model struct
  declared id, name, reasoning, context_window, max_tokens,
  thinking_level_map, provider yields `to_h` EXACTLY equal to today's
  `build_model(...).merge(provider: key)` hash (p5 asserts equality) —
  key order included. Attribute NAMES are the emitted keys: a
  snake_case attribute emits a snake_case key (p5: a `parent_session`
  attribute ≠ JSON's `parentSession` — why the WRITE path stays hashes).
- **String-keyed input RAISES by default; `transform_keys(&:to_sym)`
  declared in the struct class fixes it** (p1b) — the idiom for structs
  fed parsed JSON (session-entry envelopes).
- Unknown keys are TOLERATED in input (p1b); missing required and
  wrong-typed values raise `Dry::Struct::Error` (p1b — the
  MissingKeyError/SchemaError subclasses both surface as
  `Dry::Struct::Error`). The tolerance wrap idiom `rescue Dry::Struct::Error
  → nil` reproduces today's guard-chain nil-skips EXACTLY (p4: bad type,
  missing role, nil body, non-hash → all nil, no stray raises).
- `attribute?` (optional key) OMITS the attribute from `to_h` when not
  provided (p2/p5 — the parentSession-omission semantics), but an
  EXPLICIT nil still type-checks against the declared type (a
  `Strict::String` optional rejects nil — use `.optional` types where
  nil is legal, p2).
- **Typed constants** (p3): `Types::Strict::Hash.map(K, V)[literal]`
  applies the type and returns the plain Hash (NOT frozen — apply then
  `.freeze`); a bad literal raises `Dry::Types::MapError` at load.
  Nested `Hash.map(Symbol, String | Nil)` works (p3 — the
  THINKING_LEVEL_MAPS shape, sum types inside map keys/values).
- Coercing constructor types work as attributes (p3):
  `Types::Constructor(Strict::Symbol) { |v| v.to_sym }` (role
  symbolization) and a nil→`""` String constructor (content) — the
  entry-coercion table expressible as TYPE declarations.
- Nested `Array.of(Model)` + hash-fed nested construction (p4):
  `Provider.new(models: [{id:, provider:}])` builds Model instances
  directly from hash input.
- dry-struct 1.8.1 depends only on dry-types ~> 1.7 + dry-core ~> 1.0
  (already in I43's transitive tree) — the gemspec addition is
  dry-struct (+ dry-types declared directly: lib requires it).

## 4. Byte-stability goldens captured at base (the frozen pins)

- **Session JSONL** (tmp/i44-probe1/capture_session_bytes.rb — Recorder
  sequence: user/assistant+tool_calls/tool-result/assistant turns, a
  bashExecution record, a compaction entry, then a FORK resume appending
  one turn; volatile values masked: id/parentId/timestamp/parentSession/
  cwd/firstKeptEntryId, then per-line `JSON.generate` digest — pins key
  ORDER, field presence, entry sequence, fork verbatim-copy):
  plain `928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728`
  (roles `[:user, :assistant, :tool, :assistant]`, context-projection
  digest `d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee`),
  compaction-bearing `cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29`,
  forked `3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d`
  (context roles `[:user, :user]` — summary + post-fork prompt),
  compaction context digest `f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029`.
  Deterministic across two runs (verified).
- **Wire request bodies** (rig s1 run TWICE at base): the full rendered
  body is NOT byte-deterministic across runs for ONE reason — the system
  prompt's `<cwd>` embeds the run's sandbox path (the I41-known
  environmental artifact; `walk` diff isolates it as the ONLY
  divergence). With the sandbox path normalized to `<SBX>`, the s1
  single-request body digest is deterministic:
  `2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2`;
  the tools-array digest is I43's pin `7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707`
  (re-verified green at base both runs).
- The replay probe's byte-stability findings (ARCHITECT.md program
  handoff; the probe's scratch lives under tmp/replay-probe/) hold at
  base: request N+1 is a byte-superset of N; resume round-trip
  byte-identical — this iteration must not regress them (the wire-body
  + session-golden gates are the enforcement).

## 5. Test surgery enumeration (the conscious re-pins — every existing
   assertion that indexes the migrated shapes)

- `test/models_test.rb`: :69-70 (entry hash equality → `to_h`
  comparison), :71-72 (`.fetch(:base_url)`/`.fetch(:api_key)` →
  attribute reads), :138-140 (`.fetch(:provider)`/`.fetch(:name)` →
  attribute reads), :157/:162/:166/:172/:175/:180/:186/:192/:197 (boot
  `{provider:, id:}` hash equality → ModelRef `.to_h`/attribute
  assertions), :213 (`entry[:thinking_level_map]`), :219, :349.
- `test/schemas_test.rb`: :69-74 (entry hash equality → `to_h`).
- `test/settings_test.rb`: :335-353 (literal entry hashes → struct
  construction; `facts[:reasoning]`/`facts[:thinking_level_map]` →
  attribute reads; `entry[:id]`).
- `test/session_test.rb`: :175-179 (`projected[:role]`/`[:content]` on
  `entry_to_context_message` output → attribute reads), :191 (`[:content]`).
  The `context_messages`-output pins (:107-108, :160, :319-320, :344)
  stay UNTOUCHED — the output shape is unchanged (Grounds §6).
- `test/chat_test.rb`: :2245-2254 + :2406-2413 (the two
  `Models::Config.new` catalog fixtures — hash-fed providers/models →
  struct-built fixtures). Everything else in these files: additive only.

## 6. The seams that do NOT move (itemized, each with its reason)

- **The gem seam**: `RubyLLM::Chat#add_message` accepts Hash | Message
  and calls `.merge(config:)` on hashes (gem chat.rb:1138-1147) — a
  struct cannot ride it. `Session.context_messages` therefore KEEPS its
  public output shape (Array of `{role:, content:, …}` symbol-keyed
  Hashes; session_test :107/:160 pins, e2e payload proof) — the port
  -internal projection becomes typed, `.to_h` applied at the boundary.
- **The Recorder write path**: the three entry factories + `entry_line`
  + the fork-copy block stay Hash literals — the JSONL bytes are the
  I07 frozen surface (byte-pinned by §4, not re-derived).
- **footer_data** (launcher→render facts hash): stays a Hash — render
  data, not a settings/model shape; boot_model_entry/boot_model_ref READ
  it and build typed shapes from it.
- **Settings' internal hash domain**: `Settings.load`/`read_file`/
  `deep_merge`/`save`/`resolve_*` helpers and `Models.resolve_boot_model`'s
  settings-tier reads keep the merged Hash (the merged file shape is
  byte-pinned by settings_test + the I43 no-filter pin — `Result#settings`
  carries malformed values verbatim). The helpers' public signatures are
  unchanged.
- **Compaction::Settings** (compaction.rb:18-30): already a typed
  `::Struct` seam consumed by the loop — untouched.

## 7. Open questions (itemized for the judge; resolved by plan letter in
   the Specification — none blocking)

- **OQ-1 (the gem seam).** `context_messages` maps structs back to
  Hashes at the add_message boundary (the port cannot re-type the gem's
  API). Specification ruling: typed port-side, `.to_h` at the boundary,
  the Hash output shape pinned unchanged. Judge may re-rule (e.g. demand
  port-side `RubyLLM::Message` construction — rejected here: it moves
  the Message round-trip into port code with wire-byte risk).
- **OQ-2 (ResolvedSettings' honest typing).** pi flows-through malformed
  settings values (settings-manager.ts:126, the I43 no-filter pin), so a
  strict struct over file-sourced scalars would RAISE where today the
  value lands verbatim. Specification ruling: strict types ONLY where
  resolution guarantees the type (identity String, thinking_level
  vocab String, context_window Integer|nil via the file-tier contract,
  default_tools Array); file-sourced scalars ride `Types::Nominal::Any`
  (documented flows-through view). Judge may re-rule.
- **OQ-3 (test re-pins).** The §5 surgery is mechanical accessor/to_h
  re-pinning, semantics-neutral by enumeration; the byte goldens (§4)
  are frozen gate literals captured at base. Judge verifies
  semantics-neutrality on the diff.
- **OQ-4 (boot entry completeness).** The footer-facts-built boot entry
  gains an explicit `max_tokens: nil` (struct completeness) — its hash
  shape is unpinned (menu rows read name/provider/id only). Itemized.
- **OQ-5 (read_header's return type).** `Agent::Session.read_header`
  moves Hash → `Shapes::SessionHeader` (public API) — consumers
  enumerated (§2: find_most_recent/list internals, bin/tart:586); no
  test pins the hash shape. Intended API move, itemized.


─ The frozen Specification (verbatim from architecture/I44-dry-rb-shapes.md,
  freeze 55ca77a) ──────────────────────────────────────────────────────
# Specification — I44 dry-rb-shapes

## Objective

Program ENTRY 2 (`build/loop/plan-20261013T092136Z.md`): dry-types/dry-struct
for tart's internal shapes — typed structs replace the hash-table masses at
the Model catalog, the resolved-settings reads, and the session-entry load
path. Composes on ENTRY 1 (I43): the `Tart::Schemas` family and its 5-rule
error discipline are inherited unchanged; this iteration adds the VALUE side
(structs), not new validation. Parity track: internal only — ZERO observable
byte moves on screen or wire. HARD constraint (the letter): session-file
bytes and wire bytes do not move — the JSONL format is pi-parity I07 and the
replay probe proved byte-stability; the Grounds §4 goldens are frozen gate
literals. Known-models tables become typed constants. Consumers read the
structs; no hash-shape aliasing is left behind at the migrated seams
(enumerated in Grounds §2; the seams that do NOT move are Grounds §6).

## The shape contract (composes on I43's pattern contract)

- **Home + naming.** One module family: `lib/tart/shapes.rb` (aggregate
  require, house style of `lib/tart/schemas.rb`) +
  `lib/tart/shapes/{types,model,settings,session}.rb`, namespace
  `Tart::Shapes`. `shapes/types.rb` defines `Tart::Shapes::Types`
  (`include Dry::Types()`), the one shared Types module — member files
  `require_relative "types"` and reference `Shapes::Types::…`. `lib/tart.rb`
  gains `require_relative "tart/shapes"`. Consumers require their own
  shapes member directly (the existing require discipline).
- **Structs are `Dry::Struct` subclasses**, one class per shape, attribute
  names snake_case (the Ruby-facing vocabulary), `Types` from
  `Shapes::Types`. Structs fed parsed-JSON input declare
  `transform_keys(&:to_sym)` (Grounds §3). No schema re-validation rides
  struct construction (shape typing ≠ boundary validation — I43 rule 1).
- **Error discipline (I43's rules, applied to values).** Structs never
  construct where today's code does not branch: the session-entry
  envelopes' tolerant wrap (`rescue Dry::Struct::Error → nil`) reproduces
  today's guard-chain nil-skips EXACTLY (Grounds §3 p4); NO new raise
  reaches a user surface. The known-table type literals raise
  `MapError` at LOAD time only (compile-time constants).
- **Byte rule.** No struct's `to_h` output crosses a byte-frozen surface
  (Grounds §6): the write path stays hashes; the gem seam gets `.to_h`.
  `Shapes::Model#to_h`'s key order is DECLARED to equal today's
  `build_model.merge(provider:)` hash (Grounds §3, p5-verified) — pinned
  by unit test.
- **No filtering, no coercion beyond today.** Where a struct types a
  flows-through value, it uses `Types::Nominal::Any` (documented);
  coercing types appear ONLY where today's code already coerces (role
  `.to_sym`, content nil→`""` — the entry-coercion table as types).

## B1 — the Model family (lib/tart/shapes/model.rb + models.rb + consumers)

- `Shapes::Model` — attributes IN ORDER: `id`, `name`
  (`Strict::String`), `reasoning` (`Strict::Bool`), `context_window`,
  `max_tokens` (`Strict::Integer.optional`), `thinking_level_map`
  (`Strict::Hash.map(Strict::Symbol, Strict::String | Strict::Nil).optional`),
  `provider` (`Strict::String`). `to_h` == today's entry hash, key order
  included (unit-pinned). `thinking_level_map` values are the
  symbolized Partial-Record shape (I36 semantics ride unchanged).
- `Shapes::Provider` — `name`, `base_url`, `api_key`, `api`
  (`Strict::String.optional` — today's parse may omit them), `models`
  (`Strict::Array.of(Model)`).
- `Shapes::ModelRef` — `provider`, `id` (`Strict::String`).
- `Shapes::ThinkingFacts` — `reasoning` (`Strict::Bool`), `thinking_level_map`
  (the map type above).
- `Models.build_providers`/`build_model` construct the structs (the
  provider key feeds `Model#provider` at build); `Config` keeps its
  `::Struct` shell with `providers` now `Hash[String => Shapes::Provider]`;
  `Config#model_entries` → `Array[Shapes::Model]` (flat_map over
  `provider.models` — no merge); `Config#resolve` → `Shapes::Model|nil`
  with today's exact match table (canonical/scoped/bare, ambiguity =
  no match); `Config#provider(key)` → `Shapes::Provider|nil`.
- `Models.resolve_boot_model` returns `Shapes::ModelRef` (same precedence
  table; the settings-tier reads keep the merged Hash — Grounds §6).
  `Settings.thinking_facts` returns `Shapes::ThinkingFacts` (same
  catalog-entry-first/known-tables-second table).
- **Consumers** (Grounds §2's work list, ALL migrated): bin/tart
  (`boot.provider`/`boot.id`; `provider&.api_key`/`&.base_url`;
  `facts.reasoning`/`facts.thinking_level_map`), chat.rb
  (`apply_model_selection` reads `entry.id`/`.provider`/`.context_window`;
  `@runtime_model` holds the struct; `boot_model_entry` builds a
  `Shapes::Model` (the `max_tokens: nil` completeness note — Grounds OQ-4);
  `boot_model_ref` builds a `Shapes::ModelRef`), model_menu.rb
  (`model()` builds UI-row hashes FROM the struct — `{value:, label:,
  provider:, id:, name:, current:, default:}` rows stay plain Hashes
  (render rows); `ref_key` reads `.provider`/`.id` — Model and ModelRef
  both respond). commands.rb passes entries through unindexed —
  untouched.

## B2 — resolved settings + typed tables (lib/tart/shapes/settings.rb +
settings.rb + consumers)

- `Shapes::ResolvedSettings` — the typed view of the RESOLVED settings,
  built ONCE per boot by `.from_load(settings_or_result, identity:,
  env: ENV)` which runs today's exact resolution arithmetic per key
  (env tier via `Identity.env_key`, then the merged file hash, then
  DEFAULTS — the `resolve_setting` table; thinking level via
  `resolve_thinking_level`; the file-tier context window via
  `Schemas::Settings.context_window_value`; tools via
  `selected_tools`; compaction via the `compaction_kwargs` key set):
  - strict where resolution guarantees the type: `identity`
    (`Strict::String` — Identity.resolve validates), `thinking_level`
    (`Strict::String` — the vocab-resolved value or "medium"),
    `context_window` (`Strict::Integer.optional` — the file-tier
    contract output), `default_tools` (`Strict::Array`).
  - `Types::Nominal::Any` where pi flows-through (documented in the
    class): `default_model`, `default_provider`, `api_base`, `api_key`
    (raw staged values ride verbatim — Grounds OQ-2).
  - `compaction` → `Shapes::CompactionSettings` (`attribute?` for
    `enabled`/`reserve_tokens`/`keep_recent_tokens`, nominal values —
    the present-keys slice `compaction_kwargs` produces today).
- Consumed at the launcher's scattered sites (Grounds §2): print +
  interactive construct it once after identity resolution;
  `require_api_key`'s settings tier, `footer_data`'s legacy boot shape +
  level, `build_chat`'s api tiers read struct attributes. chat.rb's
  three `DEFAULTS.fetch("thinkingLevel")` sites (:1733, :1768, :1942)
  AND print.rb's fourth (:65 — `Print.run`'s default-level fallback)
  read the typed constant (the same migration class; print.rb's touch
  is that one line). The Settings helpers' public signatures stay
  (they remain the Settings domain's API; the struct is the consumer
  view).
- **Typed constants** in settings.rb via `Shapes::Types` map types
  applied at load, then `.freeze`: `MODEL_CONTEXT_WINDOWS`
  (`Hash.map(Strict::String, Strict::Integer)`), `MODEL_REASONING`
  (`Hash.map(Strict::String, Strict::Bool)`), `THINKING_LEVEL_MAPS`
  (`Hash.map(Strict::String, Hash.map(Strict::Symbol, Strict::String |
  Strict::Nil))`) — CONTENT byte-identical (values compared key-for-key
  in unit pins); a malformed literal fails at load (MapError). New
  `DEFAULT_THINKING_LEVEL = "medium"` (`Strict::String` literal) becomes
  the single source of `DEFAULTS["thinkingLevel"]`; chat.rb's three
  `DEFAULTS.fetch("thinkingLevel")` sites (:1733, :1768, :1942) read the
  constant. `DEFAULTS` itself (the merged-file tier source, byte-pinned
  by settings_test) stays a frozen Hash.

## B3 — session-entry typed views, READ path only
(shapes/session.rb + agent/session.rb + chat.rb resume block)

- `Shapes::MessageEntry` — `transform_keys(&:to_sym)`; `type`
  (`Strict::String.enum("message")`), `role` (`Strict::String` — read
  from `message["role"]`), `message` (`Strict::Hash` — the open
  recorded-message body). Class method `.of(raw)` = constructor inside
  `rescue Dry::Struct::Error → nil` (the tolerance idiom) — a non-Hash,
  wrong-typed, role-less, or body-less entry reads nil, exactly today's
  guard outcomes (unit-pinned against the §2 read sites' inputs).
- `Shapes::CompactionEntry` — `type` (`enum("compaction")`), `id`,
  `first_kept_entry_id` (`Nominal::Any` — the scan's raw reads; strict
  typing would change malformed-entry outcomes, Grounds §2), `summary`
  (`Nominal::Any` — the projection's own String guard stays).
  `.of(raw)` as above.
- `Shapes::SessionHeader` — `type` (`enum("session")`), `id`
  (`Strict::String`), `cwd` (`Nominal::Any` — `cwd_matches?` guards),
  `version`/`timestamp`/`parentSession` (`attribute?`, nominal).
  `Session.read_header` returns it (or nil) — the Grounds OQ-5 API move;
  `find_most_recent`/`list` pass `header.cwd` into the unchanged
  `cwd_matches?`; bin/tart reads `.id`.
- `Shapes::ContextMessage` — `role`
  (`Types::Constructor(Strict::Symbol) { _1.to_sym }`), `content`
  (nil→`""` String constructor) — the projection OUTPUT. The three
  projection functions (`entry_to_context_message`,
  `bash_execution_context_message`, `compaction_summary_message`)
  consume the envelope wraps and return `Shapes::ContextMessage` (the
  bash record's per-field `is_a?` guards stay verbatim inside the
  projection — its field reads go through the envelope's `message`
  hash, unchanged tolerance table); `context_messages` applies `.to_h`
  at the gem seam (output shape unchanged — Grounds §6, unit-pinned).
  `message_entry_with_role?` and `preview` ride the MessageEntry wrap;
  `context_entries`' compaction scan rides the CompactionEntry wrap
  (kept-entry matching semantics unchanged); chat.rb's `resume_session`
  block reads the wraps (assistant-text filter + compaction count).
- The Recorder write path, the three entry factories, and
  `Recorder#context_entries`' deep-copy stay Hash literals (Grounds
  §6) — the JSONL bytes are the frozen surface, byte-pinned by the
  Grounds §4 goldens.

## Dependency changes

`tart.gemspec` gains `spec.add_dependency "dry-struct", "~> 1.8"` and
`spec.add_dependency "dry-types", "~> 1.9"` (production deps — lib
requires them at boot; dry-types is declared directly because shapes
files require it, even though I43's tree already carries it
transitively). No other gemspec change; `Gemfile.lock` regenerates and
is committed. No path/git vendoring; no `required_ruby_version` change.

## New unit pins (test/shapes_test.rb + the re-pinned sites)

- **Construction + coercion failures** (the letter's pin set): every
  struct constructs from its feeding input (Model from a catalog-hash
  fixture, Provider with nested models, ModelRef, ThinkingFacts,
  ResolvedSettings from a merged-hash fixture per precedence row,
  ContextMessage role/content coercions, envelopes from JSON-string-keyed
  lines); wrong-typed input raises `Dry::Struct::Error` (Model id:5,
  reasoning:"true"; envelope type:"usage"; header id:nil); the
  `.of(raw)` tolerance table (nil outcomes for every malformed class
  today's guards skip — the null-content, role-less, non-Hash,
  wrong-type rows).
- **`Shapes::Model#to_h` byte-shape pin**: key order + values == the
  Grounds §3 merged-hash shape, including `thinking_level_map`
  symbolization and the provider-last order.
- **Catalog equivalence**: `Models.load` on the models_test CATALOG
  fixture yields `model_entries.map(&:to_h)` == today's entry hashes
  (line-for-line); `Config#resolve`'s match table re-pinned through
  attribute reads; `resolve_boot_model` → ModelRef `.to_h` rows (env /
  catalog-default / settings tiers, both identity namespaces).
- **ResolvedSettings outcome table**: per key, env-only / file-only /
  default-only / env+file / all / none (the I43 precedence matrix's
  keys), asserting each attribute equals today's `resolve_setting`
  output for the same fixture — including the malformed flows-through
  rows (`"contextWindow": "abc"` lands verbatim in the nominal
  attributes; no raise, no filter).
- **Typed-constant pins**: the three tables' contents compared
  key-for-key with today's literals; `DEFAULT_THINKING_LEVEL ==
  Settings::DEFAULTS.fetch("thinkingLevel")`; a doctored bad literal
  raises `Dry::Types::MapError` (a load-time check demonstrated in-test
  via `Types[...]` application on a bad literal).
- **Session projection pins** (additive in session_test): the wrap
  tolerance rows; `context_messages` output == today's Hash shape (the
  :107/:160 pins stay green untouched); the read_header struct's
  fields.

## Tool guidance (verify against live deps before writing code)

- Read the installed versions' sources first: reference clones at
  `~/architect/src/github.com/dry-rb/{dry-struct,dry-types}` (1.8.1 /
  1.9.1). Probed idioms that work on this exact stack (Grounds §3):
  `attribute`/`attribute?`; `transform_keys(&:to_sym)`;
  `Types::Strict::…`; `.optional`; sum types inside `Hash.map`;
  `Types::Constructor(type) { … }`; `Strict::Array.of(Model)`; the
  `rescue Dry::Struct::Error → nil` wrap idiom; `Types[...]`
  application on literals (MapError on mismatch, apply-then-freeze).
  Do NOT invent: `Dry.Struct` old macros, `schema.strict` input
  processors, per-call type redefinition.
- Verification (exact, per repo): `bundle install --quiet && bundle
  exec rake` (suite), `bundle exec ruby bench/seam_bench.rb`
  (SEAM_BENCH_OK), `gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/<s>.yml --out tmp/<canonical-short-dir>`
  for s1–s10 + the two `--gate` probes (cold; s1_tart exits 1 by
  design). The byte gates below are the freeze-time literals — if one
  fails, a byte moved: STOP and report, never adjust the literal.
- Comment phrasing: the no-aliasing gates grep source text — phrase
  comments to avoid the literal patterns (write "the boot ref", never
  `boot[`).

## Boundaries

**May touch** (the ```lanes block is the frozen source of truth):
`tart.gemspec`, `Gemfile.lock`, `lib/tart.rb`, `lib/tart/shapes.rb`,
`lib/tart/shapes/{types,model,settings,session}.rb` (new),
`lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/agent/session.rb`,
`lib/tart/render/chat.rb`, `lib/tart/render/model_menu.rb`,
`lib/tart/print.rb` (the :65 constant-read line ONLY), `bin/tart`,
`test/shapes_test.rb` (new), `test/{models,schemas,settings,session,
chat}_test.rb` (the Grounds §5 enumerated re-pins + additive pins only).

**Must not touch**: everything else, in particular — `lib/tart/schemas*
` (ENTRY 1's family, inherited verbatim), `lib/tart/tools/**`,
`lib/tart/mcp/**`, `lib/tart/agent/{loop,bridge,status,context_files,
system_prompt}.rb`, `lib/tart/compaction.rb`,
`lib/tart/commands.rb` (pass-through consumer — zero reads to migrate),
`lib/tart/identity.rb`, `lib/tart/skills.rb`, `lib/tart/prompts.rb`,
`lib/tart/theme.rb`, `lib/tart/tui.rb`, `lib/tart/core/**`,
`lib/tart/render/**` except `chat.rb`+`model_menu.rb`, `bench/**`,
`gems/tui-split-rig/**`; the frozen test files (`golden_parity_test.rb`,
`e2e_session_test.rb`, `launcher_smoke_test.rb`, `agent_loop_test.rb`,
`loop_test.rb`, `print_test.rb`, `tools_test.rb`, `bash_tool_test.rb`,
`mcp_test.rb`, `commands_test.rb`, `skills_test.rb`, `identity_test.rb`,
`theme_test.rb`, `tui_test.rb`, `markdown_test.rb`, `prompts_test.rb`,
`system_prompt_test.rb`, `compaction_test.rb`,
`kernel_carryin_test.rb`), `test/render/**`, `test/support/**`,
`test/fixtures/**`.

**Out of scope** (itemized, not lost): the gem seam (add_message Hash |
Message boundary — Grounds OQ-1); the Recorder write path + entry
factories (byte-frozen); footer_data (render facts); the render-side
session replay reads (transcript.rb :305/:594 `entry["message"]` —
the render family is the byte-critical parity surface; the shapes
family covers the AGENT-side load/resume path); Compaction::
Settings + the loop's compaction seam; Agent::Loop/MCP-client
dry-monads (ENTRY 3); the settings helpers' internal hash domain;
pi Value.Convert tool-arg coercion and the bash >2147483.647s tier
(I43 residuals); `Models::Schemas` behavior; any new validation, any
new diagnostics, any settings value filtering.

## Lane plan

ONE lane (single-writer — Model and Settings consumers share chat.rb/
bin/tart; parallel lanes would collide on the same files):

- **shapes** — target `repos/tart`, the full touch set above, the whole
  objective. Effort: HIGH at dispatch (3 deliverable families, ~13
  consumer files, deps, the byte-pin discipline).

```lanes
- name: shapes
  repo: tart
  touch:
    - tart.gemspec
    - Gemfile.lock
    - lib/tart.rb
    - lib/tart/shapes.rb
    - lib/tart/shapes/types.rb
    - lib/tart/shapes/model.rb
    - lib/tart/shapes/settings.rb
    - lib/tart/shapes/session.rb
    - lib/tart/models.rb
    - lib/tart/settings.rb
    - lib/tart/agent/session.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/model_menu.rb
    - lib/tart/print.rb
    - bin/tart
    - test/shapes_test.rb
    - test/models_test.rb
    - test/schemas_test.rb
    - test/settings_test.rb
    - test/session_test.rb
    - test/chat_test.rb
```


─ The frozen Acceptance Criteria incl. the gates block (verbatim from
  architecture/I44-dry-rb-shapes.md, freeze 55ca77a) ───────────────────
# Acceptance Criteria — I44 dry-rb-shapes

Gate calibration (pre-declared): **RED at base BY DESIGN** —
`deps-shapes`, `shapes-presence`, `no-aliasing` (the dry-struct/dry-types
deps, the `Tart::Shapes` family, and the migrated accessor surface do not
exist at 0c6ee246); they must be GREEN on the integrated tree,
non-vacuously. **Regression guards (GREEN at base, must stay GREEN)** —
`suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, both probe gates,
`wire-bodies`, `session-golden` (the two byte-pin gates were captured at
base this session — Grounds §4 — and verified deterministic across two
base runs; a post-build failure means a byte moved). The s-gates keep the
CANONICAL short out dirs (I41 Grounds 1's environmental note). The KNOWN
s9 lane-worktree deep-path artifact (I34/I36/I39/I40/I42/I43 precedent)
does not fail this iteration when the same tree exits 0 at canonical
depth — the judge runs the battery on the integrated tree.

**AC1 (the shapes family lands).** `Tart::Shapes` exists at the specified
home (`lib/tart/shapes.rb` + `shapes/{types,model,settings,session}.rb`)
with the specified classes (`Model`, `Provider`, `ModelRef`,
`ThinkingFacts`, `ResolvedSettings`, `CompactionSettings`,
`MessageEntry`, `CompactionEntry`, `SessionHeader`, `ContextMessage`);
`tart.gemspec` declares `dry-struct ~> 1.8` + `dry-types ~> 1.9` as
PRODUCTION deps and `Gemfile.lock` carries them. The shape contract
(naming, transform_keys for JSON-fed structs, the tolerance wrap idiom,
nominal-for-flows-through, byte rule) is followed. Pinned by
`deps-shapes` + `shapes-presence` + judge read of the diff.

**AC2 (Model-family equivalence).** `Models.load`'s valid-path outputs
are `to_h`-equal to today's entry hashes (key order included — the
`to_h` shape pin); `Config#model_entries`/`#resolve`/`#provider` return
the typed shapes with today's exact match tables;
`resolve_boot_model` → `ModelRef` (same precedence table);
`Settings.thinking_facts` → `ThinkingFacts` (same catalog-first/
known-tables-second outcomes); every Grounds §2 Model-family consumer
(bin/tart, chat.rb's model family, model_menu.rb) reads struct
attributes — no `[:provider]`/`[:id]`-style entry indexing at the
migrated seams; the Grounds §5 re-pins land (mechanical, enumerated).
Pinned by `no-aliasing` + the new unit pins + the existing pins green.

**AC3 (resolved settings + typed tables).** `ResolvedSettings.from_load`
reproduces today's resolution outcome table per key (env > file >
DEFAULTS incl. every malformed flows-through row — nominal attributes
carry raw values verbatim, no raise, no filter); it is consumed at the
launcher's Grounds §2 sites; the three known-models tables are
type-checked constants with contents byte-identical to today's literals;
`DEFAULT_THINKING_LEVEL` single-sources the default and chat.rb's three
`DEFAULTS.fetch("thinkingLevel")` sites plus print.rb's fourth (:65)
read it; `Result#settings`'
merged-hash shape and the I43 no-filter pin are untouched. Pinned by
the new unit pins + `no-aliasing` + the existing settings/schemas pins
green (the I43 precedence matrix untouched).

**AC4 (session entries typed, bytes frozen).** The read path
(`entry_to_context_message` family, `message_entry_with_role?`,
`context_entries`' scan, `preview`, `read_header`, chat.rb's resume
block) consumes the envelope wraps with today's EXACT tolerance table
(every malformed class projects nil; null content → ""; the bash
per-field guards verbatim); `context_messages`' output Hash shape is
unchanged (`.to_h` at the gem seam — the untouched session_test/
e2e_session pins prove it); the write path (factories, Recorder#persist,
fork copy) is Hash-literal-untouched. The byte goldens hold: session
JSONL digests (plain/compaction/fork/context) and the wire request-body
digest identical to the Grounds §4 literals. Pinned by `session-golden`
+ `wire-bodies` + session_test/e2e_session green UNTOUCHED at their
un-re-pinned lines.

**AC5 (parity + regression + scope).** The default rake task fully green
(run count > 823 with the new pins); `SEAM_BENCH_OK`; s1–s10 exit 0
cold at the canonical out dirs; `s1-tart-mode` completes (TART_MODE_OK);
both probe gates OK (TOOL_PENDING_GATE_OK, USER_BASH_STREAM_GATE_OK);
the integrated diff vs **0c6ee246** touches EXACTLY the lane's declared
file set — no schemas file, no tools/mcp/agent file, no frozen test
file, no rig file.

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

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
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

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i44-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i44-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i44-wire && gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i44-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i44-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i44-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i44-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: deps-shapes
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'dry-struct' tart.gemspec && grep -q 'dry-types' tart.gemspec && grep -q 'dry-struct' Gemfile.lock && grep -q 'dry-types' Gemfile.lock && bundle install --quiet && bundle exec ruby -e 'require "dry-struct"; require "dry-types"; puts "DEPS_SHAPES_OK"'
  expect:
    exit_code: 0
    stdout_match: DEPS_SHAPES_OK

- id: shapes-presence
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; need = %w[Model Provider ModelRef ThinkingFacts ResolvedSettings CompactionSettings MessageEntry CompactionEntry SessionHeader ContextMessage]; missing = need.reject { |c| Tart::Shapes.const_defined?(c, false) }; abort "Tart::Shapes missing: #{missing.inspect}" unless missing.empty? && defined?(Tart::Shapes::Types); abort "test/shapes_test.rb missing" unless File.file?("test/shapes_test.rb"); puts "SHAPES_OK"'
  expect:
    exit_code: 0
    stdout_match: SHAPES_OK

- id: no-aliasing
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if grep -q 'boot\[' bin/tart; then echo "FAIL boot ref indexing in bin/tart"; exit 1; fi; if grep -qnE 'entry\[:' lib/tart/render/chat.rb lib/tart/render/model_menu.rb lib/tart/settings.rb; then echo "FAIL entry hash indexing at migrated seams"; exit 1; fi; if grep -qnE 'fetch\(:api_key|fetch\(:base_url' bin/tart; then echo "FAIL provider config hash indexing in bin/tart"; exit 1; fi; if grep -qn 'DEFAULTS.fetch("thinkingLevel")' lib/tart/render/chat.rb lib/tart/print.rb; then echo "FAIL DEFAULTS hash read in chat.rb/print.rb"; exit 1; fi; if grep -q 'provider.fetch(:models)' lib/tart/models.rb; then echo "FAIL models hash indexing in models.rb"; exit 1; fi; if grep -qnE 'entry\.fetch\(:reasoning|entry\[:thinking_level_map\]' lib/tart/settings.rb; then echo "FAIL thinking_facts hash indexing"; exit 1; fi; if grep -qnE '\["message"\]' lib/tart/agent/session.rb lib/tart/render/chat.rb; then echo "FAIL session envelope hash indexing"; exit 1; fi; if grep -qnE 'facts\[:' bin/tart lib/tart/render/chat.rb; then echo "FAIL thinking_facts hash indexing at consumers"; exit 1; fi; echo NO_ALIASING_OK
  expect:
    exit_code: 0
    stdout_match: NO_ALIASING_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 0c6ee246 HEAD | grep -qvE '^(tart\.gemspec|Gemfile\.lock|lib/tart\.rb|lib/tart/shapes\.rb|lib/tart/shapes/types\.rb|lib/tart/shapes/model\.rb|lib/tart/shapes/settings\.rb|lib/tart/shapes/session\.rb|lib/tart/models\.rb|lib/tart/settings\.rb|lib/tart/agent/session\.rb|lib/tart/render/chat\.rb|lib/tart/render/model_menu\.rb|lib/tart/print\.rb|bin/tart|test/shapes_test\.rb|test/models_test\.rb|test/schemas_test\.rb|test/settings_test\.rb|test/session_test\.rb|test/chat_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```


─ Non-contract working notes (NOT part of the frozen contract) ────────

1. Worktree rig caveat (I34/I36/I39/I40/I42/I43 precedent): s9 may exit 1
   in the lane worktree at deep paths — the KNOWN environmental artifact.
   Run the battery at the canonical short out dirs; if s9 alone fails,
   verify with an equal-depth control and report it; the judge re-runs on
   the integrated tree.
2. Verification (exact): bundle install --quiet && bundle exec rake;
   bundle exec ruby bench/seam_bench.rb; gems/tui-split-rig/bin/tui-split-rig
   run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-dir> for
   s1_text_turn, s2_tool_turn, s3_tool_turn_files, s4_bash_variants,
   s5_bash_truncation, s6_long_calls, s7_compaction,
   s8_zero_usage_compaction, s9_startup_help, s10_editor_wrap; the
   tool-pending-probe --gate and user-bash-stream-probe --gate.
3. Reference source (read, never vendored): ~/architect/src/github.com/
   dry-rb/{dry-struct,dry-types} — verify API idioms against the
   installed 1.8.1/1.9.1 before writing code; the Grounds §3 probe
   results are the verified idiom list.
4. Comment phrasing: the no-aliasing gates grep source text — phrase
   comments to avoid the literal patterns (write "the boot ref", never
   `boot[`; never leave `entry[:` in a comment at the migrated files).
5. Report shape (build/I44-dry-rb-shapes-shapes/report.md): PHASE 0
   findings/disagreements table first, then per-deliverable summary
   (B1/B2/B3), the test-surgery diff table (every re-pinned line, old →
   new), verification output (suite/battery/gates with exit codes), and
   the residuals list. You never commit — the architect integrates.

## Builder Report

### shapes

# Lane report — I44 dry-rb-shapes, lane `shapes` (sole lane)

Worktree: `build/I44-dry-rb-shapes-shapes/wt` (repos/tart provisioned from frozen base
`0c6ee246`, branch `lane/I44-dry-rb-shapes-shapes`). Builder ran under zai/glm-5.3-flash
thinking-high. No commits made (`git log 0c6ee246..` empty; the integrated diff is the
worktree's uncommitted change set: exactly the declared 21-file touch set).

## PHASE 0 — findings / disagreements (researched, itemized; resolved by the prompt letter unless noted)

| # | Finding / disagreement | Resolution + reason |
|---|---|---|
| P0-1 | **Grounds §5's enumeration is NOT exhaustive.** Four FROZEN test files exercise the migrated seams with legacy shapes and are NOT in §5's re-pin list: `commands_test.rb` :106–131 (feeds `Models::Config.new` raw-hash providers and pins `/model` dispatch passing an entry that `==`s the legacy 6-key hash — no `thinking_level_map` key), `test/render/model_menu_test.rb` (feeds `ModelMenu.model` raw-hash entries + two-key hash refs), `e2e_session_test.rb` :118/:183 (reads `Session.read_header(...)["parentSession"]` — string-key `[]` + `.key?` on the return), `launcher_smoke_test.rb` :77/:117 (calls `Executable.footer_data` WITHOUT the new `resolved:` kwarg) + :175–198 (opens the model menu with NO `footer_data` → boot ref id nil). The spec requires these files untouched AND the suite green. | **Frozen tests win** (they are regression guards: `suite` must stay green; my builder contract freezes existing public interfaces). Added legacy-compat shims at exactly those four seams, each documented in-code and listed under Residuals: (a) `Models::Config` ducks provider values — typed `Shapes::Provider` values (the `Models.load` production path) yield typed `Shapes::Model` entries; raw-hash providers (hand-built configs only) keep today's raw merged-hash entries, so the frozen 6-key `==` pin holds; `Config#resolve` reads fields through a duck helper. (b) `ModelMenu.model`/`ref_key` read entries/refs through the same duck (typed attribute first, raw-hash fetch fallback); rows stay plain Hashes carrying the typed entry. (c) `Shapes::SessionHeader` keeps the raw recorded hash and answers the discovery readers (`[]` string/symbol, `.key?`) nil-safely. (d) `Executable.footer_data`'s `resolved:` kwarg is optional (built on the spot when absent). Judge note: OQ-5's "no test pins the hash shape" is factually wrong for e2e :118/:183. |
| P0-2 | **`ContextMessage` as a plain Dry::Struct cannot round-trip the recorded body.** A declared-attributes `to_h` would drop the open body's remaining keys (`tool_calls`, `tool_call_id`) and re-order them (a tool body records `role, tool_call_id, content`; declaration order `role, content` would flip the tail) — wire-byte fatal for tool turns and the resume seed. | `Shapes::ContextMessage` is a `Dry::Struct` whose declared typed attributes (`role` symbolizing constructor, `content` nil→"" constructor) carry the entry-coercion table, plus a constructor override that pins the coerced full input in recorded key order and a `to_h` emitting it. This is the only reading that satisfies BOTH "the three projection functions return Shapes::ContextMessage" AND "context_messages applies .to_h at the gem seam (output shape unchanged)" + the frozen wire/session goldens. Verified: SESSION_GOLDEN_OK (all 6 digests exact), s2/s3 tool turns green. |
| P0-3 | **Content constructor strictness conflict.** Grounds §3 p3/B3 call content a "nil→"" String constructor". Probed live: `Types::Constructor(Types::Strict::String) { … }` VALIDATES the block output — a recorded non-String non-nil content (e.g. `5`) would RAISE where today's projection has no guard, violating the same spec's error discipline ("NO new raise reaches a user surface"; "coercing types appear ONLY where today's code already coerces" — today coerces nil→"" only). | Content rides `Types::Constructor(Types::Nominal::Any) { |v| v.nil? ? "" : v }` — the nil→"" mapping, no constraint. The letter's word "String" is subordinated to the discipline paragraph. Itemized. |
| P0-4 | **Menu row shape vs the switch seam.** The enumerated row shape `{value:, label:, provider:, id:, name:, current:, default:}` cannot feed `apply_model_selection`'s struct reads (`.context_window`); today's row carries the merged entry hash. | Rows stay plain Hashes and carry the typed entry under an `entry:` key; the menu's `on_select` closures deliver `item.fetch(:entry)` to the switch seam, which reads struct attributes only. No re-hashing anywhere. |
| P0-5 | **`switch_model`'s legacy keyword-hash shape.** Untouched `chat_test` lines call `chat.switch_model(provider: …, id: …, …)` — Ruby 4 delivers that as one positional Hash. | `apply_model_selection` normalizes non-struct input through `Shapes::Model.new(**entry, thinking_level_map: entry.fetch(:thinking_level_map, nil))` — the struct's own type gate — before any read; production paths (menu carrier, `commands.rb` pass-through of `resolve`) deliver structs. Note: declared-`.optional` attributes still REQUIRE their key at construction (probed), hence the explicit map-key supply. |
| P0-6 | **`ModelRef` strict `Strict::String` vs malformed settings.** A settings file `{"defaultModel": 5}` flows verbatim through `Settings.load` (the I43 no-filter pin) and would now raise at `resolve_boot_model`/the footer's legacy boot construction where a raw-value hash used to ride until the wire layer failed. | Followed the frozen letter (Strict::String; OQ-2 deliberately scopes nominal typing to ResolvedSettings' scalars). Consequence itemized: a malformed defaultModel/defaultProvider FILE value crashes the boot one layer earlier. Env tier (always Strings) and catalog tier (struct-guaranteed) are unaffected; DEFAULTS guarantee Strings absent explicit malformed overrides. |
| P0-7 | **`boot_model_entry`'s reasoning can be nil** (footer fixtures without `:reasoning`; today stores nil). `Shapes::Model.reasoning` is `Strict::Bool`. | The footer-facts-built entry floors `data[:reasoning] == true`. Outcome-identical: every consumer treats non-true as false (`supported_thinking_levels`' `unless reasoning`, `!!` footer reads). OQ-4-adjacent (its `max_tokens: nil` completeness note is also implemented). `boot_model_ref` gets the same `"no-model"` id fallback as `boot_model_entry` (the footer-less degenerate surface, pinned by frozen launcher_smoke :175–198); marker outcomes identical (the fallback key matches no catalog entry, as nil never did). |
| P0-8 | **`CompactionEntry`/`SessionHeader` recorded camelCase keys.** `transform_keys(&:to_sym)` maps `"firstKeptEntryId"` to `:firstKeptEntryId`, which cannot feed a snake_case `first_kept_entry_id` attribute. | `CompactionEntry` skips transform_keys and `.of` promotes the scanned fields (`type`, `id`, `firstKeptEntryId`→`first_kept_entry_id`, `summary`) string/symbol-tolerantly (the Recorder's in-memory projection is symbol-keyed; loaded entries string-keyed). `SessionHeader` keeps the spec's own `parentSession` spelling (camelCase attribute; transform_keys maps it verbatim). |
| P0-9 | **`ResolvedSettings.context_window` is the FILE tier only** — per B2's own enumeration ("the file-tier context window via `Schemas::Settings.context_window_value`"); the env tier (`<IDENTITY>_CONTEXT_WINDOW`) and the model/registry tiers stay in `Settings.resolve_context_window`, which needs the chat model. `from_load` calls today's exact helpers (`Settings.resolve_setting`, `resolve_thinking_level`, `selected_tools`, `compaction_kwargs`) so each key's arithmetic is the production table, not a re-derivation. | Implemented as stated; pinned per precedence row (env-only/file-only/default-only/env+file/all/none) in `test/shapes_test.rb`. |
| P0-10 | **`context_entries`' kept-entry match stays a raw `entry["id"]` read.** Riding `CompactionEntry` wraps for the KEPT match would change outcomes (non-compaction entries never wrap, but today's match is type-agnostic; and a nil `firstKeptEntryId` vs a nil wrap would false-match). The no-aliasing gate greps only `["message"]` in session.rb — `entry["id"]`/`entry["type"]` remain legal. | Compaction DETECTION rides the wrap (per B3); kept-entry matching keeps today's exact raw compare against `compaction.first_kept_entry_id`. |
| P0-11 | **`print.rb`** — the one-line touch is the `:65` kwarg default (`Settings::DEFAULTS.fetch("thinkingLevel")` → `Settings::DEFAULT_THINKING_LEVEL`). Verified diff = 1 line. `Settings.resolve_thinking_level` (settings.rb's own domain) keeps its `DEFAULTS.fetch` — the gate greps only chat.rb/print.rb, and B2 names only those four sites. | Done. |

Also verified live before writing code (Grounds §3 idiom list, all green on dry-struct 1.8.1 / dry-types 1.9.1 / ruby 4.0.7): declaration-order `to_h`; string-keyed input raising by default + `transform_keys(&:to_sym)`; unknown-key tolerance; `attribute?` omission vs explicit-nil type-check; `Hash.map` application (unfrozen result — inner tables frozen explicitly); sum types inside map values; coercing `Constructor` types; nested `Array.of(Model)`; `MissingKeyError`/`SchemaError` surfacing as `Dry::Struct::Error`.

## Deliverables

### B1 — the Model family (`lib/tart/shapes/model.rb` + models.rb + consumers)
- `Shapes::Model` — attributes IN ORDER `id, name (Strict::String), reasoning (Strict::Bool), context_window, max_tokens (Strict::Integer.optional), thinking_level_map (Strict::Hash.map(Strict::Symbol, Strict::String | Strict::Nil).optional), provider (Strict::String)`; `to_h` pinned == the merged `build_model.merge(provider:)` hash, key order included (`test/shapes_test.rb#test_model_to_h_is_todays_entry_hash_key_order_included`).
- `Shapes::Provider` (`name/base_url/api_key/api` `Strict::String.optional`, `models` `Strict::Array.of(Model)`), `Shapes::ModelRef`, `Shapes::ThinkingFacts`.
- `Models.build_providers`/`build_model(model, provider:)` construct the structs (provider key feeds `Model#provider`); `Config` keeps its `::Struct` shell; `#model_entries` flat-maps `provider.models` (typed path); `#resolve`/`#provider` return typed shapes with the exact match table (canonical/scoped/bare, ambiguity = no match); `Models.resolve_boot_model` → `Shapes::ModelRef` (same precedence, settings-tier reads keep the merged Hash); `Settings.thinking_facts` → `Shapes::ThinkingFacts` (catalog-first/known-tables-second unchanged). Legacy-compat duck per P0-1a.
- Consumers migrated: `bin/tart` (`boot.provider`/`boot.id`, `provider&.api_key`/`&.base_url`, `facts.reasoning`/`facts.thinking_level_map`, session-env readers `.provider`/`.id`), chat.rb (`apply_model_selection` reads `entry.id/.provider/.context_window`; `@runtime_model` holds the struct; `boot_model_entry` builds a `Shapes::Model` with `max_tokens: nil` (OQ-4) and reasoning floored (P0-7); `boot_model_ref` builds a `Shapes::ModelRef`), model_menu.rb (rows built FROM the struct, `ref_key` ducks Model/ModelRef/legacy refs). commands.rb untouched (pass-through).

### B2 — resolved settings + typed tables (`lib/tart/shapes/settings.rb` + settings.rb + consumers)
- `Shapes::ResolvedSettings.from_load(settings_or_result, identity:, env: ENV)` — strict where resolution guarantees the class (`identity`, `thinking_level`, `context_window` file-tier, `default_tools`), `Nominal::Any` for the flows-through scalars (`default_model/default_provider/api_base/api_key`), `compaction` → `Shapes::CompactionSettings` (`attribute?` present-keys slice). Outcome table + malformed flows-through rows pinned (incl. `"contextWindow": "abc"` → nil, `"defaultModel": 5` verbatim).
- Typed constants in settings.rb via `Shapes::Types` map types, contents byte-identical (pinned key-for-key), inner maps frozen; `DEFAULT_THINKING_LEVEL = Shapes::Types::Strict::String["medium"]` single-sources `DEFAULTS["thinkingLevel"]`; chat.rb's three sites (:1733/:1768/:1942 area — `cycle_thinking_level`, `thinking_menu_items`, `default_thinking_level`) and print.rb's fourth read the constant.
- Consumed at the launcher: print_mode + interactive construct it once after identity resolution; `require_api_key`'s apiKey tier, `footer_data`'s legacy boot shape + level, `build_chat`'s api tiers read struct attributes. `Result#settings`, the Settings helpers' signatures, and the I43 no-filter pin untouched.

### B3 — session-entry typed views, READ path only (`lib/tart/shapes/session.rb` + agent/session.rb + chat.rb)
- `Shapes::MessageEntry` (`transform_keys(&:to_sym)`, type enum, role promoted from the body at construction, open `message` Hash) and `Shapes::CompactionEntry` (nominal scan fields) with `.of(raw)` = constructor inside `rescue Dry::Struct::Error → nil`; `Shapes::SessionHeader` (strict type/id, nominal cwd/version/timestamp/parentSession, discovery readers); `Shapes::ContextMessage` (P0-2 design).
- The three projections return `Shapes::ContextMessage`; `context_messages` applies `.to_h` at the gem seam (output shape pinned unchanged — session_test/e2e pins untouched and green); `message_entry_with_role?`, `preview`, `context_entries`' scan, `read_header` (→ `Shapes::SessionHeader`, OQ-5 with the P0-1c discovery readers), chat.rb's `resume_session` all ride the wraps.
- The Recorder write path, the three entry factories, `entry_line`, and the fork copy stay Hash literals — SESSION_GOLDEN_OK proves the bytes.

### Dependency changes
`tart.gemspec` gains `spec.add_dependency "dry-struct", "~> 1.8"` + `spec.add_dependency "dry-types", "~> 1.9"` (production, with the I43-style comment); `Gemfile.lock` regenerated — diff purely additive (dry-struct 1.8.1, its ice_nine dep, checksums). No other gemspec change; no `required_ruby_version` change.

## Test surgery table (every re-pinned line, old → new)

| File:line (base) | Old | New |
|---|---|---|
| models_test :69–70 | `assert_equal ({provider:, …7-key hash}), entry` | same expected vs `entry.to_h` (+ message) |
| models_test :71–72 | `config.provider("glm").fetch(:base_url)` / `.fetch(:api_key)` | `config.provider("glm").base_url` / `.api_key` |
| models_test :122–137 | `catalog` fixture with raw-hash providers/models | struct-built (`Shapes::Provider.new` + `Shapes::Model.new`) |
| models_test :138–140 | `catalog.resolve(…).fetch(:provider)` / `.fetch(:name)` | `.provider` / `.name` |
| models_test :157/:162/:166/:172/:175/:180/:186/:192/:197 | `assert_equal ({provider:, id:}), boot` (hash) | `assert_equal ({provider:, id:}), boot.to_h` (ModelRef) |
| models_test :213/:219/:349 | `entry[:thinking_level_map]` / `model_entries.first[:thinking_level_map]` | `entry.thinking_level_map` / `.thinking_level_map` |
| schemas_test :69–74 | `assert_equal({…entry hash…}, config.model_entries.first, …)` | same vs `config.model_entries.first.to_h` |
| settings_test :347–353 | `entry = {id: "m", reasoning: false, thinking_level_map: {…}}`; `facts[:reasoning]`; `facts[:thinking_level_map]`; `entry[:id]` | `Shapes::Model.new(id: "m", name: "m", …)` full construction; `facts.reasoning`; `facts.thinking_level_map`; `entry.id` (same for the third facts test's `glm[:…]` reads) |
| session_test :175–179 | `projected[:role]` / `projected[:content]` | `projected.role` / `projected.content` |
| session_test :189–191 | `entry_to_context_message(JSON.parse(JSON.generate(entry)))[:content]` | `….content` |
| chat_test :2245–2254 | `model_catalog` fixture raw hashes | struct-built providers/models |
| chat_test :2406–2413 | `mock_native_catalog` fixture raw hashes | struct-built |

Additive only elsewhere: `test/shapes_test.rb` (new, 20 tests) and `test/session_test.rb` (+4 tests: wrap tolerance rows on the real load path, `context_messages` hash-shape pin, `read_header` struct pin, placed before `private`). Frozen files: ZERO diff (verified `git status` — only the declared set).

## Verification output (exact, per repo, this worktree)

| Gate | Result |
|---|---|
| `bundle install --quiet && bundle exec rake` | **exit 0 — `846 runs, 3641 assertions, 0 failures, 0 errors, 1 skips`** (base: 823/3511/0/0/1 — the same pre-existing opt-in LiveRunTest skip; run count +23 with the new pins) |
| `bundle exec ruby bench/seam_bench.rb` (tail) | **exit 0 — `SEAM_BENCH_OK`** |
| s1_text_turn … s10_editor_wrap → `tmp/parity-gate-s1…s10` (cold, canonical short dirs) | **all exit 0** |
| `s1_tart.yml` → `tmp/parity-gate-s1tart` + summary check | rig exit 1 (by design; gate accepts ≤1) — **`TART_MODE_OK`** |
| `tool-pending-probe --gate --out tmp/i44-tp` | **exit 0 — `TOOL_PENDING_GATE_OK`** |
| `user-bash-stream-probe --gate --out tmp/i44-ubs` | **exit 0 — `USER_BASH_STREAM_GATE_OK`** |
| session-golden | **exit 0 — `SESSION_GOLDEN_OK`** — all six frozen digests exact: plain `928183de…`, plain_context `d3c1574f…`, plain_roles `[:user, :assistant, :tool, :assistant]`, primary `cb29e42e…`, forked `3a5f6d60…`, context `f75f99b4…`, fork_roles `[:user, :user]` |
| deps-shapes | **exit 0 — `DEPS_SHAPES_OK`** |
| shapes-presence | **exit 0 — `SHAPES_OK`** (all 10 classes + `Shapes::Types` defined at `Tart::Shapes`; `test/shapes_test.rb` present) |
| no-aliasing | **exit 0 — `NO_ALIASING_OK`** (all eight grep sections clean, including comments) |
| scope (`git status` vs frozen base; never committed) | working tree = exactly the declared 21-file set; no schemas/tools/mcp/agent-core/compaction/commands file, no frozen test file, no rig file |
| wire-bodies (see Residuals W-1) | tools digest **`7360fd1e…` == the frozen pin (MATCH)**; s1 request-body digest = `6323a1b6…` in THIS worktree — byte-IDENTICAL to base run in this same worktree (control executed via `git stash`); the frozen `2ece7d4b…` literal is worktree-path-bound (below) |

Wire-bodies evidence detail: my tree is deterministic across two runs (`6323a1b6…` twice). The base control in this worktree produces the SAME `6323a1b6…` after the gate's exact normalization — i.e. ZERO wire bytes moved base→shapes. The pin literal does not reproduce even at base here because the rig launches tart at `<worktree>/tmp/i44-wire/run-1/sandbox/tart` (a `tart` SUBDIRECTORY of the sandbox), so the system prompt's `<cwd>` embeds the absolute worktree PREFIX (`…/build/I44-dry-rb-shapes-shapes/wt/<SBX>/tart`) which the baked `gsub("tmp/i44-wire/run-1/sandbox", "<SBX>")` cannot absorb. The pin is reproducible only at the capture-time checkout path. Per the standing rule the literal was NOT adjusted; the judge's run on the integrated tree at the canonical path decides.

## Residuals / risks

- **W-1 (wire-body pin, environment-bound).** As above: base-parity proven byte-for-byte in-environment; the pin literal itself needs the canonical checkout path. No byte moved from base (the binding constraint).
- **W-2 (legacy-compat shims at four frozen seams).** P0-1: `Models::Config` ducks provider values (raw-hash providers yield today's raw merged-hash entries — the typed path is everything via `Models.load`); `ModelMenu.model`/`ref_key` duck entry/refs; `SessionHeader` carries raw-hash discovery readers; `footer_data`'s `resolved:` kwarg optional. Each is the minimal shim that keeps a frozen pin green; each documented in-code; production paths are fully typed.
- **W-3 (ModelRef strictness).** P0-6: a malformed `defaultModel`/`defaultProvider` FILE value crashes the boot at the ModelRef construction where it used to ride deeper. Env/catalog tiers unaffected.
- **W-4 (behavior-neutral micro-deltas, outcome-identical).** `boot_model_entry` reasoning nil→false (P0-7); `boot_model_ref` id fallback `"no-model"` for footer-less surfaces (matches no catalog entry, as nil never did); `SESSION`/`PRINT` env `MODEL` reads the struct id (never nil in launcher-wired runs); the footer-view map overlay now always rides a switch (structs always carry the key; today's `.key?` check only differed for the direct-keyword-hash switch path whose fixtures carry no composed footer map — outcome-identical on the whole suite).
- **W-5 (ContextMessage design).** P0-2/P0-3: `to_h` override pins the coerced recorded body (recorded order); content constructor is nominal-with-nil→"" (no new raises). `missing.content` reads nil when the key was absent (the projection hash still gains `content: ""` last) — no consumer reads the attribute on that path.
- **W-6 (pre-existing, NOT this iteration's).** `launcher_smoke_test#test_footer_data_clamps_the_boot_level_but_keeps_the_badge_source_raw` FAILS AT BASE when `<IDENTITY>_MODEL` is unset in the shell (verified via `git stash`: base run = same 1 failure; the legacy footer boot id defaults to the glm id whose known map floors nothing, vs the test's map-less expectation). The space's shell env (`PI_MODEL=glm-5.3-flash PI_PROVIDER=zai`) is the environment the suite is green in — both at base and with this diff (846/3641/0/0/1). Reported for the judge; no action taken.

STATUS: COMPLETE_WITH_CONCERNS

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section dry-rb-shapes verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify dry-rb-shapes`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
