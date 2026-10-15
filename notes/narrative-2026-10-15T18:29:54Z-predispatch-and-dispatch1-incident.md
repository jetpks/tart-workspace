# I61-wire-tolerance · pre-dispatch + dispatch-#1 incident · 2026-10-15T18:29Z

(Kind corrected from the mislabeled "builders-settled" — this file narrates
the pre-dispatch state and the dispatch-#1 refusal; the builders-settled
event follows dispatch #2 in its own narrative. Figures corrected to disk
bytes per the parent audit.)

## Pre-dispatch bookkeeping (complete)

I61-wire-tolerance is a consume-the-freeze run (coordinator run
1164bbb3-8a5e-4f47-beae-0100fd64234b): one lane `wire`, repo `fast-llm`.

- NO spec session this run — I61 pre-frozen at freeze 733eb24f190524f9f83bec5b5b34948048c91aa3, pre-provisioned (lane fields committed 70d5073; worktree build/I61-wire-tolerance-wire/wt @ 33571e1, branch lane/I61-wire-tolerance-wire).
- Pre-dispatch audit: architect verify wire-tolerance → (a) frozen sections untouched PASS, (b) no builder commits PASS, (c) scratch report exists FAIL (expected pre-dispatch shape), (d) in-bounds PASS.
- Lane brief ### wire authored from the frozen Specification; recorded as provenance: architect section commit c32c753 ("I61 prompt: record wire lane brief — authored from the frozen Specification (consume-freeze; kit mirrors the I59/I60 shape); dispatch next").
- Dispatch kit assembled + verified byte-exact: recorded brief + three frozen bodies verbatim; staged grounds.md/specification.md/acceptance-criteria.md each byte-equal to the frozen bodies at freeze 733eb24f (sha256 prefixes 42a5095cf0ce, bcb777166a30, 47cb5b313936); embeds verified by substring/index. Kit prompt = 26,408 bytes on disk (26,209 was the String#length chars figure — wrong unit, corrected per audit).

## Dispatch #1 — refused pre-flight (incident, recorded)

- Holder run 0240842e-a207-4a39-afa4-505190ed9c52 ran `architect dispatch wire-tolerance wire --prompt build/I61-wire-tolerance-wire/prompt.md … --timeout 7200` exactly once; exit 1 pre-flight: "Write this lane's prompt to …/prompt.md before dispatching." The CLI itself truncated the kit file 26,408B → 0B; NO builder session spawned, no credits burned.
- Root cause (confirmed independently by the parent at the gem source): space-architect 9.2.0 `copy_and_validate_prompt!` (architect_project.rb:1741-1743) opens the canonical dst "wb" BEFORE reading src — with --prompt == the canonical prompt.md path the file self-empties and the empty-prompt guard refuses.
- Incident note: notes/incident-20261015T1836Z-dispatch-prompt-selfcopy.md (commit 1550d7c). Owner filed the defect in the space-architect-refine space (their commit 82895ff); a prefilled gh issue body is at notes/bugreport-20261015T1840Z-prompt-selfcopy.md (6782197).
- Recovery (mechanical): kit re-derived from committed state (c32c753 brief + frozen regions, re-verified byte-equal to 733eb24f) at build/I61-wire-tolerance-wire/prompt-src.md; dispatch #2 passes --prompt prompt-src.md — under 9.2.0 the canonical prompt.md path is NEVER passed as --prompt.

## Running now (dispatch #2 — the real builders-settled follows it)

- `architect dispatch wire-tolerance wire --prompt build/I61-wire-tolerance-wire/prompt-src.md --model zai/glm-5.3-flash --effort high --timeout 7200` — holder run 1b91399f-ca58-4121-96ee-72080c4f8ed5 RUNNING; builder session 01a140d9-8c69-7570-bf04-f880065c76e3 streaming to build/I61-wire-tolerance-wire/run.jsonl from the worktree (cwd verified); canonical copy build/I61-wire-tolerance-wire/prompt.md byte-exact vs prompt-src.md (cmp clean, 26,408 bytes); dispatched_at stamped and committed (4e9f32c).

The builder's contract is the frozen Specification: three additive behaviors at
the fast-completions inbound seam (chunk-seam parse-with-repair via the
`repair_json` port, SSE continuation rejoin for unprefixed mid-event lines,
drop-and-continue for unrepairable chunks), with healthy-wire byte-neutrality
pinned by the 11 canonical wire fixtures and the full suite. Offline only —
no live z.ai credit burn.

## What's next

Builder report at build/I61-wire-tolerance-wire/report.md → verify 4/4 →
evidence --lane wire → cold gate (fresh judge zai/glm-5.3:high) → verdict →
integrate --lanes wire --teardown → narrate → notes/report-*.md.

Exceptions park in `notes/escalation-<ts>.md` and stop; never improvise.
Post-landing follow-ups (push/PR of fast-llm, tart `path:` consumption +
bundle install) are deliberately outside the loop and the human's.
