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

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **88 gates — 4 new/rewritten (this
iteration's discriminators) + 84 carried from the I79 block with the
standing rebases** (the I79 digest's carry instruction): the `t80*`
out-dir era prefix (the standing `t75*`–`t79*` families in the MAIN
checkout are judge/rehearsal scratch, never committed), the diff bases
`12a7ece`→`34ba69af`, and the scope gate REWRITTEN to this iteration's
frozen 5-path touch set. Carried gates keep their origin `ac:` labels
verbatim (their adjudication history travels with them); every carried
member is a regression anchor for landed behavior (I69–I79 products
are baseline). Carry audit ran clean BEFORE rehearsal
(`tmp/i80-spec/`: the extracted I79 block vs this one — 84 carried
byte-identical after the declared rebases, 1 declared drop (`scope`,
rewritten per-iteration), 3 new + 1 rewritten, zero duplicate ids, all
88 well-formed YAML).

**AC1 (the non-ASCII round-trip, end to end).** A Diátaxis-grade
payload (task and child answer carrying `á é ü ✓ —`) rides the REAL
machinery: a locale-less closed parent env (the existing `tart_env`
shape — already the defect environment, no new staging), a real child
print subprocess against the mock endpoint, the foreground delegation
flow. The child's wire request carries the task BYTE-EXACT;
`result.json` `output` equals the child's answer BYTE-EXACT with
`success: true`; `status.json` settles `completed` with `taskChars`
equal to the task's CHARACTER count (not bytes); the parent's final
stdout is byte-exact. At base this is RED for the measured reasons
(probe B: the locale-blind `read_output` swallows the byte-exact child
answer to `""` → `failed` → the json warning recorded as `error`).
Gates: `child-encoding-e2e` (+ every AC2/AC3 member).

**AC2 (the child locale law).** `child_env` picks `LANG` + every
`LC_*` present-non-empty in the scrubbed source, verbatim (pi parity —
pi-subagents passes the full parent env, async-execution.js:503); the
UTF-8 floor: effective charset key (`LC_ALL` > `LC_CTYPE` > `LANG`)
absent or non-UTF-8 → `LC_CTYPE=en_US.UTF-8` (a present non-UTF-8
`LC_ALL` is itself overridden — it would mask `LC_CTYPE`); a UTF-8
locale present → nothing added or changed; the scrub still strips
every bundler key from the same source (the plan's constraint,
untouched); the argv task text is byte-exact. Pinned through the
PUBLIC `spawn_argv_and_env` and `Tart::UTF8Boot.enforce!` under the
`/encoding/` filter. Gates: `child-encoding-units`.

**AC3 (zero BINARY-passed-to-JSON.generate warnings, every runner
path).** The DIRECT path (a locale-less `bin/tart -p` with a
non-ASCII prompt, mock endpoint): exit 0, stdout byte-exact, the wire
carries the prompt, and the runner's stderr contains ZERO
`passed as BINARY` warning lines (measured at base: TWO — probe A).
The MANAGED path: the child's `runner.stderr.log` contains ZERO (the
e2e leg) and the parent's own stderr contains ZERO (the boot law's
leg). Gates: `runner-encoding-direct` + `child-encoding-e2e`.

**AC4 (the full floor holds).** At the lane tree: the suite is
strictly greater than the base floor (**1443 runs / 6793 asserts /
0F / 0E / 1S at `34ba69af`, measured cold this session; floors pin
run counts — the assert counter is the I78-verdict dynamic class)
with `SEAM_BENCH_OK`; every carried gate holds — wire-delta
`4209f40b…`+`7360fd1e…` EXACT, session-golden EXACT, zai tart=pi=512,
the pty battery, the oracle family, the markdown battery, the
child-env law battery, the session-sink family, the signal-hygiene
family, the box/probe family, the I77 fold/identity anchors, the I78
health/validation anchors — an encoding-only change never moves a
settled wire/session/screen byte (tags move, bytes do not). Backed by
the carried block.

