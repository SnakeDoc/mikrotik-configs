###############################################################################
# Configuration for CCR2004-1G-12S+2XS RouterOS 7.x - Router
#
# Start with a system reset. Upload CCR2004.rsc, then run the following:
#
#    /system reset-configuration no-defaults=yes keep-users=yes run-after-reset=CCR2004.rsc
#
###############################################################################

#######################################
# Naming
#######################################

/system identity set name="CCR2004"

#######################################
# VLAN Overview
#######################################

# 10 = GUEST - 10.0.10.0/27
# 20 = IOT - 10.0.20.0/27
# 30 = TRUSTED - 10.0.30.0/28
# 40 = SERVICES - 10.0.40.0/28
# 50 = LAB - 10.0.50.0/28
# 99 = MGMT - 10.0.99.0/29

# OOB (not a VLAN) = ether1-oob-mgmt, untagged - 172.16.0.0/29

#######################################
# Port Configuration
#######################################

/interface ethernet set [ find default-name=ether1 ] name="ether1-oob-mgmt" disabled=no
/interface ethernet set [ find default-name=sfp-sfpplus1 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus2 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus3 ] name="sfp-sfpplus3-wan" disabled=no
/interface ethernet set [ find default-name=sfp-sfpplus4 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus5 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus6 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus7 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus8 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus9 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus10 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus11 ] disabled=yes
/interface ethernet set [ find default-name=sfp-sfpplus12 ] comment="TEMP: desktop DAC until switch" disabled=no
/interface ethernet set [ find default-name=sfp28-1 ] name="sfp28-1-trunk" disabled=no
/interface ethernet set [ find default-name=sfp28-2 ] disabled=yes

#######################################
# WAN settings
#######################################

# WAN DHCP client to pick up IP Address from the ISP
/ip dhcp-client add interface="sfp-sfpplus3-wan" name="wan-dhcp" use-peer-dns=no use-peer-ntp=no

#######################################
# IP Services
#######################################

# DNS server, cache for LAN
/ip dns set allow-remote-requests=yes servers="9.9.9.9,149.112.112.112"

# Interface Lists for easy rule matching
/interface list add name="wan"
/interface list add name="vlan"
/interface list add name="mgmt"

/interface list member add interface="sfp-sfpplus3-wan" list="wan"

# TEMP: desktop DAC until switch
/ip address add interface="sfp-sfpplus12" address=10.0.0.1/30 comment="TEMP: desktop DAC until switch"
/interface list member add interface="sfp-sfpplus12" list="vlan" comment="TEMP: desktop DAC until switch"
/ip pool add name="temp-pool" ranges=10.0.0.2 comment="TEMP: desktop DAC until switch"
/ip dhcp-server add interface="sfp-sfpplus12" name="temp-dhcp" address-pool="temp-pool" comment="TEMP: desktop DAC until switch"
/ip dhcp-server network add address=10.0.0.0/30 dns-server=10.0.0.1 gateway=10.0.0.1 comment="TEMP: desktop DAC until switch"

# Guest VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="guest-vlan" vlan-id=10
/ip address add interface="guest-vlan" address=10.0.10.1/27
/ip pool add name="guest-pool" ranges=10.0.10.2-10.0.10.30
/ip dhcp-server add interface="guest-vlan" name="guest-dhcp" address-pool="guest-pool"
/ip dhcp-server network add address=10.0.10.0/27 dns-server=10.0.10.1 gateway=10.0.10.1
/interface list member add interface="guest-vlan" list="vlan"

# IOT VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="iot-vlan" vlan-id=20
/ip address add interface="iot-vlan" address=10.0.20.1/27
/ip pool add name="iot-pool" ranges=10.0.20.2-10.0.20.30
/ip dhcp-server add interface="iot-vlan" name="iot-dhcp" address-pool="iot-pool"
/ip dhcp-server network add address=10.0.20.0/27 dns-server=10.0.20.1 gateway=10.0.20.1
/interface list member add interface="iot-vlan" list="vlan"

# Trusted VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="trusted-vlan" vlan-id=30
/ip address add interface="trusted-vlan" address=10.0.30.1/28
/ip pool add name="trusted-pool" ranges=10.0.30.2-10.0.30.14
/ip dhcp-server add interface="trusted-vlan" name="trusted-dhcp" address-pool="trusted-pool"
/ip dhcp-server network add address=10.0.30.0/28 dns-server=10.0.30.1 gateway=10.0.30.1
/interface list member add interface="trusted-vlan" list="vlan"

# Services VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="services-vlan" vlan-id=40
/ip address add interface="services-vlan" address=10.0.40.1/28
/ip pool add name="services-pool" ranges=10.0.40.2-10.0.40.14
/ip dhcp-server add interface="services-vlan" name="services-dhcp" address-pool="services-pool"
/ip dhcp-server network add address=10.0.40.0/28 dns-server=10.0.40.1 gateway=10.0.40.1
/interface list member add interface="services-vlan" list="vlan"

