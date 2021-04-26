# GNUmakefile

PACKAGE_DIR=.
debug=on

include $(PACKAGE_DIR)/xcconfig/config.make


MODULES = mustache

ifeq ($(HAVE_SPM),yes)

all :
	$(SWIFT_BUILD_TOOL)

clean :
	$(SWIFT_CLEAN_TOOL)

distclean : clean
	rm -rf .build

tests : all
	$(SWIFT_TEST_TOOL)

else

MODULE_LIBS = \
  $(addsuffix $(SHARED_LIBRARY_SUFFIX),$(addprefix $(SHARED_LIBRARY_PREFIX),$(MODULES)))
MODULE_BUILD_RESULTS = $(addprefix $(SWIFT_BUILD_DIR)/,$(MODULE_LIBS))

all :
	@$(MAKE) -C Sources/mustache all

clean :
	rm -rf .build

distclean : clean

endif


# Docker stuff

# docker config
DOCKER_BUILD_DIR=".docker.build"
SWIFT_BUILD_IMAGE="swift:5.1.3"
#SWIFT_BUILD_IMAGE="swift:5.0.3"
#SWIFT_BUILD_IMAGE="helje5/arm64v8-swift-dev:latest"
#SWIFT_DOCKER_BUILD_DIR="$(DOCKER_BUILD_DIR)/aarch64-unknown-linux/$(CONFIGURATION)"
SWIFT_DOCKER_BUILD_DIR="$(DOCKER_BUILD_DIR)/x86_64-unknown-linux/$(CONFIGURATION)"
DOCKER_BUILD_PRODUCT="$(DOCKER_BUILD_DIR)/$(TOOL_NAME)"

SWIFT_SOURCES = Sources/*/*.swift

$(DOCKER_BUILD_PRODUCT): $(SWIFT_SOURCES)
	docker run --rm \
          -v "$(PWD):/src" \
          -v "$(PWD)/$(DOCKER_BUILD_DIR):/src/.build" \
          "$(SWIFT_BUILD_IMAGE)" \
          bash -c 'cd /src && swift build -c $(CONFIGURATION)'

docker-all: $(DOCKER_BUILD_PRODUCT)

docker-test: docker-all
	docker run --rm \
          -v "$(PWD):/src" \
          -v "$(PWD)/$(DOCKER_BUILD_DIR):/src/.build" \
          "$(SWIFT_BUILD_IMAGE)" \
          bash -c 'cd /src && swift test -c $(CONFIGURATION)'

docker-clean:
	rm $(DOCKER_BUILD_PRODUCT)	
	
docker-distclean:
	rm -rf $(DOCKER_BUILD_DIR)
