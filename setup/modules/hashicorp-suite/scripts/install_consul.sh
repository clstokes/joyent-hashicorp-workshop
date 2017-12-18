#!/bin/bash
#
# Installs Consul
#
# Note: Generally follows guidelines at https://web.archive.org/web/20170701145736/https://google.github.io/styleguide/shell.xml.
#

set -e

readonly CONSUL_CONFIG_PATH='/etc/consul.d'
readonly DEPENDENCIES='wget unzip dnsutils'

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
#     None.
function install_dependencies() {
  log "Updating package index..."
  apt-get -qq update

  log "Installing dependencies [${DEPENDENCIES}]..."
  apt-get -qq install ${DEPENDENCIES}
}

# check_arguments - exits if arguments are NOT satisfied
#
# Parameters:
#     $1: the version of consul
#     $2: the version of consul template
#     $3: the consul cns service name
#     $4: the mode of consul
#     $5: the consul datacenter
#     $6: the count of consul servers
function check_arguments() {
  local -r consul_version=${1}
  local -r consul_template_version=${2}
  local -r consul_cns_service_name=${3}
  local -r consul_mode=${4}
  local -r consul_datacenter=${5}
  local -r consul_server_count=${6}

  if [[ -z "${consul_version}" ]]; then
    log "Consul Version NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${consul_template_version}" ]]; then
    log "Consul Template Version NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${consul_cns_service_name}" ]]; then
    log "Consul CNS service name NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${consul_mode}" ]]; then
    log "Consul mode NOT provided. Exiting..."
    exit 1
  fi

  if [[ -z "${consul_datacenter}" ]]; then
    log "Consul datacenter NOT provided. Exiting..."
    exit 1
  fi

  if [[ "${consul_mode}" != "server" && "${consul_mode}" != "client" ]]; then
    log "Unknown mode [${consul_mode}]. Exiting..."
    exit 1
  fi


  if [[ "${consul_mode}" == "server" && -z "${consul_server_count}" ]]; then
    log "Consul Server Count must be provided. Exiting..."
    exit 1
  fi

}

