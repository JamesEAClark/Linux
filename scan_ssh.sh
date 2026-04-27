#!/bin/bash

# Get the local subnet (e.g., 192.168.1.0/24)
# Adjust the interface name if necessary
subnet=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')

# Check if subnet is detected
if [ -z "$subnet" ]; then
    echo "Unable to detect local subnet. Please check your network configuration."
    exit 1
fi

echo "Scanning subnet: $subnet for machines with port 22 open..."

# Use nmap to scan for open port 22
nmap -p 22 --open -n $subnet | awk '/^Nmap scan report/{ip=$NF}/22\/tcp open/{print ip}'
