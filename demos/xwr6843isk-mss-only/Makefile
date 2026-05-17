IMAGE ?= meowpas/ti-mmwave-sdk:03.06.02
BUILD_DIR ?= build
MMWAVE_RUN ?= ../../scripts/mmwave-run.sh

.PHONY: pull configure build shell clean

pull:
	docker pull $(IMAGE)

configure:
	$(MMWAVE_RUN) --image $(IMAGE) --workdir . -- \
	  cmake -S . -B $(BUILD_DIR) -G Ninja -DTI_ROOT=/opt/ti

build: configure
	$(MMWAVE_RUN) --image $(IMAGE) --workdir . -- \
	  cmake --build $(BUILD_DIR) --target firmware

shell:
	$(MMWAVE_RUN) --image $(IMAGE) --workdir . --shell

clean:
	rm -rf $(BUILD_DIR)
