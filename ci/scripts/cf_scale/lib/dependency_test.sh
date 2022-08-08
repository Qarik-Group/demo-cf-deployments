#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

PATH=".:lib:$PATH"

# shellcheck source-path=SCRIPTDIR
source dependency.sh

debug::enable "checks"
dependency::add_tool_check "jq" "1.5" "jq --version"
dependency::add_tool_check "cf" "8" "cf --version"
dependency::add_tool_check "thisoneshouldfail" "8" "xf --version" 

dependency::checks jq cf thisoneshouldfail

exit 0


