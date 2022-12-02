#!/usr/bin/env bash

set -e

function zfs_raid0() {
  drives=""
  for drive in "${@}"; do
    drives="$drives /dev/$drive"
  done
  echo $drives
  read -p "Confirm destructive action on drives $drives? (y/n) " yn
  case $yn in
    [yY] ) echo "Formatting drives and creating pool";
      sudo zpool create eth-storage $drives
      sudo chmod 777 /eth-storage;;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function zfs_raid1() {
  drives=""
  for drive in "${@}"; do
    drives="$drives /dev/$drive"
  done
  echo $drives
  read -p "Confirm destructive action on drives $drives? (y/n) " yn
  case $yn in
    [yY] ) echo "Formatting drives and creating pool";
      sudo zpool create eth-storage mirror $drives
      sudo chmod 777 /eth-storage;;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function zfs_raid5() {
  drives=""
  for drive in "${@}"; do
    drives="$drives /dev/$drive"
  done
  echo $drives
  read -p "Confirm destructive action on drives $drives? (y/n) " yn
  case $yn in
    [yY] ) echo "Formatting drives and creating pool";
      sudo zpool create eth-storage raidz $drives
      sudo chmod 777 /eth-storage;;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function zfs_install_menu() {
  clear
  zfs_install_ui
  local action
  local drives
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      0)clear
        echo "Raid 5"
        lsblk
        read -p "${cyan}####### Enter the drives to add (Seperated by spaces, eg: sda sdb sdc):${white} " drives
        drives=($drives)
        zfs_raid5 "${drives[@]}"
        zfs_install_ui;;
      1)clear
        echo "Raid 1"
        lsblk
        read -p "${cyan}####### Enter the drives to add (Seperated by spaces, eg: sda sdb sdc):${white} " drives
        drives=($drives)
        zfs_raid1 "${drives[@]}"
        break;;
      2) clear
        echo "Raid 0"
        lsblk
        read -p "${cyan}####### Enter the drives to add (Seperated by spaces, eg: sda sdb sdc):${white} " drives
        drives=($drives)
        zfs_raid0 "${drives[@]}"
        break;;
      B|b)
        clear; main_setup; break;;
    esac
  done
  zfs_install_menu
}

function exec_geth() {
  echo "generating secret file"
  sudo mkdir -p /secrets
  openssl rand -hex 32 | tr -d "\n" | sudo tee /secrets/jwtsecret
  sudo chmod 644 /secrets/jwtsecret
  echo "installing geth"
  sudo add-apt-repository -y ppa:ethereum/ethereum
  sudo apt-get update -y
  sudo apt-get install ethereum -y
  echo "setting up systemd service"
cat > $EVIAH_SRCDIR/eth1.service << EOF
[Unit]
Description=Geth Execution Layer Client service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
Restart=on-failure
RestartSec=3
TimeoutSec=300
ExecStart=/usr/bin/geth \
  --<networkhere> \
  --metrics \
  --pprof \
  --datadir /eth-storage \
  --authrpc.jwtsecret=/secrets/jwtsecret

[Install]
WantedBy=multi-user.target
EOF
  sed -i "s/<networkhere>/$network/g" $EVIAH_SRCDIR/eth1.service
  sudo mv $EVIAH_SRCDIR/eth1.service /etc/systemd/system/eth1.service
  sudo chmod 644 /etc/systemd/system/eth1.service
  sudo systemctl daemon-reload
  sudo systemctl enable eth1
  echo "starting geth"
  sudo systemctl start eth1
  echo "geth installed"
  echo "To access the geth api, use the following command: geth attach 127.0.0.1:8545"
}

