# ros — RoS-sandbox

Isolert Docker-miljø for AI-assistert risiko- og sårbarhetsanalyse (RoS). Genererer YAML-filer i RoS-format (`schemaVersion: 5.2`) ved hjelp av en lokal Ollama-modell — ingen data forlater maskinen.

## Arkitektur

```
Host
├── Ollama (kjører på host)
│
└── Docker
    ├── ros-dev           arbeidscontainer (kun tilgang via proxy-net)
    ├── ros-ollama-proxy  nginx-bro til Ollama på host
    └── ros-proxy         Squid-proxy med egress-whitelist
```

| Container | Image | Rolle |
|-----------|-------|-------|
| `ros-dev` | Ubuntu noble (bygges lokalt) | Arbeidscontainer med verktøy og skills |
| `ros-ollama-proxy` | nginx:alpine | Videresender Ollama-kall til host via `host.docker.internal` |
| `ros-proxy` | Squid (fra `../jdk-gradle/proxy`) | Kontrollerer all utgående trafikk mot whitelist |

**Nettverk:**

- `ros-proxy-net` (intern): `ros-dev` kommuniserer med `ros-ollama-proxy` og `ros-proxy`
- `ros-external-net`: `ros-proxy` og `ros-ollama-proxy` har tilgang ut
- `ros-dev` har **ingen** direkte internettilgang — alt HTTP/HTTPS går via Squid-proxyen

**Egress-whitelist** (`whitelist.conf`): GitHub, Google Cloud KMS og OAuth (for SOPS).

**Volumes:**
- `repos` — persistente git-repos
- `gh-auth` — GitHub CLI-autentisering
- `opencode-config` — opencode-konfigurasjon

**Verktøy installert i `ros-dev`:**
`curl`, `git`, `jq`, `ripgrep`, `age`, `python3`, `gh` CLI, `sops`, `opencode`

## Forutsetninger

- Docker og Docker Compose
- Ollama installert og kjørende på host med ønsket modell:
  ```bash
  ollama pull llama3.3
  ```

## Oppsett

```bash
cp .env.example .env
```

Rediger `.env`:

```
GIT_AUTHOR_NAME=Fornavn Etternavn
GIT_AUTHOR_EMAIL=bruker@eksempel.no
OLLAMA_MODEL=llama3.3
```

## Bruk

**Start containeren:**

```bash
./dev.sh              # starter proxy-containere og åpner interaktiv shell
./dev.sh "kommando"   # kjør enkeltkommando og avslutt
```

**RoS-generering inne i containeren:**

```bash
bash ~/.claude/skills/ros/ros-generate.sh
```

Eller via `/ros`-skillen i Claude Code eller opencode.

### RoS-generatoren steg for steg

1. Spør interaktivt om produktinfo (henter navn fra `catalog-info.yaml` om filen finnes i gjeldende katalog)
2. Oppretter `.security/risc/<navn>.risc.yaml` med korrekt YAML-header
3. Evaluerer 7 scenarier sekvensielt — ett Ollama-kall per scenario
4. Setter `status: OK | Not OK | N/A` per tiltak og appender blokken til filen

**Eksempel på output-plassering:**
```
.security/risc/mitt-produkt.risc.yaml
.security/risc/mitt-produkt.katalognavn.component.risc.yaml  # med catalog-info.yaml
```

## Hemmeligheter (SOPS — valgfritt)

For krypterte hemmeligheter med SOPS. Legg til i `.env`:

```
# age-nøkkel
AGE_KEY_FILE=/Users/deg/.config/age/ros.key

# GCP KMS (service account JSON)
GCP_CREDENTIALS_FILE=/Users/deg/.config/gcp/ros-sops-sa.json
```

Begge mountes read-only til `/run/secrets/` i containeren.
