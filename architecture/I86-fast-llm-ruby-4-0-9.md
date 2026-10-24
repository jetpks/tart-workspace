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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I86-fast-llm-ruby-4-0-9-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section fast-llm-ruby-4-0-9 prompt --append --lane <lane> --from build/I86-fast-llm-ruby-4-0-9-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I86-fast-llm-ruby-4-0-9-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence fast-llm-ruby-4-0-9 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section fast-llm-ruby-4-0-9 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify fast-llm-ruby-4-0-9`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
