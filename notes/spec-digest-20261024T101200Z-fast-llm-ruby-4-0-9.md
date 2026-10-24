# Spec digest — fast-llm-ruby-4-0-9 (I86; fast-llm ruby pin + re-verification)

UTC 2026-10-24T10:1xZ. Spec COMPLETE and FROZEN. RUBY-PIN PROGRAM ENTRY 2
(ENTRY 1 = I85 ruby-4-0-9, tart, DONE — CONTINUE 5/5, merge `40ed92b`).

## State (verified this session)

- Space repo HEAD `16f3c07` (I86: record freeze sha). Commits this spec:
  `84115c0` grounds → `c4db5ae` specification → `bc90865` AC →
  `e53d56a` AC FIX (the `\+` repair, below) → `4ade92f` AC rehearsal
  stamp → `16f3c07` freeze record.
- space.yaml I86 record: freeze_sha
  `4ade92f3e3607bcc99ab088b5cb1021d1917a47d`, verdict pending, ONE lane
  `core` repo fast-llm touch_set [`.ruby-version`], rehearsal stamp
  gates_digest `8c05ed6d…` at 2026-10-24T03:59:14-06:00.
- Arch file `architecture/I86-fast-llm-ruby-4-0-9.md`: Grounds /
  Specification / AC + 12-gate frozen ```gates block (8 carried from the
  I63 ARCH FILE with ONE declared rebase + 2 re-anchored byte-verbatim
  from the I51 ARCH FILE + 2 new: `ruby-pin`, `scope`).
- Scratch: `tmp/fllm409-spec/` — grounds.md, specification.md,
  acceptance-criteria.md (the record source), gates-i63-arch-raw.yaml,
  gates-carried-raw.yaml, rebase.rb, gates-carried-rebased.yaml,
  gates-i51-reanchor.yaml, gates-new.yaml, gates-final.yaml (the stamped
  bytes), prompt-core.md (the lane Builder Prompt).
- `repos/fast-llm` @ `0c1949c` on main: tracked tree CLEAN, `origin/main`
  == `0c1949c` (no tart-class squashed-PR divergence; main is the owner's
  PR-landing branch here). The probe worktree (`tmp/fllm-probe`) was
  removed after measurements.

## The rehearsal vector (the fresh stamp)

**GREEN 10 / RED 2 / BROKEN 0 / EMPTY 0** at base `0c1949c` under ruby
4.0.9 (transcript
`build/rehearse/I86-fast-llm-ruby-4-0-9-20261024T035914.283883.md`):
RED = `ruby-pin` + `scope` — the DECLARED-RED pair (absent
`.ruby-version`, each RED for exactly its declared reason; both verified
standalone pre-rehearsal, and GREEN in a lane-simulation with the pin
written + lock healed). GREEN incl. `suite` 247 examples / 0 failures.
The harness's discrimination sim printed "no path operand / unsupported
flag(s): v" notes for grep pipelines (sim-stub limits, I84-digest class)
— the real runs resolved cleanly; zero BROKEN/EMPTY.

## The 12-gate battery (the frozen floor)

Carried from `architecture/I63-strict-sampling-gem.md` (THE ARCH FILE —
the last fast-llm-repo iteration; I64 is the tart consumer half with zero
fast-llm-cwd gates): `suite`, `parity`, `strict-wire`, `strict-unit`,
`strict-dialect`, `strict-tool`, `strict-emission`, `docs` — ONE declared
rebase: docs's `^## Unreleased` CHANGELOG leg → `^## 0\.4\.0` (the
strict machinery shipped in 0.4.0; the Unreleased premise expired with
the owner's 0.4.0/0.4.1/0.5.0 cuts; measured: I63 form REDs on exactly
that leg at base, rebased form GREEN). Carry audit
`tmp/fllm409-spec/rebase.rb`: rebase-then-invert byte-identical,
`CARRY_AUDIT_OK`. Re-anchored byte-verbatim from
`architecture/I51-fast-completions-gem.md`: `dep-pin` (deps EXACTLY
`[["async-http", "~> 0.95"]]` + NO_FARADAY whole-tree grep), `no-catalog`.
New: `ruby-pin` (file content `4.0.9` one-line + mise/ruby -v legs +
gemspec-floor + Gemfile/gemspec-untouched + bundle-install-green +
gem-load-smoke VERSION==0.5.0 + lock-heal-class legs), `scope` (zero
tracked diff vs `0c1949c` beyond the declared heal; untracked confined to
`.ruby-version` + `fl86*`).

## Measured facts the next spec must honor

- Suite literal at base under 4.0.9: **247 examples, 0 failures, ~2.1 s**.
  Sub-gates: parity 14, strict-wire 2, strict-unit 21, strict-dialect 3,
  strict-tool 3, strict-emission 7. The wire-fixture digest table
  (FROZEN_DIGESTS, 13 pi-capture SHA256s) lives INSIDE
  `gems/completions/spec/fast/completions/wire_parity_spec.rb`
  (:76/:269-281) — the `parity` gate carries it.
