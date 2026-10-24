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
`architect rehearse fast-llm-ruby-4-0-9` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze fast-llm-ruby-4-0-9` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse fast-llm-ruby-4-0-9` — before the freeze, while
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
