# PMKID Attack

Published by Jens Steube in 2018. Allows offline passphrase cracking without a full 4-way handshake. The most common source is the PMKID KDE in EAPOL M1, but the spec defines PMKIDs in many other frame types: M2 RSN IE, Association/Reassociation Request RSN IE, FT Authentication frames (seq 1 and 2), FT Action frames, and even Beacon/Probe Response RSN IE (vendor firmware bugs). Extraction tools like wpawolf and hcxpcapngtool check all of these locations.

## Per-AKM PMKID Formulas

### AKM 2 (PSK)

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: HMAC-SHA1, output truncated to first 128 bits (16 bytes)
- Input: literal string "PMK Name" (8 bytes) + AP MAC (6 bytes) + STA MAC (6 bytes) = 20 bytes
- PMK = PBKDF2-HMAC-SHA1(passphrase, SSID, 4096, 256 bits)
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
      counter_LE16(2) || "FT-R0" ||
      SSIDlength || SSID || MDID || R0KH-ID-Len || R0KH-ID || S0KH-ID ||
      size_LE16(384))
  Take bytes 0–15 (16 bytes).

Step B: PMK-R0-Name
  = SHA256("FT-R0N" || PMK-R0-Name-salt)
  Truncate to 128 bits.

Step C: PMKID
  = SHA256("FT-R1N" || PMK-R0-Name || R1KH-ID || S1KH-ID)
  Truncate to 128 bits.
```

S0KH-ID = S1KH-ID = STA MAC address (per §12.7.1.6.3).

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

PMKIDs appear in two container types depending on the frame:

**Container A: RSN IE (tag 48).** The PMKID Count + PMKID List sit near the end of the RSN IE per §9.4.2.23.5. Used in M2 RSN IE, Association/Reassociation Request, FT Authentication, FT Action frames, Probe Request, and (via vendor firmware bugs) Beacon/Probe Response.

**Container B: PMKID KDE.** A vendor-specific Key Data Encapsulation inside EAPOL-Key M1 Key Data:

```
Tag: 0xDD (vendor-specific KDE)
Length: 0x14 (20 bytes)
OUI: 00-0F-AC (IEEE 802.11)
Data type: 0x04
PMKID: 16 bytes
```

M1 is the most common PMKID source (the Steube 2018 attack vector). Extraction tools check both container types across all applicable frame types.

## All 20 PMKID Extraction Locations

The IEEE 802.11-2024 spec defines PMKIDs in 20 distinct frame/field combinations. [wpawolf](../tools/wpawolf.md) extracts from all 20; hcxpcapngtool covers S1-S4. The labels S1-S20 follow wpawolf's `PmkidSource` naming.

### EAPOL-Key frames

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S1 | **EAPOL-Key M1** | AP → STA | KDE (`{DD 14 00:0F:AC 04}`) | Yes | The Steube 2018 attack vector — most common source |
| S2 | **EAPOL-Key M2** | STA → AP | RSN IE in Key Data | Yes | For FT-PSK, carries PMKR1Name + MDE + FTE |

### Management frames

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S3 | Association Request | STA → AP | RSN IE | Yes | Client referencing cached PMKSA |
| S4 | Reassociation Request | STA → AP | RSN IE | Yes | For FT over-the-air roaming, carries PMKR1Name + MDE + FTE |
| S14 | Probe Request (directed) | STA → AP | RSN IE | Yes (if PSK) | Rare — most clients omit RSN IE in probes |
| S15 | Probe Request (broadcast) | STA → broadcast | RSN IE | Yes (if PSK) | Spec-valid but very rare |
| S16 | Beacon | AP → all | RSN IE | Yes (if PSK) | Vendor firmware bug — spec says PMKID Count should be 0 in AP-originated frames |
| S17 | Probe Response | AP → STA | RSN IE | Yes (if PSK) | Same vendor firmware bug as S16 |

### FT Authentication frames (Algorithm = 2, Fast BSS Transition)

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S5 | FT Auth seq=1 | STA → AP | RSN IE + MDE + FTE | Yes (FT-PSK) | Carries PMKR0Name; FTE has R0KH-ID and ANonce |
| S6 | FT Auth seq=2 | AP → STA | RSN IE + MDE + FTE | Yes (FT-PSK) | Carries PMKR1Name; FTE has R0KH-ID and R1KH-ID — everything needed for a `WPA*03*` line |

### FT Action frames (Category = 6)

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S11 | FT Action Request | STA → AP | RSN IE + FTE | Yes (FT-PSK) | Over-the-DS FT path |
| S12 | FT Action Response | AP → STA | RSN IE + FTE | Yes (FT-PSK) | |
| S13 | FT Action Confirm | STA → AP | RSN IE + FTE | Yes (FT-PSK) | Carries PMKR1Name |

### FILS Authentication frames (Algorithm = 4 or 5)

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S7 | FILS Auth seq=1 | STA → AP | RSN IE | No | PMK from EAP rMSK, not PBKDF2 |
| S8 | FILS Auth seq=2 | AP → STA | RSN IE | No | AP echoes chosen PMKID |

### PASN Authentication frames

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S9 | PASN Auth seq=1 | STA → AP | RSN IE | Conditional | Crackable only when base AKMP is PSK or FT-PSK |
| S10 | PASN Auth seq=2 | AP → STA | RSN IE | Conditional | |

### Mesh Peering and OSEN

| ID | Frame | Direction | Container | PSK crackable? | Notes |
|---|---|---|---|---|---|
| S18 | Mesh Peering Open | STA → STA | AMPE element (tag 139), last 16 bytes | No | Mesh PMKSAs derive from SAE |
| S19 | Mesh Peering Confirm | STA → STA | AMPE element (tag 139) | No | |
| S20 | Association Request (OSEN) | STA → AP | Vendor IE (`{50:6F:9A:12}`) | No | Wi-Fi Passpoint / Hotspot 2.0; enterprise 802.1X |

### Summary by crackability

| Sources | Count | Crackable? |
|---|---|---|
| S1-S6, S11-S17 (PSK / FT-PSK) | 13 | Yes — if AKM is 2, 4, 6, 19, or 20 |
| S9-S10 (PASN) | 2 | Conditional — only if base AKMP is PSK |
| S7-S8, S18-S20 (FILS, Mesh, OSEN) | 5 | No — PMK not derived from passphrase |

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
- SAE (AKM 8/9): PMK derived via Dragonfly PAKE — PMKID cannot be used for offline dictionary attack against the passphrase.
- AKM 6: silently broken in hashcat 22000 aux4 (see warning above).
- AKM 4: hashcat 37100 module not yet merged into mainline (PR #4645).
- AKMs 19, 20 (SHA-384): PMK is PBKDF2-derived (crackable in principle) but no hashcat module exists for the SHA-384 PMKID or MIC primitives.

## Spec References

- PMKID derivation: 802.11-2024 §12.7.1.3
- FT key hierarchy: §12.7.1.6
- RSN IE PMKID List: §9.4.2.23.5
