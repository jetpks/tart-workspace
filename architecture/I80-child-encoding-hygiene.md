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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section child-encoding-hygiene specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision child-encoding-hygiene`
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
