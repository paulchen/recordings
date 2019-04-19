#!/bin/bash
START=$1
END=$2

if [ "$1" == "" ]; then
	exit 1
fi

if [ "$2" == "" ]; then
	exit 1
fi

rm -f mylist.txt
for a in `seq $1 1 $2`; do
	echo "file 'segment$a.ts'" >> mylist.txt
done
ffmpeg -f concat -i mylist.txt -c copy all.ts
ffmpeg -i all.ts -bsf:a aac_adtstoasc -vcodec copy all.mp4
rm -f all.ts mylist.txt

