# Changelog

## v2.0.0 (2026-04-11)

Complete site redesign. Renamed from "WiFi Cracking" to "WiFi Security Analysis."

### Added

- PSK attacks section covering PMKID, EAPOL MIC verification, and per-AKM
  algorithm details for AKM 2, 4, 6, 19, and 20.
- EAP attacks section covering PEAP/MSCHAPv2, EAP-MD5, and Cisco LEAP with
  hash extraction and cracking procedures.
- WEP section with attack taxonomy (FMS, KoreK, PTW, ChopChop, fragmentation,
  Caffe-Latte, Hirte) and aircrack-ng workflow.
- Expanded tools section: hcxpcapngtool, hashcat, aircrack-ng suite, and
  hostapd-mana.
- Reference section with EAPOL-Key frame format, capture requirements, hash
  extraction formats, and gap table.
- Glossary with 40+ defined terms.
- Mermaid diagram support for pipeline and flow visualizations.
- Contributing guide with development setup and style guide.

### Changed

- Reorganized site structure into attack-oriented sections (PSK, EAP, WEP)
  rather than tool-oriented layout.
- Updated all hash formats to current hashcat 22000 standard.
- Replaced deprecated hashcat modes (2500, 16800) with current equivalents.

### Removed

- Legacy hash format documentation for deprecated modes.
