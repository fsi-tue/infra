# Building

`go build`

# Example usages

- Get statistics (sort users by their activity): `./mailing-list-active-members -mbox fsi.mbox -since 2019-08-01 2> /dev/null | sort | uniq -c | sort -h`
- Find inactive list members to (potentially) retire: `./find-inactive-members.sh fsi.mbox fsi-members 2019-08-01`
