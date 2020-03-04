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
unset os_type architecture kernelrelease internalip externalip nameserver loadaverage


SCRIPT_NAME="${BASH_SOURCE##*/}"
help() {
    printf "Usage:\n"
    printf " %s [-u] [-v] [-h]\n\n" "$SCRIPT_NAME"
    printf "  -u  show users\n"
    printf "  -v  show version\n"
}

show_version() {
    version=0.1
    printf "tecmint_monitor %s\n" "$version"
    printf "Designed by Tecmint.com\n"
    printf "Released Under Apache 2.0 License\n"
}

while getopts "vuh?" name; do
    case "$name" in
        v) show_version
           exit 0;;
        u) show_user=1;;
        h) help
           exit 0;;
        *) printf "Error! Invalid argument.\n"
           help
           exit 0;;
    esac
done

GREEN="\E[32m"
COLORRESET="\E[0m"

msg() {
    printf "%b$1 : %b $2\n" "$GREEN" "$COLORRESET"
}

monitor() {

    # Check OS Type
    os_type=$(uname -o)
    msg "Operating System Type" "${os_type}"

    # Check OS Release Version and Name
    OS=$(uname -s)
    REV=$(uname -r)
    MACH=$(uname -m)

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
            PSEUDONAME=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            REV=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ]; then
            DIST=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            REV=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ]; then
            DIST='Mandrake'
            PSEUDONAME=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
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

        OSSTR="${OS} ${DIST} ${REV}(${PSEUDONAME} ${KERNEL} ${MACH})"
    fi

    msg "OS Version" "$OSSTR"

    # Check Architecture
    architecture=$(uname -m)
    msg "Architecture" "$architecture"

    # Check Kernel Release
    kernelrelease=$(uname -r)
    msg "Kernel Release" "$kernelrelease"

    # Check hostname
    msg "Hostname" "$HOSTNAME"

    # Check if connected to Internet or not
    if ping -c 1 google.com &> /dev/null; then
        msg "Internet" "Connected"
    else
        msg "Internet" "Disconnected"
    fi

    # Check Internal IP
    internalip=$(hostname -I)
    msg "Internal IP" "$internalip"

    # Check External IP
    if hash dig 2>/dev/null; then
        externalip=$(dig +short myip.opendns.com @resolver1.opendns.com)
        msg "External IP" "$externalip"
    else
        msg "External IP" "NOTE: command 'dig' was not found in PATH"
    fi

    # Check DNS
    nameservers=$(grep -v '#' /etc/resolv.conf | awk '{print $2}' | tr "\n" ' ')
    msg "Name Servers" "$nameservers"

    if [ -n "$show_user" ]; then
        # Check Logged In Users
        who>/tmp/who
        msg "Logged In users" "\n$(cat /tmp/who)"
        rm /tmp/who
    fi

    # Check RAM and SWAP Usages
    free -h | grep -v + > /tmp/ramcache
    msg "Ram Usages"
    grep -v "Swap" /tmp/ramcache
    msg "Swap Usages"
	grep -v "Mem"  /tmp/ramcache

    # Check Disk Usages
    hddisk=$(lsblk | grep disk | awk '{print $1}')
    df -h| grep "Filesystem\|/dev/${hddisk}*" > /tmp/diskusage
    msg "Disk Usages"
    cat /tmp/diskusage

    # Check Load Average
    loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $(NF-2)" "$(NF-1)" "$NF}' | sed 's/, / /g')
    msg "Load Average" "$loadaverage"

    # Check System Uptime
    tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
    msg "System Uptime Days/(HH:MM)" "$tecuptime"

    # Unset Variables
    unset os architecture kernelrelease internalip externalip nameserver loadaverage

    # Remove Temporary Files
    rm /tmp/ramcache /tmp/diskusage
}

monitor

shift $((OPTIND -1))