function exec_nethermind() {
  echo "generating secret file"
  sudo mkdir -p /secrets
  openssl rand -hex 32 | tr -d "\n" | sudo tee /secrets/jwtsecret
  sudo chmod 644 /secrets/jwtsecret
  echo "installing nethermind"
  deps=("curl" "libsnappy-dev" "libc6-dev" "libc6" "unzip" "jq")
  dependency_check "${deps[@]}"
  cd $EVIAH_SRCDIR
  curl -s https://api.github.com/repos/NethermindEth/nethermind/releases/latest | jq -r ".assets[] | select(.name) | .browser_download_url" | grep linux-amd64  | xargs wget -q --show-progress
  unzip -o nethermind*.zip -d $EVIAH_SRCDIR/nethermind
  rm nethermind*linux*.zip
  echo "setting up systemd service"
  if [ "$network" = "goerli" ]; then
    cat > $EVIAH_SRCDIR/eth1.service << EOF
[Unit]
Description=Nethermind Execution Layer Client service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
Restart=on-failure
RestartSec=3
KillSignal=SIGINT
TimeoutStopSec=300
WorkingDirectory=$EVIAH_SRCDIR/nethermind
ExecStart=$EVIAH_SRCDIR/nethermind/Nethermind.Runner \
  --baseDbPath $EVIAH_SRCDIR/.nethermind \
  --config goerli \
  --Metrics.Enabled true \
  --Metrics.ExposePort 6060 \
  --Metrics.IntervalSeconds 10000 \
  --Sync.SnapSync true \
  --datadir /eth-storage \
  --JsonRpc.JwtSecretFile /secrets/jwtsecret

[Install]
WantedBy=multi-user.target
EOF
  else
    cat > $EVIAH_SRCDIR/eth1.service << EOF
[Unit]
Description=Nethermind Execution Layer Client service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$USER
Restart=on-failure
RestartSec=3
KillSignal=SIGINT
TimeoutStopSec=300
WorkingDirectory=$EVIAH_SRCDIR/nethermind
ExecStart=$EVIAH_SRCDIR/nethermind/Nethermind.Runner \
  --baseDbPath $EVIAH_SRCDIR/.nethermind \
  --Metrics.Enabled true \
  --Metrics.ExposePort 6060 \
  --Metrics.IntervalSeconds 10000 \
  --Sync.SnapSync true \
  --datadir /eth-storage \
  --JsonRpc.JwtSecretFile /secrets/jwtsecret

[Install]
WantedBy=multi-user.target
EOF
  fi

  sudo mv $EVIAH_SRCDIR/eth1.service /etc/systemd/system/eth1.service
  sudo chmod 644 /etc/systemd/system/eth1.service
  sudo systemctl daemon-reload
  sudo systemctl enable eth1
  sudo ln -s /usr/lib/x86_64-linux-gnu/libdl.so.2 /usr/lib/x86_64-linux-gnu/libdl.so
  echo "starting nethermind"
  sudo systemctl start eth1
  echo "nethermind installed"
}

function exec_install_menu() {
  clear
  exec_install_ui
  local action
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      0)clear
        exec_geth
        exec_install_ui;;
      1)clear
        exec_nethermind
        break;;
      B|b)
        clear; main_setup; break;;
    esac
  done
  exec_install_menu
}

