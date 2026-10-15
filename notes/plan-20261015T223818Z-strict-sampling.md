# Plan — strict-sampling (port pi's constrained-sampling wire layer into fast-completions, then integrate in tart)

Operator plan 2026-10-15. Repos in scope: fast-llm (the fast-completions gem,
ENTRY 1), tart (ENTRY 2). Root cause and full evidence chain: `problems.md`
@ 1b69ddb (committed 2026-10-15) — the live-session hang on
`architect looplog | head -20` is a symptom; the parity gap is that pi sends
strict-mode (constrained-sampling) tool schemas that force the model to emit
every declared property (e.g. bash `timeout`) on every call, while
tart/fast-llm sends parameters verbatim and the model omits optionals at will.

Standing context the spec needs:

- Previous spec handoff: `notes/spec-digest-20261015T195930Z.md` (I62
  stream-hardening) — carry its house conventions verbatim: token-collision
  grep BEFORE freezing any `-e` gate; `-O /dev/null` for single-spec gates;
  freeze mechanics (commit space.yaml first, clean arch file → empty freeze
  commit, freeze_sha = HEAD); `architect verify` materializes worktrees and
  the lane integration_branch must be hand-set to `main` for fast-llm
  (I53/I61/I62 precedent); expect the rehearsal's scope-asymmetry advisory
  when a gate word pre-exists elsewhere.
- Source-of-truth pins: pi source at `repos/pi` @ `f1b2e77f5` (the port
  reference; installed dist 1.2.0 and upstream 1.3.0 were verified identical
  for this surface during root-causing). fast-llm main @ `6ceba1f`
  (v0.3.0 released; the gem version is 0.3.0 — this program lands as 0.4.0,
  tag hand-cut by the owner at landing per the monorepo README).
- Verification gates: fast-llm `cd repos/fast-llm && bundle exec rspec`
  (record the fresh base count at spec time — I62 landed past the 146 in the
  digest); tart `cd repos/tart && bundle exec rake test` (minitest, default
  task). Both suites must be green at base before freeze.
- Routing: standing `architect.yaml` (peak-window flipping rides the config;
  no plan pin).
- Post-landing follow-ups OUTSIDE this loop: owner cuts the 0.4.0 gem tag and
  runs the landing blocks (I62 disposition: PR-only, paste-and-run); the
  queued tart stop_reason threading backlog (58af310) stays separate — do not
  bundle; `problems.md` entry closes at landing.

## ENTRY 1 — iteration strict-sampling-gem (repo: fast-llm, 1 lane)

**Objective.** Port pi's JSON-schema constrained-sampling machinery into the
fast-completions gem so the wire layer can send strict-mode tool schemas.
This is the fix's substance: pi forces property emission on strict-capable
providers (zai glm-5.3 `compat.supportsStrictMode: true`), which is why a pi
session never hangs on a follow-forever command — the model must emit
`timeout` every bash call (BRIEF §7.8 exact-parity bar; §8 itemize-and-defend
discipline for any deviation).

