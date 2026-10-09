###############################################################################
# Configuration for RB4011iGS+5HacQ2HnD RouterOS 7.x - Access Point + Switch
#
# Trunked over DAC: sfp-sfpplus1 <-> CCR2004 sfp28-1-trunk
# All routing, DHCP, DNS and firewalling happen on the CCR2004.
#
# Start with a system reset. Upload RB4011.rsc, then run the following:
#
#    /system reset-configuration no-defaults=yes keep-users=yes run-after-reset=RB4011.rsc
#
###############################################################################

#######################################
# Naming
#######################################

/system identity set name="RB4011"

#######################################
# VLAN Overview (defined on the CCR2004)
#######################################

# 10 = GUEST - 10.0.10.0/27
# 20 = IOT - 10.0.20.0/27
# 30 = TRUSTED - 10.0.30.0/28
# 40 = SERVICES - 10.0.40.0/28
# 50 = LAB - 10.0.50.0/28
# 99 = MGMT - 10.0.99.0/29 - this device is 10.0.99.3

#######################################
# Port Overview
#######################################

# sfp-sfpplus1 = trunk to CCR2004 (tagged 10,20,30,40,50,99)
# ether1       = mgmt (99) - admin workstation GbE NIC
# ether2-5     = trusted (30)
# ether6-7     = services (40)
# ether8-9     = lab (50)
# ether10      = iot (20) - passive PoE-out stays OFF
#
# wlan1 (5 GHz)   = Agrippa/trusted (30), Drusus/guest (10)
# wlan2 (2.4 GHz) = Agrippa/trusted (30), Drusus/guest (10), IOT/iot (20)

#######################################
# Port Configuration
#######################################

# Disable passive PoE-out - not in use
/interface ethernet set [ find default-name=ether10 ] poe-out=off

#######################################
# Wireless
#######################################

# The default profile is configured as trusted so that any wireless interface created without an explicit profile is never an open network.
/interface wireless security-profiles set [ find default=yes ] mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key="CHANGE-ME-TRUSTED" disable-pmkid=yes management-protection=allowed
/interface wireless security-profiles add name="guest" mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key="CHANGE-ME-GUEST" disable-pmkid=yes management-protection=allowed
/interface wireless security-profiles add name="iot" mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key="CHANGE-ME-IOT" disable-pmkid=yes

/interface wireless set [ find default-name=wlan1 ] name="wlan1-trusted-5g" ssid="Agrippa" mode=ap-bridge band=5ghz-onlyac channel-width=20/40/80mhz-XXXX frequency=auto country="united states3" distance=indoors wireless-protocol=802.11 wmm-support=enabled wps-mode=disabled security-profile=default disabled=no

/interface wireless set [ find default-name=wlan2 ] name="wlan2-trusted-2g" ssid="Agrippa" mode=ap-bridge band=2ghz-g/n channel-width=20mhz frequency=auto country="united states3" distance=indoors wireless-protocol=802.11 wmm-support=enabled wps-mode=disabled security-profile=default disabled=no

# Virtual APs. Guest clients are isolated from each other (default-forwarding=no).
/interface wireless add name="wlan3-guest-5g" master-interface="wlan1-trusted-5g" ssid="Drusus" security-profile="guest" default-forwarding=no wmm-support=enabled wps-mode=disabled disabled=no
/interface wireless add name="wlan4-guest-2g" master-interface="wlan2-trusted-2g" ssid="Drusus" security-profile="guest" default-forwarding=no wmm-support=enabled wps-mode=disabled disabled=no
/interface wireless add name="wlan5-iot-2g" master-interface="wlan2-trusted-2g" ssid="IOT" security-profile="iot" wmm-support=enabled wps-mode=disabled disabled=no

#######################################
# Bridge
#######################################

# CYA - VLAN filtering enabled later
/interface bridge add name="br1" vlan-filtering=no

#######################################
# Trunk Port
#######################################

# Ingress: tagged frames only
/interface bridge port add bridge="br1" interface="sfp-sfpplus1" frame-types=admit-only-vlan-tagged comment="trunk to CCR2004"

# Egress: every VLAN leaves the trunk tagged
/interface bridge vlan add bridge="br1" tagged="sfp-sfpplus1" vlan-ids=10,20,30,40,50
/interface bridge vlan add bridge="br1" tagged="br1,sfp-sfpplus1" vlan-ids=99

#######################################
# Access Ports
#######################################

/interface bridge port add bridge="br1" interface="ether1" pvid=99 frame-types=admit-only-untagged-and-priority-tagged comment="mgmt - admin workstation"
/interface bridge port add bridge="br1" interface="ether2" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether3" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether4" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether5" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether6" pvid=40 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether7" pvid=40 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether8" pvid=50 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether9" pvid=50 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether10" pvid=20 frame-types=admit-only-untagged-and-priority-tagged

/interface bridge port add bridge="br1" interface="wlan1-trusted-5g" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="wlan2-trusted-2g" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="wlan3-guest-5g" pvid=10 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="wlan4-guest-2g" pvid=10 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="wlan5-iot-2g" pvid=20 frame-types=admit-only-untagged-and-priority-tagged

#######################################
# Management
#######################################

# This device's only address, on the mgmt VLAN, reached through the bridge.
# Static and outside the CCR2004's mgmt-pool.
/interface vlan add interface="br1" name="mgmt-vlan" vlan-id=99
/ip address add interface="mgmt-vlan" address=10.0.99.3/29
/ip route add gateway=10.0.99.1 comment="CCR2004"
/ip dns set servers=10.0.99.1

/interface list add name="mgmt"
/interface list member add interface="mgmt-vlan" list="mgmt"

#######################################
# Firewall
#######################################

# Basic rules to protect the device itself
/ip firewall filter
add chain=input action=accept connection-state=established,related comment="Allow established and related connections"
add chain=input action=drop connection-state=invalid comment="Drop invalid connections"
add chain=input action=accept in-interface="lo" comment="Allow loopback traffic"
add chain=input action=accept in-interface-list="mgmt" comment="Allow full access from mgmt"
add chain=input action=drop comment="Drop all other input traffic"

# Disable IPv6 - unused
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
/ip service set ssh available-from=10.0.99.0/29

# Disable unused services
/ip service disable telnet,ftp,www,www-ssl,reverse-proxy,api,api-ssl
/tool bandwidth-server set enabled=no

# Set system clock and NTP client
/system clock set time-zone-name="America/Chicago"
/system ntp client set enabled=yes servers=time.cloudflare.com

#######################################
# Turn on VLAN filtering
#######################################

/interface bridge set br1 vlan-filtering=yes
