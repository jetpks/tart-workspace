# I86: fast-llm-ruby-4-0-9

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# fast-llm-ruby-4-0-9 grounds — RUBY-PIN PROGRAM ENTRY 2

Plan: the owner-directed ruby-pin program (the 2026-10-24 dispatch — ENTRY 1
I85 ruby-4-0-9, repo tart, DONE: CONTINUE 5/5, integrated merge `40ed92b` on
project/pi-port; THIS is ENTRY 2, repo fast-llm, ONE lane `core`). Base tip
for this iteration: **`0c1949c`** on `main` (`Merge pull request #5 from
jetpks/project/incremental-args`; verified this session:
`git -C repos/fast-llm log --oneline -1` = `0c1949c`, tracked tree clean,
`origin/main` == `0c1949c` — the tart-class squashed-PR divergence does NOT
apply here; main is the owner's PR-landing branch for this repo).

## Why (owner directive, the plan header — cited, not restated)

Same ruling as ENTRY 1: the ruby version becomes a **committed repo fact** —
`.ruby-version` → `4.0.9` — and the move is a **re-verification event**, not
a version-string edit. The diff is one line; **the gates are the
deliverable**. ENTRY 2 is the wire gem's home: the monorepo's dev-env truth.
fast-completions is pure ruby and tart consumes it as the published 0.5.0
gem (`repos/tart/Gemfile`: `gem "fast-completions", "0.5.0"`), so nothing
here moves tart's bundle — repos/tart is entirely out of bounds.

## Machine facts (measured fresh, this session)

- `ruby -v` in `repos/fast-llm`: **ruby 4.0.9 (2026-10-23 revision
  3e93b23afc) +PRISM [arm64-darwin25]**; `mise current ruby` = 4.0.9. NO
  `.ruby-version` at base — resolution rides global mise `latest` (the plan
  header: global `latest` now resolves 4.0.9, so unpinned trees — lane
  BASEs, the canonical checkout — also boot 4.0.9). Consequence, frozen into
  the gate design (I85's, carried): **base-vs-lane ruby-version
  discrimination is NOT available via the runtime alone; the `.ruby-version`
  file content itself is the pin gate.**
- The architect CLI: 9.6.0 on 4.0.9 (`architect --version`, verified this
  session by using it).

## The measured bundle facts (this session, base `0c1949c`, scratch worktree
`tmp/fllm-probe` — the canonical checkout was NOT dirtied by measurements)

- `bundle install --quiet` under 4.0.9 at the pristine base: **green in
  ~5.4 s cold**. All gems already present in the 4.0.9 gem home.
- **The bundler self-checksum heal class FIRES HERE TOO (measured this
  session, the I85 discovery carried):** the lock at `0c1949c` is
  `BUNDLED WITH 4.0.22` with a CHECKSUMS section that does NOT include
  bundler itself; bundler 4.0.22's `bundle install --quiet` deterministically
  self-heals it by adding EXACTLY ONE line —
  `+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`
  — inserted in sorted position between async-pool and console (measured:
  `git diff` = 1 file, 1 insertion, 0 deletions; byte-identical line to the
  I85 tart heal). Measured further: `bundle exec` alone does NOT heal
  (lock restored, `bundle exec rspec --version` run, diff stayed zero) —
  only `bundle install` heals. Every gate that runs `bundle install` at a
  pristine tree produces it, so the ruby-pin/scope lock legs accept exactly
  this class (zero-diff OR the single heal line, shape-pinned) and reject
  anything else. Any other Gemfile.lock movement is itemize-and-defend
  PHASE 0. The lane NEVER hand-edits the lock.
- Gem load smoke (measured, in the ruby-pin lane-simulation):
  `bundle exec ruby -e 'require "fast/completions"'` →
  `Fast::Completions::VERSION == "0.5.0"`, `Fast::Completions::Client`
  defined. Pure ruby — NO native-extension leg (that class is tart's, I85's
  native-bundle gate; nothing native here).

## The measured suite + battery facts (this session, base, ruby 4.0.9)

Every carried gate measured standalone at base:

- `suite` (bare `bundle exec rspec`, the `.rspec` pattern
  `gems/completions/spec/fast/**/*_spec.rb`): **247 examples, 0 failures**,
  ~2.1 s. (The I51-era floor was 122 examples; since grown — this spec's
  247 is the measured literal the AC prose records.)
- `parity` (wire_parity_spec.rb — the frozen pi-capture digest table lives
  INSIDE this spec: `FROZEN_DIGESTS`, the 13-fixture shape/path/SHA256 pin,
  wire_parity_spec.rb :76/:269-281): **14 examples, 0 failures**.
- `strict-wire` (wire_parity `-e zai_strict`): **2 examples, 0 failures**.
- `strict-unit` (constrained_sampling_spec): **21 examples, 0 failures**.
- `strict-dialect` (dialects `-e supports_strict_mode`): **3 examples, 0
  failures**.
- `strict-tool` (tool `-e constrained`): **3 examples, 0 failures**.
- `strict-emission` (protocol `-e strict`): **7 examples, 0 failures**.
- `dep-pin` (re-anchored from the I51 ARCH FILE): `DEP_PIN_OK` (runtime
  deps EXACTLY `[["async-http", "~> 0.95"]]`) + `NO_FARADAY_OK` — measured
  standalone GREEN.
- `no-catalog` (re-anchored from the I51 ARCH FILE): `NO_CATALOG_OK` —
  measured standalone GREEN.
- `docs`: the I63 form REDs at base on ONE leg — `grep -q "^## Unreleased"
  gems/completions/CHANGELOG.md` fails because the owner has since cut
  0.4.0/0.4.1/0.5.0 (CHANGELOG now `## 0.5.0`-first; the strict machinery
  shipped under `## 0.4.0`, whose section carries 4 "constrained" hits).
  The other four legs GREEN. **Declared release-cut rebase (the ONLY
  functional rebase to the carried 8): the Unreleased leg →
  `grep -q "^## 0\.4\.0"`** — verified standalone GREEN post-rebase
  (`STRICT_DOCS_OK`). Carry audit `tmp/fllm409-spec/rebase.rb`:
  rebase-then-invert reproduces the extracted I63 block minus scope
  byte-identically — `CARRY_AUDIT_OK`.
- New gates `ruby-pin` + `scope`: verified standalone **declared-RED at
  base for EXACTLY the declared reason** (`.ruby-version` absent), and
  GREEN in a lane-simulation (`.ruby-version` = `4.0.9\n` written; the
  ruby-pin bundle-install leg healed the lock and BOTH gates' lock legs
  accepted exactly the one declared line).

## The carried battery (the extraction + rebase record)

- The carry source is the **I63 frozen ```gates block in
  `architecture/I63-strict-sampling-gem.md` — THE ARCH FILE, never a
  digest** (the standing discipline; I63 is the last fast-llm-repo
  iteration — I64's strict-sampling-integration is the tart consumer half
  with zero fast-llm-cwd gates). 9 gates: 8 carried + the per-iteration
  `scope` (rewritten per-iteration).
- This iteration carries **8** (suite, parity, strict-wire, strict-unit,
  strict-dialect, strict-tool, strict-emission, docs) with the ONE declared
  docs rebase above, re-anchors **2** hygiene pins byte-verbatim from the
  **I51 ARCH FILE** (dep-pin, no-catalog — dropped from the battery after
  I51, re-anchored here per the entry's acceptance direction), and adds
  **2** new (ruby-pin, scope-rewrite) → **12 gates**. Carried/re-anchored
  gates keep origin `ac:` labels verbatim (house convention; the prose ACs
  name which gate carries which property).
- Handoff facts honored (`notes/spec-digest-20261024T071323Z-ruby-4-0-9.md`
  + `notes/spec-digest-20261020T081608Z-parallel-test-runner.md`): gate-shell
  discipline (/bin/sh has NO `set -e` — every comparison gates its own
  exit; the ONE `set -e` in this battery is inside the re-anchored I51
  dep-pin gate, carried byte-verbatim per the I85 lock-deps precedent);
  never gates under nohup; extraction from the ARCH FILE; post-record
  re-extraction + YAML parse before rehearsing; the bundler self-checksum
  heal class anticipated in the lock legs; the `Gem.default_dir` lesson is
  NOT applicable (pure-ruby repo, no gem-home path probe in any gate —
  recorded so the next spec doesn't re-derive it).
- None of tart's declared flake classes apply (no rig, no tmux, no parallel
  runner, a ~2 s hermetic suite). ANY RED beyond the declared-RED pair is
  material.

## The frozen seams (cited)

- `repos/fast-llm/Gemfile`: `gemspec path: "gems/completions"` + dev gems
  rspec/rake. Untouched.
- `repos/fast-llm/gems/completions/fast-completions.gemspec`:
  `spec.required_ruby_version = ">= 3.3"` — a FLOOR, unchanged (plan
  ruling); `spec.add_dependency "async-http", "~> 0.95"` (the dep-pin
  gate's exact expectation). Untouched.
- `repos/fast-llm/Gemfile.lock`: `BUNDLED WITH 4.0.22`; never hand-edited —
  the only tolerated movement is the declared heal line.
- `repos/fast-llm/.rspec`: `-I gems/completions/lib`, `-I
  gems/completions/spec`, `--require spec_helper`, `--pattern
  gems/completions/spec/fast/**/*_spec.rb`. Untouched (the carried
  sub-gates' `-O /dev/null` forms bypass it deliberately, I63-era).
- `architecture/I63-strict-sampling-gem.md`: the carry source.
- `architecture/I85-ruby-4-0-9.md`: ENTRY 1's precedent (the pin-gate
  shape, the heal class, the rehearsal discipline).

## Deliberately excluded (plan rulings, do not build)

repos/tart (any change — ENTRY 1's repo, and nothing here moves tart's
bundle); any gemspec/Gemfile/lock edit (the floor stands; the lock's only
tolerated movement is the declared tooling-produced heal, never
hand-edited); any `gems/completions/lib/`, `spec/`, `docs/`, fixture, or
CHANGELOG change unless a genuine 4.0.9 behavioral difference forces it
(minimal, itemized, defended — a PHASE 0 event); a gem release or version
bump (the owner's); the owner's post-landing follow-ups (pushing the
fast-llm PR; whether loop tooling stops riding `latest`).

## Specification

# fast-llm-ruby-4-0-9 specification

## Objective

Make the wire gem's home ruby a committed fact and prove the gem's entire
settled surface on the new runtime: `.ruby-version` → `4.0.9` at the
fast-llm repo root, `bundle install` green under 4.0.9, and the gem's own
carried frozen battery green cold on 4.0.9 — the rspec suite (247 examples
measured at base), the wire-fixture digest table EXACT (the frozen pi
capture SHA256s inside wire_parity_spec.rb), the dep pins (async-http
~> 0.95, NO_FARADAY, NO_CATALOG). fast-completions is pure ruby and tart
consumes the published 0.5.0 gem, so nothing here moves tart's bundle —
this is dev-env truth for the monorepo, landing on `main`. The diff is one
line; **the gates are the deliverable**.

## Deliverable shape (frozen)

ONE lane `core`, repo fast-llm, ONE path:

- `.ruby-version` (NEW) — one line, exactly `4.0.9`. Nothing else.

## Law 1 — the pin file

`.ruby-version` at the repo root, content exactly `4.0.9` (one line, one
trailing newline — the gate pins content and line count). The gemspec
floor `spec.required_ruby_version = ">= 3.3"` is UNTOUCHED (a floor, not
the pin); `Gemfile` is UNTOUCHED; `Gemfile.lock` is never hand-edited —
its only tolerated movement is the DECLARED bundler self-checksum heal
class (the Grounds' measured single `+  bundler (…) sha256=…` CHECKSUMS
line, produced by `bundle install` itself at any pristine tree; the
ruby-pin and scope gates accept exactly it and reject anything else).

## Law 2 — the runtime + bundle verification

In the lane tree: `mise current ruby` and `ruby -v` resolve 4.0.9 (the
file-content leg is the discriminator — the runtime alone cannot
discriminate base-vs-lane, the Grounds' mise fact); `bundle install` green
under 4.0.9; the gem loads under THIS ruby (`require "fast/completions"`,
`VERSION == "0.5.0"`, `Fast::Completions::Client` defined — the frozen
ruby-pin gate's load smoke; pure ruby, no native-extension leg exists in
this repo).

## Law 3 — the carried battery, verbatim, cold

Run the frozen ```gates block VERBATIM (never hand-retype — the I58
lesson) at the lane tree under 4.0.9: the rspec suite (`bundle exec
rspec`, the canonical gate — measured base literal **247 examples, 0
failures**), `parity` (wire_parity_spec.rb — the frozen pi-capture digest
table, measured **14 examples**), the strict quintet (strict-wire 2,
strict-unit 21, strict-dialect 3, strict-tool 3, strict-emission 7 —
measured), `docs` (with the declared release-cut rebase), and the
re-anchored hygiene pins (`dep-pin`: runtime deps EXACTLY
`[["async-http", "~> 0.95"]]` + NO_FARADAY; `no-catalog`: NO_CATALOG).
A count or shape movement on the new runtime (e.g. the suite's 247/0F
literals, the digest table) is a genuine 4.0.9 behavioral difference:
itemize-and-defend, never silent. No declared flake classes exist for this
battery (a ~2 s hermetic suite, no rig/tmux/parallelism) — any RED beyond
the declared-RED pair is material.

## Law 4 — itemize-and-defend

The touch set is `.ruby-version` ONLY. Anything beyond it is a PHASE 0
event: a genuine 4.0.9 behavioral difference forcing a change is minimal,
itemized (old bytes → new bytes), and defended per the standing discipline
— a silent fix is a defect; a behavioral difference with no test
consequence is a recorded residual, not churn. The Builder Report carries
the full 12-gate table with a measured one-liner per gate (an absent gate
entry is REJECT-class) and the itemization of EVERY deviation (expected:
zero).

## Tool guidance (exact verification, this session's tested forms)

- Canonical gate anchor: `cd repos/fast-llm && bundle exec rspec` (measured
  at base under 4.0.9: `247 examples, 0 failures`, ~2.1 s).
- Pin legs: `cat .ruby-version` → `4.0.9`; `mise current ruby` → `4.0.9`;
  `ruby -v` → `ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM
  [arm64-darwin25]`.
- Gates: run verbatim from the frozen ```gates block; /bin/sh has NO
  `set -e` — every comparison gates its own exit; never run gates under
  nohup (the I85 lesson: SIGHUP→SIG_IGN inherits across exec and cascades
  false REDs); scratch goes under the repo's gitignored `tmp/` (declare
  `tmp/fl86*`) or root-level `fl86*` (the scope whitelist's only scratch
  family). **Scratch must NEVER contain the token `faraday`
  (case-insensitive)** — the re-anchored dep-pin gate greps the whole
  tree.
- provision: `architect provision fast-llm-ruby-4-0-9 --base 0c1949c`
  (re-verify `git -C repos/fast-llm log --oneline -1 main` == `0c1949c`
  immediately before dispatch). **Known provision class (the e724afe /
  I53/I61/I62 precedent):** fast-llm lanes materialize `integration_branch`
  NIL — the coordinator hand-sets it to **`main`** at provision; the lane
  lands on `main` (the owner's PR-landing pattern for this repo).

## Boundaries

- MAY touch: exactly `.ruby-version` (NEW) — nothing else.
- MUST NOT touch: `Gemfile`, `Gemfile.lock` (never hand-edited; the
  declared heal is tooling-produced and gate-sanctioned), `.rspec`,
  `gems/completions/**` (lib, spec, fixtures, docs, CHANGELOG, gemspec),
  `README.md`, `.github/**` — unless a genuine 4.0.9 behavioral difference
  forces it (Law 4: minimal, itemized, defended; a PHASE 0 event).
- repos/tart is entirely out of bounds.
- Builders never commit (`.ruby-version` lands untracked at the lane tree;
  integration commits it).
- No new gems, no version changes, no changes to the carried gate battery
  other than the declared docs rebase + the per-iteration scope rewrite
  (all frozen in the AC).

## Lane plan

ONE lane (repo fast-llm, the one-path touch set — no overlap possible).
Effort at dispatch: **medium** — the edit is one line, but the deliverable
is the battery: a full 12-gate cold run plus the itemize-and-defend
report.

```lanes
- name: core
  repo: fast-llm
  touch:
    - .ruby-version
```

## Acceptance Criteria

# fast-llm-ruby-4-0-9 acceptance criteria

Property-level, each independently judgeable. The frozen ```gates block
below (12 gates: 8 carried from the I63 ARCH FILE with ONE declared
release-cut rebase, 2 hygiene pins re-anchored byte-verbatim from the I51
ARCH FILE, 2 new — ruby-pin + the per-iteration scope rewrite) is the
runnable floor this iteration is judged against; the prose ACs name which
gate carries which property and what the Builder Report must evidence.
Calibration: floors from the defect's side only; exactness only where the
number is itself the deliverable (the `.ruby-version` content, the gemspec
floor line, the declared lock-heal shape).

## AC preamble — declared states and the measured base

- **Carried-block provenance.** Extracted from the ARCH FILE
  (`architecture/I63-strict-sampling-gem.md`, the frozen 9-gate block —
  never a digest): 8 carried (scope rewritten per-iteration). Declared
  rebase, the ONLY change to the carried 8: the `docs` gate's
  `grep -q "^## Unreleased" gems/completions/CHANGELOG.md` leg →
  `grep -q "^## 0\.4\.0" gems/completions/CHANGELOG.md` — the Unreleased
  premise expired when the owner cut 0.4.0/0.4.1/0.5.0 (the strict
  machinery shipped in 0.4.0; measured at base `0c1949c`: the I63 form
  REDs on exactly that leg, all four other legs GREEN, the rebased form
  GREEN standalone). Carry audit (`tmp/fllm409-spec/rebase.rb`):
  rebase-then-invert reproduces the extracted I63 block minus scope
  byte-identically — `CARRY_AUDIT_OK`. Re-anchored byte-verbatim from the
  I51 ARCH FILE: `dep-pin`, `no-catalog` (the entry's acceptance
  direction; dropped from the battery after I51, re-anchored here).
  Carried/re-anchored gates keep origin `ac:` labels verbatim.
- **Declared-RED at base `0c1949c`** (each verified STANDALONE this
  session for EXACTLY its declared reason): `ruby-pin` (the file is absent
  — exit 1, `FAIL ruby-pin: .ruby-version absent (declared-new)`) and
  `scope` (the `.ruby-version` must-exist leg — its tracked-diff and lock
  legs verified GREEN at base first, and the full gate GREEN in a
  lane-simulation with the pin file written and the lock healed).
- **GREEN-expected at base:** the other 10 — every one measured
  standalone this session at base under 4.0.9: `suite` 247 examples / 0
  failures; `parity` 14/0; `strict-wire` 2/0; `strict-unit` 21/0;
  `strict-dialect` 3/0; `strict-tool` 3/0; `strict-emission` 7/0; `docs`
  (post-rebase) STRICT_DOCS_OK; `dep-pin` DEP_PIN_OK + NO_FARADAY_OK;
  `no-catalog` NO_CATALOG_OK. The rehearsal measures the true vector.
- **The declared bundler self-checksum heal class** (the Grounds'
  measurement, the I85 discovery carried): bundler 4.0.22's
  `bundle install` at a pristine tree adds EXACTLY ONE line —
  `+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`
  — to the lock's CHECKSUMS. The `ruby-pin` and `scope` lock legs accept
  zero-diff OR exactly this shape and reject anything else; any other
  Gemfile.lock movement is itemize-and-defend PHASE 0. The lane NEVER
  hand-edits the lock.
- **Declared flake classes:** NONE for this battery (a ~2 s hermetic
  rspec suite; no rig, tmux, or parallelism — tart's classes do not
  carry). Any RED beyond the declared-RED pair is material.
- **Base-vs-lane ruby discrimination:** NOT available via the runtime
  (global mise latest resolves 4.0.9 everywhere — the plan header). The
  `.ruby-version` file CONTENT is the pin gate; the runtime legs prove
  the file drives the resolution.
- **MEASURED REHEARSAL (the stamp):** `architect rehearse fast-llm-ruby-4-0-9` at base `0c1949c` under ruby 4.0.9 — **GREEN 10 / RED 2 / BROKEN 0 / EMPTY 0** (transcript `build/rehearse/I86-fast-llm-ruby-4-0-9-20261024T035914.283883.md`): RED = `ruby-pin` + `scope`, the DECLARED-RED pair (absent `.ruby-version`, each RED for exactly its declared reason); GREEN incl. `suite` 247 examples / 0 failures and every other carried/re-anchored member. The gates block below is byte-identical to the stamped block (post-record re-extraction + YAML parse verifies).

## AC1 — the pin is a committed fact

`.ruby-version` exists at the repo root containing exactly `4.0.9` (one
line, one trailing newline); the gemspec floor
`spec.required_ruby_version = ">= 3.3"` is byte-untouched; `Gemfile`
byte-untouched; `Gemfile.lock` byte-unchanged OR carrying exactly the
declared bundler self-checksum heal line (anything else is
itemize-and-defend PHASE 0). Since the runtime cannot discriminate base
from lane (the preamble's mise fact), the file content itself is THE pin.
Carried by: `ruby-pin`, `scope`.

## AC2 — the runtime resolves and the bundle is live

`mise current ruby` and `ruby -v` in the lane tree resolve 4.0.9;
`bundle install` completes green under 4.0.9; the gem loads under THIS
ruby — `require "fast/completions"`, `Fast::Completions::VERSION ==
"0.5.0"`, `Fast::Completions::Client` defined (pure ruby; no
native-extension leg exists in this repo — that class is tart's, I85's
native-bundle gate). Carried by: `ruby-pin`.

## AC3 — the carried battery green cold on 4.0.9

The whole carried battery green cold at the lane tree under 4.0.9: the
rspec suite (`bundle exec rspec` — the canonical gate; measured base
literal **247 examples, 0 failures**), `parity` (wire_parity_spec.rb —
the frozen pi-capture digest table EXACT: the 13-fixture shape/path/
SHA256 pin lives inside the spec, wire_parity_spec.rb :76/:269-281;
measured 14 examples), the strict quintet (strict-wire 2, strict-unit 21,
strict-dialect 3, strict-tool 3, strict-emission 7 — the measured
literals), `docs` (post-rebase). The runs/failures literals are expected
UNCHANGED from these measured values — a count or shape movement is a
genuine 4.0.9 behavioral difference: itemize-and-defend, never silent.
Carried by: `suite`, `parity`, `strict-wire`, `strict-unit`,
`strict-dialect`, `strict-tool`, `strict-emission`, `docs`.

## AC4 — the dep pins and hygiene floor

The gemspec's runtime dependencies are EXACTLY
`[["async-http", "~> 0.95"]]`; NO faraday token anywhere in the tree
(NO_FARADAY); NO catalog/pricing/model-id/base-url constants in
`gems/completions/lib/` (NO_CATALOG). Carried by: `dep-pin`, `no-catalog`
(re-anchored byte-verbatim from the I51 ARCH FILE).

## AC5 — scope: the frozen one-path touch set, nothing else

Exactly `.ruby-version` NEW; ZERO tracked diff vs `0c1949c` beyond the
declared Gemfile.lock heal class; the untracked set confined to
`.ruby-version` + the declared `fl86*` scratch family (repo-gitignored
tmp/ etc. never appear). Any change forced by a genuine 4.0.9 behavioral
difference is minimal, itemized, and defended (expected: ZERO — a silent
fix is a defect; a behavioral difference with no test consequence is a
recorded residual, not churn). The Builder Report itemizes every frozen
gate (12/12 — an absent entry is REJECT-class) and every deviation.
Carried by: `scope` (+ `ruby-pin`'s floor/lock legs; the carried battery
as the behavioral backstop).

```gates
- id: suite
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: parity
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-wire
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb -e "zai_strict" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-unit
  ac: AC3
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/constrained_sampling_spec.rb 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-dialect
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/dialects_spec.rb -e "supports_strict_mode" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-tool
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/tool_spec.rb -e "constrained" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: strict-emission
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/protocol_spec.rb -e "strict" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: docs
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    grep -q "supports_strict_mode" gems/completions/docs/reference/dialects.md && grep -q "constrained_sampling" gems/completions/docs/reference/tools.md && grep -q "ConstrainedSamplingError" gems/completions/docs/reference/errors.md && grep -q "^## 0\.4\.0" gems/completions/CHANGELOG.md && grep -qi "constrained" gems/completions/CHANGELOG.md && echo STRICT_DOCS_OK
  expect:
    exit_code: 0
    stdout_match: STRICT_DOCS_OK

- id: dep-pin
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    set -e
    ruby -e '
      spec = Gem::Specification.load("gems/completions/fast-completions.gemspec")
      abort "gemspec failed to load" unless spec
      deps = spec.runtime_dependencies.map { |d| [d.name, d.requirement.to_s] }
      abort "runtime deps must be exactly [async-http ~> 0.95], got #{deps.inspect}" unless deps == [["async-http", "~> 0.95"]]
      puts "DEP_PIN_OK"
    '
    if grep -ri faraday --exclude-dir=.git . | grep -q .; then echo "FARADAY PRESENT"; grep -ri faraday --exclude-dir=.git . | head -5; exit 1; fi
    echo NO_FARADAY_OK
  expect:
    exit_code: 0
    stdout_match: NO_FARADAY_OK

- id: no-catalog
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    if grep -rniE 'models\.json|pricing|price_per_million|per_million_tokens' gems/completions/lib/ | grep -q .; then
      echo "CATALOG/PRICING TOKEN PRESENT"; grep -rniE 'models\.json|pricing|price_per_million|per_million_tokens' gems/completions/lib/; exit 1
    fi
    if grep -rEn '"(glm|gpt|claude|kimi|grok|gemini|o[13]-|dsr|deepseek-chat|llama)[-_][a-z0-9]' gems/completions/lib/ | grep -q .; then
      echo "MODEL-ID LITERAL PRESENT"; grep -rEn '"(glm|gpt|claude|kimi|grok|gemini|o[13]-|dsr|deepseek-chat|llama)[-_][a-z0-9]' gems/completions/lib/; exit 1
    fi
    if grep -rnE 'https?://[a-z0-9.-]+\.(ai|com|cn)/' gems/completions/lib/ | grep -q .; then
      echo "PROVIDER BASE-URL CONSTANT PRESENT"; exit 1
    fi
    echo NO_CATALOG_OK
  expect:
    exit_code: 0
    stdout_match: NO_CATALOG_OK

- id: ruby-pin
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    # The pin is a committed FILE fact. Base-vs-lane ruby-version
    # discrimination is NOT available via the runtime alone (global mise
    # `latest` already resolves 4.0.9 — the plan header), so the
    # .ruby-version CONTENT is the discriminating leg; the runtime legs
    # prove the file actually drives the resolution. Declared-RED at base:
    # the file is absent (declared-new). (I85 tart gate shape, re-anchored:
    # gemspec path + diff base 0c1949c.)
    [ -f .ruby-version ] || { echo "FAIL ruby-pin: .ruby-version absent (declared-new)"; exit 1; }
    content=$(cat .ruby-version)
    [ "$content" = "4.0.9" ] || { echo "FAIL ruby-pin: content '$content', want exactly 4.0.9"; exit 1; }
    lines=$(wc -l < .ruby-version | tr -d " ")
    [ "$lines" = "1" ] || { echo "FAIL ruby-pin: $lines lines, want exactly one"; exit 1; }
    cur=$(mise current ruby 2>/dev/null || echo unavailable)
    [ "$cur" = "4.0.9" ] || { echo "FAIL ruby-pin: mise current ruby = '$cur', want 4.0.9"; exit 1; }
    case "$(ruby -v)" in "ruby 4.0.9 "*) ;; *) echo "FAIL ruby-pin: ruby -v = $(ruby -v)"; exit 1;; esac
    grep -qF 'spec.required_ruby_version = ">= 3.3"' gems/completions/fast-completions.gemspec || { echo "FAIL ruby-pin: the >= 3.3 gemspec floor moved (ruled a FLOOR, unchanged)"; exit 1; }
    git diff --quiet 0c1949c -- Gemfile gems/completions/fast-completions.gemspec || { echo "FAIL ruby-pin: Gemfile/gemspec touched"; exit 1; }
    # bundle install must be green under 4.0.9 (AC2's install leg). Side
    # effect at any pristine tree: bundler 4.0.22 self-heals its own
    # CHECKSUMS line into the lock (the DECLARED class below).
    bundle install --quiet || { echo "FAIL ruby-pin: bundle install not green under 4.0.9"; exit 1; }
    # The gem's own load smoke (pure ruby — no native-extension leg
    # needed; tart carries that class, not this repo).
    bundle exec ruby -e 'require "fast/completions"; abort "VERSION moved" unless Fast::Completions::VERSION == "0.5.0"; abort "Client missing" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"' || { echo "FAIL ruby-pin: gem load smoke"; exit 1; }
    # Gemfile.lock: byte-unchanged OR exactly the DECLARED bundler
    # self-checksum heal (measured at spec time, this session: bundler
    # 4.0.22's `bundle install` adds its own CHECKSUMS line — `bundler
    # (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d6
    # 1979242a5d75a` — deterministically, under the new runtime; the
    # battery's own bundle-install legs produce it at any pristine tree).
    # Any other lock movement is itemize-and-defend PHASE 0.
    badlock=$(git diff 0c1949c -- Gemfile.lock | grep -E "^[-+][^-+]" | grep -vE "^\+  bundler \([0-9.]+\) sha256=[0-9a-f]{64}$" || true)
    [ -z "$badlock" ] || { echo "FAIL ruby-pin: Gemfile.lock moved beyond the declared bundler self-checksum class:"; echo "$badlock"; exit 1; }
    echo RUBY_PIN_OK
  expect:
    exit_code: 0
    stdout_match: RUBY_PIN_OK

- id: scope
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    # fast-llm-ruby-4-0-9 frozen ONE-path touch set: `.ruby-version` NEW at
    # the repo root (untracked at the lane tree — builders never commit; the
    # content pin lives in ruby-pin). HARD-FROZEN with zero TRACKED diff vs
    # 0c1949c: the whole tree — Gemfile, gems/, spec fixtures, docs — a
    # ruby-only bump moves nothing tracked; ANY tracked diff is a PHASE 0
    # event (a genuine 4.0.9 behavioral difference forcing a change is
    # minimal, itemized, defended — never silent). Gemfile.lock carries ONE
    # declared exception: the bundler self-checksum heal class (the ruby-pin
    # comment; a single `+  bundler (...) sha256=...` CHECKSUMS line,
    # nothing else). Untracked-scratch filter: .ruby-version itself plus the
    # declared fl86* family (tmp/, pkg/, coverage/, *.gem, .bundle/ are
    # gitignored in this repo and never appear in git status).
    if ! git diff --quiet 0c1949c -- . ":(exclude)Gemfile.lock"; then echo "FAIL scope: tracked diff vs 0c1949c beyond the declared Gemfile.lock class — the touch set is .ruby-version only"; git diff --name-only 0c1949c; exit 1; fi
    badlock=$(git diff 0c1949c -- Gemfile.lock | grep -E "^[-+][^-+]" | grep -vE "^\+  bundler \([0-9.]+\) sha256=[0-9a-f]{64}$" || true)
    [ -z "$badlock" ] || { echo "FAIL scope: Gemfile.lock moved beyond the declared bundler self-checksum class:"; echo "$badlock"; exit 1; }
    [ -f .ruby-version ] || { echo "FAIL scope: .ruby-version absent (declared-new)"; exit 1; }
    if (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(\.ruby-version|fl86[0-9a-zA-Z.]*/?)$" | grep -q .; then
      echo "FAIL scope: out-of-bounds untracked paths:"; (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(\.ruby-version|fl86[0-9a-zA-Z.]*/?)$"; exit 1
    fi
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Builder Prompt — fast-llm-ruby-4-0-9, lane `core` (repo fast-llm)

RUBY-PIN PROGRAM ENTRY 2. The full contract is the frozen arch file
`architecture/I86-fast-llm-ruby-4-0-9.md` (Grounds / Specification /
Acceptance Criteria + the 12-gate frozen ```gates block). This prompt is
the operational summary — the arch file governs on any conflict.

## The task

Make fast-llm's ruby a committed repo fact and prove the gem's settled
surface on it:

1. Write `.ruby-version` at the lane-tree repo root: exactly `4.0.9`, one
   line, one trailing newline. NOTHING else is in the touch set.
2. `bundle install` under 4.0.9 (green; ~5 s measured at base). EXPECTED
   SIDE EFFECT, declared and gate-sanctioned: bundler 4.0.22 self-heals
   its own CHECKSUMS line into Gemfile.lock — EXACTLY
   `+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`
   (measured at spec time). NEVER hand-edit the lock; any other lock
   movement is a PHASE 0 itemize-and-defend event.
3. Run the frozen 12-gate battery VERBATIM from the arch file's ```gates
   block (never hand-retype — the I58 lesson) at the lane tree and record
   every result.

## Declared base states (measured at spec time, base `0c1949c`, ruby 4.0.9)

- Declared-RED at base (by construction — the file is absent):
  `ruby-pin`, `scope`. At YOUR lane tree they must be GREEN.
- GREEN-expected at base (all measured standalone at spec time):
  `suite` 247 examples / 0 failures; `parity` 14/0; `strict-wire` 2/0;
  `strict-unit` 21/0; `strict-dialect` 3/0; `strict-tool` 3/0;
  `strict-emission` 7/0; `docs` STRICT_DOCS_OK; `dep-pin` DEP_PIN_OK +
  NO_FARADAY_OK; `no-catalog` NO_CATALOG_OK.
- NO declared flake classes exist for this battery. Any RED at the lane
  tree is material: if it is a genuine 4.0.9 behavioral difference, STOP
  on that gate, itemize (old bytes → new bytes) and defend — never fix
  silently. Expected deviations: ZERO.

## Hard rules

- Builders NEVER commit. `.ruby-version` lands untracked; the integrator
  commits it.
- Touch set: `.ruby-version` ONLY. MUST NOT touch Gemfile, Gemfile.lock
  (hand), .rspec, gems/completions/** (lib/spec/fixtures/docs/CHANGELOG/
  gemspec), README.md, .github/**. repos/tart is entirely out of bounds.
- Gates: /bin/sh has NO `set -e` — every comparison gates its own exit;
  NEVER run gates under nohup (SIGHUP→SIG_IGN inherits across exec and
  cascades false REDs — the I85 lesson); scratch under the repo's
  gitignored `tmp/` (`tmp/fl86*`) or root-level `fl86*` only; scratch must
  NEVER contain the token `faraday` (case-insensitive — the dep-pin gate
  greps the whole tree).
- Base-vs-lane ruby discrimination is NOT available via the runtime
  (global mise latest resolves 4.0.9 everywhere). The `.ruby-version`
  file CONTENT is the pin gate.

## Verification commands (exact, tested at spec time)

- Canonical gate: `bundle exec rspec` → expect `247 examples, 0 failures`.
- Pin legs: `cat .ruby-version` → `4.0.9`; `mise current ruby` → `4.0.9`;
  `ruby -v` → `ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM
  [arm64-darwin25]`.
- Load smoke: `bundle exec ruby -e 'require "fast/completions"; abort
  unless Fast::Completions::VERSION == "0.5.0" &&
  defined?(Fast::Completions::Client)'`.
- Full battery: run each gate's `cmd` verbatim from the frozen block in
  the lane tree root context (each gate carries `cwd: repos/fast-llm` —
  at the lane tree that is the worktree root).

## Builder Report shape

Report raw results only: the one-file diff confirmation (`.ruby-version`
bytes); the bundle-install outcome and the EXACT lock movement (expected:
the one declared heal line or zero); the full 12-gate table with a
measured one-liner per gate (an absent gate entry is REJECT-class) —
suite literal counts included; and the itemize-and-defend table for EVERY
deviation from the frozen touch set or expected literals (expected: zero).

## Builder Report

### core

# Builder Report — fast-llm-ruby-4-0-9, lane `core` (repo fast-llm)

Lane tree: `build/I86-fast-llm-ruby-4-0-9-core/wt` @ `0c1949c7b53c1c771ebfb6cefba4f8882ae4036a`
(branch `lane/I86-fast-llm-ruby-4-0-9-core`). Builders never commit — HEAD unchanged at
exit; the full diff is left uncommitted for the integrator.

## 1. The pin file (one-file diff confirmation)

`.ruby-version` (NEW, untracked) at the lane-tree repo root:

- `xxd .ruby-version` → `00000000: 342e 302e 390a                           4.0.9.`
- bytes: 6 = `34 2e 30 2e 39 0a` — exactly `4.0.9` plus one trailing newline
- `wc -l .ruby-version` → `1`
- `cat .ruby-version` → `4.0.9`

## 2. bundle install under 4.0.9 + EXACT lock movement

- runtime legs: `mise current ruby` → `4.0.9`; `ruby -v` → `ruby 4.0.9 (2026-10-23
  revision 3e93b23afc) +PRISM [arm64-darwin25]`; bundler `4.0.22`
- pre-install `git diff 0c1949c --stat` → empty (tree pristine)
- `bundle install --quiet` → exit 0, `real 0m0.187s` (gems warm; the ~5 s base figure
  was cold)
- EXACT lock movement — `git diff 0c1949c -- Gemfile.lock`, verbatim:

```
diff --git c/Gemfile.lock w/Gemfile.lock
index 9f5429b..6385589 100644
--- c/Gemfile.lock
+++ w/Gemfile.lock
@@ -74,6 +74,7 @@ CHECKSUMS
   async (2.46.0) sha256=34f984733dbf63a997376346451ec995e858cacc3105e86ccfeaf8877b4f490b
   async-http (0.105.0) sha256=55191969d5cf61be5fbc2e0aadd51d77085318ba192a5ff5e12e3aba0826906a
   async-pool (0.12.0) sha256=5580493dc024bd704dab2ed0bf1307100722e49cbb825c7965f8501194f58506
+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a
   console (1.38.0) sha256=35b82f59130e95e9be6b832d9e539c8b3988fc192e4a8e9a86ab4922f44ad5de
   diff-lcs (1.6.2) sha256=9ae0d2cba7d4df3075fe8cd8602a8604993efc0dfa934cff568969efb1909962
   fast-completions (0.5.0)
```

- `git diff 0c1949c --stat` → `Gemfile.lock | 1 +` — `1 file changed, 1 insertion(+)`.
  The inserted line is byte-identical to the declared heal literal (bundler 4.0.22,
  sha256 `d8d5ec…5d75a`), in sorted position between async-pool and console. No other
  movement. Lock never hand-edited.
- Load smoke, prompt form: `bundle exec ruby -e 'require "fast/completions"; abort
  unless Fast::Completions::VERSION == "0.5.0" && defined?(Fast::Completions::Client)'`
  → exit 0. Gate form (inside ruby-pin) printed `GEM_LOAD_OK`.

## 3. The frozen 12-gate battery — run VERBATIM from the arch-file ```gates block

Method: gates block extracted from
`architecture/I86-fast-llm-ruby-4-0-9.md` by awk fence-scan, YAML-parsed (12 gates,
ids verified), each gate's `cmd` executed via `/bin/sh -c` with cwd = lane tree root
(the `repos/fast-llm` mapping), foreground, no nohup; exit code + stdout captured;
frozen `expect` (exit_code 0 + stdout_match) evaluated per gate. Never hand-retyped.

| # | gate            | exit (want) | stdout_match (want) | measured stdout              | verdict |
|---|-----------------|-------------|---------------------|------------------------------|---------|
| 1 | suite           | 0 (0)       | "0 failures" HIT    | `247 examples, 0 failures`   | GREEN   |
| 2 | parity          | 0 (0)       | "0 failures" HIT    | `14 examples, 0 failures`    | GREEN   |
| 3 | strict-wire     | 0 (0)       | "0 failures" HIT    | `2 examples, 0 failures`     | GREEN   |
| 4 | strict-unit     | 0 (0)       | "0 failures" HIT    | `21 examples, 0 failures`    | GREEN   |
| 5 | strict-dialect  | 0 (0)       | "0 failures" HIT    | `3 examples, 0 failures`     | GREEN   |
| 6 | strict-tool     | 0 (0)       | "0 failures" HIT    | `3 examples, 0 failures`     | GREEN   |
| 7 | strict-emission | 0 (0)       | "0 failures" HIT    | `7 examples, 0 failures`     | GREEN   |
| 8 | docs            | 0 (0)       | STRICT_DOCS_OK HIT  | `STRICT_DOCS_OK`             | GREEN   |
| 9 | dep-pin         | 0 (0)       | NO_FARADAY_OK HIT   | `DEP_PIN_OK` + `NO_FARADAY_OK` | GREEN |
| 10| no-catalog      | 0 (0)       | NO_CATALOG_OK HIT   | `NO_CATALOG_OK`              | GREEN   |
| 11| ruby-pin        | 0 (0)       | RUBY_PIN_OK HIT     | `GEM_LOAD_OK` + `RUBY_PIN_OK` | GREEN  |
| 12| scope           | 0 (0)       | SCOPE_OK HIT        | `SCOPE_OK`                   | GREEN   |

TOTAL: 12 GREEN / 0 RED / 0 BROKEN / 0 EMPTY. Every runs/failures literal equals the
measured base value (suite 247/0; parity 14/0; strict quintet 2/21/3/3/7 — all with
0 failures). stderr empty on all 12 gates.

## 4. Itemize-and-defend — deviations from the frozen touch set / expected literals

| # | deviation | old bytes → new bytes | defense |
|---|-----------|-----------------------|---------|
| — | NONE      | —                     | —       |

Zero deviations. Final `git status --porcelain` (verbatim):

```
 M Gemfile.lock
?? .ruby-version
```

Tracked diff vs `0c1949c` confined to Gemfile.lock's single declared heal line;
untracked set confined to `.ruby-version`; HEAD `0c1949c` (no commits, nothing staged).

## 5. PHASE 0 notes (recorded observations — no spec change requested)

- Carry audit re-performed at execution time (not trusted from prose): the I86 gates
  block, the I63 block (`architecture/I63-strict-sampling-gem.md:511`), and the I51
  block (`architecture/I51-fast-completions-gem.md:1208`) were extracted and
  YAML-parsed. Result: 7 carried gates byte-identical I63→I86; `docs` differs on
  exactly the one declared leg (`grep -q "^## Unreleased" …` → `grep -q "^## 0\.4\.0" …`);
  `dep-pin` + `no-catalog` byte-identical I51→I86 (including dep-pin's `set -e`).
- Carried gates' `ac:` labels are the verbatim I63 origin labels (declared house
  convention; the prose ACs name the gate→AC mapping).
- Scratch location note: the gates-block extraction and runner live in the lane build
  dir `build/I86-fast-llm-ruby-4-0-9-core/scratch/`, OUTSIDE the repo tree, because the
  verbatim dep-pin gate cmd text itself contains the token that gate greps the whole
  tree for — and plain `grep -r` ignores .gitignore, so even gitignored `tmp/fl86*`
  scratch holding the extraction would trip dep-pin. An initial extraction briefly
  placed under `wt/tmp/fl86/` was relocated before any gate ran and `wt/tmp` removed;
  the tree was swept post-run (`grep -ril <token> --exclude-dir=.git .`) → zero hits.
  No `tmp/` or `fl86*` paths remain in the repo tree.
- bundle install ran warm (0.19 s vs the ~5 s cold base figure) — same exit-0 outcome;
  heal line identical.

STATUS: COMPLETE

## Verdict

## Mechanical post-flight (this session, by command)

- `architect verify fast-llm-ruby-4-0-9`: (a) frozen sections untouched
  **PASS** (`git diff 4ade92f3 HEAD -- architecture/I86-fast-llm-ruby-4-0-9.md`
  shows only the post-freeze Builder Prompt append (df42eda0) and the
  Builder Report transcription — Grounds/Specification/Acceptance Criteria
  byte-frozen); (b) no builder commits **PASS** (`git -C
  build/I86-fast-llm-ruby-4-0-9-core/wt log 0c1949c..HEAD` empty — lanes
  committed nothing, confirmed); (c) report exists **PASS**; (d) in-bounds
  **FAIL** — adjudicated below (the I85 expressiveness gap, same class,
  same ruling; not a lane defect).
- `architect evidence fast-llm-ruby-4-0-9 --lane core`: transcribed 112
  lines (e5a29363). Builder STATUS: COMPLETE.

## The in-bounds FAIL, adjudicated

The lane worktree holds exactly two changes vs base `0c1949c`
(judge-verified, `git status --porcelain` + `git diff 0c1949c`):

1. **`.ruby-version` NEW, untracked, bytes exactly `4.0.9\n`** — THE
   deliverable, verified by my own `xxd` (`342e 302e 390a`, 6 bytes, one
   line). In the frozen touch set.
2. **`Gemfile.lock` +1 line** — I reproduced the diff myself: exactly one
   added CHECKSUMS line, `+  bundler (4.0.22)
   sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`,
   byte-identical to the frozen Grounds' measured heal literal, in sorted
   position between async-pool and console; `--stat` = `1 file changed, 1
   insertion(+)`, nothing else moved. Frozen AC1 explicitly sanctions it
   ("byte-unchanged OR carrying exactly the declared bundler self-checksum
   heal line"); the frozen `ruby-pin`/`scope` lock legs accept exactly
   this shape. Tooling-produced by `bundle install`, never hand-edited.
   The frozen ```lanes touch set (`.ruby-version` only) cannot express the
   AC-sanctioned lock heal — the touch-set/AC expressiveness gap ruled on
   in I85, not a lane violation. No scratch residue this time (no `fl86*`,
   no `tmp/` in the repo tree — judge-verified).

## The judge's own cold battery

`architect gate fast-llm-ruby-4-0-9 core` run COLD by this judge
(transcript `build/gate/I86-fast-llm-ruby-4-0-9-20261024T041158.075205.md`):
**12 PASS / 0 FAIL / 12 total** — independently reproducing the builder's
claimed vector (12 GREEN / 0 RED). Every runs/failures literal equals the
stamped base measurement, judge-observed: suite **247 examples, 0
failures**; parity **14/0**; strict-wire **2/0**; strict-unit **21/0**;
strict-dialect **3/0**; strict-tool **3/0**; strict-emission **7/0**; docs
`STRICT_DOCS_OK`; dep-pin `DEP_PIN_OK` + `NO_FARADAY_OK`; no-catalog
`NO_CATALOG_OK`; ruby-pin `GEM_LOAD_OK` + `RUBY_PIN_OK`; scope `SCOPE_OK`.
Zero behavioral movement on 4.0.9. Judge's own independent faraday sweep
of the lane tree (`grep -ril faraday --exclude-dir=.git .`): zero hits.

## PHASE 0 rulings

The builder raised **zero** spec disagreements (itemize-and-defend table
EMPTY; STATUS COMPLETE, no concerns). Its three recorded §5 observations
ruled here:

- **The Gemfile.lock heal itemization — ACCEPT.** Exactly the declared,
  shape-pinned, tooling-produced line; verified byte-for-byte by this
  judge; gate-sanctioned by the frozen `ruby-pin`/`scope` lock legs.
- **The scratch relocation out of the repo tree — ACCEPT** as correct
  contract reading, not a deviation: the Builder Prompt itself bars the
  `faraday` token in scratch, the verbatim dep-pin gate greps the whole
  tree ignoring .gitignore, so holding the gates-block extraction inside
  the repo (even gitignored `tmp/fl86*`) would have tripped dep-pin. The
  builder relocated before any gate ran and swept post-run; judge-verified
  zero residue, zero faraday hits. No spec change requested, none needed —
  recorded so the next spec's scratch guidance can name the interplay.
- **The execution-time carry-audit re-performance — ACCEPT** (house
  discipline: never trust provenance from prose; the builder's measured
  result matches the frozen preamble's: 7 carried gates byte-identical
  I63→I86, docs differing on exactly the one declared rebase leg, dep-pin
  + no-catalog byte-identical I51→I86).

## Per-AC rollup

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | `.ruby-version` bytes exact (`4.0.9\n`, judge xxd); gemspec floor `>= 3.3` byte-untouched; Gemfile byte-untouched; lock carries exactly the sanctioned heal line (judge-reproduced diff) | Law 1 | **PASS** |
| AC2 | `mise current ruby` → 4.0.9, `ruby -v` → the stamped 4.0.9 string; `bundle install` green; `GEM_LOAD_OK` (VERSION 0.5.0, Client defined) — all cold in the judge's own ruby-pin run | Law 2 | **PASS** |
| AC3 | Judge's cold battery 12/12; suite 247/0, parity 14/0, quintet 2/21/3/3/7 all 0F — every literal exactly the stamped base value; docs STRICT_DOCS_OK | Law 3 | **PASS** |
| AC4 | `DEP_PIN_OK` (runtime deps EXACTLY `[["async-http", "~> 0.95"]]`) + `NO_FARADAY_OK` + `NO_CATALOG_OK`, cold; judge's independent faraday sweep zero hits | Law 3/AC4 | **PASS** |
| AC5 | Zero tracked diff beyond the declared heal (judge-verified); untracked set confined to `.ruby-version`; 12/12 gate entries in the Builder Report, zero absent; itemize-and-defend EMPTY | Law 4 | **PASS** |

## Iteration

**CONTINUE** — diff vs the frozen Specification faithful: one-file touch
set delivered byte-exact, the only lock movement is the declared
tooling-produced heal class (judge-reproduced), the full 12-gate battery
GREEN in the judge's own cold run with every measured literal equal to the
stamped base values, zero behavioral movement on ruby 4.0.9, zero
deviations, builders committed nothing.

## Residual risks (carried forward, not blocking)

1. The bundler self-checksum heal class will fire again at every pristine
   fast-llm checkout on bundler 4.0.22 (by design; the lock legs pin its
   shape). After this lands on `main` the heal is committed, so the class
   goes quiet for this repo.
2. The verify in-bounds mechanical check still cannot express the
   AC-sanctioned lock heal (the I85 expressiveness gap; twice now, same
   class). Candidate tooling note, not an iteration defect.
3. Scratch discipline interplay (dep-pin greps the whole tree, ignoring
   .gitignore): gate-block extractions must live OUTSIDE the repo tree.
   Recorded for the next spec; handled correctly here.
