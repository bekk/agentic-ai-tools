# Nedlåst AI-utviklingsmiljø for Java

> Et portabelt, nettverksisolert utviklingscontainer med AI-agenter innebygd — klar til bruk på tvers av repoer.

---

## Motivasjon

AI-agenter er kraftige verktøy — og kraftige verktøy trenger grenser.

En kodingsagent kan lese og skrive filer, kjøre shell-kommandoer og utføre git-operasjoner helt autonomt. Det åpner for utilsiktede hendelser:

- **Datalekkasje** — agenten sender kildekode til ukjente tjenester
- **Ukontrollerte avhengigheter** — tredjepartskode hentes fra vilkårlige kilder
- **Uønskede handlinger** — push til feil branch, API-kall til ukjente endepunkt

**Målet:** gi agenten akkurat nok tilgang til å være nyttig — og ikke mer.

> *For GitHub: bruk fingranulert token begrenset til aktuelle repo(s) med kun Content- og PR-tillatelser. Påse at god kodepraksis er fulgt, og at kodebasen er eller kunne ha vært public.*

---

## Arkitektur

```mermaid
graph TD
    host["<b>Vertsmaskin</b>"]

    host -->|"./dev.sh"| aidev
    host -->|"automatisk"| proxy
    host -->|"docker exec ollama ollama pull"| ollama

    aidev -->|"HTTP_PROXY :3128"| proxy
    aidev -->|"NO_PROXY / direkte"| ollama
    proxy -->|"internett"| internet["🌐 Internett"]

    subgraph proxy-net ["proxy-net (internt Docker-nettverk)"]
        aidev["<b>ai-dev</b><br/>JDK 25 · Gradle<br/>Claude Code · opencode · copilot<br/>gh · git"]
        proxy["<b>dev-proxy</b><br/>Squid<br/>─────────────<br/>✓ *.anthropic.com / claude.ai<br/>✓ *.github.com / *.githubcopilot.com<br/>✓ Maven Central · Gradle repos<br/>✗ alt annet"]
        ollama["<b>ollama</b><br/>Ollama<br/>─────────────<br/>Lokale LLM-modeller"]
    end
```

**Tre containere, to nettverk:**

| Container | Rolle | Nettverkstilgang |
|-----------|-------|-----------------|
| `ai-dev` | Utviklingsmiljø | Kun `proxy-net` (internt) |
| `dev-proxy` | Squid-proxy | `proxy-net` + `external-net` (internett) |
| `ollama` | Lokal LLM-tjener | `proxy-net` + `external-net` (internett for modell-nedlasting) |

All trafikk fra `ai-dev` tvinges gjennom proxyen — Node.js (`undici`), Java (`GRADLE_OPTS`), og curl/wget via `HTTP_PROXY`/`HTTPS_PROXY`. Unntak: `ollama` er listet i `NO_PROXY` og nås direkte container-til-container.

**Persistens i Docker-volumer:**

| Volum | Innhold |
|-------|---------|
| `repos` | Klonede repoer |
| `gradle-cache` | Gradle-cache — holder daemonen varm mellom sesjoner |
| `gh-auth` | GitHub-legitimasjon |
| `claude-auth` | Claude Code-legitimasjon |
| `opencode-config` | opencode-konfigurasjon |
| `ollama-models` | Nedlastede LLM-modeller |

---

## Kom i gang — steg for steg

**Forutsetninger:** Docker, `docker-compose` (og f.eks. Colima på Mac)

```sh
# 0. [Vertsmaskin] Gi nok minne og diskplass til container-tjenesten. Diskplass er hvis du kjører lokale modeller
colima start --memory 8 --disk 100
```

```sh
# 1. [Vertsmaskin] Klon repoet
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/dev-sandbox/jdk-gradle

# 2. [Vertsmaskin] Sett identitet og API-nøkkel
cp .env.example .env
# Rediger .env — fyll inn navn, e-post og ANTHROPIC_API_KEY

# 3. [Vertsmaskin] Bygg imagene (kun første gang)
docker-compose build

# 4. [Vertsmaskin] Start containerne
./dev.sh
```

```sh
# 5. [ai-dev] Første gang: autentiser GitHub
gh auth login
#    → bruk fingranulert token med kun Content- og PR-tillatelser

# 6. [ai-dev] Klon ditt prosjektrepo
gh repo clone <org>/<repo>
cd <repo>

# 7. [ai-dev] Start en AI-agent og sett den i gang
claude        # Følg eventuell autentiseringsflyt første gang
(ai)> bygg prosjektet og fiks eventuelle kompileringsfeil

# — eller med opencode —
opencode      # Krever miljøvariabel for claude sin api-nøkkel 
(ai)> bygg prosjektet og fiks eventuelle kompileringsfeil

# — eller med GitHub Copilot CLI —
copilot       # Allerede logget på med gh auth login
(ai)> bygg prosjektet og fiks eventuelle kompileringsfeil

# 8. [Vertsmaskin] Åpne et nytt shell mot samme container
./shell.sh
./gradlew bootRun    # hvis Spring Boot
```

**Autentiseringstips:**
- **Claude Code:** `BROWSER=/bin/echo` gjør at URL skrives til terminalen — kopier og åpne i nettleseren på verten
- **opencode:** bruker `ANTHROPIC_API_KEY` fra `.env` — ingen manuell login
- **copilot:** bruker GitHub-legitimasjonen fra `gh auth login` — ingen ekstra steg