function consensus_lighthouse() {
  echo "installing lighthouse"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
  echo export PATH="$HOME/.cargo/bin:$PATH" >> ~/.bashrc
  source ~/.bashrc
  source "$HOME/.cargo/env"
  deps=("git" "gcc" "g++" "make" "cmake" "pkg-config" "libssl-dev" "libclang-dev" "clang" "protobuf-compiler")
  dependency_check "${deps[@]}"
  cd $EVIAH_SRCDIR
  git clone https://github.com/sigp/lighthouse.git
  cd lighthouse
  git fetch --all && git checkout stable && git pull
  make
  echo "Verifying lighthouse installation"
  lighthouse --version
  echo "importing keys"
  echo "${yellow}Please enter the password used for the validator keys or it wont work!${white}"
  if [ "$network" = "mainnet" ]; then
    lighthouse account validator import --network mainnet --directory=$EVIAH_SRCDIR/staking-deposit-cli/validator_keys
    lighthouse account_manager validator list --network mainnet
  else
    lighthouse account validator import --network prater --directory=$EVIAH_SRCDIR/staking-deposit-cli/validator_keys
    lighthouse account_manager validator list --network prater
  fi
  echo "you may now forward ports 9000 tcp/udp and port 30303 tcp/udp and then press enter to continue"
  read -p "${cyan}####### Press enter to continue:${white} " action
  echo "setting up systemd service"
  cd $EVIAH_SRCDIR
  cat > $EVIAH_SRCDIR/beacon-chain.service << EOF
[Unit]
Description=eth beacon chain service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=<USER>
Restart=on-failure
ExecStart=<HOME>/.cargo/bin/lighthouse bn \
  --network <networkhere> \
  --staking \
  --validator-monitor-auto \
  --metrics \
  --checkpoint-sync-url=https://beaconstate.info \
  --execution-endpoint http://127.0.0.1:8551 \
  --execution-jwt /secrets/jwtsecret

[Install]
WantedBy=multi-user.target
EOF
  if [ "$network" = "mainnet" ]; then
     sed -i "s/<networkhere>/mainnet/g" $EVIAH_SRCDIR/beacon-chain.service
  else
     sed -i "s/<networkhere>/prater/g" $EVIAH_SRCDIR/beacon-chain.service
  fi
  sudo mv $EVIAH_SRCDIR/beacon-chain.service /etc/systemd/system/beacon-chain.service
  sudo sed -i /etc/systemd/system/beacon-chain.service -e "s:<HOME>:${HOME}:g"
  sudo sed -i /etc/systemd/system/beacon-chain.service -e "s:<USER>:${USER}:g"
  sudo chmod 644 /etc/systemd/system/beacon-chain.service
  sudo systemctl daemon-reload
  sudo systemctl enable beacon-chain
  echo "starting lighthouse"
  sudo systemctl start beacon-chain
  echo "Setting up the validator"
  cat > $EVIAH_SRCDIR/validator.service << EOF
[Unit]
Description=eth validator service
Wants=network-online.target beacon-chain.service
After=network-online.target

[Service]
Type=simple
User=<USER>
Restart=on-failure
ExecStart=<HOME>/.cargo/bin/lighthouse vc \
 --network <networkhere> \
 --metrics \
 --suggested-fee-recipient 0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS

[Install]
WantedBy=multi-user.target
EOF
  if [ "$network" = "mainnet" ]; then
     sed -i "s/<networkhere>/mainnet/g" $EVIAH_SRCDIR/validator.service
  else
     sed -i "s/<networkhere>/prater/g" $EVIAH_SRCDIR/validator.service
  fi
  sudo mv $EVIAH_SRCDIR/validator.service /etc/systemd/system/validator.service
  sudo sed -i /etc/systemd/system/validator.service -e "s:<HOME>:${HOME}:g"
  sudo sed -i /etc/systemd/system/validator.service -e "s:<USER>:${USER}:g"
  echo "Please enter the eth1 address you want to receive your validator fees"
  local eth1_address
  read -p "${cyan}####### Enter eth1 address:${white} " eth1_address
  sudo sed -i /etc/systemd/system/validator.service -e "s:0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS:${eth1_address}:g"
  echo "Upadting the validator service"
  sudo chmod 644 /etc/systemd/system/validator.service
  sudo systemctl daemon-reload
  sudo systemctl enable validator
  echo "starting validator"
  sudo systemctl start validator
}

