# Protocol Overview

IEEE 802.11-2024 defines 25 Authentication and Key Management (AKM) suites
that govern how stations authenticate and derive encryption keys. This section
organizes them into five functional categories and links to family pages.

## AKM Authentication Categories

Every AKM falls into one of five categories:

1. **Password-Based (PSK)** — passphrase fed through PBKDF2; offline crackable.
2. **SAE (WPA3-Personal)** — passphrase used in a Dragonfly PAKE exchange; not offline crackable.
3. **Enterprise (802.1X)** — authentication delegated to a RADIUS server via EAP.
4. **FILS** — Fast Initial Link Setup for reduced-latency connections.
5. **Other** — OWE, TDLS, PASN, and deprecated suites.

## Quick Reference

| AKM | Name | Category | Offline Crackable? | Standard |
|-----|------|----------|--------------------|----------|
| 1 | 802.1X (SHA-1) | Enterprise | No | 802.11i-2004 |
| 2 | PSK (SHA-1) | PSK | **Yes** | 802.11i-2004 |
| 3 | FT-802.1X (SHA-256) | Enterprise | No | 802.11r-2008 |
| 4 | FT-PSK (SHA-256) | PSK | **Yes** | 802.11r-2008 |
| 5 | 802.1X-SHA256 | Enterprise | No | 802.11w-2009 |
| 6 | PSK-SHA256 | PSK | **Yes** (EAPOL) / BROKEN (PMKID) | 802.11w-2009 |
| 7 | TDLS | Other | No | 802.11z-2010 |
| 8 | SAE | SAE | No | 802.11-2012 |
| 9 | FT-SAE (SHA-256) | SAE | No | 802.11-2012 |
| 10 | APPeerKey | Other (deprecated) | N/A | 802.11-2012 |
| 11 | 802.1X Suite B (SHA-256) | Enterprise | No | 802.11ac-2013 |
| 12 | 802.1X Suite B (SHA-384) | Enterprise | No | 802.11ac-2013 |
| 13 | FT-802.1X (SHA-384) | Enterprise | No | 802.11ac-2013 |
| 14 | FILS-SHA256 | FILS | No | 802.11ai-2016 |
| 15 | FILS-SHA384 | FILS | No | 802.11ai-2016 |
| 16 | FT-FILS-SHA256 | FILS | No | 802.11ai-2016 |
| 17 | FT-FILS-SHA384 | FILS | No | 802.11ai-2016 |
| 18 | OWE | Other | No | 802.11-2020 |
| 19 | FT-PSK (SHA-384) | PSK | **Yes** | 802.11-2020 |
| 20 | PSK-SHA384 | PSK | **Yes** | 802.11-2020 |
| 21 | PASN | Other | No | 802.11-2024 |
| 22 | 802.1X-SHA384 | Enterprise | No | 802.11-2024 |
| 23 | FT-802.1X-SHA384 | Enterprise | No | 802.11-2024 |
| 24 | SAE (group-dependent) | SAE | No | 802.11-2024 |
| 25 | FT-SAE (group-dependent) | SAE | No | 802.11-2024 |

## Full Specification Tables

=== "Key Lengths"

    Key lengths from IEEE 802.11-2024 Table 12-8:

    | AKM | KCK | KEK | TK (CCMP) | TK (GCMP-256) |
    |-----|-----|-----|-----------|---------------|
    | 1, 2 | 128 | 128 | 128 | — |
    | 3, 4, 5, 6 | 128 | 128 | 128 | — |
    | 8, 9 (SAE) | 128 | 128 | 128 | — |
    | 11 (Suite B-128) | 128 | 128 | 128 | — |
    | 12, 13 (Suite B-192) | 192 | 256 | — | 256 |
    | 14–17 (FILS) | 256 | 256 | 256 | 256 |
    | 19, 20 | 192 | 256 | — | 256 |
    | 22, 23 | 192 | 256 | — | 256 |
    | 24, 25 | group-dependent | group-dependent | — | — |

=== "Algorithms"

    PTK derivation and MIC algorithms from IEEE 802.11-2024 Table 12-11:

    | AKM | PTK KDF | Key Descriptor Version | MIC algorithm | Key wrap |
    |-----|---------|----------------------|---------------|---------|
    | 1, 2 | PRF (HMAC-SHA1) | 1 (TKIP) or 2 (CCMP) | HMAC-MD5 (kv1) / HMAC-SHA1-128 (kv2) | RC4 (kv1) / AES (kv2) |
    | 3, 4 (FT, SHA-256) | KDF-SHA-256 | 3 | AES-128-CMAC | AES key wrap |
    | 5, 6, 11 (SHA-256) | KDF-SHA-256 | 3 | AES-128-CMAC | AES key wrap |
    | 8, 9 (SAE) | KDF-SHA-256 | 3 | AES-128-CMAC | AES key wrap |
    | 12, 13 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | AES-256-CMAC-192 | AES key wrap |
    | 19, 20 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | AES-256-CMAC-192 | AES key wrap |
    | 22, 23 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | AES-256-CMAC-192 | AES key wrap |
    | 24, 25 (SAE-ext) | group-dependent | 0 (AKM-defined) | group-dependent | AES key wrap |

## Category Pages

### Password-Based (PSK)

AKMs 2, 4, 6, 19, 20 derive the PMK from a passphrase via PBKDF2. Captured
handshakes are vulnerable to offline dictionary attacks.

- [PSK Family (AKM 2, 6, 20)](psk-family.md)
- [FT-PSK Family (AKM 4, 19)](ft-psk-family.md)

### SAE (WPA3-Personal)

AKMs 8, 9, 24, 25 use Dragonfly PAKE. Capturing the handshake does not yield
a crackable hash.

- [SAE Family (AKM 8, 9, 24, 25)](sae-family.md)

### Enterprise (802.1X)

AKMs 1, 3, 5, 11–13, 22, 23 delegate authentication to a RADIUS server via EAP.
PMK derived from EAP Master Session Key, not a passphrase.

- [Enterprise Family (AKM 1, 3, 5, 11–13, 22, 23)](enterprise-family.md)

### FILS

AKMs 14–17 implement Fast Initial Link Setup for reduced-latency associations.

- [FILS Family (AKM 14–17)](fils-family.md)

### Other

AKMs 7 (TDLS), 10 (APPeerKey, deprecated), 18 (OWE), 21 (PASN).

- [Other AKMs (OWE, TDLS, PASN)](other-family.md)
