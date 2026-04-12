# SAE Family (AKM 8, 9, 24, 25)

Simultaneous Authentication of Equals (SAE) is the authentication protocol behind WPA3-Personal. It uses a password-authenticated key exchange (PAKE) that produces a PMK without exposing any material useful for offline attacks.

## Overview

SAE implements the Dragonfly key exchange, a zero-knowledge proof protocol where both parties prove knowledge of the password without revealing it. Even if an attacker captures the full SAE exchange, there is no hash or derived value that can be subjected to offline dictionary attack.

## SAE Authentication Flow (Commit / Confirm)

<!-- TODO: add Mermaid sequence diagram for SAE Commit/Confirm exchange -->

SAE authentication happens before the 4-way handshake and consists of two frames per side:

1. **Commit** -- each side sends a scalar and element derived from the password and a random value.
2. **Confirm** -- each side sends a confirmation hash proving it computed the same shared secret.

After a successful exchange, both sides derive a PMK (and PMKID) from the shared secret.

## Why Offline Cracking Is Impossible

The Commit frame contains a scalar and an elliptic curve point (or finite field element) derived from the password, but the derivation involves random per-session values that are never transmitted. An attacker cannot separate the password contribution from the randomness without solving the discrete logarithm problem. Each password guess requires an active authentication attempt against the AP.

## Hash-to-Element vs Hunting-and-Pecking

<!-- TODO: detail both PWE derivation methods and their side-channel implications -->

The original SAE specification used a "hunting-and-pecking" method to convert the password into a group element (PWE), which was vulnerable to side-channel timing attacks (Dragonblood). The newer hash-to-element (H2E) method, required for AKM 24/25, uses a deterministic mapping that eliminates this timing channel.

## AKM Variants

| AKM | Name | Hash | FT? | PWE Method | Standard |
|-----|------|------|-----|-----------|----------|
| 8 | SAE | SHA-256 | No | H&P or H2E | 802.11-2012 |
| 9 | FT-SAE | SHA-256 | Yes | H&P or H2E | 802.11-2012 |
| 24 | SAE (group-dependent) | Group-dependent | No | H2E only | 802.11-2024 |
| 25 | FT-SAE (group-dependent) | Group-dependent | Yes | H2E only | 802.11-2024 |

AKM 24 and 25 select the hash algorithm based on the negotiated cryptographic group rather than fixing it to SHA-256, enabling stronger groups without protocol changes.

## Spec References

- SAE protocol: 802.11-2024 Section 12.4
- Dragonfly key exchange: RFC 7664
- Hash-to-element: Section 12.4.4.2.2
