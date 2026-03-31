# The 4-Way Handshake

```
    AP (Authenticator)                      STA (Supplicant)
    ==================                      =================

    Both already know PMK (derived from passphrase + SSID)

    1. ──── M1: ANonce, PMKID(optional) ──────>
                                                STA generates SNonce
                                                STA derives PTK
    2. <──── M2: SNonce, MIC, RSN IE ──────────
       AP derives PTK
       AP verifies MIC
    3. ──── M3: ANonce, MIC, GTK(encrypted) ──>
                                                STA verifies MIC
                                                STA installs keys
    4. <──── M4: MIC ──────────────────────────
       AP installs keys
```

| Message | Sender | Contains | MIC? | What It Proves |
|---------|--------|----------|------|----------------|
| M1 | AP -> STA | ANonce, optionally PMKID in Key Data | No | Nothing (unauthenticated) |
| M2 | STA -> AP | SNonce, STA's RSN IE | Yes | STA knows the PMK |
| M3 | AP -> STA | ANonce, AP's RSN IE, encrypted GTK | Yes | AP knows the PMK |
| M4 | STA -> AP | Acknowledgment | Yes | Handshake complete |
