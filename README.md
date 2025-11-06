# docker-bitcoind

Bitcoin Core daemon (bitcoind) in Docker with multi-platform support.

## Supported Platforms

This Docker image is built for the following platforms:
- linux/amd64
- linux/arm64
- linux/arm/v7
- linux/riscv64
- linux/ppc64le

## Building

The repository includes a GitHub Actions workflow that builds the Docker image on manual dispatch.

To trigger a build:
1. Go to the Actions tab in GitHub
2. Select "Build Bitcoin Docker Image"
3. Click "Run workflow"
4. Enter the Bitcoin version to build (default: 28.1)

The workflow will automatically build for all supported platforms and push to GitHub Container Registry (ghcr.io).

## Usage

```bash
# Pull the latest image
docker pull ghcr.io/andrew-stclair/bitcoind:latest

# Run bitcoind
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/home/bitcoin/.bitcoin \
  ghcr.io/andrew-stclair/bitcoind:latest

# Run with custom configuration
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/home/bitcoin/.bitcoin \
  -v /path/to/bitcoin.conf:/home/bitcoin/.bitcoin/bitcoin.conf \
  ghcr.io/andrew-stclair/bitcoind:latest
```

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
  -rpcpassword=password
```

## GitHub Container Registry

The Docker images are automatically published to GitHub Container Registry (ghcr.io) using GitHub Actions. The workflow uses the built-in `GITHUB_TOKEN` secret for authentication, which is automatically provided by GitHub Actions.

No additional secrets need to be configured - the workflow has `packages: write` permission to push images to GHCR.

## License

This repository contains only the Dockerfile and build configuration. Bitcoin Core itself is licensed under the MIT License.
