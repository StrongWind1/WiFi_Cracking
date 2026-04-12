# EAP Attacks

## Overview

EAP (Extensible Authentication Protocol) attacks target enterprise wireless
networks that use 802.1X authentication. Unlike PSK networks, EAP networks
authenticate individual users with credentials verified by a RADIUS server.
The primary attack surface is credential capture via rogue access points.

## Rogue AP Concept

A rogue AP (evil twin) impersonates a legitimate enterprise network. When a client
connects and begins EAP authentication, the rogue AP captures the challenge/response
exchange. The attacker never completes the TLS tunnel (if applicable) but extracts
enough material to attempt offline cracking of the user's credentials.

## EAP Type Taxonomy

Placeholder for a tiered table of EAP types:

| EAP Type | Code | Inner Method | Crackable | Notes |
|----------|------|-------------|-----------|-------|
| PEAP     | 25   | MSCHAPv2    | Yes       | Most common enterprise deployment |
| EAP-TTLS | 21   | MSCHAPv2/PAP | Yes     | Similar to PEAP |
| EAP-MD5  | 4    | MD5-Challenge | Yes     | No mutual authentication |
| LEAP     | 17   | MS-CHAPv1  | Yes       | Cisco proprietary, deprecated |
| EAP-TLS  | 13   | Certificate | No       | Client certificate required |
| EAP-FAST | 43   | MSCHAPv2   | Conditional | PAC provisioning may be vulnerable |

Additional registered EAP types exist but are rarely encountered in wireless
deployments. A collapsed reference of other types will be added here.

## Which Methods Produce Crackable Output

Only EAP methods that transmit a password-derived challenge/response in the clear
(or inside a terminated TLS tunnel under attacker control) produce crackable output.
Certificate-based methods like EAP-TLS do not expose crackable material.
Placeholder for a summary matrix mapping EAP types to hashcat modes.
