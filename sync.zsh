#!/usr/bin/env zsh
# sync.zsh — core rsync wrapper; always requires explicit SRC and DST.
# Called by pull.zsh and push.zsh (which supply defaults),
# or directly when you need full control over paths.
#
# Usage: ./sync.zsh <src> <dst>

set -euo pipefail

# ---------------------------------------------------------------------------
# Args — both are mandatory, no defaults here
# ---------------------------------------------------------------------------
if [[ $# -ne 2 ]]; then
    print -P "%F{red}[ERROR]%f Usage: ${0:t} <src> <dst>" >&2
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

# Exclude rules are read from .rsync-filter next to this script.
# Kept separate from .gitignore so sync.*/pull.*/push.* are copied normally
# (they're git-ignored but belong in the working copy on both sides).
FILTER="${0:A:h}/.rsync-filter"
[[ -f "$FILTER" ]] || die "Filter file not found: $FILTER"

rsync -av \
    --delete \
    --progress \
    --exclude-from="$FILTER" \
    "${SRC}/" \
    "${DST}/"

print ""
ok "Sync complete: $SRC → $DST"
