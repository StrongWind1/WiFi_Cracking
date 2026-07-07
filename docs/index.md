# WiFi Cracking

Complete technical reference for IEEE 802.11 wireless security. Two paths to choose from: a step-by-step **Guide** for cracking WiFi passwords, or a deep **Reference** covering protocol internals for all 25 AKM suites.

## Choose your path

<div class="grid cards" markdown>

- :material-school: __[Guide](guide/index.md)__

    ---

    Zero-to-hero walkthrough. Capture traffic, extract hashes, crack passwords. Step by step with just the commands you need.

- :material-book-open-variant: __[Reference](protocol/index.md)__

    ---

    Deep technical reference. All 25 AKM suites, protocol internals, attack algorithms, EAP credential extraction, WEP, and tool documentation.

</div>

## Reference sections

<div class="grid cards" markdown>

- :material-shield-lock: __[Protocol](protocol/index.md)__

    ---

    All 25 AKM suites across 5 categories. Key hierarchies, handshake flows, and cryptographic details per IEEE 802.11-2024.

- :material-key-variant: __[PSK Attacks](psk-attacks/index.md)__

    ---

    PMKID and EAPOL MIC attacks against password-based AKMs. Message pair analysis, PBKDF2/PRF/KDF algorithms.

- :material-server-network: __[EAP Attacks](eap-attacks/index.md)__

    ---

    Enterprise credential extraction. PEAP/MSCHAPv2, EAP-MD5, and LEAP hash capture from 802.1X exchanges.

- :material-wifi-off: __[WEP](wep/index.md)__

    ---

    Legacy WEP vulnerabilities. FMS, KoreK, PTW attacks and practical [aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) workflows.

- :material-wrench: __[Tools](tools/index.md)__

    ---

    [WPAWolf](https://github.com/StrongWind1/WPAWolf), [WEPWolf](https://github.com/StrongWind1/WEPWolf), [hcxdumptool](https://github.com/ZerBea/hcxdumptool), [hashcat](https://github.com/hashcat/hashcat), [aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) suite. Hash extraction, cracking, and capture tool reference.

</div>

## Quick Reference

### WEP (pre-AKM)

| Protocol | Attack | Tool | Speed |
|---|---|---|---|
| WEP-40 / WEP-104 | RC4 key recovery (PTW) | [WEPWolf](tools/wpawolf.md) / aircrack-ng | ~40K IVs → key in seconds |

### Password: PBKDF2 (offline crackable)

All six families derive the PMK from a passphrase via the same PBKDF2-HMAC-SHA1 (4096 iterations). The "SHA-256" and "SHA-384" in the names refer to the post-PMK key hierarchy, not the password hash.

| AKM | Name | Extract with | Crack with | hashcat mode | Status |
|---|---|---|---|---|---|
| WPA1 | WPA-PSK (TKIP) | [WPAWolf](tools/wpawolf.md) | hashcat | 22000 (kv1) | Working |
| 2 | WPA2-PSK (CCMP) | [WPAWolf](tools/wpawolf.md) | hashcat | 22000 (kv2) | Working |
| 6 | PSK-SHA256 | [WPAWolf](tools/wpawolf.md) | hashcat | 22000 (kv3) | EAPOL working; PMKID broken (SHA1 bug) |
| 4 | FT-PSK | [WPAWolf](tools/wpawolf.md) | hashcat | 37100 (PR pending) | Extraction works; hashcat PR #4645 not merged |
| 19 | FT-PSK-SHA384 | [WPAWolf](tools/wpawolf.md) | N/A | none | No hashcat module (24 B MIC) |
| 20 | PSK-SHA384 | [WPAWolf](tools/wpawolf.md) | N/A | none | No hashcat module (24 B MIC) |

### Password: SAE (not offline crackable)

| AKM | Name | Why it resists offline attack |
|---|---|---|
| 8 | SAE (WPA3-Personal) | Dragonfly PAKE. No crackable material on the wire |
| 9 | FT-SAE | SAE + Fast Transition |
| 24 | SAE (H2E) | Hash-to-Element, constant-time |
| 25 | FT-SAE (H2E) | H2E + Fast Transition |

### EAP: Enterprise

| AKM | Name | Crackable inner methods |
|---|---|---|
| 1 | 802.1X | PEAP/MSCHAPv2 (mode 5500), EAP-MD5 (mode 4800), LEAP (mode 5500) |
| 3 | FT-802.1X | Same inner methods via rogue AP |
| 5 | 802.1X-SHA256 | Same inner methods via rogue AP |
| 11 | Suite B-128 (deprecated) | N/A |
| 12 | Suite B-192 | N/A |
| 13 | FT-802.1X-SHA384 | N/A |
| 14-17 | FILS (SHA256/384, FT variants) | EAP-based, not directly crackable |
| 22 | FT-802.1X-SHA384 | N/A |
| 23 | 802.1X-SHA384 | N/A |

### Other

| AKM | Name | Notes |
|---|---|---|
| 7 | TDLS | Peer-to-peer direct link. Niche |
| 10 | APPeerKey (deprecated) | Removed from active standard |
| 18 | OWE | Opportunistic encryption, no password |
| 21 | PASN | Pre-association security negotiation |

## Disclaimer

This material is intended for authorized security testing, research, and education only. You must have explicit written permission from the network owner before capturing or cracking WPA handshakes. Unauthorized access to computer networks is illegal.

<p align="center">
  <a href="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml"><img src="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml/badge.svg" alt="Documentation Build"></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="Apache 2.0 License"></a>
</p>
