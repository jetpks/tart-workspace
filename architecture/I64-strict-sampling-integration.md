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

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: I60's frozen 31-gate standing battery
carried forward (30 verbatim-modulo-rebase + scope rewritten) + 4 new
(strict-wire, strict-compat, live-script, and the rewritten scope) = 34.
Base = tart `project/pi-port` @ `195ae97`; gem source = the canonical
fast-llm checkout (`project/pi-port` @ `7568589`, fast-completions 0.3.0).

**Declared standing-gate rebases (commands byte-verbatim except these,
itemized):** `lock-deps` — the pin grep `'gem "fast-completions", "0.1.0"'`
→ `"0.3.0"` and the lock regex `\(0\.1\.0\)` → `\(0\.3\.0\)` (D1's own
letter); `threads-budget` — base `24e89ba` → `195ae97`; `scope` — rewritten
for this lane's 15-file touch set (the I63 diff-vs-base form: GREEN-vacuous
at base, bites post-lane). `ac:` labels moved to this iteration's map
(I60's own relabel precedent). The rig env prefix stays mandatory.

**The measured at-base vector (pre-declared; every member accounted).**
Base CANNOT bundle (Gemfile pins 0.2.0, the canonical checkout serves 0.3.0 —
`Bundler::GemNotFound`, Grounds) and cannot boot under the rig (measured:
the s1 rig command exits 2, tart `completed=false requests=0/1`). Therefore
at base: `suite`, `lock-deps`, `zai-data`, `thinking-pins`, `hermeticity`,
`wire-delta`, `session-golden`, all rig/scenario/probe gates
(s1–s10, s1-tart-mode, both pending/stream gates, s17, s18,
render-perf-*, zai-max-tokens-*) are RED for THE PIN CLASS (one root cause —
D1 is the cure; their bar is GREEN at the lane tree). GREEN controls at
base: `scope` (vacuous — HEAD == base) and `live-script` (the spec-pre-made
artifact). New gates RED at base: `strict-wire` (the test file does not
exist), `strict-compat` (0 matching test names — verified), `lock-deps`
(the 0.3.0 pin grep fails). `bench` is pin-class RED at base (bundle exec).

**AC1 — the pin + the green suite (D1, D6).** The Gemfile pins
`gem "fast-completions", "0.3.0"` with the `path: ENV.fetch(...)`
form + its comment block byte-identical; `Gemfile.lock` carries
`fast-completions (0.3.0)` and NO other dependency moved. The full suite
(`bundle exec rake test`) is GREEN at the lane tree — 0 failures, 0 errors —
with exactly the two declared suite-repairing moves: the E-2 registry
sanction (`SANCTIONED_NON_PATH` gains I60's two ratified s18 classes) and
the compaction-summary mock re-pin (the second scripted `:error`; I62's
retry default is otherwise untouched). Judge env note (I59/I60 standing
class): the three launcher/SystemPrompt pins inside `suite` are
environment-dependent (pinned-oracle PATH + unset PI_*) — if present in the
judge's env they adjudicate env-class, exactly as at I60.

**AC2 — the compat flow (D2, D3).** `supportsStrictMode` is CARRIED, not
tolerated: `Schemas::Models` accepts nil/true/false and rejects anything
else with the enumerated `expected a boolean` line on
`compat.supportsStrictMode`; `Shapes::ModelCompat` gains the nil-defaulted
`supports_strict_mode` attribute; `Models.build_compat` picks
`raw["supportsStrictMode"]`; `Models.dialect_for`'s ZAI arm threads it
(`compat.supports_strict_mode == true`) so a live-catalog-shaped entry
yields `Dialect#supports_strict_mode == true` on the wire model — and
`wire_model` mounts it on EVERY construction path by construction (no
per-path edits). `DEFAULT_DIALECT` and the non-zai arm stay non-strict
(the frozen boundary pinned: a non-zai compat declaring strict still yields
`DEFAULT_DIALECT`; `DEFAULT_DIALECT.supports_strict_mode == false`).

**AC3 — the four declarations (D4).** EXACTLY `Tart::Tools::{Bash, Read,
Edit, Write}` declare `constrained_sampling({"type" => "json_schema",
"strict" => "prefer"})` — pi's four @ f1b2e77f5, all "prefer", nothing
else; the inventory pin proves Find/Grep/Ls/ContactSupervisor/Memory/
Subagent/Mcp::Tool read nil. The four `PARAMETERS_SCHEMA` constants are
STRING-KEYED throughout and the loud pins hold: per tool,
`Fast::Completions::ConstrainedSampling.resolve_json_schema_strict_sampling(
tool, true) == true` (nil on re-symbolization — FAILS LOUD, never silently
inert), `parameters.keys.all?(String)`, `parameters["type"] == "object"`;
descriptions/property names/required lists/key order byte-preserved.

**AC4 — the wire (D5; the recorded-wire pair).** Through the real
`Agent::Chat` + `MockLLMServer` capture with a live-catalog-shaped zai
fixture (compat incl. `supportsStrictMode: true` + a tolerated
`supportsStore`): the four function objects ship the strict rewrite of
their parameters — EXACTLY the Grounds-frozen shapes, pinned by hash
equality AND the four sha256s (bash `a6c8a972…`, read `bfce07b5…`, edit
`e34ab9c2…`, write `e7565c49…` over `JSON.generate(parameters)`), key order
`[type, properties, required, additionalProperties]`, `"strict" => true`
immediately after `"parameters"` — and the undeclared tool in the same
loadout ships `"strict" => false` with parameters verbatim-equal to its
declared schema; `tool_stream: true` rides the request. The control — a
compat-less model (today's fireworks/mock shape) through the same loadout —
ships NO strict key on ANY function object with every parameters hash
verbatim-equal to its declared schema. The byte-freeze holds: the standing
`wire-delta` gate's tools digest `7360fd1e…` + instruction `2faaf667…` and
the session goldens are EXACT at the lane tree.

**AC5 — the battery + scope (the no-move bar).** The 30-gate standing
battery is green at the lane tree except the declared standing classes:
`s18-error-transcript` stays RED in its ratified hint-cut shape (I60 OQ-1),
and the I59/I60 env-class trio inside `suite` when run under the
pinned-oracle env. Exactly the 15 declared files change vs base `195ae97`;
the frozen paths (rig bin/lib/registry/scenarios, `lib/tart/agent/**`,
`lib/tart/mcp/**`, `lib/tart/render/**`, `settings.rb`, `print.rb`,
`compaction.rb`, `bin/`, `test/support/**`, `test/chat_test.rb`,
`test/bash_tool_test.rb`) are untouched.

**AC6 — the live vehicle (D7; owner-run, non-blocking).** The script exists
at space `tmp/e2-spec/repro_strict_sampling.rb` with sha256
`d2d5b8bf25202f79c0f006667b91095a69faaee4b563b7b6f8b7579f05dcfbd3`,
is syntactically valid, reads `ZAI_API_KEY` from the environment at runtime
(ZERO secrets recorded anywhere), drives tart's own stack (the compat shape
→ `wire_model` → `Agent::Chat` with the four tagged tools), and exits 0 iff
the assistant's bash tool call CARRIES a numeric `timeout`. The Builder
Report carries the one-line run instruction verbatim. The live run is the
OWNER's landing step — env-class per I59/I46 (no ZAI key in any loop-side
environment); the verdict does not block on it; problems.md is the feedback
channel if the live run disappoints (a 4xx on `strict:true` would be the
finding).

```gates
- id: suite
  ac: AC1
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
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC5
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
  ac: AC5
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
  ac: AC1
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.3.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.3\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC5
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
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 195ae97 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/parity-gate-s17; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s17 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s17/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(a["capture"]); ls = File.read(a["styled_capture"]); abort "#{app}: live header row missing" unless live.include?(" edit edit-bg.txt"); abort "#{app}: live removed diff row missing" unless live.include?("-2 line two bravo"); abort "#{app}: live added diff row missing" unless live.include?("+2 line two charlie (edited)"); abort "#{app}: live intra-line inverse missing" unless ls.include?("\e[7m"); abort "#{app}: live success-bg missing" unless ls.include?("\e[48;2;37;65;49m"); abort "#{app}: generic defect row present" if live.include?("\u23bf edit:"); rep = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture")); reps = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture.styled")); abort "#{app}: replay header row missing" unless rep.include?(" edit edit-bg.txt"); abort "#{app}: replay removed diff row missing" unless rep.include?("-2 line two bravo"); abort "#{app}: replay success-bg missing" unless reps.include?("\e[48;2;37;65;49m"); end; puts "S17_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S17_PARITY_OK

- id: render-perf-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0

- id: render-perf-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK

- id: zai-max-tokens-units
  ac: AC5
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

- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i59-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i59-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "tmp/i59-wire/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK

- id: error-transcript-units
  ac: AC5
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
  ac: AC5
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

- id: s18-error-transcript
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s18 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s18_error_transcript.yml --out tmp/parity-gate-s18; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s18 rig ec=$ec (declared-new: scenario+registry land with the lane)"; exit 1; }
    ruby -rjson -e 'out = "tmp/parity-gate-s18"; s = JSON.parse(File.read(File.join(out, "summary.json")))["runs"][0]; stage = File.join(out, "run-1"); %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(File.join(stage, "#{app}.capture")); rows = live.lines.map(&:chomp).grep(/^\s*Error: 400:/); abort "#{app}: live error row missing" unless rows.size == 1; abort "#{app}: live error row unpadded" unless rows[0].start_with?(" "); styled = File.read(File.join(stage, "#{app}.capture.styled")); srow = styled.lines.find { |l| l.include?("Error: 400:") }; abort "#{app}: styled error row missing" unless srow; abort "#{app}: styled error row lacks the error fg" unless srow.include?("\e[38;2;234;127;129m"); rep = File.read(File.join(stage, "#{app}.replay.capture")); abort "#{app}: replay error row missing" unless rep.lines.map(&:chomp).grep(/^\s*Error: 400:/).size == 1; end; tart = Dir[File.join(stage, "home/tart/.tart/sessions/*/*.jsonl")]; pis = Dir[File.join(stage, "home/pi/.pi/agent/sessions/*/*.jsonl")]; [tart, pis].each { |d| abort "want exactly 1 session file, got #{d.size}" unless d.size == 1 }; pi_entry = File.readlines(pis[0]).map { |l| JSON.parse(l) }.find { |e| e["type"] == "message" && e.dig("message", "role") == "assistant" }; abort "pi oracle failure entry missing" unless pi_entry&.dig("message", "stopReason") == "error" && pi_entry.dig("message", "errorMessage").to_s.start_with?("400:"); tl = File.readlines(tart[0]).map { |l| JSON.parse(l) }; abort "tart session must be 3 lines, got #{tl.size}" unless tl.size == 3; m = tl[2].dig("message"); abort "tart failure entry missing/misshapen: #{m.inspect}" unless m["role"] == "assistant" && m["content"] == "" && m["tool_calls"] == {} && m["finish_reason"] == "error" && m["error_message"].to_s.start_with?("400:"); puts "S18_ERROR_TRANSCRIPT_OK"'
  expect:
    exit_code: 0
    stdout_match: S18_ERROR_TRANSCRIPT_OK

- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]* runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,

- id: strict-compat
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/models_test.rb -n "/strict/" 2>&1 | grep -E "[1-9][0-9]* runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,

- id: live-script
  ac: AC6
  cwd: .
  cmd: |-
    test -f tmp/e2-spec/repro_strict_sampling.rb && [ "$(shasum -a 256 tmp/e2-spec/repro_strict_sampling.rb | cut -d' ' -f1)" = "d2d5b8bf25202f79c0f006667b91095a69faaee4b563b7b6f8b7579f05dcfbd3" ] && ruby -c tmp/e2-spec/repro_strict_sampling.rb >/dev/null && grep -q 'ENV.fetch\|ENV\["ZAI_API_KEY"\]' tmp/e2-spec/repro_strict_sampling.rb && ! grep -qE "sk-[A-Za-z0-9]{8}" tmp/e2-spec/repro_strict_sampling.rb && grep -q "CARRIES timeout" tmp/e2-spec/repro_strict_sampling.rb && echo LIVE_SCRIPT_OK
  expect:
    exit_code: 0
    stdout_match: LIVE_SCRIPT_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    git diff --quiet 195ae97 -- bin lib/tart/agent lib/tart/mcp lib/tart/render lib/tart/settings.rb lib/tart/print.rb lib/tart/compaction.rb gems/tui-split-rig/bin gems/tui-split-rig/lib gems/tui-split-rig/registry.yml gems/tui-split-rig/scenarios test/support test/chat_test.rb test/bash_tool_test.rb && ! git diff --name-only 195ae97 | grep -vE "^(Gemfile|Gemfile\.lock|gems/tui-split-rig/test/registry_test\.rb|lib/tart/(models\.rb|schemas/models\.rb|shapes/model\.rb|tools/(bash|edit|read|write)\.rb)|test/(agent_loop_test|models_test|schemas_test|shapes_test|strict_sampling_test)\.rb)$" | grep -q . && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

You are the builder for iteration `strict-sampling-integration` (I64), lane
`core`. Work ONLY in the provisioned worktree on branch
`lane/I64-strict-sampling-integration-core` (base tart `project/pi-port` @
`195ae97`); NEVER commit (the integrator lands your tree), NEVER touch the
space repo, NEVER push, NEVER touch `repos/fast-llm` (the gem is the landed
oracle — consume, never modify). The full iteration contract is the frozen
Grounds/Specification/Acceptance Criteria in this file (verbatim below) —
read them first; this header is the lane's operating brief. You are the
ONLY lane.

THE TASK IN ONE PARAGRAPH: make tart consume the landed gem's strict
machinery end-to-end — (D1) the Gemfile pin `0.2.0` → `0.3.0` + re-lock
(the landed source's declared version; the lane's FIRST act, nothing runs
without it); (D2) `supportsStrictMode` CARRIED through the compat chain
(schema validation boolean, `Shapes::ModelCompat#supports_strict_mode`
nil-defaulted 6th attribute, `build_compat` picks it); (D3) `dialect_for`'s
ZAI arm threads `supports_strict_mode:` into the Dialect (`compat.
supports_strict_mode == true`; the frozen `DEFAULT_DIALECT` singleton and
the non-zai arm UNTOUCHED); (D4) `Tart::Tools::{Bash,Read,Edit,Write}`
declare `constrained_sampling({"type" => "json_schema", "strict" =>
"prefer"})` with their `PARAMETERS_SCHEMA` constants converted to STRING
KEYS THROUGHOUT (the gem engine reads string keys — symbol keys make
"prefer" SILENTLY INERT, never ship that); (D5) the new
`test/strict_sampling_test.rb` (the mock-wire pair + the loud pins + the
compat-flow units); (D6) the six itemized re-pins (models/schemas/shapes
tests, the agent_loop compaction-summary mock's SECOND `:error` entry, the
registry_test `SANCTIONED_NON_PATH` one-liner); (D7) nothing — the live
script is pre-made, you only carry its run instruction into your report.

