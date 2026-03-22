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
- Supports a compact table view and a per-repo detail view.
- In `--detail`, Jujutsu outgoing sections show a per-commit stat breakdown for pushable commits.
- Supports a check mode for scripting and automation.

## Requirements

- `bash`
- `find`
- `awk`
- `git` for Git repos
- `jj` for Jujutsu repos
- `realpath` is optional; the script falls back to `pwd -P`

The script is intended to work on both macOS and Linux.

## Usage

```bash
./repohealth [options] [directory]
```

If `directory` is omitted, the current directory is scanned.

### Options

- `--dirty` shows only repos that are not fully clean.
- `--depth N` limits traversal depth.
- `--no-color` disables colored output.
- `--check` exits non-zero when any repo needs attention.
- `--remote NAME` overrides the remote used for Jujutsu push checks.
- `--jobs N` limits parallel repo-state workers. Use `--jobs 1` for sequential collection.
- `--detail` prints expanded per-repo sections.
- `--fancy` enables experimental enhanced rendering.
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
./repohealth --detail ~/src
```

Use in a shell check or automation:

```bash
./repohealth --check --dirty ~/src
```

Force sequential collection for debugging:

```bash
./repohealth --jobs 1 ~/src
```

## Output Model

The default view prints one row per repo:

```text
path/to/repo  [git]  ↑ 2 outgoing  |  * 3 modified, 1 untracked
```

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
- Discovery skips common heavy directories such as `node_modules`, `vendor`, `target`, `__pycache__`, `.svn`, and `.hg`.
- Linked Git worktrees referenced through `.git` files under `/worktrees/` are skipped intentionally.
- When both `.git` and `.jj` are present at the same root, the repo is treated as `jj`.

## Validation Checklist

When changing the script, validate a few representative cases:

- Scan an empty directory.
- Scan a normal Git repo with no remote.
- Scan a clean Git repo with an upstream.
- Run `--dirty` against a fully clean repo and confirm it does not crash.
- Compare `--jobs 1` and the default run on the same workspace and confirm output matches.
- Run `--detail` and confirm the detailed sections remain aligned and readable.
- If `jj` is installed, test a repo with draft commits and one with pushable bookmark changes.

## Snapshot Tests

There is still no formal build or test pipeline, but the repo now includes a lightweight Bash snapshot harness for visual output checks:

```bash
./tests/run
```

The harness creates temporary Git repos, runs `repohealth` with fixed terminal settings, and compares stdout, stderr, and exit codes against checked-in fixtures under `tests/fixtures/`.

## Limitations

- Git status is compared against the configured upstream branch, not every remote branch.
- Jujutsu pushability and detail output rely on `jj git push --dry-run`, so behavior follows the installed `jj` version.
- The script reports repository state; it does not fetch, pull, push, or mutate repos.
