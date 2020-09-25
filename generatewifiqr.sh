#!/bin/bash
if [ $# -ne 2 ]; 
then
	echo -e "Usage: \n$0 <SSID> <PASSPHRASE>" ;
	exit 1;
else
	echo "WIFI:S:$1;T:WPA;P:$2;;" | qr ;
fi
