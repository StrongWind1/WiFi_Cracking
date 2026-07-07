# Guide

Three end-to-end workflows for WiFi security testing, from capture to cracked credential. Each guide is self-contained: pick the one that matches your target network.

## What you need

- A Linux system (Kali Linux recommended)
- A WiFi adapter that supports monitor mode (for capturing)
- One of the toolkits below, depending on the attack

| Attack | Capture | Extract / Crack | Install |
|---|---|---|---|
| **WEP** | airodump-ng | [WEPWolf](https://github.com/StrongWind1/WEPWolf) | [Download binary](https://github.com/StrongWind1/WEPWolf/releases) or `make release` |
| **WPA/WPA2** | [hcxdumptool](https://github.com/ZerBea/hcxdumptool) or airodump-ng | [WPAWolf](https://github.com/StrongWind1/WPAWolf) + [hashcat](https://github.com/hashcat/hashcat) | [Download binary](https://github.com/StrongWind1/WPAWolf/releases) or `make release`; `sudo apt install hashcat` |
| **EAP** | hostapd-mana (rogue AP) | hashcat | `sudo apt install hostapd-mana hashcat` |

<div class="grid cards" markdown>

- :material-wifi-cog: **Adapters and Linux Setup**

    Which WiFi adapter to buy, which kernel to run, and how to get monitor mode working. MediaTek vs Realtek, in-kernel drivers, and the mt76 regression.

    [:octicons-arrow-right-24: Adapter guide](adapters.md)

- :material-shield-off: **WEP Cracking**

    Recover the WEP key directly from captured traffic; no wordlist needed. WEPWolf runs PTW, KoreK, FMS, and RC4-bias attacks in one command.

    [:octicons-arrow-right-24: WEP Cracking Guide](wep.md)

- :material-wifi-lock: **WPA/WPA2 Cracking**

    Capture a PMKID or handshake, extract hashes with WPAWolf, crack with hashcat. Covers all PBKDF2-based PSK networks (AKM 2, 4, 6).

    [:octicons-arrow-right-24: WPA/WPA2 Cracking Guide](wpa.md)

- :material-badge-account: **WPA-Enterprise (EAP)**

    Capture enterprise credentials via a rogue AP (PEAP/MSCHAPv2) or passive sniffing (EAP-MD5, LEAP). Crack with hashcat mode 5500 or 4800.

    [:octicons-arrow-right-24: WPA-Enterprise Guide](eap.md)

</div>

!!! tip "Background reading"
    For protocol details behind these attacks, see the [Protocol Overview](../protocol/index.md) and the [Security Matrix](../protocol/security-matrix.md).
