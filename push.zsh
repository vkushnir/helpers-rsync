#!/usr/bin/env zsh
# push.zsh — sync FROM git (src) TO cowork (dst).
# Paths are read from .rsync-filter (# @src: and # @dst: lines).
#
# Usage: ./push.zsh

set -euo pipefail

die() { print -P "%F{red}[ERROR]%f $*" >&2; exit 1 }

FILTER="${0:A:h}/.rsync-filter"
[[ -f "$FILTER" ]] || die ".rsync-filter not found: $FILTER"

SRC=$(grep '^# @src:' "$FILTER" | sed 's|^# @src:[ ]*||')
DST=$(grep '^# @dst:' "$FILTER" | sed 's|^# @dst:[ ]*||')

[[ -n "$SRC" ]] || die "# @src: not found in $FILTER"
[[ -n "$DST" ]] || die "# @dst: not found in $FILTER"

exec "${0:A:h}/sync.zsh" "$SRC" "$DST"
