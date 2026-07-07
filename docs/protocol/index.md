# Protocol Overview

IEEE 802.11-2024 defines 25 Authentication and Key Management (AKM) suites
that govern how stations authenticate and derive encryption keys. This section
organizes them into five functional categories and links to family pages.

## Authentication Categories

Every WiFi security scheme falls into one of five categories based on how the user authenticates:

| Category | How it works | Offline crackable? |
|---|---|---|
| **WEP** | Static shared key, RC4 encryption | Key recovery from traffic (no password cracking) |
| **Password (PBKDF2)** | Passphrase → PBKDF2 → PMK; 4-way handshake exposes MIC/PMKID | **Yes** — dictionary/brute-force against PBKDF2 |
| **Password (SAE)** | Passphrase used in Dragonfly PAKE; no crackable material exposed | No — online-only, rate-limited |
| **EAP (802.1X)** | Credentials verified by RADIUS server via EAP method | Depends on EAP inner method |
| **Other** | No password (OWE), peer-to-peer (TDLS), or pre-association (PASN) | No |

## Quick Reference

### WEP (pre-AKM)

| Protocol | Encryption | Attack | Tool |
|---|---|---|---|
| WEP-40 / WEP-104 | RC4 with 24-bit IV | PTW key recovery (~40K ARP frames) | [WEPWolf](https://github.com/StrongWind1/WEPWolf) / [aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) |

### Password — PBKDF2 (offline crackable)

All six PSK families derive the PMK from a passphrase via PBKDF2-HMAC-SHA1 (4096 iterations, 256-bit output). This is the same PBKDF2 call regardless of AKM — the "SHA-256" and "SHA-384" in the AKM names refer to the post-PMK key hierarchy (KDF, MIC algorithms), not the password hashing step.

| AKM | Name | Variant | hashcat mode | Standard |
|-----|------|---------|-------------|----------|
| WPA1 | WPA-PSK | Original WPA (TKIP, vendor IE `00:50:F2:01`) | 22000 (kv1) | pre-802.11i |
| 2 | PSK | WPA2-Personal (CCMP) | 22000 (kv2) | 802.11i-2004 |
| 4 | FT-PSK | Fast Transition (802.11r) | 37100 (PR pending) | 802.11r-2008 |
| 6 | PSK-SHA256 | PMF-capable (802.11w) | 22000 (PMKID broken) | 802.11w-2009 |
| 19 | FT-PSK-SHA384 | FT with SHA-384 key hierarchy | none | 802.11-2020 |
| 20 | PSK-SHA384 | SHA-384 key hierarchy with GCMP-256 | none | 802.11-2020 |

### Password — SAE (not offline crackable)

These AKMs use the same passphrase but negotiate it via Dragonfly PAKE. The handshake exposes no material that can be cracked offline.

| AKM | Name | Variant | Standard |
|-----|------|---------|----------|
| 8 | SAE | WPA3-Personal | 802.11-2012 |
| 9 | FT-SAE | WPA3 + Fast Transition | 802.11-2012 |
| 24 | SAE (group-dependent) | H2E only | 802.11-2024 |
| 25 | FT-SAE (group-dependent) | H2E + Fast Transition | 802.11-2024 |

### EAP — Enterprise (802.1X / FILS)

Authentication delegated to a RADIUS server. PMK derived from EAP Master Session Key, not a passphrase. Whether credentials are recoverable depends on the EAP inner method (e.g., PEAP/MSCHAPv2 → mode 5500; EAP-MD5 → mode 4800; EAP-TLS → not crackable).

| AKM | Name | Variant | Standard |
|-----|------|---------|----------|
| 1 | 802.1X | Original enterprise | 802.11i-2004 |
| 3 | FT-802.1X | Enterprise + Fast Transition | 802.11r-2008 |
| 5 | 802.1X-SHA256 | Enterprise + PMF | 802.11w-2009 |
| 11 | Suite B-128 (deprecated) | CNSA predecessor | 802.11ac-2013 |
| 12 | Suite B-192 | CNSA, SHA-384, P-384 certs | 802.11ac-2013 |
| 13 | FT-802.1X-SHA384 | Suite B + Fast Transition | 802.11ac-2013 |
| 14 | FILS-SHA256 | Fast Initial Link Setup | 802.11ai-2016 |
| 15 | FILS-SHA384 | FILS with SHA-384 | 802.11ai-2016 |
| 16 | FT-FILS-SHA256 | FILS + Fast Transition | 802.11ai-2016 |
| 17 | FT-FILS-SHA384 | FILS + FT + SHA-384 | 802.11ai-2016 |
| 22 | FT-802.1X-SHA384 | Enterprise FT, SHA-384 | 802.11-2024 |
| 23 | 802.1X-SHA384 | Enterprise, SHA-384 | 802.11-2024 |

### Other

| AKM | Name | Purpose | Standard |
|-----|------|---------|----------|
| 7 | TDLS | Peer-to-peer tunneled direct link | 802.11z-2010 |
| 10 | APPeerKey (deprecated) | Removed from active standard | 802.11-2012 |
| 18 | OWE | Opportunistic encryption, no password | 802.11-2020 |
| 21 | PASN | Pre-association security negotiation | 802.11az-2022 |

## Full Specification Tables

=== "Key Lengths"

    Key lengths from IEEE 802.11-2024 Table 12-11 (KCK/KEK) and Table 12-8 (TK):

    | AKM | KCK | KEK | TK (CCMP) | TK (GCMP-256) |
    |-----|-----|-----|-----------|---------------|
    | 1, 2 | 128 | 128 | 128 | — |
    | 3, 4, 5, 6 | 128 | 128 | 128 | — |
    | 8, 9 (SAE) | 128 | 128 | 128 | — |
    | 11 (Suite B-128) | 128 | 128 | 128 | — |
    | 12, 13 (Suite B-192) | 192 | 256 | — | 256 |
    | 14, 16 (FILS, SHA-256) | 0 (ICK=256) | 256 | 128 | — |
    | 15, 17 (FILS, SHA-384) | 0 (ICK=384) | 512 | 256 | 256 |
    | 19, 20 | 192 | 256 | — | 256 |
    | 22, 23 | 192 | 256 | — | 256 |
    | 24, 25 | group-dependent | group-dependent | — | — |

=== "Algorithms"

    PTK derivation and MIC algorithms from IEEE 802.11-2024 Table 12-11:

    | AKM | PTK KDF | Key Descriptor Version | MIC algorithm | Key wrap |
    |-----|---------|----------------------|---------------|---------|
    | 1, 2 | PRF (HMAC-SHA1) | 1 (TKIP) or 2 (CCMP) | HMAC-MD5 (kv1) / HMAC-SHA1-128 (kv2) | RC4 (kv1) / AES (kv2) |
    | 3, 4 (FT, SHA-256) | KDF-SHA-256 | 3 | AES-128-CMAC | AES key wrap |
    | 5, 6 (SHA-256) | KDF-SHA-256 | 3 | AES-128-CMAC | AES key wrap |
    | 8, 9 (SAE) | KDF-SHA-256 | 0 (AKM-defined) | AES-128-CMAC | AES key wrap |
    | 11 (Suite B-128, deprecated) | KDF-SHA-256 | 0 (AKM-defined) | HMAC-SHA-256 | AES key wrap |
    | 12, 13 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | HMAC-SHA-384 | AES key wrap |
    | 19, 20 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | HMAC-SHA-384 | AES key wrap |
    | 22, 23 (SHA-384) | KDF-SHA-384 | 0 (AKM-defined) | HMAC-SHA-384 | AES key wrap |
    | 24, 25 (SAE-ext) | group-dependent | 0 (AKM-defined) | group-dependent | AES key wrap |

## Deep Dives

- [PSK Family (AKM 2, 6, 20)](psk-family.md) — PBKDF2 password-based, offline crackable
- [FT-PSK Family (AKM 4, 19)](ft-psk-family.md) — Fast Transition variants
- [SAE Family (AKM 8, 9, 24, 25)](sae-family.md) — Dragonfly PAKE, not offline crackable
- [Enterprise Family (AKM 1, 3, 5, 11–13, 22, 23)](enterprise-family.md) — 802.1X / RADIUS
- [FILS Family (AKM 14–17)](fils-family.md) — Fast Initial Link Setup
- [Other AKMs (OWE, TDLS, PASN)](other-family.md) — Opportunistic encryption, peer-to-peer, pre-association
- [Security Matrix](security-matrix.md) — per-AKM security posture and attack status
