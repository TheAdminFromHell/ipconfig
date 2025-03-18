#!/bin/bash

# Define the interface (change if needed)
INTERFACE="enp34s0"

# Check if interface exists
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "Error: Network interface '$INTERFACE' not found."
    exit 1
fi

# Get system info
OS_NAME=$(lsb_release -d | cut -f2)
KERNEL_VERSION=$(uname -r)
HOSTNAME=$(hostname)

# Get network info
MAC_ADDRESS=$(cat /sys/class/net/$INTERFACE/address | tr 'a-z' 'A-Z')
IPV4_INFO=$(ip -o -4 addr show $INTERFACE | awk '{print $4}')
IPV4_ADDRESS=$(echo "$IPV4_INFO" | cut -d'/' -f1)
CIDR=$(echo "$IPV4_INFO" | cut -d'/' -f2)

# Convert CIDR to Subnet Mask
SUBNET_MASK=$(awk -v c="$CIDR" 'BEGIN{
    for (i=0; i<c; i++) s=s"1";
    for (i=c; i<32; i++) s=s"0";
    for (i=0; i<4; i++) {
        subnets=(subnets (i? ".":"") strtonum("0b" substr(s, i*8+1, 8)))
    }
    print subnets
}')

DEFAULT_GATEWAY=$(ip route show default | awk '{print $3}')
DNS_SERVERS=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
VENDOR_ID=$(lspci -nn | grep -i ethernet | awk -F '[][]' '{print "0x"$2 " 0x"$4}')

# Print header
echo -e "\nLinux Operating System"
echo "Copyright (c) 2025 Linux Foundation. All rights reserved."
echo ""
echo "Linux IP Configuration"
echo ""
echo "Operating System . . . . . . . . : $OS_NAME"
echo "Kernel Version . . . . . . . . . : $KERNEL_VERSION"
echo "Host Name . . . . . . . . . . .  : $HOSTNAME"
echo ""

# Print basic network info
echo "Interface: $INTERFACE"
echo "Description . . . . . . . . . . . : $VENDOR_ID"
echo "Physical Address. . . . . . . . . : $MAC_ADDRESS"
echo "DHCP Enabled. . . . . . . . . . . : No"
echo "IPv4 Address. . . . . . . . . . . : $IPV4_ADDRESS"
echo "Subnet Mask . . . . . . . . . . . : $SUBNET_MASK"
echo "Default Gateway . . . . . . . . . : $DEFAULT_GATEWAY"
echo -n "DNS Servers . . . . . . . . . . . : "
echo "$DNS_SERVERS" | awk '{print (NR==1 ? $0 : "                                    " $0)}'
echo "NetBIOS over Tcpip. . . . . . . . : Microsoft Moment 69™"

# Handle `/all` argument
if [[ "$1" == "/all" ]]; then
    echo ""
    echo "Extended Network Information:"
    echo "--------------------------------"
    echo "IPv6 Address. . . . . . . . . . . : $(ip -o -6 addr show $INTERFACE | awk '{print $4}')"
    echo "MTU Size. . . . . . . . . . . . . : $(cat /sys/class/net/$INTERFACE/mtu)"
    echo "Interface State. . . . . . . . .  : $(cat /sys/class/net/$INTERFACE/operstate)"
    echo "RX Bytes. . . . . . . . . . . . . : $(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)"
    echo "TX Bytes. . . . . . . . . . . . . : $(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)"
    echo "DHCP Lease Info. . . . . . . . .  :"

    # DHCP lease file (different distros store it differently)
    DHCP_LEASE_FILE="/var/lib/dhcp/dhclient.$INTERFACE.leases"
    if [[ -f "$DHCP_LEASE_FILE" ]]; then
        cat "$DHCP_LEASE_FILE"
    else
        echo "  No lease information found."
    fi
fi

echo ""
