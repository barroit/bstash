# SPDX-License-Identifier: GPL-3.0-or-later

name := bstash
version := 0.0.0

ifneq ($(filter extra-prereqs,$(.FEATURES)),extra-prereqs)
  $(error GNU Make >= 4.3 is required. Your Make version is $(MAKE_VERSION))
endif

MAKEFLAGS += -rR

build/$(name):

include scripts/Makefile.probe
include scripts/Makefile.kconfig

ifeq ($(findstring p,$(firstword $(MAKEFLAGS))),)
  ifneq ($(filter %.o %/entry miku,$(or $(MAKECMDGOALS),miku)),)
    # We're compiling/linking.

    include build/probe/cc/features
    include build/probe/ld/features
    include include/config/auto.conf
    include build/cmdtree

    CC != cat build/probe/cc/program
    LD != cat build/probe/ld/id

    UNIX != test $$(cat build/probe/host/id) != win32 && printf y
    WIN32 != test $$(cat build/probe/host/id) = win32 && printf y

    USE_GCC != test $$(cat build/probe/cc/id) = gcc && printf y
    USE_CLANG != test $$(cat build/probe/cc/id) = clang && printf y
  endif
endif

include scripts/Makefile.flags

lib-obj-y += build/sqlite/sqlite3.o \
	     build/lib/atexit.o \
	     build/lib/err.o \
	     build/lib/list.o \
	     build/lib/log.o \
	     build/lib/parse_argv.o \
	     build/lib/rio.o \
	     build/lib/strbuf.o \
	     build/lib/xalloc.o

ifeq ($(CC_HAS_REALLOCARRAY),)
  lib-obj-y += build/lib/reallocarray.o
endif

link-$(UNIX) := build/openssl/libcrypto.a
link-$(WIN32) := build/openssl/libcrypto.lib

include scripts/Makefile.command

ifeq ($(findstring p,$(firstword $(MAKEFLAGS))),)
  ifneq ($(CONFIG_ENABLE_TEST),)
    include scripts/Makefile.unitest
    include scripts/Makefile.cmdtest
  endif
endif

-include $(lib-obj-y:.o=.d1)
-include $(cmd-obj-y:.o=.d1)

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

$(lib-obj-y):

build/%.o: %.c include/generated/build.h include/generated/features.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(addprefix -include ,$(filter include/generated/% \
						       include/command/%,$^)) \
	      -c $< -o $@

command/%_entry.c: | command/%.c
	./scripts/gen-command-entry.sh $(basename $(*F)) >$@

build/%.d1: build/%.d
	./scripts/fixconfig.sh $(shell grep .h: $< | tr -d : | \
				       sed s,include/generated/config.h,,) \
			       $*.c <$< >$@

.force:

.PHONY: clean distclean

distclean:
	rm -rf build include/command include/config include/generated

clean:
	{ \
		find build/lib build/command \
		     \( -name '*.o' -o -name '*.d' -o -name 'entry' \) \
		     -exec rm {} + ; \
		find include/command include/config include/generated \
		     -type f -exec rm {} + ; \
		find command -name '*_entry.c' -exec rm {} + ; \
	} 2>/dev/null
	rm -f build/.commands build/cmdtree build/$(name)
