# spec-digest — I77 `edit-tool-fix` — LIVE-RUN SUCCESSOR ENTRY 2 (TART-ONLY) SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane FIRST; the next spec is whatever the
plan/owner queues after the I77 verdict). Iteration `edit-tool-fix`
(I77), ONE lane `core` (repo tart, frozen 4-path touch set, effort
high). Frozen at `3210c2cd` (the AC-establishing commit, which also
carries the rehearsal-declaration repair; bookkeeping `5d7625a`),
clean rehearsal stamp `gates_digest
3f374adfd0e3dd0b6987fb59171fc9fabe5c977f215c43a50f86efc9bc2dabf9` @
`2026-10-18T12:16:24-06:00` in space.yaml, frozen region verified
byte-unchanged post-freeze (empty diff 3210c2cd..HEAD on the arch
file). Bare freeze — no --skip-rehearse.

**REPLACEMENT-RUN CONTEXT:** the prior spec run (`cf693e19`) was
killed mid-rehearsal at 2026-10-18T18:02:29Z (parent coordinator
timeout). Its four draft sections were already committed (scaffold
`68db2be`, grounds `0696dbd`, specification `fb27b73`, AC `79b563f`)
and are sound; scratch `tmp/i77-spec/` survived intact. This run
audited them, found ONE falsified claim, repaired it, rehearsed
twice, froze, provisioned.

## The audit findings (this run)

- The committed draft was internally consistent and
  measurement-faithful EXCEPT one AC-preamble line: "The carried 76
  GREEN at rehearsal" — falsified by this run's rehearsal (carried =
  75 GREEN + 1 RED). Repaired in `3210c2cd` to the measured vector
  (see below). Nothing else in Grounds/Specification/AC needed
  repair.
- Inherited space-repo working tree carries PRE-EXISTING owner /
  agent-regen ops (modified `architect.yaml` — the coordinator-model
  reroute to deepseek-v4.1-flash + narrator to devstral-2512;
  modified `.pi/agents/architect-coordinator.md` +
  `architect-narrator.md`; untracked `notes/briefs/*` +
  `notes/narrative-*.md`). NOT touched, NOT "fixed", NOT reverted —
  they are the owner's.
- `repos/tart` @ `6451f1e` branch `project/pi-port`, tracked tree
  clean; standing untracked `t75*` scratch untouched; this run's
  rehearsals regenerated the `t77*` family + `tmp/render-perf-gate`
  (gate-self-owned `rm -rf`, never committed).
