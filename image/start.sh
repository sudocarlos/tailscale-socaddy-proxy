#!/bin/ash
trap 'kill -TERM $PID' TERM INT

# Accept a single comma‑separated list of port:target pairs
# Example:
#   RELAY_LIST=8080:app1:80,9090:app2:80
# Each item in the list represents one socat relay.
RELAY_LIST=${RELAY_LIST:-}

echo "This is Tailscale-SoCaddy-proxy version"
tailscale --version

if [ ! -z "$SKIP_CADDYFILE_GENERATION" ] ; then
   echo "Skipping Caddyfile generation as requested via environment"
else
   echo "Building Caddy configfile"

   echo $TS_HOSTNAME'.'$TS_TAILNET.'ts.net' > /etc/caddy/Caddyfile
   echo 'reverse_proxy' $CADDY_TARGET >> /etc/caddy/Caddyfile
fi

# Spawn socat instances if RELAY_LIST is provided
if [ ! -z "$RELAY_LIST" ]; then
   # Split the pairs by comma (ash‑friendly)
   IFS=',' set -- $RELAY_LIST
   for pair in "$@"; do
      # Each pair must be in the format port:target
      port=${pair%%:*}
      target=${pair#*:}

      if [ -z "$port" ] || [ -z "$target" ]; then
         echo "Error: Each pair must be in 'port:target' format"
         exit 1
      fi

      echo "Starting socat. Relaying $target to port $port of this container"
      socat tcp-listen:$port,fork,reuseaddr tcp:$target < /dev/null &
   done
fi

echo "Starting Caddy"
caddy start --config /etc/caddy/Caddyfile

echo "Starting Tailscale"

exec /usr/local/bin/containerboot
