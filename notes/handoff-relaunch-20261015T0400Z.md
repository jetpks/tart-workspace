# Handoff — rev4 coordinator relaunch (post pi-1.2.0 environment repair)

UTC: 2026-10-15T04:00Z (environment repair verified 03:30–03:50Z this session).
You are resuming LIVE-RUN FIXES REV4 (notes/plan-20261014T195224Z.md) from
notes/exception-2026-10-15T03:39:58Z.md — the previous coordinator run
845943f4 terminated there because I59's judge could not spawn.

## What was broken, and the repair (owner-directed, verified this session)

1. **Subagent spawning** — the host global npm package was upgraded
   1.1.0 → 1.2.0 mid-program; 1.2.0 no longer ships `@earendil-works/chord`,
   and the then-installed pi-subagents version required it unconditionally,
   so every background-child spawn failed. **CURED by `pi update
   --extensions`**: pi-subagents 0.78.0 requires chord only when the host
   manifest declares it (1.2.0 does not — chord shipped 0.85 through 1.1.x).
   **Verified live this session**: a trivial async architect-narrator child
   spawned, ran, and completed ("ok") on pi 1.2.0 + pi-subagents 0.78.0.
   RULING: the host global stays on 1.2.0 — no downgrade. You and every
   role child run on this stack.

2. **The parity oracle drift** (the builder's checkpoint
   build/loop/exception-2026-10-15T03:30:00Z.md) — the rig's `pi` oracle
   resolved from PATH and drifted to 1.2.0, breaking s1–s10+s17 with a
   base-vs-lane byte-identical signature. **CURED by the owner's ruling:
   the oracle is now BUILT FROM THE SPACE'S repos/pi checkout** (pinned at
   f1b2e77f, version 1.1.0 — the exact source every iteration's pi
   citations are verified against). Built this session: `npm ci` +
   `npm run build:offline` in repos/pi, with packages/ai provider data taken
   from the published `@earendil-works/pi-ai@1.1.0` tarball (NOT live
   models.dev hydration — today's snapshot does not typecheck against the
   1.1.0 source). Shim: **`/Users/eric/architect/spaces/20261009-pi-port/bin/pi`**
   (fish; execs the absolute mise node 24.18.0 binary + the built
   `dist/bundle/cli.js` — the absolute node path deliberately bypasses mise
   shims, which prompt for config trust inside the rig's staged HOMEs).
   **Smoke verified this session**: rig s1 at base repos/tart `9b04d0d`
   with the shim first on PATH → **exit 0**, diff classes only the two
   sanctioned (`parity-run-path`, `footer-provider-prefix`), ZERO
   unknown-candidates. The v1.2.0 banner + `[Extensions]` drift signature
   is gone.

   This answers the builder checkpoint's three options: neither (a)
   downgrade the global install nor (c) accept-drift — the oracle is pinned
   at 1.1.0 via the space build, and the parity gates are expected GREEN
   again. The judge re-verifies cold rather than trusting this smoke.

## OPERATIVE DIRECTIVE — every shell that runs rig gates

The runner resolves its pi binary via `command -v pi` from the invoking
shell. Prepend the shim dir so the pinned oracle wins:

    PATH="/Users/eric/architect/spaces/20261009-pi-port/bin:$PATH" architect gate zai-max-tokens

(or `export PATH="/Users/eric/architect/spaces/20261009-pi-port/bin:$PATH"`
at the top of the bash session, before any gate/rig invocation). This is
space-side tooling — **the tart repo is NOT edited for this**: the I59 lane
tree must remain exactly its 10 frozen files; an 11th file fails the frozen
scope gate.

## Resume point — I59 zai-max-tokens (ENTRY A), step 5

- Spec: FROZEN at `b0f6366e` (grounds 7448b04 → spec 02d50012 → AC
  8cdaa13 → a5c2df21 → prompt b0f6366e; digest
  notes/spec-digest-20261015T020959Z.md).
- Builder: COMPLETE — report at `build/I59-zai-max-tokens-core/report.md`;
  lane tree UNCOMMITTED at base `9b04d0d` in
  `build/I59-zai-max-tokens-core/wt` (verified at the exception: exactly the
  10 frozen files modified, no commits). Nothing lost; nothing to rebuild.
- Judge: NOT STARTED — the two failed spawns (89525ec7, a807486a) were the
  old-extension chord bug, now cured. Judge I59 normally per the
  architect-judge agent file: post-flight checks, transcribe evidence, run
  the frozen gates COLD (with the PATH directive above), diff vs
  Specification + BRIEF, verdict, integrate. With the pinned oracle the
  parity gates should not need the builder's identical-signature drift
  proof — but read it (build/loop/exception-2026-10-15T03:30:00Z.md) and
  rule on it as a PHASE 0 artifact either way.
- Then ENTRY B (error-transcript) per the plan, then the program's final
  report — same plan, same order, nothing else changed.

Known metadata class (I50/I52/I53 precedent): the I59 lane's
`integration_branch` is EMPTY in space.yaml — the slug fallback resolves
`project/pi-port`; the judge back-fills the lane entry at integrate.
