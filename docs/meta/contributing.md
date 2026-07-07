# Contributing

## Getting Started

```bash
git clone https://github.com/StrongWind1/WiFi_Cracking.git
cd WiFi_Cracking
pip install mkdocs-material
mkdocs serve            # preview at http://127.0.0.1:8000
```

For strict build validation (same as CI):

```bash
python3 -m mkdocs build --strict
```

## Making Changes

1. Fork the repo and create a branch from `main`
2. Edit or add pages under `docs/`
3. Add new pages to the `nav` section in `mkdocs.yml`
4. Run `mkdocs build --strict` to verify no broken links or warnings
5. Open a PR against `main` with a clear description of what changed and why

## Content Guidelines

- Cite primary sources (IEEE 802.11-2024, RFCs, tool source code) for all
  technical claims. Include section numbers for spec references.
- Use the N#E# naming convention for message pairs (see the
  [EAPOL attack page](../psk-attacks/eapol.md))
- Use `message_pair` with hex values (`0x00`–`0x05`) when referencing the
  hashcat field
- Keep tables and code blocks formatted consistently with existing pages
- Do not add content about post-capture network access or active exploitation

## Style Guide

- Write in present tense, active voice
- Use "the AP sends" not "the AP will send"
- Spell out acronyms on first use per page (abbreviated forms auto-link via
  the glossary abbreviation list)
- Keep paragraphs short — 3–5 sentences
- Use admonitions (`!!! note`, `!!! warning`) sparingly and only when the
  information genuinely requires special attention

## Reporting Errors

Use the [bug report template](https://github.com/StrongWind1/WiFi_Cracking/issues/new?template=bug_report.md).
Include which page has the error, what is wrong, and what the correct information
is (with a source if possible).

## Scope

This project covers IEEE 802.11 wireless security analysis: protocol internals
for all AKM suites, offline password attacks against PSK networks (hcxtools,
hashcat), enterprise EAP credential extraction, and legacy WEP vulnerabilities.

Out of scope: active network exploitation, deauthentication, injection
techniques, post-authentication lateral movement, and anything requiring
unauthorized access to networks.
