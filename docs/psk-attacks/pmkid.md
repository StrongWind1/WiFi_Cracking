# PMKID Attack

## Overview

The PMKID attack, published by Jens Steube in 2018, allows offline passphrase
cracking without capturing a full 4-way handshake. The AP includes a PMKID value
in Message 1 of the handshake if it has a PMKSA cache entry, enabling extraction
from a single frame.

## Per-AKM PMKID Formulas

### AKM 2 (PSK)

The PMKID is computed as:

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || AA || SPA)
```

Placeholder for detailed derivation steps and field definitions.

### AKM 4 (FT-PSK)

Placeholder for the FT-PSK PMKID formula, which involves R0KH-ID and R1KH-ID
in the key hierarchy.

### AKM 6 (PSK-SHA256)

Placeholder for the PSK-SHA256 PMKID formula using SHA-256-based PRF.

### AKM 20 (FT-SAE)

Placeholder for the FT-SAE PMKID formula and its relationship to the SAE
key hierarchy.

## RSN IE Structure

The PMKID is carried in the RSN Information Element of EAPOL Message 1.
Placeholder for the RSN IE byte layout, PMKID count field, and extraction offset.

## AP PMKSA Cache

Not all APs include a PMKID in Message 1. The AP must have an active PMKSA cache
entry for the station. Placeholder for discussion of when the cache is populated
and vendor-specific behavior.

## Limitations

- The AP must include the PMKID; many do not.
- SAE (AKM 19) derives PMK via Dragonfly, so the PMKID cannot be used for
  offline dictionary attack against the passphrase.
- PMKID capture requires only a single frame but still needs the correct BSSID
  and SSID for cracking.
