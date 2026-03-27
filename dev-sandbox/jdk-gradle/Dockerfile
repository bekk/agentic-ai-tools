FROM eclipse-temurin:25-jdk-noble

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends curl git jq ripgrep \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && ARCH=$(dpkg --print-architecture) \
 && GH_VERSION=$(curl -sfL https://api.github.com/repos/cli/cli/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//') \
 && curl -fL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.deb" \
      -o /tmp/gh.deb \
 && apt-get install -y --no-install-recommends /tmp/gh.deb \
 && rm /tmp/gh.deb \
 && rm -rf /var/lib/apt/lists/*

# GitHub Copilot CLI — standalone binary, no auth required at build time
RUN curl -fsSL https://gh.io/copilot-install | bash

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Replace globalThis.fetch with undici's proxy-aware fetch so all Node.js code
# (including Claude Code) routes fetch() through HTTPS_PROXY automatically.
# undici is installed locally so ESM bare-specifier resolution works (NODE_PATH is ignored by ESM).
RUN mkdir -p /usr/local/lib/node-proxy \
 && npm --prefix /usr/local/lib/node-proxy install undici \
 && printf '%s\n' \
      "import { setGlobalDispatcher, ProxyAgent, fetch as proxiedFetch } from 'undici';" \
      "const p = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;" \
      "if (p) { setGlobalDispatcher(new ProxyAgent(p)); globalThis.fetch = proxiedFetch; }" \
      > /usr/local/lib/node-proxy/bootstrap.mjs

# Opencode CLI — glibc binary for Ubuntu/Debian base
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      aarch64) SUFFIX="linux-arm64" ;; \
      x86_64)  SUFFIX="linux-x64" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    VERSION=$(curl -sfL https://api.github.com/repos/sst/opencode/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4) && \
    echo "Installing opencode ${VERSION} for ${SUFFIX}" && \
    curl -fL "https://github.com/sst/opencode/releases/download/${VERSION}/opencode-${SUFFIX}.tar.gz" \
      | tar -xz -C /usr/local/bin opencode && \
    chmod +x /usr/local/bin/opencode

RUN git config --global --add safe.directory '*'
RUN mkdir /repos
WORKDIR /repos
COPY skills/ /opt/skills/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080 8081
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