**AC5 (scope + the standing adjudication classes).** The scope gate
bites exactly the frozen 5-path touch set, with the three tracked
must-differ seams (`manager.rb`, `bin/tart`, `subagents_e2e_test.rb`)
changed, the two new-at-base paths present (`[ -f ]` legs — the I79
seat-escalation form, baked in from the start), and
`lib/tart/child_env.rb` HARD-FROZEN (the scrub law byte-untouched —
the plan's constraint, mechanically enforced). The threads-budget gate
at base `34ba69af` holds. The standing adjudication classes (declared,
NOT re-litigated — the I72–I79 verdicts): `s9-parity` +
`herdr-wire-probe` at LANE-TREE depth (judge-own at-base triangle
decides), `render-perf-probe` BP2 load margin (BP2-only →
note-and-pass, the idle-machine cold re-run operative), the suite's
chat-interrupt timing class and real-HOME env class
(`test_unknown_agent_names_the_three` scans the live `~/.tart` —
stage a HOME, the I74 precedent), the single-GREEN order-flake
advisory (I79 seat condition 5, owner backlog). House rules: the judge
runs gates at the LANE tree; never run gates under nohup; short out
dirs; `env -u HERDR_*` prefixes as frozen.

**AC6 (PHASE 0).** Every disagreement with this spec is raised with
reasons in the report (or an explicit statement of what was checked
before concluding the spec is sound) — silent compliance is a defect.

> **Rehearsal declarations (frozen):**
> - `child-encoding-units`, `child-encoding-e2e`,
>   `runner-encoding-direct`, and `scope` are **declared-RED at
>   rehearsal** — the lane deliverable does not exist pre-dispatch;
>   each was verified in this spec session to fail at the base tree
>   for exactly its declared reason (`test/child_encoding_test.rb`
>   absent → runs=0; the `/encoding_e2e/` filter empty → runs=0; the
>   direct probe MEASURED RED at base — two `passed as BINARY`
>   warnings on the runner stderr while stdout round-trips, probe A;
>   and `scope` REDs on the EMPTY must-differ legs with ZERO leaks —
>   the standing I77/I78/I79 class). GREEN arrives only with the lane
>   work; BROKEN would be a gate defect, not a finding.
> - The carried 84, MEASURED at the base tip `34ba69af` by THIS spec's
>   first rehearsal (transcript
>   `build/rehearse/I80-child-encoding-hygiene-20261018T213722.142803.md`):
>   **ALL 84 GREEN + the 4 declared-RED — GREEN 84 / RED 4 / BROKEN 0 /
>   EMPTY 0**, every RED verified at the base tree for exactly its
>   declared reason (`child-encoding-units` runs=0 file-absent;
>   `child-encoding-e2e` runs=0 filter-empty; `runner-encoding-direct`
>   "2 JSON.generate encoding warning(s) on the runner stderr" — the
>   probe-A measurement, reproduced by the gate itself; `scope` RED on
>   the EMPTY must-differ legs with ZERO leak lines — the leak check
>   and the hard-freeze leg both exit 0 at base, the standing
>   I77/I78/I79 class) — including `render-perf-probe` GREEN this
>   idle-machine run (the I75-frozen LOAD-MARGIN adjudication stands
>   either way: BP2-only → note-and-pass, idle-machine cold re-run
>   operative), `s9-parity` and `herdr-wire-probe` GREEN at canonical
>   depth. The 84 GREEN are the no-regression proof at freeze time; the
>   standing adjudication classes above are adjudicated at the lane
>   tree, never silently patched.
> - The `t80*` out dirs the gates create are rehearsal/judge scratch:
>   never committed; the integrator's out-of-bounds guard may trip on
>   them (the I73–I79 judge-scratch precedent — clean and re-verify, no
>   accept-bounds override unless the recorded class).

```gates
- id: stale-run-reaper
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t80sr-")
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    id = "01deadbee-0000-7000-8000-000000000001"
    dir = File.join(runs_home, id)
    FileUtils.mkdir_p([File.join(dir, "control", "steer-requests"), File.join(dir, "control", "stop-requests"), File.join(dir, "sessions")])
    pid = Process.spawn("sleep", "0.05"); Process.detach(pid); sleep 0.5
    File.write(File.join(dir, "status.json"), JSON.generate({"id" => id, "agent" => "worker", "task" => nil, "taskChars" => nil, "mode" => "single", "state" => "running", "pid" => pid, "cwd" => home, "asyncDir" => dir, "sessionRoot" => File.join(dir, "sessions"), "startedAt" => nil, "lastUpdate" => nil, "toolCallId" => nil}))
    File.write(File.join(dir, "runner.stderr.log"), "a ruby warning line\nsecond diagnostic line\n")
    hooks = Tart::Hooks.new
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k"}, identity: "pi", hooks: hooks, root: File.join(home, ".tart"))
    list = manager.status(id: nil)
    abort "fleet did not list the stale run: #{list.inspect}" unless list.include?("- #{id} | failed | single | worker")
    status = JSON.parse(File.read(File.join(dir, "status.json")))
    abort "status not converged to failed: #{status["state"].inspect}" unless status["state"] == "failed"
    abort "status lost the pid record" unless status["pid"] == pid
    result = JSON.parse(File.read(File.join(dir, "result.json")))
    abort "result not fabricated failed" unless result["success"] == false && result["timedOut"] == false && result["output"] == ""
    msg = result["error"].to_s
    want = "Async runner process #{pid} exited or disappeared before writing a result. Marked run failed by stale-run reconciliation."
    abort "repair message not the pi-pinned base: #{msg.inspect}" unless msg.start_with?(want)
    abort "stderr-tail diagnostics missing from the message: #{msg.inspect}" unless msg.include?("\n\nRunner stderr tail:\n") && msg.include?("second diagnostic line")
    abort "status error not the repair message" unless status["error"].to_s.start_with?(want)
    abort "a non-owned convergence queued a completion notification in the adopter" unless hooks.pending_next_turn.empty?
    abort "a non-owned run gates outstanding?" if manager.outstanding?
    puts "STALE_RUN_REAPER_OK"'
  expect:
    exit_code: 0
    stdout_match: STALE_RUN_REAPER_OK

- id: unknown-model-reject
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t80um-")
    root = File.join(home, ".tart")
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "models.json"), JSON.generate({"providers" => {"openrouter" => {"name" => "OpenRouter", "baseUrl" => "http://127.0.0.1:9/v1", "apiKey" => "k", "api" => "openai-completions", "models" => [{"id" => "z-ai/glm-4.7", "name" => "GLM", "reasoning" => false, "contextWindow" => 100000, "maxTokens" => 8192}]}}}))
    loaded = Tart::Models.load(root: root)
    empty = Tart::Models.load(root: File.join(home, "no-such-root"))
    abort "fixture catalog did not load" if loaded.model_entries.empty?
    abort "empty catalog is not empty" unless empty.model_entries.empty?
    spec = "openrouter/mistralai/devstral-2512"
    begin
      Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: nil)
      abort "unknown model + loaded catalog did not raise (no dispatch validation)"
    rescue ArgumentError => e
      abort "wrong rejection message: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    pair = Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: ["openrouter", "mistralai/devstral-2512", nil])
    abort "parent-pair exemption broken: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: empty, fallback: nil)
    abort "empty-registry validation fired (must never raise without a registry): #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: nil, fallback: nil)
    abort "nil catalog must stay parse-only: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model("openrouter/z-ai/glm-4.7", catalog: loaded, fallback: nil)
    abort "registry-resolvable model rejected: #{pair.inspect}" unless pair == ["openrouter", "z-ai/glm-4.7", nil]
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k", "PI_API_BASE" => "http://127.0.0.1:9/v1", "PI_PROVIDER" => "openrouter", "PI_MODEL" => "z-ai/glm-4.7"}, identity: "pi", hooks: Tart::Hooks.new, root: root)
    begin
      manager.spawn_run(agent: "worker", task: "must not spawn", async: false, model: spec)
      abort "spawn dispatched an unknown model without raising"
    rescue ArgumentError => e
      abort "spawn rejection message moved: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    abort "side effects before validation (run dirs created)" unless Dir.children(runs_home).empty?
    puts "UNKNOWN_MODEL_REJECT_OK"'
  expect:
    exit_code: 0
    stdout_match: UNKNOWN_MODEL_REJECT_OK

- id: subagents-health-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_health_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL health pins runs=${runs1:-0} (want >=8; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL health pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENTS_HEALTH_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_HEALTH_UNITS_OK

- id: edit-fold-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    payload = %q({"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []})
    rec = JSON.parse(payload)
    abort "payload is not the recorded folded shape" unless rec["path"].start_with?("architect.yaml\nedits: [\n") && rec["edits"] == []
    tail = rec["path"].split("\n", 2)[1]
    abort "tail is not edits-prefixed" unless tail.match?(/\Aedits:\s*\[/)
    want_edits = begin
      JSON.parse(tail.sub(/\Aedits:\s*\[/, "["))
    rescue JSON::ParserError
      JSON.parse(Fast::Completions::Protocol.repair_json(tail).sub(/\Aedits:\s*\[/, "["))
    end
    e = want_edits.first
    abort "expected one edit in the tail" unless want_edits.size == 1 && e["oldText"] == "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low" && e["newText"] == "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"
    got = Tart::Tools::Edit.normalize_arguments(rec.transform_keys(&:to_sym))
    abort "folded path not recovered: #{got.inspect}" unless got[:path] == "architect.yaml"
    abort "folded edits not recovered: #{got[:edits].inspect}" unless got[:edits] == want_edits
    bad = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [oops", edits: []})
    abort "unparseable tail must stay unchanged: #{bad.inspect}" unless bad == {path: "a.rb\nedits: [oops", edits: []}
    plain = Tart::Tools::Edit.normalize_arguments({path: "a.rb", edits: []})
    abort "no-newline must stay unchanged: #{plain.inspect}" unless plain == {path: "a.rb", edits: []}
    busy = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]", edits: [{oldText: "z", newText: "w"}]})
    abort "non-empty edits must win: #{busy.inspect}" unless busy[:edits] == [{oldText: "z", newText: "w"}] && busy[:path] == "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]"
    msg = "Edit tool input is invalid. edits must contain at least one replacement."
    abort "PINNED_EDITS_MESSAGE moved" unless Tart::Schemas::Tools::PINNED_EDITS_MESSAGE == msg
    v = Tart::Schemas::Tools.validate("edit", {path: "a.rb", edits: []})
    abort "pinned rejection not byte-identical: #{v.inspect}" unless v == {error: msg}
    dir = Dir.mktmpdir("t80ef-")
    begin
      f = File.join(dir, "architect.yaml")
      File.write(f, "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\n")
      tool = Tart::Tools::Edit.new(cwd: dir)
      out = tool.call(**rec.transform_keys(&:to_sym))
      abort "the cured call failed: #{out.inspect}" unless out == "Successfully replaced 1 block(s) in architect.yaml."
      after = File.read(f)
      abort "the staged file was not cured" unless after.include?("openrouter/mistralai/devstral-2512")
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "EDIT_FOLD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_REPRO_OK

- id: edit-fold-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/edit_fold_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL edit-fold pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL edit-fold pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo EDIT_FOLD_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_UNITS_OK

- id: session-model-identity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    m = Tart::Agent::Message.new(role: :assistant, content: "hi", provider: "openrouter", model: "reflection/beam-1.0-501b-a23b:nitro", tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "stop")
    h = m.to_h
    abort "model identity not recorded: #{h.inspect}" unless h[:model] == "reflection/beam-1.0-501b-a23b:nitro"
    abort "provider identity not recorded: #{h.inspect}" unless h[:provider] == "openrouter"
    abort "key order moved: #{h.keys.inspect}" unless h.keys == [:role, :content, :tool_calls, :provider, :model, :finish_reason, :input_tokens, :output_tokens, :cache_write_tokens]
    plain = Tart::Agent::Message.new(role: :assistant, content: "hi").to_h
    abort "model-less assistant byte shape moved: #{plain.keys.inspect}" unless plain.keys == [:role, :content, :tool_calls]
    failure = Tart::Agent::Message.error_failure(error_message: "boom")
    abort "the failure assistant gained keys: #{failure.to_h.keys.inspect}" unless failure.to_h.keys == [:role, :content, :tool_calls, :finish_reason, :error_message]
    user = Tart::Agent::Message.user("hi").to_h
    abort "user message gained keys: #{user.keys.inspect}" unless user.keys == [:role, :content]
    dir = Dir.mktmpdir("t80mi-")
    begin
      rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: File.join(dir, "agent"))
      rec.append_message(Tart::Agent::Message.user("hi"))
      rec.append_message(m)
      lines = File.readlines(rec.path).map { |l| JSON.parse(l) }
      # AMENDMENT 2026-10-18 (escalation-seat ruling, disclosed in the
      # builder-report PHASE 0): the frozen form dereferenced
      # entry["message"] on the session-header line (no "message" key) and
      # raised NoMethodError on its own recorder leg — BROKEN-class, green
      # with no implementation. Nil-safe find only; the discrimination (the
      # first assistant record model identity) is preserved.
      asst = lines.find { |entry| entry["message"] && entry["message"]["role"] == "assistant" }["message"]
      abort "the recorded session lost the model identity: #{asst.keys.inspect}" unless asst["model"] == "reflection/beam-1.0-501b-a23b:nitro" && asst["provider"] == "openrouter"
      seed = Tart::Agent::Message.from_seed_hash(asst)
      abort "the replay seed must stay model-inert: #{seed.model.inspect} #{seed.provider.inspect}" unless seed.model.nil? && seed.provider.nil?
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "SESSION_MODEL_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_IDENTITY_OK

- id: session-model-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/model_identity/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL model-identity pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL model-identity pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SESSION_MODEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_UNITS_OK
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
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
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 34ba69af -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
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
  ac: AC4
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
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t80tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t80ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
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
- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t80s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t80s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t80s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t80s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t80s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t80s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t80s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t80s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t80s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t80s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t80s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t80s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t80s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t80s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t80wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t80wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t80wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t80zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t80zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t80zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i75-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i75-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t80hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t80hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i75-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: subagents-default-law
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK
- id: subagents-default-boot
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK
- id: subagents-motd-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK
- id: subagents-motd-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t80mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t80mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK
- id: rig-staging-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK
- id: vendored-attribution
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK
- id: vendored-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i75-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK
- id: listing-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK
- id: model-menu-live-merge
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK
- id: launcher-listing-thread
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK
- id: vendored-no-boot-network
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK
- id: listing-thread-law
  ac: AC4
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK
- id: md-battery-fixture
  ac: AC1
  cwd: repos/tart
  cmd: |-
    [ -f test/fixtures/markdown_battery.json ] || { echo "FAIL: battery fixture missing (declared-new; copy tmp/i68-spec/markdown_battery.json VERBATIM)"; exit 1; }
    sha=$(shasum -a 256 test/fixtures/markdown_battery.json | cut -d" " -f1)
    [ "$sha" = "4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883" ] || { echo "FAIL: battery fixture sha $sha (want the spec-frozen 4ecd9cc2...)"; exit 1; }
    ruby -rjson -e 'j = JSON.parse(File.read("test/fixtures/markdown_battery.json")); abort "want 48 cases, got #{j["cases"].size}" unless j["cases"].size == 48; puts "MD_BATTERY_FIXTURE_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_FIXTURE_OK
- id: md-battery-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/md_battery/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 48 ] || { echo "FAIL battery pins runs=${runs1:-0} (want >=48; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL battery pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_BATTERY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_UNITS_OK
- id: md-regression-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 79 ] || { echo "FAIL markdown family runs=${runs1:-0} (want >=79 = 31 base + 48 battery; nothing deleted)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown family ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_REGRESSION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_REGRESSION_UNITS_OK
- id: md-flanking-repro
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    flat = ->(src) { Tart::Render::Markdown.rows(src, width: 94).map { |r| r.map { |s| [s.text, s.fg&.to_s, s.modifiers.map(&:to_s).uniq.sort] }.reject { |t, _f, _m| t.empty? } } }
    x = flat.call("checking some_var_name and then other_value next")
    abort "R1a intraword _ em still eats underscores: #{x.inspect}" unless x == [[["checking some_var_name and then other_value next", nil, []]]]
    x = flat.call("A _real_ emphasis case")
    abort "R1b real _em_ lost: #{x.inspect}" unless x == [[["A ", nil, []], ["real", nil, ["italic"]], [" emphasis case", nil, []]]]
    x = flat.call("foo__bar__baz")
    abort "R2 intraword __ strong: #{x.inspect}" unless x == [[["foo__bar__baz", nil, []]]]
    x = flat.call("** padded ** stays literal")
    abort "R3 padded ** strong: #{x.inspect}" unless x == [[["** padded ** stays literal", nil, []]]]
    x = flat.call("foo*bar*baz")
    abort "R3b * intraword em lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["italic"]], ["baz", nil, []]]]
    x = flat.call("foo**bar**baz")
    abort "R3c ** intraword strong lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["bold"]], ["baz", nil, []]]]
    x = flat.call("*em **inner** em*")
    abort "R4 em not spanning inner *: #{x.inspect}" unless x == [[["em ", nil, ["italic"]], ["inner", nil, ["bold", "italic"]], [" em", nil, ["italic"]]]]
    x = flat.call("back \\to *em* now")
    abort "R5 backslash before letter eaten: #{x.inspect}" unless x == [[["back \\to ", nil, []], ["em", nil, ["italic"]], [" now", nil, []]]]
    x = flat.call("see [wiki](https://en.wikipedia.org/wiki/Foo_(bar)) here")
    abort "R6 parens-in-URL span boundary: #{x.inspect}" unless x == [[["see ", nil, []], ["wiki", "light_blue", ["underlined"]], [" (https://en.wikipedia.org/wiki/Foo_(bar))", "gray", []], [" here", nil, []]]]
    x = flat.call("  ```\n  indented body\n  ```")
    abort "R7 indented fence body not dedented: #{x.inspect}" unless x == [[["```", "gray", []]], [["  ", nil, []], ["indented body", "green", []]], [["```", "gray", []]]]
    x = flat.call("- [x] done\n- [ ] todo")
    abort "R8 task marker not in bullet span: #{x.inspect}" unless x == [[["- [x] ", "light_magenta", []], ["done", nil, []]], [["- [ ] ", "light_magenta", []], ["todo", nil, []]]]
    x = flat.call("x * padded * and *em* tail")
    abort "I65 reject-emission semantics regressed: #{x.inspect}" unless x == [[["x * padded * and ", nil, []], ["em", nil, ["italic"]], [" tail", nil, []]]]
    puts "MD_FLANKING_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_FLANKING_OK
- id: md-micro-perf
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    line = ->(i) { "row #{i} of some_var_name plus __dunder__ and **bold words** and *em words* and [link #{i}](https://example.test/wiki/Foo_(bar)) and `code #{i}` and ~~strike this~~ and \\no escape; filler text to widen the line toward the wrap width ninety-four" }
    p80 = (1..80).map(&line).join("\n")
    p160 = (1..160).map(&line).join("\n")
    3.times { Tart::Render::Markdown.rows(p80, width: 94) }
    n = 100
    bm = lambda do |src|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      n.times { Tart::Render::Markdown.rows(src, width: 94) }
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0 / n
    end
    a = bm.call(p80); b = bm.call(p160)
    abort format("MD_MICRO absolute over budget: %.2f ms/conversion (want <= 8.0; at-base anchor ~2.8 this session)", a) if a > 8.0
    abort format("MD_MICRO scale ratio over budget: %.2f (want <= 3.0; linear base ~2.1, the I68 defect ~4.1)", b / a) if b / a > 3.0
    puts format("MD_MICRO_OK %.2f ms/conv ratio %.2f", a, b / a)'
  expect:
    exit_code: 0
    stdout_match: MD_MICRO_OK
- id: child-env-law-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "fileutils"; require "tmpdir"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    poisoned = {
      "BUNDLE_GEMFILE" => "/t/Gemfile", "BUNDLE_LOCKFILE" => "/t/Gemfile.lock",
      "BUNDLE_BIN_PATH" => "/b/exe/bundle", "BUNDLER_VERSION" => "4.0.22",
      "BUNDLER_SETUP" => "/s/bundler/setup",
      "RUBYOPT" => "-r/s/bundler/setup -w", "RUBYLIB" => "/s",
      "GEM_HOME" => "/gems", "GEM_PATH" => "/gp", "MANPATH" => "/m",
      "RB_USER_INSTALL" => "1", "PATH" => "/bundle/bin:/usr/bin:/bin",
      "BUNDLER_ORIG_BUNDLE_GEMFILE" => NIL, "BUNDLER_ORIG_BUNDLE_LOCKFILE" => NIL,
      "BUNDLER_ORIG_BUNDLE_BIN_PATH" => NIL, "BUNDLER_ORIG_BUNDLER_VERSION" => NIL,
      "BUNDLER_ORIG_BUNDLER_SETUP" => NIL, "BUNDLER_ORIG_GEM_HOME" => NIL,
      "BUNDLER_ORIG_GEM_PATH" => NIL, "BUNDLER_ORIG_MANPATH" => NIL,
      "BUNDLER_ORIG_RB_USER_INSTALL" => NIL, "BUNDLER_ORIG_PATH" => "/usr/bin:/bin",
      "BUNDLER_ORIG_RUBYOPT" => "-w", "BUNDLER_ORIG_RUBYLIB" => NIL,
      "USER_VAR" => "keep-me"
    }
    frozen = poisoned.dup
    out = Tart::ChildEnv.scrub(poisoned)
    abort "the scrub MUTATED its argument" unless poisoned == frozen
    %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
       GEM_HOME GEM_PATH MANPATH RB_USER_INSTALL RUBYLIB].each do |k|
      abort "poison key #{k} survived: #{out[k].inspect}" if out.key?(k)
    end
    abort "ORIG residue survived: #{out.keys.grep(/\ABUNDLER_ORIG_/).inspect}" unless out.keys.grep(/\ABUNDLER_ORIG_/).empty?
    abort "ORIG-restore lost USER_VAR" unless out["USER_VAR"] == "keep-me"
    abort "PATH not restored to the ORIG record" unless out["PATH"] == "/usr/bin:/bin"
    abort "RUBYOPT not restored to the user original" unless out["RUBYOPT"] == "-w"
    belt = {
      "RUBYOPT" => "-r/x/y/bundler/setup -w -rother", "USER_VAR" => "keep-me",
      "BUNDLER_ORIG_USER_TAIL" => NIL
    }
    bout = Tart::ChildEnv.scrub(belt)
    abort "belt: the bundler setup token survived RUBYOPT: #{bout["RUBYOPT"].inspect}" unless bout["RUBYOPT"] == "-w -rother"
    dir = Dir.mktmpdir("i75-belt-")
    begin
      FileUtils.mkdir_p(File.join(dir, "bundler"))
      FileUtils.touch(File.join(dir, "bundler", "setup.rb"))
      blib = {
        "RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR),
        "BUNDLER_ORIG_RUBYLIB" => NIL
      }
      bluff = Tart::ChildEnv.scrub(blib)
      abort "a NIL ORIG record must DELETE RUBYLIB (records are authoritative, the belt never overrides them): #{bluff["RUBYLIB"].inspect}" if bluff.key?("RUBYLIB")
      blib2 = {"RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR)}
      b2 = Tart::ChildEnv.scrub(blib2)
      abort "belt-with-no-record must still strip the bundler lib dir: #{b2["RUBYLIB"].inspect}" unless b2["RUBYLIB"] == "/user/lib"
    ensure
      FileUtils.rm_rf(dir)
    end
    clean = {"PATH" => "/usr/bin:/bin", "HOME" => "/h", "USER_VAR" => "v"}
    cout = Tart::ChildEnv.scrub(clean)
    abort "clean env is not an identity: #{cout.inspect}" unless cout == clean
    empty = Tart::ChildEnv.scrub({})
    abort "empty env is not an identity: #{empty.inspect}" unless empty == {}
    puts "CHILD_ENV_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_LAW_OK
- id: child-env-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_env_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL child-env law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-env law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENV_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_UNITS_OK
- id: child-env-site-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 2 ] || { echo "FAIL bash seam pins runs=${runs1:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL bash seam pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/child_env/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL subagents seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/mcp_test.rb -n "/child_env/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 1 ] || { echo "FAIL mcp seam pins runs=${runs3:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL mcp seam pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo CHILD_ENV_SITE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_SITE_UNITS_OK
- id: bash-child-env-live
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    expected = lambda do |key|
      orig = ENV["BUNDLER_ORIG_#{key}"]
      orig.nil? ? :absent : (orig == NIL ? :absent : orig)
    end
    child_lines = lambda do |text|
      text.to_s.lines.map(&:strip).reject(&:empty?).to_h { |l| l.split("=", 2) }
    end
    check = lambda do |env, arm|
      %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
         GEM_HOME GEM_PATH MANPATH RUBYLIB RB_USER_INSTALL].each do |k|
        want = expected.call(k)
        if want == :absent
          abort "LIVE(#{arm}): #{k} reached the child: #{env[k].inspect}" if env.key?(k)
        else
          abort "LIVE(#{arm}): #{k}=#{env[k].inspect}, want the user-shell #{want.inspect}" unless env[k] == want
        end
      end
      abort "LIVE(#{arm}): RUBYOPT carries bundler poison: #{env["RUBYOPT"].inspect}" if env["RUBYOPT"].to_s.include?("bundler/setup")
      want_path = expected.call("PATH")
      abort "LIVE(#{arm}): no BUNDLER_ORIG_PATH record — the gate parent is not under bundle exec" if want_path == :absent
      abort "LIVE(#{arm}): PATH #{env["PATH"].inspect} is not the user-shell PATH" unless env["PATH"] == want_path
      abort "LIVE(#{arm}): BUNDLER_ORIG residue in the child" unless env.keys.grep(/\ABUNDLER_ORIG_/).empty?
    end
    tool = Tart::Tools::Bash.new(cwd: Dir.pwd)
    out = Async { tool.execute(command: "env", timeout: 30) }.wait
    abort "LIVE(tool): env dump failed: #{out.inspect}" if out.is_a?(Hash) && out[:error]
    tool_text = out.is_a?(String) ? out : out[:content].to_s
    check.call(child_lines.call(tool_text), "tool")
    user = Async { tool.run_user("env") }.wait
    check.call(child_lines.call(user.content), "run_user")
    cli = Async { tool.execute(command: "architect --version && gem --version", timeout: 60) }.wait
    abort "LIVE: the owner-class rubygems CLIs did not resolve in the child: #{cli.inspect}" if cli.is_a?(Hash) && cli[:error]
    puts "BASH_CHILD_ENV_LIVE_OK"'
  expect:
    exit_code: 0
    stdout_match: BASH_CHILD_ENV_LIVE_OK
