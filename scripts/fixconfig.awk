#!/bin/awk -f
# SPDX-License-Identifier: GPL-3.0-or-later

$0 !~ /\\$/ && ! done {
	done = 1

	print $0 " \\"

	system("grep -Eo CONFIG_[_0-9A-Z]+ " src " | " \
	       "tr [:upper:]_ [:lower:]/ | " \
	       "sed -e '$!s|.*| $(wildcard include/&.h) \\\\|' " \
	       "-e '$s|.*| $(wildcard include/&.h)|'")
	print ""
	next
}

$0 != "include/generated/config.h:" {
	sub("include/generated/config.h", "")
	print
}
