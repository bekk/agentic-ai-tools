# alpine25-gradle-claude

> **Repo:** https://github.com/bekk/agentic-ai-tools

Portabel dev-container for Kotlin/JVM/Gradle-prosjekter med Claude Code. Ingen prosjektkode er bakt inn — imaget gjenbrukes på tvers av repoer.

---

## Hurtigstart

Forutsetninger: Docker, `docker-compose`

```sh
# 1. Klon og gå inn i katalogen
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/alpine25-gradle-claude

# 2. Sett git-identitet
cp .env.example .env
# Rediger .env med navn og e-post

# 3. Bygg imaget (én gang)
docker-compose build

# 4. Start dev-containeren
./dev.sh

# 5. Første gang: autentiser gh og Claude
gh auth login
claude  # følg instruksjonene for å koble til API-nøkkel

# 6. Klon ditt repo og start Claude
gh repo clone <org>/<repo>
cd <repo>
claude
```

For Gradle-bygg, kjør fra **vertsmaskinen** (ikke inne i dev-containeren):

```sh
./gradle.sh "cd <repo> && ./gradlew build"
```

---

## Innhold

| Verktøy | Versjon |
|---------|---------|
| JDK | 25 (eclipse-temurin) |
| Claude Code CLI | siste (`@anthropic-ai/claude-code`) |
| GitHub CLI (`gh`) | siste (Alpine edge) |
| `git`, `bash`, `curl` | Alpine |

Ingen Gradle-binary — hvert prosjekt bruker sin egen `./gradlew`.

---

## Arkitektur

To containere, ett delt repo-volum:

**`dev` (dev-runner)**
- Claude Code, gh CLI, git
- Nettverkstilgang begrenset til GitHub og Anthropic via iptables
- Startes persistent med `dev.sh`

**`gradle` (gradle-runner)**
- Ren JDK 25, ubegrenset nettverkstilgang (nødvendig for nedlasting av avhengigheter)
- Deler `repos`- og `gradle-cache`-volum med dev-containeren
- Startes persistent med `gradle.sh`

### Nettverkspolicy (dev-containeren)

Ved oppstart hentes GitHubs publiserte IP-blokker fra `api.github.com/meta` og legges inn i iptables. Anthropic-endepunkter løses via DNS. Alt annet utgående trafikk blokkeres. Krever `--cap-add=NET_ADMIN`.

---

## Persistens

Alle data lagres i navngitte Docker-volumer:

| Volum | Innhold |
|-------|---------|
| `repos` | Klonede repoer |
| `gradle-cache` | Gradle-cache (`~/.gradle`) |
| `gh-auth` | GitHub-legitimasjon |
| `claude-auth` | Claude-legitimasjon |

Autentisering mot GitHub og Claude gjøres én gang og bevares på tvers av omstarter.

---

## Miljøvariabler

Kopier `.env.example` til `.env` ved siden av `compose.yaml`:

```sh
GIT_AUTHOR_NAME=Ditt Navn
GIT_AUTHOR_EMAIL=deg@eksempel.no
```

---

## Verifisering

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Claude Code | `claude --version` | Skriver ut versjon |
| GitHub CLI | `gh --version` | Skriver ut versjon |
| Nettverksrestriksjon | `curl -s --max-time 3 https://example.com` | Timeout |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Anthropic nåbar | API-kall via `claude` | Fungerer |
