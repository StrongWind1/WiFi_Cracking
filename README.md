<h1 align="center">WiFi Cracking</h1>

<p align="center"><strong>Complete technical reference for IEEE 802.11 security analysis.</strong></p>

<p align="center">
  <a href="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml"><img src="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml/badge.svg" alt="Docs build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License: Apache 2.0"></a>
  <a href="https://strongwind1.github.io/WiFi_Cracking/"><img src="https://img.shields.io/badge/docs-mkdocs-blue.svg" alt="Docs"></a>
</p>

<p align="center">
  <a href="https://strongwind1.github.io/WiFi_Cracking/">Documentation</a> &bull;
  <a href="https://strongwind1.github.io/WiFi_Cracking/protocol/">Protocol</a> &bull;
  <a href="https://strongwind1.github.io/WiFi_Cracking/psk-attacks/">PSK attacks</a> &bull;
  <a href="https://strongwind1.github.io/WiFi_Cracking/eap-attacks/">EAP attacks</a> &bull;
  <a href="https://strongwind1.github.io/WiFi_Cracking/reference/">Reference</a> &bull;
  <a href="https://strongwind1.github.io/WiFi_Cracking/tools/">Tools</a>
</p>

---

Covers all 25 AKM suites, PSK/EAP/WEP attack vectors, and the full pipeline from protocol internals to hash extraction and cracking. Built from primary sources: IEEE 802.11-2024, RFCs, hashcat/hcxtools source code, and hands-on testing against real captures.

## What's inside

- **Protocol** - All 25 AKM suites organized by family (PSK, FT-PSK, SAE, Enterprise, FILS, OWE), key hierarchy, 4-way handshake, security matrix
- **PSK Attacks** - PMKID and EAPOL attack vectors, per-AKM formulas, the 12-to-6-to-3 hash collapse, PBKDF2/PRF/KDF algorithms
- **EAP Attacks** - PEAP/MSCHAPv2, EAP-MD5, Cisco LEAP credential capture and cracking
- **WEP** - Design flaws, FMS/KoreK/PTW attacks, aircrack-ng practical workflow
- **Reference** - Hash line formats, EAPOL frame structure, capture requirements, tool gap analysis, glossary
- **Tools** - hcxpcapngtool, hashcat modes, aircrack-ng suite, hostapd-mana

## Credits

Built from [IEEE 802.11-2024](https://standards.ieee.org/standard/802_11-2024.html), [RFC 3748](https://www.rfc-editor.org/rfc/rfc3748), [hashcat](https://github.com/hashcat/hashcat), [hcxtools](https://github.com/ZerBea/hcxtools), and [aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) source code.

## Related tools

Other projects in this collection:

- [WPAWolf](https://github.com/StrongWind1/WPAWolf) - WPA/WPA2/WPA3-FT-PSK handshake extraction from captures
- [NFSWolf](https://github.com/StrongWind1/NFSWolf) - native NFS security toolkit

## Disclaimer

This material is intended for authorized security testing, research, and education only. You must have explicit written permission from the network owner before capturing or cracking wireless credentials. Unauthorized access to computer networks is illegal. The authors are not responsible for any misuse.

## License

[Apache License 2.0](LICENSE)
