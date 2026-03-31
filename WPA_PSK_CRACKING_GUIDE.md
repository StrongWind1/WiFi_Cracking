# Complete Guide to WPA/WPA2 PSK Cracking

## How This Document Is Organized

1. **The Protocol** -- What WPA authentication actually does
2. **PSK Variants** -- Every PSK-based system in the IEEE spec
3. **Attack Vectors** -- The two ways to crack each variant
4. **The Algorithms** -- Step-by-step math for each combination
5. **Capture Requirements** -- What to capture for each attack
6. **Hash Line Formats** -- Mode 22000 and 37100
7. **EAPOL-Key Frame Format** -- Raw frame structure
8. **The Final Matrix** -- SPEC vs HCXTOOLS vs HASHCAT
9. **EAPOL Size Limits** -- Per-tool constraints
10. **Hashcat Modes** -- 22000, 22001, 37100, salt grouping, dedup, deprecated modes
11. **hcxpcapngtool Options** -- What each flag does, options matrix
12. **Cheat Sheet** -- Workflow, tshark network detection, speed reference

---

## Part 1: How WPA PSK Authentication Works

### The Core Idea

A passphrase is never sent over the air. Instead, both sides independently derive
the same encryption keys from the passphrase and prove to each other that they
arrived at the same result.

### The Key Hierarchy

```
Passphrase  +  SSID
       \       /
        \     /
    PBKDF2-HMAC-SHA1 (4096 iterations)
            |
           PMK  (256 bits)  ← Pairwise Master Key
            |
    PRF or KDF  +  ANonce  +  SNonce  +  MAC_AP  +  MAC_STA
            |
           PTK  (384 or 512 bits)  ← Pairwise Transient Key
          / | \
        /   |   \
     KCK   KEK   TK  (+TMK for TKIP)
```

| Key | Size | Purpose |
|-----|------|---------|
| **PMK** | 256 bits | Master secret derived from passphrase + SSID |
| **PTK** | 384 bits (CCMP) / 512 bits (TKIP) | Session key bundle |
| **KCK** | 128 bits (PTK bits 0-127) | Signs EAPOL-Key handshake messages (MIC) |
| **KEK** | 128 bits (PTK bits 128-255) | Encrypts GTK during handshake |
| **TK** | 128 bits (PTK bits 256-383) | Encrypts actual data traffic |
| **TMK** | 2 x 64 bits (PTK bits 384-511) | TKIP only: Michael MIC keys, one per direction |

### The 4-Way Handshake

```
    AP (Authenticator)                      STA (Supplicant)
    ==================                      =================

    Both already know PMK (derived from passphrase + SSID)

    1. ──── M1: ANonce, PMKID(optional) ──────>
                                                STA generates SNonce
                                                STA derives PTK
    2. <──── M2: SNonce, MIC, RSN IE ──────────
       AP derives PTK
       AP verifies MIC
    3. ──── M3: ANonce, MIC, GTK(encrypted) ──>
                                                STA verifies MIC
                                                STA installs keys
    4. <──── M4: MIC ──────────────────────────
       AP installs keys
```

| Message | Sender | Contains | MIC? | What It Proves |
|---------|--------|----------|------|----------------|
| M1 | AP -> STA | ANonce, optionally PMKID in Key Data | No | Nothing (unauthenticated) |
| M2 | STA -> AP | SNonce, STA's RSN IE | Yes | STA knows the PMK |
| M3 | AP -> STA | ANonce, AP's RSN IE, encrypted GTK | Yes | AP knows the PMK |
| M4 | STA -> AP | Acknowledgment | Yes | Handshake complete |

---

## Part 2: Every PSK Variant in the IEEE Spec

### The Three Dimensions

A PSK-based WPA system is defined by three independent choices:

1. **AKM Suite** -- How authentication and key management work
2. **Cipher Suite** -- How data is encrypted after key setup
3. **Key Descriptor Version** -- Which algorithms sign/verify the handshake itself

### All PSK-Based AKM Suites

| AKM | OUI:Type | Name | Standard | Key Exchange |
|-----|----------|------|----------|-------------|
| **2** | 00-0F-AC:2 | PSK | 802.11i-2004 | 4-Way Handshake |
| **4** | 00-0F-AC:4 | FT-PSK | 802.11r-2008 | Fast Transition + 4-Way Handshake |
| **6** | 00-0F-AC:6 | PSK-SHA256 | 802.11w-2009 | 4-Way Handshake |
| **8** | 00-0F-AC:8 | SAE | 802.11-2012 / WPA3 (2018) | Dragonfly PAKE + 4-Way Handshake |
| **9** | 00-0F-AC:9 | FT-SAE | 802.11-2012 / WPA3 (2018) | Dragonfly + Fast Transition |

> **SAE (AKM 8, 9)**: Uses a password but derives PMK through the Dragonfly
> zero-knowledge proof protocol, not PBKDF2. Cannot be cracked offline.
> Excluded from the rest of this guide.

> **Enterprise (AKM 1, 3, 5)**: These use 802.1X with an EAP method
> (EAP-TLS, PEAP, etc.) instead of a pre-shared key. The PMK comes from
> the EAP exchange with a RADIUS server, not from PBKDF2. There is no
> passphrase to brute-force. Excluded from this guide -- no PSK involved.

### All Relevant Cipher Suites

| Value | Name | Encryption | Key Size | Used With |
|-------|------|-----------|---------|-----------|
| 2 | TKIP | RC4 (per-packet key mixing) | 128-bit TK (+128-bit TMK) | WPA1 |
| 4 | CCMP | AES-128 in CTR+CBC-MAC mode | 128-bit TK | WPA2/WPA3 |
| 9 | GCMP | AES in Galois/Counter Mode | 128 or 256-bit | WPA3 (RSN only) |

### All Key Descriptor Versions

| keyver | Bits 0-2 of Key Info | PTK Derivation | MIC Algorithm | Key Data Encryption |
|--------|---------------------|----------------|---------------|---------------------|
| **1** | 0x01 | PRF-512 (HMAC-SHA1) | HMAC-MD5 | RC4 |
| **2** | 0x02 | PRF-384 (HMAC-SHA1) | HMAC-SHA1-128 | AES Key Wrap |
| **3** | 0x03 | KDF-384 (HMAC-SHA256) | AES-128-CMAC | AES Key Wrap |

### The Valid Combinations

Not all combinations of AKM + cipher + keyver exist in the wild. Here are the
real-world configurations:

| # | Common Name | AKM | Cipher | keyver | IE Type | Key Descriptor |
|---|-------------|-----|--------|--------|---------|----------------|
| 1 | WPA-PSK (TKIP) | 2 | TKIP | 1 | WPA IE (0xDD, MS OUI) | 0xFE (WPA) |
| 2 | WPA2-PSK (CCMP) | 2 | CCMP | 2 | RSN IE (0x30) | 0x02 (RSN) |
| 3 | WPA2-PSK (TKIP+CCMP mixed) | 2 | TKIP or CCMP | 1 or 2 | Both IEs possible | 0xFE or 0x02 |
| 4 | WPA2-FT-PSK | 4 | CCMP | 3 | RSN IE (0x30) | 0x02 (RSN) |
| 5 | WPA2-PSK-SHA256 | 6 | CCMP | 3 | RSN IE (0x30) | 0x02 (RSN) |

