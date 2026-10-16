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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section strict-sampling-integration specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision strict-sampling-integration`
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
