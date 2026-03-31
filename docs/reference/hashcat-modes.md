# Hashcat Modes

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