---

## Part 3: The Two Attack Vectors

For every crackable PSK variant, there are two independent ways to attack:

### Attack A: PMKID

- **Requires**: A frame containing a PMKID. For standard WPA (AKM 2/6), the
  PMKID can appear in M1, M2, Association Request, or Reassociation Request.
  For FT-PSK (AKM 4), hcxpcapngtool extracts the PMKID from M2 because only
  M2 contains all the FT IEs (MDID, R0KH-ID, R1KH-ID) needed for the FT key
  derivation chain.
- **How**: The PMKID is a hash of the PMK, so it can be verified against
  password guesses.
- **Limitation**: Not all APs include a PMKID. Depends on whether the AP has
  a cached PMKSA.

### Attack B: EAPOL 4-Way Handshake (MIC verification)

- **Requires**: A message pair -- two handshake messages that together provide
  ANonce + SNonce + MIC + the EAPOL frame that was MIC'd.
- **How**: Derive the PTK from a guessed password, compute the MIC over the
  captured EAPOL frame, compare against the captured MIC.

### Message Pairs for EAPOL Attack

#### What Each Handshake Message Contains

Before understanding message pairs, you need to know what's inside each message:

| Message | Direction | Nonce Field Contains | Has MIC? | Has Usable EAPOL? | Replay Counter |
|---------|-----------|---------------------|----------|-------------------|----------------|
| M1 | AP -> STA | **ANonce** | No | No (no MIC to verify) | N |
| M2 | STA -> AP | **SNonce** | Yes | **Yes** | N (echoes M1) |
| M3 | AP -> STA | **ANonce** | Yes | **Yes** | N+1 |
| M4 | STA -> AP | **Zeroed** per spec (802.11i-2004 8.5.3.4) | Yes | **Yes** (if nonce non-zero) | N+1 (echoes M3) |

#### What Hashcat Needs

To verify a password guess, hashcat needs exactly three things from the capture:

1. **The EAPOL frame** -- a raw M2, M3, or M4 frame (with MIC field zeroed)
2. **The MIC** -- extracted from that same frame before zeroing
3. **The "other" nonce** -- the nonce NOT already embedded in the EAPOL frame

This is the key insight: **the EAPOL frame already contains one nonce inside it**.
Hashcat only needs the other nonce supplied externally.

| If EAPOL is from... | Nonce inside EAPOL | External nonce needed | External nonce comes from |
|---------------------|-------------------|----------------------|--------------------------|
| **M2** | SNonce (at byte offset 17-48) | ANonce | M1 or M3 |
| **M3** | ANonce (at byte offset 17-48) | SNonce | M2 or M4 |
| **M4** | SNonce* (at byte offset 17-48) | ANonce | M1 or M3 |

> \* M4's Key Nonce field shall be 0 per IEEE 802.11i-2004 Section 8.5.3.4.
> In practice, some implementations reuse the SNonce from M2, but most
> conform to the spec and zero it. If zeroed, M4 is unusable because
> hashcat cannot reconstruct both nonces.

#### The Hashcat 22000 Hash Line Nonce Field

In the `WPA*02*` format:

```
WPA*02*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<message_pair>
```

The field labeled "NONCE" is the **external nonce** -- the one NOT embedded
in the EAPOL frame:

| EAPOL source | What goes in the NONCE field | Why |
|-------------|----------------------------|-----|
| M2 | ANonce (from M1 or M3) | M2 contains SNonce, so ANonce is external |
| M3 | SNonce (from M2 or M4) | M3 contains ANonce, so SNonce is external |
| M4 | ANonce (from M1 or M3) | M4 contains SNonce, so ANonce is external |

This is what `tools/wpa_audit.py` does when building hash lines:

```python
ext_nonce = s_nonce if eapol_msg == 3 else a_nonce
```

#### wpa_theoretical_hashes (12 Combinations)

There are three independent choices when building a hash:

- **ANonce source**: M1 or M3 (2 choices)
- **SNonce source**: M2 or M4 (2 choices)
- **EAPOL/MIC source**: M2, M3, or M4 (3 choices)

Total: 2 x 2 x 3 = **12 theoretical combinations**.

| # | ANonce | SNonce | EAPOL | Maps to (N#E#) |
|---|--------|--------|-------|----------------|
| 1 | M1 | M2 | M2 | N1E2 |
| 2 | M1 | M2 | M3 | N2E3 |
| 3 | M1 | M2 | M4 | N1E4 |
| 4 | M1 | M4 | M2 | N1E2 (twin) |
| 5 | M1 | M4 | M3 | N4E3 |
| 6 | M1 | M4 | M4 | N1E4 (twin) |
| 7 | M3 | M2 | M2 | N3E2 |
| 8 | M3 | M2 | M3 | N2E3 (twin) |
| 9 | M3 | M2 | M4 | N3E4 |
| 10 | M3 | M4 | M2 | N3E2 (twin) |
| 11 | M3 | M4 | M3 | N4E3 (twin) |
| 12 | M3 | M4 | M4 | N3E4 (twin) |

