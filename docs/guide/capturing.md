# Capturing Traffic

<!-- TODO: rewrite from v1 into a linear walkthrough -->
<!-- Source material: docs/old/reference/capture-requirements.md -->
<!-- Link to Reference: reference/capture-requirements.md, tools/aircrack-suite.md -->

## Prerequisites

- A wireless adapter that supports **monitor mode**
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

This writes capture files to `capture-01.pcapng` (and other formats).

## What you need to capture

| Attack | What to look for | How to tell |
|--------|-----------------|-------------|
| PMKID | AP's first message (M1) with PMKID in RSN IE | airodump shows the AP |
| Handshake | Complete 4-way handshake | airodump shows "WPA handshake: \<BSSID\>" |

!!! tip "Capture details"
    See [Capture requirements](../reference/capture-requirements.md) for the
    exact frame combinations needed per attack type.

## Next steps

With a capture file in hand:

- Try the [PMKID attack](pmkid.md) first (no client needed)
- If that doesn't work, go for the [Handshake attack](handshake.md)
