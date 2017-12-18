#!/bin/bash
#
# Installs Nomad
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
#     $1: the version of nomad
#     $2: the mode of nomad
#     $3: the nomad datacenter
#     $4: the count of nomad servers
function check_arguments() {
  local -r nomad_version=${1}
  local -r nomad_mode=${2}
  local -r nomad_datacenter=${3}
  local -r nomad_machine_count=${4}

  if [[ -z "${nomad_version}" ]]; then
    log "Nomad version NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${nomad_datacenter}" ]]; then
    log "Nomad datacenter NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${nomad_mode}" ]]; then
    log "Nomad mode NOT provided. Exiting..."
    exit 1
  fi

  if [[ "${nomad_mode}" != "server" && "${nomad_mode}" != "client" ]]; then
    log "Unknown mode [${nomad_mode}]. Exiting..."
    exit 1
  fi


  if [[ "${nomad_mode}" == "server" && -z "${nomad_machine_count}" ]]; then
    log "Nomad Server Count must be provided. Exiting..."
    exit 1
  fi

}

# install - downloads and installs the specified tool and version
#
# Parameters:
#     $1: the version of nomad
#     $2: the mode of nomad
#     $3: the nomad datacenter
#     $4: the count of nomad servers
function install_nomad() {
  local -r nomad_version=${1}
  local -r nomad_mode=${2}
  local -r nomad_datacenter=${3}
  local -r nomad_machine_count=${4}

  local -r download_path="nomad_${nomad_version}_linux_amd64.zip"
  local -r install_path="/usr/local/bin"
  local -r config_path="/etc/nomad.d"
  local -r data_path="/var/lib/nomad"

  log "Downloading Nomad ${nomad_version}..."
  wget -O ${download_path} "https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip"

  log "Installing Nomad ${nomad_version}..."

  unzip -o -d ${install_path} ${download_path}

  log "Configuring Nomad service..."

  install -d ${config_path}
  install -d ${data_path}

  # we need the backslash to passthrough to the final hcl file, hence the escaping madness below.
  /usr/bin/printf "
data_dir = \"${data_path}\"
datacenter = \"${nomad_datacenter}\"
bind_addr = \"0.0.0.0\"
advertise {
  http = \"{{ GetPrivateInterfaces | exclude \\\\""\"name\\\\""\" \\\\""\"docker0\\\\""\" | attr \\\\""\"address\\\\""\" }}\"
  rpc  = \"{{ GetPrivateInterfaces | exclude \\\\""\"name\\\\""\" \\\\""\"docker0\\\\""\" | attr \\\\""\"address\\\\""\" }}\"
  serf = \"{{ GetPrivateInterfaces | exclude \\\\""\"name\\\\""\" \\\\""\"docker0\\\\""\" | attr \\\\""\"address\\\\""\" }}\"
}

consul {
}
" > ${config_path}/10-defaults.hcl

  #
  # Configure as SERVER
  #
  if [[ "${nomad_mode}" == "server" ]]; then
    log "Configuring node as a [${nomad_mode}]..."

  /usr/bin/printf "
server {
  enabled          = true
  bootstrap_expect = ${nomad_machine_count}
}
" > ${config_path}/20-server.hcl
  fi

  #
  # Configure as CLIENT
  #
  if [[ "${nomad_mode}" == "client" ]]; then
    log "Configuring node as a [${nomad_mode}]..."

  /usr/bin/printf "
client {
  enabled = true
}
" > ${config_path}/20-client.hcl
  fi

  /usr/bin/printf "
[Unit]
Description=Nomad
Requires=consul-online.target
After=consul-online.target

[Service]
Restart=on-failure
ExecStart=${install_path}/nomad agent -config ${config_path}
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/nomad.service

  log "Starting Nomad..."
  systemctl daemon-reload

  systemctl enable nomad.service
  systemctl start nomad.service

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

  local -r arg_nomad_version=$(mdata-get 'nomad_version')
  local -r arg_nomad_mode=$(mdata-get 'nomad_mode')
  local -r arg_nomad_datacenter=$(mdata-get 'sdc:datacenter_name') # see https://eng.joyent.com/mdata/datadict.html
  local -r arg_nomad_machine_count=$(mdata-get 'nomad_machine_count')
  check_arguments \
    ${arg_nomad_version} ${arg_nomad_mode} ${arg_nomad_datacenter} ${arg_nomad_machine_count}

  install_dependencies
  install_nomad \
    ${arg_nomad_version} ${arg_nomad_mode} ${arg_nomad_datacenter} ${arg_nomad_machine_count}

  log "Done."
}

main
