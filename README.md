# Device Tree for Xiaomi Mi 11X Pro / Redmi K40 Pro / Mi 11i (`haydn`)

This repository contains the device configuration tree for building **RisingOS 9 (Android 17 / SDK 37)** on Xiaomi Mi 11X Pro / Redmi K40 Pro / Mi 11i (`haydn` / `haydnin`).

## Device Specifications

| Feature | Specification |
| :--- | :--- |
| **SoC** | Qualcomm Snapdragon 888 5G (SM8350, Lahaina) |
| **CPU** | 1x 2.84 GHz Cortex-X1 + 3x 2.42 GHz Cortex-A78 + 4x 1.80 GHz Cortex-A55 |
| **GPU** | Adreno 660 |
| **Memory** | 8 GB / 12 GB LPDDR5 |
| **Storage** | 128 GB / 256 GB UFS 3.1 |
| **Display** | 6.67" Super AMOLED 1080 x 2400 (120Hz, HDR10+) |
| **Battery** | 4520 mAh (33W Fast Charging) |
| **Camera** | 108 MP (wide) + 8 MP (ultrawide) + 5 MP (telemacro) |

## Key Inclusions & Optimizations

- **Authentic `user` Variant:** Production release-keys build (`ro.debuggable=0`, no JDWP, passes banking apps).
- **Embedded Strong Keybox:** Bundles Yurikey67 in `/product/etc/security/keybox.xml`, automatically seeded to TrickyStore via `AxSpoofManager`.
- **Leica MIUI Camera 5.0:** Integrated camera stack with working photo, video, portrait, and pro modes.
- **hijackCUT:** Integrated 4K video editor suite.
- **BakaSU & SUSFS:** KernelSU-Next / BakaSU 1.5.5 support with preinstalled manager hook (`35257`).

## Build Instructions

```bash
# Initialize RisingOS environment
. build/envsetup.sh

# Lunch configuration for user build
lunch lineage_haydn-user

# Compile OTA package
mka bacon
```

## Related Repositories

- **Common Device Tree:** [`android_device_xiaomi_sm8350-common`](https://github.com/kichukic/android_device_xiaomi_sm8350-common)
- **Kernel Source:** [`android_kernel_xiaomi_sm8350`](https://github.com/kichukic/android_kernel_xiaomi_sm8350)
- **OTA Updates & Releases:** [`Rising_OTA`](https://github.com/kichukic/Rising_OTA)
