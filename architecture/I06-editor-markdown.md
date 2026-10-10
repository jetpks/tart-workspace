# I06: editor-markdown

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

<!-- WHY. Research/spec distilled: problem, decision + why, requirements,
non-goals, verified facts WITH citation URLs, open questions. If
architecture/BRIEF.md exists, cite **BRIEF §N** instead of restating — shrink this
to deltas + citations. Optional — delete this section for iterations that needed
no research. Write + commit: `architect section editor-markdown grounds --from <file>`. -->

## Specification

- **Objective:** Make the input comfortable and the assistant output readable — the two remaining daily-driver friction points from the first real live session (2026-10-10: multi-turn chat, tool calling, steering, colors, and multi-line previews all work live; driver feedback verbatim: "there's no cursor currently — it's much easier to type when there is one", and assistant replies arrive as raw markdown source in scrollback; BRIEF §7.1). Four packages, one repo: **(1) carry-in polish** — the I05-verdict comment defect in `lib/raspberry_pi/agent/loop.rb` (`strip_thinking_replay`'s comment claims "pi does not build replay from reasoning deltas either way" — false: pi replays the reasoning field the deltas carried, `openai-completions.ts:1340–1356`, re-verified against the oracle at I05 judging; the lane's own I05 report finding 8 had it right) plus the pre-existing async "Task may have ended with unhandled exception" stderr warn from the deliberate `kernel_carryin_test.rb` raising-work test (I04 verdict nit, present since I02); **(2) input-line editor** — a visible cursor at the insertion position, mid-line editing, in-memory history, and word-wise operations (the pi `editor.ts`/`input.ts`/`word-navigation.ts` subset — the current input handles only append/backspace/enter); **(3) markdown converter library** — a pure, gem-neutral styled-rows vocabulary converting the pi `markdown.ts` subset (headings, emphasis, code, lists, quotes, links, hr); **(4) fast-follow seam** — wiring the converter into the assistant scrollback path. **Why this shape:** editor and seam work both live in `render/chat.rb`, so they cannot be parallel lanes; per the parallel+fast-follow pattern (dispatch.md `### Parallel + fast-follow`), wave 1 is three mutually disjoint lanes (polish, editor, markdown-lib) and `markdown-seam` is a wave-2 lane provisioned off the integrated tip after wave 1 merges — its touch set is deliberately identical to editor's, which is the sanctioned seam home.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (cursor mechanism chosen and why; the key-binding table; history recall semantics as ported; the markdown vocabulary shape; the span→Line conversion), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement — the markdown parser is hand-rolled by default; proposing a markdown gem is a PHASE 0 disagreement, not a silent addition.
  - **Verify against gem source before coding** (`bundle info ratatui_ruby --path`), each item in the findings table: **ratatui_ruby 1.5.0** — `Frame#set_cursor_position` (`frame.rb:193–244`, the hardware blinking cursor: verify whether it is reachable through the port's inline-viewport draw path at all, and whether a hardware cursor is observable on the headless test terminal — if it is not cell-readback-provable, pi's own approach is the answer: pi renders a **fake cursor** — `editor.ts` renderFakeCursor: an inverse-video grapheme at the insertion point, a highlighted trailing space at end-of-line); the Style modifiers vocabulary (`style/style.rb` — which modifier symbols exist, e.g. reversed/bold, and what `get_cell_at`'s Cell reports for a modified cell — `Cell#fg` is proven readback; establish what else is readable, since AC2's proof is cell readback); the `TUI.key_event(code, modifiers:)` shape (`tui.rb:178–179`) and exactly which key events the kernel forwards to `Render::Chat#on_event` (what `code`/`modifiers` arrive for arrows, ctrl-w, alt-b/f, delete — the port's binding surface is whatever actually arrives).
  - **pi reference (read-only oracle, `repos/pi`):** `packages/tui/src/components/editor.ts` (cursor rendering ≈:540–600 — fake cursor on a grapheme vs highlighted trailing space; CURSOR_MARKER/IME positioning and the atomic-segment machinery are **out of scope** — the port's input is single-line); `packages/tui/src/components/input.ts` + `tui-main-screen.ts` (history recall semantics: when a line enters history, up/down navigation order, what editing a recalled line does, where history is stored); `packages/tui/src/word-navigation.ts` (word-boundary semantics for delete-word-backward and word-wise jump — port these semantics, itemize any simplification); `packages/tui/src/components/markdown.ts` (the theme function surface ≈:198–213 — heading/link/code/codeBlock/quoteBorder/hr/listBullet/bold/italic/strikethrough; token handling ≈:148–160 for list/blockquote/code; `StrictStrikethroughTokenizer` at :9; port the **observable distinctions** the theme functions produce, not the marked/ink mechanism).
  - **Hermetic discipline:** all editor and markdown tests are render-level on the headless terminal plus pure converter tests — no LLM traffic, no mock-server changes, no live API calls, no keys.
  - **House style:** as I02–I05 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, four lanes; wave 1 = `polish`/`editor`/`markdown`, mutually disjoint; `markdown-seam` is the wave-2 fast-follow — provisioned off `project/pi-port` in the judging session after wave-1 integration, never in wave 1):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write commands, no real LLM API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `polish` may touch:** `lib/raspberry_pi/agent/loop.rb` (the comment correction — comment-only diff on the behavior), `test/kernel_carryin_test.rb`, `test/test_helper.rb`.
  - **Lane `editor` may touch:** `lib/raspberry_pi/render/chat.rb`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `README.md` (input/editor + usage sections only).
  - **Lane `markdown` may touch:** `lib/raspberry_pi/render/markdown.rb` (new), `lib/raspberry_pi.rb` (the require-registration line only), `test/markdown_test.rb` (new).
  - **Lane `markdown-seam` (fast-follow) may touch:** `lib/raspberry_pi/render/chat.rb`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`. This set is deliberately identical to `editor`'s — sanctioned because the lane roots at the integrated tip after editor merges (the seam is its home per the fast-follow pattern); it must NOT be provisioned or dispatched in wave 1.
  - **Shared file discipline:** `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json`, `Gemfile`/`Gemfile.lock`, and `test/support/mock_llm_server.rb` are in **no** lane's touch set. `test/test_helper.rb` is `polish`'s — `editor` and `markdown` raise in PHASE 0 if they need it changed. If a lane believes it needs a file outside its set, raise it in PHASE 0 — do not touch it.
  - **Out of scope:** multi-line input editing, undo/kill-ring, autocomplete and slash menus, mouse support, IME/CURSOR_MARKER, streaming markdown in the live region, markdown tables, terminal hyperlinks and images, themes/keybindings as configurable resources, any change to the kernel (`core/**`), the poller, the agent layer beyond polish's comment, the tools, session persistence/JSONL, MCP.
- **Deliverables:**
  1. **Comment correction (polish):** `strip_thinking_replay`'s comment states pi's actual behavior — pi replays the reasoning field the deltas carried on chat-completions endpoints when the signature ∈ {reasoning, reasoning_content, reasoning_text} and no encrypted reasoning_details are preserved (`openai-completions.ts:617–637, 1340–1356`), and the port suppresses outright (the I05-ratified deviation). Comment-only diff; behavior unchanged.
  2. **Suite-stderr warn (polish):** the deliberate raising-work carry-in test no longer produces async's "Task may have ended with unhandled exception" warn on suite stderr, while still proving the same semantics through the public path (raising work terminates the poller and reraises). The mechanism is the lane's to choose (e.g. routing the raise so async observes it as handled); weakening the test's assertions to silence the warn is a defect, not a fix.
  3. **Input-line editor (editor):** a visible cursor at the insertion position at all times — the mechanism is PHASE 0's to verify (hardware `set_cursor_position` if reachable and provable; otherwise pi's fake-cursor analog through the seam); the frozen property is a **cell-readback-visible distinction** at end-of-input and mid-input. Left/right move the insertion point; backspace deletes before the cursor; forward-delete deletes after (if the port's key vocabulary carries it — verify); printable characters insert at the cursor. In-memory history: up/down recall previously sent messages (pi's recall semantics where verifiable, else itemized); a recalled line is editable and sends as edited. Word-wise operations per `word-navigation.ts` boundary semantics (delete-word-backward; word-wise jump if the key events carry it). `README.md` documents the key bindings. Enter-to-send, steering, and approval prompts stay unbroken.
  4. **Markdown converter (markdown):** `Render::Markdown` — pure Ruby, gem-neutral: markdown text → styled rows (a row is an array of spans; a span is text plus a style vocabulary: fg color name, bold, italic, strikethrough, code, and whatever else the pi theme distinctions require). Subset: headings h1–h6 (visually distinct per pi's theme), paragraphs, bold, italic, strikethrough, inline code, fenced code blocks, blockquote, horizontal rule, unordered + ordered lists, links (render per pi's link theme — text and URL handling verified against `markdown.ts`). Hand-rolled parser; tests assert each construct's observable distinction with `markdown.ts` file:line citations. No `RatatuiRuby` anywhere in `render/markdown.rb` (the tui-seam gate scans all of lib).
  5. **Markdown seam (markdown-seam, fast-follow):** assistant completions render through `Render::Markdown` into scrollback — styled cells proven by readback on the headless terminal for at least one construct; `tui.rb` gains the span-vocabulary → Line/Span conversion; user echo, tool preview, status, and approval rendering unchanged; the live region stays verbatim streaming text (markdown at completion only — the deviation from pi's streaming markdown rendering is itemized, not silent).
- **Lane plan:** four lanes, one repo. **Wave 1** (parallel, mutually disjoint — verified against the full file inventory: no overlap between any pair, every named file in exactly one wave-1 set): `polish` (agent comment + carry-in test hygiene), `editor` (input editing + cursor + history), `markdown` (converter library + registration). **Wave 2:** `markdown-seam` (fast-follow off `project/pi-port`; touch set identical to editor's by design — the sanctioned seam home).
- **Effort call:** polish medium (the warn fix needs async-semantics care without weakening the test; the comment itself is trivial), editor high (interaction semantics + key-event verification + headless provability), markdown high (parser subset + vocabulary design against the pi theme), markdown-seam medium (conversion + integration + readback tests; roots at the tip where the vocabulary already exists).

## Acceptance Criteria

<!-- PROOF. Write the prose conditions of correctness (AC1, AC2, …) that the
architect judges against. Calibrate precision to the property (SKILL.md §4): a
property criterion is bounded from the defect's side only — freeze a floor, not
an equality; exactness is for criteria whose number is itself the deliverable.
A presence-grep gate on prose is a tripwire, never the proof — its criterion
should say which. Runnable checks live in the fenced ```gates block below
(parsed at freeze time — absent or empty is allowed; malformed fails freeze).
Pre-freeze check — snapshot: no count/name-set/byte-identity frozen at merely
today's value; control: every baseline actually run this session; mechanism: no
*how* where the *what* is the requirement; interface: every CLI surface the
Specification names (verb, flag spelling, subcommand) executed once before it
freezes; dry-run:
`architect rehearse editor-markdown` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze editor-markdown` needs a fresh rehearsal stamp — editing gates
stales it; `--skip-rehearse REASON` records the skip. The stamp records that you
looked, never that gates passed. Freeze commits this file and records its SHA as
freeze_sha. Read-only afterward — any change to Grounds/Specification/Acceptance
Criteria = automatic iteration FAIL. -->

> Gate-pass is necessary, not sufficient: the architect also reads the diff against the
> cited **BRIEF §sections** intent and the §1 cardinal invariant before the verdict.

**AC1.** ...

```gates
# Each gate backs one prose AC above. Remove the comment markers to activate.
# `cmd` paths resolve against the REPO TREE; `cwd` is relative to the SPACE
# ROOT. The judge-time remap is asymmetric: a `cwd` under repos/<repo> is
# remapped into the lane worktree, one outside it passes through unchanged.
# End a multi-step `cmd` with `echo SENTINEL` + `stdout_match`: /bin/sh (the
# gate runner's shell) has no `set -e`, so an early branch can exit 0 — the
# sentinel proves the command reached its end.
# Draft, then run `architect rehearse editor-markdown` — before the freeze, while
# a bad gate still costs nothing.
# - id: suite-green        # unique slug within the iteration (required)
#   ac: AC1                # which prose AC this gate backs (required)
#   cwd: repos/my-repo     # run dir, space-root-relative (optional)
#   cmd: |-                # block style by default — a plain scalar breaks on `: `
#     bundle exec rake test && echo SUITE_OK
#   expect:                # at least one of: exit_code, stdout_match, threshold
#     exit_code: 0
#     stdout_match: SUITE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I06-editor-markdown-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section editor-markdown prompt --append --lane <lane> --from build/I06-editor-markdown-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I06-editor-markdown-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence editor-markdown --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section editor-markdown verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify editor-markdown`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
