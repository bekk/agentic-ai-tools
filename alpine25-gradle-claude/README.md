# Nedlåst utviklingscontainer for agent-støttet utvikling
**Med Java 25, Gradle, GitHub og Claude)**

> **Repo:** https://github.com/bekk/agentic-ai-tools

Utviklingsmiljøet består av to samarbeidende containere:
1. Nedlåst dev-container for Java 25, GitHub og Claude Code.
2. Åpen gradle-container for Java 25 og Gradle. Brukes til å laste ned avhengigheter og kjøre opp applikasjon

Ingen prosjektkode er bakt inn — imaget gjenbrukes på tvers av repoer – med antakelsen om at Gradle brukes for bygging.

*Forutsetningen er at god kodepraksis er fulgt for repo'et, og at det enten er eller kunne ha vært public*

---

## Hurtigstart

Forutsetninger: Docker, `docker-compose`

```sh
# 1. [På vertsmaskin] Klon og gå inn i katalogen
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/alpine25-gradle-claude

# 2. [På vertsmaskin] Sett git-identitet og eventuelt port-mapping
cp .env.example .env
# Rediger .env med navn, e-post og porter

# 3. [På vertsmaskin] Bygg imagene (én gang)
docker-compose build

# 4. [På vertsmaskin] Start dev-containeren
./dev.sh

# 5. [I dev-container] Første gang: autentiser gh og Claude
gh auth login  # bruk fingranulert token begrenset til de(t) aktuelle repo(s) og kun Content- og PR-tillatelser
claude  # følg instruksjonene for å koble til API-nøkkel (nettleser kan ikke åpnes, så url må kopieres til nettleser og token limes tilbake)
gh repo clone <org>/<repo>
cd <repo>

# 6. [I dev-container] Start Claude
claude
```

For Gradle-bygg, kjør fra **vertsmaskinen** (ikke inne i dev-containeren):

```sh
# 7. [På vertsmaskin] Start gradle-containeren i riktig repo og kjør bygging med Gradle i containeren
./gradle.sh "cd <repo> && ./gradlew build"
```

Når ingen nye avhengigheter trenger å lastes ned, fungerer `./gradlew` fint direkte inne i dev-containeren via den delte gradle-cachen. Bruk `gradle.sh` (claude-gradle) når avhengigheter endres, siden claude-dev har begrenset nettverkstilgang.

```sh
# 8. [I dev-container] Få Claude til å bygge repo'et (når avhengigheter ikke endres, ellers bruk gradle-containeren)
(claude)> build it

# 9. [I gradle-container] Start applikasjonen (port-mappingen må være konfigurert riktig)
./gradlew bootRun  # Hvis Spring Boot benyttes
```

---

## Motivasjon

Claude Code er et kraftig verktøy: det kan lese og skrive filer, kjøre shell-kommandoer og utføre git-operasjoner autonomt. I et agentisk arbeidsflyt øker dette risikoen for utilsiktet datalekkasje, uønskede nettverkskall eller avhengigheter som hentes fra ukjente kilder.

Dette oppsettet begrenser Claude til et strengt kontrollert miljø:

- **Nettverkstilgang** er begrenset via en Squid-proxy — Claude kan jobbe med kode og kommunisere med API-et sitt, men ikke nå ut til vilkårlige internett-ressurser.
- **Gradle-bygg** kjøres i en separat container uten nettverksbegrensning, siden nedlasting av avhengigheter fra Maven Central og lignende er nødvendig og forventet.
- **Legitimasjon** (GitHub, Claude) lagres i Docker-volumer og eksponeres ikke utenfor container-miljøet.

Målet er å gi Claude akkurat nok tilgang til å være nyttig, og ikke mer.

---

## Arkitektur

```mermaid
graph TD
    host["<b>Vertsmaskin</b>"]

    host -->|"./dev.sh"| dev["<b>claude-dev</b><br/><br/>JDK 25<br/>Claude Code CLI<br/>gh CLI<br/>git"]
    host -->|"./gradle.sh"| gradle["<b>claude-gradle</b><br/><br/>JDK 25<br/><br/>Nettverk:<br/>ubegrenset"]
    host -->|"(automatisk)"| proxy["<b>claude-proxy</b><br/><br/>Squid<br/><br/>Tillatte domener:<br/>✓ *.anthropic.com<br/>✓ claude.ai<br/>✓ *.github.com<br/>✗ alt annet"]

    dev -->|"HTTP_PROXY :3128"| proxy
    proxy -->|"internett"| internet["Internett"]

    gradle --- repos
    gradle --- gcache
    dev --- repos[("repos")]
    dev --- gcache[("gradle-cache")]
    dev --- ghauth[("gh-auth")]
    dev --- clauth[("claude-auth")]
```

`claude-dev` er koblet kun til det interne nettverket `dev-internal`. `claude-proxy` er bro mellom det interne nettverket og internett, og slipper kun gjennom domener på whitelisten.

---

## Nettverkswhitelist

Tillatte domener er definert i `whitelist.conf`:

```
.anthropic.com
claude.ai
.github.com
.githubusercontent.com
```

Legg til domener her ved behov (f.eks. for Maven-speil eller andre API-er). Start proxy-containeren på nytt etter endringer:

```sh
docker restart claude-proxy
```

---

## Persistens

Alle data som skal overleve en container-omstart lagres i Docker-volumer:

| Volum | Montert i | Innhold |
|-------|-----------|---------|
| `repos` | begge | Klonede repoer (`/repos`) |
| `gradle-cache` | begge | Gradle-cache (`~/.gradle`) — holder daemonen varm |
| `gh-auth` | claude-dev | GitHub-legitimasjon (`~/.config/gh`) |
| `claude-auth` | claude-dev | Claude-legitimasjon (`~/.claude`) |

`gh` og Claude trenger bare autentiseres én gang — legitimasjonen bevares mellom omstarter.

---

## Miljøvariabler

Kopier `.env.example` til `.env` ved siden av `compose.yaml`:

```sh
GIT_AUTHOR_NAME=Ditt Navn
GIT_AUTHOR_EMAIL=deg@eksempel.no

# Valgfritt: porter eksponert av claude-gradle (standardverdi: 8080, 8081)
GRADLE_PORT_1=8080
GRADLE_PORT_2=8081
```

`.env` er valgfritt — standardverdiene brukes hvis filen mangler.

### Portmapping

`claude-dev` eksponerer ingen porter — Claude trenger ikke å nås utenfra. `claude-gradle` eksponerer porter for applikasjoner som kjøres der:

| Variabel | Vertsport (standard) | Containerport |
|----------|----------------------|---------------|
| `GRADLE_PORT_1` | 8080 | 8080 |
| `GRADLE_PORT_2` | 8081 | 8081 |

En app som lytter på port 8080 inne i gradle-containeren nås på `localhost:8080` fra verten.

Portmappinger settes ved container-opprettelse. Hvis du endrer porter etter at `claude-gradle` allerede kjører, må du fjerne den først:

```sh
docker rm -f claude-gradle
./gradle.sh
```

---

## Verifisering av Dev-containeren

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Claude Code | `claude --version` | Skriver ut versjon |
| GitHub CLI | `gh --version` | Skriver ut versjon |
| Nettverksrestriksjon | `curl -s --max-time 3 https://example.com` | Blokkert av proxy |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Anthropic nåbar | API-kall via `claude` | Fungerer |
| Proxy-logger | `docker logs claude-proxy \| grep DENIED` | Viser blokkerte forsøk |
