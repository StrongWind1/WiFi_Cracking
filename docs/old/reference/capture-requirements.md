# Capture Requirements

### What You Need to Capture for Each Attack

| Attack | AKM | Minimum Capture | Fields Required |
|--------|-----|----------------|-----------------|
| PMKID | 2 (PSK) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |
| PMKID | 4 (FT-PSK) | M2 with PMKID + FT IEs | SSID, MAC_AP, MAC_STA, PMKID, MDID, R0KH-ID, R1KH-ID |
| PMKID | 6 (PSK-SHA256) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |
| EAPOL | 2 (PSK) | Any message pair (M1+M2 best) | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |
| EAPOL | 4 (FT-PSK) | Any message pair + FT IEs | Same as above + MDID, R0KH-ID, R1KH-ID |
| EAPOL | 6 (PSK-SHA256) | Any message pair | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |

### Where Each Field Comes From

| Field | Found In | Notes |
|-------|----------|-------|
| SSID | Beacon, Probe Response (IE tag 0) | Must be captured separately from handshake |
| MAC_AP | 802.11 header (addr2 for M1/M3, addr1 for M2/M4) | Role depends on message direction |
| MAC_STA | 802.11 header (addr1 for M1/M3, addr2 for M2/M4) | Role depends on message direction |
| ANonce | M1 or M3, EAPOL Key Nonce field (32 bytes) | Usually identical in M1 and M3 |
| SNonce | M2 (or M4 if non-zero), EAPOL Key Nonce field | M4 nonce often zeroed per spec |
| MIC | M2, M3, or M4, EAPOL Key MIC field (16 bytes) | M1 has no MIC |
| EAPOL frame | Raw bytes of the EAPOL-Key frame containing the MIC | MIC field zeroed for verification |
| PMKID | M1, M2, Assoc Req, or Reassoc Req Key Data, PMKID KDE (tag 0xDD, length 0x14, type 0x04) | Not always present. FT-PSK uses M2 specifically. |
| MDID | Mobility Domain IE (tag 0x36) in Beacon/assoc frames | 2 bytes, FT only |
| R0KH-ID | Fast BSS Transition IE (tag 0x37) subelement | Variable length, up to 48 bytes |
| R1KH-ID | Fast BSS Transition IE (tag 0x37) subelement | 6 bytes (usually = AP MAC) |