**Grounds to read.**
- `problems.md` (root cause + A/B evidence: pi emits `timeout:60`, tart 0/8).
- pi `packages/ai/src/api/constrained-sampling.ts` (entire file @ f1b2e77f5):
  `UNSUPPORTED_STRICT_SCHEMA_KEYS`, `schemaAllowsNull`,
  `makeJsonSchemaNodeStrict` (recursive: boolean schemas throw; unsupported
  keywords throw; anyOf variants must be non-structured and recurse; items
  rejects tuples and recurses; object properties must be a map; required must
  be a string array ⊆ properties; non-required properties not allowing null
  are wrapped `anyOf: [property, {type: "null"}]`; finally required = ALL
  property names, additionalProperties = false), `makeStrictJsonSchema`
  (deep-copy — the caller's schema object is never mutated), and
  `resolveJsonSchemaStrictSampling` ("prefer" falls back to loose on
  unsupportable schema or unsupported provider; "require" raises with pi's
  message shapes).
- pi `packages/ai/src/api/openai-completions.ts` ~:1504-1516 (applyTools):
  when compat `supportsStrictMode !== false`, EVERY function tool carries an
  explicit `"strict"` key — `strict ?? false` — i.e. declared-strict tools
  get `true`, undeclared tools get `false`; providers without strict support
  get NO strict key ever. Also detectCompat ~:1670-1680: default
  `supportsStrictMode: false` (OpenAI-compatibility alone does not imply it).
- pi `packages/ai/src/types.ts` :736-754 (`ConstrainedSamplingConfig`:
  `{type: "json_schema", strict: "prefer" | "require"}`; Tool.constrainedSampling
  optional, `false` allowed).
- Gem seams: `gems/completions/lib/fast/completions/dialects.rb` (the CLOSED
  Dialect vocabulary — add `supports_strict_mode` default `false`; the
  shipped `:zai` declaration gains `supports_strict_mode true`, mirroring
  pi's zai compat; `:deepseek`/`:fireworks`/default stay false);
  `lib/fast/completions/tool.rb` (Tool DSL gains a `constrained_sampling`
  declaration, default nil; the declared shape mirrors pi's);
  `lib/fast/completions/protocol.rb` `apply_tools` :72-87 (the wire seam:
  strict rewrite + strict key emission; the VERBATIM-by-default discipline
  holds for undeclared tools and non-strict dialects — amend the §9.8 comment
  deliberately, don't delete the discipline).
- Gate homes: `gems/completions/spec/fast/completions/protocol_spec.rb`,
  `wire_parity_spec.rb`, `tool_spec.rb`, `dialects` spec if present;
  `docs/` reference pages + `CHANGELOG.md` (Unreleased section).

**Acceptance direction (spec refines into frozen AC).**
- Declared-strict tool + `supports_strict_mode` dialect → wire `parameters`
  are the strict rewrite (all properties required; optionals wrapped
  anyOf-with-null; additionalProperties false) and `"strict" => true` on the
  function object — pinned byte-exact in the wire-parity spec against a
  pi-derived fixture.
- Undeclared tool on the same dialect → `"strict" => false`, parameters
  verbatim. Any tool on a non-strict dialect → NO strict key, parameters
  verbatim (byte-parity with today's wire for fireworks/deepseek).
- "prefer" + unsupportable schema → silent loose fallback; "require" +
  unsupportable schema or unsupported dialect → raises with pi's message
  shapes (message parity pinned).
- The rewrite never mutates the caller's declared parameters object
  (deep-dup pinned by test); recursion rules (anyOf/items/required ⊆
  properties/boolean-schema throw) covered by unit fixtures derived from
  pi's semantics.
- Dialect vocabulary stays CLOSED: unknown keys still raise at declaration
  time; `supports_strict_mode` enters the vocabulary, not around it.
- Docs reference the new declaration + wire behavior; CHANGELOG Unreleased.
- Base rspec suite green at freeze; every new gate RED at base (digest
  conventions).

**Constraints.** NO grammar-constrained-sampling port (pi's grammar half of
constrained-sampling.ts — resolveGrammarConstrainedSampling, grammar tool
input buffers — is OUT of scope; itemize as a named exclusion, nothing in the
gem should half-anticipate it). No provider detection/catalog in the gem
(the consumer declares via Dialect — house rule D2/D4). No codec/client arm
changes beyond what `apply_tools` needs. No version bump or release in-lane
(owner cuts 0.4.0 at landing). Builders never commit.

## ENTRY 2 — iteration strict-sampling-integration (repo: tart, 1 lane)

**Objective.** Make tart consume the gem's strict machinery end-to-end: the
four pi-tagged core tools declare constrained sampling, the model registry's
`supportsStrictMode` compat flows to the Dialect, and a live zai round-trip
shows the model emitting declared optionals (bash `timeout`) it previously
omitted — the hang class from `problems.md` @ 1b69ddb dies at the root
(BRIEF §7.8).

**Grounds to read.**
- ENTRY 1's landed gem (integrated on fast-llm main; the lane reads the
  merged `constrained_sampling` DSL + `supports_strict_mode` dialect key as
  its API) and its iteration verdict.
- pi tool declarations (the exact four, @ f1b2e77f5):
  `packages/coding-agent/src/core/tools/bash.ts:260`, `read.ts:101`,
  `edit.ts:156`, `write.ts:57` — all `{type: "json_schema", strict:
  "prefer"}`. pi tags NOTHING else in core; tart's custom tools (memory,
  subagents, …) stay untagged — itemize, don't guess.
- tart seams: `lib/tart/models.rb` :150-198 (`dialect_for` compat→Dialect
  translation — thread `supports_strict_mode`; `DEFAULT_DIALECT` stays
  non-strict), `lib/tart/schemas/models.rb` :100-130 (compat parsing —
  today `supportsStrictMode` is tolerated-and-DROPPED as an unknown key;
  carry it), the four tool files `lib/tart/tools/{bash,read,edit,write}.rb`
  (declarations), `Gemfile` :12 (fast-completions pin `0.2.0` — currently a
  release behind; bump to the landed `0.4.0` path pin + lock).
- `problems.md` @ 1b69ddb (the A/B protocol: pi -p emitted `timeout:60` and
  recovered in 140s; tart live session 2026-10-15T22-13-25 omitted timeout
  8/8).
- Gate homes: `test/bash_tool_test.rb`, `test/chat_test.rb` and siblings;
  live repro pattern precedent `tmp/repro_thinking_budget.rb` (I36).

**Acceptance direction (spec refines into frozen AC).**
- `models.json` compat `supportsStrictMode: true` flows: live object →
  parsed model → Dialect → wire (unit-gated with a fixture model).
- bash/read/edit/write declare json_schema strict "prefer" (exactly pi's
  four; customs untagged, itemized).
- Recorded-wire gate: a scripted zai round-trip (or mock-server wire
  capture) shows the strict-rewritten bash schema + `strict: true` on the
  wire; a fireworks-shaped (non-strict) model shows NO strict key and
  verbatim parameters — both pinned.
- Live A/B direction: at least one scripted live zai exchange where the
  assistant's bash tool call CARRIES `timeout` (the property the strict
  schema forces); pre-fix baseline for the same prompt omitted it (the
  problems.md evidence stands as the baseline — the gate records the
  post-fix side).
- `bundle exec rake test` green at freeze; new gates RED at base.

**Constraints.** No change to non-strict wire bytes (fireworks parity is
byte-frozen). No gem edits from this lane — if the gem API is wrong, raise
it (PHASE 0 disagreement with the ENTRY 1 verdict cited), don't fork the
machinery. Gemfile pin bump + lock only as described; no release. Builders
never commit.
