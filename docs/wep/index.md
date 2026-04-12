# WEP (Wired Equivalent Privacy)

WEP was the original 802.11 security protocol, defined in the 802.11-1997
standard. It is fundamentally broken at the cryptographic level and should not
be deployed. Any WEP network is compromised given sufficient captured traffic.

## WEP Design

WEP uses the RC4 stream cipher with a 24-bit initialization vector (IV)
prepended to the static key. Each frame is integrity-protected with a CRC-32
checksum (called the ICV) appended before encryption.

WEP key lengths:

| Name | Static key | IV | Total RC4 key |
|------|------------|-----|---------------|
| WEP-40 | 40 bits (5 bytes) | 24 bits (3 bytes) | 64 bits |
| WEP-104 | 104 bits (13 bytes) | 24 bits (3 bytes) | 128 bits |

The 3-byte IV is prepended to the key in the order `IV[0] || IV[1] || IV[2] || Key`
before initializing the RC4 KSA (Key Scheduling Algorithm).

## Why WEP Is Broken

### IV Reuse

The 24-bit IV space contains only 2^24 = 16,777,216 unique values. On a
moderate-throughput network, the IV space is exhausted within hours, guaranteeing
IV reuse. Two frames encrypted with the same IV and static key produce
XOR-related ciphertext: `C1 XOR C2 = P1 XOR P2`. If either plaintext is
known (e.g., ARP frames have known structure), the other is immediately
recoverable.

### CRC-32 Linearity

CRC-32 is a linear function over GF(2): `CRC(A XOR B) = CRC(A) XOR CRC(B)`.
An attacker can flip arbitrary bits in a WEP-encrypted frame's ciphertext and
update the ICV checksum without knowing the key. This completely breaks
integrity protection — bit-flipping attacks are trivial.

### RC4 Key Scheduling Weakness

The RC4 KSA processes the full key bytes sequentially. Certain IV values of
the form `(A+3, 255, X)` cause the KSA's internal state to leak information
about specific key bytes through the first byte of the keystream. Fluhrer,
Mantin, and Shamir (FMS) formalized this in 2001. Statistical analysis of
sufficient weak IVs recovers the key bytes one at a time.

## Attack Overview

| Attack | Year | Authors | Packets needed | Method |
|--------|------|---------|---------------|--------|
| FMS | 2001 | Fluhrer, Mantin, Shamir | ~4,000,000 data frames | Weak IV + KSA keystream correlation |
| KoreK | 2004 | KoreK | ~500,000 data frames | 16 independent correlations; fewer IVs |
| PTW | 2007 | Pyshkin, Tews, Weinmann | ~40,000 ARP frames | Multibyte attack on all keystream bytes |
| ChopChop | 2004 | KoreK | 1 frame (active) | Decrypt by truncating + replaying |
| Fragmentation | 2005 | Andrea | 1 frame (active) | Recover keystream via fragmentation |
| Caffe-Latte | 2007 | AirTight | ~40,000 (client) | Client-side; no AP needed |
| Hirte | 2008 | Tews, Beck | ~40,000 (client) | ARP fragmentation variant |

### FMS / KoreK

Statistical attacks exploiting RC4 KSA weaknesses. Require large numbers of
frames using weak IVs. KoreK extended FMS with additional correlations,
significantly reducing the required frame count.

### PTW (Pyshkin-Tews-Weinmann)

The most efficient key recovery attack. Instead of targeting only weak IVs,
PTW uses correlations between the keystream's first bytes and the key bytes
for all IVs. Requires ARP frames (68 bytes) because the plaintext structure
is known:

- ARP header structure is predictable (source/dest IP and MAC)
- Known plaintext → known first bytes of keystream → statistical correlation

PTW is the default attack in aircrack-ng. With ARP replay injection:
~40,000 unique IVs → WEP-40 or WEP-104 key in under 60 seconds.

### ChopChop

Interactive decryption: the attacker truncates the last byte of an encrypted
frame and sends modified copies to the AP. If the AP accepts (indicates valid
CRC), the last byte is determined. Repeating recovers the full plaintext and
the corresponding keystream — usable for crafting arbitrary encrypted frames.
Does not directly recover the WEP key.

### Fragmentation

Exploits the 802.11 fragmentation mechanism to recover keystream from a single
known-plaintext fragment. The recovered keystream can be used to encrypt new
frames. Like ChopChop, does not recover the key.

### Caffe-Latte / Hirte

Client-side attacks that work without proximity to the AP. The attacker induces
the client to retransmit ARP requests by sending gratuitous ARPs, then injects
the client's own encrypted traffic back at it in a loop. Sufficient IVs accumulate
from the client's transmissions alone.

## Spec References

- WEP definition: IEEE 802.11-1997, 802.11b-1999
- FMS attack: Fluhrer, Mantin, Shamir — "Weaknesses in the Key Scheduling
  Algorithm of RC4" (2001)
- PTW attack: Pyshkin, Tews, Weinmann — "Breaking 104 Bit WEP in Less Than
  60 Seconds" (2007)
- ChopChop: KoreK, H1kari (2004)
