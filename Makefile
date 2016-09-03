include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipyFolders
SwipyFolders_FILES = SwipyFolders.xm
SwipyFolders_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
SwipyFolders_PRIVATE_FRAMEWORKS = AppSupport
SwipyFolders_LDFlags += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += swipyfoldersprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
