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

| External Port | Internal Port | Protocol | Purpose |
|---|---|---|---|
| 80 | 80 | TCP | HTTP (redirects to HTTPS) |
| 443 | 443 | TCP | HTTPS (Nextcloud web interface) |
| 8080 | 8080 | TCP | Nextcloud AIO admin dashboard |
| 3478 | 3478 | TCP + UDP | STUN/TURN (Nextcloud Talk) |

### Security Notes

- **Port 8080** (AIO dashboard) can optionally be restricted to LAN-only access after initial setup. It is only needed for Nextcloud AIO administration, not for regular users.
- The firewall (`ufw`) configured in `01-base-setup.sh` only allows these ports plus SSH.

## Domain Name

You need a domain name (or subdomain) pointing to your static IP. For example:

```
archive.steffinossen.org → your.static.ip.address
```

This is required for Let's Encrypt SSL certificates to work.

If your IP changes (unlikely with a true static IP, but possible), update the DNS A record.

## SSL / TLS

SSL is handled automatically by **Caddy** inside Nextcloud AIO:
- Caddy obtains and renews Let's Encrypt certificates
- HTTP (port 80) automatically redirects to HTTPS (port 443)
- No manual certificate management required

Set the domain name in the `.env` file before deploying:

```bash
NEXTCLOUD_DOMAIN=archive.steffinossen.org
```

## Pre-Launch Checklist

Before going live, verify:

- [ ] Static IP is assigned and stable
- [ ] DNS A record points to the static IP
- [ ] All four ports are forwarded on the router
- [ ] `ufw` is active with the correct rules
- [ ] Upload speed from the building is tested and documented
- [ ] AIO dashboard (port 8080) access is reviewed for security

## Bandwidth Considerations

Remote uploads and video playback are limited by the building's **upload speed** (not download). Before committing to serving video remotely, test the actual upload bandwidth:

```bash
# Quick test from the server
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

For reference:
- Smooth 1080p video streaming needs ~5-10 Mbps upload
- Large file uploads from remote editors share that same pipe
- Go-VOD adaptive streaming helps by adjusting quality to available bandwidth

## Fallback: Cloudflare Tunnel

If port forwarding proves unreliable or the ISP blocks inbound traffic, Cloudflare Tunnel is a viable alternative. It uses outbound-only connections, bypassing port-forwarding entirely. This is documented as a fallback, not the primary approach.

See the [Nextcloud AIO reverse proxy documentation](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md) for setup instructions if needed.
