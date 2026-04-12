# Message Pairs

## Why 12 Collapses to 6

Hashcat takes one EAPOL frame + one external nonce. The MIC and EAPOL are
locked together. So the real model is:

```
EAPOL frame (M2, M3, or M4)  ×  External nonce source (2 choices)  =  6
```

| N#E# | EAPOL from | Nonce already inside EAPOL | Nonce hashcat needs externally | Hash line NONCE field contains |
|------|------------|---------------------------|-------------------------------|-------------------------------|
| N1E2 | M2 | SNonce (M2 byte offset 17-48) | ANonce | ANonce from M1 |
| N1E4 | M4 | SNonce (M4 byte offset 17-48) | ANonce | ANonce from M1 |
| N3E2 | M2 | SNonce (M2 byte offset 17-48) | ANonce | ANonce from M3 |
| N2E3 | M3 | ANonce (M3 byte offset 17-48) | SNonce | SNonce from M2 |
| N4E3 | M3 | ANonce (M3 byte offset 17-48) | SNonce | SNonce from M4 |
| N3E4 | M4 | SNonce (M4 byte offset 17-48) | ANonce | ANonce from M3 |

## Master Comparison Table

| N#E# | eapol= nonce= | Educational | hcx Bitmask | hcx Description | hcx Notes | Old hcx (M##E#) | hashcat message_pair |
|------|---------------|-------------|-------------|-----------------|-----------|-----------------|----------------------|
| N1E2 | eapol=M2 nonce=M1 | M2(SNonce+MIC) + M1(ANonce) | 000 | M1+M2, EAPOL from M2 | challenge, default | M12E2 | 0x00 |
| N1E4 | eapol=M4 nonce=M1 | M4(SNonce+MIC) + M1(ANonce) | 001 | M1+M4, EAPOL from M4 | authorized, --all | M14E4 | 0x01 |
| N3E2 | eapol=M2 nonce=M3 | M2(SNonce+MIC) + M3(ANonce) | 010 | M2+M3, EAPOL from M2 | authorized, default | M32E2 | 0x02 |
| N2E3 | eapol=M3 nonce=M2 | M3(ANonce+MIC) + M2(SNonce) | 011 | M2+M3, EAPOL from M3 | authorized, --all | M32E3 | 0x03 |
| N4E3 | eapol=M3 nonce=M4 | M3(ANonce+MIC) + M4(SNonce) | 100 | M3+M4, EAPOL from M3 | authorized, --all | M34E3 | 0x04 |
| N3E4 | eapol=M4 nonce=M3 | M4(SNonce+MIC) + M3(ANonce) | 101 | M3+M4, EAPOL from M4 | authorized, --all | M34E4 | 0x05 |

## Reading N#E#

N = external nonce source message, E = EAPOL frame source message.
N1E2 means "nonce from M1, EAPOL from M2." hashcat extracts the SNonce from
inside M2's EAPOL frame and uses the ANonce from M1 as the hash line's nonce field.

N1E4 (0x01), N4E3 (0x04), and N3E4 (0x05) all depend on M4's nonce
being non-zero. Per IEEE 802.11i-2004 Section 8.5.3.4, M4's Key Nonce
shall be 0. Most implementations conform, making these three combos
unusable for the majority of captures.

**Reading old hcx M##E#**: The first two digits are ANonce source and SNonce
source (e.g., M32E3 = ANonce from M3, SNonce from M2, EAPOL from M3). Used in
hcxtools discussions and source code (as ST_M12E2, ST_M32E3, etc.).

**Reading hcx columns**: The three hcx columns (Bitmask, Description, Notes)
come directly from the upstream hcxtools README "Bitmask Message Pair Field"
section. "Mx+My" labels the two messages involved, then the description
specifies which provides the EAPOL frame.

## Identical Hash Pairs

Within one handshake session, M1 and M3 carry the same ANonce, and M2 and M4
carry the same SNonce. So these pairs produce identical crackable hashes:

```
N1E2 == N3E2  (both use M2's EAPOL, ANonce is the same value)
N2E3 == N4E3  (both use M3's EAPOL, SNonce is the same value)
N1E4 == N3E4  (both use M4's EAPOL, ANonce is the same value)
```
