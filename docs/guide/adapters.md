# WiFi Adapters and Linux Setup

Choosing the right WiFi adapter and Linux kernel is the foundation of everything else in this guide. A bad adapter or outdated kernel means no monitor mode, no captures, no hashes.

## What you need from an adapter

WiFi security testing requires an adapter that supports:

| Capability | What it does | Who needs it |
|---|---|---|
| **Monitor mode** | Capture all nearby 802.11 frames, not just traffic to/from your machine | Everyone |
| **Packet injection** | Transmit crafted frames (deauth, association requests) | hcxdumptool active mode, aireplay-ng |
| **Active monitor mode** | Monitor + inject simultaneously on the same interface | hcxdumptool (preferred) |
| **In-kernel driver** | Driver ships with the Linux kernel — no out-of-tree builds | Reliability, future-proofing |

Not every adapter supports all four. The recommendation below prioritizes **in-kernel MediaTek drivers** because they support all four capabilities and are actively maintained in the upstream kernel.

## Recommended chipsets

### MediaTek (recommended)

MediaTek chipsets have the best in-kernel Linux support for security testing. The `mt76` driver family covers WiFi 5 through WiFi 7:

| Chipset | WiFi gen | In-kernel driver | Monitor since | Active monitor | Recommended kernel |
|---|---|---|---|---|---|
| **MT7601U** | WiFi 4 (N), 2.4 GHz | `mt7601u` | 4.2 | Yes | 5.x+ |
| **MT7610U** | WiFi 5 (AC) | `mt76x0u` | 4.19 | Yes | 6.6+ |
| **MT7612U** | WiFi 5 (AC) | `mt76x2u` | 4.19 | Yes | 6.6+ |
| **MT7663U** | WiFi 5 (AC) | `mt7663u` | 5.8 | Yes | 6.6+ |
| **MT7921AU** | WiFi 6E (AXE) | `mt7921u` | 5.18 | Yes | 6.6+ |
| **MT7925U** | WiFi 7 (BE) | `mt7925u` | 6.7 | Yes | 7.0+ |

**Popular adapters using these chipsets:**

- **ALFA AWUS036ACM** — MT7612U, WiFi 5, dual-band, widely available. The workhorse for WPA testing.
- **ALFA AWUS036AXML** — MT7921AU, WiFi 6E, tri-band. Newer, faster, but check kernel notes below.
- **Netgear A8000** — MT7921AU, WiFi 6E. Compact USB-A form factor.
- **Adapters with MT7925U** — WiFi 7 capable, newest generation. Requires kernel 7.0+.

### Realtek (monitor mode, no active monitor)

Realtek has three in-kernel driver families in kernel 7.1.3. Monitor mode support varies significantly by driver — unlike MediaTek's mt76, most Realtek drivers do **not** explicitly register `NL80211_IFTYPE_MONITOR` in their interface modes or implement dedicated monitor-mode RX filter configuration. Where monitor mode works, it relies on mac80211 providing default behavior. **None support active monitor mode** — hcxdumptool can only passively capture, not actively solicit PMKIDs.

!!! warning "Realtek monitor mode is best-effort"
    Only `rtw89` (WiFi 6/6E) and `rtl8187` (WiFi 3) have explicit monitor mode code in the kernel driver. For `rtw88` and `rtl8xxxu`, monitor mode depends on mac80211 defaults and may not capture all frames on all chipsets. Test with `tcpdump -i wlan0mon` before relying on a Realtek adapter for security testing.

**rtw88 — WiFi 5 (AC)** — the most complete Realtek USB driver as of kernel 7.1.3:

| Chipset | Config | WiFi gen | Monitor mode | Notes |
|---|---|---|---|---|
| RTL8812AU | `RTW88_8812AU` | WiFi 5 (AC) | Yes | **New in recent kernels.** Popular pentesting chipset (ALFA AWUS036ACH) — previously required out-of-tree drivers |
| RTL8814AU | `RTW88_8814AU` | WiFi 5 (AC) | Yes | **New in recent kernels.** 4x4 MIMO |
| RTL8821AU/8811AU | `RTW88_8821AU` | WiFi 5 (AC) | Yes | **New in recent kernels.** |
| RTL8822BU | `RTW88_8822BU` | WiFi 5 (AC) | Yes | |
| RTL8822CU | `RTW88_8822CU` | WiFi 5 (AC) | Yes | |
| RTL8821CU | `RTW88_8821CU` | WiFi 5 (AC) | Yes | |
| RTL8723DU | `RTW88_8723DU` | WiFi 4 (N) | Yes | |

**rtw89 — WiFi 6/6E/7** — newer Realtek chipsets:

| Chipset | Config | WiFi gen | Monitor mode | Notes |
|---|---|---|---|---|
| RTL8852AU | `RTW89_8852AU` | WiFi 6 (AX) | Yes | Supports VIF (virtual interfaces) |
| RTL8852BU | `RTW89_8852BU` | WiFi 6 (AX) | Yes | |
| RTL8852CU | `RTW89_8852CU` | WiFi 6E (AXE) | Yes | |
| RTL8851BU | `RTW89_8851BU` | WiFi 6 (AX) | Yes | |
| RTL8922AE | `RTW89_8922AE` | WiFi 7 (BE) | Yes | PCIe only — no USB variant yet |