- id: session-sink-config-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/config_law/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL config law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL config law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    if grep -nE "extensions (<<|\+=) .?.?session-sink" bin/tart; then echo "FAIL: a session-sink MOTD/extensions row was added (the no-row ruling)"; exit 1; fi
    bundle exec ruby -Ilib -e 'require "tart"
    abort "QUEUE_CAP moved" unless Tart::SessionSink::QUEUE_CAP == 2000
    abort "DEBOUNCE_MS moved" unless Tart::SessionSink::DEBOUNCE_MS == 250 && Tart::SessionSink::DEBOUNCE_MS <= 500
    abort "POST_TIMEOUT_MS moved" unless Tart::SessionSink::POST_TIMEOUT_MS == 8000
    abort "MAX_ATTEMPTS moved" unless Tart::SessionSink::MAX_ATTEMPTS == 3
    abort "RETRY_BACKOFF_MS moved" unless Tart::SessionSink::RETRY_BACKOFF_MS == [500, 1000]
    abort "SHUTDOWN_WAIT_MS moved" unless Tart::SessionSink::SHUTDOWN_WAIT_MS == 1000
    abort "SHUTDOWN_POST_TIMEOUT_MS moved" unless Tart::SessionSink::SHUTDOWN_POST_TIMEOUT_MS == 2000
    url = Tart::SessionSink.ingest_url("http://deck.test/")
    abort "ingest_url form moved: #{url.inspect}" unless url == "http://deck.test/conversations/ingest"
    puts "SESSION_SINK_CONSTANTS_OK"'
    echo SESSION_SINK_CONFIG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CONFIG_UNITS_OK
