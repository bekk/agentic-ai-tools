# jdk-anthropic

Dev-container med JDK 25, Claude Code og opencode — begge AI-CLI-verktøy i ett image. Nettverkstilgang er begrenset via Squid-proxy.

---

## Hurtigstart

```sh
cp .env.example .env
# Fyll inn GIT_AUTHOR_NAME, GIT_AUTHOR_EMAIL og ANTHROPIC_API_KEY
chmod +x dev.sh
./dev.sh
```

Første gang bygges imaget automatisk. Deretter starter `dev-proxy` og `ai-dev`, og du får en bash-sesjon inne i containeren.

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
| GitHub CLI | `gh --version` | Skriver ut versjon |
| Gradle-avhengigheter | `./gradlew dependencies` | Lastes ned via proxy |
| Nettverksrestriksjon | `curl -s --max-time 3 https://example.com` | Blokkert av proxy |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Proxy-logger | `docker logs dev-proxy \| grep DENIED` | Viser blokkerte forsøk |
