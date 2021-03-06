# GNUmakefile

swiftv=3
timeswiftc=no

NOZE_DID_INCLUDE_CONFIG_MAKE=yes

# Common configurations

SHARED_LIBRARY_PREFIX=lib

UNAME_S := $(shell uname -s)


# System specific configuration

ifeq ($(UNAME_S),Darwin)
  # lookup toolchain

  SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
  SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/swift-latest.xctoolchain/usr/bin
  ifeq ("$(wildcard $(SWIFT_TOOLCHAIN))","")
    SWIFT_TOOLCHAIN=$(shell dirname $(shell xcrun --toolchain swift-latest -f swiftc))
  endif

  # platform settings

  SHARED_LIBRARY_SUFFIX=.dylib
  DEFAULT_SDK=$(shell xcrun -sdk macosx --show-sdk-path)

  DEPLOYMENT_TARGET=x86_64-apple-macosx10.11
  SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -sdk $(DEFAULT_SDK)
  SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -target $(DEPLOYMENT_TARGET)

  SWIFT_RUNTIME_LIBS = swiftFoundation swiftDarwin swiftCore
else # Linux
  xcode=no

  # determine linux version
  OS=$(shell lsb_release -si | tr A-Z a-z)
  VER=$(shell lsb_release -sr)

  SHARED_LIBRARY_SUFFIX=.so

  SWIFT_RUNTIME_LIBS = Foundation swiftCore
endif


# Profile compile performance?

ifeq ($(timeswiftc),yes)
# http://irace.me/swift-profiling
SWIFT_INTERNAL_MAKE_BUILD_FLAGS += -Xfrontend -debug-time-function-bodies
endif


# Lookup Swift binary, decide whether to use SPM

ifneq ($(SWIFT_TOOLCHAIN),)
  SWIFT_TOOLCHAIN_PREFIX=$(SWIFT_TOOLCHAIN)/
  SWIFT_BIN=$(SWIFT_TOOLCHAIN_PREFIX)swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  ifeq ("$(wildcard $(SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
else
  SWIFT_TOOLCHAIN_PREFIX=
  SWIFT_BIN=swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  WHICH_SWIFT_BUILD_TOOL_BIN=$(shell which $(SWIFT_BUILD_TOOL_BIN))
  ifeq ("$(wildcard $(WHICH_SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
endif

ifeq ($(spm),no)
  USE_SPM=no
else
  ifeq ($(spm),yes)
    USE_SPM=yes
  else # detect
    USE_SPM=$(HAVE_SPM)
  endif
endif


ifeq ($(USE_SPM),no)
SWIFT_INTERNAL_BUILD_FLAGS += $(SWIFT_INTERNAL_MAKE_BUILD_FLAGS)
endif

SWIFTC=$(SWIFT_BIN)c


# Tests

SWIFT_INTERNAL_TEST_FLAGS := # $(SWIFT_INTERNAL_BUILD_FLAGS)

# Debug or Release?

ifeq ($(debug),on)
  CONFIGURATION=debug
  APXS_EXTRA_CFLAGS  += -g
  APXS_EXTRA_LDFLAGS += -g

  ifeq ($(USE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration debug
    SWIFT_REL_BUILD_DIR=.build/debug
  else
    SWIFT_INTERNAL_BUILD_FLAGS += -g
    SWIFT_REL_BUILD_DIR=.libs
  endif
else
  CONFIGURATION=release
  ifeq ($(USE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration release
    SWIFT_REL_BUILD_DIR=.build/release
  else
    SWIFT_REL_BUILD_DIR=.libs
  endif
endif
SWIFT_BUILD_DIR=$(PACKAGE_DIR)/$(SWIFT_REL_BUILD_DIR)


# Include/Link pathes

SWIFT_INTERNAL_INCLUDE_FLAGS += -I$(SWIFT_BUILD_DIR)
SWIFT_INTERNAL_LINK_FLAGS    += -L$(SWIFT_BUILD_DIR)


# Note: the invocations must not use swift-build, but 'swift build'
SWIFT_BUILD_TOOL=$(SWIFT_BIN) build $(SWIFT_INTERNAL_BUILD_FLAGS)
SWIFT_TEST_TOOL =$(SWIFT_BIN) test  $(SWIFT_INTERNAL_TEST_FLAGS)
SWIFT_CLEAN_TOOL=$(SWIFT_BIN) build --clean
