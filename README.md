# Standalone Dev Container (Kotlin/JVM/Gradle + Claude)

A portable dev container that works for any Kotlin/JVM/Gradle project. All tools are baked into the image; your project is cloned inside a named Docker volume at runtime. No project source is baked in, so the image can be reused for any repo.

## What's included

- JDK 25 (`eclipse-temurin:25-alpine`)
- `bash`, `curl`, `git`, `iptables`
- `gh` (GitHub CLI)
- `node` / `npm`
- `claude` (Claude Code CLI via `@anthropic-ai/claude-code`)

No Gradle binary — each project supplies its own `./gradlew`.

## Network policy

After the first-run bootstrap, outbound traffic is restricted to **GitHub and Anthropic** only via iptables. Everything else is dropped. Requires `--cap-add=NET_ADMIN` (set in `compose.yaml`).

DNS (port 53) is always allowed so `gh` and `claude` can resolve hostnames at runtime.

## Quick start

### 1. Build the image

```sh
docker compose -f dev-docker/compose.yaml build
```

### 2. Start an interactive shell

```sh
docker compose -f dev-docker/compose.yaml run dev
```

- **First run**: full internet access — Gradle cache is bootstrapped, then network is restricted.
- **Subsequent runs**: restricted immediately (GitHub + Anthropic only).

### 3. One-time auth setup (inside the container)

```sh
# GitHub CLI
gh auth login
# → GitHub.com → HTTPS → Login with a web browser
# → Enter the one-time code at https://github.com/login/device on your host

# Claude Code
claude
# → Follow the interactive auth flow (OAuth URL or API key)
```

Credentials are stored in named volumes (`gh-auth`, `claude-auth`) and persist across restarts.

### 4. Clone a repo and start working

```sh
gh repo fork kartverket/backstage-plugin-risk-scorecard-backend --clone
cd backstage-plugin-risk-scorecard-backend
git checkout -b my-feature
claude
```

### 5. Build and open a PR

```sh
./gradlew build -x test
git add -p && git commit -m "feat: my change"
git push -u origin my-feature
gh pr create --fill
```

## Restarting an existing container

Without `--rm`, the container persists after `exit`. To re-enter it:

```sh
docker compose -f dev-docker/compose.yaml start
docker compose -f dev-docker/compose.yaml exec dev bash
```

## Resetting the Gradle cache

If `build.gradle.kts` changes significantly (new dependencies), delete the cache volume and the bootstrap sentinel will re-run on next start:

```sh
docker volume rm dev-docker_gradle-cache
```

Or from inside the container:

```sh
rm /root/.gradle/.bootstrapped
```

## Environment variables

Set `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` in a `.env` file next to `compose.yaml`:

```sh
GIT_AUTHOR_NAME=Your Name
GIT_AUTHOR_EMAIL=you@example.com
```

## Verification checklist

| Check | Command | Expected |
|-------|---------|---------|
| Claude Code available | `claude --version` | Prints version |
| gh CLI available | `gh --version` | Prints version |
| git works | `git log --oneline -3` | Shows recent commits |
| Gradle works from cache | `./gradlew build -x test` | Succeeds, no downloads |
| Network blocked | `curl -s --max-time 3 https://example.com` | Times out |
| GitHub reachable | `curl -s https://api.github.com/zen` | Returns a quote |
| Anthropic reachable | API call via `claude` | Works |
