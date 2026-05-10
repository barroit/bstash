# SPDX-License-Identifier: GPL-3.0-or-later

from os import environ

def read_features(filename):
	file = open(filename)
	lines = file.read().splitlines()
	features = map(lambda line: line.split('=')[0], lines)

	file.close()
	return set(features)

objtree = environ['OBJTREE']

cc_features = read_features(f"{objtree}/probe/tool/cc_features")
ld_features = read_features(f"{objtree}/probe/tool/ld_features")

def first_line(file):
	file = open(file, 'r')
	line = file.readline().rstrip()

	file.close()
	return line

def warn_off(kconf, name):
	kconf.warn = False
	return ''

def host_id(kconf, name):
	return first_line(f"{objtree}/probe/host/id")

def host_arch(kconf, name):
	return first_line(f"{objtree}/probe/host/arch")

def host_name(kconf, name):
	return first_line(f"{objtree}/probe/host/name")

def repo_name(kconf, name):
	return first_line(f"{objtree}/probe/repo/name")

def repo_version(kconf, name):
	return first_line(f"{objtree}/probe/repo/version")

def cc_has_feature(kconf, name, feature):
	return 'y' if f"CC_HAS_{feature}" in cc_features else 'n'

def ld_has_feature(kconf, name, feature):
	return 'y' if f"LD_HAS_{feature}" in ld_features else 'n'

functions = {
	'warn-off': (warn_off, 0, 0),

	'host-id': (host_id, 0, 0),
	'host-arch': (host_arch, 0, 0),
	'host-name': (host_name, 0, 0),

	'repo-name': (repo_name, 0, 0),
	'repo-version': (repo_version, 0, 0),

	'cc-has-feature': (cc_has_feature, 1, 1),
	'ld-has-feature': (ld_has_feature, 1, 1),
}
