# Network Configuration

## Static IP

The server requires a **static IP address** on the nonprofit's business internet connection. This is typically configured through the ISP or by setting a static lease on the router.

On the server itself, configure a static IP via Netplan (Ubuntu 24.04 default):

```yaml
# /etc/netplan/01-static.yaml
network:
  version: 2
  ethernets:
    eno1:                    # Replace with your interface name
      dhcp4: false
      addresses:
        - 192.168.1.100/24   # Replace with your static LAN IP
      routes:
        - to: default
          via: 192.168.1.1   # Replace with your gateway
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

Apply with:

```bash
sudo netplan apply
```

## Port Forwarding

Configure the following port forwards on your router, pointing to the server's LAN IP:

- **Port 80 TCP**: HTTP -- Caddy uses this for Let's Encrypt certificate validation and redirects to HTTPS
- **Port 443 TCP**: HTTPS -- All Immich traffic flows through this port

That's it. Immich is much simpler than Nextcloud -- no admin dashboard port, no STUN/TURN ports.

### Security Notes

- The firewall (`ufw`) configured in `01-base-setup.sh` only allows SSH, 80, and 443.
- Immich's admin interface is part of the main web UI (no separate port).

## Domain Name

You need a domain name (or subdomain) pointing to your static IP. For example:

```
archive.steffinossen.org → your.static.ip.address
```

This is required for Let's Encrypt SSL certificates to work.

If your IP changes (unlikely with a true static IP, but possible), update the DNS A record.

## SSL / TLS

SSL is handled by **Caddy** running as a container alongside Immich:

- Caddy obtains and renews Let's Encrypt certificates automatically
- HTTP (port 80) automatically redirects to HTTPS (port 443)
- No manual certificate management required

Set the domain name in the `.env` file before deploying:

```bash
IMMICH_DOMAIN=archive.steffinossen.org
```

## Pre-Launch Checklist

- [ ] Static IP is assigned and stable
- [ ] DNS A record points to the static IP
- [ ] Ports 80 and 443 are forwarded on the router
- [ ] `ufw` is active with the correct rules
- [ ] Upload speed from the building is tested and documented

## Bandwidth Considerations

Remote uploads and video playback are limited by the building's **upload speed** (not download). Before committing to serving video remotely, test the actual upload bandwidth:

```bash
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

For reference:
- Smooth 1080p video streaming needs ~5-10 Mbps upload
- Large photo uploads from remote editors share that same pipe
- Immich transcodes video for web playback, which helps with bandwidth

## Fallback: Cloudflare Tunnel

If port forwarding proves unreliable or the ISP blocks inbound traffic, Cloudflare Tunnel is a viable alternative. It uses outbound-only connections, bypassing port forwarding entirely.

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Authenticate and create tunnel
cloudflared tunnel login
cloudflared tunnel create steffi-archive
cloudflared tunnel route dns steffi-archive archive.steffinossen.org
```

This is documented as a fallback, not the primary approach.
