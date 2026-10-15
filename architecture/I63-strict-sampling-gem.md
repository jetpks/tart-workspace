# I63: strict-sampling-gem

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**The defect (owner live-run, root-caused 2026-10-15; `problems.md` @ 1b69ddb).**
A live tart session ran `architect looplog 2>&1 | head -20` and hung forever —
looplog is follow-forever and the quiescent space never produces 20 lines. The
first-blush theory ("tart's bash tool lacks pi's default timeout") is FALSE:
neither harness has a default bash timeout (pi `resolveTimeoutMs(undefined)`
→ undefined, verified in installed 1.1.0/1.2.0 and `repos/pi`; empirical pi-SDK
`sleep 320` with no timeout ran to 320.0s). The real parity gap: **pi's
constrained-sampling (strict tools) wire layer is unimplemented in
tart/fast-llm.** pi tags its bash tool `constrainedSampling {type:"json_schema",
strict:"prefer"}`; zai glm-5.3's compat carries `supportsStrictMode: true`
(`repos/pi/packages/ai/src/providers/data/zai.json` — both glm-5.3 compat
shapes), so pi's `makeStrictJsonSchema` rewrites every declared tool schema to
force property emission (ALL properties required; optionals wrapped
`anyOf:[property,{type:"null"}]`; `additionalProperties:false`) and `strict:
true` rides the tool — glm MUST emit `timeout` on every bash call. A/B
evidence: same model+command via `pi -p` emitted `timeout:60`, died at 60s, and
the model recovered with bounded re-runs (140s total); the live tart session
(2026-10-15T22-13-25) omitted `timeout` on 8/8 bash calls. Today the gem sends
parameters VERBATIM with no strict key (protocol.rb `apply_tools` :72-87, by
design since I51) and the Tool DSL has no constrained-sampling seam. Blast
radius: every optional parameter of every tool on strict-capable providers
(read `offset`/`limit`, …), not just bash `timeout`. This iteration is the
fix's substance on the gem side; BRIEF §7.8 exact-parity bar, §8
itemize-and-defend for every deviation.

**The pi source of record (`repos/pi` @ `f1b2e77f5`; the installed
pi-coding-agent 1.2.0 dist verified identical for this surface during
root-causing).**

