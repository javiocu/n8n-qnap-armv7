# n8n for QNAP TS-431P3 (ARMv7 32KB pagesize)

![n8n](https://img.shields.io/badge/n8n-2.7+-FF6D5A?logo=n8n)
![Docker](https://img.shields.io/badge/Docker-ARMv7-2496ED?logo=docker)
![QNAP](https://img.shields.io/badge/QNAP-TS--431P3-00A3E0)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)

Custom **n8n** Docker image compiled specifically for QNAP NAS devices with **Alpine AL314 (ARMv7)** processors that use **32KB memory pages**.

## 🎯 Problem Solved

Official n8n images (and many other services) crash on ARMv7 processors with 32KB pagesize because native modules like `better-sqlite3` and `sqlite3` are precompiled for the standard 4KB page size.

**Common symptoms:**
- Segmentation fault (error 139)
- Bus error
- n8n exits immediately after starting

**Solution:** This image recompiles all native modules with the `-Wl,-z,max-page-size=32768` flag.

## 📋 Compatible Hardware

| Component | Specification |
|-----------|---------------|
| **CPU** | Alpine AL314 Quad-core ARM Cortex-A15 @ 1.70GHz |
| **Architecture** | ARMv7 (32-bit) with 32KB pagesize |
| **RAM** | 4GB minimum |
| **Tested Models** | QNAP TS-431P3 |
| **Firmware** | QTS 5.2.5+ |

## 🚀 Quick Start

### Option 1: Docker Hub (Recommended)

```bash
# SSH into your QNAP NAS
ssh admin@YOUR_NAS_IP

# Create data directory
mkdir -p /share/Container/n8ndata
chown -R 1000:1000 /share/Container/n8ndata

# Download docker-compose.yml
cd /share/Container
mkdir n8n-docker && cd n8n-docker
wget https://raw.githubusercontent.com/javiocu/n8n-qnap-armv7/main/docker-compose.yml

# Edit WEBHOOK_URL with your IP
nano docker-compose.yml

# Deploy
docker-compose up -d

# View logs
docker logs -f n8n
```

Access at `http://YOUR_NAS_IP:5678`

### Option 2: Manual Pull

```bash
docker pull javiocu/n8n-armv7-qnap431-3p:latest
docker run -d \\
  --name n8n \\
  --restart unless-stopped \\
  --network host \\
  -e N8N_PORT=5678 \\
  -e GENERIC_TIMEZONE=Europe/Madrid \\
  -v /share/Container/n8ndata:/home/node/.n8n \\
  javiocu/n8n-armv7-qnap431-3p:latest
```

## 📄 docker-compose.yml

```yaml
services:
  n8n:
    image: javiocu/n8n-armv7-qnap431-3p:latest
    container_name: n8n
    restart: unless-stopped
    network_mode: host
    environment:
      - NODE_ENV=production
      - N8N_PORT=5678
      - N8N_HOST=0.0.0.0
      - GENERIC_TIMEZONE=Europe/Madrid
      - TZ=Europe/Madrid
      - WEBHOOK_URL=http://10.8.0.1:5678  # Adjust to your NAS IP
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - LD_PRELOAD=
      # Optional: Basic authentication
      # - N8N_BASIC_AUTH_ACTIVE=true
      # - N8N_BASIC_AUTH_USER=admin
      # - N8N_BASIC_AUTH_PASSWORD=changeme
    volumes:
      - /share/Container/n8ndata:/home/node/.n8n
```

### Test Environment (Port 5679)

```yaml
services:
  n8n-test:
    image: javiocu/n8n-armv7-qnap431-3p:latest
    container_name: n8n-test-2026
    restart: unless-stopped
    network_mode: host
    environment:
      - NODE_ENV=production
      - N8N_PORT=5679
      - N8N_HOST=0.0.0.0
      - GENERIC_TIMEZONE=Europe/Madrid
      - TZ=Europe/Madrid
      - WEBHOOK_URL=http://10.8.0.1:5679
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - LD_PRELOAD=
    volumes:
      - /share/Container/n8ntest2026:/home/node/.n8n
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

## 🛠️ Build from Source

### Prerequisites (Linux Mint/Ubuntu/Debian)

```bash
# Install QEMU for cross-compilation
sudo apt-get update
sudo apt-get install -y qemu-user-static binfmt-support

# Configure Docker Buildx
docker buildx create --name multiarch --use --driver docker-container
docker buildx inspect --bootstrap
```

### Clone and Build

```bash
# Clone repository
git clone https://github.com/javiocu/n8n-qnap-armv7.git
cd n8n-qnap-armv7

# Build (takes 15-25 minutes on i5-7500)
docker buildx build \\
  --platform linux/arm/v7 \\
  -t javiocu/n8n-armv7-qnap431-3p:latest \\
  --load .

# Verify image
docker images | grep n8n
```

### Export to TAR (for NAS transfer)

```bash
# Export
docker save javiocu/n8n-armv7-qnap431-3p:latest -o n8n-qnap.tar

# Transfer to NAS
scp n8n-qnap.tar admin@YOUR_NAS_IP:/share/Public/

# On NAS: Load image
ssh admin@YOUR_NAS_IP
docker load -i /share/Public/n8n-qnap.tar
docker images | grep n8n
```

## 📦 Deploy on QNAP

### Method 1: Docker Compose (CLI)

```bash
cd /share/Container/n8n-docker
docker-compose up -d
docker logs -f n8n
```

### Method 2: Container Station (GUI)

1. Open **Container Station**
2. **Create** → **Create Application**
3. Paste contents of `docker-compose.yml`
4. Adjust paths and variables if needed
5. **Validate** → **Create**

## 🔧 Configuration

### Important Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `N8N_PORT` | `5678` | Web interface port |
| `WEBHOOK_URL` | `http://10.8.0.1:5678` | Base URL for webhooks (adjust to your IP) |
| `GENERIC_TIMEZONE` | `Europe/Madrid` | Timezone |
| `LD_PRELOAD` | (empty) | **CRITICAL**: Disables jemalloc to prevent crashes |
| `N8N_BASIC_AUTH_ACTIVE` | `false` | Enable basic authentication |

### QNAP Reverse Proxy

If using QNAP's reverse proxy:

1. **Control Panel** → **Applications** → **Proxy Server**
2. **Create**:
   - Name: `n8n`
   - Source: `localhost:5678`
   - Hostname: `n8n-nas.yourdomain.com`
   - HTTPS: Enable if you have a certificate

## ⚠️ Known Issues (Solved)

| Issue | Solution Applied |
|-------|------------------|
| **Error 139 (Segmentation fault)** | ✅ Recompilation with `LDFLAGS=-Wl,-z,max-page-size=32768` + `LD_PRELOAD=` |
| **ModuleNotFoundError: distutils** | ✅ No longer applies (using Debian Bullseye with Python 3) |
| **mdns module fails in QEMU** | ✅ Explicitly removed before `npm rebuild` |
| **Insufficient RAM during build** | ✅ Cross-compilation from external PC (16GB RAM) |
| **Python Task Runner warnings** | ℹ️ Normal - n8n looks for internal Python (doesn't affect JS functionality) |

## 🐛 Troubleshooting

### Error 139 (Segmentation Fault)

**Symptom:**
```
Segmentation fault (core dumped)
Error: Process completed with exit code 139
```

**Solution:** This image already includes the fix. If you still see this error:
- Verify you're using this custom image (not official n8n)
- Check `LD_PRELOAD=` is set (empty value)

### Python Task Runner Warnings

**Symptom:**
```
Failed to start Python task runner in internal mode because Python 3 is missing
Task runner connection attempt failed with status code 403
```

**Is it critical?** No. Only affects workflows that need to execute Python code.

**Solution:**
- **Option 1:** Ignore - most workflows use JavaScript only
- **Option 2:** Configure external Task Runner ([official guide](https://docs.n8n.io/code/python-in-n8n/))

### n8n Won't Start / Restarts Continuously

**Check logs:**
```bash
docker logs n8n
```

**Common fixes:**

1. **Incorrect permissions:**
   ```bash
   chown -R 1000:1000 /share/Container/n8ndata
   ```

2. **Port already in use:**
   ```bash
   netstat -tulpn | grep 5678
   docker ps -a | grep 5678
   ```

3. **Insufficient RAM:**
   ```bash
   # Stop other containers or limit RAM
   docker-compose down
   # Edit docker-compose.yml and add memory limits
   ```

### Can't Access from Outside LAN

**For VPN access:**
- Update `WEBHOOK_URL` to your VPN IP (e.g., `10.8.0.1:5678`)

**For external access:**
- Option 1: Cloudflare Tunnel ([guide](https://docs.n8n.io/hosting/installation/server-setups/cloudflare-tunnel/))
- Option 2: QNAP Reverse Proxy + DuckDNS

### Verify 32k Compilation

```bash
docker exec -it n8n /bin/bash -c "readelf -l /usr/local/lib/node_modules/n8n/node_modules/better-sqlite3/build/Release/better_sqlite3.node | grep LOAD"
```

Should show `Align` value of `0x8000` (32768 in hexadecimal).

## 🔄 Update to New n8n Version

```bash
# On your Linux Mint/Ubuntu
cd n8n-qnap-armv7
git pull

# Build new version
docker buildx build \\
  --platform linux/arm/v7 \\
  -t javiocu/n8n-armv7-qnap431-3p:$(date +%Y%m%d) \\
  -t javiocu/n8n-armv7-qnap431-3p:latest \\
  --push .

# On NAS
docker-compose pull
docker-compose up -d
docker logs -f n8n
```

## 📊 Performance

**Test Hardware:** QNAP TS-431P3 (Alpine AL314, 4GB RAM)

- **Boot time:** ~15-20 seconds
- **RAM usage:** 200-400MB (idle, no active workflows)
- **Build time:** 15-25 minutes (from i5-7500 with 16GB RAM)

## 🤝 Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feature/improvement`
3. Commit: `git commit -am 'Add improvement'`
4. Push: `git push origin feature/improvement`
5. Open a Pull Request

## 📚 References

- [Official n8n Documentation](https://docs.n8n.io/)
- [n8n on GitHub](https://github.com/n8n-io/n8n)
- [QNAP Forum](https://forum.qnap.com/)
- [Docker Hub Repository](https://hub.docker.com/r/javiocu/n8n-armv7-qnap431-3p)

## 📄 License

Apache 2.0 - Based on [official n8n](https://github.com/n8n-io/n8n) (Fair-code - Sustainable Use License)

## 🙏 Credits

Developed to solve specific issues with QNAP TS-431P3 running Alpine AL314 (ARMv7 32KB pagesize).

**Tested on:**
- QNAP TS-431P3
- QTS 5.2.5.3145
- Alpine AL314 CPU (ARMv7 32-bit)
- 4GB RAM

---

⭐ **If this project helped you, give it a star on GitHub!**

💬 **Having issues?** Open an issue with detailed logs and system info.

🔗 **Docker Hub:** [javiocu/n8n-armv7-qnap431-3p](https://hub.docker.com/r/javiocu/n8n-armv7-qnap431-3p)
