#--------------------------------------------------------------------------------------------------
#--------------------------------------------- GCC ------------------------------------------------
#--------------------------------------------------------------------------------------------------

# Git версионирование (из v2)
GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags 2>/dev/null || echo "unknown")
GIT_REMOTE := $(shell git config --get remote.origin.url 2>/dev/null | sed 's/^.*github/github/' || echo "unknown")

#-include config.mk
TARGET_MCU    := cortex-m3
OUTPUT_NAME   := MDR_project
FIRMWARE_NAME := mdr_firmware
LSCRIPT       := MDR32F9Qx.ld
VERSION       := _1_0

# Адрес для контрольной суммы (из v1 - сохранено!)
CHECKSUM_ADDRESS := 0x0801CFFC

INCLUDE := \
../CMSIS/MDR32FxQI/CoreSupport/CM3 \
../CMSIS/MDR32FxQI/DeviceSupport/MDR32F9Q2I/inc \
../SPL/MDR32FxQI \
../SPL/MDR32FxQI/inc \
../SPL/MDR32FxQI/inc/USB_Library \
../SPL/MDR32FxQI/inc/IRQ_Handler_Template \
../CMSIS/MDR32FxQI/DeviceSupport/MDR32F9Q2I/startup \
../src

SOURCE := \
../CMSIS/MDR32FxQI/DeviceSupport/MDR32F9Q2I/startup \
../SPL/MDR32FxQI/src \
../src

SOURCE_S := \
../CMSIS/MDR32FxQI/DeviceSupport/MDR32F9Q2I/startup/arm

# Дефайны (из v1 сохранено USB_DEBUG_MODE + из v2 добавлен Git)
GCC_DEF := \
-D__NO_SYSTEM_INIT -D__STARTUP_CLEAR_BSS \
-D__STACK_SIZE=4096 -D__START=main \
-DUSB_DEBUG_MODE \
-DGIT_VERSION="\"$(GIT_VERSION)\"" \
-DGIT_REMOTE="\"$(GIT_REMOTE)\""

OCD_INTERFACE_ := stlink-v2.cfg
OCD_INTERFACE := jlink.cfg
OCD_TARGET    := mdr32f9q2i.cfg

# Команды сброса (из v1 - сохранено!)
OCD_RESET_CMD := \
-c 'mww 0x4002001C 0x1010' \
-c 'mww 0x40060004 0x00' \
-c 'mww 0x40060000 0xFF'

REAL_PATH := $(realpath .)

MAP := $(OUTPUT_NAME).map
ELF := $(OUTPUT_NAME).elf
LSS := $(OUTPUT_NAME).lss
HEX := $(FIRMWARE_NAME)$(VERSION).hex

# Папка для сборки (из v2 - улучшено!)
BUILD_DIR := ./build

NIL :=
SPACE := $(NIL) $(NIL)

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
C_SRC := $(call rwildcard, $(SOURCE), *.c)
S_SRC := $(call rwildcard, $(SOURCE_S), *.S)

# Объектные файлы в папке build с сохранением структуры (из v2)
C_OBJ := $(sort $(patsubst ../%.c,$(BUILD_DIR)/%.o,$(C_SRC)))
S_OBJ := $(sort $(patsubst ../%.S,$(BUILD_DIR)/%.o,$(S_SRC)))

# Создаём каталоги для объектных файлов
OBJ_DIRS := $(sort $(dir $(C_OBJ) $(S_OBJ)))

# Генерация зависимостей от заголовочных файлов
DEP_DIR := $(BUILD_DIR)/deps
#DEP_FLAGS = -MMD -MP -MF $(DEP_DIR)/$(patsubst ../%,%,$*).d

# Отладочная информация
$(info C_SRC count: $(words $(C_SRC)))
$(info C_OBJ count: $(words $(C_OBJ)))
$(info S_SRC count: $(words $(S_SRC)))
$(info S_OBJ count: $(words $(S_OBJ)))

define make-depend
$(DEP_DIR)/$(patsubst ../%,%,$(1:.c=.d))
endef

#--------------------------------------------------------------------------------------------------

GCC_CFLAGS := \
$(addprefix -I, $(INCLUDE)) -mcpu=$(TARGET_MCU) -mthumb -O0 -g \
-ffunction-sections -fdata-sections \
-Wall -Wextra -Wshadow -Wredundant-decls -Wno-unused-parameter \
-Wno-missing-field-initializers -Wno-main \
-pipe $(GCC_DEF)

GCC_LFLAGS := \
-T $(LSCRIPT) \
-ggdb \
--specs=nano.specs \
--specs=nosys.specs \
-Wl,--gc-sections -ffreestanding -nostartfiles \
-Wl,-Map=$(MAP) \


#--------------------------------------------------------------------------------------------------
#===================================== ОСНОВНАЯ СБОРКА ============================================
#--------------------------------------------------------------------------------------------------

