# I31: compaction-residuals

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I31 compaction-residuals

Measured this session (2026-10-12, the I30 judging session) at base **276eda3d**
(= `project/pi-port` tip after I30; the integrated tree with panel + rebuild +
agent seams landed). All captures below are this session's cold gate runs under
`repos/tart/tmp/parity-gate-s7` and `tmp/parity-gate-s8`.

1. **The s7 failure is exactly one 7-row vertical shift.** The integrated s7
   captures: pi's settled screen retains its header rows 2–8 (MOTD art
   `▀▀█ v1.1.0`, the two startup-help lines, blank, `Pi can explain…`, two
   blanks) then the kept entry (`first turn reply…`) at row 9 and the panel at
   12–14; tart's settled screen has the SAME content rows (kept entry, blank
   pair, `[compaction]`, blank, `Compacted from 15 tokens (ctrl+o to expand)`)
   starting at row 2 — byte-identical content, shifted up 7. The rig diff: 14x
   unknown-candidate = 7 pi-side header rows + 7 tart-side trailing blanks;
   2x parity-run-path + 2x footer-provider-prefix (sanctioned); **style
   differences: none**. The panel bytes and the kept-entry replay are proven —
   the only defect is the MOTD wipe.

2. **Why the wipe was wrong (the I30 Grounds-3 authoring defect).** pi's
   `compaction_end` (interactive-mode.ts:3686-3725) calls `chatContainer.clear()`
   — the CHAT container only. pi's MOTD header lives in a separate container
   above it that compaction never touches: the header persists byte-for-byte
   through compaction (the capture is the oracle). I30's Grounds 3 conflated
   tart's `[Context]` candidate with the whole MOTD and mandated wiping both.
   The correct port behavior: the rebuild leaves the header rows on screen
   (preserve the region through the clear, or re-render it — the builder
   verifies which is faithful; the AC is the settled bytes).

