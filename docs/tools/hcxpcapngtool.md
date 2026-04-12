# hcxpcapngtool

## Overview

hcxpcapngtool is part of the hcxtools suite developed by ZerBea. It converts
pcap and pcapng capture files into hash formats suitable for hashcat. It handles
both PSK (PMKID and EAPOL) and EAP (MSCHAPv2, MD5) extraction, making it the
primary extraction tool for WiFi hash cracking.

## PSK Extraction Options

Placeholder for a table of command-line options related to PSK hash extraction,
including output file flags for PMKID and EAPOL hashes, ESSID filters, and
MAC address filters.

## EAP Extraction Options

Placeholder for a table of command-line options related to EAP hash extraction,
covering MSCHAPv2 and EAP-MD5 output formats, identity extraction, and
challenge/response field mapping.

## Options Matrix

Placeholder for a comprehensive matrix mapping each command-line flag to: what
it does, which hash types it affects, the output format produced, and the
corresponding hashcat mode.

## Output Formats

hcxpcapngtool produces several output formats:

- **WPA*01** -- PMKID hash line (hashcat mode 22000)
- **WPA*02** -- EAPOL MIC hash line (hashcat mode 22000)
- **WPA*03** -- PMKID hash line, deprecated format
- **WPA*04** -- EAPOL hash line, deprecated format
- **NetNTLMv1** -- MSCHAPv2 challenge/response (hashcat mode 5500)

Placeholder for detailed format specifications for each output type.
