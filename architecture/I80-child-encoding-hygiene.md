# I80: child-encoding-hygiene

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261018T1745Z-live-run-successor.md` ENTRY 5 —
  `child-encoding-hygiene` (repo tart, 1 lane). Coordinator deltas at
  dispatch: base = `repos/tart` @ **`34ba69af`** ("Merge
  lane/I79-subagent-status-box-core", the I79 integrate tip). Entries
  I77 (edit-tool-fix), I78 (subagent-runner-health) and I79
  (subagent-status-box) have LANDED — their behavior is baseline (the
  folded-edit tolerance + assistant model identity; the fleet sweep +
  reaper + ownership flags + loud dispatch validation; the subagent
  status box + probe + the 30-run box battery).
- **Measured base suite THIS session (fresh, cold, never predicted):**
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  **1443 runs / 6793 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0** (the I79 verdict's 6794 asserts is the standing dynamic-
  counter class — floors pin run counts) plus `bundle exec ruby
  bench/seam_bench.rb 2>&1 | tail -1` → **`SEAM_BENCH_OK`**. The
  tracked tree is clean at `34ba69af` (the standing `t75*`/`t79*`
  untracked rehearsal scratch remains, never committed).
- **Provision geometry (verified THIS session):**
  `git -C repos/tart merge-base --is-ancestor 34ba69af origin/main` →
  **FALSE** (exit 1) — `origin/main` holds squashed PR merges and is
  NOT an ancestor of the port tip, so `architect provision` needs the
  explicit `--base 34ba69af` (the default fast-forward sync
  diverges-refuses). Re-verify at the next provision.
- Carried-gate floor: **84 gates carried from the I79 block** (85 − the
  per-iteration `scope` rewrite) with the standing rebases: the `t80*`
  out-dir era prefix, the diff bases `12a7ece`→`34ba69af`, and the
  scope gate REWRITTEN to this iteration's frozen 5-path touch set.
  Carried gates keep their origin `ac:` labels verbatim.

### The plan's hypothesis AUDITED (the answer: the scrub strips NOTHING locale-related — the pick list is the defect)

The plan's constraint framing ("audit exactly what I73's
`Tart::ChildEnv.scrub` strips; if it strips `LANG`/`LC_*`, that is the
bug") was audited against the landed law (`lib/tart/child_env.rb`,
I73): **the scrub touches exactly `BUNDLER_ORIG_*` records + the
`RUBYOPT`/`RUBYLIB` belts — locale keys pass through it untouched**.
The defect is one seam over: `lib/tart/subagents/manager.rb:421
child_env` composes a FRESH CLOSED hash (the I73/I48 OQ-7 design,
spawned with `unsetenv_others: true`) whose pick list is PATH, HOME,
the identity/bootstrap keys, the model + timeout knobs, the sink and
supervisor-channel picks — **no `LANG`, no `LC_*`**. Every other
child-spawn arm already passes locale through (the bash tool's two
arms and MCP stdio all compose over `ChildEnv.scrub(ENV.to_h)`, which
carries locale keys whenever the parent has them); the subagent child
is the ONE arm that drops them. A parent whose own env is locale-less
(the devstral-docs dispatch chain — "this environment's shells carry
no LANG", `notes/docs-loop-trial-abandoned.md`) therefore boots the
child runner with **`Encoding.default_external = US-ASCII`**.

### The mechanism, measured THIS session (Ruby encoding semantics on ruby 4.0.7, the installed mise toolchain)

- A locale-less process (`env -i`, no `LANG`/`LC_*`):
  `Encoding.default_external` = **US-ASCII**.
- **ARGV** elements carrying non-ASCII bytes come back tagged
  **ASCII-8BIT (BINARY)** with valid UTF-8 bytes (measured: `env -i
  ruby probe.rb "Diátaxis ✓"` → `ARGV[0].encoding == ASCII-8BIT`) —
  exactly the "UTF-8 string passed as BINARY" class.
- **Text-mode IO reads** (`File.read`, `IO.pipe#read`,
  `Open3.capture2`) of non-ASCII bytes come back tagged **US-ASCII
  with invalid byte sequences** — and `String#sub`/`String#strip`
  then RAISE `invalid byte sequence in US-ASCII` (measured). This is
  the architect-CLI crash class inside the spec child
  (`String#strip: invalid byte sequence in US-ASCII`, the
  docs-loop record).
