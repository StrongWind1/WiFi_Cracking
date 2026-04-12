# Capture Requirements

What fields are required for each attack type and where to find them in a
capture file.

## PSK Attack Requirements

### PMKID Extraction

| Attack | AKM | Minimum capture | Fields required |
|--------|-----|----------------|-----------------|
| PMKID | 2 (PSK) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |
| PMKID | 4 (FT-PSK) | M2 with PMKID + FT IEs | SSID, MAC_AP, MAC_STA, PMKID, MDID, R0KH-ID, R1KH-ID |
| PMKID | 6 (PSK-SHA256) | M1, M2, Assoc Req, or Reassoc Req with PMKID | SSID, MAC_AP, MAC_STA, PMKID |

### EAPOL Handshake Extraction

| Attack | AKM | Minimum capture | Fields required |
|--------|-----|----------------|-----------------|
| EAPOL | 2 (PSK) | Any message pair (M1+M2 preferred) | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |
| EAPOL | 4 (FT-PSK) | Any message pair + FT IEs | Same as above + MDID, R0KH-ID, R1KH-ID |
| EAPOL | 6 (PSK-SHA256) | Any message pair | SSID, MAC_AP, MAC_STA, ANonce, SNonce, MIC, EAPOL frame |

### Field Sources (PSK)

| Field | Found in | Notes |
|-------|----------|-------|
| SSID | Beacon, Probe Response (IE tag 0) | Must be captured separately from handshake |
| MAC_AP | 802.11 header addr2 (M1/M3), addr1 (M2/M4) | Role depends on message direction |
| MAC_STA | 802.11 header addr1 (M1/M3), addr2 (M2/M4) | Role depends on message direction |
| ANonce | M1 or M3 EAPOL Key Nonce field (32 bytes) | Usually identical in M1 and M3 |
| SNonce | M2 (or M4 if non-zero) EAPOL Key Nonce field | M4 nonce usually zeroed |
| MIC | M2, M3, or M4 EAPOL Key MIC field (16 bytes) | M1 has no MIC |
| EAPOL frame | Raw bytes of the EAPOL-Key frame containing the MIC | MIC field zeroed for verification |
| PMKID | M1, M2, Assoc Req, or Reassoc Req Key Data (KDE tag 0xDD, type 0x04) | Not always present |
| MDID | Mobility Domain IE (tag 0x36) in Beacon/assoc frames | 2 bytes, FT only |
| R0KH-ID | Fast BSS Transition IE (tag 0x37) subelement | Variable length, up to 48 bytes |
| R1KH-ID | Fast BSS Transition IE (tag 0x37) subelement | 6 bytes, usually = AP MAC |

---

## EAP Attack Requirements

### MSCHAPv2 (PEAP / EAP-TTLS)

MSCHAPv2 runs inside a TLS tunnel established by PEAP or EAP-TTLS. Passive
capture sees only the outer TLS exchange, not the inner credentials.
Extraction requires a rogue AP (hostapd-mana) that terminates the TLS tunnel
and logs the inner challenge/response.

| Field | Size | Source |
|-------|------|--------|
| Username | variable | EAP-Identity response (plaintext, before TLS) |
| Authenticator Challenge | 16 bytes | Rogue AP MSCHAPv2 challenge |
| Peer Challenge | 16 bytes | Client MSCHAPv2 response |
| NT-Response | 24 bytes | Client MSCHAPv2 response |

hashcat mode 5500 format: `username::::NT-Response:challenge`

The challenge input is: `SHA1(peer_challenge || auth_challenge || username)[0:8]`

### EAP-MD5

EAP-MD5 exchanges are unencrypted and visible in passive captures.

| Field | Size | Source |
|-------|------|--------|
| Identifier | 1 byte | EAP-MD5 Request frame |
| Challenge | variable (typically 16 bytes) | EAP-MD5 Request frame |
| MD5 Response | 16 bytes | EAP-MD5 Response frame |

hashcat mode 4800 format: `md5_response:identifier:challenge`

### LEAP (Cisco LEAP)

LEAP is unencrypted and visible in passive captures.

| Field | Size | Source |
|-------|------|--------|
| Username | variable | LEAP exchange (plaintext) |
| AP Challenge | 8 bytes | LEAP AP challenge frame |
| Peer Response | 24 bytes | LEAP peer response frame |

hashcat mode 5500 format (same as MSCHAPv2).

---

## WEP Capture Requirements

WEP cracking requires data frames encrypted with unique IVs. The PTW attack
specifically needs ARP-sized frames typically obtained via ARP replay injection.

| Attack | Minimum packets | Frame type | Notes |
|--------|----------------|------------|-------|
| FMS | ~4,000,000 | Any data frames | Statistical weak IV collection |
| KoreK | ~500,000 | Any data frames | 17 statistical correlations (WEP-104; ~150K for WEP-40) |
| PTW | ~40,000 | ARP frames (68 bytes) | Multibyte key attack, default in aircrack-ng |
| ChopChop | 1 frame | Any data frame | Interactive decryption, no key recovery |
| Fragmentation | 1 frame | Any data frame | Generates keystream, no key recovery |
| Caffe-Latte | Client probe required | Client data | No AP needed |

For PTW, known-plaintext ARP frames are required. ARP replay injection
(`aireplay-ng -3`) is typically needed to generate the volume required.
