# Fresh Server Setup & ROM Build Runbook (RisingOS / haydn)
**Target Device:** Xiaomi Mi 11X Pro / Redmi K40 Pro / POCO F3 Pro (`haydn` / `haydnin` - SM8350)  
**Maintainer:** Kishor TH ([@HI_JACK_U](https://t.me/HI_JACK_U) / `kichukic@gmail.com`)  
**Base:** RisingOS 9 (*elefthería* - Android 17 / SDK 37 / LineageOS 24.0 base)

---

## 1. Why This Guide Exists

When migrating to a new or re-provisioned build server (such as ServerHive EPYC), several non-standard components, custom device tree fixes, and automation pipelines must be explicitly configured. Without them, standard `repo sync` and builds will fail or produce unstable ROMs:
1. **Empty `KernelSU` Submodule Directory:** Git submodule without `.gitmodules` leaves `drivers/kernelsu` dangling, failing `olddefconfig` at line 235 of `drivers/Kconfig`.
2. **Missing Custom Throne Tracker Hook:** BakaSU manager preinstall crown hook must be patched into `throne_tracker.c`.
3. **Official Signing Keys:** Must be restored to preserve data encryption and enable dirty-flashing over existing user data with zero data loss.
4. **Official Build Verification:** `RISING_MAINTAINER` must match `vendor/official_devices/OTA/risingOS.maintainers` without quotes.
5. **Historical Architecture Fixes:** Proprietary GCam aux limits, Dolby deduplication, HyperOS Gallery permissions, AxSpoofManager keybox, and SystemUI freeze cures.
6. **Dual-Rsync & Automated OTA Deployment:** Automated monitoring script that builds, syncs to SourceForge and local laptop, and updates OTA metadata without manual intervention.

---

## 2. Server Prerequisites & Environment

### A. Core Build Packages
```bash
sudo apt update && sudo apt install -y \
    bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
    gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool \
    libncurses6 libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop \
    pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python3 \
    python-is-python3 openjdk-21-jdk tmux byobu tree htop
```

### B. Git Credentials
Configure GitHub credentials for `kichukic` to allow pulling/pushing device trees, addons, and manifests:
```bash
git config --global user.name "Kishor Thykkattu"
git config --global user.email "38286414+kichukic@users.noreply.github.com"
git config --global credential.helper store
echo "https://kichukic:<GITHUB_TOKEN>@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

### C. Ccache Configuration (100GB)
```bash
export CCACHE_DIR=/serverhive/hijacku/.ccache
export USE_CCACHE=1
ccache -M 100G
ccache -o compression=true
```

### D. SSH Key Setup & Passwordless Authentication

#### 1. Laptop-to-Server Passwordless Access
From your local maintainer laptop, authorize your SSH public key on the new server:
```bash
# Option A: Automatic
ssh-copy-id -i ~/.ssh/id_ed25519.pub hijacku@<SERVER_HOST>

# Option B: Direct pipe (if ssh-copy-id is unavailable)
cat ~/.ssh/id_ed25519.pub | ssh hijacku@<SERVER_HOST> \
    "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

#### 2. Laptop SSH Config (`~/.ssh/config`)
Configure connection persistence and disable stale multiplex socket deadlocks:
```sshconfig
Host waffle waffle.serverhive.in
  HostName waffle.serverhive.in
  User hijacku
  Port 22
  IdentityFile ~/.ssh/id_ed25519
  # Keep ControlMaster disabled to avoid hung socket blocks when sessions drop
  ServerAliveInterval 60
  ServerAliveCountMax 10
```

#### 3. Server-to-SourceForge Passwordless Deployment Key
Generate a dedicated SSH key on the build server so automated scripts can rsync to SourceForge without human password input:
```bash
# On the build server:
ssh-keygen -t ed25519 -C "kichukic@gmail.com" -f ~/.ssh/id_ed25519_sourceforge -N ""
cat ~/.ssh/id_ed25519_sourceforge.pub
```
1. Copy the public key output.
2. Log into [SourceForge Account Settings](https://sourceforge.net/auth/preferences/) -> **SSH Keys**.
3. Paste the key and save.
4. Add the host entry to `~/.ssh/config` on the build server:
```sshconfig
Host frs.sourceforge.net
  Hostname frs.sourceforge.net
  User kichukic
  IdentityFile ~/.ssh/id_ed25519_sourceforge
  StrictHostKeyChecking accept-new
```

---

## 3. Official Signing Keys Restoration

> [!IMPORTANT]
> To allow dirty-flashing with **zero data loss**, the ROM **must** be signed with the exact private key that signed the currently installed build.

Copy all 11 key pairs from backup (`/home/hijack/RisingOS_backup/keys/` or secure storage) to the build tree:
```bash
mkdir -p /serverhive/hijacku/RisingOS/vendor/lineage-priv/keys
cp -a /path/to/backup/keys/* /serverhive/hijacku/RisingOS/vendor/lineage-priv/keys/
```

Verify the fingerprint:
```bash
keytool -printcert -jarfile /serverhive/hijacku/RisingOS/vendor/lineage-priv/keys/releasekey.x509.pem
# Expected SHA-256 Fingerprint:
# F4:E7:A0:7D:E2:9A:42:D0:15:72:41:F3:91:11:94:3F:80:C1:B8:F9:53:C0:B3:80:61:6B:D7:48:DD:B1:D3:D6
```

---

## 4. Manifest Configuration (`.repo/local_manifests/haydn.xml`)

Initialize RisingOS 9:
```bash
repo init -u https://github.com/RisingOS-Revived/android -b seventeen --git-lfs
```

Create `/serverhive/hijacku/RisingOS/.repo/local_manifests/haydn.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <!-- Device and Common Trees -->
    <remove-project name="device/xiaomi/haydn" />
    <project name="kichukic/device_xiaomi_haydn" path="device/xiaomi/haydn" remote="github" revision="lineage-24.0" />

    <remove-project name="device/xiaomi/sm8350-common" />
    <project name="kichukic/android_device_xiaomi_sm8350-common" path="device/xiaomi/sm8350-common" remote="github" revision="lineage-24.0" />

    <!-- Kernel with SUSFS & BakaSU -->
    <remove-project name="kernel/xiaomi/sm8350" />
    <project name="kichukic/android_kernel_xiaomi_sm8350" path="kernel/xiaomi/sm8350" remote="github" revision="lineage-24.0" />

    <!-- Vendor Blobs from TheMuppets -->
    <project name="TheMuppets/proprietary_vendor_xiaomi_haydn" path="vendor/xiaomi/haydn" remote="github" revision="lineage-24.0" />
    <project name="TheMuppets/proprietary_vendor_xiaomi_sm8350-common" path="vendor/xiaomi/sm8350-common" remote="github" revision="lineage-24.0" />

    <!-- Frameworks Base (AxSpoofManager & Yurikey67) -->
    <remove-project name="frameworks/base" />
    <project name="kichukic/android_frameworks_base-new" path="frameworks/base" remote="github" revision="seventeen" />

    <!-- Addons & Official Whitelist -->
    <remove-project name="vendor/addons" />
    <project name="kichukic/android_vendor_addons" path="vendor/addons" remote="github" revision="seventeen" />

    <remove-project name="vendor/official_devices" />
    <project name="kichukic/official_devices" path="vendor/official_devices" remote="github" revision="fifteen" />
</manifest>
```

Sync the tree:
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

---

## 5. Critical Kernel Setup: BakaSU & Throne Tracker (DO NOT SKIP)

Because `kernel/xiaomi/sm8350` uses a submodule pointer for `KernelSU` without `.gitmodules`:

```bash
cd /serverhive/hijacku/RisingOS/kernel/xiaomi/sm8350

# 1. Remove empty submodule directory
rm -rf KernelSU

# 2. Clone BakaSU and checkout the tested base commit
git clone https://github.com/Baka-SU/BakaSU KernelSU
cd KernelSU
git checkout 516d3e87fbc986ccefdde2c2765f1700612441a9

# 3. Apply the preinstalled manager crown hook
cat <<'EOF' | git apply
diff --git a/kernel/manager/throne_tracker.c b/kernel/manager/throne_tracker.c
index d487fc8d..4a009f83 100644
--- a/kernel/manager/throne_tracker.c
+++ b/kernel/manager/throne_tracker.c
@@ -237,6 +237,32 @@ void search_manager(const char *path, int depth, struct list_head *uid_data)
     }
 }
 
+/*
+ * haydn ROM: the manager is preinstalled as a product app at
+ *   /product/app/com.resukisu.resukisu-preinstalled/com.resukisu.resukisu-preinstalled.apk
+ * search_manager() only walks /data/app, so check that path explicitly when
+ * no manager was found there (an update installed over it lives in /data/app
+ * and takes precedence). The "<pkg>-<suffix>" directory name lets
+ * get_pkg_from_apk_path() resolve the real package name.
+ */
+#define KSU_PREINSTALLED_MANAGER_APK \
+    "/product/app/com.resukisu.resukisu-preinstalled/com.resukisu.resukisu-preinstalled.apk"
+
 static void crown_preinstalled_manager(struct list_head *uid_data)
 {
     char apk[] = KSU_PREINSTALLED_MANAGER_APK;
     u8 signature_index = 0;
 
     if (ksu_has_manager())
         return;
 
     if (!is_manager_apk(apk, &signature_index))
         return;
 
     pr_info("Found preinstalled manager at %s\n", apk);
     crown_manager(apk, uid_data, signature_index);
 }
 
 static bool is_uid_exist(uid_t uid, char *package, void *data)
 {
     struct list_head *list = (struct list_head *)data;
@@ -348,6 +374,7 @@ void do_track_throne(void *data)
 
     pr_info("Searching for manager(s)...\n");
     search_manager("/data/app", 2, &uid_list);
+    crown_preinstalled_manager(&uid_list);
     pr_info("Manager search finished\n");
 
 prune:
EOF

# 4. Commit changes
git commit -am "throne_tracker: crown preinstalled manager in /product/app"

# 5. Verify symlink
cd ..
ln -sfn ../KernelSU/kernel drivers/kernelsu
ls -la drivers/kernelsu/Kconfig
```

---

## 6. Official Build Whitelist Verification

Verify that official build status evaluates to `OFFICIAL`:
1. `device/xiaomi/haydn/lineage_haydn.mk`:
   ```makefile
   RISING_MAINTAINER := Kishor TH
   ```
   *(Ensure there are NO double quotes around `Kishor TH`)*.
2. `vendor/official_devices/OTA/risingOS.maintainers`:
   Must contain `Kishor TH`.
3. `vendor/official_devices/OTA/risingOS.devices`:
   Must contain `haydn`.

---

## 7. Battery Powerhouse Verification Checklist

Confirm the following optimizations are present in the source tree:
- [x] **Schedutil CPU Rate Limits:** `init.qti.kernel.rc` (`policy0`: 1000/2000µs, `policy4`: 2000/1000µs, `policy7`: 4000/500µs).
- [x] **Memory Management:** `vm.swappiness=60`, `compaction_proactiveness=0`, ZRAM LZ4 compression enabled in `xiaomi_QGKI.config`.
- [x] **SurfaceFlinger Blur:** `ro.surface_flinger.supports_background_blur=0` and `persist.sysui.disableBlur=true` in `vendor.prop`.
- [x] **Freeze Daemon:** `cached_apps_freezer=true` in `common.mk` and `config_supportsInKernelProcessFreezing=true` in `FrameworkOverlaySM8350`.
- [x] **Kernel Crash Suppression:** `panic_on_oops=0` and `panic=0` in `init.qti.kernel.rc` and `xiaomi_QGKI.config`.

---

## 8. Build Execution

Launch inside a persistent tmux session on the server:
```bash
tmux new -s rising
cd /serverhive/hijacku/RisingOS
source build/envsetup.sh
brunch haydn 2>&1 | tee /serverhive/hijacku/build.log
```

---

## 9. Automated Build Daemon, Dual-Rsync & OTA Pipeline

To eliminate manual monitoring and ensure artifacts are uploaded and synced immediately upon build completion, launch `monitor_build.sh` on your local laptop.

### What the Pipeline Does Automatically:
1. **Live Progress Polling:** Polls `soong_ui` / `ninja` and captures live output from tmux session `rising:0` every 30 seconds.
2. **Failure Resilience:** Does not fail on momentary network disconnection (requires 5 consecutive failed checks ~2.5 mins).
3. **Dual Rsync Pipeline (Upon Build Success):**
   * **SourceForge:** Triggers high-speed rsync directly from the server's gigabit uplink to `kichukic@frs.sourceforge.net:/home/frs/project/rising-unofficial/`.
   * **Laptop:** Pulls the signed OTA `.zip` and `boot.img` down to `/home/hijack/Downloads/RisingOS_haydn/`.
4. **Automated Metadata & GitHub Push:**
   * Computes SHA-256 and MD5 checksums and file sizes.
   * Updates `haydn.json`, `GAPPS/haydn.json`, and `device/GAPPS/haydn.json`.
   * Pushes the commit to `kichukic/Rising_OTA` on GitHub.

### `monitor_build.sh` Script Implementation
Save to `/home/hijack/Downloads/RisingOS_haydn/monitor_build.sh` and make executable (`chmod +x`):
```bash
#!/usr/bin/env bash
set -u

DOWNLOAD_DIR="/home/hijack/Downloads/RisingOS_haydn"
OTA_REPO_DIR="/home/hijack/Rising_OTA"
MONITOR_LOG="${DOWNLOAD_DIR}/monitor.log"
SERVER="waffle"
REMOTE_BUILD_DIR="/serverhive/hijacku/RisingOS"
REMOTE_LOG="/serverhive/hijacku/build.log"
START_TIME=$(date +%s)

mkdir -p "$DOWNLOAD_DIR"
rm -f "${DOWNLOAD_DIR}/BUILD_DONE" "${DOWNLOAD_DIR}/BUILD_FAILED"

echo "=== Build monitor resumed at $(date) (Start Time: $START_TIME) ===" | tee -a "$MONITOR_LOG"

CONSECUTIVE_NO_PROCESS=0

while true; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # Check if build processes are still running on server
    IS_RUNNING=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "ps -eo comm | grep -E 'soong_build|ninja|soong_ui|build_risingos' | grep -v grep | head -n 1" 2>/dev/null || echo "")

    # Get last progress line from tmux capture-pane or build log
    PROGRESS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "tmux capture-pane -pt rising:0 -S -10 2>/dev/null | grep -E '^\[ *[0-9]+%|^====|^####|FAILED:' | tail -n 1" 2>/dev/null || echo "")
    if [ -z "$PROGRESS" ]; then
        PROGRESS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "grep -E '^\[ *[0-9]+%|^====|^####|FAILED:' $REMOTE_LOG 2>/dev/null | tail -n 1" 2>/dev/null || echo "")
    fi

    echo "[$TIMESTAMP] Running: $([ -n "$IS_RUNNING" ] && echo YES || echo NO) | Progress: $PROGRESS" | tee -a "$MONITOR_LOG"

    if [ -n "$IS_RUNNING" ]; then
        CONSECUTIVE_NO_PROCESS=0
    else
        CONSECUTIVE_NO_PROCESS=$((CONSECUTIVE_NO_PROCESS + 1))
        # Require 5 consecutive checks (~2.5 minutes) with no processes before concluding
        if [ "$CONSECUTIVE_NO_PROCESS" -ge 5 ]; then
            # Check if build completed successfully
            IS_SUCCESS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "tmux capture-pane -pt rising:0 -S -50 2>/dev/null | grep -E '#### build completed successfully' | tail -n 1" 2>/dev/null || echo "")
            if [ -z "$IS_SUCCESS" ]; then
                IS_SUCCESS=$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$SERVER" "grep -E '#### build completed successfully' $REMOTE_LOG 2>/dev/null | tail -n 1" 2>/dev/null || echo "")
            fi

            if [ -n "$IS_SUCCESS" ]; then
                echo "[$TIMESTAMP] >>> BUILD COMPLETED SUCCESSFULLY! Starting post-processing..." | tee -a "$MONITOR_LOG"

                # Find newest OTA zip created
                REMOTE_ZIP=$(ssh "$SERVER" "ls -t ${REMOTE_BUILD_DIR}/out/target/product/haydn/RisingOS-*-ota.zip 2>/dev/null | head -n 1")

                if [ -z "$REMOTE_ZIP" ]; then
                    echo "[$TIMESTAMP] ERROR: Build succeeded but no zip found in out/target/product/haydn/!" | tee -a "$MONITOR_LOG"
                    echo "FAILED: No zip found" > "${DOWNLOAD_DIR}/BUILD_FAILED"
                    exit 1
                fi

                ZIP_NAME=$(basename "$REMOTE_ZIP")
                REMOTE_SIZE=$(ssh "$SERVER" "stat -c%s $REMOTE_ZIP")
                REMOTE_MD5=$(ssh "$SERVER" "md5sum $REMOTE_ZIP | awk '{print \$1}'")
                REMOTE_SHA256=$(ssh "$SERVER" "sha256sum $REMOTE_ZIP | awk '{print \$1}'")
                UNIX_TIME=$(date +%s)

                echo "[$TIMESTAMP] New Build Detected: $ZIP_NAME ($REMOTE_SIZE bytes)" | tee -a "$MONITOR_LOG"

                # 1. Dual-Rsync Pipeline: Upload directly to SourceForge from server
                echo "[$TIMESTAMP] Uploading zips and boot.img to SourceForge..." | tee -a "$MONITOR_LOG"
                ssh "$SERVER" "rsync -avP --stats ${REMOTE_BUILD_DIR}/out/target/product/haydn/RisingOS-*-ota.zip ${REMOTE_BUILD_DIR}/out/target/product/haydn/boot.img kichukic@frs.sourceforge.net:/home/frs/project/rising-unofficial/" | tee -a "$MONITOR_LOG" || true

                # 2. Update Rising_OTA JSON metadata and push to GitHub
                echo "[$TIMESTAMP] Updating Rising_OTA metadata and pushing to GitHub..." | tee -a "$MONITOR_LOG"
                python3 - << PYEOF
import json

json_path = "${OTA_REPO_DIR}/haydn.json"
with open(json_path, "r") as f:
    data = json.load(f)

for item in data.get("response", []):
    item["filename"] = "${ZIP_NAME}"
    item["download"] = "https://downloads.sourceforge.net/project/rising-unofficial/${ZIP_NAME}"
    item["url"] = "https://downloads.sourceforge.net/project/rising-unofficial/${ZIP_NAME}"
    item["timestamp"] = int("${UNIX_TIME}")
    item["datetime"] = int("${UNIX_TIME}")
    item["md5"] = "${REMOTE_MD5}"
    item["sha256"] = "${REMOTE_SHA256}"
    item["id"] = "${REMOTE_SHA256}"
    item["size"] = int("${REMOTE_SIZE}")
    item["romtype"] = "official"

content = json.dumps(data, indent=2) + "\n"
for path in [json_path, "${OTA_REPO_DIR}/GAPPS/haydn.json", "${OTA_REPO_DIR}/device/GAPPS/haydn.json", "${DOWNLOAD_DIR}/haydn.json"]:
    with open(path, "w") as f:
        f.write(content)

print("OTA JSON files successfully updated.")
PYEOF

                cd "$OTA_REPO_DIR"
                git add haydn.json GAPPS/haydn.json device/GAPPS/haydn.json
                git commit -m "haydn: Release RisingOS 9 build ${ZIP_NAME}" || true
                git push origin main || true

                # 3. Dual-Rsync Pipeline: Pull new files to local laptop
                echo "[$TIMESTAMP] Downloading $ZIP_NAME and boot.img to local machine..." | tee -a "$MONITOR_LOG"
                rsync -avP --stats "waffle:${REMOTE_BUILD_DIR}/out/target/product/haydn/RisingOS-*-ota.zip" "${DOWNLOAD_DIR}/"
                rsync -avP --stats "waffle:${REMOTE_BUILD_DIR}/out/target/product/haydn/boot.img" "${DOWNLOAD_DIR}/boot.img"

                echo "[$TIMESTAMP] ALL TASKS COMPLETE!" | tee -a "$MONITOR_LOG"
                echo "SUCCESS: ${ZIP_NAME}" > "${DOWNLOAD_DIR}/BUILD_DONE"
                exit 0
            else
                IS_FAILED=$(ssh "$SERVER" "grep -E '^FAILED:' $REMOTE_LOG 2>/dev/null | tail -n 1" || echo "")
                if [ -n "$IS_FAILED" ]; then
                    echo "[$TIMESTAMP] Build process encountered error: $IS_FAILED" | tee -a "$MONITOR_LOG"
                    echo "FAILED: $IS_FAILED" > "${DOWNLOAD_DIR}/BUILD_FAILED"
                    exit 1
                fi
            fi
        fi
    fi

    sleep 30
done
```

---

## 10. Master Architecture Reference & Custom Tweaks Catalog

A detailed index of all historical fixes, tweaks, and architecture decisions committed to the user's repositories:

### A. Camera Subsystem & GCam Aux Whitelisting (`device/xiaomi/sm8350-common`)
* **`vendor.camera.aux.packagelist` Prop Buffer Limit:**
  Android system properties enforce a strict maximum length (92 bytes standard, 120 bytes max). In commit `723b385`, the property was trimmed to prevent `__system_property_add` buffer overflow crashes at boot while maintaining aux sensor access (ultra-wide & telemacro) for:
  `org.codeaurora.snapcam,com.android.camera,com.google.android.GoogleCamera,com.google.android.GoogleCameraEng`.
* **Camera Config Deduplication:**
  Removed duplicate `camera_cnf.txt` in commit `7d6645d` to prevent target collision errors during vendor image packaging.

### B. HyperOS Leica Camera & Gallery Prebuilts (`device/xiaomi/haydn`)
* **Unprivileged Product App Placement (`gallery/Android.bp`):**
  Commits `5fd4714` and `e8c3adb` moved HyperOS Gallery and MediaEditor from privileged `/system/priv-app/` to unprivileged `/product/app/`. This bypasses strict system priv-app permission whitelist enforcement crashes while retaining full gallery, photo, and video editing functions.
* **Resigning Prebuilts:**
  Commit `6d5f8dd` re-signed `HyperOSEditor` using the official `releasekey`, ensuring clean dirty-flashes over existing user installs.

### C. Audio Subsystem & Dolby Deduplication (`device/xiaomi/sm8350-common`)
* **Motorola Dolby Deduplication:**
  Commit `842db91` removed a duplicate Motorola Dolby inherit in `common.mk` which was causing conflicting audio effect UUID registrations and audio HAL crashes on SM8350.
* **Audio Offload Buffer Optimization:**
  Configured 64KB audio offload buffer (`audio.offload.buffer.size.kb=64`) in `vendor.prop` for glitch-free low-latency playback with lower DSP wakeups.
* **Bluetooth Audio Bitrate Uncapping:**
  Commit `f11e710` uncapped LDAC/aptX Adaptive bitrates for Hi-Res audio output.

### D. Play Integrity & AxSpoofManager (`frameworks/base`)
* **Automatic Keybox Seeding:**
  Commit `793e176` implemented a persistent fallback mechanism in `AxSpoofManager` that seeds a known-working certified keybox (`Yurikey67`) from `/product/security/`.
* **Play Integrity Pass:**
  Guarantees `MEETS_DEVICE_INTEGRITY` and `MEETS_BASIC_INTEGRITY` out-of-the-box, allowing Google Wallet, banking applications, and RCS messaging to operate without manual root modules.

### E. SystemUI Stability & Freeze Cures (`frameworks/base` & `vendor/addons`)
* **`ResourcesImpl` / `TypedArray` Graceful Fallback:**
  Commit `640c232` adds graceful null-checks and fallbacks when loading `ColorStateList`, eliminating the cyclical 1-second UI freeze when unlocking the phone or waking the screen.
* **`SignalIconLoader` Memory Leak Fix:**
  Commit `51eb56c` prevents leaking `BroadcastReceiver` and `ContentObserver` instances on the status bar cellular signal icon.
* **Material You Dark Theme Color Container Fallbacks:**
  Commits `3248207`, `29dc4fd`, and `bc10890` in `vendor/addons` define missing `materialColorSurfaceContainer` and `primary_device_default_dark` values, preventing SystemUI crashes when switching to pitch-black or night themes.

### F. Kernel & Root Hardware Features (`kernel/xiaomi/sm8350`)
* **BakaSU + Inlined SUSFS v1.5.5:**
  Root hiding and mount namespace isolation directly embedded in the kernel tree.
* **USB Webcam Mode (`CONFIG_USB_CONFIGFS_F_UVC=y`):**
  Commits `87f4070` and `845b1d4` enable the UVC function driver in `lahaina-qgki_defconfig`, allowing the phone to function as a plug-and-play 4K PC webcam.
* **Watchdog & Crash Suppression:**
  `panic_on_oops=0`, `panic=0`, and `# CONFIG_QCOM_FORCE_WDOG_BITE_ON_PANIC is not set` prevent modem/audio driver transients from triggering instant device brownouts.
