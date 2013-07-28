#!/bin/bash

HOST="http://127.0.0.1:9200"
LIMIT=30
PREFIX="logstash"

while getopts ":h:l:p" flag
do
  case "$flag" in
    h)
      HOST=$OPTARG
      ;;
    l)
      LIMIT=$OPTARG
      ;;
    p)
      PREFIX=$OPTARG
      ;;
  esac
done

ESDATA=`curl -s -S "$HOST/_status?pretty=true" | grep $PREFIX | grep -v "index" | awk -F \" {'print $2'} | sort -r`

if [ -z "$ESDATA" ]; then
  echo "No '$PREFIX' indexes returned from $HOST."
  exit 1
fi

declare -a INDEXES=($ESDATA)

if [ ${#INDEXES[@]} -gt $LIMIT ]; then
  for index in ${INDEXES[@]:$LIMIT}; do
    if [ -n "$INDEXES" ]; then
      echo `date` " -- Deleting index: $index."
      ACK=`curl -s -S -XDELETE "$HOST/$index/" | sed -e's/[{}]/''/g' | sed -e's/\"//g'`
      if [ "$ACK" == "ok:true acknowledged:true" ]; then
        echo "-- $index acknowledgement: $ACK"
      else
        echo "-- $index acknowledgement: $ACK ---FAILED---"
        exit 1
      fi
    fi
  done
fi

exit 0
