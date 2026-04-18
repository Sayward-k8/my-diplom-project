#  Дипломная работа по профессии «`Системный администратор`» - `Игонин В.А.`

## Задание 

<details>
  
Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

</details> 

## Решение

Здравствуйте. 
Задание было использовать terraform и ansible и так как в ходе выполнения задания приходилось многократно удалять и заново деплоить все ресурсы на YC, хотелось в этой работе добиться максимальной автоматизации, но не всё получилось и хосты в zabbix добавлял руками ☺

У меня изменились ip адреса после [Финальный штрих](https://github.com/Sayward-k8/my-diplom-project/edit/main/README.md#L1258), так надо было перезапустить машины...поэтому правильный Outputs: 

```
Outputs:

bastion_public_ip = "93.77.190.42"
elasticsearch_fqdn = "elasticsearch.ru-central1.internal"
kibana_fqdn = "kibana.ru-central1.internal"
kibana_public_ip = "111.88.254.54"
load_balancer_ip = "81.26.179.68"
web_fqdns = {
  "ru-central1-a" = "web-rucentral1a.ru-central1.internal"
  "ru-central1-b" = "web-rucentral1b.ru-central1.internal"
}
web_ips = {
  "ru-central1-a" = "10.10.0.28"
  "ru-central1-b" = "10.11.0.6"
}
zabbix_fqdn = "zabbix.ru-central1.internal"
zabbix_public_ip = "111.88.240.234"
```


# Структура моего проекта:

```bash
vigonin@k8s-worker1:~/Diplom$ tree
.
├── ansible
│   ├── inventory
│   │   └── hosts.yml
│   └── playbooks
│       ├── elasticsearch.yml
│       ├── filebeat.yml
│       ├── kibana.yml
│       ├── nginx.yml
│       ├── zabbix-agent.yml
│       └── zabbix.yml
├── deploy.sh
├── img
│   └── 21.png
├── ter-ans.sh
├── terraform
│   ├── key.json
│   ├── main.tf
│   ├── modules
│   │   ├── instance
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   ├── security
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   └── vpc
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── variables.tf
│   │       └── versions.tf
│   ├── outputs.tf
│   ├── terraform.tfstate
│   ├── terraform.tfstate.backup
│   ├── terraform.tfvars
│   └── variables.tf
└── terraform.tfstate
```

# Terraform
## Структура Terraform

Основной конфиг

[main.tf](https://github.com/Sayward-k8/my-diplom-project/blob/main/terraform/main.tf)

Переменные подставляются из terraform.tfvars

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/terraform.tfvars.png)

а результаты сохраняются в terraform.tfstate(они оба в .gitignore)

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/terraform.tfstate.png) 

```bash
├── terraform
│   ├── main.tf
│   ├── modules
│   │   ├── instance
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   ├── security
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── variables.tf
│   │   │   └── versions.tf
│   │   └── vpc
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       ├── variables.tf
│   │       └── versions.tf
│   ├── outputs.tf
│   ├── terraform.tfstate
│   ├── terraform.tfvars
│   └── variables.tf
```

Основное преимущество модулей, что модуль можно переиспользовать подставляя другие параметры
## Модули:
## instance  [instance](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/instance)
## security  [security](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/security)
## vpc [vpc](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/vpc)

