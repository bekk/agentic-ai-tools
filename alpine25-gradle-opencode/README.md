# Nedlåst utviklingscontainer for agent-støttet utvikling
**Med Java 25, Gradle, GitHub og opencode**

> **Repo:** https://github.com/bekk/agentic-ai-tools

Portabel og nedlåst utviklingscontainer for Java 25, GitHub og opencode. Ingen prosjektkode er bakt inn — imaget gjenbrukes på tvers av repoer — med antakelsen om at Gradle brukes for bygging.

---

## Hurtigstart

Forutsetninger: Docker, `docker-compose`

```sh
# 1. Klon og gå inn i katalogen
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/alpine25-gradle-opencode

# 2. Sett git-identitet og API-nøkkel
cp .env.example .env
# Rediger .env med navn, e-post og ANTHROPIC_API_KEY

# 3. Bygg imaget (én gang)
docker-compose build

# 4. Start dev-containeren (starter proxy-containeren automatisk)
./dev.sh

# 5. Første gang: autentiser gh
gh auth login  # bruk fingranulert token begrenset til de(t) aktuelle repo(s) og kun Content- og PR-tillatelser

# 6. Klon ditt repo og start opencode
gh repo clone <org>/<repo>
cd <repo>
opencode
```

For Gradle-bygg, kjør fra **vertsmaskinen** (ikke inne i dev-containeren):

```sh
# 7. Start gradle-containeren i riktig repo og kjør bygg
./gradle.sh "cd <repo> && ./gradlew build"
```

Når ingen nye avhengigheter trenger å lastes ned, fungerer `./gradlew` fint direkte inne i dev-containeren via den delte gradle-cachen. Bruk `gradle.sh` (opencode-gradle) når avhengigheter endres, siden opencode-dev har begrenset nettverkstilgang.

```sh
# 8. [I dev-containeren] Få opencode til å bygge repo'et (når avhengigheter ikke endres, ellers bruk gradle-containeren)
(opencode)> build it

# 9a. [I gradle-containeren] Start applikasjonen (port-mappingen må være konfigurert riktig)
./gradlew bootRun  # Hvis Spring Boot benyttes

# 9b. [I dev-containeren] Start applikasjonen (port-mappingen må være konfigurert riktig)
(opencode)> /exit
./gradlew bootRun  # Hvis Spring Boot benyttes
```

---

## Motivasjon

Opencode er et kraftig verktøy: det kan lese og skrive filer, kjøre shell-kommandoer og utføre git-operasjoner autonomt. I et agentisk arbeidsflyt øker dette risikoen for utilsiktet datalekkasje, uønskede nettverkskall eller avhengigheter som hentes fra ukjente kilder.

Dette oppsettet begrenser opencode til et strengt kontrollert miljø:

- **Nettverkstilgang** er begrenset til GitHub og Anthropic — opencode kan jobbe med kode og kommunisere med API-et, men ikke nå ut til vilkårlige internett-ressurser.
- **Gradle-bygg** kjøres i en separat container uten nettverksbegrensning, siden nedlasting av avhengigheter fra Maven Central og lignende er nødvendig og forventet.
- **Legitimasjon** (GitHub-token, Anthropic API-nøkkel) lagres i Docker-volumer og miljøvariabler, og eksponeres ikke utenfor container-miljøet.

Målet er å gi opencode akkurat nok tilgang til å være nyttig, og ikke mer.

---

## Arkitektur

```mermaid
graph TD
    host["<b>Host</b>"]

    host -->|"./dev.sh"| dev["<b>opencode-dev</b><br/><br/>JDK 25<br/>opencode CLI<br/>gh CLI<br/>git<br/><br/>Nettverk:<br/>kun via proxy"]
    host -->|"./gradle.sh"| gradle["<b>opencode-gradle</b><br/><br/>JDK 25<br/><br/>Nettverk:<br/>ubegrenset"]
    dev -->|"HTTPS_PROXY"| proxy["<b>opencode-proxy</b><br/><br/>Squid<br/>domene-whitelist<br/><br/>✓ *.anthropic.com<br/>✓ *.github.com<br/>✗ alt annet"]
    proxy --> internet["internett"]

    gradle --- repos
    gradle --- gcache
    dev --- repos[("repos")]
    dev --- gcache[("gradle-cache")]
    dev --- ghauth[("gh-auth")]
    dev --- occonfig[("opencode-config")]
```

