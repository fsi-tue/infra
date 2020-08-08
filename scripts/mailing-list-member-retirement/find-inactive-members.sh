#!/usr/bin/env bash

set -eu -o pipefail

#readonly LIST_NAME="$1"
#readonly SINCE="$2"

readonly MBOX="$1" # /var/lib/mailman/archives/private/fsi.mbox/fsi.mbox
readonly LIST_MEMBERS_FILE="$2" # list_members fsi > members.txt
readonly SINCE="$3"

readonly TMPDIR="$(mktemp -d --suffix=find-inactive-members)"
readonly ACTIVE_MEMBERS_FILE="active-members.txt"
readonly ALL_MEMBERS_FILE="all-members.txt"

./mailing-list-active-members -mbox "$MBOX" -since "$SINCE" 2> /dev/null \
  | sort -u > "$TMPDIR/$ACTIVE_MEMBERS_FILE"

sort "$LIST_MEMBERS_FILE" > "$TMPDIR/$ALL_MEMBERS_FILE"

echo "Inactive members:" >&2

diff "$TMPDIR/$ALL_MEMBERS_FILE" "$TMPDIR/$ACTIVE_MEMBERS_FILE" \
  | grep -E "^< " | sed "s/^< //"

rm "$TMPDIR/$ACTIVE_MEMBERS_FILE"
rm "$TMPDIR/$ALL_MEMBERS_FILE"
rmdir "$TMPDIR"
