# EAP-MD5

## Overview

EAP-MD5 is a simple challenge/response EAP method defined in RFC 3748. It provides
no mutual authentication (the client cannot verify the server) and no key derivation
for session encryption. It is considered insecure for wireless networks and is
primarily encountered in legacy deployments.

## MD5-Challenge Structure (RFC 3748 S5.4)

The authenticator sends a random challenge value. The peer responds with an MD5
hash computed over: the EAP identifier byte, the user's password, and the challenge.

```
Response = MD5(ID || Password || Challenge)
```

Placeholder for a detailed packet-level breakdown of the EAP-MD5 exchange,
including the Value-Size field and optional Name field.

## Hash Extraction Format

The captured fields needed for cracking are: the EAP identifier, the challenge
value, and the MD5 response. Placeholder for extraction procedures from pcap
files and the expected field sizes.

## hashcat Mode 4800

hashcat mode 4800 handles EAP-MD5 hashes in the format:

```
hash:id:challenge
```

Placeholder for a detailed format specification and example hash line.

## Why It's Insecure

- No mutual authentication: the client cannot verify the server, enabling trivial
  rogue AP attacks.
- No session key derivation: the method cannot protect subsequent data frames.
- The MD5 hash is computed directly over the password with no key stretching,
  making dictionary attacks extremely fast.
- RFC 3748 itself states that EAP-MD5 is not recommended for wireless.
