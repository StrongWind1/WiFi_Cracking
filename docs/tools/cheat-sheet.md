# Cheat Sheet

### Capture and Crack Workflow

```
1. CAPTURE
   hcxdumptool -> capture.pcapng

2. CHECK FOR FT-PSK (802.11r) NETWORKS
   tshark -r capture.pcapng -Y "wlan.rsn.akms.type == 4" \
       -T fields -e wlan.sa -e wlan.ssid | sort -u

3. CONVERT
   hcxpcapngtool -o hashes.22000 capture.pcapng       # standard WPA
   hcxpcapngtool -o hashes.22000 -f hashes.37100 \    # also extract FT
       capture.pcapng

4. DEDUP (important: dedup by crackable content, not full line)
   awk -F'*' '!seen[$3,$4,$5,$6,$7,$8]++' hashes.22000 > unique.22000

5. CHECK WHAT YOU GOT
   python3 mp_print.py unique.22000                    # decode message pairs
   hcxhashtool -i unique.22000 --info                  # detailed hash info

6. CRACK
   hashcat -m 22000 unique.22000 wordlist.txt          # passphrase attack
   hashcat -m 22001 unique.22000 pmk_list.txt          # pre-computed PMK attack
   hashcat -m 37100 hashes.37100 wordlist.txt          # FT-PSK (mode 37100)
```

### Detecting Network Types with tshark

```bash
# AKM type 2 = standard PSK (mode 22000)
# AKM type 4 = FT-PSK / 802.11r (mode 37100)
# AKM type 6 = PSK-SHA256 / 802.11w (mode 22000, keyver 3)
# AKM type 8 = SAE / WPA3 (not crackable offline)

# List all WPA networks and their AKM types:
tshark -r capture.pcap -Y "wlan.rsn.akms.type" \
    -T fields -e wlan.sa -e wlan.ssid -e wlan.rsn.akms.type \
    2>/dev/null | sort -u

# Batch scan a directory:
for f in /path/to/pcaps/*.pcap; do
    count=$(tshark -r "$f" -Y "wlan.rsn.akms.type == 4" 2>/dev/null | wc -l)
    [ "$count" -gt 0 ] && echo "$f: $count FT-PSK frames"
done
```

### Useful Commands

Do not clean pcaps with wpaclean (removes useful frames). Do not merge pcapng
files (destroys metadata). Do not filter during capture.

**Convert with ESSID wordlist extraction** (pulls ESSIDs and identities into
a wordlist for targeted cracking):
```bash
hcxpcapngtool -o hash.hc22000 -E wordlist dumpfile.pcapng
hashcat -m 22000 hash.hc22000 wordlist
```

**Filter hash files:**
```bash
# By type
grep 'WPA\*01' hash.hc22000 > pmkid_only.hc22000
grep 'WPA\*02' hash.hc22000 > eapol_only.hc22000
hcxhashtool -i hash.hc22000 --type=1 -o pmkid_only.hc22000
hcxhashtool -i hash.hc22000 --type=2 -o eapol_only.hc22000

# By authorization status
hcxhashtool -i hash.hc22000 --authorized -o authorized.hc22000
hcxhashtool -i hash.hc22000 --challenge -o challenge.hc22000

# By MAC address
hcxhashtool -i hash.hc22000 --mac-ap=112233445566 -o target_ap.hc22000
hcxhashtool -i hash.hc22000 --mac-client=112233445566 -o target_sta.hc22000
```

**Online converter** (no need to compile hcxtools):
https://hashcat.net/cap2hashcat/

### What Determines Cracking Speed

| Step | Operations per guess | Relative Cost |
|------|---------------------|---------------|
| PBKDF2-SHA1 (PMK) | 8192 HMAC-SHA1 calls | **~99.9%** of total time |
| PTK derivation | 1-3 HMAC calls | ~0.05% |
| MIC verification | 1 HMAC or AES-CMAC call | ~0.05% |

The PBKDF2 step dominates everything. Cracking speed is measured in PMKs/second
and is essentially identical regardless of keyver (1, 2, or 3). Mode 22001
eliminates PBKDF2 entirely, making it limited only by PTK + MIC speed.
