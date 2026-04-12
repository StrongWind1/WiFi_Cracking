# Contributing

## Quick Start

1. Clone the repository:

    ```bash
    git clone <repo-url>
    cd WiFi_Cracking
    ```

2. Install mkdocs-material:

    ```bash
    pip install mkdocs-material
    ```

3. Start the development server:

    ```bash
    mkdocs serve
    ```

    The site is available at `http://127.0.0.1:8000` and auto-reloads on changes.

## Making Changes

- All documentation lives in the `docs/` directory.
- Edit existing pages or create new ones following the directory structure.
- Add new pages to the `nav` section in `mkdocs.yml` so they appear in the
  site navigation.
- Preview changes locally with `mkdocs serve` before submitting.

## Content Guidelines

- Every page must have a single H1 title matching the `nav` entry.
- Use H2 for major sections and H3 for subsections.
- Reference authoritative sources (IEEE 802.11-2020, RFCs, tool documentation)
  wherever possible.
- Include spec section numbers when discussing protocol details.
- Tables should have a header row and use consistent column alignment.
- Code blocks must specify a language for syntax highlighting.

## Style Guide

- Write in present tense, active voice.
- Use "the AP sends" not "the AP will send" or "the AP would send."
- Spell out acronyms on first use per page, with the abbreviation in parentheses.
- Keep paragraphs short -- aim for 3-5 sentences.
- Use admonitions (`!!! note`, `!!! warning`) sparingly and only when the
  information genuinely requires special attention.
