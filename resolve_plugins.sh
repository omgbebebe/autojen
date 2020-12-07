#!/usr/bin/env bash
set -euo pipefail
set -x
plugins_list="plugins.list"

plugins_arg=""

while IFS= read -r plugin; do
  plugins_arg="${plugins_arg} -p ${plugin}"
done < "${plugins_list}"

jenkinsPlugins2nix -r latest ${plugins_arg} > plugins.nix
