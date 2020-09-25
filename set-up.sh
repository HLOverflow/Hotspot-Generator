#!/bin/bash

if [ $# -ne 1 ]; 
then
	echo -e "This will generate a hotspot with generated password for a chosen SSID. \n"
	echo -e "Usage:\n$0 <SSID>";
	exit 1;
fi

if [ ! $(id -u) -eq "0" ]; 
then 
	echo "Please run as root"
	exit 2;
fi


# Start

# change hostapd
SSIDNAME=$1
echo -e "\e[32m(1/8) - Setting SSID to $SSIDNAME \e[39m"
sed s/SSIDHERE/$SSIDNAME/ hostapd.conf.template > hostapd.conf

# Generate New Passphase
RANDOMPASSPHRASE=$(uuidgen)
echo -e "\e[32m(2/8) - Generated random passphrase to $RANDOMPASSPHRASE \e[39m"
sed -i s/PASSPHRASEHERE/$RANDOMPASSPHRASE/ hostapd.conf

echo -e "\e[32m(3/8) - Updating /etc/hostapd/hostapd.conf \e[39m"
cp hostapd.conf /etc/hostapd/hostapd.conf

echo -e "\e[32m(4/8) - Configuring hotspot's ip and route \e[39m"
# Configure IP address for WLAN
ifconfig wlan0 192.168.150.1
# Start DHCP/DNS server
service dnsmasq restart
# Enable routing
sysctl net.ipv4.ip_forward=1
# Enable NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Generate QR code for WIFI connection

echo -e "\e[32m(5/8) - Generating QR code to connect to \e[39m"
./generatewifiqr.sh $(cat /etc/hostapd/hostapd.conf | grep "ssid\|wpa_passphrase" | cut -d"=" -f2 | xargs)
# Run access point daemon

echo -e "\e[32m(6/8) - Running hostapd now... Use Ctrl-C to terminate hotspot \e[39m"
hostapd /etc/hostapd/hostapd.conf || (echo -e "\e[91m[!] Something went wrong... try : airmon-ng check kill \e[39m"; exit 1;)

# Stop
# Disable NAT
echo -e "\e[32m(7/8) - Resetting firewall and routes \e[39m"
iptables -D POSTROUTING -t nat -o eth0 -j MASQUERADE

# Disable routing
sysctl net.ipv4.ip_forward=0

# Disable DHCP/DNS server
echo -e "\e[32m(8/8) - Stopping services ...  \e[39m"
service dnsmasq stop
service hostapd stop
