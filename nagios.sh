#!/bin/bash

cd "`dirname $0`"
HOME=`pwd`

. config

if [ ! -e failed_stations ]; then
	echo "File failed_stations does not exist, please run test.sh"
	exit 2
fi

FAILED_STATIONS=`cat failed_stations`
if [ "$FAILED_STATIONS" != "0" ]; then
	echo "Number of failed stations: $FAILED_STATIONS"
	exit 2
fi

COUNT=`echo 'SELECT COUNT(*) FROM recording WHERE start_date >= end_date;'|mysql --silent -u recordings -p$DB_PASSWORD recordings`

if [ "$COUNT" -gt "0" ]; then
	echo "$COUNT recording(s) with start_date not before end date"
	exit 2
fi

COUNT=`echo 'SELECT COUNT(*) FROM recording WHERE end_date < NOW() - INTERVAL 2 hour;'|mysql --silent -u recordings -p$DB_PASSWORD recordings`
if [ "$COUNT" -gt "0" ]; then
	echo "$COUNT outdated recording(s)"
	exit 1
fi


echo "Everything fine"