Nettverksisolasjon oppnås via Docker-nettverk: `opencode-dev` er kun koblet til et internt nettverk uten internett-ruting. All utgående trafikk går gjennom `opencode-proxy` (Squid), som tillater kun domener listet i `proxy/whitelist.conf`. Filtrering skjer på domenenavn — ikke IP-adresser — og fungerer derfor uavhengig av CDN-rotasjon.

---

## Persistens

Alle data som skal overleve en container-omstart lagres i Docker-volumer:

| Volum | Montert i | Innhold |
|-------|-----------|---------|
| `repos` | dev + gradle | Klonede repoer (`/repos`) |
| `gradle-cache` | dev + gradle | Gradle-cache (`~/.gradle`) — holder daemonen varm |
| `gh-auth` | opencode-dev | GitHub-legitimasjon (`~/.config/gh`) |
| `opencode-config` | opencode-dev | Opencode-konfig (`~/.config/opencode`) |

`gh` trenger bare autentiseres én gang — legitimasjonen bevares mellom omstarter. Anthropic-tilgang skjer via `ANTHROPIC_API_KEY` i `.env`.

---

## Nettverkswhitelist

Tillatte domener er definert i `proxy/whitelist.conf`:

```
.anthropic.com
.github.com
.githubusercontent.com
```

### Legge til et nytt domene

Ingen rebuild og ingen container-restart nødvendig:

```sh
echo ".nyttdomene.com" >> proxy/whitelist.conf
docker exec opencode-proxy squid -k reconfigure
```

### Se hva som blokkeres

```sh
docker logs opencode-proxy | grep DENIED
```

Eksempel på output:
```
TCP_DENIED/403 CONNECT example.com:443
```

---

## Miljøvariabler

Kopier `.env.example` til `.env` ved siden av `compose.yaml`:

```sh
GIT_AUTHOR_NAME=Ditt Navn
GIT_AUTHOR_EMAIL=deg@eksempel.no

# Påkrevd: Anthropic API-nøkkel for opencode
ANTHROPIC_API_KEY=sk-ant-...

# Valgfritt: porter eksponert av opencode-gradle (standardverdi: 8080, 8081)
GRADLE_PORT_1=8080
GRADLE_PORT_2=8081
```

`ANTHROPIC_API_KEY` er påkrevd for at opencode skal fungere. De øvrige variablene har standardverdier.

### Portmapping

`opencode-dev` eksponerer ingen porter — opencode trenger ikke å nås utenfra. `opencode-gradle` eksponerer porter for applikasjoner som kjøres der:

| Variabel | Vertsport (standard) | Containerport |
|----------|----------------------|---------------|
| `GRADLE_PORT_1` | 8080 | 8080 |
| `GRADLE_PORT_2` | 8081 | 8081 |

En app som lytter på port 8080 inne i gradle-containeren nås på `localhost:8080` fra verten.

Portmappinger settes ved container-opprettelse. Hvis du endrer porter etter at `opencode-gradle` allerede kjører, må du fjerne den først:

```sh
docker rm -f opencode-gradle
./gradle.sh
```

---

## Verifisering av Dev-containeren

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Opencode CLI | `opencode --version` | Skriver ut versjon |
| GitHub CLI | `gh --version` | Skriver ut versjon |
| Nettverksrestriksjon | `curl -s --max-time 3 https://example.com` | Feil (blokkert av proxy) |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Anthropic nåbar | API-kall via `opencode` | Fungerer |
| Proxy-logg | `docker logs opencode-proxy \| grep DENIED` | Viser blokkerte forsøk |
