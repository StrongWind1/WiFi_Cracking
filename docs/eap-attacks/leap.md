# Cisco LEAP

## Overview

LEAP (Lightweight Extensible Authentication Protocol) is a Cisco-proprietary EAP
method introduced in 2000. It uses a modified MS-CHAPv1 challenge/response for
mutual authentication. LEAP was widely deployed in early enterprise wireless
networks but has been deprecated due to fundamental cryptographic weaknesses.

## LEAP Protocol Flow

Placeholder for the LEAP authentication sequence: EAP-Identity, AP challenge,
peer response, peer challenge, AP response. LEAP performs mutual authentication
by running the challenge/response in both directions, but both directions use
the same weak cryptographic construction.

## MS-CHAPv1 Challenge/Response

LEAP's challenge/response is based on MS-CHAPv1. The NT hash of the user's
password is split into three 7-byte DES keys (with two bytes of zero padding
on the third key), and each encrypts the 8-byte challenge.

Placeholder for the detailed DES key derivation and the resulting 24-byte
response structure.

## hashcat Mode 5500

LEAP challenge/response pairs are cracked using hashcat mode 5500 (NetNTLMv1),
the same mode used for MSCHAPv2. The hash line format is:

```
username::::response:challenge
```

Placeholder for format details and example hash line.

## Why Deprecated

- MS-CHAPv1 uses DES with a 2-byte zero-padded third key, reducing effective
  key space.
- No TLS tunnel protects the challenge/response exchange.
- The asleap tool (2003) demonstrated practical real-time cracking.
- Cisco officially recommends migrating to EAP-FAST or PEAP.
- The mutual authentication provides no additional security since both
  directions use the same weak construction.
