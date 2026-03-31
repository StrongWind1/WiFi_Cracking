# Standard PSK Algorithms (AKM 2 and 6)

### Step 2: Verification -- Differs Per Attack Vector and AKM

#### AKM 2 (Standard PSK) -- PMKID Attack

```
PMKID = HMAC-SHA1-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: **HMAC-SHA1**, output truncated to first 128 bits (16 bytes)
- Input: literal string "PMK Name" (8 bytes) + AP MAC (6 bytes) + STA MAC (6 bytes) = 20 bytes
- Compare result against captured PMKID

#### AKM 2 (Standard PSK) + keyver 1 (TKIP) -- EAPOL Attack

```
PTK = PRF-512(PMK,
              "Pairwise key expansion\x00" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
KCK = PTK[0:16]
MIC = HMAC-MD5(KCK, EAPOL_frame_with_MIC_zeroed)
```

- PRF uses **HMAC-SHA1** internally
- PRF input: 100 bytes (23-byte label + 12-byte MACs + 64-byte nonces + 1-byte counter)
- Only first 16 bytes of PRF output needed (KCK)
- MIC: **HMAC-MD5**, full 128-bit output
- Compare against captured MIC

#### AKM 2 (Standard PSK) + keyver 2 (CCMP) -- EAPOL Attack

```
PTK = PRF-384(PMK,
              "Pairwise key expansion\x00" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce))
KCK = PTK[0:16]
MIC = HMAC-SHA1-128(KCK, EAPOL_frame_with_MIC_zeroed)
```

- PRF uses **HMAC-SHA1** internally (same as keyver 1)
- PRF input: 100 bytes (same format)
- MIC: **HMAC-SHA1**, output truncated to 128 bits
- Compare against captured MIC

#### AKM 6 (PSK-SHA256) -- PMKID Attack

```
PMKID = HMAC-SHA256-128(PMK, "PMK Name" || MAC_AP || MAC_STA)
```

- Hash: **HMAC-SHA256**, output truncated to first 128 bits
- Input: same 20-byte string as AKM 2
- Different hash function than AKM 2!

#### AKM 6 (PSK-SHA256) + keyver 3 -- EAPOL Attack

```
PTK = KDF-384(PMK,
              "\x01\x00" ||
              "Pairwise key expansion" ||
              Min(MAC_AP, MAC_STA) || Max(MAC_AP, MAC_STA) ||
              Min(ANonce, SNonce)  || Max(ANonce, SNonce) ||
              "\x80\x01")
KCK = PTK[0:16]
MIC = AES-128-CMAC(KCK, EAPOL_frame_with_MIC_zeroed)
```

- KDF uses **HMAC-SHA256** internally (not SHA1)
- KDF input: 102 bytes (counter prefix + 22-byte label without null + MACs + nonces + length suffix)
- Counter prefix: `\x01\x00` (LE uint16 = 1)
- Length suffix: `\x80\x01` (LE uint16 = 384)
- MIC: **AES-128-CMAC** (not HMAC-based)
- Compare against captured MIC
