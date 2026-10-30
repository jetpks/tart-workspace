# Evidence — io-event undelivered-cancellation (I87 class (a), residual ii)

Preserved 2026-10-26 from `build/I87-suite-deflake-core/scratch/` (gitignored
build scratch) before housekeeping could claim it.

- `repro_a.rb` — the I87 reduced-context reproduction of class (a): the escape
  interrupt's undelivered cancellation. Same wiring as
  `test/chat_test.rb#chat_with_server` + the escape scenario, tight loop,
  external CPU steal, per-iteration outcome + async cancel-branch tally
  (FiberError→Later counted; observed 0 across all runs). Fired the firing
  signature at ~1/20–1/300 iterations under 8-way steal on ruby 4.0.9 /
  async 2.46.0 / io-event 1.22.1 (kqueue). The original firing JSON/log
  artifacts died with the I87 worktree teardown; the forensic that read them
  is frozen in `architecture/I87-suite-deflake.md` (Builder Report, class (a)
  section) — the ring-buffer probe instrumentation is in this file.

Forensic chain (proven, from the frozen I87 report): ESC dispatched busy=true →
`interrupt_work!` found both tasks alive (`tasks_alive=[true,true]`) →
`Async::Scheduler#raise` invoked for both fibers → cancel returned
(`cancelled_after=true, fiber_after=nil`) → the agent block's ensure/rescue
never executed (`@in_run` stuck true, `server_requests=0` — the fiber was
parked at a PRE-IO cooperative point, i.e. sitting in io-event's ready queue
when raised out-of-band). Delivery swallowed below `Scheduler#raise`.

Delivery-path ground truth (traced 2026-10-26 against the local socketry
clones, `~/architect/src/github.com/socketry/`):

- async 2.46.0 `lib/async/scheduler.rb:215` — `Scheduler#raise` is a two-line
  passthrough to `@selector.raise(...)`; async owns nothing of the delivery.
- io-event 1.22.1 `ext/io/event/selector/selector.c:298` —
  `IO_Event_Selector_raise`: pushes the interrupter onto the ready queue,
  then `IO_Event_Fiber_raise` (= plain `Fiber#raise`, `ext/io/event/fiber.c`)
  transfers into the target fiber to raise at its park point.
- io-event 1.22.1's own release notes fixed an infinite-loop symptom of this
  exact interleaving ("a queued fiber resumed out of band… another fiber
  re-queues itself on every iteration"; placeholder boundaries; "remove them
  if a fiber raises"). Our firing is the swallowed-delivery symptom of the
  same stale-entry/out-of-band-resume hazard.
- io-event 1.22.1 → 1.22.3 (upstream latest at preserve time): contains
  `#232` "Prevent worker-pool re-entry with `Fiber.blocking`" (77e0c72,
  2026-10-18) — fiber-scheduling machinery again; 1.22.2 yanked; 1.22.3 is
  signing + #232 + Linux futex. NOT yet A/B-tested against this repro.

Plan consuming this evidence: `notes/plan-20261026T*Z-io-event-delivery.md`.
