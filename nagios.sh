#!/bin/bash

cd "`dirname $0`"
HOME=`pwd`

. config

if [ ! -e stations ]; then
	echo "File stations does not exist, please copy stations.dist to stations and edit accordingly"
	exit 2
fi
for STATION in `cat stations`; do
	if [ ! -e "failed_stations/$STATION" ]; then
		echo "File failed_stations/$STATION does not exist, please run test.sh"
		exit 2
	fi

	failures=`cat "failed_stations/$STATION"`
	if [ "$failures" -gt "24" ]; then
		echo "Failed station: $STATION"
		exit 2
	fi
done

COUNT=`echo 'SELECT COUNT(*) FROM recording WHERE start_date >= end_date;'|mysql --silent -u recordings -p$DB_PASSWORD recordings 2> /dev/null`
if [ "$COUNT" == "" ]; then
	echo "Unable to query database"
	exit 3
fi
if [ "$COUNT" -gt "0" ]; then
	echo "$COUNT recording(s) with start_date not before end date"
	exit 2
fi

COUNT=`echo 'SELECT COUNT(*) FROM recording WHERE end_date < NOW() - INTERVAL 2 hour;'|mysql --silent -u recordings -p$DB_PASSWORD recordings 2> /dev/null`
if [ "$COUNT" == "" ]; then
	echo "Unable to query database"
	exit 3
fi
if [ "$COUNT" -gt "0" ]; then
	echo "$COUNT outdated recording(s)"
	exit 1
fi


echo "Everything fine"

