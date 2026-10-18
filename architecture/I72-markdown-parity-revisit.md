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

### Objective

Close plan ENTRY 4 (`notes/plan-20261017T183001Z-tart-standalone.md`): **re-freeze the
I68 markdown-parity cure with the O(n) delimiter guard** — the parity substance the I68
judge adjudicated SOUND (48/48 battery, R1–R8 exact, I65 D1 reject semantics preserved,
scope exact, anchors EXACT) lands, minus the complexity defect that killed it. The
battery, the fixture, the cure law, and the frozen expectations are NOT re-litigated —
carried verbatim from I68. The iteration's own work is exactly one thing: **make the
cured converter's inline scan+resolve pipeline effectively linear in paragraph size,
hard-gated at both the micro and integration scales.**

### The contract (one lane)

**The fixture (frozen, spec-authored — copied, never regenerated).** Copy
`tmp/i68-spec/markdown_battery.json` VERBATIM to `test/fixtures/markdown_battery.json`
(byte-identical; the `md-battery-fixture` gate pins sha256
`4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883`, 48 cases). This
file is DATA, not code — any change to it is out of bounds. The expected distinctions
are the I68 spec session's oracle captures, not builder output.

**The battery tests** (`test/markdown_test.rb`): exactly one test per fixture case,
named `test_md_battery_<name>` (the `md_battery` token is LOAD-BEARING — the gate
filter `/md_battery/` must match ≥ 48 runs). Each test renders
`Render::Markdown.rows(src, width: 94)` and compares row-by-row: actual spans mapped to
`[text, fg&.to_s, modifiers.map(&:to_s).uniq.sort]` (zero-width spans dropped) vs the
fixture rows; fg `null` ↔ `span.fg.nil?`; modifiers compare as SETS. One shared
fixture-load + compare helper; tests through the public `Markdown.rows` interface
only — the I68 landed shape verbatim.