---

## Ollama — lokale LLM-modeller

Sandkassen inkluderer en `ollama`-container på `proxy-net` som lar deg kjøre lokale språkmodeller uten internett-tilgang fra `ai-dev`. Modellene lagres i et eget Docker-volum og overlever container-omstart.

### Starte Ollama

`ollama`-containeren er valgfri og startes separat fra resten av sandkassen:

```sh
# [Vertsmaskin] Start Ollama-containeren
docker-compose up -d ollama
```

### Laste ned en modell

`ollama`-containeren har tilgang til `external-net` slik at den kan laste ned modeller direkte:

```sh
# [Vertsmaskin] Last ned en modell (lagres i ollama-models-volumet)
docker exec ollama ollama pull qwen3-coder-next

# Andre eksempler
docker exec ollama ollama pull qwen3-coder          # 19 GB
docker exec ollama ollama pull llama3.3             # 43 GB
```

> Modeller kan være mange titalls GB. Nedlastingen skjer kun én gang — volumet bevarer dem mellom omstarter.

### Bruke Ollama fra ai-dev

`ai-dev` når Ollama direkte på `http://ollama:11434/v1` (omgår proxyen via `NO_PROXY`). opencode er forhåndskonfigurert med Ollama som provider:

```sh
# [ai-dev] Bruk opencode med en lokal modell
opencode --model ollama/qwen3-coder-next

# [ai-dev] List tilgjengelige modeller
curl http://ollama:11434/api/tags

# [ai-dev] Kall API-et direkte
curl http://ollama:11434/api/generate -d '{
  "model": "qwen3-coder-next",
  "prompt": "Forklar denne Java-koden",
  "stream": false
}'
```

### Verifisering

```sh
# [Vertsmaskin] Sjekk at Ollama kjører
docker ps | grep ollama

# [ai-dev] Bekreft at modellen er tilgjengelig
curl -s http://ollama:11434/api/tags | jq '.models[].name'
```

---

## Fordeler og ulemper

### Fordeler

| | |
|---|---|
| **Nettverksisolasjon** | Agenten kan ikke nå vilkårlige internett-ressurser. Whitelisten er eksplisitt og enkel å revidere. |
| **Ingen kode bakt inn** | Imaget er generisk — det samme imaget gjenbrukes på tvers av alle Java/Gradle-repoer. |
| **Legitimasjon i volumer** | Tokens og nøkler lever utenfor kildekoden og overlever container-omstart. |
| **Tre AI-verktøy i ett** | Claude Code (agentic), opencode (alternativ UI), copilot (CLI-spørsmål og forklaringer). |
| **Lokale modeller** | Ollama på `proxy-net` gir tilgang til lokale LLM-er uten at modelltrafikk forlater maskinen. |
| **Live whitelist-endring** | Nytt domene kan legges til uten rebuild eller container-restart. |
| **Reproduserbart** | Alle avhengigheter er pinnet i Dockerfile — samme image på alle maskiner. |

### Ulemper

| | |
|---|---|
| **Bygg tar tid** | `docker-compose build` laster ned JDK, Node.js, tre AI-verktøy — plan for 5–10 min ved første bygg. |
| **Minnekrav** | Colima bør ha minst 8 GB for å kjøre JVM + AI-prosesser komfortabelt. |
| **Whitelist-vedlikehold** | Nye tjenester (f.eks. private artifact-registre) krever manuell tillegg i `whitelist.conf`. |
| **Ingen GUI** | Rent CLI-miljø — IDE-integrasjoner (VS Code Remote, IntelliJ Gateway) krever ekstra oppsett. |
| **Statisk proxy-konfig** | Squid-proxyen er enkel — ingen autentisering, rate limiting eller detaljert logging per agent. |

---

## Veien videre

**Nærmeste tiltak:**

- [ ] Private artifact-registre (Nexus, Artifactory) — legg til domener i whitelist og evt. credentials i volum
- [ ] IDE-integrasjon — VS Code Remote Containers eller IntelliJ Gateway mot `ai-dev`
- [ ] Flere språk/byggverktøy — variant med Maven, Node.js-prosjekter, Python

**Mer ambisiøst:**

- [ ] Egendefinert proxy-policy per agent (f.eks. strengere regler for autonome kjøringer)
- [ ] Auditlogg — strukturert logging av alle agenthandlinger (fil, git, nett)
- [ ] CI-integrasjon — kjør agenten i en engangskontainer som del av PR-prosessen
- [ ] Secrets-håndtering — integrasjon med Vault eller cloud-native secrets manager i stedet for `.env`

---

## Rask verifisering

```sh
# Kjør inne i ai-dev etter oppstart:
claude --version       # Claude Code installert
opencode --version     # opencode installert
copilot --version      # GitHub Copilot CLI installert
gh --version           # GitHub CLI installert

curl -s --max-time 3 https://example.com          # → blokkert av proxy
curl -s https://api.github.com/zen                # → returnerer et sitat

docker logs dev-proxy | grep DENIED               # → viser blokkerte forsøk

# Ollama (hvis startet):
curl -s http://ollama:11434/api/tags              # → liste over nedlastede modeller
```
