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

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **66 gates — 60 carried from the I71
frozen block + 4 re-admitted from the I68 frozen block byte-verbatim + 2
new/rewritten.** The carry audit ran clean BEFORE rehearsal
(`tmp/i72-spec/audit-gates.rb`: AUDIT_OK — 60 carried byte-identical after
the DECLARED rebases, zero DIFF, zero AC-DRIFT, zero undeclared-DROP).
**Declared DROPPED (1):** `scope` — per-iteration (rewritten here for this
lane's 5-path touch set, never carried). **Declared rebases (the carried
commands, byte-verbatim except these):** the out-dir family
`t71*`→`t72*` and the I70-carried `t70mot`→`t72mot` (all SHORT, ≤ 5 chars
rel the tart root — the s9 AGENTS.md context row stays inside the
measured-green boundary at the 87-char predicted lane tree, measured this
session); `threads-budget`'s diff base `dd41ae1`→`870e3f8` (this
iteration's base; the standing `lib/tart/models/listing.rb` pathspec
exclusion rides unchanged); the scratch cosmetics `tmp/i71-unused`→
`tmp/i72-unused` and the mktmpdir prefixes `i71-*`→`i72-*` (zero
semantics). **Re-admitted from I68 byte-verbatim (4):**
`md-battery-fixture`, `md-battery-units`, `md-regression-units`,
`md-flanking-repro` — the killed iteration's own parity-battery gates;
the battery is NOT re-litigated. **New (2):** `md-micro-perf` (the
two-scale O(n) hard gate) and the rewritten `scope`. The carried gates
keep their I71 `ac:` labels verbatim — the I71-labeled members collapse
onto AC4 as standing guards, except the pty battery (AC5) and suite/bench
(AC6); the re-admitted I68 gates keep their I68 labels (they align
exactly with AC1/AC2/AC3 below).