**The cure (re-derived from the preserved diff).** The R1–R8 mechanism is re-derived
from `build/I68-markdown-parity-core/lane-core.diff` (the retained worktree
`build/I68-markdown-parity-core/wt` is reference; `lib/tart/render/markdown.rb` and
`test/markdown_test.rb` are byte-unchanged since that diff's base `3845f6a`, measured
— the diff's context applies at `870e3f8`). The cure law is frozen (Grounds): the
CommonMark flanking predicates in both em and strong arms for both delimiters, `_`
intraword disallowed, `*` kept, the rule of 3, nearest-opener with run splitting; em
spanning inner `*`; the escapable-set escape arm; balanced-paren link destinations;
indented-fence dedent; task markers in the listBullet span; the I65 D1
reject-emission semantics as the reject path; the I68 PHASE-0 rulings as settled law.
Mechanism beyond the law is the builder's choice (hand-rolled, gem-neutral — the file
stays free of the underlying gem's name, tui-seam).

**THE O(n) GUARD — the iteration's own work (the I68 kill's cure).** The whole inline
scan+resolve pipeline must be effectively linear in paragraph size. Named, frozen:
(1) **the `~` guard** — `tokenize_inline` (or its successor) NEVER attempts the
strict-delimiter probe (`STRICT_DEL.match` on a tail slice) at a character that cannot
open the strict delimiter: a `~` character-class pre-check before any regex/slice work
(the judge's suggested shape; a builder-refined equivalent that provably skips the
probe on non-`~` chars is equally valid). (2) **the `close_emphasis` cost** — the
`toks.index { |t| t.equal?(…) }` identity scans (and the `openers.reject!` /
`children.any?` nested walk in the same arm) are replaced with O(1) bookkeeping
(index/position carried with the stack) or an otherwise-provably-linear equivalent —
measured this session, the bare `~` guard alone leaves the cure QUADRATIC (ratio 4.23;
the `toks.index` scans dominate on delimiter-dense text). (3) **the linear constant** —
per-CHARACTER text-Node emission is the remaining hog (~7,000 Struct allocations per
80-line paragraph); coalesce runs of plain text into single nodes (a boring-segment
fast path is the obvious shape — a segment with none of `\ ` ` * _ [ ~` is one text
node). The frozen `md-micro-perf` gate is the bar: **≤ 8.0 ms/conversion AND scale
ratio (160-line / 80-line) ≤ 3.0** on the gate's embedded markdown-heavy block (base
measures 2.69–2.83 / 2.14 this session; the I68 defect 83.55 / 4.12; guard-only
76.95 / 4.23 — both fail both legs). **`render-perf-probe` BP2 ≤ 250 stays the
integration-scale HARD gate** (at-base control 237.6 this session, the machine's
standing regime 236.7–241.7 — headroom is ~5%; the converter must be at or below
base-class cost on the probe's real transcript mix). The perf gates are measured
BEFORE the report claims green — benchmark first (micro + probe), then write the
table.

**Itemize-and-defend (the I68 lesson, standing ruling).** The builder's gate table
MUST include EVERY frozen gate — 66 of 66, `render-perf-probe` and `md-micro-perf`
included — each with its measured one-liner. An absent gate in the table is a
REJECT-class violation, exactly as the I68 Builder Report's "every local gate is
green" claim was REJECTed for tabling only 24 of 46.

**All other I68 frozen semantics preserved.** The I65 D1 owner-payload pins
(`OWNER_PAYLOAD`, `OWNER_PAYLOAD_SLICE`, the minimal trigger, the cover walk) and
reject-emission pins stay GREEN or move ONLY with declared, oracle-verified
expectations (never silently); the md-repro passthrough cases stay byte-exact. NO
render call-site changes: `transcript.rb` ({markdown_lines} :491, {reasoning_lines}
:536) and `chat.rb` :2068-:2124 are OUT of the touch set unless a battery defect
demands a seam change — declared in the report if so. The converter's public
interface (`Markdown.rows(text, width:)`, `Span`, `FG`) is unchanged — both render
paths consume it as-is.

### Frozen expectations (do not redesign)

- The wire/session/oracle anchors all hold EXACT at the lane tree: wire-delta
  (instruction sha `4209f40b…`, tools sha `7360fd1e…758831…`, key order,
  `store:false`, `stream_options`), session-golden (7/7 digests),
  zai-max-tokens-wire (tart=pi=512), the oracle-pin family, and every
  I69/I70/I71 landed-behavior gate — a render-only change never moves a settled
  byte.
- No rig scenario-content edits (`gems/tui-split-rig/scenarios/**`,
  `registry.yml`, `fixtures/` byte-frozen); no new gems; no
  Gemfile/gemspec/lock changes; no new `Thread.new` sites (the threads-budget
  law with the standing `lib/tart/models/listing.rb` exclusion).
- The frozen out dirs (`t72s1`…`t72s10`, `t72s17`, `t72s1t`, `t72tp`, `t72ub`,
  `t72wir`, `t72zwr`, `t72hwp`, `t72mot` — SHORT, ≤ 5 chars rel the tart root)
  keep the s9 AGENTS.md context row inside the measured-green boundary at the
  87-char lane tree (measured this session, Grounds).

### Named exclusions (Constraints, itemized)

- **Tables** (pi's renderTable is a full bordered-table renderer — owner backlog
  candidate; the battery contains no table case); setext headings; autolinks
  `<…>`; images; OSC-8 hyperlinks (standing I06 exclusion); latex rendering (the
  battery contains no `$`/`\(`/`\[` bytes by design); paragraph soft breaks
  (row-per-line parity already holds, GREEN).
- The plan's post-landing follow-ups (owner backlog, NOT loop work): model-window
  automation re-arm; tart PR-to-main decision; a `~/bin/architect` wrapper; the
  I71-era gate re-freeze backlog items (the s9 wrap-suffix constants, the scope
  `-uall`/`t70mot` rebase misses) — none re-litigated here; the s9 gate is
  carried in its I71 frozen form and was measured GREEN at this base at the
  predicted I72 lane geometry.
- `problems.md`/`ARCHITECT.md` annotations are LANDING work (architect-owned), not
  lane work.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands the tree). The
  deliverable is the provisioned worktree's diff vs `870e3f8`, exactly:
  `lib/tart/render/markdown.rb` (modified — MUST differ, the core touch),
  `test/markdown_test.rb` (modified), `test/fixtures/markdown_battery.json` (NEW,
  untracked — byte-identical to the spec fixture), plus `test/chat_test.rb` /
  `test/render/transcript_test.rb` ONLY if frozen expectations legitimately move
  (each move declared, oracle-verified).
