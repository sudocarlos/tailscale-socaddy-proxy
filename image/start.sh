#!/bin/ash
trap 'kill -TERM $PID' TERM INT

# Accept a single comma‑separated list of port:target pairs
# Example:
#   RELAY_LIST=8080:app1:80,9090:app2:80
# Each item in the list represents one socat relay.
RELAY_LIST=${RELAY_LIST:-}

echo -n "Starting tailscale-socaddy-proxy version"
tailscale --version

# Spawn socat instances if RELAY_LIST is provided
if [ ! -z "$RELAY_LIST" ]; then
   # Split the comma‑separated list into individual items
   set -- ${RELAY_LIST//,/ }
   for item in "$@"; do
      # Example item: 50002:electrs.embassy:50001
      # Extract the three parts
      listening_port=${item%%:*}      # 50002
      rest=${item#*:}                 # electrs.embassy:50001
      target_host=${rest%%:*}         # electrs.embassy
      target_port=${rest#*:}          # 50001

      # Basic sanity check
      if [ -z "$listening_port" ] || [ -z "$target_host" ] || [ -z "$target_port" ]; then
         echo "Error: '$item' must be in 'port:target_host:target_port' format"
         exit 1
      fi

      echo "Starting socat: relaying $target_host:$target_port to listening port $listening_port"
      socat tcp-listen:$listening_port,fork,reuseaddr tcp:$target_host:$target_port < /dev/null &
   done
fi


echo "Starting Caddy"
caddy start --config /etc/caddy/Caddyfile

echo "Starting Tailscale"

exec /usr/local/bin/containerboot