- tart remote fact the next spec must know: `origin/main` @
  `8eafc22` is a stack of SQUASHED PR merges (#2–#6) — `6451f1e` is
  NOT an ancestor, so `architect provision`'s default
  fast-forward-sync from the default branch DIVERGES → refuse. This
  run provisioned with `--base 6451f1e` (cut exactly the frozen base;
  the lane plan's own pin).

## Rehearsal vector (measured TWICE this run — both transcripts kept)

**GREEN 74 / RED 6 / BROKEN 0 / EMPTY 0** at the base tip
`6451f1e`, identical both runs:
`build/rehearse/I77-edit-tool-fix-20261018T120510.717713.md` and
`…T121624.997002.md`.

- **5 DECLARED-RED** (each verified to fail for exactly its declared
  reason, clean RED): `edit-fold-repro` ("folded path not recovered"
  — every pre-recovery leg passed, incl. the `repair_json` tail
  parse, the `PINNED_EDITS_MESSAGE` byte-identity and the
  `Schemas::Tools.validate` pinned-rejection leg), `edit-fold-units`
  (runs=0, file absent, declared-new), `session-model-identity`
  ("model identity not recorded" — pre-projection; the Message attrs
  + key-set legs passed), `session-model-units` (runs=0,
  declared-new), `scope` (RED on the empty must-differ legs with
  ZERO leaks — the grep found no out-of-set bites). GREEN arrives
  only with the lane work.
- **1 STANDING ADJUDICATION RED:** `render-perf-probe`, whose ONLY
  failing line is BP2 (`render-ms/s 265.1` / `266.6` vs `<= 250`;
  every other line PASS; AV window 137.4s PASS, final settle
  ~135.2s, geometry IDENTICAL to I75's ~139s) — exactly the
  I75-frozen LOAD-MARGIN class (BP2-only → note-and-pass,
  idle-machine cold re-run operative; it was RED at the I75
  rehearsal too, BP2 269.6, and I75 froze on that stamp). NOT a gate
  defect; now recorded as such in the frozen AC preamble.
- The 74 GREEN include `s9-parity` + `herdr-wire-probe` (GREEN at
  canonical depth this machine) and the full suite gate
  (1382/6507/0F/0E/1S base floor confirmed at `6451f1e`).

## Verification commands actually used (exact, tested this run)

- Rehearsal (the stamp source): `architect rehearse edit-tool-fix`
  (run twice; transcripts above; `--record`-shaped summary on
  stdout).
- Section repair: edit `tmp/i77-spec/acceptance-criteria.md` (the
  section's scratch source; gates block byte-identical to the arch
  file — verified by awk-extract + cmp), then
  `architect section edit-tool-fix acceptance-criteria --from
  tmp/i77-spec/acceptance-criteria.md -m "<message>"` → `3210c2cd`.
- Freeze: `architect freeze edit-tool-fix -m "<message>"` →
  bookkeeping `5d7625a` (bare; matched the fresh stamp).
- Provision: `architect provision edit-tool-fix --base 6451f1e` →
  worktree `build/I77-edit-tool-fix-core/wt` @ `6451f1e`, branch
  `lane/I77-edit-tool-fix-core`.
- Frozen-region integrity: `git diff --stat 3210c2cd..HEAD --
  architecture/I77-edit-tool-fix.md` (empty).
- Remote-ancestry check that forced `--base`:
  `git -C repos/tart merge-base --is-ancestor 6451f1e 8eafc22`
  (false) + `git -C repos/tart log --oneline 6451f1e..8eafc22`.

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I77-edit-tool-fix.md` (frozen region
  read-only after `3210c2cd`), space.yaml I77 record (freeze_sha +
  lane `core` with base_sha/worktree; NOTE: the provision write to
  space.yaml is still UNCOMMITTED — the coordinator's dispatch flow
  owns the next space.yaml commit). Scratch: `tmp/i77-spec/`
  (grounds.md, specification.md, acceptance-criteria.md +
  acceptance-criteria-prose.md [both carry the repaired declaration],
  new-gates.yaml, carried-gates-*.yaml, sim/, prompt-core.md — the
  lane prompt, below).
- `repos/tart` @ `6451f1e`: untouched by spec (rehearsal scratch
  only). The frozen seams the builder lands: `lib/tart/tools/edit.rb`
  (`normalize_arguments` :76-103 runs in `#call` BEFORE
  `SafeExecute#call` → `validate_input`; dual key spellings;
  `normalize_edit_shapes` :176-180 passes string-key parsed arrays
  through verbatim) and `lib/tart/agent/message.rb`
  (`assistant_to_h` :190-203 drops `provider`/`model` — the ONLY
  gap; Message already carries both attrs, `from_gem_assistant`
  already stamps them, the sink already projects them).
- Byte-frozen neighbors (NOT touchable): `lib/tart/schemas/tools.rb`
  :29 `PINNED_EDITS_MESSAGE` (pi `edit.ts:138`);
  `lib/tart/session_sink.rb` :326-327; `lib/tart/agent/chat.rb`
  :337-343/:360; edit tool `PARAMETERS_SCHEMA`/`constrained_sampling`.
- Installed-gem API the recovery depends on:
  `Fast::Completions::Protocol.repair_json` (0.5.0, protocol.rb
  :239+) — verified callable in rehearsal (the `edit-fold-repro`
  pre-legs parse the recorded tail through it).
- `~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-18T06-58-52-352Z_01a14dce-….jsonl`:
  READ-ONLY evidence; the recorded payload is embedded verbatim in
  the `edit-fold-repro` gate, so the builder needs no live session
  access.
- pi oracle (read-only, cited): `repos/pi` v1.1.0
  `packages/coding-agent/src/core/tools/edit.ts:103-141`
  (`prepareEditArguments` does NOT recover the folded shape — the
  declared divergence) + the E5 live proof that pi records
  `provider`+`model` per assistant message.

## House conventions the next spec must honor

- **Carry the I75 80-gate floor onward** (this iteration carried it
  with the standing rebases: `t77*` era prefix, threads-budget base
  `6451f1e`, scope rewritten to the 4-path touch set). The NEXT
  entry re-bases again: era prefix → its own, threads-budget base →
  the then-tip, scope → its own touch set. Carried gates keep origin
  `ac:` labels verbatim.
- **render-perf-probe BP2-only RED is note-and-pass** (the I75
  frozen rule, re-measured RED twice here) — any OTHER failing line
  is NOT the class.
- Declared-RED gates for not-yet-built deliverables are the standing
  pattern (I76/I77): each must be verified in-sim or by rehearsal to
  fail for EXACTLY its declared reason; the AC preamble must state
  the MEASURED vector, never a predicted one (this run's one repair).
- **A spec session killed mid-rehearsal leaves no half-state in
  repos/** — the rehearsal is read-only against the checkout (out
  dirs are gate-owned scratch); a replacement run can resume from
  the committed draft + scratch.
- provision on tart needs `--base <pin>` while `origin/main` holds
  squashed PR merges (see above) — check
  `merge-base --is-ancestor` before assuming the default sync.
- Zero-live-API-spend iterations are legal and preferred when the
  reproduction is pinnable frozen (the I76 residual-(e) carve-out
  honored by absence).
- Short out dirs; judge runs gates at the LANE tree; never gates
  under nohup; `env -u PI_PACKAGE_DIR` for pi execs; oracle clone
  never written; itemize-and-defend EVERY frozen gate (80/80).
- Embedded `-e '…'` gate bodies: no apostrophes (both I77 rehearsals
  clean on this).

## Builder Prompt provenance

Assembled THIS run (a task-assigned deviation from the I72–I76
"coordinator assembles" precedent — the replacement task explicitly
assigned provision + prompt assembly to the spec):

- **Lane `core` prompt scratch: `tmp/i77-spec/prompt-core.md`** —
  assembled from the frozen arch file (Objective, the two laws,
  Output format, Tool guidance, Boundaries, the rehearsal
  declarations) + the I76 digest's carry/adjudication classes + the
  I75 prompt shape. NOT yet copied anywhere.
- **The COORDINATOR copies it to
  `build/I77-edit-tool-fix-core/prompt.md`** and appends the Builder
  Prompt section at dispatch
  (`architect section edit-tool-fix prompt --append --lane core
  --from build/I77-edit-tool-fix-core/prompt.md`) — the arch file's
  Builder Prompt section is still the committed template.
- Frozen-section scratch sources: `tmp/i77-spec/grounds.md` (→
  `0696dbd`), `tmp/i77-spec/specification.md` (→ `fb27b73`),
  `tmp/i77-spec/acceptance-criteria.md` (→ `79b563f`, repaired →
  `3210c2cd`). The authoritative contract is
  `architecture/I77-edit-tool-fix.md`.

## Decisions taken this session (one-line reasons)

- **Repaired only the falsified AC-declaration line** — everything
  else in the inherited draft measured sound; minimal-diff
  discipline pre-freeze.
- **render-perf-probe recorded as the declared load-margin RED, not
  patched or re-run-to-green** — the I75 frozen adjudication rule
  forbids silent patching; two identical measurements make it the
  class, not a flake.
- **`--base 6451f1e` at provision** — origin/main's squashed PR
  merges make the default fast-forward sync diverge-refuse; the
  frozen lane plan pins `6451f1e` anyway.
- **No live leg (AC2)** — the spike's E1 documented non-reproduction
  stands; frozen unit + execution tests pin the class for zero
  spend.
- **Digest names the scratch prompt path; coordinator copies +
  records** — the task's split of labor; the arch-file section stays
  a template until dispatch (the recorded precedent's shape).

## Known unknowns (for the judge / next spec)

- Whether `render-perf-probe` BP2 passes on an idle machine at the
  LANE tree — the judge's cold re-run decides (the class is
  note-and-pass either way; any other failing line is NOT).
- Whether the recovery's frozen trigger is over- or under-broad
  against FUTURE emission variants (e.g. a tail folding into a key
  other than `path`, or `edits:` prefix variants) — the frozen law
  recovers EXACTLY the recorded class + its unambiguous cousins;
  anything else passes through unchanged. A recurrence outside the
  trigger is the gem-observability follow-up's evidence (the named
  residual, a separate entry; `repos/fast-llm` read-only here).
- The suite's `test_unknown_agent_names_the_three` real-HOME class
  and the chat-interrupt timing class are standing adjudication
  classes at the lane tree (stage a HOME / cold re-run; I74/I75
  precedent) — they were GREEN in both rehearsals here.
- `~/.tart/agents` remains POPULATED (5 architect-* profiles) — the
  plain suite was GREEN at base both runs, but re-verify at the lane
  tree.
- The provision write to space.yaml (base_sha/worktree) is
  uncommitted, awaiting the coordinator's dispatch bookkeeping — if
  the coordinator dies before dispatch, the next run re-checks
  `git status` + the I77 lane record before re-provisioning
  (`--force` only on a stale unregistered worktree).
- pi also records `responseModel`/`responseId` per assistant message
  and `model_change` session entries — NOT ported (named residuals,
  owner-backlog candidates; needs a gem Message attr read-back / a
  new entry type).
