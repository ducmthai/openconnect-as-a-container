# AnyConnect, Pulse and PAN container with proxies
## Changelog

- v20230402: Update to `s6-overlay` version 3. **Use new build argument to specify its architecture (`S6_OVERLAY_ARCH`)**. Use latest [`vpnc-script`](https://gitlab.com/openconnect/vpnc-scripts)
- v20220603: Add a `build.sh` script. Set s6-overlay version to 2.2.0.3. Update to version 3 pending.
- v20210813: Fix mount vpnpassd typo in `docker-compose.yml`. Add a note regarding password editing with `vim.`
- v20210405: Set dynamic token through mounted file to `/vpn/token` for 2FA users. Rename `PASSWORD1` and `PASSWORD2` to `PASSWORD` and `TOKEN`, respectively. Add `dnsmasq`.
- v20201208: Replace `brook` + `ufw` combo with `3proxy`. Reduce image size significantly.
- v20201116: Enable IPv6to4 fallback.
- v20201109: Use `s6-overlay` instead of `runit`. This change allow setting an environment variable through a file via prefix `FILE__`.
- v20200115: Use `brook` for SOCKS5 instead of HTTP on `privoxy`.
- v20190924: Initial version.

![openconnect](vpncontainer.png)

An [s6-overlay](https://github.com/just-containers/s6-overlay)ed Alpine Linux container with:

- VPN connection to your corporate network via [`openconnect`](https://github.com/openconnect). `openconnect` can connect to AnyConnect, Pulse and PAN.
- Proxy server with [3proxy](https://github.com/z3APA3A/3proxy)
- [`dnsmasq`](https://thekelleys.org.uk/dnsmasq/doc.html) to resolve internal domains.
- The container starts in [`privileged`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) mode in order to avoid the `read-only file system` [error](https://serverfault.com/questions/878443/when-running-vpnc-in-docker-get-cannot-open-proc-sys-net-ipv4-route-flush). Please proceed with your own **risk**.

## Build
### Set architecture
The container uses pre-built `s6-overlay` binaries. By default, it uses `amd64` s6 binaries. If your platform is different, modify `S6_OVERLAY_ARCH` argument value in `Dockerfile` as follow:

```Dockerfile
ARG S6_OVERLAY_ARCH=<your_platform_arch>
```
See [s6-overlay release page](https://github.com/just-containers/s6-overlay/releases/latest) to see if your platform is available. The argument can be set using `--build-arg` as below.

### Build the image

Use `build.sh`:

```Shell
sh build.sh amd64
```

Or, build the image with `docker` with BuiltKit enabled:

```Shell
DOCKER_BUILDKIT=1 docker build --build-arg S6_OVERLAY_ARCH=amd64 -t ducmthai/openconnect:latest .
```

Alternatively, use `docker-compose build`:
```Shell
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build --build-arg S6_OVERLAY_ARCH=amd64
```

## Starting the VPN Proxy

### `vpn.config`

The main configuration file, contain the following values:

- `SERVER`: VPN endpoint
- `USERNAME`: Login username
- `PASSWORD`: Login primary password
- `DYNAMIC_TOKEN`: `true` if dynamic OTP is required, `false` otherwise.
- `PROXY_USER`: Proxy username (optional).
- `PROXY_PASS`: Proxy password.
- `KEEP_ALIVE_ENDPOINT`: An endpoint (can be internal or external) to keep the VPN connection alive

### Environment variables

The environment variables needed for exposing the proxy to the local network:

- `PROXY_PORT`: If set, the SOCKS5 proxy is enabled and exposed through this port
- `HTTP_PROXY_PORT`: If set, the HTTP proxy is enabled and exposed through this port
- `LOCAL_NETWORK`: The CIDR mask of the local IP addresses (e.g. 192.168.0.1/24, 10.1.1.0/24) which will be acessing the proxy. This is so the response to a request can be returned to the client (i.e. your browser).
- `EXT_IP`: Your external IP. Used only for healthcheck. You can get your current external IP on [ifconfig.co](https://ifconfig.co/ip)

These variables can be specified in the command line or in the `.env` file in the case of `docker-compose`.

### Set password in a file

Passwords can be set using a `FILE__` prefixed environment variable where its value is path to the file contains the password:

```Shell
FILE__PASSWORD=/vpn/passwd
```
**Note**: If you edit the file with `vim,` please ensure to do `:set nofixeol` in `vim` before saving it or else a newline will be added after the password.

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
-e "FILE__PASSWORD=/vpn/passwd" \
-e "EXT_IP=<get_yours_at_ifconfig.co/ip> \
-v /etc/localtime:/etc/localtime:ro \
-v "$(pwd)"/vpn.config:/vpn/vpn.config:ro \
-v "$(pwd)"/vpnpasswd:/vpn/passwd:ro \
-v "$(pwd)"/vpntoken:/vpn/token \
-p 3128:3128 \
-p 3129:3129 \
ducmthai/openconnect
```

### Start with `docker-compose`

A `docker-compose.yml` file is also provided:

```Shell
docker-compose up -d
```

### Supplying token
Token is taken from the file `/vpn/token` within the container. If `DYNAMIC_TOKEN` is `true` then the container clears the file after reading. To supply the dynamic OTP, simply do this outside the container:

```Shell
echo OTP_HERE > ./vpntoken
```

## Connecting to the VPN Proxy

Set your proxy to socks5://127.0.0.1:${PROXY_PORT}. Use Socks5 username and password if set.

## Tested environments
- Raspberry Pi 4 B+ (4GB model)
- WSL 2 + Docker WSL2 + Proxifier