function consensus_prysm(){
  echo "installing prysm"
  cd $EVIAH_SRCDIR
  mkdir $EVIAH_SRCDIR/prysm && cd $EVIAH_SRCDIR/prysm
  curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh --output prysm.sh && chmod +x prysm.sh
  echo "You may now forward ports 12000 udp, port 13000 tcp and port 30303 tcp/udp and then press enter to continue"
  read -p "${cyan}####### Press enter to continue:${white} " action
  echo "importing keys"
  if [ "$network" = "mainnet" ]; then
    $EVIAH_SRCDIR/prysm/prysm.sh validator accounts import --mainnet --keys-dir=$EVIAH_SRCDIR/staking-deposit-cli/validator_keys
    echo "verifying import"
    $EVIAH_SRCDIR/prysm/prysm.sh validator accounts list --mainnet
  else
    $EVIAH_SRCDIR/prysm/prysm.sh validator accounts import --prater --keys-dir=$EVIAH_SRCDIR/staking-deposit-cli/validator_keys
    echo "verifying import"
    $EVIAH_SRCDIR/prysm/prysm.sh validator accounts list --prater
  fi
  echo "setting up systemd service"
  cat > $EVIAH_SRCDIR/beacon-chain.service << EOF
[Unit]
Description=eth consensus layer beacon chain service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=<USER>
Restart=on-failure
ExecStart=<HOME>/prysm/prysm.sh beacon-chain \
  --<networkhere> \
  --datadir /eth-storage \
  --checkpoint-sync-url=https://beaconstate.info \
  --genesis-beacon-api-url=https://beaconstate.info \
  --execution-endpoint=http://localhost:8551 \
  --jwt-secret=/secrets/jwtsecret \
  --suggested-fee-recipient=0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS \
  --accept-terms-of-use

[Install]
WantedBy=multi-user.target
EOF
  if [ "$network" = "mainnet" ]; then
     sed -i "s/<networkhere>/mainnet/g" $EVIAH_SRCDIR/beacon-chain.service
  else
     sed -i "s/<networkhere>/prater/g" $EVIAH_SRCDIR/beacon-chain.service
  fi
  sudo mv $EVIAH_SRCDIR/beacon-chain.service /etc/systemd/system/beacon-chain.service
  sudo sed -i /etc/systemd/system/beacon-chain.service -e "s:<HOME>:${EVIAH_SRCDIR}:g"
  sudo sed -i /etc/systemd/system/beacon-chain.service -e "s:<USER>:${USER}:g"
  echo "Please enter the eth1 address you want to receive your validator fees"
  local eth1_address
  read -p "${cyan}####### Enter eth1 address:${white} " eth1_address
  sudo sed -i /etc/systemd/system/beacon-chain.service -e "s:0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS:${eth1_address}:g"
  echo "Upadting the beacon-chain service"
  sudo chmod 644 /etc/systemd/system/beacon-chain.service
  sudo systemctl daemon-reload
  sudo systemctl enable beacon-chain
  echo "starting prysm"
  sudo systemctl start beacon-chain
  echo "Final Prysm configuration"
  echo "Please enter your prysm only password"
  local prysm_password
  read -p "${cyan}####### Enter prysm password:${white} " prysm_password
  echo "$prysm_password" > $HOME/.eth2validators/validators-password.txt
  sudo chmod 600 $HOME/.eth2validators/validators-password.txt
  cat $HOME/.eth2validators/validators-password.txt
  echo "secure eraseing history..."
  shred -u ~/.bash_history && touch ~/.bash_history
  echo "Setting up systemd service"
  cat > $EVIAH_SRCDIR/validator.service << EOF
[Unit]
Description=eth validator service
Wants=network-online.target beacon-chain.service
After=network-online.target

[Service]
Type=simple
User=<USER>
Restart=on-failure
ExecStart=<HOME>/prysm/prysm.sh validator \
  --<networkhere> \
  --datadir /eth-storage \
  --accept-terms-of-use \
  --wallet-password-file <passfile>/.eth2validators/validators-password.txt \
  --suggested-fee-recipient 0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS

[Install]
WantedBy=multi-user.target
EOF
  if [ "$network" = "mainnet" ]; then
     sed -i "s/<networkhere>/mainnet/g" $EVIAH_SRCDIR/validator.service
  else
     sed -i "s/<networkhere>/prater/g" $EVIAH_SRCDIR/validator.service
  fi
  sudo mv $EVIAH_SRCDIR/validator.service /etc/systemd/system/validator.service
  sudo sed -i /etc/systemd/system/validator.service -e "s:0x_CHANGE_THIS_TO_MY_ETH_FEE_RECIPIENT_ADDRESS:${eth1_address}:g"
  sudo sed -i /etc/systemd/system/validator.service -e "s:<HOME>:${EVIAH_SRCDIR}:g"
  sudo sed -i /etc/systemd/system/validator.service -e "s:<passfile>:${HOME}:g"
  sudo sed -i /etc/systemd/system/validator.service -e "s:<USER>:${USER}:g"
  sudo chmod 644 /etc/systemd/system/validator.service
  sudo systemctl daemon-reload
  sudo systemctl enable validator
  echo "starting validator"
  sudo systemctl start validator
  echo "Prysm installed"
}

function consensus_install_menu() {
  clear
  consensus_install_ui
  local action
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      0)clear
        consensus_lighthouse
        consensus_install_ui;;
      1)clear
        consensus_prysm
        break;;
      B|b)
        clear; main_setup; break;;
    esac
  done
  consensus_install_menu
}