The "Maps to" column shows which practical combo (N#E#) each theoretical
combo produces. Twins produce identical hash lines because the "unused"
nonce source choice doesn't affect the output.

#### Why 12 Collapses to 6 (wpa_hashcat_hashes)

Hashcat takes one EAPOL frame + one external nonce. The MIC and EAPOL are
locked together. So the real model is:

```
EAPOL frame (M2, M3, or M4)  ×  External nonce source (2 choices)  =  6
```

| N#E# | EAPOL from | Nonce already inside EAPOL | Nonce hashcat needs externally | Hash line NONCE field contains |
|------|------------|---------------------------|-------------------------------|-------------------------------|
| N1E2 | M2 | SNonce (M2 byte offset 17-48) | ANonce | ANonce from M1 |
| N1E4 | M4 | SNonce (M4 byte offset 17-48) | ANonce | ANonce from M1 |
| N3E2 | M2 | SNonce (M2 byte offset 17-48) | ANonce | ANonce from M3 |
| N2E3 | M3 | ANonce (M3 byte offset 17-48) | SNonce | SNonce from M2 |
| N4E3 | M3 | ANonce (M3 byte offset 17-48) | SNonce | SNonce from M4 |
| N3E4 | M4 | SNonce (M4 byte offset 17-48) | ANonce | ANonce from M3 |

The EAPOL frame already contains one nonce embedded inside it (column 3).
Hashcat extracts that automatically. The only thing hashcat needs supplied
separately is the **other** nonce (column 4), which goes in the `WPA*02*`
NONCE field (column 5).

The other 6 theoretical combos produce identical hash lines to one of these 6
because the EAPOL frame already contains one nonce. Changing which message the
embedded nonce "came from" doesn't change the nonce value itself, so the hash
is identical.

**"Challenge" vs "Authorized"**: N1E2 is the only "challenge" hash.
It requires only M1+M2: the client sent a password response (M2) but the
AP never confirmed it was correct. The password was sent but not validated.
All other combos require M3 or M4, which only exist after the AP verified
the MIC in M2. The password was both sent and validated. These are
"authorized" hashes. N3E2 is authorized despite using M2 as the EAPOL
source, because M3 (the external nonce source) proves the AP confirmed.

**N1E4, N3E4, and N4E3 all require non-zero M4 nonce.** N1E4 and N3E4
use M4 as the EAPOL source (SNonce embedded). N4E3 uses M4 as the
external SNonce source. M4's Key Nonce shall be 0 per IEEE 802.11i-2004
Section 8.5.3.4, making these combos impossible for most captures. Some
implementations reuse the SNonce from M2 instead of zeroing it, but
this is nonstandard. In practice, most captures yield only Hash A
(from M2) and Hash B (from M3).

#### Why 6 Collapses to 3 (wpa_unique_hashcat_hashes)

Within one handshake session, **there is only one real ANonce and one real
SNonce**:

- M1 and M3 carry the **same ANonce** (the AP commits to one value)
- M2 and M4 carry the **same SNonce** (or M4 is zeroed/unusable)

So the identical hash pairs are:

```
N1E2 == N3E2  (both use M2's EAPOL, ANonce is the same value from M1 or M3)
N2E3 == N4E3  (both use M3's EAPOL, SNonce is the same value from M2 or M4)
N1E4 == N3E4  (both use M4's EAPOL, ANonce is the same value from M1 or M3)
```

| Unique hash | EAPOL from | Identical combos |
|-------------|-----------|-----------------|
| **Hash A** | M2 | N1E2 == N3E2 |
| **Hash B** | M3 | N2E3 == N4E3 |
| **Hash C** | M4 | N1E4 == N3E4 |

#### The Full Pipeline

```
 12 theoretical (ANonce x SNonce x EAPOL)
         │
         │  Constraint: EAPOL frame already contains one nonce
         ▼
  6 practical (wpa_hashcat_hashes: N#E# combos)
         │
         │  Constraint: ANonce M1==M3, SNonce M2==M4
         ▼
  3 unique (wpa_unique_hashcat_hashes: Hash A, B, C)

  N1E2 ─┐                              ┌─ Hash A (eapol=M2)
  N3E2 ─┘── same EAPOL, same ANonce ───┘
  N2E3 ─┐                              ┌─ Hash B (eapol=M3)
  N4E3 ─┘── same EAPOL, same SNonce ───┘
  N1E4 ─┐                              ┌─ Hash C (eapol=M4)
  N3E4 ─┘── same EAPOL, same ANonce ───┘
```

Hash C requires non-zero M4 nonce (N1E4, N3E4 use M4 as EAPOL source).
Hash B's N4E3 twin also requires non-zero M4 nonce (M4 as external
SNonce source). N2E3 does not (external SNonce from M2). In practice,
most captures yield only Hash A and one copy of Hash B (via N2E3).

#### Why N1E2 Is Preferred

1. **Reliability**: M2 SNonce is always populated. M4 nonce may be zeroed.
2. **Size**: M2 EAPOL is typically ~120-140 bytes. M3 can be larger (contains
   encrypted GTK + AP RSN IE), potentially exceeding buffer limits.
3. **Timing**: M1+M2 are the first two messages -- easiest to capture, even
   with packet loss on M3/M4.
4. **Replay counter**: M1 and M2 share the same replay counter value (N),
   making nonce error correction simpler.

#### Higher Bits of the Message Pair Byte

| Bit | Hex | Meaning | Effect on Cracking |
|-----|-----|---------|-------------------|
| 3 | 0x08 | Reserved | Unused |
| 4 | 0x10 | AP-less attack | Nonce error corrections forced to 0 |
| 5 | 0x20 | LE replay counter detected | Only try little-endian nonce corrections |
| 6 | 0x40 | BE replay counter detected | Only try big-endian nonce corrections |
| 7 | 0x80 | Replay count not checked | Nonce error corrections = 8 (default) |

**Nonce error correction** compensates for firmware bugs or capture artifacts
where the ANonce value differs slightly between what was used in key derivation
and what was captured (e.g., the AP's internal counter incremented between
deriving the PTK and transmitting M1). Hashcat adjusts the last 4 bytes of
the nonce in the PKE buffer by +/- N (default N=8), trying both little-endian
and big-endian byte orders.

---

## Part 4: The Algorithms -- Step by Step

### Step 1: Passphrase to PMK (Same for ALL crackable PSK variants)

```
PMK = PBKDF2(passphrase, SSID, ssidLen, 4096, 256)
```

- Inner PRF: **HMAC-SHA1** (always, regardless of AKM or keyver)
- Salt: the SSID (0-32 bytes)
- Iterations: 4096 (fixed by spec)
- Output: 256 bits (32 bytes)
- Internally calls HMAC-SHA1 **8192 times** (4096 iterations x 2 PBKDF2 blocks)
- This step is always the computational bottleneck

> The passphrase must be 8-63 printable ASCII characters (code points 32-126),
> or exactly 64 hex characters representing a raw 256-bit PSK.

#### How PRF-X Works Internally

The PRF (Pseudo-Random Function) used in keyver 1 and 2 is defined as:

```
PRF-X(K, A, B):
    R = ""
    for i = 0 to ceil(X / 160) - 1:
        R = R || HMAC-SHA1(K, A || 0x00 || B || i)
    return first X bits of R
```

Where `A` is the label string, `0x00` is a separator byte, `B` is the context
data (sorted MACs + sorted nonces), and `i` is a single counter byte.

For cracking, only the first 128 bits of output (the KCK) are needed to verify
the MIC. Since HMAC-SHA1 produces 160 bits per iteration, **only one iteration
(i=0) is ever computed**. This is why the counter byte is always 0x00 in the
100-byte PKE buffer.

The KDF used in keyver 3 follows the same principle but uses HMAC-SHA256 and
a different framing (counter prefix as LE uint16 instead of trailing byte,
length suffix appended).

#### Min/Max Ordering

The PRF input uses `Min(MAC_AP, MAC_STA)` and `Min(ANonce, SNonce)`. The
comparison treats each value as an **unsigned big-endian integer** -- the first
byte is the most significant. The smaller value is concatenated first, then the
larger. This ensures both sides compute the same PTK regardless of who is AP
vs STA.

---

### Step 2: Verification -- Differs Per Attack Vector and AKM

#### AKM 2 (Standard PSK) -- PMKID Attack

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: **HMAC-SHA1**, output truncated to first 128 bits (16 bytes)
- Input: literal string "PMK Name" (8 bytes) + AP MAC (6 bytes) + STA MAC (6 bytes) = 20 bytes
- Compare result against captured PMKID

#### AKM 2 (Standard PSK) + keyver 1 (TKIP) -- EAPOL Attack

