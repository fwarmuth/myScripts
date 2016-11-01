#!/bin/bash
#Felix W. 27.04.16
#script for reconnecting vpn connection based on a keep a live ping to a host. Afther 

#settings
vpn_con_id="felix@n0s3.xyz" # name of connection, in network manager
heartbeat_host="192.168.10.1" # address of host inside of vpn to check
run_interval="5" #interval of keep alive ping in sec
failcounter_max="5" #max number of failed attempts before restarting network-manager

# real start
failcounter="0"
while true
do # mainloop      
   now=$(date +"%T")
   echo "$now checking connection"
   vpn_isactive=$(fping -c 1 -t1000 $heartbeat_host 2> /dev/null 1> /dev/null && echo "1" || echo "0")
   
   if [ $vpn_isactive == '1' ];
   then
       current_ping=$(ping -c 1 $heartbeat_host |grep "ttl" | cut -d '=' -f 4 | rev | cut -c 3- | rev) # heartbeat_host is used to measure latency through vpn tunnel
       echo "$(tput setaf 3)vpn is active, do nothing, current latency ~$current_ping ms"
       failcounter='0'
   else
       failcounter=$((failcounter + 1))
       echo "$(tput setaf 1)vpn is down ($failcounter), start reconnect"
       echo "-- close old connection"
       nmcli con down id "${vpn_con_id}" 2> /dev/null 1> /dev/null
       #echo "kill all ovpn"
       #sudo killall openvpn
       echo "-- start new connection"
       nmcli --ask con up id "${vpn_con_id}"
   fi
   COUNTER=$run_interval
   while [  $COUNTER -gt 0 ]; do
        echo -e "$(tput sgr0)$(tput cub 5)$COUNTER...\c"
        let COUNTER=COUNTER-1
        sleep 1
   done
   echo ""
   if [ $failcounter -eq $failcounter_max ]
	then
	echo "$(tput setaf 1)-- a row of failure, restarting network-manager"
	systemctl restart NetworkManager.service
   fi

done # mainloop

