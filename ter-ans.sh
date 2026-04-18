#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"

cd $TERRAFORM_DIR

# Получаем outputs
BASTION_IP=$(terraform output -raw bastion_public_ip)
ZABBIX_IP=$(terraform output -raw zabbix_public_ip)
KIBANA_IP=$(terraform output -raw kibana_public_ip)
LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)

# Получаем FQDN из outputs
#WEB_FQDNS=$(terraform output -json web_fqdns)
WEB1_IP=$(terraform output -json web_ips | jq -r '.["ru-central1-a"]')
WEB2_IP=$(terraform output -json web_ips | jq -r '.["ru-central1-b"]')

# Создаем inventory файл
mkdir -p $ANSIBLE_DIR/inventory

cat > $ANSIBLE_DIR/inventory/hosts.yml << EOF
---
all:
  vars:
    ansible_user: vigonin
    ansible_python_interpreter: /usr/bin/python3
    bastion_ip: ${BASTION_IP}
    load_balancer_ip: ${LOAD_BALANCER_IP}
    zabbix_public_ip: ${ZABBIX_IP}
    kibana_public_ip: ${KIBANA_IP}
    web1_ip: ${WEB1_IP}
    web2_ip: ${WEB2_IP}
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    bastion_ssh_args: '-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q vigonin@${BASTION_IP}"'
    # Общие переменные
    elasticsearch_host: "elasticsearch.ru-central1.internal"
    kibana_host: "kibana.ru-central1.internal"
    zabbix_server_host: "zabbix.ru-central1.internal"
    zabbix_db_password: "pass_123"
    zabbix_admin_password: "zabbix"

  children:
    bastion:
      hosts:
        bastion-host:
          ansible_host: ${BASTION_IP}
          ansible_user: vigonin

    web_servers:
      hosts:
        web-rucentral1a:
          ansible_host: web-rucentral1a.ru-central1.internal
          ansible_user: vigonin
          internal_ip: ${WEB1_IP}
        web-rucentral1b:
          ansible_host: web-rucentral1b.ru-central1.internal
          ansible_user: vigonin
          internal_ip: ${WEB2_IP}

    monitoring:
      hosts:
        zabbix:
          ansible_host: '{{ zabbix_server_host }}'
          ansible_ssh_common_args: '{{ bastion_ssh_args }}'

    logging:
      hosts:
        elasticsearch:
          ansible_host: '{{ elasticsearch_host }}'
          ansible_ssh_common_args: '{{ bastion_ssh_args }}'
        kibana:
          ansible_host: '{{ kibana_host }}'
          ansible_ssh_common_args: '{{ bastion_ssh_args }}'

    private_servers:
      children:
        web_servers:
        logging:
      vars:
        ansible_ssh_common_args: '{{ bastion_ssh_args }}'

    all_servers:
      children:
        bastion:
        web_servers:
        monitoring:
        logging:

EOF
