#!/bin/sh

cat >/etc/init.d/ssh <<EOF
#! /bin/sh
set -e

# /etc/init.d/ssh: start and stop the OpenBSD "secure shell(tm)" daemon

test -x /usr/sbin/sshd || exit 0
( /usr/sbin/sshd -\? 2>&1 | grep -q OpenSSH ) 2>/dev/null || exit 0

if test -f /etc/default/ssh; then
    . /etc/default/ssh
fi

. /lib/lsb/init-functions

check_for_no_start() {
    # forget it if we're trying to start, and /etc/ssh/sshd_not_to_be_run exists
    if [ -e /etc/ssh/sshd_not_to_be_run ]; then 
        log_end_msg 0
        log_warning_msg "OpenBSD Secure Shell server not in use (/etc/ssh/sshd_not_to_be_run)"
        exit 0
    fi
}

check_privsep_dir() {
    # Create the PrivSep empty dir if necessary
    if [ ! -d /var/run/sshd ]; then
        mkdir /var/run/sshd
        chmod 0755 /var/run/sshd
    fi
}

check_config() {
    if [ ! -e /etc/ssh/sshd_not_to_be_run ]; then
        /usr/sbin/sshd -t || exit 1
    fi
}

export PATH="\${PATH:+\$PATH:}/usr/sbin:/sbin"

case "\$1" in
  start)
        log_begin_msg "Starting OpenBSD Secure Shell server..."
        check_for_no_start
        check_privsep_dir
        /usr/bin/nice -n -5 start-stop-daemon --start --quiet --pidfile /var/run/sshd.pid --exec /usr/sbin/sshd -- \$SSHD_OPTS || log_end_msg 1
        log_end_msg 0
        ;;
  stop)
        log_begin_msg "Stopping OpenBSD Secure Shell server..."
        start-stop-daemon --stop --quiet --oknodo --pidfile /var/run/sshd.pid || log_end_msg 1
        log_end_msg 0
        ;;

  reload|force-reload)
        log_begin_msg "Reloading OpenBSD Secure Shell server's configuration"
        check_for_no_start
        check_config
        /usr/bin/nice -n -5 start-stop-daemon --stop --signal 1 --quiet --oknodo --pidfile /var/run/sshd.pid --exec /usr/sbin/sshd || log_end_msg 1
        log_end_msg 0
        ;;

  restart)
        log_begin_msg "Restarting OpenBSD Secure Shell server..."
        check_privsep_dir
        check_config
        start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile /var/run/sshd.pid
        check_for_no_start
        /usr/bin/nice -n -5 start-stop-daemon --start --quiet --pidfile /var/run/sshd.pid --exec /usr/sbin/sshd -- \$SSHD_OPTS || log_end_msg 1
        log_end_msg 0
        ;;

  *)
        log_success_msg "Usage: /etc/init.d/ssh {start|stop|reload|force-reload|restart}"
        exit 1
esac

exit 0
EOF

exit 0
