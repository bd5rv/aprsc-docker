# aprsc - APRS-IS Server in Docker

[![Docker Image Size](https://img.shields.io/docker/image-size/bd5rv/aprsc/latest)](https://hub.docker.com/r/bd5rv/aprsc)
[![Docker Pulls](https://img.shields.io/docker/pulls/bd5rv/aprsc)](https://hub.docker.com/r/bd5rv/aprsc)
[![GitHub](https://img.shields.io/badge/github-aprsc--docker-blue)](https://github.com/bd5rv/aprsc-docker)

Lightweight, production-ready Docker image for [aprsc](https://github.com/hessu/aprsc) - a high-performance APRS-IS (Automatic Packet Reporting System - Internet Service) server.

## ✨ Features

- **🪶 Ultra-compact**: Only **4.8 MB** download (11.2 MB uncompressed)
- **🏗️ Multi-architecture**: Native support for **AMD64, ARM64, and ARMv7** (Raspberry Pi ready!)
- **⚡ Zero-configuration**: Run without config files using environment variables
- **🔒 Secure**: Runs as non-root user with minimal Alpine Linux base
- **🌐 Complete**: Full APRS-IS server with web monitoring interface
- **📊 Production-ready**: Health checks, resource limits, and proper signal handling
- **🔧 Flexible**: Support for both environment variables and configuration files

## 🚀 Quick Start

### Run with defaults

```bash
docker run -d \
  -p 14580:14580 \
  -p 14501:14501 \
  bd5rv/aprsc:latest
```

Access web interface at **http://localhost:14501/**

### Run with custom callsign

```bash
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  -p 14501:14501 \
  bd5rv/aprsc:latest
```

Get your passcode at: https://apps.magicbug.co.uk/passcode/

## 📦 Available Tags

- `latest` - Latest stable release
- `2.1.19-g6d55570` - Specific version with git hash
- `2.1.19` - Semantic version
- `2.1` - Major.minor version
- `2` - Major version

## 🏗️ Multi-Architecture Support

This image supports multiple CPU architectures with **automatic platform detection**:

| Architecture | Platform | Devices |
|--------------|----------|---------|
| **AMD64** | `linux/amd64` | Intel/AMD servers, desktops, laptops |
| **ARM64** | `linux/arm64` | Raspberry Pi 4/5, ARM servers, Apple Silicon |
| **ARMv7** | `linux/arm/v7` | Raspberry Pi 2/3, older ARM devices |

### Automatic Detection

Docker automatically selects the correct architecture for your device:

```bash
# On x86-64 server - pulls AMD64 image
docker pull bd5rv/aprsc:latest

# On Raspberry Pi 4 - pulls ARM64 image automatically
docker pull bd5rv/aprsc:latest

# On Raspberry Pi 3 - pulls ARMv7 image automatically
docker pull bd5rv/aprsc:latest
```

### Raspberry Pi Quick Start

Perfect for APRS iGate on Raspberry Pi:

```bash
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  -p 14501:14501 \
  --restart unless-stopped \
  bd5rv/aprsc:latest

# Verify architecture
docker exec <container> uname -m
# Raspberry Pi 4/5: aarch64 (ARM64)
# Raspberry Pi 2/3: armv7l (ARMv7)
```

**See**: [Multi-Architecture Guide](https://github.com/bd5rv/aprsc-docker/blob/main/MULTI_ARCH.md)

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_SERVER_ID` | `NOCALL` | Your amateur radio callsign |
| `APRSC_PASSCODE` | `-1` | Server passcode (read-only with -1) |
| `APRSC_MY_ADMIN` | `Docker User` | Administrator name |
| `APRSC_MY_EMAIL` | `root@localhost` | Administrator email |
| `APRSC_UPLINK_ENABLED` | `no` | Enable upstream APRS-IS connection |
| `APRSC_UPLINK_SERVER` | `rotate.aprs2.net` | Upstream server address |
| `APRSC_IGATE_PORT` | `14580` | Client port |
| `APRSC_HTTP_STATUS_PORT` | `14501` | Web monitoring port |

**See full list**: [Environment Variables Guide](https://github.com/bd5rv/aprsc-docker/blob/main/ENVIRONMENT.md)

### Using Configuration File

```bash
docker run -d \
  -v ./aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  -p 14580:14580 \
  -p 14501:14501 \
  bd5rv/aprsc:latest
```

## 🌐 Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 14580 | TCP/UDP | APRS-IS client port (filtered) |
| 10152 | TCP/UDP | Full feed port (unfiltered) |
| 8080 | UDP | UDP packet submission |
| 8080 | TCP | HTTP position upload |
| 14501 | TCP | Web status monitoring |

## 🐳 Docker Compose Example

```yaml
version: '3.8'

services:
  aprsc:
    image: bd5rv/aprsc:latest
    container_name: aprsc
    restart: unless-stopped
    environment:
      - APRSC_SERVER_ID=YOUR-CALL
      - APRSC_PASSCODE=12345
      - APRSC_MY_ADMIN=Your Name
      - APRSC_MY_EMAIL=you@example.com
      - APRSC_UPLINK_ENABLED=yes
      - APRSC_UPLINK_SERVER=rotate.aprs2.net
    ports:
      - "14580:14580"
      - "14501:14501"
    volumes:
      - ./logs:/var/log/aprsc
      - aprsc-data:/var/run/aprsc/data
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://127.0.0.1:14501/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  aprsc-data:
```

## 🔗 Connecting to APRS-IS Network

### Read-Only Mode (No Authentication)

```bash
docker run -d \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_TYPE=ro \
  -p 14580:14580 \
  -p 14501:14501 \
  bd5rv/aprsc:latest
```

### Full Access Mode (With Authentication)

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_TYPE=full \
  -e APRSC_UPLINK_SERVER=asia.aprs2.net \
  -p 14580:14580 \
  -p 14501:14501 \
  bd5rv/aprsc:latest
```

### Available Upstream Servers

- `rotate.aprs2.net` - Global round-robin (recommended)
- `asia.aprs2.net` - Asia region
- `euro.aprs2.net` - Europe region
- `noam.aprs2.net` - North America region

## 🧪 Testing Connection

Test with telnet:

```bash
telnet localhost 14580
```

Then login:
```
user TEST pass -1 vers test 1.0
```

You should see APRS packets streaming immediately.

**See**: [Testing Guide](https://github.com/bd5rv/aprsc-docker/blob/main/TESTING.md)

## 📊 Monitoring

### Web Interface

Open **http://localhost:14501/** in your browser to see:
- Server runtime status
- Connected clients list
- Traffic statistics
- Uplink status

### JSON API

```bash
curl http://localhost:14501/status.json
```

### Health Check

```bash
docker ps
# Look for "(healthy)" in STATUS column
```

## 🎯 Use Cases

- **APRS iGate**: Receive RF packets and gate to APRS-IS
- **APRS Server**: Provide filtered feeds to APRS clients
- **APRS Hub**: Central hub for local APRS network
- **Testing/Development**: Test APRS applications locally
- **Read-Only Feed**: Monitor APRS traffic without transmitting

## 💻 System Requirements

**Minimal:**
- CPU: 0.5 cores
- RAM: 128 MB
- Disk: ~15 MB

**Supported Platforms:**
- **x86-64** (AMD64) - Intel/AMD servers and desktops
- **ARM64** (aarch64) - Raspberry Pi 4/5, ARM servers, Apple Silicon
- **ARMv7** (armv7l) - Raspberry Pi 2/3, older ARM devices

**All platforms tested and production-ready!**

## 📚 Documentation

- **GitHub Repository**: https://github.com/bd5rv/aprsc-docker
- **Multi-Architecture Guide**: https://github.com/bd5rv/aprsc-docker/blob/main/MULTI_ARCH.md
- **Environment Variables**: https://github.com/bd5rv/aprsc-docker/blob/main/ENVIRONMENT.md
- **Testing Guide**: https://github.com/bd5rv/aprsc-docker/blob/main/TESTING.md
- **aprsc Official**: http://he.fi/aprsc/
- **APRS-IS Network**: http://www.aprs-is.net/

## ⚠️ Important Notes

### Default Configuration Warning

When running with default settings, you'll see:

```
WARNING: Using default callsign 'NOCALL'
WARNING: Using invalid passcode
```

This is normal for testing. For production use, set `APRSC_SERVER_ID` and `APRSC_PASSCODE`.

### POSIX Capabilities Warning

You may see:

```
aprsc: Failed to apply initial POSIX capabilities: Operation not permitted
```

This is **normal and can be safely ignored**. The container still works perfectly. See [FAQ](https://github.com/bd5rv/aprsc-docker#troubleshooting) for details.

## 🛠️ Troubleshooting

### No data received?

1. Check uplink is enabled: `APRSC_UPLINK_ENABLED=yes`
2. Verify uplink connection: `curl http://localhost:14501/status.json | jq '.uplinks'`
3. Check logs: `docker logs <container-name>`

### Web interface shows 404?

1. Ensure port 14501 is exposed
2. Check health status: `docker ps`
3. Verify with: `curl http://localhost:14501/`

### Port conflicts?

Change host port mapping:
```bash
docker run -p 24580:14580 ...
```

## 📄 License

- **aprsc**: Licensed under its original license
- **Docker configuration**: MIT License

## 🤝 Contributing

Issues and Pull Requests welcome at: https://github.com/bd5rv/aprsc-docker

## 🏷️ Version Information

This image is based on:
- **aprsc**: v2.1.19-g6d55570
- **Alpine Linux**: 3.20
- **Image Size**: 4.8 MB (download) / 11.2 MB (uncompressed)

---

**Built with ❤️ for the Amateur Radio community**

*For detailed documentation, visit the [GitHub repository](https://github.com/bd5rv/aprsc-docker)*

Enjoy! 73!
de BD5RV
