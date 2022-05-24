#!/bin/bash

close_connection() {
  pkill -3 autossh
  exit 0
}

trap close_connection TERM

case "$1" in
  "proxy" )
    TUNNELS=""

    for MAPPINGS in `echo ${PORTS} | awk -F, '{for (i=1;i<=NF;i++)print $i}'`; do
      IFS=':' read -r -a MAPPING <<< "$MAPPINGS"; unset IFS

      read -r -d '' TUNNELS <<-EOS
${TUNNELS}

server {
    listen ${MAPPING[0]};

    proxy_pass 127.0.0.1:${MAPPING[1]};
    proxy_responses 0;
}
EOS
    done

    export TUNNELS

    bash -c "envsubst < /nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"
    ;;

  "app" )
    DOCKER_HOST="$(getent hosts host.docker.internal | cut -d' ' -f1)"
    APP_IP="${APP_IP:-$DOCKER_HOST}"

    if [ -z "${APP_IP}" ]; then
      APP_IP=$(ip -4 route show default | cut -d' ' -f3)
    fi

    TUNNELS=" "

    for MAPPINGS in `echo ${PORTS} | awk -F, '{for (i=1;i<=NF;i++)print $i}'`; do
      IFS=':' read -r -a MAPPING <<< "$MAPPINGS"; unset IFS
      TUNNELS="${TUNNELS} -R ${MAPPING[1]}:${APP_IP}:${MAPPING[0]} "
    done

    autossh -M 0 -o "PubkeyAuthentication=yes" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=5" -o "ServerAliveCountMax 3" -i /ssh.key ${TUNNELS} ${PROXY_SSH_USER}@${PROXY_HOST} -p ${PROXY_SSH_PORT}

    while true; do
      sleep 1 &
      wait $!
    done

    exit 0
    ;;
esac
