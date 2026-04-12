# FILS Family (AKM 14-17)

Fast Initial Link Setup (FILS) reduces the time required for a station to associate and begin data exchange, targeting environments with high station density and frequent (re)associations such as stadiums and transit systems.

## Overview

FILS combines the authentication, association, and key establishment steps into fewer frame exchanges than standard 802.1X. It can use either a shared key (rMSK from a prior EAP exchange cached via FILS or ERP) or a full EAP exchange compressed into the association frames. The result is sub-100ms connection times compared to several hundred milliseconds for standard 802.1X.

## FILS Authentication Flow

<!-- TODO: add Mermaid sequence diagram showing FILS Authentication + Association -->
<!-- Key steps: Authentication frame with FILS Indication, Association Request with ERP/Key Confirm, Association Response with GTK/PTK -->

FILS authentication uses an Authentication frame with the FILS algorithm number, followed by Association Request/Response frames that carry the key exchange material. The AP and STA derive a FILS Key Confirmation Key (KCK) and complete key installation within the association exchange.

## AKM Variants

| AKM | Name | Hash | FT? | Standard |
|-----|------|------|-----|----------|
| 14 | FILS-SHA256 | SHA-256 | No | 802.11ai-2016 |
| 15 | FILS-SHA384 | SHA-384 | No | 802.11ai-2016 |
| 16 | FT-FILS-SHA256 | SHA-256 | Yes | 802.11ai-2016 |
| 17 | FT-FILS-SHA384 | SHA-384 | Yes | 802.11ai-2016 |

AKMs 16 and 17 combine FILS with Fast Transition, enabling both fast initial connection and fast roaming within the same mobility domain.

## Spec References

- FILS protocol: 802.11-2024 Section 12.11
- FILS key derivation: Section 12.11.2
- AKM selectors: Table 9-190
