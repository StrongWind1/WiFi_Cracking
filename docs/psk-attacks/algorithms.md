# PSK Algorithms

## Algorithm Comparison Table

Placeholder for a table comparing key derivation across AKM suites, covering:
PMK derivation function, PRF/KDF used for PTK, MIC algorithm, PMKID hash, and
the hashcat mode that handles each combination.

## PBKDF2 (Passphrase to PMK)

All PSK-based AKM suites derive the PMK from the passphrase using PBKDF2:

```
PMK = PBKDF2(HMAC-SHA1, passphrase, SSID, 4096, 256)
```

The SSID serves as the salt. The iteration count is fixed at 4096, and the output
length is 256 bits regardless of the downstream cipher suite.

## Standard PSK (AKM 2 and 6)

### PMKID

Placeholder for the PMKID derivation under AKM 2 (HMAC-SHA1-128) and AKM 6
(HMAC-SHA256-128), including the input concatenation and truncation.

### EAPOL (Key Version 1 — TKIP)

Placeholder for the PTK derivation using PRF-512 and MIC computation using
HMAC-MD5 under Key Version 1 (TKIP cipher suite).

### EAPOL (Key Version 2 — CCMP)

Placeholder for the PTK derivation using PRF-384 and MIC computation using
HMAC-SHA1-128 under Key Version 2 (CCMP cipher suite).

### EAPOL (Key Version 3 — AKM-defined)

Placeholder for AKM 6 using CMAC-AES-128 for the MIC, with the PRF replaced
by KDF-SHA256.

## FT-PSK (AKM 4)

### PMKID

Placeholder for the FT key hierarchy: PMK-R0, PMK-R1, and how the PMKID is
derived using R0KH-ID and R1KH-ID.

### EAPOL

Placeholder for the FT-PSK PTK derivation and MIC computation, noting the
different KDF inputs compared to standard PSK.