**The designed-RED vector (5, every one RED at base `870e3f8` for the
right reason — the iteration's own work does not exist at base):**
`md-battery-fixture` (the fixture does not exist at base),
`md-battery-units` (0 test names match `/md_battery/` at base),
`md-regression-units` (31 runs < the 79 floor — the battery pins are
declared-new), `md-flanking-repro` (every embedded assertion is a measured
base divergence — the I68 Grounds ledger R1–R8), `scope` (markdown.rb
untouched at base — the must-differ leg). **Every other member is
expected GREEN at base.** Measured this session (cold, fresh — never a
predicted floor): suite **1255 runs / 6141 assertions / 0F / 0E / 1 skip,
rake exit 0** (one first-run spinner-dwell timing flake, the standing I58
class, cold-green on re-run — the standing note-and-pass ledger applies to
the builder and judge alike: re-run cold before adjudicating that class);
`SEAM_BENCH_OK`; the markdown family 31 runs / 102 assertions / 0F;
`render-perf-probe` at base `RENDER_PERF_OK` with **BP2 237.6** (the
machine's standing regime 236.7–241.7 across the I71-era runs); the s9
gate form GREEN at the exact predicted 87-char lane-tree geometry
(scratch worktree, exit 0, both apps completed, zero unknown-candidates).
**The standing chat interrupt-timing class manifested TWICE this session,
in both its forms:** once as the spinner-dwell FAILURE noted above, and
once as a HANG under rehearsal #1 (`chat_test.rb:1613`
`test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
blocked in `wait_until` until the harness SIGTERMed at the 900 s gate
timeout — the identical test the I70/I71 ledgers record flaking as a
failure) — while the same suite measured GREEN twice directly in this
session (227 s wall each) and every other rehearsal member ran green.
The standing re-run-cold-before-adjudicating ledger governs BOTH forms
for builder and judge alike; a suite BROKEN-by-timeout carrying this
test's hang signature is that environment class, never an unadjudicated
lane-defect claim.
The rehearsal measures the true at-base vector; any member that
contradicts this preamble is amended and re-rehearsed before the freeze
(the I67/I71 protocol — never freeze on a stale or
corrected-without-rerun vector).

**AC1 — the frozen battery fixture (spec-authored bytes).**
`test/fixtures/markdown_battery.json` exists and is BYTE-IDENTICAL to the
I68 spec session's frozen fixture (sha256
`4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883`,
48 cases): the builder copies it VERBATIM from
`tmp/i68-spec/markdown_battery.json` and NEVER regenerates it — the
expected distinctions are the frozen oracle captures, not builder output.
Any byte drift is out of bounds. Gates: `md-battery-fixture`.

**AC2 — the battery landed as pins, nothing deleted.** The battery is
pinned as exactly one `test/markdown_test.rb` test per fixture case
(≥ 48 runs under the `/md_battery/` name filter, 0F/0E), comparing
rendered span rows field-wise (text, fg, modifiers-as-SET) at
`width: 94` through the public `Markdown.rows` interface; the full
markdown family runs ≥ 79 (31 base + 48 battery) with 0F/0E — the
existing pins (incl. the I65 D1 owner-payload fixtures and the
reject-emission semantics) stay green or move only with declared,
oracle-verified expectations. Gates: `md-battery-units`,
`md-regression-units` (+ AC4's `md-repro`, `md-inline-units` cold).

**AC3 — the delimiter/inline/block law, independent of builder-authored
tests.** The I68 headline discriminations hold at the lane tree, asserted
by the frozen embedded gate (re-admitted byte-verbatim): `_` intraword
disallowed in BOTH arms (the snake_case line and `foo__bar__baz` literal;
`A _real_ emphasis case` still em); `*`-intraword kept (em + strong);
`**`-flanking (padded strong literal); em spanning inner `*` (nested
em+strong); backslash literal before non-punctuation; link URLs carrying
balanced parens (the gray span boundary); indented-fence body dedent;
task markers riding the listBullet span; the I65 D1 reject-emission
semantics preserved. Gates: `md-flanking-repro` (+ every AC2 member).

**AC4 — the O(n) guard + render-only byte-freeze + the standing battery.
HARD perf gates, measured BEFORE the report claims green.** (a)
`md-micro-perf` PASSES cold at the lane tree: the frozen markdown-heavy
block renders ≤ 8.0 ms/conversion AND the scale ratio (160-line /
80-line) ≤ 3.0 — the complexity class is pinned machine-independently
(base 2.69–2.83 / 2.14 this session; the I68 defect 83.55 / 4.12;
guard-only 76.95 / 4.23 — both fail both legs). (b) `render-perf-probe`
PASSES cold at the lane tree: BP2 ≤ 250 render-ms/s (at-base control
this session 237.6, the standing machine regime 236.7–241.7 — headroom
~5%; if BP2 fails at the lane tree, the judge applies the standing
three-leg adjudication — cold re-run, at-base control on the same
machine, micro attribution — the I68 verdict precedent, never a silent
relaxation). (c) The scan-pipeline law: no regex or slice work on
characters that cannot open a construct (the `~` guard or equivalent),
no linear identity scans per closer (O(1) index bookkeeping or
equivalent), plain-text runs coalesced — semantics byte-preserved (the
battery + every existing pin is the bar; a boring-segment fast path must
render identically). (d) Exactly the declared 5-path touch set changes
vs `870e3f8` — `lib/tart/render/markdown.rb` (MUST differ), and the
other four only as declared — NOTHING else; all standing anchors hold at
the lane tree (wire-delta, session-golden, threads-budget, the oracle
family, the I69/I70/I71 landed-behavior gates). No new runtime deps; the
parser stays hand-rolled and gem-neutral. (e) Itemize-and-defend: the
builder's gate table includes EVERY frozen gate — 66 of 66 — an absent
entry (perf gates included) is a REJECT-class violation. Gates:
`md-micro-perf`, `render-perf-probe`, `scope` + every carried member +
`wire-delta`.

**AC5 — the pty parity battery, cold at the lane tree.** Every frozen
scenario gate — `s1`–`s10`, `s17`, `s1-tart-mode` (the tolerant form:
rig ec ≤ 1 + `TART_MODE_OK`), `zai-max-tokens-wire` (tart=pi=512) —
passes at the lane tree with the frozen SHORT out dirs (`t72s1`…
`t72s10`, `t72s17`, `t72s1t`) and NO `--pi-bin` flag anywhere (the
default resolution serves the pinned clone; `Identity::ORACLE_VERSION`
1.1.0 untouched). The render-only converter change must not move any
settled screen. Gates: `s1`–`s10`, `s17`-parity, `s1-tart-mode`,
`zai-max-tokens-wire`.

**AC6 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — ≥ 1255 runs, 0
failures, 0 errors (the standing 1 rig live-run skip unchanged; the 48
battery pins grow the count) — and `bundle exec ruby bench/seam_bench.rb`
prints `SEAM_BENCH_OK`. Judge env note (the I59+ standing class): the
three launcher/SystemPrompt pins inside `suite` are
environment-dependent — if present in the judge's env they adjudicate
env-class, exactly as standing. Gates: `suite`, `bench`.

```gates
---
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
    added=$(git diff 870e3f8 -- lib ':(exclude)lib/tart/models/listing.rb' | grep -E "^\+[^+].*Thread\.new" || true)
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
    --gate --out t72tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t72ub
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
  cmd: rm -rf t72s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t72s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t72s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t72s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t72s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t72s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t72s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t72s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t72s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t72s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t72s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t72s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t72s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t72s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t72s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t72wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t72wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t72wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t72zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t72zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t72zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
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
    home = Dir.mktmpdir("i72-boot-")
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
    dir = Dir.mktmpdir("i72-hu-")
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
    rm -rf t72hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t72hwp
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
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i72-unused")
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
    rm -rf t72mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t72mot
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
    home = Dir.mktmpdir("i72-vu-")
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
- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: 'git diff --quiet 870e3f8 -- Gemfile Gemfile.lock tart.gemspec bin bench gems
    lib/tart/render/transcript.rb lib/tart/render/chat.rb && ! (git diff --name-only
    870e3f8; git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(lib/tart/render/markdown\.rb|test/markdown_test\.rb|test/fixtures/markdown_battery\.json|test/chat_test\.rb|test/render/transcript_test\.rb|t72[0-9a-z]*/?)$"
    | grep -q . && [ -n "$(git diff 870e3f8 -- lib/tart/render/markdown.rb)" ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 5-path touch set or markdown.rb
    is untouched (the core touch)"; exit 1; } && echo SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Builder lane prompt — iteration `markdown-parity-revisit` (I72), lane `core`

You are the builder for iteration `markdown-parity-revisit` (I72), lane `core`, repo `tart`. You are the ONLY lane.

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I72-markdown-parity-revisit.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (the `Objective`, `The contract (one lane)`, `THE O(n) GUARD`, `Frozen expectations`, `Named exclusions`, `Output format`, `Tool guidance`, `Boundaries`, `Lane plan`, the 66-gate frozen ```gates block, and the `## Builder Prompt`-adjacent laws). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting reads named by the specification (do not skip): `notes/spec-digest-20261018T031345Z-markdown-parity-revisit.md`, `architecture/I68-markdown-parity.md` (§Verdict), `notes/spec-digest-20261017T083354Z.md`, `notes/report-20261017T090112Z.md`, and the preserved cure `build/I68-markdown-parity-core/lane-core.diff` (reference worktree `build/I68-markdown-parity-core/wt` @ 3845f6a).

## Operating constraints (lane)

- Work ONLY in your provisioned worktree: `build/I72-markdown-parity-revisit-core/wt` in the space, on branch `lane/I72-markdown-parity-revisit-core`, base tart `project/pi-port` @ `870e3f8`.
- NEVER commit (the integrator lands your tree). NEVER touch the space repo. NEVER push.
- NEVER touch any gem: `ratatui_ruby 1.5.0` and `fast-completions 0.5.0` are dependencies — consume, never modify. No new gems; no Gemfile/gemspec/lock changes.
- NEVER write anything under `repos/pi` — the pinned oracle clone (branch `oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state`; read-only reference. `env -u PI_PACKAGE_DIR` for every direct oracle exec.
- Touch set is EXACTLY the 5 paths in the Specification's `Boundaries`/`Lane plan` (scope gate): `lib/tart/render/markdown.rb`, `test/markdown_test.rb`, `test/fixtures/markdown_battery.json` (NEW), `test/chat_test.rb`, `test/render/transcript_test.rb`.
- Battery fixture: copy `tmp/i68-spec/markdown_battery.json` VERBATIM to `test/fixtures/markdown_battery.json` (byte-identical; sha256 `4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883`, 48 cases) — never regenerate.
- Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root); each gate owns `rm -rf` of its out dir. No rig scenario-content edits (`gems/tui-split-rig/scenarios/**`, `registry.yml`, `fixtures/` byte-frozen).
- Full env scrub for every `architect` CLI call: `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`.
- Standing flake classes (`render_perf_test.rb:265` spinner-dwell margin; `chat_test.rb:1613` interrupt-timing, BOTH the failure and the 900s-hang forms): re-run COLD before adjudicating; note-and-pass per the standing ledger.
- ITEMIZE-AND-DEFEND (the I68 lesson, frozen into AC): your gate table MUST carry EVERY frozen gate — 66 of 66, `render-perf-probe` and `md-micro-perf` INCLUDED — each with a measured one-liner. An absent gate in the table is a REJECT-class violation.
- PERF FIRST: measure the perf gates (micro + probe) BEFORE your report claims green — benchmark, then table.

## Deliverable + report

- Deliverable: the worktree diff vs `870e3f8` — exactly the 5-path set (markdown.rb MUST differ — the core touch; markdown_battery.json NEW untracked; chat_test.rb / transcript_test.rb ONLY if frozen expectations legitimately move, each declared oracle-verified). NO lane commits.
- Scratch report at `build/I72-markdown-parity-revisit-core/report.md`: the suite summary line, the FULL 66-gate table (one measured one-liner each), the battery per-family outcome (11 designed-RED cured / 37 green kept), the perf evidence (md-micro-perf number + scale ratio, render-perf-probe BP-line), deviations itemized, and a final `STATUS:` line.

## Builder Report

### core

# Builder report — I72 `markdown-parity-revisit`, lane `core`

Repo `tart`, worktree `build/I72-markdown-parity-revisit-core/wt`, branch
`lane/I72-markdown-parity-revisit-core`, base `870e3f8`. NO lane commits
(`git log 870e3f8..` = 0 commits). Deliverable diff = exactly:
`lib/tart/render/markdown.rb` (M, +436/−78 net with tests aside), `test/markdown_test.rb`
(M, +31), `test/fixtures/markdown_battery.json` (NEW, untracked).
`test/chat_test.rb` / `test/render/transcript_test.rb`: NOT touched (zero diff —
no frozen expectation moved). `git diff 870e3f8 --stat`:
`lib/tart/render/markdown.rb | 514 +++++++++++++++++++++++++++++++++++++-------`,
`test/markdown_test.rb | 31 +++`; 2 tracked files, 467 insertions, 78 deletions.
Untracked besides the fixture: only the frozen `t72*` gate out dirs (each gate
owns its `rm -rf`; left in place per the standing precedent) and
`tmp/render-perf-gate`.

## Suite + bench (AC6, cold, this session)

- `bundle install --quiet && bundle exec rake && echo SUITE_OK` →
  **1303 runs, 6187 assertions, 0 failures, 0 errors, 1 skips** — rake exit 0,
  `SUITE_OK` printed. (Base floor 1255 runs; +48 = the battery pins, exactly.)
  The standing 1 skip unchanged.
- `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`.
- Standing flake ledger: NEITHER class manifested this session —
  `render_perf_test.rb:265` spinner-dwell margin and the
  `chat_test.rb:1613` interrupt-timing class (both forms) never fired across
  two full suite runs; note-and-pass ledger carries nothing new.

## Perf evidence (measured before any green claim)

### md-micro-perf (AC4a, the frozen embedded form, verbatim)

```
MD_MICRO_OK 4.64 ms/conv ratio 1.99        (gate-form run)
MD_MICRO_OK 4.44 ms/conv ratio 2.23        (repeat 1)
MD_MICRO_OK 4.72 ms/conv ratio 1.78        (repeat 2)
```

Both legs: ≤ 8.0 ms/conversion ✓ (margin ~42%) and ratio ≤ 3.0 ✓. Anchors on
record: base `870e3f8` 2.69–2.83 / 2.14 (linear); I68 defect 83.55 / 4.12
(quadratic); judge's bare `~`-guard-only 76.95 / 4.23 (still quadratic).

### render-perf-probe (AC4b, frozen form, at the lane tree)

```
AV marker: PASS observed
AV requests: PASS 3 (want == 3)
AV frames: PASS 3013 (want >= 1500)
AV live-bytes: PASS 44677 (want >= 30,000)
AV transcript-rows: PASS 12535 (want >= 11,000)
BP1: PASS 2.20 (median frame_ms <= 3.0)
BP2: PASS 214.9 (render-ms/s <= 250)
BP3: PASS 9.6 (md conversions/s <= 25)
BP4: PASS 22.4 (paints/s <= 35)
BP5: PASS 8.8 (burst->top-row-change ms <= 40)
RENDER_PERF_OK
```

**BP2 = 214.9 ≤ 250** — the lane tree sits 35 under the frozen budget and ~23
BELOW this machine's base-class regime (237.6 spec-session control, 242.0
digest control, standing band 236.7–241.7): the converter is FASTER than base
on the probe's real transcript mix, not merely inside headroom.

### The O(n) guard law, per-term (AC4c)

- **The `~` guard**: `tokenize_inline` pre-gates the strict-del probe on a
  literal `~~` (`ch == "~" && src[i + 1] == "~"`); every other probe branch is
  pre-gated on its opening character. No regex or slice work runs on a
  character that cannot open a construct. The probe itself is a
  StringScanner-anchored scan of the frozen `STRICT_DEL` body (no
  `src[i..]` tail-slice allocation per attempt — the I68 kill's dominant term).
- **O(1) closer bookkeeping**: the token run is doubly linked with sentinel
  ends; a match = one O(children) unlink walk (each node absorbed from the
  flow exactly once) + O(1) splice; the opener stack prunes by
  `slice!(j..)` truncation (the I68 `toks.index` identity scans and the
  `openers.reject!`/`children.any?` containment walk are gone). The failed-
  closer path binds the reference openers-bottom law: the bound rides just
  below the failed closer and a closer that can no longer open leaves the
  stack — the I68 cure's degenerate `nil` bound re-walked the whole
  accumulated stack on EVERY failed closer. Measured:
  - I68 cure's bound mechanism (instrumented, this session): 19,680 search
    steps @ 80 lines → 77,760 @ 160 → 309,120 @ 320 (4x per 2x — quadratic);
    per-1k-token resolve cost 3.24 → 5.18 → 9.19 ms.
  - After the fix: per-1k-token resolve cost 1.15 → 1.15 → 1.17 ms
    (80/160/320 lines) — flat, linear.
- **Text-run coalescing**: `BORING_RUN` fast path — a run with no
  construct-opening character is ONE text node. The gate's 80-line block
  tokenizes to 1921 nodes (the I68 cure emitted ~8,000+ per-char Struct
  nodes for the same block; ~7,000-allocation-per-paragraph hog retired).

## The frozen battery — per-family outcome (AC1/AC2/AC3)

Fixture: copied VERBATIM from `tmp/i68-spec/markdown_battery.json`; sha256
`4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883` ✓
48 cases ✓ (gate `md-battery-fixture` PASS). 48 battery tests
(`/md_battery/` filter: **48 runs, 48 assertions, 0 failures**) through the
public `Markdown.rows(src, width: 94)`, field-wise
`[text, fg&.to_s, sorted-unique modifiers]`, zero-width spans dropped — the
I68 landed shape verbatim. Markdown family: **79 runs (31 base + 48 battery),
148 assertions, 0 failures** (≥ 79 floor ✓).

Designed-RED measured at base (`870e3f8`, this session, per-case probe) —
all 11 cured at the lane tree:

| # | case | family |
|---|------|--------|
| 1 | owner_snake_line | R1a `_` intraword em disallowed |
| 2 | intraword_double_underscore | R2 `__` intraword strong disallowed |
| 3 | multi_snake_identifiers | R1a |
| 4 | strong_padded | R3 `**` flanking (padded literal) |
| 5 | strong_intraword | R2 |
| 6 | underscore_pair_in_parens | R1a |
| 7 | em_nested_strong_star | R4 em spans inner `*` |
| 8 | escaped_backslash_before_letter | R5 escape arm = ASCII punctuation only |
| 9 | link_parens_url | R6 balanced-paren link destinations |
| 10 | fenced_indented | R7 indented-fence body dedent (≤ 3) |
| 11 | list_task | R8 task markers fold into the listBullet span |

37 GREEN kept: the base-mismatch probe renders **0 mismatching cases** at the
lane tree (base: the 11 above; lane: none) — nothing deleted, nothing
re-litigated. The 12 embedded `md-flanking-repro` assertions (R1a/R1b/R2/
R3/R3b/R3c/R4/R5/R6/R7/R8 + the I65 D1 reject-emission pin) all EXACT
(`MD_FLANKING_OK`); `md-repro` passthrough byte-exact (`MD_REPRO_OK`).

## The frozen 66-gate table (itemize-and-defend — 66 of 66)

| # | gate | result | measured one-liner |
|---|------|--------|--------------------|
| 1 | suite | PASS | `bundle install --quiet && bundle exec rake` → 1303 runs, 6187 assertions, 0F, 0E, 1 skip, exit 0, SUITE_OK (cold, ×2) |
| 2 | bench | PASS | `SEAM_BENCH_OK` |
| 3 | md-repro | PASS | `MD_REPRO_OK` — both passthrough cases byte-exact (42-byte trigger + `a ~~ padded ~~ b * and *`) |
| 4 | md-inline-units | PASS | `/inline_scan/` markdown 3 runs 0F + transcript 2 runs 0F → `MD_INLINE_UNITS_OK` |
| 5 | pending-registry-units | PASS | `/pending_registry/` transcript 4 runs 0F → `PENDING_REGISTRY_UNITS_OK` |
| 6 | footer-window | PASS | `FOOTER_WINDOW_OK 1000000` — footer/loop window agreement + env tier |
| 7 | thinking-pins | PASS | agent-loop 11 runs + settings 8 runs, 0F → `THINKING_PINS_OK` |
| 8 | hermeticity | PASS | launcher smoke 8 runs + e2e session 4 runs, 0F → `HERMETICITY_OK` |
| 9 | lock-deps | PASS | no ruby_llm; `fast-completions 0.5.0` pin; lock clean; `GEM_LOAD_OK` |
| 10 | zai-data | PASS | dialect pins 2 runs 0F; zai dialect values exact → `ZAI_DATA_OK` |
| 11 | threads-budget | PASS | `git diff 870e3f8 -- lib` (listing.rb excluded): zero new `Thread.new` sites → `THREADS_BUDGET_OK` |
| 12 | session-golden | PASS | 7/7 digests exact → `SESSION_GOLDEN_OK` |
| 13 | strict-wire | PASS | strict_sampling 8 runs, 76 assertions, 0F |
| 14 | error-transcript-units | PASS | agent-loop 4 + session 2 runs, 0F → `ERROR_TRANSCRIPT_UNITS_OK` |
| 15 | error-transcript-render-units | PASS | chat 3 + transcript 2 runs, 0F → `ERROR_TRANSCRIPT_RENDER_UNITS_OK` |
| 16 | render-perf-units | PASS | render_perf 7 runs, 29 assertions, 0F |
| 17 | render-perf-probe | PASS | `RENDER_PERF_OK` — **BP2 214.9 ≤ 250**; BP1 2.20, BP3 9.6, BP4 22.4, BP5 8.8, frames 3013, transcript-rows 12535 (base control 237.6/242.0) |
| 18 | tool-pending-gate | PASS | `TOOL_PENDING_GATE_OK` (out dir t72tp) |
| 19 | user-bash-stream-gate | PASS | `USER_BASH_STREAM_GATE_OK` (out dir t72ub) |
| 20 | zai-max-tokens-units | PASS | agent-loop 4 + models 2 + launcher 2 runs, 0F → `ZAI_MAX_TOKENS_UNITS_OK` |
| 21 | rail-bg | PASS | `RAIL_BG_OK` — full-width/pad/plain/straddle legs |
| 22 | jump-pill-units | PASS | `/jump_pill/` chat 6 runs, 0F → `JUMP_PILL_UNITS_OK` |
| 23 | rail-bg-units | PASS | `/rail_background/` chat 4 runs, 0F → `RAIL_BG_UNITS_OK` |
| 24 | viewport-probe | PASS | `VIEWPORT_PROBE_OK` |
| 25 | oracle-pin-state | PASS | pin branch = tag v1.1.0, clean tree, cli.js v1.1.0 → `ORACLE_PIN_OK` |
| 26 | oracle-bin-units | PASS | `/oracle_bin/` 5 runs, 0F → `ORACLE_BIN_UNITS_OK` |
| 27 | oracle-resolve | PASS | default resolves the pinned clone cli; flag/env tiers intact → `ORACLE_RESOLVE_OK` |
| 28 | s1-parity | PASS | exit 0 (out dir t72s1) |
| 29 | s2-parity | PASS | exit 0 (t72s2) |
| 30 | s3-parity | PASS | exit 0 (t72s3) |
| 31 | s4-parity | PASS | exit 0 (t72s4) |
| 32 | s5-parity | PASS | exit 0 (t72s5) |
| 33 | s6-parity | PASS | exit 0 (t72s6) |
| 34 | s7-parity | PASS | exit 0 (t72s7) |
| 35 | s8-parity | PASS | exit 0 (t72s8) |
| 36 | s9-parity | **FAIL** | deterministic lane-tree GEOMETRY — see the geometry section below (candidates `- / for commands`, `+md`; exit 1; reproduced ×2) |
| 37 | s10-parity | PASS | exit 0 (t72s10) |
| 38 | s17-parity | PASS | exit 0 (t72s17) |
| 39 | s1-tart-mode | PASS | rig ec 0 ≤ 1 + `TART_MODE_OK` (tart completed, requests == expected) (t72s1t) |
| 40 | wire-delta | PASS | `WIRE_DELTA_OK` — instruction sha `4209f40b…` EXACT, tools sha `7360fd1e…758831…` EXACT, key order/store:false/stream_options exact (t72wir) |
| 41 | zai-max-tokens-wire | PASS | `ZAI_WIRE_OK tart=pi=512` (t72zwr) |
| 42 | identity-law | PASS | `IDENTITY_LAW_OK` — default tart, all opt-in tiers, ORACLE_VERSION 1.1.0 |
| 43 | default-face | PASS | `DEFAULT_FACE_OK` — tart face + pi face legs |
| 44 | default-boot | PASS | `DEFAULT_BOOT_OK` — tart preamble + TART_* namespace on a default boot |
| 45 | herdr-units | PASS | `HERDR_UNITS_OK` — session/state ladder, seq scale, apostrophe path drop, env-off |
| 46 | herdr-wire-probe | **FAIL** | deterministic lane-tree GEOMETRY — see the geometry section below (`HERDR_WIRE_FAIL: no reports received`, reproduced ×3) |
| 47 | rig-identity-assert | PASS | `RIG_IDENTITY_OK` — staged TART_IDENTITY=pi + override + blank refusal |
| 48 | subagents-default-law | PASS | `SUBAGENTS_DEFAULT_LAW_OK` — DEFAULTS on, env/file tiers, namespacing |
| 49 | subagents-default-boot | PASS | `SUBAGENTS_DEFAULT_BOOT_OK` — on-shape digest exact; off-shape = the I48 constant exact; instruction bytes unchanged |
| 50 | subagents-motd-units | PASS | `SUBAGENTS_MOTD_UNITS_OK` — six builtins, expanded/collapsed rows exact |
| 51 | subagents-motd-probe | PASS | `SUBAGENTS_MOTD_OK` (t72mot) |
| 52 | subagents-e2e-default-on | PASS | `/default_on/` 4 runs, 0F → `SUBAGENTS_E2E_DEFAULT_OK` |
| 53 | rig-staging-units | PASS | `RIG_STAGING_OK` — opt-out staged; compaction rows present only with a window |
| 54 | vendored-attribution | PASS | `VENDORED_ATTRIBUTION_OK` — attribution + offline refresh task + oracle-identical file set |
| 55 | vendored-units | PASS | `VENDORED_UNITS_OK` — gap fill, cap fill, thinking map, dialect legs |
| 56 | listing-units | PASS | models_listing 5 runs, 0F → `LISTING_UNITS_OK` |
| 57 | model-menu-live-merge | PASS | live_list 3 + menu refresh 2 runs, 0F → `MODEL_MENU_LIVE_MERGE_OK` |
| 58 | launcher-listing-thread | PASS | `/listing_endpoint/` 1 run, 0F → `LAUNCHER_LISTING_THREAD_OK` |
| 59 | vendored-no-boot-network | PASS | `VENDORED_NO_BOOT_NETWORK_OK` — no HTTP tokens; listing only in the menu path |
| 60 | listing-thread-law | PASS | exactly one `Thread.new` site, in listing.rb only → `LISTING_THREAD_LAW_OK` |
| 61 | md-battery-fixture | PASS | sha256 `4ecd9cc2…` ✓, 48 cases → `MD_BATTERY_FIXTURE_OK` |
| 62 | md-battery-units | PASS | `/md_battery/` → 48 runs, 48 assertions, 0F → `MD_BATTERY_UNITS_OK` |
| 63 | md-regression-units | PASS | markdown family → 79 runs, 148 assertions, 0F (31 base + 48 battery, nothing deleted) |
| 64 | md-flanking-repro | PASS | `MD_FLANKING_OK` — R1a/R1b/R2/R3/R3b/R3c/R4/R5/R6/R7/R8 + I65 D1 reject-emission EXACT |
| 65 | md-micro-perf | PASS | `MD_MICRO_OK 4.64 ms/conv ratio 1.99` (≤ 8.0 / ≤ 3.0; repeats 4.44/2.23, 4.72/1.78) |
| 66 | scope | PASS | `SCOPE_OK` — diff vs `870e3f8` = exactly markdown.rb (M, must-differ ✓) + markdown_test.rb (M) + the fixture (NEW); zero bites outside the 5-path set |

Tally: **64 PASS / 2 FAIL / 0 BROKEN**. Both FAILs are the same measured
lane-tree geometry class (below), each with a complete three-leg record.

## The two geometry-class gate FAILs (raw evidence)

### `s9-parity` — FAIL, deterministic, zero lane attribution

- Command byte-verbatim (`rm -rf t72s9 && env -u …tui-split-rig run …
  s9_startup_help.yml --out t72s9`), exit 1, reproduced twice.
- `t72s9/summary.json`: both apps completed 1/1, requests 1/1;
  `candidates: ["- / for commands", "+md"]`, exit_code 1. The ONLY new
  unknown-candidate vs the recorded base/regime vector is `+md`.
- Mechanism (measured): tart's [Context] AGENTS.md row =
  tree(87 chars) + `/t72s9/run-1/sandbox/tart/AGENTS.md`(35) = **122 chars**
  against the 120-col pane (`GEOMETRY = %w[-x 120 -y 40]`) → the row wraps
  with a 2-char fragment `md`; the frozen registry class
  `staged-path-wrap-fragment` forgives only `^\s*\S+\.md$` — `md` is not
  `.md`-suffixed → unknown-candidate. pi's row (120 chars) fits unwrapped.
- Geometry arithmetic (the I68 digest's own s9 law): I68 tree 79 +
  `/tmp/i68s9/…`(39) = 118 ≤ 120 ✓ GREEN; I72 tree 87 + `/t72s9/…`(35) =
  122 ✗ — the frozen out-dir shortening (tmp/ dropped, −5) did not cover the
  tree growth (+8). The fragment is `.md`-suffixed (absorbed) iff row ≥ 123,
  i.e. **tree ≥ 88**; rows ≤ 120 (tree ≤ 85) do not wrap at all; **tree 86–87
  is the dead zone** (fragments `d` / `md`).
- Attribution: the row is a staged PATH rendered by motd.rb/formatDisplayPath
  and pi's word-wrap — none of which is in the lane's 5-path touch set; the
  lane diff (`markdown.rb`, tests) cannot move a path row's length. The
  Grounds' "s9 GREEN at the predicted 87-char geometry" scratch measurement
  is NOT reproducible at tree length exactly 87 — measured here
  deterministically twice.

### `herdr-wire-probe` — FAIL, deterministic, zero lane attribution

- Command byte-verbatim (`rm -rf t72hwp && env -u …
  herdr-wire-probe --out t72hwp`), exit 1, reproduced three times:
  `HERDR_WIRE_FAIL: no reports received … received 0 report(s)`.
- The pane boot is healthy: the staged session jsonl shows the user turn and
  the scripted mock reply landed (`"content":"ok"`, finish stop).
- Mechanism (measured): the probe's fake herdr socket path =
  tree(87) + `/t72hwp/herdr.sock` = **105 bytes**; macOS `sockaddr_un`
  accepts ≤ 104 → `UNIXServer.new` raises
  `ArgumentError: too long unix socket path (105bytes given but 104bytes
  max)` inside the probe's listener thread (silently rescued) → the listener
  never binds → 0 reports ever received. Reproduced standalone:
  `BIND FAIL` at the exact lane-tree path; `BIND OK` at a 100-byte path.
- At-base control, same machine, same command bytes, `repos/tart` @ `870e3f8`
  (78-char root → 96-byte socket path): **`HERDR_WIRE_OK`** with the exact
  5-report ladder — session(idle) → working → idle, seqs 1792294905866001–05
  (the Date.now()*1000 class), source=tart agent=tart, resume_argv
  `["tart", "-r", <session id>]` on every ref-carrying report. Rig bytes
  identical between the lane tree and base (`diff -r` clean).
- Attribution: zero — the socket path is constructed by the byte-frozen rig
  bin from the byte-frozen out dir; no lane-touched file participates. No
  frozen out dir fits at this tree (min socket path with a 1-char dir =
  100 bytes; the frozen 6-char dir gives 105): the gate as frozen is
  geometrically impossible at an 87-char lane tree; a re-freeze decision
  (shorter socket name in the rig, shorter out dir, or a shorter tree) is
  coordinator/judge territory.

## Deviations (itemized)

1. **The I68 cure's scan-resume overshoot is NOT emulated** (declared).
   The cure's outer scan resumes at an ARRAY INDEX (`ci_old + 1`) after
   closer splices shrank the array — when a closer-remnant call ends
   unmatched after ≥ 1 splice, the landing index overshoots by the total
   shrink (in the cure's per-CHARACTER token units) and up to S unscanned
   tokens are skipped from closer examination. That arithmetic is coupled to
   the per-char token granularity that AC4c itself mandates coalescing away
   ("plain-text runs coalesced"), so it has no clean analogue in the
   coalesced linked run. The lane's walk examines every token. Evidence:
   (a) all 48 battery cases + all 31 base pins + the 12 embedded
   flanking-repro assertions byte-identical; (b) 20 hand shapes identical to
   the preserved cure worktree; (c) a 2,000-case seeded adversarial fuzz
   (delimiter-dense atom salad): 74/2000 diverge from the preserved cure,
   and the pinned marked 18.0.11 oracle (pi's StrictStrikethroughTokenizer
   setup, hoisted node_modules) agrees with NEITHER implementation on the 51
   inline-comparable mismatch cases (0/51 both) — the divergence is
   invisible to the frozen gates and to the oracle-shape bar; (d) an
   overshoot-emulating variant (skip = total array-shrink, clamped at the
   sentinel) was built and fuzz-verified to 20 diffs before being rejected —
   its residual diffs trace to cure-unit/per-char bookkeeping that cannot be
   reproduced on coalesced nodes without reintroducing per-char emission.
2. **del_token probes via a StringScanner-anchored scan** (no `src[i..]`
   tail slice) under the `~~` pre-guard — semantics-equivalent to the cure's
   `STRICT_DEL.match(src[i..])` (verified: same matches on the battery,
   pins, 20 shapes, fuzz corpus); removes the per-attempt slice allocation.
3. **Failed-closer bookkeeping follows the reference openers-bottom law**
   (bound = the entry just below the failed closer; a closer that can no
   longer open leaves the stack) instead of the cure's degenerate nil-bound
   form. Result-neutral on the 2,000-case fuzz corpus: the overshoot-
   emulating variant with the cure's exact fail path produced the same
   residual diff set (20) as with the strong bound + pop — the two changes
   add zero additional divergences. (Proven sound: everything below the
   bound was examined by this or an earlier same-key walk — hit eligibility
   depends only on ch + can_open, both immutable.)
4. **code_token counts backtick runs without tail slices**
   (`m += 1 while src[i + m] == "\`"`) — equivalent to the cure's
   `src[i..][/\A\`+/]`.
5. `test/chat_test.rb` / `test/render/transcript_test.rb`: NOT touched —
   no frozen expectation moved (zero diff vs `870e3f8`, gate-verified by
   `scope`).
6. House style: commented citations at the touched seams carried from the
   cure diff; the file stays gem-neutral (name-scan pin green, the
   `test_converter_source_is_gem_neutral` pin among the 79).

## PHASE 0 record (plan + disagreements, before code)

- Plan: copy the fixture → re-derive the I68 cure from the preserved diff →
  weave the O(n) guard (pre-gated probes, O(1) closer bookkeeping, run
  coalescing) → land the battery tests → measure perf BEFORE claiming → run
  all 66 gates → report. Executed as planned.
- Disagreement 1 (Grounds' s9 scratch-tree claim): the Grounds state s9 was
  measured GREEN at the predicted 87-char lane geometry; at tree length
  exactly 87 the gate is deterministic-RED (mechanism above). This is a
  factual correction to the measurement claim, not a contract change — the
  gate stays frozen; the evidence is tabled for judge adjudication.
- Disagreement 2 (geometry coverage): the Grounds' lane-geometry section
  measured only the s9 form at the scratch tree; the herdr-wire-probe's
  unix-socket path was never geometry-checked at the lane tree and cannot
  fit at 87 chars as frozen. Same class, same handling.
- Disagreement 3 (overshoot): none with the contract as written — AC4c's
  bar is "the battery + every existing pin", which the law-faithful
  implementation satisfies byte-exactly; the overshoot is cure-internal
  mechanism (and incompatible with AC4c's coalescing mandate). Declared in
  deviation 1 above.

STATUS: COMPLETE_WITH_CONCERNS
- Concern 1: `s9-parity` FAIL at the lane tree — deterministic lane-tree
  geometry (122-char AGENTS.md row → non-`.md`-suffixed fragment `md`),
  zero lane attribution, three-leg evidence complete (cold ×2, base-state
  analysis, geometry law); needs judge adjudication or an out-dir/tree
  re-freeze (coordinator).
- Concern 2: `herdr-wire-probe` FAIL at the lane tree — deterministic
  geometry (105-byte unix-socket path > 104-byte sun_path; silent listener
  bind failure), zero lane attribution, three-leg evidence complete
  (cold ×3, at-base control GREEN with the identical command bytes, socket
  mechanism standalone-reproduced); needs judge adjudication or a re-freeze.
- Concern 3: deviation 1 (the scan-resume overshoot not emulated) —
  battery/pin/oracle-shape invisible, declared with fuzz evidence; the
  judge may rule it must be emulated, in which case the emulating variant
  exists but cannot reach exact cure-unit fidelity on coalesced nodes
  (structurally).

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
