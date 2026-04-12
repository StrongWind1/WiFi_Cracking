# EAPOL-Key Frame Format

Byte-level layout of the EAPOL-Key frame as defined in IEEE 802.11-2024 §12.7.2.
This frame carries the 4-way handshake messages and the MIC that hashcat verifies.

## Frame Structure

```
Offset  Length  Field
------  ------  -----
0       1       Protocol Version (always 0x02 for 802.11i/RSN)
1       1       Packet Type (0x03 = Key)
2       2       Packet Body Length (big-endian uint16)
4       1       Descriptor Type (0x02 = RSN, 0xFE = WPA)
5       2       Key Information (bitfield — see below)
7       2       Key Length
9       8       Key Replay Counter (big-endian uint64)
17      32      Key Nonce (ANonce or SNonce per message)
49      16      EAPOL-Key IV (zero for CCMP; RC4 IV for TKIP kv1)
65      8       Key RSC (Receive Sequence Counter for GTK)
73      8       Reserved
81      16      Key MIC (zero while computing; filled after HMAC/CMAC)
97      2       Key Data Length (big-endian uint16)
99      var     Key Data (RSN IE, PMKID KDE, encrypted GTK, etc.)
```

!!! note "Variable MIC length"
    The MIC field at offset 81 is 16 bytes for AKM 1–9 and 11 (HMAC-SHA1-128,
    HMAC-MD5, AES-128-CMAC, or HMAC-SHA-256, all 128-bit output). It is 24
    bytes for AKM 12/13/19/20/22/23 (HMAC-SHA-384, truncated to 192 bits). For
    AKM 14/15 (FILS with AES-SIV), the MIC is 0 bytes. The Key Data Length
    field at offset 97 is then shifted by the difference.

## Key Information Bitfield

The 2-byte Key Information field encodes the descriptor version, key type, and
handshake flags. All undefined bits are reserved (set to 0).

| Bits | Field | Values / Notes |
|------|-------|----------------|
| 0–2 | Key Descriptor Version | 0 = per negotiated AKM (Table 12-11); 1 = HMAC-MD5/RC4 (kv1); 2 = HMAC-SHA1-128/AES (kv2); 3 = AES-128-CMAC/AES (kv3, AKM 3–6) |
| 3 | Key Type | 0 = Group/GTK; 1 = Pairwise/PTK |
| 4–5 | Reserved | Always 0 |
| 6 | Install | 1 = Install the key now (set in M3) |
| 7 | Key ACK | 1 = AP requests a response (set in M1, M3) |
| 8 | Key MIC | 1 = MIC field is populated (set in M2, M3, M4) |
| 9 | Secure | 1 = Both sides have installed keys (set in M3, M4) |
| 10 | Error | 1 = MIC failure notification |
| 11 | Request | 1 = STA requesting key refresh |
| 12 | Encrypted Key Data | 1 = Key Data is encrypted with KEK (set in M3) |
| 13–15 | Reserved | Always 0 |

## Message Identification Table

These flag combinations identify each handshake message:

| Message | Key ACK | Key MIC | Install | Secure | Nonce field | Key Data |
|---------|---------|---------|---------|--------|-------------|----------|
| M1 | 1 | 0 | 0 | 0 | ANonce | PMKID (optional) |
| M2 | 0 | 1 | 0 | 0 | SNonce | STA RSN IE |
| M3 | 1 | 1 | 1 | 1 | ANonce | Encrypted GTK + AP RSN IE |
| M4 | 0 | 1 | 0 | 1 | 0 | None |

## EAPOL-Key IV Note

For keyver 1 (TKIP), the 16-byte EAPOL-Key IV carries the RC4 encryption
parameters for Key Data. For keyver 2 and 3 (CCMP, AES-CMAC), this field
is always zeroed — Key Data is wrapped with the NIST AES key wrap algorithm
using the KEK.

## MIC Computation

To verify a MIC (hashcat's core operation):

1. Extract the raw EAPOL-Key frame bytes
2. Zero out the 16-byte MIC field (offset 81–96)
3. Compute `HMAC-MD5(KCK, frame)` (keyver 1) or `HMAC-SHA1(KCK, frame)`
   truncated to 128 bits (keyver 2) or `AES-128-CMAC(KCK, frame)` (keyver 3)
4. Compare result against the saved MIC bytes

The frame used includes the full EAPOL header (from offset 0) through the end
of Key Data. The 802.3/802.11 header preceding the EAPOL packet is NOT included.

## Spec References

- EAPOL-Key frame layout: 802.11-2024 §12.7.2
- Key Information field: §12.7.3, Figure 12-36
- MIC computation: §12.7.3
- Variable MIC lengths: Table 12-11 (integrity algorithms and MIC sizes per AKM)
