# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [2.0.0] — 2026-04-11

Complete site redesign. Expanded scope from WPA/WPA2 PSK to all 25 AKM suites.
Expanded scope from WPA/WPA2 PSK cracking to comprehensive IEEE 802.11 security
reference.

### Added

- **Protocol section**: All 25 AKM suites across 5 categories (PSK, FT-PSK,
  SAE, Enterprise/802.1X, FILS, Other). Key hierarchies, handshake flows,
  and cryptographic details per IEEE 802.11-2024.
- **EAP attacks section**: PEAP/MSCHAPv2 (hashcat mode 5500), EAP-MD5
  (mode 4800), Cisco LEAP (mode 5500). Hash extraction and cracking procedures.
- **WEP section**: Design flaws, attack taxonomy (FMS, KoreK, PTW, ChopChop,
  fragmentation, Caffe-Latte, Hirte), and practical aircrack-ng workflow.
- **Expanded tools section**: hcxpcapngtool (with EAP extraction options),
  hashcat, aircrack-ng suite, and hostapd-mana.
- **Reference section**: EAPOL-Key frame format, capture requirements (PSK,
  EAP, WEP), unified hash extraction reference, gap table expanded to all
  attack types.
- **Glossary** with 40+ defined terms.
- **Abbreviation auto-linking** via pymdownx.snippets.
- Mermaid diagram support for all flow, sequence, and hierarchy diagrams.

### Changed

- Reorganized nav into attack-oriented sections (PSK Attacks, EAP Attacks, WEP)
  rather than the previous tool-oriented layout.
- Protocol section expanded from 3 AKMs (PSK variants) to all 25 AKMs.
- `four-way-handshake.md`: replaced ASCII sequence diagram with Mermaid, added
  Key Information bitfield table.
- `key-hierarchy.md`: replaced ASCII tree with Mermaid flowcharts, added FT
  key hierarchy diagram and per-AKM PTK size table.
- `psk-attacks/eapol.md`: merged `message-pairs.md` content into the EAPOL
  attack page. N#E# Master Comparison Table now lives here.
- `psk-attacks/algorithms.md`: consolidated v1 `pbkdf2.md`, `standard-psk.md`,
  and `ft-psk.md` into a single algorithms reference.
- `reference/hash-extraction.md`: consolidated v1 `hash-line-formats.md`,
  `hashcat-modes.md`, and `eapol-size-limits.md` into unified reference.
- `reference/gap-table.md`: expanded from PSK-only to PSK + EAP + WEP gaps.
- Updated all spec references from 802.11i-2004 and 802.11r-2008 to
  IEEE 802.11-2024.

### Fixed

- **FT-PTK derivation**: AKM 4 PTK derivation (Step C) requires 2 HMAC-SHA256
  iterations because PTK = 384 bits and KDF-SHA256 produces 256 bits per call.
  ceil(384/256) = 2 per §12.7.1.6.2. Previous version showed only 1 iteration.
- **GCMP cipher suites**: GCMP-128 = suite type 8, GCMP-256 = suite type 9.
  Previous version listed both as type 9.
- **PRF null separator**: The 0x00 null byte in PRF is injected internally by
  the function, not part of the label argument (§12.7.1.2). Corrected in all
  PRF call representations.
- **M4 nonce**: Updated "shall be 0" (802.11i-2004) to "should be 0"
  (802.11-2024 §12.7.6.5 NOTE 9).
- **PMK-R0-Name-salt slice**: Step A output is always exactly 16 bytes;
  removed incorrect `[0:16]` truncation annotation.
- **EAPOL-Key frame MIC length**: Added note that MIC is 16 bytes for AKM 1–9,
  24 bytes for AKM 12/13/19/20/22/23, 0 bytes for AKM 14/15.

### Removed

- `docs/algorithms/` directory (content merged into `psk-attacks/algorithms.md`)
- `docs/attacks/` directory (content merged into `psk-attacks/` section)
- `docs/reference/hash-line-formats.md` (merged into `reference/hash-extraction.md`)
- `docs/reference/hashcat-modes.md` (merged into `reference/hash-extraction.md`)
- `docs/reference/eapol-size-limits.md` (merged into `reference/hash-extraction.md`)
- `docs/tools/cheat-sheet.md` (merged into `tools/hashcat.md`)
- `WPA_PSK_CRACKING_GUIDE.md` (superseded by site content)

---

## [1.0.0] — 2026-03-31

### Added

- Complete WPA/WPA2 PSK cracking guide covering protocol, attacks, algorithms, and tools
- WPA key hierarchy and 4-way handshake protocol documentation
- All PSK variants: AKM 2 (standard PSK), AKM 4 (FT-PSK), AKM 6 (PSK-SHA256)
- PMKID and EAPOL attack vector documentation with 12-to-6-to-3 hash collapse derivation
- N#E# message pair naming convention with full comparison table
- Step-by-step algorithms: PBKDF2, PRF, KDF, FT-PSK key derivation chain
- Hash line format reference for modes 22000 and 37100
- EAPOL-Key frame structure with byte offsets and bitfield documentation
- Spec vs hcxtools vs hashcat gap analysis table
- hcxpcapngtool options reference with tested results matrix
- hashcat salt grouping model and correct deduplication method
- Cracking cheat sheet with tshark commands and workflow
- MkDocs Material documentation site with dark/light theme
- GitHub Actions CI/CD for docs build and deploy
