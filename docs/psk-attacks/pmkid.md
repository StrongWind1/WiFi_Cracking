# PMKID Attack

Published by Jens Steube in 2018. Allows offline passphrase cracking from a
single EAPOL M1 frame — no full 4-way handshake required. The AP includes a
PMKID in M1 if it has a PMKSA cache entry for the station.

## Per-AKM PMKID Formulas

### AKM 2 (PSK)

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: HMAC-SHA1, output truncated to first 128 bits (16 bytes)
- Input: literal string "PMK Name" (8 bytes) + AP MAC (6 bytes) + STA MAC (6 bytes) = 20 bytes
- PMK = PBKDF2-HMAC-SHA1(passphrase, SSID, 4096, 256)
- hashcat mode 22000, hash type `WPA*01*`

### AKM 6 (PSK-SHA256)

```
PMKID = HMAC-SHA256-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: HMAC-SHA256, output truncated to first 128 bits — **not SHA1**
- Same input format as AKM 2
- PMK same PBKDF2-HMAC-SHA1 derivation as AKM 2

!!! warning "AKM 6 PMKID is broken in hashcat 22000"
    hashcat mode 22000's aux4 (PMKID verification) uses HMAC-SHA1 for all
    `WPA*01*` lines. AKM 6 requires HMAC-SHA256. AKM 6 PMKID hashes will
    silently fail to crack even with the correct passphrase. EAPOL attack
    (aux3) works correctly for AKM 6. See the [gap table](../reference/gap-table.md).

### AKM 4 (FT-PSK)

FT-PSK uses a SHA-256 chain involving the FT key hierarchy, not a simple
HMAC of the PMK:

```
Step A: PMK-R0-Name-salt
  = HMAC-SHA256(PMK,
      counter_LE16(2) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take bytes 0–15 (16 bytes).

Step B: PMK-R0-Name
  = SHA256("FT-R0N" || PMK-R0-Name-salt)
  Truncate to 128 bits.

Step C: PMKID
  = SHA256("FT-R1N" || PMK-R0-Name || R1KHID || STA_MAC)
  Truncate to 128 bits.
```

- Requires extra fields: MDID, R0KH-ID, R1KH-ID
- hashcat mode 37100, hash type `WPA*03*`
- **Not yet crackable in hashcat mainline** — PR #4645 pending

### AKM 19 (FT-PSK-SHA384)

Same 3-step FT derivation as AKM 4, but using SHA-384 for both HMAC calls.
Not supported by current tools.

### AKM 20 (PSK-SHA384)

```
PMKID = HMAC-SHA384-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

Truncated to 128 bits. Not supported in current hashcat.

## RSN IE Structure

The PMKID is carried in the RSN Information Element Key Data of M1 as a
PMKID KDE (Key Data Encapsulation):

```
Tag: 0xDD (vendor-specific KDE)
Length: 0x14 (20 bytes)
OUI: 00-0F-AC (IEEE 802.11)
Data type: 0x04
PMKID: 16 bytes
```

Alternatively, the PMKID can appear in the PMKID List subelement of the
RSN IE directly (tag 0x30), at fixed offset after RSN capabilities.
hcxpcapngtool extracts both locations.

## AP PMKSA Cache Requirement

The AP only includes a PMKID in M1 if it has an active PMKSA cache entry for
the station. The cache is populated after a successful association. For a first
connection, many APs do not send a PMKID.

Vendor behavior varies:

- Some APs always include PMKID in M1 (proactive caching)
- Some include it only on reassociation
- Some never include it regardless of spec support

The EAPOL attack remains the primary method because it works regardless of
PMKSA cache state.

## Limitations

- AP must have a PMKSA cache entry; not all APs comply.
- SAE (AKM 8/9): PMK derived via Dragonfly PAKE — PMKID cannot be used for
  offline dictionary attack against the passphrase.
- AKM 6: silently broken in hashcat 22000 aux4 (see warning above).
- AKM 4: hashcat 37100 module not yet merged into mainline.

## Spec References

- PMKID definition: 802.11-2024 §12.7.1.3
- FT PMKID derivation: §12.7.1.6.3
- RSN IE PMKID List: §9.4.2.24.7
