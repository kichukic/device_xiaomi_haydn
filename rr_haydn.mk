#
# Copyright (C) 2021 The LineageOS Project
# Copyright (C) 2026 ResurrectedRemixOS
#
# SPDX-License-Identifier: Apache-2.0
#

# Maintainer (must be set before common_full_phone.mk)
RR_MAINTAINER := hijack

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from haydn device
$(call inherit-product, device/xiaomi/haydn/device.mk)

# Inherit some common RR stuff.
$(call inherit-product, vendor/rr/config/common_full_phone.mk)

PRODUCT_BRAND := Xiaomi
PRODUCT_DEVICE := haydn
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_MODEL := M2012K11G
PRODUCT_NAME := rr_haydn

PRODUCT_BUILD_PROP_OVERRIDES +=     BuildDesc="haydn_global-user 14 UKQ1.231207.002 V816.0.19.0.UKKMIXM release-keys"     BuildFingerprint=Xiaomi/haydn_global/haydn:14/UKQ1.231207.002/V816.0.19.0.UKKMIXM:user/release-keys     DeviceProduct=haydn     SystemName=haydn_global

PRODUCT_SYSTEM_EXT_PROPERTIES +=     ro.rr.maintainer=hijack     ro.lineage.maintainer=hijack     persist.sys.usb.config=mtp

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

RISING_MAINTAINER := hijack
LINEAGE_MAINTAINER := hijack
KIC_MAINTAINER := hijack

# Prebuilt baked apps
PRODUCT_PACKAGES +=     hijackCUT     HyperOSGallery     HyperOSEditor

# HyperOS Gallery properties to satisfy Xiaomi API parameter requirements
PRODUCT_PRODUCT_PROPERTIES +=     ro.miui.ui.version.name=V816.0.19.0.UKKMIXM     ro.miui.ui.version.code=14     ro.miui.region=Global     ro.miui.build.region=Global

PRODUCT_BROKEN_VERIFY_USES_LIBRARIES := true

# Private release keys signing
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey
PRODUCT_EXTRA_RECOVERY_KEYS += vendor/lineage-priv/keys/releasekey