- id: session-sink-projection-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/projection/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL projection pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL projection pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"
    S = "018f0000-0000-7000-8000-000000000001"
    abort "record id law" unless Tart::SessionSink.record_id(S, 7) == "#{S}/7"
    u = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.user("hi there")}, S, 1)
    uj = JSON.parse(JSON.generate(u))
    um = uj["message"]
    abort "user record shape: #{uj.inspect}" unless uj["type"] == "message_end" && uj["id"] == "#{S}/1"
    abort "user blocks: #{um["content"].inspect}" unless um["role"] == "user" && um["content"] == [{"type" => "text", "text" => "hi there"}]
    abort "user timestamp: #{um["timestamp"].inspect}" unless um["timestamp"].is_a?(Integer) && um["timestamp"] > 1_700_000_000_000
    abort "user keys moved: #{um.keys.inspect}" unless um.keys.sort == ["content", "role", "timestamp"]
    call = Tart::Agent::ToolCall.new(id: "c1", name: "bash", arguments: {"command" => "ls"})
    am1 = Tart::Agent::Message.new(role: :assistant, content: "the answer", tool_calls: {"c1" => call},
      thinking: Tart::Agent::Thinking.new(text: "because", signature: "reasoning_content"),
      tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "tool_calls")
    a = Tart::SessionSink.project_event({type: :message_end, message: am1}, S, 2)
    aj = JSON.parse(JSON.generate(a))
    am = aj["message"]
    abort "assistant record id" unless aj["id"] == "#{S}/2"
    want_blocks = [{"type" => "thinking", "thinking" => "because", "thinkingSignature" => "reasoning_content"},
      {"type" => "text", "text" => "the answer"},
      {"type" => "toolCall", "id" => "c1", "name" => "bash", "arguments" => {"command" => "ls"}}]
    abort "assistant blocks: #{am["content"].inspect}" unless am["content"] == want_blocks
    abort "stopReason map: #{am["stopReason"].inspect}" unless am["stopReason"] == "toolUse"
    abort "usage map: #{am["usage"].inspect}" unless am["usage"] == {"input" => 5, "output" => 4, "cacheWrite" => 0}
    {"stop" => "end_turn", "length" => "maxTokens", "error" => "error"}.each do |fr, want|
      m = Tart::Agent::Message.new(role: :assistant, content: "x", finish_reason: fr)
      r = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: m}, S, 3)))
      abort "stopReason map #{fr}: #{r["message"]["stopReason"].inspect}" unless r["message"]["stopReason"] == want
    end
    quiet = Tart::Agent::Message.new(role: :assistant, content: "x")
    q = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: quiet}, S, 4)))
    abort "unreported usage must omit the key: #{q["message"].keys.inspect}" if q["message"].key?("usage")
    abort "absent finish_reason must omit stopReason: #{q["message"].keys.inspect}" if q["message"].key?("stopReason")
    t = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "ok-output", duration: 1.234}, S, 5)
    tj = JSON.parse(JSON.generate(t))
    want_tool = {"type" => "tool_execution_end", "id" => "#{S}/5", "toolCallId" => "c1", "toolName" => "bash",
      "result" => {"content" => [{"type" => "text", "text" => "ok-output"}]}, "isError" => false, "durationMs" => 1234}
    abort "tool record: #{tj.inspect}" unless tj == want_tool
    e = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: {"error" => "boom"}, duration: 0.5}, S, 6)
    ej = JSON.parse(JSON.generate(e))
    abort "isError law: #{ej.inspect}" unless ej["isError"] == true && ej.dig("result", "content", 0, "text") == JSON.generate({"error" => "boom"})
    p = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "x", duration: 0.5, parent_tool_call_id: "pc9"}, S, 7)
    abort "parentToolCallId present-only law" unless JSON.parse(JSON.generate(p))["parentToolCallId"] == "pc9"
    skip1 = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.tool(tool_call_id: "c1", content: "x")}, S, 8)
    skip2 = Tart::SessionSink.project_event({type: :message_start, message: Tart::Agent::Message.user("x")}, S, 9)
    abort "skip rules: #{skip1.inspect} #{skip2.inspect}" unless skip1.nil? && skip2.nil?
    puts "SESSION_SINK_PROJECTION_REPRO_OK"'
    echo SESSION_SINK_PROJECTION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_PROJECTION_UNITS_OK
