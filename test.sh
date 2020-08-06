#!/bin/bash

DIRECTORY=`dirname "$0"`
cd "$DIRECTORY"

. config

RECORDINGS=`echo 'SELECT COUNT(*) FROM recording WHERE NOW() < start_date;'|mysql --silent -u recordings -p$DB_PASSWORD recordings`
echo "Number of upcoming recordings: $RECORDINGS"
if [ "$RECORDINGS" -gt "0" ]; then
	exit
fi

rm -rf test
mkdir test
cd test

ERRORS=0
for STATION in `cat ../stations`; do
	echo "Testing station $STATION..."

	rm -f all.mp4 download.log

	NOW=`date +%s`
	THEN=$((NOW+30))

	station_error=0
	../download.sh "$STATION" "$THEN" || station_error=1

	if [ "$station_error" -eq "0" ]; then
		if [ ! -e all.mp4 ]; then
			station_error=1
		else
			SIZE=`stat --printf="%s" all.mp4`
			if [ "$SIZE" -eq "0" ]; then
				station_error=1
			fi
		fi
	fi

	if [ "$station_error" -eq "1" ]; then
		echo "Error while downloading $STATION"
		ERRORS=$((ERRORS+1))
	fi

	rm -f all.mp4 download.log
done

cd ..
rm -rf test

echo $ERRORS > failed_stations

echo "Failed stations: $ERRORS"
exit $ERRORS

