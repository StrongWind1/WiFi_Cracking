# FT-PSK Algorithms (AKM 4)

#### AKM 4 (FT-PSK) -- PMKID Attack

FT-PSK uses a completely different PMKID derivation based on the 802.11r key
hierarchy. The PMKID is not a simple HMAC of the PMK.

```
Step A: PMK-R0-Name-salt
  = HMAC-SHA256(PMK,
      counter_LE16(2) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take bytes 0-15 of the result.

Step B: PMK-R0-Name
  = SHA256("FT-R0N" || PMK-R0-Name-salt[0:16])
  Truncate to 128 bits.

Step C: PMKID
  = SHA256("FT-R1N" || PMK-R0-Name || R1KHID || STA_MAC)
  Truncate to 128 bits.
```

- All SHA-256 (no SHA-1 after the initial PBKDF2)
- Requires extra inputs: MDID, R0KH-ID, R1KH-ID

#### AKM 4 (FT-PSK) -- EAPOL Attack

```
Step A: PMK-R0
  = HMAC-SHA256(PMK,
      counter_LE16(1) || "FT-R0" || ssidLen || SSID ||
      MDID || R0KHIDLen || R0KHID || STA_MAC ||
      size_LE16(384))
  Take first 32 bytes.

Step B: PMK-R1
  = HMAC-SHA256(PMK-R0,
      counter_LE16(1) || "FT-R1" ||
      R1KHID || STA_MAC ||
      size_LE16(384))
  Take first 32 bytes.

Step C: PTK (2 iterations required: ceil(384/256) = 2)
  iter1 = HMAC-SHA256(PMK-R1,
      counter_LE16(1) || "FT-PTK" ||
      SNonce || ANonce || MAC_AP || STA_MAC ||
      size_LE16(384))                          -- 32 bytes
  iter2 = HMAC-SHA256(PMK-R1,
      counter_LE16(2) || "FT-PTK" ||
      SNonce || ANonce || MAC_AP || STA_MAC ||
      size_LE16(384))                          -- 32 bytes
  PTK = (iter1 || iter2)[0:48]                 -- first 384 bits of 512

Step D: MIC
  KCK = PTK[0:16]
  MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- Three chained HMAC-SHA256 KDF calls (vs one PRF call for standard PSK)
- Only keyver 3 (AES-CMAC) is used
- Requires: MDID, R0KH-ID, R1KH-ID in addition to standard handshake data
