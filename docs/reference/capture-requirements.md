# Capture Requirements

## PSK Capture Requirements

### PMKID Extraction

Requires a single EAPOL M1 frame containing a PMKID in its RSN IE Key Data.
Additionally, the BSSID, STA MAC, and SSID must be known (from beacon or
probe response frames in the same capture).

### EAPOL Handshake Extraction

Requires at least two EAPOL-Key frames forming a valid message pair (e.g., M1+M2).
The capture must also contain the SSID (from beacons or probe responses).
Placeholder for a detailed field source table.

## EAP Capture Requirements

### MSCHAPv2 (PEAP/EAP-TTLS)

Requires the EAP-Identity, authenticator challenge, peer challenge, and NT-Response.
These are typically captured from a rogue AP log rather than a passive pcap, since
the exchange occurs inside a TLS tunnel. Placeholder for field size and format details.

### EAP-MD5

Requires the EAP identifier, challenge value, and MD5 response. These travel in
cleartext EAP packets and can be captured passively. Placeholder for field details.

### LEAP

Requires the AP challenge, peer response, and username. LEAP exchanges are
unencrypted and visible in passive captures. Placeholder for field details.

## WEP Capture Requirements

WEP cracking requires a large number of data frames encrypted with unique IVs.
The PTW attack needs ARP-sized frames (typically obtained via injection). The
FMS/KoreK attacks work with any data frames. Placeholder for minimum IV counts
per attack type.

## Field Sources

Placeholder for a comprehensive table mapping each required field to its source
frame type (beacon, probe response, EAPOL M1-M4, EAP-Identity, data frame) and
the relevant protocol header offset.
