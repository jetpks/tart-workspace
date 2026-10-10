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

```lanes
- name: polish
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/loop.rb
    - test/kernel_carryin_test.rb
    - test/test_helper.rb
- name: editor
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/render/chat.rb
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
    - README.md
- name: markdown
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/render/markdown.rb
    - lib/raspberry_pi.rb
    - test/markdown_test.rb
- name: markdown-seam
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/render/chat.rb
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
```

## Acceptance Criteria

**AC1 (comment + stderr — BRIEF §2).** The `strip_thinking_replay` comment in `lib/raspberry_pi/agent/loop.rb` states pi's actual replay behavior (pi replays the reasoning field the deltas carried; the port suppresses outright — the I05-ratified deviation) — architect-read, comment-only diff, behavior unchanged. The suite runs with stderr free of async's "unhandled exception" warn (gate `stderr-quiet`) while the raising-work carry-in test still proves termination + reraise through the public path — architect-read: assertions preserved or strengthened, never weakened to silence the warn.

**AC2 (cursor — BRIEF §7.1).** The input line renders a cursor at the insertion position, proven by **cell readback on the headless test terminal** at (a) end-of-input and (b) a mid-input position after cursor-left; left/right move the insertion point; backspace deletes before the cursor; printable characters insert at the cursor; send/steer/approval behavior unbroken (suite green, gate `editor-guard`). The cursor mechanism (hardware vs fake cursor) is the lane's PHASE 0 call — the readback-visible distinction is the frozen property.

**AC3 (history + word ops — BRIEF §7.1).** Up/down recall previously sent messages in order — test-proven (send A, send B: up recalls B, up recalls A, down returns B); a recalled line is editable and sends as edited. Word-wise operations follow pi's `word-navigation.ts` boundary semantics — test-proven for at least delete-word-backward; whatever key events the port's kernel actually carries, verified in PHASE 0. Key bindings documented in `README.md`'s usage/editor section.

**AC4 (markdown converter — BRIEF §7.1, §2).** `Render::Markdown` converts every subset construct (headings, paragraph, bold, italic, strikethrough, inline code, fenced code block, blockquote, hr, unordered + ordered list, link) to the gem-neutral styled-rows vocabulary; `test/markdown_test.rb` asserts each construct's observable distinction with `markdown.ts` file:line citations; the vocabulary carries no `RatatuiRuby` reference (tui-seam gate); no new runtime dependencies (gem-pins gate).

**AC5 (markdown seam — fast-follow, BRIEF §7.1).** Assistant completions render markdown into scrollback — cell-readback proof of at least one styled construct on the headless terminal; user echo, tool preview, status, and approval rendering unchanged (their existing tests pass unmodified); the live region stays verbatim streaming text; the deviation (pi renders markdown while streaming; the port renders at completion) is itemized in the parity table, not silent.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: editor-guard
  ac: AC2, AC3
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/chat_test.rb test/tui_test.rb && echo EDITOR_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OK

- id: markdown-guard
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/markdown_test.rb && echo MD_OK
  expect:
    exit_code: 0
    stdout_match: MD_OK

- id: tui-seam
  ac: AC2, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Prompt

### polish

