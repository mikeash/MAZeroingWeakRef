include $(GNUSTEP_MAKEFILES)/common.make

CC=clang

LIBRARY_NAME = libweakref
libweakref_HEADER_FILES_DIR = Source
libweakref_HEADER_FILES = \
    MAZeroingWeakRef.h \
    MAWeakArray.h \
    MAWeakDictionary.h \
    MAZeroingWeakProxy.h \
    MAZeroingWeakRefNativeZWRNotAllowedTable.h
libweakref_HEADER_FILES_INSTALL_DIR = MAZeroingWeakRef

libweakref_OBJC_FILES = \
    Source/MAWeakArray.m \
    Source/MAWeakDictionary.m \
    Source/MAZeroingWeakProxy.m \
    Source/MAZeroingWeakRef.m

libweakref_RESOURCE_FILES =
libweakref_CFLAGS = -fblocks -fobjc-nonfragile-abi -g -Os
libweakref_OBJCFLAGS = -fblocks -fobjc-nonfragile-abi -DNS_BLOCKS_AVAILABLE -g -Os
libweakref_OBJC_LIBS = 
libweakref_LDFLAGS = -g -Os
libweakref_INCLUDE_DIRS = -ISource/

include $(GNUSTEP_MAKEFILES)/library.make

