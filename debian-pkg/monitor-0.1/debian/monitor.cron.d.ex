#
# Regular cron jobs for the monitor package
#
0 4	* * *	root	[ -x /usr/bin/monitor_maintenance ] && /usr/bin/monitor_maintenance
