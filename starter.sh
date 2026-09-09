#!/bin/bash

# Linux Firewall Practical
# Student Name:
# Register Number:

# 1. Check firewalld service status
systemctl status firewalld

# 2. Start firewalld
systemctl start firewalld

# 3. Enable firewalld at boot
systemctl enable firewalld

# 4. Check firewall state
firewall-cmd --state

# 5. Get default firewall zone
firewall-cmd --get-default-zone

# 6. Get active firewall zones
firewall-cmd --get-active-zones
