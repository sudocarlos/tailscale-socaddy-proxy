# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
ARG TAILSCALE_VERSION=v1.86.2
ARG TAILRELAY_VERSION=v0.1

FROM tailscale/tailscale:$TAILSCALE_VERSION

LABEL maintainer="carlos@sudocarlos.com"

ENV RELAY_LIST=
ENV TS_HOSTNAME=
ENV TS_EXTRA_FLAGS=
ENV TS_STATE_DIR=/var/lib/tailscale/ 
ENV TS_AUTH_ONCE=true

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache ca-certificates mailcap caddy socat && \
    caddy upgrade

COPY start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh && \
    mkdir --parents /var/run/tailscale && \
    ln -s /tmp/tailscaled.sock /var/run/tailscale/tailscaled.sock && \
    touch /etc/caddy/Caddyfile

CMD  [ "start.sh" ]