# Lab VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="lab-vlan" vlan-id=50
/ip address add interface="lab-vlan" address=10.0.50.1/28
/ip pool add name="lab-pool" ranges=10.0.50.2-10.0.50.14
/ip dhcp-server add interface="lab-vlan" name="lab-dhcp" address-pool="lab-pool"
/ip dhcp-server network add address=10.0.50.0/28 dns-server=10.0.50.1 gateway=10.0.50.1
/interface list member add interface="lab-vlan" list="vlan"

# Mgmt VLAN creation, IP assignment, and DHCP service
/interface vlan add interface="sfp28-1-trunk" name="mgmt-vlan" vlan-id=99
/ip address add interface="mgmt-vlan" address=10.0.99.1/29
/ip pool add name="mgmt-pool" ranges=10.0.99.2-10.0.99.6
/ip dhcp-server add interface="mgmt-vlan" name="mgmt-dhcp" address-pool="mgmt-pool"
/ip dhcp-server network add address=10.0.99.0/29 dns-server=10.0.99.1 gateway=10.0.99.1
/interface list member add interface="mgmt-vlan" list="vlan"
/interface list member add interface="mgmt-vlan" list="mgmt"

# OOB management on ether1-oob-mgmt - untagged
# no gateway or DNS - nothing routes through this port
/ip address add interface="ether1-oob-mgmt" address=172.16.0.1/29
/ip pool add name="oob-mgmt-pool" ranges=172.16.0.2-172.16.0.6
/ip dhcp-server add interface="ether1-oob-mgmt" name="oob-mgmt-dhcp" address-pool="oob-mgmt-pool"
/ip dhcp-server network add address=172.16.0.0/29
/interface list member add interface="ether1-oob-mgmt" list="mgmt"

#######################################
# Firewalling & NAT
#######################################

# VLAN aware firewall - order is important!
/ip firewall filter

##################
# INPUT CHAIN
##################
add chain=input action=accept connection-state=established,related comment="Allow established and related connections"

add chain=input action=drop connection-state=invalid comment="Drop invalid connections"

# Allow loopback
add chain=input action=accept in-interface="lo" comment="Allow loopback traffic"

# Allow VLANs to access router services (DNS, DHCP, etc.)
add chain=input action=accept in-interface-list="vlan" protocol=udp dst-port=53 comment="Allow DNS from VLANs"
add chain=input action=accept in-interface-list="vlan" protocol=tcp dst-port=53 comment="Allow DNS from VLANs"
add chain=input action=accept in-interface-list="vlan" protocol=udp dst-port=67 comment="Allow DHCP from VLANs"
add chain=input action=accept in-interface-list="vlan" protocol=icmp comment="Allow ICMP from VLANs"

# Allow mgmt full access to the device for Winbox, etc.
add chain=input action=accept in-interface-list="mgmt" comment="Allow full access from mgmt"

add chain=input action=drop comment="Drop all other input traffic"

##################
# FORWARD CHAIN
##################
add chain=forward action=fasttrack-connection connection-state=established,related comment="Fasttrack established and related connections"
add chain=forward action=accept connection-state=established,related comment="Allow established and related connections"

add chain=forward action=drop connection-state=invalid comment="Drop invalid connections"

# Allow all VLANs to access the internet only - NOT each other
add chain=forward action=accept connection-state=new in-interface-list="vlan" out-interface-list="wan" comment="Allow VLANs to access the internet only"

add chain=forward action=drop comment="Drop all other forward traffic"

##################
# NAT
##################
/ip firewall nat add chain=srcnat action=masquerade out-interface-list="wan" comment="Masquerade traffic going out to the internet"

##################
# IPv6
##################

# Disable IPv6 - unused and not offered by ISP
/ipv6 settings set disable-ipv6=yes

#######################################
# MAC Server settings
#######################################

# Ensure only visibility and availability from mgmt
/ip neighbor discovery-settings set discover-interface-list="mgmt"
/tool mac-server mac-winbox set allowed-interface-list="mgmt"
/tool mac-server set allowed-interface-list="mgmt"

#######################################
# Services settings
#######################################

/ip ssh set strong-crypto=yes
/ip service set ssh available-from=172.16.0.0/29,10.0.99.0/29

# Disable unused services
/ip service disable telnet,ftp,www,www-ssl,reverse-proxy,api,api-ssl
/ip firewall service-port disable ftp,h323,irc,pptp,rtsp,sip,tftp
/tool bandwidth-server set enabled=no

# Set system clock and NTP client
/system clock set time-zone-name="America/Chicago"
/system ntp client set enabled=yes servers=time.cloudflare.com
