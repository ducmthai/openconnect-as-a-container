# Proxy through VPN connection in a Docker container
An Alpine Linux container with 

- VPN connection to your corporate network via [`openconnect`](https://github.com/openconnect). `openconnect` can connect to AnyConnect, Pulse and PAN.
- Web proxy with Privoxy
- The container starts in [`privileged`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) mode in order to avoid the `read-only file system` [error](https://serverfault.com/questions/878443/when-running-vpnc-in-docker-get-cannot-open-proc-sys-net-ipv4-route-flush). Please proceed with your own **risk**.

## Starting the VPN Proxy

```Shell
docker build -t jasper/openconnect .
docker run -d \
--cap-add=NET_ADMIN \
--device=/dev/net/tun \
--name=vpn_proxy \
--dns=172.25.21.1 --dns=172.25.21.1 \
--privileged=true \
--restart=always \
-e "SERVER=<vpn-mfa.yourcompany.com" \
-e "USERNAME=<vpn_username>" \
-e "PASSWORD1=<vpn_password>" \
-e "PASSWORD2=<token>" \
-e "LOCAL_NETWORK=192.168.1.0/24" \
-e "PROXY_PORT=3129" \
-v /etc/localtime:/etc/localtime:ro \
-p 3129:3129 \
jasper/openconnect
```

Substitute the environment variables for `SERVER`, `USERNAME`, `PASSWORD1`, `PASSWORD2`, `LOCAL_NETWORK` and `PROXY_PORT` as indicated.

A `docker-compose.yml` file is also provided. Edit `.env` to the values on your setup for `USERNAME` and `PASSWORD1`, as well as your `LOCAL_NETWORK` cidr.

Then start the container:

```Shell
docker-compose up -d
```

### Environment Variables

`LOCAL_NETWORK` - The CIDR mask of the local IP addresses (e.g. 192.168.0.1/24, 10.1.1.0/24) which will be acessing the proxy. This is so the response to a request can be returned to the client (i.e. your browser).

## Connecting to the VPN Proxy

Set your proxy to 127.0.0.1:${PROXY_PORT}.

## Tested environments
- Raspberry Pi 4 B+ (4GB model)
- WSL 2 + Docker WSL2 technical preview (2.1.2.0) + Proxifier