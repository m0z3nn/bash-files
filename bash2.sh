#!/bin/bash
#Для ОС: Ubuntu/Debian

# Функция для приветствия текущего пользователя
greet_user() {
    echo "Привет, $(whoami)!"
}

# Функция для автоматической настройки сети
auto_network_setup() {
    echo "Автоматическая настройка сети..."
    #Настройка сети через DHCP
    tee /etc/netplan/01-netcfg.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    $(ip link show | awk '{print $2}' | sed 's/://g'):
      dhcp4: true
      dhcp6: true
EOF
    sudo netplan apply
    echo "Настройка сети выполнена."
    ip addr show
}

# Функция для ручной настройки сети
manual_network_setup() {
    echo "Ручная настройка сети..."
    # Получение списка доступных сетевых адаптеров
    adapters=$(ip link show | awk '{print $2}' | sed 's/://g')
    echo "Выберите сетевой адаптер:"
    select adapter in $adapters; do
        echo "Выбран адаптер $adapter"
        break
    done

    # Выбор между DHCP и STATIC IPv6
    echo "Выберите тип настройки IPv6:"
    select ipv6_type in "DHCP" "STATIC"; do
        case $ipv6_type in
            "DHCP")
                ipv6_config="dhcp6: true"
                break
                ;;
            "STATIC")
                echo "Введите IP-адрес IPv6:"
                read -r ipv6_address
                echo "Введите маску IPv6 (например, 64):"
                read -r ipv6_mask
                ipv6_config="addresses: [$ipv6_address/$ipv6_mask]"
                break
                ;;
        esac
    done

    # Выбор между DHCP и STATIC IPv4
    echo "Выберите тип настройки IPv4:"
    select ipv4_type in "DHCP" "STATIC"; do
        case $ipv4_type in
            "DHCP")
                ipv4_config="dhcp4: true"
                break
                ;;
            "STATIC")
                echo "Введите IP-адрес IPv4:"
                read -r ipv4_address
                echo "Введите маску IPv4 (например, 24):"
                read -r ipv4_mask
                ipv4_config="addresses: [$ipv4_address/$ipv4_mask]"
                break
                ;;
        esac
    done

    # Выбор DNS-серверов
    echo "Выберите DNS-серверы (через запятую, например, 8.8.8.8,4.4.4.4):"
    read -r dns_servers
    dns_config="nameservers: [$dns_servers]"

    # Выбор шлюза и метрики
    echo "Введите шлюз:"
    read -r gateway
    echo "Введите метрику:"
    read -r metric
    gateway_config="gateway4: $gateway"
    metric_config="metric: $metric"

    # Генерация конфигурации Netplan
    netplan_config="network:
  version: 2
  ethernets:
    $adapter:
      $ipv6_config
      $ipv4_config
      $dns_config
      $gateway_config
      $metric_config"

    # Создание файла конфигурации Netplan
    echo "$netplan_config" > /etc/netplan/01-netcfg.yaml

    # Применение настроек Netplan
    sudo netplan apply
    echo "Настройка сети выполнена."
}

# Функция для сброса настроек по умолчанию
reset_network_setup() {
    echo "Сброс настроек сети..."
    # Здесь может быть реализован сброс настроек сети
    echo "Настройки сети сброшены."
}

# Функция для вывода информации из лог-файла
show_log() {
    echo "Вывод информации из лог-файла..."
    # Здесь может быть реализован вывод информации из лог-файла
    echo "Информация из лог-файла:"
    cat /var/log/network_setup.log
}

# Функция для пинга сайта
ping_site() {
    echo "Пинг сайта..."
    echo "Введите адрес сайта:"
    read -r site
    echo "Введите количество пингов:"
    read -r count
    ping -c $count $site
}

# Главное меню
while true; do
    clear
    echo "Меню:"
    echo "1. Приветствие текущего пользователя"
    echo "2. Автоматическая настройка сети"
    echo "3. Ручная настройка сети"
    echo "4. Сброс настроек по умолчанию"
    echo "5. Вывод информации из лог-файла"
    echo "6. Пинг сайта"
    echo "7. Выход"
    read -r choice

    case $choice in
        1)
            greet_user
            ;;
        2)
            auto_network_setup
            ;;
        3)
            manual_network_setup
            ;;
        4)
            reset_network_setup
            ;;
        5)
            show_log
            ;;
        6)
            ping_site
            ;;
        7)
            exit
            ;;
        *)
            echo "Неверный выбор. Пожалуйста, выберите снова."
            ;;
    esac

    # Добавление информации в лог-файл
    echo "$(date) - Выбор: $choice" >> /var/log/network_setup.log
    read -p "Нажмите Enter, чтобы продолжить..."
done