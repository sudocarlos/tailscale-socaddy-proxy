# Tailscale‑SoCaddy‑Proxy

A container image designed to run on [Start9](https://start9.com) that exposes
local services to your Tailscale network, using **Caddy** as an HTTP reverse 
proxy and **socat** for other non‑HTTP protocols.

## Table of Contents

- [Why Use This Image?](#why-use-this-image)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Create the Caddyfile](#create-the-caddyfile)
  - [Determine Your Tailnet Name](#determine-your-tailnet-name)
  - [Start9 File Operations](#start9-file-operations)
- [Usage](#usage)
- [Future Plans](#future-plans)
- [Contributing & Issues](#contributing--issues)

---

## Why Use This Image?

Managing a small cluster of services behind a firewall can quickly become cumbersome. Tailscale lets you expose a virtual network that behaves like a LAN over the public internet, while Caddy automatically handles TLS certificates. `socat` bridges any TCP‑based control protocol (e.g. Lightning nodes, mempool RPC) that Caddy cannot reverse‑proxy.

This image pulls everything together into a **single container** that can be:

* started on any machine that supports Docker
* integrated directly with Start9
* configured via simple environment variables and a Caddyfile

---

## Technology Stack

| Component | Purpose | Docs |
|-----------|---------|------|
| **Start9** | Local container orchestration & file persistence | [Start9 docs](https://start9.com) |
| **Tailscale** | Zero‑configuration VPN, MagicDNS, and device authentication | [Tailscale docs](https://tailscale.com) |
| **Caddy** | Modern HTTP/2 reverse proxy, automatic Let's Encrypt integration | [Caddy docs](https://caddyserver.com/docs) |
| **socat** | One‑shot TCP relay for non‑HTTP services | [socat manual](https://linux.die.net/man/1/socat) |

---

## Getting Started

### Prerequisites

1. A [Start9](https://docs.start9.com/0.3.5.x/user-manual/) server
2. A [Tailscale](https://tailscale.com/kb/1017/install) with an active [Tailnet](https://tailscale.com/kb/1217/tailnet-name)
3. [HTTPS certificates](https://tailscale.com/kb/1153/enabling-https) enabled
 in Tailscale **Admin console > DNS**

### Caddyfile

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
- Replace `your-tailnet` with your Tailnet name
- This example lists some common services. Feel free to discover and add more
- See https://caddyserver.com/docs/caddyfile/patterns#reverse-proxy for more info


### Determine Your Tailnet Name

The “Tailnet name” is the short identifier for your Tailscale VPN.  
To find it:

1. Log into the Tailscale admin console.
2. Look in the header of any device: the part before `.ts.net` is your tailnet name.  
   e.g., `start9.YOUR-TAILNET.ts.net`.

Alternatively, consult the troubleshooting article:  
[Tailscale – Tailnet Name](https://tailscale.com/kb/1217/tailnet-name).

### Start9 File Operations

Start9 exposes a UNIX‑compatible shell inside the container. Typical file creation tasks are straightforward:

```bash
# Login to your Start9, see https://docs.start9.com/0.3.5.x/user-manual/ssh
ssh start9@SERVER-HOSTNAME

# Create a directory for state files
mkdir -p /home/start9/tailscale

# Create the Caddyfile, see Caddyfile.example in repo
nano /home/start9/tailscale/Caddyfile
```

- ⚠️ Files are removed by Start9 on reboot. **Back up `/home/start9/tailscale`** ⚠️
- See [Caddyfile](#caddyfile) or [`Caddyfile.example`](/Caddyfile.example)
---

## Usage

```bash
# Start the container, replace 1
sudo podman run --name start9.tailscale \
 -v /home/start9/tailscale/:/var/lib/tailscale \
 -v /home/start9/tailscale/Caddyfile:/etc/caddy/Caddyfile \
 -e TS_HOSTNAME=start9 \
 -e TS_TAILNET=YOUR-TAILNET \
 -e RELAY_LIST=50001:electrs.embassy:50001,21004:lnd.embassy:10009 \
 --net start9 \
 --restart always \
 --init \
 docker.io/sudocarlos/tailscale-socaddy-proxy:latest

```

**Explanation**

* `TS_HOSTNAME` – The DNS name that will appear in your Tailscale network (`<TS_HOSTNAME>.<TS_TAILNET>.ts.net`).
* `RELAY_LIST` – Optional comma‑separated `port:target` pairs for socat listeners.  
  Example: `8080:lightning:9735,9090:electrs:30001`.
- https://tailscale.com/kb/1282/docker

---

## Future Plans

* **Integrated Web UI** – Manage reverse proxies and socat listeners from the browser (under development).
* **CLI Enhancements** – Dynamic proxy configuration via `tailscale-socaddy-proxy` command line.
* **Better Persistence** – Fine‑grained control over which files are auto‑synced by Start9.

---

## Contributing & Issues

Feel free to open issues for bugs or feature requests. When contributing:

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request with tests and documentation updates.

Happy hacking! 🚀
