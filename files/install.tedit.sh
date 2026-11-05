#!/bin/sh
# tedit one-line installer: clones the repo and runs its install.sh for you,
# with a GitHub-style spinner. Host it on a server and install with:
#
#   curl -fsSL https://<your-server-url> | sh
#
# Override the repo / clone location if you ever need to:
#   TEDIT_REPO=https://gitlab.com/stonecoding1/tedit.git TEDIT_DIR=... curl -fsSL ... | sh
# Keep the .git metadata after install with KEEP_GIT=1.

set -u

REPO_URL="${TEDIT_REPO:-https://gitlab.com/stonecoding1/tedit.git}"
DEST="${TEDIT_DIR:-$HOME/.local/share/tedit}"

# --- pretty bits --------------------------------------------------------------
bold= dim= red= green= cyan= reset=
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  bold="$(tput bold)"
  dim="$(tput dim)"
  red="$(tput setaf 1)"
  green="$(tput setaf 2)"
  cyan="$(tput setaf 6)"
  reset="$(tput sgr0)"
fi

# --- GitHub-style spinner (braille frames, like the gh CLI's) -------------------
SPIN_PID=

spin_start() { # $1 = message
  [ -t 1 ] || return 0
  msg=$1
  (
    while :; do
      for frame in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
        printf '\r%s%s%s %s' "$cyan" "$frame" "$reset" "$msg"
        sleep 0.08
      done
    done
  ) &
  SPIN_PID=$!
}

spin_stop() { # $1 = 0 ok / 1 fail, $2 = final line
  if [ -n "$SPIN_PID" ]; then
    kill "$SPIN_PID" 2>/dev/null
    wait "$SPIN_PID" 2>/dev/null
    SPIN_PID=
    printf '\r\033[K'
  fi
  if [ "$1" -eq 0 ]; then
    printf '%s%s✓%s %s\n' "$bold" "$green" "$reset" "$2"
  else
    printf '%s%s✗%s %s\n' "$bold" "$red" "$reset" "$2"
  fi
}

die() {
  spin_stop 1 "failed"
  printf '%s%serror:%s %s\n' "$bold" "$red" "$reset" "$1" >&2
  exit 1
}

# --- hello --------------------------------------------------------------------
printf '\n%s%s  tedit — actually good TUI text editor for Linux  %s\n\n' "$bold" "$cyan" "$reset"

# --- dependencies ---------------------------------------------------------------
for dep in git python3; do
  command -v "$dep" >/dev/null 2>&1 || die "install '$dep' first, then run this again"
done
printf '%s%s✓%s dependencies ok (git, python3)\n' "$bold" "$green" "$reset"

# --- clone (or update) the repo ---------------------------------------------------
spin_start "cloning the repository"
if [ -d "$DEST/.git" ]; then
  out=$(git -C "$DEST" pull --ff-only 2>&1)
  ok=$?
  action="updated"
else
  if [ -e "$DEST" ]; then
    rm -rf "$DEST" 2>/dev/null || true
  fi
  out=$(git clone --depth 1 "$REPO_URL" "$DEST" 2>&1)
  ok=$?
  action="cloned"
fi
if [ "$ok" -ne 0 ]; then
  spin_stop 1 "clone failed"
  printf '%s%s%s\n' "$dim" "$out" "$reset"
  die "could not clone $REPO_URL into $DEST"
fi
spin_stop 0 "$action the repository into $DEST"

# --- run the repo's own installer --------------------------------------------------
spin_start "installing (desktop entry + tedit on PATH)"
out=$(sh "$DEST/install.sh" 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
  spin_stop 1 "install failed"
  printf '%s%s%s\n' "$dim" "$out" "$reset"
