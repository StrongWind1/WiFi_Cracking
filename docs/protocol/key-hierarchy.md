# Key Hierarchy

### The Core Idea

A passphrase is never sent over the air. Instead, both sides independently derive
the same encryption keys from the passphrase and prove to each other that they
arrived at the same result.

### The Key Hierarchy

```
Passphrase  +  SSID
       \       /
        \     /
    PBKDF2-HMAC-SHA1 (4096 iterations)
            |
           PMK  (256 bits)  ← Pairwise Master Key
            |
    PRF or KDF  +  ANonce  +  SNonce  +  MAC_AP  +  MAC_STA
            |
           PTK  (384 or 512 bits)  ← Pairwise Transient Key
          / | \
        /   |   \
     KCK   KEK   TK  (+TMK for TKIP)
```

| Key | Size | Purpose |
|-----|------|---------|
| **PMK** | 256 bits | Master secret derived from passphrase + SSID |
| **PTK** | 384 bits (CCMP) / 512 bits (TKIP) | Session key bundle |
| **KCK** | 128 bits (PTK bits 0-127) | Signs EAPOL-Key handshake messages (MIC) |
| **KEK** | 128 bits (PTK bits 128-255) | Encrypts GTK during handshake |
| **TK** | 128 bits (PTK bits 256-383) | Encrypts actual data traffic |
| **TMK** | 2 x 64 bits (PTK bits 384-511) | TKIP only: Michael MIC keys, one per direction |
