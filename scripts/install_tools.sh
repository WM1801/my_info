#!/bin/bash

sudo apt update && sudo apt install -y build-essential linux-headers-$(uname -r) git dkms flex bison libncurses-dev libncurses6 libncursesw6

gcc --version
make --version
flex --version
bison --version
uname -r  # покажет версию ядра
