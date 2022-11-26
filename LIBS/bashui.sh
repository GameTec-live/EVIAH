#!/usr/bin/env bash

set -e

function main_ui {
  echo -e "${yellow}/=======================================================\\"
  echo -e "|  ${white} Etherium Validator Installation and Update Helper ${yellow}  |"
  echo -e "\=======================================================/${white}"
  echo -e "/=======================================================\\"
  echo -e "|     ~~~~~~~~~~~~~~~ [ Main Menu ] ~~~~~~~~~~~~~~~     |"
  echo -e "|-------------------------------------------------------/"
  echo -e "|  0) [Install]      |       ZFS: $(zfs_status)"
  echo -e "|                    |"
  echo -e "|                    |       Staking tool: $(staketool)"
  echo -e "|  1) [Update]       |       Exec Client: $(execclient)"
  echo -e "|  2) [Remove]       |       Consensus Client: $(consensus)"
  echo -e "|  3) [Advanced]     |"
  echo -e "|  4) [Backup]       |"
  echo -e "|                    |       Chrony $(chrony_status)"
  echo -e "|  5) [Settings]     |       Prometheus: $(promethius_status)"
  echo -e "|                    |       Grafana: $(grafana_status)"
  echo -e "|                    |       WebUI: $(webui_status)"
  echo -e "|  $(Eviah_version)  |       IP: $(get_ip)"
  echo -e "|------------------------${red}Q) Quit${white}------------------------\\"
  echo -e "\=======================================================/"
}

function main_setup_ui {
  echo -e "${yellow}/=======================================================\\"
  echo -e "|  ${white} Etherium Validator Installation and Update Helper ${yellow}  |"
  echo -e "\=======================================================/${white}"
  echo -e "/=======================================================\\"
  echo -e "|       ~~~~~~~~~~~~~~~ [ Setup ] ~~~~~~~~~~~~~~~       |"
  echo -e "|-------------------------------------------------------/"
  echo -e "|  0) [ZFS]          |       ZFS: $(zfs_status)"
  echo -e "|                    |"
  echo -e "|  1) [Staking Tool] |       Staking tool: $(staketool)"
  echo -e "|  2) [Exec CLient]  |       Exec Client: $(execclient)"
  echo -e "|  3) [Consensus]    |       Consensus Client: $(consensus)"
  echo -e "|  4) [Chrony]       |"
  echo -e "|  5) [Prometheus]   |"
  echo -e "|  6) [Grafana]      |       Chrony $(chrony_status)"
  echo -e "|  7) [WebUI]        |       Prometheus: $(promethius_status)"
  echo -e "|                    |       Grafana: $(grafana_status)"
  echo -e "|                    |       WebUI: $(webui_status)"
  echo -e "|  $(Eviah_version)  |       IP: $(get_ip)"
  echo -e "|------------------------${red}B) Back${white}------------------------\\"
  echo -e "\=======================================================/"
}

function zfs_install_ui {
  echo -e "${yellow}/=======================================================\\"
  echo -e "|  ${white} Etherium Validator Installation and Update Helper ${yellow}  |"
  echo -e "\=======================================================/${white}"
  echo -e "/=======================================================\\"
  echo -e "|     ~~~~~~~~~~~~~~~ [ ZFS Setup ] ~~~~~~~~~~~~~~~     |"
  echo -e "|-------------------------------------------------------/"
  echo -e "|  0) [Raid 5]       |"
  echo -e "|  1) [Raid 1]       |"
  echo -e "|  2) [Raid 0]       |"
  echo -e "|  $(Eviah_version)  |"
  echo -e "|------------------------${red}B) Back${white}------------------------\\"
  echo -e "\=======================================================/"
}

function exec_install_ui {
  echo -e "${yellow}/=======================================================\\"
  echo -e "|  ${white} Etherium Validator Installation and Update Helper ${yellow}  |"
  echo -e "\=======================================================/${white}"
  echo -e "/=======================================================\\"
  echo -e "|  ~~~~~~~~~~~~~~~ [ Execution Setup ] ~~~~~~~~~~~~~~~  |"
  echo -e "|-------------------------------------------------------/"
  echo -e "|  0) [GETH]       |"
  echo -e "|  1) [Nethermind] |"
  echo -e "|  $(Eviah_version)|"
  echo -e "|------------------------${red}B) Back${white}------------------------\\"
  echo -e "\=======================================================/"
}

function consensus_install_ui {
  echo -e "${yellow}/=======================================================\\"
  echo -e "|  ${white} Etherium Validator Installation and Update Helper ${yellow}  |"
  echo -e "\=======================================================/${white}"
  echo -e "/=======================================================\\"
  echo -e "|  ~~~~~~~~~~~~~~~ [ Consensus Setup ] ~~~~~~~~~~~~~~~  |"
  echo -e "|-------------------------------------------------------/"
  echo -e "|  0) [Lighthouse] |"
  echo -e "|  1) [Prysm]      |"
  echo -e "|  $(Eviah_version)|"
  echo -e "|------------------------${red}B) Back${white}------------------------\\"
  echo -e "\=======================================================/"
}