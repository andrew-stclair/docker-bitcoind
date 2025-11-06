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

# Create bitcoin user and data directories
RUN useradd -r -m -d /home/bitcoin bitcoin \
    && mkdir -p /home/bitcoin/.bitcoin /bitcoin/blocks \
    && chown -R bitcoin:bitcoin /home/bitcoin /bitcoin

# Create default bitcoin.conf
RUN echo "# This config should be placed in following path:" > /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "# ~/.bitcoin/bitcoin.conf" >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "" >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "# [core]" >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "# Specify a non-default location to store blockchain data." >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "blocksdir=/bitcoin/blocks" >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "# Specify a non-default location to store blockchain and other data." >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    echo "datadir=/bitcoin" >> /home/bitcoin/.bitcoin/bitcoin.conf && \
    chown bitcoin:bitcoin /home/bitcoin/.bitcoin/bitcoin.conf

USER bitcoin
WORKDIR /home/bitcoin

# Volume for persistent blockchain data
VOLUME ["/bitcoin"]

# Expose Bitcoin ports
# 8332: RPC, 8333: P2P mainnet, 18332: RPC testnet, 18333: P2P testnet
EXPOSE 8332 8333 18332 18333

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/bitcoind"]
CMD ["-printtoconsole"]