- id: session-sink-engine-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/engine/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL engine pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL engine pins ec=$ec"; echo "$out1" | tail -10; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/boot/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 5 ] || { echo "FAIL process-level boot pins runs=${runs2:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL process-level boot pins ec=$ec"; echo "$out2" | tail -12; exit 1; }
    echo SESSION_SINK_ENGINE_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_ENGINE_E2E_OK
- id: session-sink-child-e2e
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/child_capture/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL child-capture pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-capture pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    echo SESSION_SINK_CHILD_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CHILD_E2E_OK
- id: signal-hygiene-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/routing/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL routing pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL routing pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/teardown/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 6 ] || { echo "FAIL teardown pins runs=${runs2:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL teardown pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"
    codes = Tart::TUI::SignalGuard::EXIT_FOR
    abort "EXIT_FOR moved: #{codes.inspect}" unless codes == {"HUP" => 129, "TERM" => 143}
    bound = Tart::TUI::SignalGuard::EXIT_BOUND_S
    abort "EXIT_BOUND_S moved: #{bound.inspect}" unless bound == 10
    puts "SIGNAL_CONSTANTS_OK"'
    echo SIGNAL_HYGIENE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SIGNAL_HYGIENE_UNITS_OK
- id: signal-orphan-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t80sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t80sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK
- id: subagent-box-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagent_box_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 12 ] || { echo "FAIL box pins runs=${runs1:-0} (want >=12; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL box pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENT_BOX_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_BOX_UNITS_OK

- id: subagent-status-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagent-status-probe ]; then echo "FAIL subagent-status-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t80sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t80sb
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_STATUS_OK
- id: child-encoding-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_encoding_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 7 ] || { echo "FAIL encoding pins runs=${runs1:-0} (want >=7; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENCODING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_UNITS_OK
- id: child-encoding-e2e
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/encoding_e2e/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 1 ] || { echo "FAIL encoding e2e runs=${runs1:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding e2e ec=$ec"; echo "$out1" | tail -20; exit 1; }
    echo CHILD_ENCODING_E2E_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_E2E_OK