### LANE polish — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-polish/wt
  (a git worktree of the raspberry-pi repo, branch lane/I06-editor-markdown-polish, based on
  project/pi-port — everything through I05: kernel, agent loop (error-terminal + thinking
  strip), seven parity tools, TUI seam with style vocabulary, chat surface with fg colors
  + multi-line tool preview, §5 toggle seam (off), committed bin/raspberry-pi launcher,
  suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-polish/report.md
- You may touch ONLY:
  lib/raspberry_pi/agent/loop.rb (the strip_thinking_replay comment — comment-only diff), test/kernel_carryin_test.rb, test/test_helper.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - test/test_helper.rb is YOURS (assigned to this lane); the other wave-1 lanes were told to raise in PHASE 0 rather than touch it — you are the only lane that may change it.
  - The lanes block in the spec lists a fourth lane markdown-seam — it is a wave-2 fast-follow, NOT running now; ignore it except to know that render/chat.rb and tui.rb belong to the editor lane in this wave.
  - Gates stderr-quiet and suite-green are your proof; editor-guard/markdown-guard run other lanes' files — run them only if the files exist in your worktree (they do: chat_test/tui_test exist and must stay green; test/markdown_test.rb does NOT exist yet — record 'NOT RUNNABLE: wave-1 markdown lane deliverable', do not create it).
Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** Verify your
work by running the acceptance criteria's gate commands and record the
verbatim output. Do NOT commit and do NOT run any git write command
(commit/add/branch/reset/checkout) — the architect commits and merges after
verification, and verifies you made no commits. Do NOT delete lock files or
escalate privileges if a command fails; record the exact error and continue.
Do NOT use `run_in_background` (or shell `&`) for your own work — this process
terminates when you end your turn and reaps its own children, so backgrounded
work is SIGTERMed and its output lost while the run still exits 0; run long
commands serially in the foreground instead. Give every potentially long
command an explicit timeout; if a runtime will not start unattended
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===

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

**AC1 (comment + stderr — BRIEF §2).** The `strip_thinking_replay` comment in `lib/raspberry_pi/agent/loop.rb` states pi's actual replay behavior (pi replays the reasoning field the deltas carried; the port suppresses outright — the I05-ratified deviation) — architect-read, comment-only diff, behavior unchanged. The suite runs with stderr free of async's "unhandled exception" warn (gate `stderr-quiet`) while the raising-work carry-in test still proves termination + reraise through the public path — architect-read: assertions preserved or strengthened, never weakened to silence the warn.

**AC2 (cursor — BRIEF §7.1).** The input line renders a cursor at the insertion position, proven by **cell readback on the headless test terminal** at (a) end-of-input and (b) a mid-input position after cursor-left; left/right move the insertion point; backspace deletes before the cursor; printable characters insert at the cursor; send/steer/approval behavior unbroken (suite green, gate `editor-guard`). The cursor mechanism (hardware vs fake cursor) is the lane's PHASE 0 call — the readback-visible distinction is the frozen property.

**AC3 (history + word ops — BRIEF §7.1).** Up/down recall previously sent messages in order — test-proven (send A, send B: up recalls B, up recalls A, down returns B); a recalled line is editable and sends as edited. Word-wise operations follow pi's `word-navigation.ts` boundary semantics — test-proven for at least delete-word-backward; whatever key events the port's kernel actually carries, verified in PHASE 0. Key bindings documented in `README.md`'s usage/editor section.

**AC4 (markdown converter — BRIEF §7.1, §2).** `Render::Markdown` converts every subset construct (headings, paragraph, bold, italic, strikethrough, inline code, fenced code block, blockquote, hr, unordered + ordered list, link) to the gem-neutral styled-rows vocabulary; `test/markdown_test.rb` asserts each construct's observable distinction with `markdown.ts` file:line citations; the vocabulary carries no `RatatuiRuby` reference (tui-seam gate); no new runtime dependencies (gem-pins gate).

**AC5 (markdown seam — fast-follow, BRIEF §7.1).** Assistant completions render markdown into scrollback — cell-readback proof of at least one styled construct on the headless terminal; user echo, tool preview, status, and approval rendering unchanged (their existing tests pass unmodified); the live region stays verbatim streaming text; the deviation (pi renders markdown while streaming; the port renders at completion) is itemized in the parity table, not silent.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: editor-guard
  ac: AC2, AC3
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/chat_test.rb test/tui_test.rb && echo EDITOR_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OK

- id: markdown-guard
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/markdown_test.rb && echo MD_OK
  expect:
    exit_code: 0
    stdout_match: MD_OK

- id: tui-seam
  ac: AC2, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```


=== ACCEPTANCE CRITERIA (frozen) ===


**AC1 (comment + stderr — BRIEF §2).** The `strip_thinking_replay` comment in `lib/raspberry_pi/agent/loop.rb` states pi's actual replay behavior (pi replays the reasoning field the deltas carried; the port suppresses outright — the I05-ratified deviation) — architect-read, comment-only diff, behavior unchanged. The suite runs with stderr free of async's "unhandled exception" warn (gate `stderr-quiet`) while the raising-work carry-in test still proves termination + reraise through the public path — architect-read: assertions preserved or strengthened, never weakened to silence the warn.

**AC2 (cursor — BRIEF §7.1).** The input line renders a cursor at the insertion position, proven by **cell readback on the headless test terminal** at (a) end-of-input and (b) a mid-input position after cursor-left; left/right move the insertion point; backspace deletes before the cursor; printable characters insert at the cursor; send/steer/approval behavior unbroken (suite green, gate `editor-guard`). The cursor mechanism (hardware vs fake cursor) is the lane's PHASE 0 call — the readback-visible distinction is the frozen property.

**AC3 (history + word ops — BRIEF §7.1).** Up/down recall previously sent messages in order — test-proven (send A, send B: up recalls B, up recalls A, down returns B); a recalled line is editable and sends as edited. Word-wise operations follow pi's `word-navigation.ts` boundary semantics — test-proven for at least delete-word-backward; whatever key events the port's kernel actually carries, verified in PHASE 0. Key bindings documented in `README.md`'s usage/editor section.

**AC4 (markdown converter — BRIEF §7.1, §2).** `Render::Markdown` converts every subset construct (headings, paragraph, bold, italic, strikethrough, inline code, fenced code block, blockquote, hr, unordered + ordered list, link) to the gem-neutral styled-rows vocabulary; `test/markdown_test.rb` asserts each construct's observable distinction with `markdown.ts` file:line citations; the vocabulary carries no `RatatuiRuby` reference (tui-seam gate); no new runtime dependencies (gem-pins gate).

**AC5 (markdown seam — fast-follow, BRIEF §7.1).** Assistant completions render markdown into scrollback — cell-readback proof of at least one styled construct on the headless terminal; user echo, tool preview, status, and approval rendering unchanged (their existing tests pass unmodified); the live region stays verbatim streaming text; the deviation (pi renders markdown while streaming; the port renders at completion) is itemized in the parity table, not silent.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `tui-seam`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: stderr-quiet
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: editor-guard
  ac: AC2, AC3
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/chat_test.rb test/tui_test.rb && echo EDITOR_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OK

- id: markdown-guard
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/markdown_test.rb && echo MD_OK
  expect:
    exit_code: 0
    stdout_match: MD_OK

- id: tui-seam
  ac: AC2, AC4, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

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
