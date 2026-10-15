# Strict-sampling I63 judge-settled — 20261015T235010Z

## What finished

Builder phase for strict-sampling-gem (I63, ENTRY 1, repo fast-llm, lane `strict`) settled.

- Builder predecessor run `43fae79d-64c5-4895-bf16-020db8348b04` (zai/glm-5.3-flash:high): implemented the full lane GREEN, escalated a frozen-claims collision (D4/AC2 vs AC4/D5 on the two pi-ai 1.1.0-era zai parity rows; recommended Option A), architect RULED Option A mid-run; the escalated wait consumed the run's 30-minute cap and the run was killed mid-report-write — never resumed, per standing rule.
- Replacement builder run `15218b9f-a6ce-4de9-a691-58c49713c839` (same worktree): first task audited the inherited uncommitted diff — exactly the declared 18-file touch set (13 modified + 5 new), zero commits, no out-of-bounds file, no half-finished hunk; ruling mechanics verified (`:zai_1_1` harness-local in wire_parity_spec.rb only, evidence why-comment, 13 fixture JSONs byte-identical, AC6 untouched); fresh verification full suite 210 examples, 0 failures (+36 vs base 174), all 9 frozen gates exit 0; report written at `build/I63-strict-sampling-gem-strict/report.md` ending `STATUS: COMPLETE`.

The replacement report confirms the audit details directly: `:zai_1_1` grep in `gems/completions/lib/` → no matches (shipped trio `:zai`/:153, `:deepseek`/:163, `:fireworks`/:172 unchanged), the byte-delta claim re-measured at exactly 15B = `,"strict":false` (501B → 516B, like-for-like thinking-high pair), and a Grounds disagreement table resolving the "20 keys" frozen numeral to pi's 16 keys (pi is the oracle; noted as an owner-side doc nit).

## Running now

- Judge run `0fb47647-5256-4f8f-bc9b-410597e92c0c` (zai/glm-5.3:high) SPAWNED AND RUNNING — full frozen-AC judging with the ruling attached (D5 deviation adjudicated PHASE 0-class on the ruling's terms), plus the Grounds "20 keys" vs pi 16-key item and the timeout/replacement incident on its docket.

## What's next

Judge runs to completion; verdict lands next.
