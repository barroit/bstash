#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -e

trap 'rm -f .tmp-$$*' EXIT

scripts=$(dirname $0)

test -n "$cc" && test -n "$ld" && cat <<EOF >>.tmp-$$.in
$CC	$LD
EOF

test $(python3 -c 'import sys; print(sys.platform)') = darwin && \
cat <<EOF >>.tmp-$$.in
clang	ld64.lld
EOF

test $(python3 -c 'import sys; print(sys.platform)') = win32 && \
cat <<EOF >>.tmp-$$.in
clang	ld.lld
EOF

cat <<EOF >>.tmp-$$.in
gcc	ld.bfd
clang	ld.lld
EOF

while read cc ld; do
	cc=$($scripts/which.py $cc) || continue
	ld=$($scripts/which.py $ld) || continue

	$scripts/probe-cc.sh $cc >.tmp-$$ || continue
	$scripts/probe-ld.sh $ld $(awk '{ print $1 " " $2 }' .tmp-$$) \
			     >>.tmp-$$ || continue

	cat .tmp-$$
	exit
done <.tmp-$$.in

exit 1
