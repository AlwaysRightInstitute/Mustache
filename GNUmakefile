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
	@$(MAKE) -C Samples clean

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
