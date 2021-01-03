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

include $(PACKAGE_DIR)/xcconfig/docker.make

SWIFT_SOURCES = Sources/*/*.swift

$(DOCKER_BUILD_PRODUCT): $(SWIFT_SOURCES)
	$(DOCKER) run --rm -it \
          -v "$(PWD):/src" \
          -v "$(PWD)/$(DOCKER_BUILD_DIR):/src/.build" \
          "$(SWIFT_BUILD_IMAGE)" \
          bash -c 'cd /src && swift build -c $(CONFIGURATION)'

docker-all: $(DOCKER_BUILD_PRODUCT)

docker-test: docker-all
	$(DOCKER) run --rm -it \
          -v "$(PWD):/src" \
          -v "$(PWD)/$(DOCKER_BUILD_DIR):/src/.build" \
          "$(SWIFT_BUILD_IMAGE)" \
          bash -c 'cd /src && swift test -c $(CONFIGURATION)'

docker-clean:
	rm $(DOCKER_BUILD_PRODUCT)	
	
docker-distclean:
	rm -rf $(DOCKER_BUILD_DIR)
