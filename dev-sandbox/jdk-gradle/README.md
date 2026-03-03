# jdk-gradle

Dev-container med JDK 25, Claude Code, opencode og copilot — AI-CLI-verktøy i ett image. Nettverkstilgang er begrenset via Squid-proxy.

---

## Hurtigstart

Forutsetninger: Docker, `docker-compose`
```sh
# Gi nok minne til container-tjenesten, f.eks colima:
colima start --memory 8
```

```sh
# 1. [På vertsmaskin] Klon og gå inn i katalogen
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/dev-sandbox/jdk-gradle

# 2. [På vertsmaskin] Sett git-identitet og API-nøkkel
cp .env.example .env
# Rediger .env med navn, e-post og ANTHROPIC_API_KEY

# 3. [På vertsmaskin] Bygg imagene (én gang)
docker-compose build

# 4. [På vertsmaskin] Start dev-containeren (starter proxy automatisk)
./dev.sh

# 5. [I dev-container] Første gang: autentiser gh
gh auth login        # bruk fingranulert token begrenset til de(t) aktuelle repo(s) og kun Content- og PR-tillatelser

# 6. [I dev-container] Klon ditt repo
gh repo clone <org>/<repo>
cd <repo>

# 7a. [I dev-container] Første gang: autentiser Claude Code hvis ikke env-variabel
claude               # følg instruksjonene — kopier URL til nettleseren på verten og lim inn token

# 7b. [I dev-container] Start opencode. Autentisert mot Anthropic gjennom env-variabe
opencode               # følg instruksjonene — kopier URL til nettleseren på verten og lim inn token

# 8. [I dev-container] Få agenten til å bygge repo'et
(ai)> build it

# 8a. [På vertsmaskin] Start nytt shell og start applikasjonen
./shell.sh
./gradlew bootRun    # hvis Spring Boot benyttes

# 8b. [I dev-container] Start applikasjonen (port-mappingen må være konfigurert riktig)
(ai)> /exit
./gradlew bootRun    # hvis Spring Boot benyttes
```
---

## Autentisering

### Claude Code

```sh
# Inne i containeren:
claude
# Følg instruksjonen — åpne URL-en på verten og lim inn koden
```

> **Tips:** Claude Code forsøker å åpne URL-en automatisk, men inne i containeren settes `BROWSER=/bin/echo` — URL-en skrives da ut i terminalen. Kopier den og åpne i nettleseren på verten.

Legitimasjonen lagres i volumet `claude-auth` (`~/.claude`) og overlever container-omstart.

### opencode

opencode bruker `ANTHROPIC_API_KEY` fra miljøet. Sett nøkkelen i `.env`-filen:

```
ANTHROPIC_API_KEY=sk-ant-...
```

Konfigurasjonen lagres i volumet `opencode-config` (`~/.config/opencode`) og opprettes automatisk ved første oppstart.

### copilot

`copilot` bruker GitHub-legitimasjonen fra `gh auth login` — ingen separat autentisering nødvendig.

```sh
copilot explain "git rebase -i HEAD~3"
copilot suggest "angre siste commit uten å miste endringer"
```

---

## Volumer

| Volum | Innhold |
|-------|---------|
| `repos` | Klonede repoer (`/repos`) |
| `gradle-cache` | Gradle-cache (`~/.gradle`) |
| `gh-auth` | GitHub-legitimasjon (`~/.config/gh`) |
| `claude-auth` | Claude Code-legitimasjon (`~/.claude`) |
| `opencode-config` | opencode-konfigurasjon (`~/.config/opencode`) |

---

## Miljøvariabler

| Variabel | Beskrivelse | Standardverdi |
|----------|-------------|---------------|
| `GIT_AUTHOR_NAME` | Git-brukernavn | `Dev` |
| `GIT_AUTHOR_EMAIL` | Git-e-post | `dev@local` |
| `ANTHROPIC_API_KEY` | Anthropic API-nøkkel (påkrevd for opencode) | — |
| `GRADLE_PORT_1` | Vertsport → 8080 i container | `8080` |
| `GRADLE_PORT_2` | Vertsport → 8081 i container | `8081` |

---

## Nettverkswhitelist

Tillatte domener er definert i `whitelist.conf`. Endre domener uten rebuild:

```sh
echo ".nyttdomene.com" >> whitelist.conf
docker exec dev-proxy squid -k reconfigure
```

---

## Verifisering

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Claude Code | `claude --version` | Skriver ut versjon |
| opencode | `opencode --version` | Skriver ut versjon |
| copilot | `copilot --version` | Skriver ut versjon |
| GitHub CLI | `gh --version` | Skriver ut versjon |
| Gradle-avhengigheter | `./gradlew dependencies` | Lastes ned via proxy |
| Nettverksrestriksjon | `curl -s --max-time 3 https://example.com` | Blokkert av proxy |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Proxy-logger | `docker logs dev-proxy \| grep DENIED` | Viser blokkerte forsøk |
