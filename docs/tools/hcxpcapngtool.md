# hcxpcapngtool Options

### Hash Combo Naming Convention

Each WPA hash is built from two messages: one provides the EAPOL frame (MIC +
embedded nonce), the other provides the external nonce not present in the frame.

Multiple naming conventions exist across tools and documentation:

```
N#E# (this guide):  N{nonce_source}E{eapol_source}     e.g. N1E2
Verbose:            eapol=M{e} nonce=M{n}               e.g. eapol=M2 nonce=M1
Educational:        M{e}({embedded}+MIC) + M{n}({ext})  e.g. M2(SNonce+MIC) + M1(ANonce)
```

### Options Reference

| Option | Default | What It Controls |
|--------|---------|-----------------|
| `--all` | off | Master switch: disables dedup, adds N2E3/N4E3, includes relayed/zeroed-PSK/bad-FCS frames |
| `--nonce-error-corrections=N` | 0 | Max replay counter gap between paired messages. 0 = exact match only. |
| `--eapoltimeout=N` | 5000 (ms) | Max time gap between paired messages. |
| `--ignore-ie` | off | Bypass AKM checks (process non-PSK APs, PSK-SHA256 mismatches). |

### What Default Mode Does

With no flags, hcxpcapngtool:

1. **Generates only 4 combo types**: N1E2, N1E4, N3E2, N3E4 (not N2E3/N4E3)
2. **Requires exact RC match**: rcgap must be 0 (no nonce error tolerance)
3. **Enforces 5-second timeout**: messages more than 5s apart are not paired
4. **Deduplicates to 1 hash per AP/STA pair**: keeps the "best" (smallest time gap)
5. **Skips relayed frames**: WDS/relayed EAPOL messages are dropped
6. **Skips zeroed PSK/PMK**: hashes that verify against empty passphrase are dropped
7. **Checks AKM from beacons**: only PSK/PSK-SHA256/FT-PSK APs produce hashes

### What `--all` Enables

1. **Adds N2E3 and N4E3 combo types** (EAPOL from M3 with external SNonce)
2. **Disables per-AP/STA deduplication**: writes ALL pairs, not just the best
3. **Includes relayed/WDS frames**
4. **Includes zeroed PSK/PMK hashes**
5. **Includes bad FCS frames**
6. Combined with NC>0, this produces the maximum number of hash lines

### What `--nonce-error-corrections=N` Does

Allows pairing messages where the replay counter differs by up to N from the
expected value. This compensates for:
- AP firmware bugs that increment the nonce counter between derivation and transmission
- Packet loss causing retransmitted M1/M3 with bumped counters
- Multiple interleaved handshake attempts

When NC>0, the sort order changes: "best" pair is determined by smallest RC gap
(instead of smallest time gap). The message_pair byte gets bit 7 set (0x80)
to tell hashcat that nonce error correction may be needed.

### Options Matrix (tested results)

| Pcap | Messages | Unique | default | --all | NC=8+all |
|------|----------|--------|---------|-------|----------|
| A | 1/1/1/1(nz) | 3e | 1e/0p | 6e/0p | 6e/0p |
| B | 1/1/1/1(z) | 2e | 1e/0p | 3e/0p | 3e/0p |
| C | 5/5/8/4(z) | 45e | 1e/1p | 20e/5p | 51e/5p |
| D | 15/1/2/1(z) | 8e | 1e/0p | 3e/0p | 10e/0p |

Messages format: M1/M2/M3/M4 count, (nz)=non-zero M4 nonce, (z)=zeroed.
Output format: {EAPOL}e/{PMKID}p.

Key observations:
- **`--all` has the biggest impact** (6x-20x more hashes) because it disables dedup
- **NC only matters with `--all`**: without `--all`, dedup limits output to 1 per pair anyway
- **`--eapoltimeout` and `--ignore-ie` had no effect** on these test captures
- **Default mode under-extracts** because of dedup (1 per AP/STA), strict RC
  matching, and only 4 of 6 combo types.
