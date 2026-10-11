---
description: "Run Keycloak with PostgreSQL on general01 with Docker Compose behind the lab gateway, and create the mcp realm that the OAuth playbook uses."
---

# Run Keycloak on general01

This playbook runs Keycloak and PostgreSQL with Docker Compose on general01 and creates the `mcp` realm. TLS is terminated at the gateway, so Keycloak itself only speaks HTTP.

Use it to set up (or rebuild) the identity provider before [Secure MCP Servers with OAuth](mcp-oauth.md).

Stack: Keycloak 26.8.0, PostgreSQL 18, Docker Compose · Target: `general01` (`192.168.10.9`, Debian 12), driven from the Fedora 44 KVM host · Env: lab

!!! warning "Lab-only configuration"
    Keycloak runs in `start-dev` mode, with the bootstrap admin account and the plain-HTTP listener on `8080`/`8443` published on all of general01's interfaces. That is acceptable on the isolated `net-lab` NAT network. Do not reuse it as is outside the lab.

The configuration lives in the repo under [`addons/keycloak/`](https://github.com/riupie/infra-lab/tree/main/addons/keycloak); the compose file below is embedded from there, so edit the repo, not this page.

## Prerequisites

- [ ] general01 reachable from the host: `ssh cloud@192.168.10.9 hostname`
- [ ] Docker Engine with the Compose plugin on general01: `docker --version && docker compose version`
- [ ] `jq` on the host for the checks: `sudo dnf install -y jq`
- [ ] [Dynamic DNS](dynamic-dns.md) done: External-DNS publishes `keycloak.lab.riupie.com` from the gateway route
- [ ] The route to Keycloak is in place. It is defined in [`gitops-fluxcd`](https://github.com/riupie/gitops-fluxcd) under `infrastructure/overlays/development/configs/keycloak/`, not in this repo: a `Service` and `EndpointSlice` pointing at `192.168.10.9:8080`, and an `HTTPRoute` for `keycloak.lab.riupie.com` on the `https` listener of `gateway-ai`. TLS is a Let's Encrypt certificate that cert-manager issues with DNS-01 through Cloudflare (`ClusterIssuer` `letsencrypt-production`).

## Steps

### 1. Prepare the directory on general01

*On the host:*

```bash
ssh cloud@192.168.10.9 'sudo install -d /opt/keycloak'
```

### 2. Copy the compose file

*On the host:*

```bash
scp addons/keycloak/docker-compose.yaml addons/keycloak/.env.example cloud@192.168.10.9:/tmp/
ssh cloud@192.168.10.9 'sudo install -m 0644 /tmp/docker-compose.yaml /opt/keycloak/docker-compose.yaml \
  && { sudo test -e /opt/keycloak/.env || sudo install -m 0600 /tmp/.env.example /opt/keycloak/.env; } \
  && rm /tmp/docker-compose.yaml /tmp/.env.example'
```

An existing `/opt/keycloak/.env` is never overwritten, so this is safe on a rebuild.

```yaml
--8<-- "addons/keycloak/docker-compose.yaml"
```

### 3. Fill in the credentials

*On general01.* The compose file reads every secret from `/opt/keycloak/.env`. Generate the two passwords there instead of typing them, so they never enter your shell history:

```bash
cd /opt/keycloak
sudo sed -i \
  -e "s|^KC_BOOTSTRAP_ADMIN_PASSWORD=.*|KC_BOOTSTRAP_ADMIN_PASSWORD=$(openssl rand -hex 16)|" \
  -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|" .env
sudo cat .env   # note the admin password in your password manager
```

!!! warning "First install only"
    On a rebuild that keeps the `postgres_data` volume, skip this step: PostgreSQL ignores a new `POSTGRES_PASSWORD` once the volume exists, and Keycloak then fails to log in.

`KC_HOSTNAME` must be the full public URL (`https://keycloak.lab.riupie.com`). It decides the `iss` claim that the gateway policy compares in the OAuth playbook.

### 4. Start Keycloak

*On general01:*

```bash
cd /opt/keycloak
docker compose up -d
docker compose ps
docker compose logs keycloak | grep -E 'Keycloak .* started|Listening'
```

Expected: both containers `Up`, and a line such as `Keycloak 26.8.0 on JVM (...) started in 25.4s`. The first start imports the schema into PostgreSQL and takes about a minute.

### 5. Check the endpoint locally

*On general01:*

```bash
curl -s http://127.0.0.1:8080/realms/master/.well-known/openid-configuration | grep -o '"issuer":"[^"]*"'
```

Expected: `"issuer":"https://keycloak.lab.riupie.com/realms/master"`. The public hostname appears even though you called the HTTP port because of `KC_HOSTNAME`.

### 6. Create the `mcp` realm

*Admin console, `https://keycloak.lab.riupie.com/admin`* (log in with the bootstrap admin from `.env`):

1. Realm selector (top left) → **Manage realms** → **Create realm** → Realm name `mcp`, Enabled ON → Create.
2. Switch back to the `master` realm → Users → **Add user**, then **Credentials** → Set password (Temporary OFF) and **Role mapping** → Assign role → `admin`. Log in as that user and delete the bootstrap admin; Keycloak intends the bootstrap account to be temporary.

Continue with the groups, scopes and client registration policies in [Secure MCP Servers with OAuth](mcp-oauth.md#2-create-the-group-and-user).

## Verify

*On the host:*

```bash
curl -s https://keycloak.lab.riupie.com/realms/mcp/.well-known/openid-configuration \
  | jq '{issuer, jwks_uri, registration_endpoint}'
```

Expected: `issuer` is exactly `https://keycloak.lab.riupie.com/realms/mcp`, and `registration_endpoint` ends in `/realms/mcp/clients-registrations/openid-connect`. The certificate is the public Let's Encrypt one, so `curl` needs no extra CA.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `https://keycloak.lab.riupie.com` returns `404 route not found` or times out, while `http://192.168.10.9:8080` works | The gateway route or DNS record is missing | Check the HTTPRoute in `gitops-fluxcd` and `resolvectl query keycloak.lab.riupie.com` ([Dynamic DNS step 8](dynamic-dns.md#8-resolve-the-lab-zone-from-the-fedora-host)) |
| `iss` or `issuer` shows `http://…:8080` | `KC_HOSTNAME` is a bare hostname, or the gateway does not send `X-Forwarded-*` | Set the full `https://` URL in `.env`, then `docker compose up -d`. Keep `KC_PROXY_HEADERS=xforwarded` |
| `keycloak_app` exits with `password authentication failed` | `POSTGRES_PASSWORD` changed after the database volume was created | Restore the old password in `.env`. To start from an empty database instead, run `docker compose down -v` (`-v` removes the `postgres_data` volume, and with it the `mcp` realm, users and clients; plain `down` keeps the volume), then `docker compose up -d` |
| Browser login loops or shows `Invalid parameter: redirect_uri` | The client's redirect URI does not match the URL you open | Open the console through `https://keycloak.lab.riupie.com`, not the node IP |

## Rollback

*On general01:*

```bash
cd /opt/keycloak && docker compose down
```

This stops Keycloak; the realm, users and registered clients stay in the `postgres_data` volume. DCR clients and MCP logins stop working until it is started again.

## References

- [Keycloak: configuring the hostname](https://www.keycloak.org/server/hostname)
- [Keycloak: using a reverse proxy](https://www.keycloak.org/server/reverseproxy)
- [Keycloak container guide](https://www.keycloak.org/server/containers)
