#!/bin/bash

if [ "$1" == "" ]; then
	echo "No station specified"
	exit 1
fi

if [ "$2" == "" ]; then
	echo "No end specified"
	exit 1
fi

SIMPLE=0
SEGMENT_TIME=6
case "$1" in
	daserste)
		MAIN_PLAYLIST_URL='https://mcdn.daserste.de/daserste/de/master.m3u8'
		RESOLUTION='4898071'
		INDEX_PREFIX='chunk'
		;;

	zdf)
		MAIN_PLAYLIST_URL='https://zdf-hls-01.akamaized.net/hls/live/2002460/de/high/master.m3u8'
		RESOLUTION='1280x720'
		INDEX_PREFIX=''
		;;

	zdfneo)
		MAIN_PLAYLIST_URL='https://zdf-hls-02.akamaized.net/hls/live/2002461/de/high/master.m3u8'
		RESOLUTION='1280x720'
		INDEX_PREFIX=''
		;;

	3sat)
		MAIN_PLAYLIST_URL='https://zdfhls18-i.akamaihd.net/hls/live/744751/dach/high/master.m3u8'
		RESOLUTION='852x480'
		INDEX_PREFIX=''
		;;

	orf1)
		MAIN_PLAYLIST_URL='https://orf1.mdn.ors.at/out/u/orf1/qxb/manifest_6.m3u8?m=1552488594'
		INDEX_PREFIX='manifest_6_'
		SIMPLE=1
		SEGMENT_TIME=5
		;;

	orf2)
		MAIN_PLAYLIST_URL='https://orf2.mdn.ors.at/out/u/orf2/qxb/manifest_6.m3u8?m=1552488594'
		INDEX_PREFIX='manifest_6_'
		SIMPLE=1
		SEGMENT_TIME=5
		;;

	orf3)
		MAIN_PLAYLIST_URL='https://orf3.mdn.ors.at/out/u/orf3/qxb/manifest_6.m3u8?m=1552488594'
		INDEX_PREFIX='manifest_6_'
		SIMPLE=1
		SEGMENT_TIME=5
		;;

	*)
		# TODO extend by more stations
		echo "Unknown station $1"
		exit 2
		;;
esac

LOCKFILE="/tmp/recording_$1.lock"

(
flock -xn 200 || exit

echo "Lock file: $LOCKFILE" >> $LOGFILE

LOGFILE=download.log

END=$2
END=$((END+500))

echo `date` Current end time: $END >> $LOGFILE
while [ "`date +%s`" -lt "$END" ]; do
	start_time=`date +%s`

	if [ "$SIMPLE" == "0" ]; then
		echo "Downloading: $MAIN_PLAYLIST_URL" >> $LOGFILE
		MAIN_PLAYLIST=`wget "$MAIN_PLAYLIST_URL" -q -O -|grep -A 1 "$RESOLUTION"|head -n 2|tail -n 1`

		if [ `echo "$MAIN_PLAYLIST" | grep -c '^http'` -eq "0" ]; then
			TEMP=`echo "$MAIN_PLAYLIST_URL"|sed -e 's/\?.*$//;s/\/[^/]*$//'`
			MAIN_PLAYLIST="$TEMP/$MAIN_PLAYLIST"
		fi
	else
		MAIN_PLAYLIST="$MAIN_PLAYLIST_URL"
	fi
	echo "Downloading: $MAIN_PLAYLIST" >> $LOGFILE
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

	total_seconds=$((SEGMENT_TIME*segments))
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
			echo "Downloading: $URL" >> $LOGFILE
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
		echo "Done" >> $LOGFILE

		rm -f "$LOCKFILE"

		break
	fi

	sleep $sleep_time
done

) 200> $LOCKFILE

