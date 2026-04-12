# The Gap Table: Spec vs hcxtools vs hashcat

### PMKID Attacks

| # | AKM | Common Name | PMKID Algorithm (per spec) | hcxtools Extracts? | hcxtools Output | Hashcat Cracks? | Hashcat Mode | Notes |
|---|-----|-------------|---------------------------|-------------------|-----------------|----------------|-------------|-------|
| 1 | 2 | WPA/WPA2-PSK | HMAC-**SHA1**-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes | `WPA*01*` | **Yes** | 22000 | Fully working |
| 2 | 4 | WPA2-FT-PSK | SHA-**256** chain (HMAC-SHA256 KDF + 2x SHA-256) | Yes | `WPA*03*` | **No** (PR #4645 pending) | 37100 | Module exists but not merged |
| 3 | 6 | WPA2-PSK-SHA256 | HMAC-**SHA256**-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes (flag `PMKID_APPSK256`) | `WPA*01*` | **BROKEN** | 22000 | aux4 uses SHA1, spec requires SHA256. Silent failure. |

### EAPOL (4-Way Handshake) Attacks

| # | AKM | Cipher | keyver | PTK Derivation (per spec) | MIC Algorithm (per spec) | hcxtools Extracts? | hcxtools Output | Hashcat Cracks? | Hashcat Mode | Notes |
|---|-----|--------|--------|--------------------------|-------------------------|-------------------|-----------------|----------------|-------------|-------|
| 4 | 2 | TKIP | 1 | PRF-512 (HMAC-SHA1) | HMAC-MD5 | Yes | `WPA*02*` | **Yes** (aux1) | 22000 | Fully working |
| 5 | 2 | CCMP | 2 | PRF-384 (HMAC-SHA1) | HMAC-SHA1-128 | Yes | `WPA*02*` | **Yes** (aux2) | 22000 | Fully working |
| 6 | 6 | CCMP | 3 | KDF-384 (HMAC-SHA256) | AES-128-CMAC | Yes | `WPA*02*` | **Yes** (aux3) | 22000 | Fully working |
| 7 | 4 | CCMP | 3 | 3x HMAC-SHA256 KDF chain (R0->R1->PTK) | AES-128-CMAC | Yes | `WPA*04*` | **No** (PR #4645 pending) | 37100 | Module exists but not merged |
| 8 | 4 | CCMP | 3 | (same as above) | AES-128-CMAC | Yes, but skipped if >255 bytes | `WPA*04*` | **No** | 37100 | FT M2 frames often >255 bytes |

### Combined Summary View

```
                         ┌──────────────┐
                         │  SPEC SAYS   │
                         │   IT EXISTS  │
                         └──────┬───────┘
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  AKM 2 PSK   │    │  AKM 4 FT    │     │  AKM 6 SHA256│
    │              │    │              │     │              │
    │ PMKID: SHA1  │    │ PMKID: SHA256│     │ PMKID: SHA256│
    │ EAPOL: 3     │    │   chain      │     │ EAPOL: kv3   │
    │  keyvers     │    │ EAPOL: kv3   │     │              │
    └──────┬───────┘    └──────┬───────┘     └───────┬──────┘
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  HCXTOOLS    │    │  HCXTOOLS    │     │  HCXTOOLS    │
    │              │    │              │     │              │
    │ PMKID: WPA*01│    │ PMKID: WPA*03│     │ PMKID: WPA*01│
    │ EAPOL: WPA*02│    │ EAPOL: WPA*04│     │ EAPOL: WPA*02│
    │ ALL WORKING  │    │ EAPOL >255B  │     │ ALL WORKING  │
    │              │    │ skipped      │     │              │
    └──────┬───────┘    └──────┬───────┘     └───────┬──────┘
           │                    │                     │
    ┌──────▼───────┐    ┌──────▼───────┐     ┌───────▼──────┐
    │  HASHCAT     │    │  HASHCAT     │     │  HASHCAT     │
    │  MODE 22000  │    │  MODE 37100  │     │  MODE 22000  │
    │              │    │              │     │              │
    │ PMKID: YES   │    │ PMKID: NO    │     │ PMKID: BROKEN│
    │  (SHA1 aux4) │    │  (not merged)│     │  (uses SHA1, │
    │ kv1:YES aux1 │    │ EAPOL: NO    │     │   needs      │
    │ kv2:YES aux2 │    │  (not merged)│     │   SHA256)    │
    │ kv3:YES aux3 │    │              │     │ EAPOL: YES   │
    │              │    │              │     │  (kv3, aux3) │
    └──────────────┘    └──────────────┘     └──────────────┘
```

### The Gap Table

| # | What | Spec Says | hcxtools | hashcat | Status |
|---|------|-----------|----------|---------|--------|
| 1 | AKM 2 PMKID | HMAC-SHA1 | Extracts as `WPA*01` | aux4: HMAC-SHA1 | **Working** |
| 2 | AKM 2 EAPOL kv1 | PRF-SHA1 + HMAC-MD5 MIC | Extracts as `WPA*02` | aux1 | **Working** |
| 3 | AKM 2 EAPOL kv2 | PRF-SHA1 + HMAC-SHA1 MIC | Extracts as `WPA*02` | aux2 | **Working** |
| 4 | AKM 6 EAPOL kv3 | KDF-SHA256 + AES-CMAC MIC | Extracts as `WPA*02` | aux3 | **Working** |
| 5 | AKM 6 PMKID | **HMAC-SHA256** | Extracts as `WPA*01` (flag `APPSK256`) | aux4: uses **SHA1** | **BROKEN** -- wrong hash, silent failure |
| 6 | AKM 4 PMKID | SHA-256 chain | Extracts as `WPA*03` | No module in mainline | **MISSING** -- PR #4645 open |
| 7 | AKM 4 EAPOL kv3 | 3x HMAC-SHA256 + AES-CMAC | Extracts as `WPA*04` (if <=255B) | No module in mainline | **MISSING** -- PR #4645 open |
| 8 | AKM 4 EAPOL oversized | Same as #7 | Skips with warning if >255B | N/A | **MISSING** in both tools |
