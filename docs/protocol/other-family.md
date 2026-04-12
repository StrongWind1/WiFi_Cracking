# Other AKMs (OWE, TDLS, PASN)

AKM suites outside the PSK, SAE, Enterprise, and FILS categories. These serve
specialized roles: opportunistic encryption, direct peer links, pre-association
security negotiation, and one deprecated suite.

## OWE — AKM 18

**Opportunistic Wireless Encryption**, marketed as "Enhanced Open."

OWE provides encryption on open networks without requiring a password. The AP
and STA perform an unauthenticated Diffie-Hellman key exchange during
association, deriving a PMK from the shared secret.

### Key Derivation

```
DH shared secret Z = STA_priv × AP_pub     (ECDH, group negotiated in assoc frames)
PMK = HKDF-Extract(STA_pub || AP_pub, Z)   -- RFC 5869
PMKID = HMAC-SHA256(PMK, "OWE PMK Name" || STA_pub || AP_pub)[0:16]
```

Then the standard 4-way handshake proceeds using this PMK.

### Security Properties

- **Protects against passive eavesdropping** — each session uses a unique DH
  key pair, so captured frames are unreadable without the session private key.
- **Does NOT authenticate the AP** — a rogue AP can complete the DH exchange
  and observe traffic. OWE offers no protection against active MITM.
- **No password** — there is nothing to crack. The PMK is derived from fresh
  DH randomness, not from a static secret.

OWE is designed for public hotspots where some confidentiality is better than
none, but where certificate-based authentication is impractical.

### Spec References

- OWE: 802.11-2024 §12.12
- DH group negotiation: §12.12.2
- RFC 8110 (OWE definition)

---

## TDLS — AKM 7

**Tunneled Direct-Link Setup** allows two stations associated to the same AP
to establish a direct encrypted link for peer-to-peer communication, without
routing traffic through the AP.

### Key Derivation

TDLS uses a separate handshake (the TDLS Setup Request/Response/Confirm
exchange) to establish a Tunnel Peer Key (TPK):

```
TPK = PRF-X(SNonce || ANonce,
            "TDLS PMK",
            Min(MAC_A, MAC_B) || Max(MAC_A, MAC_B))
```

The TPK is then split into the TPK-KCK and TPK-TK. This handshake runs inside
the existing 802.11 data channel (encapsulated in 802.11 data frames), so it
is protected by the AP's PTK.

### Usage

TDLS is negotiated between stations using TDLS Action frames. The AP is not
involved in the key exchange. Primarily used for high-throughput peer-to-peer
scenarios (media streaming, file transfer) to avoid the AP bottleneck.

### Spec References

- TDLS: 802.11-2024 §10.28, §12.7.1.5

---

## PASN — AKM 21

**Pre-Association Security Negotiation**, introduced in 802.11-2020.

PASN enables a station and AP to establish a secure channel before the
standard authentication/association procedure. This is required for:

- Secure 802.11az ranging (Fine Timing Measurement with security)
- Location services requiring pre-association encryption
- Bootstrapping credentials before association

### Key Derivation

PASN uses a 3-way authentication handshake (PASN Authentication frames 1, 2,
3) to establish a PASN-base key. The method for deriving the PASN-base key
depends on the configured "PASN wrapped data" type — it can be based on SAE,
FILS, a full 4-way handshake PMKSA, or open (no prior security context).

```
PTK = KDF-SHA256(PASN-base-key,
                 "PASN PTK Derivation",
                 SPA || BSSID || ANonce || SNonce)
```

### Usage

PASN is primarily a protocol primitive, not an end-user configuration option.
It is invoked by services that need secure pre-association communication,
particularly 802.11az ranging.

### Spec References

- PASN: 802.11-2024 §12.7.1.9

---

## APPeerKey — AKM 10 (Deprecated)

AKM 10 was defined for direct AP-to-AP key exchange in mesh or infrastructure
contexts. It was deprecated and has been removed from active use in the
standard. AKM 10 should not appear in modern deployments.

No attack surface exists because the AKM is not deployed.
