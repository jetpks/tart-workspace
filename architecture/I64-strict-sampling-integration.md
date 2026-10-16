# I64: strict-sampling-integration

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**The defect and the program (problems.md @ 1b69ddb, committed 2026-10-15; plan
`notes/plan-20261015T223818Z-strict-sampling.md`).** ENTRY 1 (I63) landed pi's
JSON-schema constrained-sampling machinery in the fast-completions gem — the
fix's wire-side substance. THIS iteration is the consumer half: tart's four
pi-tagged core tools declare constrained sampling, the model registry's
`supportsStrictMode` compat flows to the Dialect, and the strict wire reaches
api.z.ai — the hang class from `problems.md` (a live tart session omitted
`timeout` on 8/8 bash calls; the same prompt under pi emitted `timeout:60`
and recovered in 140s) dies at the root. BRIEF §7.8 exact-parity bar; §8
itemize-and-defend.

**ENTRY 1's landed state (the API this lane consumes; verified this session).**
fast-llm `project/pi-port` @ `7568589` (I63 lane commit 244f048 merged; NOT
pushed — `origin/project/pi-port` is behind at fbd013c): `constrained_sampling.rb`
engine, the Tool DSL `constrained_sampling` (nil default; `false`; the mirrored
string-keyed `{"type" => "json_schema", "strict" => "prefer"|"require"}` shape;
anything else raises `ArgumentError` at declaration — tool.rb :38-48), the
Dialect vocabulary's 14th key `supports_strict_mode` (default false; shipped
`:zai` declares true), and the `apply_tools` wire seam (protocol.rb :81-97):
declared-strict tool on a strict dialect → the strict REWRITE of parameters +
`"strict" => true` right after `"parameters"`; undeclared tool on a strict
dialect → verbatim + `"strict" => false`; ANY tool on a non-strict dialect →
NO strict key, parameters verbatim with object identity. Gem VERSION is
**0.3.0** with the strict machinery under `## Unreleased` in CHANGELOG.md —
the owner's 0.4.0 hand-cut is PENDING (I63 verdict; landing stays the human's).

**The Gemfile pin reality (measured this session; supervisor ruling
2026-10-16).** tart's Gemfile :12 pins `gem "fast-completions", "0.2.0", path:
ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")`. The
canonical fast-llm checkout is ON `project/pi-port` @ 7568589 (version 0.3.0),
so `bundle exec rake test` in repos/tart FAILS TODAY with `Bundler::GemNotFound`
(Could not find gem 'fast-completions (= 0.2.0)' … source contains
fast-completions-0.3.0) — the pin bump is the precondition for ANY suite run,
not polish. The plan's letter says "bump to the landed `0.4.0` path pin"; no
0.4.0 exists and pinning it breaks bundler identically. **Supervisor ruling:
pin `"0.3.0"` + lock** (the version the landed source declares); the owner's
0.4.0 hand-cut is followed by the mechanical re-pin commit (I61 precedent,
tart 195ae97 "follow the released gem; path pin + lock") — version-string +
lock only, no code delta, no re-gating.

