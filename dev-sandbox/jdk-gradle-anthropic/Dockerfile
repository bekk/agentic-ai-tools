FROM eclipse-temurin:25-alpine

RUN apk upgrade --no-cache \
 && apk add --no-cache bash curl git nodejs npm jq ripgrep \
 && apk add --no-cache \
      --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
      github-cli

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Replace globalThis.fetch with undici's proxy-aware fetch so all Node.js code
# (including Claude Code) routes fetch() through HTTPS_PROXY automatically.
RUN npm install -g undici
RUN printf '%s\n' \
  "import { setGlobalDispatcher, ProxyAgent, fetch as proxiedFetch } from 'undici';" \
  "const p = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;" \
  "if (p) { setGlobalDispatcher(new ProxyAgent(p)); globalThis.fetch = proxiedFetch; }" \
  > /usr/local/lib/node-proxy-bootstrap.mjs

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

RUN git config --global --add safe.directory '*'
RUN mkdir /repos
WORKDIR /repos
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 8080 8081
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