GEM ENVIRONMENT (load-bearing): the worktree's Gemfile resolves
fast-completions through `FAST_COMPLETIONS_PATH` — export it pointing at
the CANONICAL checkout `/Users/eric/architect/spaces/20261009-pi-port/
repos/fast-llm/gems/completions` (fast-completions 0.3.0 + the strict
machinery, branch `project/pi-port` @ 7568589) on EVERY bundle/rake/ruby
invocation, or run from the repo root with it unset IF your cwd layout
resolves `../fast-llm/gems/completions` there (a provisioned worktree does
NOT — export it). Do NOT pin or point at any v0.2.0-era tree.

PRE-MADE ARTEFACT (read-only for you): the live A/B script exists at space
`tmp/e2-spec/repro_strict_sampling.rb` (sha256 `d2d5b8bf…cfbd3`, frozen in
AC6) — you NEVER run it (no z.ai credits from the lane), NEVER copy it into
the repo, NEVER edit it; its one-line run instruction goes VERBATIM into
your Builder Report:
`cd <space>/repos/tart && ZAI_API_KEY=<key> bundle exec ruby <space>/tmp/e2-spec/repro_strict_sampling.rb`

FROZEN EXPECTATIONS (do not redesign; the frozen sections govern on any
conflict):
- The four strict-rewritten parameter shapes are PRE-COMPUTED and frozen in
  Grounds (bash `a6c8a972…`, read `bfce07b5…`, edit `e34ab9c2…`, write
  `e7565c49…`, sha256 over `JSON.generate(parameters)`); your wire test
  pins hash equality AND those digests. Key order after the rewrite is
  `[type, properties, required, additionalProperties]` (tart's declared
  order preserved — do NOT reorder to pi's TypeBox order; that would break
  the non-strict byte-freeze).
