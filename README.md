# docker-tunnel

This is a Docker-based, self hosted alternative to [Ngrok](https://ngrok.com/). It exposes a web app running locally on a development machine to the Internet, using a secure SSH reverse tunnel to a server which is already exposed to the Internet. It was inspired by [this blog post](https://jerrington.me/posts/2019-01-29-self-hosted-ngrok.html). [Here](https://vitobotta.com/2019/06/29/self-hosted-alternative-to-ngrok/)'s a blog post that explains how the code works.

### Example use cases

- testing from the Internet an application which is running locally - without having to deploy the application to some server; this can be useful for a faster feedback for example from clients during development;
- allowing [Let's Encrypt](https://letsencrypt.org/)'s HTTP challenge for domain verification to work with apps otherwise not exposed to the Internet directly. For example, I needed this to test a SaaS app running on a local Kubernetes cluster, that lets users add custom domains out of my control for which I cannot use the DNS verification method.


## Usage

It's easier with an example. Let's say you want your app to accept HTTP requests from the Internet on the usual ports 80 and 443, and the app is also listening to the ports 80 and 443 on your dev machine, so to be able to test the app with both HTTP and HTTPS requests like in production. In order to set up the tunnel and expose your app, two containers are required. Firstly, on a server exposed to the Internet and with Docker installed (the proxy server) run:

```bash
docker run --name tunnel-proxy --env PORTS="80:3000,443:3001" -itd --net=host vitobotta/docker-tunnel:0.30.0 proxy
```

Each value in the `PORTS` environment variable is a mapping between a port exposed to the Internet (let's call it port A) and a corresponding port (B) which will be used by the SSH tunnel - initiated by your dev machine - to forward requests made to the port A to the app on your dev machine. The second port should differ from any of the ports exposed to the Internet because Nginx will be listening on those ports.


Then, on your dev machine, run:

```bash
docker run --name tunnel-app --env PORTS="80:3000,443:3001" --env PROXY_HOST="1.2.3.4" --env PROXY_SSH_PORT="22" --env PROXY_SSH_USER="${USER}" -v "${HOME}/.ssh/id_rsa:/ssh.key" -itd vitobotta/docker-tunnel:0.30.0 app
```

Here each couple in `PORTS` is a mapping between a port the app is listening to on your dev machine (C), and the port that will be used on the proxy server by the SSH connection to forward the requests to the app, so this second port must match port B specified for the proxy server. So you basically have a tunnel C->B->A, for example from port 80 of your app, to port 80 exposed on the Internet via an SSH tunnel using the port 3000. Hopefully it makes sense :)

Note that it is assumed that the SSH connection will use key authentication, so you need to mount the SSH key you want to use as shown in the command above.


## A side note..

I'd recommend you use something like [Cloudflare](https://www.cloudflare.com/) to have some basic protection when exposing an app with this method.
