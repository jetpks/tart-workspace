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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section dry-rb-boundaries specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision dry-rb-boundaries`
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
