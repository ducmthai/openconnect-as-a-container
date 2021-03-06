# AnyConnect, Pulse and PAN container with proxies
## Changelog

- v20201208: Replace `brook` + `ufw` combo with `3proxy`. Reduce image size significantly.
- v20201116: Enable IPv6to4 fallback.
- v20201109: Use `s6-overlay` instead of `runit`. This change allow setting an environment variable through a file via prefix `FILE__`.
- v20200115: Use `brook` for SOCKS5 instead of HTTP on `privoxy`.
- v20190924: Initial version.

![openconnect](vpncontainer.png)

An [s6-overlay](https://github.com/just-containers/s6-overlay)ed Alpine Linux container with:

- VPN connection to your corporate network via [`openconnect`](https://github.com/openconnect). `openconnect` can connect to AnyConnect, Pulse and PAN.
- Proxy server with [3proxy](https://github.com/z3APA3A/3proxy)
- The container starts in [`privileged`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) mode in order to avoid the `read-only file system` [error](https://serverfault.com/questions/878443/when-running-vpnc-in-docker-get-cannot-open-proc-sys-net-ipv4-route-flush). Please proceed with your own **risk**.

## Build
### Set architecture
The container uses pre-built `s6-overlay` binaries. By default, it uses `amd64` s6 binaries. If your platform is different, modify `s6_arch` argument value in `Dockerfile` as follow:

```Dockerfile
ARG s6_arch=<your_platform_arch>
```
See [s6-overlay release page](https://github.com/just-containers/s6-overlay/releases/latest) to see if your platform is available. The argument can be set using `--build-arg` as below.

### Build the image
Build the image with `docker` with BuiltKit enabled:

```Shell
DOCKER_BUILDKIT=1 docker build --build-arg s6_arch=amd64 -t ducmthai:nord .
```

Alternatively, use `docker-compose build`:
```Shell
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build --build-arg s6_arch=amd64
```

## Starting the VPN Proxy

### `vpn.config`

The main configuration file, contain the following values:

- `SERVER`: VPN endpoint
- `USERNAME`: Login username
- `PASSWORD1`: Login primary password
- `PASSWORD2`: OTP password or prompt response
- `PROXY_USER`: Proxy username (optional).
- `PROXY_PASS`: Proxy password.
- `KEEP_ALIVE_ENDPOINT`: An endpoint (can be internal or external) to keep the VPN connection alive

Will set the environment variable PASSWORD based on the contents of the /run/secrets/mysecretpassword file.
### Environment variables

The environment variables needed for exposing the proxy to the local network:

- `PROXY_PORT`: If set, the SOCKS5 proxy is enabled and exposed through this port
- `HTTP_PROXY_PORT`: If set, the HTTP proxy is enabled and exposed through this port
- `LOCAL_NETWORK`: The CIDR mask of the local IP addresses (e.g. 192.168.0.1/24, 10.1.1.0/24) which will be acessing the proxy. This is so the response to a request can be returned to the client (i.e. your browser).
- `EXT_IP`: Your external IP. Used only for healthcheck. You can get your current external IP on [ifconfig.co](https://ifconfig.co/ip)

These variables can be specified in the command line or in the `.env` file in the case of `docker-compose`.

### Set password via file

Passwords can be set using a `FILE__` prefixed environment variable where its value is path to the file contains the password:

```Shell
FILE__PASSWORD1=/vpn/passwd1
FILE__PASSWORD2=/vpn/passwd2
```
### Create a docker network
Before starting the container, please create a docker network for it:

```Shell
docker network create openconnect --subnet=10.30.0.1/16
```
### Start with `docker run`

```Shell
docker build -t ducmthai/openconnect .
docker run -d \
--cap-add=NET_ADMIN \
--device=/dev/net/tun \
--name=vpn_proxy \
--dns=1.1.1.1 --dns=1.0.0.1 \
--privileged=true \
--restart=always \
-e "PROXY_PORT=3128" \
-e "HTTP_PROXY_PORT=3129" \
-e "LOCAL_NETWORK=192.168.0.1/24" \
-e "FILE__PASSWORD1=/vpn/passwd1" \
-e "FILE__PASSWORD2=/vpn/passwd2" \
-e "EXT_IP=<get_yours_at_ifconfig.co/ip> \
-v /etc/localtime:/etc/localtime:ro \
-v "$(pwd)"/vpn.config:/vpn/vpn.config:ro \
-v "$(pwd)"/vpnpasswd1:/vpn/passwd1:ro \
-v "$(pwd)"/vpnpasswd2:/vpn/passwd2:ro \
-p 3128:3128 \
-p 3129:3129 \
ducmthai/openconnect
```

### Start with `docker-compose`

A `docker-compose.yml` file is also provided:

```Shell
docker-compose up -d
```

## Connecting to the VPN Proxy

Set your proxy to socks5://127.0.0.1:${PROXY_PORT}. Use Socks5 username and password if set.

## Tested environments
- Raspberry Pi 4 B+ (4GB model)
- WSL 2 + Docker WSL2 technical preview (2.1.2.0) + Proxifier