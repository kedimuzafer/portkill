#!/usr/bin/env sh

# portkill-install.sh
# Simple installer for the `portkill` shell function.
# Usage (once in its own repo):
#   curl -fsSL https://raw.githubusercontent.com/youruser/portkill/main/portkill-install.sh | sh

set -eu

PORTKILL_MARK_START="# >>> portkill >>>"
PORTKILL_MARK_END="# <<< portkill <<<"

print_banner() {
  if [ -t 1 ]; then
    printf '\033[1;35m'
  fi
  cat <<'EOF'
 ____            _   _ _ _ _
|  _ \ ___  _ __| |_(_) | | ___
| |_) / _ \| '__| __| | | |/ _ \
|  __/ (_) | |  | |_| | | |  __/
|_|   \___/|_|   \__|_|_|_|\___|

EOF
  if [ -t 1 ]; then
    printf '\033[0m'
  fi
}

detect_rc_file() {
  # Allow explicit override
  if [ "${PORTKILL_RC:-}" != "" ]; then
    printf '%s\n' "$PORTKILL_RC"
    return 0
  fi

  shell_name="$(basename "${SHELL:-}")"
  home="${HOME:-$PWD}"

  # Prefer zsh if running under it
  if [ "$shell_name" = "zsh" ]; then
    if [ -n "${ZDOTDIR:-}" ]; then
      printf '%s\n' "$ZDOTDIR/.zshrc"
    else
      printf '%s\n' "$home/.zshrc"
    fi
    return 0
  fi

  # Prefer bash if running under it
  if [ "$shell_name" = "bash" ]; then
    if [ -f "$home/.bashrc" ]; then
      printf '%s\n' "$home/.bashrc"
      return 0
    fi
  fi

  # Fallback: first existing of common rc files
  for candidate in \
    "$home/.zshrc" \
    "$home/.bashrc" \
    "$home/.bash_profile" \
    "$home/.profile"
  do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  # Nothing exists yet; default to ~/.bashrc
  printf '%s\n' "$home/.bashrc"
}

ensure_not_installed() {
  rc="$1"
  if [ -f "$rc" ] && grep -q "$PORTKILL_MARK_START" "$rc"; then
    echo "portkill: already installed in $rc"
    echo "          nothing to do 🎯"
    exit 0
  fi
}

append_portkill_block() {
  rc="$1"
  mkdir -p "$(dirname "$rc")"
  touch "$rc"

  {
    printf '\n%s\n' "$PORTKILL_MARK_START"
    cat <<'EOF'
# portkill - kill whatever listens on a given TCP port

_portkill_detect_rc() {
  if [ "${PORTKILL_RC:-}" != "" ] && [ -f "$PORTKILL_RC" ]; then
    printf '%s\n' "$PORTKILL_RC"
    return 0
  fi

  home="${HOME:-$PWD}"

  # Try to find the rc file that actually contains the portkill block
  for candidate in \
    "$home/.zshrc" \
    "$home/.bashrc" \
    "$home/.bash_profile" \
    "$home/.profile"
  do
    if [ -f "$candidate" ] && grep -q "# >>> portkill >>>" "$candidate" 2>/dev/null; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  # Fallback – best guess
  printf '%s\n' "$home/.zshrc"
}

_portkill_uninstall() {
  rc="$(_portkill_detect_rc)"

  if [ ! -f "$rc" ]; then
    printf 'portkill: rc file not found: %s\n' "$rc" >&2
    return 1
  fi

  if ! grep -q "# >>> portkill >>>" "$rc" 2>/dev/null; then
    printf 'portkill: no portkill block found in %s\n' "$rc"
    return 0
  fi

  tmp="${rc}.portkill.tmp.$$"
  awk '
    BEGIN { in_block = 0 }
    /# >>> portkill >>>/ { in_block = 1; next }
    /# <<< portkill <</  { in_block = 0; next }
    in_block == 0 { print }
  ' "$rc" > "$tmp" && mv "$tmp" "$rc"

  printf 'portkill: removed from %s\n' "$rc"
}

portkill() {
  # Subcommands / flags
  case "${1:-}" in
    -h|--help|help)
      cat <<'USAGE'
portkill - kill whatever listens on a given TCP port

Usage:
  portkill <port>          Kill whatever is listening on <port>
  portkill -h | --help     Show this help
  portkill uninstall       Remove the portkill block from your shell rc file
  portkill remove|delete   Alias for "uninstall"

Examples:
  portkill 3003
  portkill 8080
USAGE
      return 0
      ;;
    uninstall|remove|delete)
      _portkill_uninstall
      return $?
      ;;
  esac

  if [ -z "$1" ]; then
    printf 'Usage: portkill <port>\n' >&2
    return 1
  fi

  port="$1"
  pids=""

  # Try lsof first (TCP LISTEN)
  if command -v lsof >/dev/null 2>&1; then
    pids="$(lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
    if [ -z "$pids" ]; then
      # Fallback: any protocol on that port
      pids="$(lsof -t -i:"$port" 2>/dev/null || true)"
    fi
  fi

  # Fallback to fuser if available
  if [ -z "$pids" ] && command -v fuser >/dev/null 2>&1; then
    pids="$(fuser -n tcp "$port" 2>/dev/null || true)"
  fi

  if [ -z "$pids" ]; then
    printf 'portkill: no process found on port %s\n' "$port"
    return 0
  fi

  # Normalize and uniquify PIDs
  pids="$(printf '%s\n' $pids | tr ' ' '\n' | sed 's/[^0-9]//g' | sed '/^$/d' | sort -u)"

  if [ -z "$pids" ]; then
    printf 'portkill: could not extract any valid PIDs for port %s\n' "$port" >&2
    return 1
  fi

  printf 'portkill: killing PIDs [%s] on port %s\n' "$pids" "$port"

  # Try graceful then forceful kill
  kill $pids 2>/dev/null || true
  sleep 0.2
  kill -9 $pids 2>/dev/null || true
}
EOF
    printf '%s\n' "$PORTKILL_MARK_END"
  } >>"$rc"
}

main() {
  print_banner

  rc_file="$(detect_rc_file)"
  echo "portkill: installing into: $rc_file"

  ensure_not_installed "$rc_file"
  append_portkill_block "$rc_file"

  echo
  echo "portkill: installation complete."
  echo "         Reload your shell config, e.g.:"
  echo "           . \"$rc_file\""
  echo "         Then run: portkill 3003"
}

main "$@"
