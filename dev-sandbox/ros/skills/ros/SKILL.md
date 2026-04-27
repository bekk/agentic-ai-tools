---
name: ros
description: Lag en risiko- og sårbarhetsanalyse (RoS) for et produkt eller en tjeneste. Bruk når noen ber om å lage, generere eller oppdatere en RoS. Produserer gyldig YAML i henhold til RoS-skjemaet.
argument-hint: "[produktbeskrivelse]"
---

# RoS-generator

Kjør skriptet som håndterer innsamling av produktinfo og scenarievurdering:

```bash
bash ~/.claude/skills/ros/ros-generate.sh
```

Scriptet:
1. Spør interaktivt om produktinfo (henter navn fra `catalog-info.yaml` om det finnes i gjeldende katalog)
2. Oppretter `.security/risc/<navn>.risc.yaml` med korrekt YAML-header
3. Vurderer alle 7 scenarier sekvensielt — ett isolert `claude -p`-kall per scenario
4. Appender hvert vurdert scenario-blokk til output-filen fortløpende

Bekreft filstien til brukeren når scriptet er ferdig.
