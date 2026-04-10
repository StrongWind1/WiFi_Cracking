# EAPOL Attack (MIC Verification)

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

In code, this looks like:

```
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
