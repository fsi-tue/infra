#!/bin/bash

# Author/Copyright: Lukas Oertel <git@luoe.dev>
#
# This script fetches Github Actions egress IP addresses from the API and whitelists them for ingress SSH connections using a seperate iptables chain.


# put in the correct port here
SSH_PORT=123456

IPTABLES=/usr/sbin/iptables # ->  /etc/alternatives/iptables -> /usr/sbin/iptables-nft (at least on trinity)
CURL=/usr/bin/curl
JQ=/usr/bin/jq
TR=/usr/bin/tr
SHA256SUM=/usr/bin/sha256sum

echo "Fetching Github Actions IPs from Github API..."
GITHUB_META=`${CURL} https://api.github.com/meta 2>/dev/null`

# for debugging purposes (to not hit the rate limit)
# IPS_DUMP="github_actions_ips_v4"
# GITHUB_META=`cat ${IPS_DUMP}`

ACTIONS_IPS=$(echo $GITHUB_META | ${JQ} '.actions[]' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}' | sort)

# use two distinct chains so there is now downtime when updating the rules
# one could iterate over the rules of the list, but it's quicker to just switch chains

GH_ACTIONS_CHAIN1="GH-ACTIONS-1"
GH_ACTIONS_CHAIN2="GH-ACTIONS-2"

# -n does not try to resolve PTR
GH_ACTIONS_CHAIN1_EXISTS=$("${IPTABLES}" -nL "${GH_ACTIONS_CHAIN1}" >/dev/null 2>&1; echo $?)
GH_ACTIONS_CHAIN2_EXISTS=$("${IPTABLES}" -nL "${GH_ACTIONS_CHAIN2}" >/dev/null 2>&1; echo $?)

CURRENT_CHAIN=""
NEW_CHAIN=""


if [ "${GH_ACTIONS_CHAIN1_EXISTS}" == 1 ] && [ "${GH_ACTIONS_CHAIN2_EXISTS}" == 1 ] ||  [ "${GH_ACTIONS_CHAIN1_EXISTS}" == 0 ]; then
	CURRENT_CHAIN="${GH_ACTIONS_CHAIN1}"
	NEW_CHAIN="${GH_ACTIONS_CHAIN2}"
else
	CURRENT_CHAIN="${GH_ACTIONS_CHAIN2}"
	NEW_CHAIN="${GH_ACTIONS_CHAIN1}"
fi

"${IPTABLES}" -N "${NEW_CHAIN}" > /dev/null 2>&1
"${IPTABLES}" -F "${NEW_CHAIN}" > /dev/null 2>&1

echo "Adding IP addresses to new chain..."
for ip in $ACTIONS_IPS; do
	"${IPTABLES}" -I "${NEW_CHAIN}" -s $ip -p tcp --dport "${SSH_PORT}" -j ACCEPT
done

# not hitting any of the rules in the GH chain implies the last rule, so no dropping in INPUT needed
#${IPTABLES} -A INPUT -p tcp --dport ${SSH_PORT} -j DROP
${IPTABLES} -A ${NEW_CHAIN} -p tcp --dport ${SSH_PORT} -j DROP 

# switch the chains
${IPTABLES} -I INPUT -p tcp --dport ${SSH_PORT} -j ${NEW_CHAIN}
${IPTABLES} -D INPUT -p tcp --dport ${SSH_PORT} -j ${CURRENT_CHAIN} > /dev/null 2>&1

# flush and remove the old chain
# not flushing it before throws an error, even though the chain is not referenced:
# iptables v1.8.7 (nf_tables):  CHAIN_USER_DEL failed (Device or resource busy): chain
${IPTABLES} -F ${CURRENT_CHAIN} > /dev/null 2>&1
${IPTABLES} -X ${CURRENT_CHAIN} > /dev/null 2>&1
