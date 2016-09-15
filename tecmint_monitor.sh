#!/bin/sh
###############################################################################################
#                                   Tecmint_monitor.sh                                        #
# Written for Tecmint.com for the post www.tecmint.com/linux-server-health-monitoring-script/ #
# If any bug, report us in the link below                                                     #
# Free to use/edit/distribute the code below by                                               #
# giving proper credit to Tecmint.com and Author                                              #
#                                                                                             #
###############################################################################################

# unset any variable which system may be using
unset os architecture kernelrelease internalip externalip nameserver loadaverage

#
# Check for CURL availiability, a dependency of this script
#
command -v curl > /dev/null || ( echo "CURL not availiable or not installed, fix prior running"; exit 1 )

#
# MacOs not yet supported. 
#
if [ "$(uname -s)" = "darwin" ]; then
  echo "Mac OS X is not supported at this time"
  exit 1
fi

#
# Parse Command Line arguments
#
while getopts iv name
do
        case $name in
          i)iopt=1;;
          v)vopt=1;;
          *)echo "Invalid arg";;
        esac
done

#
# Install
#
if [ ! -z "$iopt" ]; then 
	fail_msg="Installation failed"
	ok_msg="Congratulations! Script Installed, now run monitor Command"
	wd=$(pwd)
	basename "$(test -L "$0" && readlink "$0" || echo "$0")" > /tmp/scriptname
	scriptname=$(echo -e -n "$wd"/ && cat /tmp/scriptname)
	su -c "cp $scriptname /usr/bin/monitor" root && echo "${ok_message}" || echo "${fail_msg}"
	# cleanup after install
	rm -f /tmp/scriptname
fi


#
# Show version info
#
if [ ! -z "$vopt" ]; then
	printf "tecmint_monitor version 0.1.2\nDesigned by Tecmint.com\nReleased Under Apache 2.0 License\n"
fi

#
# Monitoring
#
if [ "$#" -eq 0 ]; then

	# Check if connected to Internet or not
	ping -c 1 google.com &> /dev/null && printf "\E[32mInternet: \E[0m Connected\n" || printf "\E[32mInternet: \E[0m Disconnected\n"

	#
	# Check OS Release Version and Name
	#
	OS=$(uname -s)   # Kernel Name, for display purpose we need OS Name
	REV=$(uname -r)
	MACH=$(uname -m)

	GetVersionFromFile()
	{
    		VERSION=$(cat "$1" | tr "\n" ' ' | sed s/.*VERSION.*=\ // )
	}
	# Check OS
	if [ "${OS}" = "SunOS" ] ; then
		OS=Solaris
		ARCH=$(uname -p)
		OSSTR="${OS} ${REV}(${ARCH} $(uname -v) )"
	elif [ "${OS}" = "AIX" ] ; then
		OSSTR="${OS} $(oslevel) ($(oslevel -r))"
	elif [ "${OS}" = "Linux" ] ; then
		KERNEL=$(uname -r)
		if [ -f /etc/redhat-release ] ; then
			DIST='RedHat'
			PSUEDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
			REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
		elif [ -f /etc/SuSE-release ] ; then
			DIST=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
			REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
		elif [ -f /etc/mandrake-release ] ; then
			DIST='Mandrake'
			PSUEDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
			REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
		elif [ -f /etc/debian_version ] ; then
			DIST="Debian $(cat /etc/debian_version)"
			REV=""
		elif [ -f /etc/UnitedLinux-release ] ; then
			DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
			REV=""
		fi
		OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"
	fi
	OS=$(uname -o)

	# Check OS Type
	printf "\E[32mOperating System Type : \E[0m ${OS}\n"
	printf "\E[32mOS Name : \E[0m $OSSTR\n"
	printf "\E[32mOS Version : \E[0m ${REV}\n"

	# Check Architecture
	architecture=$(uname -m)
	printf "\E[32mArchitecture : \E[0m $architecture\n"

	# Check Kernel Release
	kernelrelease=$(uname -r)
	printf "\E[32mKernel Release : \E[0m $kernelrelease\n"

	# Check hostname
	printf "\E[32mHostname : \E[0m $HOSTNAME\n"

	# Check Internal IP
	internalip=$(hostname -i)
	printf "\E[32mInternal IP : \E[0m $internalip\n"

	# Check External IP
	externalip=$(curl -s ipecho.net/plain;echo)
	printf "\E[32mExternal IP : \E[0m $externalip\n"

	# Check DNS
	nameservers=$(cat /etc/resolv.conf |grep -v '#'| sed '1 d' | awk '{print $2}')
	printf "\E[32mName Servers : \E[0m $nameservers\n"

	# Check Logged In Users
	who>/tmp/who
	printf "\E[32mLogged In users : \E[0m\n" && cat /tmp/who 

	# Check RAM and SWAP Usages
	free -m | grep -v + > /tmp/ramcache
	printf "\E[32mRam Usages :\E[0m\n"
	cat /tmp/ramcache | grep -v "Swap"
	printf "\E[32mSwap Usages : \E[0m\n"
	cat /tmp/ramcache | grep -v "Mem" 

	# Check Disk Usages
	df -h| grep 'Filesystem\|/dev/sda*' > /tmp/diskusage
	printf "\E[32mDisk Usages :\E[0m\n"
	cat /tmp/diskusage

	# Check Load Average, get data from /proc . This might not work outsude Linux.
	loadaverage=$(cat /proc/loadavg |  awk '{printf("%s %s %s",$1,$2,$3)}')
	printf "\E[32mLoad Average : \E[0m $loadaverage\n"

	# Check System Uptime
	tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
	printf "\E[32mSystem Uptime Days/(HH:MM) : \E[0m $tecuptime\n"

	# Unset Variables
	unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

	# Remove Temporary Files
	temp_files="/tmp/osrelease /tmp/who /tmp/ramcache /tmp/diskusage"
	for i in ${temp_files}; do 
		# check if file exists prior removing.
		if [ -f "${i}" ]; then
			rm "${i}"
		fi
	done

fi
shift $((OPTIND -1))
