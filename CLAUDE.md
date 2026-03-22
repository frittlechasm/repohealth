- Keep this file small and concise.
- Update this file only when you have a new learning or a new rule is introduced.

# Docs
- Check `README.md` for the full plan, design decisions, and validation checklist.

# Rules
- Single self-contained Bash script (`repohealth`). No build, test, or lint pipeline.
- No dependencies beyond `bash`, `find`, `awk`, `git`, and optionally `jj` and `realpath`.
- Must run correctly on macOS and Linux.
- All repo output goes to stdout; warnings, per-repo errors, and startup errors go to stderr.
- Two-pass rendering: collect all repo data first, then print. Never stream output line by line — column alignment requires seeing all rows first.
- When both `.git` and `.jj` exist at the same root, always treat the repo as type `jj`.