function staking_tool {
  echo "Building staking tool"
  cd $EVIAH_SRCDIR
  git clone https://github.com/ethereum/staking-deposit-cli
  cd staking-deposit-cli
  sed -i sed -i "s/exit 1/ /g" $EVIAH_SRCDIR/eth1.service $EVIAH_SRCDIR/staking-deposit-cli/deposit.sh
  sudo ./deposit.sh install $?
  if [ "$network" = "mainnet" ]; then
     sudo ./deposit.sh new-mnemonic --chain mainnet
  else
     sudo ./deposit.sh new-mnemonic --chain prater
  fi
  echo "Please save your mnemonic phrase in a safe place"
  echo "You will need a metamask wallet for the next steps: https://metamask.io/"
  echo "Skip through this website, until youve reached the upload field. (Altough it doesnt hurt to read through it)"
  if [ "$network" = "mainnet" ]; then
     echo "https://launchpad.ethereum.org/en/overview"
  else
     echo "https://goerli.launchpad.ethereum.org/en/overview"
  fi
  sudo chmod 777 $EVIAH_SRCDIR/staking-deposit-cli/validator_keys -R
  echo "Once youve reached the upload field, press enter to continue"
  read -p "${cyan}####### Press enter to continue:${white} " action
  echo "Now please open the local webserver at $(get_ip)"
  echo "Download the deposit_data-#########.json file and upload it to the launchpad website. You have 2 minutes to do so after pressing Enter."
  read -p "${cyan}####### Press enter to continue:${white} " action
  cd ./validator_keys
  sudo python3 -m http.server 80 &
  sleep 120
  sudo kill $!
  cd ..
  echo "After uploading, connect your metamask wallet to the launchpad website and press enter to continue"
  read -p "${cyan}####### Press enter to continue:${white} " action
  echo "${green}Staking tool set up!"
  cd $EVIAH_SRCDIR
}

function chrony_install() {
  deps=("chrony")
  dependency_check "${deps[@]}"
  cat > $EVIAH_SRCDIR/chrony.conf << EOF
pool time.google.com       iburst minpoll 1 maxpoll 2 maxsources 3
pool ntp.ubuntu.com        iburst minpoll 1 maxpoll 2 maxsources 3
pool us.pool.ntp.org     iburst minpoll 1 maxpoll 2 maxsources 3

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 5.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 0.1 -1
EOF
  sudo mv $EVIAH_SRCDIR/chrony.conf /etc/chrony/chrony.conf
  echo "Starting chrony"
  sudo systemctl restart chrony.service
  sudo systemctl enable chrony.service
  echo "Chrony installed"
}

function prometheus_install() {
  echo "Installing prometheus"
  cd $EVIAH_SRCDIR
  deps=("prometheus" "prometheus-node-exporter")
  dependency_check "${deps[@]}"
  sudo systemctl enable prometheus.service prometheus-node-exporter.service
  if [ -d $EVIAH_SRCDIR/lighthouse ]; then
    cat > $EVIAH_SRCDIR/prometheus.yml << EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
   - job_name: 'node_exporter'
     static_configs:
       - targets: ['localhost:9100']
   - job_name: 'nodes'
     metrics_path: /metrics
     static_configs:
       - targets: ['localhost:5054']
   - job_name: 'validators'
     metrics_path: /metrics
     static_configs:
       - targets: ['localhost:5064']
EOF
  else
    cat > $EVIAH_SRCDIR/prometheus.yml << EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
   - job_name: 'node_exporter'
     static_configs:
       - targets: ['localhost:9100']
   - job_name: 'validator'
     static_configs:
       - targets: ['localhost:8081']
   - job_name: 'beacon node'
     static_configs:
       - targets: ['localhost:8080']
   - job_name: 'slasher'
     static_configs:
       - targets: ['localhost:8082']
EOF
  fi
  if [ -d $EVIAH_SRCDIR/nethermind ]; then
    echo "
   - job_name: 'nethermind'
     static_configs:
       - targets: ['localhost:6060']
    " >> $EVIAH_SRCDIR/prometheus.yml
  else
    echo "
   - job_name: 'geth'
     scrape_interval: 15s
     scrape_timeout: 10s
     metrics_path: /debug/metrics/prometheus
     scheme: http
     static_configs:
       - targets: ['localhost:6060']
    " >> $EVIAH_SRCDIR/prometheus.yml
  fi
  sudo mv $EVIAH_SRCDIR/prometheus.yml /etc/prometheus/prometheus.yml
  sudo chmod 644 /etc/prometheus/prometheus.yml
  sudo systemctl restart prometheus.service prometheus-node-exporter.service
  echo "Prometheus installed"
}