**The symbol-key hazard (measured this session — the lane's sharpest trap).**
The gem engine reads STRING keys (pi's JS shape: `node["type"]`, I63 D3/R5).
tart's four tools' `PARAMETERS_SCHEMA` constants are symbol-keyed at the top
level (`{type: "object", properties: {...}, required: [...]}` — bash.rb :22-28,
read.rb :21-30, edit.rb :22-45, write.rb :20-28). Under the strict arm a
symbol-keyed root makes `make_strict_json_schema` raise `root schema must have
type object` internally, which `"prefer"` CATCHES AS SILENT LOOSE FALLBACK —
**the declarations would be inert with zero errors** (verified by probe:
symbol-keyed schema → resolver returns nil → no strict key, no rewrite). The
conversion is therefore MANDATED, not optional: the four constants go
string-keyed throughout (nested `type:`/`description:`/`items:` included).
Wire-byte neutral today (JSON.generate serializes `:type` and `"type"`
identically — the standing `7360fd1e…` tools digest proves the bytes), and
supervisor-ruled to carry a LOUD pin (resolver == true for each of the four +
string-key assertions) so a future re-symbolizing fails gates, not silently.

**Fresh base measurements (this session; the pin-consistency protocol).**
Base = tart `project/pi-port` @ `195ae97` (tip; I60 integrated + the owner's
0.2.0 pin bump). Because base cannot bundle against the canonical gem
checkout, the base suite was measured with `FAST_COMPLETIONS_PATH` pointed at
a v0.2.0 fast-llm worktree (space `tmp/e2-base-gem/`, tag v0.2.0 = 43ea169):
**1168 runs, 5491 assertions, 1 failure, 0 errors, 1 skip** — the single
failure is I60's disclosed E-2 (`TuiSplitRig::RegistryTest#
test_seed_registry_contains_only_path_or_sandbox_classes`: the two I60-ratified
s18 registry classes `error-transcript-row-tail` + `pi-bug-report-hint` are not
in `SANCTIONED_NON_PATH`, registry_test.rb :17 — I60 deferred the one-line
ratification to the integrator; it never landed). Second run with the pin
bumped to 0.3.0 in a throwaway worktree (space `tmp/e2-tart-wt/`,
`FAST_COMPLETIONS_PATH` → the canonical 0.3.0 checkout): **1168 runs, 2
failures** — E-2 plus exactly ONE gem-behavior re-pin:
`Tart::AgentLoopTest#test_compaction_start_without_completion_when_the_summary_
call_fails` (agent_loop_test.rb :1304-1320) — I62's request-creation retry
(default `max_retries: 1`) consumes the NEXT mock script entry after the
scripted 500, so the summary call succeeds on retry with "second answer" and
the completed-compaction event fires; the re-pin adds a second scripted `:error`
so both attempts fail. No other test moves. The I62 gem otherwise holds tart's
suite (its 210-example suite is green at 7568589, I63 verdict).

**pi's four tags and tart's tool inventory (itemized, not guessed).** pi @
`f1b2e77f5` tags EXACTLY four core tools `constrainedSampling: {type:
"json_schema", strict: "prefer"}`: bash.ts :260, read.ts :101, edit.ts :156,
write.ts :57 (the wrapper tool-definition-wrapper.ts :18/:53 passes it through;
nothing else in `packages/coding-agent/src/core/` or `packages/agent/src/`
carries it — grep-verified). tart's full tool surface, all
`Fast::Completions::Tool` subclasses: TAGGED (this lane, exactly pi's four) —
`Tart::Tools::Bash`, `Read`, `Edit`, `Write`. UNTAGGED (itemized, stay
undeclared — on a strict dialect they ship `"strict" => false` + verbatim,
pi's undeclared behavior): built-ins `Find`, `Grep`, `Ls`, `ContactSupervisor`
(tools/registry.rb TOOL_CLASSES :23-32), hook-registered customs `Memory`
(memory.rb :55) and `Subagent` (subagents.rb :237), `Tart::Mcp::Tool` per-server
instances (mcp/tool.rb — declared direct), and the `ToolGate` SimpleDelegator
wrapper (registry.rb :109 — instance-method delegation forwards the
`constrained_sampling` reader to the inner tool; class-level DSL untouched).
Support modules, not tools: `SafeExecute`, `OutputAccumulator`.

**tart seams at base (with the exact flow to build).** The compat chain
today: `Schemas::Models` (schemas/models.rb :104-130) validates the I46
five-key compat subset and TOLERATES unknown keys (the comment :108 names
`supportsStore`/`supportsStrictMode` — today dropped); `Shapes::ModelCompat`
(shapes/model.rb :32-44) is the dry-struct with five nil-defaulted attributes
(unknown constructor keys are silently ignored — verified: constructing with
`supports_strict_mode:` reads `<no method>`); `Models.build_compat`
(models.rb :272-285) picks the five keys; `Models.dialect_for` (models.rb
:166-180) translates compat→Dialect — the ZAI ARM builds the explicit zai-shaped
Dialect (thread `supports_strict_mode` here); `DEFAULT_DIALECT` (models.rb :184,
frozen singleton) serves every compat-less/non-zai model and STAYS non-strict.
`Models.wire_model` (models.rb :152-165) mounts the dialect on the gem Model —
the single seam every construction path already threads (boot interactive +
print, `/model` switch, compaction one-shot, subagent children — I59), so the
strict flag rides everywhere by construction. **Boundary (itemized): the
non-zai arm stays DEFAULT_DIALECT verbatim** — a non-zai compat declaring
`supportsStrictMode` is tolerated-and-dropped like every other non-zai compat
key (I46's frozen "only-zai arms" shape, models.rb :166-171 comment; pi's
getCompat would thread it — recorded as a declared divergence + known unknown;
no such catalog entry exists here).

**The owner's live catalog (the "live object" the flow gate feeds).**
`~/.tart/models.json`: provider zai (baseUrl api.z.ai/api/coding/paas/v4, NO
inline apiKey — keys resolve via the identity env `PI_API_KEY`/`ZAI_API_KEY`,
pi args.ts :440), models glm-5.3 + glm-5.3-flash, compat keys
`{supportsStore, supportsDeveloperRole, supportsReasoningEffort, maxTokensField,
thinkingFormat: "zai", supportsStrictMode: true, zaiToolStream}` — the exact
shape the unit flow gate's fixture mirrors (`supportsStore` stays
tolerated-and-dropped).

**Live evidence vehicle (supervisor ruling 2026-10-16).** ZAI_API_KEY is
absent from every loop-side environment (spec/judge/coordinator verified;
I46/I63 records) — the live half CANNOT run inside the loop. Shape: (a)
JUDGEABLE COLD — the recorded-wire mock-server gate (zai-shaped fixture →
strict bytes on the wire; fireworks-shaped control → no strict key + verbatim),
with problems.md 1b69ddb standing as the omitted-baseline + pi-side causal
evidence (pi -p emitted timeout:60 under the same constraint bytes); (b)
OWNER-RUN AT LANDING — a pre-made script at space `tmp/e2-spec/
repro_strict_sampling.rb` (this spec session; I36 tmp/repro_* precedent; reads
ZAI_API_KEY from the owner's env at runtime, ZERO secrets recorded) with a
one-line run instruction in the Builder Report + landing blocks; live
emission-confirmation adjudicated env-class per I59/I46 — the verdict does NOT
block on it; problems.md is the feedback channel.

**Expected strict bytes (pre-computed this session through the LANDED engine
against string-keyed forms of the four declared schemas — these freeze as the
pinned expectations; sha256 over `JSON.generate(parameters)`):** bash
`required ["command","timeout"]`, `timeout` wrapped `anyOf:[{type:"number",
description:"Timeout in seconds (optional, no default timeout)"},{type:"null"}]`,
`additionalProperties:false`, key order `[type, properties, required,
additionalProperties]` (tart's declared order preserved — pi's TypeBox order
`[type, required, properties]` is a STANDING tart-vs-pi wire divergence,
delta-audited since I52; reordering would break the non-strict byte-freeze) —
`a6c8a972736069994badf4f85cacae7549ef564697f8fc77cc693c1b392ca254`; read
(required all three, offset+limit wrapped)
`bfce07b51dfaa08d4a4c61b22f5f4efcb8f8bb89cc49baf6e834ac67eae45ad3`; edit
(items node rewritten: oldText/newText already required,
`additionalProperties:false` inside items too)
`e34ab9c2d955de1b60ffb86f5caa961f15626ccdd219ca07425e8f8fecfe3b9c`; write
(both already required — no wrap, additionalProperties appended)
`e7565c49119b3f73f0c3f436e460d689a19a0724283ef7a11c4bdc2965416f43`.

**Gate homes + token collisions (house convention; measured at base).** NEW
`test/strict_sampling_test.rb` (missing at base → RED by missing-file). New
`-n` token `/strict/` on models_test: 0 test NAMES match at base (the 2 file
hits are the owner-catalog fixture JSON :132 + a comment :136 — the fixture
ALREADY carries `supportsStrictMode: true` as a tolerated unknown, so the
re-pin flips it to a carried key + gains the assert). `supports_strict_mode`:
0 hits in lib/ (the seam is untouched today); 0 in Gemfile/Gemfile.lock
("0.3.0": 0 hits both). The I60-ratified s18 registry classes land in
`gems/tui-split-rig/test/registry_test.rb` :17 `SANCTIONED_NON_PATH`.
Standing battery: I60's frozen 31-gate block carried forward with THREE
declared rebases (lock-deps pin `0.1.0`→`0.3.0` in both greps; threads-budget
base `24e89ba`→`195ae97`; scope rewritten for this lane's touch set) —
commands otherwise byte-verbatim. The rig env prefix
(`env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
HERDR_WORKSPACE_ID -u HERDR_PANE_ID`) stays mandatory on rig invocations.

**Previous handoff honored** (`notes/spec-digest-20261015T225213Z.md`, I63):
the API surface consumed as frozen there (DSL shape, dialect key, D4 wire
discipline — verified compatible by probe this session: `wire_model` + the
landed Dialect accept the flow, and today's tart emits zero strict keys, the
inert baseline); freeze mechanics (commit space.yaml first, clean arch file →
bookkeeping-only freeze commit); provision's fast-llm nil integration_branch
class (tart lanes target `project/pi-port` — the tool's tart default, verify
at provision); token-collision grep before freezing any `-e`/`-n` gate; no
process substitution in gates; known unknowns inherited: zai LIVE strict
acceptance (api.z.ai vs `strict:true` + rewritten schemas) stays unverified
pre-landing — the owner-run script is the probe.

## Specification

### Objective

Make tart consume the landed gem's strict machinery end-to-end (the consumer
half of the `problems.md` @ 1b69ddb fix): the four pi-tagged core tools
declare `constrained_sampling` json_schema/"prefer" with STRING-KEYED
schemas, the registry's `supportsStrictMode` compat flows live object →
parsed model → Dialect → wire, the strict-rewritten declarations + `strict:
true` reach strict-capable providers while EVERY non-strict wire byte stays
frozen, and the owner's live A/B vehicle is in place (script + instruction;
the live run is the owner's landing step per the supervisor ruling).

### The contract (one lane)

**D1 — the pin bump + lock (Gemfile :12, Gemfile.lock).** `gem
"fast-completions", "0.2.0"` → `gem "fast-completions", "0.3.0"` — the
version the landed source declares (fast-llm project/pi-port @ 7568589;
supervisor ruling 2026-10-16); the `path: ENV.fetch(...)` form and comment
block stay byte-identical; `Gemfile.lock` re-locked (fast-completions 0.3.0
path entry). NO other dependency moves. The owner's future 0.4.0 hand-cut is
followed by their mechanical re-pin commit (out of this lane; I61 precedent).

**D2 — the compat carry (schemas/models.rb, shapes/model.rb, models.rb).**
Three edits, one flow:
- `Schemas::Models` compat validation (schemas/models.rb :117-129): the
  boolean trio `%w[supportsDeveloperRole supportsReasoningEffort
  zaiToolStream]` becomes a quartet adding `supportsStrictMode` — nil passes,
  true/false pass, anything else fails `expected a boolean` on the same
  `compat.supportsStrictMode` key line (the enumerated reject-table shape).
  The :104-108 comment is AMENDED (supportsStrictMode now CARRIED;
  supportsStore remains the tolerated-and-dropped example). Unknown compat
  keys stay tolerated (pi additionalProperties:true).
- `Shapes::ModelCompat` (shapes/model.rb): gains `attribute
:supports_strict_mode, Types::Strict::Bool.optional.default(nil)` — appended
AFTER `zai_tool_stream` (the struct's declaration order is the documented
carry order; nil default, omittable, reads nil like the five).
- `Models.build_compat` (models.rb :272-285): gains `supports_strict_mode:
raw["supportsStrictMode"]`; the comment's "five carried keys" arithmetic
becomes six.

**D3 — the Dialect thread (models.rb `dialect_for` :166-180).** The ZAI ARM's
`Fast::Completions::Dialect.new(...)` gains `supports_strict_mode:
compat.supports_strict_mode == true` (nil/false/absent → false — pi
detectCompat's "OpenAI compatibility alone does not imply it"). The frozen
`DEFAULT_DIALECT` singleton (:184) is UNTOUCHED — compat-less and non-zai
models keep today's bytes verbatim. **Declared boundary (itemized):** a
non-zai compat declaring `supportsStrictMode` is tolerated-and-dropped
(I46's frozen only-zai-arms shape; pi's getCompat would thread it — recorded
divergence + known unknown, no such catalog entry exists).

**D4 — the four declarations + the string-key conversion
(lib/tart/tools/{bash,read,edit,write}.rb).** Each of the four gains, beside
its `pi_name`/`parameters` declarations: `constrained_sampling({"type" =>
"json_schema", "strict" => "prefer"})` — EXACTLY pi's tag (bash.ts :260,
read.ts :101, edit.ts :156, write.ts :57). Each `PARAMETERS_SCHEMA` constant
converts to STRING keys throughout (top-level `type`/`properties`/`required`
AND nested `type`/`description`/`items` — the gem engine reads string keys;
symbol keys make "prefer" silently inert, Grounds). The `parameters
PARAMETERS_SCHEMA.dup` declaration lines stay as-is. NO other tool declares
`constrained_sampling` (Find/Grep/Ls/ContactSupervisor/Memory/Subagent/
Mcp::Tool stay undeclared — pi tags nothing else; itemized in Grounds).
Descriptions, property names, required lists, and key ORDER are
BYTE-PRESERVED (JSON.generate serializes the converted constants
identically — the non-strict wire is frozen).

**D5 — the new test home (test/strict_sampling_test.rb).** One file, three
groups:
1. **The mock-wire pair (the recorded-wire gate).** Using `MockLLMServer` +
   the real `Tart::Agent::Chat` stack (the chat_test pattern): a zai-shaped
   fixture model (inline models.json JSON → `Models.load` → entry →
   `wire_model` — the FULL flow; compat mirrors the owner's live object
   including `supportsStrictMode: true` and a tolerated `supportsStore`) with
   the five-tool loadout bash/read/edit/write/ls; drive one request; capture
   the body. Pin: bash/read/edit/write function objects carry `"strict" =>
true` with parameters EXACTLY the Grounds-frozen rewrites (hash equality +
the four sha256s over `JSON.generate(parameters)`); `ls` carries `"strict" =>
false` with parameters verbatim-equal to its declared (parsed) schema; the
`strict` key sits right after `parameters` in the function-object key order;
`tool_stream: true` rides the request (the zai arm). The control: a
compat-less model (today's fireworks/mock shape) through the same loadout —
NO function object carries a `strict` key; every parameters hash is
verbatim-equal to its declared schema (the byte-freeze proof at the unit
seam).
2. **The loud string-key/resolution pins.** For each of the four:
   `Fast::Completions::ConstrainedSampling.resolve_json_schema_strict_sampling(
tool, true) == true` (returns nil on re-symbolized schemas — FAILS LOUD),
   `parameters.keys.all?(String)`, and `parameters["type"] == "object"`.
   Plus the untagged inventory pin: every OTHER Tart tool class enumerated
   (Find, Grep, Ls, ContactSupervisor, Memory, Subagent) reads
   `constrained_sampling` nil, and a fresh `Mcp::Tool` instance reads nil.
3. **The compat-flow units.** models.json fixture with supportsStrictMode →
   `ModelCompat#supports_strict_mode == true` → `Models.dialect_for(compat).
   supports_strict_mode == true` → `wire_model(...).dialect.
   supports_strict_mode == true`; absent/nil/false → false; the non-zai
   strict boundary pinned (a `thinkingFormat: nil` compat with
   `supports_strict_mode: true` still yields DEFAULT_DIALECT — the frozen
   arm); `DEFAULT_DIALECT.supports_strict_mode == false`.

**D6 — the re-pins (itemized, not silent).**
- `test/models_test.rb`: the owner-catalog test (:123-143) gains
  `assert_equal true, compat.supports_strict_mode` and its :136 message drops
  supportsStrictMode from the "unknown" list; the five-key partial test
  (:146-157) gains the nil assert + its name's "five" arithmetic updated;
  the dialect tests (the `/dialect/` set the zai-data gate runs) re-pin their
  `to_h`/Dialect expectations with the 14th key (zai arm true, default false).
- `test/schemas_test.rb`: the compat reject table (:91-103) gains the
  supportsStrictMode non-boolean line; an accept case (boolean passes).
- `test/shapes_test.rb`: the ModelCompat block (:68-80) gains the
  new-attribute nil-default read + a set/get round-trip.
- `test/agent_loop_test.rb` :1304-1320: the compaction-summary-fails mock
  script gains a SECOND `{type: :error, status: 500, ...}` entry (I62's
  retry default consumes one script entry per attempt — both attempts now
  fail; the test's assertions otherwise unchanged). The I62 retry behavior
  itself is NOT touched (ruled gem-default at I62; `max_retries: 0` restores
  and is NOT taken here).
- `gems/tui-split-rig/test/registry_test.rb` :17: `SANCTIONED_NON_PATH`
  gains `"error-transcript-row-tail"` + `"pi-bug-report-hint"` (I60's OQ-1
  ratified classes; the deferred integrator ratification — makes the suite
  green at freeze).
- `test/bash_tool_test.rb`, `test/chat_test.rb`: NO changes expected (no
  PARAMETERS_SCHEMA references exist — grep-verified; if the lane finds one,
  PHASE 0-disclose it, don't silently bend).

**D7 — the live A/B vehicle (pre-made by the spec; the lane copies NOTHING).**
The script exists at space `tmp/e2-spec/repro_strict_sampling.rb` (spec-made,
sha256 frozen in AC): drives TART'S OWN stack (Models.load-shaped zai model
with the owner-catalog compat → wire_model → Agent::Chat with the four
tagged tools), one live turn against api.z.ai reading ZAI_API_KEY from the
env at runtime, prints the outgoing bash parameters digest + the assistant's
tool_call arguments, exits 0 iff the bash call CARRIES a numeric `timeout`;
ZERO secrets in any file. The lane's Builder Report carries the one-line run
instruction verbatim; the live run is the OWNER's landing step (env-class,
I59/I46 precedent; the verdict does not block on it).

### Named exclusions (Constraints, itemized)

- NO gem edits (repos/fast-llm out of bounds entirely): the lane CONSUMES the
  landed API; if the API proves wrong, PHASE 0-disagree with the ENTRY 1/I63
  verdict cited — never fork the machinery in-lane.
- NO non-strict wire byte moves (the fireworks/mock parity is byte-frozen):
  the standing wire-delta gate's `7360fd1e…` tools digest + instruction
  `2faaf667…` + session goldens must hold EXACT; D4's conversion is
  serialization-neutral by construction and D5's control pins it.
- NO release, NO version bump beyond D1's pin (the 0.4.0 cut + re-pin are the
  owner's); NO new gem dependencies; Gemfile.lock changes ONLY as the pin's
  lock consequence.
- NO strict emission for undeclared tools on non-strict dialects (the gem's
  D4 discipline, untouched); NO reordering of the four schemas' keys (pi's
  TypeBox order is a delta-audited standing divergence — reordering breaks
  the freeze).
- NO grammar half, NO provider detection, NO dialect vocabulary growth (gem
  boundaries, I63); the non-zai strict arm stays dropped (D3 boundary).
- NO changes to the rig scenarios/registry, render, session, compaction
  behavior, subagents, MCP, or hooks beyond D6's enumerated re-pins; builders
  never commit; the lane never touches the space repo.

### Output format

The lane reports raw results only: files added/changed; the full suite line
(`bundle exec rake test` runs/assertions/failures/errors/skips); the new
gates' outputs (strict-wire, strict-compat — runs + failures); the lock-deps
rebased gate output; the mock-wire capture's four sha256s as landed; the
PHASE 0 disagreement table (if any) with file:line cites both sides; and the
D7 one-line run instruction verbatim.

### Tool guidance

- Repo: `repos/tart`, base `project/pi-port` @ `195ae97`; integration target
  `project/pi-port`. Suite: `bundle exec rake test` (base measured 1168/1F —
  the E-2 registry pin; with D1+D6 applied the lane must be FULLY green).
- **Gem environment (load-bearing):** the canonical `repos/fast-llm` checkout
  is ON `project/pi-port` @ 7568589 (fast-completions 0.3.0 + strict) — work
  from the repo root with `FAST_COMPLETIONS_PATH` UNSET (the relative default
  `../fast-llm/gems/completions` resolves it) or explicitly pointed there;
  never at a v0.2.0-era tree (bundler fails, Grounds).
- Single-test runs: `bundle exec ruby -Ilib -Itest <file> [-n "/token/"]`
  (the zai-data gate form). Mock: `test/support/mock_llm_server.rb`
  (captured request bodies on `captured_requests`/`requests`).
- pi source of record: `repos/pi` @ `f1b2e77f5` (the four tool tags; zai.json
  glm compat). Gem API: fast-llm @ 7568589 `constrained_sampling.rb`,
  `tool.rb` :38-48, `dialects.rb`, `protocol.rb` :81-97 — cite line numbers
  in code comments as the existing files do.
- Do NOT burn live z.ai credits from the lane: D7's script is OWNER-run; the
  lane never executes it against the live endpoint.

### Boundaries

- Lane may touch (repo `tart`): the 12 files of the lanes block below.
  OUT OF BOUNDS: `repos/fast-llm` (any change), `lib/tart/mcp/**`,
  `lib/tart/agent/**` (the Chat seam is the gem's — no tart change needed;
  the compat threads through `wire_model` by construction), `lib/tart/
  settings.rb`, `bin/tart`, every rig scenario + `gems/tui-split-rig/
  registry.yml`, `test/support/mock_llm_server.rb`, all session goldens and
  frozen digests, and the space repo.
- The four `PARAMETERS_SCHEMA` constants' BYTES-on-the-wire are frozen: the
  conversion must be provably serialization-neutral (D5's control + the
  standing wire-delta gate).

### Lane plan

One lane — one flow, one test home, one pin.

```lanes
- name: core
  repo: tart
  touch:
    - Gemfile
    - Gemfile.lock
    - gems/tui-split-rig/test/registry_test.rb
    - lib/tart/models.rb
    - lib/tart/schemas/models.rb
    - lib/tart/shapes/model.rb
    - lib/tart/tools/bash.rb
    - lib/tart/tools/edit.rb
    - lib/tart/tools/read.rb
    - lib/tart/tools/write.rb
    - test/agent_loop_test.rb
    - test/models_test.rb
    - test/schemas_test.rb
    - test/shapes_test.rb
    - test/strict_sampling_test.rb
  effort: high
```

### Effort call

`high` — a cross-layer contract change (registry schema → shapes → dialect →
tool declarations → wire) with a byte-freeze bar on every non-strict path, a
mandated silent-failure-eliminating conversion, gem-behavior re-pins pulled
in by the pin bump, and the iteration's evidence gate living in a new
mock-wire harness — not a routine lane.

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
`architect rehearse strict-sampling-integration` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze strict-sampling-integration` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse strict-sampling-integration` — before the freeze, while
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
subsection per lane. A copy is written to build/I64-strict-sampling-integration-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section strict-sampling-integration prompt --append --lane <lane> --from build/I64-strict-sampling-integration-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I64-strict-sampling-integration-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence strict-sampling-integration --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section strict-sampling-integration verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify strict-sampling-integration`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
