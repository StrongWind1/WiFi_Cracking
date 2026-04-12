# EAPOL-Key Frame Format

This is the raw frame that gets captured, MIC-zeroed, and included in the hash line.

```
Offset  Size  Field
------  ----  -----
0       1     Version (usually 0x01 or 0x02)
1       1     Type (0x03 = EAPOL-Key)
2       2     Length (big-endian, of everything after this field)
4       1     Key Descriptor Type (0xFE=WPA, 0x02=RSN)
5       2     Key Information (big-endian, bitfield below)
7       2     Key Length (16=CCMP, 32=TKIP)
9       8     Replay Counter
17      32    Key Nonce (ANonce or SNonce depending on message)
49      16    Key IV
65      8     Key RSC
73      8     Reserved
81      16    Key MIC  ← THIS is zeroed for MIC computation
97      2     Key Data Length
99      var   Key Data (RSN IEs, GTK KDE, PMKID KDE, FT IEs...)
```

### Key Information Bitfield (16 bits, big-endian)

| Bit(s) | Name | Values |
|--------|------|--------|
| 0-2 | Key Descriptor Version | 1=HMAC-MD5/RC4, 2=HMAC-SHA1/AES, 3=AES-CMAC/AES |
| 3 | Key Type | 1=Pairwise, 0=Group |
| 4-5 | (reserved) | |
| 6 | Install | 1 in M3 |
| 7 | Key Ack | 1 = response required (set by AP in M1, M3) |
| 8 | Key MIC | 1 = MIC field is valid (M2, M3, M4) |
| 9 | Secure | 1 = initial key exchange complete (M3, M4) |
| 10 | Error | MIC failure report (TKIP countermeasures) |
| 11 | Request | Supplicant requesting handshake |
| 12 | Encrypted Key Data | 1 in M3 (GTK encrypted) |

### How to Identify Each Message

| Message | Key Ack | Key MIC | Install | Secure | Has SNonce | Has Key Data |
|---------|---------|---------|---------|--------|------------|-------------|
| M1 | 1 | 0 | 0 | 0 | No (ANonce) | PMKID KDE (optional) |
| M2 | 0 | 1 | 0 | 0 | Yes (SNonce) | STA RSN IE |
| M3 | 1 | 1 | 1 | 1 | No (ANonce) | AP RSN IE + encrypted GTK |
| M4 | 0 | 1 | 0 | 1 | Often zeroed | Empty |
