# GitHub Copilot Instructions for docker-bitcoind

This project maintains a secure, multi-platform Docker image for Bitcoin Core daemon (bitcoind).

## Architecture Support

Maintain builds for all architectures that are commonly supported across:
1. **Docker/Docker Buildx platforms**
2. **Debian base image** (currently `debian:bookworm-slim`)
3. **Bitcoin Core binaries** available at https://bitcoin.org/bin/bitcoin-core-{VERSION}/

### Currently Supported Architectures

Based on the intersection of Docker, Debian bookworm-slim, and Bitcoin Core 28.1 binaries:

- `linux/amd64` → `x86_64-linux-gnu`
- `linux/arm64` → `aarch64-linux-gnu`
- `linux/arm/v7` → `arm-linux-gnueabihf`

### Architecture Mapping Reference

When adding or updating architecture support in the Dockerfile, use this mapping:

```dockerfile
case "${TARGETPLATFORM}" in
    linux/amd64)
        BITCOIN_ARCH="x86_64-linux-gnu"
        ;;
    linux/arm64)
        BITCOIN_ARCH="aarch64-linux-gnu"
        ;;
    linux/arm/v7)
        BITCOIN_ARCH="arm-linux-gnueabihf"
        ;;
    linux/386)
        # Only if Bitcoin Core provides i686/i386 binaries
        BITCOIN_ARCH="i686-pc-linux-gnu"
        ;;
    linux/ppc64le)
        # Only if both Debian and Bitcoin Core support it
        BITCOIN_ARCH="powerpc64le-linux-gnu"
        ;;
    linux/riscv64)
        # RISC-V 64-bit - check Bitcoin binaries availability
        BITCOIN_ARCH="riscv64-linux-gnu"
        ;;
    *)
        echo "Unsupported platform: ${TARGETPLATFORM}";
        exit 1
        ;;
esac
```

**Important**: Before adding a new architecture:
1. Verify the Bitcoin Core binary exists at https://bitcoin.org/bin/bitcoin-core-{VERSION}/
2. Confirm Debian base image supports the architecture
3. Test the build with Docker Buildx
4. Update the GitHub Actions workflow's `platforms` list

## Version Management

### Base Container Image

**Current**: `debian:bookworm-slim`

**Instructions**:
- Monitor Debian releases at https://www.debian.org/releases/
- Keep the base image updated to the latest stable Debian release
- When updating, use the `-slim` variant for minimal image size
- Test multi-arch builds after base image updates
- Update both occurrences in the Dockerfile (builder and runtime stages)

**Update Process**:
1. Check for new Debian stable releases
2. Update `FROM debian:bookworm-slim` to the new version (e.g., `debian:trixie-slim`)
3. Test builds on all supported architectures
4. Verify GPG keyserver access and signature verification still work
5. Update README.md if there are any compatibility notes

### Bitcoin Core Version

**Current**: Version defined in Dockerfile `ARG BITCOIN_VERSION=28.1` and workflow default

**Instructions**:
- Monitor releases at https://bitcoin.org/bin/
- Always use the latest stable version available
- Update in **both** locations:
  1. `Dockerfile` → `ARG BITCOIN_VERSION=28.1`
  2. `.github/workflows/build-docker.yml` → `default: '28.1'`

**Update Process**:
1. Check https://bitcoin.org/bin/ for new releases
2. Verify available architectures match our supported platforms
3. Update the `BITCOIN_VERSION` in Dockerfile
4. Update the workflow default version
5. Verify GPG signing keys are still valid (check Bitcoin Core release notes)
6. Update GPG keys in Dockerfile if new release signers are added
7. Test build for all architectures

**GPG Key Management**:
- Bitcoin Core releases are signed by multiple developers
- Maintain the list of trusted signing keys in the Dockerfile
- When a new version is released, check the release notes for the list of signing keys
- Add any new trusted keys to the `gpg --recv-keys` command
- Remove keys that are no longer used (but be conservative - keep historical keys)

## Bitcoin Core Best Practices

Follow best practices from https://bitcoin.org/en/full-node when configuring the container:

### Security Best Practices

1. **Rootless Execution** (Already implemented)
   - Container runs as non-root user `bitcoin`
   - User created with `useradd -r -m -d /home/bitcoin bitcoin`
   - Never run bitcoind as root

2. **Read-Only Root Filesystem** (Already supported)
   - Container designed to work with `--read-only` flag
   - All persistent data written to `/bitcoin` volume
   - Temporary files use `/tmp` (mount as tmpfs when using --read-only)
   - Test with: `docker run --read-only --tmpfs /tmp ...`

3. **Data Directory Isolation**
   - Use dedicated volume for blockchain data (`/bitcoin`)
   - Separate blocks directory: `blocksdir=/bitcoin/blocks`
   - Keep data directory permissions restricted to bitcoin user

4. **Minimal Attack Surface**
   - Use slim base image (debian:bookworm-slim)
   - Remove package manager cache after installs
   - Install only necessary runtime dependencies
   - No unnecessary tools in runtime image

5. **GPG Signature Verification** (Already implemented)
   - Always verify SHA256SUMS.asc signature
   - Verify tarball checksum against SHA256SUMS
   - Never skip signature verification
   - Keep signing keys up to date

