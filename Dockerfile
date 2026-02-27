FROM eclipse-temurin:25-alpine

# System tools
RUN apk upgrade --no-cache \
 && apk add --no-cache bash curl git iptables nodejs npm \
 && apk add --no-cache \
      --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
      github-cli

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Safe git directory for all repos
RUN git config --global --add safe.directory '*'

# Repos directory — mounted as a named volume at runtime
RUN mkdir /repos

WORKDIR /repos

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080 8081

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
