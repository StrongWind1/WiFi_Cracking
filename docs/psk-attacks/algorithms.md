# PSK Algorithms

Step-by-step cryptographic derivations for all crackable PSK AKMs. Every
field, constant, and algorithm is traceable to the spec or tool source.

## Algorithm Comparison

| AKM | Name | PMK KDF | PTK KDF | PTK size | MIC algorithm | PMKID hash | hashcat mode |
|-----|------|---------|---------|----------|---------------|------------|-------------|
| 2 | PSK | PBKDF2-HMAC-SHA1 | PRF-512/384 (HMAC-SHA1) | 384/512 | HMAC-MD5 (kv1) / HMAC-SHA1-128 (kv2) | HMAC-SHA1-128 | 22000 |
| 4 | FT-PSK | PBKDF2-HMAC-SHA1 | KDF-SHA256 (2 iters) | 384 | AES-128-CMAC | SHA256 chain | 37100 |
| 6 | PSK-SHA256 | PBKDF2-HMAC-SHA1 | KDF-SHA256 | 384 | AES-128-CMAC | HMAC-SHA256-128 | 22000 (kv3) |

---

## PBKDF2 — Passphrase to PMK

The same for all crackable PSK variants:

```
PMK = PBKDF2(passphrase, SSID, ssidLen, 4096, 256)
```

- Inner PRF: **HMAC-SHA1** (always, regardless of AKM or keyver)
- Salt: the SSID (0–32 bytes)
- Iterations: **4096** (fixed by spec)
- Output: **256 bits** (32 bytes)
- Internally calls HMAC-SHA1 **8192 times** (4096 iterations × 2 PBKDF2 blocks)
- This step is always the computational bottleneck

The passphrase must be 8–63 printable ASCII characters (code points 32–126),
or exactly 64 hex characters representing a raw 256-bit PSK.

### PRF Internal Structure (AKM 2, keyver 1/2)

```
PRF-X(K, A, B):
    R = ""
    for i = 0 to ceil(X / 160) - 1:
        R = R || HMAC-SHA1(K, A || 0x00 || B || i)
    return first X bits of R
```

Where `A` is the label string, `0x00` is a null separator byte injected
internally (§12.7.1.2), `B` is context data (sorted MACs + sorted nonces),
and `i` is a single counter byte.

For cracking, only the first 128 bits of output (the KCK) are needed to
verify the MIC. Since HMAC-SHA1 produces 160 bits per iteration, only one
iteration (i=0) is ever computed. The counter byte is always 0x00 in the
100-byte PKE buffer.

### KDF Internal Structure (AKM 6, 4 — keyver 3)

```
KDF-Hash-Length(K, label, context):
    result = ""
    for i = 1 to ceil(Length/Hashlen):
        result ||= HMAC-Hash(K,
            counter_LE16(i) || label || context || size_LE16(Length))
    return first Length bits of result
```

Counter is a 2-byte little-endian unsigned integer (not a single byte).
Length is appended as a 2-byte little-endian integer.

### Min/Max Ordering

The PRF/KDF input uses `Min(MAC_AP, MAC_STA)` and `Min(ANonce, SNonce)`.
Comparison treats each as an unsigned big-endian integer. The smaller value
is concatenated first. This ensures both sides derive the same PTK
regardless of AP vs. STA role.

---

## Standard PSK — AKM 2

### AKM 2 PMKID

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: HMAC-SHA1, truncated to first 128 bits (16 bytes)
- Input: "PMK Name" (8 bytes) + AP MAC (6 bytes) + STA MAC (6 bytes) = 20 bytes

### AKM 2 + keyver 1 (TKIP) — EAPOL Attack

```
PTK = PRF-512(PMK,
              "Pairwise key expansion",
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
```

PRF internally constructs: Label `||` 0x00 `||` Context `||` counter (§12.7.1.2)

```
KCK = PTK[0:16]
MIC = HMAC-MD5(KCK, EAPOL_frame_with_MIC_zeroed)
```

- PRF uses **HMAC-SHA1** internally
- PRF input (the context B): 76 bytes (12-byte MACs + 64-byte nonces)
- Full PKE buffer: 22-byte label + 1-byte null separator + 76-byte context + 1-byte counter = 100 bytes
- Only first 16 bytes of PRF output needed (KCK)
- MIC: **HMAC-MD5**, full 128-bit output

