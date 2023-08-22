#TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MeloPrefs

MeloPrefs_FILES = $(wildcard *.m)
MeloPrefs_FRAMEWORKS = UIKit
MeloPrefs_PRIVATE_FRAMEWORKS = Preferences
MeloPrefs_INSTALL_PATH = /Library/PreferenceBundles
MeloPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MeloPrefs.plist$(ECHO_END)
