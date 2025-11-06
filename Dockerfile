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
        linux/ppc64le) \
            BITCOIN_ARCH="powerpc64le-linux-gnu" \
            ;; \
        *) \
            echo "Unsupported platform: ${TARGETPLATFORM}"; \
            exit 1 \
            ;; \
    esac; \
    BITCOIN_URL="https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}"; \
    BITCOIN_FILE="bitcoin-${BITCOIN_VERSION}-${BITCOIN_ARCH}.tar.gz"; \
    curl -SL "$BITCOIN_URL/$BITCOIN_FILE" -o "$BITCOIN_FILE"; \
    curl -SL "$BITCOIN_URL/SHA256SUMS" -o SHA256SUMS; \
    curl -SL "$BITCOIN_URL/SHA256SUMS.asc" -o SHA256SUMS.asc; \
    # Import Bitcoin Core release signing keys \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    # Bitcoin Core builder keys that signed this release \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys \
        01EA5486DE18A882D4C2684590C8019E36C2E964 \
        71A3B16735405025D447E8F274810B012346C9A6 \
        26646D99CBAEC9B81982EF6029D9EE6B1FC730C1 \
        101598DC823C1B5F9A6624ABA5E0907A0380E6C3 \
        152812300785C96444D3334D17565732E08E5E41 \
        E61773CD6E01040E2F1BD78CE7E2984B6289C93A \
        9DEAE0DC7063249FB05474681E4AED62986CD25D \
        C388F6961FB972A95678E327F62711DBDCA8AE56 \
        9D3CC86A72F8494342EA5FD10A41BDC3F4FAFF1C \
        637DB1E23370F84AFF88CCE03152347D07DA627C \
        F2CFC4ABD0B99D837EEBB7D09B79B45691DB4173 \
        E86AE73439625BBEE306AAE6B66D427F873CB1A3 \
        F19F5FF2B0589EC341220045BA03F4DBE0C63FB4 \
        F4FC70F07310028424EFC20A8E4256593F177720 \
        A0083660F235A27000CD3C81CE6EC49945C17EA6 \
        0CCBAAFD76A2ECE2CCD3141DE2FFD5B1D88CA97D; \
    # Verify the signature of SHA256SUMS file \
    gpg --verify SHA256SUMS.asc SHA256SUMS; \
    # Verify the tarball checksum \
    grep " $BITCOIN_FILE\$" SHA256SUMS | sha256sum -c -; \
    # Verify the tarball signature (optional, as SHA256SUMS is signed) \
    # gpg --verify "$BITCOIN_FILE.asc" "$BITCOIN_FILE"; \
    tar -xzf "$BITCOIN_FILE"; \
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

# Add default bitcoin.conf
COPY bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
RUN chown bitcoin:bitcoin /home/bitcoin/.bitcoin/bitcoin.conf

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
