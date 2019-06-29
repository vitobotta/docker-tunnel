#!/bin/bash

close_connection() {
  pkill -3 autossh
  exit 0
}

trap close_connection TERM

case "$1" in
  "proxy" )
    export LISTEN=`echo ${FORWARD_PORTS} | awk -F, '{for (i=1;i<=NF;i++)print "listen " $i ";"}'`

    bash -c "envsubst < /nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"
    ;;

  "app" )
    DOCKER_HOST="$(getent hosts host.docker.internal | cut -d' ' -f1)"

    if [ -z "${DOCKER_HOST}" ]; then
      DOCKER_HOST=$(ip -4 route show default | cut -d' ' -f3)
    fi

    autossh -M 10984 -o "PubkeyAuthentication=yes" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=5" -i /ssh.key -R ${TUNNEL_PORT}:${DOCKER_HOST}:${APP_PORT} ${PROXY_SSH_USER}@${PROXY_HOST} -p ${PROXY_SSH_PORT}

    while true; do
      sleep 1 &
      wait $!
    done

    exit 0
    ;;
esac
