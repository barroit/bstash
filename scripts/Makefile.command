# SPDX-License-Identifier: GPL-3.0-or-later

$(objtree)/$(name)/%/entry: $(lib-y) $(objtree)/cmdtree
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) -fuse-ld=$(LD) $(filter %.o,$^) -o $@

include/%/d.h:
	mkdir -p $(@D)
	printf '%s\n' $^ | sort | ./scripts/gen-d_h.sh $*/ >$@

$(objtree)/cmdtree: $(objtree)/.commands
	OBJTREE=$(objtree) ./scripts/build-cmdtree.py main.c >$@

$(objtree)/.commands: .force
	@mkdir -p $(@D)
	@trap 'rm -f .tmp-$$$$' EXIT && \
	find main -type f | sort >.tmp-$$$$ && \
	test -f $@ && diff .tmp-$$$$ $@ >/dev/null || \
	{ mv .tmp-$$$$ $@ && touch $@; }
