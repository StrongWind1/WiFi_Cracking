# Capturing Traffic

## Prerequisites

- A wireless adapter that supports **monitor mode** (a special adapter mode that captures all nearby WiFi traffic, not just traffic to/from your machine)
- Linux (Kali, Parrot, or any distro with aircrack-ng installed)

## Step 1 — Enable monitor mode

```bash
sudo airmon-ng check kill    # stop interfering processes
sudo airmon-ng start wlan0   # enable monitor mode
```

Your interface is now `wlan0mon` (or similar).

## Step 2 — Scan for networks

```bash
sudo airodump-ng wlan0mon
```

Find your target network. Note the **BSSID** (MAC address) and **channel**.

## Step 3 — Capture on the target channel

```bash
sudo airodump-ng -c <channel> --bssid <BSSID> -w capture wlan0mon
```

This writes a pcapng (packet capture file format) file to `capture-01.pcapng` and related output files.

## What you need to capture

| Attack | What to look for | How to tell |
|--------|-----------------|-------------|
| PMKID | AP's first message (M1) with PMKID in RSN IE | airodump shows the AP |
| Handshake | Complete 4-way handshake | airodump shows "WPA handshake: \<BSSID\>" |

!!! tip "Capture details"
    See [Capture requirements](../reference/capture-requirements.md) for the
    exact frame combinations needed per attack type.

**Next:** [PMKID attack](pmkid.md)
