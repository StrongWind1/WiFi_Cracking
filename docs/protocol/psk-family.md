# PSK Family (AKM 2, 6, 20)

These three AKM suites derive the PMK from a passphrase using PBKDF2, making
captured handshakes vulnerable to offline dictionary and brute-force attacks.
They differ in the KDF and MIC algorithms used during the 4-way handshake.

## Overview

AKM 2 is the original WPA/WPA2-Personal suite from 802.11i-2004. AKM 6 added
SHA-256-based key derivation with 802.11w-2009. AKM 20, introduced in
802.11-2020, uses SHA-384 with longer key sizes for GCMP-256 deployments.

## AKM Comparison

| AKM | Name | PTK KDF | MIC algorithm | KCK | KEK | TK (CCMP) | hashcat mode |
|-----|------|---------|---------------|-----|-----|-----------|-------------|
| 2 | PSK | PRF (HMAC-SHA1) | HMAC-MD5 (kv1) / HMAC-SHA1-128 (kv2) | 128 | 128 | 128 | 22000 |
| 6 | PSK-SHA256 | KDF-SHA-256 | AES-128-CMAC (kv3) | 128 | 128 | 128 | 22000 |
| 20 | PSK-SHA384 | KDF-SHA-384 | HMAC-SHA-384 (kv0) | 192 | 256 | 256 | pending |

Key lengths per IEEE 802.11-2024 Table 12-11 (KCK/KEK) and Table 12-8 (TK).

## PMK Derivation (PBKDF2)

All three AKMs use the same PMK derivation:

```
PMK = PBKDF2(HMAC-SHA1, passphrase, SSID, 4096, 256)
```

- Inner PRF: **HMAC-SHA1** (always, regardless of AKM or keyver)
- Salt: SSID (0–32 bytes)
- Iterations: **4096** (fixed by spec)
- Output: **256 bits** — same for AKM 2, 6, and 20
- Internally calls HMAC-SHA1 **8192 times** (4096 iterations × 2 PBKDF2 blocks)

The passphrase is 8–63 printable ASCII characters (code points 32–126), or
exactly 64 hex characters for a raw 256-bit PSK.

PBKDF2 is the computational bottleneck: ~8192 HMAC-SHA1 calls per candidate.
PTK derivation and MIC verification add ~0.1% overhead.

## PTK Derivation

### AKM 2 — PRF-X (HMAC-SHA1)

```
PTK = PRF-X(PMK,
            "Pairwise key expansion",
            Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
            Min(ANonce, SNonce)  || Max(ANonce, SNonce))
```

PRF internally constructs: `Label || 0x00 || Context || counter` per §12.7.1.2.

- X = 384 for CCMP (KCK 128 + KEK 128 + TK 128)
- X = 512 for TKIP (KCK 128 + KEK 128 + TK 256 including TMK)

### AKM 6 — KDF-SHA-256

```
PTK = KDF-SHA-256-384(PMK,
                       "Pairwise key expansion",
                       Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
                       Min(ANonce, SNonce)  || Max(ANonce, SNonce))
```

KDF constructs: `counter_LE16(i) || Label || Context || size_LE16(384)`.
Two iterations needed for full PTK (ceil(384/256) = 2), but cracking only requires the first iteration to extract KCK.

### AKM 20 — KDF-SHA-384

Same structure as KDF-SHA-256 but using HMAC-SHA-384 internally. PTK = 704
bits (KCK 192 + KEK 256 + TK 256). Requires two iterations:
ceil(704/384) = 2.

## Cipher Suites

| Cipher suite | Value | Encryption | TK size | Used with |
|-------------|-------|-----------|---------|-----------|
| TKIP | 2 | RC4 + per-packet key mixing | 128 bits (+128-bit TMK) | AKM 2 (legacy, deprecated) |
| CCMP-128 | 4 | AES-128-CCM | 128 bits | AKM 2, 6 |
| GCMP-128 | 8 | AES-128-GCM | 128 bits | AKM 6 |
| GCMP-256 | 9 | AES-256-GCM | 256 bits | AKM 20 |

Cipher suite values from IEEE 802.11-2024 Table 9-188 (RSN cipher suite selectors).
Note: GCMP-128 is suite type 8, GCMP-256 is suite type 9 — distinct values.

## Key Descriptor Versions

The Key Descriptor Version (bits 0–2 of Key Information) determines the MIC
algorithm and key wrap cipher for EAPOL-Key frames:

| keyver | Key Info bits | MIC algorithm | Key Data encryption | Typical AKM |
|--------|--------------|---------------|---------------------|-------------|
| 1 | 0x01 | HMAC-MD5 | RC4 | AKM 2 + TKIP |
| 2 | 0x02 | HMAC-SHA1-128 | AES key wrap | AKM 2 + CCMP |
| 3 | 0x03 | AES-128-CMAC | AES key wrap | AKM 6 |
| 0 | 0x00 | AKM-defined | AES key wrap | AKM 20 |

For keyver 3 (AKM 6), the MIC is AES-128-CMAC over the full EAPOL frame with
the MIC field zeroed. For keyver 1/2, the MIC is an HMAC truncated to 128 bits.

## Real-World Combinations

| Common name | AKM | Cipher | keyver | Notes |
|-------------|-----|--------|--------|-------|
| WPA-PSK (TKIP) | 2 | TKIP (2) | 1 | Legacy, rarely seen in production |
| WPA2-PSK (CCMP) | 2 | CCMP (4) | 2 | Most common home/SOHO WiFi |
| WPA2-PSK-SHA256 | 6 | CCMP (4) | 3 | PMF-capable networks (802.11w required) |
| WPA3 Transition Mode | 2+8 | CCMP (4) | 2 | Mixed WPA2/WPA3 networks; AKM 2 still crackable |
| WPA3-PSK-384 | 20 | GCMP-256 (9) | 0 | High-security enterprise; not yet common |

## Offline Attack Summary

| AKM | Attack | hcxtools output | hashcat mode | Works? |
|-----|--------|-----------------|-------------|--------|
| 2 | PMKID | WPA*01* | 22000 (aux4) | Yes |
| 2 | EAPOL kv1 | WPA*02* | 22000 (aux1) | Yes |
| 2 | EAPOL kv2 | WPA*02* | 22000 (aux2) | Yes |
| 6 | PMKID | WPA*01* | 22000 (aux4) | **Broken** (uses SHA1, needs SHA256) |
| 6 | EAPOL kv3 | WPA*02* | 22000 (aux3) | Yes |
| 20 | PMKID/EAPOL | — | pending | No module yet |

## Spec References

- AKM suite selectors: IEEE 802.11-2024 Table 9-190
- PMK derivation (PBKDF2): Annex J.4.1, §12.7.1.3
- PTK derivation (PRF): §12.7.1.2; (KDF): §12.7.1.6.2
- Key descriptor versions: §12.7.3, Table 12-11
- Cipher suite selectors: Table 9-188
- Key lengths: Table 12-8 (TK), Table 12-11 (KCK/KEK)
