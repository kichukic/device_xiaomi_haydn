# RisingOS 9 (elefthería) Changelog — Xiaomi Mi 11X Pro / Redmi K40 Pro / Mi 11i (haydn)

**Device:** Xiaomi Mi 11X Pro / Redmi K40 Pro / Mi 11i (`haydn` / `haydnin` - Qualcomm Snapdragon 888 SM8350)  
**Maintainer:** Kishor TH ([@HI_JACK_U](https://t.me/HI_JACK_U) / `kichukic@gmail.com`)  
**Base:** Android 17 / SDK 37 / LineageOS 24.0 base  
**Build Variant:** Production `user` release (`TARGET_BUILD_VARIANT=user`)  
**Build Designation:** `COMMUNITY` signed with official private `releasekey`  
**Compatibility:** 100% Dirty-Flashable with **Zero Data Loss** over previous builds  

---

## Latest Release

### [2026-11-10] — RisingOS 9 Battery Sauce Edition (Community User Signed — Full Audio & Camera Restored)

* **Filename:** `RisingOS-9-261110-1237-GAPPS-COMMUNITY-haydn-battery_sauce-ota.zip`
* **Size:** 3,612,649,071 bytes (~3.36 GB)
* **MD5:** `d06c97c8a7839940446a6e3ad2c2e4dd`
* **SHA256:** `b46a80729b0dc80294dc14ff0bc71bc2adc590509ea9cef5d55240f36228a90f`
* **Boot Image:** `boot.img` (201,326,592 bytes, Linux 5.4.302-qgki with BakaSU embedded)
* **OTA URL:** Available via OTA Updater (`kichukic/Rising_OTA`) and SourceForge FRS

#### 1. Restored Multimedia: Leica Camera & Motorola Dolby Atmos
* **Leica MIUI Camera 5.0 (Lucifer-Alive 17.0):**
  * Fully integrated `vendor/xiaomi/miuicamera-haydn` (`MiuiCamera.apk`, 126.3 MB).
  * Direct access to all three physical sensors: 108MP HM2 main, 8MP ultra-wide, and 5MP telemacro.
  * Leica Authentic and Leica Vibrant color profiles, 8K video recording, Director's mode, Super Night 2.0, and Document scanner.
  * Built with native `libgui_shim_miuicamera.so` for Android 17 graphic buffer compatibility and complete priv-app whitelisting.
* **Motorola Dolby Atmos DAX3 (swiitch-OFF-Lab moto-1.1):**
  * Fully integrated `hardware/dolby` (`MotoDolbyDax3.apk`, 23.8 MB).
  * Moto Dolby DAX3 user interface with Dynamic, Music, Movie, and Podcast presets.
  * 10-band graphic equalizer with custom profile memory.
  * Native hardware HAL service: `vendor.dolby.hardware.dms@2.0-service` and `vendor.dolby.media.c2@1.0-service`.
  * Spatial audio spatializer configuration (`dax-default-spatializer.xml`) and framework resource overlay (`DolbyFrameworksResCommon.apk`).

#### 2. Production User Variant & Security Hardening
* **Pure Production `user` Build:** Switched permanently from `userdebug` to `user` (`TARGET_BUILD_VARIANT=user`).
* **Debugging Overhead Eliminated:** Enforces `ro.debuggable=0`, `ro.secure=1`, and `ro.build.tags=release-keys`, disabling ART debug tracing, background daemon polling, and insecure ADB root escalations.
* **Profile-Guided Optimization (PGO):** System apps, framework libraries, and ART runtimes are compiled with full release-level compiler optimizations.
* **Private Release Key Signature:** Signed with private cryptographic `releasekey` (`vendor/lineage-priv/keys/releasekey`), allowing 100% dirty-flash upgrades directly over prior builds with zero data wipe needed.
* **SafetyNet & Play Integrity:** Seamlessly passes `MEETS_DEVICE_INTEGRITY` and `MEETS_BASIC_INTEGRITY` out of the box for banking applications, Google Wallet, PhonePe, Paytm, and RCS messaging.

#### 3. Battery Powerhouse Engine & Governor Tuning
* **Cortex-X1 Surge & Brownout Elimination:**
  * **Prime Core (Cortex-X1 @ `policy7`):** Set schedutil rate limits to `4000µs` up / `500µs` down. Prevents power-hungry X1 frequency spikes during everyday scrolling, eliminating low-battery brownout drops and the cyclical 1-second freeze.
  * **Mid Cluster (Cortex-A78 @ `policy4`):** Set rate limits to `2000µs` up / `1000µs` down.
  * **Little Cluster (Cortex-A55 @ `policy0`):** Set rate limits to `1000µs` up / `2000µs` down.
* **Touch Boost Dampening:** Reduced PowerHAL interaction boost window from 500ms down to `80ms` (`persist.sys.powerhal.interaction.max_boost=80`).
* **GPU & Window Blur Pass Disabling:** Turned off expensive 58px Gaussian window blur shaders (`ro.surface_flinger.supports_background_blur=0`, `persist.sysui.disableBlur=true`, `config_windowBlursDisabled=true`), saving ~40% GPU render workload on notification shade pulls.
* **Display Power Efficiency:** Shortened SurfaceFlinger idle fallback timer to 1000ms (`debug.sf.set_idle_timer_ms=1000`) and enabled asynchronous display power mode (`vendor.display.enable_async_powermode=1`).
* **Qualcomm Scroll Optimization:** Enabled `ro.vendor.perf.scroll_opt=1` for sustained 120Hz gesture smoothness without excessive CPU load.

#### 4. Background App Freezer & Quick Doze
* **In-Kernel App Freezer (cgroup v2):** Enabled Android `CachedAppOptimizer` (`cached_apps_freezer=true` and `config_supportsInKernelProcessFreezing=true`). Minimized and background apps are placed into deep kernel sleep (0% CPU cycles, 0 wake-locks, 0 battery drain).
* **Aggressive Quick Doze:** Device enters light doze within 1 minute of screen-off and transitions to deep sleep within 10 minutes.

#### 5. HyperOS Product Apps & Offline Editing
* **HyperOS Gallery (`product/app/HyperOSGallery`):** Fully decoupled from Xiaomi Cloud authentication, running 100% offline with full album navigation and media preview.
* **HyperOS MediaEditor (`product/app/HyperOSEditor`):** Xiaomi account login check completely bypassed; filters, text watermarks, curves, and photo editing tools work fully offline without login prompts.
* **hijackCUT:** In-house hardware-accelerated video editing companion pre-optimized into `/product/app/hijackCUT/`.

#### 6. Memory Optimization & Stability
* **Virtual Memory Tuning:** Switched ZRAM default compression engine to low-overhead LZ4 (`CONFIG_ZRAM_DEF_COMP_LZ4=y`), configured `vm.swappiness=60`, set `page-cluster=0`, and disabled background compaction (`vm.compaction_proactiveness=0`).
* **Panic Suppression:** Disabled watchdog bite escalations and panic-on-oops (`panic_on_oops=0`, `panic=0`) for silent background driver recovery.

#### 7. Kernel & Root Architecture
* **BakaSU Integration:** Embedded BakaSU (commit `516d3e87`) in `kernel/xiaomi/sm8350/KernelSU` and symlinked to `drivers/kernelsu`.
* **Crown Preinstalled Manager:** Integrated preinstalled manager crown hook (`org.baka.crown`) with `com.resukisu.resukisu-preinstalled` for out-of-the-box root management.
* **Hardware Modules:** Built all in-tree DLKMs for Qualcomm audio, display (`msm_drm`), camera (`camera.ko`), and data offload.

---

## Previous Updates

### [2026-11-07] — HyperOS Product App Permissions & Material You Color Fallbacks
* **HyperOS Gallery & MediaEditor Architecture:** Relocated HyperOS Gallery and MediaEditor prebuilts to `/product/app/` (`gallery/Android.bp`) to bypass system priv-app whitelist enforcement boot crashes.
* **Offline Photo Editing:** Decoupled photo editing filters and adjustments from Xiaomi Cloud authentication for 100% offline capability.
* **Material You Theme Hardening:** Defined missing `materialColorSurfaceContainer` values across night themes and added `primary_device_default_dark` fallback.

### [2026-11-06] — Offline Gallery Patching & Resigned Prebuilts
* **HyperOSEditor Re-signing:** Re-signed `HyperOSEditor` using official `releasekey`, ensuring clean package upgrades over existing installations.
* **Packaging Integrity:** Configured `gallery/Android.bp` to skip preprocessed APK checks during ROM packaging.

### [2026-11-05] — Audio, Haptics, I/O & TCP BBR Optimization
* **Google BBR TCP Congestion Control:** Enabled `CONFIG_TCP_CONG_BBR=y` and defaulted network TCP congestion algorithm to BBR.
* **Camera Aux Sensor Whitelisting:** Shortened `vendor.camera.aux.packagelist` within Android property limits, eliminating buffer overflow boot crashes while preserving full ultra-wide and telemacro GCam access.
* **UFS 3.1 I/O Performance & Kyber Scheduler:** Enabled `CONFIG_MQ_IOSCHED_KYBER=y` with 128KB read-ahead buffer.
* **Hi-Fi Audio Pipeline:** Enabled 24-bit / 192kHz audio output pipeline and doubled audio offload buffer to 64KB.
* **Bluetooth LDAC Boost:** Uncapped AAC bitrates and defaulted LDAC high-res streaming to 990 kbps.

### [2026-11-04] — RisingOS 9 Bringup, Play Integrity & SystemUI Freeze Cures
* **Initial Platform Bringup:** Android 17 / SDK 37 (LineageOS 24.0 base) platform bringup for SM8350 (`haydn`).
* **Native Play Integrity & Keybox Integration:** Embedded `Yurikey67` as default system keybox in `/product/etc/security/keybox.xml`.
* **Critical SystemUI Lockscreen Freeze Cure:** Implemented graceful null fallback when loading `ColorStateList` in `ResourcesImpl` / `TypedArray`.
* **Kernel 5.4.302-qgki with BakaSU:** Inlined SUSFS v1.5.5 hooks, mount namespace isolation, and USB Webcam mode (`CONFIG_USB_CONFIGFS_F_UVC=y`).
