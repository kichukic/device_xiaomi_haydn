#
# BakaSU / ReSukiSU manager, preinstalled as a regular (non-privileged) product app.
#
# Notes:
#  - The module name must stay "<package>-<suffix>": the patched BakaSU kernel
#    (KernelSU/kernel/manager/throne_tracker.c) looks for exactly
#    /product/app/com.resukisu.resukisu-preinstalled/com.resukisu.resukisu-preinstalled.apk
#    and derives the package name from the directory name.
#  - The APK is installed byte-for-byte (LOCAL_REPLACE_PREBUILT_APK_INSTALLED):
#    it is v2-signed and its JNI libs are compressed, so any rewrite by the
#    build would invalidate the signature KernelSU checks.
#  - Bundled system apps don't get JNI libs extracted at runtime, so the
#    pre-extracted libs are installed next to the APK in lib/arm64/.
#  - Users can update it by installing a newer manager over it (same signing key).
#
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := com.resukisu.resukisu-preinstalled
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := BakaSU.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/BakaSU.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRODUCT_MODULE := true
LOCAL_DEX_PREOPT := false
LOCAL_MULTILIB := 64
LOCAL_PREBUILT_JNI_LIBS := \
    lib/arm64-v8a/libadbroot.so \
    lib/arm64-v8a/libandroidx.graphics.path.so \
    lib/arm64-v8a/libdatastore_shared_counter.so \
    lib/arm64-v8a/libkernelsu.so \
    lib/arm64-v8a/libksud.so
include $(BUILD_PREBUILT)