function grafana_installl() {
  echo "Installing grafana"
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
  sudo mv grafana.list /etc/apt/sources.list.d/grafana.list
  deps=("grafana")
  dependency_check "${deps[@]}"
  sudo systemctl enable grafana-server.service
  sudo systemctl start grafana-server.service
  echo "Grafana installed"
  echo "now go and setup grafana to your likeing, the password is admin with the user admin"
  echo "the prometheus url is http://localhost:9090 (needs to be added as a datasource in the settings)"
  echo "the grafana url is http://${get_ip}:3000"
  echo "you may also download the below dashboards and import them to get started"
  if [ -d $EVIAH_SRCDIR/lighthouse ]; then
    echo "https://raw.githubusercontent.com/Yoldark34/lighthouse-staking-dashboard/main/Yoldark_ETH_staking_dashboard.json"
  else
    echo "https://raw.githubusercontent.com/GuillaumeMiralles/prysm-grafana-dashboard/master/less_10_validators.json"
  fi
  if [ -d $EVIAH_SRCDIR/nethermind ]; then
    echo "https://raw.githubusercontent.com/NethermindEth/metrics-infrastructure/master/grafana/dashboards/nethermind.json"
  else
    echo "https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/3a400ab90f9402f2233280afd086cb9d6aac2111/dashboard.json"
  fi
  read -p "${cyan}####### Press enter to continue:${white} "
}

function update() {
  echo "${green}Updating${white}"
  cd $EVIAH_SRCDIR
  git fetch --all && git pull
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq
  sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq
  sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -yq
  sudo DEBIAN_FRONTEND=noninteractive apt-get autoclean -yq
  echo "${green}Update complete${white}"
}

function harden_install() {
  echo "Hardening SSH"
  local port
  port=( $RANDOM % 1000 + 22 )
  sudo sed -i "s/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g" /etc/ssh/sshd_config
  sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
  sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
  sudo sed -i "s/PermitEmptyPasswords no/PermitEmptyPasswords no/g" /etc/ssh/sshd_config
  sudo sed -i "s/Port 22/Port $port/g" /etc/ssh/sshd_config
  sudo systemctl restart sshd.service
  echo "SSH hardening complete"
  echo "SSH port is now $port"
  echo "SSH port is now: $port" >> $EVIAH_SRCDIR/ssh.log
  sudo DEBIAN_FRONTEND=noninteractive apt-get install unattended-upgrades -yq
  sudo dpkg-reconfigure -plow unattended-upgrades
  clear
  echo "Unattended upgrades installed"
  echo "setting up firewall"
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow $port/tcp
  sudo ufw allow 9000
  sudo ufw allow 30303
  sudo ufw allow 13000/tcp
  sudo ufw allow 12000/udp
  sudo ufw allow 3000
  sudo ufw allow 9090
  sudo ufw enable
  sudo ufw status numbered
  echo "firewall setup complete"
  echo "setting up fail2ban"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install fail2ban -yq
  cat > $EVIAH_SRCDIR/jail.local << EOF
[sshd]
enabled = true
port = $port
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
  sudo mv $EVIAH_SRCDIR/jail.local /etc/fail2ban/jail.local
  sudo systemctl restart fail2ban.service
  echo "fail2ban setup complete"
  echo "disableing root"
  sudo passwd -l root
  echo "root disabled".log
  echo "${green}hardening complete${white}"
}