- Non-strict wire bytes are FROZEN: the compat-less model ships NO strict
  key with parameters verbatim; the standing wire-delta digest
  `7360fd1e…` + instruction `2faaf667…` + session goldens must hold EXACT
  at your tree. The string-key conversion is serialization-neutral by
  construction — prove it with D5's control, don't assume it.
- The untagged inventory is ITEMIZED (Grounds): Find/Grep/Ls/
  ContactSupervisor/Memory/Subagent/Mcp::Tool stay undeclared — pin that
  they read nil; do not "helpfully" tag anything else (pi tags exactly the
  four).
- The non-zai strict boundary is FROZEN (D3): a non-zai compat declaring
  supportsStrictMode still rides DEFAULT_DIALECT (I46's only-zai-arms
  shape) — pin it as a test, don't "fix" it.
- I62's retry default (`max_retries: 1`) is NOT touched: the compaction
  test re-pin adds a second scripted `:error` — take that path, never
  `max_retries: 0`.
- NO gem edits, NO new dependencies, NO rig scenario/registry changes, NO
  changes to lib/tart/agent/** (the compat threads through `wire_model` by
  construction — if you believe you need an agent/ change, that is a PHASE
  0 disagreement, record it, don't do it).

BUILD FREEDOM (layout only, behavior frozen): test example wording inside
test/strict_sampling_test.rb (the file must contain the mock-wire pair, the
loud pins, and the compat-flow units — group names yours), fixture shape
inside the test (inline JSON or test/fixtures file — if you add a fixture
file it enters the touch set via PHASE 0 disclosure), and the mock script
driving details.

VERIFICATION (run from the repo root with FAST_COMPLETIONS_PATH exported):
- Full suite: `bundle exec rake test` — base is UNBUNDLABLE (the pin
  defect — Grounds); at YOUR tree it must be FULLY green (0 failures, 0
  errors — D6's two suite-repairing re-pins are in your touch set).
- New gates (frozen forms): `bundle exec ruby -Ilib -Itest
  test/strict_sampling_test.rb` and `bundle exec ruby -Ilib -Itest
  test/models_test.rb -n "/strict/"` — both must report
  `[1-9][0-9]* runs, … 0 failures, 0 errors`.
- lock-deps (rebased): the 0.3.0 pin grep + lock regex + `env -u
  FAST_COMPLETIONS_PATH bundle install` — note the `env -u` means the
  canonical relative path must resolve from YOUR worktree: if it does not
  (worktree layout), run that install step with the canonical checkout
  staged so the relative default resolves — disclose which in the report.
- Smoke the standing wire-delta gate (`gems/tui-split-rig/bin/tui-split-rig
  run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire` +
  the digest ruby one-liner from the frozen block) at your tree before
  reporting — the `7360fd1e…` digest is the byte-freeze proof.

PHASE 0 PROTOCOL: before writing code, re-read the frozen Specification
D1–D7 against the repos (tart @ 195ae97, fast-llm @ 7568589, pi @
f1b2e77f5). If you believe a frozen claim misreads a source (the four pi
tags, the gem DSL shape, the compat chain, the frozen digests), STOP,
record the disagreement in your report (file:line cites both sides),
implement YOUR reading of the source of record, and flag it loudly. Same
for any gate you believe is vacuous or mis-authored.

REPORT (raw results only, no narrative): files added/changed; the full
suite line (runs/assertions/failures/errors/skips); the new gates' outputs;
the lock-deps output; the mock-wire capture's four sha256s as landed; the
wire-delta smoke result; the PHASE 0 disagreement table if any; and the D7
one-line run instruction verbatim.

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
