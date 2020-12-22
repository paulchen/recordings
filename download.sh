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
	daserste) URL='https://mcdn.daserste.de/daserste/de/master.m3u8' ;;
	zdf)      URL='https://zdf-hls-15.akamaized.net/hls/live/2016498/de/high/master.m3u8' ;;
	zdfneo)   URL='https://zdf-hls-16.akamaized.net/hls/live/2016499/de/high/master.m3u8' ;;
	3sat)     URL='https://zdf-hls-18.akamaized.net/hls/live/2016501/dach/high/master.m3u8' ;;
	orf1)     URL='https://orf1.mdn.ors.at/out/u/orf1/qxb/manifest.m3u8' ;;
	orf2)     URL='https://orf2.mdn.ors.at/out/u/orf2/qxb/manifest.m3u8' ;;
	orf3)     URL='https://orf3.mdn.ors.at/out/u/orf3/qxb/manifest.m3u8' ;;
	rbb)      URL='https://rbblive-lh.akamaihd.net/i/rbb_brandenburg@349369/master.m3u8?set-segment-duration=responsive' ;;
	mdr)      URL='https://mdrtvsnhls.akamaized.net/hls/live/2016928/mdrtvsn/master.m3u8' ;;
	*)
		# TODO extend by more stations
		echo "Unknown station $1"
		exit 2
		;;
esac

LOCKFILE="/tmp/recording_$1.lock"
ERROR=0

(
flock -xn 200 || exit

LOGFILE=download.log

echo "Lock file: $LOCKFILE" >> $LOGFILE

START=`date +%s`
END=$2

DURATION=$((END-START))

ffmpeg -i "$URL" -t $DURATION -c copy -bsf:a aac_adtstoasc all.mp4 >> "$LOGFILE" 2>&1 || ERROR=1

) 200> $LOCKFILE

exit $ERROR

