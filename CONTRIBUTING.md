# Contributing to WiFi Cracking

## Getting started

```bash
git clone https://github.com/StrongWind1/WiFi_Cracking.git
cd WiFi_Cracking
uv run --group docs mkdocs serve    # preview at http://127.0.0.1:8000
```

## Making changes

1. Fork the repo and create a branch from `main`
2. Edit or add pages under `docs/`
3. Run `uv run --group docs mkdocs build --strict` to verify no broken links or warnings
4. Open a PR against `main` with a clear description of what changed and why

## Content guidelines

- Cite primary sources (IEEE specs, RFCs, tool source code) for all technical claims
- Use the N#E# naming convention for message pairs (see the [EAPOL attack page](https://strongwind1.github.io/WiFi_Cracking/psk-attacks/eapol/))
- Use `message_pair` with hex values (0x00-0x05) when referencing the hashcat field
- Keep tables and code blocks formatted consistently with existing pages
- Do not add content about post-capture network access or unauthorized activity

## Reporting errors

Use the [bug report template](https://github.com/StrongWind1/WiFi_Cracking/issues/new?template=bug_report.md). Include which page has the error, what's wrong, and what the correct information is (with a source if possible).

## Scope

This project documents WiFi security analysis across all 802.11 authentication mechanisms: protocol internals (all AKM suites), hash extraction, and offline cracking for PSK, EAP, and WEP. Content about active network attacks, deauthentication, injection, or post-authentication activity is out of scope.
