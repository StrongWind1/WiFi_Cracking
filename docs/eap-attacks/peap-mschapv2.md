# PEAP / MSCHAPv2

## Overview

PEAP (Protected EAP) wraps an inner authentication method inside a TLS tunnel.
The most common inner method is MSCHAPv2. When a rogue AP terminates the TLS
tunnel, the MSCHAPv2 challenge/response exchange is captured in cleartext,
enabling offline cracking of the user's NT hash.

## MSCHAPv2 Challenge/Response Structure

Placeholder for the MSCHAPv2 exchange structure: authenticator challenge (16 bytes),
peer challenge (16 bytes), NT-Response (24 bytes), and how the challenge hash is
derived from both challenges plus the username.

## Hash Extraction from Capture

Placeholder for how to extract the MSCHAPv2 fields from a packet capture, including
the EAP identity, authenticator challenge, peer challenge, and NT-Response.
Tools like hcxpcapngtool or manual Wireshark extraction can be used.

## hashcat Mode 5500 Format

The captured challenge/response is formatted for hashcat mode 5500 (NetNTLMv1) as:

```
username::::NT-Response:authenticator-challenge
```

Placeholder for a detailed field breakdown and example hash line.

## NTHash Derivation

The NT-Response is computed from the NT hash of the user's password. Cracking
recovers the NT hash, which can then be used for pass-the-hash attacks or
reversed to the plaintext password via dictionary/brute-force attack.

## Why It's Crackable

MSCHAPv2 relies on DES-based challenge/response with known weaknesses. The
24-byte NT-Response is derived from three DES operations using two bytes of
zero-padding, reducing the effective key space. Moxie Marlinspike's 2012
Defcon talk demonstrated practical attacks reducing this to a single DES
operation via lookup table.
