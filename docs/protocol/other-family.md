# Other AKMs (OWE, TDLS, PASN)

This page covers AKM suites that fall outside the PSK, SAE, Enterprise, and FILS categories. These serve specialized roles: opportunistic encryption, direct peer links, pre-association negotiation, and one deprecated suite.

## OWE -- AKM 18

Opportunistic Wireless Encryption (OWE), marketed as "Enhanced Open," provides encryption on open networks without requiring a password. The AP and STA perform an unauthenticated Diffie-Hellman key exchange during association, deriving a PMK from the shared secret. This protects against passive eavesdropping but not active attacks (rogue APs, MitM).

<!-- TODO: document DH group negotiation and PMK derivation from DH shared secret -->

## TDLS -- AKM 7

Tunneled Direct-Link Setup allows two stations associated to the same AP to establish a direct link for peer-to-peer communication without routing traffic through the AP. AKM 7 handles the key management for this direct link, deriving a TPK (TDLS Peer Key) through a TDLS-specific handshake.

<!-- TODO: document TPK derivation and TDLS handshake flow -->

## PASN -- AKM 21

Pre-Association Security Negotiation (PASN), introduced in 802.11-2024, allows a station and AP to establish a security association before the standard authentication and association procedure. This enables secure ranging (802.11az) and other pre-association operations that require encrypted frames.

<!-- TODO: document PASN authentication flow and key derivation -->

## APPeerKey -- AKM 10

AKM 10 was intended for peer-to-peer key management (AP PeerKey) but has been deprecated and removed from active use in the standard. It should not be encountered in modern deployments.

## Spec References

- OWE: 802.11-2024 Section 12.12, RFC 8110
- TDLS: Section 12.7.1.5
- PASN: Section 12.12.7 (802.11-2024)
- APPeerKey (deprecated): referenced in earlier revisions
