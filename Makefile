# Board serial port for upload
SERIAL_PORT ?= /dev/cu.usbserial-0001
BAUDRATE = 115200

# Arduino CLI Fully Qualified Board Name (FQBN)
CORE ?= esp8266:esp8266
BOARD_TYPE ?= $(CORE):nodemcuv2
BOARD_OPTIONS ?= :xtal=160
PACKAGE_URLS ?= "https://arduino.esp8266.com/stable/package_esp8266com_index.json" # Add extra packages in comma-separated list

PROJECT_BASE = fm-streamer
PROJECT ?= fm-streamer

# Tool paths / names
ARDUINO_CLI = arduino-cli

# Optional verbose compile/upload trigger
V ?= 0
VERBOSE=

# Build path -- used to store built binary and object files
BUILD_DIR=_build
BUILD_PATH=$(PWD)/$(PROJECT_BASE)/$(BUILD_DIR)

ifneq ($(V), 0)
	VERBOSE=-v
endif

.PHONY: all fm-streamer program clean

all: fm-streamer

config-tools:
	$(ARDUINO_CLI) config init --additional-urls $(PACKAGE_URLS) --overwrite
	$(ARDUINO_CLI) config set library.enable_unsafe_install true
	$(ARDUINO_CLI) core update-index
	$(ARDUINO_CLI) core install $(CORE)
	$(ARDUINO_CLI) lib install ESP8266Audio@1.9.0
	$(ARDUINO_CLI) lib install "Adafruit Si4713 Library"
	$(ARDUINO_CLI) lib install --git-url https://github.com/me-no-dev/ESPAsyncWebServer.git
	$(ARDUINO_CLI) lib install --git-url https://github.com/me-no-dev/ESPAsyncTCP.git

fm-streamer:
	$(ARDUINO_CLI) compile $(VERBOSE) --build-path=$(BUILD_PATH) --build-cache-path=$(BUILD_PATH) -b $(BOARD_TYPE)$(BOARD_OPTIONS) $(PROJECT_BASE)/$(PROJECT)

program: all stop-serial
	$(ARDUINO_CLI) upload $(VERBOSE) -p $(SERIAL_PORT) --fqbn $(BOARD_TYPE)$(BOARD_OPTIONS) --input-dir=$(BUILD_PATH)

stop-serial:
	screen -ls | grep Detached | cut -d. -f1 | awk '{print $1}' | xargs kill

serial: stop-serial
	screen $(SERIAL_PORT) $(BAUDRATE)

clean:
	@rm -rf $(BUILD_PATH)
