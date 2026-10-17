# I68: markdown-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T081509Z-markdown-parity.md` ENTRY 1 (this
  iteration; ENTRY 2 `child-env-scrub` is a SEPARATE iteration — not
  spec'd here). Done bar: **BRIEF §8** as refined by the owner's
  2026-10-17 ruling (plan standing context): **parity is VISUAL in the
  interface, not implementation-exact** — port observable distinctions
  (text content + fg/modifier distinctions), never mechanism.
- **Owner rulings in force (2026-10-17, plan standing context):** (1) the
  hand-rolled markdown converter STAYS — no markdown dependency, ever
  (deps budget + gem-neutrality); fixes port marked's observable
  behavior into the existing parser. (2) The owner's live finding —
  underscores eaten in thinking text plus "a ton of issues" across live
  conversation rendering — is the SECOND live finding against the I06
  flanking approximation (I65's D1 reject-emission explosion was the
  first); per the I37 precedent it RETIRES the sanctioned deviation.
  The I06 deviation log in `lib/tart/render/markdown.rb`'s header names
  the now-retired items: flanking "approximated by a no-padded-content
  check", "intraword `__` emphasis is allowed".
- **Base = tart `project/pi-port` @ `3845f6a`** (tip, clean tree, in
  sync with origin — measured `git status` empty). **Measured base
  suite this session** (canonical checkout): **1211 runs / 5911
  assertions / 0 failures / 0 errors / 1 skip, rake exit 0** (the
  standing rig live-run skip; identical to the I67 post-landing record
  — the 0.5.0 pin moved nothing) + `bench/seam_bench.rb` →
  `SEAM_BENCH_OK`. `test/markdown_test.rb` alone: **31 runs / 102
  assertions / 0F / 0E** (the regression floor; the battery grows it).
  fast-completions **0.5.0** published/pinned (Gemfile :11
  `gem "fast-completions", "0.5.0"`; lock `fast-completions (0.5.0)`).
