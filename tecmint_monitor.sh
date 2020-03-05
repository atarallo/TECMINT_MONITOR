#!/usr/bin/env bash

####################################################################################################
#                                        Tecmint_monitor.sh                                        #
# Written for Tecmint.com for the post www.tecmint.com/linux-server-health-monitoring-script/      #
# If any bug, report us in the link below                                                          #
# Free to use/edit/distribute the code below by                                                    #
# giving proper credit to Tecmint.com and Author                                                   #
#                                                                                                  #
####################################################################################################

# Declare and assign separately to avoid masking return values (sh-shellcheck)
# shellcheck disable=SC2155

SCRIPT_NAME="${BASH_SOURCE##*/}"
help() {
    printf "Usage:\n"
    printf " %s [-u] [-v] [-h] [-c]\n\n" "$SCRIPT_NAME"
    printf "  -c  use 'curl' to get external IP(only if unavailable 'dig')\n"
    printf "  -u  show users\n"
    printf "  -v  show version\n"
}

show_version() {
    local version='0.2'
    printf "tecmint_monitor %s\n" "$version"
    printf "Designed by Tecmint.com\n"
    printf "Released Under Apache 2.0 License\n"
}

while getopts "vuhc?" name; do
    case "$name" in
        v) show_version
           exit 0;;
        u) show_user=1;;
        h) help
           exit 0;;
        c) use_curl=1;;
        *) printf "Error! Invalid argument.\n"
           help
           exit 0;;
    esac
done

msg() {
    local green="\E[32m"
    local colorreset="\E[0m"

    printf "%b$1 : %b $2\n" "$green" "$colorreset"
}

monitor() {

    msg "OS" "$(uname -o)"

    local nkernel=$(uname -s)
    local krelease=$(uname -r)
    local mach=$(uname -m)
    local distr=''
    local pseudoname=''
    local os_info=''

    if [ "$nkernel" = "SunOS" ]; then
        nkernel=Solaris
        local arch=$(uname -p)
        os_info="$nkernel $krelease($arch $(uname -v)"
    elif [ "$nkernel" = "AIX" ]; then
        os_info="$nkernel $(oslevel) ($(oslevel -r))"
    elif [ "$nkernel" = "Linux" ]; then
        nkernel=$(uname -r)
        if [ -f /etc/fedora-release ]; then
            distr='Fedora'
            pseudoname=$(cat /etc/fedora-release | sed s/.*\(// | sed s/\)//)
            krelease=$(cat /etc/fedora-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/redhat-release ]; then
            distr='RedHat'
            pseudoname=$(cat /etc/redhat-release | sed s/.*\(// | sed s/\)//)
            krelease=$(cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/SuSE-release ]; then
            distr=$(cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//)
            krelease=$(cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //)
        elif [ -f /etc/mandrake-release ]; then
            distr='Mandrake'
            pseudoname=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
            krelease=$(cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//)
        elif [ -f /etc/debian_version ]; then
            distr='Debian'
            distr="Debian $(cat /etc/debian_version)"
            krelease=""
        elif [ -f /etc/os-release ]; then
            distr=$(awk -F "PRETTY_NAME=" '{print $2}' /etc/os-release | tr -d '\n"')
        fi
        if [ -f /etc/UnitedLinux-release ]; then
            distr="${distr}[$(cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//)]"
        fi

        os_info="$nkernel $distr $krelease($pseudoname $nkernel $mach)"
    fi

    msg "OS Description" "$os_info"

    # Check Architecture
    local architecture=$(uname -m)
    msg "Architecture" "$architecture"

    # Check Kernel Release
    local kernelrelease=$(uname -r)
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
    local internalip=$(hostname -I)
    msg "Internal IP" "$internalip"

    # Check External IP
    if hash dig 2>/dev/null; then
        local externalip=$(dig +short myip.opendns.com @resolver1.opendns.com)
        msg "External IP" "$externalip"
    else
        if ! hash curl 2>/dev/null; then
            msg "External IP" "'curl' not available or not installed, fix prior running"
        else
            if [ -z "$use_curl" ]; then
                msg "External IP" " - (see note)"
                printf "Note: should install 'dig' (domain information groper) to get External IP\n"
                printf "      or use key '-c' for use UNSAFE command: 'curl'\n"
            else
                local externalip="$(curl -s ipecho.net/plain) (NOTE: should install 'dig' for get External IP)"
                msg "External IP" "$externalip"
            fi
        fi
    fi

    # Check DNS
    local nameservers=$(grep -v '#' /etc/resolv.conf | awk '{print $2}' | tr "\n" ' ')
    msg "Name Servers" "$nameservers"

    # Check Logged In Users
    if [ -n "$show_user" ]; then
        who>/tmp/who
        msg "Logged In users" "\n$(cat /tmp/who)"
        rm /tmp/who
    fi

    # Check RAM and SWAP Usages
    local tecm_ramcache=/tmp/ramcache
    free -h | grep -v + > "$tecm_ramcache"
    msg "Ram Usages"
    grep -v "Swap" "$tecm_ramcache"
    msg "Swap Usages"
	grep -v "Mem"  "$tecm_ramcache"
    rm "$tecm_ramcache"

    # Check Disk Usages
    local tecm_diskusage=/tmp/diskusage
    local hddisk=$(lsblk | grep disk | awk '{print $1}')
    df -h| grep "Filesystem\|/dev/${hddisk}*" > "$tecm_diskusage"
    msg "Disk Usages"
    cat "$tecm_diskusage"
    rm "$tecm_diskusage"

    # Check Load Average
    local loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $(NF-2)" "$(NF-1)" "$NF}' | sed 's/, / /g')
    msg "Load Average" "$loadaverage"

    # Check System Uptime
    local tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
    msg "System Uptime Days/(HH:MM)" "$tecuptime"
}

monitor
