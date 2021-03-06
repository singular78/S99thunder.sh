#! /bin/sh
### BEGIN INIT INFO
# Provides:          thunder
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop embed thunder manager
#
# Chkconfig: 2345 99 9
# Description: Start/stop embed thunder manager
### END INIT INFO
#
# Author: singular78 <fhyb168@gmail.com>
# Acknowledgements: Pengxuan Men <pengxuan.men@gmail.com>
#

USER=yb
XWAREPATH=/volume2/homes/$USER/xware
RUN=$XWAREPATH/portal
LOG=$XWAREPATH/message.log

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Embed Thunder Manager"
NAME=thunder
DAEMON=$XWAREPATH/lib/ETMDaemon
DNAME=ETMDaemon
PIDFILE=/var/run/$NAME/$NAME.pid
SCRIPTNAME=/usr/syno/etc.defaults/rc.d/$NAME

# Exit if the package is not installed
[ -x "$RUN" ] || exit 5

# Read configuration variable file if it is present
#[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Define LSB log_* functions. Depend on lsb-base (>= 3.0-6)
# . /lib/lsb/init-functions

# Get pid
# is_daemon_alive() {
#         if [ -f "$1" ]; then
#                 local pid=`cat "$1"`

#                 kill -0 $pid
#                 if [ "0" = "$?" ]; then
#                         echo "$pid";
#                         return 1;
#                 else
#                         echo "0";
#                         return 0;
#                 fi
#         fi

#         echo "0";
#         return 0;
# }


# start the daemon/service

do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started

    # Check if running
    # if [ [ -e $PIDFILE ] -a "0" != `is_daemon_alive "$PIDFILE"` ] ; then
    #     return 1
    # fi

    local pid=$(ps | grep $DAEMON | grep -v grep | awk '{print $1}')
    if [ "$pid" != "" ] ; then
	    if [ -e $PIDFILE ] ; then
	        if [ "$pid" = $(cat $PIDFILE) ] ; then
	            return 1
	        fi
    	fi
    fi

    # Mount
    #umount -l /media/thunder 2>/dev/null
    #mount -B /share/Downloads /media/thunder

    # Run
    # su $USER -c "$RUN" > $LOG 2>/dev/null
    $RUN > $LOG 2>/dev/null

    # Check result
    local LAST=`cat $LOG | tail -n 1`
    [ "$LAST" = "finished." ] || return 2

    # Check if fail
    FAIL=`cat $LOG | tail -n 4 | grep fail`
    [ "$FAIL" != "" ] && return 2


    # Check ACTIVE CODE
    local MSG=""
    MSG=`cat $LOG | tail -n 4 | grep "ACTIVE CODE"`
    if [ "$MSG" != "" ] ; then
        cat $LOG | tail -n 5 | head -n 4 | while read l; do logger -p user.err -t `basename $0` $l; done
        return 2
    fi

    # Check if bound
    MSG=`cat $LOG | tail -n 4 | grep "BOUND TO USER"`
    if [ "$MSG" != "" ] ; then
        cat $LOG | tail -n 4 | head -n 3 | while read l; do logger -p user.err -t `basename $0` $l; done
        [ -e /var/run/$NAME ] || mkdir /var/run/$NAME
        ps | grep $DAEMON | grep -v grep | awk '{print $1}' > $PIDFILE
        return 0
    fi

    return 2
}

# stop the daemon/service

do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred

    # killproc -p $PIDFILE $DAEMON

    # local RET=0

    # if [ -e $PIDFILE ] ; then
    # 	ps | grep $DAEMON | grep -v grep | awk '{print $1}' |grep -q $(cat $PIDFILE)
    #     if "$?" > /dev/null 2>&1 ; then
    #         RET=1
    #     else
    #         RET=2
    #     fi
    # else
    #     RET=0
    # fi
    local pid=$(ps | grep $DAEMON | grep -v grep | awk '{print $1}') # pid in the first column
    if [ "$pid" != "" ] ; then
	    if [ -e $PIDFILE ] ; then
	        if [ "$pid" = $(cat $PIDFILE) ] ; then
	            RET=2
	        else
	            RET=1
	        fi
	    else
	    	RET=1
    	fi
    else
    	RET=0
    fi

    # RET is:
    # 0 if Deamon (whichever) is not running
    # 1 if Deamon (whichever) is running
    # 2 if Deamon from the PIDFILE is running

    if [ $RET = 0 ] ; then
        return 1
    elif [ $RET = 2 -o $RET = 1 ] ; then
	    #su $USER -c "$RUN -s" > $LOG 2>/dev/null
	    $RUN -s > $LOG 2>/dev/null
	    local COUNT=`cat $LOG | grep -c stopped`
	    if [ $COUNT -gt 0 ] ; then
	        # remove pidfile if daemon could not delete on exit.
	        rm -f $PIDFILE
	        return 0
	    else
	        FAIL=`cat $LOG | tail -n 1`
	        logger -p user.err -t `basename $0` "$FAIL"
	        return 2
	    fi
    # elif [ $RET = 1 ] ; then
    #    FAIL="There are processes named '$DNAME' running which do not match your pid file which are left untouched in the name of safety, Please review the situation by hand."
    #    echo "$FAIL"
    #    logger -p user.err -t `basename $0` "$FAIL"
    #    return 2
    fi

    return 2
}

case "$1" in
  start)
    echo "Starting $DESC $NAME"
    logger -p user.err -t `basename $0` "Starting $DESC $NAME"

    do_start

    case "$?" in
        0)	
			echo 'Start successfully!'
			logger -p user.err -t `basename $0` 'Start successfully!' ;;
        1) 
			echo 'Old process is still running!'
        	logger -p user.err -t `basename $0` 'Old process is still running' ;; # Old process is still running			
        *) 
			echo "$FAIL"
			logger -p user.err -t `basename $0` "$FAIL" ;;
    esac
    ;;
  stop)
    echo "Stopping $DESC $NAME"
    logger -p user.err -t `basename $0` "Stopping $DESC $NAME"

    do_stop

    case "$?" in
        0|1)	
			echo 'Stop successfully!'
			logger -p user.err -t `basename $0` 'Stop successfully!' 
			;;
        2) 
			echo 'Stop failed'
			logger -p user.err -t `basename $0` 'Stop failed'
			;;
    esac
    ;;
  restart|force-reload)
    echo "Restarting $DESC $NAME"
    logger -p user.err -t `basename $0` "Restarting $DESC $NAME"

    do_stop
    case "$?" in
		0)
        sleep 1
        do_start

        case "$?" in
            0) 
				echo 'Restart successfully!'
				logger -p user.err -t `basename $0` 'Restart successfully!' ;;
            *) 
				echo "$FAIL"
            	logger -p user.err -t `basename $0` "$FAIL";; # Failed to start
        esac
        ;;
      	*)
          # Failed to stop
          	echo 'Failed to start'
        	logger -p user.err -t `basename $0` 'Failed to start'
        ;;
    esac
    ;;
  status)
    LAN_IP=192.168.2.145
    PORT=9001
    STATUS=`wget -t 3 -T 3 -qO- http://${LAN_IP}:${PORT}/getsysinfo`
    if [[ "$?" == "0" ]]; then
	echo $STATUS
    else
	echo -e "\033[33m $DESC appearlly not running. \033[0m"
    fi
    ;;
  *)

    echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload|status}"
    exit 3
    ;;
esac

exit 0;
