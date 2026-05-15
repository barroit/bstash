# SPDX-License-Identifier: GPL-3.0-or-later

$(objtree)/command/%/entry: $(lib-y) $(link-y)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) -fuse-ld=$(LD) $(filter %.o %.a %.lib,$^) -o $@

include/command/%/d.h:
	mkdir -p $(@D)
	printf '%s\n' $| | sort | ./scripts/gen-d_h.sh $*/ >$@

$(objtree)/cmdtree: $(objtree)/.commands
	OBJTREE=$(objtree) ./scripts/build-cmdtree.py command/main.c >$@

$(objtree)/.commands: .force
	@mkdir -p $(@D)
	@trap 'rm -f .tmp-$$$$' EXIT && \
	find command -type f | sort >.tmp-$$$$ && \
	test -f $@ && diff .tmp-$$$$ $@ >/dev/null || \
	{ mv .tmp-$$$$ $@ && touch $@; }
