# PMKID Attack

- **Requires**: A frame containing a PMKID. For standard WPA (AKM 2/6), the
  PMKID can appear in M1, M2, Association Request, or Reassociation Request.
  For FT-PSK (AKM 4), hcxpcapngtool extracts the PMKID from M2 because only
  M2 contains all the FT IEs (MDID, R0KH-ID, R1KH-ID) needed for the FT key
  derivation chain.
- **How**: The PMKID is a hash of the PMK, so it can be verified against
  password guesses.
- **Limitation**: Not all APs include a PMKID. Depends on whether the AP has
  a cached PMKSA.
