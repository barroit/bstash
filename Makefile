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
		    $(kconfig_dir)/% $(probe_dir)/%,$(MAKECMDGOALS)),),)
  # We're compiling/linking.

  include $(probe_dir)/cc/features
  include $(probe_dir)/ld/features
  include $(kconfig_dir)/deps/auto.conf

  CC != cat $(probe_dir)/cc/program
  LD != cat $(probe_dir)/ld/id

  UNIX != test $$(cat $(probe_dir)/host/id) != win32 && printf y
  WIN32 != test $$(cat $(probe_dir)/host/id) = win32 && printf y

  USE_GCC != test $$(cat $(probe_dir)/cc/id) = gcc && printf y
  USE_CLANG != test $$(cat $(probe_dir)/cc/id) = clang && printf y
endif

include scripts/Makefile.flags

lib-src := sqlite/build/sqlite3.c \
	   lib/atexit.c \
	   lib/err.c \
	   lib/list.c \
	   lib/log.c \
	   lib/parse_argv.c \
	   lib/rio.c \
	   lib/strbuf.c \
	   lib/xalloc.c

ifeq ($(CC_HAS_REALLOCARRAY),)
  lib-src += lib/reallocarray.c
endif

cmd-src := cmd/add.c \
	   cmd/help.c \
	   cmd/search.c \
	   cmd/version.c

main-src := main.c commands.c

link-src := openssl/build/libcrypto

main-obj := $(addprefix $(objtree)/,$(main-src:.c=.o))
cmd-obj := $(addprefix $(objtree)/,$(cmd-src:.c=.o))
lib-obj := $(addprefix $(objtree)/,$(lib-src:.c=.o))

link-$(UNIX) := $(addsuffix .a,$(link-src))
link-$(WIN32) := $(addsuffix .lib,$(link-src))

obj-y := $(main-obj) $(cmd-obj) $(lib-obj)

cmd-y := $(addprefix $(objtree)/bstash-,$(notdir $(basename $(cmd-obj))))

ifneq ($(CONFIG_ENABLE_TEST),)
  include scripts/Makefile.unitest
  include scripts/Makefile.cmdtest
endif

.PNONY: commands

commands: $(objtree)/$(name) $(cmd-y)

$(objtree)/$(name): $(obj-y) $(link-y)
	$(CC) $(LDFLAGS) -fuse-ld=$(LD) $^ -o $@

$(cmd-y):

$(filter-out bstash-version bstash-help,$(cmd-y)): $(link-y)

$(objtree)/bstash-%: $(objtree)/cmd/main_%.o $(objtree)/cmd/%.o $(lib-obj)
	$(CC) $(LDFLAGS) -fuse-ld=$(LD) $^ -o $@

cmd/main_%.c:
	./scripts/gen-command-entry.sh $* >$@

$(objtree)/sqlite/build/sqlite3.o: sqlite/build/sqlite3.c
	mkdir -p $(@D)
	$(CC) -O3 -w -c $< -o $@

sqlite/build/sqlite3.c openssl/build/libcrypto.a openssl/build/libcrypto.lib:
	$(error No $@ found. \
		Run 'scripts/build-$(firstword $(subst /, ,$@)).sh' first)

$(objtree)/main.o $(cmd-obj): $(objtree)/commands.o

$(cmd-obj) $(objtree)/commands.o: include/gen/commands.h

$(objtree)/%.o: %.c include/gen/build.h \
		include/gen/config.h include/gen/features.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(addprefix -include ,$(filter include/gen/%,$^)) \
	      -c $< -o $@

-include $(obj-y:.o=.d)

commands.c: build/commands
	printf '%s\n' $(notdir $(cmd-src)) | ./scripts/gen-commands_c.sh >$@

include/gen/commands.h: build/commands
	mkdir -p $(@D)
	printf '%s\n' $(notdir $(cmd-src)) | ./scripts/gen-commands_h.sh >$@

build/commands: .force
	@trap 'rm -f .tmp-$$$$' EXIT && \
	printf '%s\n' $(cmd-src) | sort >.tmp-$$$$ && \
	test -f $@ && diff .tmp-$$$$ $@ >/dev/null || mv .tmp-$$$$ $@

.force:

.PHONY: clean distclean

distclean: clean
	rm -rf build include/gen

clean:
	test -d $(objtree) && \
	find $(objtree) \( -name '*.o' -o -name '*.d' \) ! -name sqlite3.o \
			-exec rm {} + || true
	rm -f commands.c include/gen/*.h \
	      $(objtree)/commands $(objtree)/$(name) $(objtree)/$(name)-* \
	      $(objtree)/unitest/*
