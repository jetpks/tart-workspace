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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section dry-rb-shapes specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision dry-rb-shapes`
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
`architect rehearse dry-rb-shapes` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze dry-rb-shapes` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse dry-rb-shapes` — before the freeze, while
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
subsection per lane. A copy is written to build/I44-dry-rb-shapes-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section dry-rb-shapes prompt --append --lane <lane> --from build/I44-dry-rb-shapes-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I44-dry-rb-shapes-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence dry-rb-shapes --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
