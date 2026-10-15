# Incident — dispatch #1 refused pre-flight; --prompt self-copy truncation (2026-10-15T18:36Z)

Iteration I61-wire-tolerance, lane wire (consume-the-freeze dispatch, plan
notes/plan-20261015T1825Z-wire-tolerance-dispatch.md commit 652384b).
NO plan exception: frozen state untouched (verify re-run: a/b/d PASS, c FAIL
= expected pre-dispatch shape), no repair required beyond re-deriving an
ephemeral scratch file from committed state. Loop continues.

## What happened

Dispatch-holder run 0240842e-a207-4a39-afa4-505190ed9c52 executed
`architect dispatch wire-tolerance wire --prompt
build/I61-wire-tolerance-wire/prompt.md --model zai/glm-5.3-flash --effort
high --timeout 7200` exactly once (as instructed: no re-run, no writes).

- The CLI exited 1 pre-flight: "Write this lane's prompt to
  …/build/I61-wire-tolerance-wire/prompt.md before dispatching."
- build/I61-wire-tolerance-wire/prompt.md went 26,408B (mtime 12:28) →
  0B (mtime 12:31) — truncated BY the dispatch command itself.
- No builder session spawned (build/I61-wire-tolerance-wire/run.jsonl
  absent); no builder credits burned. The holder did its reporting job and
  stopped (its cost: $0.0058).

## Root cause (read from source, space-architect 9.2.0)

`copy_and_validate_prompt!` (lib/space_architect/architect_project.rb:1745-1754):

    File.open(prompt_path, "wb") { |f| f.write(File.binread(src)) }

With --prompt == the canonical destination
(build/I61-wire-tolerance-wire/prompt.md), the "wb" open truncates the
shared file BEFORE File.binread(src) reads it → src is read post-truncate
→ 0 bytes written → the command's own empty-prompt guard then refuses.
Classic src==dst self-copy truncation. The --prompt help text states the
expected shape: "the caller authors the lane prompt anywhere (a fresh
scratch file) and the CLI owns the canonical copy" — I61's kit violated
that by assembling directly AT the canonical path (the I59/I60 kit
locations; earlier dispatches evidently ran a CLI vintage without the
copy step, or from distinct paths).

## Recovery (mechanical, zero judgment calls)

1. Kit re-derived from committed state: ### wire body (commit c32c753) +
   the three frozen regions (re-verified byte-equal to freeze 733eb24f;
   grounds/specification/acceptance-criteria sha256 prefixes 42a5095cf0ce,
   bcb777166a30, 47cb5b313936). Same assembly code as the first pass; all
   embed checks re-verified by substring/index.
2. Dispatch source moved OFF the canonical path:
   build/I61-wire-tolerance-wire/prompt-src.md (26,209 chars / 26,408
   bytes, sha256 prefix 89b0710a80abe05b). The CLI now owns the canonical
   copy at build/I61-wire-tolerance-wire/prompt.md per its contract;
   canonical == src is byte-checked post-launch.
3. Dispatch re-issued (attempt #2) with --prompt prompt-src.md; everything
   else in the ENTRY 1 ladder unchanged.

## Standing fix candidates (for the human / upstream, outside this loop)

- space-architect: guard copy_and_validate_prompt! against
  src.expand_path == prompt_path.expand_path (no-op the copy when
  identical) — or validate BEFORE the write.
- Coordinator convention going forward: never assemble a lane kit AT
  build/<id>-<lane>/prompt.md; assemble at prompt-src.md and pass that to
  --prompt.
