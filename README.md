<h1 align="center">Wi-Fi Cracking</h1>

<p align="center"><strong>How 802.11 authentication works, and how PSK, EAP, and WEP credentials get cracked offline.</strong></p>

<p align="center">
  <a href="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml"><img src="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml/badge.svg" alt="Docs build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License: Apache 2.0"></a>
  <a href="https://strongwind.dev/WiFi_Cracking/"><img src="https://img.shields.io/badge/docs-mkdocs-blue.svg" alt="Docs"></a>
</p>

<p align="center">
  <a href="https://strongwind.dev/WiFi_Cracking/protocol/">Protocol</a> &bull;
  <a href="https://strongwind.dev/WiFi_Cracking/psk-attacks/">PSK attacks</a> &bull;
  <a href="https://strongwind.dev/WiFi_Cracking/eap-attacks/">EAP attacks</a> &bull;
  <a href="https://strongwind.dev/WiFi_Cracking/tools/">Tools</a> &bull;
  <a href="https://strongwind.dev/WiFi_Cracking/">Documentation</a>
</p>

---

A reference for IEEE 802.11 security, with step-by-step guides that take a capture to a cracked WEP, WPA/WPA2, or WPA-Enterprise credential. It follows the PSK, EAP, and WEP attack vectors from protocol internals to hash extraction and cracking. It is built from IEEE 802.11-2024, the RFCs, and the hashcat and hcxtools source, and tested against real captures.

## What's inside

- **[Guide](https://strongwind.dev/WiFi_Cracking/guide/)**: Capture, extract, and crack, step by step, for WEP, WPA/WPA2, and WPA-Enterprise (EAP), plus Linux adapter setup and cheat sheets for WPAWolf, WEPWolf, hcxdumptool, and hashcat
- **[Protocol](https://strongwind.dev/WiFi_Cracking/protocol/)**: All 25 AKM suites by family (PSK, FT-PSK, SAE, Enterprise, FILS, and OWE/TDLS/PASN), key hierarchy, 4-way handshake, security matrix
- **[PSK attacks](https://strongwind.dev/WiFi_Cracking/psk-attacks/)**: PMKID and EAPOL attack vectors, per-AKM formulas, the 12-to-6-to-3 hash collapse, PBKDF2/PRF/KDF algorithms
- **[EAP attacks](https://strongwind.dev/WiFi_Cracking/eap-attacks/)**: PEAP/MSCHAPv2, EAP-MD5, and Cisco LEAP credential capture and cracking
- **[WEP](https://strongwind.dev/WiFi_Cracking/wep/)**: Design flaws, FMS/KoreK/PTW attacks, and the aircrack-ng workflow
- **[Reference](https://strongwind.dev/WiFi_Cracking/reference/)**: Hash line formats, EAPOL frame structure, capture requirements, tool gap analysis, glossary
- **[Tools](https://strongwind.dev/WiFi_Cracking/tools/)**: hcxpcapngtool, WPAWolf, hashcat modes, aircrack-ng suite, hostapd-mana

## Development

```sh
git clone https://github.com/StrongWind1/WiFi_Cracking.git && cd WiFi_Cracking
uv sync --group docs   # install dependencies
make serve             # live preview at http://127.0.0.1:8000
make docs              # strict build, as CI runs it
```

Page sources live in `docs/`. Content and style rules are on the [Contributing](https://strongwind.dev/WiFi_Cracking/meta/contributing/) page.

## Credits

Built from [IEEE 802.11-2024](https://standards.ieee.org/standard/802_11-2024.html), [RFC 3748](https://www.rfc-editor.org/rfc/rfc3748), and the [hashcat](https://github.com/hashcat/hashcat), [hcxtools](https://github.com/ZerBea/hcxtools), and [aircrack-ng](https://github.com/aircrack-ng/aircrack-ng) source code.

## Related tools

- [**WPAWolf**](https://github.com/StrongWind1/WPAWolf): WPA / WPA2 / WPA3 PSK handshake and PMKID extractor for hashcat mode 22000
- [**WEPWolf**](https://github.com/StrongWind1/WEPWolf): Offline, passive WEP key recovery from 802.11 captures

All tools: [strongwind.dev](https://strongwind.dev)

## Disclaimer

This material is for authorized security testing, research, and education. Use it only against systems and networks you own or have written permission to test. You are responsible for how you use it.

## License

[Apache License 2.0](LICENSE)
