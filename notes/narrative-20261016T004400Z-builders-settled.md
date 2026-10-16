# I64 strict-sampling — builders-settled @ 2026-10-16T00:44Z

## What finished

- Spec run 11dfb62c-9b3d-48e3-889d-c7e9915e7ec2 (zai/glm-5.3:high) COMPLETE; I64 frozen — iteration strict-sampling-integration, one lane `core`, repo tart, base 195ae97; freeze sha 0333fcc (freeze commit d4c775a bookkeeping-only).
- Spec escalated two pre-freeze decisions; architect ruled: (1) Gemfile pin freezes at 0.3.0 + lock (plan's "0.4.0" cannot exist yet — owner hand-cuts tags at landing; mechanical re-pin commit follows, I61 precedent); (2) live-zai half = mock-wire cold gate + owner-run repro script at landing (no ZAI_API_KEY in any loop-side env — I46/I63/I64-verified), verdict never blocks on it.
- Rehearsal vector at freeze: 3 GREEN / 31 RED, every RED pre-declared — GREEN scope (vacuous), live-script (pre-made artifact), threads-budget; the 28 REDs are one pin class (tart pins 0.2.0, canonical gem serves 0.3.0 — Bundler::GemNotFound measured) plus strict-wire/strict-compat/lock-deps new-gate REDs. Rehearsal #1 caught one label bug (I60's stray ac: AC2) — fixed, re-rehearsed clean.
- Digest: notes/spec-digest-20261016T002403Z.md (space commit 249a5a7). Provision: lane core worktree build/I64-strict-sampling-integration-core/wt (base 195ae97, clean); integration_branch hand-set to project/pi-port (I50-incident precedent); space commit c0e7394.
- Dispatch kit: build/I64-strict-sampling-integration-core/prompt.md (65,369 bytes, sha256 b7db2bff…), prompt-src.md byte-identical.

## Running now

- Builder run 65a0b850-0eab-4e00-9511-3076e531a9ae (zai/glm-5.3-flash:high, timeoutMs 7200000) SPAWNED AND RUNNING in the lane worktree; builders never commit.

## What's next

- Builder runs to completion; judge spawns after its STATUS report.
