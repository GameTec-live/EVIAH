#!/usr/bin/env bash
set -e
clear

EVIAH_SRCDIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
for script in "${EVIAH_SRCDIR}/LIBS/"*.sh; do . "${script}"; done
set_globals

deps=("git" "curl" "wget" "python3" "python3-pip" "python3-venv" "zfsutils-linux")
dependency_check "${deps[@]}"
main_menu