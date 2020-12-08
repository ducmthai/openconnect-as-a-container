# Alpine version
ARG ALPINE_VERSION=3.12.1
# 3proxy version
ARG THREE_PROXY_REPO=https://github.com/z3APA3A/3proxy
ARG THREE_PROXY_BRANCH=0.9.3
ARG THREE_PROXY_URL=${THREE_PROXY_REPO}/archive/${THREE_PROXY_BRANCH}.tar.gz


# Build 3proxy
FROM alpine:${ALPINE_VERSION} as builder
ARG THREE_PROXY_REPO
ARG THREE_PROXY_BRANCH
ARG THREE_PROXY_URL
ADD ${THREE_PROXY_URL} /${THREE_PROXY_BRANCH}.tar.gz
RUN apk add --update alpine-sdk bash linux-headers && \
    cd / && \
    tar -xf ${THREE_PROXY_BRANCH}.tar.gz && \
    cd 3proxy-${THREE_PROXY_BRANCH} && \
    make -f Makefile.Linux



FROM alpine:${ALPINE_VERSION}
ARG THREE_PROXY_BRANCH

COPY --from=builder /3proxy-${THREE_PROXY_BRANCH}/bin /usr/local/bin

# Select S6 runtime architecture: aarch64|amd64 (more on https://github.com/just-containers/s6-overlay/releases/latest)
ARG s6_arch=amd64
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${s6_arch}.tar.gz /tmp/s6overlay.tar.gz

ADD rootfs /
RUN \
echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
apk upgrade --update --no-cache && \
apk --update --no-cache add \
  bash \
  openconnect@community && \
echo "Extracting s6 overlay..." && \
  tar xzf /tmp/s6overlay.tar.gz -C / && \
  chmod +x /opt/utils/healthcheck.sh && \
echo "Cleaning up temp directory..." && \
  rm -rf /tmp/s6overlay.tar.gz && \
rm -rf /var/cache/apk/*

# Init
ENTRYPOINT [ "/init" ]