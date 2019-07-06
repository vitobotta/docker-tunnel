FROM nginx:alpine

RUN apk add --no-cache bash autossh

ADD nginx.conf.template /
ADD start.sh /

RUN chmod +x /start.sh

ENV PORTS "80:3000,443:3001"
ENV PROXY_HOST "1.2.3.4"
ENV PROXY_SSH_PORT "22"
ENV PROXY_SSH_USER "user"
ENV APP_IP ""

ENTRYPOINT ["/start.sh"]
