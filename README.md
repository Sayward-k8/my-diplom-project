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

Так как в ходе выполнения задания приходилось многократно удалять и заново деплоить все ресурсы на YC, я хотел, чтобы всё максимально было автоматизировано

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

## instance  [instance](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/instance)
## security  [security](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/security)
## vpc [vpc](https://github.com/Sayward-k8/my-diplom-project/tree/main/terraform/modules/vpc)

## Выполнение 
Запускаем скрипт [deploy.sh](https://github.com/Sayward-k8/my-diplom-project/blob/main/deploy.sh)

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/terraform-plan.png)
![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/terraform-plan2.png)

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

После создания ресурсов на YC через терраформ, выполняется скрипт [ter-ans.sh](https://github.com/Sayward-k8/my-diplom-project/blob/main/ter-ans.sh), который формируется файл hosts.yml для ansible,

![alt text](https://github.com/Sayward-k8/my-diplom-project/blob/main/img/hosts.yml.png)

а затем происходит выполнение всех плейбуков ansible 

*Немного о плейбуках:*

~~Изначально, я планировал устанавливать все сервисы традиционным способом через DEB-пакеты, тк официальный репозиторий Elastic был недоступен (ошибка 403 Forbidden), в процессе возник ряд проблем: для версии 9.3 требовалось значительно больше оперативной памяти, чем для 7.17...проблема с блокировкой dpkg, из-за чего плейбуки падали с ошибкой и еще какие то неприятные мелочи и...~~
**В итоге я принял решение использовать Docker**

[плейбуки Elastic Stack, Nginx и Zabbix](https://github.com/Sayward-k8/my-diplom-project/tree/main/ansible/playbooks)

![alt text](скрины выполнения плейбуков ansible )

# Проверка работоспособности сайта через балансировщик

![alt text](скрин сайта)

# Проверка мониторинга Zabbix

Доступность Zabbix

![alt text](скрин сайта)

## Хосты в Zabbix

![alt text](скрин сайта)

## Dashboard с метриками

![alt text](скрин сайта)


## Проверка логов

Веб-интерфейс Kibana доступен по адресу:

![alt text](скрин сайта)

Для просмотра логов nginx был создан index pattern `filebeat-*`

![alt text](скрин сайта)

В разделе **Discover** отображаются логи nginx:

- `access.log` — все HTTP запросы к веб-серверам
- `error.log` — ошибки nginx

![alt text](скрин сайта)

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
