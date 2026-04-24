---
name: ros
description: Lag en risiko- og sårbarhetsanalyse (RoS) for et produkt eller en tjeneste. Bruk når noen ber om å lage, generere eller oppdatere en RoS. Produserer gyldig YAML i henhold til RoS-skjemaet.
argument-hint: "[produktbeskrivelse]"
---

# RoS-generator

Du skal lage en risiko- og sårbarhetsanalyse (RoS) som gyldig YAML.

## Fremgangsmåte

Sjekk markdown og yaml-filer i kodebasen. Ting du vil ha svar på er:

1. **Navn** — hva heter produktet, tjenesten eller komponenten?
2. **Hva gjør produktet/tjenesten/komponenten?** — kort beskrivelse av formål og brukergruppe
3. **Type tjeneste** — er det en ekstern SaaS, intern tjeneste, API, mobilapp, o.l.?
4. **Data som behandles** — hvilke kategorier data behandles (persondata, gradert info, åpne data)?
5. **Integrasjoner** — viktige tredjeparter, sky-leverandører, databaser?
6. **Spesielle risikoforhold** — noe teamet allerede vet om som er særlig bekymringsfullt?

Hvis du ikke finner svarene, spør brukeren. Hvis det er en eller flere dokumentasjonsfiler som burde inneholdt informasjonen, spør brukeren om du skal oppdatere dem før du fortsetter.

## Regler for YAML-generering

Les malen i [template.yaml](template.yaml) og bruk den som utgangspunkt.

**Felt som skal tilpasses produktet:**
- `title`: "RoS av [Navn]"
- `scope`: Tilpass scopeteksten til produktet. Fjern advarselen om at den ikke er komplett.
- `scenarios`: Behold **alle** scenarier fra malen uavhengig av produkttype. Legg heller ikke til nye scenarier
- For hvert scenario: 
- `risk.probability` og `risk.consequence`: Behold meldingsverdiene fra malen med mindre du har god grunn til å avvike basert på det brukeren har fortalt.
- `remainingRisk`: Behold malens verdier.

**Felt som skal beholdes uendret:**
- Alle `action`-objekter med sine `ID`-er, `description`-er og referanser (ISO 27002, NIST CSF 2.0 osv.) — disse skal ikke endres
- `schemaVersion`: behold `'5.2'`
- Alle `url`-felt: sett til `''`

**Statussetting for hver action (`status`):**

Vurder hver action opp mot det som er kjent om produktet og sett `status` til ett av følgende:

- `OK` — tiltaket er allerede ivaretatt basert på det brukeren har beskrevet
- `Not OK` — tiltaket er ikke ivaretatt eller ukjent
- `N/A` — tiltaket er klart ikke relevant for dette produktet (begrunn gjerne kort i en kommentar hvis mulig)

Hvis du ikke kan avgjøre status for et tiltak ut fra tilgjengelig informasjon, **spør brukeren** før du setter status. **Ellers gi en kort forklaring på hvorfor status blir satt til den verdien.** 

**ID-generering:**
- Scenario-`ID`er: Generer nye 5-tegns alfanumeriske ID-er (mix av store/små bokstaver og tall, f.eks. `aB3xK`)
- Behold de eksisterende action-`ID`-ene fra malen uendret

## Output

Lever gyldig YAML (uten markdown-blokk rundt). Ikke legg til forklarende tekst etter YAML-en. Filen skal lages i mappen .security/risc og ha et filnavn på formatet <title>.<backstage-entity-ID>.<backstage-kind>.risc.yaml. <backstage-id> og <backstage-kind> finnes i catalog-info.yaml i rot-katalogen. Hvis catalog-info.yaml ikke finnes, bruk formatet <title>.risc.yaml. Hvis catalog-info.yaml er tvertydig, spør brukeren om backstage kind og ID til entiteten.

Hvis brukeren vil lagre til fil, spør om filnavn og bruk Write-verktøyet.
