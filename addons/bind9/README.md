### Generate TSIG Key

```bash
tsig-keygen -a hmac-sha512 externaldns-key > config/keys/external-dns.key
```
The output should be like this:
```
key "externaldns-key" {
	algorithm hmac-sha512;
	secret "<BASE64 encoded>";
};
```

### Run BIND9
```bash
docker compose up -d
```