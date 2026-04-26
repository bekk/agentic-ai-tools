#!/usr/bin/env bash
# RoS-generator — harness-agnostisk orkestrator for risiko- og sårbarhetsanalyse
#
# Bruk:
#   bash ros-generate.sh
#
# Konfigurasjon via miljøvariabler:
#   AI_BACKEND    ollama (default) | claude | <vilkårlig kommando som leser prompt fra stdin>
#   OLLAMA_HOST   http://ollama-proxy:11434 (default)
#   OLLAMA_MODEL  modellnavn (påkrevd ved AI_BACKEND=ollama)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_YAML="$SCRIPT_DIR/template.yaml"
SUMMARY_YAML="$SCRIPT_DIR/scenarios-summary.yaml"

AI_BACKEND="${AI_BACKEND:-ollama}"
OLLAMA_HOST="${OLLAMA_HOST:-http://ollama-proxy:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-}"

# ──────────────────────────────────────────────────────────────────
# Hjelpefunksjoner
# ──────────────────────────────────────────────────────────────────

die()  { printf '\nFEIL: %s\n' "$*" >&2; exit 1; }
info() { printf '\033[1;34m%s\033[0m\n' "$*"; }
ok()   { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }

ask() {
    local label="$1" varname="$2" default="${3:-}"
    local hint="${default:+ [$default]}"
    read -r -p "${label}${hint}: " val
    printf -v "$varname" '%s' "${val:-$default}"
}

call_ai() {
    local prompt="$1"
    case "$AI_BACKEND" in
        ollama)
            [[ -n "$OLLAMA_MODEL" ]] || die "Sett OLLAMA_MODEL (f.eks. export OLLAMA_MODEL=llama3.3)"
            curl -sf "${OLLAMA_HOST}/api/generate" \
                -H "Content-Type: application/json" \
                -d "$(jq -n \
                    --arg model "$OLLAMA_MODEL" \
                    --arg prompt "$prompt" \
                    '{model:$model, prompt:$prompt, stream:false, options:{temperature:0.05}}')" \
                | jq -r '.response'
            ;;
        claude)
            claude -p "$prompt"
            ;;
        *)
            # Generisk: send prompt til stdin på kommandoen
            echo "$prompt" | $AI_BACKEND
            ;;
    esac
}

strip_markdown_fences() {
    sed -E '/^```(yaml|yml)?[[:space:]]*$/d'
}

extract_scenario() {
    local title="$1"
    python3 - "$TEMPLATE_YAML" "$title" <<'PYEOF'
import sys, yaml, io

with open(sys.argv[1], encoding='utf-8') as f:
    doc = yaml.safe_load(f)

target = sys.argv[2].strip().replace('​', '')

for s in doc.get('scenarios', []):
    t = s.get('title', '').strip().replace('​', '')
    if t == target:
        buf = io.StringIO()
        # Serialize as a one-element list so yaml.dump uses list syntax
        yaml.dump([s], buf, allow_unicode=True, default_flow_style=False, indent=2, width=100)
        # Prefix every line with 2 spaces so it slots under `scenarios:` in the output file
        lines = buf.getvalue().rstrip('\n').split('\n')
        print('\n'.join(('  ' + l) if l else '' for l in lines))
        sys.exit(0)

print(f"Scenario ikke funnet: '{sys.argv[2]}'", file=sys.stderr)
sys.exit(1)
PYEOF
}

get_scenario_titles() {
    python3 - "$SUMMARY_YAML" <<'PYEOF'
import sys, yaml
with open(sys.argv[1], encoding='utf-8') as f:
    doc = yaml.safe_load(f)
for s in doc.get('scenarios', []):
    print(s['title'])
PYEOF
}

detect_catalog_info() {
    [[ -f "catalog-info.yaml" ]] || return 0
    python3 - "catalog-info.yaml" <<'PYEOF'
import sys, yaml
with open(sys.argv[1], encoding='utf-8') as f:
    d = yaml.safe_load(f) or {}
name = d.get('metadata', {}).get('name', '')
kind = d.get('kind', '').lower()
print(f"{name}\t{kind}")
PYEOF
}