```
PTK = PRF-512(PMK,
              "Pairwise key expansion\x00" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
KCK = PTK[0:16]
MIC = HMAC-MD5(KCK, EAPOL_frame_with_MIC_zeroed)
```

- PRF uses **HMAC-SHA1** internally
- PRF input: 100 bytes (23-byte label + 12-byte MACs + 64-byte nonces + 1-byte counter)
- Only first 16 bytes of PRF output needed (KCK)
- MIC: **HMAC-MD5**, full 128-bit output
- Compare against captured MIC

#### AKM 2 (Standard PSK) + keyver 2 (CCMP) -- EAPOL Attack

```
PTK = PRF-384(PMK,
              "Pairwise key expansion\x00" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
KCK = PTK[0:16]
MIC = HMAC-SHA1-128(KCK, EAPOL_frame_with_MIC_zeroed)
```

- PRF uses **HMAC-SHA1** internally (same as keyver 1)
- PRF input: 100 bytes (same format)
- MIC: **HMAC-SHA1**, output truncated to 128 bits
- Compare against captured MIC

#### AKM 6 (PSK-SHA256) -- PMKID Attack

```
PMKID = HMAC-SHA256-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: **HMAC-SHA256**, output truncated to first 128 bits
- Input: same 20-byte string as AKM 2
- Different hash function than AKM 2!

#### AKM 6 (PSK-SHA256) + keyver 3 -- EAPOL Attack

```
PTK = KDF-384(PMK,
              "\x01\x00" ||
              "Pairwise key expansion" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce) ||
              "\x80\x01")
KCK = PTK[0:16]
MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- KDF uses **HMAC-SHA256** internally (not SHA1)
- KDF input: 102 bytes (counter prefix + 22-byte label without null + MACs + nonces + length suffix)
- Counter prefix: `\x01\x00` (LE uint16 = 1)
- Length suffix: `\x80\x01` (LE uint16 = 384)
- MIC: **AES-128-CMAC** (not HMAC-based)
- Compare against captured MIC

#### AKM 4 (FT-PSK) -- PMKID Attack

FT-PSK uses a completely different PMKID derivation based on the 802.11r key
hierarchy. The PMKID is not a simple HMAC of the PMK.

```
Step A: PMK-R0-Name-salt
  = HMAC-SHA256(PMK,
      counter_LE16(2) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take bytes 0-15 of the result.

Step B: PMK-R0-Name
  = SHA256("FT-R0N" || PMK-R0-Name-salt[0:16])
  Truncate to 128 bits.

Step C: PMKID
  = SHA256("FT-R1N" || PMK-R0-Name || R1KHID || STA_MAC)
  Truncate to 128 bits.
```

- All SHA-256 (no SHA-1 after the initial PBKDF2)
- Requires extra inputs: MDID, R0KH-ID, R1KH-ID

#### AKM 4 (FT-PSK) -- EAPOL Attack

```
Step A: PMK-R0
  = HMAC-SHA256(PMK,
      counter_LE16(1) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take first 32 bytes.

Step B: PMK-R1
  = HMAC-SHA256(PMK-R0,
      counter_LE16(1) || "FT-R1" ||
      R1KHID || STA_MAC ||
      size_LE16(256))
  Take first 32 bytes.

Step C: PTK
  = HMAC-SHA256(PMK-R1,
      counter_LE16(1) || "FT-PTK" ||
      SNonce || ANonce || MAC_AP || STA_MAC ||
      size_LE16(384))
  Take first 48 bytes.

Step D: MIC
  KCK = PTK[0:16]
  MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- Three chained HMAC-SHA256 KDF calls (vs one PRF call for standard PSK)
- Only keyver 3 (AES-CMAC) is used
- Requires: MDID, R0KH-ID, R1KH-ID in addition to standard handshake data

---

## Part 5: Capture Requirements Summary

### What You Need to Capture for Each Attack

| Attack | AKM | Minimum Capture | Fields Required |
|--------|-----|----------------|-----------------|
| PMKID | 2 (PSK) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |
| PMKID | 4 (FT-PSK) | M2 with PMKID + FT IEs | SSID, MAC_AP, MAC_STA, PMKID, MDID, R0KH-ID, R1KH-ID |
| PMKID | 6 (PSK-SHA256) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |
| EAPOL | 2 (PSK) | Any message pair (M1+M2 best) | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |
| EAPOL | 4 (FT-PSK) | Any message pair + FT IEs | Same as above + MDID, R0KH-ID, R1KH-ID |
| EAPOL | 6 (PSK-SHA256) | Any message pair | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |

### Where Each Field Comes From

| Field | Found In | Notes |
|-------|----------|-------|
| SSID | Beacon, Probe Response (IE tag 0) | Must be captured separately from handshake |
| MAC_AP | 802.11 header (addr2 for M1/M3, addr1 for M2/M4) | Role depends on message direction |
| MAC_STA | 802.11 header (addr1 for M1/M3, addr2 for M2/M4) | Role depends on message direction |
| ANonce | M1 or M3, EAPOL Key Nonce field (32 bytes) | Usually identical in M1 and M3 |
| SNonce | M2 (or M4 if non-zero), EAPOL Key Nonce field | M4 nonce often zeroed per spec |
| MIC | M2, M3, or M4, EAPOL Key MIC field (16 bytes) | M1 has no MIC |
| EAPOL frame | Raw bytes of the EAPOL-Key frame containing the MIC | MIC field zeroed for verification |
| PMKID | M1, M2, Assoc Req, or Reassoc Req Key Data, PMKID KDE (tag 0xDD, length 0x14, type 0x04) | Not always present. FT-PSK uses M2 specifically. |
| MDID | Mobility Domain IE (tag 0x36) in Beacon/assoc frames | 2 bytes, FT only |
| R0KH-ID | Fast BSS Transition IE (tag 0x37) subelement | Variable length, up to 48 bytes |
| R1KH-ID | Fast BSS Transition IE (tag 0x37) subelement | 6 bytes (usually = AP MAC) |

---

## Part 6: Hash Line Formats

### Mode 22000 (Standard WPA-PSK)

**Type 01 -- PMKID:**
```
WPA*01*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>***
         32hex   12hex    12hex    0-64hex
```

**Type 02 -- EAPOL:**
```
WPA*02*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<message_pair>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex
```

Note: the hashcat docs label field 7 as "ANONCE" but this is the **external
nonce**, which is the SNonce when the EAPOL is from M3 (see N2E3/N4E3 combos).
The EAPOL field (field 8) already contains the other nonce embedded within it.

**PMKID message pair field (type 01):**
```
bitmask of MESSAGEPAIR field for WPA*01:
  0: reserved
  1: PMKID from AP (standard)
  2: reserved
  4: PMKID from CLIENT (possible MESH or REPEATER)
