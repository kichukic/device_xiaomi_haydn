#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from haydn device
$(call inherit-product, device/xiaomi/haydn/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_BRAND := Xiaomi
PRODUCT_DEVICE := haydn
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_MODEL := M2012K11G
PRODUCT_NAME := lineage_haydn

PRODUCT_BUILD_PROP_OVERRIDES +=     BuildDesc="haydn_global-user 14 UKQ1.231207.002 V816.0.19.0.UKKMIXM release-keys"     BuildFingerprint=Xiaomi/haydn_global/haydn:14/UKQ1.231207.002/V816.0.19.0.UKKMIXM:user/release-keys     DeviceProduct=haydn     SystemName=haydn_global     RisingChipset="Snapdragon 888 5G"     RisingMaintainer="Kishor TH"

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

RISING_MAINTAINER := Kishor TH
RISING_BUILDTYPE := COMMUNITY


# Prebuilt baked apps
PRODUCT_PACKAGES +=     hijackCUT     HyperOSGallery     HyperOSEditor

# HyperOS Gallery properties to satisfy Xiaomi API parameter requirements
PRODUCT_PRODUCT_PROPERTIES +=     ro.miui.ui.version.name=V816.0.19.0.UKKMIXM     ro.miui.ui.version.code=14     ro.miui.region=Global     ro.miui.build.region=Global


# Enforce Google Suite
PRODUCT_PACKAGES +=     GoogleDialer     PrebuiltBugle     GoogleContacts     Photos     NexusLauncherRelease

# Inherit official signing keys if generated
-include vendor/lineage-priv/keys/keys.mk
