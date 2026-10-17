# Idea — extract the markdown converter stack into a gem (post-program, owner backlog)

Owner + architect discussion 2026-10-17 (escalation-seat turn, while the
tart-standalone program runs). Status: **forward-looking, queued** — not
in-loop, not started. Preconditions below.

## The idea

After the tart-standalone program lands (ENTRY 4 included), the streaming
markdown processing stack is a separable, externally-usable piece worth
releasing as a standalone gem. Motivation is not need — there is no second
consumer in mind — it's that the piece is genuinely separable, it will carry
an oracle-frozen test battery (rare and valuable), and the owner likes
releasing gem "legos".

## Why it's unusually extractable (verified 2026-10-17)

- One file, 371 lines (`repos/tart/lib/tart/render/markdown.rb`), zero
  runtime deps, zero requires of tart internals. The tui-seam gate has
  enforced gem-neutrality on this file since I06 — it was kept clean for
  this without anyone promising the gem.
- Public surface is one class method: `Markdown.rows(text, width:)` →
  rows of `Span` structs.
- The theme is already a two-layer design: the converter emits raw semantic
  color symbols; `theme.rb` (`MD_SOURCE` → `md_fg`) remaps them. Extraction
  formalizes a decomposition that already exists.
- Wrapping is external by design (`Text.wrap_row` in the consumer).
- `bg` is never set by the converter (verified: only the Struct default;
  transcript.rb :513 injects panel bg downstream).

## The ruling shape: parse/render split, both halves in the gem

- **Parse layer (fully generic):** markdown text → semantic tree/stream —
  heading level, link + href, code span, list nesting, quote depth. Pure
  marked-18.0.11 CommonMark-subset behavior (flanking, strict
  strikethrough, escapes — ENTRY 4's work). Nothing tart in it.
- **Render layer (generic-but-opinionated):** the default terminal
  renderer producing exactly today's rows — same glyphs (`─`, `│ `), same
  indents, same `" (href)"` link suffix — with those choices **declared as
  the gem's policy constants**, not scattered literals. Consumers can
  override; tart passes nothing and gets byte-identical output.

**Tart keeps** (all already outside the converter): theme remap
(`MD_SOURCE`), wrapping (`Text.wrap_row`), bg injection (downstream).

## Span ownership (same problem space, decided in principle)

The generic styled run (text + fg + modifiers) goes to the gem; `bg` stays
tart's. Wrinkle to resolve at extraction time: tart's render surface
(panel.rb, text.rb, tui.rb) constructs `Markdown::Span` directly as its
*general* styled-rows vocabulary, not just markdown — so the gem becomes
the vocabulary owner and tart either consumes the gem's struct directly
(zero-dep, fine) or keeps a one-line local alias/subclass if surface-local
fields are ever wanted. Naming/ownership decision, not a rework.

## The battery travels unmodified

`rows` with default policy remains the public API, so the 48-case
oracle-frozen battery pins the gem exactly as it pins tart today — fixtures
move to the gem's suite untouched; tart runs a thin pin against the gem.
The tree layer gets pinned as a free byproduct if wanted.

## Attribution

Owner-confirmed: happy to attribute. NOTICE/CREDITS in the gem pointing at
pi's MIT `markdown.ts` (Mario Zechner) and the marked 18.0.11 oracle.

## Preconditions & sequencing

1. The whole coordinator program
   (`notes/plan-20261017T183001Z-tart-standalone.md`, run
   `f0e5dc7a-acfb-4b44-9510-6a59b2b9de33`) must land first — owner ruled
   no extraction before then, ENTRY 4 (markdown-parity-revisit) included.
   ENTRY 4 is what produces the battery-frozen, O(n)-guarded artifact; the
   tree-merged converter still has the flanking defect.
2. When it happens: a small successor plan entry (or owner-direct work) —
   gemspec, policy constants, Span ownership decision, battery moved to the
   gem suite, tart runs a thin pin against the gem.
