# Hash Extraction Reference

Hash line formats, hashcat modes, and EAPOL size constraints for all supported
WiFi attack types.

---

## WPA Hash Line Formats

### Mode 22000 — WPA*01 (PMKID)

```
WPA*01*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>***
         32hex   12hex    12hex    0-64hex
```

Fields:

| Field | Encoding | Description |
|-------|----------|-------------|
| PMKID | 32-char hex (16 bytes) | Captured PMKID value |
| MAC_AP | 12-char hex (6 bytes) | AP BSSID, no separators |
| MAC_STA | 12-char hex (6 bytes) | STA MAC, no separators |
| ESSID | 0–64-char hex (0–32 bytes) | SSID hex-encoded (not string) |
| Fields 7–9 | empty | Unused in type 01 |

### Mode 22000 — WPA*02 (EAPOL)

```
WPA*02*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<MP>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex
```

Fields:

| Field | Encoding | Description |
|-------|----------|-------------|
| MIC | 32-char hex (16 bytes) | MIC from the EAPOL frame |
| MAC_AP | 12-char hex | AP BSSID |
| MAC_STA | 12-char hex | STA MAC |
| ESSID | 0–64-char hex | SSID hex-encoded |
| NONCE | 64-char hex (32 bytes) | External nonce (ANonce if EAPOL=M2/M4, SNonce if EAPOL=M3) |
| EAPOL | variable hex | Raw EAPOL-Key frame (MIC field zeroed) |
| MP | 2-char hex (1 byte) | message_pair bitmask |

!!! note "NONCE field label"
    hashcat docs label field 7 as "ANONCE" but this is the external nonce.
    For N2E3/N4E3 combos (EAPOL from M3), the external nonce is the SNonce.

### Mode 22000 — message_pair byte

Lower 3 bits encode the N#E# combo; upper bits are flags:

```
Bits 0-2:
  000 = N1E2  (M1+M2, EAPOL from M2)  challenge
  001 = N1E4  (M1+M4, EAPOL from M4)  authorized, --all
  010 = N3E2  (M2+M3, EAPOL from M2)  authorized
  011 = N2E3  (M2+M3, EAPOL from M3)  authorized, --all
  100 = N4E3  (M3+M4, EAPOL from M3)  authorized, --all
  101 = N3E4  (M3+M4, EAPOL from M4)  authorized, --all
Bit 4: 0x10 = AP-less attack
Bit 5: 0x20 = LE router detected
Bit 6: 0x40 = BE router detected
Bit 7: 0x80 = replay count not checked (NC corrections needed)
```

### Mode 37100 — WPA*03 (FT PMKID)

```
WPA*03*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>****<MDID>*<R0KHID>*<R1KHID>
         32hex   12hex    12hex    0-64hex      4hex  var hex   12hex
```

### Mode 37100 — WPA*04 (FT EAPOL)

```
WPA*04*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<MP>*<MDID>*<R0KHID>*<R1KHID>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex  4hex   var hex   12hex
```

### ESSID Encoding

The ESSID field is always hex-encoded because IEEE 802.11 defines SSIDs as
arbitrary 0–32 byte sequences. An SSID can contain null bytes, non-UTF8
sequences, or any byte value. Field length ÷ 2 = SSID byte length.

---

## hashcat Mode Reference

