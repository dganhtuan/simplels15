THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:12.2
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = simplels15

simplels15_FILES = $(shell find Sources/simplels15 -name '*.swift') $(shell find Sources/simplels15C -name '*.m' -o -name '*.c' -o -name '*.mm' -o -name '*.cpp')
simplels15_SWIFTFLAGS = -ISources/simplels15C/include
simplels15_CFLAGS = -fobjc-arc -ISources/simplels15C/include

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += simplels15prefs
include $(THEOS_MAKE_PATH)/aggregate.mk
