

export ARCHS = arm64e
export THEOS_PACKAGE_SCHEME = rootless

export THEOS_DEVICE_IP = 192.168.86.21

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Melo

Melo_FILES = _FILES = $(wildcard *.x *.m)
Melo_CFLAGS = -fobjc-arc
Melo_FRAMEWORKS += AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