- tart's bundle pins **json 3.0.2** (`Gemfile.lock:85`) — the version
  that **warns** `JSON.generate: UTF-8 string passed as BINARY, this
  will raise an encoding error in json 3.0` (`json/common.rb:382`)
  instead of raising (3.1.0 raises, measured on the mise default).
- Locale precedence for MRI's default external: `LC_ALL` > `LC_CTYPE`
  > `LANG`, all measured THIS session (`LC_CTYPE=en_US.UTF-8` alone →
  UTF-8; `LANG=C` + `LC_CTYPE=en_US.UTF-8` → UTF-8 — LC_CTYPE masks a
  non-UTF-8 LANG; `LANG=en_US.UTF-8` → UTF-8).

### THE BASE-RED REPRODUCTIONS (this session, hermetic, `tmp/i80-spec/probe-*.rb` — MockLLMServer, never a live API)

- **Probe A — the DIRECT runner path** (`bin/tart -p "<Diátaxis-grade
  prompt>"` spawned with a closed, locale-less env, mock endpoint):
  exit 0, the final non-ASCII answer round-trips to stdout BYTE-EXACT
  — but the runner's own stderr carries **2 `JSON.generate: UTF-8
  string passed as BINARY` warnings** (the prompt rides ARGV tagged
  BINARY; every wire-request generate + the session-record generate
  warn), byte-identical to the 52-warning line observed live. The wire
  request DOES carry the prompt byte-exact (messages[1] content).
- **Probe B — the MANAGER path** (leg A's exact shape: locale-less
  parent subprocess — `tart_env` in `test/subagents_e2e_test.rb`
  already carries NO locale keys — scripted subagent call with a
  non-ASCII task, non-ASCII child answer): the child runner's stdout
  (`runner.stdout.log`) contains the answer **byte-exact**, the child
  wire request carries the task **byte-exact**, and `taskChars`
  records the correct CHARACTER count (66) — but the run settles
  **`state: "failed"`, `result.json` `output: ""`, `error:` THE JSON
  WARNING LINE**, and the child's `runner.stderr.log` carries **2
  BINARY warnings** while the parent's own stderr carries **3**.
  Root cause chain, each link measured: the locale-less parent's
  `read_output` (`manager.rb:1159`, text-mode `File.read` + `.sub`)
  RAISES on the invalid-US-ASCII output and its `rescue StandardError`
  swallows it to **`""`** → `settle_run`'s `success = !parent_killed
  && !output.empty?` (:592-620) → **false** → state failed, result
  output empty, and `first_error_line` (:1168) records the json-gem
  warning as the run's `error` — **the exact devstral-docs failure
  class** (two independent live runs, `01a14df7` and `01a14e3c`,
  recording that warning line as their `error`; the dead spec run's
  `runner.stderr.log` holds 52 copies; specimen:
  `~/.tart/subagents/01a14e3c-6650-717a-a3c1-c7945b425a82/`).
- **The live evidence this reproduces** (cited, read-only): the
  devstral-docs record `notes/docs-loop-trial-abandoned.md` (the
  runner died mid-turn, the recorded error was the warning line, the
  architect CLI inside the child crashed on `String#strip`, the
  gates crashed on UTF-8 em-dashes — "Locale-less shells bite every
  Ruby tool in the dispatch path"), and the run-1 record
  `notes/devstral-docs-run-1.md` (the first dispatch failure recorded
  the same warning as its error).