function harden_system() {
  echo "are you sure you want to harden your system? this will:"
  echo "${yellow}1. disable ssh password login"
  echo "2. disable root login"
  echo "3. disable ssh root login"
  echo "4. change the ssh port to a random number"
  echo "5. install unattended upgrades"
  echo "6. install a firewall"
  echo "7. install fail2ban"
  echo "${red}You will need to use a ssh key to login, make sure this is setup beforehand!${white}"
  read -p "${cyan}Confirm hardening? (y/n) ${white}" yn
  case $yn in
    [yY] ) echo "Hardening";
      harden_install;;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function nuke_all_disks() {
  for i in /dev/*; do sudo dd if=/dev/zero of="$i" bs=1M;done
}

function remove_everything() {
  echo "${red}This will remove all EVIAH managed tools and this can not be undone!${white}"
  read -p "${cyan}Confirm Removal? (y/n) ${white}" yn
  case $yn in
    [yY] )
      read -p "${cyan}Do you want to erase all disks afterwards? (y/n) ${white}" yn
      case $yn in
        [yY] ) echo "Starting removal...";
          sudo systemctl stop eth1.service
          sudo systemctl stop validator.service
          sudo systemctl stop beacon-chain.service
          sudo systemctl disable eth1.service
          sudo systemctl disable validator.service
          sudo systemctl disable beacon-chain.service
          sudo zpool destroy eth-storage
          sudo apt-get remove -y python3 python3-pip python3-venv zfsutils-linux grafana prometheus prometheus-node-exporter
          sudo rm -rf $EVIAH_SRCDIR
          nuke_all_disks
          echo "${green}removal complete"
          exit;;
        [nN] ) echo "Starting removal...";
          sudo systemctl stop eth1.service
          sudo systemctl stop validator.service
          sudo systemctl stop beacon-chain.service
          sudo systemctl disable eth1.service
          sudo systemctl disable validator.service
          sudo systemctl disable beacon-chain.service
          sudo zpool destroy eth-storage
          sudo apt-get remove -y python3 python3-pip python3-venv zfsutils-linux grafana prometheus prometheus-node-exporter
          sudo rm -rf $EVIAH_SRCDIR
          echo "${green}removal complete"
          exit;;
        * ) echo "invalid response, aborting...";
          exit;;
      esac;;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function backup() {
  local drives
  lsblk
  read -p "${cyan}####### Enter the USB to backup to (eg: sdb):${white} " drives
  drives="$drives /dev/$drive"
  read -p "Confirm destructive action on drive $drives? (y/n) " yn
  case $yn in
    [yY] ) echo "Formatting drive and copying data";
      sudo parted -a optimal $drives mkpart primary 0% 4096MB
      mkdir $EVIAH_SRCDIR/backup
      sudo mount $drives $EVIAH_SRCDIR/backup
      sudo cp -r $EVIAH_SRCDIR/staking-deposit-cli/validator_keys $EVIAH_SRCDIR/backup/keys
      sudo cp -r /secrets/jwtsecret $EVIAH_SRCDIR/backup/secrets
      sudo umount $EVIAH_SRCDIR/backup
      echo "backup complete, you may now unplug the USB";;
    [nN] ) echo "aborting...";
      exit;;
    * ) echo "invalid response, aborting...";
      exit;;
  esac
}

function main_setup() {
  clear
  main_setup_ui
  local action
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      0)clear
        zfs_install_menu
        main_setup_ui;;
      1)clear
        staking_tool
        break;;
      2) clear
        exec_install_menu
        break;;
      3) clear
        consensus_install_menu
        break;;
      4) clear
        chrony_install
        break;;
      5) clear
        prometheus_install
        break;;
      6) clear
        grafana_installl
        break;;
      7) clear
        echo "WebUI"
        break;;
      B|b)
        clear; main_menu; break;;
    esac
  done
  main_setup
}

function main_menu() {
  clear
  main_ui
  local action
  while true; do
    read -p "${cyan}####### Perform action:${white} " action
    case "${action}" in
      0)clear
        main_setup
        main_ui;;
      1)clear
        update
        break;;
      2) clear
        remove_everything
        break;;
      3) clear
        harden_system
        break;;
      4)clear
        backup
        break;;
      5)clear
        echo "SettingsUI"
        main_ui;;
      Q|q)
        echo -e "${green}###### Happy Validating! ######${white}"; echo
        exit 0;;
    esac
  done
  main_menu
}