### AKM 2 + keyver 2 (CCMP) — EAPOL Attack

```
PTK = PRF-384(PMK,
              "Pairwise key expansion",
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
KCK = PTK[0:16]
MIC = HMAC-SHA1-128(KCK, EAPOL_frame_with_MIC_zeroed)
```

- Same PRF-with-HMAC-SHA1 internally (same as keyver 1)
- MIC: **HMAC-SHA1**, output truncated to 128 bits

---

## PSK-SHA256 — AKM 6

### AKM 6 PMKID

```
PMKID = HMAC-SHA256-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: **HMAC-SHA256** (not SHA1)
- Same input format as AKM 2
- hashcat 22000 aux4 uses SHA1 for all `WPA*01*` lines — **silently broken for AKM 6**

### AKM 6 + keyver 3 — EAPOL Attack

```
PTK = KDF-SHA256-384(PMK,
                     "Pairwise key expansion",
                     Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
                     Min(ANonce, SNonce)  || Max(ANonce, SNonce))
```

KDF constructs: `counter_LE16(1)` `||` label `||` context `||` `size_LE16(384)`

```
KCK = PTK[0:16]
MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- KDF uses **HMAC-SHA256** internally
- One iteration (ceil(384/256) = 2 → but for AKM 6 KCK=128, only KCK needed)

    !!! note
        For AKM 6, full PTK = 384 bits (KCK 128 + KEK 128 + TK 128). KDF-SHA256
        produces 256 bits per iteration — two iterations required for the full PTK,
        but only one needed to extract the 128-bit KCK for MIC verification.

- MIC: **AES-128-CMAC** (not HMAC-based)

---

## FT-PSK — AKM 4

### AKM 4 PMKID

The PMKID is not a simple HMAC of the PMK — it uses the FT key hierarchy:

```
Step A: PMK-R0-Name-salt
  = HMAC-SHA256(PMK,
      counter_LE16(2) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take bytes 0–15 (always exactly 16 bytes).

Step B: PMK-R0-Name
  = SHA256("FT-R0N" || PMK-R0-Name-salt)
  Truncate to 128 bits.

Step C: PMKID
  = SHA256("FT-R1N" || PMK-R0-Name || R1KHID || STA_MAC)
  Truncate to 128 bits.
```

- All SHA-256 after the initial PBKDF2
- Requires extra inputs: MDID, R0KH-ID, R1KH-ID

### AKM 4 EAPOL Attack — 3-Step KDF Chain

```
Step A: PMK-R0 (first 32 bytes)
  = HMAC-SHA256(PMK,
      counter_LE16(1) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take bytes 0–31.

Step B: PMK-R1 (first 32 bytes)
  = HMAC-SHA256(PMK-R0,
      counter_LE16(1) || "FT-R1" ||
      R1KHID || STA_MAC ||
      size_LE16(256))
  Take bytes 0–31.

Step C: PTK (48 bytes — requires 2 iterations)
  iter1 = HMAC-SHA256(PMK-R1,
      counter_LE16(1) || "FT-PTK" ||
      SNonce || ANonce || MAC_AP || STA_MAC ||
      size_LE16(384))              -- 32 bytes
  iter2 = HMAC-SHA256(PMK-R1,
      counter_LE16(2) || "FT-PTK" ||
      SNonce || ANonce || MAC_AP || STA_MAC ||
      size_LE16(384))              -- 32 bytes
  PTK = (iter1 || iter2)[0:48]   -- first 384 bits of 512

Step D: MIC
  KCK = PTK[0:16]
  MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- **Two KDF iterations mandatory for Step C** — PTK = 384 bits,
  KDF-SHA256 produces 256 bits per call: ceil(384/256) = 2 (§12.7.1.6.2)
- Three chained HMAC-SHA256 KDF calls vs. one PRF call for standard PSK
- Only keyver 3 (AES-CMAC) is used with AKM 4
- Requires: MDID, R0KH-ID, R1KH-ID in addition to standard handshake data

## Spec References

- PBKDF2 for PMK: 802.11-2024 §12.7.1.2 + RFC 2898
- PRF definition: §12.7.1.2
- KDF definition (iterations formula): §12.7.1.6.2
- PMKID computation: §12.7.1.3
- Standard PSK PTK derivation: §12.7.1.6.2
- FT key hierarchy: §12.7.1.6.3–6.5
- AES-128-CMAC: RFC 4493
