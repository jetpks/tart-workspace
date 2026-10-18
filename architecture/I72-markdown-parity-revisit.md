# I72: markdown-parity-revisit

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 4 — the
  markdown-parity REVISIT. This iteration exists because **I68
  (`architecture/I68-markdown-parity.md`) was KILLed on exactly ONE defect**
  while its parity substance was judged SOUND. The I68 Verdict (quoted
  ground): "KILL — 45/46 frozen gates PASS cold, but the one FAIL
  (`render-perf-probe`, BP2 render-ms/s 298.9 vs the ≤ 250 budget) is a
  REAL, REPRODUCIBLE, LANE-ATTRIBUTABLE performance regression. The parity
  substance (the iteration's whole letter: R1–R8 cured, 48/48 frozen
  battery, 37 GREEN kept, I65 D1 reject semantics preserved, scope exactly
  the 3-path set, wire/session/oracle anchors EXACT) is sound — but the
  deliverable as a whole violates AC4's frozen render-perf standing guard,
  and a criterion is never relaxed to land good substance." Judge guidance
  on file (Verdict, "Successor shape"): "the successor lane re-uses this
  diff and fixes the tokenizer's scan cost — the minimal mechanism fix is
  a `~`-character guard before the STRICT_DEL attempt … plus attention to
  `close_emphasis`'s `toks.index` scans — with the render-perf-probe BP2
  budget re-measured GREEN at the lane tree as a first-class AC." Kill
  report: `notes/report-20261017T090112Z.md`; frozen battery law:
  `notes/spec-digest-20261017T083354Z.md`.
- **Base = tart `project/pi-port` @ `870e3f8`** (tip, clean tree —
  `git status` empty, measured this session). Entries I69
  (tart-identity-herdr), I70 (subagents-default-on) and I71
  (model-catalogue) have LANDED — their behavior is baseline: identity
  default TART, subagents default-on (the rig stages the opt-out on every
  parity path — the s1 tools digest is the I48-off constant
  `7360fd1e…758831…`), the vendored `/model` catalogue + live listing.
  **Measured base suite this session (fresh, cold, `bundle install
  --quiet && bundle exec rake`): 1255 runs / 6141 assertions / 0 failures
  / 0 errors / 1 skip, rake exit 0** — identical to the I71 judge wrap-up
  record (`notes/i71-judge-wrapup-20261018T0155Z.md`). First run this
  session hit the standing timing flake once
  (`render_perf_test.rb:265` spinner-dwell margin, 0.0742 vs ≥ 0.075 —
  the I58 flake class); cold re-run green — note-and-pass per the
  standing ledger. + `bench/seam_bench.rb` → `SEAM_BENCH_OK` (measured
  this session). `test/markdown_test.rb` alone: **31 runs / 102
  assertions / 0F** (the regression floor, unchanged since I68's base —
  `git diff 3845f6a 870e3f8 -- lib/tart/render/markdown.rb
  test/markdown_test.rb` is EMPTY, measured this session: the I68 cure
  diff still applies conceptually at this tip).
- **The I68 preserved artifacts (consumed here, not cleaned up):**
  `build/I68-markdown-parity-core/lane-core.diff` (the preserved cure
  diff, 530 lines — the builder re-derives the cure from it);
  `build/I68-markdown-parity-core/wt` (retained worktree @ 3845f6a with
  the cure applied, reference only); `tmp/i68-spec/markdown_battery.json`
  (the battery fixture, 22,070 bytes, sha256
  `4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883` —
  re-verified byte-identical this session; copied VERBATIM again, never
  regenerated).
