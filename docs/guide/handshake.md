# Handshake Attack

<!-- TODO: rewrite from v1 into a concise walkthrough -->
<!-- Source material: docs/old/attacks/eapol.md, docs/old/attacks/message-pairs.md -->
<!-- Link to Reference: psk-attacks/eapol.md -->

The handshake attack captures messages from the WPA/WPA2 4-way handshake and
uses them to verify password guesses offline. Unlike PMKID, this requires a
client to be connected (or connecting) to the network.

## How it works

During the 4-way handshake, the client proves it knows the password by
computing a MIC (Message Integrity Code) over the handshake data. An attacker
captures these messages, then tries passwords offline — computing the expected
MIC for each guess and comparing.

## Step 1 — Capture the handshake

Follow the [Capturing traffic](capturing.md) steps. Wait for a client to
connect, or send a deauth to force a reconnection:

```bash
# Wait for airodump-ng to show "WPA handshake: <BSSID>"
```

## Step 2 — Extract the hash

```bash
hcxpcapngtool -o hashes.22000 capture-01.pcapng
```

Look for `WPA*02*` lines — these are EAPOL handshake hashes.

## Step 3 — Crack with hashcat

```bash
hashcat -m 22000 hashes.22000 wordlist.txt
```

## Message pairs

Not all handshake captures are equal. hcxpcapngtool extracts the best
available message combination automatically. The key requirement is having
at least one message from the AP and one from the client that share the
same ANonce/SNonce pair.

!!! tip "Deep dive"
    See the [EAPOL attack reference](../psk-attacks/eapol.md) for message pair
    theory, the N#E# naming convention, and the 12→6→3 hash collapse.
