# Gap Table

Known gaps between the IEEE 802.11 specification, hcxtools implementation,
and hashcat cracking support. A "gap" is any AKM, cipher suite, or feature
that is defined in the spec but unsupported by the toolchain, or where tool
behavior diverges from the spec.

## Master Summary

| Category | Total tracked | Fully working | Broken/wrong | Missing/pending |
|----------|--------------|---------------|-------------|-----------------|
| PSK PMKID | 3 | 1 | 1 (AKM 6 SHA1 bug) | 1 (AKM 4 no mainline module) |
| PSK EAPOL | 5 | 3 | 0 | 2 (AKM 4 no module, FT oversized) |
| EAP | 3 | 0 | 0 | 3 (extraction works; cracking modes exist but tool integration varies) |
| WEP | 1 | 1 | 0 | 0 |

---

## PSK Gaps

### PMKID Attacks

| # | AKM | Name | PMKID algorithm (spec) | hcxtools extracts? | hcxtools output | hashcat cracks? | hashcat mode | Notes |
|---|-----|------|------------------------|-------------------|-----------------|----------------|-------------|-------|
| 1 | 2 | WPA/WPA2-PSK | HMAC-SHA1-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes | `WPA*01*` | **Yes** | 22000 | Fully working |
| 2 | 4 | WPA2-FT-PSK | SHA-256 chain (HMAC-SHA256 KDF + 2× SHA-256) | Yes | `WPA*03*` | **No** (PR #4645 pending) | 37100 | Module exists but not in mainline |
| 3 | 6 | WPA2-PSK-SHA256 | HMAC-SHA256-128(PMK, "PMK Name"\|\|AA\|\|SPA) | Yes (flag `PMKID_APPSK256`) | `WPA*01*` | **BROKEN** | 22000 | aux4 uses SHA1; spec requires SHA256. Silent failure. |

### EAPOL Attacks

| # | AKM | Cipher | keyver | PTK derivation (spec) | MIC algorithm (spec) | hcxtools extracts? | hcxtools output | hashcat cracks? | hashcat mode | Notes |
|---|-----|--------|--------|-----------------------|---------------------|--------------------|-----------------|----------------|-------------|-------|
| 4 | 2 | TKIP | 1 | PRF-512 (HMAC-SHA1) | HMAC-MD5 | Yes | `WPA*02*` | **Yes** (aux1) | 22000 | Fully working |
| 5 | 2 | CCMP | 2 | PRF-384 (HMAC-SHA1) | HMAC-SHA1-128 | Yes | `WPA*02*` | **Yes** (aux2) | 22000 | Fully working |
| 6 | 6 | CCMP | 3 | KDF-384 (HMAC-SHA256) | AES-128-CMAC | Yes | `WPA*02*` | **Yes** (aux3) | 22000 | Fully working |
| 7 | 4 | CCMP | 3 | 3× HMAC-SHA256 KDF chain | AES-128-CMAC | Yes | `WPA*04*` | **No** (PR #4645 pending) | 37100 | Module not in mainline |
| 8 | 4 | CCMP | 3 | (same as #7) | AES-128-CMAC | Yes, but skipped if >255 bytes | `WPA*04*` | **No** | 37100 | FT M2 often >255 bytes — skipped by hcxtools |

### Gap Summary (PSK)

```mermaid
flowchart TD
    spec["<b>SPEC DEFINES IT</b><br>IEEE 802.11-2024"]

    spec --> akm2_spec
    spec --> akm4_spec
    spec --> akm6_spec

    subgraph akm2["AKM 2 — WPA/WPA2-PSK"]
        akm2_spec["PMKID: HMAC-SHA1<br>EAPOL: kv1, kv2, kv3"]
        akm2_hcx["hcxtools<br>PMKID → WPA*01<br>EAPOL → WPA*02<br>✅ All working"]
        akm2_hc["hashcat mode 22000<br>PMKID: ✅ aux4 SHA1<br>kv1: ✅ aux1<br>kv2: ✅ aux2<br>kv3: ✅ aux3"]
        akm2_spec --> akm2_hcx --> akm2_hc
    end

    subgraph akm4["AKM 4 — WPA2-FT-PSK"]
        akm4_spec["PMKID: SHA-256 chain<br>EAPOL: kv3"]
        akm4_hcx["hcxtools<br>PMKID → WPA*03<br>EAPOL → WPA*04<br>⚠️ EAPOL >255B skipped"]
        akm4_hc["hashcat mode 37100<br>PMKID: ❌ not merged<br>EAPOL: ❌ not merged<br>PR #4645 pending"]
        akm4_spec --> akm4_hcx --> akm4_hc
    end

    subgraph akm6["AKM 6 — WPA2-PSK-SHA256"]
        akm6_spec["PMKID: HMAC-SHA256<br>EAPOL: kv3"]
        akm6_hcx["hcxtools<br>PMKID → WPA*01<br>EAPOL → WPA*02<br>✅ All working"]
        akm6_hc["hashcat mode 22000<br>PMKID: 🔴 BROKEN<br>aux4 uses SHA1 ≠ SHA256<br>silent wrong answer<br>EAPOL: ✅ kv3, aux3"]
        akm6_spec --> akm6_hcx --> akm6_hc
    end

    classDef working fill:#1b4332,stroke:#69f0ae,color:#e0e0e0
    classDef broken fill:#4a1515,stroke:#ff5252,color:#e0e0e0
    classDef missing fill:#3e2723,stroke:#ffab40,color:#e0e0e0
    classDef specbox fill:#1a237e,stroke:#90caf9,color:#e0e0e0
    classDef neutral fill:#1c2d28,stroke:#4dd0e1,color:#c9d1d9

    class spec specbox
    class akm2_spec,akm4_spec,akm6_spec neutral
    class akm2_hcx,akm6_hcx working
    class akm2_hc working
    class akm4_hcx missing
    class akm4_hc missing
    class akm6_hc broken
```

### Detailed Gap Records (PSK)

| # | What | Spec says | hcxtools | hashcat | Status |
|---|------|-----------|----------|---------|--------|
| 1 | AKM 2 PMKID | HMAC-SHA1 | Extracts as `WPA*01` | aux4: HMAC-SHA1 | **Working** |
| 2 | AKM 2 EAPOL kv1 | PRF-SHA1 + HMAC-MD5 MIC | Extracts as `WPA*02` | aux1 | **Working** |
| 3 | AKM 2 EAPOL kv2 | PRF-SHA1 + HMAC-SHA1 MIC | Extracts as `WPA*02` | aux2 | **Working** |
| 4 | AKM 6 EAPOL kv3 | KDF-SHA256 + AES-CMAC MIC | Extracts as `WPA*02` | aux3 | **Working** |
| 5 | AKM 6 PMKID | **HMAC-SHA256** | Extracts as `WPA*01` (flag `APPSK256`) | aux4: uses **SHA1** | **BROKEN** — wrong hash, silent failure |
| 6 | AKM 4 PMKID | SHA-256 chain | Extracts as `WPA*03` | No module in mainline | **MISSING** — PR #4645 open |
| 7 | AKM 4 EAPOL kv3 | 3× HMAC-SHA256 + AES-CMAC | Extracts as `WPA*04` (if ≤255B) | No module in mainline | **MISSING** — PR #4645 open |
| 8 | AKM 4 EAPOL oversized | Same as #7 | Skips with warning if >255B | N/A | **MISSING** in both tools |

---

## EAP Gaps

| # | EAP method | hcxtools extracts? | hashcat mode | Notes |
|---|------------|-------------------|-------------|-------|
| 9 | MSCHAPv2 (PEAP/EAP-TTLS) | Yes (rogue AP mode) | 5500 | Requires hostapd-mana; passive capture insufficient |
| 10 | EAP-MD5 | Yes (passive) | 4800 | EAP-MD5 travels in cleartext |
| 11 | Cisco LEAP | Yes (passive) | 5500 | LEAP is unencrypted |
| — | EAP-TLS | No (uses certificates, no password) | N/A | No shared secret to crack |
| — | EAP-TTLS/PAP | No (plaintext password inside TLS) | N/A | No hash to crack, credential captures require rogue AP |

---

## WEP Gaps

WEP is considered fully supported by aircrack-ng. The FMS, KoreK, and PTW
attacks are all implemented. No significant gaps exist between the specification
and aircrack-ng's implementation.

| # | What | Status | Notes |
|---|------|--------|-------|
| 12 | WEP-40 PTW | Working | aircrack-ng default |
| 13 | WEP-104 PTW | Working | Same algorithm, longer key |
| 14 | ChopChop | Working | `aireplay-ng -4` |
| 15 | Fragmentation | Working | `aireplay-ng -5` |
| 16 | Caffe-Latte / Hirte | Working | Client-side attacks |
