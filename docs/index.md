<p align="center">
  <a href="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml"><img src="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml/badge.svg" alt="Documentation Build"></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="Apache 2.0 License"></a>
</p>

# WiFi Security Analysis

Complete technical reference for IEEE 802.11 wireless security. Covers protocol internals for all 25 AKM suites, offline password attacks against PSK networks, enterprise EAP credential extraction, and legacy WEP vulnerabilities. Built from primary sources: IEEE 802.11-2024, RFC 3748, hashcat, hcxtools, and aircrack-ng.

## Sections

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

    Legacy WEP vulnerabilities. FMS, KoreK, PTW attacks and practical aircrack-ng workflows.

- :material-wrench: __[Tools](tools/index.md)__

    ---

    hcxpcapngtool, hashcat, aircrack-ng suite. Hash extraction, cracking, and capture tool reference.

</div>

## Quick Reference

| AKM | Name | Category | Offline Crackable? | hashcat Mode |
|-----|------|----------|--------------------|--------------|
| 2 | PSK | Password | Yes — PBKDF2 | 22000 |
| 4 | FT-PSK | Password | Yes — FT KDF chain | 37100 |
| 6 | PSK-SHA256 | Password | Yes — KDF-SHA-256 | 22000 |
| 8 | SAE | Password (ZKP) | No — Dragonfly PAKE | N/A |
| 1 | 802.1X | Enterprise | EAP inner method dependent | 5500, 4800 |
| 18 | OWE | Open | No — no password | N/A |
| N/A | WEP | Legacy | Yes — RC4 key recovery | N/A (aircrack-ng) |

## Disclaimer

This material is intended for authorized security testing, research, and education only. You must have explicit written permission from the network owner before capturing or cracking WPA handshakes. Unauthorized access to computer networks is illegal.
