# Cisco LEAP

LEAP (Lightweight Extensible Authentication Protocol) is a Cisco-proprietary
EAP method (type 17) introduced in 2000 as an alternative to EAP-MD5. It uses
a modified MS-CHAPv1 challenge/response for mutual authentication. LEAP
exchanges are unencrypted and visible in passive captures.

Cisco officially deprecated LEAP and recommends migrating to EAP-FAST or PEAP.

## LEAP Authentication Flow

LEAP performs a two-way challenge/response — the server challenges the client,
and then the client challenges the server with the same NTHash construction:

```
AP → STA:  LEAP Challenge (AP Challenge — 8 bytes)
STA → AP:  LEAP Response (Peer Response — 24 bytes)
           Username

STA → AP:  LEAP Challenge (Peer Challenge — 8 bytes)
AP → STA:  LEAP Response (AP Response — 24 bytes)

AP → STA:  EAP-Success
```

Both directions use the same MS-CHAPv1 computation, so cracking either
response yields the password.

## MS-CHAPv1 Challenge/Response

```
NTHash = MD4(UTF16LE(Password))            -- 16 bytes

Response = DESencrypt(NTHash[0:7],  Challenge)   -- 8 bytes
        || DESencrypt(NTHash[7:14], Challenge)   -- 8 bytes
        || DESencrypt(NTHash[14:16] || 0x00*5, Challenge)  -- 8 bytes
```

The third DES block pads the remaining 2 bytes of NTHash with 5 zero bytes,
reducing effective key space to 2^16 = 65536 for that block. This makes an
offline attack practical: crack the third block first (65536 possibilities),
then verify against the NTHash.

## Why LEAP Is Deprecated

1. **No TLS tunnel** — challenge and response are transmitted in cleartext.
   Passive sniffing captures everything needed for offline cracking.
2. **MS-CHAPv1 weakness** — same DES-based construction as MSCHAPv2 without
   the peer challenge. The `asleap` tool (2003, Joshua Wright) demonstrated
   real-time practical cracking.
3. **Same NT hash derivation** — cracking LEAP yields the Windows NTHash,
   usable for pass-the-hash attacks.
4. **Mutual authentication is illusory** — both sides use the same weak
   construction. The "mutual" verification does not prevent an active attacker
   who can precompute the AP's response for any guessed password.

## Hash Extraction

LEAP exchanges are visible in passive 802.11 captures:

```bash
hcxpcapngtool --eapleap=leap.hc5500 capture.pcapng
```

Also extractable with the `asleap` tool:

```bash
asleap -r capture.pcap -f asleap.dict -n asleap.hash
```

## hashcat Mode 5500 Format

LEAP uses the same hashcat mode as MSCHAPv2 (NetNTLMv1):

```
username::::response:challenge
```

| Field | Encoding | Size |
|-------|----------|------|
| username | plaintext | variable |
| LM fields | empty (4 colons) | 0 |
| response | 48-char hex (24 bytes) | 24 bytes |
| challenge | 16-char hex (8 bytes) | 8 bytes (the AP challenge) |

Note: LEAP uses the raw 8-byte AP challenge directly (no Challenge-Hash
computation as in MSCHAPv2).

## Cracking

```bash
hashcat -m 5500 leap.hashes wordlist.txt
```

Mode 5500 is GPU-accelerated against DES. Modern GPUs achieve billions of
candidates per second. LEAP passwords are typically domain credentials —
a targeted dictionary attack against common corporate passwords is highly
effective.

## Spec and Source References

- LEAP: Cisco documentation (proprietary)
- MS-CHAPv1: RFC 2433
- asleap tool: Joshua Wright (2003)
- hashcat format: `HCX_EAPLEAP_OUT` in hcxpcapngtool.h
