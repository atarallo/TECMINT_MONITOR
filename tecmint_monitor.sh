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
unset os architecture kernelrelease internalip externalip nameserver loadaverage green red colorReset batUsage

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
	scriptname=$(printf "%s" "$wd"/ && cat /tmp/scriptname)
	su -c "cp $scriptname /usr/bin/monitor" root && echo "${ok_msg}" || echo "${fail_msg}"
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
green="\E[32m"
red="\E[31m"
colorReset="\E[0m"
if [ "$#" -eq 0 ]; then

	# Check if connected to Internet or not
	ping -c 1 google.com >/dev/null 2>&1
	if [ "$?" -eq 0 ]; then
		printf "%b Internet: %b Connected\n" "$green" "$colorReset"
	else
		printf "%b Internet: %b Disconnected%b\n" "$green" "$red" "$colorReset"
	fi

	#
	# Check OS Release Version and Name
	#
	OS=$(uname -s)   # Kernel Name, for display purpose we need OS Name
	REV=$(uname -r)
	MACH=$(uname -m)

#	GetVersionFromFile()
#	{
#    		VERSION=$(cat "$1" | tr "\n" ' ' | sed s/.*VERSION.*=\ // )
#	}
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
			PSUEDONAME=$(sed s/.*\(// /etc/redhat-release | sed s/\)//)
			REV=$(sed s/.*release\ // /etc/redhat-release | sed s/\ .*//)
		elif [ -f /etc/SuSE-release ] ; then
			DIST=$(sed s/VERSION.*// /etc/SuSE-release | tr "\n" ' ' )
			#
			# Detect between OpenSuSE and SLES, 
			#
			echo "${DIST}"|grep SERVER > /dev/null
			if [ "${?}" = "1" ]; then 
				REV="Release "$(sed s/.*=\ // /etc/SuSE-release | tr "\n" ' ' )
			else
				REV=""
			fi
		elif [ -f /etc/mandrake-release ] ; then
			DIST='Mandrake'
			PSUEDONAME=$(sed s/.*\(// /etc/mandrake-release  | sed s/\)//)
			REV=$(sed s/.*release\ // /etc/mandrake-release | sed s/\ .*//)
		elif [ -f /etc/debian_version ] ; then
			DIST="Debian $(cat /etc/debian_version)"
			REV=""
		elif [ -f /etc/UnitedLinux-release ] ; then
			DIST="${DIST}[$(sed s/VERSION.*// /etc/UnitedLinux-release | tr "\n" ' ' )]"
			REV=""
		fi
		OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"
	fi
	OS=$(uname -o)


	# Check OS Type
	printf "%b Operating System Type : %b ${OS}\n" "$green" "$colorReset"
	printf "%b OS Name : %b $OSSTR\n" "$green" "$colorReset"
	printf "%b OS Version : %b ${REV}\n" "$green" "$colorReset"

	# Check Architecture
	architecture=$(uname -m)
	printf "%b Architecture : %b $architecture\n" "$green" "$colorReset"
	# Check Kernel Release
	kernelrelease=$(uname -r)
	printf "%b Kernel Release : %b $kernelrelease\n" "$green" "$colorReset"

	# Check hostname
	hostnamev=$(hostname -f)
	printf "%b Hostname : %b %s\n" "$green" "$colorReset" "$hostnamev"

	# Check Internal IP
	internalip=$(hostname -i)
	printf "%b Internal IP : %b %s\n" "$green" "$colorReset" "$internalip"

	# Check External IP
	externalip=$(curl -s ipecho.net/plain;echo)
	printf "%b External IP : %b %s\n" "$green" "$colorReset" "$externalip"

	# Check DNS
	nameservers=$(grep -v '#' /etc/resolv.conf  | sed '1 d' | awk '{print $2}'|tr "\n" ' ')
	printf "%b Name Servers : %b %s\n" "$green" "$colorReset" "$nameservers"

	# Check Logged In Users
	who>/tmp/who
	printf "%b Logged In users : %b\n" "$green" "$colorReset" && cat /tmp/who  

	# Check RAM and SWAP Usages
	free -m | grep -v + > /tmp/ramcache
	printf "%b Ram Usages :%b\n" "$green" "$colorReset"
	grep -v "Swap" /tmp/ramcache
	printf "%b Swap Usages : %b\n" "$green" "$colorReset"
	grep -v "Mem"  /tmp/ramcache

	# Check Disk Usages
	df -h| grep 'Filesystem\|/dev/sda*' > /tmp/diskusage
	printf "%b Disk Usages :%b\n" "$green" "$colorReset"
	cat /tmp/diskusage

	# Check Load Average, get data from /proc . This might not work outsude Linux.
	loadaverage=$(awk '{printf("%b %b %b",$1,$2,$3)}' /proc/loadavg )
	printf "%b Load Average : %b $loadaverage\n" "$green" "$colorReset"

	# Check System Uptime
	tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
	printf "%b System Uptime Days/(HH:MM) : %b $tecuptime\n" "$green" "$colorReset"

	# Check Battery Usage
	batUsage=$(upower -i $(upower -e | grep "battery") | grep -E 'state|to\ full|percentage')
	printf "%b Battery Usage :%b \n%b\n" "$green" "$colorReset" "$batUsage"

	# Unset Variables
	unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage green red colorReset batUsage

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
