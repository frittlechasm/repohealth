- Keep this file small and concise.
- Update this file only when there is a new learning or a new rule is introduced.

## Docs

- Check `README.md` for the full plan, design decisions, and validation checklist.

## Rules

- The project is a single self-contained Bash script: `repohealth`.
- There is no build, test, or lint pipeline.
- Avoid dependencies beyond `bash`, `find`, `awk`, `git`, and optional `jj` and `realpath`.
- The script must run correctly on both macOS and Linux.
- Normal repo output goes to stdout; warnings, per-repo errors, and startup errors go to stderr.
- Use a two-pass render: collect repo data first, then print output after widths are known.
- When changing or adding new rendered CLI output, update the snapshot fixtures as needed and run `./tests/run`.
- When both `.git` and `.jj` exist at the same root, treat the repo as `jj`.
- `jj git push --dry-run` may print `Nothing changed.` for both clean repos and draft-only repos when no bookmarks are in the default push revset; only skip draft counting on the unambiguous clean path.
