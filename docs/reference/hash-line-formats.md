# Hash Line Formats

### Mode 22000 (Standard WPA-PSK)

**Type 01 -- PMKID:**
```
WPA*01*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>***
         32hex   12hex    12hex    0-64hex
```

**Type 02 -- EAPOL:**
```
WPA*02*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<message_pair>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex
```

Note: the hashcat docs label field 7 as "ANONCE" but this is the **external
nonce**, which is the SNonce when the EAPOL is from M3 (see N2E3/N4E3 combos).
The EAPOL field (field 8) already contains the other nonce embedded within it.

**PMKID message pair field (type 01):**
```
bitmask of MESSAGEPAIR field for WPA*01:
  0: reserved
  1: PMKID from AP (standard)
  2: reserved
  4: PMKID from CLIENT (possible MESH or REPEATER)
```

**EAPOL message pair field (type 02):**
```
bitmask of MESSAGEPAIR field for WPA*02:
  bits 0-2:
    000 = M1+M2, EAPOL from M2 (challenge)          N1E2
    001 = M1+M4, EAPOL from M4 (authorized)         N1E4
    010 = M2+M3, EAPOL from M2 (authorized)         N3E2
    011 = M2+M3, EAPOL from M3 (authorized, --all)  N2E3
    100 = M3+M4, EAPOL from M3 (authorized, --all)  N4E3
    101 = M3+M4, EAPOL from M4 (authorized)         N3E4
  bit 3: reserved
  bit 4: AP-less attack (1 = no nonce-error-corrections needed)
  bit 5: LE router detected (1 = NC only for LE)
  bit 6: BE router detected (1 = NC only for BE)
  bit 7: replay count not checked (1 = NC mandatory)
```

N1E4 (0x01), N4E3 (0x04), and N3E4 (0x05) all depend on M4's nonce
being non-zero. Per IEEE 802.11i-2004 Section 8.5.3.4, M4's Key Nonce
shall be 0. Most implementations conform, making these three combos
unusable for the majority of captures.

**Hashcat pot file format (result of cracking):**
```
PMK*ESSID:PSK

PMK    = Plain Master Key (64 hex)
ESSID  = network name in hex
PSK    = Pre-Shared Key (the cracked password)
```

**Hashcat output file format:**
```
PMKID/MIC:MACAP:MACCLIENT:ESSID:PSK

PMKID/MIC = PMKID or MIC depending on hash type
MACAP     = AP MAC
MACCLIENT = client MAC
ESSID     = network name in plain text
PSK       = cracked password
```

### Mode 37100 (FT-PSK)

**Type 03 -- FT PMKID:**
```
WPA*03*<PMKID>*<MAC_AP>*<MAC_STA>*<ESSID>****<MDID>*<R0KHID>*<R1KHID>
         32hex   12hex    12hex    0-64hex      4hex  var hex   12hex
```

**Type 04 -- FT EAPOL:**
```
WPA*04*<MIC>*<MAC_AP>*<MAC_STA>*<ESSID>*<NONCE>*<EAPOL>*<message_pair>*<MDID>*<R0KHID>*<R1KHID>
       32hex  12hex    12hex    0-64hex  64hex   var hex  2hex          4hex   var hex   12hex
```