- **The oracle** (BRIEF §8 instrument): the pinned `repos/pi` clone @
  tag v1.1.0 (branch `oracle-v1.1.0`, GUARDED by the standing
  `oracle-pin-state` gate — never re-performed from a lane), marked
  **18.0.11** (the tui package.json pin) at `repos/pi/node_modules/marked`
  — **hoisted to the repo root, NOT `packages/tui/node_modules`** (the
  plan letter's path was wrong; probe from `repos/pi/packages/tui` so
  node's parent walk resolves it, or `NODE_PATH=<pi-root>/node_modules`).
  The frozen capture methodology (this session, all scratch under
  `tmp/i68-spec/`): `capture.js` replicates pi's parser setup EXACTLY
  (a fresh `Marked` + `setOptions({tokenizer: new
  StrictStrikethroughTokenizer()})` — markdown.ts :173-176; the latex
  extensions (markdown.ts :181-194) are OMITTED because the frozen
  battery contains no `$`/`\(`/`\[` bytes — measured irrelevant), walks
  the token tree to per-case **observable distinctions** (segments
  `[role, text]` per inline container + compact block facts + HTML for
  eyeball), all 48 cases captured in `tmp/i68-spec/oracle.json` (marked
  18.0.11 verified in the output).

### The measured divergence ledger (base @ 3845f6a, every case measured)

Battery = 48 real-world cases (`tmp/i68-spec/cases.json`; base-side
comparison `tmp/i68-spec/ledger.txt`). **11 designed-RED at base — the
cure's work list; 37 GREEN — regression coverage the cure must not
break.**

**Delimiter law family (the owner's headline):**

- **R1 — `_` intraword em.** The em arm `_[^_\n]+_` pairs ANY two
  underscores on a line. Owner's headline, measured:
  `checking some_var_name and then other_value next` → tart
  "checking some" + ITALIC "var" + "name and then other_value next"
  (underscores EATEN); oracle: the whole line literal. Same class
  measured for `multi_snake_identifiers`
  (`file_name_2_test.rb and other_name_here too`) and
  `underscore_pair_in_parens` (`call (x_y) then (p_q) now` → tart
  italicizes "y) then (p"). CommonMark/marked law: a `_` delimiter run
  can OPEN emphasis only if left-flanking AND (not right-flanking OR
  preceded by punctuation) — an opener directly preceded by an
  alphanumeric can NEVER open. `A _real_ emphasis case` stays em
  (GREEN at base — the law must keep it).
- **R2 — `_` intraword strong.** The strong arm `__.+?__` has NO
  flanking check at all (the I06 "intraword `__` is allowed" sanction,
  now retired). Measured: `foo__bar__baz` → tart strong("bar"); oracle
  literal. Same for `a__bold__b`. `The __quick__ brown fox` stays
  strong (GREEN — keep).
- **R3 — `*`-strong flanking.** `** padded ** stays literal` → tart
  strong(" padded "); oracle literal (a `**` opener followed by
  whitespace is not left-flanking → cannot open). The em arm's
  `padded?` check was always a crude approximation of exactly this
  left/right-flanking rule; the strong arm got nothing.
- **R4 — nested em must span `*`.** `*em **inner** em*` → tart renders
  the outer delimiters literal and inner strong bare ("*em " + bold
  "inner" + " em*"); oracle: em wrapping strong. The em arm's content
  class `[^*\n]+` cannot cross an inner `*` delimiter. The `**bold
  *inner* bold**` (strong spanning `*`) and `**bold _inner_ bold**`
  cases are GREEN at base — keep.
- **R5 — escape arm punctuation law.** `back \to *em* now` → tart EATS
  the backslash ("back to *em* now"); oracle keeps it literal
  (`\` before a non-punctuation is literal text). The escape arm
  `\\.` must only consume backslash + ASCII punctuation
  (CommonMark's escapable set); `\*not em\*` / `\_a\_` /
  `x \\ y` are GREEN at base — keep.
- **R6 — link URLs with balanced parens.** `[wiki](https://en.wikipedia.org/wiki/Foo_(bar))`
  → tart's link arm `\([^)\n]+\)` stops at the URL's internal `)`: the
  gray URL span renders one `)` short and the stray `)` renders
  default-fg (span-boundary divergence — joined text identical, the
  fg distinction on ONE character differs). Oracle: marked carries
  balanced parens in the destination; the full URL rides the gray
  link_url span. All other link edges are GREEN at base (text==href,
  punctuation URLs, mailto stripping, bold-in-link-text) — keep.

**Block family:**

- **R7 — indented fence body dedent.** "  ```"-indented fence: marked
  strips the opening fence's indent (up to 3 spaces) from body lines;
  tart keeps them ("  indented body" vs "indented body"). Non-indented,
  tilde, lang-tagged, and unclosed fences are GREEN at base — keep.
- **R8 — task-list markers.** `- [x] done` / `- [ ] todo`: marked sets
  item.task/checked; pi's renderList folds `[x] `/`[ ] ` INTO the
  listBullet-styled marker (markdown.ts `taskMarker` — the marker span
  is `"- [x] "` violet). tart renders them as default-fg item text —
  an fg distinction. Paren-ordered lists (`1)` → normalized `1. `),
  nested ordered-in-unordered, list-in-quote, and code-in-list are
  GREEN at base — keep.

**Not in the battery (itemized exclusions, all declared):** tables (pi
renders a full bordered table — markdown.ts renderTable; the converter
has NO table support and porting it is a lane of its own, outside the
plan's frozen battery letter — owner backlog candidate), setext
headings, autolinks `<https://…>`, images, OSC-8 hyperlinks (standing
I06 exclusion), latex rendering (pi's $…$ → unicode; outside the plan
letter — the battery contains no `$`/`\(`/`\[` bytes by design),
paragraph soft breaks (already row-per-line parity, GREEN). The
nested-strong-inside-heading duplicate `:bold` modifier (mods
`[bold, bold]`, heading_inline_bold) is VISUALLY IDEMPOTENT — NOT a
battery RED under set-compare semantics; optional span-hygiene for the
builder, never a gate.

### The frozen fixture (spec-authored, builder copies VERBATIM)

`tmp/i68-spec/markdown_battery.json` (scratch) → lands VERBATIM at
`tart test/fixtures/markdown_battery.json` — 48 cases, each `{name,
src, rows}`; a row is an array of spans `[text, fg, modifiers]`
(fg a FG-symbol name or null = terminal default; zero-width spans
dropped; **modifiers compare as a SET**; an empty row is a blank
line), rendered at `width: 94` (the I65 reasoning-width convention).
36 of 48 expect rows are tart's MEASURED base spans (verified equal to
the oracle distinctions); 11 are frozen from the oracle captures (the
post-cure bar, R1–R8 above). **sha256
`4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883`**
(22,070 bytes) — the `md-battery-fixture` gate pins this sha; the
builder NEVER regenerates it.

### Environment / ops facts (measured this session)

- **The owner-state swap precondition does NOT arise at this tip**:
  `repos/tart` is CLEAN at `3845f6a` (the I65/I66/I67-era
  stripped-checksum Gemfile.lock owner diff is gone — the 0.5.0 pin
  landed committed; `bundle install` boots canonical tart panes,
  measured). The swap protocol still applies to ANY canonical-site run
  if an owner diff appears (snapshot → checkout committed → run → cp
  back → verify diff sha + status equality).
- **Judge venue:** the LANE tree (standing rule). Lane-tree geometry:
  `build/I68-markdown-parity-core/wt` = 79 chars; frozen scenario out
  dirs `tmp/i68s1`…`tmp/i68s10`, `tmp/i68s17`, `tmp/i68s1t`,
  `tmp/i68wire`, `tmp/i68zwire` (≤ 8 chars) keep the s9 AGENTS.md
  context row at **119 ≤ 120** at the lane tree (tart's
  `wrap_resource_row` fires at >120; I67 precedent: row exactly 120
  was GREEN, 122 wrapped) and every pane cwd line under the 120-col
  `run-<n>/` anchor.
- **Carried-gate corrections (judge-adjudicated, I67 Verdict):**
  (1) the I67 `wire-delta` tools-sha constant `…758331…` was a
  stale-source transcription — corrected to
  `7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707`
  (I64's recorded "EXACT (raw)" measurement; triple-verified in the I67
  verdict). (2) the s9 gate out dir rebased to the ≤ 7-char form (the
  I67 verdict's own fix; here `tmp/i68s9`, row 119). The instruction
  sha `4209f40b…` carries unchanged (lib/tart untouched by 3845f6a;
  rehearsal re-verifies).
- Direct oracle execs: `env -u PI_PACKAGE_DIR node <cli.js>` (the env
  var overrides pi's package-dir walk); marked probes from
  `repos/pi/packages/tui`. `BUNDLE_GEMFILE`/bundler context may leak
  from parent sessions — prefix suspect `architect` calls with the
  FULL scrub (`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u
  BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION`).
- Both render call paths consume the ONE converter — parity applies to
  both without call-site changes: `transcript.rb` ({markdown_lines}
  :491, {reasoning_lines} :536) and `chat.rb` :2068-:2124 (cited at
  the seams; neither file is in the touch set).

### Prior handoffs

`notes/spec-digest-20261017T050053Z.md` (I67 — the pin/oracle
conventions, short out dirs, judge-at-lane-tree, kit assembly, the
2026-10-17 division-of-labor CORRECTION: the spec session never
provisions and never dispatches — the coordinator owns lanes and
launches).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section markdown-parity specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision markdown-parity`
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
`architect rehearse markdown-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze markdown-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse markdown-parity` — before the freeze, while
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
subsection per lane. A copy is written to build/I68-markdown-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section markdown-parity prompt --append --lane <lane> --from build/I68-markdown-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I68-markdown-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence markdown-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section markdown-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify markdown-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
