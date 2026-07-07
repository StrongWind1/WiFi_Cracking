# Extracting Hashes

Before you can crack a WiFi password, you need to extract the relevant cryptographic data from your pcapng (packet capture file format) file into a format hashcat understands.
The primary tool for this is **hcxpcapngtool** (part of hcxtools). An alternative is **[wpawolf](https://github.com/StrongWind1/WPAWolf)**, which uses a collect-then-pair architecture that avoids hcxpcapngtool's 64-entry buffer limit and EAPOL size gate, and supports cross-file pairing.

## Basic usage

```bash
hcxpcapngtool -o hashes.22000 -f hashes.37100 capture-01.pcapng
```

This extracts PMKID (a fingerprint the AP computes from the PMK and both MAC addresses) and EAPOL (the protocol that carries the 4-way handshake frames) hashes for standard PSK (`-o`, mode 22000) and FT-PSK (`-f`, mode 37100) into separate files.

## Output format

Each line is a hash in the format:

```
WPA*TYPE*PMKID_OR_MIC*MAC_AP*MAC_STA*ESSID*NONCE*EAPOL*MP
```

| Type | Meaning |
|------|---------|
| `WPA*01*` | PMKID hash (mode 22000) |
| `WPA*02*` | EAPOL handshake hash (mode 22000) |
| `WPA*03*` | FT-PSK PMKID hash (mode 37100) |
| `WPA*04*` | FT-PSK EAPOL hash (mode 37100) |

## Common options

| Flag | Purpose |
|------|---------|
| `-o file` | Output hashcat 22000 format (PSK) |
| `-f file` | Output hashcat 37100 format (FT-PSK) |
| `--all` | Include all message pairs (not just best) |
| `-E essids` | Write ESSIDs to file (for wordlist building) |

## Verifying your hashes

Check that hashes were extracted:

```bash
wc -l hashes.22000           # count of extracted hashes
grep "^WPA\*01" hashes.22000  # PMKID hashes only
grep "^WPA\*02" hashes.22000  # EAPOL hashes only
```

!!! tip "Deep dive"
    See the [hcxpcapngtool reference](../tools/hcxpcapngtool.md) for the full
    options matrix and the [Hash extraction reference](../reference/hash-extraction.md)
    for hash line format details.

**Next:** [Cracking with hashcat](cracking.md)
