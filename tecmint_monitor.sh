                  ####################################################################################################
                  #                                        Tecmint_monitor.sh                                        #
                  # Written for Tecmint.com for the post www.tecmint.com/linux-server-health-monitoring-script/      #
                  # If any bug, report us in the link below                                                          #
                  # Free to use/edit/distribute the code below by                                                    #
                  # giving proper credit to Tecmint.com and Author                                                   #
                  #                                                                                                  #
                  ####################################################################################################
#! /bin/bash

set -euo pipefail

# unset any variable which system may be using

unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

opt=0

while getopts ijv name
do
        case $name in
          i)opt="i";;
          v)opt="v";;
          j)opt="j";;
          *)echo "Invalid arg";;
        esac
done

if [[ $opt == "i" ]]
then
{
wd=$(pwd)
basename "$(test -L "$0" && readlink "$0" || echo "$0")" > /tmp/scriptname
scriptname=$(echo -e -n $wd/ && cat /tmp/scriptname)
su -c "cp $scriptname /usr/bin/monitor" root && echo "Congratulations! Script Installed, now run monitor Command" || echo "Installation failed"
exit
}
fi

if [[ $opt == "v" ]]
then
{
echo -e "tecmint_monitor version 0.3\nDesigned by Tecmint.com\nReleased Under Apache 2.0 License"
exit
}
fi

#functions
GetVersionFromFile()
{
    VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
}
remove_files()
{
    # Remove Temporary Files
    rm /tmp/who /tmp/ramcache /tmp/diskusage
}

#define output constants and tmp files
internet=$(ping -c 1 google.com &> /dev/null && echo "Connected" || echo "Disconnected")
os=$(uname -o 2>/dev/null || uname -s)
architecture=$(uname -m)
kernelrelease=$(uname -r)
hostname=$HOSTNAME
internalip=$(hostname -I 2>/dev/null || (echo $(ip a| grep inet| grep -v "host lo" | tr / " " | awk '{print $2}')))
dig >/dev/null 2>&1 || USEDIG=0
if [[ $USEDIG == "1" ]]; then
    externalip=$(dig +short myip.opendns.com @resolver1.opendns.com)
else
    externalip=$(curl -s ipecho.net/plain;echo)
fi
nameservers=$(cat /etc/resolv.conf | grep -v ^\# | awk '{print $2}')
loadaverage=$((top -n 1 -b 2>/dev/null || (echo q | top)) | grep -i "load average:" | awk -F'average:' '{print $2}'| awk '{print $1" "$2" "$3}')
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`
if [ "${OS}" = "SunOS" ] ; then
    OS=Solaris
    ARCH=`uname -p`
    OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
elif [ "${OS}" = "AIX" ] ; then
    OSSTR="${OS} `oslevel` (`oslevel -r`)"
elif [ "${OS}" = "Linux" ] ; then
    KERNEL=`uname -r`
    PSUEDONAME=""
    REV=""
    if [ -f /etc/redhat-release ] ; then
        DIST='RedHat'
        PSUEDONAME="`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//` "
        REV="`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//` "
    elif [ -f /etc/SuSE-release ] ; then
        DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
    elif [ -f /etc/mandrake-release ] ; then
        DIST='Mandrake'
        PSUEDONAME="`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//` "
        REV="`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//` "
    elif [ -f /etc/os-release ]; then
        DIST=`awk -F "PRETTY_NAME=" '{print $2}' /etc/os-release | tr -d '\n"'`
    elif [ -f /etc/debian_version ] ; then
        DIST="Debian `cat /etc/debian_version`"
    fi
    if [ -f /etc/UnitedLinux-release ] ; then
        DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
    fi
    OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME}${KERNEL} ${MACH})"
fi
SKIPWHO=0 && who 2>/dev/null > /tmp/who || SKIPWHO=1
(free -h 2>/dev/null || free )| grep -v + | grep -v Total: > /tmp/ramcache
df -h| grep '^Filesystem\|^/dev/sd\|^/dev/mapper/\|^/dev/root\|^/dev/mm\|^overlay' > /tmp/diskusage

