# PEAP / MSCHAPv2

PEAP (Protected EAP, RFC 2716) wraps an inner authentication method inside a
TLS 1.2 tunnel. The most common inner method is MSCHAPv2 (RFC 2759). When a
rogue AP terminates the TLS tunnel, the MSCHAPv2 challenge/response is
captured in cleartext, enabling offline cracking of the user's Windows NT hash.

## MSCHAPv2 Challenge/Response Structure

MSCHAPv2 is a challenge/response protocol based on the Windows NT hash. The
full exchange:

1. **Authenticator Challenge** (16 bytes) — sent by the server/rogue AP
2. **Peer Challenge** (16 bytes) — sent by the client in the Response packet
3. **NT-Response** (24 bytes) — computed by the client:

```
Challenge-Hash = SHA1(Peer-Challenge || Auth-Challenge || Username)[0:8]
                                                                    ↑ 8 bytes

NTHash = MD4(UTF16LE(Password))             -- 16 bytes (the "NT hash")

NT-Response = DESencrypt(NTHash[0:7],  ChallengeHash)  -- 8 bytes
           || DESencrypt(NTHash[7:14], ChallengeHash)  -- 8 bytes
           || DESencrypt(NTHash[14:16] || 0x000000000, ChallengeHash)  -- 8 bytes
```

The third DES operation pads the 2-byte remainder with 5 zero bytes, reducing
the effective DES key to `2^16 = 65536` possibilities for that block.

## Why It's Crackable

1. **DES is weak**: 56-bit DES with key space 2^56 is broken in hours on modern GPUs.
2. **Known padding**: The third 8-byte DES block uses only 2 bytes of NT hash
   + 5 zero-bytes. Cracking this block first narrows the NT hash to 65536 candidates.
3. **No salt**: MSCHAPv2 uses a challenge-derived value (not random salt per
   user), so rainbow tables are feasible.
4. **NT hash reuse**: Cracking yields the NT hash, which can be used directly
   for pass-the-hash attacks.

Moxie Marlinspike's 2012 Defcon presentation demonstrated that MS-CHAPv2 can
be reduced to a single DES crack, recoverable in under 24 hours against any
password using cloud DES cracking.

## Hash Extraction

### Passive capture (not possible without rogue AP for PEAP)

PEAP TLS tunnel prevents passive capture of inner MSCHAPv2. The rogue AP
technique is required to terminate the tunnel.

### With hostapd-mana

hostapd-mana logs captured MSCHAPv2 exchanges in the format needed for
hashcat:

```
# /etc/hostapd-mana/hostapd-mana.conf relevant options:
mana_wpe=1              # Enable credential capture
mana_credout=creds.txt  # Output file
```

Output format from hostapd-mana logs:

```
MSCHAPV2 username:challenge:response
```

Convert to hashcat 5500 format:

```
username::::NT-Response:authenticator-challenge
```

### With hcxpcapngtool (only works for EAP-TTLS/MSCHAPv2 without TLS — rare)

```bash
hcxpcapngtool --eapmschapv2=mschapv2.hc5500 capture.pcapng
```

## hashcat Mode 5500 Format

```
username::::NT-Response:challenge
```

| Field | Encoding | Size |
|-------|----------|------|
| username | plaintext | variable |
| LM fields | empty (4 colons) | 0 |
| NT-Response | 48-char hex (24 bytes) | 24 bytes |
| challenge | 16-char hex (8 bytes) | 8 bytes (the Challenge-Hash) |

The challenge field for mode 5500 is the 8-byte `Challenge-Hash`, not the raw
16-byte authenticator challenge. The hash derivation:
`SHA1(Peer-Challenge || Auth-Challenge || Username)[0:8]`.

Example hash line:

```
jdoe::::f14c0699e0c6adac8c8d93c20e0a62db7834b1c8eb3ebe5f:aabbccddeeff0011
```

## Cracking

```bash
# Dictionary attack
hashcat -m 5500 mschapv2.hashes wordlist.txt

# Brute force 8-char alphanumeric
hashcat -m 5500 mschapv2.hashes -a 3 '?a?a?a?a?a?a?a?a'
```

Mode 5500 is extremely fast compared to mode 22000 (no PBKDF2). Modern GPUs
achieve 10+ billion candidates per second against MS-CHAPv2, making short
passwords trivially crackable.

Cracking mode 5500 yields the NT hash. To recover the plaintext password from
the NT hash:

```bash
hashcat -m 1000 nthash.txt wordlist.txt   # NT hash cracking
```

## Spec and Source References

- MSCHAPv2 protocol: RFC 2759
- PEAP protocol: RFC 2716 / draft-kamath-pppext-peapv0
- hashcat format: `HCX_EAPMSCHAPV2HASHLIST` in hcxpcapngtool.h
