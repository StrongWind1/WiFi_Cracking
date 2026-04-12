<p align="center">
  <a href="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml"><img src="https://github.com/StrongWind1/WiFi_Cracking/actions/workflows/docs.yml/badge.svg" alt="Docs"></a>
  <a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License"></a>
</p>

# WiFi Cracking

Complete technical reference for WPA/WPA2 PSK security analysis.

Covers the full pipeline from IEEE 802.11i protocol internals to practical hash extraction and cracking. Built from primary sources: IEEE specs, hashcat/hcxtools source code, and hands-on testing against real captures.

## Sections

- **[Protocol](protocol/key-hierarchy.md)** -- WPA key hierarchy, 4-way handshake, all PSK variants (AKM 2/4/6)
- **[Attacks](attacks/pmkid.md)** -- PMKID and EAPOL attack vectors, the 12-to-6-to-3 hash collapse, N#E# message pair naming
- **[Algorithms](algorithms/pbkdf2.md)** -- Step-by-step math for PBKDF2, PRF, KDF, FT-PSK key derivation chain
- **[Reference](reference/capture-requirements.md)** -- Hash line formats, EAPOL frame structure, capture requirements, tool gap analysis
- **[Tools](tools/hcxpcapngtool.md)** -- hcxpcapngtool options, hashcat modes, salt grouping, cracking workflow
- **[Cheat Sheet](tools/cheat-sheet.md)** -- Quick reference for capture, convert, and crack

## Single-file version

The full guide is also available as a single markdown file: [WPA_PSK_CRACKING_GUIDE.md](https://github.com/StrongWind1/WiFi_Cracking/blob/main/WPA_PSK_CRACKING_GUIDE.md)

## Disclaimer

This material is intended for authorized security testing, research, and education only. You must have explicit written permission from the network owner before capturing or cracking WPA handshakes. Unauthorized access to computer networks is illegal.

## Credits

Built from [IEEE 802.11i-2004](https://standards.ieee.org/standard/802_11i-2004.html), [IEEE 802.11r-2008](https://standards.ieee.org/standard/802_11r-2008.html), [hashcat](https://github.com/hashcat/hashcat), and [hcxtools](https://github.com/ZerBea/hcxtools) source code.
