---
name: ros
description: Lag en risiko- og sårbarhetsanalyse (RoS) for et produkt eller en tjeneste. Bruk når noen ber om å lage, generere eller oppdatere en RoS. Produserer gyldig YAML i henhold til RoS-skjemaet.
argument-hint: "[produktbeskrivelse]"
---

# RoS-generator

Du skal lage en risiko- og sårbarhetsanalyse (RoS) som gyldig YAML.

## Fremgangsmåte

Hvis brukeren ikke har oppgitt nok kontekst om produktet, spør om følgende før du genererer:

1. **Produktnavn** — hva heter produktet/tjenesten?
2. **Hva gjør produktet?** — kort beskrivelse av formål og brukergruppe
3. **Type tjeneste** — er det en ekstern SaaS, intern tjeneste, API, mobilapp, o.l.?
4. **Data som behandles** — hvilke kategorier data behandles (persondata, gradert info, åpne data)?
5. **Integrasjoner** — viktige tredjeparter, sky-leverandører, databaser?
6. **Spesielle risikoforhold** — noe teamet allerede vet om som er særlig bekymringsfullt?

Hvis tilstrekkelig informasjon allerede er oppgitt (i $ARGUMENTS eller i samtalen), gå direkte til generering.

## Regler for YAML-generering

Les malen i [template.yaml](template.yaml) og bruk den som utgangspunkt.

**Felt som skal tilpasses produktet:**
- `title`: "Initiell RoS [versjon] [produktnavn]"
- `scope`: Tilpass scopeteksten til produktet. Behold advarselen om at den ikke er komplett.
- `scenarios`: Behold **alle** scenarier fra malen uavhengig av produkttype. Du kan legge til nye scenarier som er spesifikke for produktet.
- For hvert scenario: Tilpass `description` slik at den refererer til det konkrete produktet der det er naturlig.
- `risk.probability` og `risk.consequence`: Behold meldingsverdiene fra malen med mindre du har god grunn til å avvike basert på det brukeren har fortalt.
- `remainingRisk`: Behold malens verdier.

**Felt som skal beholdes uendret:**
- Alle `action`-objekter med sine `ID`-er, `description`-er og referanser (ISO 27002, NIST CSF 2.0 osv.) — disse skal ikke endres
- `schemaVersion`: behold `'5.2'`
- Alle `url`-felt: sett til `''`

**Statussetting for hvert tiltak (`status`):**

Vurder hvert tiltak opp mot det som er kjent om produktet og sett `status` til ett av følgende:

- `OK` — tiltaket er allerede ivaretatt basert på det brukeren har beskrevet
- `Not OK` — tiltaket er ikke ivaretatt eller ukjent
- `N/A` — tiltaket er klart ikke relevant for dette produktet (begrunn gjerne kort i en kommentar hvis mulig)

Hvis du ikke kan avgjøre status for et tiltak ut fra tilgjengelig informasjon, **spør brukeren** før du setter status. Samle opp alle uavklarte tiltak og still spørsmålene samlet — ikke ett og ett.

**ID-generering:**
- Scenario-`ID`er: Generer nye 5-tegns alfanumeriske ID-er (mix av store/små bokstaver og tall, f.eks. `aB3xK`)
- Behold de eksisterende action-`ID`-ene fra malen uendret

## Output

Lever gyldig YAML (uten markdown-blokk rundt). Ikke legg til forklarende tekst etter YAML-en.

Hvis brukeren vil lagre til fil, spør om filnavn og bruk Write-verktøyet.
