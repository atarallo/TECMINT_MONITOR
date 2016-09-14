#!/bin/bash
		  ####################################################################################################
                  #                                        Tecmint_monitor.sh                                        #
                  # Written for Tecmint.com for the post www.tecmint.com/linux-server-health-monitoring-script/      #
                  # If any bug, report us in the link below                                                          #
                  # Free to use/edit/distribute the code below by                                                    #
                  # giving proper credit to Tecmint.com and Author                                                   #
                  #                                                                                                  #
                  ####################################################################################################


# unset any variable which system may be using
unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

while getopts iv name
do
        case $name in
          i)iopt=1;;
          v)vopt=1;;
          *)echo "Invalid arg";;
        esac
done

if [[ ! -z $iopt ]]
then
{
	wd=$(pwd)
	basename "$(test -L "$0" && readlink "$0" || echo "$0")" > /tmp/scriptname
	scriptname=$(echo -e -n "$wd"/ && cat /tmp/scriptname)
	su -c "cp $scriptname /usr/bin/monitor" root && echo "Congratulations! Script Installed, now run monitor Command" || echo "Installation failed"
}
fi

if [[ ! -z $vopt ]]
then
{
	echo -e "tecmint_monitor version 0.1\nDesigned by Tecmint.com\nReleased Under Apache 2.0 License"
}
fi

if [[ $# -eq 0 ]]
then
{

echo -e '\E[1;33m'"OS Informations : "'\E[0m'

# Check OS Type
OSTYPE=$(uname -o)
echo -e '\t\E[32m'"Operating System Type :"'\E[0m' "$OSTYPE"

# Check OS Release Version and Name
OS=$(uname -s)
REV=$(uname -r)
MACH=$(uname -m)

#GetVersionFromFile()
#{
#    VERSION=$(tr "\n" ' ' "$1" | sed s/.*VERSION.*=\ // )
#}

if [ "${OS}" = "SunOS" ] ; then
    OS=Solaris
    ARCH=$(uname -p)
    OSSTR="${OS} ${REV}(${ARCH} $(uname -v))"
elif [ "${OS}" = "AIX" ] ; then
    OSSTR="${OS} $(oslevel) ($(oslevel -r))"
elif [ "${OS}" = "Linux" ] ; then
    KERNEL=$(uname -r)
    if [ -f /etc/redhat-release ] ; then
        DIST='RedHat'
        PSUEDONAME=$(sed s/.*\(// /etc/redhat-release | sed s/\)//)
        REV=$(sed s/.*release\ // /etc/redhat-release | sed s/\ .*//)
    elif [ -f /etc/SuSE-release ] ; then
        DIST=$(sed s/VERSION.*// /etc/SuSE-release | tr "\n" ' ')
        REV=$(sed s/.*=\ // /etc/SuSE-release | tr "\n" ' ')
    elif [ -f /etc/mandrake-release ] ; then
        DIST='Mandrake'
        PSUEDONAME=$(sed s/.*\(//  /etc/mandrake-release | sed s/\)//)
        REV=$(sed s/.*release\ // /etc/mandrake-release | sed s/\ .*//)
    elif [ -f /etc/os-release ]; then
	DIST=$(awk -F "PRETTY_NAME=" '{print $2}' /etc/os-release | tr -d '\n"')
    elif [ -f /etc/debian_version ] ; then
        DIST="Debian $(cat /etc/debian_version)"
        REV=""

    fi
    if ${OSSTR} [ -f /etc/UnitedLinux-release ] ; then
        DIST="${DIST}[ $(sed s/VERSION.*// /etc/UnitedLinux-release | tr "\n" ' '  ) ]"
    fi

    OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"

fi

echo -e '\t\E[32m'"OS Version :" '\E[0m' "$OSSTR"
# Check Architecture
architecture=$(uname -m)
echo -e '\t\E[32m'"Architecture :" '\E[0m' "$architecture"

# Check Kernel Release
kernel="$(uname --kernel-name) $(uname --kernel-release) $(uname --kernel-version)"
echo -e '\t\E[32m'"Kernel :" '\E[0m' "$kernel"


echo -e '\E[1;33m'"Network status : "'\E[0m'

# Check if connected to Internet or not
ping -c 1 google.com &> /dev/null && echo -e '\E[32m'"Internet:" '\E[0m' "Connected" || echo -e '\E[32m'"Internet:" '\E[0m' "Disconnected"

# Check hostname
echo -e '\E[32m'"Hostname :" '\E[0m' "$HOSTNAME"

# Check Internal IP
internalip=$(hostname -I)
echo -e '\E[32m'"Internal IP :" '\E[0m' "$internalip"

# Check External IP
externalip=$(curl -s ipecho.net/plain)
echo -e '\E[32m'"External IP :" '\E[0m' "$externalip"

# Check DNS
nameservers=$(sed '1 d' /etc/resolv.conf | awk '{print $2}')
echo -e '\E[32m'"Name Servers :" '\E[0m' "$nameservers"

# Check Logged In Users
who>/tmp/who
echo -e '\E[32m'"Logged In users :" '\E[0m' && cat /tmp/who 

# Check RAM and SWAP Usages
free -h | grep -v + > /tmp/ramcache
echo -e '\E[32m'"Ram Usages :" '\E[0m'
grep -v "Swap" /tmp/ramcache
echo -e '\E[32m'"Swap Usages :" '\E[0m'
grep -v "Mem" /tmp/ramcache

# Check Disk Usages
df -h| grep 'Filesystem\|/dev/sda*' > /tmp/diskusage
echo -e '\E[32m'"Disk Usages :" '\E[0m' 
cat /tmp/diskusage

# Check Load Average
loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $10 $11 $12}')
echo -e '\E[32m'"Load Average :" '\E[0m' "$loadaverage"

# Check System Uptime
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e '\E[32m'"System Uptime Days/(HH:MM) :" '\E[0m' "$tecuptime"

# Unset Variables
unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

# Remove Temporary Files
rm /tmp/who /tmp/ramcache /tmp/diskusage
}
fi
shift $((OPTIND -1))
