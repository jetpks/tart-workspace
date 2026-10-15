# I59 zai-max-tokens — judge-settled — 2026-10-15T03:59:33Z

## What finished

- I59 spec (architect-spec run 7531458c-b566-4c6a-8a0e-9d20b12eb547): COMPLETE, frozen at b0f6366e, one lane core, 10-file touch set, digest notes/spec-digest-20261015T020959Z.md.
- I59 builder (architect-builder run 6db2d305-c266-43ca-8efa-c87854525bb5): COMPLETE — lane tree uncommitted at base 9b04d0d in build/I59-zai-max-tokens-core/wt (exactly the 10 frozen files); report build/I59-zai-max-tokens-core/report.md. Builder self-declares AC1–AC3 PASS, incl. the wire parity pin `ZAI_WIRE_OK tart=pi=512` (base tart measured 27840 vs lane 512 vs pi 512).
- I59 judge: two earlier spawn attempts (89525ec7-b68a-40e5-b376-08e616915fb5, a807486a-332c-4168-8166-578b525106a1) failed at start — host pi 1.1.0→1.2.0 upgrade removed @earendil-works/chord from the global install. CURED owner-side by `pi update --extensions` (pi-subagents 0.78.0 needs chord only when the host manifest declares it; 1.2.0 does not). Judge now RUNNING: run 6dc3e7c9-3843-4f69-a89d-2e367451b7fe, timeoutMs 7200000, cwd space root.
- Environment repair in force: the rig's pi oracle is pinned via space-built shim bin/pi (repos/pi checkout f1b2e77f, version 1.1.0, pi-ai@1.1.0 tarball data; global host pi stays 1.2.0 per owner ruling). Repair smoke: rig s1 at base repos/tart 9b04d0d with shim first on PATH → exit 0, artifact repos/tart/tmp/oracle-pin-s1; the v1.2.0 banner + [Extensions] drift signature is gone.
- Builder's earlier drift exception (build/loop/exception-2026-10-15T03:30:00Z.md: s1–s10+s17 parity gates RED at base and lane with byte-identical signatures) is explained and cured by the oracle pin.

## Running now

- I59 judge run 6dc3e7c9-3843-4f69-a89d-2e367451b7fe (architect-judge), cwd space root, timeoutMs 7200000.

## What's next

- Resume point after this judge: ENTRY B error-transcript (unstarted), then the program's final report.
- Coordinator directive in force for any child shell touching pi/tart directly (notes/coordinator-env-pipackagedir-2026-10-15T03:58:24Z.md): prepend the space bin dir to PATH and unset PI_PACKAGE_DIR (and PI_MODEL/PI_PROVIDER/PI_CONTEXT_WINDOW) — bare `pi --version` in a child shell reports 1.2.0 via the leaked PI_PACKAGE_DIR; `env -u PI_PACKAGE_DIR` restores 1.1.0. Rig panes are immune (rig scrubs parent PI_*/TART_* keys); rig gates need only the PATH prepend.

## Attention

Nothing beyond the running judge — no pending ruling. The judge's task carries the PATH+unset directive; the two prior judge spawn failures are cured.
