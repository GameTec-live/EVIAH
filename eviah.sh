#!/usr/bin/env bash
set -e
clear

EVIAH_SRCDIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
for script in "${EVIAH_SRCDIR}/LIBS/"*.sh; do . "${script}"; done
set_globals

deps=("git" "curl" "wget" "python3" "python3-pip" "python3-venv" "zfsutils-linux" "software-properties-common")
dependency_check "${deps[@]}"
clear
echo "${green}Dependencies installed! ${white}"
echo "its recommended to use the goerli testnet for testing purposes"
  read -p "${cyan}Use testnet? (y/n) " yn
  case $yn in
    [yY] ) echo "Setting network to goerli"; network="goerli";;
    [nN] ) echo "Setting network to mainnet"; network="mainnet";;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
echo $network
main_menu
