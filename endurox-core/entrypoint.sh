#!/bin/bash

# Load env
source /app1dir/conf/setapp1

# SIGTERM-handler for graceful shutdown 
term_handler(){
   echo "***Stopping"
   xadmin stop -y
   exit 0
}

# Setup signal handlers
trap 'term_handler' SIGTERM

echo "***Starting"
#
# boot up
#
xadmin start -y

# put the logging in background, so that bash cn wait for signal
tail -f $NDRX_APPHOME/log/ndrxd.log &

#
# keep terminal hanging.. (needs for signal waiting)
#
while [[ 1 == 1 ]]; do
	sleep 1
done

