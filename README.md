# docker-bitcoind

Bitcoin Core daemon (bitcoind) in Docker with multi-platform support.

## Supported Platforms

This Docker image is built for the following platforms:
- linux/amd64
- linux/arm64
- linux/arm/v7

## Building

The repository includes a GitHub Actions workflow that builds the Docker image on manual dispatch.

To trigger a build:
1. Go to the Actions tab in GitHub
2. Select "Build Bitcoin Docker Image"
3. Click "Run workflow"
4. Enter the Bitcoin version to build (default: 28.1)

The workflow will automatically build for all supported platforms and push to GitHub Container Registry (ghcr.io).

## Usage

The Docker image uses `/bitcoin` as a persistent volume for blockchain data storage. The configuration is pre-set to use this directory for both blockchain blocks and other data.

```bash
# Pull the latest image
docker pull ghcr.io/andrew-stclair/bitcoind:latest

# Run bitcoind with persistent storage
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/bitcoin \
  ghcr.io/andrew-stclair/bitcoind:latest

# Run with custom configuration
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/bitcoin \
  -v /path/to/bitcoin.conf:/home/bitcoin/.bitcoin/bitcoin.conf \
  ghcr.io/andrew-stclair/bitcoind:latest

# Run with read-only root filesystem (enhanced security)
docker run -d \
  --name bitcoind \
  --read-only \
  --tmpfs /tmp \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/bitcoin \
  ghcr.io/andrew-stclair/bitcoind:latest
```

### Default Configuration

The container includes a default `bitcoin.conf` file that configures the data directory:

```
# [core]
# Specify a non-default location to store blockchain data.
blocksdir=/bitcoin/blocks
# Specify a non-default location to store blockchain and other data.
datadir=/bitcoin
```

This configuration ensures all blockchain data is stored in the `/bitcoin` volume for easy persistence and backup.

### Read-Only Root Filesystem

For enhanced security, this container can run with a read-only root filesystem using Docker's `--read-only` flag. This prevents any modifications to the container's filesystem, reducing the attack surface.

When running with `--read-only`, you must provide a tmpfs mount for `/tmp` to allow temporary file operations:

```bash
docker run -d \
  --name bitcoind \
  --read-only \
  --tmpfs /tmp \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/bitcoin \
  ghcr.io/andrew-stclair/bitcoind:latest
```

The container is designed to work seamlessly with this configuration, as all persistent data is written to the `/bitcoin` volume mount, and temporary files use the `/tmp` tmpfs mount.

## Configuration

You can pass Bitcoin Core configuration options as command-line arguments:

```bash
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  ghcr.io/andrew-stclair/bitcoind:latest \
  -printtoconsole \
  -testnet \
  -rpcuser=user \
  -rpcpassword=YOUR_STRONG_PASSWORD
```

## GitHub Container Registry

The Docker images are automatically published to GitHub Container Registry (ghcr.io) using GitHub Actions. The workflow uses the built-in `GITHUB_TOKEN` secret for authentication, which is automatically provided by GitHub Actions.

No additional secrets need to be configured - the workflow has `packages: write` permission to push images to GHCR.

## License

This repository contains only the Dockerfile and build configuration. Bitcoin Core itself is licensed under the MIT License.