```

**EAPOL message pair field (type 02):**
```
bitmask of MESSAGEPAIR field for WPA*02:
  bits 0-2:
    000 = M1+M2, EAPOL from M2 (challenge)          N1E2
    001 = M1+M4, EAPOL from M4 (authorized)         N1E4
    010 = M2+M3, EAPOL from M2 (authorized)         N3E2
    011 = M2+M3, EAPOL from M3 (authorized, --all)  N2E3
    100 = M3+M4, EAPOL from M3 (authorized, --all)  N4E3
    101 = M3+M4, EAPOL from M4 (authorized)         N3E4
  bit 3: reserved
  bit 4: AP-less attack (1 = no nonce-error-corrections needed)
  bit 5: LE router detected (1 = NC only for LE)
  bit 6: BE router detected (1 = NC only for BE)
  bit 7: replay count not checked (1 = NC mandatory)
```

N1E4 (0x01), N4E3 (0x04), and N3E4 (0x05) all depend on M4's nonce
being non-zero. Per IEEE 802.11i-2004 Section 8.5.3.4, M4's Key Nonce
shall be 0. Most implementations conform, making these three combos
unusable for the majority of captures.

**Hashcat pot file format (result of cracking):**
```
PMK*ESSID:PSK

PMK    = Plain Master Key (64 hex)
ESSID  = network name in hex
PSK    = Pre-Shared Key (the cracked password)
```

**Hashcat output file format:**
```
PMKID/MIC:MACAP:MACCLIENT:ESSID:PSK

PMKID/MIC = PMKID or MIC depending on hash type
MACAP     = AP MAC
MACCLIENT = client MAC
ESSID     = network name in plain text
PSK       = cracked password
```

### Mode 37100 (FT-PSK)

**Type 03 -- FT PMKID:**
```
WPA*03*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>****<MDID>*<R0KHID>*<R1KHID>
         32hex   12hex    12hex    0-64hex      4hex  var hex   12hex
```

**Type 04 -- FT EAPOL:**
```
WPA*04*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<message_pair>*<MDID>*<R0KHID>*<R1KHID>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex          4hex   var hex   12hex
```

---

## Part 7: The EAPOL-Key Frame Format

This is the raw frame that gets captured, MIC-zeroed, and included in the hash line.

```
Offset  Size  Field
------  ----  -----
0       1     Version (usually 0x01 or 0x02)
1       1     Type (0x03 = EAPOL-Key)
2       2     Length (big-endian, of everything after this field)
4       1     Key Descriptor Type (0xFE=WPA, 0x02=RSN)
5       2     Key Information (big-endian, bitfield below)
7       2     Key Length (16=CCMP, 32=TKIP)
9       8     Replay Counter
17      32    Key Nonce (ANonce or SNonce depending on message)
49      16    Key IV
65      8     Key RSC
73      8     Reserved
81      16    Key MIC  ← THIS is zeroed for MIC computation
97      2     Key Data Length
99      var   Key Data (RSN IEs, GTK KDE, PMKID KDE, FT IEs...)
```

### Key Information Bitfield (16 bits, big-endian)

| Bit(s) | Name | Values |
|--------|------|--------|
| 0-2 | Key Descriptor Version | 1=HMAC-MD5/RC4, 2=HMAC-SHA1/AES, 3=AES-CMAC/AES |
| 3 | Key Type | 1=Pairwise, 0=Group |
| 4-5 | (reserved) | |
| 6 | Install | 1 in M3 |
| 7 | Key Ack | 1 = response required (set by AP in M1, M3) |
| 8 | Key MIC | 1 = MIC field is valid (M2, M3, M4) |
| 9 | Secure | 1 = initial key exchange complete (M3, M4) |
| 10 | Error | MIC failure report (TKIP countermeasures) |
| 11 | Request | Supplicant requesting handshake |
| 12 | Encrypted Key Data | 1 in M3 (GTK encrypted) |

### How to Identify Each Message

| Message | Key Ack | Key MIC | Install | Secure | Has SNonce | Has Key Data |
|---------|---------|---------|---------|--------|------------|-------------|
| M1 | 1 | 0 | 0 | 0 | No (ANonce) | PMKID KDE (optional) |
| M2 | 0 | 1 | 0 | 0 | Yes (SNonce) | STA RSN IE |
| M3 | 1 | 1 | 1 | 1 | No (ANonce) | AP RSN IE + encrypted GTK |
| M4 | 0 | 1 | 0 | 1 | Often zeroed | Empty |

---

## Part 8: The Final Matrix -- SPEC vs HCXTOOLS vs HASHCAT

### PMKID Attacks

| # | AKM | Common Name | PMKID Algorithm (per spec) | hcxtools Extracts? | hcxtools Output | Hashcat Cracks? | Hashcat Mode | Notes |
|---|-----|-------------|---------------------------|-------------------|-----------------|----------------|-------------|-------|
| 1 | 2 | WPA/WPA2-PSK | HMAC-**SHA1**-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes | `WPA*01*` | **Yes** | 22000 | Fully working |
| 2 | 4 | WPA2-FT-PSK | SHA-**256** chain (HMAC-SHA256 KDF + 2x SHA-256) | Yes | `WPA*03*` | **No** (PR #4645 pending) | 37100 | Module exists but not merged |
| 3 | 6 | WPA2-PSK-SHA256 | HMAC-**SHA256**-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes (flag `PMKID_APPSK256`) | `WPA*01*` | **BROKEN** | 22000 | aux4 uses SHA1, spec requires SHA256. Silent failure. |

### EAPOL (4-Way Handshake) Attacks

| # | AKM | Cipher | keyver | PTK Derivation (per spec) | MIC Algorithm (per spec) | hcxtools Extracts? | hcxtools Output | Hashcat Cracks? | Hashcat Mode | Notes |
|---|-----|--------|--------|--------------------------|-------------------------|-------------------|-----------------|----------------|-------------|-------|
| 4 | 2 | TKIP | 1 | PRF-512 (HMAC-SHA1) | HMAC-MD5 | Yes | `WPA*02*` | **Yes** (aux1) | 22000 | Fully working |
| 5 | 2 | CCMP | 2 | PRF-384 (HMAC-SHA1) | HMAC-SHA1-128 | Yes | `WPA*02*` | **Yes** (aux2) | 22000 | Fully working |
| 6 | 6 | CCMP | 3 | KDF-384 (HMAC-SHA256) | AES-128-CMAC | Yes | `WPA*02*` | **Yes** (aux3) | 22000 | Fully working |
| 7 | 4 | CCMP | 3 | 3x HMAC-SHA256 KDF chain (R0->R1->PTK) | AES-128-CMAC | Yes | `WPA*04*` | **No** (PR #4645 pending) | 37100 | Module exists but not merged |
| 8 | 4 | CCMP | 3 | (same as above) | AES-128-CMAC | Yes, but skipped if >255 bytes | `WPA*04*` | **No** | 37100 | FT M2 frames often >255 bytes |

### Combined Summary View

```
                         ┌──────────────┐
                         │  SPEC SAYS   │
                         │   IT EXISTS  │
                         └──────┬───────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  AKM 2 PSK   │    │  AKM 4 FT    │     │  AKM 6 SHA256│
    │              │    │              │     │              │
    │ PMKID: SHA1  │    │ PMKID: SHA256│     │ PMKID: SHA256│
    │ EAPOL: 3     │    │   chain      │     │ EAPOL: kv3   │
    │  keyvers     │    │ EAPOL: kv3   │     │              │
    └──────┬───────┘    └──────┬───────┘     └───────┬──────┘
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  HCXTOOLS    │    │  HCXTOOLS    │     │  HCXTOOLS    │
    │              │    │              │     │              │
    │ PMKID: WPA*01│    │ PMKID: WPA*03│     │ PMKID: WPA*01│
    │ EAPOL: WPA*02│    │ EAPOL: WPA*04│     │ EAPOL: WPA*02│
    │ ALL WORKING  │    │ EAPOL >255B  │     │ ALL WORKING  │
    │              │    │ skipped      │     │              │
    └──────┬───────┘    └──────┬───────┘     └───────┬──────┘
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  HASHCAT     │    │  HASHCAT     │     │  HASHCAT     │
    │  MODE 22000  │    │  MODE 37100  │     │  MODE 22000  │
    │              │    │              │     │              │
    │ PMKID: YES   │    │ PMKID: NO    │     │ PMKID: BROKEN│
    │  (SHA1 aux4) │    │  (not merged)│     │  (uses SHA1, │
    │ kv1:YES aux1 │    │ EAPOL: NO    │     │   needs      │
    │ kv2:YES aux2 │    │  (not merged)│     │   SHA256)    │
    │ kv3:YES aux3 │    │              │     │ EAPOL: YES   │
    │              │    │              │     │  (kv3, aux3) │
    └──────────────┘    └──────────────┘     └──────────────┘
