# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1.0] - 2026-07-07

Spec-verification pass: every claim cross-referenced against WPAWolf source code and IEEE 802.11-2024 spec text (5 review passes, 29 agents, 90 findings resolved).

### Added

- Tools: wpawolf page with full CLI reference, comparison table, output options
- Gap table: APLESS kernel gap section explaining the FT-PSK nonce-swap bug in mode 37100
- Gap table: AKM 19/20 (SHA-384) rows — no hashcat module, suppressed from legacy sinks
- hcxpcapngtool: documented 64-entry buffer limit, EAPOL 255 B size gate, per-file state reset
- Tools index: wpawolf row and pipeline diagram reference
- Guide: wpawolf mentioned alongside hcxpcapngtool, FT-PSK hash types (`-f` flag), WPA\*03\*/04\*
- Protocol: KDV=0 added to Key Descriptor Version tables (AKMs 8/9/19/20/24/25)
- Protocol: M3 classification note (ACK=1 + Install=1 only; MIC and Secure not checked)
- Protocol: Secure bit "0 (1 if rekey)" for M1/M2 in all identification tables

### Changed

- AKM 22/23 names swapped per Table 9-190: AKM 22 = FT-802.1X-SHA384, AKM 23 = 802.1X-SHA384
- PMKID description broadened from "single M1 frame" to 20 extraction sites with two container types (KDE vs RSN IE)
- Message pair byte: bit 7 = NC (nonce error correction needed), not "replay count not checked"
- LE/BE flags: ANonce byte order for nonce correction, not replay-counter endianness
- FT-PSK nonce ordering: documented as fixed order (SNonce || ANonce || BSSID || STA), not Min/Max
- Gap table: complete rewrite with WPAWolf corpus-verified support matrix
- WPA\*01\* format: trailing message_pair byte documented (was omitted)
- EAPOL field: 0-512 hex (256 bytes) upper bound documented
- TKIP TK: 256 bits per Table 12-8 (was listed as 128+128)
- AKM 11 ciphers: GCMP-128 only per Table 9-190 (was incorrectly showing CCMP-128)
- PASN introduction: 802.11az-2022 (was incorrectly 802.11-2020)

### Fixed

- FT-PSK PMK-R0 KDF context: SSIDlength (1 B) as first field per §12.7.1.6.3 (was incorrectly SPA)
- FT-PSK PMK-R1: output length 256 bits, PMK-R1-Name computed separately per §12.7.1.6.4
- AKM 19/20 PTK size: 704 bits per Table 12-11 + Table 12-8 (was incorrectly 576)
- EAPOL MIC computation: variable length (16/24 B) with KDV=0 / HMAC-SHA384 path
- Removed HMAC-SHA-256 from EAPOL MIC algorithm list (no AKM uses it for MIC)
- FILS PTK derivation formula corrected per §12.11.2.5.3
- N1E4/N3E4: default hcxpcapngtool combos (were incorrectly marked as --all only)
- 30+ spec section references corrected against IEEE 802.11-2024 (§12.7.1.3, §12.7.1.6, §12.7.2, §9.4.2.23.5, §9.4.2.45/46, §11.20, §12.7.8, §12.14, §12.7.1.6.5, Annex J.4.1)

### Removed

- `.pre-commit-config.yaml` (no Python source to lint)

### Infrastructure

- `pyproject.toml`: full metadata, `package = false`, authors, keywords, classifiers, URLs
- `Makefile`: `check` target, canonical `clean`/`distclean`
- `.gitignore`/`.gitattributes`/`.editorconfig`: tailored to mkdocs repo
- `docs.yml`: bumped `setup-uv` to v8.3.0, removed stale `fetch-depth: 0`

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
