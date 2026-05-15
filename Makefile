# SPDX-License-Identifier: GPL-3.0-or-later

name := bstash
version := 0.0.0

ifneq ($(filter extra-prereqs,$(.FEATURES)),extra-prereqs)
  $(error GNU Make >= 4.3 is required. Your Make version is $(MAKE_VERSION))
endif

MAKEFLAGS += -rR

objtree := build

$(objtree)/$(name):

include scripts/Makefile.probe
include scripts/Makefile.kconfig

ifeq ($(or $(or $(findstring q,$(firstword $(MAKEFLAGS))), \
		$(findstring p,$(firstword $(MAKEFLAGS)))), \
	   $(filter clean distclean bootstrap menuconfig \
		    include/gen/% include/command/% \
		    $(objtree)/cmdtree $(objtree)/.commands \
		    $(kconfig_dir)/% $(probe_dir)/%,$(MAKECMDGOALS)),),)
  # We're compiling/linking.

  include $(probe_dir)/cc/features
  include $(probe_dir)/ld/features
  include $(kconfig_dir)/deps/auto.conf
  include $(objtree)/cmdtree

  CC != cat $(probe_dir)/cc/program
  LD != cat $(probe_dir)/ld/id

  UNIX != test $$(cat $(probe_dir)/host/id) != win32 && printf y
  WIN32 != test $$(cat $(probe_dir)/host/id) = win32 && printf y

  USE_GCC != test $$(cat $(probe_dir)/cc/id) = gcc && printf y
  USE_CLANG != test $$(cat $(probe_dir)/cc/id) = clang && printf y
endif

include scripts/Makefile.flags

lib-y := $(objtree)/sqlite/build/sqlite3.o \
	 $(objtree)/lib/atexit.o \
	 $(objtree)/lib/err.o \
	 $(objtree)/lib/list.o \
	 $(objtree)/lib/log.o \
	 $(objtree)/lib/parse_argv.o \
	 $(objtree)/lib/rio.o \
	 $(objtree)/lib/strbuf.o \
	 $(objtree)/lib/xalloc.o

ifeq ($(CC_HAS_REALLOCARRAY),)
  lib-y += $(objtree)/lib/reallocarray.o
endif

link-$(UNIX) := $(objtree)/openssl/libcrypto.a
link-$(WIN32) := $(objtree)/openssl/libcrypto.lib

include scripts/Makefile.command

ifneq ($(CONFIG_ENABLE_TEST),)
  include scripts/Makefile.unitest
  include scripts/Makefile.cmdtest
endif

$(objtree)/$(name): $(objtree)/command/main/entry
	cp $< $@

$(objtree)/sqlite/build/sqlite3.o: sqlite/build/sqlite3.c
	mkdir -p $(@D)
	$(CC) -O3 -w -c $< -o $@

$(objtree)/openssl/libcrypto.%: openssl/build/libcrypto.%
	mkdir -p $(@D)
	ln $< $@

sqlite/build/sqlite3.c openssl/build/libcrypto.a openssl/build/libcrypto.lib:
	$(error No $@ found. \
		Run 'scripts/build-$(firstword $(subst /, ,$@)).sh' first)

$(objtree)/%.o: %.c \
		include/gen/build.h \
		include/gen/config.h \
		include/gen/features.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(addprefix -include ,$(filter include/gen/% \
						       include/command/%,$^)) \
	      -c $< -o $@

command/%_entry.c: | command/%.c
	./scripts/gen-command-entry.sh $(basename $(*F)) >$@

-include $(lib-y:.o=.d)

.force:

.PHONY: clean distclean

distclean: clean
	rm -rf build include/gen include/command

clean:
	{ \
		find $(objtree)/lib $(objtree)/command \
		     \( -name '*.o' -o -name '*.d' -o -name 'entry' \) \
		     -exec rm {} + ; \
		find include/command include/gen -type f -exec rm {} + ; \
		find command -name '*_entry.c' -exec rm {} + ; \
	} 2>/dev/null
	rm -f $(objtree)/.commands $(objtree)/cmdtree $(objtree)/$(name)