- id: runner-encoding-direct
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest -e 'require "tmpdir"; require "fileutils"; require "json"; require_relative "test/support/mock_llm_server"
    prompt = "I80 runner: the Diataxis-note payload Diátaxis résumé — á é ü ✓ (em-dash —)"
    answer = "I80 runner answer: Diátaxis résumé ✓ — á é ü OK"
    home = Dir.mktmpdir("i80rd-")
    server = MockLLMServer.new.start
    server.script([{type: :stream, content: answer}])
    env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi", "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "zai/glm-5.3-e2e", "TART_MCP_CONFIG" => File.join(home, "absent.json")}
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    pid = Process.spawn(env, RbConfig.ruby, "bin/tart", "-p", prompt, home, chdir: Dir.pwd, unsetenv_others: true, pgroup: true, out: out_w, err: err_w)
    out_w.close
    err_w.close
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 120
    status = nil
    loop do
      _p, status = Process.waitpid2(pid, Process::WNOHANG)
      break if status
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        begin
          Process.kill("-KILL", -pid)
        rescue StandardError
          nil
        end
        Process.waitpid2(pid)
        abort "I80 direct: parent watchdog fired"
      end
      sleep 0.1
    end
    stdout = out_r.read
    stderr = err_r.read
    out_r.close
    err_r.close
    abort "I80 direct: exit #{status.exitstatus} (stderr: #{stderr.lines.first})" unless status.exitstatus == 0
    abort "I80 direct: stdout mismatch (#{stdout.bytesize}B)" unless stdout.chomp == answer
    hits = stderr.scan("passed as BINARY").size
    abort "I80 direct: #{hits} JSON.generate encoding warning(s) on the runner stderr" unless hits.zero?
    logs = server.captured_request_logs
    body = logs.find { |log| (log[:body]["messages"] || []).any? { |m| m["content"].to_s.include?(prompt) } }
    abort "I80 direct: no wire request carries the non-ASCII prompt" unless body
    server.stop
    FileUtils.rm_rf(home)
    puts "RUNNER_ENCODING_DIRECT_OK"'
  expect:
    exit_code: 0
    stdout_match: RUNNER_ENCODING_DIRECT_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    git diff --quiet 34ba69af -- Gemfile Gemfile.lock tart.gemspec bench gems lib ':(exclude)lib/tart/utf8_boot.rb' ':(exclude)lib/tart/subagents/manager.rb' &&
    ! (git diff --name-only 34ba69af; git status --porcelain | grep "^??" | cut -c4-) |
    grep -vE "^(lib/tart/utf8_boot\.rb|lib/tart/subagents/manager\.rb|bin/tart|test/child_encoding_test\.rb|test/subagents_e2e_test\.rb|t7[5-9][0-9a-z]*/?|t80[0-9a-z]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-?)$" |
    grep -q . &&
    [ -n "$(git diff 34ba69af -- lib/tart/subagents/manager.rb)" ] &&
    [ -n "$(git diff 34ba69af -- bin/tart)" ] &&
    [ -n "$(git diff 34ba69af -- test/subagents_e2e_test.rb)" ] &&
    # New-at-base must-differ legs take the -f form from the START (the
    # I79 seat escalation lesson: git diff <commit> -- <untracked> is
    # empty by construction at a never-commit lane tree).
    [ -f lib/tart/utf8_boot.rb ] &&
    [ -f test/child_encoding_test.rb ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 5-path touch set (lib/tart/utf8_boot.rb the NEW boot law, lib/tart/subagents/manager.rb the locale picks + hygienic readers, bin/tart the one-line boot call, test/child_encoding_test.rb the NEW pins, test/subagents_e2e_test.rb the DECLARED re-pin carrying the encoding e2e leg) — lib/tart/child_env.rb is HARD-FROZEN (the scrub law is byte-untouched, the plan constraint) — or one of the three tracked must-differ seams is untouched"; exit 1; }
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Builder lane prompt — iteration `child-encoding-hygiene` (I80), lane `core`, repo `tart`

You are the builder for iteration `child-encoding-hygiene` (I80), lane `core`, repo `tart`. You are the ONLY lane. Your worktree is `build/I80-child-encoding-hygiene-core/wt` (base `34ba69af`, branch `lane/I80-child-encoding-hygiene-core`) — do all work THERE; the space's main checkout is read-only for you. **ZERO live API calls of any kind** — no provider keys, no driver scripts, no spend (every pin and leg is hermetic: staged homes, the MockLLMServer, closed subprocess envs).

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I80-child-encoding-hygiene.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (the three Laws, Output format, Tool guidance, Boundaries, Lane plan, the 88-gate frozen ```gates block with its rehearsal declarations). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting read: `notes/spec-digest-20261018T234835Z-subagent-status-box.md` (the I79 handoff — the carry/adjudication classes, the declared-RED pattern, judge-runs-gates-at-the-lane-tree, never gates under nohup, short out dirs, the new-directory `dir/**` touch-path rule) and this spec's scratch `tmp/i80-spec/` (grounds/spec/AC sources, the carried-gates rebases, and the two base-RED probe scripts `probe-runner.rb` / `probe-manager.rb` — READ-ONLY reference for the defect shapes; never copy them into the repo).

## THE DEFECT (one root class, three symptoms — all reproduced hermetically at base this session)

A locale-less child process (`Encoding.default_external = US-ASCII`; the subagent child env pick list drops `LANG`/`LC_*`, and a locale-less parent chain never had them) mangles every non-ASCII byte crossing the child boundary: (a) the task text rides ARGV tagged ASCII-8BIT → `JSON.generate: UTF-8 string passed as BINARY` warnings on every wire round (52 copies in the dead devstral spec run); (b) the locale-blind text-mode `read_output` RAISES on the child's byte-exact non-ASCII stdout and its rescue swallows it to `""` → the run settles `failed` with the json warning recorded as its `error` — the exact devstral failure class (`01a14df7`, `01a14e3c`); (c) `String#strip`/`String#sub` raise `invalid byte sequence in US-ASCII` inside the child (the architect-CLI crash class). The scrub itself strips NOTHING locale-related — the audit answer; your cure rides ON TOP of the untouched scrub.

## WHAT YOU ARE LANDING (three frozen laws, one lane)

1. **LAW 1 — the child locale law** (`lib/tart/subagents/manager.rb`, the private `child_env` pick builder behind the PUBLIC `spawn_argv_and_env`): after the existing picks, (a) pass-through picks — `LANG` and every source key matching `/\ALC_/`, present-non-empty, verbatim values (pi parity: pi-subagents passes the full parent env, async-execution.js:503); (b) the UTF-8 floor — effective charset key `env["LC_ALL"] || env["LC_CTYPE"] || env["LANG"]`; if nil or not matching `/UTF-?8\z/i`, set `env["LC_ALL"] = "en_US.UTF-8"` when `LC_ALL` is present (it masks `LC_CTYPE`), else `env["LC_CTYPE"] = "en_US.UTF-8"` (frozen constant `UTF8_LOCALE = "en_US.UTF-8"`). The pick list grows ONLY these keys — the CLOSED-env design (I73 OQ-7) stays; `lib/tart/child_env.rb` is HARD-FROZEN byte-untouched (the plan's constraint, mechanically enforced by the scope gate).
2. **LAW 2 — the boot UTF-8 law** (`lib/tart/utf8_boot.rb`, NEW + one require-and-call in `bin/tart`'s `run(argv)` before parse): `Tart::UTF8Boot.enforce!(argv:)` — unless `Encoding.default_external` is already UTF-8, set it to `Encoding::UTF_8` (`Encoding.default_internal` stays nil, never touched); ARGV retag: each element whose encoding is not UTF-8 AND whose bytes are valid UTF-8 gets `force_encoding(Encoding::UTF_8)` in place; invalid-UTF-8 bytes are left byte-identical, never mangled. It sets Encoding values, NOT env vars. It cures the DIRECT runner path (a locale-less `bin/tart -p "Diátaxis…"` — measured at base: 2 warnings on stderr while stdout round-trips) and is a no-op belt under Law 1.
3. **LAW 3 — byte-hygienic artifact readers** (`lib/tart/subagents/manager.rb`): `read_output` (:1159) reads via `File.binread` → `force_encoding(Encoding::UTF_8).scrub` → the existing trailing-newline `.sub(/\n\z/, "")`, `rescue StandardError → ""` belt stays; `first_error_line` (:1168) gets the same discipline (binread + force + scrub, first non-empty `.strip`, `rescue → nil` belt stays). The port's own established idiom (`output_accumulator.rb:41`, `read.rb:85`) — byte-identical for valid UTF-8, never-raise for arbitrary child bytes. NOTHING else in the settle/reap/ownership chain moves (I78's laws byte-unchanged; `truncate_utf8_head` is already byte-safe and untouched).

Frozen discipline you must not drift from: wire-delta + session-golden hold EXACT (encoding tags move, bytes do not — JSON.generate output is byte-identical for a valid UTF-8 string whether tagged UTF-8 or BINARY); the task-never-recorded law (`taskChars` only) stays; no rig scenario-content edits; no new gems; no new `Thread.new` sites.

## Deliverable (frozen Output format)

Code + tests, exactly the 5-path touch set. The pin battery lives in `test/child_encoding_test.rb` (NEW, ≥ 7 runs under the `/encoding/` filter — the `child-encoding-units` gate floor), driving the PUBLIC surfaces (`spawn_argv_and_env` with a staged Manager — the `subagents_test` idiom; `Tart::UTF8Boot.enforce!` with save/restore of `Encoding.default_external` in ensure): at minimum, pins for (1) locale pass-through from a POISONED bundler env (child env carries `LANG` verbatim AND zero bundler keys — the constraint honored); (2) the floor when no locale key is present (`LC_CTYPE=en_US.UTF-8`, nothing invented for `LANG`); (3) a non-UTF-8 `LANG=C` → `LC_CTYPE` floor with `LANG` untouched; (4) a UTF-8 `LANG` → nothing added or changed; (5) a present non-UTF-8 `LC_ALL` → `LC_ALL` overridden; (6) the argv task text byte-exact (a Diátaxis-grade payload, bytes compared); (7) the boot law both ways (US-ASCII external → UTF-8 + BINARY-valid-UTF-8 argv retagged; invalid-UTF-8 argv left byte-identical; UTF-8 external a no-op).

The e2e leg lives in `test/subagents_e2e_test.rb` (the DECLARED re-pin file): ONE new leg `test_encoding_e2e_non_ascii_round_trip` under the `/encoding_e2e/` filter — leg A's exact machinery (staged HOME, the closed locale-less `tart_env` — ALREADY the defect environment, no new staging, MockLLMServer, the foreground subagent call) with a Diátaxis-grade non-ASCII task AND child answer, asserting: parent exit 0; the child wire request carries the task byte-exact; `runner.stderr.log` ZERO `passed as BINARY` lines; the PARENT's own stderr ZERO (the boot law's leg); `status.json` `completed` with `taskChars` == the task's CHARACTER count; `result.json` `success: true` and `output` == the child answer BYTE-EXACT; the parent's final stdout byte-exact. Any edit to existing legs is behavior-preserving re-pinning only.

## Operating constraints (lane)

- Touch set (frozen, the scope gate bites exactly): `lib/tart/utf8_boot.rb` (NEW), `lib/tart/subagents/manager.rb`, `bin/tart`, `test/child_encoding_test.rb` (NEW), `test/subagents_e2e_test.rb` — the three tracked must-differ seams (`manager.rb`, `bin/tart`, `subagents_e2e_test.rb`) must all change; `lib/tart/child_env.rb` is HARD-FROZEN.
- No live API spend. No new gems. No new threads. No rig scenario edits.
- PHASE 0: every disagreement with this spec is raised with reasons in your report (or an explicit statement of what was checked before concluding the spec is sound) — silent compliance is a defect.
- The four declared-RED gates (`child-encoding-units`, `child-encoding-e2e`, `runner-encoding-direct`, `scope` — scope REDs on the empty must-differ legs pre-work) turn GREEN only with your lane work; everything else is a regression anchor that must not move. The standing adjudication classes (s9/herdr lane-tree depth, render-perf BP2 load margin, the suite's env/interrupt classes) are declared in the AC — never silently patched.
- Scratch under `build/I80-child-encoding-hygiene-core/scratch/`; never commit the `t80*` gate out dirs.
- Verification (exact, measured at base): `bundle install --quiet && bundle exec rake` → 1443 runs / 6793 asserts / 0F / 0E / 1S, exit 0 (post-lane ≥ 1443 runs, 0F/0E); `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`. The unit/e2e forms are in the arch file's Tool guidance.
- Report at `build/I80-child-encoding-hygiene-core/report.md`: the suite summary line, the FULL 88-gate table (every gate, one measured one-liner each — itemize-and-defend), deviations itemized, a final `STATUS:` line.

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
