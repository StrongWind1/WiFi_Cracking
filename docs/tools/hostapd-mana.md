# hostapd-mana

## Overview

hostapd-mana is a modified version of hostapd designed for wireless security
testing. It operates as a rogue access point capable of capturing EAP credentials
from clients that connect expecting a legitimate enterprise network. The tool
intercepts the inner authentication exchange (typically MSCHAPv2 within PEAP or
EAP-TTLS) and logs the challenge/response material for offline cracking.

## Conceptual Flow

1. Configure hostapd-mana with the target ESSID and EAP settings.
2. Start the rogue AP; clients with stored network profiles auto-connect.
3. The TLS tunnel is established with the attacker's certificate.
4. The inner EAP method (MSCHAPv2) runs inside the tunnel under attacker control.
5. The challenge/response exchange is logged.
6. The captured hashes are formatted for hashcat mode 5500.

Placeholder for a detailed configuration walkthrough and example mana.conf file.

## Alternatives

### eaphammer

eaphammer is a Python-based tool that automates rogue AP attacks for EAP credential
capture. It wraps hostapd with additional features including automatic certificate
generation, GTC downgrade attacks, and integrated output formatting. Placeholder
for a brief comparison of eaphammer vs. hostapd-mana capabilities and trade-offs.
