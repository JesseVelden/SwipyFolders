include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SwipyFoldersPrefs
SwipyFoldersPrefs_FILES = SwipyFoldersPrefs.xm SFSliderTableCell.m SFSwitchTableCell.m SFCustomFolderSettingsController.m
SwipyFoldersPrefs_INSTALL_PATH = /Library/PreferenceBundles
SwipyFoldersPrefs_FRAMEWORKS = UIKit CoreGraphics
SwipyFoldersPrefs_PRIVATE_FRAMEWORKS = Preferences AppSupport

SwipyFoldersPrefs_LDFLAGS += -Wl,-segalign,4000




include $(THEOS_MAKE_PATH)/bundle.mk
include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipyFoldersPrefs.plist$(ECHO_END)