- `packages/ai/src/api/constrained-sampling.ts` (entire file, 298 lines — the
  JSON-schema half; the grammar half is OUT, see Boundaries):
  - `UNSUPPORTED_STRICT_SCHEMA_KEYS` — exactly 20 keys, frozen order: `$ref`,
    `$defs`, `definitions`, `allOf`, `oneOf`, `patternProperties`,
    `dependentSchemas`, `dependencies`, `unevaluatedProperties`,
    `propertyNames`, `contains`, `prefixItems`, `not`, `if`, `then`, `else`.
    A node carrying ANY of them (value `!== undefined`) throws
    `<key> schemas are unsupported` (first present key in list order).
  - `schemaAllowsNull(schema)` — true when `type` is/contains `"null"`, or
    `const === null`, or `enum` (array) contains `null`, or `anyOf` (array)
    has any variant that allows null.
  - `makeJsonSchemaNodeStrict` (recursive, IN PLACE on the cloned node;
    check order is observable through which message throws first): (1) a node
    that is not a plain object (boolean schemas, null, arrays, scalars)
    throws `boolean schemas are unsupported`; (2) unsupported keys (above);
    (3) the optional provider-keyword hook `isUnsupportedKeyword` (NOT
    ported — pi's own call site passes none; see Specification R2);
    (4) `anyOf` must be a non-empty array (else `anyOf must contain at least
    one schema`), every variant must be NON-structured (`isStructuredSchema`:
    type includes `"object"` or `"array"`, or `properties`/`items` defined —
    else `object and array unions are unsupported`) and recurses; (5) `items`
    must not be an array (else `tuple schemas are unsupported`) and recurses;
    (6) `properties` defined without `type === "object"` throws `properties
    require type object`; non-object-typed nodes RETURN here; (7)
    `additionalProperties` defined and not `false` throws `schema-valued or
    true additionalProperties is unsupported`; (8) `properties` defined and
    not a plain object throws `object properties must be a schema map`;
    (9) `required` defined and not an all-string array throws `object
    required must be a string array`; (10) every `required` entry must name a
    property (else `required contains an unknown property`); (11) per
    property: recurse FIRST, then if the property is not required and does
    not allow null, wrap it `{"anyOf": [property, {"type": "null"}]}`
    (reassignment keeps the key's hash position in both JS and Ruby);
    (12) finally `required` = ALL property names (existing key keeps its
    position) and `additionalProperties = false` (absent key appends).
  - `makeStrictJsonSchema` — `structuredClone` FIRST (the caller's schema
    object is NEVER mutated), then a non-plain-object root throws `root
    schema must have type object` (note: at ROOT the message differs from
    the nested `boolean schemas…` arm), node-strict recursion, then the
    root's `type` must equal `"object"` (same message).
  - `resolveJsonSchemaStrictSampling(tool, supportsStrictMode)` — config
    absent or not `json_schema` → undefined; on a strict-capable provider:
    try the strict rewrite → `true`; on `UnsupportedStrictJsonSchemaError`:
    `strict !== "require"` → undefined (silent loose fallback), `require` →
    raises `Tool "<name>" requires JSON-schema constrained sampling, but
    <reason>.` (the inner reason has no trailing period; the template adds
    it); on a non-strict provider: `require` → raises `Tool "<name>"
    requires JSON-schema constrained sampling, but strict tools are
    unsupported.` (trailing period), else undefined. Only the unsupported-
    schema class is caught — any other error propagates.
- `packages/ai/src/api/openai-completions.ts` `convertTools` :1483-1518: per
  function tool, `strict = resolveJsonSchemaStrictSampling(tool,
  compat.supportsStrictMode !== false)`; `parameters = getJsonSchemaToolParameters`
  (strict === true → the strict rewrite, else the declared schema VERBATIM);
  the function object carries `strict: strict ?? false` — the EXPLICIT key
  on EVERY function tool when the provider supports strict mode (declared →
  `true`, undeclared/loose → `false`), and NO strict key ever otherwise
  ("Some reject unknown fields"). Key order in the function object: name,
  description, parameters, strict.
- `detectCompat` :1670-1680: default `supportsStrictMode: false` —
  "OpenAI compatibility alone does not imply strict JSON-schema tool
  support"; `getCompat` :1334 merges `model.compat.supportsStrictMode ??
  detected.supportsStrictMode` (the catalog declares it per model; zai's
  glm-5.3 compat shapes carry `true`).
- `packages/ai/src/types.ts` :736-754: `ConstrainedSamplingConfig` = `{
  type: "json_schema", strict: "prefer" | "require" }`; `Tool.
  constrainedSampling?: false | ConstrainedSamplingConfig` (optional,
  explicit `false` allowed).
- The four core tools pi tags (`bash.ts:260`, `read.ts:101`, `edit.ts:156`,
  `write.ts:57` — all `{type:"json_schema", strict:"prefer"}`) are ENTRY 2's
  tart-side consumption, NOT this iteration's.

**Fresh evidence captured this session (the two frozen wire fixtures).** The
I51 capture discipline re-run hermetically against the installed pi-ai dist
(1.2.0 — same compiled-wire class the parity rig runs; driver at
`tmp/i63-spec/capture/CAPTURE-STRICT.mjs`, modeled line-for-line on
`spec/fixtures/wire/CAPTURE.mjs`, mock provider + explicit
`compat.supportsStrictMode: true`, the same §12.3 read tool):
- `zai_strict_tool` — read declared `{type:"json_schema", strict:"prefer"}`:
  wire tools = `[{"type":"function","function":{"name":"read","description":
  "Read file contents.","parameters":{"type":"object","required":["path",
  "offset"],"properties":{"path":{"type":"string"},"offset":{"anyOf":[{"type":
  "number"},{"type":"null"}]}},"additionalProperties":false},"strict":true}}]`
  — SHA256 `d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c2410d65ce824a8`.
- `zai_strict_undeclared` — same dialect, undeclared tool: parameters
  VERBATIM (`required:["path"]`, bare `offset`), `"strict":false` — SHA256
  `fead3755e34689d502cbb865d6d424ccc84b4453d8724aa8fee713f9516a60c9`.
Fixture bytes live at `tmp/i63-spec/capture/out/` (committed by the builder
into `spec/fixtures/wire/` with the provenance driver).

**Gem seams at base (fast-llm `main` @ `6ceba1f`; base suite measured this
session: 174 examples, 0 failures).**

- `lib/fast/completions/dialects.rb` — the CLOSED 13-key `VOCABULARY`
  (insertion order = canonical `to_h` order), defaults = the plain arm,
  unknown keys/values raise `ArgumentError` at declaration; the shipped trio
  `:zai`/`:deepseek`/`:fireworks` as declarations; `:zai` carries the I46
  five-key subset + store suppression. `supports_strict_mode` enters the
  vocabulary (default `false`, boolean) as the 14th key; `:zai` gains
  `supports_strict_mode true`; `:deepseek`/`:fireworks`/the default stay
  false.
- `lib/fast/completions/tool.rb` — class-level DSL `description` /
  `tool_name` / `parameters` (default `{"type"=>"object","properties"=>{}}`);
  gains `constrained_sampling` (default nil; `false` or the mirrored
  `{type:"json_schema", strict:"prefer"|"require"}` shape; anything else
  raises at declaration time — the fail-loud discipline).
- `lib/fast/completions/protocol.rb` `apply_tools` :72-87 — the wire seam;
  today's §9.8 comment ("parameters VERBATIM — the consumer's schema is the
  bytes") is AMENDED deliberately, not deleted: verbatim stays the default
  for undeclared tools and non-strict dialects.
- `lib/fast/completions/errors.rb` — the §8 tree; two new classes (the
  internal unsupportable-schema raise and the public require-raise, R3).
- Facade `lib/fast/completions.rb` — one `require_relative` for the new
  `constrained_sampling.rb` (pi's file name; the JSON-schema half only).
- Gate homes: `spec/fast/completions/{protocol,wire_parity,tool,dialects}
  _spec.rb` + a NEW `constrained_sampling_spec.rb`; `docs/reference/
  {dialects,tools,errors}.md`; `CHANGELOG.md` (Unreleased — 0.3.0 is the
  released head; 0.4.0 is cut by the OWNER at landing, never in-lane).

**Token-collision greps at base (house convention; all RED as required):**
`strict` in protocol_spec.rb — 0 matches; `supports_strict_mode` in
dialects_spec.rb — 0; `constrained` in tool_spec.rb — 0; `zai_strict` in
wire_parity_spec.rb — 0; `constrained` in CHANGELOG.md — 0;
`supports_strict_mode` under docs/ — 0; `ConstrainedSamplingError` in
errors.md — 0; `^## Unreleased` in CHANGELOG.md — 0. Measured `-e` forms at
base all report `0 examples, 0 failures` (the `[1-9][0-9]* examples?, 0
failures` requirement makes them RED); a missing spec file also reports 0
examples (I61 lesson). `-O /dev/null` still resolves `require
"fast/completions"` (the gemspec path dep puts lib/ on the load path —
verified this session).

**README constraint (I53 owner-prose gate, `docs_links_spec.rb`):** the gem
README is preserved against the byte-frozen `owner-4736ddc.md` fixture —
removals outside the Error-taxonomy section and non-definition additions
beyond the one ≤6-line errors pointer FAIL the suite. README.md carries
"vocabulary is closed (13 keys)" at :86 and CANNOT be edited in-lane; it
stays untouched (the plan's gate homes list excludes it). The stale count is
a DECLARED residual: the canonical inventory is `docs/reference/dialects.md`
(13 → 14 there), and the README count is the owner's next-pass call.

**Previous handoff honored** (`notes/spec-digest-20261015T195930Z.md`, I62):
token-collision grep BEFORE freezing any `-e` gate (done above); `-O
/dev/null` for single-spec gates; docs-gate markers single-line-safe;
freeze mechanics (commit space.yaml first, clean arch file → empty freeze
commit, freeze_sha = HEAD); `architect verify` materializes worktrees and
the lane integration_branch must be hand-set to `main` for fast-llm
(I53/I61/I62 precedent); the rehearsal's scope-asymmetry advisory
is possible when a gate word pre-exists elsewhere ("strict" today appears
ONLY in lib comments — client.rb:254 (I62's x-should-retry commentary) and
types.rb:16 ("restricted") — never in a spec file).

## Specification

### Objective

Port pi's JSON-schema constrained-sampling machinery into the fast-completions
gem so the wire layer can send strict-mode tool schemas (the fix's substance
for `problems.md` @ 1b69ddb): a tool declared `constrained_sampling
{type:"json_schema", strict:"prefer"|"require"}` on a dialect declaring
`supports_strict_mode` ships the STRICT REWRITE of its parameters (all
properties required; non-required properties not allowing null wrapped
`anyOf:[property,{type:"null"}]`; `additionalProperties:false`) with
`"strict":true` on the function object; every OTHER function tool on a
strict dialect ships `"strict":false` with parameters verbatim; tools on
non-strict dialects carry NO strict key ever, parameters verbatim — the
today-wire. "prefer" falls back silently to loose when the schema is
unsupportable or the dialect lacks strict support; "require" raises with
pi's exact message bytes. BRIEF §7.8 exact-parity bar; §8 itemize-and-defend.

### The ported contract (one lane)

**D1 — Dialect vocabulary (dialects.rb).** `supports_strict_mode` enters the
CLOSED vocabulary as the 14th key (appended after `session_affinity_format`):
default `false`, free boolean, same declaration/DSL/validation machinery
(unknown keys still raise `ArgumentError` at declaration time — the key is IN
the vocabulary, not around it). `to_h` gains the key in canonical position
(14 keys). The shipped `:zai` declaration gains `supports_strict_mode true`
(pi's zai glm-5.3 compat `supportsStrictMode:true`); `:deepseek`,
`:fireworks`, and the anonymous default stay `false` (pi detectCompat's
default: OpenAI compatibility alone does not imply strict support).

**D2 — Tool DSL (tool.rb).** A `constrained_sampling` class-level declaration
mirroring pi's `Tool.constrainedSampling?: false | {type:"json_schema",
strict:"prefer"|"require"}`:
- default `nil` (undeclared — today's behavior, no strict participation);
- `constrained_sampling false` — the explicit opt-out, wire-equivalent to nil;
- `constrained_sampling({"type" => "json_schema", "strict" => "prefer"})` (or
  `"require"`) — string keys mirroring pi's shape, readable from instances
  and classes like `parameters`;
- ANY other shape raises `ArgumentError` AT DECLARATION TIME — unknown
  `type` (including `"grammar"` — the named exclusion, nothing
  half-anticipates grammar), unknown `strict` value, missing keys,
  non-Hash/non-false values. Fail loud, never silently mistranslate.

**D3 — The rewrite engine (NEW lib/fast/completions/constrained_sampling.rb;
facade gains ONE `require_relative "completions/constrained_sampling"`
immediately before the protocol require).** A module port of pi's
JSON-schema half, semantics frozen to Grounds' reading (check order =
throw-order observability):

- `UNSUPPORTED_STRICT_SCHEMA_KEYS` — pi's 20 keys, frozen order.
- `make_strict_json_schema(schema)` — DEEP-COPY FIRST (the caller's schema
  — nested included — is never mutated); root not a Hash → raise `root
  schema must have type object`; node rewrite; root `type` must equal
  `"object"` → else the same message. Returns the rewritten copy.
- `make_json_schema_node_strict(node)` — pi's recursion exactly: non-Hash
  node → `boolean schemas are unsupported`; first present unsupported key
  (list order) → `<key> schemas are unsupported`; `anyOf` non-array/empty →
  `anyOf must contain at least one schema`, structured variant (type
  includes "object"/"array", or `properties`/`items` present) → `object and
  array unions are unsupported`, variants recurse; `items` array → `tuple
  schemas are unsupported`, else recurses; `properties` without
  `type == "object"` → `properties require type object`, non-object nodes
  return; `additionalProperties` present and not `false` → `schema-valued
  or true additionalProperties is unsupported`; `properties` not a Hash →
  `object properties must be a schema map`; `required` present and not an
  all-String array → `object required must be a string array`; a `required`
  entry naming no property → `required contains an unknown property`; per
  property recurse-then-wrap (non-required and not null-allowing →
  `{"anyOf"=>[property, {"type"=>"null"}]}`, key position preserved);
  finally `required` = all property names, `additionalProperties` = false.
  `schema_allows_null`: `type` is/contains "null", `const` nil, `enum`
  includes nil, or any `anyOf` variant allows null.
- `resolve_json_schema_strict_sampling(tool, supports_strict_mode)` →
  `true` (strict) or `nil` (loose): config nil/false or non-json_schema →
  nil; strict dialect: rewrite succeeds → true, unsupportable →
  `strict != "require"` ? nil : raise `ConstrainedSamplingError` with
  `Tool "<name>" requires JSON-schema constrained sampling, but <reason>.`
  (pi's template: inner reason has no trailing period, the template adds
  it); non-strict dialect: `require` → raise `ConstrainedSamplingError`
  `Tool "<name>" requires JSON-schema constrained sampling, but strict
  tools are unsupported.`; prefer → nil. Only the unsupportable-schema
  class is caught — any other error propagates (pi's rethrow).
- Errors (errors.rb): `UnsupportedStrictJsonSchemaError < Error` — the
  internal raise (pi's inner reasons verbatim), never escapes the
  resolver; `ConstrainedSamplingError < Error` — the public require-raise.
  Message bytes are the parity observable (English literals identical to
  pi's).

**D4 — The wire seam (protocol.rb `apply_tools`).** Per function tool:
`strict = resolve_json_schema_strict_sampling(tool, dialect.
supports_strict_mode)`; `parameters` = strict == true ? the rewrite : the
declared schema VERBATIM (object-identity emission — today's `equal?` pin
holds for every non-strict path); the function object gains `"strict" =>
(strict || false)` IMMEDIATELY AFTER `parameters` (pi's key order: name,
description, parameters, strict) when `dialect.supports_strict_mode` —
declared-strict `true`, undeclared/loose `false` — and NO strict key ever
otherwise. The §9.8 comment is AMENDED deliberately (strict rewrite +
strict-key emission on strict dialects; VERBATIM remains the discipline for
undeclared tools and non-strict dialects) — never deleted. `tool_stream`,
the `tools: []` fallback, and declaration order are untouched. Nothing else
in protocol.rb/codec/client/chat changes beyond what this seam needs.

**D5 — Wire-parity fixtures (wire_parity_spec.rb + spec/fixtures/wire/).**
The two fresh pi captures (Grounds) land as `zai_strict_tool.json` +
`zai_strict_undeclared.json` (bytes at `tmp/i63-spec/capture/out/`, provenance
driver `CAPTURE-STRICT.mjs` committed beside `CAPTURE.mjs`); the scenario
table gains a `StrictReadTool` (same §12.3 parameters +
`constrained_sampling` declaration) and the two zai-strict model rows
(dialect `:zai`, thinking high); the FROZEN_DIGESTS table grows to 13
(`zai_strict_tool` → `d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c
2410d65ce824a8`, `zai_strict_undeclared` → `fead3755e34689d502cbb865d6d424
ccc84b4453d8724aa8fee713f9516a60c9`); the fixture-fidelity example re-pins
11 → 13 (the count line is the spec's own bookkeeping). The existing 11
scenarios stay byte-identical (no regression to fireworks/deepseek/openai
wire — the non-strict path emits no strict key).

**D6 — Unit gate (NEW spec/fast/completions/constrained_sampling_spec.rb).**
Pi-derived fixtures pin the rewrite + resolution semantics: the full rewrite
on a nested schema (required-before-properties key ordering, nested objects,
arrays via items, anyOf passthrough with null-variant, enum/const null
allowance); every throw class with pi's EXACT message bytes (boolean schema,
each unsupported-key family, structured anyOf, tuple items, properties
without type object, truthy additionalProperties, non-map properties,
non-string-array required, unknown required, root-not-object ×2); prefer →
silent nil on unsupportable schema AND unsupported dialect; require → both
message templates verbatim; the no-mutation property (declared parameters
deep-equal a pre-call snapshot AFTER a strict build; the emitted strict
parameters are NOT the declared object); non-json_schema/false/nil configs
resolve nil.

**D7 — Docs + CHANGELOG.** `docs/reference/dialects.md`: 13→14-key vocabulary
text + table row (`supports_strict_mode | false | boolean`) + the `:zai`
declaration block gains the key + a strict-mode paragraph (default false =
pi's detectCompat; the shipped :zai mirrors glm-5.3 compat).
`docs/reference/tools.md`: the DSL table gains the `constrained_sampling`
row; the "Parameters are emitted VERBATIM" section is AMENDED deliberately —
verbatim remains the default; a strict-declared tool on a strict dialect
ships the forced-emission rewrite with `strict:true`, undeclared tools
`strict:false`, non-strict dialects no key and verbatim (the §9.8-parallel).
`docs/reference/errors.md`: ONE taxonomy row for `ConstrainedSamplingError`
(strict-"require" tools whose schema cannot be strict-rewritten, or require
tools on dialects without `supports_strict_mode`). `CHANGELOG.md`: a NEW
`## Unreleased` section (0.3.0 is the released head) carrying the
strict-sampling bullets. `gems/completions/README.md` stays UNTOUCHED (the
I53 owner-prose gate forbids the edit — its "13 keys" line is a declared
residual, R8).

**D8 — Re-pins (itemized, not silent).** `dialects_spec.rb`: the two
"13-key" strings (header comment + the CLOSED-vocabulary example
description) become 14-key; the defaults example gains
`supports_strict_mode` false; the `:zai` describe block gains the
`supports_strict_mode true` assertion. `protocol_spec.rb`'s existing VERBATIM
example (§9.2) keeps holding — its scope is the undeclared tool; new
strict-emission examples (token `strict`) carry the strict cases:
declared-strict → rewrite + `strict:true` (hash key order: parameters then
strict); undeclared on strict dialect → `strict:false`, `equal?` verbatim
identity; declared on non-strict dialect (prefer) → NO strict key, verbatim,
byte-equal to the undeclared build; require-raise surfaces through
`build_request`. Nothing else re-pins.

### Named exclusions (Constraints, itemized)

- NO grammar-constrained sampling: `resolveGrammarConstrainedSampling`,
  grammar tool input buffers, `type:"grammar"` configs (raise at
  declaration, D2), `supportsOpenAIGrammarTools` — nothing in the gem
  half-anticipates grammar.
- NO provider detection/catalog/base-URL logic in the gem — the consumer
  declares via Dialect (standing D2/D4 house rule); `supports_strict_mode`
  is data, not detection.
- NO codec/client/chat/cancellation/types changes beyond `apply_tools`'
  needs; NO version bump or release in-lane (the owner cuts 0.4.0 at
  landing); builders never commit.
- The optional `isUnsupportedKeyword` provider hook is NOT ported (pi's own
  call site passes none; adding it would grow the Dialect vocabulary around
  the closed set). Recorded as R2; if a provider ever needs it, that is a
  future vocabulary decision.

### Output format

The lane reports raw results only: the spec files added/changed with run
counts (examples/failures per file), the full suite line (`bundle exec
rspec` examples/failures/exit), the wire-parity digest table result (13
fixtures pass/fail), the two new fixtures' SHA256s as landed, file list
touched, and the PHASE 0 disagreement table (if any) with file:line cites.

### Tool guidance

- Repo: `repos/fast-llm` (gem `gems/completions`). Suite: `bundle exec
  rspec` from the repo root (174 examples, 0 failures at base `6ceba1f`).
  Single-spec runs: `bundle exec rspec -O /dev/null <spec> [-e "<token>"]`.
- Wire-parity harness: `spec/fast/completions/wire_parity_spec.rb` — the 11
  existing fixtures must stay byte-identical (GREEN at base); the two new
  scenarios reproduce the Grounds digests. The fixture bytes + driver are
  PRE-MADE at `tmp/i63-spec/capture/{out,CAPTURE-STRICT.mjs}` — copy them
  in verbatim; do not re-capture.
- pi source of record: `repos/pi` @ `f1b2e77f5`
  `packages/ai/src/api/constrained-sampling.ts` (JSON-schema half only),
  `openai-completions.ts` convertTools :1483-1518 / detectCompat :1670-1680
  / getCompat :1334, `types.ts` :736-754. Cite line numbers in code
  comments as the existing files do.
- Ruby semantics notes: Hash reassignment preserves key position (the
  wrap/required-assignment ordering mirrors JS objects by construction);
  deep-copy = your deep_dup (frozen string literals dup clean); `nil`
  property values hit the non-Hash node arm (JS `undefined` equivalence).
- Mock server: unchanged this iteration (the strict scenarios replay the
  standard `:stream` script).

### Boundaries

- Lane may touch (repo `fast-llm`): the 18 files of the lanes block below.
  `gems/completions/README.md` is FROZEN (owner-prose gate);
  `spec/fixtures/readme/**`, `docs_links_spec.rb`, `spec/support/
  mock_llm_server.rb`, `codec.rb`, `client.rb`, `chat.rb`, `types.rb`,
  `cancellation.rb`, `sse.rb`, and all of `repos/tart` are out of bounds.
- The existing 11 wire fixtures and their digests are frozen bytes — no
  edits, no re-capture.

### Lane plan

One lane — one seam, one gem, one engine file.

```lanes
- name: strict
  repo: fast-llm
  touch:
    - gems/completions/lib/fast/completions/constrained_sampling.rb
    - gems/completions/lib/fast/completions.rb
    - gems/completions/lib/fast/completions/dialects.rb
    - gems/completions/lib/fast/completions/tool.rb
    - gems/completions/lib/fast/completions/protocol.rb
    - gems/completions/lib/fast/completions/errors.rb
    - gems/completions/spec/fast/completions/constrained_sampling_spec.rb
    - gems/completions/spec/fast/completions/protocol_spec.rb
    - gems/completions/spec/fast/completions/wire_parity_spec.rb
    - gems/completions/spec/fast/completions/tool_spec.rb
    - gems/completions/spec/fast/completions/dialects_spec.rb
    - gems/completions/spec/fixtures/wire/zai_strict_tool.json
    - gems/completions/spec/fixtures/wire/zai_strict_undeclared.json
    - gems/completions/spec/fixtures/wire/CAPTURE-STRICT.mjs
    - gems/completions/docs/reference/dialects.md
    - gems/completions/docs/reference/tools.md
    - gems/completions/docs/reference/errors.md
    - gems/completions/CHANGELOG.md
```

### Effort call

`high` — a byte-parity wire change with a recursive rewrite engine, exact
error-message parity, and frozen fixture digests; not a routine lane.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form. Base = fast-llm `main` @ `6ceba1f`
(base suite measured this session: 174 examples, 0 failures). Measured at
base: `suite`/`parity` GREEN (controls); `strict-wire`, `strict-unit`,
`strict-dialect`, `strict-tool`, `strict-emission`, `docs` RED (0 examples
/ 0 matches — the digest's every-new-gate-RED-at-base convention); `scope`
GREEN (vacuously — the empty diff changes nothing outside the set; it bites
post-lane).

**AC1 — declarations.** `supports_strict_mode` is INSIDE the closed Dialect
vocabulary (14 keys, default `false`, free boolean): unknown dialect keys
still raise `ArgumentError` at declaration time; `to_h` carries the key in
canonical position; the shipped `:zai` declares `true`; `:deepseek`,
`:fireworks`, and the anonymous default are `false`. The Tool DSL declares
`constrained_sampling`: default `nil`; `false` accepted; the mirrored
`{"type"=>"json_schema","strict"=>"prefer"|"require"}` shape accepted,
readable from class and instance; any other shape — including
`type:"grammar"`, unknown `strict`, missing keys — raises `ArgumentError` at
declaration time.

**AC2 — wire emission (byte parity).** Through the public
Chat→Client→Protocol path against the mock, the two fresh pi captures
reproduce BYTE-EXACT (string equality + frozen SHA256):
`zai_strict_tool` = `d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c
2410d65ce824a8` (declared-strict read tool on the zai dialect: parameters
are the strict rewrite — `required` = ALL property names, `offset` wrapped
`anyOf:[{"type"=>"number"},{"type"=>"null"}]`, `additionalProperties:false`
— and the function object carries `"strict"=>true` immediately after
`"parameters"`); `zai_strict_undeclared` = `fead3755e34689d502cbb865d6d424
ccc84b4453d8724aa8fee713f9516a60c9` (same dialect, undeclared tool:
parameters verbatim, `"strict"=>false`). On non-strict dialects NO function
tool ever carries a strict key, parameters verbatim with object identity
(today's `equal?` pin keeps holding for every non-strict path — including
undeclared tools ON strict dialects).

**AC3 — engine semantics (unit).** The rewrite and resolution are pinned by
pi-derived unit fixtures: every recursion rule (anyOf non-empty + variants
non-structured + recurse; items rejects tuples + recurses; nested objects;
`required ⊆ properties`; non-required non-null-allowing properties wrapped
anyOf-with-null; final required=all names + additionalProperties=false);
every unsupportable class raises with pi's EXACT message bytes (boolean
schemas; each unsupported key; structured unions; tuple items; properties
without type object; truthy/schema-valued additionalProperties; non-map
properties; non-string-array required; unknown required; root not type
object — root-level and nested-level arms both); "prefer" resolves loose
(nil) on an unsupportable schema AND on an unsupported dialect; "require"
raises `ConstrainedSamplingError` with BOTH pi templates verbatim; the
declared parameters object is NEVER mutated (deep-equal snapshot after a
strict build; the emitted strict parameters are a different object).

**AC4 — regression bar.** The full gem suite is green; the 11 existing
wire-parity fixtures stay byte-identical with their frozen digests (the
non-strict wire is unchanged — fireworks/deepseek/openai rows).

**AC5 — documented.** `docs/reference/dialects.md` (14-key vocabulary +
table row + :zai block + strict paragraph), `docs/reference/tools.md`
(`constrained_sampling` DSL row + the deliberately AMENDED verbatim
section), `docs/reference/errors.md` (the `ConstrainedSamplingError` row),
and `CHANGELOG.md` (`## Unreleased` + the strict-sampling bullets) all
carry the new surface. `gems/completions/README.md` stays untouched (the
I53 owner-prose gate; its "13 keys" line is the declared residual R8).

**AC6 — scope.** Exactly the declared 18-file touch set (lanes block);
nothing else changes against base `6ceba1f`. The 11 existing fixture JSONs
+ `CAPTURE.mjs`, `README.md`, `docs_links_spec.rb`, and
`spec/support/mock_llm_server.rb` are frozen (byte-identical).

```gates
- id: suite
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: parity
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-wire
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb -e "zai_strict" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-unit
  ac: AC3
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/constrained_sampling_spec.rb 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-dialect
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/dialects_spec.rb -e "supports_strict_mode" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-tool
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/tool_spec.rb -e "constrained" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-emission
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/protocol_spec.rb -e "strict" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: docs
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    grep -q "supports_strict_mode" gems/completions/docs/reference/dialects.md && grep -q "constrained_sampling" gems/completions/docs/reference/tools.md && grep -q "ConstrainedSamplingError" gems/completions/docs/reference/errors.md && grep -q "^## Unreleased" gems/completions/CHANGELOG.md && grep -qi "constrained" gems/completions/CHANGELOG.md && echo STRICT_DOCS_OK
  expect:
    exit_code: 0
    stdout_match: STRICT_DOCS_OK

- id: scope
  ac: AC6
  cwd: repos/fast-llm
  cmd: |-
    git diff --quiet 6ceba1f -- gems/completions/README.md gems/completions/spec/fixtures/wire/CAPTURE.mjs gems/completions/spec/fast/completions/docs_links_spec.rb gems/completions/spec/support/mock_llm_server.rb && ! git diff --name-only 6ceba1f | grep -vE "^(gems/completions/(CHANGELOG\\.md|docs/reference/(dialects|errors|tools)\\.md|lib/fast/completions(\\.rb|/constrained_sampling\\.rb|/dialects\\.rb|/errors\\.rb|/protocol\\.rb|/tool\\.rb)|spec/fast/completions/(constrained_sampling|dialects|protocol|tool|wire_parity)_spec\\.rb|spec/fixtures/wire/(CAPTURE-STRICT\\.mjs|zai_strict_tool\\.json|zai_strict_undeclared\\.json)))$" | grep -q . && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### strict

You are the builder for iteration `strict-sampling-gem` (I63), lane
`strict`. Work ONLY in the provisioned worktree on branch
`lane/I63-strict-sampling-gem-strict` (base fast-llm `main` @ `6ceba1f`);
NEVER commit (the integrator lands your tree), NEVER touch the space repo,
NEVER push. The full iteration contract is the frozen
Grounds/Specification/Acceptance Criteria in this file (verbatim below) —
read them first; this header is the lane's operating brief. You are the
ONLY lane; `repos/tart` is out of bounds entirely (ENTRY 2 consumes your
landed API later).

THE TASK IN ONE PARAGRAPH: port pi's JSON-schema constrained-sampling
machinery (pi `packages/ai/src/api/constrained-sampling.ts` @ `f1b2e77f5`,
the JSON-schema half ONLY) into the gem so the wire layer can send
strict-mode tool schemas: a NEW `constrained_sampling.rb` engine (the
strict rewrite `make_strict_json_schema` / node recursion / `schema_allows_
null` / `resolve_json_schema_strict_sampling`, exact message bytes, deep-
copy never mutating the declared parameters), a `supports_strict_mode`
Dialect vocabulary key (14th, default false; the shipped `:zai` declares
true), a Tool `constrained_sampling` declaration (nil/false/the mirrored
`{"type"=>"json_schema","strict"=>"prefer"|"require"}` shape, fail-loud),
and the `apply_tools` wire seam (declared-strict tool on a strict dialect →
the REWRITTEN parameters + `"strict"=>true` right after `"parameters"`;
undeclared tool on a strict dialect → verbatim + `"strict"=>false`; ANY
tool on a non-strict dialect → NO strict key, verbatim, exactly today's
wire). "prefer" falls back to loose silently; "require" raises with pi's
two message templates verbatim.

PRE-MADE ARTEFACTS (copy, do not re-derive): the two frozen wire fixtures
and their provenance driver already exist in the SPACE at
`tmp/i63-spec/capture/out/zai_strict_tool.json`,
`tmp/i63-spec/capture/out/zai_strict_undeclared.json`, and
`tmp/i63-spec/capture/CAPTURE-STRICT.mjs` — copy them byte-identical into
`gems/completions/spec/fixtures/wire/` (the two JSONs + the driver).
Frozen SHA256s (also in Grounds): `zai_strict_tool` =
`d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c2410d65ce824a8`;
`zai_strict_undeclared` =
`fead3755e34689d502cbb865d6d424ccc84b4453d8724aa8fee713f9516a60c9`.
The captures were recorded hermetically against the installed pi-ai 1.2.0
dist this spec session — if your lane tree disagrees with one BYTE, your
emission is wrong, not the fixture.

FROZEN BEHAVIOR (do not redesign; the frozen sections govern on any
conflict):
- The rewrite's CHECK ORDER is observable through which message throws
  first — port pi's order exactly (Specification D3 enumerates it).
- Message bytes are the parity observable: pi's literals, unchanged
  (including `root schema must have type object` appearing TWICE in pi's
  `makeStrictJsonSchema` for different arms — keep both).
- Verbatim emission keeps OBJECT IDENTITY (`equal?(tool.parameters)`) for
  every non-strict path — the existing protocol_spec pin must keep
  holding; strict-rewrite emission is a DIFFERENT object (deep-copied).
- The strict key sits in the function object AFTER `parameters` (pi key
  order; the fixtures pin it byte-level).
- Nothing outside `apply_tools`' needs changes in protocol.rb; codec/
  client/chat/types/cancellation/sse are out of bounds; the mock server is
  untouched.
- `gems/completions/README.md` is FROZEN (the I53 owner-prose gate
  `docs_links_spec.rb` fails on any edit) — its stale "13 keys" line stays;
  docs land in `docs/reference/*.md` + CHANGELOG's new `## Unreleased`.

BUILD FREEDOM (layout only, behavior frozen): module/method names inside
`constrained_sampling.rb` beyond the frozen API surface, spec example
wording (as long as the `-e` gate tokens `strict`, `supports_strict_mode`,
`constrained`, `zai_strict` each match at least one full example
description in their named spec files), and the deep_dup implementation.

VERIFICATION (run from the repo root, exactly these forms):
- Full suite: `bundle exec rspec` (base: 174 examples, 0 failures — your
  additions grow it; 0 failures must hold).
- Gate forms (frozen in Acceptance Criteria): single-spec with
  `bundle exec rspec -O /dev/null <spec> [-e "<token>"]`; every NEW gate is
  RED at base by design — your lane makes them GREEN.
- Wire parity: the 11 existing fixtures must stay byte-identical (GREEN at
  base); your two new scenarios must reproduce the frozen digests above.

PHASE 0 PROTOCOL: before writing code, read pi's
`constrained-sampling.ts` in full and diff your reading against the frozen
Specification D3. If you believe a frozen claim misreads pi (message bytes,
check order, resolution semantics), STOP, record the disagreement in your
report (file:line cites both sides), implement YOUR reading of pi, and flag
it loudly — pi @ `f1b2e77f5` is the oracle, not this brief. Same for any
gate you believe is vacuous or mis-authored.

REPORT (raw results only, no narrative): spec files added/changed with run
counts; the full suite line; the wire-parity digest table (13 rows,
pass/fail); the two landed fixture SHA256s; file list touched; the PHASE 0
disagreement table if any.

## Builder Report

### strict

# I63 strict-sampling-gem — builder report (REPLACEMENT builder, lane `strict`)

Worktree: `build/I63-strict-sampling-gem-strict/wt` · branch `lane/I63-strict-sampling-gem-strict` · base fast-llm `main` @ `6ceba1f`
Kit: `prompt-src.md` (sha256 below) · pi source of record: `repos/pi` @ `f1b2e77f5` (verified: `git rev-parse HEAD` = `f1b2e77f5b13b2a199b1052cb79c235451afe7d7`)

```
$ shasum -a 256 prompt-src.md
(built from canonical prompt.md; frozen Grounds/Specification/AC read in full before any work)
```

## 0. Audit of the inherited uncommitted state (done FIRST, before any edit)

`git -C <wt> status --short` (verbatim):

```
 M gems/completions/CHANGELOG.md
 M gems/completions/docs/reference/dialects.md
 M gems/completions/docs/reference/errors.md
 M gems/completions/docs/reference/tools.md
 M gems/completions/lib/fast/completions.rb
 M gems/completions/lib/fast/completions/dialects.rb
 M gems/completions/lib/fast/completions/errors.rb
 M gems/completions/lib/fast/completions/protocol.rb
 M gems/completions/lib/fast/completions/tool.rb
 M gems/completions/spec/fast/completions/dialects_spec.rb
 M gems/completions/spec/fast/completions/protocol_spec.rb
 M gems/completions/spec/fast/completions/tool_spec.rb
 M gems/completions/spec/fast/completions/wire_parity_spec.rb
?? gems/completions/lib/fast/completions/constrained_sampling.rb
?? gems/completions/spec/fast/completions/constrained_sampling_spec.rb
?? gems/completions/spec/fixtures/wire/CAPTURE-STRICT.mjs
?? gems/completions/spec/fixtures/wire/zai_strict_tool.json
?? gems/completions/spec/fixtures/wire/zai_strict_undeclared.json
```

- 13 modified + 5 new = exactly the declared 18-file touch set; zero commits (`git log 6ceba1f..` prints nothing; HEAD = `6ceba1f`).
- `git diff` reviewed file by file against the frozen Specification D1–D8: **no out-of-bounds file, no half-finished hunk found.** Every hunk maps to a spec letter (D1 dialects.rb 14th key + `:zai true`; D2 tool.rb `constrained_sampling` DSL w/ UNSET sentinel + fail-loud validation; D3 new engine file + facade require immediately before the protocol require; D4 `apply_tools` seam w/ amended §9.8 comment; D5 wire_parity rows + FROZEN_DIGESTS@13; D6 new unit spec; D7 docs + `## Unreleased`; D8 re-pins).
- AC6 frozen set untouched (verified by the scope gate + absence from status): `README.md`, 11 existing fixture JSONs, `CAPTURE.mjs`, `docs_links_spec.rb`, `mock_llm_server.rb` — `git diff --quiet 6ceba1f` on all four paths passes.
- Both new fixtures are BYTE-IDENTICAL to the space pre-made artifacts (`cmp` vs `tmp/i63-spec/capture/out/{zai_strict_tool,zai_strict_undeclared}.json` — silent pass on both), and both reproduce the Grounds' frozen wire digests from their `request_body` bytes:

```
zai_strict_tool:       d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c2410d65ce824a8
zai_strict_undeclared: fead3755e34689d502cbb865d6d424ccc84b4453d8724aa8fee713f9516a60c9
```

- Landed fixture FILE sha256s (files, not wire bytes):
  - `zai_strict_tool.json` = `ee40a1e098063cd6e71289c26f51da0fa1f701e25f2a86bb8637d7609b07727d`
  - `zai_strict_undeclared.json` = `70df5cc951d9f8935247a4f3b2635d863a56f8eb45ac4bd456ad05f432f35419`

## 1. PHASE 0 — pi cross-read and disagreement table

Read `packages/ai/src/api/constrained-sampling.ts` in full (298 lines) at `f1b2e77f5`; diffed arm-by-arm against Specification D3 and the ported engine. Check order (boolean-schema arm → unsupported keys in list order → anyOf → items → properties-requires-object → non-object return → additionalProperties → properties-map → required-string-array → required⊆properties → recurse-then-wrap → required=all+additionalProperties=false), both `root schema must have type object` arms, deep-copy-first, the resolver's catch-only-Unsupported + rethrow, both raise templates, and the `const === null` (key-present) subtlety all MATCH pi exactly.

| # | Frozen claim | pi @ f1b2e77f5 | Resolution |
|---|---|---|---|
| 1 | Grounds/Spec: "`UNSUPPORTED_STRICT_SCHEMA_KEYS` — exactly **20** keys" (prompt-src.md:125, :324) | The array at `constrained-sampling.ts:17-34` holds **16** keys; the Grounds' own enumeration on the next lines lists the same 16 in the same order. The numeral 20 is internally inconsistent with its own enumeration. | Implemented 16 per pi (pi is the oracle per PHASE 0 protocol). Predecessor documented it in the engine header (`constrained_sampling.rb:14`: "16 keys — the frozen order IS the first-present-key-wins order… the count numeral in the brief is wrong, pi is the oracle"). I concur. No other disagreement found. |

## 2. Superseded-era ruling (cited verbatim; binds this lane)

> Option A — the lib stays 100% faithful to D1–D4/pi @ f1b2e77f5; the two pi-ai 1.1.0 capture rows (zai_on/zai_off) get a HARNESS-LOCAL `:zai_1_1` dialect declared inside wire_parity_spec.rb ONLY (never in dialects.rb's shipped registry; shipped trio stays :zai/:deepseek/:fireworks); the why-comment at that declaration carries capture generation (pi-ai 1.1.0 vs 1.2.0), the byte delta (,"strict":false — 501B vs 516B), and zai_strict_undeclared (sha fead3755…) as proof pi changed the wire between capture generations; all 13 fixture JSONs stay byte-identical; AC6 untouched; the D5-letter deviation (two scenario rows' dialect assignment — spec-side, not AC6 frozen bytes) is itemized + defended in your Builder Report with the ruling cited.

Ruling mechanics verified in the inherited tree:

- `grep -rn "zai_1_1" gems/completions/lib/` → **no matches** (exit 1). `Dialects.declare` sites in dialects.rb: `:zai` (:153), `:deepseek` (:163), `:fireworks` (:172) — shipped trio unchanged.
- `:zai_1_1` is declared inside `wire_parity_spec.rb` via `Fast::Completions.dialect(:zai_1_1)` (consumer-side declaration = data, not detection), = `:zai` minus `supports_strict_mode`.
- The why-comment at that declaration carries all three required evidences: capture generation ("The zai_on/zai_off fixtures are pi-ai 1.1.0 captures, from BEFORE strict emission existed on this surface: pi 1.2.0 — the generation the two I63 captures come from"), the byte delta ("emits ,\"strict\":false on exactly this wire … 501B → 516B"), and the proof SHA ("fixture zai_strict_undeclared, SHA256 fead3755e34689d502cbb865d6d424ccc84b4453d8724aa8fee713f9516a60c9").
- All 13 fixture JSONs byte-identical: 11 existing untouched (not in git status); 2 new byte-identical to `tmp/i63-spec/capture/out/` (§0).
- Byte-delta claim independently re-measured this session (request_body bytes / `tools` substring bytes):

```
zai_on:                request_body=501B tools=210B   (pi-ai 1.1.0 capture, thinking high)
zai_off:               request_body=453B tools=210B   (pi-ai 1.1.0 capture, thinking off)
zai_strict_undeclared: request_body=516B tools=225B   (pi-ai 1.2.0 capture, thinking high)
zai_strict_tool:       request_body=581B tools=290B   (pi-ai 1.2.0 capture, thinking high)
```

  Like-for-like pair (both thinking high, same undeclared read tool): 501B vs 516B — delta exactly 15B = `,"strict":false`. Confirmed.
- pi-side corroboration: `packages/ai/src/providers/data/zai.json` — every glm compat shape carries `"supportsStrictMode":true` (incl. glm-5.3); `openai-completions.ts` convertTools `:1500` `const strict = resolveJsonSchemaStrictSampling(tool, compat.supportsStrictMode !== false);`, key order name/description/parameters/strict, `...(compat.supportsStrictMode !== false && { strict: strict ?? false })`; detectCompat `:1675` `// OpenAI compatibility alone does not imply strict JSON-schema tool support.` `supportsStrictMode: false`.

## 3. D5-letter deviation — itemized + defended

**Deviation:** Specification D5's letter reads "The existing 11 scenarios stay byte-identical". In the inherited diff, the two scenario ROWS `zai_on`/`zai_off` had their model kwargs' `dialect:` re-pointed from `:zai` to the harness-local `:zai_1_1` (wire_parity_spec.rb SCENARIOS table). The scenario WIRE BYTES, fixture files, and frozen digests are unchanged — the deviation is strictly the harness-side dialect assignment of those two rows.

**Why it is unavoidable under the frozen letters alone:** D1 mandates the shipped `:zai` gains `supports_strict_mode true`; D4 then makes every function tool on `:zai` carry a strict key. The `zai_on`/`zai_off` fixtures are pi-ai **1.1.0** captures (per CAPTURE.mjs provenance) recorded before strict emission existed: replaying them through the re-defined `:zai` yields 501B+15B bodies and breaks the frozen digests (AC2/AC4). The three exits were: (a) regress shipped `:zai` to `false` — violates D1/pi zai.json (`supportsStrictMode:true`); (b) re-capture the two fixtures against 1.2.0 — violates the frozen-bytes rule (11 fixtures byte-frozen); (c) harness-local capture-era compat — changes nothing shipped, nothing frozen. The architect ruled (c). Defended: shipped lib stays 100% faithful to D1–D4/pi; all 13 digest assertions stay byte-exact; AC6 frozen set untouched; the deviation is visible in exactly two harness lines, each carrying an inline pointer comment to the `:zai_1_1` declaration.

## 4. Verification — fresh runs this session (raw output)

Environment: ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [arm64-darwin23], bundler 4.0.22. All commands run from the repo root with explicit timeouts, nothing in background.

| gate (frozen form) | fresh output | exit |
|---|---|---|
| suite: `bundle exec rspec` | `210 examples, 0 failures` (RSPEC_EXIT=0) | 0 |
| parity: `bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb` | `14 examples, 0 failures` | 0 |
| strict-wire: `… wire_parity_spec.rb -e "zai_strict"` | `2 examples, 0 failures` | 0 |
| strict-unit: `… constrained_sampling_spec.rb` | `21 examples, 0 failures` | 0 |
| strict-dialect: `… dialects_spec.rb -e "supports_strict_mode"` | `3 examples, 0 failures` | 0 |
| strict-tool: `… tool_spec.rb -e "constrained"` | `3 examples, 0 failures` | 0 |
| strict-emission: `… protocol_spec.rb -e "strict"` | `7 examples, 0 failures` | 0 |
| docs: the 5-grep chain | `STRICT_DOCS_OK` | 0 |
| scope: frozen diff-scope chain | `SCOPE_OK` | 0 |

Per-spec run counts (single-spec `-O /dev/null`, all 0 failures):

| spec file | examples |
|---|---|
| constrained_sampling_spec.rb (NEW) | 21 |
| wire_parity_spec.rb (13 scenarios + 1 fidelity) | 14 |
| protocol_spec.rb (+7 strict-emission) | 42 |
| tool_spec.rb (+3 constrained_sampling) | 8 |
| dialects_spec.rb (+3 supports_strict_mode) | 13 |
| docs_links_spec.rb (untouched; README owner-prose gate) | 5 |

Suite delta: 210 − 174 (base) = **+36 examples** (= 21+2+7+3+3).

RED-at-base spot-checks (read-only `git grep -c <token> 6ceba1f -- <path>`): `strict` in protocol_spec 0; `supports_strict_mode` in dialects_spec 0; `constrained` in tool_spec 0; `zai_strict` in wire_parity_spec 0; `supports_strict_mode` under docs/ 0; `^## Unreleased` in CHANGELOG 0 — every new gate was 0-example RED at base as the kit declares.

### Wire-parity digest table (13 rows — all PASS in the single parity run; each row asserts SHA256(request_body) == frozen digest, twice: fixture-fidelity example + per-scenario example)

| # | tag | frozen digest (SHA256 of request_body) | result |
|---|---|---|---|
| 1 | fireworks_plain | 0b9da927d3cab0b8b41ecb634fde099729e03f817ef6ba3aba26720df2130d93 | PASS |
| 2 | openai_ladder_on | b05b45aeb3a4f7bdfa12d142e839882855688a246ead4d016fbe474188dfaed2 | PASS |
| 3 | openai_ladder_off | 60914406494e2e8403de6b932f01cd5d901c9ae4c4de75e283b25656fa6304b1 | PASS |
| 4 | zai_on | 9a23aee6b115cce0bd6a608465f2c56332123e47a0f22c491793c0a4d0e45c13 | PASS |
| 5 | zai_off | 88dd5af69ceb68bbc41aad9ddfbc4dcb36e0dd66fec3563054d484cc0f727f7c | PASS |
| 6 | deepseek_on | ce98edaee2ecb634dcd4461e3e56cfc4f973cd37026fc390b63ac2bdfbfec5f5 | PASS |
| 7 | tool_roundtrip | 940d8f5b262f59a3db7b27a70471ac96a40c170264edc83219bef83dce1e9038 | PASS |
| 8 | thinking_replay | c9259d5da9ca8c63186522c24b9bdfd1fe81aa0903187b0f50634b56eb3c7e6c | PASS |
| 9 | reasoning_details_replay | c21da08d520e246652b33bedf76d89db581692a7775de5181dc8c63013a0ae4e | PASS |
| 10 | cross_model_thinking_replay | 809a9b7ecc99399379031524ed5810677e31c22cac2f64eb6e728602ea5939fc | PASS |
| 11 | budget_field | fb29e70650e9708f394c319d3c8ecacb840c134d214f9ce2747151356b86d1b7 | PASS |
| 12 | zai_strict_tool | d7470202a2f66216b3d0381bb18d3c5c29082e5c334b7fb87c2410d65ce824a8 | PASS |
| 13 | zai_strict_undeclared | fead3755e34689d502cbb865d6d424ccc84b4453d8724aa8fee713f9516a60c9 | PASS |

Full 13-example reproduction run (documentation format, all names):

```
  carries the 13 frozen fixtures: shape, request_path, digest
  reproduces the recorded pi bytes for fireworks_plain (byte equality + frozen digest)
  reproduces the recorded pi bytes for openai_ladder_on (byte equality + frozen digest)
  reproduces the recorded pi bytes for openai_ladder_off (byte equality + frozen digest)
  reproduces the recorded pi bytes for zai_on (byte equality + frozen digest)
  reproduces the recorded pi bytes for zai_off (byte equality + frozen digest)
  reproduces the recorded pi bytes for deepseek_on (byte equality + frozen digest)
  reproduces the recorded pi bytes for tool_roundtrip (byte equality + frozen digest)
  reproduces the recorded pi bytes for thinking_replay (byte equality + frozen digest)
  reproduces the recorded pi bytes for reasoning_details_replay (byte equality + frozen digest)
  reproduces the recorded pi bytes for cross_model_thinking_replay (byte equality + frozen digest)
  reproduces the recorded pi bytes for budget_field (byte equality + frozen digest)
  reproduces the recorded pi bytes for zai_strict_tool (byte equality + frozen digest)
  reproduces the recorded pi bytes for zai_strict_undeclared (byte equality + frozen digest)
```

(`14 examples, 0 failures` for the file.)

## 5. Files touched (exactly the declared 18; nothing else vs base 6ceba1f)

Modified (13): `gems/completions/CHANGELOG.md`, `docs/reference/{dialects,errors,tools}.md`, `lib/fast/completions.rb`, `lib/fast/completions/{dialects,errors,protocol,tool}.rb`, `spec/fast/completions/{dialects,protocol,tool,wire_parity}_spec.rb` — New (5): `lib/fast/completions/constrained_sampling.rb`, `spec/fast/completions/constrained_sampling_spec.rb`, `spec/fixtures/wire/{CAPTURE-STRICT.mjs,zai_strict_tool.json,zai_strict_undeclared.json}`.

Zero commits: `git log 6ceba1f..` empty; no git write command run by this builder (only status/diff/log/grep reads).

## 6. Residual observations (no action taken; itemized per §8 discipline)

- R2 (named exclusion, by spec): the `isUnsupportedKeyword` provider hook is NOT ported; commented at the port site (`constrained_sampling.rb`).
- R8 (declared residual, by spec): `gems/completions/README.md` still says "13 keys" at its :86 line — FROZEN by the I53 owner-prose gate (docs_links_spec 5/0 green); canonical inventory is docs/reference/dialects.md (14 there).
- Tool DSL accepts a valid `{"type","strict"}` Hash carrying EXTRA keys (validation checks the two required keys' values; extra keys never reach the wire — the resolver reads only `config["type"]`/`config["strict"]`). No spec letter enumerates extra keys as a raise case; left as inherited.
- The Grounds "20 keys" numeral (§1): resolved per pi = 16; the frozen text itself remains internally inconsistent (numeral vs its own enumeration) — owner-side doc nit for any future brief re-issue.

STATUS: COMPLETE

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section strict-sampling-gem verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify strict-sampling-gem`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
