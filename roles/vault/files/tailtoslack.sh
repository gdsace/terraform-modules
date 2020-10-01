#!/bin/sh

tail -n0 -F "$1"  | while read LINE; do
  #(echo "$LINE" | grep -i 'path\"\:\"secrets' | grep -i username | grep -iv 'list' | grep -iv 'username\"\:\"hmac' | tr '{' '\n' |  tr '}' '\n' | tr ',' '\n' | egrep -i 'operation|username|path') \

  SECRET_ACCESS=$(echo "$LINE" | grep -i 'path\"\:\"secrets' | grep -i username | grep -iv 'list' | grep -iv 'username\"\:\"hmac' | tr '{' '\n' | tr '}' '\n' | tr ',' '\n' | egrep -i 'operation')
  ROOT_ACCESS=$(echo "$LINE" | grep -i 'display_name\"\:\"root' | grep -iv 'display_name\"\:\"hmac' | tr '{' '\n' | tr '}' '\n' | tr ',' '\n' | egrep -i 'operation')


  if [ ! -z $SECRET_ACCESS ]
  then
    curl -X POST --silent --data-urlencode \
    "payload={\"text\": \"$(echo "$LINE" | grep -i 'path\"\:\"secrets' | grep -i username | grep -iv 'list' | grep -iv 'username\"\:\"hmac' | tr '{' '\n' | tr '}' '\n' | tr ',' '\n' | egrep -i 'operation|username|path' | sed "s/\"/'/g")\"}" "$2";
  elif [ ! -z $ROOT_ACCESS ]
  then
    curl -X POST --silent --data-urlencode \
    "payload={\"text\": \"$(echo "$LINE" | grep -i 'display_name\"\:\"root' | grep -iv 'display_name\"\:\"hmac' | tr '{' '\n' | tr '}' '\n' | tr ',' '\n' | egrep -i 'operation|display_name|path' | sed "s/\"/'/g")\"}" "$2";
  fi
done
