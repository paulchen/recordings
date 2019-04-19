#!/bin/bash

if [ "$1" == "" ]; then
	echo "No station specified"
	exit 1
fi

if [ "$2" == "" ]; then
	echo "No end specified"
	exit 1
fi

case "$1" in
	daserste)
		MAIN_PLAYLIST_URL='https://mcdn.daserste.de/daserste/de/master.m3u8'
		RESOLUTION='4898071'
		INDEX_PREFIX='chunk'
		;;

	zdf)
		MAIN_PLAYLIST_URL='https://zdf1314-lh.akamaihd.net/i/de14_v1@392878/master.m3u8?set-segment-duration=quality'
		RESOLUTION='1280x720'
		INDEX_PREFIX='segment'
		;;

	zdfneo)
		MAIN_PLAYLIST_URL='https://zdf1314-lh.akamaihd.net/i/de13_v1@392877/master.m3u8?set-segment-duration=quality'
		RESOLUTION='1280x720'
		INDEX_PREFIX='segment'
		;;

	3sat)
		MAIN_PLAYLIST_URL='http://zdf0910-lh.akamaihd.net/i/dach10_v1@392872/master.m3u8?set-segment-duration=quality'
		RESOLUTION='852x480'
		INDEX_PREFIX='segment'
		;;

	*)
		# TODO extend by more stations
		echo "Unknown station $1"
		exit 2
		;;
esac

(
flock -xn 200 || exit

LOGFILE=download.log

END=$2
END=$((END+500))

echo `date` Current end time: $END >> $LOGFILE
while [ "`date +%s`" -lt "$END" ]; do
	start_time=`date +%s`
	MAIN_PLAYLIST=`wget "$MAIN_PLAYLIST_URL" -q -O -|grep -A 1 "$RESOLUTION"|head -n 2|tail -n 1`

	if [ `echo "$MAIN_PLAYLIST" | grep -c '^http'` -eq "0" ]; then
		TEMP=`echo "$MAIN_PLAYLIST_URL"|sed -e 's/\?.*$//;s/\/[^/]*$//'`
		MAIN_PLAYLIST="$TEMP/$MAIN_PLAYLIST"
	fi
#	echo $MAIN_PLAYLIST

	URLS=`wget "$MAIN_PLAYLIST" -q -O -|grep '\.ts'`

	first=1
	segments=0
	for URL in $URLS; do
		if [ `echo "$URL" | grep -c '^http'` -eq "0" ]; then
			TEMP=`echo "$MAIN_PLAYLIST"|sed -e 's/\?.*$//;s/\/[^/]*$//'`
			URL="$TEMP/$URL"
		fi
#		echo $URL

		INDEX=`echo "$URL"|sed -e "s/^.*\/$INDEX_PREFIX//;s/[^0-9].*//"`
		if [ "$first" -eq 1 ]; then
			echo `date` First index: "$INDEX" >> $LOGFILE
		fi
		first=0
		segments=$((segments+1))
	done

	total_seconds=$((6*segments))
	echo `date` Last index: "$INDEX" >> $LOGFILE
	echo `date` Total number of segments: "$segments" >> $LOGFILE
	echo `date` Time span covered: "$total_seconds" >> $LOGFILE

#	exit

	downloaded=0
	for URL in $URLS; do
		if [ `echo "$URL" | grep -c '^http'` -eq "0" ]; then
			TEMP=`echo "$MAIN_PLAYLIST"|sed -e 's/\?.*$//;s/\/[^/]*$//'`
			URL="$TEMP/$URL"
		fi
		INDEX=`echo "$URL"|sed -e "s/^.*\/$INDEX_PREFIX//;s/[^0-9].*//"`
		if [ -f "segment${INDEX}.ts" ]; then
			continue;
		fi
	
		for i in 1 2 3 4 5; do
			echo -n `date` Downloading segment "$INDEX"... >> $LOGFILE
			wget -nc "$URL" -q -O "segment${INDEX}.ts"
			if [ $? -eq 0 ]; then
				downloaded=$((downloaded+1))
				echo 'ok' >> $LOGFILE
				break
			else
				echo 'fail!' >> $LOGFILE
				echo `date` 'Sleeping 5 seconds' >> $LOGFILE
				rm -f "segment${INDEX}.ts"
				sleep 5
			fi
		done
		sleep .1
	done

	end_time=`date +%s`
	elapsed_time=$((end_time - start_time))
	sleep_time=$(( (total_seconds-elapsed_time) / 4 ))

	echo `date` Number of segments downloaded: "$downloaded" >> $LOGFILE
	echo `date` Elapsed time: "$elapsed_time" seconds >> $LOGFILE
	echo `date` Sleeping "$sleep_time" seconds >> $LOGFILE

	END=$2
	END=$((END+total_seconds))
	echo `date` New end time: $END >> $LOGFILE

	no_sleep=$((END-sleep_time))
	if [ "`date +%s`" -gt "$no_sleep" ]; then
		echo "End time reached" >> $LOGFILE
		break
	fi

	sleep $sleep_time
done

) 200> /tmp/recording_$1.lock

rm -f /tmp/recording_$1.lock

echo "Done" >> $LOGFILE

