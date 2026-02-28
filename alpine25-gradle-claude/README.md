# Frittstående dev-container (Kotlin/JVM/Gradle + Claude)

> **Repo:** https://github.com/bekk/agentic-ai-tools

En portabel dev-container som fungerer for ethvert Kotlin/JVM/Gradle-prosjekt. Alle verktøy er bakt inn i imaget; prosjektet ditt klones inn i et navngitt Docker-volum ved oppstart. Ingen prosjektkode er bakt inn, så imaget kan gjenbrukes for ethvert repo.

## Innhold

- JDK 25 (`eclipse-temurin:25-alpine`)
- `bash`, `curl`, `git`, `iptables`
- `gh` (GitHub CLI)
- `node` / `npm`
- `claude` (Claude Code CLI via `@anthropic-ai/claude-code`)

Ingen Gradle-binary — hvert prosjekt bruker sin egen `./gradlew`.

## Nettverkspolicy

Etter første oppstart begrenses utgående trafikk til **GitHub og Anthropic** via iptables. Alt annet blokkeres. Krever `--cap-add=NET_ADMIN` (satt i `compose.yaml`).

Gradle-bygg kjøres i den separate `gradle`-tjenesten som har ubegrenset nettverkstilgang. Gradle-cachen deles mellom begge tjenestene via et navngitt volum.

DNS (port 53) er alltid tillatt slik at `gh` og `claude` kan slå opp vertsnavn ved kjøring.

## Kom i gang

### 1. Bygg imaget

```sh
docker-compose -f alpine25-gradle-claude/compose.yaml build
```

### 2. Start et interaktivt skall

```sh
docker-compose -f alpine25-gradle-claude/compose.yaml run dev
```

Nettverket begrenses til GitHub + Anthropic ved oppstart. Gradle-cache leses fra `~/.gradle` på verten.

### 3. Autentisering

**Claude:** legitimasjon leses fra `~/.claude` på vertsmaskinen (bind-mountet inn i containeren). Ingen oppsett nødvendig hvis du allerede er innlogget lokalt.

**GitHub:** kjør `gh auth login` inne i containeren ved første gangs bruk. Legitimasjon lagres i `gh-auth`-volumet og bevares på tvers av omstarter.

### 4. Klon et repo og begynn å jobbe

```sh
gh repo fork kartverket/backstage-plugin-risk-scorecard-backend --clone
cd backstage-plugin-risk-scorecard-backend
git checkout -b min-feature
claude
```

### 5. Bygg prosjektet (gradle-tjeneste)

Kjør Gradle-bygg i den ubegrensede `gradle`-tjenesten via `gradle.sh`. Containeren kjører
persistent slik at Gradle-daemonen forblir varm mellom bygg:

```sh
# Åpne et skall i gradle-containeren (starter den hvis den ikke kjører)
./alpine25-gradle-claude/gradle.sh

# Eller kjør en enkelt kommando direkte
./alpine25-gradle-claude/gradle.sh "cd backstage-plugin-risk-scorecard-backend && ./gradlew build"
```

### 6. Åpne en PR (dev-tjeneste)

```sh
git add -p && git commit -m "feat: min endring"
git push -u origin min-feature
gh pr create --fill
```

## Starte en eksisterende container på nytt

Uten `--rm` bevares containeren etter `exit`. For å gå inn igjen:

```sh
docker-compose -f alpine25-gradle-claude/compose.yaml start
docker-compose -f alpine25-gradle-claude/compose.yaml exec dev bash
```

## Miljøvariabler

Kopier `.env.example` til `.env` ved siden av `compose.yaml` og fyll inn verdiene:

```sh
GIT_AUTHOR_NAME=Ditt Navn
GIT_AUTHOR_EMAIL=deg@eksempel.no
```

## Sjekkliste for verifisering

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Claude Code tilgjengelig | `claude --version` | Skriver ut versjon |
| gh CLI tilgjengelig | `gh --version` | Skriver ut versjon |
| git fungerer | `git log --oneline -3` | Viser nylige commits |
| Gradle fungerer | `./gradlew build -x test` | Lykkes |
| Nettverk blokkert | `curl -s --max-time 3 https://example.com` | Timeout |
| GitHub nåbar | `curl -s https://api.github.com/zen` | Returnerer et sitat |
| Anthropic nåbar | API-kall via `claude` | Fungerer |
