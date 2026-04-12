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
| 19  | SAE (WPA3) | SAE + PBKDF2 | Dragonfly handshake; PMKID not useful |
| 20  | FT-SAE | SAE + FT KDF | Fast Transition variant of SAE |

## Relative Cost

Placeholder for a comparison of computational cost per candidate across AKM types,
covering PBKDF2 iterations, SAE group operations, and the impact on cracking throughput.
