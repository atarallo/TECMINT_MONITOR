#!/usr/bin/env bash

####################################################################################################
#                                        Tecmint_monitor.sh                                        #
# Written for Tecmint.com for the post www.tecmint.com/linux-server-health-monitoring-script/      #
# If any bug, report us in the link below                                                          #
# Free to use/edit/distribute the code below by                                                    #
# giving proper credit to Tecmint.com and Author                                                   #
#                                                                                                  #
####################################################################################################


# clear the screen
clear

# unset any variable which system may be using
unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

SCRIPT_NAME="${BASH_SOURCE##*/}"
help() {
    echo "Usage:"
    echo " $SCRIPT_NAME [-u] [-v] [-h]"
    echo ""
    echo "  -u  show users"
    echo "  -v  show version"
}

show_version() {
    version=0.2
    echo "tecmint_monitor $version"
    echo "Designed by Tecmint.com"
    echo "Released Under Apache 2.0 License"
}

while getopts "vuh?" name; do
    case "$name" in
        v) show_version
           exit 0;;
        u) show_user=1;;
        h) help
           exit 0;;
        *) echo "Error! Invalid argument."
           help
           exit 0;;
    esac
done

monitor() {

    # Define Variable tecreset
    tecreset=$(tput sgr0)

    # Check OS Type
    os=$(uname -o)
    echo -e '\E[32m'"Operating System Type :" $tecreset $os

    # Check OS Release Version and Name
    ###################################
    OS=$(uname -s)
    REV=$(uname -r)
    MACH=$(uname -m)

    GetVersionFromFile()
    {
        VERSION=$(cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // )
    }

    if [ "${OS}" = "SunOS" ]; then
        OS=Solaris
        ARCH=$(uname -p)
        OSSTR="${OS} ${REV}(${ARCH} $(uname -v)"
    elif [ "${OS}" = "AIX" ]; then
        OSSTR="${OS} $(oslevel) ($(oslevel -r))"
    elif [ "${OS}" = "Linux" ]; then
        KERNEL=$(uname -r)
        if [ -f /etc/redhat-release ]; then
            DIST='RedHat'
            PSUEDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ]; then
            DIST=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ]; then
            DIST='Mandrake'
            PSUEDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/os-release ]; then
            DIST=$(awk -F "PRETTY_NAME=" '{print $2}' /etc/os-release | tr -d '\n"')
        elif [ -f /etc/debian_version ]; then
            DIST="Debian $(cat /etc/debian_version)"
            REV=""
        fi
        if ${OSSTR} [ -f /etc/UnitedLinux-release ]; then
            DIST="${DIST}[$(cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//)]"
        fi

        OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"
    fi

    ##################################
    #cat /etc/os-release | grep 'NAME\|VERSION' | grep -v 'VERSION_ID' | grep -v 'PRETTY_NAME' > /tmp/osrelease
    #echo -n -e '\E[32m'"OS Name :" $tecreset && cat /tmp/osrelease | grep -v "VERSION" | grep -v CPE_NAME | cut -f2 -d\"
    #echo -n -e '\E[32m'"OS Version :" $tecreset && cat /tmp/osrelease | grep -v "NAME" | grep -v CT_VERSION | cut -f2 -d\"
    echo -e '\E[32m'"OS Version :" $tecreset $OSSTR
    # Check Architecture
    architecture=$(uname -m)
    echo -e '\E[32m'"Architecture :" $tecreset $architecture

    # Check Kernel Release
    kernelrelease=$(uname -r)
    echo -e '\E[32m'"Kernel Release :" $tecreset $kernelrelease

    # Check hostname
    echo -e '\E[32m'"Hostname :" $tecreset $HOSTNAME

    # Check if connected to Internet or not
    ping -c 1 google.com &> /dev/null && echo -e '\E[32m'"Internet: $tecreset Connected" || echo -e '\E[32m'"Internet: $tecreset Disconnected"

    # Check Internal IP
    internalip=$(hostname -I)
    echo -e '\E[32m'"Internal IP :" $tecreset $internalip

    # Check External IP
    if hash dig 2>/dev/null; then
        externalip=$(dig +short myip.opendns.com @resolver1.opendns.com)
        echo -e '\E[32m'"External IP : $tecreset "$externalip
    else
        echo "External IP : command 'dig' was not found in PATH"
    fi

    # Check DNS
    nameservers=$(cat /etc/resolv.conf | sed '1 d' | awk '{print $2}')
    echo -e '\E[32m'"Name Servers :" $tecreset $nameservers

    if [ -n "$show_user" ]; then
        # Check Logged In Users
        who>/tmp/who
        echo -e '\E[32m'"Logged In users :" $tecreset && cat /tmp/who
        rm /tmp/who
    fi

    # Check RAM and SWAP Usages
    free -h | grep -v + > /tmp/ramcache
    echo -e '\E[32m'"Ram Usages :" $tecreset
    cat /tmp/ramcache | grep -v "Swap"
    echo -e '\E[32m'"Swap Usages :" $tecreset
    cat /tmp/ramcache | grep -v "Mem"

    # Check Disk Usages
    df 2>/dev/null -h| grep 'Filesystem\|/dev/sda*' > /tmp/diskusage
    echo -e '\E[32m'"Disk Usages :" $tecreset
    cat /tmp/diskusage

    # Check Load Average
    loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $(NF-2)" "$(NF-1)" "$NF}')
    echo -e '\E[32m'"Load Average :" $tecreset $loadaverage

    # Check System Uptime
    tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
    echo -e '\E[32m'"System Uptime Days/(HH:MM) :" $tecreset $tecuptime

    # Unset Variables
    unset tecreset os architecture kernelrelease internalip externalip nameserver loadaverage

    # Remove Temporary Files
    rm /tmp/ramcache /tmp/diskusage
}

monitor

shift $(($OPTIND -1))
