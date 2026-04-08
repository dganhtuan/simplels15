THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = simplels15prefs

simplels15prefs_FILES = TuanRootListController.m
simplels15prefs_FRAMEWORKS = UIKit
simplels15prefs_PRIVATE_FRAMEWORKS = Preferences
simplels15prefs_INSTALL_PATH = /Library/PreferenceBundles
simplels15prefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
