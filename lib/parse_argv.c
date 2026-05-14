// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * Copyright 2026 Jiamu Sun <39@barroit.sh>
 */

#include <stdio.h>
#include <stdlib.h>

#include "parse_argv.h"

/*
build/bstash --opt_a=aaa cmd_a --opt_b bbb \
	     -a -b 39 -abxyz miku -ab"xyz negi" miku
 */

int pa_parse_args(int argc, const char **argv,
		  struct pa_opt *opts, unsigned int flag)
{
	const char **next = argv;

	while (*next)
		puts(*next++);

	return 0;
}