- **The bundler self-checksum heal class fires on fast-llm too**:
  `bundle install` at the pristine base adds EXACTLY
  `+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`
  (sorted between async-pool and console; byte-identical to I85's tart
  heal). `bundle exec` alone does NOT heal (measured). The ruby-pin/scope
  lock legs accept zero-diff OR exactly this shape.
- Base-vs-lane ruby discrimination is NOT available via the runtime
  (global mise latest == 4.0.9); the `.ruby-version` CONTENT is the pin.
- fast-llm `.gitignore` covers tmp/, pkg/, coverage/, *.gem, .bundle/ —
  git status only ever shows root-level scratch; the scope whitelist is
  `.ruby-version` + `fl86*`.

## Verification commands actually used (exact, tested)

- Rehearse: `architect rehearse fast-llm-ruby-4-0-9 --color never` —
  foreground, NEVER nohup (~2 min wall; the suite is 2 s).
- Freeze: `architect freeze fast-llm-ruby-4-0-9 --color never`.
- Post-record gate-block verification:
  `sed -n '/^```gates$/,/^```$/p' architecture/I86-fast-llm-ruby-4-0-9.md | sed '1d;$d' | diff - tmp/fllm409-spec/gates-final.yaml` + YAML parse
  (held, twice).
- Carry audit: `ruby tmp/fllm409-spec/rebase.rb` → `CARRY_AUDIT_OK`.
- Standalone gate probes: extract a gate's `cmd` via ruby+YAML from
  gates-final.yaml into /tmp/gate-<id>.sh, `sh /tmp/gate-<id>.sh` in a
  base worktree (`git worktree add tmp/fllm-probe 0c1949c` — REMOVED
  after use; the canonical checkout was never dirtied by measurements).

## House conventions the next spec must honor

- **Ruby `String#sub` with a string replacement EATS backslash escapes**
  (`\+` → `+`): injecting gate YAML into markdown with
  `ac.sub(placeholder, gates)` corrupted the `grep -vE "^\+  bundler…"`
  lock legs. Use the BLOCK form `sub(placeholder) { gates }`. Caught by
  the post-record re-extraction diff (AC FIX `e53d56a`) — the discipline
  works; never skip it.
- Extract carried gates TEXTUALLY (split on `^- id: `), never via a YAML
  load/dump round trip — `to_yaml` rewraps long lines and breaks
  byte-identity.
- NEVER gates/rehearse under nohup (the I85 SIGHUP lesson). Gate-shell:
  /bin/sh, no `set -e` except inside byte-verbatim carried gates.
- `Gem.default_dir` never `Gem.dir` for gem-home probes (I85 rule;
  NOT applicable here — pure-ruby repo, no gem-home probe in any gate).
- Scratch in the lane tree: `tmp/fl86*` (gitignored) or root `fl86*`;
  scratch must NEVER contain the token `faraday` (the dep-pin gate greps
  the whole tree, case-insensitive).
- Judge runs gates at the LANE tree; builders never commit; integration
  commits `.ruby-version`.

## Provision facts for the coordinator

- Exact provision ref: `architect provision fast-llm-ruby-4-0-9 --base
  0c1949c` (re-verify `git -C repos/fast-llm log --oneline -1 main` ==
  `0c1949c` immediately before dispatch).
- **Known class (e724afe commit message + I53/I61/I62 precedent):**
  fast-llm lanes materialize `integration_branch` NIL at provision — the
  coordinator hand-sets it to **`main`**; the lane lands on `main` (the
  owner's PR-landing pattern for this repo).

## Builder Prompt provenance

Assembled by THIS spec session at **`tmp/fllm409-spec/prompt-core.md`**
(modeled on the I85 shape `tmp/ruby409-spec/prompt-core.md`: the four
Laws compressed, the declared base states with measured literals, the
hard rules, the tested verification commands, the report shape). NOT
copied anywhere. **The COORDINATOR copies it to
`build/I86-fast-llm-ruby-4-0-9-core/prompt.md`** at dispatch and appends
the Builder Prompt section (`architect section fast-llm-ruby-4-0-9 prompt
--append --lane core --from build/I86-fast-llm-ruby-4-0-9-core/prompt.md`)
— the recorded split of labor. `tmp/` is gitignored; this digest is the
committed record of the prompt's existence and contents.

## Known unknowns / open questions for the judge

- None battery-shaped: no declared flake classes for this repo; any RED
  beyond the declared pair is material. The one anticipated tooling
  movement is the declared bundler heal line (judge-adjudicated ACCEPT
  class at I85 under "lock unchanged-or-itemized" — here it is
  gate-sanctioned by the frozen lock legs themselves, no accept-bounds
  needed).
- The owner's post-landing follow-ups (pushing the fast-llm PR; loop
  tooling riding `latest`) are out of scope by plan ruling.
