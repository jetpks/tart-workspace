# I65: render-correctness

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T005042Z-live-render-correctness.md` ENTRY 1 (this
  iteration), standing context block. Done bar: **BRIEF §8** exact parity ("pi in
  one tab, tart in another, indistinguishable"); **BRIEF §3** the daily-driver
  scope. Owner findings: `new_problems.md` (committed a97a8dd) + `problems.md`
  `### friday october 16, 2026 18:18 mdt`.
- **Base = tart `project/pi-port` @ `1b83e05`** ("use fast-completions
  v0.4.0" — tip, in sync with origin). fast-completions **0.4.0** is published
  and installed; the committed Gemfile is pin-only (`gem "fast-completions",
  "0.4.0"`, :12) — NO path branch, NO `FAST_COMPLETIONS_PATH` export needed
  (unlike I64; measured cold: `bundle install` resolves from rubygems). fast-llm
  `main` holds an unpushed/untagged 0.4.1 fix — OWNER work, outside this plan.
- **The canonical checkout carries an intentional owner-local uncommitted
  diff** (Gemfile FAST_COMPLETIONS_PATH path-branch + the lock's checksum drop
  + `lib/tart/subagents/manager.rb` + 3 test files). Left untouched by this
  session; provisioned lanes are cut from the committed branch and never see
  it. The owner's modified tests pass in-checkout (measured: subagents ×2 +
  e2e_session 31 runs / 0F cold).
- **Measured base suite** (scratch worktree @ 1b83e05, published gem, no
  FAST_COMPLETIONS_PATH): **1179 runs / 5591 assertions / 0 failures / 0
  errors / 1 skip, rake exit 0.** The plan's "green minus E-2" letter is
  SUPERSEDED by measurement: I64 D6's E-2 registry sanction fold LANDED
  (7c00d29) — the suite is fully green at base. The standing 1 skip is
  `TuiSplitRig::LiveRunTest#test_s1_end_to_end_against_installed_pi_and_this_tart`
  (rig class). Logs: space `tmp/i65-spec/base-suite.log`.
- **Measured base, cold**: `bench/seam_bench.rb` → `SEAM_BENCH_OK`;
  `render-perf-probe --app tart --shape gate` → `RENDER_PERF_OK`;
  `tool-pending-probe --gate` → `TOOL_PENDING_GATE_OK`;
  `user-bash-stream-probe --gate` → `USER_BASH_STREAM_GATE_OK` (all three
  tart-only — no pi oracle needed).
- **pi oracle drift standing**: installed pi is 1.2.0 while
  `Identity::ORACLE_VERSION` pins 1.1.0 — every rig scenario family gate
  (s1–s10, s1-tart-mode, s17, s18; wire-delta's and zai-max-tokens-wire's s1
  legs) exits 1 `unknown-candidate`. Per the plan's standing context BOTH
  entries are UNIT-PINNED: those gates are EXCLUDED from this battery
  (itemized in the AC preamble), not carried-as-RED.
- Prior handoff: `notes/spec-digest-20261016T002403Z.md` (verification
  discipline, base-suite protocol, kit assembly shape, lane-level
  integration_branch check at provision).

### D1 — the markdown inline-scan explosion (the screen-destroyer)

Owner finding: `new_problems.md` "rendering weirdness" (the garbled
"we somehow completely screwed up this content" render — the repeated-prefix
artifact quoted verbatim there).

- **Root cause, verified in source** (`lib/tart/render/markdown.rb`
  `inline_spans`, :258-:310): when an em or del match is REJECTED as literal —
  the em arm's `padded?` flanking approximation (:282-:286) or the del arm's
  `strict_strikethrough?` (:291-296) — both reject arms do
  `spans << span(src[pos], …); consumed = pos + 1`. But `pos` is the SCAN
  START while the regex match began at `m.begin(0)` (≥ pos, possibly far
  ahead), and the pre-text `src[pos...m.begin(0)]` was ALREADY emitted at the
  loop top (:266-267). Every loop iteration re-emits the ENTIRE pre-match
  prefix minus one character → quadratic text explosion. Both reject arms are
  identical in the defect.
