# EAPOL-Key Frame Format

## Frame Structure

Placeholder for the byte-level layout of an EAPOL-Key frame as defined in
IEEE 802.11-2020 Section 12.7.2. Key fields include:

| Offset | Length | Field |
|--------|--------|-------|
| 0 | 1 | Protocol Version |
| 1 | 1 | Packet Type (3 = Key) |
| 2 | 2 | Packet Body Length |
| 4 | 1 | Descriptor Type |
| 5 | 2 | Key Information |
| 7 | 2 | Key Length |
| 9 | 8 | Key Replay Counter |
| 17 | 32 | Key Nonce |
| 49 | 16 | EAPOL-Key IV |
| 65 | 8 | Key RSC |
| 73 | 8 | Reserved |
| 81 | 16 | Key MIC |
| 97 | 2 | Key Data Length |
| 99 | var | Key Data |

## Key Information Bitfield

The 2-byte Key Information field encodes descriptor version, key type, and
handshake flags. Placeholder for a bit-by-bit diagram:

| Bits | Field | Values |
|------|-------|--------|
| 0-2 | Key Descriptor Version | 1=HMAC-MD5/RC4, 2=HMAC-SHA1/AES, 3=AKM-defined |
| 3 | Key Type | 0=Group, 1=Pairwise |
| 4-5 | Install | Pairwise key install flag |
| 6 | Key ACK | Set by AP |
| 7 | Key MIC | Set when MIC is present |
| 8 | Secure | Set after handshake complete |
| 9 | Error | Error notification |
| 10 | Request | Request flag |
| 11 | Encrypted Key Data | Set when Key Data is encrypted |
| 12-15 | Reserved | |

## Message Identification Table

Placeholder for a table showing how to identify each of the four handshake
messages from the Key Information flags, presence of nonces, and MIC field:

| Message | Key ACK | Key MIC | Install | Secure | Nonce | Key Data |
|---------|---------|---------|---------|--------|-------|----------|
| M1 | 1 | 0 | 0 | 0 | ANonce | PMKID (optional) |
| M2 | 0 | 1 | 0 | 0 | SNonce | RSN IE |
| M3 | 1 | 1 | 1 | 1 | ANonce | Encrypted GTK |
| M4 | 0 | 1 | 0 | 1 | 0 | None |
