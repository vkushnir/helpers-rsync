#!/usr/bin/env zsh
# push.zsh — sync FROM git (src) TO cowork (dst).
# Paths are read from .rsync-filter (# @src: and # @dst: lines).
#
# Usage: ./push.zsh

set -euo pipefail

die() { print -P "%F{red}[ERROR]%f $*" >&2; exit 1 }

# Locate .rsync-filter: check the symlink's own directory first,
# then the real script's directory (:A resolves all symlinks).
_LINK_DIR="${0:h:A}"   # absolute dir of the symlink (or script itself)
_REAL_DIR="${0:A:h}"   # absolute dir of the resolved real file

if   [[ -f "${_LINK_DIR}/.rsync-filter" ]]; then FILTER="${_LINK_DIR}/.rsync-filter"
elif [[ -f "${_REAL_DIR}/.rsync-filter" ]]; then FILTER="${_REAL_DIR}/.rsync-filter"
else die ".rsync-filter not found in ${_LINK_DIR} or ${_REAL_DIR}"
fi

FILTER_DIR="${FILTER:h}"   # directory where .rsync-filter was found

SRC=$(grep '^# @src:' "$FILTER" | sed 's|^# @src:[ ]*||')
DST=$(grep '^# @dst:' "$FILTER" | sed 's|^# @dst:[ ]*||')

# push: FROM git (src) TO cowork (dst)
# If @src: is missing — use filter's own directory as the source to push from.
[[ -n "$DST" ]] || die "# @dst: not found in $FILTER"
[[ -n "$SRC" ]] || SRC="$FILTER_DIR"

exec "${0:A:h}/sync.zsh" "$SRC" "$DST" "$FILTER"
