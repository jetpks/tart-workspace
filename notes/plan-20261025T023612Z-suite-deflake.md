# Plan — suite-deflake (cure the two 4.0.9 parallel-load flake classes before the tart PR merges)

Operator plan 2026-10-25. Repo in scope: `tart` (branch project/pi-port,
tip `40ed92b`). ONE lane.

**Why (owner directive, this session).** The I77–I85 PR is staged
(`build/land/tart-pr-body-20261024-2034.md`, not yet pushed — the owner
ruled: fix the flakes before merge). I85's recorded residual measured two
declared flake classes firing at an elevated rate on ruby 4.0.9 under full
parallel load (~2/9 full `rake test:par` runs each):

- **Class (a) — chat-interrupt loud-red.** A streaming-interrupt test in
  the `test/chat_test.rb` family (the I82 anti-wedge belt makes it a ≤5 s
  red, never a hang). Standing note-and-pass class since the I75–I83 era;
  fire rate elevated on 4.0.9.
- **Class (f) — subagents-e2e drain-timing** (first sighting I85):
  `test_default_on_e2_async_detached_notify_and_print_drain`
  (`test/subagents_e2e_test.rb:987`) — the "the drain adds no extra
  stdout" assertion inverts when the child answer beats the parent drain
  under sustained parallel load. GREEN standalone ×3 and under deliberate
  CPU steal; fires only inside full 8-way runs.

Both are timing races the suite has been carrying as note-and-pass; the
owner wants them cured, not carried. I82's standing law applies:
**deterministic synchronization over real sleeps** — the fix is test-side
synchronization (await the actual condition, don't poll a wall-clock
window), unless forensics prove a production defect, in which case the fix
is minimal and itemize-and-defend.

**Standing context the spec needs:**
- Carried-gates floor: `architecture/I85-ruby-4-0-9.md` frozen gates block
  (103 gates — ARCH FILE only, never a digest), rebase era prefix `t85*` →
  its own, diff base `6a054df` → `40ed92b`, rewrite `scope`. Handoff:
  `notes/spec-digest-20261024T071323Z-ruby-4-0-9.md` (gate-shell
  discipline, the declared-flake-class record incl. the (a)/(f) fire-rate
  measurements, provision `--base` requirement, suite wall ≤ 240 s,
  one-full-suite-run-per-battery fold).
- Runtime is now ruby 4.0.9 by committed `.ruby-version` — gates run on
  4.0.9 with no extra ceremony; worktrees inherit the pin.
- If the cure holds, the (a) and (f) declared classes come OFF the
  note-and-pass preamble — the AC record states their cured status so the
  next iteration stops carrying them. (If a class proves incurable at
  acceptable cost, the spec says so and it stays declared — that outcome
  requires owner ruling, PHASE 0.)
- **Post-landing follow-ups (outside the loop, owner's):** push tart
  project/pi-port and open the I77–I85 PR from the staged body (now
  including I87); the fast-llm PR is independent and unaffected by this
  entry; the standing I84 gate-flip question remains open.

## ENTRY 1 — iteration suite-deflake (repo: tart, ONE lane `core`)

**Objective.** Cure flake classes (a) and (f) at the root so the suite
runs clean under parallel load on ruby 4.0.9 — measured, not asserted.
Cite BRIEF §8: the daily-driver suite must be trustworthy; a battery that
cries wolf trains its operator to ignore red.

**Grounds to read.** `architecture/I85-ruby-4-0-9.md` (frozen gates block
+ the declared-flake-class record with fire-rate measurements);
`notes/spec-digest-20261024T071323Z-ruby-4-0-9.md` (handoff);
`notes/spec-digest-20261020T044344Z-suite-sleep-surgery.md` (the I82
deterministic-fakes-over-sleeps law and the anti-wedge belt shape);
`repos/tart/test/subagents_e2e_test.rb` (class (f), line ~987);
`repos/tart/test/chat_test.rb` (the streaming-interrupt family — class (a)
candidates: `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`,
`test_escape_interrupts_a_streaming_run_through_the_kernel_path`);
`repos/tart/test/support/parallel_runner.rb` (the load context the flakes
fire under); `repos/tart/test/support/signal_hygiene_harness.rb` (the I82
belt — do not weaken it).

**Acceptance direction (spec refines into frozen AC).**
- **Forensics first**: each class gets a named firing test, a stated race
  mechanism, and a fix that removes the mechanism (deterministic
  synchronization — await the condition, fake the clock, order the
  handshake), itemize-and-defend per edit. A fix that only widens a
  timeout or adds a sleep is a defect, not a cure.
- **The cure bar is measured**: N consecutive full `rake test:par` runs
  with ZERO (a)/(f) firings — N frozen by the spec from the measured fire
  rates (2/9 ⇒ N materially larger than 9; the spec picks and defends the
  number). Plus: serial `rake test` green; the touched tests green
  standalone ×N and under deliberate CPU steal; the carried battery green
  cold.
- The carried 103-gate floor rides rebased; the parallel gates' declared
  flake preamble no longer lists (a)/(f) as live classes (their cured
  status is stated in the AC record).
- The anti-wedge belt and every existing timeout/loud-red safety stay or
  tighten — never loosen.

**Constraints.** Repo tart only; integration branch project/pi-port;
provision with `--base 40ed92b` (origin/main holds squashed PR merges —
re-verify immediately before). Expected touch set: the firing test files
(+ possibly a test-support helper) — production `lib/` changes only if
forensics prove a production defect, minimal and itemized (PHASE 0 if the
shape surprises). Do NOT touch: `.ruby-version`, `Gemfile*`, the parallel
runner's fan-out mechanics (unless proven the race source — then
itemize-and-defend), `architecture/`. Builders never commit. Suite wall
≤ 240 s serial; the one-full-suite-run-per-battery fold holds. Judge runs
gates at the lane tree, cold, itemize-and-defend every gate and edit.
