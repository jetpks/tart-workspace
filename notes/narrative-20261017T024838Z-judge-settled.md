# I65 render-correctness — judge-settled — 20261017T024838Z

## What finished

Builder run `7b7e8ff9-890b-4067-8738-8fc96462d6f2`: state complete, success true — STATUS: COMPLETE_WITH_CONCERNS (concerns: worktree intentionally left uncommitted for the integrator; Deviation 3 declared reader-less-double shape change accepted under the frozen nil-id letter, invisible to render_perf assertions; pre-existing orphaned custom-block tests are the owner's to rescue)

- Builder lane report: `build/I65-render-correctness-core/report.md`
- Lane tree: `build/I65-render-correctness-core/wt`, branch `lane/I65-render-correctness-core`, exactly the 8-file touch set modified, 0 commits by design; all 21 frozen gates green at the lane tree per builder
- Spec frozen at `6db5bcb2`; rehearsal stamp 16 GREEN / 5 RED (all RED pre-declared)

Lane highlights (from the builder report, not re-derived):

- AC1 (markdown inline-scan explosion, D1): both reject arms in `lib/tart/render/markdown.rb` `inline_spans` fixed to emit from `m.begin(0)`; base defect (42-byte source → 120 bytes) now passthrough-exact; 6 new `inline_scan` markdown pins + 2 transcript seam pins, all passing; existing 25 markdown pins pass unchanged.
- AC2 (id-keyed pending registry, D2): single-slot `@pending_tool` replaced by `@pending_tools = {}` keyed by tool call id; `finalize_pending_as_error` settles every live pending; supersede-pinning test deleted (the supersede WAS the defect); 7 new `pending_registry` pins; chat_test 254 runs / 0 failures.
- AC3 (footer context window, D3): boot entry hoisted in `bin/tart` `footer_data`; gate `FOOTER_WINDOW_OK 1000000`; launcher_smoke_test 10 → 11 runs.

## Running now

- Judge run `5e039698-f0c3-43f4-9d59-fce2b38ec3a0`: state running (confirmed via status — active 2s ago)

## What's next

Judge verdict on the lane is pending; integration and landing disposition follow it.
