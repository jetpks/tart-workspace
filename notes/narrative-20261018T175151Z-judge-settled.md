# I76-edit-tool-spike judge-settled 20261018T175151Z

## What finished

Builder run `bb238f67-f42c-43cf-b9b1-f78e0491fcca` completed successfully in 921205 ms, cwd `build/I76-edit-tool-spike-edit-probe/wt`.

Builder final STATUS line (first line of `build/I76-edit-tool-spike-edit-probe/report.md`):
> STATUS: COMPLETE_WITH_CONCERNS (spend-ledger gate RED: E2 leg 4 lines vs cap 3 and total 19 vs cap 18 — two zero-token creation-phase HTTP 400s from harness-fidelity fixes, disclosed in SPEND; E1 non-reproduction: beam never emitted an edit call in the capped legs; exact-context replay is system-less because tart's instructions are unrecorded in the session jsonl)

Builder summary: 59 scratch artifacts preserved, and 8/8 frozen gates measured (7 GREEN, spend-ledger RED as disclosed).

Builder gate vector: `REPORT_OK / STRUCTURE_OK / ATTRIB_OK / ARTIFACTS_OK / CLEAN_OK / ENV_OK / MODELS_OK / LEDGER_RED(total 19>18, E2 4>3)`.

Builder attribution: `model-emission (tart-argument-handling eliminated as producer — the fold predates all tart code; gem-wire-or-parse eliminated as producer — E2 raw captures show raw bytes == finalize view on every observed emission; gem's repair_json is at most a silent normalizer under the narrowed hypothesis B')`.

Builder recommendation: `YES recover the folded shape in tart's prepareEditArguments (pi's oracle does NOT recover it — edit.ts:103-141 + pinned :138 message — so it is a declared divergence; keep the pinned rejection message byte-identical); landing repo tart first, gem observability as follow-up`.

Builder live-leg results: `19 wire-reaching calls: E1 not-reproduced (6/6), E2 raw bytes well-formed == finalize view (2 captures + 2 zero-token 400s), E3 strict accepted (3/3), E4 glm well-formed (3/3), E5 pi well-formed (3/3)`.

Builder integrity check: `~/.tart/models.json sha256 prefix c8294a2e1b67c7f6 matches the spec-time hash exactly (file untouched), all repos pristine, no commits anywhere`.

Judge run `7518ebb8-3440-429e-904c-dbaf56b684e4` spawned and running, explicit timeoutMs 7200000, cwd the space root.

## Running now

Judge run `7518ebb8-3440-429e-904c-dbaf56b684e4` is in progress.

## What's next

Await judge completion for `7518ebb8-3440-429e-904c-dbaf56b684e4`.

expected-wall: 7200000 ms
