// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * Copyright 2026 Jiamu Sun <39@barroit.sh>
 */

#include "atexit.h"
#include "err.h"
#include "main/d.h"
#include "parse_argv.h"
#include "stdio.h"

int cmd_main(int argc, const char **argv)
{
	// struct pa_opt opts[] = {
	// 	{  }
	// }
	atexit_setup();

	// argc = pa_parse_args(argc, argv, , PA_STOP_BARE);
	puts(argv[0]);

	return 0;
}
