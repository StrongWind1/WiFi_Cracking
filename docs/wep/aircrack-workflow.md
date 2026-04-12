# Aircrack-ng WEP Workflow

## Prerequisites

- A wireless adapter that supports monitor mode and packet injection.
- The aircrack-ng suite installed (airmon-ng, airodump-ng, aireplay-ng, aircrack-ng).
- Target network must be using WEP encryption.
- Sufficient proximity to the access point for reliable frame capture and injection.

## Step 1: Monitor Mode (airmon-ng)

Place the wireless adapter into monitor mode to capture raw 802.11 frames.
Placeholder for the airmon-ng command sequence and verification steps, including
killing interfering processes.

## Step 2: Capture (airodump-ng)

Start capturing frames on the target channel and BSSID. Write captured data to
a file for later cracking. Placeholder for the airodump-ng command with channel
lock, BSSID filter, and output file options.

## Step 3: Injection (aireplay-ng)

Accelerate IV collection by injecting ARP replay packets. This step is critical
for generating enough unique IVs in a reasonable time frame. Placeholder for
the aireplay-ng ARP replay command, fake authentication, and expected packet
rate output.

## Step 4: Crack (aircrack-ng)

Once enough IVs are captured (typically 40,000+ for PTW or 500,000+ for KoreK),
run aircrack-ng against the capture file. Placeholder for the aircrack-ng command
with PTW mode selection and expected output.

## Expected Output

A successful crack displays the WEP key in hexadecimal. Placeholder for example
output showing the key recovery result, number of IVs tested, and elapsed time.