# install - downloads and installs the specified tool and version
#
# Parameters:
#     $1: the version of consul
#     $2: the consul cns service name
#     $3: the mode of consul
#     $4: the consul datacenter
#     $5: the count of consul servers
function install_consul() {
  local -r consul_version=${1}
  local -r consul_cns_service_name=${2}
  local -r consul_mode=${3}
  local -r consul_datacenter=${4}
  local -r consul_server_count=${5}

  local -r consul_user='consul'

  local -r download_path="consul_${consul_version}_linux_amd64.zip"
  local -r install_path="/usr/local/bin"
  local -r data_path="/var/lib/consul"

  log "Downloading Consul ${consul_version}..."
  wget -O ${download_path} "https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip"

  log "Installing Consul ${consul_version}..."

  useradd ${consul_user} || log "User [${consul_user}] already exists. Continuing..."

  unzip -o -d ${install_path} ${download_path}

  log "Configuring Consul service..."

  install -d -o ${consul_user} -g ${consul_user} ${CONSUL_CONFIG_PATH}
  install -d -o ${consul_user} -g ${consul_user} ${data_path}

  local -r consul_address=$(get_cns_service_name ${consul_cns_service_name})

  /usr/bin/printf "
data_dir = \"${data_path}\"
datacenter = \"${consul_datacenter}\"
retry_join = [\"${consul_address}\"]
addresses {
  http = \"0.0.0.0\"
}
ui = true
enable_script_checks = true
" > ${CONSUL_CONFIG_PATH}/10-defaults.hcl

  #
  # Configure as SERVER
  #
  if [[ "${consul_mode}" == "server" ]]; then
    log "Configuring node as a [${consul_mode}]..."

  /usr/bin/printf "
server = true
bootstrap_expect = ${consul_server_count}
" > ${CONSUL_CONFIG_PATH}/20-server.hcl
  fi

  /usr/bin/printf "
[Unit]
Description=Consul
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=${install_path}/consul agent -config-dir ${CONSUL_CONFIG_PATH}
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=consul
Group=consul

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/consul.service

  log "Starting Consul..."
  systemctl daemon-reload

  systemctl enable consul.service
  systemctl start consul.service

  log "Installing Consul Online service..."

  local -r path_consul_online_script="/${install_path}/waitForConsulOnline.sh"

  # Borrowed from https://github.com/jen20/hashidays-nyc/blob/a6115f5e3804a5f56231314e071f80833a8e7a0c/packaging/deb-consul/deb-pkg/usr/local/bin/waitForConsulOnline.sh
  /usr/bin/printf '#!/bin/bash

set -e

CONSUL_ADDRESS=${1:-"127.0.0.1:8500"}

# waitForConsulToBeAvailable loops until the local Consul agent returns a 200
# response at the /v1/operator/raft/configuration endpoint.
function waitForConsulToBeAvailable() {
  local consul_addr=$1
  local consul_leader_http_code

  consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%%{http_code}" "${consul_addr}/v1/operator/raft/configuration") || consul_leader_http_code=""

  while [ "${consul_leader_http_code}" != "200" ] ; do
    echo "Waiting for Consul to get a leader..."
    sleep 5
    consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%%{http_code}" "${consul_addr}/v1/operator/raft/configuration") || consul_leader_http_code=""
  done

  echo "Consul leader has been elected."
}

waitForConsulToBeAvailable "${CONSUL_ADDRESS}"
' > ${path_consul_online_script}

  chmod +x ${path_consul_online_script}

  /usr/bin/printf "
[Unit]
Description=Consul Online
Requires=consul.service
After=consul.service

[Service]
Type=oneshot
ExecStart=${path_consul_online_script}
User=consul
Group=consul

[Install]
WantedBy=consul-online.target multi-user.target
" > /etc/systemd/system/consul-online.service

  /usr/bin/printf "
[Unit]
Description=Consul Online
RefuseManualStart=true
" > /etc/systemd/system/consul-online.target

  systemctl daemon-reload

  systemctl enable consul-online.service
  systemctl enable consul-online.target
  systemctl start consul-online.service
}

# install_consul_template - downloads and installs the specified tool and version
#
# Parameters:
#     $1: the version of consul template
function install_consul_template() {
  local -r consul_template_version=${1}

  local -r download_path="consul-template_${consul_template_version}_linux_amd64.zip"
  local -r install_path="/usr/local/bin"

  log "Downloading Consul ${consul_template_version}..."
  wget -O ${download_path} "https://releases.hashicorp.com/consul-template/${consul_template_version}/consul-template_${consul_template_version}_linux_amd64.zip"

  log "Installing Consul ${consul_template_version}..."
  unzip -o -d ${install_path} ${download_path}
}

function install_dnsmasq() {
  log "Installing dnsmasq..."
  apt-get -qq install dnsmasq-base dnsmasq

  log "Configuring dnsmasq..."
  /usr/bin/printf "
server=/consul/127.0.0.1#8600
listen-address=127.0.0.1
bind-interfaces
" > /etc/dnsmasq.d/consul

  log "Restarting dnsmasq..."
  systemctl restart dnsmasq

  # TODO(clstokes): Better way to update this? Original file has many more lines.
  log "Configuring resolvconf interface-order..."
  /usr/bin/printf "
# customized by consul install script for dnsmasq
lo.@(dnsmasq|pdnsd)
lo.inet6
lo.inet
" > /etc/resolvconf/interface-order

  log "Updating resolvconf..."
  resolvconf -u

  log "Adding dnsmasq service to Consul..."
  /usr/bin/printf '
service {
  name = "dnsmasq"
  tags = ["primary"]
  port = 53
  check {
    args     = ["/usr/bin/pgrep","dnsmasq"]
    interval = "5s"
  }
}
' > ${CONSUL_CONFIG_PATH}/service-dnsmasq.hcl

  log "Reloading Consul..."
  consul reload
}

function get_cns_service_name() {
  # cns format:
  # <instance name>.inst.<account uuid>.<data center name>.cns.joyent.com
  # <service name>.svc.<account uuid>.<data center name>.cns.joyent.com

  local -r service=${1}

  local -r triton_account_uuid=$(mdata-get 'sdc:owner_uuid') # see https://eng.joyent.com/mdata/datadict.html
  local -r triton_region=$(mdata-get 'sdc:datacenter_name') # see https://eng.joyent.com/mdata/datadict.html

  echo "${service}.svc.${triton_account_uuid}.${triton_region}.cns.joyent.com"
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

  local -r arg_consul_version=$(mdata-get 'consul_version')
  local -r arg_consul_template_version=$(mdata-get 'consul_template_version')
  local -r arg_consul_cns_service_name=$(mdata-get 'consul_cns_service_name')
  local -r arg_consul_mode=$(mdata-get 'consul_mode')
  local -r arg_consul_datacenter=$(mdata-get 'sdc:datacenter_name') # see https://eng.joyent.com/mdata/datadict.html
  local -r arg_consul_server_count=$(mdata-get 'consul_server_count')

  check_arguments \
    ${arg_consul_version} ${arg_consul_template_version} \
    ${arg_consul_cns_service_name} ${arg_consul_mode} ${arg_consul_datacenter} ${arg_consul_server_count}

  install_dependencies
  install_consul \
    ${arg_consul_version} \
    ${arg_consul_cns_service_name} ${arg_consul_mode} ${arg_consul_datacenter} ${arg_consul_server_count}

  install_consul_template \
    ${arg_consul_template_version}

  install_dnsmasq

  log "Done."
}

main
