# Tart switched to OpenRouter (zai quota exhausted)

**2026-10-17, inline architect op. Not a loop iteration.**

The owner ran out of z.ai tokens. `~/.tart/models.json` now carries an
`openrouter` provider (baseUrl `https://openrouter.ai/api/v1`, apiKey copied
from `~/.pi/agent/auth.json` `.openrouter.key`, file chmod 600) with
`z-ai/glm-5.3` and `z-ai/glm-5.3-flash`, and `"default":
"openrouter/z-ai/glm-5.3"`. The zai provider entries stay in the catalog —
flip the default back when quota returns.

Facts and rulings baked in:

- **Compat mirrored from pi's own store.** The entry compat
  (`supportsDeveloperRole: false`, `thinkingFormat: "openrouter"`,
  `supportsStrictMode: true`) mirrors pi's `models-store.json` openrouter
  rows; `sendSessionAffinityHeaders` dropped (tart's compat subset doesn't
  carry it). Caveat: tart's `Models.dialect_for` only arms the **zai** arm —
  `"openrouter"` is schema-valid but rides the DEFAULT dialect
  (openai shape). That was wire-verified live against OpenRouter before
  committing: `reasoning_effort`, `max_completion_tokens`, and the developer
  role are all accepted (curl probe, 200/stop).
- **No thinking-behavior change.** Same thinkingLevelMap as the old zai
  entries (`medium: null` …), so the boot default `medium` still clamps to
  `max` — parity with the pre-switch config.
- **Boot precedence unchanged.** `PI_MODEL`/`PI_PROVIDER` env still override
  the catalog default; the shell already exports
  `PI_MODEL=z-ai/glm-5.3 PI_PROVIDER=openrouter`, which now resolves to the
  new entry. The catalog default covers shells without those exports.
- **Key hygiene.** The key is a plaintext copy in `~/.tart/models.json`
  (tart has no auth.json seam — provider `apiKey` is the designed tier).
  Rotating means updating both `~/.pi/agent/auth.json` and this file. The
  key is deliberately NOT in any repo.

Verified: `Tart::Models.load` clean (error nil), and
`bin/tart -p "Reply with exactly: openrouter-wired"` end-to-end with
`PI_MODEL`/`PI_PROVIDER` unset — resolved the catalog default, authenticated,
streamed the response.
