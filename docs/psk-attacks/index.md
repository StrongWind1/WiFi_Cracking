# PSK Attacks

## Overview

Pre-Shared Key attacks target networks where all stations share a common passphrase.
Two distinct attack surfaces exist: PMKID capture (client-less) and EAPOL handshake
interception. This section covers both vectors, the AKM suites they apply to, and
their relative computational cost.

## Attack Vectors

### PMKID vs EAPOL

PMKID attacks extract a key identifier from the first message of the 4-way handshake,
requiring no client interaction. EAPOL-based attacks capture the full handshake and
verify a candidate passphrase against the MIC field.

Each vector has different capture requirements, hash formats, and hashcat modes.
The pages linked below cover each in detail.

## Crackable AKMs

The following AKM suites derive their PMK from a passphrase and are therefore
subject to offline dictionary attack:

| AKM | Suite | Key Derivation | Notes |
|-----|-------|---------------|-------|
| 2   | PSK (WPA2) | PBKDF2-SHA1 | Most common target |
| 4   | FT-PSK | PBKDF2-SHA1 + FT KDF | Fast Transition variant |
| 6   | PSK-SHA256 | PBKDF2-SHA1 | Management Frame Protection capable |
| 19  | FT-PSK-SHA384 | PBKDF2-SHA1 + FT KDF-SHA384 | SHA-384 FT variant |
| 20  | PSK-SHA384 | PBKDF2-SHA1 + KDF-SHA384 | SHA-384 standard PSK |

AKM 8/9/24/25 (SAE) are not crackable offline — the Dragonfly PAKE does not
expose material suitable for dictionary attack. AKM 19/20 are offline crackable
but hashcat modules are not yet in mainline.

## Relative Computational Cost

All crackable PSK AKMs share the same PBKDF2 bottleneck:

| Step | Operations per candidate | Relative cost |
|------|-------------------------|---------------|
| PBKDF2 (PMK derivation) | 8192 HMAC-SHA1 calls | **~99.9%** |
| PTK derivation | 1–3 HMAC calls (varies by AKM) | ~0.05% |
| MIC verification | 1 HMAC or AES-CMAC call | ~0.05% |

Speed is effectively identical across AKM 2, 6, and 4 — the PBKDF2 step
dominates everything else. Typical GPU rates: ~500K–2M PMK/s (hardware-dependent).

Mode 22001 (raw PMK input) skips PBKDF2 entirely and is 100–1000× faster —
use when you have pre-computed PMKs or can obtain the PMK from another source.
