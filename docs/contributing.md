# Contributing

See [CONTRIBUTING.md](https://github.com/StrongWind1/WiFi_Cracking/blob/main/CONTRIBUTING.md) for full guidelines.

## Quick start

```bash
git clone https://github.com/StrongWind1/WiFi_Cracking.git
cd WiFi_Cracking
pip install mkdocs-material
mkdocs serve            # preview at http://127.0.0.1:8000
```

## Making changes

1. Fork the repo and create a branch from `main`
2. Edit or add pages under `docs/`
3. Run `mkdocs build --strict` to verify no broken links or warnings
4. Open a PR against `main`

## Content guidelines

- Cite primary sources (IEEE specs, tool source code) for all technical claims
- Use the N#E# naming convention for message pairs
- Use `message_pair` with hex values (0x00-0x05) when referencing the hashcat field
- Do not add content about post-capture network access or unauthorized activity
