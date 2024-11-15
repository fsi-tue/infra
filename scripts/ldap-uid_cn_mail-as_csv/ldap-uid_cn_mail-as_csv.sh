#!/bin/bash
# Author Lukas Oertel <dev.luoe@gmail.com>

# Get the uid, cn and mail-address of all LDAP accounts that are not disabled


RND_FOLDER=$(openssl rand -hex 16)
mkdir "$RND_FOLDER"

# See
## https://lurchi.wordpress.com/2009/11/03/ldapsearch-and-base64-encoding/
# or
## https://web.archive.org/web/20210620230910/https://lurchi.wordpress.com/2009/11/03/ldapsearch-and-base64-encoding/
# for source of the following alias.
# Required for decoding base64 encoded 'cn::' fields
shopt -s expand_aliases
alias un64='awk '\''BEGIN{FS=":: ";c="base64 -d"}{if(/\w+:: /) {print $2 |& c; close(c,"to"); c |& getline $2; close(c); printf("%s:: \"%s\"\n", $1, $2); next} print $0 }'\'''

# Get LDAP data and sort all required fields
ldapsearch -x "(&(objectclass=posixAccount)(!(loginShell=/usr/sbin/nologin)))" 2>/dev/null | \
	egrep "^(mail:|uid:|cn:)" | \
	un64 | \
	sed 's/cn::/cn:/g' > "$RND_FOLDER"/ldap.txt

# Sort the data by cn, mail and uid
split -l 3 "$RND_FOLDER"/ldap.txt "$RND_FOLDER"/ldap.txt.chunk.
ls "$RND_FOLDER"/ldap.txt.chunk.* | xargs -P 4 -I {} sort {} -o {}
cat "$RND_FOLDER"/ldap.txt.chunk.* > "$RND_FOLDER"/ldap.txt.sorted

cat "$RND_FOLDER"/ldap.txt.sorted | \
# Split every 3 lines and make CSV file from data
xargs -n3 -d'\n' | \
sed 's/cn: //g; s/ mail: /,/g; s/ uid: /,/g' | \
# Quote columns with spaces correctly
sed 's/^/"/g; s/,/",/1' | sed 's/""/"/g' > ldapdata.csv

rm -r "$RND_FOLDER"
