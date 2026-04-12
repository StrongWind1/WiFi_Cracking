# Aircrack-ng Suite

Open-source suite for 802.11 wireless security assessment. Covers monitor mode
setup, packet capture, traffic injection, and key recovery for WEP and WPA.
See [WEP Workflow](../wep/aircrack-workflow.md) for a step-by-step procedure.

## Tool Overview

| Tool | Purpose |
|------|---------|
| airmon-ng | Enable/disable monitor mode on wireless interfaces |
| airodump-ng | Capture 802.11 frames, display live network/client summary |
| aireplay-ng | Inject 802.11 frames: deauth, fake auth, ARP replay |
| aircrack-ng | WEP key recovery (PTW/KoreK) and WPA dictionary attack |
| airdecap-ng | Decrypt WEP/WPA captured frames given the key |
| airbase-ng | Operate as a soft AP for testing |

---

## airmon-ng

```bash
# List interfaces and their driver info
airmon-ng

# Kill interfering processes (NetworkManager, wpa_supplicant)
airmon-ng check kill

# Enable monitor mode
airmon-ng start wlan0

# Enable on specific channel
airmon-ng start wlan0 6

# Disable monitor mode
airmon-ng stop wlan0mon
```

| Flag | Description |
|------|-------------|
| `check` | List processes that may interfere |
| `check kill` | Kill interfering processes |
| `start <iface>` | Enable monitor mode, creates `<iface>mon` |
| `stop <iface>` | Disable monitor mode |

---

## airodump-ng

```bash
# Scan all channels
airodump-ng wlan0mon

# Lock to channel, filter by BSSID, write to file
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon

# Show clients associated to specific BSSID
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF wlan0mon
```

| Option | Description |
|--------|-------------|
| `-c <channel>` | Lock to specific channel |
| `--bssid <mac>` | Filter to single AP |
| `-w <prefix>` | Write capture to `prefix-01.cap`, `prefix-01.csv`, etc. |
| `--band <a/b/g>` | Scan specific band (default: bg) |
| `-d <mac>` | Filter to clients with specific AP MAC |

Column definitions:

| Column | Meaning |
|--------|---------|
| BSSID | AP MAC address |
| PWR | Signal level (lower negative = stronger) |
| #Data | Unique IV count (WEP) or data frame count (WPA) |
| ENC | Encryption: WEP, WPA, WPA2, OPN |
| ESSID | Network name |
| STA | Client MAC (lower table) |

---

## aireplay-ng

```bash
# Deauthenticate clients (force reconnect to capture handshake)
aireplay-ng -0 5 -a <BSSID> wlan0mon           # 5 deauths to all clients
aireplay-ng -0 5 -a <BSSID> -c <STA> wlan0mon  # target specific client

# Fake authentication (associate adapter with AP)
aireplay-ng -1 0 -e <ESSID> -a <BSSID> -h <your_mac> wlan0mon

# ARP replay injection (WEP IV generation)
aireplay-ng -3 -b <BSSID> -h <your_mac> wlan0mon

# ChopChop decryption (WEP)
aireplay-ng -4 -b <BSSID> -h <your_mac> wlan0mon

# Fragmentation attack (WEP keystream recovery)
aireplay-ng -5 -b <BSSID> -h <your_mac> wlan0mon
```

| Attack | Flag | Use |
|--------|------|-----|
| Deauthentication | `-0 N` | Force clients to reconnect (WPA handshake capture) |
| Fake Authentication | `-1` | Associate with AP for injection |
| Interactive Replay | `-2` | Manually select a captured frame to replay |
| ARP Replay | `-3` | Replay ARP requests to generate IVs (WEP) |
| KoreK ChopChop | `-4` | Byte-by-byte decryption (WEP) |
| Fragmentation | `-5` | PRGA (keystream) recovery (WEP) |
| Caffe-Latte | `-6` | Client-side WEP attack without AP |
| WPA Migration | `-7` | WPA Migration Mode attack |
| Hirte | `-8` | Client-side ARP fragmentation (WEP) |

---

## aircrack-ng

```bash
# WEP key recovery (PTW default)
aircrack-ng capture*.cap

# WEP key recovery (KoreK, more IVs needed)
aircrack-ng -K capture*.cap

# WEP with known key length
aircrack-ng -l 13 capture*.cap    # 13 bytes = WEP-104

# WPA dictionary attack (requires 4-way handshake in capture)
aircrack-ng -w wordlist.txt -b <BSSID> capture*.cap

# Specify capture file explicitly
aircrack-ng -w wordlist.txt capture-01.cap
```

| Option | Description |
|--------|-------------|
| `-K` | Use KoreK statistical attack (WEP) instead of PTW |
| `-l <len>` | Force key length in bytes (WEP) |
| `-w <wordlist>` | Wordlist for WPA dictionary attack |
| `-b <bssid>` | Target specific AP by BSSID |
| `-e <essid>` | Target specific network by ESSID |

!!! note "WPA cracking in aircrack-ng vs hashcat"
    aircrack-ng performs WPA dictionary attacks on CPU only. For any serious
    WPA cracking, use hashcat with hcxpcapngtool extraction — GPU acceleration
    is 10-100× faster. Use aircrack-ng for WEP (where it excels) and quick
    wordlist tests; use hashcat for sustained WPA attacks.

---

## airdecap-ng

```bash
# Decrypt WEP capture given the key
airdecap-ng -w AABBCCDDEEFF0011223344 capture-01.cap

# Decrypt WPA capture given the passphrase + ESSID
airdecap-ng -e "NetworkName" -p "passphrase" capture-01.cap
```

Produces a `capture-01-dec.cap` file with decrypted frames.
