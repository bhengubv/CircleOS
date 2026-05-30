# Circle OS product makefile fragment.
#
# Included from a device's device.mk via:
#   $(call inherit-product, vendor/circle/circle.mk)
#
# This is the single source of truth for which Circle modules ship in an
# image. Adding a new Circle service is a two-line change: drop its module
# directory under vendor/circle/<area>/ and append the module name here.

# --- Privacy Framework (Step 1) ----------------------------------------
PRODUCT_PACKAGES += \
    services.circleprivacy \

# --- Inference Service (Step 2) — TODO ---------------------------------
# PRODUCT_PACKAGES += services.circleinference inferencebridge

# --- Personality Engine (Step 3) — TODO --------------------------------
# PRODUCT_PACKAGES += services.circlepersonality

# --- Mesh (Step 4) — TODO ----------------------------------------------
# PRODUCT_PACKAGES += services.circlemesh

# --- Security: Traffic Lobby, File DMZ, CDR, Zombie Map (Step 5) — TODO -
# PRODUCT_PACKAGES += services.circlesecurity traffic_lobby_app

# --- SDPKT Titanium (Step 6) — TODO ------------------------------------
# PRODUCT_PACKAGES += services.sdpkt sdpkt_titanium_app

# --- 8 Circle apps (Step 7) — TODO -------------------------------------
# PRODUCT_PACKAGES += \
#     CircleMessages Butler CircleSettings InferenceBridge \
#     PersonalityTile PersonalityEditor SdpktTitanium TrafficLobby

# --- OTA (Step 8) — TODO -----------------------------------------------
# PRODUCT_PACKAGES += services.circleota

# --- Design System (Step 9) — pulled in by apps that depend on it ------

# Property: identify this build as Circle OS at runtime.
PRODUCT_PROPERTY_OVERRIDES += \
    ro.circleos.build=1 \
    ro.circleos.version=0.2.0-dev \

# Inherit a permission XML that grants ourselves the privileges we need.
PRODUCT_COPY_FILES += \
    vendor/circle/permissions/privapp-permissions-circle.xml:system/etc/permissions/privapp-permissions-circle.xml
