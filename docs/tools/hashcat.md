# hashcat

## WiFi-Related Modes

| Mode | Name | Input |
|------|------|-------|
| 22000 | WPA-PBKDF2-PMKID+EAPOL | WPA*01 (PMKID) and WPA*02 (EAPOL) hash lines |
| 22001 | WPA-PMK-PMKID+EAPOL | Pre-computed PMK input (skips PBKDF2) |
| 37100 | WPA3-SAE-PMKID | SAE/WPA3 PMKID hash lines |
| 5500  | NetNTLMv1 / MSCHAPv2 | PEAP/LEAP challenge/response |
| 4800  | iSCSI CHAP / EAP-MD5 | MD5-Challenge hash lines |

## Deprecated Modes

| Mode | Replaced By | Notes |
|------|------------|-------|
| 2500 | 22000 | Old WPA EAPOL format, split PMKID/EAPOL |
| 16800 | 22000 | Old WPA PMKID-only format |

These modes are no longer accepted by current hashcat versions. Convert old hash
files using hcxhashtool or re-extract from the original capture.

## Hash Format Per Mode

Placeholder for a detailed breakdown of the hash line format for each active mode,
with field positions, data types, and encoding (hex vs. base64).

## Salt Grouping and Dedup

hashcat groups WPA hashes by ESSID (salt) to amortize the PBKDF2 computation
across multiple BSSIDs sharing the same network name. Placeholder for details
on deduplication behavior, the impact on performance, and how to control grouping.

## Common Commands

Placeholder for example hashcat commands covering: dictionary attack, rule-based
attack, mask attack, and combination attack against mode 22000 hash files.

## Relative Performance Notes

Placeholder for rough performance figures across GPU generations for mode 22000
(PBKDF2-SHA1 is the bottleneck), mode 5500 (DES-based, very fast), and mode 4800
(MD5, extremely fast). These numbers are hardware-dependent and intended as
order-of-magnitude guidance.
