FROM debian:bookworm-slim AS builder

ARG BITCOIN_VERSION=28.1
ARG TARGETPLATFORM

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Download and verify Bitcoin Core
WORKDIR /tmp
RUN set -ex; \
    case "${TARGETPLATFORM}" in \
        linux/amd64) \
            BITCOIN_ARCH="x86_64-linux-gnu" \
            ;; \
        linux/arm64) \
            BITCOIN_ARCH="aarch64-linux-gnu" \
            ;; \
        linux/arm/v7) \
            BITCOIN_ARCH="arm-linux-gnueabihf" \
            ;; \
        linux/riscv64) \
            BITCOIN_ARCH="riscv64-linux-gnu" \
            ;; \
        linux/ppc64le) \
            BITCOIN_ARCH="powerpc64le-linux-gnu" \
            ;; \
        *) \
            echo "Unsupported platform: ${TARGETPLATFORM}"; \
            exit 1 \
            ;; \
    esac; \
    curl -SL https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}.tar.gz -o bitcoin.tar.gz \
    && tar -xzf bitcoin.tar.gz \
    && mv bitcoin-${BITCOIN_VERSION}/bin/* /usr/local/bin/ \
    && rm -rf /tmp/*

FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binaries from builder
COPY --from=builder /usr/local/bin/* /usr/local/bin/

# Create bitcoin user and data directory
RUN useradd -r -m -d /home/bitcoin bitcoin \
    && mkdir -p /home/bitcoin/.bitcoin \
    && chown -R bitcoin:bitcoin /home/bitcoin

USER bitcoin
WORKDIR /home/bitcoin

# Expose Bitcoin ports
# 8332: RPC, 8333: P2P mainnet, 18332: RPC testnet, 18333: P2P testnet
EXPOSE 8332 8333 18332 18333

# Default entrypoint
ENTRYPOINT ["bitcoind"]
CMD ["-printtoconsole"]
