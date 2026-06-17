#!/bin/bash

sudo docker run --rm \
  -v $(pwd)/project:/project \
  -w /project/mfi_su35/make_files \
  milandr-build-env \
  make clean



sudo docker run --rm \
  -v $(pwd)/project:/project \
  -w /project/mfi_su35/make_files \
  milandr-build-env \
  make
