# PMKID Attack (Clientless)

### Attack A: PMKID (Clientless)

- **Requires**: Only M1 from the AP (no client needed, no full handshake)
- **How**: The AP includes a PMKID in M1's Key Data field. The PMKID is a hash
  of the PMK, so it can be verified against password guesses.
- **Limitation**: Not all APs include a PMKID in M1. Depends on whether the AP
  has a cached PMKSA.
