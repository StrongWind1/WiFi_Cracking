# How WiFi Passwords Work

## What happens when you connect

When you type a WiFi password, your device and the access point go through a
process called the **4-way handshake** to prove you both know the password
without sending it over the air.

## Why passwords are crackable

The password is transformed into the **PMK** (Pairwise Master Key — the 256-bit key derived from your password) using a slow hashing function called PBKDF2. If an attacker captures the right data from
the handshake, they can try passwords offline — running each guess through the
same PBKDF2 function and checking if it produces a matching result.

## Two attack vectors

| Attack | What you capture | Client needed? |
|--------|-----------------|----------------|
| **PMKID** (a fingerprint the AP computes from the PMK and both MAC addresses) | A hash from the AP's first message | No |
| **Handshake** | Messages from the 4-way handshake | Yes (must be connected) |

Both attacks produce a hash that can be cracked offline with hashcat.

!!! tip "Want the full picture?"
    See the [Key hierarchy](../protocol/key-hierarchy.md) and
    [4-way handshake](../protocol/four-way-handshake.md) reference pages for
    byte-level protocol details.

**Next:** [Capturing traffic](capturing.md)
