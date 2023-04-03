# Alpine version
ARG ALPINE_VERSION=3.17.3
# 3proxy version
ARG THREE_PROXY_REPO=https://github.com/3proxy/3proxy
ARG THREE_PROXY_BRANCH=0.9.4
ARG THREE_PROXY_URL=${THREE_PROXY_REPO}/archive/${THREE_PROXY_BRANCH}.tar.gz

# Build 3proxy
FROM alpine:${ALPINE_VERSION} as builder
ARG THREE_PROXY_REPO
ARG THREE_PROXY_BRANCH
ARG THREE_PROXY_URL
ADD ${THREE_PROXY_URL} /${THREE_PROXY_BRANCH}.tar.gz

RUN apk add --update \
      alpine-sdk \
      bash \
      linux-headers \
      xz \
    && cd / \
    && tar -xf ${THREE_PROXY_BRANCH}.tar.gz \
    && cd 3proxy-${THREE_PROXY_BRANCH} \
    && make -f Makefile.Linux \
    && mkdir /root-out


# set version for s6 overlay
ARG S6_OVERLAY_VERSION="3.1.4.1"
ARG S6_OVERLAY_ARCH="amd64"

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# Update latest vpnc-script
ADD https://gitlab.com/openconnect/vpnc-scripts/raw/master/vpnc-script /root-out/etc/vpnc/vpnc-script

ADD rootfs /root-out
RUN chmod +x /root-out/etc/vpnc/vpnc-script \
    && chmod +x /root-out/opt/utils/healthcheck.sh \
    && chmod +x /root-out/etc/services.d/*/run \
    && chmod +x /root-out/etc/vpnc/vpnc-script \
    && chmod +x /root-out/etc/cont-init.d/01-contcfg \
    && chmod +x /root-out/etc/cont-init.d/30-occfg

# add s6 optional symlinks
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

FROM alpine:${ALPINE_VERSION}
ARG THREE_PROXY_BRANCH

RUN apk upgrade --update --no-cache \
    && apk --update --no-cache add \
        bash \
        tzdata \
        openconnect \
        dnsmasq \
    && rm -rf /var/cache/apk/*

COPY --from=builder /3proxy-${THREE_PROXY_BRANCH}/bin /usr/local/bin
COPY --from=builder /root-out /

# Init
ENTRYPOINT [ "/init" ]
