IMAGE ?= ti-mmwave-build-tools:linux-smoke
TI_ROOT ?= /home/kj/ti
HOST_TI_ROOT ?= $(TI_ROOT)

.PHONY: docker-build docker-shell github-actions-smoke official-demo-manifest project-new project-docker project-native doctor test ci docker-cmake native-cmake benchmark validate-devices flash-list flash-doctor flash-dry-run flash package clean

docker-build:
	docker build -t $(IMAGE) .

docker-shell:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/docker-shell.sh

github-actions-smoke:
	scripts/github-actions-smoke.sh

official-demo-manifest:
	scripts/check-official-demo-manifest.sh

project-new:
	scripts/new-project.sh $(PROJECT) --device $(or $(DEVICE),xwr68xx) $(if $(OUT),--out $(OUT),) $(if $(FORCE),--force,)

project-docker:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) PROJECT=$(PROJECT) scripts/cmake-build-project.sh

project-native:
	TI_ROOT=$(TI_ROOT) PROJECT=$(PROJECT) scripts/native-build-project.sh

doctor:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/doctor.sh

test:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/test.sh

ci:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/ci.sh

docker-cmake:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/cmake-build-xwr68xx-sdk-demo.sh

native-cmake:
	TI_ROOT=$(TI_ROOT) scripts/native-cmake-build-xwr68xx-sdk-demo.sh

benchmark:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/benchmark.sh

validate-devices:
	IMAGE=$(IMAGE) TI_ROOT=$(TI_ROOT) HOST_TI_ROOT=$(HOST_TI_ROOT) scripts/validate-devices.sh

flash-list:
	scripts/flash-list.sh

flash-doctor:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) scripts/flash-doctor.sh

flash-dry-run:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) scripts/flash-dry-run.sh

flash:
	PORT=$(PORT) BIN=$(BIN) DSLITE=$(DSLITE) UNIFLASH_ROOT=$(UNIFLASH_ROOT) UNIFLASH_CLI_DIR=$(UNIFLASH_CLI_DIR) CCXML=$(CCXML) UFSETTINGS=$(UFSETTINGS) CONFIRM_FLASH=$(CONFIRM_FLASH) scripts/flash.sh

package:
	ARTIFACT_DIR=$$(pwd)/artifacts REPORT_DIR=$$(pwd)/reports scripts/package-artifacts.sh

clean:
	scripts/clean.sh
