# SPDX-License-Identifier: GPL-3.0-or-later

from os import environ

objtree = environ['OBJTREE']

repo_info_dir = f"{objtree}/probe/repo"
host_info_dir = f"{objtree}/probe/host"
tool_info_dir = f"{objtree}/probe/tool"

format_feature = lambda line: line.split('=')[0]

cc_feature_file = open(f"{tool_info_dir}/cc_features")
cc_feature_lines = cc_feature_file.read().splitlines()
cc_features = set(map(format_feature, cc_feature_lines))

ld_feature_file = open(f"{tool_info_dir}/ld_features")
ld_feature_lines = ld_feature_file.read().splitlines()
ld_features = set(map(format_feature, ld_feature_lines))

cc_feature_file.close()
ld_feature_file.close()

def first_line(file):
	file = open(file, 'r')
	line = file.readline().rstrip()

	file.close()
	return line

def warn_off(kconf, name):
	kconf.warn = False
	return ''

def host_id(kconf, name):
	return first_line(f"{host_info_dir}/id")

def host_arch(kconf, name):
	return first_line(f"{host_info_dir}/arch")

def host_name(kconf, name):
	return first_line(f"{host_info_dir}/name")

def repo_name(kconf, name):
	return first_line(f"{repo_info_dir}/name")

def repo_version(kconf, name):
	return first_line(f"{repo_info_dir}/version")

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
