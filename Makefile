export ARCHS = arm64e

#export TARGET = iphone:latest:14.0
export TARGET = iphone:14.5:14.0

INSTALL_TARGET_PROCESSES = Music
#INSTALL_TARGET_PROCESSES = SpringBoard

export THEOS_PACKAGE_SCHEME = rootless

# export THEOS_DEVICE_IP = 192.168.86.21
export THEOS_DEVICE_IP = 10.0.0.42
# export THEOS_DEVICE_IP = 192.168.1.116

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Melo

Melo_FILES = src/hooks/main.xmi $(wildcard src/objc/*/*.m) $(wildcard src/objc/*/*/*.m) $(wildcard src/objc/*/*/*/*.m)
Melo_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations -Wno-unused-value
Melo_FRAMEWORKS += AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += meloprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
