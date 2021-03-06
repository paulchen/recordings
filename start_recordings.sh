#!/bin/bash

cd "`dirname $0`"
HOME=`pwd`

. config

IDS=`echo 'SELECT id FROM recording WHERE NOW() BETWEEN start_date AND end_date;'|mysql --silent -u recordings -p$DB_PASSWORD recordings`

for ID in $IDS; do
	DATA=`echo "SELECT station, DATE_FORMAT(start_date, '%Y-%m-%d-%H:%i:%s'), UNIX_TIMESTAMP(end_date) FROM recording WHERE id=$ID"|mysql --silent -u recordings -p$DB_PASSWORD recordings`

	read -r -a array <<< "$DATA"
	STATION=${array[0]}
	START=${array[1]}
	END_UNIX=${array[2]}

	DIRECTORY=$BASE_DIR/$STATION-$START

	mkdir -p "$DIRECTORY"
	cd "$DIRECTORY"

	nohup "$HOME/download.sh" "$STATION" "$END_UNIX" > /dev/null 2>&1 &
done

