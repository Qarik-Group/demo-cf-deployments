#!/usr/bin/env bash
# $1 - is always the config that may be passed from task
set -eu

CONFIG=$1

create_or_update() {

}

bail() {
	echo >&2 "$*"
	exit 2
}

test -n "${CONFIG}" || bail "SCRIPT_CONFIG parameter needs to be set for ASG."


exit 0