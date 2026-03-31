<p align="center">
  <strong>WiFi Cracking</strong>
</p>

<p align="center">
  <a href="https://strongwind1.github.io/WiFi_Cracking/"><img src="https://img.shields.io/badge/docs-live-brightgreen.svg" alt="Documentation"></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License"></a>
</p>

<p align="center">
  <a href="https://strongwind1.github.io/WiFi_Cracking/">Documentation</a> |
  <a href="https://strongwind1.github.io/WiFi_Cracking/protocol/key-hierarchy/">Protocol</a> |
  <a href="https://strongwind1.github.io/WiFi_Cracking/attacks/eapol/">Attacks</a> |
  <a href="https://strongwind1.github.io/WiFi_Cracking/reference/hash-line-formats/">Reference</a> |
  <a href="https://strongwind1.github.io/WiFi_Cracking/tools/cheat-sheet/">Cheat Sheet</a>
</p>

---

Complete technical reference for WPA/WPA2 PSK security analysis.

Covers the full pipeline from IEEE 802.11i protocol internals to practical hash extraction and cracking. Built from primary sources: IEEE specs, hashcat/hcxtools source code, and hands-on testing against real captures.

## What's Inside

- **Protocol** -- WPA key hierarchy, 4-way handshake, all PSK variants (AKM 2/4/6)
- **Attacks** -- PMKID and EAPOL attack vectors, the 12-to-6-to-3 hash collapse, N#E# message pair naming
- **Algorithms** -- Step-by-step math for PBKDF2, PRF, KDF, FT-PSK key derivation chain
- **Reference** -- Hash line formats (mode 22000/37100), EAPOL frame structure, capture requirements, tool gap analysis
- **Tools** -- hcxpcapngtool options and behavior, hashcat modes and salt grouping, tshark commands, cracking workflow

## Single-file version

The full guide is also available as a single markdown file: [WPA_PSK_CRACKING_GUIDE.md](WPA_PSK_CRACKING_GUIDE.md)

## Disclaimer

This material is intended for authorized security testing, research, and education only. You must have explicit written permission from the network owner before capturing or cracking WPA handshakes. Unauthorized access to computer networks is illegal. The authors are not responsible for any misuse.

## Credits

Built from [IEEE 802.11i-2004](https://standards.ieee.org/standard/802_11i-2004.html), [IEEE 802.11r-2008](https://standards.ieee.org/standard/802_11r-2008.html), [hashcat](https://github.com/hashcat/hashcat), and [hcxtools](https://github.com/ZerBea/hcxtools) source code.

## License

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
