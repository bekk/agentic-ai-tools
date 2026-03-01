# Claude Code — nedlåst utviklingscontainer

Nedlåst Java 25/Gradle-container med Claude Code CLI og GitHub CLI. Se [rot-README](../README.md) for delt arkitektur, proxy-oppsett og felles konfigurasjon.

---

## Hurtigstart

Forutsetninger: Docker, `docker-compose`

```sh
# 1. Klon og gå inn i katalogen
git clone https://github.com/bekk/agentic-ai-tools.git
cd agentic-ai-tools/alpine25-gradle-claude

# 2. Sett git-identitet og eventuelt port-mapping
cp .env.example .env
# Rediger .env med navn og e-post

# 3. Bygg imagene (én gang)
docker-compose -f ../shared/compose-proxy.yaml build
docker-compose build

# 4. Start dev-containeren (starter delt proxy automatisk)
./dev.sh

# 5. [I dev-container] Første gang: autentiser gh og Claude
gh auth login  # bruk fingranulert token begrenset til de(t) aktuelle repo(s) og kun Content- og PR-tillatelser
claude  # følg instruksjonene for å koble til API-nøkkel (nettleser kan ikke åpnes — kopier url til nettleser og lim inn token)
gh repo clone <org>/<repo>
cd <repo>

# 6. [I dev-container] Start Claude
claude
```

```sh
# 7. [I dev-container] Få Claude til å bygge repo'et
(claude)> build it

# 8. [I dev-container] Start applikasjonen (port-mappingen må være konfigurert riktig)
./gradlew bootRun  # Hvis Spring Boot benyttes
```

---

## Legitimasjon og persistens

| Volum | Montert i | Innhold |
|-------|-----------|---------|
| `claude-auth` | claude-dev | Claude-legitimasjon (`~/.claude`) |

`gh` og Claude trenger bare autentiseres én gang — legitimasjonen bevares mellom omstarter.

Claude Code kan ikke åpne nettleseren fra containeren. Kopier URL-en manuelt til nettleseren på verten og lim inn token tilbake i terminalen.

---

## Verifisering

| Sjekk | Kommando | Forventet |
|-------|----------|-----------|
| Claude Code | `claude --version` | Skriver ut versjon |
| Anthropic nåbar | API-kall via `claude` | Fungerer |
