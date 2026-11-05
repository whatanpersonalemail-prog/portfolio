#!/bin/sh
# tedit one-line installer: downloads the tedit archive and runs its
# install.sh for you, with a GitHub-style spinner. Host it on a server and
# install with:
#
#   curl -fsSL https://<your-server-url> | sh
#
# Override the archive URL / clone location if you ever need to:
#   TEDIT_URL=https://example.com/tedit.tar.gz curl -fsSL ... | sh
#   TEDIT_DIR=/opt/tedit curl -fsSL ... | sh
#   TEDIT_REPO=https://github.com/user/tedit TEDIT_REF=main curl -fsSL ... | sh
#
# No git required: everything comes down as a plain archive.

set -u

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
