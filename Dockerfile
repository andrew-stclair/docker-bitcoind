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
    BITCOIN_URL="https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}"; \
    curl -SL "$BITCOIN_URL/bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}.tar.gz" -o bitcoin.tar.gz; \
    curl -SL "$BITCOIN_URL/bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}.tar.gz.asc" -o bitcoin.tar.gz.asc; \
    curl -SL "$BITCOIN_URL/SHA256SUMS" -o SHA256SUMS; \
    curl -SL "$BITCOIN_URL/SHA256SUMS.asc" -o SHA256SUMS.asc; \
    # Import Bitcoin Core release signing keys \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    # List of key fingerprints from https://bitcoincore.org/en/download/ \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys \
        590B7292695AFFA5B672CBB2E13FC145CD3F4304 \
        01EA5486DE18A882D4C2684590C8019E36C2E964 \
        99EAC8F2B9B50F2C7A029E8B8C49A5E6A4E4F27E \
        152812300785C96444D3334D17565732E08E5E41; \
    # Verify the signature of SHA256SUMS file \
    gpg --verify SHA256SUMS.asc SHA256SUMS; \
    # Verify the tarball checksum \
    grep " bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}.tar.gz\$" SHA256SUMS | sha256sum -c -; \
    # Verify the tarball signature (optional, as SHA256SUMS is signed) \
    # gpg --verify bitcoin.tar.gz.asc bitcoin.tar.gz; \
    tar -xzf bitcoin.tar.gz; \
    mv bitcoin-${BITCOIN_VERSION}/bin/* /usr/local/bin/; \
    rm -rf /tmp/*

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