3. **The `[Context]` trap.** The port's MOTD `[Context]` section (motd.rb:117,
   :133) is a port-only inline listing of loaded resource files — pi shows
   loaded resources only in the ctrl+o expanded startup help, never in its
   settled header. The registry's `staged-settings-path` class covers the path
   fragments and its comment says "the [Context] heading itself stays a
   candidate (a real port-only listing, left on the work list)". I30's wipe
   already removed it from the settled screen (matching pi); the header fix
   must NOT resurrect it — the header that survives the rebuild is pi's header
   shape (art + help + `Pi can explain…`), not the port's full MOTD block with
   its resource listings. The long-term home for the listings is the queued
   "header startup-help flip" backlog item (loaded resources under ctrl+o,
   pi's shape) — NOT this iteration.

4. **The s8 `tokens_before` divergence decomposes into a fixable defect plus a
   sanctioned residue (this session's measurements).** s8 suppresses usage, so
   both apps fall to the chars/4 Case-3 estimate over their own message
   history. Measured from the run artifacts:
   - **tart = 67, exactly**: `estimate_tokens` (compaction.rb:248) counts
     message TEXT only — developer prompt 203 + user 13 + assistant reply 45
     chars, ceil per message → 51+4+12 = 67.
   - **pi = 1,482**: `estimateTokens` (pi compaction.ts:296-311) counts the
     system message's content + **`system.sections`** + **`system.toolsAdded`
     (the JSON of the tool definitions)** — 2,930 content + 2,841 tool JSON +
     13 user chars, /4 with per-message ceilings ≈ 1,482. pi's estimate is an
     honest measurement of its real wire request (5,783 chars ≈ 1,445 tokens).
   - **tart's real wire request is 5,187 chars ≈ 1,296 tokens** (its tool
     schemas alone are 4,971 chars — MORE than pi's 2,841). tart's estimator
     under-reports its own wire context by ~20×. This is a genuine
     estimator-scope defect vs pi's mechanism, and it is production-relevant:
     whenever a real provider reports no usage, the port under-estimates and
     under-triggers compaction.
   - The residue after the fix (different prompt sizes + different tool-schema
     verbosity — pi 4 tools on the wire, tart 7) is each app's honest
     measurement of its own deliberately different context: same family as the
     footer usage values already covered by `footer-provider-prefix`'s
     line-level match. s7, where usage IS reported, shows `15` on BOTH sides —
     the render is faithful; only the estimate source differs.

5. **The registry class (owner-agreed direction, 2026-10-12).** The registry's
   own doctrine (registry.yml header): "pin a new class here only when the
   OWNER has ruled the difference out of scope". The owner agreed with the
   direction this session: fix the estimator scope, then sanction the residual
   value divergence as a documented class. Class shape: name
   `compaction-token-estimate`, line-anchored pattern matching the panel's
   token row on BOTH sides (e.g. `Compacted from [\d,]+ tokens`) — the panel's
   wording/bytes stay pinned by the I30 chat tests, so the class forgives only
   the number (each app's own context measurement), exactly as
   `footer-provider-prefix`'s `mock-1$` anchor forgives the footer's
   provider-prefix + usage values at line level.

6. **The comment artifact (I30 style flag).** transcript.rb ≈:365-373: the
   comment block atop `compaction_panel_rows` opens with 9 pasted lines of the
   SKILL-panel's comment before the actual compaction-panel comment starts.
   Fold into this iteration (same file as the header fix).

7. **Control (this session, base 276eda3d).** Suite 565 runs / 2217
   assertions / 0 failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0
   cold; s7 + s8 exit 1 (the two residuals above). All regression claims are
   against this baseline.

## Specification

# Specification — I31 compaction-residuals

- **Objective.** Close the two root-caused residuals from I30's verdict (BRIEF
  §8 full settled-screen parity): (a) the compaction rebuild wipes the MOTD
  while pi keeps its header container (Grounds 1-2) — s7's entire 14-candidate
  unknown set is one 7-row shift; (b) the zero-usage estimator counts message
  text only and misses the wire tool schemas (Grounds 4) — s8's `67 vs 1,482`
  is ~20× under-reporting of tart's own context, plus a sanctioned residue
  needing its documented registry class. Deliver: the header-preserving
  rebuild, the estimator-scope fix, the `compaction-token-estimate` registry
  class (owner-agreed, Grounds 5), and the comment-artifact fold. Target:
  **s7 AND s8 exit 0 cold** with s1–s6 untouched.

- **Lane `rebuild`** (repo `repos/tart`; touch: `lib/tart/render/chat.rb`,
  `lib/tart/render/transcript.rb`, `test/chat_test.rb`, `test/render/**`):
  1. **The header-preserving rebuild.** pi's `compaction_end` clears the CHAT
     container and its MOTD header container survives untouched
     (interactive-mode.ts:3686-3725 — read it; the capture is the oracle).
     The port's transcript is one buffer, so the rebuild must leave the
     header rows on screen: preserve the MOTD region through the wipe, or
     re-render the header block — VERIFY which is faithful (measure what pi's
     header contains in a loaded-resources session vs the rig capture; the
     rig stages only settings.json, and pi's settled header shows art + help
     + `Pi can explain…` ONLY). The `[Context]`/resource listings must NOT
     reappear (Grounds 3 — port-only listings; their long-term home is the
     queued startup-help flip, out of scope here). Everything else I30 landed
     stays: kept entries chronologically, panel LAST, footer invalidate (not
     reset), history not duplicated, `:compaction_start` untouched.
  2. **The comment fold** (Grounds 6): fix the pasted 9-line skill-panel
     comment atop `compaction_panel_rows` (transcript.rb ≈:365-373) — the
     method's comment starts at its own subject.
  3. Tests: adjust the I30 rebuild pins for the header's presence (MOTD rows
     survive the rebuild; `[Context]` not resurrected; kept entries + panel
     last + footer-not-reset pins stand). No rig changes in THIS lane (the
     registry class is lane `estimate`'s).

- **Lane `estimate`** (repo `repos/tart`; touch: `lib/tart/compaction.rb`,
  `lib/tart/agent/loop.rb`, `test/compaction_test.rb`,
  `test/agent_loop_test.rb`, `gems/tui-split-rig/registry.yml`):
  1. **The estimator scope** (pi estimateTokens parity, Grounds 4): the
     chars/4 estimate must cover the FULL wire context — the message text AND
     the tool schemas the chat sends on every request (pi's
     `system.toolsAdded` equivalent; the port's tools live on the chat/loop,
     not in a message — thread them into `Compaction.prepare`, currently
     `prepare(@chat.messages, @compaction_settings)` at loop.rb:323). Read pi
     compaction.ts:296-311 (the system arm: content + sections + toolsAdded)
     and map the port's equivalent faithfully; cite what you port. The
     usage-backed path (estimate through the last valid assistant usage) is
     UNCHANGED — only the estimate arms grow the tools component. Do not
     reshape `Preparation`; `tokens_before` semantics stay "the context the
     summarization replaces".
  2. **The registry class** (Grounds 5): add `compaction-token-estimate` to
     registry.yml — a line-anchored pattern matching the panel's token row on
     both sides (`Compacted from [\d,]+ tokens`), with the comment block
     documenting the owner-agreed provenance (2026-10-12 direction: each
     app's estimate over its own deliberately different context; the panel
     bytes stay pinned by chat tests — the class forgives only the number).
     Additions-only vs 276eda3d (no edits to existing classes).
  3. Tests: compaction_test pins the estimate arms (with-tools vs without;
     the wire-tools component counted once, not per-message); agent_loop
     pins the threading (the s8-shape zero-usage estimate now covers the
     tools) — update existing estimate pins to the new arithmetic. The rig
     registry test (if it pins class count/shape) updates in
     `gems/tui-split-rig/test/**` — WAIT: that dir is NOT in this lane's
     touch set; if a rig test needs changing, STOP and raise it in PHASE 0
     (it is lane-crossing into I32's parallel territory — the architect
     rules on it).

- **Output format.** Raw evidence to scratch: file list + wc; the render
  table (pi mechanic → port seam, before/after); verbatim test tails + suite
  counts; s1–s8 exit codes from YOUR worktree run (lane `rebuild`: s7 expected
  exit 0 in-worktree — the header fix is wholly render-side; s8 expected exit
  1 in-worktree with ONLY the token-value candidates remaining, itemized;
  lane `estimate`: s7 expected exit 0 (no estimate change on the reported
  path), s8 expected exit 1 in-worktree with the token candidates STILL
  UNKNOWN (the registry class lands in your worktree, but the header fix is
  lane `rebuild`'s — the s8 exit 0 proves at INTEGRATION); the in-worktree
  candidate lists verbatim). Itemized deviations/cuts. PHASE 0 disagreements
  mandatory (a labeled PHASE 0 section). STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet
  && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources: `packages/coding-agent/src/modes/interactive/
  interactive-mode.ts:3686-3725` (compaction_end), `src/core/compaction/
  compaction.ts:296-311` (estimateTokens, the system arm) — read before
  coding; cite what you port. This session's captures (the byte oracle):
  `repos/tart/tmp/parity-gate-s7/run-1/{pi,tart}.capture` and
  `tmp/parity-gate-s8/…` (READ them; the header rows and the shift are
  measured facts, Grounds 1).

- **Boundaries.** Lane `rebuild` must not touch anything outside its set — in
  particular `lib/tart/agent/**` ALL, `lib/tart/compaction.rb`,
  `test/compaction_test.rb`, `test/agent_loop_test.rb`, `gems/**` (the
  registry is lane `estimate`'s), `bin/tart`, `lib/tart/identity.rb`,
  `lib/tart/settings.rb`, `lib/tart/agent/system_prompt.rb` (a PARALLEL
  iteration I32 is building in identity/settings/prompt territory right now —
  touching those files fails both iterations). Lane `estimate` must not touch
  anything outside its set — in particular `lib/tart/render/**` ALL (lane
  `rebuild`'s single-writer territory), `test/chat_test.rb`,
  `test/render/**`, `gems/tui-split-rig/**` EXCEPT `registry.yml` (I32's
  parallel territory — runner/lib/test/scenarios), `bin/tart`,
  `lib/tart/identity.rb`, `lib/tart/settings.rb`. No placeholders; search
  before implementing. Out of scope, itemize if tempted: the
  loaded-resources-under-ctrl+o flip (queued backlog), the `[Context]` MOTD
  section's existence (port feature, on the work list), the compaction
  failure render paths (still unmeasured), `@last_assistant_text` on rebuild
  (I30 itemized, unmeasured), the footer ↑/↓ value divergence (covered by
  the existing footer class).

```lanes
- name: rebuild
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
    - test/render/**
- name: estimate
  repo: tart
  touch:
    - lib/tart/compaction.rb
    - lib/tart/agent/loop.rb
    - test/compaction_test.rb
    - test/agent_loop_test.rb
    - gems/tui-split-rig/registry.yml
```

## Acceptance Criteria

# Acceptance Criteria — I31 compaction-residuals

**AC1 (the header-preserving rebuild).** On the `:compaction` event the
settled tart screen matches pi's settled screen modulo sanctioned classes:
the MOTD header rows (art, startup-help lines, `Pi can explain…`) survive the
rebuild at pi's positions, the kept entries and panel follow, and no
port-only resource listing (`[Context]` et al.) is resurrected by the rebuild.
The I30 pins stand unchanged otherwise: kept entries chronological, panel
LAST, footer invalidated not reset, history not duplicated,
`:compaction_start` untouched. Proof: the s7 gate exits 0 cold + the chat-test
pins (MOTD survives, `[Context]` absent, rebuild pins).

**AC2 (the estimator scope).** The zero-usage estimate covers the full wire
context — message text AND the tool schemas sent on the request (pi
estimateTokens' `toolsAdded` equivalent, compaction.ts:296-311) — counted
once, not per-message; the usage-backed path is unchanged. Pinned by
compaction/agent_loop tests on the estimate arms; the reported-usage path
stays value-identical (s7's panel shows 15, both sides).

**AC3 (the registry class).** `compaction-token-estimate` added to
registry.yml: line-anchored on the panel's token row (matches both sides'
`Compacted from <grouped> tokens` spellings), documented with the
owner-agreed provenance (2026-10-12: each app's estimate over its own
deliberately different context; the class forgives only the number — the
panel bytes stay pinned by the I30 chat tests). Registry additions-only vs
276eda3d — no edits to existing classes. Proof: s8 exits 0 cold with the
class in place (the zero-usage panel renders identically; the number is the
app's own measurement).

**AC4 (regression).** s1–s6 all exit 0 cold; the default rake task fully
green with run-count delta ≥ 0 (adjusted pins count); SEAM_BENCH_OK.

**AC5 (scope).** The integrated diff vs 276eda3d touches exactly the union of
the two lanes' enumerated files: chat.rb, transcript.rb, chat_test.rb,
test/render/**, compaction.rb, loop.rb, compaction_test.rb,
agent_loop_test.rb, gems/tui-split-rig/registry.yml.

**AC6 (the comment fold).** The comment block atop `compaction_panel_rows`
(transcript.rb) starts at its own subject — the 9 pasted skill-panel lines
are gone (a grep tripwire below pins it; the substance is
architect-read).

```gates
- id: suite
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-header
  ac: AC1
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-estimate
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 276eda3d:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: comment-fold
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if grep -B22 'def compaction_panel_rows' lib/tart/render/transcript.rb | grep -q 'skill-invocation'; then exit 1; else echo COMMENT_OK; fi
  expect:
    exit_code: 0
    stdout_match: COMMENT_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 276eda3d HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|test/chat_test\.rb|test/render/|lib/tart/compaction\.rb|lib/tart/agent/loop\.rb|test/compaction_test\.rb|test/agent_loop_test\.rb|gems/tui-split-rig/registry\.yml)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### rebuild

# Lane dispatch — I31 compaction-residuals, lane `rebuild`

**You are lane `rebuild`.** You are ONE of TWO parallel lane agents dispatched
together (the other is lane `estimate` of the SAME iteration, isolated in its
own worktree — its territory is `lib/tart/compaction.rb`,
`lib/tart/agent/loop.rb`, `test/compaction_test.rb`,
`test/agent_loop_test.rb`, and `gems/tui-split-rig/registry.yml`, which you
must NEVER touch). Your lane's territory, exhaustively:

- **Touch (exactly these files):** `lib/tart/render/chat.rb`,
  `lib/tart/render/transcript.rb`, `test/chat_test.rb`, `test/render/**`.
- **Must not touch:** everything else — in particular `lib/tart/agent/**`
  ALL, `lib/tart/compaction.rb`, `test/compaction_test.rb`,
  `test/agent_loop_test.rb`, `gems/**` ALL (the rig registry is lane
  `estimate`'s), `bin/tart`, `lib/tart/identity.rb`, `lib/tart/settings.rb`,
  `lib/tart/agent/system_prompt.rb`, `lib/tart/models.rb`,
  `lib/tart/render/motd.rb`, `test/support/**`.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you
have with this spec, with reasons, citing real files in this repo. Silent
compliance is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them (notably: pi's compaction_end clear semantics — read
interactive-mode.ts:3686-3725 and determine WHAT pi's header container holds
vs the chat container; and the rig captures at
`tmp/parity-gate-s7/run-1/{pi,tart}.capture` — read them, the 7-row shift is
a measured fact).

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property
the AC asserts, build the right thing and raise the conflict in your report —
name the AC, the conflict, and the evidence. This is not permission to skip
work or weaken a criterion: the conflict is reported, never silently
resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed above. No placeholder
implementations — search the codebase before implementing; full
implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever —
the smallest change that does the job, no abstraction it doesn't need.
Consistency with the surrounding code is part of correctness here: a change
that works but fights the house style (or introduces an inconsistency a
careful reader of this repo would never write) is not done. Tests stay simple
and terse, exercising public behavior, no mock/stub of the class under test.
Verify your work by running the acceptance criteria's gate commands and
record the verbatim output. Do NOT commit and do NOT run any git write
command (commit/add/branch/reset/checkout) — the architect commits and merges
after verification, and verifies you made no commits. Do NOT delete lock
files or escalate privileges if a command fails; record the exact error and
continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout (the parity rig runs take tens
of seconds each — allow 120s+ each). IMPORTANT tmux discipline: a
`tmux kill-server` from you kills every other agent's live sessions on the
shared server — NEVER run it; kill only sessions you created by exact name
(the runner's sessions are token-scoped). If a runtime will not start
unattended, record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the
scratch file given to you below (an absolute path OUTSIDE your worktree),
with RAW results only — tables, numbers, command output — no interpretation,
no "promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE |
COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you
tried). Verdicts belong to the architect and the human. Persist until your
lane is fully handled end-to-end; do not stop at analysis or partial fixes.

Your scratch report (write RAW results here, never inside your worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I31-compaction-residuals-rebuild/report.md

## Your lane's specification (lane `rebuild` ONLY — lane `estimate`'s
## deliverables are NOT yours)

- **Objective (iteration context).** Close I30's two root-caused residuals:
  the MOTD wipe (the compaction rebuild clears the header pi keeps — s7's
  entire 14-candidate unknown set is one 7-row vertical shift) and the s8
  estimator scope (lane `estimate`'s). YOUR lane owns the header-preserving
  rebuild and the comment fold.

- Deliver **the header-preserving rebuild**: pi's `compaction_end` clears the
  CHAT container and its MOTD header container survives untouched
  (interactive-mode.ts:3686-3725 — read it; the capture is the oracle). The
  port's transcript is one buffer, so the rebuild must leave the header rows
  on screen: preserve the MOTD region through the wipe, or re-render the
  header block — VERIFY which is faithful (measure what pi's header contains
  in a loaded-resources session vs the rig capture; the rig stages only
  settings.json, and pi's settled header shows art + help + `Pi can
  explain…` ONLY). The `[Context]`/resource listings must NOT reappear —
  port-only listings (the registry's staged-settings-path comment: "the
  [Context] heading itself stays a candidate"; their long-term home is the
  queued startup-help flip, out of scope here). Everything else I30 landed
  stays: kept entries chronologically, panel LAST, footer invalidate (not
  reset), history not duplicated, `:compaction_start` untouched.

- Deliver **the comment fold**: transcript.rb ≈:365-373 — the comment block
  atop `compaction_panel_rows` opens with 9 pasted lines of the SKILL-panel's
  comment before the actual compaction-panel comment starts (line 376). The
  method's comment starts at its own subject; the pasted lines are deleted.

- Tests: adjust the I30 rebuild pins for the header's presence (MOTD rows
  survive the rebuild; `[Context]` not resurrected; kept entries + panel
  last + footer-not-reset pins stand). No rig changes in THIS lane.

- **In-worktree gate expectations (spelled precisely — the frozen spec's
  output-format line compresses this):** s1–s6 exit 0; **s7 exit 0** (the
  header fix is wholly render-side — all 14 unknowns are yours to close);
  **s8 exit 1** with ONLY the token-value candidates remaining (lane
  `estimate`'s estimator + registry class are absent from your worktree —
  itemize the remaining candidate list verbatim; do not chase it). The s7/s8
  exit-0 pair proves at INTEGRATION.

## Frozen ACCEPTANCE CRITERIA (verify against these; never weaken them)

**AC1 (the header-preserving rebuild).** On the `:compaction` event the
settled tart screen matches pi's settled screen modulo sanctioned classes:
the MOTD header rows (art, startup-help lines, `Pi can explain…`) survive the
rebuild at pi's positions, the kept entries and panel follow, and no
port-only resource listing (`[Context]` et al.) is resurrected by the
rebuild. The I30 pins stand unchanged otherwise: kept entries chronological,
panel LAST, footer invalidated not reset, history not duplicated,
`:compaction_start` untouched. Proof: the s7 gate exits 0 cold + the
chat-test pins (MOTD survives, `[Context]` absent, rebuild pins).

**AC2 (the estimator scope).** [Lane `estimate`'s deliverable — not yours;
its gate (s8) proves at integration.] The zero-usage estimate covers the
full wire context — message text AND the tool schemas sent on the request
(pi estimateTokens' `toolsAdded` equivalent, compaction.ts:296-311) — counted
once, not per-message; the usage-backed path is unchanged. Pinned by
compaction/agent_loop tests on the estimate arms; the reported-usage path
stays value-identical (s7's panel shows 15, both sides).

**AC3 (the registry class).** [Lane `estimate`'s deliverable — not yours.]
`compaction-token-estimate` added to registry.yml: line-anchored on the
panel's token row (matches both sides' `Compacted from <grouped> tokens`
spellings), documented with the owner-agreed provenance (2026-10-12: each
app's estimate over its own deliberately different context; the class
forgives only the number — the panel bytes stay pinned by the I30 chat
tests). Registry additions-only vs 276eda3d — no edits to existing classes.
Proof: s8 exits 0 cold with the class in place.

**AC4 (regression).** s1–s6 all exit 0 cold; the default rake task fully
green with run-count delta ≥ 0 (adjusted pins count); SEAM_BENCH_OK.

**AC5 (scope).** The integrated diff vs 276eda3d touches exactly the union of
the two lanes' enumerated files: chat.rb, transcript.rb, chat_test.rb,
test/render/**, compaction.rb, loop.rb, compaction_test.rb,
agent_loop_test.rb, gems/tui-split-rig/registry.yml. (Your lane's diff alone:
chat.rb, transcript.rb, chat_test.rb, test/render/** — the scope gate checks
the union at integration.)

**AC6 (the comment fold).** The comment block atop `compaction_panel_rows`
(transcript.rb) starts at its own subject — the 9 pasted skill-panel lines
are gone.

```gates
- id: suite
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-header
  ac: AC1
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-estimate
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 276eda3d:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: comment-fold
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if grep -B22 'def compaction_panel_rows' lib/tart/render/transcript.rb | grep -q 'skill-invocation'; then exit 1; else echo COMMENT_OK; fi
  expect:
    exit_code: 0
    stdout_match: COMMENT_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 276eda3d HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|test/chat_test\.rb|test/render/|lib/tart/compaction\.rb|lib/tart/agent/loop\.rb|test/compaction_test\.rb|test/agent_loop_test\.rb|gems/tui-split-rig/registry\.yml)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I31-compaction-residuals-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence compaction-residuals --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction-residuals verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction-residuals`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
