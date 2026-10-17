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

### Objective

Close the three live-run correctness defects of plan ENTRY 1
(`notes/plan-20261017T005042Z-live-render-correctness.md`) — all three
render-layer, all three root-caused in Grounds (D1/D2/D3), none needing a
terminal to verify. Done bar: **BRIEF §8** exact parity on the owner's
daily-driver surface (**BRIEF §3**); this iteration is the correctness half —
ENTRY 2 (viewport polish) builds on this tip.

### The contract (one lane)

**D1 — the markdown emission cure** (`lib/tart/render/markdown.rb` ONLY).

- Both reject arms of `inline_spans` (the em `padded?` arm and the del
  `strict_strikethrough?` arm) change to: emit the delimiter character AT THE
  MATCH POSITION (`src[m.begin(0)]`) and advance the scan to
  `m.begin(0) + 1` — NEVER `src[pos]`, NEVER `pos + 1`. The pre-text is
  already emitted at the loop top (`src[pos...m.begin(0)]`); the remainder of
  a rejected match re-scans as ordinary text, so a later delimiter pair inside
  it still processes (accept or reject) normally.
- The accepted arms, `INLINE_SCAN`, `padded?`, `strict_strikethrough?`,
  `merge_adjacent`, `split_rows`, the block parser, the `FG` table, and every
  row composer (heading/quote/list/code/hr) are byte-frozen. The I06 flanking
  approximation STAYS a declared deviation — rejects still reject; they now
  render as literal text exactly once.