- **The perf defect, measured this session (all three variants, same
  block, same machine — the spec session's own micro harness,
  `tmp/i72-spec/micro-bench2.rb`**: an 80-line/160-line markdown-heavy
  paragraph block, `Markdown.rows(src, width: 94)`, 100 iterations):
  **base `870e3f8` 2.69–2.83 ms/conversion, scale ratio P160/P80 2.14
  (linear); the I68 unguarded cure (preserved worktree) 83.55 ms/conversion,
  ratio 4.12 (quadratic); the cure + the judge's bare `~` guard (scratch
  shadow-lib probe, this session) 76.95 ms/conversion, ratio 4.23 — STILL
  QUADRATIC.** The `~` guard kills the per-plain-char
  `STRICT_DEL.match(src[i..])` tail-slice (the judge's dominant term on
  their block) but the remaining super-linear terms dominate on
  delimiter-dense content: `close_emphasis`'s two `toks.index { |t|
  t.equal?(…) }` linear scans over the whole token array per closer, the
  `openers.reject!`'s `children.any?` nested scan, and per-CHARACTER text
  Node emission (~7,000 Struct allocations per 80-line paragraph) as the
  linear-constant hog. **Consequence frozen into this spec: the O(n)
  mandate covers the WHOLE inline scan+resolve pipeline, not just the del
  guard.**
- **The integration-scale at-base control, measured this session**:
  `gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate` at
  base `870e3f8` → `RENDER_PERF_OK` with **BP2 = 237.6 render-ms/s** (≤
  250 budget) — BP1 2.40, BP3 9.3, BP4 21.8, BP5 18.6, frames 3042,
  transcript-rows 12535. The machine's standing hot regime across the
  I71-era runs measured BP2 236.7–241.7 (I71 rehearsal + judge runs) —
  today's 237.6 is that regime, not a transient: **the base sits ~5%
  under the frozen 250 budget, so the lane's converter must be at or
  below base-class cost on the probe's real transcript mix.** The I68
  defect micro (judge's own numbers): base 5.08 → lane 213.67
  ms/conversion (~42x) aggregated by 12,535-row live re-renders at 9.2
  conversions/s into BP2 115→299 on the I68 night (that night's at-base
  control was 115.4).
- **The oracle** (BRIEF §8 instrument): the pinned `repos/pi` clone @
  tag v1.1.0 (branch `oracle-v1.1.0`), ENVIRONMENT guarded by the standing
  `oracle-pin-state` gate — never re-performed from a lane. Direct oracle
  execs: `env -u PI_PACKAGE_DIR node <cli.js>`; marked 18.0.11 hoisted at
  `repos/pi/node_modules` (probe from `repos/pi/packages/tui`). The
  battery's expected distinctions are the I68 spec session's frozen
  oracle captures — they do NOT move with this iteration (the capture is
  frozen; a re-pin would need a re-capture decision, I68 digest).
- **Lane-tree geometry (measured, not predicted-by-formula):** the
  predicted lane tree is `build/I72-markdown-parity-revisit-core/wt` =
  **87 chars absolute** (8 longer than I71's 79). This session extracted
  base `870e3f8` into a scratch worktree of EXACTLY that length and ran
  the s9 gate form with the frozen out dir `t72s9`: **exit 0, both apps
  completed 1/1, zero unknown-candidates** — tart's AGENTS.md context row
  lands at 121 chars (wraps exactly one char deeper than pi's 120) and
  the rig's path normalization absorbs it. GREEN at the predicted
  geometry; the scratch tree was removed and `repos/tart` is clean (0
  entries).
- **ENV GOTCHA (standing until a child-env-scrub entry lands):** any
  `architect` CLI call from inside a bundle-exec'd context needs the FULL
  scrub (`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE
  -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`);
  tart gates that boot the app carry the HERDR_* scrub; every
  out-dir-writing gate owns its `rm -rf`.
- **Routing:** rides `architect.yaml` as-is; the model-window tick is
  DEAD (owner re-arms post-reset) — never re-armed in-loop. Landing is
  the human's (PRs, pushes, gem releases — nothing pushed by the loop).

### The frozen battery + cure law (carried from I68 VERBATIM — this iteration does NOT re-litigate it)

- **48 cases, 11 designed-RED, 37 GREEN** (`tmp/i68-spec/
  markdown_battery.json`, the I68 Grounds divergence ledger R1–R8): `_`
  intraword em/strong disallowed (owner's snake_case headline,
  `foo__bar__baz`, paren pairs), `*` intraword kept, `**` flanking
  (`** padded **` literal), em spanning inner `*`, escape arm =
  backslash + ASCII punctuation ONLY, link destinations carry balanced
  parens, indented-fence body dedent (≤ 3), task markers folded into the
  listBullet span. The CommonMark flanking predicates in BOTH em and
  strong arms for BOTH delimiters; the I65 D1 reject-emission semantics
  FROZEN as the reject path (delimiter at `m.begin(0)`, advance
  `m.begin(0)+1`, re-scan). The fixture stores explicit span TRIPLES
  `[text, fg, modifiers]` (fg symbol-name or null; zero-width spans
  dropped; modifiers compare as SETS; width 94); 36 cases' rows are
  tart's measured base spans (oracle-equal at I68's base), 11 carry the
  oracle-frozen post-cure expectations. The I68 judge confirmed all of
  this SOUND (48/48 battery green at the killed lane, R1–R8 exact,
  reject semantics preserved by construction, scope exact).
- **The I68 PHASE-0 rulings carry as settled law** (all ACCEPT, I68
  Verdict): CommonMark predicates (not marked's regex quirks) with marked
  as oracle SHAPE and the battery as bar; emphasis may span paragraph
  soft breaks (rows still split per-line — observable unchanged);
  codespans stay line-bound with the run-length closer and one-edge-space
  strip; link label/dest line-bound, non-empty, titles unsupported;
  standing exclusions unchanged (tables — owner backlog; setext,
  autolinks, images, OSC-8, latex — the battery contains no `$`/`\(`/`\[`
  bytes by design); the nested-strong-inside-heading duplicate `:bold`
  modifier is visually idempotent — optional span hygiene, never a gate.

### The frozen wire/session anchors at base (the render-only bar)

A converter-only change must not move a single wire/session byte: the s1
request body digests (instruction `4209f40b…` EXACT, tools
`7360fd1ec641…758831…c23707` EXACT — the staged subagents opt-out
constant on parity paths, key order, `store:false`,
`stream_options`), the session-golden digests (7/7), zai wire
tart=pi=512, the oracle-pin family, and every I69/I70/I71 landed-behavior
gate (identity law, default-face/boot, herdr wire, subagents default law
+ MOTD probes + e2e, rig staging, the vendored catalogue + listing
family) — all standing regression pins at this base, carried into this
iteration's frozen block.

### Prior handoffs

`notes/spec-digest-20261017T233040Z-model-catalogue.md` (I71 — the
generation/audit/rehearsal/freeze mechanics, the short-out-dir law, the
judge-at-lane-tree venue, the flake ledger, the scrub forms);
`notes/spec-digest-20261017T083354Z.md` (I68 — the battery law, the
fixture generation chain, the designed-RED discipline, the
carry-audit-before-rehearsal rule).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section markdown-parity-revisit specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision markdown-parity-revisit`
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
`architect rehearse markdown-parity-revisit` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze markdown-parity-revisit` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse markdown-parity-revisit` — before the freeze, while
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
subsection per lane. A copy is written to build/I72-markdown-parity-revisit-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section markdown-parity-revisit prompt --append --lane <lane> --from build/I72-markdown-parity-revisit-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I72-markdown-parity-revisit-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence markdown-parity-revisit --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section markdown-parity-revisit verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify markdown-parity-revisit`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
