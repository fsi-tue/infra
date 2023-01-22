#!/bin/bash

while read p; do
  USER=`echo $p | sed 's/\s.*$//'`
  ID=`echo $p | sed 's/.* //'`
  echo $USER $ID
  sed 's/$UID/'$USER'/g' replacements.txt | sed 's/$LDAPID/'$ID'/g' - >> replacements.sql
done <ldap_users.txt
