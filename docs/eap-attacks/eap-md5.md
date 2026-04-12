# EAP-MD5

EAP-MD5 (EAP type 4) is a simple challenge/response method defined in
RFC 3748 §5.4. It transmits the challenge and response in cleartext
(no TLS tunnel), making passive capture sufficient. No rogue AP required.

## MD5-Challenge Structure (RFC 3748 §5.4)

The authenticator sends a random challenge. The peer responds with an MD5
hash over the EAP identifier, password, and challenge:

```
Response-Value = MD5(Identifier || Password || Challenge-Value)
```

Where:
- `Identifier` — 1-byte EAP packet ID (from the Request frame)
- `Password` — the user's password (plaintext bytes, no encoding specified)
- `Challenge-Value` — random bytes sent in the MD5-Challenge Request

The MD5 output is 16 bytes. RFC 3748 does not specify padding or encoding
of the password — implementations use it as raw bytes.

## Packet-Level Exchange

```
Authenticator → Peer:
  EAP Code:   1 (Request)
  Identifier: 0x42
  Type:        4 (MD5-Challenge)
  Value-Size: 0x10 (16 bytes)
  Value:      <16 random challenge bytes>
  Name:       <optional authenticator identity>

Peer → Authenticator:
  EAP Code:   2 (Response)
  Identifier: 0x42
  Type:        4 (MD5-Challenge)
  Value-Size: 0x10
  Value:      MD5(0x42 || Password || Challenge)
  Name:       <peer identity>
```

Both frames are visible in a passive capture — no TLS or encryption.

## Hash Extraction

```bash
hcxpcapngtool --eapmd5=eapmd5.hc4800 capture.pcapng
```

Also extractable with Wireshark by filtering `eap` frames and reading the
MD5-Challenge fields manually.

## hashcat Mode 4800 Format

```
md5_response:identifier:challenge
```

| Field | Encoding | Size |
|-------|----------|------|
| md5_response | 32-char hex (16 bytes) | 16 bytes |
| identifier | 2-char hex (1 byte) | 1 byte |
| challenge | variable hex | variable (typically 16 bytes) |

Example hash line:

```
a3d4b7c9e1f23458a9bc4d7e2f1a6b90:42:deadbeefcafebabe0102030405060708
```

## Cracking

```bash
hashcat -m 4800 eapmd5.hashes wordlist.txt
```

Mode 4800 is extremely fast — MD5 with no key stretching, no PBKDF2. Billions
of candidates per second on GPU. Any password under ~10 characters with a
reasonable charset is crackable in seconds with a GPU.

## Why EAP-MD5 Is Insecure

1. **No mutual authentication** — the client cannot verify the server. Any
   device broadcasting the right SSID and sending a challenge will receive
   the user's MD5 response.
2. **No session key derivation** — EAP-MD5 produces no keying material for
   encrypting data frames. Networks using EAP-MD5 cannot deploy WPA encryption
   properly.
3. **MD5 with no key stretching** — the hash is directly crackable at GPU speed.
4. **RFC 3748 itself explicitly recommends against EAP-MD5 for wireless**
   (§5.4: "EAP-MD5 SHOULD NOT be used ... in environments where authentication
   information could be captured").

EAP-MD5 is deprecated for wireless by RFC 3748 and should not appear in
production deployments. It persists in legacy enterprise environments.

## Spec References

- EAP-MD5: RFC 3748 §5.4
- hashcat format: `HCX_EAPMD5_OUT` in hcxpcapngtool.h
