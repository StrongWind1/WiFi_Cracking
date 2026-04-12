# hashcat

GPU-accelerated password recovery tool. For WiFi attacks, hashcat operates on
hash lines produced by hcxpcapngtool from pcap captures.

## WiFi-Related Modes

| Mode | Name | Input | PBKDF2? | Use case |
|------|------|-------|---------|----------|
| **22000** | WPA-PBKDF2-PMKID+EAPOL | Passphrase (8–63 chars) | Yes (4096 iter) | Standard PSK attack |
| **22001** | WPA-PMK-PMKID+EAPOL | Raw PMK (64 hex chars) | No (skipped) | Pre-computed PMKs, memory dumps |
| **37100** | WPA-PBKDF2-PMKID+EAPOL (FT) | Passphrase (8–63 chars) | Yes (4096 iter) | FT-PSK (PR #4645, not yet merged) |
| **5500** | NetNTLMv1 / MSCHAPv2 | `user::::NTresp:challenge` | No | PEAP/LEAP credential cracking |
| **4800** | iSCSI CHAP / EAP-MD5 | `hash:id:challenge` | No | EAP-MD5 cracking |

**Mode 22001** uses the same `WPA*01*`/`WPA*02*` format as 22000. The only
difference: candidates are 64-hex-char raw PMKs. PBKDF2 is skipped entirely
(iterations = 0) — orders of magnitude faster. Use with pre-computed PMK tables
or PMKs extracted from device memory.

## Deprecated Modes

These modes use obsolete binary or split-format files. Do not use:

| Mode | Old name | Replaced by |
|------|----------|-------------|
| 2500 | WPA-EAPOL-PBKDF2 | 22000 (type 02) |
| 2501 | WPA-EAPOL-PMK | 22001 (type 02) |
| 16800 | WPA-PMKID-PBKDF2 | 22000 (type 01) |
| 16801 | WPA-PMKID-PMK | 22001 (type 01) |

## Salt Grouping

hashcat groups WPA hashes by ESSID to amortize PBKDF2 across shared SSIDs.
Per password guess:

1. Compute PBKDF2 once per unique ESSID (the expensive step)
2. Test the PMK against every hash sharing that ESSID (cheap, parallel)

Adding more hashes for the same ESSID costs almost nothing since PBKDF2
dominates 99.9% of compute time.

## Deduplication

Two `WPA*02*` lines with identical fields 3–8 (MIC, AP, STA, ESSID, NONCE,
EAPOL) but different field 9 (message_pair byte) are the same hash. A naive
`sort -u` overcounts by ~27%. Correct dedup:

```bash
awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' raw.22000 > unique.22000
```

## Common Commands

```bash
# Dictionary attack
hashcat -m 22000 hashes.22000 wordlist.txt

# Dictionary + rules
hashcat -m 22000 hashes.22000 wordlist.txt -r rules/best64.rule

# Mask attack (8-digit numeric)
hashcat -m 22000 hashes.22000 -a 3 '?d?d?d?d?d?d?d?d'

# Pre-computed PMK attack (skip PBKDF2)
hashcat -m 22001 hashes.22000 pmk_table.txt

# EAP-MD5
hashcat -m 4800 eapmd5.hashes wordlist.txt

# MSCHAPv2 / LEAP
hashcat -m 5500 mschapv2.hashes wordlist.txt

# Tshark: check AKM types in capture
tshark -r capture.pcap -Y "wlan.rsn.akms.type" \
    -T fields -e wlan.sa -e wlan.ssid -e wlan.rsn.akms.type \
    2>/dev/null | sort -u

# Filter hash file by type
grep 'WPA\*01' hashes.22000 > pmkid_only.22000
grep 'WPA\*02' hashes.22000 > eapol_only.22000

# Filter by authorization status (requires hcxhashtool)
hcxhashtool -i hashes.22000 --authorized -o authorized.22000
hcxhashtool -i hashes.22000 --challenge -o challenge.22000

# Filter by MAC address
hcxhashtool -i hashes.22000 --mac-ap=112233445566 -o target_ap.22000
```

## Cracking Speed Breakdown

| Step | Operations per guess | Relative cost |
|------|---------------------|---------------|
| PBKDF2-SHA1 (PMK) | 8192 HMAC-SHA1 calls | **~99.9%** of total time |
| PTK derivation | 1–3 HMAC calls | ~0.05% |
| MIC verification | 1 HMAC or AES-CMAC call | ~0.05% |

The PBKDF2 step dominates everything. Cracking speed is effectively identical
for keyver 1, 2, and 3. Mode 22001 eliminates PBKDF2 entirely and is limited
only by PTK + MIC speed — typically 100–1000× faster than mode 22000.

Mode 5500 (MSCHAPv2/LEAP) uses DES internally and is extremely fast by
comparison — billions of candidates per second on modern GPUs. Mode 4800
(EAP-MD5) is similarly fast.

## PMKID + EAPOL in One Session

PMKID (`WPA*01*`) and EAPOL (`WPA*02*`) hashes for the same SSID share the
PBKDF2 salt. Put both in the same file — one PBKDF2 per guess covers both:

```
WPA*01*<pmkid>*<mac_ap>*<mac_sta1>*<essid>***
WPA*02*<mic>*<mac_ap>*<mac_sta2>*<essid>*<nonce>*<eapol>*<mp>
```
