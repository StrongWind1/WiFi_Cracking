# Extracting Hashes

<!-- TODO: rewrite from v1 into a concise walkthrough -->
<!-- Source material: docs/old/tools/hcxpcapngtool.md, docs/old/reference/hash-line-formats.md -->
<!-- Link to Reference: tools/hcxpcapngtool.md, reference/hash-extraction.md -->

Before you can crack a WiFi password, you need to extract the relevant
cryptographic data from your capture file into a format hashcat understands.
The tool for this is **hcxpcapngtool** (part of hcxtools).

## Basic usage

```bash
hcxpcapngtool -o hashes.22000 capture-01.pcapng
```

This extracts both PMKID and EAPOL hashes into a single file.

## Output format

Each line is a hash in the format:

```
WPA*TYPE*PMKID_OR_MIC*MAC_AP*MAC_STA*ESSID*NONCE*EAPOL*MP
```

| Type | Meaning |
|------|---------|
| `WPA*01*` | PMKID hash |
| `WPA*02*` | EAPOL handshake hash |

## Common options

| Flag | Purpose |
|------|---------|
| `-o file` | Output hashcat 22000 format |
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
