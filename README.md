# repohealth

`repohealth` is a single-file Bash utility for scanning a directory tree and summarizing the state of nested Git and Jujutsu repositories. It focuses on two questions:
- What needs to be pushed?
- What has local working-copy changes?

The script is designed for fast workspace sweeps where you want one aligned view across many repos without opening each repo individually.

## Features

- Recursively discovers nested `.git` and `.jj` repositories.
- Prefers `jj` when a repo root contains both Git and Jujutsu metadata.
- Reports Git outgoing, behind, diverged, and working-copy states.
- Reports Jujutsu outgoing commit counts, draft commits, and working-copy changes.
- Collects per-repo state in parallel by default for faster workspace sweeps.
- Supports a compact table view, a minimal view for narrow terminals, a per-repo detail view, a fancy detail view with enhanced block-char rendering, and JSON output.
- In detail output, Jujutsu outgoing sections show a per-commit stat breakdown for pushable commits.
- Supports a check mode for scripting and automation.

## Requirements

- `bash`
- `find`
- `awk`
- `git` for Git repos
- `jj` for Jujutsu repos
- `fd` or `fdfind` is optional; used for faster repo discovery when available, falls back to `find`
- `realpath` is optional; the script falls back to `pwd -P`

The script is intended to work on both macOS and Linux.

## Usage

```bash
./repohealth [options] [directory]
```

If `directory` is omitted, the current directory is scanned.

### Options

- `-d`, `--dirty` shows only repos that are not fully clean.
- `-n`, `--depth N` limits traversal depth.
- `-c`, `--check` exits non-zero when any repo needs attention.
- `-e`, `--exclude PATTERN` skips repos whose path matches the ERE. May be repeated to exclude multiple patterns.
- `-r`, `--remote NAME` overrides the remote used for Jujutsu push checks.
- `-j`, `--jobs N` limits parallel repo-state workers. By default, repohealth auto-detects CPU count with a floor of 8 workers. Use `--jobs 1` for sequential collection.
- `-o`, `--output FORMAT` sets the output format. Supported values: `table`, `minimal`, `detail`, `fancy-detail`, `json`.
- `-p`, `--paths STYLE` controls how repo paths are displayed. Supported values: `name` (repo basename, default), `relative` (path relative to the scan root), `full` (absolute path). JSON output defaults to stable unique paths unless `--paths` is set explicitly.
- `-N`, `--no-color` disables ANSI color output.
- `-D`, `--detail` is a compatibility alias for `--output detail`; with `--output json`, it also includes detail fields.
- `-h`, `--help` shows the help text.

## Examples

Scan the current workspace:

```bash
./repohealth
```

Show only repos that need attention:

```bash
./repohealth --dirty ~/src
```

Get detailed per-repo output:

```bash
./repohealth --output detail ~/src
```

Use the compact minimal view:

```bash
./repohealth --output minimal ~/src
```

Use in a shell check or automation:

```bash
./repohealth --check --dirty ~/src
```

Exclude repos matching a pattern:

```bash
./repohealth --exclude archived ~/src
```

Exclude multiple patterns:

```bash
./repohealth --exclude archived --exclude '\.bak$' ~/src
```

Output results as JSON:

```bash
./repohealth --output json ~/src
```

Output JSON with per-repo detail fields:

```bash
./repohealth --output json --detail ~/src
```

Use enhanced block-char rendering with per-repo detail:

```bash
./repohealth --output fancy-detail ~/src
```

Disable color output:

```bash
./repohealth --no-color ~/src
```

Force sequential collection for debugging:

```bash
./repohealth --jobs 1 ~/src
```

## Output Model

The default view prints one row per repo:

```text
myrepo  [git]  ↑ 2 outgoing  |  * 3 modified, 1 untracked
```

Minimal output uses a one-character VCS column (`g` for Git, `j` for JJ) and compact status cells:

```text
myrepo  g  ↑2 O  *3 M +1 U
```

Minimal mode is intentionally lossy for question and error reasons; use the default table or detail view when you need the explanatory text.

By default the human-readable views show only the repo basename. Use `--paths relative` to show paths relative to the scan root, or `--paths full` to show absolute paths.

The left status describes push state and the right status describes working-copy state.

Common push statuses:

- `- up to date`
- `↑ N outgoing`

For Jujutsu repos, this is the number of commits reachable from local bookmarks that are not yet on the selected remote bookmark ancestry.

- `↓ N behind`
- `↕ A ahead, B behind`
- `? no commits`
- `? no remote`
- `? no upstream`
- `~ N draft only`
- `! push check failed`

Common working-copy statuses:

- `- clean`
- `* N modified`
- `* N modified, N untracked`
- `* N untracked`
- `!! scan error`

At the end of every run, the script prints a summary line with scanned repo count, outgoing repo count, dirty repo count, and error count when applicable.

## Design Notes

- The project is intentionally a single self-contained Bash script named `repohealth`.
- There is no build, test, or lint pipeline.
- Output is collected first and rendered second so columns can be aligned consistently.
- Repo state collection runs in bounded parallel batches; rendering happens in sorted path order for stable output.
- Repo rows are written to stdout, while warnings and errors go to stderr.
- Discovery uses `fd`/`fdfind` when available for faster traversal; falls back to `find` otherwise.
- Discovery skips common heavy directories such as `node_modules`, `vendor`, `target`, `__pycache__`, `.svn`, and `.hg`.
- Linked Git worktrees referenced through `.git` files under `/worktrees/` are skipped intentionally.
- When both `.git` and `.jj` are present at the same root, the repo is treated as `jj`.
- In JSON output, the `path` field defaults to stable unique paths: relative to the scan root for single-root scans, and absolute for multi-root scans. Pass `--paths` explicitly to override that behavior.
- In JSON output, detail fields (outgoing commits, draft commits, working-copy changes) are structured arrays, not raw strings. Detail fields are only populated when `--detail` is requested alongside `--output json`.

## Validation Checklist

When changing the script, validate a few representative cases:

- Scan an empty directory.
- Scan a normal Git repo with no remote.
- Scan a clean Git repo with an upstream.
- Run `--dirty` against a fully clean repo and confirm it does not crash.
- Compare `--jobs 1` and the default run on the same workspace and confirm output matches.
- Run `--output detail` and confirm the detailed sections remain aligned and readable.
- If `jj` is installed, test a repo with draft commits and one with pushable bookmark changes.

## Snapshot Tests

There is still no formal build or test pipeline, but the repo now includes a lightweight Bash snapshot harness for visual output checks:

```bash
./tests/run
```

The harness creates temporary Git repos, runs `repohealth` with fixed terminal settings, and compares stdout, stderr, and exit codes against checked-in fixtures under `tests/fixtures/`.

For performance work, there is also a repeatable benchmark harness:

```bash
./tests/benchmark
```

It compares the current script against baseline ref `4ebf75e` on synthetic Git and JJ workspaces and reports median timings for default, detail-output, and job-count runs.

## Limitations

- Git status is compared against the configured upstream branch, not every remote branch.
- Jujutsu pushability and detail output rely on `jj git push --dry-run`, so behavior follows the installed `jj` version.
- The script reports repository state; it does not fetch, pull, push, or mutate repos.
