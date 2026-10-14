# SUCCESSOR HANDOFF — live-run fixes rev4 (zai max_tokens + error transcript)

You are architect-coordinator for the successor to the live-run rev3 program
(the run dispatched 2026-10-14T09:37Z driving I53 gem-concurrency-docs through
rev3 ENTRY E). That program should be COMPLETE — you were dispatched by the
space's successor watcher only after it verified the final report landed AND
no loop sessions were active. FIRST ACTION: verify that (a fresh
notes/report-*.md newer than 2026-10-14T09:37:38Z, architect status showing
the rev3 tail iterations — resize-layout I56, edit-tool-bg, render-perf — all
with verdicts, `bin/looplog --list` showing no active ● sessions). If it is
NOT true, write notes/exception-<UTC>.md with the raw facts and terminate. Do
not improvise.

You drive ONE plan: notes/plan-20261014T195224Z.md — **live-run fixes rev4**
(repo tart): ENTRY A zai-max-tokens → ENTRY B error-transcript, strictly in
order, serial (both entries touch agent/loop.rb — single writer).

The plan carries its own standing-rules preamble — those govern (per-child
timeoutMs AND toolTimeoutMs, no mid-run contact_supervisor, bg_wait abort →
re-issue, builders zai/glm-5.3-flash, builders never commit, loop discipline
rehearse → freeze → provision → dispatch → judge → integrate, final report to
notes/report-<UTC>.md).

PHASE -1 (before the first spec): the plan was authored against the tree as
it stood at rev3 ENTRY C's close (I56, commit 8181c59). The spec sessions
verify every file:line cite against the tree at freeze time — a cite that
moved is a spec input, not a defect. Anything that invalidates a plan PREMISE
(an entry's work already done, a named file gone, an API reshaped by ENTRY
D/E) is an exception file, never silent improvisation.

Context you need that the plan does not carry:

- The defect is a TOTAL outage of the owner's default provider (zai/glm-5.3,
  ~/.tart/models.json): every live turn 400s before the first token with
  `The max_tokens parameter is illegal.：限制数值范围[1,131072]`. The owner is
  running tart live against z.ai with a config-only workaround
  (contextWindow 131072) — see the plan's trailing note. ENTRY A must remove
  the need for it; do not depend on it.
- The deterministic repro the plan cites (tmp/repro_max_tokens_20261014.rb)
  runs offline: `cd repos/tart && bundle exec ruby ../tmp/repro_max_tokens_20261014.rb`
  from the space root, or copy it next to a worktree. Use it; do not burn
  live z.ai credits re-proving the 400.

Owner rulings locked 2026-10-14:

- The gem (repos/fast-llm) is NOT touched by rev4. ENTRY A is tart-side
  threading only; the undeclared-maxTokens fallback is the spec session's to
  rule (pi's 16384 default vs anything else — itemize and defend).
- Wire/session digests on EXISTING scenarios must not move; new behavior gets
  new scenarios only (ENTRY B adds entries ONLY on the error path).
- Landing (tart PR) stays the human's — the loop stops at releasable, always.