- **Reproduced deterministically this session, no terminal involved** (scratch
  worktree @ 1b83e05): `Markdown.rows("between zai/* and openrouter/z-ai-*);
  tail", width: 94)` — a **42-byte source renders 120 bytes**
  ("between zai/between zai/etween zai/tween zai/…"), exactly the owner's
  artifact class. The del arm measured identically (`"a ~~ padded ~~ b * and
  *"` explodes). Trigger: ANY rejected em/del pair with non-empty pre-text —
  the owner payload's `zai/* and openrouter/z-ai-*` matches em
  (`\*[^*\n]+\*`, inner ` and openrouter/z-ai-` starts with a space → reject).
  A reject at match-position 0 renders correctly today and stays correct
  (existing pin `test/markdown_test.rb:64-66` `~~ padded ~~`).
- **Blast radius**: EVERY markdown path — live reasoning
  (`Transcript.reasoning_lines`), live content/completion, replay, custom
  blocks — all flow through `Render::Markdown.rows` (transcript.rb :494
  `markdown_lines`).
- pi context: the flanking approximation itself is the I06 itemized deviation
  (delimiter-flanking rules approximated by the no-padded-content check) —
  UNCHANGED by this fix. The fix cures the EMISSION on reject, not the
  approximation: rejected delimiters render as literal text, once.

### D2 — orphaned parallel tool-call blocks

Owner finding: `new_problems.md` "parallel tool calls that finish out of
order get orphaned" (grey block stays grey forever; a NEW green box appears).

- **Root cause, verified in source** (`lib/tart/render/transcript.rb`): a
  SINGLE-slot `@pending_tool` (the `PendingTool` Struct :52 — its own comment
  admits "the executor runs the batch concurrently on the reactor");
  `enqueue_pending_tool_block` (:245-:251) SUPERSEDES the slot on every
  enqueue; `finalize_tool_block` (:263-:277) matches by `[name, args]`
  EQUALITY against the one slot, falling back to APPEND on mismatch; the
  drain (:371-:374) links a flushed region to the CURRENT slot only
  (`@pending_tool&.region&.equal?(item)`); `finalize_pending_as_error`
  (:287-:292) settles the single slot only; `reset` (:451-:455) nils it.
  Under a parallel batch, the superseded call's pending region is orphaned:
  its end event mismatches (or the slot is empty) → append → a second block.
- **Reproduced this session** (scratch worktree, transcript driven directly):
  two bash calls enqueued (A `sleep 3`, B `echo hi`), B's end first → B
  settles in place; A's end then appends — measured: `$ sleep 3` renders
  TWICE, 3 tool-pending-bg rows survive forever. Exactly the owner's report.
- **The id is already on the wire of the seam**: `ToolCall = Struct.new(:id,
  :name, :arguments, :details)` (`lib/tart/agent/message.rb:12`); BOTH events
  carry the full tool_call object (`render/chat.rb` :569-:577 start arm,
  :579-:591 end arm; `agent/loop.rb` :925-:935 `install_chat_callbacks`
  closes over the call). Only the transcript's signatures drop the id.
- **pi parity shape** (installed dist = oracle 1.1.0 family, cited in the file
  headers): `pendingTools` is a Map KEYED BY `toolCallId` —
  `interactive-mode.ts` :3611-3621 (a component per call at
  `:tool_execution_start`), :3645-:3652 (`:tool_execution_end` gets by id,
  `updateResult` mutates the SAME component in place, delete), :3573-3586
  (the abort/error arm LOOPS every pending with `updateResult({content:
  [errorMessage], isError: true})`, then clears).
- **Frozen discipline**: the I34 pending ROW COMPOSITION
  (`pending_tool_rows` :802-:810, the per-family call shapes, the
  replace/swap arithmetic :830-:863) is byte-frozen — the registry replaces
  the slot's BOOKKEEPING, never the rows. The I34 rig gate
  (`tool-pending-probe`) is carried in this battery to hold it.
