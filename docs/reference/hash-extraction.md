# Hash Extraction Reference

## WPA Hash Line Formats

### WPA*01 (PMKID)

```
WPA*01*PMKID*MAC_AP*MAC_STA*ESSID
```

Placeholder for field-by-field documentation with data types, encoding, and
example values.

### WPA*02 (EAPOL)

```
WPA*02*MIC*MAC_AP*MAC_STA*ESSID*NONCE*EAPOL*MP
```

Placeholder for field-by-field documentation, noting the message pair byte
encoding and EAPOL frame content.

### WPA*03 and WPA*04 (Deprecated)

These formats were used by older hcxtools versions. WPA*03 carried PMKID data
and WPA*04 carried EAPOL data in a different field arrangement. Both are
superseded by WPA*01 and WPA*02. Placeholder for legacy format reference.

## hashcat Mode Reference

| Mode | Hash Type | Format Source |
|------|-----------|--------------|
| 22000 | WPA-PBKDF2-PMKID+EAPOL | WPA*01 / WPA*02 |
| 22001 | WPA-PMK-PMKID+EAPOL | Pre-computed PMK variants |
| 37100 | WPA3-SAE-PMKID | SAE-specific PMKID |
| 5500 | NetNTLMv1 / MSCHAPv2 | username::::response:challenge |
| 4800 | iSCSI CHAP / EAP-MD5 | hash:id:challenge |

## EAPOL Size Constraints

hashcat imposes size limits on the EAPOL frame field in WPA*02 hash lines.
Placeholder for documentation of the maximum EAPOL frame size, truncation
behavior, and the impact on Key Data-heavy M3 frames.

## EAP Hash Formats

### NetNTLMv1 (Mode 5500)

```
username::::NT-Response:challenge
```

Placeholder for field encoding details, noting the empty LM fields and the
challenge construction from authenticator + peer challenges.

### EAP-MD5 (Mode 4800)

```
md5_response:identifier:challenge
```

Placeholder for field encoding details and example hash lines.
