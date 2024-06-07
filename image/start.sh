#!/bin/ash
trap 'kill -TERM $PID' TERM INT

echo "This is Tailscale-SoCaddy-proxy version"
tailscale --version

if [ ! -z "$SKIP_CADDYFILE_GENERATION" ] ; then
   echo "Skipping Caddyfile generation as requested via environment"
else
   echo "Building Caddy configfile"

   echo $TS_HOSTNAME'.'$TS_TAILNET.'ts.net' > /etc/caddy/Caddyfile
   echo 'reverse_proxy' $CADDY_TARGET >> /etc/caddy/Caddyfile
fi

if [ ! -z "$RELAY_PORT" ] ; then
   echo "Starting socat. Relaying $CADDY_TARGET to port $RELAY_PORT of this container"

   socat tcp-listen:$RELAY_PORT,fork,reuseaddr tcp:$CADDY_TARGET < /dev/null &
fi

echo "Starting Caddy"
caddy start --config /etc/caddy/Caddyfile

echo "Starting Tailscale"

export TS_EXTRA_ARGS=--hostname="${TS_HOSTNAME} ${TS_EXTRA_ARGS}"
echo "Note: set TS_EXTRA_ARGS to " $TS_EXTRA_ARGS
/usr/local/bin/containerboot
