# aprsc Docker

[English](README.md) | [中文](README.zh-CN.md)

This is a Docker configuration for running [aprsc](https://github.com/hessu/aprsc) (APRS-IS server).

## Features

- **Ultra-compact Image**: Only 4.8 MB download size (11.2 MB uncompressed)
- **Zero-Configuration**: Runs without config file using environment variables
- **Environment Variable Support**: All settings configurable via environment variables with sensible defaults
- **Multi-stage Build**: Both stages based on Alpine Linux for optimal compatibility
- **Secure Execution**: Runs as non-root user (aprsc)
- **Complete Features**: Includes web monitoring interface and all APRS-IS functionality
- **Easy Deployment**: Supports Docker Compose and Makefile

## Quick Start

### Use Pre-built Image from Docker Hub (Recommended)

The fastest way to get started - pull the ready-to-use image from Docker Hub:

```bash
# Pull the latest image
docker pull bd5rv/aprsc:latest

# Run with default settings
docker run -d \
  -p 14580:14580 \
  -p 14501:14501 \
  --name aprsc \
  bd5rv/aprsc:latest

# Or run with your callsign and passcode
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  -p 14501:14501 \
  --name aprsc \
  bd5rv/aprsc:latest
```

**Access web interface at:** http://localhost:14501/

**Available tags:**
- `latest` - Latest stable release
- `2.1.19-g6d55570` - Specific version with git hash
- `2.1.19` - Semantic version
- `2.1` - Major.minor version
- `2` - Major version

**Docker Hub:** https://hub.docker.com/r/bd5rv/aprsc

**Using Docker Compose with Hub image:**

```bash
# Use the pre-built image with Docker Compose
docker compose -f docker-compose.hub.yml up -d
```

See `docker-compose.hub.yml` for the full configuration example.

### Build from Source (Alternative)

If you prefer to build the image yourself:

```bash
# Pull and run (uses default values)
docker compose up -d

# Or with custom environment variables
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

The container will:
- ✅ Start immediately without any configuration file
- ✅ Use sensible defaults for all settings
- ✅ Show warnings to remind you to set your callsign and passcode

**See [ENVIRONMENT.md](ENVIRONMENT.md) for all available environment variables and examples.**

## Multi-Architecture Support

The aprsc Docker image supports multiple CPU architectures with **automatic platform detection**:

| Architecture | Platform | Description | Devices |
|--------------|----------|-------------|---------|
| **AMD64** | `linux/amd64` | 64-bit x86 processors | Intel/AMD servers, desktops, laptops |
| **ARM64** | `linux/arm64` | 64-bit ARM processors (ARMv8) | Raspberry Pi 4/5, ARM servers, Apple Silicon |
| **ARMv7** | `linux/arm/v7` | 32-bit ARM processors (ARMv7) | Raspberry Pi 2/3, older ARM devices |

### Automatic Platform Detection

Docker automatically selects the correct architecture for your device:

```bash
# On x86-64 server - pulls AMD64 image
docker pull bd5rv/aprsc:latest

# On Raspberry Pi 4 - pulls ARM64 image
docker pull bd5rv/aprsc:latest

# On Raspberry Pi 3 - pulls ARMv7 image
docker pull bd5rv/aprsc:latest
```

No special configuration needed!

### Raspberry Pi Usage

Perfect for APRS iGate on Raspberry Pi:

```bash
# Pull and run (automatic architecture detection)
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  -p 14501:14501 \
  --name aprsc \
  --restart unless-stopped \
  bd5rv/aprsc:latest

# Verify architecture
docker exec aprsc uname -m
# Raspberry Pi 4/5: aarch64 (ARM64)
# Raspberry Pi 2/3: armv7l (ARMv7)
```

### Platform-Specific Pulls

Force a specific architecture (useful for testing):

```bash
# Force AMD64 on any host
docker pull --platform linux/amd64 bd5rv/aprsc:latest

# Force ARM64 on any host
docker pull --platform linux/arm64 bd5rv/aprsc:latest

# Force ARMv7 on any host
docker pull --platform linux/arm/v7 bd5rv/aprsc:latest
```

**See [MULTI_ARCH.md](MULTI_ARCH.md) for detailed multi-architecture documentation, build instructions, and troubleshooting.**

### Advanced: Using Configuration File (Optional)

If you prefer to use a configuration file, you can create the `aprsc.conf` file. You can extract the example configuration from the built image:

```bash
# Build the image
docker compose build

# Extract example configuration
docker run --rm aprsc-docker-aprsc cat /etc/aprsc/aprsc.conf.example > aprsc.conf
```

Or download the example configuration from GitHub:

```bash
wget -O aprsc.conf https://raw.githubusercontent.com/hessu/aprsc/master/src/aprsc.conf
```

### 2. Edit Configuration File

Edit the `aprsc.conf` file, **the following items must be configured**:

#### Basic Configuration

```conf
# Your server callsign
ServerId YOUR-CALLSIGN

# Server passcode (get from https://apps.magicbug.co.uk/passcode/)
PassCode 12345

# Administrator information
MyAdmin "Your Name, YOUR-CALLSIGN"
MyEmail your.email@example.com

# Run directory (must use absolute path)
RunDir /var/run/aprsc
```

#### Listening Port Configuration

```conf
# Full feed port
Listen "Full feed"              fullfeed tcp ::  10152
Listen ""                       fullfeed udp ::  10152

# Client filter port
Listen "Client-Defined Filters" igate tcp ::  14580
Listen ""                       igate udp ::  14580

# UDP packet submission port
Listen "UDP submit"             udpsubmit udp :: 8080

# HTTP status page
HTTPStatus 0.0.0.0 14501

# HTTP position upload
HTTPUpload 0.0.0.0 8080
```

#### Important Reminder

⚠️ **Delete Test Directive**: The configuration file contains a deliberate error directive `MagicBadness` (usually on line 124), you must delete or comment it out to start the service:

```conf
# Delete or comment out this line:
# MagicBadness	42.7
```

### 3. Start Service

Using Docker Compose:

```bash
docker compose up -d
```

Or using Docker directly:

```bash
docker build -t aprsc-docker-aprsc .
docker run -d \
  --name aprsc \
  -p 14580:14580 \
  -p 10152:10152 \
  -p 8080:8080/udp \
  -p 8080:8080/tcp \
  -p 14501:14501 \
  -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  -v $(pwd)/logs:/var/log/aprsc \
  --restart unless-stopped \
  aprsc-docker-aprsc
```

### 4. Check Status

#### Web Monitoring Interface

Open browser and visit: **http://localhost:14501/**

You will see the complete aprsc status monitoring page, including:
- Server runtime status
- Connected client list
- Traffic statistics
- Uplink status

#### View Logs

```bash
# Using docker compose
docker compose logs -f

# Or using docker
docker logs -f aprsc

# View persistent log files
tail -f logs/aprsc.log
```

## Using Makefile (Recommended)

The project provides a Makefile to simplify common operations:

### Complete Deployment Process

```bash
# One-click deployment (automatically extracts configuration file template)
make deploy

# Edit configuration file (remember to delete the MagicBadness line!)
vim aprsc.conf

# Start service
make run
```

### Common Commands

```bash
# Build image
make build

# Start container (using docker compose)
make run

# Stop container
make stop

# View logs (real-time)
make logs

# Enter container shell
make shell

# Extract example configuration file (won't overwrite existing file)
make config-example

# Clean up containers, volumes and images
make clean
```

### Typical Workflow

```bash
# 1. Initial deployment
make deploy          # Get configuration file template
vim aprsc.conf       # Edit configuration (delete MagicBadness!)
make run             # Start service

# 2. Verify running
make logs            # View logs
# Visit http://localhost:14501/ in browser

# 3. Daily operations
make stop            # Stop service
make run             # Restart service

# 4. Complete cleanup
make clean           # Clean up all resources
```

## Port Description

Default exposed ports:

| Port | Protocol | Purpose | Description |
|------|----------|---------|-------------|
| **14580** | TCP/UDP | APRS-IS Client Port | User-defined filters |
| **10152** | TCP/UDP | APRS-IS Full Feed Port | Complete data stream |
| **8080** | UDP | UDP Packet Submission | For receiving APRS packets |
| **8080** | TCP | HTTP Position Upload | Upload position via HTTP POST |
| **14501** | TCP | Web Status Monitoring | Real-time server status view |

Adjust the ports to expose according to your configuration file.

## Directory Structure

```
aprsc-docker/
├── Dockerfile           # Docker build file
├── docker-compose.yml   # Docker Compose configuration
├── Makefile            # Convenient command collection
├── aprsc.conf          # aprsc configuration file (need to create yourself)
├── aprsc.conf.template # Configuration file template (optional)
├── README.md           # This file (English)
├── README.zh-CN.md     # Chinese version
└── logs/               # Log directory (auto-created)
```

## Image Size

The final Docker image is extremely compact:

- **Runtime image**: **11.2 MB** 🎉
- Build stage image: ~370 MB (discarded after build)

### Size Breakdown

| Component | Size | Description |
|-----------|------|-------------|
| Alpine Linux base | 8.44 MB | Minimal Linux distribution |
| aprsc binary & web files | 1.78 MB | Server program and monitoring interface |
| Runtime dependencies | 981 KB | libevent, openssl, libcap, tini |
| Configuration & user | ~8 KB | Config template and user setup |

### Why So Small?

- **Alpine Linux**: Uses musl libc instead of glibc, base image only 8.44 MB
- **Multi-stage build**: Build tools (gcc, make, etc.) not included in final image
- **Minimal dependencies**: Only runtime-required libraries installed
- **Efficient compilation**: aprsc is a well-optimized C program

This makes the image ideal for:
- 🚀 Fast deployment and distribution
- 💾 Resource-constrained environments
- 🌐 Edge devices and Raspberry Pi
- ⚡ Quick container startup

## Advanced Configuration

### Custom Build Parameters

If you need to modify installation paths and other parameters, edit the `configure` options in the Dockerfile:

```dockerfile
RUN ./configure \
        --prefix=/opt/aprsc \
        --sysconfdir=/etc/aprsc \
        --localstatedir=/var
```

### Performance Optimization

Resource limit configurations are already included in `docker-compose.yml`, adjust as needed:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 128M
```

### Connect to Upstream Server

If your server needs to connect to the APRS-IS core network, uncomment and configure the upstream server in the configuration file:

```conf
# Connect to core rotate address (recommended)
Uplink "Core rotate" full tcp rotate.aprs.net 10152

# Or read-only mode
# Uplink "Core rotate" ro tcp rotate.aprs.net 10152
```

### Network Configuration

If you need to use host network mode (better performance, but directly exposes all ports):

```bash
docker run -d \
  --name aprsc \
  --network host \
  -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  aprsc-docker-aprsc
```

## Troubleshooting

### Container Exits Immediately After Starting

**Symptoms**: Container keeps restarting, logs show configuration errors.

**Cause**: The `MagicBadness` test directive in the configuration file was not deleted.

**Solution**:

```bash
# Edit configuration file
vim aprsc.conf

# Delete or comment out the line containing MagicBadness (usually line 124)
# MagicBadness	42.7

# Restart container
docker compose restart
```

### Web Monitoring Page Shows 404

**Symptoms**: Visiting http://localhost:14501/ shows 404 Not Found.

**Cause**: Web file path not properly mapped.

**Solution**:

```bash
# Check if symlink exists in container
docker compose exec aprsc ls -la /var/run/aprsc/web

# If not exists, rebuild image
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Configuration File Error

If startup fails, you can verify the configuration file syntax:

```bash
docker run --rm -v $(pwd)/aprsc.conf:/etc/aprsc/aprsc.conf:ro aprsc-docker-aprsc \
  /opt/aprsc/sbin/aprsc -c /etc/aprsc/aprsc.conf -y
```

### Permission Issues

Ensure the log directory has correct permissions:

```bash
chmod 755 logs
```

### "No such file or directory" Error (Exit 127)

**Symptoms**: Container startup fails with error message:
```
[FATAL tini (7)] exec /opt/aprsc/sbin/aprsc failed: No such file or directory
aprsc exited with code 127
```

**Cause**: This is usually due to binary file incompatibility with the runtime environment (glibc vs musl libc).

**Solution**: This project has fixed this issue. If encountered, ensure:
1. Use the latest Dockerfile (both stages use Alpine)
2. Rebuild image: `docker compose build --no-cache`

### Port Conflicts

If you encounter port already in use errors, modify the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "24580:14580"  # Change host port to 24580
```

## Monitoring and Maintenance

### View Server Statistics

Access JSON API for detailed statistics:

```bash
curl http://localhost:14501/status.json | jq
```

### Log Rotation

Log rotation is already enabled in the configuration file:

```conf
LogRotate 10 5  # Keep 5 log files of 10MB each
```

### Health Check

Add health check to `docker-compose.yml`:

```yaml
healthcheck:
  test: ["CMD", "nc", "-z", "localhost", "14580"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Testing Connections

See [TESTING.md](TESTING.md) for detailed guide on:
- Testing APRS-IS connections with telnet
- Using filters (geographic, callsign, type)
- Testing script usage
- Common issues and solutions

Quick test:
```bash
./test-aprs-connection.sh localhost 14580 YOUR-CALL
```

## Reference Documentation

- [TESTING.md](TESTING.md) - Connection testing guide
- [ENVIRONMENT.md](ENVIRONMENT.md) - Environment variables guide
- [aprsc Official Documentation](http://he.fi/aprsc/)
- [aprsc GitHub](https://github.com/hessu/aprsc)
- [APRS-IS Protocol](http://www.aprs-is.net/)
- [APRS Passcode Generator](https://apps.magicbug.co.uk/passcode/)

## Technical Details

### Build Architecture

- **Stage 1 (builder)**: Compile aprsc on Alpine Linux
- **Stage 2 (runtime)**: Copy compiled binaries to clean Alpine Linux image
- Uses `tini` as init process to ensure proper signal handling
- Creates symlinks for proper web file access

### Security

- Runs service as unprivileged user `aprsc`
- Configuration file mounted as read-only
- Supports POSIX capabilities for binding low ports

## Contributing

Issues and Pull Requests are welcome!

## License

- aprsc software follows its original license
- This Docker configuration is licensed under MIT License
