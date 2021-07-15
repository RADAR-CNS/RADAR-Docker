#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin

# maximum file size in byte  to rotate log
minimumsize=10000000

# current time
timestamp=$(date '+%Y-%m-%d %H:%M:%S');

# Write message in the log file
log_info() {
  echo "$timestamp - $@" >> $logfile 2>&1
}

# Remove old lock
checkLock() {
  uptime=$(</proc/uptime)
  uptime=${uptime%%.*}

  if [ "$uptime" -lt "180" ]; then
     if [ -f $lockfile ]; then
       rm $lockfile
       log_info "Removed old lock"
     fi
  fi
}

# Rolling log file
rolloverLog() {
  actualsize=$(wc -c <"$logfile")
  if [ $actualsize -ge $minimumsize ]; then
    timestamp=$(date '+%d-%m-%Y_%H-%M-%S');
    cp $logfile $logfile"_"$timestamp
    > $logfile
  fi
}

# Check connection
isConnected() {
  case "$(curl -s --max-time 10 --retry 5 -I $url | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
    [23]) log_info "HTTP connectivity is up" && return 0;;
    5) log_info "The web proxy won't let us through" && return 1;;
    *) log_info "The network is down or very slow" && return 1;;
esac
}

# Force connection
connect() {
  log_info "Forcing reconnection"
  sudo nmcli conn down $network >> $logfile 2>&1
  log_info "Turning wifi NIC off"
  sleep 30
  sudo nmcli conn up $network >> $logfile 2>&1
  log_info "Turning wifi NIC on"
  log_info "Double checking ..."
  if ! isConnected; then
    log_info "Forcing reconnection with a sleep time of 30 sec ..."
    sudo nmcli conn down $network >> $logfile 2>&1
    log_info "Turning wifi NIC off"
    sleep 60
    sudo nmcli conn up $network >> $logfile 2>&1
    log_info "Turning wifi NIC on"
  fi
  log_info "Completed"
}

# Entry point
touch $logfile
log_info "### $timestamp ###"
log_info "Checking lock ..."
checkLock
