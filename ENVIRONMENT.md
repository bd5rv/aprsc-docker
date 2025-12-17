# Environment Variables Configuration

[English](ENVIRONMENT.md) | [中文](ENVIRONMENT.zh-CN.md)

aprsc Docker supports configuration through environment variables, making it easy to run without a configuration file.

## Quick Start

Run without any configuration (uses all defaults):

```bash
docker run -d -p 14580:14580 -p 14501:14501 aprsc-docker-aprsc
```

Run with custom callsign and passcode:

```bash
docker run -d \
  -e APRSC_SERVER_ID=YOUR-CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 -p 14501:14501 \
  aprsc-docker-aprsc
```

## Configuration Priority

1. **Configuration File** (if mounted at `/etc/aprsc/aprsc.conf`)
2. **Environment Variables**
3. **Default Values**

## Available Environment Variables

### Server Identification

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_SERVER_ID` | `NOCALL` | Your amateur radio callsign (REQUIRED for production) |
| `APRSC_PASSCODE` | `-1` | Server passcode (get from https://apps.magicbug.co.uk/passcode/) |
| `APRSC_MY_ADMIN` | `Docker User` | Administrator name |
| `APRSC_MY_EMAIL` | `root@localhost` | Administrator email |

### Directories

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_RUN_DIR` | `/var/run/aprsc` | Runtime data directory |

### Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_LOG_ROTATE` | `10 5` | Log rotation: "megabytes filecount" |

### Timeouts

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_UPSTREAM_TIMEOUT` | `15s` | Upstream server timeout |
| `APRSC_CLIENT_TIMEOUT` | `48h` | Client connection timeout |

### Resource Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_MAX_CLIENTS` | `500` | Maximum simultaneous clients |
| `APRSC_FILE_LIMIT` | `10000` | Maximum open files |

### Listeners

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_ENABLE_FULL_FEED` | `yes` | Enable full feed port |
| `APRSC_FULL_FEED_PORT` | `10152` | Full feed port number |
| `APRSC_ENABLE_IGATE` | `yes` | Enable iGate/client port |
| `APRSC_IGATE_PORT` | `14580` | iGate/client port number |
| `APRSC_ENABLE_UDP_SUBMIT` | `yes` | Enable UDP packet submission |
| `APRSC_UDP_SUBMIT_PORT` | `8080` | UDP submission port number |

### HTTP Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_HTTP_STATUS_PORT` | `14501` | HTTP status page port |
| `APRSC_HTTP_UPLOAD_PORT` | `8080` | HTTP position upload port |

### Uplink Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `APRSC_UPLINK_ENABLED` | `no` | Enable connection to upstream server |
| `APRSC_UPLINK_SERVER` | `rotate.aprs2.net` | Upstream server address |
| `APRSC_UPLINK_PORT` | `10152` | Upstream server port |
| `APRSC_UPLINK_TYPE` | `full` | Uplink type: `full` or `ro` (read-only) |

## Usage Examples

### Minimal Configuration

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### With Uplink Connection

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_SERVER=rotate.aprs2.net \
  -e APRSC_UPLINK_PORT=10152 \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### Read-Only Mode

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=-1 \
  -e APRSC_UPLINK_ENABLED=yes \
  -e APRSC_UPLINK_TYPE=ro \
  -p 14580:14580 \
  -p 14501:14501 \
  aprsc-docker-aprsc
```

### Custom Ports

```bash
docker run -d \
  -e APRSC_SERVER_ID=N0CALL \
  -e APRSC_PASSCODE=12345 \
  -e APRSC_IGATE_PORT=24580 \
  -e APRSC_HTTP_STATUS_PORT=24501 \
  -p 24580:24580 \
  -p 24501:24501 \
  aprsc-docker-aprsc
```

### Using .env File

1. Copy the example file:
```bash
cp .env.example .env
```

2. Edit `.env` with your configuration:
```bash
vim .env
```

3. Run with docker-compose (automatically loads `.env`):
```bash
docker-compose up -d
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  aprsc:
    image: aprsc-docker-aprsc
    environment:
      - APRSC_SERVER_ID=N0CALL
      - APRSC_PASSCODE=12345
      - APRSC_MY_ADMIN=Your Name
      - APRSC_MY_EMAIL=you@example.com
      - APRSC_UPLINK_ENABLED=yes
    ports:
      - "14580:14580"
      - "14501:14501"
    volumes:
      - ./logs:/var/log/aprsc
    restart: unless-stopped
```

## Viewing Generated Configuration

To see the generated configuration:

```bash
docker exec <container-name> cat /etc/aprsc/aprsc.conf
```

## Warnings

When using default values, you'll see warnings:

```
WARNING: Using default callsign 'NOCALL'
Please set APRSC_SERVER_ID environment variable to your callsign

WARNING: Using invalid passcode
Please set APRSC_PASSCODE environment variable
Generate at: https://apps.magicbug.co.uk/passcode/
```

These are reminders to configure the server properly for production use.

## Mixing Configuration Methods

You can combine configuration file and environment variables:

1. **Mount a partial configuration file** with basic settings
2. **Override specific values** using environment variables
3. **Configuration file takes precedence** over environment variables

Example:
```bash
docker run -d \
  -v ./aprsc.conf:/etc/aprsc/aprsc.conf:ro \
  -e APRSC_UPLINK_ENABLED=yes \
  -p 14580:14580 \
  aprsc-docker-aprsc
```

In this case, the mounted `aprsc.conf` will be used, and environment variables are ignored.
