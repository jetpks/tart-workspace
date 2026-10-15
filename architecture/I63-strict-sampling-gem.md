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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section strict-sampling-gem specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision strict-sampling-gem`
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
`architect rehearse strict-sampling-gem` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze strict-sampling-gem` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse strict-sampling-gem` — before the freeze, while
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
subsection per lane. A copy is written to build/I63-strict-sampling-gem-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section strict-sampling-gem prompt --append --lane <lane> --from build/I63-strict-sampling-gem-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I63-strict-sampling-gem-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence strict-sampling-gem --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
