# SPDX-License-Identifier: GPL-3.0-or-later

name := bstash
version := 0.0.0

ifneq ($(filter extra-prereqs,$(.FEATURES)),extra-prereqs)
  $(error GNU Make >= 4.3 is required. Your Make version is $(MAKE_VERSION))
endif

MAKEFLAGS += -rR

printing_db := $(findstring p,$(firstword $(MAKEFLAGS)))
non_build_targets := clean distclean bootstrap menuconfig \
		     include/generated/% include/command/% \
		     build/cmdtree build/.commands \
		     build/kconfig/% build/probe/%

build/$(name):

include scripts/Makefile.probe
include scripts/Makefile.kconfig

ifeq ($(or $(printing_db),$(filter $(non_build_targets),$(MAKECMDGOALS))),)
  # We're compiling/linking.

  include build/probe/cc/features
  include build/probe/ld/features
  include build/kconfig/auto.conf
  include build/cmdtree

  CC != cat build/probe/cc/program
  LD != cat build/probe/ld/id

  UNIX != test $$(cat build/probe/host/id) != win32 && printf y
  WIN32 != test $$(cat build/probe/host/id) = win32 && printf y

  USE_GCC != test $$(cat build/probe/cc/id) = gcc && printf y
  USE_CLANG != test $$(cat build/probe/cc/id) = clang && printf y
endif

include scripts/Makefile.flags

lib-y := build/sqlite/sqlite3.o \
	 build/lib/atexit.o \
	 build/lib/err.o \
	 build/lib/list.o \
	 build/lib/log.o \
	 build/lib/parse_argv.o \
	 build/lib/rio.o \
	 build/lib/strbuf.o \
	 build/lib/xalloc.o

ifeq ($(CC_HAS_REALLOCARRAY),)
  lib-y += build/lib/reallocarray.o
endif

link-$(UNIX) := build/openssl/libcrypto.a
link-$(WIN32) := build/openssl/libcrypto.lib

include scripts/Makefile.command

ifneq ($(or $(CONFIG_ENABLE_TEST),$(printing_db)),)
  include scripts/Makefile.unitest
  include scripts/Makefile.cmdtest
endif

-include $(lib-y:.o=.d)

build/$(name): build/command/main/entry
	cp $< $@

build/sqlite/sqlite3.o: sqlite/build/sqlite3.c
	mkdir -p $(@D)
	$(CC) -O3 -w -c $< -o $@

build/openssl/libcrypto.a build/openssl/libcrypto.lib:

build/openssl/libcrypto.%: openssl/build/libcrypto.%
	mkdir -p $(@D)
	ln $< $@

sqlite/build/% openssl/build/%:
	$(error No $@ found. \
		Run 'scripts/build-$(firstword $(subst /, ,$@)).sh' first)

$(lib-y):

build/%.o: %.c \
		include/generated/build.h \
		include/generated/config.h \
		include/generated/features.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(addprefix -include ,$(filter include/generated/% \
						       include/command/%,$^)) \
	      -c $< -o $@

command/%_entry.c: | command/%.c
	./scripts/gen-command-entry.sh $(basename $(*F)) >$@

.force:

.PHONY: clean distclean

distclean: clean
	rm -rf build include/generated include/command

clean:
	{ \
		find build/lib build/command \
		     \( -name '*.o' -o -name '*.d' -o -name 'entry' \) \
		     -exec rm {} + ; \
		find include/command include/generated -type f -exec rm {} + ; \
		find command -name '*_entry.c' -exec rm {} + ; \
	} 2>/dev/null
	rm -f build/.commands build/cmdtree build/$(name)
