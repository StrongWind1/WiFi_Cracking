# Guide

A step-by-step walkthrough for cracking WiFi passwords — from zero knowledge
to recovered passphrase. Each page builds on the previous one.

## What you need

- A Linux system (Kali Linux recommended)
- A WiFi adapter that supports monitor mode
- aircrack-ng suite (`sudo apt install aircrack-ng`)
- hcxtools (`sudo apt install hcxtools`) or [wpawolf](https://github.com/StrongWind1/WPAWolf)
- hashcat (`sudo apt install hashcat`) with GPU drivers for reasonable speed
- A wordlist (e.g., `rockyou.txt`, typically at `/usr/share/wordlists/rockyou.txt` on Kali)

<div class="grid cards" markdown>

- :material-wifi: **How WiFi passwords work**

    Brief overview of WPA/WPA2 security and why passwords are crackable offline.

    [:octicons-arrow-right-24: How WiFi passwords work](how-wifi-works.md)

- :material-access-point: **Capturing traffic**

    Put your adapter in monitor mode and capture the data you need.

    [:octicons-arrow-right-24: Capturing traffic](capturing.md)

- :material-key-variant: **PMKID attack**

    The fastest path — grab a PMKID from a single beacon, no client needed.

    [:octicons-arrow-right-24: PMKID attack](pmkid.md)

- :material-handshake: **Handshake attack**

    Capture a 4-way handshake between an AP and client, then crack it offline.

    [:octicons-arrow-right-24: Handshake attack](handshake.md)

- :material-file-export: **Extracting hashes**

    Convert your capture file into a hash that cracking tools understand.

    [:octicons-arrow-right-24: Extracting hashes](extracting.md)

- :material-hammer-wrench: **Cracking with hashcat**

    Feed the hash to hashcat with wordlists, rules, or masks to recover the password.

    [:octicons-arrow-right-24: Cracking with hashcat](cracking.md)

</div>
