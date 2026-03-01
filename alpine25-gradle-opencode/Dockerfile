FROM eclipse-temurin:25-alpine

# System tools
RUN apk upgrade --no-cache \
 && apk add --no-cache bash curl git jq ripgrep \
 && apk add --no-cache \
      --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
      github-cli

# Opencode CLI — download musl binary directly from GitHub releases
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      aarch64) SUFFIX="linux-arm64-musl" ;; \
      x86_64)  SUFFIX="linux-x64-musl" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    VERSION=$(curl -sfL https://api.github.com/repos/sst/opencode/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4) && \
    echo "Installing opencode ${VERSION} for ${SUFFIX}" && \
    curl -fL "https://github.com/sst/opencode/releases/download/${VERSION}/opencode-${SUFFIX}.tar.gz" \
      | tar -xz -C /usr/local/bin opencode && \
    chmod +x /usr/local/bin/opencode

# Safe git directory for all repos
RUN git config --global --add safe.directory '*'

RUN mkdir /repos

WORKDIR /repos

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080 8081

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
