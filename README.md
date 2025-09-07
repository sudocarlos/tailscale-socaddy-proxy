# tailscale-socaddy-proxy

A container image designed to run on [Start9](https://start9.com) that exposes
local services to your Tailscale network, using **Caddy** as an HTTP reverse 
proxy and **socat** for other non‑HTTP protocols.

![](images/tailrelay.svg)

## Table of Contents

- [Why?](#why)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Tailscale](#tailscale)
    - [Caddy](#create-the-caddyfile)
        - [Caddyfile](#caddyfile)
    - [Start9](#start9)


## Why?

Accessing **Start9** services such as **BTCPayServer** and **electrs RPC** requires Tor today.
**Tailscale** lets you privately and securely expose your services, while 
**Caddy** takes care of obtaining and renewing TLS certificates.
**`socat`** relays the non-HTTP ports Caddy can’t reverse‑proxy.

This container image combines them 


## Technology Stack

| Component | Purpose | Docs |
|-----------|---------|------|
| **Start9** | Local container orchestration & file persistence | [Start9 docs](https://docs.start9.com/0.3.5.x/user-manual/) |
| **Tailscale** | Zero‑configuration VPN, MagicDNS, and device authentication | [Tailscale docs](https://tailscale.com/kb) |
| **Caddy** | Modern HTTP/2 reverse proxy, automatic Let's Encrypt integration | [Caddy docs](https://caddyserver.com/docs) |
| **socat** | One‑shot TCP relay for non‑HTTP services | [socat manual](https://linux.die.net/man/1/socat) |


## Getting Started

### Prerequisites

1. A [Start9](https://docs.start9.com/0.3.5.x/user-manual/) server
2. A [Tailscale](https://tailscale.com/kb/1017/install) with an active [Tailnet](https://tailscale.com/kb/1217/tailnet-name)
3. [HTTPS certificates](https://tailscale.com/kb/1153/enabling-https) enabled
 in Tailscale **Admin console > DNS**

### Tailscale

1. Log into the Tailscale **Admin console** and click [**DNS**](https://login.tailscale.com/admin/dns)
1. Verify or set your [**Tailnet name**](https://tailscale.com/kb/1217/tailnet-name)
1. Scroll down and **Enable HTTPS** under **HTTPS Certificates**

### Caddy

1. Login to your Start9, see https://docs.start9.com/0.3.5.x/user-manual/ssh

        ssh start9@SERVER-HOSTNAME

1. Create a directory to persist Tailscale and Caddy files

        mkdir -p /home/start9/tailscale

1. Create the [Caddyfile](#caddyfile) below or [`Caddyfile.example`](/Caddyfile.example)

        nano /home/start9/tailscale/Caddyfile

1. ⚠️ Files are removed by Start9 on reboot. **Back up `/home/start9/tailscale`** ⚠️

#### Caddyfile

```
# Caddyfile
start9.your-tailnet.ts.net:21000 {
	reverse_proxy https://lnd.embassy:8080 {
		header_up Host {upstream_hostport}
		transport http {
			tls_trust_pool file /var/lib/tailscale/tls.cert
		}
	}
}

start9.your-tailnet.ts.net:21001 {
	reverse_proxy http://mempool.embassy:8080 {
		header_up Host {upstream_hostport}
	}
}

start9.your-tailnet.ts.net:21002 {
	reverse_proxy http://btcpayserver.embassy:80 {
		header_up Host {upstream_hostport}
		trusted_proxies private_ranges
	}
}

start9.your-tailnet.ts.net:21003 {
	reverse_proxy http://jam.embassy:80 {
		header_up Host {upstream_hostport}
	}
}

```
- Replace `start9` with the Tailscale machine name you want,
 this must match `-e TS_HOSTNAME=` in `podman run`
- Replace `your-tailnet.ts.net` with your [**Tailnet name**](https://tailscale.com/kb/1217/tailnet-name)
- This example lists some common services. Feel free to discover and add more
- See https://caddyserver.com/docs/caddyfile/patterns#reverse-proxy for more info

⚠️ Files are removed by Start9 on reboot. **Back up `/home/start9/tailscale`** ⚠️


### Start9

1. Finally, run the container
```bash
sudo podman run --name start9.tailscale \
 -v /home/start9/tailscale/:/var/lib/tailscale \
 -v /home/start9/tailscale/Caddyfile:/etc/caddy/Caddyfile \
 -e TS_HOSTNAME=start9 \
 -e RELAY_LIST=50001:electrs.embassy:50001,21004:lnd.embassy:10009 \
 --net start9 \
 docker.io/sudocarlos/tailrelay:latest

```

- `TS_HOSTNAME` - your desired Tailnet machine name. This should match in your [Caddyfile](#caddyfile)
- `RELAY_LIST` - optional, comma‑separated `listener_port:target_host:target_port` pairs for socat listeners  
  Example: `50001:electrs.embassy:50001,21004:lnd.embassy:10009`
- `-v` - volume mounts. Only change values on the left of `:`
  if you decide to place files in your Start9 in a different directory
- See https://tailscale.com/kb/1282/docker for more info
