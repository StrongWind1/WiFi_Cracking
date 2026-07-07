# hcxdumptool Quick Reference

## Capture

```bash
# Standard capture (PMKID solicitation + passive handshakes)
sudo hcxdumptool -i wlan0 -o capture.pcapng --active_beacon --enable_status=15

# Time-limited (120 seconds)
sudo hcxdumptool -i wlan0 -o capture.pcapng --active_beacon --tot=120

# Quick scan (10 seconds, no capture file)
sudo hcxdumptool -i wlan0 --tot=10 --rcascan=active
```

| Flag | Purpose |
|------|---------|
| `-i wlan0` | Monitor-mode interface |
| `-o FILE` | Output pcapng |
| `--active_beacon` | Send beacons/assoc requests to solicit PMKIDs |
| `--enable_status=15` | Show all status messages |
| `--tot=N` | Stop after N seconds |

## Target Filtering

```bash
# Create a filterlist with target BSSIDs (one per line, no colons)
echo "112233445566" > targets.txt

# Capture only targets
sudo hcxdumptool -i wlan0 -o capture.pcapng --active_beacon \
    --filterlist_ap=targets.txt --filtermode=2
```

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
# Verify adapter supports monitor mode
iw phy phy0 info | grep -A 5 "Supported interface modes"

# Manual monitor mode (if hcxdumptool doesn't set it automatically)
sudo ip link set wlan0 down
sudo iw dev wlan0 set type monitor
sudo ip link set wlan0 up
```

[Adapter setup guide](adapters.md) -- [WPA cracking guide](wpa.md)
