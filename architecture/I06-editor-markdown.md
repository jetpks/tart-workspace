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

### editor

### LANE editor — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-editor/wt
  (a git worktree of the raspberry-pi repo, branch lane/I06-editor-markdown-editor, based on
  project/pi-port — everything through I05: kernel, agent loop (error-terminal + thinking
  strip), seven parity tools, TUI seam with style vocabulary, chat surface with fg colors
  + multi-line tool preview, §5 toggle seam (off), committed bin/raspberry-pi launcher,
  suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-editor/report.md
- You may touch ONLY:
  lib/raspberry_pi/render/chat.rb, lib/raspberry_pi/tui.rb, test/chat_test.rb, test/tui_test.rb, README.md (input/editor + usage sections only). Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - A wave-2 fast-follow lane (markdown-seam) will rework render/chat.rb + tui.rb AFTER this lane merges — build cleanly and idiomatically; leave no seams for it, it roots at your merged tip.
  - The cursor is the driver's stated pain point ('there's no cursor currently — it's much easier to type when there is one') — it is the highest-value deliverable in this lane.
  - test/support/mock_llm_server.rb and test/test_helper.rb are other lanes' / shared — raise in PHASE 0 if you need them changed; do not touch.
  - test/markdown_test.rb does not exist yet (wave-1 markdown lane deliverable) — markdown-guard is NOT RUNNABLE in your worktree; record that, do not create it.
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

### markdown

### LANE markdown — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-markdown/wt
  (a git worktree of the raspberry-pi repo, branch lane/I06-editor-markdown-markdown, based on
  project/pi-port — everything through I05: kernel, agent loop (error-terminal + thinking
  strip), seven parity tools, TUI seam with style vocabulary, chat surface with fg colors
  + multi-line tool preview, §5 toggle seam (off), committed bin/raspberry-pi launcher,
  suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-markdown/report.md
- You may touch ONLY:
  lib/raspberry_pi/render/markdown.rb (new), lib/raspberry_pi.rb (the require-registration line only), test/markdown_test.rb (new). Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - GEM-NEUTRAL VOCABULARY: render/markdown.rb must contain zero RatatuiRuby references — the tui-seam gate greps all of lib/. The span→Line/Span conversion in tui.rb belongs to the wave-2 markdown-seam lane, NOT you. Your vocabulary is the port-internal contract that lane will consume — document its shape in the class comment.
  - No new runtime deps: the parser is hand-rolled. Proposing a markdown gem is a PHASE 0 disagreement, not a silent addition.
  - test/test_helper.rb is the polish lane's — raise in PHASE 0 if you need it; do not touch. If your test can use the existing shared base without changing it, do that.
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

### markdown-seam

### LANE markdown-seam — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-markdown-seam/wt
  (a git worktree of the raspberry-pi repo, branch lane/I06-editor-markdown-markdown-seam, based on the
  integrated project/pi-port tip 728428d — wave 1 already merged into your base: the polish comment
  correction + carry-in warn fix, the full input-line editor in render/chat.rb (fake cursor via the
  reversed modifier, mid-line editing, history, word-wise operations), and the Render::Markdown
  converter (lib/raspberry_pi/render/markdown.rb, registered in lib/raspberry_pi.rb). All wave-1
  behavior and tests must stay green — you root at the tip, you do not redo wave 1.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I06-editor-markdown-markdown-seam/report.md
- You may touch ONLY:
  lib/raspberry_pi/render/chat.rb, lib/raspberry_pi/tui.rb, test/chat_test.rb, test/tui_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only).
- Lane-specific notes:
  - You are the wave-2 fast-follow seam lane (spec deliverable 5): assistant completions render
    through Render::Markdown into scrollback. The converter's consumption contract is documented in
    lib/raspberry_pi/render/markdown.rb's class comment — rows (Array of Array of Span), Span
    (text/fg/modifiers), fg as TUI.style color symbols, modifiers as ratatui modifier names. The
    row → TUI::Text::Line, span → TUI::Text::Span conversion belongs in tui.rb's seam
    (TUI.span/TUI.line already exist from the editor lane — extend, do not duplicate).
  - Cell-readback proof of at least one styled markdown construct on the headless test terminal is
    the frozen AC5 property (TUI::Session#cell_fg / #cell_modifiers are proven readback).
  - User echo, tool preview, status, and approval rendering paths stay unchanged (their existing
    tests must pass unmodified); the live region stays verbatim streaming text — markdown renders
    at completion only, and that deviation (pi renders markdown while streaming) is itemized in
    your parity-deviation table, never silent.
  - The input-line editor's tests (fake cursor, history, word ops) are in your base — they must
    stay green; if your seam work conflicts with an editor behavior, port pi's semantics and raise
    it in your report rather than silently changing it.
  - README.md is NOT in your touch set (the editor lane owns it); raise any doc need in PHASE 0.
  - test/support/mock_llm_server.rb, test/test_helper.rb, test/golden_parity_test.rb,
    test/fixtures/edit_golden.json, Gemfile/Gemfile.lock are no lane's to touch — raise in
    PHASE 0 if you need them changed; do not touch.
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

### polish

### Findings (PHASE 0)

| # | Verify item | Spec claim | Reality (evidence from this run) | Verdict |
|---|---|---|---|---|
| 1 | pi reasoning-delta capture | deltas map to thinking blocks keyed by signature ∈ {reasoning, reasoning_content, reasoning_text} | Confirmed: `repos/pi/packages/ai/src/api/openai-completions.ts:611` — `const reasoningFields = ["reasoning_content", "reasoning", "reasoning_text"];` then :615-627 `ensureThinkingBlock(thinkingSignature)` + `thinking_delta` push | spec correct |
| 2 | pi replays reasoning on send (the current loop.rb comment denies this) | replay gated on no preserved encrypted reasoning_details | Confirmed: `openai-completions.ts:1318` `preservedReasoningDetails = signedReasoningDetails ?? legacy…`; `:1340` `if (!preservedReasoningDetails)`; `:1346` `assistantMsg[signature] = nonEmptyThinkingBlocks.map(b => b.thinking).join("\n")` — pi does build replay from the reasoning field the deltas carried. The shipped comment ("pi does not build replay from reasoning deltas either way") is false. Corrected. | spec correct; shipped comment wrong |
| 3 | async warn source | "Task may have ended with unhandled exception" comes from the raising-work carry-in test | Confirmed: full-suite stderr contained exactly one async warn, `class: RuntimeError, message: "work boom"`, backtrace `test/kernel_carryin_test.rb:34` (pre-fix run, verbatim in JSON log). Emitted at async-2.46.0 `lib/async/task.rb:224-226`: `rescue => error … unless @promise.waiting? then warn(self, "Task may have ended with unhandled exception.", exception: error)`. | spec correct |
| 4 | warn mechanism | routing the raise so async observes it as handled is viable without touching `core/**` | Confirmed: `Promise#waiting?` (`async/promise.rb:63-65`) is `@waiting > 0` — set by a fiber blocked in `wait`. The kernel's supervisor (`core/loop.rb` `supervise` → `work_task.wait`) starts greedily and registers before the reactor next schedules the work fiber, so a single reactor yield (`sleep 0.001`) inside the test's work block ahead of the raise guarantees `waiting?` → no warn. `core/loop.rb` untouched (out of scope). | fix is test-side, sanctioned |
| 5 | test_helper.rb need | polish owns it | No change needed — untouched (git status clean for it). | n/a |

### Disagreements

None. Checked before concluding the spec is sound for this lane: the two oracle citations (findings 1-2), the async gem source for the warn condition (finding 3), the kernel's supervisor ordering (`lib/raspberry_pi/core/loop.rb:141-172` — supervisor task created before `frame_loop`, work fiber cannot resume until the reactor yields), and the baseline suite output.

### Diff summary

```
 lib/raspberry_pi/agent/loop.rb | comment-only (12 +/-4 lines, all leading-#; strip_thinking_replay body byte-identical)
 test/kernel_carryin_test.rb    | test_raising_work_terminates_poller_and_reraises: work block now yields
                                | (sleep 0.001) before `raise "work boom"`; assertions unchanged (16 total before and after)
```

No commits made (`git log` head `516d85a`, `git status` = 2 modified files only).

### Test-suite output (verbatim, post-change)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
Run options: --seed 38508

# Running:

....................................................................................

Finished in 14.832530s, 5.6632 runs/s, 22.7878 assertions/s.

84 runs, 338 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

Baseline (pre-change, same tree): `84 runs, 338 assertions, 0 failures, 0 errors, 0 skips` — assertions identical, nothing weakened.

### Gate outputs (verbatim)

```
# stderr-quiet
$ bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
NO_WARN

# editor-guard (other lanes' files; chat/tui tests exist in this worktree)
$ timeout 120 bundle exec ruby -Itest test/chat_test.rb test/tui_test.rb && echo EDITOR_OK
16 runs, 60 assertions, 0 failures, 0 errors, 0 skips
EDITOR_OK

# markdown-guard
$ ls test/markdown_test.rb
ls: test/markdown_test.rb: No such file or directory
NOT RUNNABLE: wave-1 markdown lane deliverable (not created, per lane notes)

# tui-seam
$ test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
SEAM_OK

# bench-seam
$ timeout 90 bundle exec ruby bench/seam_bench.rb
SEAM_BENCH_OK

# gem-pins
$ grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
PINS_OK

# stderr-clean
$ bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
NO_EPIPE
```

### Determinism of the warn fix

5 seeded reruns of `bundle exec ruby -Itest test/kernel_carryin_test.rb`, each:
`7 runs, 16 assertions, 0 failures, 0 errors, 0 skips` — stderr clean of "unhandled exception" on every run.

### Parity-deviation table

| Deviation | Status |
|---|---|
| (none new) | The port's replay suppression vs pi's reasoning-field replay is the pre-existing I05-ratified deviation; the corrected comment now itemizes it in place (loop.rb:301-307) with oracle citations. |

### Judgment calls

| Call | Detail |
|---|---|
| Warn-fix mechanism | Test-side reactor yield (`sleep 0.001`) before the raise rather than any kernel change: `core/**` is out of scope, and the yield makes async's own suppression condition (`@promise.waiting?`, task.rb:225) deterministically true because the kernel's supervisor task registers `work_task.wait` greedily before the reactor re-schedules the work fiber. Failure semantics asserted are unchanged: `assert_raises(RuntimeError, "work boom")` + `refute poller.thread.alive?`. |
| test_helper.rb | Owned by this lane but left untouched — no fixture change required. |

### Files

- `lib/raspberry_pi/agent/loop.rb` — comment-only correction of `strip_thinking_replay`'s pi-behavior claim
- `test/kernel_carryin_test.rb` — raising-work test yields to the reactor before raising (warn suppressed, assertions identical)

STATUS: COMPLETE

### editor

### Lane: editor (I06 wave 1)

## Scope executed

Input-line editor in `lib/raspberry_pi/render/chat.rb` + seam additions in `lib/raspberry_pi/tui.rb`: fake cursor at the insertion point (cell-readback-provable), mid-line editing, in-memory history (pi's editor.ts semantics), word-wise operations (pi's word-navigation.ts semantics), README key-binding docs. Files touched (exactly the lane set): `lib/raspberry_pi/render/chat.rb`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `README.md`. No git write commands run (`git status` clean pre-work; `git diff` only, shown to architect).

## PHASE 0 findings (verify items, spec-vs-reality)

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | `Frame#set_cursor_position` exists in ratatui_ruby 1.5.0 | ✅ | `frame.rb:193–244` (`:method: set_cursor_position`, native) |
| 2 | Hardware cursor reachable through the port's inline-viewport draw path? | ❌ NO — kernel draws via the tree form `RatatuiRuby.draw(widget)` (`ratatui_ruby.rb:320` → private native `_draw(tree)`); `set_cursor_position` exists only on the Frame of the **block** form. `Widgets::Cursor` in a raw array tree does not move it either (measured below) | `ratatui_ruby.rb:314–337`; experiment row A |
| 3 | Hardware cursor cell-readback-provable on the headless test terminal? | ❌ NO — `get_cell_at` returns buffer cells (symbol/fg/bg/underline_color/modifiers); a hardware cursor position is not a cell. AC2's frozen property is cell readback | `cell.rb`; experiment rows A/B |
| 4 | Fake cursor (pi's approach) cell-readback-provable? | ✅ YES — a span with `modifiers: [:reversed]` reads back `[symbol, [:reversed]]` mid-line, and a reversed trailing space survives at end-of-line | `tui.ts:199–207 renderFakeCursor`, `editor.ts:583–597` (oracle); `style/style.rb:86–89` (modifier vocabulary: bold/dim/italic/underlined/slow_blink/rapid_blink/reversed/hidden/crossed_out), `cell.rb:36–38,128–131` (`modifiers` readback + `reversed?`); experiment rows B/C |
| 5 | `TUI.key_event(code, modifiers:)` shape | ✅ `Event::Key.new(code:, modifiers: [], kind: :standard)`; modifiers strings `"ctrl"/"alt"/"shift"`; codes `"left" "right" "up" "down" "home" "end" "backspace" "delete"` | `tui.rb:178–179` (port), `event/key.rb:100–163`, `event/key/navigation.rb:56` (`del:` → `"delete"`) |
| 6 | Which key events the kernel forwards to `Render::Chat#on_event` | Everything except STOP/WAKE/INTERRUPT sentinels and in-band Ctrl+C (`TUI.ctrl_c?`) — the editor sees code+modifiers for arrows/ctrl-w/alt-b/f/delete unchanged | `core/loop.rb:292–307` (`process`) |
| 7 | Real-gem `Key#text?` | `code.length == 1` — **ignores modifiers**, so alt+f is `text?` true; the port's printable guard `!(modifiers & %w[ctrl alt]).any?` is load-bearing | `event/key/character.rb:26–27` |
| 8 | test_helper `KeyEvent` double divergence | Double's `text? = code.length == 1 && !ctrl?` (alt-modified single chars are text?); with the printable guard both real and double behave identically → **no test_helper change needed, nothing to raise** | `test/test_helper.rb` |
| 9 | pi history semantics | `editor.ts:427–438 addToHistory`: trim, skip empty, skip consecutive duplicate, unshift, cap 100. `navigateHistory` :454–484: index −1 = live draft; up walks older; down back toward draft; draft captured on entering browsing, restored at −1; up places cursor at **start**, down at **end** | oracle `components/editor.ts` |
| 10 | pi word-boundary semantics | `word-navigation.ts:17–70` + `utils.ts:1006 PUNCTUATION_REGEX`, :1011 `isWhitespaceChar`: skip trailing whitespace, then one boundary unit — word-like segment (with the ASCII-punct sub-rule: stop after the last punct match inside it) or non-word non-whitespace run. Measured consequence ported exactly: on `"hello world"` ctrl+w deletes `"world"` **keeping the separator space** (pi cursor lands at 6, not 5); on `"hello "` it deletes `"hello "` (whitespace is trailing) | oracle files; test_find_word_backward_boundaries |
| 11 | pi keybindings defaults | `keybindings.ts:82–145`: cursorLeft `left/ctrl+b`; cursorRight `right/ctrl+f`; cursorWordLeft `alt+left/ctrl+left/alt+b`; cursorWordRight `alt+right/ctrl+right/alt+f`; cursorLineStart `home/ctrl+a`; cursorLineEnd `end/ctrl+e`; deleteCharBackward `backspace`; deleteCharForward `delete/ctrl+d`; deleteWordBackward `ctrl+w/alt+backspace`; deleteWordForward `alt+d/alt+delete`; submit `enter` | oracle `keybindings.ts` |
| 12 | pi markdown theme/token surface (markdown lane's file — verified for the findings record, not built by this lane) | `markdown.ts:198–213` theme fns; `theme.ts:1023–1033` token mapping; `system-theme.ts:87–117` dark-theme slots (heading yellow, link blue+underline, linkUrl neutral, code violet, codeBlock green, quote/hr/borders neutral, listBullet violet); `StrictStrikethroughTokenizer` `markdown.ts:9–19`; heading/list/blockquote/code/hr rendering `markdown.ts:426–450, 563–610, 763–815` | oracle files |
| 13 | markdown-guard runnable in this worktree | ❌ NOT RUNNABLE — `test/markdown_test.rb` does not exist here (wave-1 markdown lane deliverable). Recorded; not created | `ls test/` |
| 14 | Baseline suite before work | 84 runs, 338 assertions, 0 failures, 0 errors, 0 skips | run at 19:19 |

Experiments (verbatim, ratatui_ruby 1.5.0, headless inline test terminal):

```
# A: hardware cursor unreachable via tree form
RatatuiRuby.draw([RatatuiRuby::Widgets::Paragraph.new(text: "hello"),
                  RatatuiRuby::Widgets::Cursor.new(x: 8, y: 0)])
RatatuiRuby.get_cursor_position  # => [1, 3]   (viewport base, NOT (8,0))
RatatuiRuby.get_cell_at(8, 0)    # => [" ", nil, []]

# B: fake cursor mid-line — reversed grapheme reads back
spans ["❯ hi", "X" reversed, " there"] → get_cell_at(4, 0) # => ["X", nil, [:reversed]]

# C: fake cursor end-of-input — reversed trailing space reads back
spans ["❯ hi", " " reversed] → get_cell_at(4, 0) # => [" ", nil, [:reversed]]
```

## Cursor mechanism (the lane's PHASE 0 call)

**Fake cursor** (pi's `renderFakeCursor` analog): the grapheme at the insertion point renders with the `reversed` modifier; at end-of-input a highlighted trailing space. Why: findings #2/#3 — the hardware cursor is unreachable through the port's tree-draw seam (`set_cursor_position` is block-form-Frame-only) and is not cell-readback-provable in any case; the reversed modifier is proven readable on the headless terminal (experiment C). Frozen property (readback-visible distinction at end-of-input and mid-input) met.

## Judgment calls

- **Key-binding table (ported; ported from `keybindings.ts` defaults, port key surface = code + ctrl/alt/shift):**

  | Key | Action |
  |---|---|
  | printable chars | insert at cursor |
  | Left / Right (+ Ctrl+B / Ctrl+F) | cursor one char |
  | Backspace | delete before cursor |
  | Delete / Ctrl+D | delete after cursor |
  | Home / End (Ctrl+A / Ctrl+E) | line start / end |
  | Alt+Left, Ctrl+Left, Alt+B | word backward |
  | Alt+Right, Ctrl+Right, Alt+F | word forward |
  | Ctrl+W, Alt+Backspace | delete word backward |
  | Alt+D, Alt+Delete | delete word forward |
  | Up / Down | history previous / next |
  | Enter | submit (steer when busy) |

- **History recall semantics as ported** (`Chat#add_to_history`/`navigate_history`): trimmed submissions only; consecutive-duplicate suppression; cap 100 (HISTORY_LIMIT); most recent first; index −1 = live draft, captured when browsing starts and restored on Down past the newest; Up places the cursor at line start, Down at line end (pi's `cursorPlacement`); any editing/movement key exits browsing (pi `exitHistoryBrowsing`).
- **Recorded simplifications (parity table):**
  1. Edit/move units are **chars**, not grapheme clusters (pi segments graphemes; the port's input is single-line plain text today).
  2. `Intl.Segmenter` word-like segments approximated by word-character runs (`[[:alnum:]_]]`) with pi's exact ASCII `PUNCTUATION_REGEX` set as boundaries — for every representative input the landing position matches (verified: `hello world|`→6, `hello |`→0, `foo.bar|`→4, `foo.|`→3); recorded, not silent.
  3. Up/Down **always** navigate history (pi only from the first/last visual line of its multi-line editor; the port is single-line).
  4. Any non-history key exits history browsing; pi's exact per-handler set was not exhaustively enumerated (observable difference: none for the single-line case).
  5. Input longer than one row clips at the viewport edge (pre-existing; pi scrolls horizontally) — unchanged this lane.
  6. Modified navigation keys on a **real** terminal (ctrl+left etc.) could not be verified headless (no tty); bindings follow pi's defaults and are proven through synthetic events, which is the port's only testable key surface.
- **Parity deviations adopted:** none beyond the recorded simplifications above. AC2/AC3 are met as written; no AC conflicts found.
- **Existing test comment updated:** `test_input_line_edits_and_submits`'s ctrl+e line — previously "non-printing: ignored", now ctrl+e is bound (move-to-end); assertion unchanged and still true (buffer untouched).

## Gate results (verbatim)

| Gate | Result | Output |
|---|---|---|
| suite-green | ✅ PASS | `98 runs, 387 assertions, 0 failures, 0 errors, 0 skips` + `SUITE_OK` |
| editor-guard | ✅ PASS | `29 runs, 102 assertions, 0 failures, 0 errors, 0 skips` + `EDITOR_OK` |
| tui-seam | ✅ PASS | `SEAM_OK` |
| bench-seam | ✅ PASS | `SEAM_BENCH_OK` (mean fps/synthetic p95 within self-asserted thresholds) |
| gem-pins | ✅ PASS | `PINS_OK` |
| stderr-clean | ✅ PASS | `NO_EPIPE` |
| stderr-quiet | ❌ FAIL in this worktree — **not this lane's file** | 1 × `"Task may have ended with unhandled exception."` from `test/kernel_carryin_test.rb:34` (`work boom`) — the pre-existing I04 warn; the fix lives in `test/kernel_carryin_test.rb`/`test/test_helper.rb` (polish lane's touch set, outside my boundaries). Expected to go green at wave-1 integration when polish merges. |
| markdown-guard | ⚠ NOT RUNNABLE in this worktree | `test/markdown_test.rb` does not exist yet (markdown lane deliverable); recorded per lane notes, not created |

Suite verbatim (final full run):

```
Finished in 14.825263s, 6.6103 runs/s, 26.1041 assertions/s.
98 runs, 387 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

New editor tests (all cell-readback or public-path, no mocks/stubs of the class under test): cursor readback at end-of-input and mid-input after Left (and back after Right); cursor hidden while the approval prompt holds the row; printable insert at cursor; backspace-before / forward-delete-after; Home/End/Ctrl+B/Ctrl+F; history order (A,B → up=B, up=A, down=B, down=draft); recalled entry editable and sends as edited (scrollback echo `❯ !A`); duplicate/empty submissions enter history once; pure `find_word_backward`/`find_word_forward` boundary tables; Ctrl+W through the key surface; Alt+B/Alt+F word jumps.

## Files

- `lib/raspberry_pi/tui.rb` — `TUI.span` (fg + modifier span vocabulary), `TUI.line` (String → single span; array of spans → multi-span row), `TUI::Session#cell_modifiers` (readback).
- `lib/raspberry_pi/render/chat.rb` — `@cursor` + history state; `edit_input` dispatch (pi keybindings); `add_to_history`/`navigate_history`; editing primitives (insert/delete_backward/delete_forward/move_*/delete_word_*); `find_word_backward`/`find_word_forward` (pure, `class << self`); `input_spans` (fake-cursor row); `submit` records history.
- `test/chat_test.rb`, `test/tui_test.rb` — 15 new tests + span vocabulary test.
- `README.md` — Usage: input-line editing section (cursor, key-binding table, history semantics).

No commits made; working tree left uncommitted for the architect.

STATUS: COMPLETE_WITH_CONCERNS — (1) stderr-quiet fails in this worktree: the pre-existing async "unhandled exception" warn from `test/kernel_carryin_test.rb:34` is the polish lane's AC1 deliverable; I did not touch its files (outside my boundaries) and it should pass at integration; (2) markdown-guard not runnable here (`test/markdown_test.rb` is the markdown lane's new file); (3) recorded simplifications in the parity table above (chars vs graphemes, word-run vs Intl.Segmenter, up/down always navigate, unverified real-terminal arrival for modified navigation keys).

### markdown

Lane: markdown (wave 1). Working dir: build/I06-editor-markdown-markdown/wt @ 516d85a (project/pi-port base). No commits made (git log stays at 516d85a; `git status --short` = ` M lib/raspberry_pi.rb`, `?? lib/raspberry_pi/render/markdown.rb`, `?? test/markdown_test.rb`).

### PHASE 0 findings (spec-vs-reality, file:line evidence)

| # | Verify item | Spec claim | Reality | Evidence |
|---|---|---|---|---|
| 1 | MarkdownTheme function surface | ≈markdown.ts:198-213 | Exact: `interface MarkdownTheme` at :198-214 — heading, link, linkUrl, code, codeBlock, codeBlockBorder, quote, quoteBorder, hr, listBullet, bold, italic, strikethrough, underline, highlightCode?, codeBlockIndent? | repos/pi/packages/tui/src/components/markdown.ts:198-214 |
| 2 | Theme colors (interactive) | port the observable distinctions | `getMarkdownTheme()` = fg roles only: mdHeading=yellow, mdLink=blue, mdLinkUrl=muted, mdCode=violet, mdCodeBlock=green, mdCodeBlockBorder=muted, mdQuote=muted, mdQuoteBorder=muted, mdHr=muted, mdListBullet=violet | theme/theme.ts:1022-1036; theme/dark.json:42-51 (light.json identical :42-51) |
| 3 | Token handling: list/blockquote/code | ≈markdown.ts:148-160 | Block cases: code :530-550 (border fences + "  " indent, `codeBlockIndent ?? "  "` :531), list :552-554 (no trailing spacing) + renderList :766-806 (normalized `- `/`N. ` bullets :775-779, continuation indent to marker width :781-782, nested lists unprefixed :794-798, loose blank rows, empty item keeps bare marker :804-806), blockquote :566-612 ("│ " quoteBorder prefix, quote(italic) :567), hr :615-617 (`"─" * min(width, 80)`), space → "" :594-596, heading :473-499 (h1 = heading(bold(underline)) :481-483, h3+ styled `#`-prefix :493), paragraph :501-507 | markdown.ts (same file) |
| 4 | Inline token handling | — | strong :683-687, em :689-693, codespan :695-697 (raw text, no nesting), link :699-719 (link(underline(text)); OSC-8 if hyperlinks else linkUrl ` (href)` fallback unless text==href / mailto-equal :711-719), del :725-729, escape :681-682 | markdown.ts |
| 5 | StrictStrikethroughTokenizer | markdown.ts:9 | `STRICT_STRIKETHROUGH_REGEX = /^(~~)(?=[^\s~])((?:\\.|[^\\])*?(?:\\.|[^\s~\\]))\1(?=[^~]|$)/` — content may not start/end with whitespace or `~` | markdown.ts:8-21 |
| 6 | ratatui_ruby 1.5.0 Style modifiers | which modifier symbols exist | `:bold, :dim, :italic, :underlined, :slow_blink, :rapid_blink, :reversed, :hidden, :crossed_out`; named colors incl. `:yellow, :green, :gray, :light_blue, :light_magenta` — all vocabulary choices are valid symbols | gem lib/ratatui_ruby/style/style.rb (modifiers doc block, colors :46-53) |
| 7 | Cell readback surface (AC2/AC5 proof mechanism) | `Cell#fg` proven | `TUI::Session#cell_fg(x,y)` → `RatatuiRuby.get_cell_at(x, y).fg` exists in the port; NOT exercised by this lane — cell-readback proof belongs to the wave-2 markdown-seam lane (AC5) | lib/raspberry_pi/tui.rb (Session#cell_fg) |
| 8 | Editor verify items (set_cursor_position reachability, key_event arrivals, word-navigation semantics) | PHASE 0 of lane `editor` | Out of this lane's scope; not verified here, not duplicated | — |
| 9 | test/test_helper.rb | raise if needed | Shared `RaspberryPi::Test` base used unchanged; nothing needed | test/test_helper.rb |
| 10 | No markdown gem in bundle | hand-rolled default | No markdown parser gem present (Gemfile.lock: async, ratatui_ruby, ruby_llm + dev); hand-rolled implemented — no gem proposed, no new deps | Gemfile, Gemfile.lock |

### Disagreements / judgment calls

| # | Item | Call + reason |
|---|---|---|
| 1 | "code" in the span vocabulary (Spec deliverable 4) | Carried as fg role (`:light_magenta`), not a `code` boolean: pi's `code` theme fn is fg-only (theme.ts:1027) and ratatui 1.5.0 has no code modifier (style/style.rb modifiers list). AC4's letter (observable distinction) is satisfied; no conflict. |
| 2 | hr width | Converter takes `width:` kwarg (nil → cap 80): pi sizes hr to content width capped at 80 (markdown.ts:616); the converter has no terminal context, the seam passes viewport width. |
| 3 | Gem-neutrality test stricter than the gate | `test_converter_source_is_gem_neutral` refutes the bare token `RatatuiRuby` anywhere in the file (the tui-seam gate greps `RatatuiRuby\.`); the class comment reworded to keep even the prose clean. |
| 4 | Hand-rolled parser | No disagreement: the subset is ~10 constructs; a CommonMark engine would be a new runtime dep (forbidden without raised disagreement) for behavior we'd immediately subset. |

### Markdown vocabulary shape (for the wave-2 markdown-seam lane)

- `Render::Markdown.rows(text, width: nil)` → `Array<Array<Span>>`; one row per display line; empty row = blank line.
- `Render::Markdown::Span` = `Struct(text, fg, modifiers, keyword_init: true)`; `fg` = `TUI.style` color symbol or nil; `modifiers` = subset of `[:bold, :italic, :underlined, :crossed_out]` (ratatui modifier names).
- Seam conversion: row → `TUI::Text::Line`, span → `TUI::Text::Span` (`fg` → `Style#fg`, `modifiers` → `Style#modifiers`); document in lib/raspberry_pi/render/markdown.rb class comment.

### Parity-deviation table (itemized; nothing silent)

| Deviation | pi behavior | Port behavior | Why |
|---|---|---|---|
| OSC-8 hyperlinks | rendered when terminal supports (markdown.ts:702-709) | linkUrl ` (href)` fallback always (markdown.ts:711-719) | terminal hyperlinks out of scope (spec) |
| Paragraph soft breaks | single line with `\n`, wrapped later | one row per soft break | rows are display lines; wrapping is the seam's concern |
| Flanking rules | full CommonMark/marked delimiter runs | approximated: padded delimiter content → literal; intraword `__` allowed | hand-rolled subset; edge cases itemized here |
| Quote inner styling | outer ANSI prefix trick (markdown.ts:573-583) | default-fg spans recolored gray + italic; colored spans keep fg, gain italic | matches pi's observable behavior (inner ANSI colors survive) |
| Tables / LaTeX / html tokens / task markers / syntax highlighting (`highlightCode`) / `codeBlockIndent` option | supported | not ported | out of subset (spec) |
| List nesting depth | arbitrary (marked) | arbitrary via recursion (indent 4 spaces/depth) | ported |

### Gate commands (verbatim results, this run)

| Gate | Result | Output |
|---|---|---|
| suite-green | PASS | `bundle exec rake` → `109 runs, 369 assertions, 0 failures, 0 errors, 0 skips`, exit 0 (no `SUITE_OK` echo form run — rake itself exited 0) |
| markdown-guard | PASS | `25 runs, 31 assertions, 0 failures, 0 errors, 0 skips` + `MD_OK` |
| tui-seam | PASS | `SEAM_OK` |
| gem-pins | PASS | `PINS_OK` |
| bench-seam | PASS | `SEAM_BENCH_OK` (exit 0) |
| editor-guard | PASS | `16 runs, 60 assertions, 0 failures, 0 errors, 0 skips` (chat/tui untouched, still green) |
| golden_parity_test.rb | PASS | `10 runs, 89 assertions, 0 failures, 0 errors, 0 skips` |
| stderr-quiet | FAIL (expected — polish lane's AC1, not this lane's files) | suite stderr carries `"message":"Task may have ended with unhandled exception."` from test/kernel_carryin_test.rb:34 raising work — exactly the defect lane `polish` must fix |

### Files

| File | Change |
|---|---|
| lib/raspberry_pi/render/markdown.rb | new — `Render::Markdown` converter + `Span` vocabulary, zero gem references |
| lib/raspberry_pi.rb | one added line: `require_relative "raspberry_pi/render/markdown"` |
| test/markdown_test.rb | new — 25 tests, every subset construct asserted with markdown.ts file:line citations |

STATUS: COMPLETE_WITH_CONCERNS — (1) gate stderr-quiet fails at this tip pending lane `polish`'s AC1 fix (evidence above; outside my touch set); (2) cell-readback proof of the vocabulary is deferred to wave-2 markdown-seam per the lane plan (AC5).

### markdown-seam

### PHASE 0 findings

| # | Verify item | Evidence (this run unless noted) | Verdict |
|---|---|---|---|
| 1 | `Frame#set_cursor_position` (ratatui_ruby 1.5.0 frame.rb:193–200) reachable / cell-readable? | Port never calls it (`grep set_cursor_position\|show_cursor -r lib/` → no matches); it positions the terminal hardware cursor, not a buffer cell — not observable via `get_cell_at`. Editor lane's fake cursor (base commit 728428d) is the only readback-provable mechanism. No change needed. | confirmed |
| 2 | Style modifier vocabulary | `style/style.rb`: modifiers are `:bold :dim :italic :underlined :slow_blink :rapid_blink :reversed :hidden :crossed_out`; `buffer/cell.rb:55,131` — `Cell#modifiers` reads back as symbol array. Probe this run: `:yellow` fg + `[:bold]` read back on the headless inline terminal. | confirmed |
| 3 | `TUI.key_event(code, modifiers:)` + kernel forwarding | tui.rb:178–179 confirmed; kernel forwards every non-interrupt key event to `on_event` (core/loop.rb:280–287). Binding surface = `edit_input`'s case in chat.rb; all editor tests in base green. | confirmed |
| 4 | pi oracle markdown.ts citations (converter consumed, not modified) | Spot-checked `repos/pi/packages/tui/src/components/markdown.ts`: StrictStrikethroughTokenizer :9–21, theme interface :199–213, heading :473–499, hr :612–618, link :699–719 — in-base `Render::Markdown` citations accurate. | confirmed |
| 5 | Empty markdown row → blank line (seam dependency) | Probe this run: `Text::Line.new(spans: [])` in a Paragraph renders exactly one blank row on the headless inline terminal. | confirmed |
| 6 | Line/Span/Style constructors off-frame | Gem `text/line.rb`, `style/style.rb`: pure `Data` objects, no terminal session required — building markdown Lines on the agent fiber is safe. | confirmed |

### PHASE 0 disagreements / scope statements

1. **Row wrapping is a seam responsibility the spec does not name (scope addition, raised):** `Render::Markdown.rows` wraps only the hr; the frozen base test `test_completed_message_lands_above_the_live_region_wrapped` requires prose to wrap at width. Added `Chat.wrap_row` (styled-row word wrap reusing the existing `fit`, break-space consumption identical to `wrap`) in chat.rb — inside the touch set.
2. **Conversion shape:** `TUI.markdown_line(row)` accepts duck-typed spans (`text`/`fg`/`modifiers`) — tui.rb never references `Render::Markdown`, keeping tui.rb the gem-only seam with no require cycle.
3. **Dead key removed:** `FG[:assistant]` (nil) became unused once completions render markdown; removed it and updated the palette comment. Existing tests referenced only `FG[:status]/[:tool]/[:user]`.
4. No disagreements with the spec's ACs, boundaries, or parity requirements. README (editor lane's, AC3) already documents the key bindings in base — verified present, untouched.

### Judgment calls

| Call | Decision |
|---|---|
| Cursor mechanism | pi's fake cursor (reversed modifier) — already in base; hardware cursor unreachable through the tree-draw seam and not cell-readable (finding 1). |
| Markdown render point | At `message_end` (completion) only; live region streams raw source verbatim. Deviation table below. |
| Span→Line conversion | `TUI.markdown_line(row)` → `TUI.line(row.map { TUI.span(...) })`; empty row → Line with `spans: []` → one blank row (probe-verified). |
| Styled-row wrap | `Chat.wrap_row` reuses `fit` (same word-break/space-consumption semantics as plain `wrap`); spans re-grouped per wrapped line by source-span identity (`styled_row`); fitting rows and blank rows pass through unchanged. Same width-vs-char-index simplification as the pre-existing `fit`. |
| Assistant styling source | Per-span styles from the converter's vocabulary; plain prose keeps terminal default (converter's paragraph styling), so `test_user_assistant_tool_and_status_lines_read_back_distinct_fg_colors` holds unmodified. |
| Scrollback entry format | Changed from `[lines, fg]` pairs to final `TUI::Text::Line` arrays built at enqueue time (plain path wraps+fgs; markdown path converts); `flush_scrollback` just inserts. Internal representation, no public-interface change. |

### Parity-deviation table (itemized)

| Deviation | Reason |
|---|---|
| pi renders markdown while streaming; the port renders markdown at completion only — the live region carries verbatim streaming text | The live region is the ratatui_ruby inline viewport re-rendered per frame; restyling mid-stream would require markdown re-conversion per delta. Sanctioned shape per the lane brief; test-pinned by `test_live_region_streams_markdown_source_verbatim`. |
| Markdown scrollback rows wrap via `Chat.wrap_row` (char-index/width conflation for multi-cell-width chars), not pi's grapheme-aware wrap | Same recorded simplification as the pre-existing `Chat.wrap`/`fit`. |
| Converter-level approximations (soft breaks as rows, flanking-rule approximation, intraword `__`, no OSC-8) are inherited from `Render::Markdown` (markdown lane's record) — unchanged by the seam. | out of seam scope |

### Files changed

| File | Change |
|---|---|
| lib/raspberry_pi/tui.rb | +9: `TUI.markdown_line(row)` (markdown-vocabulary row → `Text::Line`). |
| lib/raspberry_pi/render/chat.rb | Assistant completions route `message_end` → `enqueue_markdown` (`Render::Markdown.rows(width:)` → `Chat.wrap_row` → `TUI.markdown_line`); `enqueue_scrollback` builds plain lines at enqueue; `flush_scrollback` inserts final Lines; removed dead `FG[:assistant]`; +`wrap_row`/`styled_row`. |
| test/chat_test.rb | +5 tests: markdown styled scrollback (cell readback: heading `:yellow`/`[:bold, :underlined]`, strong `[:bold]`, plain default), verbatim streaming live region, kernel-driven markdown end-to-end (MockLLMServer), `wrap_row` purity; +`scrollback_cells` helper. |
| test/tui_test.rb | +1 test: `markdown_line` fg/modifier readback + blank-line row. |

### Gate results (verbatim)

| Gate | Result |
|---|---|
| suite-green | `128 runs, 434 assertions, 0 failures, 0 errors, 0 skips` exit=0 (baseline pre-lane: 123 runs, 418 assertions, 0 failures) |
| stderr-quiet | `NO_WARN` (grep -ci 'unhandled exception' → 0) |
| editor-guard | `33 runs, 114 assertions, 0 failures, 0 errors, 0 skips` |
| markdown-guard | `25 runs, 31 assertions, 0 failures, 0 errors, 0 skips` |
| tui-seam | `SEAM_OK` |
| bench-seam | `SEAM_BENCH_OK` (timeout 90 not hit) |
| gem-pins | `PINS_OK` (ratatui_ruby 1.5.0, minitest 5.x, ruby_llm 2.x) |
| stderr-clean | `NO_EPIPE` |

Git state: branch lane/I06-editor-markdown-markdown-seam at 728428d, working tree modified in exactly the four lane files (`git status --short` above), no commits made.

STATUS: COMPLETE

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