- Regression pins, names carrying the token `inline_scan`:
  - the minimal trigger `Markdown.rows("between zai/* and openrouter/z-ai-*);
    tail", width: 94)` renders passthrough-exact (one row, text == source);
  - a reject-with-pre-text case for BOTH families (em and del — match
    position > 0) asserting the exact literal spans (no duplicated prefix,
    no dropped chars);
  - a re-scan case (a rejected pair followed by an accepted pair in the same
    source) pinning the exact spans — the advance-past-the-delimiter
    semantics, never before the match, never by scan-start+1;
  - the owner's literal payload (new_problems.md's thinking text — at minimum
    the exploded items 5-6 slice carrying `zai/* and openrouter/z-ai-*`;
    the full text preferred) through BOTH seams — `Markdown.rows` AND
    `Transcript.reasoning_lines` — asserting the at-most-once cover property:
    every non-empty row's text is a substring of the source, rows appear in
    source order (each row's source-index window starts at-or-after the
    previous row's end), no source character rendered twice, and every row's
    display width fits the content width (readable wrapped rows, no
    explosion).
  - the existing at-position-0 literal pins (`~~ padded ~~`) pass unchanged.
  Test homes: `test/markdown_test.rb` (the converter pins) +
  `test/render/transcript_test.rb` (the `reasoning_lines` seam pins).

**D2 — the id-keyed pending registry** (`lib/tart/render/transcript.rb` +
the two arms in `lib/tart/render/chat.rb`).

- The single-slot `@pending_tool` becomes an id-keyed Hash registry. Seam
  contract (the frozen shape; deviations itemized):
  `enqueue_pending_tool_block(id, name, args)` — id FIRST (ToolCall member
  order) — registers the region under the call id, NO supersede (a second
  concurrent enqueue adds a second entry; pi `interactive-mode.ts`
  :3611-:3621);
  `finalize_tool_block(id, name, args, result, duration, details: nil)` —
  finalizes IN PLACE by call id through today's exact two paths
  (`replace_flushed_pending` for the flushed registration,
  `swap_queued_pending` for the still-queued region); an id MISS (or nil id —
  reader-less doubles) falls back to today's append (`enqueue_tool_block`) —
  the replay path, the post-reset finalize, and the unknown-id shape keep
  today's observable behavior (pi :3645-:3652);
  the drain links EVERY registry entry's flushed region to its registration
  by region identity (not just one slot);
  `finalize_pending_as_error(text)` loops EVERY live pending — each settles
  in place as the error block with today's exact bytes — then clears the
  registry (pi :3573-3586);
  `reset` clears the whole registry.
- The `chat.rb` arms (:569-:591) thread `call.id` into both calls; the
  reader-guard idiom for reader-less doubles is builder freedom (declared in
  the report either way). The `[name, args]` identity member dies with the
  slot.
- ROW COMPOSITION AND BOOKKEEPING ARITHMETIC FROZEN: `pending_tool_rows`,
  `tool_block_builder`, the per-family block rows, the I34 pending shapes,
  `replace_flushed_pending`/`swap_queued_pending` as-is — the registry
  replaces the slot's REGISTRATION bookkeeping only. The `PendingTool`
  struct may reshape or die; nothing observable may change for the
  single-call, sequential, error, replay, or reset paths.
- Unit pins, names carrying the token `pending_registry`
  (`test/render/transcript_test.rb`), driving the transcript state directly
  with start/end event pairs:
  - N=2 concurrent calls, BOTH completion orders (B-first and A-first): each
    call's block settles IN PLACE — exactly one block per call, the blocks
    stay in start order, zero `tool_pending_bg` rows survive, no appended
    duplicate;
  - an identical-name/identical-args pair with DISTINCT ids finalizes
    correctly in place (the discriminating case `[name, args]` equality
    could not solve);
  - `finalize_pending_as_error` over TWO live pendings settles BOTH in place
    as error blocks and clears the registry; the single-pending case keeps
    today's exact bytes;
  - reset clears the registry (post-reset finalize appends);
  - the id-miss finalize appends (the replay/unknown shape).
  Mechanical re-pins of the existing pending family to the id-carrying
  signature are part of the lane (itemized in the report);
  `test_second_pending_supersedes_and_the_stale_end_appends` is REPLACED by
  the registry behavior — the supersede WAS the defect (declared).
  `test/chat_test.rb`'s `ToolCallDouble`/`tool_start`/`tool_end` helpers
  gain the id (centralized — the call sites stay untouched).

**D3 — the footer context window** (`bin/tart` ONLY).

- `footer_data`'s context_window line gains the same fallback the other two
  call sites already carry: `Settings.resolve_context_window(settings:,
  model: chat.model, identity:) || Models.entry_context_window(entry)` —
  with `entry` hoisted once (the `resolve_boot_entry(models, boot)` the
  method already computes for `thinking_facts`, reused). All three boot
  call sites one shape (print :323-:326, loop kwarg :473-:476, footer
  :660) — the I59 D4 asymmetry closed.
- `models: nil` legacy calls (footer_data's optional shape) keep today's
  behavior: entry nil → window nil. Env-tier precedence unchanged (the
  resolve ladder runs FIRST; the fallback fires only when the whole ladder
  is nil). The `/model` switch overlay (`@runtime_model` reader +
  `apply_model_selection`) is untouched.
- Pin (`test/launcher_smoke_test.rb`, the `Executable.footer_data` staged
  shape): a staged catalog `zai/glm-5.3` with `contextWindow: 1_000_000` +
  the placeholder chat → `footer_data[:context_window] == 1_000_000` from
  the first frame (identical in value to the loop kwarg's expression —
  assert both in one test); a second leg with `PI_CONTEXT_WINDOW` set →
  the env value wins over the entry (precedence pinned).

### Named exclusions (Constraints, itemized)

- Repo tart ONLY; fast-llm untouched; no rig/oracle work — the iteration is
  unit-pinned (the pi-1.2.0 banner drift keeps the rig family out; the
  owner may re-pin `ORACLE_VERSION` separately, outside this plan).
- NO wire/tool/agent-layer changes: `lib/tart/tools/**`, `lib/tart/agent/**`,
  `lib/tart/models.rb`, `lib/tart/settings.rb`, `lib/tart/schemas/**`,
  `lib/tart/shapes/**`, `lib/tart/session*` untouched (scope-gated). No
  changes to wire-body or session golden digests — guarded by the carried
  `strict-wire`/`session-golden` gates + the suite.
- NO gem changes: Gemfile/Gemfile.lock/tart.gemspec untouched (0.4.0 pin
  stands); no new gems.
- Do NOT delete or move the MOTD/mark/version machinery or the I34
  pending-block row shapes.
- ENTRY 2's surface (viewport/scrollbar/jump-to-bottom;
  `render/viewport.rb`, the rail/mouse/widget-assembly family of chat.rb) is
  OUT — chat.rb edits are confined to the two tool-execution arms.
- No docs gates claimed (no tart docs exist for these surfaces).

### Output format

- Lane commit on `lane/I65-render-correctness-core` (provisioned from
  `project/pi-port` @ 1b83e05): the 8-file declared touch set, nothing else.
- Scratch report at `build/I65-render-correctness-core/report.md` (the
  builder's; transcribed verbatim by the architect).
- Test output: the suite summary line + the per-gate one-liners in the
  report; deviations itemized (any signature/shape deviation from this
  contract, every test re-pin enumerated).

### Tool guidance

- Verification (exact, tested this session):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1179 runs, 5591 assertions, 0 failures, 0 errors, 1 skips` at base
  (post-lane: >= 1179 runs, 0 failures, 0 errors);
  `bundle exec ruby bench/seam_bench.rb` → last line `SEAM_BENCH_OK`.
- The four defect gates (exact forms frozen in the AC):
  md-repro + footer-window (self-contained `ruby -Ilib` one-shots),
  md-inline-units + pending-registry-units (minitest name filters
  `/inline_scan/` and `/pending_registry/` — the token in the test NAMES is
  REQUIRED by the gates; both are 0-run at base).
- Probes (tart-only, cold-verified at base):
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
  -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/
  {render-perf-probe --app tart --shape gate,tool-pending-probe --gate,
  user-bash-stream-probe --gate}`.
- pi citations for the touched seams (house style — commented citations at
  the seam): interactive-mode.ts :3611-:3621, :3645-:3652, :3573-3586 (the
  pendingTools Map); footer.ts / the I59 boot-facts citations already at
  the three call sites.
- `BUNDLE_GEMFILE` may leak into the lane env — prefix suspect `architect`
  calls with `env -u BUNDLE_GEMFILE`.

### Boundaries

- May touch: exactly the declared 8 files (scope gate): `bin/tart`,
  `lib/tart/render/chat.rb`, `lib/tart/render/markdown.rb`,
  `lib/tart/render/transcript.rb`, `test/chat_test.rb`,
  `test/launcher_smoke_test.rb`, `test/markdown_test.rb`,
  `test/render/transcript_test.rb`.
- Must not touch: everything else — including `lib/tart/render/footer.rb`
  (the `?` is the DATA's fault, not the segment's), the viewport/rail
  family (ENTRY 2), and the frozen wire/session surfaces.
- Frozen stack: **BRIEF §2** (async/ratatui_ruby/fast-completions 0.4.0);
  house style per AGENTS/discipline: commented pi citations at the touched
  seams, tests through public interfaces, no refactors beyond the task.

### Lane plan

One lane — one flow, one commit, one test surface family.

```lanes
- name: core
  repo: tart
  touch:
    - bin/tart
    - lib/tart/render/chat.rb
    - lib/tart/render/markdown.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
    - test/launcher_smoke_test.rb
    - test/markdown_test.rb
    - test/render/transcript_test.rb
  effort: high
```

### Effort call

`high` — three distinct defect cures with frozen byte-disciplines on each
side (the markdown converter's accepted arms byte-frozen while the reject
arms' scan semantics change; the registry swap with the I34 row shapes and
both in-place paths held; the boot-facts one-liner against two frozen call
sites), a signature change rippling through an established 12-test family,
and owner-payload regression pins at two seams — not a routine lane.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: 21 gates — 17 carried/rebased from the
I64 standing battery (the unit-runnable members) + 4 new (the defect gates:
md-repro, md-inline-units, pending-registry-units, footer-window). Base =
tart `project/pi-port` @ `1b83e05` (tip, in sync); gem = fast-completions
**0.4.0 published** (pin-only Gemfile; NO `FAST_COMPLETIONS_PATH` export —
unlike I64; measured cold).

**Declared battery exclusions (itemized, per the plan's unit-pin ruling).**
The pi-1.2.0-vs-ORACLE-1.1.0 banner drift makes every rig-scenario gate exit
1 `unknown-candidate` — NOT carried as RED: `s1`–`s10`, `s1-tart-mode`,
`s17`, `s18`, `wire-delta`, `zai-max-tokens-wire` (all need the s1/pi rig
leg), and `live-script` (the I64-closed owner-run artifact). The wire-byte
freeze they would guard is covered here by `scope` + `strict-wire` +
`session-golden` + `suite` instead.

**Declared standing-gate rebases (commands byte-verbatim except these,
itemized):** `lock-deps` — pin greps `0.3.0`→`0.4.0` and the I64-era
`path: ENV.fetch(...)` Gemfile grep DROPPED (the 1b83e05 committed Gemfile
is pin-only; the owner's local path-branch is uncommitted and invisible to
lanes); `threads-budget` — base `195ae97`→`1b83e05`; `tool-pending-gate`
and `user-bash-stream-gate` — the `env -u HERDR_*` env-strip prefix added
(the house rig-gate idiom — the probes are pty-family; a no-op in clean
envs) and their `--out` dirs re-pointed at `tmp/i65-*`; `scope` —
rewritten for this lane's 8-file touch set (the I63/I64 diff-vs-base
form). `ac:` labels mapped to this iteration's ACs. Rehearsal #1 caught
and fixed ONE transcription drift vs the I64 frozen forms (the
`error-transcript-units` session floor — restored to `>= 2`) and the
carry audit re-verified every other leg byte-identical
(`tmp/i65-spec/audit-gates.rb`).

**The measured at-base vector (pre-declared; every member accounted,
scratch worktree @ 1b83e05, logs in space `tmp/i65-spec/`).** GREEN at
base: `suite` (1179 runs / 5591 assertions / **0 failures / 0 errors / 1
skip** — E-2 is REPAIRED at base, I64 D6's fold landed; the plan's "green
minus E-2" letter is superseded by this measurement), `bench`
(SEAM_BENCH_OK), `thinking-pins`, `hermeticity`, `lock-deps`, `zai-data`,
`threads-budget`, `session-golden`, `strict-wire`, `error-transcript-units`,
`error-transcript-render-units`, `render-perf-units`, `render-perf-probe`,
`tool-pending-gate`, `user-bash-stream-gate`, `zai-max-tokens-units`
(all measured or suite-covered cold), `scope` (vacuous — HEAD == base).
RED at base (the four defect gates, by construction): `md-repro` (measured:
42-byte source renders 120 bytes), `md-inline-units` (0 test names match
`/inline_scan/` — verified), `pending-registry-units` (0 match
`/pending_registry/` — verified), `footer-window` (measured:
`footer_data[:context_window]` nil against a 1_000_000-entry catalog — the
owner's `?`).

**Rehearsal-vs-judge checkout note (env-class, pre-declared).** The
canonical `repos/tart` checkout carries the owner's standing uncommitted
diff (6 files: the Gemfile path-branch, its lock checksum drop,
`lib/tart/subagents/manager.rb`, 3 test files — plan standing context:
intentional, LEAVE). Rehearsal runs there: `scope` reads those 6 files as
out-of-scope NOISE at rehearsal time (the owner's files, never the lane's);
every other gate is unaffected (the diff is inert without
`FAST_COMPLETIONS_PATH`; the owner's modified tests pass in-checkout —
31/0F measured). The judge runs the frozen battery at the LANE tree (cut
from the committed branch, no owner diff): `scope` bites there exactly.

**AC1 — the markdown emission cure (D1).** Through `Render::Markdown.rows`,
no input renders any source character more than once: a rejected em/del
match emits the delimiter character AT THE MATCH POSITION once and advances
the scan to exactly `m.begin(0) + 1` (never before the match, never
scan-start+1); the pre-text stays emitted exactly once at the loop top; the
remainder re-scans (later pairs still process). The minimal trigger
`"between zai/* and openrouter/z-ai-*); tail"` renders passthrough-exact at
`width: 94`; the owner's literal payload (new_problems.md's thinking text)
renders as readable wrapped rows (every row a source substring, in source
order, no row exceeding the content width) through BOTH the
`Markdown.rows` and `Transcript.reasoning_lines` seams — pinned in tests
carrying the `inline_scan` token (>=3 in markdown_test, >=1 in
transcript_test). Everything else in the converter is byte-frozen: the
accepted arms, `INLINE_SCAN`, `padded?`, `strict_strikethrough?`, the
block parser, the FG table, all row composers — the existing 25 markdown
pins and every markdown/wire/session golden pass UNCHANGED (the I06
flanking-approximation deviation stays: rejects still reject, now
rendering literally exactly once). Gates: `md-repro`, `md-inline-units`,
`suite`.

**AC2 — the id-keyed pending registry (D2).** N concurrent tool calls
completing in ANY order each finalize IN PLACE: the grey pending rows are
replaced by the settled rows, exactly one block per call, blocks stay in
start order, zero `tool_pending_bg` rows survive, no appended duplicate —
the registry keyed by the call ID (both events already carry the full
`ToolCall` object, `agent/message.rb:12`), finalize by id through today's
exact `replace_flushed_pending`/`swap_queued_pending` paths. Identical-name
+ identical-args parallel calls with distinct ids finalize correctly (the
case `[name, args]` equality cannot discriminate). The id-miss finalize
keeps today's append fallback (replay, post-reset, unknown ids);
`finalize_pending_as_error` settles EVERY live pending in place as the
error block (today's exact bytes per block) and clears the registry; the
abort/error arms and the replay path behave exactly as today for every
shape that works today. The I34 pending ROW composition and the
replace/swap arithmetic are UNCHANGED (the registry replaces the single
slot's bookkeeping only — the `tool-pending-gate` rig probe and the
existing flushed/queued settle controls stay green, mechanically re-pinned
to the id-carrying signature; the supersede-pinning test is REPLACED —
declared). Pinned in tests carrying the `pending_registry` token (>=4),
driving the transcript state directly with start/end pairs in BOTH
completion orders. Gates: `pending-registry-units`, `tool-pending-gate`,
`error-transcript-render-units`, `suite`.

**AC3 — the footer context window (D3).** The interactive footer renders
the boot catalog entry's window from the FIRST frame: `footer_data`'s
context_window carries `Settings.resolve_context_window(...) ||
Models.entry_context_window(entry)` — the same shape the loop kwarg and
the print boot already have (the I59 D4 asymmetry closed; all three call
sites one shape). For a staged `zai/glm-5.3` catalog entry declaring
`contextWindow: 1_000_000`, `footer_data[:context_window] == 1_000_000`
with the placeholder chat, identical in value to the loop kwarg's
expression (one measurement, both asserted); the footer segment renders
pi's `format_tokens` form (footer.rb:201-213 — unchanged, it was never the
defect). The env tier (`PI_CONTEXT_WINDOW`, identity-namespaced) still
wins over the entry; the `models: nil` legacy call keeps window nil; the
`/model` switch overlay is untouched. A launcher/boot test pins the
interactive arm (staged catalog + env-precedence legs). Gates:
`footer-window`, `hermeticity`, `suite`.

**AC4 — the byte-freeze discipline (scope).** Exactly the declared 8-file
touch set changes vs `1b83e05`: `bin/tart`,
`lib/tart/render/{markdown,transcript,chat}.rb`,
`test/{markdown_test,chat_test,launcher_smoke_test}.rb`,
`test/render/transcript_test.rb` — NOTHING else (no Gemfile/lock/gemspec,
no tools/agent/models/settings/schemas/shapes/session bytes, no
viewport/rail/ENTRY-2 surface, no rig files). The wire and session bytes
hold EXACT: the four strict tool-schema rewrites + their digests
(`strict-wire`), the session-golden digests (`session-golden`), the
thinking wire pins (`thinking-pins`), the zai dialect data (`zai-data`),
the gem pin/load (`lock-deps`), no new `Thread.new` in lib
(`threads-budget`), the render-perf budgets (`render-perf-units`,
`render-perf-probe`), the user-bash stream gate, and the zai-max-tokens
boot pins — all green at the lane tree. Gates: `scope`, `strict-wire`,
`session-golden`, `thinking-pins`, `lock-deps`, `zai-data`,
`threads-budget`, `render-perf-units`, `render-perf-probe`,
`user-bash-stream-gate`, `zai-max-tokens-units`.

**AC5 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — >= 1179 runs, 0
failures, 0 errors (the standing 1 rig skip unchanged) — and
`bundle exec ruby bench/seam_bench.rb` prints `SEAM_BENCH_OK`. Judge env
note (I59/I64 standing class): the three launcher/SystemPrompt pins inside
`suite` are environment-dependent (pinned-oracle PATH + unset PI_*) — if
present in the judge's env they adjudicate env-class, exactly as standing.
Gates: `suite`, `bench` (+ every AC4 member cold).

```gates
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: md-repro
  ac: AC1
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
  ac: AC1
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
  ac: AC2
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
  ac: AC3
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
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
      ENV["PI_CONTEXT_WINDOW"] = "999"
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
    grep -qF 'gem "fast-completions", "0.4.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.4\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
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
    added=$(git diff 1b83e05 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]* runs, .* 0 failures, 0 errors"
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
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
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
  ac: AC2
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i65-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i65-ubs
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

- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    git diff --quiet 1b83e05 -- Gemfile Gemfile.lock tart.gemspec lib/tart/agent lib/tart/tools lib/tart/models.rb lib/tart/settings.rb lib/tart/schemas lib/tart/shapes lib/tart/mcp lib/tart/subagents lib/tart/hooks.rb lib/tart/theme.rb bench gems && ! git diff --name-only 1b83e05 | grep -vE "^(bin/tart|lib/tart/render/(markdown|transcript|chat)\.rb|test/(markdown_test|chat_test|launcher_smoke_test)\.rb|test/render/transcript_test\.rb)$" | grep -q . && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
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
