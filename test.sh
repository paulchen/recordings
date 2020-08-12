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

for STATION in `cat ../stations`; do
	echo "Testing station $STATION..."

	rm -f all.mp4 download.log

	NOW=`date +%s`
	THEN=$((NOW+30))

	current_failures=0
	if [ -e "../failed_stations/$STATION" ]; then
		current_failures=`cat "../failed_stations/$STATION"`

		if [ "$current_failures" -eq "0" ]; then
			DONT_CHECK=0
			/opt/icinga-plugins/check_fileage.py -f "../failed_stations/$STATION" -w 1400 -c 2800 > /dev/null 2>&1 && DONT_CHECK=1
			if [ "$DONT_CHECK" -eq "1" ]; then
				echo "Not checking station, last success was less than 24h ago" 
				continue
			fi
		fi
	fi
	echo "Current failures: $current_failures"

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
		current_failures=$((current_failures+1))
	else
		echo "Test successful"
		current_failures=0
	fi
	echo "$current_failures" > "../failed_stations/$STATION"

	rm -f all.mp4 download.log
done

cd ..
rm -rf test


