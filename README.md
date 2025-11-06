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

The workflow will automatically build for all supported platforms and push to Docker Hub.

## Usage

```bash
# Pull the latest image
docker pull <your-dockerhub-username>/bitcoind:latest

# Run bitcoind
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/home/bitcoin/.bitcoin \
  <your-dockerhub-username>/bitcoind:latest

# Run with custom configuration
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  -p 8332:8332 \
  -v bitcoin-data:/home/bitcoin/.bitcoin \
  -v /path/to/bitcoin.conf:/home/bitcoin/.bitcoin/bitcoin.conf \
  <your-dockerhub-username>/bitcoind:latest
```

## Configuration

You can pass Bitcoin Core configuration options as command-line arguments:

```bash
docker run -d \
  --name bitcoind \
  -p 8333:8333 \
  <your-dockerhub-username>/bitcoind:latest \
  -printtoconsole \
  -testnet \
  -rpcuser=user \
  -rpcpassword=password
```

## Docker Hub Setup

To use the workflow, you need to set up the following secrets in your GitHub repository:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password or access token

## License

This repository contains only the Dockerfile and build configuration. Bitcoin Core itself is licensed under the MIT License.