- Scratch report at `build/I72-markdown-parity-revisit-core/report.md`: the suite
  summary line, the FULL 66-gate table (every gate, one measured one-liner each —
  itemize-and-defend), the battery per-family outcome (11 designed-RED cured, 37
  green kept), the perf evidence (md-micro-perf number + ratio, render-perf-probe
  BP-line) measured BEFORE the claims, deviations itemized.

### Tool guidance

- Verification (exact, tested at base `870e3f8` this session):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1255 runs, 6141 assertions, 0 failures, 0 errors, 1 skips`, exit 0 (post-lane:
  ≥ 1255 runs, 0F/0E); `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
  `SEAM_BENCH_OK`. The standing flake classes (spinner-dwell margin
  `render_perf_test.rb:265`, chat interrupt-timing) — re-run cold before
  adjudicating, note-and-pass per the standing ledger.
- The battery unit form: `bundle exec ruby -Ilib -Itest test/markdown_test.rb -n
  "/md_battery/"` → ≥ 48 runs, 0F; the full markdown family:
  `bundle exec ruby -Ilib -Itest test/markdown_test.rb` → 0F (base 31 runs + your
  48 battery pins, floor ≥ 79).
- The micro gate form (frozen, embedded): the `md-micro-perf` gate verbatim —
  measure, do not re-derive the block.
- The rig battery at YOUR tree (the lane worktree): the s-gate forms verbatim
  from the Acceptance Criteria (HERDR_* scrub prefix, the frozen SHORT out dirs,
  NO `--pi-bin` flag anywhere — the default resolution serves the pinned clone).
- Oracle probes (read-only): `cd repos/pi/packages/tui && node -e '…require("marked")…'`
  (marked 18.0.11 resolves via the hoisted root `node_modules`); `env -u
  PI_PACKAGE_DIR` for direct cli.js execs. NEVER write under `repos/pi`.
- `BUNDLE_GEMFILE`/bundler context may leak from parent sessions — prefix suspect
  tool calls with `env -u BUNDLE_GEMFILE` (the FULL scrub for `architect` CLI
  calls).

### Boundaries

- May touch: exactly the declared 5-path set (scope gate):
  `lib/tart/render/markdown.rb`, `test/markdown_test.rb`,
  `test/fixtures/markdown_battery.json` (NEW, spec-frozen bytes),
  `test/chat_test.rb` + `test/render/transcript_test.rb` (declared-moves only).
- Must not touch: everything else — including the render call sites
  (`lib/tart/render/transcript.rb`, `lib/tart/render/chat.rb`) absent a declared
  defect, all other `lib/tart/**`, the rig (`gems/tui-split-rig/**`), Gemfile/
  lock/gemspec, `bench/`, tart's `bin/`, `vendor/`, and anything under `repos/pi`.
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.5.0); house style per AGENTS: commented citations at the
  touched seams, tests through public interfaces, no refactors beyond the task.

### Lane plan

One lane — one converter, one battery, one guard, both render paths proven through it.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/markdown.rb
    - test/markdown_test.rb
    - test/fixtures/markdown_battery.json
    - test/chat_test.rb
    - test/render/transcript_test.rb
  effort: high
```

### Effort call

`high` — the lane re-derives the full I68 cure (the CommonMark delimiter machinery
woven into the scan/reject architecture without breaking the I65 D1 semantics or any
of the 37 green cases) AND re-engineers the scan/resolve cost profile to linear
(guard + O(1) index bookkeeping + text-run coalescing) against hard two-scale perf
gates with ~5% integration headroom, plus the 48-case battery and the full
13-scenario pty battery. The R4-vs-strong-arm priority edge and the
close_emphasis rewrite (semantics byte-preserved while the index scans go away) are
the risky edges that need the budget.

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
