# PMKID Attack

<!-- TODO: rewrite from v1 into a concise walkthrough -->
<!-- Source material: docs/old/attacks/pmkid.md -->
<!-- Link to Reference: psk-attacks/pmkid.md -->

The PMKID attack recovers a WiFi password without needing a connected client.
The AP includes a PMKID value in its first handshake message — if present,
this single value is enough to crack the password offline.

## How it works

The AP computes:

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || AP_MAC || Client_MAC)
```

Since the PMK is derived from the password, an attacker can guess passwords,
compute the expected PMKID, and check for a match.

## Step 1 — Extract the PMKID

```bash
hcxpcapngtool -o hashes.22000 capture-01.pcapng
```

Look for `WPA*01*` lines in the output — these are PMKID hashes.

## Step 2 — Crack with hashcat

```bash
hashcat -m 22000 hashes.22000 wordlist.txt
```

## When PMKID works

- The AP must have **PMKSA caching** enabled (most do)
- Not all APs include PMKID in their responses
- PMKID formula varies by AKM — the simple HMAC-SHA1 formula above applies to AKM 2 only. AKM 6 uses HMAC-SHA256, AKM 4 uses an FT chain. See the [PMKID reference](../psk-attacks/pmkid.md)

!!! tip "Deep dive"
    See the [PMKID reference](../psk-attacks/pmkid.md) for per-AKM PMKID
    formulas, RSN IE structure, and edge cases with AKM 4 and 6.
