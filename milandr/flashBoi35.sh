#!/bin/bash

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функция помощи
show_help() {
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -i, --interface <swd|jtag>  Интерфейс отладки (по умолчанию: jtag)"
    echo "  -s, --skip-build            Пропустить сборку (только прошивка)"
    echo "  -h, --help                  Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0                          # JTAG (по умолчанию)"
    echo "  $0 -i jtag                  # JTAG (явно)"
    echo "  $0 -i swd                   # SWD"
    echo "  $0 -s                       # Только прошивка через JTAG"
    echo "  $0 -s -i swd                # Только прошивка через SWD"
}

# Значения по умолчанию
INTERFACE="jtag"
SKIP_BUILD=false

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interface)
            INTERFACE="$2"
            if [[ "$INTERFACE" != "swd" && "$INTERFACE" != "jtag" ]]; then
                echo -e "${RED}❌ Ошибка: интерфейс должен быть 'swd' или 'jtag'${NC}"
                exit 1
            fi
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Неизвестная опция: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Определяем конфиг
if [ "$INTERFACE" == "swd" ]; then
    OCD_CFG="jlink-swd.cfg"
else
    OCD_CFG="jlink.cfg"
fi

# Проверка J-Link
echo -e "${YELLOW}🔍 Проверяю подключение J-Link...${NC}"
if ! lsusb | grep -qi "segger\|jlink"; then
    echo -e "${RED}❌ J-Link не найден!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ J-Link найден${NC}"

# Сборка (если не пропущена)
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${YELLOW}🔨 Собираю проект...${NC}"
    sudo docker run --rm \
      -v $(pwd)/project:/project \
      -w /project/mfi_su35/make_files \
      milandr-build-env \
      make
    echo -e "${GREEN}✅ Сборка завершена${NC}"
else
    echo -e "${YELLOW}⏭ Сборка пропущена${NC}"
fi

# Прошивка
echo -e "${YELLOW}🔌 Прошиваю через OpenOCD (интерфейс: ${INTERFACE}, конфиг: ${OCD_CFG})...${NC}"

# Если SWD — переопределяем OCD_INTERFACE, иначе используем дефолт из makefile
if [ "$INTERFACE" == "swd" ]; then
    sudo docker run --rm \
      --privileged \
      --net=host \
      -v /dev/bus/usb:/dev/bus/usb \
      -v $(pwd)/project:/project \
      -w /project/mfi_su35/make_files \
      milandr-build-env \
      make prog OCD_INTERFACE=${OCD_CFG}
else
    sudo docker run --rm \
      --privileged \
      --net=host \
      -v /dev/bus/usb:/dev/bus/usb \
      -v $(pwd)/project:/project \
      -w /project/mfi_su35/make_files \
      milandr-build-env \
      make prog
fi

echo -e "${GREEN}✅ Готово!${NC}"
