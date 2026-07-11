# WPAWolf Quick Reference

## Extract Hashes

```bash
# Legacy hashcat modes (22000 + 37100)
wpawolf --22000-out hashes.22000 --37100-out hashes.37100 capture.pcapng

# Smart mode — fewer lines, zero MIC loss (recommended)
wpawolf --22000-out hashes.22000 --smart captures/

# Directory scan — cross-file pairing
wpawolf --22000-out h.22000 captures/

# Combined per-AKM output (all 11 hash types)
wpawolf -o all.out captures/

# Per-AKM split
wpawolf --wpa2-out wpa2.out --ft-out ft.out capture.pcapng.gz
```

## Auxiliary Outputs

```bash
# All outputs at once — prefix shorthand (recommended)
wpawolf --prefix=results --smart captures/
# Creates results.22000, results.37100, results.essid, results.wordlist,
# results.identity, results.username, results.device, results.log, ...

# Explicit per-sink (overrides prefix-derived paths)
wpawolf --prefix=results --smart -W custom-wordlist.txt captures/
```

| Flag | Content |
|------|---------|
| `-E` | Unique ESSIDs from AP beacons |
| `-R` | ESSIDs from Probe Requests |
| `-W` | Combined wordlist (ESSIDs + probes + WPS + EAP + vendor) |
| `-I` | EAP identity strings |
| `-U` | EAP inner usernames |
| `-D` | WPS device info (tab-separated) |

## Verify Extraction

```bash
wc -l hashes.22000                # total hash count
grep -c "^WPA\*01" hashes.22000   # PMKID hashes
grep -c "^WPA\*02" hashes.22000   # EAPOL handshake hashes
```

## Reduction vs Filter Flags

| Flag | Safe? | Effect |
|------|-------|--------|
| `--smart` | Yes | One line per MIC, no MIC loss |
| `--dedup-hash-combos` | Yes | 6 N#E# combos to 3 unique |
| `--nc-dedup` | Yes | Fold near-identical-nonce siblings |
| `--strict` | **No** | Drops crackable MICs |
| `--eapoltimeout N` | **No** | Discards pairs > N seconds apart |

## Hash Types

| Line prefix | hashcat mode | Content |
|-------------|--------------|---------|
| `WPA*01*` | 22000 | PMKID |
| `WPA*02*` | 22000 | EAPOL handshake |
| `WPA*03*` | 37100 | FT PMKID |
| `WPA*04*` | 37100 | FT EAPOL |

[Full WPAWolf reference](../tools/wpawolf.md)