- **Existing test surface** (all re-pinned mechanically — the signature gains
  the id): `test/render/transcript_test.rb` pending family (:42-:244 — 12
  tests incl. the flushed/queued settle controls, the delta threading, the
  generic drop, the orphan-error, the no-pending append, the reset);
  `test/chat_test.rb` `ToolCallDouble` (:5809, `Struct.new(:name,
  :arguments)`) + the `tool_start`/`tool_end` helpers (:5575-:5583).
  ONE test pins the defect itself —
  `test_second_pending_supersedes_and_the_stale_end_appends` (:216-:231,
  "the superseded block rides on (the documented caveat)") — REPLACED by the
  registry behavior (declared; the caveat was the defect).

### D3 — the footer context window `?`

Owner finding: `new_problems.md` "model context window still missing" (the
`?` in `↑57k ↓6.7k R238k CH97.7% ?` on `zai/glm-5.3`).

- **Root cause, verified in source** (`bin/tart`): the interactive boot
  snapshots `footer_data` at :457 (`facts = footer_data(workdir, settings,
  boot:, chat:, identity:, models:, resolved:)`) BEFORE `Agent::Loop.new`
  (:464), while `chat.model` is still the placeholder `ModelFacts` (nil
  window — `agent/chat.rb` :32-:33, :175). The `footer_data` method
  (:649-:677) sets `context_window: Settings.resolve_context_window(
  settings:, model: chat.model, identity:)` WITHOUT the `||
  Models.entry_context_window(entry)` fallback that the LOOP kwarg (:473-:476)
  and the PRINT boot (:323-:326) both carry — the **I59 D4 asymmetry**, the
  one call site left behind.
- **Reproduced this session** (scratch worktree, staged catalog
  `zai/glm-5.3` with `contextWindow: 1_000_000`): `footer_data[:
  context_window]` = **nil** → `Footer#context_segment` (`render/footer.rb`
  :201-:213) renders **"?"** (measured); the loop-kwarg expression resolves
  **1_000_000** in the same run — the asymmetry in one measurement.
- **The fix's neighbors are already correct**: `Models.entry_context_window`
  (`models.rb` :129-:133 — the entry's declared window, 128_000 definition
  default when an entry exists, nil without one); `Settings.
  resolve_context_window` (`settings.rb` :176-:189 — explicit > env tier
  (`PI_CONTEXT_WINDOW`, identity-namespaced) > settings > model > known
  tables; the `|| entry` fallback fires only when the whole ladder is nil —
  env precedence is untouched by construction). The `/model` switch overlay
  does NOT flow through the launcher's `footer_data` (chat.rb :1922-:1933
  the reader overlays `@runtime_model.context_window`; :2236-:2273
  `apply_model_selection`) — out of the fix's path, unchanged.
- footer_data already receives `models:`/`boot:`/`resolved:` — the entry is
  resolvable INSIDE the method (it already computes
  `resolve_boot_entry(models, boot)` for `thinking_facts`, :662).

### Environment facts the lane inherits

- Verification gate (tart): `bundle install --quiet && bundle exec rake`
  (minitest, `test/**/*_test.rb` + `gems/tui-split-rig/test/**/*_test.rb`) +
  `bundle exec ruby bench/seam_bench.rb` (prints SEAM_BENCH_OK).
- `BUNDLE_GEMFILE` leaks from tart/bundler contexts and kills bare
  `architect` calls — run as `env -u BUNDLE_GEMFILE architect …`.
- Rig-family gates (when carried) need the HERDR_* env-strip prefix; the
  tart-only probes (render-perf-probe, tool-pending-probe,
  user-bash-stream-probe) need it too and pass cold at base.
- Provision: tart lanes target integration_branch `project/pi-port` — verify
  the LANE-level field at provision (the I50/I52 fast-llm nil-class; tart has
  resolved correctly via slug fallback historically).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section render-correctness specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision render-correctness`
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
`architect rehearse render-correctness` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze render-correctness` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse render-correctness` — before the freeze, while
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
subsection per lane. A copy is written to build/I65-render-correctness-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section render-correctness prompt --append --lane <lane> --from build/I65-render-correctness-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I65-render-correctness-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence render-correctness --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section render-correctness verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify render-correctness`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