```

### The Gap Table

| # | What | Spec Says | hcxtools | hashcat | Status |
|---|------|-----------|----------|---------|--------|
| 1 | AKM 2 PMKID | HMAC-SHA1 | Extracts as `WPA*01` | aux4: HMAC-SHA1 | **Working** |
| 2 | AKM 2 EAPOL kv1 | PRF-SHA1 + HMAC-MD5 MIC | Extracts as `WPA*02` | aux1 | **Working** |
| 3 | AKM 2 EAPOL kv2 | PRF-SHA1 + HMAC-SHA1 MIC | Extracts as `WPA*02` | aux2 | **Working** |
| 4 | AKM 6 EAPOL kv3 | KDF-SHA256 + AES-CMAC MIC | Extracts as `WPA*02` | aux3 | **Working** |
| 5 | AKM 6 PMKID | **HMAC-SHA256** | Extracts as `WPA*01` (flag `APPSK256`) | aux4: uses **SHA1** | **BROKEN** -- wrong hash, silent failure |
| 6 | AKM 4 PMKID | SHA-256 chain | Extracts as `WPA*03` | No module in mainline | **MISSING** -- PR #4645 open |
| 7 | AKM 4 EAPOL kv3 | 3x HMAC-SHA256 + AES-CMAC | Extracts as `WPA*04` (if <=255B) | No module in mainline | **MISSING** -- PR #4645 open |
| 8 | AKM 4 EAPOL oversized | Same as #7 | Skips with warning if >255B | N/A | **MISSING** in both tools |

---

## Part 9: EAPOL Size Limits

| Tool / Context | Max EAPOL Size | Why |
|----------------|---------------|-----|
| IEEE 802.11 spec | 65535 bytes (uint16 length field) | Protocol allows it |
| hcxpcapngtool internal | 1024 bytes | Practical limit |
| hcxpcapngtool -> mode 22000 | 255 bytes | Legacy hccap/hccapx uint8 constraint |
| hcxpcapngtool -> mode 37100 | 1024 bytes | ZerBea raised limit for FT |
| hashcat m22000 kernel | 320 bytes (`eapol[64+16]` u32 words) | GPU buffer |
| hashcat m37100 kernel | 320 bytes (`eapol[64+16]` u32 words) | GPU buffer |
| Typical WPA2-PSK M2 | ~120-140 bytes | Fits easily |
| Typical FT-PSK M2 | ~260-300 bytes | Contains FT IEs, often exceeds 255 |
| Largest in wpa-sec (2018 analysis) | **510 bytes** | ZerBea found 256-510 byte frames in wpa-sec data |

ZerBea's 2018 wpa-sec analysis found these EAPOL lengths in real captures:
256, 258, 262, 270, 278, 288, 294, 306, 310, 322, 326, 330, 334, 342,
358, 370, 374, 386, 390, 406, 422, 438, 484, 500, 502, 510.
(Source: https://github.com/hashcat/hashcat/issues/1816)

### ESSID encoding

The ESSID field in hash lines is always hex-encoded because IEEE 802.11
defines SSIDs as arbitrary 0-32 byte sequences, not strings. An SSID can
contain null bytes, non-UTF8 sequences, or any byte value. When parsing
the hex ESSID field, use the field length divided by 2 as the ESSID
length. Do not use strlen() on the decoded bytes.

---

## Part 10: Hashcat Modes for WPA

### The Current Modes

| Mode | Name | Input | PBKDF2? | Use Case |
|------|------|-------|---------|----------|
| **22000** | WPA-PBKDF2-PMKID+EAPOL | Passphrase (8-63 chars) | Yes (4096 iter) | Standard attack -- guess passphrases |
| **22001** | WPA-PMK-PMKID+EAPOL | Raw PMK (64 hex chars) | No (skipped) | Pre-computed PMKs, memory dumps, PMK databases |
| **37100** | WPA-PBKDF2-PMKID+EAPOL (FT) | Passphrase (8-63 chars) | Yes (4096 iter) | FT-PSK attack (PR #4645, not yet merged) |

**Mode 22001** uses the exact same `WPA*01*`/`WPA*02*` hash line format as
22000. The only difference: the "password" candidates are 64-hex-char raw PMKs
instead of passphrases. PBKDF2 is skipped entirely (iterations = 0), making it
orders of magnitude faster. Use this when you have:

- Pre-computed PMK tables for a specific SSID (e.g., from Pyrit)
- A PMK extracted from device memory or a compromised RADIUS server
- A rainbow table of SSID-specific PMKs

### PMKID + EAPOL in the Same Session

PMKID (type 01) and EAPOL (type 02) hashes for the **same SSID** share the
same PBKDF2 salt. Hashcat computes the PMK once per guess and tests it against
all matching hashes. Put both types in the same file:

```
WPA*01*<pmkid_1>*<mac_ap>*<mac_sta1>*<essid>***
WPA*02*<mic_1>*<mac_ap>*<mac_sta2>*<essid>*<anonce>*<eapol>*<mp>
```

One PBKDF2 computation covers both. This costs almost nothing extra since PBKDF2
dominates 99.9% of the time and the PMKID/MIC verification is negligible.

### How Hashcat Groups Hashes by Salt

Hashcat organizes all hashes into salt groups by ESSID. Per password guess:

1. Compute PBKDF2 once per unique ESSID (the expensive part)
2. Test that PMK against every hash sharing that ESSID (cheap, parallel)

```
Salt group "MyNetwork":
  PBKDF2(guess, "MyNetwork", 4096) -> PMK       <- computed ONCE
  test PMK against 50,000 EAPOL hashes           <- cheap per hash
  test PMK against 3 PMKID hashes                <- cheap per hash
