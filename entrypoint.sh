#!/bin/bash
set -eu
log=/var/log/vpn.log
cleanup() { set +x;echo "Stop /etc/hosts refresh !" >&2;rm -f /refresh_host; }
vv() { echo "$@">&2;"$@";}
trap cleanup 2 3 6 9 14 15 0
HOST=${HOST:?Error \$HOST is not defined}
PORT=${PORT:?Error \$PORT is not defined}
USERNAME=${USERNAME:?Error \$PORT is not defined}
PASSWORD=${PASSWORD:?Error \$PORT is not defined}
USE_SSH_TUNNEL=${USE_SSH_TUNNEL-}
if [ ! -e /etc/openfortivpn/config ];then
    if [ ! -e /etc/openfortivpn/ ];then
        mkdir /etc/openfortivpn/
    fi
    cat > /etc/openfortivpn/config << EOF
host = $HOST
port = $PORT
username = $USERNAME
password = $PASSWORD
EOF
fi

add_ssh_host() {
    echo "Refreshing /etc/hosts" >&2
    f=$(mktemp)
    sed -i -re "s/port =.*/port = $PORT/g" /etc/openfortivpn/config
    cat /etc/hosts | sed -re "/^ $HOST/d" >$f
    cat $f>/etc/hosts
    rm -f $f
    echo "$gw $HOST">>/etc/hosts
}

if [[ -n $USE_SSH_TUNNEL ]];then
    gw=$(ip r show default|awk '/via/{print $3}')
    echo "Using ssh tunnel ssh://$HOST($gw):$PORT" >&2
    touch /refresh_host
    ( while [ -e /refresh_host ];do add_ssh_host && sleep 30;done ) &
fi

echo  "Using config"
( cat /etc/openfortivpn/config | sed -re "s/password.*/password = ***/g" ) >&2
pkill -9 -f glider || /bin/true
/usr/bin/glider -listen :8443 &
echo "http/socks5 proxy server: $(hostname -i):8443" >&2
if [[ -n $INSECURE_SSL ]] && [[ "$1" == "openfortivpn" ]];then
    set -- "$@" --insecure-ssl
fi
vv $@ 2>&1 | tee $log
ret=$?
if [[ "$ret" = "0" ]] && ( egrep -q "ERROR:  Gateway certificate validation failed, and the certificate digest in not in the local whitelist" $log );then
    digest=$(egrep -- --trusted-cert $log|sed -re "s/.*--trusted-cert/--trusted-cert/g"|awk '!seen[$1]++')
    echo "Retry with cert digest $digest" >&2
    set -- "$@" $digest
    vv $@ 2>&1 | tee -a $log
    ret=$?
fi
echo "ret: $ret"
exit $ret
