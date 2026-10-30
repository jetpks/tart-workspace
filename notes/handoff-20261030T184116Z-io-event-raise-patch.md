# Handoff — io-event-raise-patch coordinator standdown (20261030T184116ZZ)

Owner directive (relayed mid-run 2026-10-30): host is restarting all pi
instances. The in-flight spec child was allowed to finish; then the loop
stands down — no provision, no builders, no further children. A fresh
coordinator resumes from this note.

## Exact resume point

- Plan: `notes/plan-20261030T181034Z-io-event-raise-patch.md` — 2 ENTRYs,
  ENTRY ordering load-bearing (ENTRY 2 `raise-fix` must not start before
  ENTRY 1 `raise-mechanism` is judged).
- **Iteration I91 `raise-mechanism`: SPEC COMPLETE AND FROZEN.**
  - Spec run: `e6478f0f-be8e-4908-9815-9e2ea83bf896` (architect-spec,
    kimi-coding/k3:high, completed success 2026-10-30T~18:4xZ).
  - Freeze SHA: `f64b2a4fd08a4c5939b5d97e3a8c51291dd8eeb6` (Builder
    Prompt commit; frozen region unchanged since AC-repair `0747ac2`).
    Freeze-record commit `ec06fc2`; digest commit `0cf1e0b`.
  - Arch file: `architecture/I91-raise-mechanism.md` — Grounds /
    Specification (Laws 0–8) / AC (7 ACs + declared-states preamble) +
    frozen 8-gate t91 gates block. space.yaml: verdict pending, ONE lane
    `forensics` (repo io-event; touch `build/I91-raise-mechanism/scratch/**`
    + `build/I91-raise-mechanism/report.md`).
  - Rehearsal (operative stamp, post-repair): **3 GREEN / 5 RED** —
    transcript `build/rehearse/I91-raise-mechanism-20261030T123620.752789.md`;
    GREEN `suite`, `scope-zero`, `container-preflight`; the 5 REDs are
    exactly the declared absent-at-base deliverable legs. Rehearsal #1
    exposed a real gate bug, repaired in `0747ac2` (direct
    `bundle exec ruby repro.rb N` invocations both arms).
  - Digest (read this FIRST on relaunch — carries every frozen fact):
    `notes/spec-digest-20261030T183811Z-raise-mechanism.md`.
- Lanes NOT provisioned. Builders NOT dispatched. No judge run. No
  narration children (per directive). Zero tracked changes in
  repos/io-event (still clean at `6cc4bfd`, fork `jetpks/io-event`).
- Working tree of the space is clean at `0cf1e0b` (this note is the next
  commit).

## Next steps on relaunch (in order)

1. Read `notes/spec-digest-20261030T183811Z-raise-mechanism.md` and the
   Builder Prompt section of `architecture/I91-raise-mechanism.md`.
2. **Provision**: `architect provision raise-mechanism` (lane repo
   io-event; add `--base 6cc4bfd` if a base is requested).
3. **Dispatch forensics lane builder** (architect-builder, cwd = lane
   worktree, timeoutMs 7200000, standing routing — zai/glm-5.3-flash @
   high, no pin overrides): builder prompt is assembled and committed at
   `build/I91-raise-mechanism/prompt.md` (digest: "the coordinator uses
   this path for dispatch"); per plan step 3 copy it to
   `build/I91-raise-mechanism-forensics/prompt.md` and point the builder
   at that copy — read it before anything else.
4. On builder completion: spawn architect-judge for I91
   (cwd = space root, timeoutMs 7200000). Narrations per plan kinds
   (builders-settled, judge-settled, verdict-landed) — narrator
   timeoutMs 300000.
5. On verdict CONTINUE: work ENTRY 2 `raise-fix` (spec → provision →
   `core` lane builder → judge). Its spec must carry I91 repro assets
   forward, re-freeze the suite literal if sus tests grow, reuse the I91
   container recipe for the Linux leg, and use the UNPATCHED fork tip as
   control arm. On KILL: stop after integration result.
6. Relaunch spawn contract unchanged: spec 3600000, builder/judge
   7200000, narrator 300000 — never the 30-min default.

## Known unknowns carried for the judge (from frozen Grounds)

Repro is a new artifact (judge re-verifies ≥1 firing ring per darwin arm
against Law 2); Linux-leg evidence is container-side (judge may re-run
`scratch/linux/run_linux.sh`); Arm B loaded-from-worktree asserted from
batch logs, not trusted; AC2's ≥1-firing-per-arm vs bursty rate — a
shortfall is a loud verdict input, never a silent pass; `repro-smoke` is
firing-tolerant (harness rot reds, firings are data).
