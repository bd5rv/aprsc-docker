# ============================================================
# Stage 1: Build stage (based on Alpine Linux)
# ============================================================
FROM alpine:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    gcc \
    make \
    git \
    ca-certificates \
    libevent-dev \
    openssl-dev \
    lksctp-tools-dev \
    libcap-dev \
    perl

# Clone aprsc source code from GitHub
WORKDIR /tmp
RUN git clone https://github.com/hessu/aprsc.git

# Compile and install
WORKDIR /tmp/aprsc/src
RUN ./configure \
        --prefix=/opt/aprsc \
        --sysconfdir=/etc/aprsc \
        --localstatedir=/var && \
    make && \
    make install DESTDIR=/tmp/aprsc-install

# ============================================================
# Stage 2: Runtime stage (based on Alpine Linux - minimal image)
# ============================================================
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    libevent \
    libssl3 \
    libcrypto3 \
    lksctp-tools \
    libcap \
    tini

# Copy compiled files from builder stage
COPY --from=builder /tmp/aprsc-install /

# Create aprsc user and group
RUN addgroup -S aprsc && \
    adduser -S -D -H -h /var/run/aprsc -s /sbin/nologin -G aprsc aprsc

# Copy example configuration file from builder stage
COPY --from=builder /tmp/aprsc/src/aprsc.conf /etc/aprsc/aprsc.conf.example

# Create necessary directories and set permissions
RUN mkdir -p /var/run/aprsc /var/run/aprsc/logs /var/log/aprsc && \
    ln -s /opt/aprsc/web /var/run/aprsc/web && \
    chown -R aprsc:aprsc /var/run/aprsc /var/log/aprsc && \
    chmod 755 /var/run/aprsc /var/log/aprsc

# Expose ports (adjust according to your configuration)
# 14580: APRS-IS client port (TCP/UDP)
# 10152: APRS-IS full feed port (TCP/UDP)
# 8080: UDP packet submission + HTTP position upload
# 14501: HTTP status monitoring page
EXPOSE 14580 10152 8080 8080/udp 14501

# Set working directory
WORKDIR /var/run/aprsc

# Use tini as init process
ENTRYPOINT ["/sbin/tini", "--"]

# Start aprsc (requires valid configuration file)
# Note: You need to copy aprsc.conf.example to aprsc.conf and configure it
# -u aprsc: Run as aprsc user (secure)
# Don't use -f parameter to run in foreground (Docker needs foreground process)
CMD ["/opt/aprsc/sbin/aprsc", "-c", "/etc/aprsc/aprsc.conf", "-u", "aprsc"]
