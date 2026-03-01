# opencode — nedlåst utviklingscontainer

Nedlåst Java 25/Gradle-container med opencode CLI og GitHub CLI. Se [rot-README](../README.md) for delt arkitektur, proxy-oppsett og felles konfigurasjon.

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

# 3. Bygg imagene (én gang)
docker-compose -f ../shared/compose-proxy.yaml build
docker-compose build

# 4. Start dev-containeren (starter delt proxy automatisk)
./dev.sh

# 5. [I dev-container] Første gang: autentiser gh
gh auth login  # bruk fingranulert token begrenset til de(t) aktuelle repo(s) og kun Content- og PR-tillatelser

# 6. [I dev-container] Klon ditt repo og start opencode
gh repo clone <org>/<repo>
cd <repo>
opencode

# 7. [I dev-container] Få opencode til å bygge repo'et
(opencode)> build it

# 8. [I dev-container] Start applikasjonen (port-mappingen må være konfigurert riktig)
(opencode)> /exit
./gradlew bootRun  # Hvis Spring Boot benyttes
```

---

## Legitimasjon og persistens

| Volum | Montert i | Innhold |
|-------|-----------|---------|
| `opencode-config` | opencode-dev | Opencode-konfig (`~/.config/opencode`) |

`gh` trenger bare autentiseres én gang. Anthropic-tilgang skjer via `ANTHROPIC_API_KEY` i `.env`.

---

## Spesifikke miljøvariabler

```sh
# Påkrevd for opencode
ANTHROPIC_API_KEY=sk-ant-...
```

`ANTHROPIC_API_KEY` er påkrevd for at opencode skal fungere.

---

## Verifisering

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Opencode CLI | `opencode --version` | Skriver ut versjon |
| Anthropic nåbar | API-kall via `opencode` | Fungerer |