all: clean_old $(BUILD_DIR) $(HEX)
	@rm -f $(MAP)
	@echo "Building done"

clean_old:
	@echo "Removing old object files from current directory..."
	@rm -f *.o

$(BUILD_DIR):
	@mkdir -p $(OBJ_DIRS)
	@mkdir -p $(DEP_DIR)

clean: 
	@echo "Cleaning"
	@rm -rf $(BUILD_DIR) $(ELF) $(LSS) $(HEX) $(MAP)
	@rm -f *.o

# Правило для создания объектных файлов из .c
$(BUILD_DIR)/%.o: ../%.c makefile | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@mkdir -p $(dir $(DEP_DIR)/$(patsubst ../%,%,$<))
	@echo -e "Compile: $@ \t\t $<"
	@arm-none-eabi-gcc $(GCC_CFLAGS) -MMD -MP -MF $(DEP_DIR)/$(patsubst ../%,%,$<).d -c -o $@ $<
	
# Правило для создания объектных файлов из .S
$(BUILD_DIR)/%.o: ../%.S makefile | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	@echo -e "Compile: $@ \t $<"
	@arm-none-eabi-gcc $(GCC_CFLAGS) -c -o $@ $<

$(ELF): $(C_OBJ) $(S_OBJ)
	@echo -e "Linking: $@"
	@echo "Object files count: $(words $(C_OBJ) $(S_OBJ))"
	@arm-none-eabi-gcc $(GCC_CFLAGS) $(GCC_LFLAGS) $(C_OBJ) $(S_OBJ) -o $(ELF) -lm
	
$(LSS): $(ELF)
	@echo -e "Generate $@"
	@arm-none-eabi-objdump -h -S $(ELF) > $(LSS)

# HEX + Контрольная сумма (из v1 - сохранено!)
$(HEX): $(ELF) $(LSS)
	@echo 
	@arm-none-eabi-size $<
	@echo -e '\nGenerate firmware: $@'
	@arm-none-eabi-objcopy -O ihex $< $@
	@python add_checksum.py $@ $(CHECKSUM_ADDRESS)

# Правило для включения файлов зависимостей (ИСПРАВЛЕНО)
# Создаем список .d файлов на основе C_OBJ
DEP_FILES := $(C_OBJ:.o=.d)
# Заменяем build/ на build/deps/ в путях
DEP_FILES := $(subst $(BUILD_DIR)/,$(DEP_DIR)/,$(DEP_FILES))
-include $(DEP_FILES)

#--------------------------------------------------------------------------------------------------
#--------------------------------------------Jlink load ------------------------------------------
#--------------------------------------------------------------------------------------------------
jlink_prog:
	@JLinkExe -device K1986BE92QI -CommanderScript  CommandFile.jlink

#--------------------------------------------------------------------------------------------------
#------------------------------------------- OpenOCD ----------------------------------------------
#--------------------------------------------------------------------------------------------------

OCD_SHUTDOWN := \
-c 'shutdown'

OCD_PROGRAM := \
-c 'init' \
$(OCD_RESET_CMD) \
-c 'reset halt' \
-c 'wait_halt' \
-c 'flash write_image erase $(REAL_PATH)/$(ELF)' \
-c 'flash verify_image $(REAL_PATH)/$(ELF)' \
-c 'reset' \
$(OCD_RESET_CMD)

OCD_ERASE := \
-c 'init' \
-c 'reset halt' \
-c 'flash erase_sector 0 0 31' \
-c 'flash erase_check 0' \
-c 'reset'

OCD_READ := \
-c 'init' \
-c 'reset' \
-c 'halt' \
-c 'flash read_bank 0 test.bin 0 0x20000' \
-c 'reset'

OCD_DBG := \
-c 'bindto 0.0.0.0' \
-c 'debug_level 0' \
$(OCD_PROGRAM) \
-c 'reset halt'

prog: all
	@openocd -f $(OCD_INTERFACE) -f $(OCD_TARGET) $(OCD_PROGRAM) $(OCD_SHUTDOWN)

erase:
	@openocd -f $(OCD_INTERFACE) -f $(OCD_TARGET) $(OCD_ERASE) $(OCD_SHUTDOWN)

read:
	@openocd -f $(OCD_INTERFACE) -f $(OCD_TARGET) $(OCD_READ) $(OCD_SHUTDOWN)

ocd:
	@openocd -f $(OCD_INTERFACE) -f $(OCD_TARGET) $(OCD_DBG)

#--------------------------------------------------------------------------------------------------
GDB_DBG := \
-ex 'target remote localhost:3333' \
-ex 'break main' \
-ex 'continue'

debug:
	@openocd -f $(OCD_INTERFACE) -f $(OCD_TARGET) $(OCD_DBG) &
	@arm-none-eabi-gdb $(GDB_DBG) $(ELF)
	@killall openocd
	@echo "\033[33mDebuging closed\033[37m\n"

.PHONY: all clean clean_old prog erase read ocd debug jlink_prog
