# Fresh Server Setup & ROM Build Runbook (RisingOS / haydn)
**Target Device:** Xiaomi Mi 11X Pro / Redmi K40 Pro / POCO F3 Pro (`haydn` / `haydnin` - SM8350)  
**Maintainer:** Kishor TH ([@HI_JACK_U](https://t.me/HI_JACK_U) / `kichukic@gmail.com`)  
**Base:** RisingOS 9 (*elefthería* - Android 17 / SDK 37 / LineageOS 24.0 base)

---

## 1. Why This Guide Exists

When migrating to a new or re-provisioned build server (such as ServerHive EPYC), several non-standard components must be explicitly restored. Without them, standard `repo sync` will produce build failures:
1. **Empty `KernelSU` Submodule Directory:** Git submodule without `.gitmodules` leaves `drivers/kernelsu` dangling, failing `olddefconfig` at line 235 of `drivers/Kconfig`.
2. **Missing Custom Throne Tracker Hook:** BakaSU manager preinstall crown hook must be patched into `throne_tracker.c`.
3. **Official Signing Keys:** Must be restored to preserve data encryption and enable dirty-flashing over existing user data.
4. **Official Build Verification:** `RISING_MAINTAINER` must match `vendor/official_devices/OTA/risingOS.maintainers` without quotes.

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
Configure GitHub credentials for `kichukic` to allow pushing to device trees and addons:
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

## 8. Build & Release Execution

Launch inside a persistent tmux session:
```bash
tmux new -s rising
cd /serverhive/hijacku/RisingOS
source build/envsetup.sh
brunch haydn 2>&1 | tee /serverhive/hijacku/build.log
```

When completed successfully:
1. Output OTA zip located at `out/target/product/haydn/RisingOS-9-*-GAPPS-OFFICIAL-haydn-ota.zip`.
2. Output `boot.img` located at `out/target/product/haydn/boot.img`.
3. Sync to SourceForge:
   ```bash
   rsync -avP out/target/product/haydn/RisingOS-*-ota.zip out/target/product/haydn/boot.img \
       kichukic@frs.sourceforge.net:/home/frs/project/rising-unofficial/
   ```
4. Update `Rising_OTA` metadata (`haydn.json`) with MD5, SHA256, and timestamp, then git push to `kichukic/Rising_OTA`.
