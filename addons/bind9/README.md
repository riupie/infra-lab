### Generate TSIG Key

```bash
tsig-keygen -a hmac-sha512 externaldns-key > config/keys/external-dns.key
```

### Run BIND9
```bash
docker compose up -d
```