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

# Acceptance Criteria — I43 dry-rb-boundaries

Gate calibration (pre-declared): **RED at base BY DESIGN** — `deps-pin`,
`schemas-presence`, `tool-input-vocab` (the dry deps, the schema family,
and the new failure vocabulary do not exist at 6d8a079); they must be
GREEN on the integrated tree, non-vacuously. **Regression guards (GREEN
at base, must stay GREEN)** — `suite`, `bench`, `s1`–`s10`,
`s1-tart-mode`, both probe gates, `wire-declarations`, `error-goldens`
(today's behavior IS the contract; the parity battery proves zero
observable byte moves). The s-gates keep the CANONICAL short out dirs
(I41 Grounds 1's environmental note). The KNOWN s9 lane-worktree
deep-path artifact (I34/I36/I39/I40/I42 precedent, five confirmations)
does not fail this iteration when the same tree exits 0 at canonical
depth — the judge runs the battery on the integrated tree.

**AC1 (the pattern lands).** `Tart::Schemas` exists at the specified
home (`lib/tart/schemas.rb` + `schemas/{settings,models,mcp,tools}.rb`)
with the four boundary members, contracts instantiated once at load;
`tart.gemspec` declares `dry-schema ~> 1.16` + `dry-validation ~> 1.11`
as PRODUCTION deps; `Gemfile.lock` carries them plus the accepted
transitive tree. The pattern contract (naming, JSON flavor, error
discipline rules 1–5, key tolerance, settings no-filtering) is followed
by all four boundaries. Pinned by `deps-pin` + `schemas-presence` +
judge read of the diff.

**AC2 (settings equivalence).** Every resolution outcome is unchanged:
the env > project > user > defaults precedence exactly (env tier rides
the identity namespace), pi's settings-manager.ts:126 flows-through
preserved (type-invalid file values land in `Result#settings` verbatim —
no filtering, no new diagnostics, no new rejections), the
non-digit-env / non-positive-file context-window fall-throughs
unchanged, the thinking-vocabulary and modelReasoning truthiness
outcomes unchanged, `read_file`/`deep_merge`/`save`/modifier semantics
untouched. Pinned by the new precedence-matrix + no-filter unit pins
and the existing settings pins green UNTOUCHED; spot-pinned by
`error-goldens`.

**AC3 (models.json equivalence).** `Models.load` produces, for every
Grounds §5 fixture, TODAY'S EXACT error string (header, line order incl.
the multi-error interleave, path suffix); valid catalogs parse to
byte-identical entries (the I36 symbolization semantics hold); the
loader still never raises (error-as-field); the hand-rolled `validate*`
family is deleted (the contract replaces it). Pinned by the
accept/reject unit tables + `error-goldens`.

**AC4 (mcp.json equivalence).** `Mcp::Config.load` raises
`ConfigError` with the EXACT pinned strings (root shape, the six
per-server messages — Grounds §5) for every fixture, fail-fast on the
FIRST invalid server in insertion order; the parser-error passthrough
and the normalized success output are unchanged. Pinned by the exact-
string unit table (mcp_test stays green untouched) + `error-goldens`.

