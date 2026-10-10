# Deploy BIND9 DNS on bastion01

This playbook runs authoritative DNS for the `lab.riupie.com` zone plus recursive resolution for the lab, with TSIG-secured dynamic updates so External-DNS can register records from Kubernetes.

Use it to set up (or rebuild) the lab DNS server on the bastion, before configuring External-DNS in Kubernetes (step 3 produces its TSIG key).

Stack: BIND9 9.20 (`internetsystemsconsortium/bind9:9.20`), Docker Compose · Target: `bastion01` (`192.168.10.9`, Debian 12), driven from the Fedora 44 KVM host · Env: lab

The configuration lives in the repo under [`addons/bind9/`](https://github.com/riupie/infra-lab/tree/main/addons/bind9); the files shown below are embedded from there, so edit the repo, not this page.

## Prerequisites

- [ ] bastion01 reachable from the host: `ssh cloud@192.168.10.9 hostname`
- [ ] Docker Engine with the Compose plugin on bastion01: `docker --version && docker compose version`
- [ ] Port 53 free on bastion01: `sudo ss -lntup 'sport = :53'` prints nothing (see [Troubleshooting](#troubleshooting) if not)
- [ ] `dig` and `nsupdate` on the Fedora host: `sudo dnf install -y bind-utils`
- [ ] A checkout of this repo on the host; commands marked *On the host* run from its root

## Steps

### 1. Prepare the directory on bastion01

*On the host:*

```bash
ssh cloud@192.168.10.9 'sudo install -d -o cloud -g cloud /opt/bind9 /opt/bind9/config/keys'
```

### 2. Copy the configuration

*On the host:*

```bash
rsync -av --exclude README.md --exclude 'config/keys/' \
  addons/bind9/ cloud@192.168.10.9:/opt/bind9/
```

!!! warning "Rebuilds"
    External-DNS writes records into the zone journal (`zones/*.jnl`) on bastion01. Re-running this rsync on a live server overwrites `zones/lab.riupie.com.zone`; on an existing server copy only `config/` and `docker-compose.yaml`, and bump the SOA serial when you edit the zone by hand.

The copied files:

=== "named.conf"

    ```text
    --8<-- "addons/bind9/config/named.conf"
    ```

=== "named.conf.options"

    ```text
    --8<-- "addons/bind9/config/named.conf.options"
    ```

=== "named.conf.local"

    ```text
    --8<-- "addons/bind9/config/named.conf.local"
    ```

=== "lab.riupie.com.zone"

    ```text
    --8<-- "addons/bind9/zones/lab.riupie.com.zone"
    ```

=== "docker-compose.yaml"

    ```yaml
    --8<-- "addons/bind9/docker-compose.yaml"
    ```

### 3. Generate the TSIG key

*On bastion01* (`ssh cloud@192.168.10.9`). The key is generated inside the BIND image, so the bastion needs no BIND packages:

```bash
cd /opt/bind9
docker run --rm --entrypoint tsig-keygen internetsystemsconsortium/bind9:9.20 \
  -a hmac-sha512 externaldns-key > config/keys/external-dns.key
chmod 640 config/keys/external-dns.key
sudo chgrp 53 config/keys/external-dns.key   # gid 53 = bind inside the image
```

Expected content of `config/keys/external-dns.key`:

```text
key "externaldns-key" {
	algorithm hmac-sha512;
	secret "<base64>";
};
```

!!! warning "Key security"
    This key can rewrite any record in `lab.riupie.com`. Don't commit it unencrypted (the repo copy is protected by git-crypt) and don't paste it into docs or tickets.

### 4. Set ownership for named

*On bastion01.* `named` runs as uid/gid 53 inside the container and must write the zone journal and its cache:

```bash
sudo chown -R 53:53 /opt/bind9/zones /opt/bind9/cache
```

If you skip this, dynamic updates fail with `permission denied` on `lab.riupie.com.zone.jnl`.

### 5. Validate the configuration

*On bastion01:*

```bash
cd /opt/bind9
docker run --rm -v "$PWD/config:/etc/bind" --entrypoint named-checkconf \
  internetsystemsconsortium/bind9:9.20 /etc/bind/named.conf
docker run --rm -v "$PWD/zones:/zones" --entrypoint named-checkzone \
  internetsystemsconsortium/bind9:9.20 lab.riupie.com /zones/lab.riupie.com.zone
```

Expected output (`named-checkconf` prints nothing when the config is valid):

```text
zone lab.riupie.com/IN: loaded serial 2025050307
OK
```

### 6. Start BIND9

*On bastion01:*

```bash
cd /opt/bind9
docker compose up -d
docker compose ps
docker compose logs bind9 | grep -E 'loaded serial|running'
```

Expected output (`STATUS` reaches `healthy` after up to 40 s):

```text
NAME    IMAGE                                  SERVICE   STATUS
bind9   internetsystemsconsortium/bind9:9.20   bind9     Up 1 minute (healthy)
...
zone lab.riupie.com/IN: loaded serial 2025050307
running
```

### 7. Hand the TSIG secret to External-DNS

*On bastion01:*

```bash
grep secret /opt/bind9/config/keys/external-dns.key
```

Use the value (without quotes) as the RFC2136 TSIG secret in the External-DNS configuration, with key name `externaldns-key` and algorithm `hmac-sha512`.

### 8. (Optional) Resolve the lab zone from the Fedora host

*On the host.* Route only `lab.riupie.com` queries to bastion01 through systemd-resolved on the lab bridge:

```bash
BR=$(sudo virsh net-info net-lab | awk '/^Bridge/ {print $2}')
sudo resolvectl dns "$BR" 192.168.10.9
sudo resolvectl domain "$BR" '~lab.riupie.com'
resolvectl query ns1.lab.riupie.com
```

This setting is runtime-only: it is lost when the libvirt network or the host restarts. Re-run the commands after a restart.

## Verify

### 1. Authoritative and recursive resolution

*On the host:*

```bash
dig @192.168.10.9 lab.riupie.com SOA +short
dig @192.168.10.9 example.com A +short
```

Expected output: the SOA record (`ns1.lab.riupie.com. admin.lab.riupie.com. <serial> 3600 1800 604800 86400`), then one or more IP addresses for `example.com`.

### 2. Dynamic update with the TSIG key

*On bastion01* (the key stays on the server):

```bash
cd /opt/bind9
docker compose exec -T bind9 nsupdate -k /etc/bind/keys/external-dns.key <<'EOF'
server 127.0.0.1
zone lab.riupie.com.
update add test.lab.riupie.com. 300 A 192.168.10.100
send
EOF
dig @127.0.0.1 test.lab.riupie.com A +short
```

Expected output: `192.168.10.100`. Remove the test record:

```bash
docker compose exec -T bind9 nsupdate -k /etc/bind/keys/external-dns.key <<'EOF'
server 127.0.0.1
zone lab.riupie.com.
update delete test.lab.riupie.com. A
send
EOF
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker compose up` fails: `address already in use` on port 53 | The systemd-resolved stub listener holds port 53 (`sudo ss -lntup 'sport = :53'` shows `systemd-resolve`) | Disable the stub listener (below) |
| `nsupdate` returns `REFUSED`, log shows `permission denied` on `.jnl` | `zones/` not writable by uid 53 | Step 4 |
| `nsupdate` returns `NOTAUTH` / `tsig verify failure` | Wrong key file or algorithm mismatch | Use the key from step 3; algorithm must be `hmac-sha512` on both sides |
| Recursive queries return `REFUSED` | Client is outside `allow-recursion` | Add the client network to `allow-recursion` in `named.conf.options`, redeploy `config/` (step 2), `docker compose restart` |
| Container stays `unhealthy` | `named` failed to load the zone | `docker compose logs bind9`, then re-run step 5 |

Disabling the systemd-resolved stub listener on bastion01:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nDNS=127.0.0.1\nDNSStubListener=no\n' | sudo tee /etc/systemd/resolved.conf.d/bind9.conf
sudo systemctl restart systemd-resolved
```

## Rollback

*On bastion01:*

```bash
cd /opt/bind9 && docker compose down
```

Clients that use `192.168.10.9` as their resolver lose DNS until it is restarted. `/opt/bind9` (zone, journal, key) is left in place; delete it only if you are rebuilding from scratch, because you will need a new TSIG key in External-DNS afterwards.

## References

- [BIND 9 Administrator Reference Manual](https://bind9.readthedocs.io/en/v9.20.0/)
- [ISC BIND9 container image](https://hub.docker.com/r/internetsystemsconsortium/bind9)
- [External-DNS RFC2136 provider](https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/rfc2136/)
