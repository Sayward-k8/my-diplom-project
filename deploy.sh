#!/bin/bash

#Создаем инфраструктуру в yc

cd ~/Diplom/terraform
terraform apply -auto-approve

#Формируем hosts для ansible

cd ~/Diplom/
bash ./ter-ans.sh

#Копирование SSH ключа на bastion
BASTION_IP=$(cd ~/Diplom/terraform && terraform output -raw bastion_public_ip)
ssh-copy-id -o StrictHostKeyChecking=no vigonin@$BASTION_IP 2>/dev/null || true

cd ~/Diplom/ansible

for playbook in playbooks/elasticsearch.yml \
                playbooks/kibana.yml \
                playbooks/nginx.yml \
                playbooks/filebeat.yml \
                playbooks/zabbix.yml \
                playbooks/zabbix-agent.yml; do
    ansible-playbook -i inventory/hosts.yml "$playbook"
done
cd ~/Diplom/terraform
