# docker-tunnel

This is a Docker-based, self hosted alternative to [Ngrok](https://ngrok.com/). It exposes a web app running locally on a development machine to the Internet, using a secure SSH reverse tunnel to a server already exposed to the Internet. This was inspired by [this blog post](https://jerrington.me/posts/2019-01-29-self-hosted-ngrok.html).

### Example use cases

- testing from the Internet an application running locally - without having to deploy the application to some server; this allows for a faster feedback e.g. with clients during development;
- allowing [Let's Encrypt](https://letsencrypt.org/)'s HTTP domain verification to work with apps otherwise not exposed to the Internet directly. For example, I needed this to test locally a SaaS running on Kubernetes that lets users add custom domains out of my control, for which I cannot use the DNS verification method.

## Usage

To set up the tunnel for an application, two containers are required. The first container will be accepting the HTTP requests from clients and needs to run on a server that is exposed to the Internet and has Docker installed. To start this container, simply run:

```
docker run --name tunnel-proxy --env FORWARD_PORTS="80,443" --env TUNNEL_PORT=3000 -itd --net=host vitobotta/docker-tunnel:0.27.0 proxy
```

- `FORWARD_PORTS` is optional and can be set to a list of ports to forward to the app separated by comma. If not specified, only requests to ports 80 and 443 will be forwarded to the app;
- `TUNNEL_PORT` is the port that Nginx will be proxying requests to on the proxy server and which is the port the SSH connection - initiated by the app side - will be listening on. This port can be anything other than any of the ports specified in `FORWARD_PORTS` since Nginx will be listening on those ports for requests to forward.

Note that Nginx will use TCP load balacing in order to enable TLS passthrough, meaning that TLS termination will happen on the app's side on your local machine.


Then, on your local dev machine - where the app that you want to expose is running - run:

```
docker run --name tunnel-app --env TUNNEL_PORT=3000 --env APP_PORT=3000 --env PROXY_HOST=1.2.3.4 --env PROXY_SSH_PORT=22 --env PROXY_SSH_USER=${USER} -v ${HOME}/.ssh/id_rsa:/ssh.key -itd vitobotta/docker-tunnel:0.27.0 app
```

`APP_PORT` is the port on which the app is listening to on the dev machine while `TUNNEL_PORT` should match the port used on the proxy.

Of course, by "proxy host" we mean the host where the proxy container is running. The other environment variables for the SSH connection should be self-explanatory. Note that it is assumed that the SSH connection will use key authentication, so you need to mount the SSH key you want to use as shown in the command above.

## A side note..

I'd recommend you use something like [Cloudflare](https://www.cloudflare.com/) to have some basic protection when exposing an app with this method.
