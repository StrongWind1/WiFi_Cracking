# Gap Table

## Overview

This page tracks known gaps between the IEEE 802.11 specification, the hcxtools
implementation, and hashcat's cracking support. A "gap" is any AKM, cipher suite,
or protocol feature that is defined in the spec but not yet supported by the
toolchain, or where tool behavior diverges from the spec.

## PSK Gaps

Placeholder for a table of PSK-related gaps:

| Feature | Spec Section | hcxtools | hashcat | Notes |
|---------|-------------|----------|---------|-------|
| AKM 19 (SAE) EAPOL | 12.4 | Extracts | Mode 37100 (PMKID only) | No EAPOL cracking for SAE |
| AKM 20 (FT-SAE) EAPOL | 13.5 | Extracts | Not supported | FT-SAE EAPOL cracking unavailable |
| GCMP-256 MIC | 12.5.3 | Partial | Supported | Placeholder for details |

## EAP Gaps

Placeholder for a table of EAP-related gaps covering EAP methods that produce
crackable output but lack tool support, and methods where extraction is supported
but cracking modes are missing.

## WEP Gaps

WEP is considered fully supported by aircrack-ng. No significant gaps exist
between specification and tooling. Placeholder for any edge cases or known
limitations.

## Master Summary

Placeholder for a high-level summary table counting: total features tracked,
fully supported, partially supported, and unsupported, broken down by category.
