# SPDX-License-Identifier: GPL-3.0-or-later

name := bstash
version := 0.0.0

ifneq ($(filter extra-prereqs,$(.FEATURES)),extra-prereqs)
  $(error GNU Make >= 4.3 is required. Your Make version is $(MAKE_VERSION))
endif

MAKEFLAGS += -rR

objtree := build

printing_db := $(findstring p,$(firstword $(MAKEFLAGS)))
non_build_targets := clean distclean bootstrap menuconfig \
		     include/generated/% include/command/% \
		     $(objtree)/cmdtree $(objtree)/.commands \
		     $(objtree)/kconfig/% $(objtree)/probe/%

$(objtree)/$(name):

include scripts/Makefile.probe
include scripts/Makefile.kconfig

ifeq ($(or $(printing_db),$(filter $(non_build_targets),$(MAKECMDGOALS))),)
  # We're compiling/linking.

  include $(objtree)/probe/cc/features
  include $(objtree)/probe/ld/features
  include $(objtree)/kconfig/auto.conf
  include $(objtree)/cmdtree

  CC != cat $(objtree)/probe/cc/program
  LD != cat $(objtree)/probe/ld/id

  UNIX != test $$(cat $(objtree)/probe/host/id) != win32 && printf y
  WIN32 != test $$(cat $(objtree)/probe/host/id) = win32 && printf y

  USE_GCC != test $$(cat $(objtree)/probe/cc/id) = gcc && printf y
  USE_CLANG != test $$(cat $(objtree)/probe/cc/id) = clang && printf y
endif

include scripts/Makefile.flags

lib-y := $(objtree)/sqlite/sqlite3.o \
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

ifneq ($(or $(CONFIG_ENABLE_TEST),$(printing_db)),)
  include scripts/Makefile.unitest
  include scripts/Makefile.cmdtest
endif

-include $(lib-y:.o=.d)

$(objtree)/$(name): $(objtree)/command/main/entry
	cp $< $@

$(objtree)/sqlite/sqlite3.o: sqlite/build/sqlite3.c
	mkdir -p $(@D)
	$(CC) -O3 -w -c $< -o $@

$(objtree)/openssl/libcrypto.a $(objtree)/openssl/libcrypto.lib:

$(objtree)/openssl/libcrypto.%: openssl/build/libcrypto.%
	mkdir -p $(@D)
	ln $< $@

sqlite/build/% openssl/build/%:
	$(error No $@ found. \
		Run 'scripts/build-$(firstword $(subst /, ,$@)).sh' first)

$(lib-y):

$(objtree)/%.o: %.c \
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
		find $(objtree)/lib $(objtree)/command \
		     \( -name '*.o' -o -name '*.d' -o -name 'entry' \) \
		     -exec rm {} + ; \
		find include/command include/generated -type f -exec rm {} + ; \
		find command -name '*_entry.c' -exec rm {} + ; \
	} 2>/dev/null
	rm -f $(objtree)/.commands $(objtree)/cmdtree $(objtree)/$(name)
