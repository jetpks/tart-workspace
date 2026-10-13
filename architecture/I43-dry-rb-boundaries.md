# I43: dry-rb-boundaries

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I43 dry-rb-boundaries

Program ENTRY 1 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding context folded in). All
measurements and probes this session (2026-10-13) at base **6d8a079**
(`project/pi-port` tip, I42 e2e-session merged — `git log --oneline -1`
re-run at spec time; working tree clean). Spec-time probes live in
`tmp/i43-probe1/` (gitignored; findings transcribed here).

## 1. Control (this session, base 6d8a079)

- Suite: `796 runs, 3268 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip); `SEAM_BENCH_OK`.
- Parity: the battery gates are the I42 judge's fresh-session cold record
  (14/14 on this exact tip, verdict 9607917); this session re-ran suite +
  bench only. Environmental carry-in (I41 Grounds 1): every frozen gate
  keeps the CANONICAL short out dirs — long out-dir prefixes are
  path-length artifacts, not evidence.
- Deps tree present in the local ruby (4.0.7, mise): dry-schema 1.16.0,
  dry-validation 1.11.1, dry-types 1.9.1, dry-core 1.2.0, dry-logic 1.6.0
  (+ dry-configurable 1.4.0, dry-inflector 1.3.1, zeitwerk 2.8.x,
  concurrent-ruby 1.3.8) — `gem list` this session; the tree resolves with
  no network. Reference source (read, never vendored): the 28 dry-rb
  clones at `~/architect/src/github.com/dry-rb/` (synced 2026-10-01);
  the exact clones read for this spec: `dry-schema` (1.16.0 —
  `lib/dry/schema.rb`, `examples/*.rb`), `dry-validation` (1.11.1 —
  `examples/*.rb`, `lib/dry/validation/contract.rb`), `dry-logic`
  (1.6.0 — `lib/dry/logic/predicates.rb`).

## 2. The letter's counts vs the verified boundary inventory

The plan letter's raise counts are approximate; the spec's enumeration is
the verified one (this session, `grep -nE "^\s*raise"` over the tree):

- **settings.rb (329 l)** — no raise statements at all. The hand-rolled
  surface: `resolve_setting` :131-133 (`env[Identity.env_key(...)] ||
  settings[key] || DEFAULTS[key]`), `resolve_context_window` :141-157
  (env digit regex + `Integer()`, file/model/registry integer guards),
  `resolve_thinking_level` :167-169 (`THINKING_LEVELS.include?` —
  vocabulary at :70), `model_reasoning_capable` :204-209 (`staged == true ||
  staged == "true"`), the known-models tables `MODEL_CONTEXT_WINDOWS` :91 /
  `MODEL_REASONING` :100 / `THINKING_LEVEL_MAPS` :109-115, `read_file`
  :311-321 (JSON.parse + BOM strip + not-a-Hash diagnostic), diagnostics
  classes :323-328 (parse failure / not an object / unknown key).
- **models.rb (320 l)** — no raise statements; the `validate*` family
  :262-318 produces the error-line list; `Config#error` set at :104-118
  (never raises, error names the file); `build_providers` :186-197,
  `build_model` :199-207, `build_thinking_level_map` :221-224 (symbolized
  keys, null kept, unknown level keys tolerated — I36).
- **mcp/config.rb (74 l)** — NINE raise statements (the letter says 10):
  :34 (JSON parse), :37 (root shape), :44 (per-server wrap), :52, :55,
  :58, :61, :63, :69 (pi's exact per-server strings, I07 AC4). All raise
  `ConfigError`; `load` prefixes `#{path}: `.
- **Tool input validation** (executable raise statements; the letter's
  counts 6/4/3/3 are close but off): bash.rb 4 (:95, :125 cwd ENOENT ×2 —
  RUNTIME, not input; :175 timeout — INPUT; :277 bare re-raise —
  cancellation), edit.rb 4 (:105 empty edits — INPUT; :116/:117/:119
  file-access — RUNTIME), ls.rb 3 (:44/:45/:51 — all RUNTIME path state),
  grep.rb 3 (:54/:65/:87 — all RUNTIME binary/path state), find.rb 3
  (:51/:54/:74 — all RUNTIME), read.rb 1 (:79 offset beyond EOF —
  RUNTIME file state), write.rb 0. So the pure INPUT-shape guards today
  are exactly TWO: bash `resolve_timeout` :175 and edit's empty-edits
  :105; everything else on the tools' raise lists is runtime outcome that
  schemas cannot and must not replace. ruby_llm's own `Tool#call` does
  arity-only validation first (gem tool.rb:313-320, message
  `Invalid tool arguments: …`) — that layer is the gem's, untouched.

## 3. The decisive pi precedents (read this session)

- **pi settings files are NOT validated** — `settings-manager.ts:126`:
  "Settings files are not validated; a malformed value replaces instead of
  throwing here." A schema that REJECTS or FILTERS settings-file values
  would diverge from the oracle on malformed input. The settings
  deliverable is therefore a TYPED VIEW + env-tier coercion, never a gate.
- **pi DOES validate tool inputs at the agent loop** —
  `packages/ai/src/utils/validation.ts:317-342` (`validateToolArguments`:
  normalizeOptionalNulls → Value.Convert coercion → TypeBox compile check
  → throws `Validation failed for tool "<name>":\n  - <path>: <message>\n
  \nReceived arguments:\n<pretty JSON>`), driven from
  `agent-loop.ts:725-777` (`prepareToolCall` catches → immediate ERROR
  tool result). The port's tool-input schemas are the internal analog of
  this layer (the port's loop is the gem's, so the port's validation rides
  the tool boundary).
- **The two pinned in-tool messages are pi's own**, checked AFTER pi's
  loop validation passes: `bash.ts:29-37` (`resolveTimeoutMs`: not-finite
  or <= 0 → `Invalid timeout: must be a finite number of seconds`; a
  >2147483.647s tier exists in pi and is a pre-existing unpinned port CUT —
  stays cut this iteration) and `edit.ts:138` (`Edit tool input is
  invalid. edits must contain at least one replacement.`).

## 4. dry-rb API facts verified by probe (tmp/i43-probe1/p1..p8.rb)

- `Dry::Schema.JSON` coerces JSON types, coerces STRING keys → symbol
  recursively under string-keyed roots, and returns symbolized output
  (p1/p3/p6); symbol top-level keys also pass (p7). CAVEAT: nested
  string keys under a SYMBOL-keyed top level are NOT coerced (p7) —
  normalize keys before validating nested wildcards (edit's
  `normalize_edit_shapes` already does exactly this).
- `Dry::Validation::Contract` rules carry exact arbitrary failure strings
  via `key.failure("…")` (p3/p5) — the home for pi-exact messages. A rule
  whose key failed schema validation is skipped (p8) — exact strings that
  must fire on shape failures need either base rules or boundary mapping.
- `Contract#call` RAISES `ArgumentError` on non-Hash input
  (`contract.rb:170` `validate_input_type`, p8) — root-object guards stay
  at the boundary (both config loaders already have them).
- Number type: `maybe([:integer, :float])` sum type (p5); no `finite?`
  predicate in dry-logic 1.6 — finiteness rides a rule (p5 reproduces the
  bash message byte-exactly). `min_size?: 1` + `each { hash … }` for the
  edits shape (p5/p6).
- `config.validate_keys = false` tolerates unknown keys (p3) — required
  for models.json (pi's TypeBox additionalProperties default) and the
  settings view.

## 5. Frozen goldens — today's exact error strings at base (the
   error-equivalence contract; captured by
   `tmp/i43-probe1/capture_goldens.rb` this session, base 6d8a079)

models.json (`Models.load(root:).error` — header `Invalid models.json
schema:\n` + lines + `\n(<path>)`; only the line list varies):

| fixture body | error lines |
|---|---|
| `[1,2]` | `  - root: expected a JSON object` |
| `{}` | `  - providers: expected an object of providers` |
| `{"default": 5}` | `  - default: expected a "provider/model-id" string` ; `  - providers: expected an object of providers` |
| `{"providers": 5}` | `  - providers: expected an object of providers` |
| `{"providers": {"a": 5}}` | `  - providers.a: expected an object` |
| `{"providers": {"a": {"name": 5, "baseUrl": 5, "apiKey": 5, "api": 5}}}` | `  - providers.a.name: expected a string` ; `…baseUrl` ; `…apiKey` ; `…api` (that order) |
| `{"providers": {"a": {"models": 5}}}` | `  - providers.a.models: expected an array` |
| `{"providers": {"a": {"models": [5]}}}` | `  - providers.a.models[0]: expected an object` |
| `{"providers": {"a": {"models": [{}]}}}` , `…[{"id": ""}]` | `  - providers.a.models[0].id: required non-empty string` |
| `{"providers": {"a": {"models": [{"id": "m", "name": 5, "reasoning": 5, "contextWindow": 0, "maxTokens": -1}]}}}` | `…models[0].name: expected a string` ; `…reasoning: expected a boolean` ; `…contextWindow: expected a positive integer` ; `…maxTokens: expected a positive integer` |
| `…"thinkingLevelMap": "high"` | `  - providers.a.models[0].thinkingLevelMap: expected an object` |
| `…"thinkingLevelMap": {"low": 5}` | `  - providers.a.models[0].thinkingLevelMap.low: expected a string or null` |
| `{"default": 5, "providers": {"a": {"name": 5, "models": [{"id": ""}, {"id": "m", "thinkingLevelMap": {"low": 5}}]}}}` | default ; a.name ; models[0].id ; models[1].thinkingLevelMap.low (multi-error interleave, that order) |

Valid catalog parse: entry `{id: "m", name: "m", reasoning: true,
context_window: nil, max_tokens: nil, thinking_level_map: {off: nil, low:
"low", madeup: "x"}, provider: "glm"}` — the symbolization pin.

mcp.json (`Mcp::Config.load(path)` — `ConfigError` message, prefixed
`#{path}: `):

| fixture | message after prefix |
|---|---|
| `[1, 2]` root / `{"mcpServers": "nope"}` | `expected an object with an "mcpServers" object` |
| `{"mcpServers": {"x": "nope"}}` | `server "x" must be an object` |
| `{"x": {"command": "c", "args": "nope"}}` / args `[1]` | `server "x": args must be an array of strings` |
| `…"env": {"a": 1}` | `server "x": env must map names to strings` |
| `…"cwd": 3` | `server "x": cwd must be a string` |
| `…"url": "https://e/mcp"` | `server "x": streamable HTTP transport is not supported (stdio only)` |
| `{"x": {"args": []}}` | `server "x" needs either "command" (stdio) or "url" (streamable HTTP)` |
| valid entry | returns `{command:, args: [], env: nil, cwd: nil}` shape, no error |
| `{}` (no mcpServers key) | returns `{}`, no error |
| malformed JSON | parser message passthrough after prefix (mcp_test pins the prefix) |
| servers `{"a": "nope", "b": {…valid…}}` | the FIRST server's error wins (fail-fast, iteration order) |

Settings diagnostics (pinned by settings_test): `invalid settings JSON:
#{e.message}` / `settings file is not a JSON object` / `unknown settings
key: #{key}` — each as `Diagnostic(type: "warning", path:)`. Tool input
pins: bash `Invalid timeout: must be a finite number of seconds`
(bash_tool_test:73), edit `Edit tool input is invalid. edits must contain
at least one replacement.` (golden_parity_test edit goldens +
edit.ts:138), ls `Path not found:` (tools_test:39).

## 6. Where the resolution chain is consumed (settings integration facts)

`resolve_setting` callers: bin/tart :396/:417/:418/:515/:516 (apiKey,
defaultProvider, defaultModel, apiBase, apiKey again);
`resolve_context_window`: bin/tart :299/:434, agent/loop.rb :179 (env
tier inside the loop); `resolve_thinking_level`: bin/tart :427/:450;
`declared_thinking_level`: render/chat.rb :1863; `load`:
bin/tart :197/:240. Diagnostics surface through `report_diagnostics`
(bin/tart :461-466) — stderr (print) or `command_line` (interactive) — so
the settings diagnostic set MUST NOT grow new classes (zero byte moves).
`Settings.load`'s merged hash composition (DEFAULTS deep-merged user
deep-merged project, defaultTools merged separately) is consumed by the
whole launcher; its byte-shape for well-formed inputs is part of the
contract (settings_test + launcher_smoke_test + rig staging).

## 7. Open questions (itemized for the judge; resolved by plan letter in
   the Specification — none blocking)

- **OQ-1 (tool-input failure vocabulary).** pi's loop-level validation
  message (`Validation failed for tool "<name>": …`) does not exist in the
  port today; the pinned in-tool messages (bash timeout, edit empty) do.
  Specification ruling: the pinned in-tool messages stay byte-exact (they
  are pi's own tool-level messages); NEW shape failures that pi's loop
  would have caught adopt pi's wrapper shape with dry's detail text (the
  TypeBox prose is not cloned — approximation itemized). Judge may
  re-rule.
- **OQ-2 (settings malformed-value semantics).** Drop-to-default vs
  flows-through: pi is flows-through (settings-manager.ts:126). The
  Specification rules flows-through (schema = typed view + env coercion,
  never a filter) — zero divergence. Judge may re-rule.
- **OQ-3 (mcp fail-fast vs collect-all).** Today `load` raises on the
  FIRST invalid server (each_with_object + rescue/re-raise). The
  Specification preserves fail-fast first-error semantics (not a collect-
  all) — pi's per-file error collection is close to collect-all, but the
  port's pinned tests assert single messages; preserving the port's shape
  is the zero-change read of the letter ("observable error behavior …
  stays equivalent where tests pin it"). Judge may re-rule.

## Specification

# Specification — I43 dry-rb-boundaries

## Objective

Establish the dry-rb validation pattern in tart (program ENTRY 1,
`build/loop/plan-20261013T092136Z.md`): dry-schema/dry-validation at every
parsing boundary — settings resolution, models.json, mcp.json, and tool
input args — replacing the hand-rolled fetch-chain type logic and raise
walls. This is the PATTERN-SETTER: where schemas live, how they are named,
and the error discipline every later dry-rb iteration (ENTRY 2 shapes,
ENTRY 3 flow) inherits. Parity track: internal only — ZERO observable
byte moves on screen or wire for every input the parity battery, the
suite, and the e2e instruments exercise (BRIEF §8; the §8 rig measures
settled screens, so an internal validation swap must leave s1–s10 +
probes byte-identical). Pinned error strings are preserved byte-exactly;
unpinned malformed-input corners are re-pinned CONSCIOUSLY (Grounds §7).

## The pattern contract (binding on every later dry-rb iteration)

- **Home + naming.** One module family under `lib/tart/schemas.rb`
  (aggregate require, house style of `lib/tart/mcp.rb`) +
  `lib/tart/schemas/{settings,models,mcp,tools}.rb`, namespace
  `Tart::Schemas`, one member module per boundary: `Tart::Schemas::
  Settings`, `Tart::Schemas::Models`, `Tart::Schemas::Mcp`,
  `Tart::Schemas::Tools`. Contracts are `Dry::Validation::Contract`
  subclasses or `Dry::Schema` processors, INSTANTIATED ONCE at module
  load (frozen instances or memoized `.new` — never re-defined per call).
  `lib/tart.rb` gains `require_relative "tart/schemas"`; consumers
  (`settings.rb`, `models.rb`, `mcp/config.rb`, `tools/*.rb`) require
  their own schema file directly (the existing require discipline).
- **Flavor.** JSON-flavored schemas (`Dry::Schema.JSON` / contract `json
  do … end`) for everything originating in JSON text; plain kwargs for
  tool inputs arrive symbol-keyed (normalize nested wildcard keys before
  validating — Grounds §4's caveat).
- **Error discipline (the rule later iterations copy).**
  1. Contracts validate SHAPE. Semantic floors, clamps, and precedence
     arithmetic stay in the consuming module (pi parity: pi's loop
     validates shape; the tools clamp semantics).
  2. Where a PINNED message exists (Grounds §5), the exact string is
     produced — by a contract rule firing `key.failure(<pinned string>)`
     when the rule sees the values, or by a message map living WITH the
     schema module. Never dry's default prose for a pinned surface.
  3. New/unpinned failure vocabulary adopts pi's agent-loop wrapper
     shape (Grounds §3): `Validation failed for tool "<pi-name>":\n  -
     <path>: <detail>\n\nReceived arguments:\n<pretty JSON>` for tool
     inputs; dry's detail text is accepted (the TypeBox prose is not
     cloned — itemized approximation).
  4. A boundary NEVER raises where it did not raise before, and never
     returns a different surface class (ConfigError stays ConfigError;
     {error:} stays {error:}; Settings diagnostics keep their three
     pinned classes — no new diagnostic kinds).
  5. `Dry::Validation::Contract#call` raises on non-Hash input
     (Grounds §4) — root-object guards stay at the boundary before the
     contract call.
- **Tolerance.** Unknown keys are tolerated wherever today's code
  tolerates them (models.json — pi TypeBox additionalProperties default;
  settings files — pi settings-manager.ts:126; tool inputs pass through
  the gem's arity gate first). `config.validate_keys = false`.
- **No filtering of settings values.** pi: "Settings files are not
  validated; a malformed value replaces instead of throwing"
  (settings-manager.ts:126). The settings schemas TYPe and COERCE; they
  never drop, never reject, never add diagnostics (Grounds §6: the
  diagnostic set is observable stderr/transcript).

## Boundary contracts

### B1 — Settings resolution (lib/tart/settings.rb + schemas/settings.rb)

`Tart::Schemas::Settings` carries:
- **The carried-key view**: one JSON-flavored schema typing the port's
  settings keys (`identity`, `defaultModel`, `defaultProvider`,
  `apiBase`, `apiKey`, `contextWindow`, `thinkingLevel`, `compaction
  {enabled, reserveTokens, keepRecentTokens}`, `modelReasoning`,
  `defaultTools`) with today's effective types (Strings; apiKey
  string-or-nil; contextWindow integer-or-nil; thinkingLevel in
  `Settings::THINKING_LEVELS`; compaction booleans/positive integers;
  modelReasoning true|false|"true"|"false"|nil; defaultTools an array of
  strings). TOLERANT (`validate_keys = false`) and NON-FILTERING — it is
  the typed documentation of the file shape, applied for validation
  reporting only where the letter's no-behavior-change rule allows (i.e.:
  nowhere observable — it must not gate `Settings.load`).
- **The resolution contracts** replacing today's hand-rolled type logic,
  consumed by the resolution helpers, preserving each helper's public
  signature and outcome table EXACTLY:
  - `resolve_context_window` (:141-157): the env tier's digit-string →
    Integer coercion and the file/model tiers' `Integer && positive?`
    guards expressed as contracts (Params-style integer coercion for the
    env tier; JSON integer+gt? 0 for file/model). A value failing its
    contract tier reads as ABSENT at that tier (falls through — today's
    regex/guard outcomes, not new rejections).
  - `resolve_thinking_level` (:167-169) and `declared_thinking_level`
    (:185-189): the `THINKING_LEVELS.include?` vocabulary check via the
    view's thinkingLevel contract.
  - `model_reasoning_capable` (:204-209): the `staged == true || staged
    == "true"` truthiness rides the modelReasoning contract (values
    outside true|false|"true"|"false" read as unstaged — today's
    behavior).
  - `resolve_setting` (:131-133): the `env || settings || DEFAULTS`
    precedence arithmetic STAYS in Settings (pi's semantics; a schema
    cannot express three-source `||` honestly); the env tier's value is
    documented by the string-key contracts.
- Unchanged: `read_file` (BOM strip, JSON.parse, the three pinned
  diagnostic messages), `deep_merge`, `merge_default_tools`,
  `selected_tools`/modifier semantics, `compaction_kwargs` composition,
  `save`, the known-models tables (their CONTENT and freezing), and the
  `Result{settings, diagnostics}` shape.

### B2 — models.json (lib/tart/models.rb + schemas/models.rb)

`Tart::Schemas::Models.validate(parsed)` replaces the hand-rolled
`validate*` family (:262-318, deleted): a root guard (non-Hash → `  -
root: expected a JSON object`) + one dry-validation contract over the
parsed root producing, on failure, TODAY'S EXACT ERROR LINES in TODAY'S
EXACT ORDER (Grounds §5's fixture table is the frozen contract — the
`Invalid models.json schema:\n` + `\n(<path>)` wrapping stays in
`Models.load`). Iteration order = parsed insertion order; per-server
check order = fields (name, baseUrl, apiKey, api) then models array then
per-model (id, name, reasoning, thinkingLevelMap, contextWindow,
maxTokens). Failures never raise — `Config#error` as today. The valid
path: `build_providers`/`build_model` outputs byte-identical (the entry
hash shape, reasoning `== true`, context_window/max_tokens passthrough),
`build_thinking_level_map` symbolization unchanged (keys `to_sym`, null
kept, unknown level keys tolerated, non-Hash → nil).

### B3 — mcp.json (lib/tart/mcp/config.rb + schemas/mcp.rb)

`Tart::Schemas::Mcp` (a contract + exact-string rules) replaces
`validate_server!`'s hand-rolled checks (:52-69) and the root shape
check (:37): `Config.load` keeps file IO, JSON.parse rescue
(`ConfigError, "#{path}: #{e.message}"`), the non-Hash/mcpServers-shape
root guard (pinned string), calls the contract, and on ANY failure
raises `ConfigError, "#{path}: #{first failure text}"` — FIRST failure
in today's evaluation order (servers in insertion order; within a
server: must-be-an-object → args → env → cwd → url → command), i.e.
fail-fast preserved (Grounds §7 OQ-3's ruling). The 6 per-server pinned
strings (Grounds §5) come from the contract's rules byte-exactly. The
normalized success output `{command:, args: [], env:, cwd:}` shape is
unchanged. `ConfigError`, `DEFAULT_PATH`, the public `load(path)` /
`validate_server!` signatures stay (validate_server! may delegate to the
contract but must keep raising the same strings — mcp_test calls
`Mcp::Config.load` only).

### B4 — Tool inputs (lib/tart/tools/*.rb + schemas/tools.rb +
safe_execute.rb)

`Tart::Schemas::Tools` defines one input contract per tool — ALL SEVEN
built-ins (read, bash, edit, write, ls, grep, find) — mirroring each
tool's JSON-Schema declaration shapes (the declarations themselves STAY
byte-identical, wire-unchanged):
- read: `path` required string; `offset`/`limit` optional integers.
- bash: `command` required string; `timeout` optional integer-or-float,
  with the FINITE/POSITIVE rule firing the pinned `Invalid timeout:
  must be a finite number of seconds` (replaces `resolve_timeout`'s
  raise :175; pi's >2147483.647s second tier stays CUT as today).
- edit: `path` required string; `edits` required — the not-an-array and
  empty cases fire the pinned `Edit tool input is invalid. edits must
  contain at least one replacement.` (replaces the raise at :105); each
  item `{old_text, new_text}` must be a string WHEN PRESENT — but EMPTY
  STRINGS and nil-shapes flow to EditDiff exactly as today (the
  `oldText must not be empty in …` golden is EditDiff's, not the
  schema's — do not steal it).
- write: `path`, `content` required strings.
- ls: `path` optional string; `limit` optional integer.
- grep: `pattern` required string; `path`/`glob` optional strings;
  `ignoreCase`/`literal` optional booleans; `context`/`limit` optional
  integers. Semantic floors stay in the tool (context ≤ 0 → 0; limit
  clamp `[1, limit].max`).
- find: `pattern` required string; `path` optional string; `limit`
  optional integer.
Validation runs at the TOP of each `execute`, inside `safe_execute`,
before the runtime work: failure → `return {error: <message>}` where
<message> is the pinned in-tool string where one exists (bash timeout,
edit edits) and pi's loop-level wrapper shape (pattern rule 3) for NEW
shape failures. The seam is ONE shared helper (SafeExecute class-method
or module function, e.g. `validate_input(contract, pi_name:, **)`)
— seven tools, one idiom. NO COERCION (pi's Value.Convert string→number
coercion is NOT ported — today's port rejects wrong-typed numbers and
the zero-change rule keeps that; the pi-coercion gap is itemized and
queued). RUNTIME raises stay raises, untouched: bash cwd ENOENT ×2,
edit's file-access trio, ls path/directory/read trio, grep rg-binary/
exit/path, find fd-binary/path, read's offset-beyond-EOF — none of these
is input shape. `Edit#call`'s `normalize_arguments` (pi
prepareEditArguments) stays BEFORE validation; validation sees the
normalized kwargs.

## Dependency changes

`tart.gemspec` gains `spec.add_dependency "dry-schema", "~> 1.16"` and
`spec.add_dependency "dry-validation", "~> 1.11"` (BRIEF §2 frozen
stack unchanged otherwise). The transitive tree (dry-core, dry-logic,
dry-types, dry-configurable, dry-inflector, zeitwerk, concurrent-ruby)
is accepted per the program letter; `Gemfile.lock` regenerates and is
committed. No path/git vendoring of the reference clones. No
`required_ruby_version` change. Deps are PRODUCTION deps (lib requires
them at boot), not dev deps.

## New unit pins (test/schemas_test.rb + additive pins in the touched
test files)

- **Accept/reject tables per boundary** — every fixture in Grounds §5
  (both config files, both valid and every invalid row) asserting the
  EXACT strings through the public APIs (`Models.load`,
  `Mcp::Config.load`); plus the tool-input table (bash timeout −1 /
  Float::INFINITY / "x"; edit empty/not-array edits/valid/legacy shapes
  through `Edit#call`; each tool's required-arg and wrong-typed-arg
  rejections with the wrapper message; each tool's valid acceptance).
- **Settings precedence matrix** — for each of defaultModel /
  defaultProvider / apiBase / apiKey / modelReasoning: env-only /
  file-only / default-only / env+file / env+default / file+default /
  all / none combinations, and both identities (PI_/TART_ prefixes),
  asserting resolved values identical to today (existing
  settings_test pins stay green untouched — the matrix ADDS the cross
  product); the contextWindow ladder (explicit > env digit-string >
  file integer > model > known table > nil) incl. the non-digit env and
  non-positive file fall-throughs; thinkingLevel in/out of vocabulary;
  declared_thinking_level project-over-user.
- **thinkingLevelMap symbolization** — the I36 pin stays green
  untouched (symbolized keys, null kept, unknown level keys tolerated)
  and the schema-path equivalent is added via a catalog fixture.
- **No-filter pin** — a settings file carrying type-invalid values for
  known keys (e.g. `"contextWindow": "abc"`, `"thinkingLevel": 5`)
  still lands those values in `Result#settings` verbatim (pi:126
  flows-through; the schema is a view, not a gate).

## Tool guidance (verify against live deps before writing code)

- Read the exact installed versions' sources first: reference clones at
  `~/architect/src/github.com/dry-rb/{dry-schema,dry-validation,
  dry-logic}` (1.16.0 / 1.11.1 / 1.6.0 — Grounds §1) — do not invent
  against old dry-rb folklore (no `Dry::Validation.Schema`, no
  `Schema.with` pre-1.14 idioms, no `Type::Strict` strings).
- Probed idioms that work on this exact stack (Grounds §4):
  `Dry::Schema.JSON do … end`; `config.validate_keys = false`;
  `maybe([:integer, :float])`; `rule(:key) { key.failure("exact …") }`;
  `optional/required`; `each { hash … }`; `min_size?`; `gt?`;
  `included_in?` (vocabulary). Contract `#call` raises on non-Hash —
  guard roots.
- Verification (exact, per repo): `bundle install --quiet && bundle
  exec rake` (suite; default task), `bundle exec ruby bench/
  seam_bench.rb` (SEAM_BENCH_OK), `gems/tui-split-rig/bin/tui-split-rig
  run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<canonical-short-
  dir>` for s1–s10 + the two `--gate` probes (cold; s1_tart exits 1 by
  design — the staged identity work list, I39 ruling).

## Boundaries

**May touch** (the lane's enumerated file set — the ```lanes block is
the frozen source of truth): `tart.gemspec`, `Gemfile.lock`,
`lib/tart.rb`, `lib/tart/schemas.rb`, `lib/tart/schemas/{settings,
models,mcp,tools}.rb` (new), `lib/tart/settings.rb`,
`lib/tart/models.rb`, `lib/tart/mcp/config.rb`,
`lib/tart/tools/safe_execute.rb`, `lib/tart/tools/{bash,edit,read,
write,ls,grep,find}.rb`, `test/schemas_test.rb` (new),
`test/{settings,models,mcp,tools,bash_tool}_test.rb` (additive only).

**Must not touch**: everything else, in particular — `gems/
tui-split-rig/**` (no rig work); the wire JSON-Schema tool declarations
(every `PARAMETERS_SCHEMA` / `DESCRIPTION` constant byte-identical —
wire-unchanged by the letter); `lib/tart/agent/**`, `lib/tart/render/**
`, `lib/tart/print.rb`, `bin/tart`, `lib/tart/identity.rb`,
`lib/tart/mcp/{client,stdio,tool,jsonrpc}.rb`; `lib/tart/tools/
registry.rb`, `support/**` (registry semantics and edit-diff are
runtime, not input shape); `test/golden_parity_test.rb`,
`test/e2e_session_test.rb`, `test/launcher_smoke_test.rb`,
`test/agent_loop_test.rb`, `test/session_test.rb` (all frozen pins stay
green untouched); `bench/**`.

**Out of scope** (itemized, not lost): pi's loop-level string→number
coercion (Value.Convert) for tool args; pi's bash >2147483.647s timeout
tier (stays cut); session-entry dry-struct shapes (ENTRY 2); Agent::
Loop/MCP-client dry-monads (ENTRY 3); any settings diagnostic growth;
any new settings-file rejection; MCP collect-all error semantics.

## Lane plan

ONE lane (single-writer — the pattern must land coherently; chat-side
files untouched):

- **schemas** — target `repos/tart`, the full touch set above, the whole
  objective. Effort: HIGH at dispatch (cross-cutting pattern-setter,
  4 boundaries + deps + the pattern contract).

```lanes
- name: schemas
  repo: tart
  touch:
    - tart.gemspec
    - Gemfile.lock
    - lib/tart.rb
    - lib/tart/schemas.rb
    - lib/tart/schemas/settings.rb
    - lib/tart/schemas/models.rb
    - lib/tart/schemas/mcp.rb
    - lib/tart/schemas/tools.rb
    - lib/tart/settings.rb
    - lib/tart/models.rb
    - lib/tart/mcp/config.rb
    - lib/tart/tools/safe_execute.rb
    - lib/tart/tools/bash.rb
    - lib/tart/tools/edit.rb
    - lib/tart/tools/read.rb
    - lib/tart/tools/write.rb
    - lib/tart/tools/ls.rb
    - lib/tart/tools/grep.rb
    - lib/tart/tools/find.rb
    - test/schemas_test.rb
    - test/settings_test.rb
    - test/models_test.rb
    - test/mcp_test.rb
    - test/tools_test.rb
    - test/bash_tool_test.rb
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
`architect rehearse dry-rb-boundaries` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze dry-rb-boundaries` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse dry-rb-boundaries` — before the freeze, while
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
subsection per lane. A copy is written to build/I43-dry-rb-boundaries-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section dry-rb-boundaries prompt --append --lane <lane> --from build/I43-dry-rb-boundaries-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I43-dry-rb-boundaries-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence dry-rb-boundaries --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section dry-rb-boundaries verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify dry-rb-boundaries`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
