# PBKDF2: Passphrase to PMK

### Step 1: Passphrase to PMK (Same for ALL crackable PSK variants)

```
PMK = PBKDF2(passphrase, SSID, ssidLen, 4096, 256)
```

- Inner PRF: **HMAC-SHA1** (always, regardless of AKM or keyver)
- Salt: the SSID (0-32 bytes)
- Iterations: 4096 (fixed by spec)
- Output: 256 bits (32 bytes)
- Internally calls HMAC-SHA1 **8192 times** (4096 iterations x 2 PBKDF2 blocks)
- This step is always the computational bottleneck

> The passphrase must be 8-63 printable ASCII characters (code points 32-126),
> or exactly 64 hex characters representing a raw 256-bit PSK.

#### How PRF-X Works Internally

The PRF (Pseudo-Random Function) used in keyver 1 and 2 is defined as:

```
PRF-X(K, A, B):
    R = ""
    for i = 0 to ceil(X / 160) - 1:
        R = R || HMAC-SHA1(K, A || 0x00 || B || i)
    return first X bits of R
```

Where `A` is the label string, `0x00` is a separator byte, `B` is the context
data (sorted MACs + sorted nonces), and `i` is a single counter byte.

For cracking, only the first 128 bits of output (the KCK) are needed to verify
the MIC. Since HMAC-SHA1 produces 160 bits per iteration, **only one iteration
(i=0) is ever computed**. This is why the counter byte is always 0x00 in the
100-byte PKE buffer.

The KDF used in keyver 3 follows the same principle but uses HMAC-SHA256 and
a different framing (counter prefix as LE uint16 instead of trailing byte,
length suffix appended).

#### Min/Max Ordering

The PRF input uses `Min(MAC_AP, MAC_STA)` and `Min(ANonce, SNonce)`. The
comparison treats each value as an **unsigned big-endian integer** -- the first
byte is the most significant. The smaller value is concatenated first, then the
larger. This ensures both sides compute the same PTK regardless of who is AP
vs STA.
