The specification is complete and frozen. Final report:

---

## I69 `tart-identity-herdr` — iteration specification COMPLETE

**Session chain** (all committed to the space repo): scaffold → Grounds `47b7d1d8` → Specification `64781486` → Acceptance Criteria `d63cd27f` → carry audit (**AUDIT_OK**, run before rehearsal) → **rehearsal #1: 40 GREEN / 8 RED — exactly the declared designed-RED vector, zero amendments, zero BROKEN** → Builder Prompt `bda6355c` → **freeze (freeze_sha `bda6355c55edbd1a90c4ca862ea9c1902f524a99`, bookkeeping `931eacd`; accepted without --skip-rehearse — the frozen region was byte-unchanged since the stamp, the I67/I68 precedent)**.

**Lane** — one lane `core` (repo tart, base `3845f6a`, effort high):
- **Scratch prompt path: `build/i69-core/prompt-brief.md`** — committed verbatim as the arch file's `## Builder Prompt / ### core` via `architect section tart-identity-herdr prompt --append --lane core --from build/i69-core/prompt-brief.md` (commit `bda6355c`). Provenance: the brief embeds the plan's ENTRY 1 law, the Grounds blast-radius table, the herdr contract citations (add-herdr-support.mdx, socket-api.mdx:692, panes.rs, detect/mod.rs:330-348), the probe contract modeled on `tmp/probe-herdr/` + `bin/tool-pending-probe`, and the verification commands measured this session. No other copies.

**Rehearsal verdict vector (transcript `build/rehearse/I69-tart-identity-herdr-20261017T124336.396861.md`)**: **GREEN 40 / RED 8 / BROKEN 0 / EMPTY 0**. The 8 RED are exactly the declared designed-RED cures, each verified RED-for-the-right-reason at base by direct runs this session: `identity-law`, `default-face`, `default-boot`, `herdr-units`, `herdr-wire-probe`, `rig-identity-assert`, `scope`, `footer-window` (the identity-flip rebase). Measured base floors frozen fresh: suite **1211/5911/0F/0E/1S** + **SEAM_BENCH_OK**.

**Digest path (authoritative for this run)**: `…/subagent-artifacts/outputs/96e232ba-0cc2-4f4a-b9f1-12829bba4548/notes/spec-digest-20261017T185618Z-tart-identity-herdr.md` — per the task's output ruling I wrote ONLY this path; the coordinator may want to place a copy at the space's `notes/spec-digest-20261017T185618Z-tart-identity-herdr.md` for the next spec session's standing read.

**Open questions for the judge / coordinator** (all recorded in the AC preamble and digest):
1. The lane tree is *predicted* at 83 chars (`build/I69-tart-identity-herdr-core/wt`); the s9 out-dir budget is `120 − 32 − len(tree)` — the judge recomputes if provision's tree differs.
2. The blast-radius table is the audited head start, not the ceiling — a test outside the 16-path whitelist breaking on the flip is stop-and-disclose (deviation adjudication).
3. The live herdr restore (server restart actually re-running `tart -r <id>`) is argv-shape-gated, not live-gated — the owner's drive is the post-landing channel.