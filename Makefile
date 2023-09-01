export ARCHS = arm64e

export TARGET = iphone:14.5:14.0

INSTALL_TARGET_PROCESSES = Music
#INSTALL_TARGET_PROCESSES = SpringBoard

export THEOS_PACKAGE_SCHEME = rootless

#export THEOS_DEVICE_IP = 192.168.86.21
export THEOS_DEVICE_IP = 10.0.0.231

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Melo

Melo_FILES = $(wildcard src/hooks/*.x src/hooks/*.xm src/objc/*/*.m)
Melo_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-everything
#Melo_FRAMEWORKS += AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += meloprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
