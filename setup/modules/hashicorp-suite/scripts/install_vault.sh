#!/bin/bash
#
# Installs Vault
#
# Note: Generally follows guidelines at https://web.archive.org/web/20170701145736/https://google.github.io/styleguide/shell.xml.
#

set -e

readonly DEPENDENCIES='wget unzip'

# check_prerequisites - exits if distro is not supported.
#
# Parameters:
#     None.
function check_prerequisites() {
  local distro
  if [[ -f "/etc/lsb-release" ]]; then
    distro="Ubuntu"
  fi

  if [[ -z "${distro}" ]]; then
    log "Unsupported platform. Exiting..."
    exit 1
  fi
}

# install_dependencies - installs dependencies
#
# Parameters:
#     -
function install_dependencies() {
  echo "Updating package index..."
  apt-get -qq update

  log "Installing dependencies [${DEPENDENCIES}]..."
  apt-get -qq install ${DEPENDENCIES}
}

# check_arguments - exits if arguments are NOT satisfied
#
# Parameters:
#     $1: the version of vault
function check_arguments() {
  local -r vault_version=${1}

  if [[ -z "${vault_version}" ]]; then
    log "Vault version NOT provided. Exiting..."
    exit 1
  fi

}

# install - downloads and installs the specified tool and version
#
# Parameters:
#     $1: the version of vault
function install_vault() {
  local -r vault_version=${1}

  local -r user_vault='vault'

  local -r download_path="vault_${vault_version}_linux_amd64.zip"
  local -r install_path="/usr/local/bin"
  local -r config_path="/etc/vault"

  log "Downloading Vault ${vault_version}..."
  wget -O ${download_path} "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"

  log "Installing Vault ${vault_version}..."

  useradd ${user_vault} || log "User [${user_vault}] already exists. Continuing..."

  unzip -o -d ${install_path} ${download_path}

  # allow mlock - https://www.vaultproject.io/docs/configuration/index.html#disable_mlock
  setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

  log "Configuring Vault service..."

  install -d ${config_path}

  /usr/bin/printf '
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
' > ${config_path}/vault.hcl

  /usr/bin/printf "
[Unit]
Description=Vault
Requires=consul-online.target
After=consul-online.target

[Service]
Restart=on-failure
ExecStart=${install_path}/vault server -config ${config_path}/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=${user_vault}
Group=${user_vault}

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/vault.service

  log "Starting Vault..."
  systemctl daemon-reload

  systemctl enable vault.service
  systemctl start vault.service

  log "Set VAULT_ADDR in .bash_profile..."
  echo 'export VAULT_ADDR=http://localhost:8200' >> .bash_profile
}

# log - prints an informational message
#
# Parameters:
#     $1: the message
function log() {
  local -r message=${1}
  local -r script_name=$(basename ${0})
  echo -e "==> ${script_name}: ${message}"
}

# main
function main() {
  check_prerequisites

  local -r arg_vault_version=$(mdata-get 'vault_version')

  check_arguments \
    ${arg_vault_version}

  install_dependencies
  install_vault \
    ${arg_vault_version}

  log "Done."
}

main
