# WEP (Wired Equivalent Privacy)

## WEP Design

WEP uses the RC4 stream cipher with a 24-bit initialization vector (IV) prepended
to the static key. Each frame is integrity-protected with a CRC-32 checksum
(called the ICV) appended before encryption. WEP keys are either 40-bit (WEP-40)
or 104-bit (WEP-104), yielding total RC4 key lengths of 64 or 128 bits
including the IV.

## Why WEP Is Broken

### IV Reuse

The 24-bit IV space contains only 16,777,216 values. On a busy network the IV
space is exhausted in hours, guaranteeing IV collisions. Two frames encrypted
with the same IV and key produce XOR-related ciphertext, leaking plaintext.

### CRC-32 Linearity

CRC-32 is a linear function, meaning `CRC(A XOR B) = CRC(A) XOR CRC(B)`. This
allows an attacker to flip arbitrary bits in the ciphertext and correct the ICV
without knowing the key, breaking integrity protection entirely.

### RC4 Key Scheduling Weakness

The FMS attack (2001) showed that certain weak IVs leak information about the
key bytes through the RC4 Key Scheduling Algorithm. Later work by KoreK and
the PTW attack further reduced the number of captured frames needed.

## Attack Overview Table

| Attack | Year | Packets Needed | What It Does |
|--------|------|---------------|--------------|
| FMS | 2001 | ~4,000,000 | Exploits weak IVs in RC4 KSA to recover key bytes |
| KoreK | 2004 | ~500,000 | Extends FMS with additional correlations, fewer packets |
| PTW | 2007 | ~40,000 | Uses RC4 keystream correlations; needs ARP packets |
| ChopChop | 2004 | Active | Decrypts a packet byte-by-byte by truncating and replaying |
| Fragmentation | 2005 | Active | Recovers keystream by exploiting 802.11 fragmentation |
| Caffe-Latte | 2007 | ~40,000 | Attacks client directly without AP using gratuitous ARPs |
| Hirte | 2008 | ~40,000 | Improved client-side attack using ARP request fragmentation |
