FROM ubuntu:noble

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      curl git jq ripgrep age python3 python3-yaml \
 && ARCH=$(dpkg --print-architecture) \
 && GH_VERSION=$(curl -sfL https://api.github.com/repos/cli/cli/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//') \
 && curl -fL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.deb" \
      -o /tmp/gh.deb \
 && apt-get install -y --no-install-recommends /tmp/gh.deb \
 && rm /tmp/gh.deb \
 && SOPS_VERSION=$(curl -sfL https://api.github.com/repos/getsops/sops/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//') \
 && curl -fL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops_${SOPS_VERSION}_linux_${ARCH}.deb" \
      -o /tmp/sops.deb \
 && apt-get install -y --no-install-recommends /tmp/sops.deb \
 && rm /tmp/sops.deb \
 && rm -rf /var/lib/apt/lists/*

# opencode CLI — glibc binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      aarch64) SUFFIX="linux-arm64" ;; \
      x86_64)  SUFFIX="linux-x64" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    VERSION=$(curl -sfL https://api.github.com/repos/sst/opencode/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4) && \
    curl -fL "https://github.com/sst/opencode/releases/download/${VERSION}/opencode-${SUFFIX}.tar.gz" \
      | tar -xz -C /usr/local/bin opencode && \
    chmod +x /usr/local/bin/opencode

RUN git config --global --add safe.directory '*'
RUN mkdir /repos
WORKDIR /repos
COPY skills/ /opt/skills/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