6. **Network Security**
   - Document all exposed ports in Dockerfile
   - Default ports: 8332 (RPC), 8333 (P2P mainnet), 18332 (RPC testnet), 18333 (P2P testnet)
   - Consider documenting port 28332 (RPC signet), 28333 (P2P signet) if needed

7. **Configuration Security**
   - Never include RPC credentials in the image
   - Document secure RPC authentication in README
   - Encourage use of strong passwords
   - Support configuration via volume mounts and command-line args

### Full Node Best Practices

From https://bitcoin.org/en/full-node:

1. **Resource Requirements**
   - Document minimum disk space requirements (currently ~500GB+ for mainnet)
   - Document memory requirements (recommend 2GB+ RAM)
   - Note that initial sync can take several days

2. **Network Configuration**
   - Document port forwarding for full node operation
   - Explain inbound connection benefits
   - Document bandwidth requirements

3. **Data Persistence**
   - Always use a volume for `/bitcoin` directory
   - Warn about data loss if volume not used
   - Document backup strategies

4. **Updates and Maintenance**
   - Keep Bitcoin Core version current
   - Document upgrade procedures
   - Note the importance of verifying releases

## Dockerfile Best Practices

### Multi-Stage Builds

- Use multi-stage builds to minimize final image size
- Builder stage: includes curl, gnupg, ca-certificates
- Runtime stage: minimal dependencies only
- Copy only necessary binaries from builder

### Build Arguments

- Support `BITCOIN_VERSION` build arg for flexibility
- Support `TARGETPLATFORM` for multi-arch builds
- Document all build args in comments

### Layer Optimization

- Combine related RUN commands to reduce layers
- Clean up package manager cache in the same layer
- Order commands from least to most frequently changed

## GitHub Actions Workflow

### Build Configuration

**File**: `.github/workflows/build-docker.yml`

**Requirements**:
1. Support manual dispatch with version input
2. Build for all supported architectures in parallel
3. Use QEMU for cross-platform builds
4. Tag images with both version and `latest`
5. Push to GitHub Container Registry (ghcr.io)

**Platform List**:
Update the `platforms` field when adding/removing architecture support:
```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

### Permissions

Ensure workflow has:
- `contents: read` - to checkout code
- `packages: write` - to push to GHCR

## Testing and Validation

When making changes, always:

1. **Build Test**: Build for all architectures locally
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 .
   ```

2. **Signature Verification**: Ensure GPG verification succeeds for all architectures

3. **Runtime Test**: Test the container starts and runs
   ```bash
   docker run --rm ghcr.io/andrew-stclair/bitcoind:latest --version
   ```

4. **Read-Only Test**: Verify read-only filesystem works
   ```bash
   docker run --rm --read-only --tmpfs /tmp ghcr.io/andrew-stclair/bitcoind:latest --version
   ```

5. **Volume Test**: Verify data persistence
   ```bash
   docker run -d -v bitcoin-data:/bitcoin ghcr.io/andrew-stclair/bitcoind:latest
   ```

## Common Maintenance Tasks

### Adding a New Architecture

1. Check Bitcoin Core binary availability for the architecture
2. Check Debian base image support
3. Add mapping in Dockerfile TARGETPLATFORM case statement
4. Update platforms list in GitHub Actions workflow
5. Update README.md supported platforms list
6. Test build with `docker buildx build --platform linux/NEW_ARCH`

### Updating Bitcoin Core Version

1. Check https://bitcoin.org/bin/ for latest version
2. Review release notes at https://bitcoincore.org/en/releases/
3. Check GPG signing keys in release notes
4. Update `BITCOIN_VERSION` in Dockerfile
5. Update workflow default version
6. Add any new GPG keys if needed
7. Test build for all architectures
8. Update README.md version references

### Updating Base Image

1. Check Debian releases status
2. Test new base image: `docker pull debian:NEW_VERSION-slim`
3. Update both FROM lines in Dockerfile
4. Test all architectures build successfully
5. Verify GPG keyserver access still works
6. Update README.md if needed

### Security Updates

1. Monitor security advisories for:
   - Bitcoin Core (https://bitcoincore.org/en/security-advisories/)
   - Debian security updates
   - Docker base image vulnerabilities

2. Apply security updates promptly:
   - Update Bitcoin Core version
   - Rebuild with latest base image patches
   - Test thoroughly before deploying

## Documentation Requirements

Keep README.md updated with:
- Current Bitcoin Core version
- Supported architectures
- Security features (rootless, read-only)
- Usage examples
- Configuration options
- Volume mount recommendations

## Code Style

- Use 4-space indentation in Dockerfile
- Use 2-space indentation in YAML files
- Add comments for complex operations
- Keep lines under 120 characters when practical
- Use meaningful variable names (e.g., `BITCOIN_ARCH` not `ARCH`)

## Additional Resources

- Bitcoin Core documentation: https://bitcoin.org/en/full-node
- Bitcoin Core downloads: https://bitcoin.org/bin/
- Bitcoin Core release notes: https://bitcoincore.org/en/releases/
- Debian releases: https://www.debian.org/releases/
- Docker multi-platform builds: https://docs.docker.com/build/building/multi-platform/
- Docker security best practices: https://docs.docker.com/develop/security-best-practices/
