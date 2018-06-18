#!/bin/bash
# Tested on RHEL/CENTOS only
# Reset SSH hosts keys 

# Delete existing keys
rm -fR /etc/ssh/ssh_host*

# Regenerate all missing SSH keys
ssh-keygen -A |  sed -e "s/^/$(date -R) /" >> /var/log/ssh_keygen.log 2>&1

# Set the correct file permissions and ownership
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host*.pub
chown root:root /var/empty/sshd
chmod 711 /var/empty/sshd

# Disable firewall
systemctl disable firewalld

# Restart SSH
systemctl restart sshd.service

exit 0