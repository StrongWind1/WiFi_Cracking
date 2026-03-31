# EAPOL Size Limits

| Tool / Context | Max EAPOL Size | Why |
|----------------|---------------|-----|
| IEEE 802.11 spec | 65535 bytes (uint16 length field) | Protocol allows it |
| hcxpcapngtool internal | 1024 bytes | Practical limit |
| hcxpcapngtool -> mode 22000 | 255 bytes | Legacy hccap/hccapx uint8 constraint |
| hcxpcapngtool -> mode 37100 | 1024 bytes | ZerBea raised limit for FT |
| hashcat m22000 kernel | 320 bytes (`eapol[64+16]` u32 words) | GPU buffer |
| hashcat m37100 kernel | 320 bytes (`eapol[64+16]` u32 words) | GPU buffer |
| Typical WPA2-PSK M2 | ~120-140 bytes | Fits easily |
| Typical FT-PSK M2 | ~260-300 bytes | Contains FT IEs, often exceeds 255 |
| Largest in wpa-sec (2018 analysis) | **510 bytes** | ZerBea found 256-510 byte frames in wpa-sec data |

ZerBea's 2018 wpa-sec analysis found these EAPOL lengths in real captures:
256, 258, 262, 270, 278, 288, 294, 306, 310, 322, 326, 330, 334, 342,
358, 370, 374, 386, 390, 406, 422, 438, 484, 500, 502, 510.
(Source: https://github.com/hashcat/hashcat/issues/1816)

### ESSID encoding

The ESSID field in hash lines is always hex-encoded because IEEE 802.11
defines SSIDs as arbitrary 0-32 byte sequences, not strings. An SSID can
contain null bytes, non-UTF8 sequences, or any byte value. When parsing
the hex ESSID field, use the field length divided by 2 as the ESSID
length. Do not use strlen() on the decoded bytes.