**AC5 (tool inputs).** All seven built-in tools validate their inputs
through the ONE shared seam at the top of `execute` (inside
`safe_execute`): bash `timeout` −1 / Float::INFINITY and edit's
empty/not-array `edits` return the two PINNED messages byte-exactly;
new shape failures (wrong-typed args on any tool) return pi's
loop-level wrapper vocabulary (`Validation failed for tool "<name>":
…Received arguments:…`); RUNTIME raises (cwd/path/binary/EOF/file-access
families) stay raises, untouched; `Edit#call`'s normalize_arguments
runs before validation; NO coercion is added; the wire JSON-Schema
declarations are byte-unchanged (`PARAMETERS_SCHEMA`/`DESCRIPTION`
constants; the captured request's tools array hash-pinned). Pinned by
`tool-input-vocab` + `wire-declarations` + the unit tables + the
golden_parity pins green untouched.

**AC6 (parity + regression + scope).** The default rake task fully
green with new additive pins (run count > 796); `SEAM_BENCH_OK`; s1–s10
exit 0 cold at the canonical out dirs; `s1-tart-mode` completes
(TART_MODE_OK); both probe gates OK (TOOL_PENDING_GATE_OK,
USER_BASH_STREAM_GATE_OK); the integrated diff vs **6d8a079** touches
EXACTLY the lane's declared file set — no `gems/tui-split-rig/**`, no
frozen test file, no `bin/tart`, no render/agent/print file.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i43-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i43-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-declarations
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i43-wire && ruby -rjson -rdigest -e 'req = JSON.parse(File.readlines("tmp/i43-wire/run-1/tart-requests.jsonl")[0]); tools = req["body"]["tools"]; names = tools.map { |t| t.dig("function","name") }; abort "loadout: #{names.inspect}" unless names == %w[read bash edit write]; digest = Digest::SHA256.hexdigest(JSON.generate(tools)); abort "tool declarations moved on the wire: #{digest}" unless digest == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_DECLARATIONS_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DECLARATIONS_OK

- id: error-goldens
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; Dir.mktmpdir do |dir|
      models = lambda do |body|
        File.write(File.join(dir, "models.json"), body)
        Tart::Models.load(root: dir).error
      end
      multi = models.call(%({"default": 5, "providers": {"a": {"name": 5, "models": [{"id": ""}, {"id": "m", "thinkingLevelMap": {"low": 5}}]}}}))
      want = "Invalid models.json schema:\n  - default: expected a \"provider/model-id\" string\n  - providers.a.name: expected a string\n  - providers.a.models[0].id: required non-empty string\n  - providers.a.models[1].thinkingLevelMap.low: expected a string or null\n("
      abort "models multi-error diverges:\n#{multi}" unless multi&.start_with?(want)
      fields = models.call(%({"providers": {"a": {"name": 5, "baseUrl": 5, "apiKey": 5, "api": 5}}}))
      want2 = "Invalid models.json schema:\n  - providers.a.name: expected a string\n  - providers.a.baseUrl: expected a string\n  - providers.a.apiKey: expected a string\n  - providers.a.api: expected a string\n("
      abort "models field order diverges:\n#{fields}" unless fields&.start_with?(want2)
      path = File.join(dir, "mcp.json")
      check = lambda do |body, want3|
        File.write(path, JSON.generate(body))
        begin
          Tart::Mcp::Config.load(path)
          abort "expected ConfigError for #{body.inspect}"
        rescue Tart::Mcp::Config::ConfigError => e
          abort "mcp diverges: #{e.message.inspect} (want #{want3.inspect})" unless e.message == "#{path}: #{want3}"
        end
      end
      check.call({"mcpServers" => "nope"}, %q{expected an object with an "mcpServers" object})
      check.call({"mcpServers" => {"x" => "nope"}}, %q{server "x" must be an object})
      check.call({"mcpServers" => {"x" => {"command" => "c", "args" => "nope"}}}, %q{server "x": args must be an array of strings})
      check.call({"mcpServers" => {"x" => {"command" => "c", "env" => {"a" => 1}}}}, %q{server "x": env must map names to strings})
      check.call({"mcpServers" => {"x" => {"cwd" => 3}}}, %q{server "x": cwd must be a string})
      check.call({"mcpServers" => {"x" => {"url" => "https://e/mcp"}}}, %q{server "x": streamable HTTP transport is not supported (stdio only)})
      check.call({"mcpServers" => {"x" => {"args" => []}}}, %q{server "x" needs either "command" (stdio) or "url" (streamable HTTP)})
      check.call({"mcpServers" => {"a" => "nope", "b" => {"command" => "c"}}}, %q{server "a" must be an object})
      bash = Tart::Tools::Bash.new(cwd: dir)
      r = bash.execute(command: "true", timeout: -1)
      abort "bash timeout message diverges: #{r.inspect}" unless r == {error: "Invalid timeout: must be a finite number of seconds"}
      edit = Tart::Tools::Edit.new(cwd: dir)
      r2 = edit.execute(path: "absent.txt", edits: [])
      abort "edit empty-edits message diverges: #{r2.inspect}" unless r2 == {error: "Edit tool input is invalid. edits must contain at least one replacement."}
      settings = Dir.mktmpdir do |sdir|
        File.write(File.join(sdir, "settings.json"), %({"contextWindow": "abc", "thinkingLevel": 5, "identity": "pi"}))
        result = Tart::Settings.load(cwd: dir, root: sdir)
        abort "settings filtered a malformed value: #{result.settings.inspect}" unless result.settings["contextWindow"] == "abc" && result.settings["thinkingLevel"] == 5
        abort "settings diagnostics grew" unless result.diagnostics.empty?
        "OK"
      end
      abort "settings no-filter diverges" unless settings == "OK"
      puts "ERROR_GOLDENS_OK"
    end'
  expect:
    exit_code: 0
    stdout_match: ERROR_GOLDENS_OK

- id: deps-pin
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'dry-schema' tart.gemspec && grep -q 'dry-validation' tart.gemspec && grep -q 'dry-schema' Gemfile.lock && grep -q 'dry-validation' Gemfile.lock && bundle install --quiet && bundle exec ruby -e 'require "dry-schema"; require "dry-validation"; puts "DEPS_OK"'
  expect:
    exit_code: 0
    stdout_match: DEPS_OK

- id: schemas-presence
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; abort "Tart::Schemas missing" unless defined?(Tart::Schemas) && defined?(Tart::Schemas::Settings) && defined?(Tart::Schemas::Models) && defined?(Tart::Schemas::Mcp) && defined?(Tart::Schemas::Tools); abort "test/schemas_test.rb missing" unless File.file?("test/schemas_test.rb"); puts "SCHEMAS_OK"'
  expect:
    exit_code: 0
    stdout_match: SCHEMAS_OK

- id: tool-input-vocab
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; Dir.mktmpdir do |dir|
      File.write(File.join(dir, "entry.txt"), "x\n")
      ls = Tart::Tools::Ls.new(cwd: dir)
      r = ls.execute(limit: "x")
      abort "ls wrapper vocabulary missing: #{r.inspect}" unless r.is_a?(Hash) && r[:error].to_s.start_with?("Validation failed for tool \"ls\":")
      bash = Tart::Tools::Bash.new(cwd: dir)
      r2 = bash.execute(command: "true", timeout: "5")
      abort "bash shape-failure vocabulary missing: #{r2.inspect}" unless r2.is_a?(Hash) && r2[:error].to_s.start_with?("Validation failed for tool \"bash\":")
      puts "TOOL_VOCAB_OK"
    end'
  expect:
    exit_code: 0
    stdout_match: TOOL_VOCAB_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 6d8a079 HEAD | grep -qvE '^(tart\.gemspec|Gemfile\.lock|lib/tart\.rb|lib/tart/schemas\.rb|lib/tart/schemas/settings\.rb|lib/tart/schemas/models\.rb|lib/tart/schemas/mcp\.rb|lib/tart/schemas/tools\.rb|lib/tart/settings\.rb|lib/tart/models\.rb|lib/tart/mcp/config\.rb|lib/tart/tools/safe_execute\.rb|lib/tart/tools/bash\.rb|lib/tart/tools/edit\.rb|lib/tart/tools/read\.rb|lib/tart/tools/write\.rb|lib/tart/tools/ls\.rb|lib/tart/tools/grep\.rb|lib/tart/tools/find\.rb|test/schemas_test\.rb|test/settings_test\.rb|test/models_test\.rb|test/mcp_test\.rb|test/tools_test\.rb|test/bash_tool_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### schemas

# Lane prompt — I43 dry-rb-boundaries, lane `schemas` (sole lane)

You are the builder for LANE `schemas` of iteration I43 dry-rb-boundaries
(space 20261009-pi-port, repo repos/tart, branch worktree provisioned from
frozen base 6d8a079). This prompt is your complete, self-contained contract.
You never commit; you write code + tests in your worktree and a scratch
report at build/I43-dry-rb-boundaries-schemas/report.md. PHASE 0 discipline
applies: disagreements with this contract are RESEARCHED (you may read
~/architect/src/github.com/dry-rb/* reference clones) and ITEMIZED in your
report's PHASE 0 section — never silently implemented differently, never
silently blocking.

Your may-touch set (EXACTLY these files, nothing else):

    tart.gemspec
    Gemfile.lock
    lib/tart.rb
    lib/tart/schemas.rb            (new)
    lib/tart/schemas/settings.rb   (new)
    lib/tart/schemas/models.rb     (new)
    lib/tart/schemas/mcp.rb        (new)
    lib/tart/schemas/tools.rb      (new)
    lib/tart/settings.rb
    lib/tart/models.rb
    lib/tart/mcp/config.rb
    lib/tart/tools/safe_execute.rb
    lib/tart/tools/bash.rb
    lib/tart/tools/edit.rb
    lib/tart/tools/read.rb
    lib/tart/tools/write.rb
    lib/tart/tools/ls.rb
    lib/tart/tools/grep.rb
    lib/tart/tools/find.rb
    test/schemas_test.rb           (new)
    test/settings_test.rb          (additive pins only)
    test/models_test.rb            (additive pins only)
    test/mcp_test.rb               (additive pins only)
    test/tools_test.rb             (additive pins only)
    test/bash_tool_test.rb         (additive pins only)

Must-not (binding): gems/tui-split-rig/** untouched; the wire JSON-Schema
tool declarations (every PARAMETERS_SCHEMA / DESCRIPTION constant)
byte-identical; lib/tart/agent/**, lib/tart/render/**, lib/tart/print.rb,
bin/tart, lib/tart/identity.rb, lib/tart/mcp/{client,stdio,tool,jsonrpc}.rb,
lib/tart/tools/registry.rb, lib/tart/tools/support/** untouched; the frozen
test files (golden_parity_test.rb, e2e_session_test.rb,
launcher_smoke_test.rb, agent_loop_test.rb, session_test.rb) untouched;
runtime raise sites stay raises; no new settings diagnostics; no settings
value filtering.

─ ENTRY 1 of the program plan (verbatim from
  build/loop/plan-20261013T092136Z.md) ────────────────────────────────

ITERATION: dry-rb-boundaries

Establish the dry-rb pattern in the codebase: dry-schema/dry-validation at
every parsing boundary, replacing the hand-rolled fetch-chains and raise
walls. This entry is the pattern-setter — where schemas live, naming, error
discipline — so every later iteration inherits it (the owner's stated reason
this program runs first).

Grounding (verified by the architect 2026-10-13, tart @ 6d8a079):
- settings.rb (329 l): env→file→DEFAULTS resolution at :129
  (`env[Identity.env_key(...)] || settings[key] || DEFAULTS[key]`), thinking
  vocabulary check :163, known-models tables MODEL_CONTEXT_WINDOWS/
  MODEL_REASONING/THINKING_LEVEL_MAPS :70-99/:199.
- models.rb (320 l): ~/.tart/models.json catalog + override parse (pi schema
  subset from I27), thinkingLevelMap parse (I36: Partial Record level →
  String|null, symbolized).
- mcp/config.rb: 10 raise sites — the newest hand-rolled validation (I07).
- Tool input validation: tools/bash.rb 6 raises, edit.rb 4, ls/grep/find 3
  each (arg presence/shape guards before execution).
- Upstream reference: ~/architect/src/github.com/dry-rb/dry-schema (v1.16+),
  dry-validation (v1.11+), dry-logic — read for current API idioms (params vs
  schema, contract macros, custom predicate placement); do not invent against
  old dry-rb folklore.

Shape: one schema module family (lib/tart/schemas/ or the spec's better
name — spec decides, this sets the pattern) covering: settings resolution
(same precedence semantics EXACTLY — env > project > user > defaults; no
behavior change), models.json (catalog/override/thinkingLevelMap), MCP
config, and tool input args (each tool's parameter schema in dry-schema form
replacing raise guards — the JSON-Schema tool declarations STAY as they are,
wire-unchanged; dry-schema validates inputs internally). Observable error
behavior on invalid config/args stays equivalent where tests pin it; the
spec enumerates every pinned message and preserves or re-pins consciously.

Gates: suite + bench + s1–s10 + probes cold unchanged; new unit pins: each
boundary's accept/reject table (valid/invalid fixtures per schema), settings
precedence matrix, thinkingLevelMap symbolization. Gemspec gains dry-schema
+ dry-validation (+ their transitive dry-core/dry-logic/dry-types — accept
the tree).

Coordinator standing rules (binding): you run under zai/glm-5.3-flash
thinking-high; never commit; scratch under tmp/ and build/ in the SPACE
repo, never inside repos/tart's tracked tree. The parity battery gates this
iteration: bundle exec rake, bundle exec ruby bench/seam_bench.rb
(SEAM_BENCH_OK), rig s1–s10 + probes exit 0 cold (s1_tart exit 1 by design)
— ZERO observable byte moves on screen or wire.

─ The frozen Grounds (verbatim from architecture/I43-dry-rb-boundaries.md,
  commit 967a2c87) ──────────────────────────────────────────────────────
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
─ The frozen Specification (verbatim; the ```lanes block names YOUR touch
  set — it matches the list above) ────────────────────────────────────────
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
─ The frozen Acceptance Criteria (verbatim — the gates are your bar; the
  judge runs them cold on the integrated tree) ────────────────────────────
# Acceptance Criteria — I43 dry-rb-boundaries

Gate calibration (pre-declared): **RED at base BY DESIGN** — `deps-pin`,
`schemas-presence`, `tool-input-vocab` (the dry deps, the schema family,
and the new failure vocabulary do not exist at 6d8a079); they must be
GREEN on the integrated tree, non-vacuously. **Regression guards (GREEN
at base, must stay GREEN)** — `suite`, `bench`, `s1`–`s10`,
`s1-tart-mode`, both probe gates, `wire-declarations`, `error-goldens`
(today's behavior IS the contract; the parity battery proves zero
observable byte moves). The s-gates keep the CANONICAL short out dirs
(I41 Grounds 1's environmental note). The KNOWN s9 lane-worktree
deep-path artifact (I34/I36/I39/I40/I42 precedent, five confirmations)
does not fail this iteration when the same tree exits 0 at canonical
depth — the judge runs the battery on the integrated tree.

**AC1 (the pattern lands).** `Tart::Schemas` exists at the specified
home (`lib/tart/schemas.rb` + `schemas/{settings,models,mcp,tools}.rb`)
with the four boundary members, contracts instantiated once at load;
`tart.gemspec` declares `dry-schema ~> 1.16` + `dry-validation ~> 1.11`
as PRODUCTION deps; `Gemfile.lock` carries them plus the accepted
transitive tree. The pattern contract (naming, JSON flavor, error
discipline rules 1–5, key tolerance, settings no-filtering) is followed
by all four boundaries. Pinned by `deps-pin` + `schemas-presence` +
judge read of the diff.

**AC2 (settings equivalence).** Every resolution outcome is unchanged:
the env > project > user > defaults precedence exactly (env tier rides
the identity namespace), pi's settings-manager.ts:126 flows-through
preserved (type-invalid file values land in `Result#settings` verbatim —
no filtering, no new diagnostics, no new rejections), the
non-digit-env / non-positive-file context-window fall-throughs
unchanged, the thinking-vocabulary and modelReasoning truthiness
outcomes unchanged, `read_file`/`deep_merge`/`save`/modifier semantics
untouched. Pinned by the new precedence-matrix + no-filter unit pins
and the existing settings pins green UNTOUCHED; spot-pinned by
`error-goldens`.

**AC3 (models.json equivalence).** `Models.load` produces, for every
Grounds §5 fixture, TODAY'S EXACT error string (header, line order incl.
the multi-error interleave, path suffix); valid catalogs parse to
byte-identical entries (the I36 symbolization semantics hold); the
loader still never raises (error-as-field); the hand-rolled `validate*`
family is deleted (the contract replaces it). Pinned by the
accept/reject unit tables + `error-goldens`.

**AC4 (mcp.json equivalence).** `Mcp::Config.load` raises
`ConfigError` with the EXACT pinned strings (root shape, the six
per-server messages — Grounds §5) for every fixture, fail-fast on the
FIRST invalid server in insertion order; the parser-error passthrough
and the normalized success output are unchanged. Pinned by the exact-
string unit table (mcp_test stays green untouched) + `error-goldens`.

**AC5 (tool inputs).** All seven built-in tools validate their inputs
through the ONE shared seam at the top of `execute` (inside
`safe_execute`): bash `timeout` −1 / Float::INFINITY and edit's
empty/not-array `edits` return the two PINNED messages byte-exactly;
new shape failures (wrong-typed args on any tool) return pi's
loop-level wrapper vocabulary (`Validation failed for tool "<name>":
…Received arguments:…`); RUNTIME raises (cwd/path/binary/EOF/file-access
families) stay raises, untouched; `Edit#call`'s normalize_arguments
runs before validation; NO coercion is added; the wire JSON-Schema
declarations are byte-unchanged (`PARAMETERS_SCHEMA`/`DESCRIPTION`
constants; the captured request's tools array hash-pinned). Pinned by
`tool-input-vocab` + `wire-declarations` + the unit tables + the
golden_parity pins green untouched.

**AC6 (parity + regression + scope).** The default rake task fully
green with new additive pins (run count > 796); `SEAM_BENCH_OK`; s1–s10
exit 0 cold at the canonical out dirs; `s1-tart-mode` completes
(TART_MODE_OK); both probe gates OK (TOOL_PENDING_GATE_OK,
USER_BASH_STREAM_GATE_OK); the integrated diff vs **6d8a079** touches
EXACTLY the lane's declared file set — no `gems/tui-split-rig/**`, no
frozen test file, no `bin/tart`, no render/agent/print file.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i43-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i43-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-declarations
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i43-wire && ruby -rjson -rdigest -e 'req = JSON.parse(File.readlines("tmp/i43-wire/run-1/tart-requests.jsonl")[0]); tools = req["body"]["tools"]; names = tools.map { |t| t.dig("function","name") }; abort "loadout: #{names.inspect}" unless names == %w[read bash edit write]; digest = Digest::SHA256.hexdigest(JSON.generate(tools)); abort "tool declarations moved on the wire: #{digest}" unless digest == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_DECLARATIONS_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DECLARATIONS_OK

- id: error-goldens
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; Dir.mktmpdir do |dir|
      models = lambda do |body|
        File.write(File.join(dir, "models.json"), body)
        Tart::Models.load(root: dir).error
      end
      multi = models.call(%({"default": 5, "providers": {"a": {"name": 5, "models": [{"id": ""}, {"id": "m", "thinkingLevelMap": {"low": 5}}]}}}))
      want = "Invalid models.json schema:\n  - default: expected a \"provider/model-id\" string\n  - providers.a.name: expected a string\n  - providers.a.models[0].id: required non-empty string\n  - providers.a.models[1].thinkingLevelMap.low: expected a string or null\n("
      abort "models multi-error diverges:\n#{multi}" unless multi&.start_with?(want)
      fields = models.call(%({"providers": {"a": {"name": 5, "baseUrl": 5, "apiKey": 5, "api": 5}}}))
      want2 = "Invalid models.json schema:\n  - providers.a.name: expected a string\n  - providers.a.baseUrl: expected a string\n  - providers.a.apiKey: expected a string\n  - providers.a.api: expected a string\n("
      abort "models field order diverges:\n#{fields}" unless fields&.start_with?(want2)
      path = File.join(dir, "mcp.json")
      check = lambda do |body, want3|
        File.write(path, JSON.generate(body))
        begin
          Tart::Mcp::Config.load(path)
          abort "expected ConfigError for #{body.inspect}"
        rescue Tart::Mcp::Config::ConfigError => e
          abort "mcp diverges: #{e.message.inspect} (want #{want3.inspect})" unless e.message == "#{path}: #{want3}"
        end
      end
      check.call({"mcpServers" => "nope"}, %q{expected an object with an "mcpServers" object})
      check.call({"mcpServers" => {"x" => "nope"}}, %q{server "x" must be an object})
      check.call({"mcpServers" => {"x" => {"command" => "c", "args" => "nope"}}}, %q{server "x": args must be an array of strings})
      check.call({"mcpServers" => {"x" => {"command" => "c", "env" => {"a" => 1}}}}, %q{server "x": env must map names to strings})
      check.call({"mcpServers" => {"x" => {"cwd" => 3}}}, %q{server "x": cwd must be a string})
      check.call({"mcpServers" => {"x" => {"url" => "https://e/mcp"}}}, %q{server "x": streamable HTTP transport is not supported (stdio only)})
      check.call({"mcpServers" => {"x" => {"args" => []}}}, %q{server "x" needs either "command" (stdio) or "url" (streamable HTTP)})
      check.call({"mcpServers" => {"a" => "nope", "b" => {"command" => "c"}}}, %q{server "a" must be an object})
      bash = Tart::Tools::Bash.new(cwd: dir)
      r = bash.execute(command: "true", timeout: -1)
      abort "bash timeout message diverges: #{r.inspect}" unless r == {error: "Invalid timeout: must be a finite number of seconds"}
      edit = Tart::Tools::Edit.new(cwd: dir)
      r2 = edit.execute(path: "absent.txt", edits: [])
      abort "edit empty-edits message diverges: #{r2.inspect}" unless r2 == {error: "Edit tool input is invalid. edits must contain at least one replacement."}
      settings = Dir.mktmpdir do |sdir|
        File.write(File.join(sdir, "settings.json"), %({"contextWindow": "abc", "thinkingLevel": 5, "identity": "pi"}))
        result = Tart::Settings.load(cwd: dir, root: sdir)
        abort "settings filtered a malformed value: #{result.settings.inspect}" unless result.settings["contextWindow"] == "abc" && result.settings["thinkingLevel"] == 5
        abort "settings diagnostics grew" unless result.diagnostics.empty?
        "OK"
      end
      abort "settings no-filter diverges" unless settings == "OK"
      puts "ERROR_GOLDENS_OK"
    end'
  expect:
    exit_code: 0
    stdout_match: ERROR_GOLDENS_OK

- id: deps-pin
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'dry-schema' tart.gemspec && grep -q 'dry-validation' tart.gemspec && grep -q 'dry-schema' Gemfile.lock && grep -q 'dry-validation' Gemfile.lock && bundle install --quiet && bundle exec ruby -e 'require "dry-schema"; require "dry-validation"; puts "DEPS_OK"'
  expect:
    exit_code: 0
    stdout_match: DEPS_OK

- id: schemas-presence
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; abort "Tart::Schemas missing" unless defined?(Tart::Schemas) && defined?(Tart::Schemas::Settings) && defined?(Tart::Schemas::Models) && defined?(Tart::Schemas::Mcp) && defined?(Tart::Schemas::Tools); abort "test/schemas_test.rb missing" unless File.file?("test/schemas_test.rb"); puts "SCHEMAS_OK"'
  expect:
    exit_code: 0
    stdout_match: SCHEMAS_OK

- id: tool-input-vocab
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; Dir.mktmpdir do |dir|
      File.write(File.join(dir, "entry.txt"), "x\n")
      ls = Tart::Tools::Ls.new(cwd: dir)
      r = ls.execute(limit: "x")
      abort "ls wrapper vocabulary missing: #{r.inspect}" unless r.is_a?(Hash) && r[:error].to_s.start_with?("Validation failed for tool \"ls\":")
      bash = Tart::Tools::Bash.new(cwd: dir)
      r2 = bash.execute(command: "true", timeout: "5")
      abort "bash shape-failure vocabulary missing: #{r2.inspect}" unless r2.is_a?(Hash) && r2[:error].to_s.start_with?("Validation failed for tool \"bash\":")
      puts "TOOL_VOCAB_OK"
    end'
  expect:
    exit_code: 0
    stdout_match: TOOL_VOCAB_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 6d8a079 HEAD | grep -qvE '^(tart\.gemspec|Gemfile\.lock|lib/tart\.rb|lib/tart/schemas\.rb|lib/tart/schemas/settings\.rb|lib/tart/schemas/models\.rb|lib/tart/schemas/mcp\.rb|lib/tart/schemas/tools\.rb|lib/tart/settings\.rb|lib/tart/models\.rb|lib/tart/mcp/config\.rb|lib/tart/tools/safe_execute\.rb|lib/tart/tools/bash\.rb|lib/tart/tools/edit\.rb|lib/tart/tools/read\.rb|lib/tart/tools/write\.rb|lib/tart/tools/ls\.rb|lib/tart/tools/grep\.rb|lib/tart/tools/find\.rb|test/schemas_test\.rb|test/settings_test\.rb|test/models_test\.rb|test/mcp_test\.rb|test/tools_test\.rb|test/bash_tool_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```
─ Working notes (not contract) ───────────────────────────────────────────

- Work from your provisioned worktree (the coordinator created it from the
  frozen base). Run the suite early and often: `bundle install --quiet &&
  bundle exec rake`. You CANNOT run the full rig battery meaningfully in a
  deep worktree (the known s9 deep-path artifact) — run suite + bench +
  targeted unit tests in your tree; the judge runs the full battery on the
  integrated tree.
- Read the dry-rb reference clones before writing the contracts
  (~/architect/src/github.com/dry-rb/dry-schema, dry-validation, dry-logic)
  and the installed gem sources — Grounds §4 lists the exact probed idioms
  that work on this stack; trust those over memory.
- Your scratch report at build/I43-dry-rb-boundaries-schemas/report.md:
  PHASE 0 disagreements (with evidence), the file-by-file change table,
  command outputs (suite/bench + any probes), the STATUS line
  (COMPLETE / COMPLETE_WITH_CONCERNS / INCOMPLETE), and any OQ notes for
  the judge.

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