```

This means adding more hashes for the same ESSID is nearly free. On a test
capture with 42 unique ESSIDs, extracting 1,221,007 hashes (vs 96 with default
settings) costs only 42 PBKDF2 computations per guess. The extra hashes add
~0.03% overhead for 12,720x more chances to crack.

### Correct Hash Line Deduplication

Two `WPA*02*` lines with identical fields 3-8 (MIC, AP, STA, ESSID, NONCE,
EAPOL) but different field 9 (message_pair byte) are the same hash from
hashcat's perspective. A naive `sort -u` on full lines overcounts by ~27%
because it treats different message_pair bytes as distinct.

Correct dedup preserves the message_pair byte from whichever line survives:
```bash
awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' raw.22000 > unique.22000
```

### Deprecated Modes (Do NOT Use)

These are legacy modes from before the unified 22000 format. They use obsolete
binary formats (hccapx, hccap) or single-purpose text formats. They will be
removed from hashcat and should not be used:

| Mode | Old Name | Replaced By |
|------|----------|------------|
| 2500 | WPA-EAPOL-PBKDF2 | 22000 (type 02) |
| 2501 | WPA-EAPOL-PMK | 22001 (type 02) |
| 16800 | WPA-PMKID-PBKDF2 | 22000 (type 01) |
| 16801 | WPA-PMKID-PMK | 22001 (type 01) |

If you encounter hccapx files, convert them: hashcat mode 22000 auto-detects
the binary hccapx format and converts internally, or use `hcxhash2cap` to
convert between formats.

---

## Part 11: hcxpcapngtool Options That Affect Hash Output

### Hash Combo Naming Convention

Each WPA hash is built from two messages: one provides the EAPOL frame (MIC +
embedded nonce), the other provides the external nonce not present in the frame.

Multiple naming conventions exist across tools and documentation:

```
N#E# (this guide):  N{nonce_source}E{eapol_source}     e.g. N1E2
Verbose:            eapol=M{e} nonce=M{n}               e.g. eapol=M2 nonce=M1
Educational:        M{e}({embedded}+MIC) + M{n}({ext})  e.g. M2(SNonce+MIC) + M1(ANonce)
```

### All formats for the 6 valid combos

| N#E# | eapol= nonce= | Educational | hcx Bitmask | hcx Description | hcx Notes | Old hcx (M##E#) | hashcat message_pair |
|------|---------------|-------------|-------------|-----------------|-----------|-----------------|----------------------|
| N1E2 | eapol=M2 nonce=M1 | M2(SNonce+MIC) + M1(ANonce) | 000 | M1+M2, EAPOL from M2 | challenge, default | M12E2 | 0x00 |
| N1E4 | eapol=M4 nonce=M1 | M4(SNonce+MIC) + M1(ANonce) | 001 | M1+M4, EAPOL from M4 | authorized, --all | M14E4 | 0x01 |
| N3E2 | eapol=M2 nonce=M3 | M2(SNonce+MIC) + M3(ANonce) | 010 | M2+M3, EAPOL from M2 | authorized, default | M32E2 | 0x02 |
| N2E3 | eapol=M3 nonce=M2 | M3(ANonce+MIC) + M2(SNonce) | 011 | M2+M3, EAPOL from M3 | authorized, --all | M32E3 | 0x03 |
| N4E3 | eapol=M3 nonce=M4 | M3(ANonce+MIC) + M4(SNonce) | 100 | M3+M4, EAPOL from M3 | authorized, --all | M34E3 | 0x04 |
| N3E4 | eapol=M4 nonce=M3 | M4(SNonce+MIC) + M3(ANonce) | 101 | M3+M4, EAPOL from M4 | authorized, --all | M34E4 | 0x05 |

**Reading N#E#**: N = external nonce source message, E = EAPOL frame source message.
N1E2 means "nonce from M1, EAPOL from M2." hashcat extracts the SNonce from
inside M2's EAPOL frame and uses the ANonce from M1 as the hash line's nonce field.

N1E4 (0x01), N4E3 (0x04), and N3E4 (0x05) all depend on M4's nonce
being non-zero. Per IEEE 802.11i-2004 Section 8.5.3.4, M4's Key Nonce
shall be 0. Most implementations conform, making these three combos
unusable for the majority of captures.

**Reading old hcx M##E#**: The first two digits are ANonce source and SNonce
source (e.g., M32E3 = ANonce from M3, SNonce from M2, EAPOL from M3). Used in
hcxtools discussions and source code (as ST_M12E2, ST_M32E3, etc.).

**Reading hcx columns**: The three hcx columns (Bitmask, Description, Notes)
come directly from the upstream hcxtools README "Bitmask Message Pair Field"
section. "Mx+My" labels the two messages involved, then the description
specifies which provides the EAPOL frame.

### Identical hash pairs

Within one handshake session, M1 and M3 carry the same ANonce, and M2 and M4
carry the same SNonce. So these pairs produce identical crackable hashes:

```
N1E2 == N3E2  (both use M2's EAPOL, ANonce is the same value)
N2E3 == N4E3  (both use M3's EAPOL, SNonce is the same value)
N1E4 == N3E4  (both use M4's EAPOL, ANonce is the same value)
```

### Options Reference

| Option | Default | What It Controls |
|--------|---------|-----------------|
| `--all` | off | Master switch: disables dedup, adds N2E3/N4E3, includes relayed/zeroed-PSK/bad-FCS frames |
| `--nonce-error-corrections=N` | 0 | Max replay counter gap between paired messages. 0 = exact match only. |
| `--eapoltimeout=N` | 5000 (ms) | Max time gap between paired messages. |
| `--ignore-ie` | off | Bypass AKM checks (process non-PSK APs, PSK-SHA256 mismatches). |

### What Default Mode Does

With no flags, hcxpcapngtool:

1. **Generates only 4 combo types**: N1E2, N1E4, N3E2, N3E4 (not N2E3/N4E3)
2. **Requires exact RC match**: rcgap must be 0 (no nonce error tolerance)
3. **Enforces 5-second timeout**: messages more than 5s apart are not paired
4. **Deduplicates to 1 hash per AP/STA pair**: keeps the "best" (smallest time gap)
5. **Skips relayed frames**: WDS/relayed EAPOL messages are dropped
6. **Skips zeroed PSK/PMK**: hashes that verify against empty passphrase are dropped
7. **Checks AKM from beacons**: only PSK/PSK-SHA256/FT-PSK APs produce hashes

### What `--all` Enables

1. **Adds N2E3 and N4E3 combo types** (EAPOL from M3 with external SNonce)
2. **Disables per-AP/STA deduplication**: writes ALL pairs, not just the best
3. **Includes relayed/WDS frames**
4. **Includes zeroed PSK/PMK hashes**
5. **Includes bad FCS frames**
6. Combined with NC>0, this produces the maximum number of hash lines

### What `--nonce-error-corrections=N` Does

Allows pairing messages where the replay counter differs by up to N from the
expected value. This compensates for:
- AP firmware bugs that increment the nonce counter between derivation and transmission
- Packet loss causing retransmitted M1/M3 with bumped counters
- Multiple interleaved handshake attempts

When NC>0, the sort order changes: "best" pair is determined by smallest RC gap
(instead of smallest time gap). The message_pair byte gets bit 7 set (0x80)
to tell hashcat that nonce error correction may be needed.

### Options Matrix (tested results)

| Pcap | Messages | Our unique | default | --all | NC=8+all | bruteforce |
|------|----------|-----------|---------|-------|----------|------------|
| small_m4 | 1/1/1/1(nz) | 3e | 1e/0p | 6e/0p | 6e/0p | **3e**/0p |
| 331 | 1/1/1/1(z) | 2e | 1e/0p | 3e/0p | 3e/0p | **2e**/0p |
| 327 | 5/5/8/4(z) | 45e | 1e/1p | 20e/5p | 51e/5p | **45e**/5p |
| 546 | 15/1/2/1(z) | 8e | 1e/0p | 3e/0p | 10e/0p | **8e**/0p |

Messages format: M1/M2/M3/M4 count, (nz)=non-zero M4 nonce, (z)=zeroed.
Output format: {EAPOL}e/{PMKID}p.

Key observations:
- **`--all` has the biggest impact** (6x-20x more hashes) because it disables dedup
- **NC only matters with `--all`**: without `--all`, dedup limits output to 1 per pair anyway
- **`--eapoltimeout` and `--ignore-ie` had no effect** on these test captures
- **Default mode under-extracts** because of dedup (1 per AP/STA), strict RC
  matching, and only 4 of 6 combo types. `--bruteforce` recovers everything.

### `--bruteforce` Mode (crackwolf custom)

Our custom build adds `--bruteforce` which enables maximum hash extraction:
- Enables `--all` + `--ignore-ie`
- Sets NC and timeout to maximum
- Uses a 4096-entry message window (vs default 64)
- **Deduplicates by hash fingerprint** (SHA1 of AP+STA+ANonce+EAPOL via
  OpenSSL EVP API) so each unique crackable hash is written exactly once

Tested against `wpa_audit.py` (independent Python implementation using scapy):
all test pcaps produce identical unique fingerprint sets with `--bruteforce`.

---

## Part 12: Quick Reference -- Cracking Cheat Sheet

### Capture and Crack Workflow

```
1. CAPTURE
   hcxdumptool -> capture.pcapng

2. CHECK FOR FT-PSK (802.11r) NETWORKS
   tshark -r capture.pcapng -Y "wlan.rsn.akms.type == 4" \
       -T fields -e wlan.sa -e wlan.ssid | sort -u

3. CONVERT
   hcxpcapngtool -o hashes.22000 capture.pcapng       # standard WPA
   hcxpcapngtool -o hashes.22000 -f hashes.37100 \    # also extract FT
       capture.pcapng

4. DEDUP (important: dedup by crackable content, not full line)
   awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' hashes.22000 > unique.22000

5. CHECK WHAT YOU GOT
   python3 mp_print.py unique.22000                    # decode message pairs
   hcxhashtool -i unique.22000 --info                  # detailed hash info

6. CRACK
   hashcat -m 22000 unique.22000 wordlist.txt          # passphrase attack
   hashcat -m 22001 unique.22000 pmk_list.txt          # pre-computed PMK attack
   hashcat -m 37100 hashes.37100 wordlist.txt          # FT-PSK (mode 37100)
```

### Detecting Network Types with tshark

```bash
# AKM type 2 = standard PSK (mode 22000)
# AKM type 4 = FT-PSK / 802.11r (mode 37100)
# AKM type 6 = PSK-SHA256 / 802.11w (mode 22000, keyver 3)
# AKM type 8 = SAE / WPA3 (not crackable offline)

# List all WPA networks and their AKM types:
tshark -r capture.pcap -Y "wlan.rsn.akms.type" \
    -T fields -e wlan.sa -e wlan.ssid -e wlan.rsn.akms.type \
    2>/dev/null | sort -u

# Batch scan a directory:
for f in /path/to/pcaps/*.pcap; do
    count=$(tshark -r "$f" -Y "wlan.rsn.akms.type == 4" 2>/dev/null | wc -l)
    [ "$count" -gt 0 ] && echo "$f: $count FT-PSK frames"
done
```

### Useful Commands

**Reduce pcap size before conversion** (strips everything except mgmt frames + EAPOL):
```bash
tshark -r dumpfile.pcap \
    -R "(wlan.fc.type_subtype == 0x00 || wlan.fc.type_subtype == 0x02 || \
         wlan.fc.type_subtype == 0x04 || wlan.fc.type_subtype == 0x05 || \
         wlan.fc.type_subtype == 0x08 || eapol)" \
    -2 -F pcapng -w stripped.pcapng
```

Do not clean pcaps with wpaclean (removes useful frames). Do not merge pcapng
files (destroys metadata). Do not filter during capture.

**Convert with ESSID wordlist extraction** (pulls ESSIDs and identities into
a wordlist for targeted cracking):
```bash
hcxpcapngtool -o hash.hc22000 -E wordlist dumpfile.pcapng
hashcat -m 22000 hash.hc22000 wordlist
```

**Filter hash files:**
```bash
# By type
grep 'WPA\*01' hash.hc22000 > pmkid_only.hc22000
grep 'WPA\*02' hash.hc22000 > eapol_only.hc22000
hcxhashtool -i hash.hc22000 --type=1 -o pmkid_only.hc22000
hcxhashtool -i hash.hc22000 --type=2 -o eapol_only.hc22000

# By authorization status
hcxhashtool -i hash.hc22000 --authorized -o authorized.hc22000
hcxhashtool -i hash.hc22000 --challenge -o challenge.hc22000

# By MAC address
hcxhashtool -i hash.hc22000 --mac-ap=112233445566 -o target_ap.hc22000
hcxhashtool -i hash.hc22000 --mac-client=112233445566 -o target_sta.hc22000
```

**Online converter** (no need to compile hcxtools):
https://hashcat.net/cap2hashcat/

### What Determines Cracking Speed

| Step | Operations per guess | Relative Cost |
|------|---------------------|---------------|
| PBKDF2-SHA1 (PMK) | 8192 HMAC-SHA1 calls | **~99.9%** of total time |
| PTK derivation | 1-3 HMAC calls | ~0.05% |
| MIC verification | 1 HMAC or AES-CMAC call | ~0.05% |

The PBKDF2 step dominates everything. Cracking speed is measured in PMKs/second
and is essentially identical regardless of keyver (1, 2, or 3). Mode 22001
eliminates PBKDF2 entirely, making it limited only by PTK + MIC speed.