## Выполнение 
Запускаем скрипт [deploy.sh](https://github.com/Sayward-k8/my-diplom-project/blob/main/deploy.sh)

## Terraform plan 

<details>

```bash

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_alb_backend_group.web will be created
  + resource "yandex_alb_backend_group" "web" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + name       = "web-backend-group"

      + http_backend {
          + name             = "web-backend"
          + port             = 80
          + target_group_ids = (known after apply)
          + weight           = 1

          + healthcheck {
              + healthy_threshold   = 1
              + interval            = "1s"
              + timeout             = "1s"
              + unhealthy_threshold = 2

              + http_healthcheck {
                  + path = "/"
                }
            }

          + load_balancing_config {
              + mode            = "ROUND_ROBIN"
              + panic_threshold = 50
            }
        }
    }

  # yandex_alb_http_router.web will be created
  + resource "yandex_alb_http_router" "web" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + name       = "web-router"
    }

  # yandex_alb_load_balancer.web will be created
  + resource "yandex_alb_load_balancer" "web" {
      + created_at   = (known after apply)
      + folder_id    = (known after apply)
      + id           = (known after apply)
      + log_group_id = (known after apply)
      + name         = "web-load-balancer"
      + network_id   = (known after apply)
      + status       = (known after apply)

      + allocation_policy {
          + location {
              + disable_traffic = false
              + subnet_id       = (known after apply)
              + zone_id         = "ru-central1-a"
            }
        }

      + listener {
          + name = "http-listener"

          + endpoint {
              + ports = [
                  + 80,
                ]

              + address {
                  + external_ipv4_address {
                      + address = (known after apply)
                    }
                }
            }

          + http {
              + handler {
                  + allow_http10       = false
                  + http_router_id     = (known after apply)
                  + rewrite_request_id = false
                }
            }
        }
    }

  # yandex_alb_target_group.web will be created
  + resource "yandex_alb_target_group" "web" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + name       = "web-target-group"

      + target {
          + ip_address = (known after apply)
          + subnet_id  = (known after apply)
        }
      + target {
          + ip_address = (known after apply)
          + subnet_id  = (known after apply)
        }
    }

  # yandex_alb_virtual_host.web will be created
  + resource "yandex_alb_virtual_host" "web" {
      + http_router_id = (known after apply)
      + id             = (known after apply)
      + name           = "web-host"

      + route {
          + name = "default-route"

          + http_route {
              + http_route_action {
                  + backend_group_id = (known after apply)
                  + timeout          = "2s"
                }
            }
        }
    }

  # yandex_compute_snapshot_schedule.daily_backup will be created
  + resource "yandex_compute_snapshot_schedule" "daily_backup" {
      + created_at     = (known after apply)
      + disk_ids       = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + name           = "daily-backup-schedule"
      + snapshot_count = 7
      + status         = (known after apply)

      + schedule_policy {
          + expression = "0 2 * * *"
          + start_at   = (known after apply)
        }

      + snapshot_spec (known after apply)
    }

  # module.bastion.yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "bastion"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "bastion"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.elasticsearch.yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "elasticsearch"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "elasticsearch"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.kibana.yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "kibana"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "kibana"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.security.yandex_vpc_security_group.bastion will be created
  + resource "yandex_vpc_security_group" "bastion" {
      + created_at  = (known after apply)
      + description = "Bastion host security group"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "bastion-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow all egress"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "SSH from internet"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # module.security.yandex_vpc_security_group.elasticsearch will be created
  + resource "yandex_vpc_security_group" "elasticsearch" {
      + created_at  = (known after apply)
      + description = "Elasticsearch security group"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "elastic-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow all egress"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "Elasticsearch API"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 9200
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "SSH from bastion"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # module.security.yandex_vpc_security_group.kibana will be created
  + resource "yandex_vpc_security_group" "kibana" {
      + created_at  = (known after apply)
      + description = "Kibana security group"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "kibana-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow all egress"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "Kibana web UI"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 5601
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "SSH from bastion"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # module.security.yandex_vpc_security_group.web will be created
  + resource "yandex_vpc_security_group" "web" {
      + created_at  = (known after apply)
      + description = "Web servers security group"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "web-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow all egress"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "HTTP from load balancer"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 80
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "SSH from bastion"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Zabbix agent"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 10050
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # module.security.yandex_vpc_security_group.zabbix will be created
  + resource "yandex_vpc_security_group" "zabbix" {
      + created_at  = (known after apply)
      + description = "Zabbix server security group"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "zabbix-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Allow all egress"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "SSH from bastion"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Zabbix server"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 10051
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "10.0.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Zabbix web UI"
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 80
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # module.security.yandex_vpc_security_group_rule.elasticsearch_from_web will be created
  + resource "yandex_vpc_security_group_rule" "elasticsearch_from_web" {
      + description            = "Allow Elasticsearch from web servers"
      + direction              = "ingress"
      + from_port              = -1
      + id                     = (known after apply)
      + labels                 = (known after apply)
      + port                   = 9200
      + predefined_target      = (known after apply)
      + protocol               = "TCP"
      + security_group_binding = (known after apply)
      + security_group_id      = (known after apply)
      + to_port                = -1
      + v4_cidr_blocks         = [
          + "10.10.0.0/24",
          + "10.11.0.0/24",
        ]
      + v6_cidr_blocks         = (known after apply)
    }

  # module.vpc.yandex_vpc_gateway.nat will be created
  + resource "yandex_vpc_gateway" "nat" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + labels     = (known after apply)
      + name       = "nat-gateway"

      + shared_egress_gateway {}
    }

  # module.vpc.yandex_vpc_network.main will be created
  + resource "yandex_vpc_network" "main" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "Main VPC for diplom infrastructure"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "diplom-vpc"
      + subnet_ids                = (known after apply)
    }

  # module.vpc.yandex_vpc_route_table.nat will be created
  + resource "yandex_vpc_route_table" "nat" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + labels     = (known after apply)
      + name       = "nat-route"
      + network_id = (known after apply)

      + static_route {
          + destination_prefix = "0.0.0.0/0"
          + gateway_id         = (known after apply)
            # (1 unchanged attribute hidden)
        }
    }

  # module.vpc.yandex_vpc_subnet.private["ru-central1-a"] will be created
  + resource "yandex_vpc_subnet" "private" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "private-ru-central1-a"
      + network_id     = (known after apply)
      + route_table_id = (known after apply)
      + v4_cidr_blocks = [
          + "10.10.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # module.vpc.yandex_vpc_subnet.private["ru-central1-b"] will be created
  + resource "yandex_vpc_subnet" "private" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "private-ru-central1-b"
      + network_id     = (known after apply)
      + route_table_id = (known after apply)
      + v4_cidr_blocks = [
          + "10.11.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # module.vpc.yandex_vpc_subnet.public["ru-central1-a"] will be created
  + resource "yandex_vpc_subnet" "public" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public-ru-central1-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # module.vpc.yandex_vpc_subnet.public["ru-central1-b"] will be created
  + resource "yandex_vpc_subnet" "public" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public-ru-central1-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.1.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # module.web["ru-central1-a"].yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "web-rucentral1a"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "web-rucentral1a"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.web["ru-central1-b"].yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "web-rucentral1b"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "web-rucentral1b"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.zabbix.yandex_compute_instance.this will be created
  + resource "yandex_compute_instance" "this" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = "zabbix"
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = (sensitive value)
        }
      + name                      = "zabbix"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd83ica41cade1mj35sr"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }
```
</details>

## Инфрастуктура на YC

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/VM.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/vpc.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/sg.png)

