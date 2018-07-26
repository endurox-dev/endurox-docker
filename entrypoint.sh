#!/bin/bash

# Load env
source /app1dir/conf/setapp1

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
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

#
# keep terminal hanging..
#
while [[ 1 == 1 ]]; do
	sleep 1
done

