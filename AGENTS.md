- Keep this file small and concise.
- Update this file only when you have a new learning or a new rule is introduced.

# Docs
- See `README.md` for the full plan, design decisions, and validation checklist.

# Task Rules
- When adding or changing a feature, add or update the corresponding tests.
- Never consider a task complete until `./tests/run` passes with no failures.

# Architecture Restraints
- Single self-contained Bash script (`repohealth`). No build, test, or lint pipeline.
- No dependencies beyond `bash`, `find`, `awk`, `git`, and optional `jj` and `realpath`.
- Must run correctly on macOS and Linux.
- Normal repo output goes to stdout; warnings, per-repo errors, and startup errors go to stderr.
- Use two-pass rendering: collect repo data first, then print after widths are known.
- When both `.git` and `.jj` exist at the same root, treat the repo as `jj`.
- With `jj git push --dry-run`, only skip draft counting on the unambiguous clean path.
