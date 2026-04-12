# EAPOL Attack (MIC Verification)

## Overview

The EAPOL MIC-based attack captures messages from the WPA/WPA2 4-way handshake
and verifies candidate passphrases by recomputing the MIC field. This is the
traditional WPA cracking method and works against all PSK-based AKM suites.

## What Each Message Contains

Placeholder for a table describing the key fields carried in each of the four
EAPOL-Key messages: ANonce, SNonce, MIC, encrypted GTK, Key Data, and the
direction of each message.

## What Hashcat Needs

To verify a candidate passphrase, hashcat requires: the ANonce, SNonce, AP MAC (AA),
STA MAC (SPA), SSID, and at least one MIC-bearing frame with its associated replay
counter. Placeholder for detailed field requirements per hash format.

## The Hashcat 22000 Hash Line

The WPA*02 hash line encodes all fields needed for EAPOL-based cracking in a single
colon-delimited string. Placeholder for field-by-field breakdown of the format.

## 12 Theoretical Combinations

Given four handshake messages and the need for a nonce-bearing message plus a
MIC-bearing message, there are 12 theoretical pairings. Placeholder for the
full enumeration of these combinations.

## Why 12 Collapses to 6

Half the combinations are eliminated because the MIC must be verifiable against
a known nonce. Placeholder for the reasoning and a reduction table.

## Master Comparison Table

Placeholder for a table listing all valid message pair combinations with their
properties: which message provides the MIC, which provides the nonce, replay
counter relationship, and the message pair bitmask value.

## Why 6 Collapses to 3

Placeholder for the explanation of why certain pairs are equivalent from a
cracking perspective, reducing the effective set to three distinct verification
paths.

## Why N1E2 Is Preferred

Message pair N1E2 (ANonce from M1, MIC from M2) is preferred because it uses the
earliest frames, avoids encrypted key data, and has the most reliable replay
counter relationship. Placeholder for detailed justification.

## Higher Bits of Message Pair Byte

The message pair byte in the hashcat 22000 format encodes additional flags in its
upper bits. Placeholder for a bitfield diagram covering AP-less, LE, BE, and NC
flags.

## Nonce Error Correction

Some implementations increment the replay counter between M1 and M2, causing a
nonce mismatch. hashcat supports nonce error correction to handle this.
Placeholder for details on the correction range and performance impact.
