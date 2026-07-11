# WEPWolf Quick Reference

## Crack

```bash
# Basic — auto-detects key length, runs all attacks
wepwolf capture.cap

# Directory scan — parallel ingestion, cross-file IV merging
wepwolf captures/

# With wordlist (dictionary + keygen attacks)
wepwolf -w wordlist.txt capture.cap

# Target a single BSSID
wepwolf -b 00:11:22:33:44:55 capture.cap

# Force key length (40, 104, or 232 bits)
wepwolf -n 104 capture.cap
wepwolf -n 40 capture.cap
wepwolf -n 232 capture.cap
```

## Output Formats

```bash
# JSON (NDJSON, one object per line)
wepwolf --json capture.cap

# Potfile (hashcat-style bssid:key_hex)
wepwolf --potfile keys.pot capture.cap

# Tab-separated (for awk/cut pipelines)
wepwolf --plain capture.cap

# Keys only, no summary
wepwolf -q capture.cap
```

## Frame Carving

```bash
# Extract all WEP frames into a standalone pcap
wepwolf --carve wep-frames.pcap capture.cap
```

Normalizes mixed radiotap/Prism/AVS inputs to raw 802.11.

## Search Tuning

| Flag | Effect |
|------|--------|
| `-f N` | Fudge factor: keep octets voting >= top/N |
| `-x N` | Exhaustively sweep last N key octets (default 2, max 4) |
| `-c` | Restrict candidates to printable ASCII |
| `--brute` | Brute-force WEP-40 (slow: 2^40) |

## IV Requirements

| Key length | Minimum unique IVs (PTW) |
|------------|--------------------------|
| WEP-40 | ~20,000 |
| WEP-104 | ~40,000 |

[WEP cracking guide](wep.md)
