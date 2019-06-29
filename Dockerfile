FROM nginx:alpine

RUN apk add --no-cache bash autossh

ADD nginx.conf.template /
ADD start.sh /

RUN chmod +x /start.sh

ENV TUNNEL_PORT "3000"
ENV FORWARD_PORTS "80,443"
ENV APP_PORT "3000"
ENV PROXY_HOST "1.2.3.4"
ENV PROXY_SSH_PORT "22"
ENV PROXY_SSH_USER "user"

ENTRYPOINT ["/start.sh"]
