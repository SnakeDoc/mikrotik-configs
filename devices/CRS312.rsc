###############################################################################
# Configuration for CRS312-4C+8XG-RM RouterOS 7.x - Switch only
#
# All routing, DHCP, DNS and firewalling happen on the CCR2004.
# The WAN enters here (ether1, from the ONT) and rides the trunk to the CCR2004 in its own VLAN
#
# Start with a system reset. Upload CRS312.rsc, then run the following:
#
#    /system reset-configuration no-defaults=yes keep-users=yes run-after-reset=CRS312.rsc
#
###############################################################################

#######################################
# Naming
#######################################

/system identity set name="CRS312"

#######################################
# VLAN Overview (defined on the CCR2004)
#######################################

#  2 = WAN - ONT handoff, carried to the CCR2004, no address
# 10 = GUEST - 10.0.10.0/27
# 20 = IOT - 10.0.20.0/27
# 30 = TRUSTED - 10.0.30.0/28
# 40 = SERVICES - 10.0.40.0/28
# 50 = LAB - 10.0.50.0/28
# 99 = MGMT - 10.0.99.0/29 - this device is 10.0.99.3

# OOB (not a VLAN) = ether9-oob-mgmt, untagged - 172.16.0.2/29

#######################################
# Port Overview
#######################################

# ether1  = WAN from ONT (2)
# ether2  = mgmt (99) - admin workstation GbE NIC
# ether3-5 = trusted (30) - disabled until used
# ether6-7 = services (40) - disabled until used
# ether8  = lab (50) - disabled until used
# ether9  = OOB management, not a bridge port
# combo1  = trunk to CCR2004 sfp28-1-trunk (SFP+ DAC) - tagged 2,10,20,30,40,50,99
# combo2  = spare, disabled
# combo3  = trunk to RB4011 sfp-sfpplus1 (SFP+ DAC) - tagged 10,20,30,40,50,99
# combo4  = desktop SFP+ DAC - trusted (30)

#######################################
# Port Configuration
#######################################

/interface ethernet set [ find default-name=ether1 ] name="ether1-wan" disabled=no
/interface ethernet set [ find default-name=ether2 ] disabled=no
/interface ethernet set [ find default-name=ether3 ] disabled=yes
/interface ethernet set [ find default-name=ether4 ] disabled=yes
/interface ethernet set [ find default-name=ether5 ] disabled=yes
/interface ethernet set [ find default-name=ether6 ] disabled=yes
/interface ethernet set [ find default-name=ether7 ] disabled=yes
/interface ethernet set [ find default-name=ether8 ] disabled=yes
/interface ethernet set [ find default-name=ether9 ] name="ether9-oob-mgmt" disabled=no
/interface ethernet set [ find default-name=combo1 ] name="combo1-trunk-ccr2004" combo-mode=sfp disabled=no
/interface ethernet set [ find default-name=combo2 ] disabled=yes
/interface ethernet set [ find default-name=combo3 ] name="combo3-trunk-rb4011" combo-mode=sfp disabled=no
/interface ethernet set [ find default-name=combo4 ] combo-mode=sfp disabled=no

#######################################
# Bridge
#######################################

# CYA - VLAN filtering enabled later
/interface bridge add name="br1" vlan-filtering=no

#######################################
# Trunk Ports
#######################################

# Ingress: tagged frames only
/interface bridge port add bridge="br1" interface="combo1-trunk-ccr2004" frame-types=admit-only-vlan-tagged comment="trunk to CCR2004"
/interface bridge port add bridge="br1" interface="combo3-trunk-rb4011" frame-types=admit-only-vlan-tagged comment="trunk to RB4011"

# Egress: The WAN VLAN exists only on two ports ether1-wan (untagged, via pvid) and the CCR2004 trunk. The bridge itself is a tagged member of VLAN 99 only.
/interface bridge vlan add bridge="br1" tagged="combo1-trunk-ccr2004" vlan-ids=2
/interface bridge vlan add bridge="br1" tagged="combo1-trunk-ccr2004,combo3-trunk-rb4011" vlan-ids=10,20,30,40,50
/interface bridge vlan add bridge="br1" tagged="br1,combo1-trunk-ccr2004,combo3-trunk-rb4011" vlan-ids=99

#######################################
# Access Ports
#######################################

/interface bridge port add bridge="br1" interface="ether1-wan" pvid=2 frame-types=admit-only-untagged-and-priority-tagged comment="WAN from ONT"
/interface bridge port add bridge="br1" interface="ether2" pvid=99 frame-types=admit-only-untagged-and-priority-tagged comment="mgmt - admin workstation"
/interface bridge port add bridge="br1" interface="ether3" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether4" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether5" pvid=30 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether6" pvid=40 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether7" pvid=40 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="ether8" pvid=50 frame-types=admit-only-untagged-and-priority-tagged
/interface bridge port add bridge="br1" interface="combo4" pvid=30 frame-types=admit-only-untagged-and-priority-tagged comment="desktop SFP+ DAC"

#######################################
# Management
#######################################

# This device's address on the mgmt VLAN, reached through the bridge.
/interface vlan add interface="br1" name="mgmt-vlan" vlan-id=99
/ip address add interface="mgmt-vlan" address=10.0.99.2/29
/ip route add gateway=10.0.99.1 comment="CCR2004"
/ip dns set servers=10.0.99.1

# OOB management on ether9-oob-mgmt - untagged
# no gateway or DNS - nothing routes through this port
/ip address add interface="ether9-oob-mgmt" address=172.16.0.2/29

/interface list add name="mgmt"
/interface list member add interface="mgmt-vlan" list="mgmt"
/interface list member add interface="ether9-oob-mgmt" list="mgmt"

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
add chain=forward action=drop comment="This device does not route"

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
/ip service set ssh available-from=172.16.0.0/29,10.0.99.0/29

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
