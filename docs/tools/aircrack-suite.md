# Aircrack-ng Suite

## Overview

Aircrack-ng is an open-source suite of tools for 802.11 wireless security
assessment. It covers the full workflow from monitor mode setup through packet
capture, traffic injection, and key recovery for both WEP and WPA networks.

## airmon-ng (Monitor Mode)

Sets the wireless interface into monitor mode, enabling raw 802.11 frame capture.
Placeholder for usage details including process killing (`airmon-ng check kill`),
interface renaming behavior, and verification commands.

## airodump-ng (Capture)

Captures raw 802.11 frames and displays a live summary of visible networks and
associated clients. Placeholder for key options: channel selection, BSSID filter,
output format (pcap, CSV, kismet), and GPS logging.

## aireplay-ng (Injection)

Injects crafted 802.11 frames to stimulate traffic or force client behavior.
Placeholder for the main attack modes: deauthentication, fake authentication,
ARP replay, ChopChop, fragmentation, and interactive injection.

## aircrack-ng (Key Recovery)

Performs key recovery against captured data. For WEP, it uses statistical attacks
(PTW, FMS/KoreK) on collected IVs. For WPA, it performs dictionary attacks
against captured EAPOL handshakes. Placeholder for key options: dictionary file,
BSSID selection, and key index.

## Common Flags

Placeholder for a quick-reference table of the most frequently used flags across
all tools in the suite, organized by tool.