### The pi parity letter (read-only oracles)

pi-subagents 0.79.1 `src/runs/background/async-execution.js:503-522`:
the async runner env is `{...omitGitRoutingEnv(omitExtensionBindingsEnv(
process.env)), ...childCacheRetentionEnv(), …}` — **the FULL parent env
passes through** (minus a few pi-specific keys), so pi's children carry
whatever `LANG`/`LC_*` the parent had. node is encoding-agnostic
internally (UTF-8 always), so pi never needed a floor. The port's
CLOSED-env design stays (I73 OQ-7, byte-preserved); the parity gap is
only that the pick list omits the locale keys pi passes implicitly.

### tart today (the seams, base `34ba69af`)

- `lib/tart/subagents/manager.rb` — the three encoding seams: the
  `child_env` pick list (:421, locale keys absent), the argv task text
  (`spawn_argv_and_env` :386-393, `-p run[:task_text]`), and the two
  artifact readers `read_output` (:1159) / `first_error_line` (:1168)
  (text-mode reads; `notify_completion`'s `output.strip` :1001 is the
  same landmine). The task text is NEVER recorded (`taskChars` only,
  :1119) and `truncate_utf8_head` (:1219) is already byte-safe.
- `bin/tart` — `run(argv)` (:228-242): parse → workdir → print/interactive
  boots. No encoding law anywhere: a locale-less direct invocation
  (probe A's shape) has BINARY-tagged ARGV and US-ASCII text reads for
  its whole life. The tool layer is ALREADY hygienic
  (`output_accumulator.rb:41/:87/:91`, `read.rb:85`, `edit.rb:216`:
  binread + `force_encoding(UTF_8)` + scrub) — the discipline exists,
  the runner boundary lacks it.
- `lib/tart/child_env.rb` — the I73 scrub law: UNTOUCHED by this
  iteration (the plan's constraint, mechanically enforced by the scope
  gate hard-freezing the file).

### Decisions taken this session (one-line reasons)

- **The bug is the pick list, not the scrub** — the audit answer
  (measured); the scrub never touches locale keys, so the cure rides
  ON TOP of it, exactly as the plan's constraint demands.
- **The child locale law: pass-through picks + a UTF-8 floor** —
  `LANG` + every `LC_*` ride through from the scrubbed source (pi
  parity, the full-env letter); when the effective charset key
  (`LC_ALL` > `LC_CTYPE` > `LANG`) is absent or non-UTF-8, the floor
  sets `LC_CTYPE=en_US.UTF-8` (or overrides a present non-UTF-8
  `LC_ALL`, which would mask `LC_CTYPE`) — the Ruby-ecosystem
  hardening pi never needed (node is UTF-8-native), itemized per
  BRIEF §5.1.
- **The floor value `en_US.UTF-8`** — the owner's measured machine
  locale (this session's own env: `LANG=en_US.UTF-8`).
- **The boot law lives in a NEW lib module** (`Tart::UTF8Boot`,
  `lib/tart/utf8_boot.rb`) called once from `bin/tart` `run` —
  unit-testable through the public seam; `bin/tart`'s diff stays the
  require + one call (prior iterations froze bin/tart; this one owns
  exactly that).
- **The boot law sets Encoding values, NOT env vars** —
  `Encoding.default_external = UTF_8` unless already, plus an ARGV
  retag (only when the element's bytes are VALID UTF-8; invalid bytes
  are left byte-identical, never mangled). It does not touch the env
  other processes see; the child-env law does that at spawn.
- **The hygienic readers use the port's own established idiom** —
  `File.binread + force_encoding(UTF_8) + scrub`
  (`output_accumulator.rb:41`, `read.rb:85`) — byte-identical for
  valid UTF-8 (scrub is identity there) and never-raise for arbitrary
  child bytes (a result.json write failure is a never-terminal-run
  bug, the I78 law).
- **The e2e leg reuses leg A's exact machinery with non-ASCII
  payloads** — the closed `tart_env` is ALREADY locale-less, so the
  leg needs no new staging to reproduce the owner's dispatch
  environment; the discrimination is the payload alone.
- **New-at-base scope must-differ legs take the `[ -f ]` form from the
  start** — the I79 seat-escalation lesson (git diff <commit> --
  <untracked> is empty by construction at a never-commit lane tree),
  baked into the frozen form this time.

### Open questions / named residuals (NOT this lane)

- The json 3.0.2 warn-vs-raise upgrade (json 3.1.0 RAISES on the same
  input) is a gem/owner concern — tart pins 0.5.0/3.0.2; when the pin
  moves, the warnings become crashes and this law is the difference
  between green and dead (owner backlog note, not lane work).
- `first_error_line` records the first stderr line as the run `error`
  — NOT redesigned here (with zero warnings the first line is a real
  error); richer error classification is ENTRY 6 forensics territory.
- The `task: null` / `taskChars`-only status shape and the doubled
  `sessions/sessions/` path — ENTRY 6's scope, untouched here.
- Other CLIs' own locale-less behavior (the architect CLI direct from
  a bare shell) — cured here only insofar as tart's children now carry
  a UTF-8 locale; their own boots are out of scope.
- The suite single-GREEN order-flake advisory (I79 seat condition 5) —
  owner backlog for a future gate-discipline pass; the suite gate form
  carries byte-verbatim.
- The standing s9/herdr lane-tree geometry classes, the render-perf
  BP2 load margin, the suite's chat-interrupt/env classes — carried
  declared, never re-litigated (the I72–I79 verdicts).

## Specification

### Objective

Close plan ENTRY 5 (`notes/plan-20261018T1745Z-live-run-successor.md`):
**UTF-8 must survive every child boundary.** Three defects, one root
class — a locale-less child process (`Encoding.default_external =
US-ASCII`) mangles every non-ASCII byte that crosses the spawn/status/
result boundary: the non-ASCII task text that broke the first devstral
dispatch (BINARY-tagged ARGV → `JSON.generate` warnings on every wire
round), the `JSON.generate: UTF-8 string passed as BINARY` warnings in
the runner stderr (52 copies in the dead spec run), and the swallowed-
then-failed settle (a locale-blind `read_output` turns a byte-exact
child answer into `output: ""` + `state: "failed"` + a json warning
recorded as the run `error`). One iteration, three laws riding ON TOP
of the untouched I73 scrub (the plan's constraint: the security law
holds, the allowlist does not widen — the CLOSED-env design stays, the
pick list grows exactly the locale keys pi passes implicitly).

### Law 1 — the child locale law (AC2, `lib/tart/subagents/manager.rb`)

`child_env` (the private pick-list builder behind the PUBLIC
`spawn_argv_and_env`) gains, after the existing picks, the locale arm:

1. **Pass-through picks (pi parity).** `LANG` and every source key
   matching `/\ALC_/` are picked from the scrubbed source when present
   and non-empty (verbatim values, the sink-picks' present-non-empty
   idiom) — pi-subagents passes the full parent env
   (async-execution.js:503); these keys are the port's share of that.
2. **The UTF-8 floor.** After the picks, the effective charset key is
   `env["LC_ALL"] || env["LC_CTYPE"] || env["LANG"]` (MRI/setlocale
   precedence, measured). If it is nil OR its value does not match
   `/UTF-?8\z/i`, set `env["LC_ALL"] = "en_US.UTF-8"` when `LC_ALL` is
   present (it would mask `LC_CTYPE`), else set
   `env["LC_CTYPE"] = "en_US.UTF-8"` (masks a non-UTF-8 `LANG`, leaves
   `LANG` untouched). Frozen constant `UTF8_LOCALE = "en_US.UTF-8"`
   (the owner's measured machine locale).

The floor is the declared BRIEF §5.1 mechanism deviation (itemized in
the report): pi never needed it (node is UTF-8-native); observable-
identical for ASCII payloads, the cure for everything else. The pick
list grows ONLY these keys — nothing else joins the closed env (the
plan's constraint honored mechanically: `lib/tart/child_env.rb` is
hard-frozen by the scope gate, byte-untouched).

### Law 2 — the boot UTF-8 law (AC3, `lib/tart/utf8_boot.rb` NEW + one call in `bin/tart`)

A new module `Tart::UTF8Boot` (`lib/tart/utf8_boot.rb`), required and
called ONCE at the top of `bin/tart`'s `run(argv)` (before parse):

- Unless `Encoding.default_external` is already UTF-8, set it to
  `Encoding::UTF_8`. (`Encoding.default_internal` stays nil — never
  set, never changed.)
- **ARGV retag**: for each argv element whose encoding is not UTF-8
  AND whose bytes are valid UTF-8, `force_encoding(Encoding::UTF_8)`
  in place; elements with invalid-UTF-8 bytes are left byte-identical
  and untouched (never mangled — a binary argv stays binary).

This cures the DIRECT runner path (a locale-less `bin/tart -p
"Diátaxis…"` — probe A's shape: BINARY-tagged prompt → warnings on
every wire round) and belt-covers the manager child (Law 1 makes the
child's interpreter boot UTF-8 natively, so the boot law is a no-op
there). It does NOT write env vars (the child-env law does that);
it fixes THIS process's Encoding defaults the moment it starts, before
any parse or IO.

### Law 3 — byte-hygienic artifact readers (AC1's parent leg, `lib/tart/subagents/manager.rb`)

- `read_output` (:1159): read via `File.binread`, then
  `force_encoding(Encoding::UTF_8).scrub`, then the existing
  trailing-newline `.sub(/\n\z/, "")`; the `rescue StandardError → ""`
  belt stays (a missing/unreadable file is still ""). The port's own
  established idiom (`output_accumulator.rb:41`, `read.rb:85`) —
  byte-identical for valid UTF-8 (probe B's answer bytes round-trip
  exactly), never-raise for arbitrary child bytes.
- `first_error_line` (:1168): same discipline — binread +
  `force_encoding(UTF_8).scrub`, iterate lines, first non-empty
  `.strip`; `rescue → nil` belt stays.

With these, the settle chain (`settle_run` :592: `success` from
`output.empty?`, `result.json` write, `status.json` flip,
`notify_completion`'s `output.strip`) is locale-independent in the
PARENT: a locale-less parent (probe B's shape) settles a non-ASCII
child answer to `completed` with byte-exact `result.json` output
instead of `failed`/`""`/a warning-as-error. No other settle/reap/
ownership logic moves (I78's laws byte-unchanged; `truncate_utf8_head`
is already byte-safe and untouched).

### Tests (the builder's pins, filter-frozen by the gates)

- **NEW `test/child_encoding_test.rb`**, ≥ 7 tests under the
  `/encoding/` name filter, driving the PUBLIC surfaces:
  - `spawn_argv_and_env` (a staged Manager, the `subagents_test`
    idiom): locale pass-through (a poisoned bundler env + `LANG` → the
    child env carries `LANG` verbatim AND zero bundler keys — the
    scrub still strips them, the constraint honored); the floor
    (source with no locale keys → `LC_CTYPE=en_US.UTF-8`, nothing
    invented for `LANG`); a non-UTF-8 `LANG=C` → `LC_CTYPE` floor with
    `LANG` untouched; a UTF-8 `LANG` → nothing added or changed; a
    present non-UTF-8 `LC_ALL` → `LC_ALL` overridden; the argv task
    text byte-exact (`argv` carries the Diátaxis-grade task, bytes
    compared).
  - `Tart::UTF8Boot.enforce!`: default_external US-ASCII → UTF-8;
    ARGV BINARY-tagged valid-UTF-8 elements retagged; an
    invalid-UTF-8 byte string left byte-identical and untouched; a
    UTF-8-tagged argv a no-op (identity). Test discipline: save/restore
    `Encoding.default_external` in ensure (the law mutates process
    globals by design).
- **`test/subagents_e2e_test.rb`** — DECLARED re-pin file, ONE new leg
  `test_encoding_e2e_non_ascii_round_trip` under the `/encoding_e2e/`
  filter: leg A's exact machinery (staged HOME, closed locale-less
  `tart_env` — already the defect environment, MockLLMServer, the
  foreground subagent call) with a Diátaxis-grade non-ASCII task AND
  non-ASCII child answer. Asserts: parent exit 0; the child wire
  request carries the task byte-exact; `runner.stderr.log` contains
  ZERO `passed as BINARY` lines; the PARENT's own stderr contains ZERO
  (the boot law's leg); `status.json` state `completed`, `taskChars`
  == the task's CHARACTER count; `result.json` `success: true` and
  `output` == the child answer BYTE-EXACT; the parent's final stdout
  non-ASCII and byte-exact. Any edit to existing legs is
  behavior-preserving re-pinning only (permission, not obligation).

### Frozen expectations (do not redesign)

- Encoding-only change: **wire/session/screen bytes unaffected** —
  tags move, bytes do not (JSON.generate output is byte-identical for
  a valid UTF-8 string whether tagged UTF-8 or BINARY; the tools'
  scrub idiom already proved this). wire-delta
  (instruction `4209f40b…`, tools `7360fd1e…`), session-golden (7/7),
  zai tart=pi=512, the pty battery, the box/probe family, and every
  I69–I79 landed-behavior gate carry as standing guards (the 84-gate
  carried block).
- No tool-semantics changes: timeouts, process groups, the reaper, the
  ownership flags, the supervisor channel, the closed-env OQ-7 design,
  the task-never-recorded law (`taskChars` only), the
  five-`<IDENTITY>_*` session-key law — all byte-preserved.
- `lib/tart/child_env.rb` HARD-FROZEN (the scrub law byte-untouched —
  the plan's constraint, mechanically enforced by the scope gate).
- No rig scenario-content edits (`gems/tui-split-rig/scenarios/**`,
  `registry.yml`, `fixtures/` byte-frozen); no new gems; no
  Gemfile/lock/gemspec changes; no new `Thread.new` sites
  (threads-budget law, base rebased to `34ba69af`).
- No new directories in the touch set (all five paths land in existing
  directories — the I79 `dir/**` carry-in does not bite, noted for the
  record).

### Named exclusions (Constraints, itemized)

- The gem side (`repos/fast-llm`, fast-completions 0.5.0 / json 3.0.2):
  READ-ONLY; the warn-vs-raise upgrade concern is the owner's (named
  residual).
- pi and pi-subagents 0.79.1 clones: READ-ONLY oracles.
- `problems.md`/`ARCHITECT.md` annotations are LANDING work
  (architect-owned), not lane work.
- ENTRY 6's forensics nits (`task: null`, the doubled
  `sessions/sessions/` path) — not this lane.
- The first_error_line error-classification redesign — not this lane.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands
  the tree). The deliverable is the provisioned worktree's diff vs
  `34ba69af`, exactly: `lib/tart/utf8_boot.rb` (NEW),
  `lib/tart/subagents/manager.rb` (MUST differ — the locale law + the
  readers), `bin/tart` (MUST differ — the require + the one boot
  call), `test/child_encoding_test.rb` (NEW),
  `test/subagents_e2e_test.rb` (MUST differ — the encoding e2e leg).
- Scratch report at `build/I80-child-encoding-hygiene-core/report.md`:
  the suite summary line, the FULL 88-gate table (every gate, one
  measured one-liner each — itemize-and-defend), deviations itemized,
  a final `STATUS:` line.

### Tool guidance

- Verification (exact, measured at base `34ba69af` this session):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1443 runs, 6793 assertions, 0 failures, 0 errors, 1 skips`, exit 0
  (post-lane: ≥ 1443 runs, 0F/0E); `bundle exec ruby bench/seam_bench.rb
  2>&1 | tail -1` → `SEAM_BENCH_OK`.
- The unit forms: `bundle exec ruby -Ilib -Itest
  test/child_encoding_test.rb -n "/encoding/"` → ≥ 7 runs, 0F; the
  e2e leg `bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n
  "/encoding_e2e/"` → ≥ 1 run, 0F (real subprocess boots — budget
  minutes, not seconds; the leg-A watchdog discipline).
- The two RED probes this spec measured at base
  (`tmp/i80-spec/probe-runner.rb`, `tmp/i80-spec/probe-manager.rb`,
  space scratch — READ-ONLY reference for the defect shapes; never
  copy them into the repo): the direct path warns twice on stderr
  while round-tripping stdout; the manager path settles `failed` with
  `output: ""` and the warning recorded as `error`. Your lane work
  turns both green — the gates `runner-encoding-direct` and
  `child-encoding-e2e` are exactly these shapes.
- The rig battery at YOUR tree (the lane worktree): the s-gate forms
  verbatim from the Acceptance Criteria (HERDR_* scrub prefix, the
  frozen SHORT out dirs, NO `--pi-bin` flag anywhere).
- Standing flake classes (`chat_test.rb` interrupt-timing BOTH forms,
  `render_perf_test.rb:265` spinner-dwell, the box order-flake fixed
  at I79 but the single-GREEN advisory stands): re-run COLD before
  adjudicating; note-and-pass per the standing ledger.

### Boundaries

- May touch: exactly the declared 5-path set (scope gate):
  `lib/tart/utf8_boot.rb` (NEW), `lib/tart/subagents/manager.rb`,
  `bin/tart`, `test/child_encoding_test.rb` (NEW),
  `test/subagents_e2e_test.rb`.
- Must not touch: everything else — including `lib/tart/child_env.rb`
  (HARD-FROZEN, the scrub law byte-untouched, the plan's constraint),
  all of `lib/tart/render/`, `lib/tart/agent/`, `lib/tart/tools/`,
  the rig (`gems/tui-split-rig/**`), Gemfile/lock/gemspec, `bench/`,
  `vendor/`, and anything under `repos/pi`,
  `repos/fast-llm`, or `~/.pi/`.
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.5.0); house style per AGENTS: commented citations
  at the touched seams, tests through public interfaces, no refactors
  beyond the task.

### Lane plan

One lane — three small laws on the child boundary, both-ways pins, the
standing battery.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/utf8_boot.rb
    - lib/tart/subagents/manager.rb
    - bin/tart
    - test/child_encoding_test.rb
    - test/subagents_e2e_test.rb
  effort: medium
```

### Effort call

`medium` — a bounded, fully-specified mechanism (all three laws frozen
with measured reference behavior; both base-RED shapes reproduced
hermetically this session; no perf exposure, no wire exposure), but it
owes the ≥ 7-run unit battery, a real-subprocess e2e leg, the boot-law
discipline in `bin/tart`, and the full 88-gate standing battery.

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
`architect rehearse child-encoding-hygiene` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze child-encoding-hygiene` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse child-encoding-hygiene` — before the freeze, while
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
subsection per lane. A copy is written to build/I80-child-encoding-hygiene-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section child-encoding-hygiene prompt --append --lane <lane> --from build/I80-child-encoding-hygiene-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I80-child-encoding-hygiene-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence child-encoding-hygiene --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section child-encoding-hygiene verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify child-encoding-hygiene`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
