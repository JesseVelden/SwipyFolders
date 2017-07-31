BUNDLE_NAME = SwipyFoldersPrefs
SwipyFoldersPrefs_FILES = SwipyFoldersPrefs.xm SFSliderTableCell.m SFSwitchTableCell.m SFCustomFolderSettingsController.m
SwipyFoldersPrefs_INSTALL_PATH = /Library/PreferenceBundles

SwipyFoldersPrefs_PRIVATE_FRAMEWORKS = Preferences AppSupport


ifeq ($(SIMULATOR),1)
	# i386 slice is required for 32-bit iOS Simulator (iPhone 5, etc.)
	TARGET = simulator:clang
	ARCHS = x86_64 i386
else
	SwipyFoldersPrefs_FRAMEWORKS = UIKit CoreGraphics Foundation
endif


GO_EASY_ON_ME = 1
SwipyFoldersPrefs_LDFLAGS += -Wl,-segalign,4000
SwipyFolders_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipyFoldersPrefs.plist$(ECHO_END)
