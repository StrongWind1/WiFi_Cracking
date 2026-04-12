# PSK Variants

### The Three Dimensions

A PSK-based WPA system is defined by three independent choices:

1. **AKM Suite** -- How authentication and key management work
2. **Cipher Suite** -- How data is encrypted after key setup
3. **Key Descriptor Version** -- Which algorithms sign/verify the handshake itself

### All PSK-Based AKM Suites

| AKM | OUI:Type | Name | Standard | Key Exchange |
|-----|----------|------|----------|-------------|
| **2** | 00-0F-AC:2 | PSK | 802.11i-2004 | 4-Way Handshake |
| **4** | 00-0F-AC:4 | FT-PSK | 802.11r-2008 | Fast Transition + 4-Way Handshake |
| **6** | 00-0F-AC:6 | PSK-SHA256 | 802.11w-2009 | 4-Way Handshake |
| **8** | 00-0F-AC:8 | SAE | 802.11-2012 / WPA3 (2018) | Dragonfly PAKE + 4-Way Handshake |
| **9** | 00-0F-AC:9 | FT-SAE | 802.11-2012 / WPA3 (2018) | Dragonfly + Fast Transition |

> **SAE (AKM 8, 9)**: Uses a password but derives PMK through the Dragonfly
> zero-knowledge proof protocol, not PBKDF2. Cannot be cracked offline.
> Excluded from the rest of this guide.

> **Enterprise (AKM 1, 3, 5)**: These use 802.1X with an EAP method
> (EAP-TLS, PEAP, etc.) instead of a pre-shared key. The PMK comes from
> the EAP exchange with a RADIUS server, not from PBKDF2. There is no
> passphrase to brute-force. Excluded from this guide -- no PSK involved.

### All Relevant Cipher Suites

| Value | Name | Encryption | Key Size | Used With |
|-------|------|-----------|---------|-----------|
| 2 | TKIP | RC4 (per-packet key mixing) | 128-bit TK (+128-bit TMK) | WPA1 |
| 4 | CCMP | AES-128 in CTR+CBC-MAC mode | 128-bit TK | WPA2/WPA3 |
| 9 | GCMP | AES in Galois/Counter Mode | 128 or 256-bit | WPA3 (RSN only) |

### All Key Descriptor Versions

| keyver | Bits 0-2 of Key Info | PTK Derivation | MIC Algorithm | Key Data Encryption |
|--------|---------------------|----------------|---------------|---------------------|
| **1** | 0x01 | PRF-512 (HMAC-SHA1) | HMAC-MD5 | RC4 |
| **2** | 0x02 | PRF-384 (HMAC-SHA1) | HMAC-SHA1-128 | AES Key Wrap |
| **3** | 0x03 | KDF-384 (HMAC-SHA256) | AES-128-CMAC | AES Key Wrap |

### The Valid Combinations

Not all combinations of AKM + cipher + keyver exist in the wild. Here are the
real-world configurations:

| # | Common Name | AKM | Cipher | keyver | IE Type | Key Descriptor |
|---|-------------|-----|--------|--------|---------|----------------|
| 1 | WPA-PSK (TKIP) | 2 | TKIP | 1 | WPA IE (0xDD, MS OUI) | 0xFE (WPA) |
| 2 | WPA2-PSK (CCMP) | 2 | CCMP | 2 | RSN IE (0x30) | 0x02 (RSN) |
| 3 | WPA2-PSK (TKIP+CCMP mixed) | 2 | TKIP or CCMP | 1 or 2 | Both IEs possible | 0xFE or 0x02 |
| 4 | WPA2-FT-PSK | 4 | CCMP | 3 | RSN IE (0x30) | 0x02 (RSN) |
| 5 | WPA2-PSK-SHA256 | 6 | CCMP | 3 | RSN IE (0x30) | 0x02 (RSN) |
