#!/usr/bin/env sh

set -eu

program_name="${0##*/}"
repo_url="https://raw.githubusercontent.com/frittlechasm/repohealth"
version="${REPOHEALTH_VERSION:-main}"
install_dir="${REPOHEALTH_INSTALL_DIR:-${HOME:-}/.local/bin}"
bin_name="${REPOHEALTH_BIN:-repohealth}"
profile_updated=0

usage() {
  cat <<EOF
Usage: $program_name [--dir PATH] [--version REF] [--bin NAME]

Install repohealth for macOS and Linux.

Environment:
  REPOHEALTH_INSTALL_DIR  Install directory (default: ~/.local/bin)
  REPOHEALTH_VERSION      Git ref to install (default: main)
  REPOHEALTH_BIN          Installed command name (default: repohealth)
  REPOHEALTH_BASE_URL     Raw file base URL override
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*" >&2
}

os_family() {
  case "$(uname -s 2>/dev/null || printf unknown)" in
  Darwin) printf 'macos' ;;
  Linux) printf 'linux' ;;
  CYGWIN* | MINGW* | MSYS*) printf 'windows' ;;
  *) printf 'unknown' ;;
  esac
}

print_dependency_install_help() {
  missing="$1"
  family="$(os_family)"

  {
    printf 'Error: missing required dependencies: %s\n' "$missing"
    printf '\n'
    printf 'repohealth requires bash, find, awk, and git to run.\n'
    printf '\n'
    printf 'Install instructions:\n'
    case "$family" in
    macos)
      printf '  macOS:\n'
      printf '    xcode-select --install\n'
      printf '    brew install git\n'
      printf '    If find or awk is reported missing, make sure /usr/bin is on PATH.\n'
      ;;
    linux)
      printf '  Debian/Ubuntu:\n'
      printf '    sudo apt-get update && sudo apt-get install -y bash findutils gawk git\n'
      printf '  Fedora:\n'
      printf '    sudo dnf install bash findutils gawk git\n'
      printf '  Arch:\n'
      printf '    sudo pacman -S bash findutils gawk git\n'
      ;;
    windows)
      printf '  Windows:\n'
      printf '    Install Git for Windows: https://git-scm.com/download/win\n'
      printf '    Or run: winget install --id Git.Git -e\n'
      printf '    Then open Git Bash or make sure Git Bash is on PATH.\n'
      ;;
    *)
      printf '  Install bash, findutils, awk or gawk, and git with your OS package manager.\n'
      ;;
    esac
    printf '\n'
    printf 'Optional: install jj for Jujutsu repos, and fd or fdfind for faster discovery.\n'
  } >&2
}

require_runtime_dependencies() {
  missing=""
  for cmd in bash find awk git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      if [ -n "$missing" ]; then
        missing="$missing, $cmd"
      else
        missing="$cmd"
      fi
    fi
  done

  if [ -n "$missing" ]; then
    print_dependency_install_help "$missing"
    exit 1
  fi
}

add_path_line() {
  profile="$1"
  path_line="export PATH=\"$install_dir:\$PATH\""

  mkdir -p "$(dirname "$profile")" || return 1
  touch "$profile" || return 1

  if grep -F "$path_line" "$profile" >/dev/null 2>&1; then
    profile_updated=1
    return 0
  fi

  {
    printf '\n'
    printf '# Added by repohealth installer\n'
    printf '%s\n' "$path_line"
  } >>"$profile" || return 1

  profile_updated=1
}

ensure_path_setup() {
  case ":$PATH:" in
  *":$install_dir:"*) return 0 ;;
  esac

  [ -n "${HOME:-}" ] || return 1

  if [ -n "${SHELL:-}" ]; then
    case "${SHELL##*/}" in
    zsh)
      add_path_line "$HOME/.zshrc" && return 0
      ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        add_path_line "$HOME/.bashrc" && return 0
      fi
      add_path_line "$HOME/.bash_profile" && return 0
      ;;
    esac
  fi

  if [ -f "$HOME/.profile" ]; then
    add_path_line "$HOME/.profile" && return 0
  fi
  add_path_line "$HOME/.profile" && return 0
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --dir)
    [ "$#" -ge 2 ] || die "--dir requires a path"
    install_dir="$2"
    shift 2
    ;;
  --dir=*)
    install_dir="${1#*=}"
    shift
    ;;
  --version)
    [ "$#" -ge 2 ] || die "--version requires a ref"
    version="$2"
    shift 2
    ;;
  --version=*)
    version="${1#*=}"
    shift
    ;;
  --bin)
    [ "$#" -ge 2 ] || die "--bin requires a name"
    bin_name="$2"
    shift 2
    ;;
  --bin=*)
    bin_name="${1#*=}"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "unknown option: $1"
    ;;
  esac
done

[ -n "${HOME:-}" ] || [ -n "${REPOHEALTH_INSTALL_DIR:-}" ] || die "HOME is unset; set REPOHEALTH_INSTALL_DIR"
[ -n "$install_dir" ] || die "install directory is empty"
[ -n "$bin_name" ] || die "binary name is empty"
require_runtime_dependencies

case "$bin_name" in
*/*) die "binary name must not contain /" ;;
esac

base_url="${REPOHEALTH_BASE_URL:-$repo_url/$version}"
source_url="$base_url/repohealth"
target="$install_dir/$bin_name"
tmp="$(mktemp "${TMPDIR:-/tmp}/repohealth-install.XXXXXX")"

cleanup() {
  rm -f "$tmp"
}

trap cleanup EXIT HUP INT TERM

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$source_url" -o "$tmp" || die "failed to download $source_url"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$source_url" || die "failed to download $source_url"
else
  die "curl or wget is required"
fi

IFS= read -r first_line <"$tmp" || first_line=""
[ "$first_line" = "#!/usr/bin/env bash" ] || die "downloaded file does not look like repohealth"

mkdir -p "$install_dir" || die "failed to create $install_dir"
cp "$tmp" "$target" || die "failed to install $target"
chmod 755 "$target" || die "failed to make $target executable"

info "Installed repohealth to $target"

if ensure_path_setup; then
  if [ "$profile_updated" -eq 1 ]; then
    info "Updated your shell profile so $bin_name is available from new terminals."
    info "Run this once in the current terminal to use it now:"
    info "  export PATH=\"$install_dir:\$PATH\""
  fi
else
  info "Add this directory to PATH to run $bin_name from any terminal:"
  info "  export PATH=\"$install_dir:\$PATH\""
fi
