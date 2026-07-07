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

| Chipset | WiFi gen | In-kernel driver | Monitor mode since | Active monitor | Recommended kernel |
|---|---|---|---|---|---|
| **MT7612U** | WiFi 5 (AC) | `mt76x2u` | 4.19 | Yes | 6.6+ |
| **MT7610U** | WiFi 5 (AC) | `mt76x0u` | 4.19 | Yes | 6.6+ |
| **MT7921AU** | WiFi 6E (AXE) | `mt7921u` | 5.18 | Yes | 6.6+ |
| **MT7925U** | WiFi 7 (BE) | `mt7925u` | 6.7 | Yes | 7.0+ |

**Popular adapters using these chipsets:**

- **ALFA AWUS036ACM** — MT7612U, WiFi 5, dual-band, widely available. The workhorse for WPA testing.
- **ALFA AWUS036AXML** — MT7921AU, WiFi 6E, tri-band. Newer, faster, but check kernel notes below.
- **Netgear A8000** — MT7921AU, WiFi 6E. Compact USB-A form factor.
- **Adapters with MT7925U** — WiFi 7 capable, newest generation. Requires kernel 7.0+.

### Realtek (limited support)

Realtek has multiple in-kernel driver families, but monitor mode support is incomplete compared to MediaTek:

| Driver | Chipsets | WiFi gen | Monitor mode | Active monitor | Notes |
|---|---|---|---|---|---|
| `rtl8xxxu` | RTL8188EUS, RTL8192EU | WiFi 4 (N) | Partial (kernel 6.6+ with [patch](https://bugzilla.kernel.org/show_bug.cgi?id=217205)) | No | Legacy chipsets; patch not yet merged into mainline |
| `rtw88` | RTL8822BU, RTL8822CU, RTL8723DU | WiFi 5 (AC) | Yes | No | No active monitor, no VIF |
| `rtw89` | RTL8852AU, RTL8852BU, RTL8852CU | WiFi 6 (AX) | Yes | No | Supports VIF but no active monitor |
| `rtl8187` | RTL8187L | WiFi 3 (B/G) | Yes | Yes | Ancient but fully working; 2.4 GHz only |

**Bottom line:** Realtek adapters work for passive capture and basic monitor mode, but they do **not** support active monitor mode. This means hcxdumptool cannot actively solicit PMKIDs — it can only passively wait for handshakes. For active attacks, use a MediaTek adapter.

### Legacy (still works)

| Chipset | Driver | WiFi gen | Notes |
|---|---|---|---|
| Atheros AR9271 | `ath9k_htc` | WiFi 4 (N) | Rock-solid monitor + injection. 2.4 GHz only. The classic pentesting adapter (ALFA AWUS036NHA). |
| Ralink RT5572 | `rt2800usb` | WiFi 4 (N) | Dual-band. Stable but slow by modern standards. |

These still work and are well-tested, but they are WiFi 4 only — they cannot see 5 GHz or 6 GHz networks.

## Linux kernel requirements

### Why the kernel version matters

WiFi adapter drivers ship inside the Linux kernel. A newer kernel = newer drivers with more chipset support and bug fixes. The kernel also contains the `mac80211` subsystem (the WiFi stack that provides monitor mode) and the `cfg80211/nl80211` interface that hcxdumptool uses.

### Current kernel status

Check your kernel version:

```bash
uname -r
```

| Kernel | Status | MediaTek mt76 monitor mode | Notes |
|---|---|---|---|
| 5.x | Old | MT7612U works; MT7921AU limited | Missing many fixes |
| **6.6 LTS** | Longterm | Works up to 6.6.40; **broken in 6.6.41+** | WiFi 7 stack changes caused mt76 regression |
| 6.8-6.11 | Stable (EOL) | Broken after 6.8.12 | Same WiFi 7 regression |
| **6.12+ LTS** | Current longterm | Use [morrownr/mt76](https://github.com/morrownr/mt76) out-of-tree driver | In-kernel driver still has issues |
| **7.0+** | Latest stable | In-kernel fixes landing; MT7925U support | Best path forward |

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