| Mode | Name | Input | PBKDF2? | Use case |
|------|------|-------|---------|----------|
| 22000 | WPA-PBKDF2-PMKID+EAPOL | Passphrase (8–63 chars) | Yes (4096 iter) | Standard passphrase attack |
| 22001 | WPA-PMK-PMKID+EAPOL | Raw PMK (64 hex chars) | No (skipped) | Pre-computed PMKs, memory dumps |
| 37100 | WPA-PBKDF2-PMKID+EAPOL (FT) | Passphrase (8–63 chars) | Yes (4096 iter) | FT-PSK attack (PR #4645, not yet merged) |
| 5500 | NetNTLMv1 / MSCHAPv2 | `user::::NTresp:chal` | No | PEAP/LEAP credential cracking |
| 4800 | iSCSI CHAP / EAP-MD5 | `hash:id:challenge` | No | EAP-MD5 credential cracking |

**Mode 22001** uses the same `WPA*01*`/`WPA*02*` hash format as 22000. The
only difference: password candidates are 64-hex-char raw PMKs. PBKDF2 is
skipped entirely (iterations = 0), making it orders of magnitude faster.

### PMKID + EAPOL in One Session

PMKID (type 01) and EAPOL (type 02) hashes for the same SSID share the same
PBKDF2 salt. hashcat computes the PMK once per guess and tests it against all
matching hashes. Put both types in the same file:

```
WPA*01*<pmkid>*<mac_ap>*<mac_sta1>*<essid>***
WPA*02*<mic>*<mac_ap>*<mac_sta2>*<essid>*<nonce>*<eapol>*<mp>
```

### Salt Grouping

hashcat organizes hashes into salt groups by ESSID. Per password guess:

1. Compute PBKDF2 once per unique ESSID (expensive)
2. Test that PMK against every hash sharing that ESSID (cheap, parallel)

Adding more hashes for the same ESSID is nearly free — PBKDF2 dominates.

### Deduplication

Two `WPA*02*` lines with identical fields 3–8 (MIC, AP, STA, ESSID, NONCE,
EAPOL) but different field 9 (message_pair byte) are the same hash. A naive
`sort -u` on full lines overcounts by ~27%.

Correct dedup (preserves the message_pair byte from the surviving line):

```bash
awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' raw.22000 > unique.22000
```

### Deprecated Modes

| Mode | Old name | Replaced by |
|------|----------|-------------|
| 2500 | WPA-EAPOL-PBKDF2 | 22000 (type 02) |
| 2501 | WPA-EAPOL-PMK | 22001 (type 02) |
| 16800 | WPA-PMKID-PBKDF2 | 22000 (type 01) |
| 16801 | WPA-PMKID-PMK | 22001 (type 01) |

---

## EAPOL Size Constraints

| Tool / context | Max EAPOL size | Why |
|----------------|---------------|-----|
| IEEE 802.11 spec | 65535 bytes (uint16 length field) | Protocol allows it |
| hcxpcapngtool internal | 1024 bytes | Practical implementation limit |
| hcxpcapngtool → mode 22000 | 255 bytes | Legacy hccap/hccapx uint8 constraint |
| hcxpcapngtool → mode 37100 | 1024 bytes | ZerBea raised limit for FT |
| hashcat m22000 kernel | 320 bytes (`eapol[64+16]` u32 words) | GPU buffer |
| hashcat m37100 kernel | 320 bytes | GPU buffer |
| Typical WPA2-PSK M2 | ~120–140 bytes | Fits easily |
| Typical FT-PSK M2 | ~260–300 bytes | Contains FT IEs, often exceeds 255 |
| Largest in wpa-sec (2018) | **510 bytes** | ZerBea found 256–510 byte frames |

ZerBea's 2018 wpa-sec analysis found real FT-PSK EAPOL lengths:
256, 258, 262, 270, 278, 288, 294, 306, 310, 322, 326, 330, 334, 342,
358, 370, 374, 386, 390, 406, 422, 438, 484, 500, 502, 510.
(Source: hashcat issue #1816)

---

## EAP Hash Formats

### Mode 5500 — NetNTLMv1 / MSCHAPv2

```
username::::NT-Response:challenge
```

| Field | Encoding | Size |
|-------|----------|------|
| username | plaintext | variable |
| LM Response | empty (4 colons) | 0 |
| NT-Response | 48-char hex (24 bytes) | 24 bytes |
| challenge | 16-char hex (8 bytes) | 8 bytes |

Challenge = `SHA1(peer_challenge || auth_challenge || username)[0:8]`

### Mode 4800 — iSCSI CHAP / EAP-MD5

```
md5_response:identifier:challenge
```

| Field | Encoding | Size |
|-------|----------|------|
| md5_response | 32-char hex (16 bytes) | 16 bytes |
| identifier | 2-char hex (1 byte) | 1 byte |
| challenge | variable hex | variable |

### Hashcat Output Format

After cracking:

```
PMKID/MIC:MACAP:MACCLIENT:ESSID:PSK
```

Pot file format:

```
PMK*ESSID:PSK
```
