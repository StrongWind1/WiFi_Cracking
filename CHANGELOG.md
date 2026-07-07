# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.0.0] - 2026-07-02

Complete rewrite: expanded from WPA/WPA2 PSK-only to all 25 AKM suites, EAP attacks, and WEP.

### Added

- Guide section: beginner-friendly walkthrough from capturing traffic through cracking (how WiFi passwords work, capturing, PMKID attack, handshake attack, extracting hashes, cracking with hashcat)
- Protocol: security matrix covering all 25 AKM suites organized by family
- Protocol: SAE family (WPA3) — AKM 8 (SAE), AKM 9 (FT-SAE), AKM 24/25 (SAE-PK)
- Protocol: Enterprise family — AKM 1, 3, 5, 11-13, 22, 23
- Protocol: FILS family — AKM 14-17
- Protocol: OWE (Opportunistic Wireless Encryption), TDLS, PASN
- Protocol: FT-PSK expanded with AKM 19 (FT-PSK-SHA384), PSK expanded with AKM 20 (PSK-SHA384)
- EAP Attacks: PEAP/MSCHAPv2, EAP-MD5, Cisco LEAP credential capture and cracking
- WEP: design flaws, FMS/KoreK/PTW attacks, aircrack-ng practical workflow
- Tools: hostapd-mana (rogue AP for EAP credential capture), expanded aircrack-ng suite docs
- Custom dark/light theme with WiFi-inspired color palette
- Responsive tables, full-width content layout, dashboard-style index cards

### Changed

- Restructured site into Guide (walkthrough) and Reference (deep technical) tabs
- Migrated v1 content into new structure, archived original pages under `docs/old/`

### Fixed

- Corrected MIC algorithms, EAP codes, and OWE formula against IEEE 802.11-2024
- Corrected spec references against IEEE 802.11-2024 §12.7
- Corrected PASN PTK derivation per §12.13.8

## [1.0.0] - 2026-03-31

### Added

- Complete WPA/WPA2 PSK cracking guide covering protocol, attacks, algorithms, and tools
- WPA key hierarchy and 4-way handshake protocol documentation
- All PSK variants: AKM 2 (standard PSK), AKM 4 (FT-PSK), AKM 6 (PSK-SHA256)
- PMKID and EAPOL attack vector documentation with 12-to-6-to-3 hash collapse derivation
- N#E# message pair naming convention with full comparison table
- Step-by-step algorithms: PBKDF2, PRF, KDF, FT-PSK key derivation chain
- Hash line format reference for modes 22000 and 37100 (WPA\*01\*/02\*/03\*/04\*)
- EAPOL-Key frame structure with byte offsets and bitfield documentation
- Spec vs hcxtools vs hashcat gap analysis table
- hcxpcapngtool options reference with tested results matrix
- Hashcat salt grouping model and correct deduplication method
- Cracking cheat sheet with tshark commands and workflow
- MkDocs Material documentation site with dark/light theme
- GitHub Actions CI/CD for docs build and deploy
