# PSK Family (AKM 2, 6, 20)

These three AKM suites derive the PMK from a passphrase using PBKDF2, making captured handshakes vulnerable to offline dictionary and brute-force attacks. They differ in the KDF and MIC algorithms used during the 4-way handshake.

## Overview

AKM 2 is the original WPA/WPA2-Personal suite from 802.11i-2004. AKM 6 added SHA-256-based key derivation with 802.11w-2009. AKM 20, introduced in 802.11-2020, extends to SHA-384 with longer key sizes for GCMP-256 deployments.

## AKM Comparison Table

<!-- TODO: fill in exact key sizes from Table 12-8 -->

| AKM | Name | KDF | MIC Algorithm | Key Wrap | PMK Bits | KCK Bits | KEK Bits | TK Bits |
|-----|------|-----|---------------|----------|----------|----------|----------|---------|
| 2 | PSK | PRF (HMAC-SHA1) | HMAC-SHA1-128 or HMAC-MD5 | RC4 or AES-Wrap | 256 | 128 | 128 | 128 |
| 6 | PSK-SHA256 | KDF (HMAC-SHA256) | AES-128-CMAC | AES-Wrap | 256 | 128 | 128 | 128 |
| 20 | PSK-SHA384 | KDF (HMAC-SHA384) | HMAC-SHA384 | AES-Wrap | 384 | 192 | 256 | 256 |

## PMK Derivation (PBKDF2)

All three AKMs use the same PMK derivation:

    PMK = PBKDF2(HMAC-SHA1, passphrase, SSID, 4096, 256)

The passphrase is 8-63 ASCII characters. The SSID (including length) serves as the salt. 4096 iterations of HMAC-SHA1 produce a 256-bit PMK regardless of AKM.

<!-- TODO: confirm whether AKM 20 uses a 384-bit PMK from PBKDF2 or truncates -->

## PTK Derivation

### AKM 2 -- PRF (HMAC-SHA1)

PTK = PRF-X(PMK, "Pairwise key expansion", Min(AA,SPA) || Max(AA,SPA) || Min(ANonce,SNonce) || Max(ANonce,SNonce))

Where X is 384 (CCMP) or 512 (TKIP). Uses HMAC-SHA1 internally per Section 12.7.1.2.

### AKM 6 -- KDF-SHA-256

PTK = KDF-Hash-Length(PMK, "Pairwise key expansion", ...) using HMAC-SHA-256. Inputs are the same but the PRF is replaced by the KDF defined in Section 12.7.1.6.2.

### AKM 20 -- KDF-SHA-384

PTK = KDF-Hash-Length(PMK, "Pairwise key expansion", ...) using HMAC-SHA-384. Produces a longer PTK to accommodate 192-bit KCK, 256-bit KEK, and 256-bit TK.

## Cipher Suites

| Cipher Suite | Value | Encryption | TK Size | Used With |
|-------------|-------|-----------|---------|-----------|
| TKIP | 2 | RC4 + per-packet key mixing | 128-bit (+128-bit TMK) | AKM 2 (legacy) |
| CCMP | 4 | AES-128-CCM | 128-bit | AKM 2, 6 |
| GCMP-128 | 8 | AES-128-GCM | 128-bit | AKM 6, 20 |
| GCMP-256 | 9 | AES-256-GCM | 256-bit | AKM 20 |

## Key Descriptor Versions

| keyver | Bits 0-2 of Key Info | MIC Algorithm | Key Data Encryption | Typical AKM |
|--------|---------------------|---------------|---------------------|-------------|
| 1 | 0x01 | HMAC-MD5 | RC4 | AKM 2 + TKIP |
| 2 | 0x02 | HMAC-SHA1-128 | AES Key Wrap | AKM 2 + CCMP |
| 3 | 0x03 | AES-128-CMAC | AES Key Wrap | AKM 6 |
| 0 | 0x00 | Determined by AKM | AES Key Wrap | AKM 20 |

## Real-World Combinations

<!-- TODO: expand with observed AP configurations and market share estimates -->

| Common Name | AKM | Cipher | keyver | Notes |
|-------------|-----|--------|--------|-------|
| WPA-PSK (TKIP) | 2 | TKIP (2) | 1 | Legacy, rarely seen |
| WPA2-PSK (CCMP) | 2 | CCMP (4) | 2 | Most common home WiFi |
| WPA2-PSK-SHA256 | 6 | CCMP (4) | 3 | PMF-capable networks |
| WPA3 Transition | 2+8 | CCMP (4) | 2 | Mixed WPA2/WPA3 mode |
| WPA3-PSK-384 | 20 | GCMP-256 (9) | 0 | Future high-security deployments |

## Spec References

- AKM suite selectors: Table 9-190
- PMK derivation: Section 12.7.1.2
- PTK derivation (KDF): Section 12.7.1.6.2
- Key descriptor versions: Table 12-11, Section 12.7.3
