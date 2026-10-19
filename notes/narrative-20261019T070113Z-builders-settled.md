# I81 builders-settled — agent-loading-forensics, core lane dispatched & running

## What finished

The spec run for iteration **I81 `agent-loading-forensics`** (lane `core`, repo
tart — the FINAL planned iteration, ENTRY 6 of the live-run successor plan) is
complete and the builder is dispatched.

Facts, verbatim:

- Iteration: I81 `agent-loading-forensics`, lane `core`, repo tart, branch
  `lane/I81-agent-loading-forensics-core`, base `project/pi-port` @ `7b70e8a`,
  worktree `build/I81-agent-loading-forensics-core/wt`.
- Spec frozen at freeze_sha `8ebd516c` (sha record `9758482`); the
  ```lanes``` block was written before the first freeze.
- Spec digest: `notes/spec-digest-20261019T070027Z-agent-loading-forensics.md`.
- The three frozen laws:
  1. warn-and-drop for unknown tools in custom-agent frontmatter (pi-parity;
     the universe gains exactly `subagent`);
  2. the nested grant — `subagent` grantable through Registry acceptance +
     pi's depth law verbatim (default max 2, env override, pi's blocked bytes
     exact);
  3. forensics — single-`sessions` transcript path (argv-side cure;
     `lib/tart/agent/session.rb` hard-frozen) + `status.task` carrying the
     raw task text verbatim.
- Rehearsal vector: **GREEN 87 / RED 5 / BROKEN 0 / EMPTY 0** at `7b70e8a`;
  each of the 5 declared-RED verified for exactly its declared reason. 92
  gates = 87 carried (rebased `t80`→`t81` / `7b70e8a`, `-f` legs baked in) +
  scope rewritten to the 10-path set + 4 new discriminators. All 10 touch
  paths exist at base.
- The task's three named lessons HELD: lanes block pre-freeze (zero
  amendments); no new-directory touch paths; and a PRE-FREEZE carried-pin
  audit found exactly five contradicting pins (profiles reject-message,
  task-never-recorded, session-root argv, closed-env sanctioned list, box
  task-nil) — each inside the touch set as a DECLARED re-pin (the I80 lesson
  addressed).
- Lane provisioned at `--base 7b70e8a` (ancestry re-verified immediately
  prior). Coordinator copied the lane prompt scratch
  (`tmp/i81-spec/prompt-core.md`) to
  `build/I81-agent-loading-forensics-core/prompt.md` and appended the Builder
  Prompt section (arch commit `04515e37`).
- Builder spawned and confirmed RUNNING, run id
  `64c3820e-66f3-4703-92da-e9016bcc8887` (architect-builder).

## Running now

- Builder run `64c3820e-66f3-4703-92da-e9016bcc8887` (architect-builder) on
  lane `core` of I81, working in `build/I81-agent-loading-forensics-core/wt`
  against the frozen 92-gate contract in
  `architecture/I81-agent-loading-forensics.md`. Lane prompt:
  `build/I81-agent-loading-forensics-core/prompt.md`; report will land at
  `build/I81-agent-loading-forensics-core/report.md`.

## What's next

- Wait for the builder report (`STATUS:` line + full 92-gate table +
  itemized deviations), then judge, verdict, and land I81.
- After I81's verdict the successor plan (entries 1–6) is COMPLETE.
