TARGET = iphone:clang
ARCHS = armv7 armv7s arm64

DEBUG = 0
GO_EASY_ON_ME = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

TWEAK_NAME = SwipyFolders
SwipyFolders_FILES = SwipyFolders.xm
SwipyFolders_CFLAGS = -fno-objc-arc -Wno-deprecated-declarations
SwipyFolders_PRIVATE_FRAMEWORKS = AppSupport
SwipyFolders_LDFlags += -Wl,-segalign,4000
SUBPROJECTS += swipyfoldersprefs

ifeq ($(SIMULATOR),1)
	# i386 slice is required for 32-bit iOS Simulator (iPhone 5, etc.)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64 i386
else
	SwipyFolders_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
endif


include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

simulator::
	@make
	@echo Copying files to simject directory
	@cp $(THEOS_OBJ_DIR)/*.dylib /opt/simject
	@cp *.plist /opt/simject
	@echo Respringing simulator…
	@~/git/simject/bin/respring_simulator

after-install::
	install.exec "killall -9 SpringBoard"


