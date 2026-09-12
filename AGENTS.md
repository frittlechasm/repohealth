# Scope

- Keep only durable repo-specific guidance here; avoid repeating global instructions or skills.
- See `README.md` for installation, usage, and output semantics.
- Keep `repohealth` a self-contained Bash script with no build step.

# Restrictions
- Preserve Bash 3.2 compatibility on macOS and Linux, and Windows support through Bash.
- Keep runtime requirements to Bash, Git, and standard Unix tools.
- `jj`, `fd`/`fdfind`, and `realpath` remain optional.
- This restriction does not apply to development tools or skill workflows.

# Validation

- Add or update behavioral tests for feature changes and bug fixes.
- For CLI output changes, update affected snapshots in `tests/fixtures` and check narrow terminals.
- `LC_ALL=C`, and color suppression when relevant. Review snapshot diffs.
- Run `./tests/run` after changes; it must pass before the task is complete.
- For performance changes, compare output and timings on the same workspace.
- Use `tests/benchmark` for timing, not wall-clock assertions in regression tests.

# Behavior to preserve

- Send normal output to stdout and warnings and errors to stderr.
- Collect data before rendering, calculate widths across rows, and keep sorted output identical between scans.
- Keep full repo names visible by default; wrap rather than truncate them.
- Measure status symbols by display width, not byte length.
- Keep JSON paths stable and unambiguous by default, independent of human display names.
- Prefer JJ when `.git` and `.jj` coexist. If `jj` is unavailable, use Git for working-copy state.
- Count JJ outgoing commits from revsets, not bookmark actions or rendered stat lines.
- Only skip JJ draft counting on an unambiguous clean dry-run result.
- `Nothing changed.` alongside `No bookmarks found in the default push revset` is ambiguous.
