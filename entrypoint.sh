#!/usr/bin/env bash

[[ -f /var/lib/asterisk/.setup ]] || {
    echo Copying initial data contents...
    cp -r /var/lib/.asterisk/* /var/lib/asterisk || exit 1
    touch /var/lib/asterisk/.setup || exit 1
    echo Done!
}
[[ -f /var/log/asterisk/.setup ]] || {
    echo Copying initial log contents...
    cp -r /var/log/.asterisk/* /var/log/asterisk || exit 1
    touch /var/log/asterisk/.setup || exit 1
    echo Done!
}

exec /usr/sbin/asterisk -f -C /etc/asterisk/asterisk.conf