**Legacy Realtek:**

| Driver | Chipsets | WiFi gen | Monitor mode | Notes |
|---|---|---|---|---|
| `rtl8187` | RTL8187L, RTL8187B | WiFi 3 (B/G) | Yes (+ active) | Ancient but fully working; 2.4 GHz only |
| `rtl8xxxu` | RTL8188CU/RU/EU/FU, RTL8191CU, RTL8192CU/EU/FU, RTL8723AU/BU, RTL8710BU (aka RTL8188GU) | WiFi 4 (N) | Partial | Requires kernel 6.6+ with unmerged [patch](https://bugzilla.kernel.org/show_bug.cgi?id=217205) |
| `rtlwifi` (rtl8192cu) | RTL8192CU, RTL8188CU | WiFi 4 (N) | Limited | Older driver for same chips as rtl8xxxu; being phased out |
| `rtlwifi` (rtl8192du) | RTL8192DU | WiFi 4 (N) | Limited | Dual-band N adapter; newer rtlwifi USB addition |

**Bottom line:** Realtek adapters work for passive capture and basic monitor mode, but **none support active monitor mode**. This means hcxdumptool cannot actively solicit PMKIDs — it can only passively wait for handshakes. For active attacks, use a MediaTek adapter. The upside: the RTL8812AU/8814AU/8821AU are now in-kernel via rtw88, so you no longer need the old out-of-tree `aircrack-ng/rtl8812au` drivers.

### Ralink (now MediaTek — legacy but solid)

Ralink was acquired by MediaTek in 2011. Their chipsets use the `rt2x00` driver family, which gets monitor mode through mac80211 automatically. All are WiFi 4 (N) or older — they cannot see 5 GHz networks unless the chipset is explicitly dual-band.

| Driver | Chipsets | WiFi gen | Bands | Monitor mode | Notes |
|---|---|---|---|---|---|
| `rt2500usb` | RT2571, RT2572 | WiFi 3 (B/G) | 2.4 GHz | Yes | Very old, 11 Mbps max |
| `rt73usb` | RT2573, RT2671 | WiFi 3/4 (B/G) | 2.4 GHz | Yes | |
| `rt2800usb` | RT2870, RT3070, RT3071, RT3072 | WiFi 4 (N) | 2.4 GHz | Yes | Common in older USB dongles |
| `rt2800usb` | RT3370 | WiFi 4 (N) | 2.4 GHz | Yes | rt33xx family |
| `rt2800usb` | **RT3572, RT3573** | WiFi 4 (N) | **Dual-band** | Yes | The best Ralink for pentesting — 2.4 + 5 GHz |
| `rt2800usb` | RT5370, RT5372 | WiFi 4 (N) | 2.4 GHz | Yes | rt53xx family, very common in cheap dongles |
| `rt2800usb` | **RT5572** | WiFi 4 (N) | **Dual-band** | Yes | Dual-band variant of RT5370; used in ALFA AWUS051NH v2 |

All rt2x00 drivers support monitor mode and packet injection via mac80211. The dual-band chipsets (RT3572, RT3573, RT5572) are the most useful since they can capture both 2.4 GHz and 5 GHz traffic.

### Other legacy (still works)

| Chipset | Driver | WiFi gen | Monitor | Injection | Notes |
|---|---|---|---|---|---|
| Atheros AR9271 | `ath9k_htc` | WiFi 4 (N) | Yes | Yes | Rock-solid. 2.4 GHz only. The classic pentesting adapter (ALFA AWUS036NHA) |
| Intersil ISL38xx | `p54usb` | WiFi 3/4 | Yes | Yes | Prism54-based |
| ZyDAS ZD1211/B | `zd1211rw` | WiFi 3 | Yes | Limited | Very old, mostly historical |

These still work and are well-tested, but they are WiFi 4 or older — they cannot see 5 GHz or 6 GHz networks.

## Linux kernel requirements

### Why the kernel version matters

WiFi adapter drivers ship inside the Linux kernel. A newer kernel = newer drivers with more chipset support and bug fixes. The kernel also contains the `mac80211` subsystem (the WiFi stack that provides monitor mode) and the `cfg80211/nl80211` interface that hcxdumptool uses.

### Current kernel status

Check your kernel version:

```bash
uname -r
```

As of July 2026 ([kernel.org](https://kernel.org)):

| Kernel | Status | MediaTek mt76 monitor mode | Notes |
|---|---|---|---|
| 5.x | EOL (5.15 LTS still maintained) | MT7612U works; MT7921AU limited | Missing many fixes |
| **6.6 LTS** | Longterm (6.6.144) | Works up to 6.6.40; **broken in 6.6.41+** | WiFi 7 stack changes caused mt76 regression |
| 6.8-6.11 | EOL | Broken after 6.8.12 | Same WiFi 7 regression |
| **6.12 LTS** | Longterm (6.12.95) | Use [morrownr/mt76](https://github.com/morrownr/mt76) out-of-tree driver | In-kernel driver still has issues |
| **6.18 LTS** | Longterm (6.18.38) | Fixes landing | Newest LTS branch |
| **7.1** | Latest stable (7.1.3) | In-kernel fixes; MT7925U fully supported | Best path forward |
| 7.2-rc2 | Mainline dev | Bleeding edge | For testing only |

!!! warning "mt76 monitor mode regression"
    The massive WiFi 7 modernization work in the Linux WiFi stack introduced regressions in the mt76 driver for monitor mode and frame injection. The last fully working in-kernel versions were **6.6.40** (longterm) and **6.8.12** (stable). If you're on a kernel after these versions and mt76 monitor mode is broken, use the [morrownr/mt76](https://github.com/morrownr/mt76) out-of-tree driver (supports kernels 6.12 through 7.x).

### Choosing a distro

Pick a distro that tracks recent kernels so your adapter's driver is included and up to date:

| Distro | Kernel tracking | Good for |
|---|---|---|
| **Kali Linux** (rolling) | Tracks latest stable | Security testing default; tools pre-installed |
| **Arch Linux** (rolling) | Tracks latest stable within days | Always has the newest drivers |
| **Fedora** (latest release) | Ships recent stable kernels | Good balance of stability and freshness |
| **Ubuntu** (latest non-LTS, e.g., 24.10+) | 1-2 releases behind stable | Widest hardware support; LTS releases lag behind |
| **Ubuntu LTS** (22.04, 24.04) | Backport kernels via HWE | Stable but may need `linux-generic-hwe` for newer adapters |

For MediaTek WiFi 6E/7 adapters (MT7921AU, MT7925U), you need at minimum **kernel 6.6**. If your distro ships an older kernel, either upgrade the kernel or use a rolling distro.

### Installing the morrownr/mt76 out-of-tree driver

If your kernel has the mt76 regression (6.6.41+ through ~7.1), install the fixed driver:

```bash
sudo apt install git build-essential linux-headers-$(uname -r)
git clone https://github.com/morrownr/mt76
cd mt76
make
sudo make install
sudo modprobe -r mt76x2u   # or mt7921u, whichever your adapter uses
sudo modprobe mt76x2u      # reload with the fixed driver
```

This driver tracks mainline and carries fixes before they reach your distro's kernel package.

## hcxdumptool vs aircrack-ng: why the tool matters

| | hcxdumptool | aircrack-ng (airmon-ng) |
|---|---|---|
| **Interface** | Modern nl80211 / NETLINK | Legacy Wireless Extensions (WEXT) |
| **WiFi 7 support** | Works | **Broken** — kernel blocks WEXT for WiFi 7 devices |
| **Active PMKID solicitation** | Yes (sends association requests) | No (passive only, or manual deauth) |
| **Monitor mode setup** | Handles internally | Requires `airmon-ng start wlan0` |
| **Future-proof** | Yes — nl80211 is the maintained path | WEXT is deprecated; some distros (Fedora) are dropping it |

aircrack-ng's `airmon-ng` and `aireplay-ng` scripts use WEXT (Wireless Extensions), which the Linux kernel now blocks for WiFi 7 devices. The failure can be **silent** — you get bad results without an error message. hcxdumptool uses the modern nl80211/NETLINK interface and is not affected.

For WPA testing, prefer hcxdumptool. For WEP testing (which requires injection via `aireplay-ng`), aircrack-ng is still necessary but use it with a WiFi 4/5 adapter where WEXT works.

## Quick setup checklist

```bash
# 1. Check your kernel
uname -r

# 2. Plug in your adapter and check it's recognized
lsusb | grep -i -E "mediatek|ralink|realtek|atheros"

# 3. Check the driver loaded
iw dev

# 4. Verify monitor mode support
iw phy phy0 info | grep -A 5 "Supported interface modes"
# Look for "monitor" in the list

# 5. Test monitor mode
sudo ip link set wlan0 down
sudo iw dev wlan0 set type monitor
sudo ip link set wlan0 up
sudo iw dev wlan0 info   # type should say "monitor"

# 6. Test with hcxdumptool (quick scan, 10 seconds)
sudo hcxdumptool -i wlan0 --tot=10 --rcascan=active
```

If step 5 fails, your kernel or driver doesn't support monitor mode for this adapter. Check the kernel version table above and consider upgrading or using the morrownr/mt76 out-of-tree driver.

## References

- [morrownr/USB-WiFi](https://github.com/morrownr/USB-WiFi) — comprehensive USB WiFi adapter guide with in-kernel driver status
- [morrownr/mt76](https://github.com/morrownr/mt76) — out-of-tree mt76 driver with monitor mode fixes
- [hcxdumptool discussions](https://github.com/ZerBea/hcxdumptool/discussions) — adapter compatibility reports and kernel regression tracking
- [hcxdumptool adapter list](https://github.com/ZerBea/hcxdumptool/discussions/361) — ZerBea's tested adapters with driver info
- [kernel.org](https://kernel.org) — latest kernel releases and longterm support status
