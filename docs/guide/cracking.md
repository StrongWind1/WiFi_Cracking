# Cracking with hashcat

<!-- TODO: rewrite from v1 into a concise walkthrough -->
<!-- Source material: docs/old/tools/cheat-sheet.md, docs/old/reference/hashcat-modes.md -->
<!-- Link to Reference: tools/hashcat.md -->

hashcat is the primary tool for offline password cracking. It takes the hash
extracted by hcxpcapngtool and tests password candidates against it.

## Basic attack

```bash
hashcat -m 22000 hashes.22000 wordlist.txt
```

- `-m 22000` — WPA/WPA2 mode (handles both PMKID and EAPOL)
- `hashes.22000` — your extracted hashes
- `wordlist.txt` — password candidates (one per line)

## Attack modes

| Mode | Flag | Description | Example |
|------|------|-------------|---------|
| Wordlist | `-a 0` | Try each word in a file | `hashcat -m 22000 -a 0 hash.22000 rockyou.txt` |
| Wordlist + rules | `-a 0 -r` | Apply mutations to each word | `hashcat -m 22000 -a 0 -r best64.rule hash.22000 rockyou.txt` |
| Brute-force | `-a 3` | Try all combinations of a pattern | `hashcat -m 22000 -a 3 hash.22000 ?d?d?d?d?d?d?d?d` |
| Combinator | `-a 1` | Combine words from two lists | `hashcat -m 22000 -a 1 hash.22000 list1.txt list2.txt` |

## Common mask characters

| Placeholder | Matches |
|-------------|---------|
| `?d` | Digits (0-9) |
| `?l` | Lowercase (a-z) |
| `?u` | Uppercase (A-Z) |
| `?s` | Special characters |
| `?a` | All printable ASCII |

## Checking results

```bash
hashcat -m 22000 hashes.22000 --show    # display cracked passwords
```

## Performance notes

WPA/WPA2 cracking is slow by design — each password guess requires 4096
rounds of HMAC-SHA1 (PBKDF2). A high-end GPU might test ~500K-1M
passwords/second. Good wordlists and smart rules matter more than raw speed.

!!! tip "Deep dive"
    See the [hashcat reference](../tools/hashcat.md) for all WiFi-related
    modes, salt grouping, deduplication, and advanced usage patterns.
