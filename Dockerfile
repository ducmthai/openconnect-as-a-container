FROM golang:alpine as builder
RUN set -ex && apk add --update git \
	&& go get -u -v github.com/txthinking/brook/cli/brook

FROM alpine:edge

ARG server=vpn-mfa.sysmex.com
ARG username=
ARG password=
ARG localnet="192.168.0.1/24"
ARG proxy_port=3129

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories 

RUN apk --update --no-cache add openconnect@testing runit bash

COPY --from=builder /go/bin/brook /usr/bin
COPY vpn /vpn
COPY vpnc-script /etc/vpnc/vpnc-script
RUN find /vpn -name run | xargs chmod u+x


ENV SERVER=${server} \
    USERNAME=${username} \
    PASSWORD=${password} \
    LOCAL_NETWORK=${localnet} \
    PROXY_PORT=${proxy_port}

CMD ["runsvdir", "/vpn"]
