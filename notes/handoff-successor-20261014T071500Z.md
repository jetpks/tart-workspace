# SUCCESSOR PROGRAMS HANDOFF — gem polish, then live-run rev3

You are architect-coordinator for the successor to the fiber-native &
own-the-wire program (the run that drove I50–I52). That program should be
COMPLETE — you were dispatched by the space's successor watcher only after
it verified I52's verdict landed AND the final report exists. FIRST ACTION:
verify that (architect status shows I52 fast-completions-integration with a
verdict, and a fresh notes/report-*.md from that run). If it is NOT true,
write notes/exception-<UTC>.md with the raw facts and terminate. Do not
improvise.

You drive TWO plans, strictly in this order, as one continuous program:

1. notes/plan-20261014T070847Z.md — **gem polish** (repo fast-llm): one
   iteration, `gem-concurrency-docs`, lanes `concurrency` + `docs`
   (disjoint file sets, may run concurrently).
2. notes/plan-20261014T031751Z.md — **live-run fixes rev3** (repo tart):
   ENTRY A steering-queue → B paste-markers → C resize-layout →
   D edit-tool-bg → E render-perf, in order.

Each plan carries its own standing-rules preamble — those govern (per-child
timeoutMs AND toolTimeoutMs, no mid-run contact_supervisor, bg_wait abort →
re-issue, builders zai/glm-5.3-flash, builders never commit, loop
discipline rehearse → freeze → provision → dispatch → judge → integrate,
final report to notes/report-<UTC>.md).

PHASE -1 (before the first spec): both plans were authored against the tree
as it stood DURING I52's build. The spec sessions verify every file:line
cite against the final integrated tree at freeze time — a cite that moved
is a spec input, not a defect. Anything that invalidates a plan's PREMISE
(an entry's work already done, a named file gone, an API reshaped by the
I52 integration) is an exception file, never silent improvisation.

Owner rulings locked 2026-10-14:

- Order: gem polish THEN rev3. Not interchangeable.
- The owner's README prose on the gem (commit 4736ddc) is byte-frozen —
  the docs lane fixes/defines links and moves sections per its plan, and
  touches no other prose.
- Wire/session digests on EXISTING scenarios must not move in either
  program; new behavior gets new scenarios only.
- Landing (tart PR, fast-llm publish, rubygems push) stays the human's —
  the loop stops at releasable, always.
