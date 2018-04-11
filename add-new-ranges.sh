#!/bin/bash
#
# Simple way to add IPs ranges to CentOS/RHEL system
# (c) Jonas Bunevicius, 2018 
#

################## chk_os_version() #####################
chk_os_version() {
   if [ $1 -eq 0 ]
   then
      echo
      echo "Sorry, script supports only CentOS/RHEL based systems..."
      echo
      exit 1
   fi
}
#########################################################

################# chk_subnet_input() ####################
chk_subnet_input() {
   mask=$(echo $1 | awk -F '/' '{print $2}')
   if [[ $mask =~ ^[0-9]+$ ]]
   then
      if [ $mask -lt 16 ]
      then
         echo "Range $1 not supported yet..."
         exit 1
      elif [ $mask -gt 31 ]
      then
         echo "Range $1 is invalid..."
         exit 1
      fi
   else
      echo "Range $1 was defined incorrectly..."
      exit 1
   fi
}
#########################################################

################# upd_clonenum_start() ##################
upd_clonenum_start() {
   if [ -z $clonenum_start ]
   then
      clonenum_start=$(ifconfig | grep ^eth0: | tail -n1 |\
                       awk -F ' ' '{print $1}' | cut -d ':' -f2)
      already_checked=0
   fi

   if [ $already_checked -eq 0 ]
   then
      if [ -z $clonenum_start ]
      then 
         clonenum_start=0
      else
         let clonenum_start++
      fi
      already_checked=1
   else
      let clonenum_start+=$prv_step
   fi
   prv_step=$step
}
##########################################################

################## add_ifcfg-range() #####################
add_ifcfg-range() {
   if [ -z $num ]
   then
      num=$(ls -l /etc/sysconfig/network-scripts/ | grep ifcfg-eth0-.* |\
            awk -F ' ' '{print $9}' | sed 's/.*range//' | sort -n | tail -n1)
   fi

   if [ -z $num ]
   then
      num=0
      cd /etc/sysconfig/network-scripts && touch ifcfg-eth0-range${num}
   else
      let num++
      cd /etc/sysconfig/network-scripts && touch ifcfg-eth0-range${num}
   fi 

   echo "IPADDR_START="${ipaddr_start} >> /etc/sysconfig/network-scripts/ifcfg-eth0-range${num}
   echo "IPADDR_END="${ipaddr_end} >> /etc/sysconfig/network-scripts/ifcfg-eth0-range${num}
   echo "NETMASK="${netmask} >> /etc/sysconfig/network-scripts/ifcfg-eth0-range${num}
   echo "CLONENUM_START="${clonenum_start} >> /etc/sysconfig/network-scripts/ifcfg-eth0-range${num}
   echo ARPCHECK=no >> /etc/sysconfig/network-scripts/ifcfg-eth0-range${num}
}
##########################################################

#################### calc_boundry() ######################
calc_boundry() {
   ips=$((2 ** (32 - $2)))
   if [ $ips -gt 256 ]
   then 
      step=256
   else
      step=$ips
   fi
   
   hosts=$((2 ** ($1 - $2)))
   boundry=$((($3 / $hosts) * $hosts))
   wildcard=$(((2 ** ($1 - $2)) - 1))
}
##########################################################

RED="\e[91m"
NC="\e[0m"

chk_os_version $(cat /etc/*-release | grep -i centos | wc -l)

netmask=255.255.255.255

echo
echo -e "${RED}>>>${NC} Please enter IP(s) with netmask (e.g. 192.168.100.0/25) ${RED}<<<${NC}"
echo -e "${RED}>>>${NC}    Each new IP ranges please write from the new line    ${RED}<<<${NC}"
echo -e "${RED}>>>${NC} When you done, hit Ctrl-D on a blank line to stop input ${RED}<<<${NC}"
echo

readarray -t subnet
echo

for ((i=0; i < ${#subnet[@]}; i++))
do
   chk_subnet_input ${subnet[i]}
done

for ((i=0; i < ${#subnet[@]}; i++))
do

   mask=$(echo ${subnet[i]} | awk -F '/' '{print $2}')
   ipaddr=$(echo ${subnet[i]} | awk -F '/' '{print $1}')
   oct1=$(echo $ipaddr | awk -F '.' '{print $1}')
   oct2=$(echo $ipaddr | awk -F '.' '{print $2}')
   oct3=$(echo $ipaddr | awk -F '.' '{print $3}')
   oct4=$(echo $ipaddr | awk -F '.' '{print $4}')

   case $mask in
      3[0-1]|2[4-9])
         calc_boundry 32 $mask $oct4
         ipaddr=$(echo $ipaddr | cut -d '.' -f1-3)
         ipaddr_start=${ipaddr}.${boundry}
         oct4=$(($boundry + $wildcard))
         ipaddr_end=${ipaddr}.${oct4}
         upd_clonenum_start
         add_ifcfg-range
         ;;
      2[0-3]|1[6-9])
         calc_boundry 24 $mask $oct3
         ipaddr=$(echo $ipaddr | cut -d '.' -f1-2)
	 while [ $wildcard -ge 0 ]
         do
            ipaddr_start=${ipaddr}.${boundry}.0
            ipaddr_end=$(echo $ipaddr_start | cut -d '.' -f1-2)
            ipaddr_end=${ipaddr_end}.${boundry}.255
            upd_clonenum_start
            add_ifcfg-range
            let boundry++
            let wildcard--
         done
         ;;
   esac

done

/etc/init.d/network restart
echo
