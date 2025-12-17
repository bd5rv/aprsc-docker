# APRS-IS Connection Testing Guide

[English](TESTING.md) | [中文](TESTING.zh-CN.md)

This guide shows how to test APRS-IS connections using telnet and other tools.

## Quick Test

### Test Local aprsc Server

```bash
# Use the test script
./test-aprs-connection.sh localhost 14580 N0CALL

# Or manually
telnet localhost 14580
```

After connecting, enter:
```
user N0CALL pass -1 vers test 1.0
```

You should see APRS data streaming.

## Connection Parameters

### Login String Format

```
user <callsign> pass <passcode> vers <software> <version> [filter <filter>]
```

**Parameters:**
- `callsign`: Your amateur radio callsign (use any for testing)
- `passcode`:
  - `-1` for read-only access
  - Valid passcode for full access (get from https://apps.magicbug.co.uk/passcode/)
- `software`: Name of your software
- `version`: Version number
- `filter`: (optional) Data filter

### Common Ports

| Port | Type | Description |
|------|------|-------------|
| 14580 | TCP | Standard client port (filtered) |
| 10152 | TCP | Full feed port (unfiltered) |
| 8080 | UDP | Packet submission |

## Testing Scenarios

### 1. Test Local Server (Read-Only)

```bash
telnet localhost 14580
```

Login:
```
user TEST pass -1 vers telnet-test 1.0
```

### 2. Test with Geographic Filter

```bash
telnet localhost 14580
```

Login with filter:
```
user TEST pass -1 vers telnet-test 1.0 filter r/35.6/139.7/100
```

This receives packets within 100km of Tokyo (35.6°N, 139.7°E).

### 3. Test with Callsign Filter

```bash
telnet localhost 14580
```

Login:
```
user TEST pass -1 vers telnet-test 1.0 filter b/CALLSIGN1/CALLSIGN2
```

This receives packets only from specified callsigns.

### 4. Test Upstream Server

```bash
# Test connecting to upstream APRS-IS server
telnet rotate.aprs2.net 14580
```

Login:
```
user N0CALL pass -1 vers test 1.0
```

### 5. Test Full Feed Port

```bash
telnet localhost 10152
```

Login:
```
user TEST pass -1 vers test 1.0
```

Note: Full feed sends ALL packets (high volume).

## Filter Types

### Range Filter (Geographic)
```
filter r/lat/lon/radius
```
Example: `filter r/35.6/139.7/100` (100km around Tokyo)

### Buddy Filter (Callsign)
```
filter b/CALL1/CALL2/CALL3
```
Example: `filter b/N0CALL/W1AW` (only these callsigns)

### Prefix Filter
```
filter p/PREFIX1/PREFIX2
```
Example: `filter p/CQ/JA` (callsigns starting with CQ or JA)

### Type Filter
```
filter t/poimqstunw
```
- `p` = position
- `o` = objects
- `i` = items
- `m` = message
- `q` = query
- `s` = status
- `t` = telemetry
- `u` = user-defined
- `n` = NWS format
- `w` = weather

### Entry Station Filter
```
filter e/CALL1/CALL2
```
Only packets entered via specified igates.

### Group Filter
```
filter g/GROUP
```
Example: `filter g/TELEM` (telemetry groups)

## Using the Test Script

### Basic Usage

```bash
# Test local server
./test-aprs-connection.sh

# Test specific server and port
./test-aprs-connection.sh rotate.aprs2.net 14580

# Test with custom callsign
./test-aprs-connection.sh localhost 14580 YOUR-CALL
```

### Interactive Testing

After connecting, you can type filter commands:
```
filter r/35.6/139.7/100
filter b/N0CALL
filter p/JA
```

Press Ctrl+C to exit.

## Testing with netcat (nc)

Alternative to telnet:

```bash
echo "user TEST pass -1 vers test 1.0" | nc localhost 14580
```

With timeout:
```bash
echo "user TEST pass -1 vers test 1.0" | nc -w 10 localhost 14580
```

## Verify Server is Working

### Check if server is accepting connections

```bash
nc -zv localhost 14580
nc -zv localhost 10152
nc -zv localhost 14501
```

### Check HTTP status page

```bash
curl http://localhost:14501/
curl http://localhost:14501/status.json
```

### Check with wget

```bash
wget -qO- http://localhost:14501/status.json | jq
```

## Common Issues

### Connection Refused

**Symptom:** `Connection refused` or `Unable to connect`

**Solutions:**
1. Check if container is running: `docker ps`
2. Check if port is exposed: `docker port aprsc`
3. Check firewall settings
4. Verify port in configuration

### No Data After Login

**Symptom:** Login successful but no packets received

**Solutions:**
1. Check if uplink is enabled: `APRSC_UPLINK_ENABLED=yes`
2. Verify uplink configuration in logs: `docker logs aprsc`
3. Try full feed port (10152) instead of filtered port
4. Check server has active uplink connection

### Invalid Passcode

**Symptom:** `Login failed` or `Invalid passcode`

**Solutions:**
1. Use `-1` for read-only access (no validation needed)
2. Generate valid passcode at https://apps.magicbug.co.uk/passcode/
3. Check callsign spelling

## Expected Output

### Successful Connection

```
$ telnet localhost 14580
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
# aprsc 2.1.19-g6d55570 fbn02lzp 17 Dec 2025 11:39:19 GMT NOCALL
user TEST pass -1 vers test 1.0
# logresp TEST verified, server NOCALL
N0CALL>APRS,TCPIP*,qAC,NOCALL:>Test packet
...
```

### With Filter

```
user TEST pass -1 vers test 1.0 filter r/35.6/139.7/100
# logresp TEST verified, server NOCALL
# filter r/35.6/139.7/100 active
JA1YOE>APRS,TCPIP*:=3542.71N/13941.25E-PHG7130
...
```

## Automated Testing Script

Create a simple test script:

```bash
#!/bin/bash
# test-aprs-data.sh

{
    sleep 1
    echo "user TEST pass -1 vers test 1.0"
    sleep 10
} | telnet localhost 14580 | head -20
```

This connects, logs in, waits 10 seconds, and shows first 20 lines.

## Performance Testing

### Test Connection Count

```bash
for i in {1..10}; do
    (echo "user TEST$i pass -1 vers test 1.0"; sleep 30) | \
    nc localhost 14580 &
done
```

Check connections:
```bash
curl -s http://localhost:14501/status.json | jq '.clients.clients_cur'
```

### Monitor Traffic

```bash
# Watch packet rate in real-time
watch -n 1 'curl -s http://localhost:14501/status.json | jq ".totals"'
```

## References

- [APRS-IS Protocol Documentation](http://www.aprs-is.net/javAPRSFilter.aspx)
- [aprsc Documentation](http://he.fi/aprsc/)
- [APRS Filter Guide](http://www.aprs-is.net/javAPRSFilter.aspx)
