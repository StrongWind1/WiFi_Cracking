# wpawolf

Pure-Rust rewrite of hcxpcapngtool. Reads pcap, pcapng, and gzip captures and emits hashcat mode 22000 and 37100 hash lines. Covers WPA1, WPA2, and WPA3 PSK-family handshake extraction plus PMKID extraction from every spec-defined location.

## Why wpawolf

wpawolf addresses several architectural limitations of hcxpcapngtool:

| Behaviour | hcxpcapngtool | wpawolf |
|---|---|---|
| Pairing strategy | Stream-pairs as frames arrive | Collect-then-pair (reads everything, then pairs) |
| EAPOL frame size ceiling | 255 bytes (`EAPOL_AUTHLEN_OLD_MAX`) | No size gate — emits every valid EAPOL-Key frame |
| Per-(AP, STA) message buffer | Shared 64-entry circular buffer | `HashMap<(AP, STA), Vec<Message>>`, no eviction |
| WDS / 4-address relay frames | Skipped unless `--all` | Always processed |
| State across input files | Reset between files | Carried across files (cross-file pairing) |
| EAPOL session window | 5 seconds default | Unlimited default; `--eapoltimeout` opts in |
| PMKID extraction sites | M1 KDE + M2 RSN IE | 20 spec-defined locations (M1/M2/AssocReq/ReassocReq/FT Auth/FT Action/Beacon/ProbeResp/Mesh/OSEN) |
| Dedup | Look-back ring + write-time dedup | Global SipHash set (cross-file, cross-session) |
| Parallelism | Single-threaded | Rayon work-stealing (`--threads N`) |
| Memory pressure | OOM on large captures | Disk-backed fallback at 80% RAM |

The collect-then-pair architecture means wpawolf cannot miss a valid pair regardless of message ordering or interleaving. hcxpcapngtool's 64-entry ring silently drops the oldest message when the 65th arrives without a successful pair.

## Hash Output

| Flag | What it writes | hashcat mode | Format |
|---|---|---|---|
| `--22000-out FILE` | Non-FT PSK hashes | 22000 | `WPA*01*` (PMKID), `WPA*02*` (EAPOL) |
| `--37100-out FILE` | FT-PSK hashes | 37100 | `WPA*03*` (FT PMKID), `WPA*04*` (FT EAPOL) |
| `-o FILE` | All hashes, per-AKM 11-type format | proposed 22002/22003 | `WPA*01*` through `WPA*11*` |
| `--wpa1-out FILE` | WPA1-PSK only | — | `WPA*01*` |
| `--wpa2-out FILE` | WPA2-PSK only | — | `WPA*02*`, `WPA*03*` |
| `--psk-sha256-out FILE` | PSK-SHA256 only | — | `WPA*04*`, `WPA*05*` |
| `--ft-out FILE` | FT-PSK only | — | `WPA*06*`, `WPA*07*` |
| `--psk-sha384-out FILE` | PSK-SHA384 only | — | `WPA*08*`, `WPA*09*` |
| `--ft-psk-sha384-out FILE` | FT-PSK-SHA384 only | — | `WPA*10*`, `WPA*11*` |

The legacy sinks (`--22000-out`, `--37100-out`) produce lines that current hashcat reads. The per-AKM sinks (`-o` and the six per-family flags) use an 11-prefix format that no current hashcat mode reads — proposed modes 22002/22003 are sketched in the wpawolf docs.

SHA-384 hashes (types 8-11) are deliberately suppressed from the legacy sinks because their 24-byte MIC does not fit the 16-byte `<mic>` field.

## Auxiliary Outputs

| Flag | Description |
|---|---|
| `-E FILE` | Unique ESSIDs from AP management frames |
| `-R FILE` | Unique ESSIDs from Probe Request frames |
| `-W FILE` | Combined wordlist (superset of -E + -R + WPS + EAP + country + vendor) |
| `-I FILE` | EAP identity strings |
| `-U FILE` | EAP peer-identity (inner username) strings |
| `-D FILE` | WPS device info (tab-separated, sorted by manufacturer) |
| `--log FILE` | Structured processing log |

## Output Options

wpawolf splits output options into two categories:

**Reduction** options fold redundant lines per MIC and never drop a crackable hash:

| Flag | Default | Meaning |
|---|---|---|
| `--smart` | off | Recommended. Emit ~one line per MIC instead of the full cross-product. Implies `--dedup-hash-combos` + `--nc-dedup` |
| `--dedup-hash-combos` | off | 6 N#E# combos to 3 unique per session |
| `--nc-dedup` | off | Fold near-identical-nonce siblings into one survivor |
| `--collapse-message-pair` | off | Drop message-pair byte from dedup identity |

**Filter** options can drop crackable hashes — use with caution:

| Flag | Default | Effect |
|---|---|---|
| `--strict` | off | Bundle of tight filters. Drops thousands of crackable MICs in large captures. Prefer `--smart` |
| `--eapoltimeout N` | unlimited | Discard pairs more than N seconds apart |
| `--rc-drift N` | off | Discard pairs with replay-counter delta > N |
| `--max-eapol-per-type N` | off | Cap pairing to first N messages of each type per (AP, STA) |

## Typical Workflow

```bash
# Legacy 22000 + 37100 (what hashcat cracks today)
wpawolf --22000-out hashes.22000 --37100-out hashes.37100 *.pcap

# Combined per-AKM output (all 11 types)
wpawolf -o all-hashes.out *.pcap

# Per-AKM split for triage
wpawolf --wpa2-out wpa2.out --ft-out ft.out --psk-sha384-out psk384.out capture.pcapng.gz

# Maximum extraction with all auxiliaries
wpawolf --22000-out h.22000 --37100-out h.37100 -o all.out \
        -E essids.txt -R probes.txt -W wordlist.txt \
        -I identities.txt -U usernames.txt -D devices.txt \
        --log run.log captures/*

# Recommended: smart mode (fewer lines, zero MIC loss)
wpawolf --22000-out hashes.22000 --smart captures/
```

At least one output flag is required; wpawolf exits without doing any work if no output is configured.

## Installation

### Prebuilt binaries

Download from [GitHub Releases](https://github.com/StrongWind1/WPAWolf/releases). Static musl binaries for Linux x86_64 and arm64, macOS universal (arm64 + x86_64), and Windows (MSVC + GNU).

### From source

```bash
git clone https://github.com/StrongWind1/WPAWolf
cd WPAWolf
make release      # optimised native build -> target/release/wpawolf
```

Requires a stable Rust toolchain.

## Spec References

- Project: [github.com/StrongWind1/WPAWolf](https://github.com/StrongWind1/WPAWolf)
- Architecture: [ARCHITECTURE.md](https://github.com/StrongWind1/WPAWolf/blob/main/ARCHITECTURE.md) — 5-phase pipeline, critical invariants, 20 PMKID sites
- Hash formats: [HASHCAT-CURRENT-FORMATS.md](https://github.com/StrongWind1/WPAWolf/blob/main/HASHCAT-CURRENT-FORMATS.md) — modes 22000/37100 as hashcat reads them today
- New formats: [HASHCAT-NEW-FORMATS.md](https://github.com/StrongWind1/WPAWolf/blob/main/HASHCAT-NEW-FORMATS.md) — the 11-type per-AKM classification
