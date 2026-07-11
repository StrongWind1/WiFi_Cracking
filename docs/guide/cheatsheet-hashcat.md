# hashcat Quick Reference

## Cracking

```bash
# Wordlist attack
hashcat -m 22000 hashes.22000 wordlist.txt

# Wordlist + rules
hashcat -m 22000 hashes.22000 wordlist.txt -r rules/best64.rule

# Brute-force 8-digit numeric
hashcat -m 22000 hashes.22000 -a 3 '?d?d?d?d?d?d?d?d'

# Pre-computed PMK (skips PBKDF2, 100-1000x faster)
hashcat -m 22001 hashes.22000 pmk_table.txt

# FT-PSK (requires hashcat PR #4645)
hashcat -m 37100 hashes.37100 wordlist.txt

# EAP-MD5
hashcat -m 4800 eapmd5.hashes wordlist.txt

# MSCHAPv2 / LEAP
hashcat -m 5500 mschapv2.hashes wordlist.txt
```

## Results

```bash
# Show cracked passwords
hashcat -m 22000 hashes.22000 --show

# Output format: hash:password
```

## WiFi Modes

| Mode | Name | Input | Speed |
|------|------|-------|-------|
| 22000 | WPA-PBKDF2 | Passphrase | Slow (PBKDF2 4096 iter) |
| 22001 | WPA-PMK | Raw 64-hex PMK | 100-1000x faster |
| 37100 | FT-PSK | Passphrase | Same as 22000 |
| 4800 | EAP-MD5 | Passphrase | Fast |
| 5500 | MSCHAPv2 | Passphrase | Fast (DES) |

## Mask Placeholders

| Placeholder | Character set |
|-------------|--------------|
| `?d` | Digits (0-9) |
| `?l` | Lowercase (a-z) |
| `?u` | Uppercase (A-Z) |
| `?s` | Special (!@#$...) |
| `?a` | All printable |

## Hash Filtering

```bash
# Split by type
grep 'WPA\*01' hashes.22000 > pmkid_only.22000
grep 'WPA\*02' hashes.22000 > eapol_only.22000

# Filter by authorization status
hcxhashtool -i hashes.22000 --authorized -o authorized.22000
hcxhashtool -i hashes.22000 --challenge -o challenge.22000

# Filter by AP MAC
hcxhashtool -i hashes.22000 --mac-ap=112233445566 -o target_ap.22000

# Hash info summary
hcxhashtool -i hashes.22000 --info=stdout
```

## Deduplication

```bash
# Correct dedup (fields 3-8, ignoring message_pair byte)
awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' raw.22000 > unique.22000

# Naive sort -u overcounts by ~27% — don't use it
```

## ESSID Wordlist from Captures

```bash
# Extract SSIDs with WPAWolf
wpawolf --22000-out /dev/null -E essids.txt -W wordlist.txt captures/

# Or with tshark
tshark -r capture.pcapng -Y "wlan.ssid" \
    -T fields -e wlan.ssid 2>/dev/null | sort -u > essids.txt
```

[Full hashcat reference](../tools/hashcat.md)
