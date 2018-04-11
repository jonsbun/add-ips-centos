# Add IP Addresses Range to CentOS

Script which allows you simple bind IPs ranges to CentOS/RHEL based Linux system. All provided ranges will be placed in the `/etc/sysconfig/network-scripts` directory using separate scripts and `ifcfg-eth0-rangeX` naming system (where X is a unique number corresponding to a specific range). Keep in mind that this script allows to add multiple IPs ranges at once. However, script supports not bigger than /16 ranges at this moment.

## How to Use

You can run this script remotely on any CentOS/RHEL based Linux machine using following command:

```bash
bash <(curl -s -L https://git.io/add-ips-centos.sh)
```

If you want to run this script locally, use these commands:
```
wget https://git.io/add-ips-centos.sh && chmod +x add-ips-centos.sh
./add-ips-centos.sh
```

**Please follow these rules when you want to add IPs:**
- Write each new range from the new line;
- Don't use any extra symbols after netmask number;
- After last range hit Ctrl-D on a blank line to stop input.
