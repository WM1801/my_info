FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем тулчейн, OpenOCD и утилиты
RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi \
    build-essential \
    cmake \
    make \
    git \
    python3 \
    python3-pip \
    python-is-python3 \
    openocd \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Python-библиотеки для сборки и скриптов
RUN pip3 install --no-cache-dir \
    intelhex \
    pyserial \
    crcmod

WORKDIR /project

CMD ["/bin/bash"]
