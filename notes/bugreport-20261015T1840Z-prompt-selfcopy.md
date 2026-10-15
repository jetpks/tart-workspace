# Prefilled bug-report body — space-architect 9.2.0 dispatch --prompt src==dst truncation (owner submits via: gh issue create -R jetpks/space-architect --title "dispatch --prompt self-copy truncates the canonical lane prompt (copy_and_validate_prompt!)" --body-file <unwrapped body below>)

```
# gh issue create -R jetpks/space-architect --body-file <this-file-with-fences-stripped>

**Kind:** tooling

## Summary

`architect dispatch --prompt P` truncates P to 0 bytes and refuses pre-flight when P **is** the lane's canonical prompt path (`build/<id>-<lane>/prompt.md`) — a src==dst self-copy in `copy_and_validate_prompt!`.

## What happened

Dispatched with `--prompt build/I61-wire-tolerance-wire/prompt.md` (the kit had been assembled directly at the canonical path, mirroring an earlier CLI vintage's flow). The command exited 1 with "Write this lane's prompt to …/prompt.md before dispatching." and the file went 26,408B → 0B (mtime bump at dispatch time): `File.open(prompt_path, "wb")` truncated the shared file BEFORE `File.binread(src)` read it, so the "copy" wrote 0 bytes and the command's own empty-prompt guard then refused. No builder session spawned.

## What was expected

Either the copy is skipped when src and dst resolve to the same file (idempotent no-op, dispatch proceeds), or the src==dst condition is rejected upfront with an actionable message — never a silent truncation of the caller's only kit copy.

## Repro steps

1. In a space with a provisioned lane, write a non-empty lane prompt directly to `build/<id>-<lane>/prompt.md`.
2. Run `architect dispatch <iteration> <lane> --prompt build/<id>-<lane>/prompt.md …`.
3. Observe exit 1 ("Write this lane's prompt … before dispatching.") and `build/<id>-<lane>/prompt.md` is now 0 bytes.

Root cause site: space-architect 9.2.0 `lib/space_architect/architect_project.rb:1741-1743` (`copy_and_validate_prompt!`).

Workaround (what we shipped): keep the kit at a distinct scratch path (e.g. `prompt-src.md`) and pass THAT to `--prompt`; the CLI's canonical copy is then written byte-for-byte as documented.

## Diagnostics

- space-architect: 9.2.0
- space-cadet: 9.1.0
- ruby: 4.0.7 (arm64-darwin23)

## Diagnostics

- space-architect: 9.2.0
- space-cadet: 9.1.0
- ruby: 4.0.7 (arm64-darwin23)

## Space context

- Space id: 20261009-pi-port
- Space title: pi-port

### Iterations

- I01 seam-spike — continue
- I02 core-loop — continue
- I03 agent-loop — continue
- I04 tui — continue
- I05 live-run — continue
- I06 editor-markdown — continue
- I07 session-mcp-print — continue
- I08 compaction — continue
- I09 rename-tart — continue
- I10 skills-settings-commands — continue
- I11 render-surface — continue
- I12 autocomplete-scroll — continue
- I13 live-run-fixes — continue
- I14 third-run-parity — continue
- I15 fourth-run-parity — continue
- I16 identity-parity — continue
- I17 tool-turn-parity — continue
- I18 tool-render-parity — continue
- I19 bash-preview-collapse — continue
- I20 viewport-parity — continue
- I21 decomp-wave1 — continue
- I22 decomp-wave2 — continue
- I23 decomp-wave3 — continue
- I24 decomp-wave4 — continue
- I25 transcript-expandables — continue
- I26 editor-kill-ring — continue
- I27 model-menus — continue
- I28 whole-screen-selection — continue
- I29 compaction-usage — continue
- I30 compaction-panel — continue
- I31 compaction-residuals — continue
- I32 prompt-identity — continue
- I33 header-startup-help — continue
- I34 tool-pending-bg — continue
- I35 editor-multiline — continue
- I36 thinking-wiring — continue
- I37 thinking-ux — continue
- I38 user-bash-streaming — continue
- I39 editor-undo — continue
- I40 model-catalog-polish — continue
- I41 loadout-session-env — continue
- I42 e2e-session — continue
- I43 dry-rb-boundaries — continue
- I44 dry-rb-shapes — continue
- I45 dry-rb-flow — continue
- I46 zai-provider — continue
- I47 seam-memory — continue
- I48 subagents-core — continue
- I49 subagents-profiles-intercom — continue
- I50 de-bridge — continue
- I51 fast-completions-gem — continue
- I52 fast-completions-integration — continue
- I53 gem-concurrency-docs — continue
- I54 steering-queue — continue
- I55 paste-markers — continue
- I56 resize-layout — continue
- I57 edit-tool-bg — continue
- I58 render-perf — continue
- I59 zai-max-tokens — continue
- I60 error-transcript — continue
- I61 wire-tolerance — pending
```
