include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipyFolders
SwipyFolders_FILES = SwipyFolders.xm
SwipyFolders_FRAMEWORKS = UIKit Foundation
FOR_RELEASE=1

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += swipyfoldersprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
