# Multi-Architecture Support

This document explains how aprsc-docker supports multiple CPU architectures, enabling the same Docker image to run on x86-64 servers, ARM servers, Raspberry Pi devices, and more.

## Table of Contents

- [Supported Architectures](#supported-architectures)
- [How It Works](#how-it-works)
- [Using Multi-Architecture Images](#using-multi-architecture-images)
- [Building Multi-Architecture Images](#building-multi-architecture-images)
- [Local Testing](#local-testing)
- [Hardware Testing](#hardware-testing)
- [Performance and Size](#performance-and-size)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)

## Supported Architectures

The aprsc Docker image supports the following CPU architectures:

| Architecture | Platform | Description | Devices |
|--------------|----------|-------------|---------|
| **AMD64** | `linux/amd64` | 64-bit x86 processors | Intel/AMD servers, desktops, laptops |
| **ARM64** | `linux/arm64` | 64-bit ARM processors (ARMv8) | Raspberry Pi 4/5, ARM servers, Apple Silicon |
| **ARMv7** | `linux/arm/v7` | 32-bit ARM processors (ARMv7) | Raspberry Pi 2/3, older ARM devices |

### Why These Architectures?

- **AMD64**: The standard for servers and desktop computers
- **ARM64**: Growing in popularity for edge computing, IoT, and modern Raspberry Pi devices
- **ARMv7**: Legacy support for older Raspberry Pi and ARM devices

## How It Works

### Docker Manifest Lists

When you pull `bd5rv/aprsc:latest`, Docker automatically selects the correct architecture for your device using **manifest lists** (also called "multi-architecture images").

A manifest list is a special index that contains references to multiple architecture-specific images:

```
bd5rv/aprsc:latest (manifest list)
├── linux/amd64 → sha256:abc123... (4.8 MB)
├── linux/arm64 → sha256:def456... (4.6 MB)
└── linux/arm/v7 → sha256:ghi789... (4.5 MB)
```

When you run `docker pull bd5rv/aprsc:latest`:
1. Docker checks your system architecture
2. Downloads only the matching architecture from the manifest list
3. You get the optimized image for your device

**No special configuration required!**

### Cross-Compilation with Docker Buildx

Multi-architecture images are built using **Docker Buildx** with QEMU emulation:

- **Native build** (linux/amd64): Compiled directly on x86-64 host (~3-5 minutes)
- **Cross-compilation** (linux/arm64, linux/arm/v7): Emulated using QEMU (~5-7 minutes each)

Total build time for all three architectures: **15-20 minutes**

## Using Multi-Architecture Images

### Automatic Platform Detection

Simply pull and run - Docker handles the rest:

```bash
# Automatically selects the correct architecture
docker pull bd5rv/aprsc:latest
docker run -d -p 14580:14580 -p 14501:14501 bd5rv/aprsc:latest
```

On a Raspberry Pi 4:
```bash
$ docker run --rm bd5rv/aprsc:latest uname -m
aarch64  # ARM64 architecture detected and used
```

On an x86-64 server:
```bash
$ docker run --rm bd5rv/aprsc:latest uname -m
x86_64  # AMD64 architecture detected and used
```

### Explicit Platform Selection

Force a specific architecture (useful for testing):

```bash
# Run AMD64 image on any host
docker run --platform linux/amd64 -d bd5rv/aprsc:latest

# Run ARM64 image on any host (requires QEMU)
docker run --platform linux/arm64 -d bd5rv/aprsc:latest

# Run ARMv7 image on any host (requires QEMU)
docker run --platform linux/arm/v7 -d bd5rv/aprsc:latest
```

**Note**: Running non-native architectures requires QEMU and will be slower.

### Docker Compose

Specify platform in `docker-compose.yml` (optional):

```yaml
services:
  aprsc:
    image: bd5rv/aprsc:latest
    platform: linux/arm64  # Optional: force specific platform
    # ... rest of configuration
```

Without `platform:`, Docker Compose automatically selects the host architecture.

### Inspecting Manifest Lists

View all available architectures:

```bash
docker buildx imagetools inspect bd5rv/aprsc:latest
```

Output example:
```
Name:      docker.io/bd5rv/aprsc:latest
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:abc123...

Manifests:
  Name:      docker.io/bd5rv/aprsc:latest@sha256:def456...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/amd64

  Name:      docker.io/bd5rv/aprsc:latest@sha256:ghi789...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm64

  Name:      docker.io/bd5rv/aprsc:latest@sha256:jkl012...
  MediaType: application/vnd.docker.distribution.manifest.v2+json
  Platform:  linux/arm/v7
```

## Building Multi-Architecture Images

### Prerequisites

1. **Docker with Buildx support** (Docker 19.03+)
   ```bash
   docker buildx version
   ```

2. **QEMU for cross-compilation** (usually pre-installed)
   ```bash
   # Install QEMU if needed
   docker run --privileged --rm tonistiigi/binfmt --install all
   ```

3. **Docker Hub account** (for pushing images)
   ```bash
   docker login
   ```

### Build and Push Script

Use the provided script to build and push all architectures:

```bash
./push-to-dockerhub.sh
```

The script will:
1. Detect aprsc version automatically
2. Create/use a buildx builder named `aprsc-multiarch-builder`
3. Build for all three platforms: linux/amd64, linux/arm64, linux/arm/v7
4. Push to Docker Hub with multiple tags:
   - `2.1.19-g6d55570` (full version with git hash)
   - `2.1.19` (semantic version)
   - `2.1` (major.minor)
   - `2` (major)
   - `latest`

**Build time**: Approximately 15-20 minutes for all platforms

### Manual Build

If you prefer manual control:

```bash
# Create builder (once)
docker buildx create --name mybuilder --use --bootstrap

# Build and push
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --push \
    -t yourusername/aprsc:latest \
    .
```

## Local Testing

### Test Script

Use the provided test script to build locally without pushing:

```bash
# Test single platform (fast, loads to local Docker)
./test-multiarch-build.sh linux/amd64

# Test all platforms (slower, doesn't load to local Docker)
./test-multiarch-build.sh linux/amd64,linux/arm64,linux/arm/v7

# Test specific ARM platform
./test-multiarch-build.sh linux/arm64
```

### Testing Single Platform

When testing a single platform, the image is loaded to local Docker:

```bash
# Build for AMD64
./test-multiarch-build.sh linux/amd64

# Test the built image
docker run --rm aprsc-test:multiarch uname -m
docker run --rm aprsc-test:multiarch /opt/aprsc/sbin/aprsc --version

# Start test container
docker run -d --name aprsc-test -p 14580:14580 -p 14501:14501 aprsc-test:multiarch

# Test APRS connection
./test-aprs-connection.sh localhost 14580 TEST

# Check web interface
curl http://localhost:14501/

# Clean up
docker stop aprsc-test && docker rm aprsc-test
docker rmi aprsc-test:multiarch
```

### Testing ARM on x86-64

Test ARM images on x86-64 using QEMU emulation:

```bash
# Build ARM64 image
./test-multiarch-build.sh linux/arm64

# Run with explicit platform (uses QEMU)
docker run --platform linux/arm64 --rm aprsc-test:multiarch uname -m
# Output: aarch64

# Start ARM64 container on x86-64 host
docker run -d --platform linux/arm64 --name aprsc-arm64-test \
    -p 14580:14580 -p 14501:14501 aprsc-test:multiarch

# Test (will be slower due to emulation)
./test-aprs-connection.sh localhost 14580 TEST

docker stop aprsc-arm64-test && docker rm aprsc-arm64-test
```

**Note**: Emulated containers run slower than native but are useful for functional testing.

## Hardware Testing

### Testing on Raspberry Pi

The best way to verify ARM builds is on actual hardware:

#### Raspberry Pi 4/5 (ARM64)

```bash
# Pull image (automatic ARM64 selection)
docker pull bd5rv/aprsc:latest

# Verify architecture
docker run --rm bd5rv/aprsc:latest uname -m
# Expected: aarch64

# Run container
docker run -d --name aprsc \
    -e APRSC_SERVER_ID=YOUR-CALL \
    -e APRSC_PASSCODE=12345 \
    -e APRSC_UPLINK_ENABLED=yes \
    -p 14580:14580 \
    -p 14501:14501 \
    bd5rv/aprsc:latest

# Test
curl http://localhost:14501/
docker logs aprsc
```

#### Raspberry Pi 2/3 (ARMv7)

Same commands as above. Docker will automatically use the ARMv7 image on these devices:

```bash
docker run --rm bd5rv/aprsc:latest uname -m
# Expected: armv7l
```

### Performance Comparison

| Device | Architecture | Build Time | Runtime Performance |
|--------|--------------|------------|---------------------|
| Intel i7 | AMD64 | 3-5 min | Baseline (100%) |
| Raspberry Pi 4 | ARM64 | 5-7 min | ~80-90% of AMD64 |
| Raspberry Pi 3 | ARMv7 | 7-10 min | ~60-70% of AMD64 |

**Note**: aprsc is CPU-efficient. Even Raspberry Pi 3 can handle typical APRS-IS loads.

## Performance and Size

### Image Sizes

Compressed (download) sizes by architecture:

| Architecture | Compressed | Uncompressed | Compression Ratio |
|--------------|------------|--------------|-------------------|
| AMD64 | ~4.8 MB | ~11.2 MB | 57% |
| ARM64 | ~4.6 MB | ~10.8 MB | 57% |
| ARMv7 | ~4.5 MB | ~10.5 MB | 57% |

All architectures remain ultra-compact, ideal for:
- Fast deployment over limited bandwidth
- Resource-constrained devices
- Edge computing scenarios
- Quick container startup

### Build Times

| Build Type | Time | Description |
|------------|------|-------------|
| Single platform (native) | 3-5 min | Building for host architecture |
| Single platform (emulated) | 5-7 min | Cross-compiling with QEMU |
| All platforms | 15-20 min | All three architectures |

**Tip**: Build times can be reduced with Docker layer caching on repeated builds.

## Troubleshooting

### "exec format error"

**Symptom**:
```
standard_init_linux.go:228: exec user process caused: exec format error
```

**Cause**: Trying to run an image built for a different architecture.

**Solution**:
```bash
# Check what architecture the image is
docker inspect bd5rv/aprsc:latest | grep Architecture

# Ensure you're pulling the manifest list (not architecture-specific digest)
docker pull bd5rv/aprsc:latest  # Correct
docker pull bd5rv/aprsc@sha256:abc123...  # Wrong (architecture-specific)
```

### QEMU Not Installed

**Symptom**:
```
ERROR: failed to solve: process "/dev/.buildkit_qemu_emulator" did not complete successfully
```

**Solution**:
```bash
# Install QEMU binfmt support
docker run --privileged --rm tonistiigi/binfmt --install all

# Verify installation
docker buildx ls
# Should show multiple platforms
```

### Slow Performance on ARM

**Symptom**: Container runs but is very slow.

**Possible causes**:
1. **Running emulated image**: Make sure you're using the native architecture
   ```bash
   # Check what's actually running
   docker exec <container> uname -m
   ```

2. **QEMU overhead**: If deliberately running non-native, this is expected

3. **Resource limits**: Check if container has resource constraints
   ```bash
   docker stats <container>
   ```

### Build Fails for Specific Platform

**Symptom**: Build succeeds for AMD64 but fails for ARM.

**Common causes**:
- Architecture-specific dependencies (rare for Alpine Linux)
- Insufficient memory during build
- QEMU timeout

**Solution**:
```bash
# Build platforms individually to isolate the problem
./test-multiarch-build.sh linux/amd64  # Test AMD64
./test-multiarch-build.sh linux/arm64  # Test ARM64
./test-multiarch-build.sh linux/arm/v7 # Test ARMv7

# Increase Docker memory limits if needed
# (Docker Desktop: Settings → Resources → Memory)
```

### Cannot Load Multi-Platform Image

**Symptom**:
```
ERROR: docker exporter does not currently support exporting manifest lists
```

**Explanation**: Docker cannot load multi-platform images to local Docker daemon. This is a Docker limitation.

**Solution**:
```bash
# Load single platform only
./test-multiarch-build.sh linux/amd64  # OK - loads to local Docker

# Multiple platforms must be pushed to a registry
./test-multiarch-build.sh linux/amd64,linux/arm64  # Builds but doesn't load

# Or push to a local registry
docker run -d -p 5000:5000 --name registry registry:2
docker buildx build --platform linux/amd64,linux/arm64 \
    --push -t localhost:5000/aprsc:test .
```

## Technical Details

### Why Alpine Linux?

Alpine Linux provides native multi-architecture support:

1. **Same base across architectures**: `alpine:latest` is a manifest list supporting all target platforms
2. **musl libc portability**: More portable than glibc, works identically across architectures
3. **Package availability**: All aprsc dependencies (libevent, openssl, etc.) available for all architectures
4. **Minimal size**: Base image only 8.44 MB, keeps all architectures compact

### Build Process

The Dockerfile uses multi-stage builds:

**Stage 1 (builder)**: Compile aprsc
- Pulls Alpine base for the target architecture
- Installs build tools (gcc, make, autoconf)
- Compiles aprsc from source
- Native compilation on AMD64, cross-compilation for ARM

**Stage 2 (runtime)**: Create minimal image
- Pulls Alpine base for the target architecture
- Copies only compiled binaries from builder
- Installs runtime dependencies
- Creates non-root user
- Sets up entrypoint

**Result**: Each architecture gets an optimized, minimal image.

### Buildx and QEMU

Docker Buildx uses QEMU user-mode emulation for cross-compilation:

```bash
# When building linux/arm64 on linux/amd64:
# 1. Buildx starts ARM64 Alpine container
# 2. QEMU intercepts ARM instructions
# 3. Translates them to x86-64 instructions
# 4. Runs build process as if on real ARM CPU
```

This allows building for any architecture on any host, but is slower than native compilation.

### Manifest List Structure

A manifest list is a JSON document:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
  "manifests": [
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 1234,
      "digest": "sha256:abc123...",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 1156,
      "digest": "sha256:def456...",
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    }
  ]
}
```

When you pull `bd5rv/aprsc:latest`, Docker:
1. Fetches the manifest list
2. Filters for matching OS and architecture
3. Pulls only the matching manifest

### Why Not More Architectures?

**Considered but not included**:

- **linux/arm/v6** (ARMv6): Raspberry Pi 1, Zero
  - Older hardware with declining usage
  - Can run ARMv7 images in most cases

- **linux/riscv64** (RISC-V): Emerging architecture
  - Very limited hardware availability
  - Alpine Linux support still maturing

- **linux/ppc64le** (PowerPC): IBM POWER systems
  - Niche use case for amateur radio applications

- **linux/s390x** (IBM Z): Mainframes
  - Extremely niche for APRS-IS

**The three supported architectures cover >99% of use cases** while keeping build times reasonable.

## References

- [Docker Buildx Documentation](https://docs.docker.com/build/buildx/)
- [Multi-platform images](https://docs.docker.com/build/building/multi-platform/)
- [Docker Manifest Lists Specification](https://docs.docker.com/registry/spec/manifest-v2-2/)
- [Alpine Linux Architectures](https://wiki.alpinelinux.org/wiki/Architectures)
- [QEMU User Mode Emulation](https://www.qemu.org/docs/master/user/main.html)

## Summary

Multi-architecture support in aprsc-docker provides:

- ✅ **Seamless experience**: Pull and run on any supported platform
- ✅ **Automatic selection**: Docker picks the right architecture
- ✅ **Optimized images**: Native compilation for each architecture
- ✅ **Compact size**: 4-5 MB download regardless of architecture
- ✅ **Wide compatibility**: Servers, desktops, Raspberry Pi devices
- ✅ **Easy testing**: Scripts for local validation
- ✅ **Production-ready**: Used in real deployments

For most users, multi-architecture support is completely transparent - just pull and run!
