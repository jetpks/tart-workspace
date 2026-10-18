# I75 signal-hygiene — escalations + seat rulings (relayed by coordinator #4)

Recorded 2026-10-18T13:0xZ by the coordinator, because the native supervisor
reply path DID NOT reach the nested builder children (measurement below). Both
rulings are the architect seat's, relayed via the coordinator's
`contact_supervisor`; the builders autonomously chose the same primitive the
seat ruled, so the landed direction agrees — but the seat's BINDING CONDITIONS
below must reach the judge (they were not deliverable to the builder).

## Delivery failure (raw facts)

- The child builders' `contact_supervisor(need_decision)` calls returned
  "Timed out waiting for supervisor reply." (see the primary builder run
  64844552 transcript, record after its need_decision call) and the children
  then proceeded autonomously. The coordinator cannot reply: the parent-side
  reply tool is `subagent_supervisor`, ABSENT from the coordinator's toolset;
  and the nested builder run ids are unresolvable by `subagent steer/resume/
  stop/command.*` ("Async run not found" / "No stoppable async run found in
  this session") — likely post-compaction nested-registry orphaning.
- Consequence: the seat's rulings were relayed and recorded here, but the
  builders did not receive them mid-run. The judge must treat the seat's
  conditions below as ADVISORY INPUT to its cold adjudication, not as
  builder-attested facts.

## Escalation #1 (primary builder 64844552) — SHAPE A (since RETIRED)

Child question (verbatim): frozen AC3 "tart exits with EXACTLY the mapped exit
code (129/143)" proven unachievable on the wire with the F4 wedge; the only
reliable death was believed to be self-SIGKILL (wire 137); asked how the
"recorded exit code is exactly the mapped one" is met.

Seat ruling #1: **SHAPE A** — declaration channel (`ENV["TART_SIGNAL_EXIT_DECL"]`)
+ dual record with 4 binding conditions (dual record zero-masking incl.
WIRE==137 for wedged legs; no-op channel in discussed files; formal PHASE 0
deviation #2 with the evidence pack; dead-tty legs only).

The primary builder did NOT receive this — it timed out and proceeded on the
frozen contingency text, choosing the self-SIGKILL primitive.

## Escalation #2 (replacement builder a40ce67f) — exits!-primitive (SUPERSEDES #1)

Child question (verbatim summary): measurement 3 FALSIFIED ruling #1's premise
— `exit!(code)` from the MAIN thread kills a wedged process PROMPTLY with the
MAPPED code (exit!(7) → exitstatus 7; wedge confirmed), while `exit(7)` (the
non-bang form) hangs via rb_ec_cleanup → rb_thread_terminate_all (the F6
join). `exit!` is a reliable join-bypass that restores frozen AC3 as written;
the sealed choice was SHAPE A (wire 137) vs exit! (wire 129/143), mutually
exclusive.

Seat ruling #2 (verbatim, supersedes #1): **PROCEED on the exit!-primitive —
SHAPE A is RETIRED.** exit!(code) is strictly superior if measurement 3 stands
in the six-leg harness: it restores frozen AC3 as written (wire == mapped
EXACTLY), needs no lib-side declaration channel, and is the frozen cure text's
FIRST-named primitive ("exit!(code) or self-SIGKILL") — the belt (exit! first,
SIGKILL fallback) is the frozen menu in order.

BINDING CONDITIONS (seat, for the report — the builder did NOT receive these):
1. THE CONTRADICTION IS CARRIED, NOT DROPPED. Present BOTH setups and
   reconcile them — name what the prior evidence pack (e) actually measured
   (`exit` vs `exit!`, calling thread, timing). The judge must see the full arc
   (premise → falsification → new ruling) or the pack reads as cherrypicked.
   This is the trust-bearing condition.
2. THE LEGS SETTLE IT, NOT THE SIDEBENCH. All six harness legs with exit! on
   genuinely wedged pollers. ANY leg hang → flip to SIGKILL/SHAPE A machinery
   immediately with the hang as recorded evidence; no mid-gate debugging. All
   six green on wire == mapped → AC3 met as frozen and deviation #2 CLOSED as
   refuted.
3. WIRE HONESTY, BOTH RECORDS: every leg records EXIT= and EXIT_RAW=, both
   asserted == the mapped code. No declaration channel anywhere.
4. THE KILL FALLBACK MUST BE HONEST ABOUT ITS REACHABILITY. If exit! hangs in
   cleanup-join, the fallback only fires if a thread stays schedulable during
   that hang. If it provably can never fire, it is unreachable code: either
   demonstrate a firing path or leave it out; disclose the choice + reasoning.
5. PollerLingerError containment stays (F5 flush tail load-bearing). Upstream
   citation stays: ratatui_ruby 1.5.0 events.rs:391-394 missing-UBF remains the
   ROOT CAUSE of the wedge class — exit! is a workaround needing a schedulable
   thread, so the nobody-alive-to-exit orphan still requires external SIGKILL
   until upstream fixes the UBF. State exactly that in the report appendix.

## Fallback saga (coordinator lifecycle, for the record)

A same-role FALLBACK builder (8bb7f173) was launched when the primary appeared
irrecoverably blocked; the primary then proved alive and progressing, so the
fallback's runner (pid 85090) was TERMINATED to remove a double-writer hazard.
It made no edits. The primary then TIMED OUT at its 7200000ms contract; per the
timeout law ONE replacement builder (a40ce67f, 10800000ms, audit-first) was
launched. All child run ids: 64844552 (primary, timed out), 8bb7f173 (fallback,
terminated), a40ce67f (replacement, live).
