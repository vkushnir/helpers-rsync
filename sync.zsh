#!/usr/bin/env zsh
# sync.zsh — core rsync wrapper; always requires explicit SRC and DST.
# Called by pull.zsh and push.zsh (which supply defaults),
# or directly when you need full control over paths.
#
# Usage: ./sync.zsh <src> <dst> [filter]
#   filter — optional path to .rsync-filter file.
#            If omitted, searched next to the script (symlink-aware).

set -euo pipefail

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
if [[ $# -lt 2 || $# -gt 3 ]]; then
    print -P "%F{red}[ERROR]%f Usage: ${0:t} <src> <dst> [filter]" >&2
    exit 1
fi

SRC="$1"
DST="$2"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info() { print -P "%F{cyan}[INFO]%f  $*" }
ok()   { print -P "%F{green}[OK]%f    $*" }
die()  { print -P "%F{red}[ERROR]%f $*" >&2; exit 1 }

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
[[ -d "$SRC" ]]       || die "Source not found: $SRC"
[[ -d "${DST:h}" ]]   || die "Destination parent not found: ${DST:h}"

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
info "SRC → $SRC"
info "DST → $DST"
print ""

# Locate .rsync-filter.
# Priority:
#   1. Third argument — explicit path passed by caller (pull.zsh / push.zsh).
#   2. Symlink's own directory (${0:h:A}) — direct call via project symlink.
#   3. Real script's directory (${0:A:h}) — direct call of the real file.
# Kept separate from .gitignore so sync.*/pull.*/push.* are synced normally.
if [[ $# -eq 3 ]]; then
    FILTER="$3"
    [[ -f "$FILTER" ]] || die "Filter file not found: $FILTER"
else
    _LINK_DIR="${0:h:A}"   # absolute dir of the symlink (or script itself)
    _REAL_DIR="${0:A:h}"   # absolute dir of the resolved real file

    if   [[ -f "${_LINK_DIR}/.rsync-filter" ]]; then FILTER="${_LINK_DIR}/.rsync-filter"
    elif [[ -f "${_REAL_DIR}/.rsync-filter" ]]; then FILTER="${_REAL_DIR}/.rsync-filter"
    else die ".rsync-filter not found in ${_LINK_DIR} or ${_REAL_DIR}"
    fi
fi

rsync -av \
    --delete \
    --progress \
    --exclude-from="$FILTER" \
    "${SRC}/" \
    "${DST}/"

print ""
ok "Sync complete: $SRC → $DST"