# Ansible
```bash
├── ansible
│   ├── inventory
│   │   └── hosts.yml
│   └── playbooks
│       ├── elasticsearch.yml
│       ├── filebeat.yml
│       ├── kibana.yml
│       ├── nginx.yml
│       ├── zabbix-agent.yml
│       └── zabbix.yml
```

После создания ресурсов на YC через терраформ, выполняется скрипт [ter-ans.sh](https://github.com/Sayward-k8/my-diplom-project/blob/main/ter-ans.sh), который формируется файл hosts.yml для ansible, а затем происходит выполнение всех плейбуков ansible.

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/hosts.yml.png)


*Немного о плейбуках:*

~~Изначально, я планировал устанавливать все сервисы традиционным способом через DEB-пакеты, тк официальный репозиторий Elastic был недоступен (ошибка 403 Forbidden), в процессе возник ряд проблем: для версии 9.3 требовалось значительно больше оперативной памяти, чем для 7.17...проблема с блокировкой dpkg, из-за чего плейбуки падали с ошибкой и еще какие то неприятные мелочи и...~~
**В итоге я принял решение использовать Docker**

[плейбуки Elastic Stack, Nginx и Zabbix](https://github.com/Sayward-k8/my-diplom-project/tree/main/ansible/playbooks)

## Выполнение плейбуков

<details>
  
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/1.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/2.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/3.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/4.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/5.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/ansible/6.png)

</details>

# Проверка работоспособности сайта через балансировщик

load_balancer_ip = "81.26.179.68"

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/load_balancer.png)

# Проверка мониторинга Zabbix

## Хосты в Zabbix

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/zabbix_host.png)

## Dashboard с метриками web серверов

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/zabbix_web1.png)

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/zabbix_web2.png)

## Проверка логов

Веб-интерфейс Kibana доступен по адресу: http://111.88.254.54:5601/

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/kibana.png)

Для просмотра логов nginx был создан index pattern `filebeat-*` , отображаются все HTTP запросы к веб-серверам и ошибки nginx

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/filebeat.png)

# Резервное копирование (Snapshots) 
```hcl 
resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name = "daily-backup-schedule"

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    module.bastion.disk_id,
    module.web["ru-central1-a"].disk_id,
    module.web["ru-central1-b"].disk_id,
    module.zabbix.disk_id,
    module.elasticsearch.disk_id,
    module.kibana.disk_id
  ]
}
```

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/snap.png)

# Финальный штрих
И сейчас отправляя на проверку, я меняю одну строчку в файлике terraform.tfvars  
```preemptible            =true ```

на  

```preemptible            = false```