# ──────────────────────────────────────────────────────────────────
# Produktinfo
# ──────────────────────────────────────────────────────────────────

info "=== RoS-generator ==="
echo

catalog_row=$(detect_catalog_info 2>/dev/null || echo "")
catalog_name=$(echo "$catalog_row" | cut -f1)
catalog_kind=$(echo "$catalog_row" | cut -f2)

ask "Produktnavn"                                           PRODUCT_NAME         "${catalog_name:-}"
ask "Type tjeneste (ekstern SaaS, intern API, mobilapp…)"  PRODUCT_TYPE         ""
ask "Formål og brukergruppe (1–2 setninger)"               PRODUCT_DESC         ""
ask "Data som behandles (persondata, gradert, åpne data)"  PRODUCT_DATA         ""
ask "Integrasjoner (tredjeparter, sky, databaser)"         PRODUCT_INTEGRATIONS ""
ask "Kjente risikoforhold"                                  PRODUCT_RISKS        "Ingen kjente"

echo

# ──────────────────────────────────────────────────────────────────
# Output-fil
# ──────────────────────────────────────────────────────────────────

safe_name=$(printf '%s' "$PRODUCT_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/æ/ae/g; s/ø/oe/g; s/å/aa/g' \
    | tr -cs '[:alnum:]-' '-' \
    | sed 's/^-//; s/-$//')

if [[ -n "$catalog_name" && -n "$catalog_kind" ]]; then
    OUTPUT_FILE=".security/risc/${safe_name}.${catalog_name}.${catalog_kind}.risc.yaml"
else
    OUTPUT_FILE=".security/risc/${safe_name}.risc.yaml"
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" <<YAML
schemaVersion: '5.2'
title: "RoS av ${PRODUCT_NAME}"
scope: >-
  RoS for ${PRODUCT_TYPE}: ${PRODUCT_DESC}
scenarios:
YAML

info "Output: $OUTPUT_FILE"
echo

# ──────────────────────────────────────────────────────────────────
# Scenarievurdering — ett AI-kall per scenario
# ──────────────────────────────────────────────────────────────────

PRODUCT_CONTEXT="Navn: ${PRODUCT_NAME}
Type: ${PRODUCT_TYPE}
Beskrivelse: ${PRODUCT_DESC}
Data som behandles: ${PRODUCT_DATA}
Integrasjoner: ${PRODUCT_INTEGRATIONS}
Kjente risikoforhold: ${PRODUCT_RISKS}"

mapfile -t TITLES < <(get_scenario_titles)
TOTAL="${#TITLES[@]}"

for i in "${!TITLES[@]}"; do
    title="${TITLES[$i]}"
    num=$((i + 1))
    info "  [$num/$TOTAL] $title"

    scenario_yaml=$(extract_scenario "$title")

    prompt="Du er en sikkerhetsrådgiver som vurderer ett RoS-scenario.

## Produktkontekst
${PRODUCT_CONTEXT}

## Scenariet (YAML fra mal — behold all formatering eksakt)
${scenario_yaml}

## Oppgave
Gå gjennom hvert action-objekt i scenariet.
For hvert tiltak, sett \`status\` til ett av: OK, Not OK eller N/A.
  - OK       → tiltaket er allerede ivaretatt
  - Not OK   → tiltaket er ikke ivaretatt eller ukjent
  - N/A      → tiltaket er klart ikke relevant for dette produktet

Regler:
- Behold alle ID-er, descriptions, url-felt og remainingRisk eksakt som i inndataene.
- Endre KUN status-feltet per tiltak.
- Behold innrykk og YAML-struktur identisk med inndataene.

Returner KUN det vurderte YAML-blokket.
Ingen forklaring. Ingen markdown-wrapper (\`\`\`yaml eller \`\`\`)."

    result=$(call_ai "$prompt" | strip_markdown_fences)
    printf '%s\n' "$result" >> "$OUTPUT_FILE"

    ok "Scenario $num ferdig"
    echo
done

info "Ferdig → $OUTPUT_FILE"
