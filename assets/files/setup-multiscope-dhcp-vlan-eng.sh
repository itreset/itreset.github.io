#!/bin/bash

set -e

echo "=== Interactive DHCP Installer (with VLAN support) for Ubuntu 22.04 / 24.04 ==="

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root (e.g., sudo $0)"
  exit 1
fi

apt update && apt install -y isc-dhcp-server vlan

echo ""
echo "Available network interfaces:"
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
echo "$interfaces"
echo ""

read -p "How many subnets do you want to configure? (e.g., 2): " SUBNET_COUNT

NETPLAN_CFG="network:\n  version: 2\n  ethernets:\n"
VLAN_CFG=""
DHCP_CONF="default-lease-time 600;\nmax-lease-time 7200;\nauthoritative;\n"
IFACE_LIST=()

for ((i=1; i<=SUBNET_COUNT; i++)); do
  echo ""
  echo "=== Configuration for subnet $i ==="

  echo "Should this subnet use a VLAN interface? (y/n)"
  read -n1 USE_VLAN
  echo ""

  if [[ "$USE_VLAN" == "y" || "$USE_VLAN" == "Y" ]]; then
    echo "Select the parent (physical) interface for the VLAN:"
    select PARENT_IFACE in $interfaces; do
      [[ -n "$PARENT_IFACE" ]] && break
    done

    read -p "Enter VLAN ID (e.g., 10): " VLAN_ID
    VLAN_IFACE="${PARENT_IFACE}.${VLAN_ID}"
    IFACE_LIST+=("${VLAN_IFACE}")

    VLAN_CFG+="  vlans:\n"
    VLAN_CFG+="    ${VLAN_IFACE}:\n"
    VLAN_CFG+="      id: ${VLAN_ID}\n"
    VLAN_CFG+="      link: ${PARENT_IFACE}\n"

    read -p "Enter the server IP address (e.g., 192.168.${VLAN_ID}.1): " SERVER_IP
    read -p "Enter the subnet mask (e.g., 255.255.255.0): " NETMASK
    read -p "Enter the default gateway (e.g., 192.168.${VLAN_ID}.254): " GATEWAY
    read -p "Enter the DHCP range start (e.g., 192.168.${VLAN_ID}.100): " DHCP_START
    read -p "Enter the DHCP range end (e.g., 192.168.${VLAN_ID}.200): " DHCP_END
    read -p "Enter CIDR prefix length (e.g., 24): " CIDR

    VLAN_CFG+="      addresses: [${SERVER_IP}/${CIDR}]\n"
    VLAN_CFG+="      gateway4: ${GATEWAY}\n"
    VLAN_CFG+="      nameservers:\n"
    VLAN_CFG+="        addresses: [8.8.8.8,8.8.4.4]\n"

  else
    echo "Select a physical interface for this subnet:"
    select IFACE in $interfaces; do
      [[ -n "$IFACE" ]] && break
    done

    IFACE_LIST+=("$IFACE")

    read -p "Enter the server IP address (e.g., 192.168.1.1): " SERVER_IP
    read -p "Enter the subnet mask (e.g., 255.255.255.0): " NETMASK
    read -p "Enter the default gateway (e.g., 192.168.1.254): " GATEWAY
    read -p "Enter the DHCP range start (e.g., 192.168.1.100): " DHCP_START
    read -p "Enter the DHCP range end (e.g., 192.168.1.200): " DHCP_END
    read -p "Enter CIDR prefix length (e.g., 24): " CIDR

    NETPLAN_CFG+="    ${IFACE}:\n"
    NETPLAN_CFG+="      addresses: [${SERVER_IP}/${CIDR}]\n"
    NETPLAN_CFG+="      gateway4: ${GATEWAY}\n"
    NETPLAN_CFG+="      nameservers:\n"
    NETPLAN_CFG+="        addresses: [8.8.8.8,8.8.4.4]\n"
  fi

  SUBNET_BASE=$(echo "$SERVER_IP" | awk -F'.' '{print $1"."$2"."$3".0"}')
  DHCP_CONF+="\nsubnet ${SUBNET_BASE} netmask ${NETMASK} {\n"
  DHCP_CONF+="  range ${DHCP_START} ${DHCP_END};\n"
  DHCP_CONF+="  option routers ${GATEWAY};\n"
  DHCP_CONF+="  option subnet-mask ${NETMASK};\n"
  DHCP_CONF+="  option domain-name-servers 8.8.8.8, 8.8.4.4;\n"
  DHCP_CONF+="}\n"
done

echo ""
echo "=== Generating configuration ==="

# Finalize netplan
NETPLAN_ALL="$NETPLAN_CFG"
if [[ -n "$VLAN_CFG" ]]; then
  NETPLAN_ALL+="\n$VLAN_CFG"
fi

echo -e "$NETPLAN_ALL" > /etc/netplan/01-multiscope-dhcp.yaml
echo "Applying netplan..."
netplan apply

# Configure DHCP server interfaces
echo "INTERFACESv4=\"${IFACE_LIST[*]}\"" > /etc/default/isc-dhcp-server
echo -e "$DHCP_CONF" > /etc/dhcp/dhcpd.conf

systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

echo ""
echo "✅ Done! DHCP server is now running on interfaces: ${IFACE_LIST[*]}"
