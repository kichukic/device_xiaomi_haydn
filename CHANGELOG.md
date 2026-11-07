# Changelog for Xiaomi Mi 11X Pro / Redmi K40 Pro / Mi 11i (`haydn`)

## RisingOS 9 (elefthería) — 2026-11-05 Release

### Core System & Security
- **Production `user` Variant:** Compiled as authentic `user` build with `ro.debuggable=0`, disabled JDWP, and maximum AOT/PGO runtime performance.
- **Native Play Integrity & Strong Keybox:** Embedded Yurikey67 as default system keybox in `/product/etc/security/keybox.xml`. Automatically seeded to TrickyStore on first boot.
- **SystemUI Stability Fix:** Resolved static broadcast receiver leak in `SignalIconLoader` that previously triggered notification crashes.

### Performance & Memory Tuning
- **ZSTD ZRAM Compression Engine:** Upgraded ZRAM compression from `lz4` to Zstandard (`zstd`), jumping compression ratio from ~2.1x to ~3.2x (~12GB+ effective background app capacity).
- **RAM Deduplication Disabled:** Maintained `use_dedup = 0` to eliminate SHA256 page hashing battery drain.
- **Dalvik VM Heap:** Optimized for 8GB/12GB RAM hardware profile with 384MB heap growth limit.

### Networking & Gaming
- **Google BBR Congestion Control:** Enabled `CONFIG_TCP_CONG_BBR=y` in kernel and enforced at runtime via `init.qcom.rc` and `system.prop`. Lowers ping spikes and eliminates packet-loss throughput collapse.

### Kernel Hardening & Anti-Reboot
- **Anti-Kernel Panic Protection:** Disabled `CONFIG_PANIC_ON_OOPS`, Qualcomm watchdog bite on panic, and SSR notification timeout panics.
- **Silent Recovery:** Subsystem glitches and non-critical driver drops recover gracefully without spontaneous phone reboots.
- **KernelSU & SUSFS:** Linux 5.4.302-qgki with BakaSU 1.5.5 and inline SUSFS hooks.

### Audio & Multimedia
- **Motorola Dolby Atmos (`MotoDolbyDax3`):** Integrated full Dolby stack with working master toggle, 10-band equalizer, presets, and `DSPVolumeSynchronizer`.
- **Leica Camera 5.0:** Full working MIUI camera integration.
- **hijackCUT:** Integrated 4K video editing application.

### Additional Enhancements (Storage, ART, Audio & Haptics)
- **UFS 3.1 I/O Kyber Scheduler:** Low-latency multi-queue scheduler with 128KB read-ahead and CPU spinlock reduction.
- **ART Speed-Profile & Parallel Dexopt:** Profile-guided AOT bytecode compilation on install and 6/8-thread dex2oat.
- **120Hz SurfaceFlinger Pacing & 25MB Launcher Pinning:** Latch unsignaled buffers and prevent launcher redraws.
- **24-bit Hi-Fi Audio & 64KB DSP Buffer:** High-resolution audio pipeline with 50% fewer CPU wakeups during music playback.
- **3-Level Vibration Haptics:** Granular Low/Medium/High vibration intensity slider in Settings.

### UI Animation Physics
- **0.8x Spring Physics:** Configured `def_window_animation_scale`, `def_transition_animation_scale`, and `def_animator_duration_scale` to 0.8x across all regional models (Mi 11X Pro, Redmi K40 Pro, Mi 11i) for hyper-fluid gesture navigation.
