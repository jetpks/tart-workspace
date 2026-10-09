# pi-port

Space: `20261009-pi-port`
Created: 2026-10-09T02:03:09-06:00

## Organization

- `space.yaml` tracks the space identity, status, and associated metadata.
- `repos/` contains cloned Git repositories for this work.
- `notes/` is for task notes, scratch docs, and thinking-in-progress.
- `architecture/` holds the architect project memory (ARCHITECT.md and the per-iteration files).
- `tmp/` is the workspace-local scratch directory. Use it instead of `/tmp` or
  `/var/tmp`; when using `mktemp`, use `tmp/` as the base directory.
- `build/` holds the architect loop's per-lane worktrees and scratch
  (gitignored except `.keep`).
- The space is a Git repository so notes and architecture are versioned.
  `repos/`, `tmp/`, and `build/` are gitignored, keeping the cloned repos and scratch
  out of the space's history (each clone keeps its own Git repo).
