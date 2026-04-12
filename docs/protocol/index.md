# Protocol Overview

IEEE 802.11-2024 defines 25 Authentication and Key Management (AKM) suites that govern how stations authenticate and derive encryption keys. This section organizes them into five functional categories and links to detailed family pages.

## AKM Authentication Categories

Every AKM falls into one of five categories based on its authentication mechanism:

1. **Password-Based (PSK)** -- passphrase fed through PBKDF2; offline crackable.
2. **SAE (WPA3-Personal)** -- passphrase used in a Dragonfly PAKE exchange; not offline crackable.
3. **Enterprise (802.1X)** -- authentication delegated to a RADIUS server via EAP.
4. **FILS** -- Fast Initial Link Setup for reduced-latency connections.
5. **Other** -- OWE, TDLS, PASN, and deprecated suites that don't fit the above.

## Quick Reference

| AKM | Name | Category | Offline Crackable? | Standard |
|-----|------|----------|--------------------|----------|
| 1 | 802.1X (SHA-1) | Enterprise | No | 802.11i-2004 |
| 2 | PSK (SHA-1) | PSK | Yes | 802.11i-2004 |
| 3 | FT-802.1X (SHA-256) | Enterprise | No | 802.11r-2008 |
| 4 | FT-PSK (SHA-256) | PSK | Yes | 802.11r-2008 |
| 5 | 802.1X-SHA256 | Enterprise | No | 802.11w-2009 |
| 6 | PSK-SHA256 | PSK | Yes | 802.11w-2009 |
| 7 | TDLS | Other | No | 802.11z-2010 |
| 8 | SAE | SAE | No | 802.11-2012 |
| 9 | FT-SAE (SHA-256) | SAE | No | 802.11-2012 |
| 10 | APPeerKey (deprecated) | Other | N/A | 802.11-2012 |
| 11 | 802.1X Suite B (SHA-256) | Enterprise | No | 802.11ac-2013 |
| 12 | 802.1X Suite B (SHA-384) | Enterprise | No | 802.11ac-2013 |
| 13 | FT-802.1X (SHA-384) | Enterprise | No | 802.11ac-2013 |
| 14 | FILS-SHA256 | FILS | No | 802.11ai-2016 |
| 15 | FILS-SHA384 | FILS | No | 802.11ai-2016 |
| 16 | FT-FILS-SHA256 | FILS | No | 802.11ai-2016 |
| 17 | FT-FILS-SHA384 | FILS | No | 802.11ai-2016 |
| 18 | OWE | Other | No | 802.11-2020 |
| 19 | FT-PSK (SHA-384) | PSK | Yes | 802.11-2020 |
| 20 | PSK-SHA384 | PSK | Yes | 802.11-2020 |
| 21 | PASN | Other | No | 802.11-2024 |
| 22 | 802.1X-SHA384 | Enterprise | No | 802.11-2024 |
| 23 | FT-802.1X-SHA384 | Enterprise | No | 802.11-2024 |
| 24 | SAE-group-dependent | SAE | No | 802.11-2024 |
| 25 | FT-SAE-group-dependent | SAE | No | 802.11-2024 |

## Full Specification Table

<!-- TODO: Readable version of Table 12-11 from 802.11-2024 -->

=== "Key Lengths"

    <!-- Placeholder: table showing KCK, KEK, TK, KDK bit lengths per AKM -->

    Key length details for each AKM will be added here, sourced from Table 12-8.

=== "Algorithms"

    <!-- Placeholder: table showing PRF, KDF, MIC, and Key Wrap algorithms per AKM -->

    Algorithm mappings for each AKM will be added here, sourced from Table 12-11.

## Category Descriptions

### Password-Based (PSK)

AKMs 2, 4, 6, 19, and 20 derive the PMK from a passphrase via PBKDF2, making them vulnerable to offline dictionary attacks when a handshake is captured. This is the primary target for hash extraction tools.

See [PSK Family](psk-family.md) and [FT-PSK Family](ft-psk-family.md).

### SAE (WPA3-Personal)

AKMs 8, 9, 24, and 25 use the Dragonfly PAKE protocol to establish a PMK without ever exposing material that can be attacked offline. Capturing the handshake does not yield a crackable hash.

See [SAE Family](sae-family.md).

### Enterprise (802.1X)

AKMs 1, 3, 5, 11, 12, 13, 22, and 23 delegate authentication to a RADIUS server through the EAP framework. The PMK is derived from the Master Session Key produced by the EAP method, not from a passphrase.

See [Enterprise Family](enterprise-family.md).

### FILS

AKMs 14-17 implement Fast Initial Link Setup to reduce association latency. They combine authentication and association into fewer frames and support both SHA-256 and SHA-384 variants with optional Fast Transition.

See [FILS Family](fils-family.md).

### Other

AKMs 7 (TDLS), 10 (APPeerKey, deprecated), 18 (OWE), and 21 (PASN) serve specialized roles outside the main authentication categories. OWE provides encryption without authentication; PASN enables pre-association security negotiation.

See [Other AKMs](other-family.md).
