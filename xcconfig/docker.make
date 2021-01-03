# GNUmakefile

# docker config

DOCKER=docker

#SWIFT_BUILD_IMAGE="swift:5.2.4"
#SWIFT_BUILD_IMAGE="swift:5.1.3"
#SWIFT_BUILD_IMAGE="ang/swift:nightly-5.3-bionic"
#SWIFT_BUILD_IMAGE="swiftlang/swift:nightly-5.3-xenial"
SWIFT_BUILD_IMAGE="swift:5.3.1"

DOCKER_BUILD_DIR=".docker$(SWIFT_BUILD_DIR)"
SWIFT_DOCKER_BUILD_DIR="$(DOCKER_BUILD_DIR)/x86_64-unknown-linux/$(CONFIGURATION)"
DOCKER_BUILD_PRODUCT="$(DOCKER_BUILD_DIR)/$(TOOL_NAME)"
