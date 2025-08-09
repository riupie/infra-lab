# BIND9 Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying BIND9 DNS server on the bastion host (bastion01) using Docker Compose. The deployment includes configuration setup, TSIG key generation, and integration with the lab infrastructure.

## Prerequisites

### System Requirements

| Component | Requirement | Verification Command |
|-----------|-------------|---------------------|
| **Docker** | 20.10+ | `docker --version` |
| **Docker Compose** | 2.0+ | `docker compose version` |

## Configuration Deployment

### Step 1: Prepare Deployment Directory

```bash
# Create BIND9 deployment directory
mkdir -p /opt/bind9/{config,zones,cache,config/keys}

# Set proper ownership
chown -R cloud:cloud /opt/bind9

# Switch back to cloud user
su - cloud
cd /opt/bind9
```

### Step 2: Generate TSIG Key

```bash
# Generate authentication key for dynamic DNS updates
tsig-keygen -a hmac-sha512 externaldns-key > /opt/bind9/config/keys/external-dns.key

# Verify key generation
cat config/keys/external-dns.key

# Expected output format:
# key "externaldns-key" {
#     algorithm hmac-sha256;
#     secret "base64-key-string==";
# };
```

!!! warning "Key Security"
    Store the generated key securely. This key will be used by External-DNS for dynamic updates.

### Step 3: Create Configuration Files

#### Main Configuration

```bash
cat > config/named.conf << 'EOF'
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
EOF
```

#### Server Options

```bash
cat > config/named.conf.options << 'EOF'
//The following keys are used for dynamic DNS updates
include "/etc/bind/keys/external-dns.key";

options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };

    forwarders {
        8.8.8.8;
        1.1.1.1;
    };

    dnssec-validation auto;

    listen-on { any; };
};

logging {
   channel stdout_channel {
       stderr;
       severity info;
       print-category yes;
       print-severity yes;
       print-time yes;
   };
   category default {
       stdout_channel;
   };
   category queries {
       stdout_channel;
   };
   category security {
       stdout_channel;
   };
   category dnssec {
       stdout_channel;
   };
};
EOF
```

#### Zone Configuration

```bash
cat > config/named.conf.local << 'EOF'
zone "lab.riupie.com" {
    type master;
    file "/zones/lab.riupie.com.zone";
    allow-transfer {
        key "externaldns-key";
    };
    update-policy {
        grant externaldns-key zonesub any;
    };
};
EOF
```

### Step 3: Create Zone File

```bash
# Create initial zone file with current date as serial
SERIAL=$(date +%Y%m%d%H)

cat > zones/lab.riupie.com.zone << EOF
\$TTL 3600	; 1 hour
lab.riupie.com.		IN SOA	ns1.lab.riupie.com. admin.lab.riupie.com. (
				${SERIAL} ; serial
				3600       ; refresh (1 hour)
				1800       ; retry (30 minutes)
				604800     ; expire (1 week)
				86400      ; minimum (1 day)
				)
			NS	ns1.lab.riupie.com.
			
ns1.lab.riupie.com.     A       192.168.10.9
EOF
```

### Step 4: Create Docker Compose File

```bash
cat > docker-compose.yaml << 'EOF'
services:
  bind9:
    image: internetsystemsconsortium/bind9:9.20
    container_name: bind9
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    volumes:
      - ./config:/etc/bind
      - ./zones:/zones
      - ./cache:/var/cache/bind
    restart: unless-stopped
    environment:
      - TZ=UTC
    healthcheck:
      test: ["CMD", "dig", "@localhost", "lab.riupie.com", "SOA"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF
```

## Configuration Validation

### Step 1: Validate Configuration Files

```bash
# Check BIND configuration syntax
 docker run --rm -v "$(pwd)/config:/etc/bind" \
   --entrypoint named-checkconf \
   internetsystemsconsortium/bind9:9.20 \
   /etc/bind/named.conf

# Expected output: (no output means configuration is valid)
```

### Step 2: Validate Zone File

```bash
# Check zone file syntax
docker run --rm \
  -v "$(pwd):/bind-data" \
  --entrypoint named-checkzone \
  internetsystemsconsortium/bind9:9.20 \
  lab.riupie.com /bind-data/zones/lab.riupie.com.zone

# Expected output:
# zone lab.riupie.com/IN: loaded serial 2025050307
# OK
```

## Service Deployment

### Step 1: Start BIND9 Service

```bash
# Start the DNS server
docker compose up -d

# Verify container is running
docker compose ps

# Expected output:
# NAME      IMAGE                                    COMMAND             SERVICE   CREATED         STATUS                   PORTS
# bind9     internetsystemsconsortium/bind9:9.20    "/usr/sbin/named"   bind9     2 seconds ago   Up 1 second (healthy)   0.0.0.0:53->53/tcp, 0.0.0.0:53->53/udp
```

### Step 2: Monitor Startup Logs

```bash
# Check container logs
docker compose logs -f bind9

# Expected log entries:
# bind9  | starting BIND 9.20.3 (Extended Support Version)
# bind9  | zone lab.riupie.com/IN: loaded serial 2025050307
# bind9  | running
```

### Step 3: Test DNS Resolution

```bash
# Test internal zone resolution
dig @localhost lab.riupie.com SOA

# Expected output includes:
# ;; ANSWER SECTION:
# lab.riupie.com. 3600 IN SOA ns1.lab.riupie.com. admin.lab.riupie.com. ...

# Test recursive resolution
dig @localhost google.com A

# Should return Google's IP addresses
```

## Dynamic DNS Integration

### Step 1: Extract TSIG Key for External-DNS

```bash
# On bastion01, extract the TSIG key secret
cd /opt/bind9
grep secret config/keys/external-dns.key

# Output format:
# secret "base64-encoded-key-here==";

# Copy this key for External-DNS configuration in Kubernetes
```

### Step 2: Test Dynamic DNS Updates

```bash
# Create a test update file
cat > test-update.txt << 'EOF'
server 192.168.10.9
zone lab.riupie.com.
update add test.lab.riupie.com. 300 A 192.168.10.100
send
EOF

# Test dynamic update (requires TSIG key setup)
nsupdate -k config/keys/external-dns.key < test-update.txt

# Verify the update
dig @192.168.10.9 test.lab.riupie.com A
```

## Troubleshooting Common Issues
On Debian-based systems, systemd-resolved may conflict with BIND9. You can resolve this by pointing systemd-resolved to your BIND9 server.
Edit `/etc/systemd/resolved.conf`:

```bash
[Resolve]
DNS=127.0.0.1   # or your BIND9 server IP
DNSStubListener=no
```

Then restart the service:

```bash
sudo systemctl restart systemd-resolved
```