if [[ $opt == "j" ]]
then
{
echo -n "{"
echo -n "\"internet\":$(echo $internet | jq -R '.'),"
echo -n "\"os_type\":$(echo $os | jq -R '.'),"
echo -n "\"os_version\":$(echo $OSSTR | jq -R '.'),"
echo -n "\"architecture\":$(echo $architecture | jq -R '.'),"
echo -n "\"kernel_release\":$(echo $kernelrelease | jq -R '.'),"
echo -n "\"hostname\":$(echo $hostname | jq -R '.'),"
echo -n "\"ip_internal\":$(echo $internalip | jq -R -c 'split(" ")'),"
echo -n "\"ip_external\":$(echo $externalip | jq -R -c 'split(" ")'),"
echo -n "\"name_servers\":$(echo $nameservers | jq -R -c 'split(" ")'),"
if [[ $SKIPWHO != "1" ]];then
    echo -n "\"logged_in_users\":$(cat /tmp/who | tr "()" "  " | sed 's/  \+/  /g' | sed 's/ $//g' | jq -R -c 'split("  ")' | jq  -s -c '.'),"
fi
echo -n "\"memory\":$(cat /tmp/ramcache | grep "Mem" | awk '{$1="";print $0}' | xargs | jq -R -c 'split(" ")'),"
echo -n "\"swap\":$(cat /tmp/ramcache | grep "Swap" | awk '{$1="";print $0}' | xargs | jq -R -c 'split(" ")'),"
echo -n "\"disk\":$(tail -n +2 /tmp/diskusage | sed 's/ \+/ /g' | jq -R -c 'split(" ")' | jq  -s -c '.'),"
echo -n "\"load\":$(echo $loadaverage | jq -R -c 'split(", ")'),"
echo -n "\"uptime\":$(echo $tecuptime | jq -R '.')"
echo -n "}"
echo
remove_files
exit
}
fi

if [[ $# -eq 0 ]]
then
{


# Define Variable tecreset
tecreset=$(tput sgr0 2>/dev/null || echo -e '\E[0m')

# Check if connected to Internet or not
echo -e '\E[32m'"Internet :" $tecreset $internet

# Check OS Type
echo -e '\E[32m'"Operating System Type :" $tecreset $os

#cat /etc/os-release | grep 'NAME\|VERSION' | grep -v 'VERSION_ID' | grep -v 'PRETTY_NAME' > /tmp/osrelease
#echo -n -e '\E[32m'"OS Name :" $tecreset  && cat /tmp/osrelease | grep -v "VERSION" | grep -v CPE_NAME | cut -f2 -d\"
#echo -n -e '\E[32m'"OS Version :" $tecreset && cat /tmp/osrelease | grep -v "NAME" | grep -v CT_VERSION | cut -f2 -d\"
echo -e '\E[32m'"OS Version :" $tecreset $OSSTR
# Check Architecture
echo -e '\E[32m'"Architecture :" $tecreset $architecture

# Check Kernel Release
echo -e '\E[32m'"Kernel Release :" $tecreset $kernelrelease

# Check hostname
echo -e '\E[32m'"Hostname :" $tecreset $hostname

# Check Internal IP
echo -e '\E[32m'"Internal IP :" $tecreset $internalip

# Check External IP
echo -e '\E[32m'"External IP : $tecreset "$externalip

# Check DNS
echo -e '\E[32m'"Name Servers :" $tecreset $nameservers

if [[ $SKIPWHO != "1" ]];then
    # Check Logged In Users
    echo -e '\E[32m'"Logged In users :" $tecreset && cat /tmp/who
fi

# Check RAM and SWAP Usages
echo -e '\E[32m'"Ram Usages :" $tecreset
cat /tmp/ramcache | grep -v "Swap"
echo -e '\E[32m'"Swap Usages :" $tecreset
cat /tmp/ramcache | grep -v "Mem" | awk -F'shared' '{print $1}'

# Check Disk Usages
df -h| grep 'Filesystem\|/dev/.*da*' > /tmp/diskusage
echo -e '\E[32m'"Disk Usages :" $tecreset 
cat /tmp/diskusage

# Check Load Average
echo -e '\E[32m'"Load Average :" $tecreset $loadaverage

# Check System Uptime
echo -e '\E[32m'"System Uptime Days/(HH:MM) :" $tecreset $tecuptime

# Unset Variables
unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage
remove_files
}
fi
shift $(($OPTIND -1))
