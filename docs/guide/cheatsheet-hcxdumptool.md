# hcxdumptool Quick Reference

## Capture

```bash
# Standard capture (PMKID solicitation + passive handshakes)
sudo hcxdumptool -i wlan0 -w capture.pcapng -A --rds=1

# Time-limited (2 minutes)
sudo hcxdumptool -i wlan0 -w capture.pcapng -A --rds=1 --tot=2

# Exit on first PMKID or handshake
sudo hcxdumptool -i wlan0 -w capture.pcapng -A --exitoneapol=7

# Quick channel scan (1 minute, no capture file)
sudo hcxdumptool -i wlan0 --tot=1 --rcascan=active

# Headless / daemonized capture (no display output)
sudo hcxdumptool -i wlan0 -w capture.pcapng -A --rds=0 --daemonize
```

| Flag | Purpose |
|------|---------|
| `-i wlan0` | Monitor-mode interface |
| `-w FILE` | Write packets to pcapng file |
| `-c CHAN` | Set channel (e.g. `1a`, `6a`, `11a`, `36b`) |
| `-f FREQ` | Set frequency |
| `-F` | Scan all available frequencies from interface |
| `-t SEC` | Minimum stay time on a channel (seconds) |
| `-A` | ACK incoming frames (active monitor mode; needed for PMKID solicitation) |
| `--rds=N` | Real time display mode (0=off/headless, 1-4=various displays) |
| `--tot=N` | Timeout in **minutes** (not seconds) |
| `--exitoneapol=N` | Exit on first EAPOL (bitmask: 1=PMKID, 2=M1M2M3, 4=M1M2, 8=M1M2ROGUE, 16=M1) |
| `--daemonize` | Run as daemon (suppresses status messages) |
| `--disable_disassociation` | Do not transmit DISASSOCIATION frames |

## Target Filtering

hcxdumptool uses Berkeley Packet Filters (BPF) for target filtering. Compile a BPF filter with `--bpfc`, then load it with `--bpf`.

```bash
# Compile a BPF filter to capture only a specific BSSID
sudo hcxdumptool --bpfc="ether host 11:22:33:44:55:66"

# Save the compiled BPF output to a file, then use it
sudo hcxdumptool --bpfc="ether host 11:22:33:44:55:66" --bpfd=0 > target.bpf
sudo hcxdumptool -i wlan0 -w capture.pcapng -A --bpf=target.bpf

# Filter by multiple BSSIDs
sudo hcxdumptool --bpfc="ether host 11:22:33:44:55:66 or ether host aa:bb:cc:dd:ee:ff"
```

Note: `--bpfc` and `--bpfd` require hcxdumptool to be built with libpcap support.

## Check AKM Types (tshark)

```bash
# List all AKM types in a capture
tshark -r capture.pcapng -Y "wlan.rsn.akms.type" \
    -T fields -e wlan.sa -e wlan.ssid -e wlan.rsn.akms.type \
    2>/dev/null | sort -u

# Check for FT-PSK (AKM 4) — needs hashcat mode 37100
tshark -r capture.pcapng -Y "wlan.rsn.akms.type == 4" \
    -T fields -e wlan.sa -e wlan.ssid \
    2>/dev/null | sort -u

# Batch scan all captures for FT-PSK
for f in captures/*.pcapng; do
    count=$(tshark -r "$f" -Y "wlan.rsn.akms.type == 4" 2>/dev/null | wc -l)
    [ "$count" -gt 0 ] && echo "$f: $count FT-PSK frames"
done
```

## AKM Type Reference

| AKM | Authentication | hashcat mode |
|-----|---------------|--------------|
| 2 | PSK | 22000 |
| 4 | FT-PSK | 37100 |
| 6 | PSK-SHA256 | 22000 |
| 8 | SAE (WPA3) | not crackable |

## Monitor Mode Setup

```bash
# List available wireless interfaces
sudo hcxdumptool -L

# List interfaces (tab-separated, greppable)
sudo hcxdumptool -l

# Show detailed interface info
sudo hcxdumptool -I wlan0

# Set monitor mode via hcxdumptool
sudo hcxdumptool -m wlan0

# Verify adapter supports monitor mode
iw phy phy0 info | grep -A 5 "Supported interface modes"

# Manual monitor mode (if hcxdumptool -m doesn't work for your adapter)
sudo ip link set wlan0 down
sudo iw dev wlan0 set type monitor
sudo ip link set wlan0 up
```

[Adapter setup guide](adapters.md) -- [WPA cracking guide](wpa.md)
