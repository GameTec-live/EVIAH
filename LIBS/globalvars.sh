#!/usr/bin/env bash

set -e

function set_globals() {
  green=$(echo -en "\e[92m")
  yellow=$(echo -en "\e[93m")
  magenta=$(echo -en "\e[35m")
  red=$(echo -en "\e[91m")
  cyan=$(echo -en "\e[96m")
  white=$(echo -en "\e[39m")
}

function dependency_check() {
  local dep=( "${@}" )
  local packages
  echo "${yellow}Checking for the following dependencies:"
  for pkg in "${dep[@]}"; do
    echo -e "${cyan}● ${pkg} ${white}"
    [[ ! $(dpkg-query -f'${Status}' --show "${pkg}" 2>/dev/null) = *\ installed ]] && \
    packages+=("${pkg}")
  done
  if (( ${#packages[@]} > 0 )); then
    echo "${yellow}Installing the following dependencies:"
    for package in "${packages[@]}"; do
      echo -e "${cyan}● ${package} ${white}"
    done
    echo

    if sudo apt-get update --allow-releaseinfo-change && sudo DEBIAN_FRONTEND=noninteractive apt-get install "${packages[@]}" -yq; then
      echo "${green}Dependencies installed! ${white}"
    else
      echo "${red}Installing dependencies failed! ${white}"
      return 1
    fi
  else
    echo "${green}Dependencies already met! ${white}"
    return
  fi
}

function zfs_status() {
  if [ -f /etc/zfs/zpool.cache ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}
function staketool() {
  if [ -f $EVIAH_SRCDIR/staking-deposit-cli/deposit.sh ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function execclient() {
  if [ -f /etc/systemd/system/eth1.service ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function consensus() {
  if [ -f /etc/systemd/system/beacon-chain.service ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function grafana_status() {
  if [ -f /etc/systemd/system/grafana-server.service ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function promethius_status() {
  if [ -f /etc/prometheus/prometheus.yml ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function webui_status() {
  if [ -f /abc ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function chrony_status() {
  if [ -f /etc/chrony/chrony.conf ]; then
    echo -e "${green}Installed${white}"
  else
    echo -e "${red}Not Installed${white}"
  fi
}

function get_ip() {
  local ip
  ip=$(hostname -I | cut -d' ' -f1)
  echo -e "${green}${ip}${white}"
}

function Eviah_version() {
  local version
  cd "${KIAUH_SRCDIR}"
  #version="$(git describe HEAD --always --tags | cut -d "-" -f 1,2)"
  version="0.0"
  echo -e "${yellow}Eviah Version: ${white}${version}"
}